<?php

namespace MJ\DnsManager\Cron;

use MJ\DnsManager\Gateway\DAGateway;
use MJ\DnsManager\Models\Domain;
use MJ\DnsManager\Models\DriftReport;
use MJ\DnsManager\Models\Record;
use MJ\DnsManager\Models\Server;

/**
 * DriftChecker — Detect discrepancies between WHMCS and DirectAdmin.
 *
 * 3 drift types:
 *   - ADDED_ON_DA   : Record exists on DA but not in WHMCS
 *   - REMOVED_ON_DA : Record exists in WHMCS but was deleted from DA
 *   - VALUE_CHANGED : Same name + type but value differs
 */
class DriftChecker
{
    private $startTime;
    private $maxRunTime = 50;
    private $throttleSeconds = 1;
    private $maxDomainsPerRun = 200;
    private $scanned = 0;
    private $driftCount = 0;

    public function __construct()
    {
        $this->startTime = microtime(true);
    }

    // ──────────────────────────────────────────────────────────────────────
    // Public entry points
    // ──────────────────────────────────────────────────────────────────────

    /**
     * Run manually via AJAX — skip isDue(), disable throttle.
     */
    public function runForced(): void
    {
        $this->throttleSeconds = 0;
        $this->maxRunTime = 25;

        $server = Server::where('is_active', true)
            ->where('role', 'primary')
            ->orderBy('sort_order')
            ->first();

        if (!$server) {
            logActivity('MJ DNS Manager [DriftChecker]: No active primary server found. Skipping.');
            return;
        }

        $this->updateLastRunTime();
        $gateway = new DAGateway($server);
        $this->scanDomains($gateway);

        logActivity(
            "MJ DNS Manager [DriftChecker]: Forced scan complete — {$this->scanned} domains scanned, " .
                "{$this->driftCount} domain(s) with drift detected."
        );
    }

    /**
     * Run automatically from AfterCronJob hook.
     */
    public function run(): void
    {
        if (!$this->isDue()) {
            return;
        }

        $server = Server::where('is_active', true)
            ->where('role', 'primary')
            ->orderBy('sort_order')
            ->first();

        if (!$server) {
            logActivity('MJ DNS Manager [DriftChecker]: No active primary server found. Skipping.');
            return;
        }

        $this->updateLastRunTime();
        $gateway = new DAGateway($server);
        $this->scanDomains($gateway);

        logActivity(
            "MJ DNS Manager [DriftChecker]: Scan complete — {$this->scanned} domains scanned, " .
                "{$this->driftCount} domain(s) with drift detected."
        );
    }

    /**
     * Scan a single domain — used for AJAX Check Drift from domains.tpl.
     * Returns array of drifts, saves to DB, no throttle.
     */
    public function scanSingleDomain(Server $server, Domain $domain): array
    {
        $gateway  = new DAGateway($server);
        $response = $gateway->getZone($domain->domain);

        if (!$response->isSuccess() || !isset($response->data['records'])) {
            throw new \RuntimeException(
                'Cannot fetch zone from DA: ' . ($response->errorMessage ?? 'no records returned')
            );
        }

        $localRecords  = Record::where('domain_id', $domain->id)->where('pending_delete', 0)->get();
        $remoteRecords = $this->normalizeRemoteRecords($response->data['records'], $domain->domain);
        $drifts        = $this->diff($localRecords, $remoteRecords);

        DriftReport::where('domain_id', $domain->id)->where('status', 'pending')->delete();

        if (!empty($drifts)) {
            $this->insertDriftRows($domain->id, $drifts);
        }

        logActivity(
            "MJ DNS Manager [DriftChecker]: Manual scan '{$domain->domain}' — " .
                count($drifts) . " drift(s) detected."
        );

        return $drifts;
    }

    // ──────────────────────────────────────────────────────────────────────
    // Private — scan logic
    // ──────────────────────────────────────────────────────────────────────

    private function scanDomains(DAGateway $gateway): void
    {
        $domains = Domain::where('status', 'active')
            ->whereNotNull('provisioned_at')
            ->orderBy('id')
            ->limit($this->maxDomainsPerRun)
            ->get();

        if ($domains->isEmpty()) {
            return;
        }

        foreach ($domains as $domain) {
            if ($this->isTimeLimitReached()) {
                logActivity('MJ DNS Manager [DriftChecker]: Time limit reached, stopping early.');
                break;
            }

            $this->scanOneDomain($gateway, $domain);
            $this->scanned++;

            if ($this->throttleSeconds > 0 && !$this->isTimeLimitReached()) {
                sleep($this->throttleSeconds);
            }
        }
    }

    private function scanOneDomain(DAGateway $gateway, Domain $domain): void
    {
        try {
            $response = $gateway->getZone($domain->domain);

            if (!$response->isSuccess() || !isset($response->data['records'])) {
                logActivity(
                    "MJ DNS Manager [DriftChecker]: getZone failed for '{$domain->domain}' — " .
                        ($response->errorMessage ?? 'no records returned')
                );
                return;
            }

            $localRecords  = Record::where('domain_id', $domain->id)->where('pending_delete', 0)->get();
            $remoteRecords = $this->normalizeRemoteRecords($response->data['records'], $domain->domain);
            $drifts        = $this->diff($localRecords, $remoteRecords);

            DriftReport::where('domain_id', $domain->id)->where('status', 'pending')->delete();

            if (empty($drifts)) {
                return;
            }

            $this->insertDriftRows($domain->id, $drifts);
            $this->driftCount++;

            // Auto-fix if setting drift_auto_fix = true
            // Only fixes REMOVED_ON_DA (WHMCS is source of truth → push to DA)
            if (\MJ\DnsManager\Helpers\SettingsHelper::getBool('drift_auto_fix', false)) {
                $this->autoFix($domain->id, $drifts);
            }

            logActivity(
                "MJ DNS Manager [DriftChecker]: '{$domain->domain}' — " .
                    count($drifts) . " drift(s) detected."
            );

            // ── Notify domain owner (client) about drift ──────────────────
            try {
                $notif = new \MJ\DnsManager\Services\NotificationService();
                $notif->notifyDriftDetected(
                    (int) ($domain->whmcs_user_id ?? 0),
                    $domain->domain,
                    $drifts
                );
            } catch (\Exception $e) {
                logActivity('MJ DNS Manager [DriftChecker]: drift notification exception — ' . $e->getMessage());
            }
        } catch (\Throwable $e) {
            logActivity(
                "MJ DNS Manager [DriftChecker]: Exception scanning '{$domain->domain}' — " .
                    $e->getMessage()
            );
        }
    }

    /**
     * Compare local vs remote, return list of discrepancies.
     *
     * Rules:
     *  - Local has key but remote does not       → REMOVED_ON_DA
     *  - Both have key but values differ         → VALUE_CHANGED
     *  - Remote has key but local has none       → ADDED_ON_DA
     *
     * ADDED_ON_DA is NOT reported when same type|name exists on both sides —
     * that case is handled by VALUE_CHANGED.
     */
    private function diff($localRecords, array $remoteRecords): array
    {
        $drifts = array();

        // Build maps: "{TYPE}|{name}" => [records]
        $localMap = array();
        foreach ($localRecords as $rec) {
            $key = strtoupper($rec->type) . '|' . $rec->name;
            $localMap[$key][] = $rec;
        }

        $remoteMap = array();
        foreach ($remoteRecords as $rec) {
            $key = $rec['type'] . '|' . $rec['name'];
            $remoteMap[$key][] = $rec;
        }

        // ── Pass 1: iterate local → detect REMOVED_ON_DA and VALUE_CHANGED ──
        foreach ($localMap as $key => $localGroup) {
            list($type, $name) = explode('|', $key, 2);

            if ($type === 'SOA') {
                continue;
            }

            if (!isset($remoteMap[$key])) {
                // Remote missing key → REMOVED_ON_DA
                foreach ($localGroup as $rec) {
                    $drifts[] = array(
                        'drift_type'  => 'REMOVED_ON_DA',
                        'record_type' => $type,
                        'record_name' => $name,
                        'local_value' => $this->recordToArray($rec),
                        'remote_value' => null,
                    );
                }
                continue;
            }

            // Both have key — compare values
            $remoteGroup  = $remoteMap[$key];
            $remoteValues = array_column($remoteGroup, 'value');

            foreach ($localGroup as $rec) {
                if (!in_array($rec->value, $remoteValues, true)) {
                    $drifts[] = array(
                        'drift_type'  => 'VALUE_CHANGED',
                        'record_type' => $type,
                        'record_name' => $name,
                        'local_value' => $this->recordToArray($rec),
                        'remote_value' => $remoteGroup[0],
                    );
                }
            }
        }

        // ── Pass 2: iterate remote → detect ADDED_ON_DA ───────────────────
        // Only report ADDED_ON_DA when key is completely absent in local.
        // If key exists on both sides → VALUE_CHANGED (handled above).
        foreach ($remoteMap as $key => $remoteGroup) {
            list($type, $name) = explode('|', $key, 2);

            if ($type === 'SOA') {
                continue;
            }

            if (!isset($localMap[$key])) {
                foreach ($remoteGroup as $remRec) {
                    $drifts[] = array(
                        'drift_type'  => 'ADDED_ON_DA',
                        'record_type' => $type,
                        'record_name' => $name,
                        'local_value' => null,
                        'remote_value' => $remRec,
                    );
                }
            }
        }

        return $drifts;
    }

    /**
     * Bulk insert drift rows into DB.
     */
    private function insertDriftRows(int $domainId, array $drifts): void
    {
        $now  = date('Y-m-d H:i:s');
        $rows = array();

        foreach ($drifts as $d) {
            $rows[] = array(
                'domain_id'    => $domainId,
                'drift_type'   => $this->mapDriftType($d['drift_type']),
                'record_type'  => $d['record_type'],
                'record_name'  => $d['record_name'],
                'local_value'  => json_encode($d['local_value']),
                'remote_value' => json_encode($d['remote_value']),
                'status'       => 'pending',
                'detected_at'  => $now,
            );
        }

        \Illuminate\Database\Capsule\Manager::table('tbl_mj_dns_drift_reports')->insert($rows);
    }

    /**
     * Map internal drift_type → DB ENUM value.
     */
    private function mapDriftType($type)
    {
        $map = array(
            'REMOVED_ON_DA' => 'missing_on_da',
            'ADDED_ON_DA'   => 'added_on_da',
            'VALUE_CHANGED' => 'modified',
        );
        return isset($map[$type]) ? $map[$type] : 'modified';
    }

    /**
     * Normalize records from DA API to WHMCS format for comparison.
     */
    private function normalizeRemoteRecords(array $daRecords, string $domainName): array
    {
        $allowed = array('A', 'AAAA', 'CNAME', 'MX', 'TXT', 'NS', 'SOA', 'SRV', 'CAA');
        $result  = array();

        foreach ($daRecords as $rec) {
            $type = strtoupper((string) ($rec['type'] ?? ''));
            if (!in_array($type, $allowed)) {
                continue;
            }

            // Normalize name
            $name = (string) ($rec['name'] ?? '');
            if ($name === $domainName . '.') {
                $name = '@';
            } elseif (substr($name, - (strlen($domainName) + 2)) === '.' . $domainName . '.') {
                $name = substr($name, 0, - (strlen($domainName) + 2));
            } else {
                $name = rtrim($name, '.');
            }

            $result[] = array(
                'type'     => $type,
                'name'     => $name,
                'value'    => $this->normalizeValue((string) ($rec['value'] ?? ''), $type),
                'ttl'      => (int) ($rec['ttl'] ?? 3600),
                'priority' => isset($rec['priority']) ? (int) $rec['priority'] : null,
            );
        }

        return $result;
    }

    /**
     * Normalize value from DA — keep raw to match DB.
     * Exception MX: strip priority prefix since WHMCS stores it separately.
     */
    private function normalizeValue($daValue, $type)
    {
        if ($type === 'MX') {
            $parts = explode(' ', $daValue, 2);
            if (count($parts) === 2 && is_numeric($parts[0])) {
                return trim($parts[1]);
            }
        }
        return $daValue;
    }

    /**
     * Convert Record model → array for drift_reports storage.
     */
    private function recordToArray($rec)
    {
        return array(
            'type'     => $rec->type,
            'name'     => $rec->name,
            'value'    => $rec->value,
            'ttl'      => $rec->ttl,
            'priority' => in_array(strtoupper($rec->type), ['MX', 'SRV']) ? $rec->priority : null,
        );
    }

    // ──────────────────────────────────────────────────────────────────────
    // Scheduling helpers
    // ──────────────────────────────────────────────────────────────────────

    private function isDue(): bool
    {
        try {
            $hours   = \MJ\DnsManager\Helpers\SettingsHelper::getInt('drift_check_interval_hours', 24);
            $lastRun = \MJ\DnsManager\Helpers\SettingsHelper::get('drift_last_run', '');

            if (empty($lastRun)) {
                return true;
            }

            return time() >= strtotime($lastRun) + ($hours * 3600);
        } catch (\Throwable $e) {
            return true;
        }
    }

    private function updateLastRunTime(): void
    {
        try {
            \MJ\DnsManager\Helpers\SettingsHelper::set('drift_last_run', date('Y-m-d H:i:s'));
        } catch (\Throwable $e) {
            // Silent
        }
    }

    private function isTimeLimitReached(): bool
    {
        return (microtime(true) - $this->startTime) >= $this->maxRunTime;
    }

    /**
     * Auto-fix drift: only handles REMOVED_ON_DA (record in WHMCS but missing from DA)
     * by dispatching ADD_RECORD job to push it back up.
     * ADDED_ON_DA and VALUE_CHANGED are not auto-fixed — admin decision required.
     */
    private function autoFix(int $domainId, array $drifts): void
    {
        $qm = new \MJ\DnsManager\Services\QueueManager();

        foreach ($drifts as $d) {
            if ($d['drift_type'] !== 'REMOVED_ON_DA') {
                continue;
            }

            $local = $d['local_value'];
            if (empty($local['value'])) {
                continue;
            }

            try {
                $payload = [
                    'record_id' => 0,
                    'type'      => $local['type'],
                    'name'      => $local['name'],
                    'value'     => $local['value'],
                    'ttl'       => $local['ttl'] ?? 3600,
                ];
                if (!empty($local['priority'])) {
                    $payload['priority'] = $local['priority'];
                }

                $qm->dispatch($domainId, 'ADD_RECORD', $payload, 3, 'system', null);

                logActivity(
                    "MJ DNS Manager [DriftChecker]: Auto-fix dispatched ADD_RECORD " .
                        "{$local['type']} {$local['name']} for domain #{$domainId}."
                );
            } catch (\Throwable $e) {
                logActivity(
                    "MJ DNS Manager [DriftChecker]: Auto-fix failed for " .
                        "{$local['type']} {$local['name']} — " . $e->getMessage()
                );
            }
        }
    }
}
