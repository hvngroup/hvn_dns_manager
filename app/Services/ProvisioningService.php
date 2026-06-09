<?php

namespace HvnGroup\DnsManager\Services;

use HvnGroup\DnsManager\Models\AuditTrail;
use HvnGroup\DnsManager\Models\Domain;
use HvnGroup\DnsManager\Models\Template;

/**
 * ProvisioningService — Handles the full lifecycle of DNS zone provisioning.
 *
 * Called exclusively from Hook handlers in app/Hooks/.
 * This service writes to DB and dispatches queue jobs only — NO DA API calls.
 */
class ProvisioningService
{
    /** @var QueueManager */
    private QueueManager $queue;

    public function __construct()
    {
        $this->queue = new QueueManager();
    }

    /**
     * Handle DNS zone creation when a WHMCS service is provisioned.
     *
     * Called by: AfterModuleCreate hook.
     * Steps:
     *   1. Create/find domain record in mod_hvndns_domains.
     *   2. Build CREATE_ZONE payload from default template.
     *   3. Dispatch CREATE_ZONE job to queue (returns batch_id immediately).
     *   4. Write audit trail.
     *   5. Update WHMCS nameservers via localAPI().
     *
     * @param  string   $domainName Domain name (e.g. "example.com").
     * @param  int      $userId     WHMCS client ID (tblclients.id).
     * @param  int|null $serviceId  WHMCS service ID (tblhosting.id), nullable for manual.
     * @param  string   $clientIp   Client IP for audit trail.
     * @return array{success: bool, batch_id?: string, error?: string}
     */
    public function handleCreate(
        string $domainName,
        int $userId,
        ?int $whmcsDomainId,
        string $clientIp = '127.0.0.1'
    ): array {
        // Step 1: Idempotent domain record creation
        // whmcs_domain_id maps to tbldomains.id (domain registration)
        $domain = Domain::firstOrCreate(
            ['domain' => $domainName],
            [
                'whmcs_domain_id' => $whmcsDomainId,
                'whmcs_user_id' => $userId,
                'status' => 'active',
            ]
        );

        // Step 2: Build payload — try to use default template first
        $template = Template::where('is_default', true)->first();
        $payload = $this->buildCreateZonePayload($domainName, $template);

        // Step 3: Dispatch CREATE_ZONE to queue (DB write only, < 50ms)
        try {
            $batchId = $this->queue->dispatch(
                $domain->id,
                'CREATE_ZONE',
                $payload,
                5,        // priority = 5 (system provision)
                'system',
                null
            );
        } catch (\RuntimeException $e) {
            logActivity("HVN DNS Manager: Cannot dispatch CREATE_ZONE for {$domainName} — " . $e->getMessage());
            return ['success' => false, 'error' => $e->getMessage()];
        }

        // Step 4: Append-only audit trail
        AuditTrail::create([
            'actor_type' => 'system',
            'actor_id' => $userId,
            'actor_name' => 'WHMCS AutoProvision',
            'domain' => $domainName,
            'domain_id' => $domain->id,
            'action' => 'zone_provision',
            'target_type' => 'zone',
            'new_value' => $payload,
            'context' => 'cron_provision',
            'ip_address' => $clientIp,
            'notes' => "Auto-provisioned via domain registration. Queue batch_id: {$batchId}",
        ]);

        logActivity("HVN DNS Manager: CREATE_ZONE dispatched for {$domainName} (batch: {$batchId})");

        return ['success' => true, 'batch_id' => $batchId, 'domain_id' => $domain->id];
    }

    /**
     * Handle DNS zone deletion when a WHMCS service is terminated.
     *
     * Soft-deletes the domain (status = 'terminated') and dispatches DELETE_ZONE.
     * The zone is NOT immediately deleted on DA — the queue worker does it async.
     * Physical deletion happens after 30-day grace period.
     *
     * @param  string   $domainName Domain name.
     * @param  int      $userId     WHMCS client ID.
     * @param  int|null $serviceId  WHMCS service ID.
     * @param  string   $clientIp   Client IP for audit trail.
     * @return array{success: bool, batch_id?: string, error?: string}
     */
    public function handleTerminate(
        string $domainName,
        int $userId,
        ?int $serviceId,
        string $clientIp = '127.0.0.1'
    ): array {
        $domain = Domain::where('domain', $domainName)->first();

        if (!$domain) {
            logActivity("HVN DNS Manager: Terminate — domain not found: {$domainName}");
            return ['success' => true]; // Already gone, treat as success
        }

        // Soft-delete: mark as terminated (do NOT hard-delete — grace period from Settings)
        $graceDays = \HvnGroup\DnsManager\Helpers\SettingsHelper::getInt('grace_period_days', 30);
        $domain->update([
            'status' => 'terminated',
            'terminated_at' => date('Y-m-d H:i:s'),
        ]);

        // Dispatch DELETE_ZONE job — thực sự xóa trên DA ngay,
        // hard-delete trong DB sẽ do cleanup cron sau grace_period_days ngày
        try {
            $batchId = $this->queue->dispatch(
                $domain->id,
                'DELETE_ZONE',
                ['domain' => $domainName],
                5,
                'system',
                null
            );
        } catch (\RuntimeException $e) {
            logActivity("HVN DNS Manager: Cannot dispatch DELETE_ZONE for {$domainName} — " . $e->getMessage());
            return ['success' => false, 'error' => $e->getMessage()];
        }

        AuditTrail::create([
            'actor_type' => 'system',
            'actor_id' => $userId,
            'actor_name' => 'WHMCS AutoTerminate',
            'domain' => $domainName,
            'domain_id' => $domain->id,
            'action' => 'zone_terminate',
            'target_type' => 'zone',
            'context' => 'cron_provision',
            'ip_address' => $clientIp,
            'notes' => "Terminated. DELETE_ZONE batch_id: {$batchId}. Grace period {$graceDays} days.",
        ]);

        logActivity("HVN DNS Manager: DELETE_ZONE dispatched for {$domainName} (batch: {$batchId})");

        return ['success' => true, 'batch_id' => $batchId];
    }

    /**
     * Handle service suspension — mark domain as suspended (client cannot edit DNS).
     * Zone stays active on DA server (customers still resolve DNS).
     *
     * @param  string $domainName Domain name.
     * @param  int    $userId     WHMCS client ID.
     * @return array{success: bool}
     */
    public function handleSuspend(string $domainName, int $userId): array
    {
        $domain = Domain::where('domain', $domainName)->first();

        if (!$domain) {
            return ['success' => true]; // Nothing to suspend
        }

        $domain->update(['status' => 'suspended']);

        AuditTrail::create([
            'actor_type' => 'system',
            'actor_id' => $userId,
            'actor_name' => 'WHMCS AutoSuspend',
            'domain' => $domainName,
            'domain_id' => $domain->id,
            'action' => 'zone_suspend',
            'target_type' => 'zone',
            'context' => 'cron_provision',
            'ip_address' => '127.0.0.1',
        ]);

        logActivity("HVN DNS Manager: Domain suspended — {$domainName}");

        return ['success' => true];
    }

    /**
     * Handle service unsuspension — restore domain to active status.
     *
     * @param  string $domainName Domain name.
     * @param  int    $userId     WHMCS client ID.
     * @return array{success: bool}
     */
    public function handleUnsuspend(string $domainName, int $userId): array
    {
        $domain = Domain::where('domain', $domainName)->first();

        if (!$domain) {
            return ['success' => true];
        }

        $domain->update(['status' => 'active']);

        AuditTrail::create([
            'actor_type' => 'system',
            'actor_id' => $userId,
            'actor_name' => 'WHMCS AutoUnsuspend',
            'domain' => $domainName,
            'domain_id' => $domain->id,
            'action' => 'zone_unsuspend',
            'target_type' => 'zone',
            'context' => 'cron_provision',
            'ip_address' => '127.0.0.1',
        ]);

        logActivity("HVN DNS Manager: Domain unsuspended — {$domainName}");

        return ['success' => true];
    }

    // ─────────────────────────────────────────────────────────
    // Private helpers
    // ─────────────────────────────────────────────────────────

    /**
     * Build the CREATE_ZONE queue job payload.
     *
     * Uses the default template if available; otherwise, builds a minimal
     * payload with NS records and a placeholder A record.
     *
     * @param  string        $domainName
     * @param  Template|null $template
     * @return array
     */
    private function buildCreateZonePayload(string $domainName, ?Template $template): array
    {
        // Đọc từ Settings thay vì hardcode
        $ns1 = \HvnGroup\DnsManager\Helpers\SettingsHelper::get('default_nameserver_1', 'dns1.hvn.vn');
        $ns2 = \HvnGroup\DnsManager\Helpers\SettingsHelper::get('default_nameserver_2', 'dns2.hvn.vn');
        $ns3 = \HvnGroup\DnsManager\Helpers\SettingsHelper::get('default_nameserver_3', 'dns3.hvn.vn');
        $ns4 = \HvnGroup\DnsManager\Helpers\SettingsHelper::get('default_nameserver_4', '');
        $ns5 = \HvnGroup\DnsManager\Helpers\SettingsHelper::get('default_nameserver_5', '');

        $baseRecords = array_filter([
            $ns1 ? ['type' => 'NS', 'name' => '@', 'value' => $ns1, 'ttl' => 86400] : null,
            $ns2 ? ['type' => 'NS', 'name' => '@', 'value' => $ns2, 'ttl' => 86400] : null,
            $ns3 ? ['type' => 'NS', 'name' => '@', 'value' => $ns3, 'ttl' => 86400] : null,
            $ns4 ? ['type' => 'NS', 'name' => '@', 'value' => $ns4, 'ttl' => 86400] : null,
            $ns5 ? ['type' => 'NS', 'name' => '@', 'value' => $ns5, 'ttl' => 86400] : null,
        ]);
        $baseRecords = array_values($baseRecords);

        if ($template && !empty($template->records_data)) {
            // Merge template records (replace {{domain}} placeholders)
            $templateRecords = $this->applyTemplatePlaceholders(
                $template->records_data,
                $domainName
            );

            return [
                'template_id' => $template->id,
                'ns1' => $ns1,
                'ns2' => $ns2,
                'records' => array_merge($baseRecords, $templateRecords),
            ];
        }

        return [
            'template_id' => null,
            'ns1' => $ns1,
            'ns2' => $ns2,
            'records' => $baseRecords,
        ];
    }

    /**
     * Replace {{domain}} and {{ip}} placeholders in template records.
     *
     * @param  array  $records    Template records with placeholders.
     * @param  string $domainName Actual domain name.
     * @return array  Records with placeholders resolved.
     */
    private function applyTemplatePlaceholders(array $records, string $domainName): array
    {
        return array_map(function (array $record) use ($domainName) {
            $record['value'] = str_replace('{{domain}}', $domainName, $record['value'] ?? '');
            $record['name'] = str_replace('{{domain}}', $domainName, $record['name'] ?? '@');
            return $record;
        }, $records);
    }

    /**
     * Update nameservers in WHMCS via localAPI().
     *
     * Updates the tbldomains record if the service has an associated WHMCS domain.
     * This is best-effort: failure does NOT block provisioning.
     *
     * @param  int|null $serviceId WHMCS hosting service ID (tblhosting.id).
     * @param  string   $domainName Domain name for logging.
     * @return void
     */
    private function updateWhmcsNameservers(?int $serviceId, string $domainName): void
    {
        if (!$serviceId) {
            return;
        }

        try {
            // Look up domain registered in tbldomains with matching service domain name
            $result = localAPI('GetClientsProducts', ['serviceid' => $serviceId]);

            if (!empty($result['products']['product'][0]['domain'])) {
                $domainRecord = localAPI('GetClientsDomains', [
                    'domain' => $result['products']['product'][0]['domain'],
                ]);

                if (!empty($domainRecord['domains']['domain'][0]['id'])) {
                    $domainId = $domainRecord['domains']['domain'][0]['id'];

                    localAPI('UpdateDomain', [
                        'domainid'    => $domainId,
                        'nameserver1' => \HvnGroup\DnsManager\Helpers\SettingsHelper::get('default_nameserver_1', 'dns1.hvn.vn'),
                        'nameserver2' => \HvnGroup\DnsManager\Helpers\SettingsHelper::get('default_nameserver_2', 'dns2.hvn.vn'),
                        'nameserver3' => \HvnGroup\DnsManager\Helpers\SettingsHelper::get('default_nameserver_3', 'dns3.hvn.vn'),
                        'nameserver4' => \HvnGroup\DnsManager\Helpers\SettingsHelper::get('default_nameserver_4', ''),
                        'nameserver5' => \HvnGroup\DnsManager\Helpers\SettingsHelper::get('default_nameserver_5', ''),
                    ]);

                    logActivity("HVN DNS Manager: Updated WHMCS nameservers for {$domainName}");
                }
            }
        } catch (\Exception $e) {
            // Non-critical — log and continue
            logActivity("HVN DNS Manager: Could not update WHMCS nameservers for {$domainName}: " . $e->getMessage());
        }
    }
}
