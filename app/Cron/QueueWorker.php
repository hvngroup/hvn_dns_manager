<?php

namespace MJ\DnsManager\Cron;

defined("WHMCS") or die("Access Denied");

use MJ\DnsManager\Gateway\DAGateway;
use MJ\DnsManager\Models\Domain;
use MJ\DnsManager\Models\QueueJob;
use MJ\DnsManager\Models\Server;
use MJ\DnsManager\Models\SyncLog;

/**
 * QueueWorker — Processes pending DNS queue jobs and executes them via DAGateway.
 *
 * IMPORTANT: This class MUST only be called from the cron entry point.
 * It is the ONLY place in the entire codebase allowed to call DAGateway methods.
 *
 * Characteristics:
 *   - Processes jobs in priority ASC, created_at ASC order.
 *   - Row-level locking via SELECT FOR UPDATE SKIP LOCKED (no 2 workers process same job).
 *   - Exponential backoff on failure: 2min, 4min, 8min, 16min, then PERMANENTLY_FAILED.
 *   - Stale job recovery: SYNCING > 5min → reset to FAILED.
 *   - Hard time limit: exits after 55 seconds to avoid overlapping cron cycles.
 */
class QueueWorker
{
    private $startTime;
    private $maxRunTime = 55;
    private $maxJobsPerServer = 50;
    private $backoffMinutes = [1 => 2, 2 => 4, 3 => 8, 4 => 16];
    private $forceRun = false;

    public function __construct()
    {
        $this->startTime = microtime(true);
        $this->maxRunTime = \MJ\DnsManager\Helpers\SettingsHelper::getInt('worker_max_runtime', 55);
    }

    /**
     * Run the queue worker — called once per cron cycle.
     *
     * @return void
     */
    public function run(bool $force = false): void
    {
        $this->forceRun = $force;

        // Step 1: Recover stale SYNCING jobs (worker crashed mid-process)
        $this->recoverStaleJobs();

        // Step 2: Reset FAILED jobs đã đến hạn retry về PENDING
        $this->resetRetryableFailedJobs();

        // Step 3: Pick and process PENDING jobs
        $this->processJobs();

        try {
            $notif = new \MJ\DnsManager\Services\NotificationService();
            $notif->checkBacklogAlert();
        } catch (\Throwable $e) {
            logActivity('MJ DNS Manager [QueueWorker]: checkBacklogAlert exception — ' . $e->getMessage());
        }
    }



    /**
     * Process một job cụ thể theo batch_id — gọi ngay sau khi dispatch
     * (dùng bởi AcceptOrderHook để xử lý CREATE_ZONE tức thì, best-effort).
     *
     * Nếu DA server offline: job ở lại FAILED, AfterCronJob sẽ retry sau.
     *
     * @param  string $batchId UUID batch_id từ QueueManager::dispatch().
     * @return bool   True nếu job hoàn thành thành công.
     */
    public function runOnce(string $batchId): bool
    {
        $job = QueueJob::where('batch_id', $batchId)
            ->where('status', 'PENDING')
            ->first();

        if (!$job) {
            return false;
        }

        $server = Server::find($job->server_id);
        if (!$server) {
            return false;
        }

        $gateway = new DAGateway($server);
        $this->executeJob($job, $server, $gateway);

        $job->refresh();
        return $job->status === 'COMPLETE';
    }

    /**
     * Recover jobs stuck in SYNCING state for more than 5 minutes.
     *
     * @return void
     */
    private function recoverStaleJobs(): void
    {
        $staleSeconds = \MJ\DnsManager\Helpers\SettingsHelper::getInt('stale_lock_timeout', 300);
        $staleThreshold = date('Y-m-d H:i:s', strtotime('-' . $staleSeconds . ' seconds'));

        $staleJobs = QueueJob::where('status', 'SYNCING')
            ->where('locked_at', '<', $staleThreshold)
            ->get();

        foreach ($staleJobs as $job) {
            $job->update([
                'status' => 'FAILED',
                'error_message' => 'Worker timeout — stale job recovered by next cron cycle.',
                'locked_by' => null,
                'locked_at' => null,
            ]);
        }

        if ($staleJobs->count() > 0) {
            logActivity("MJ DNS Manager [QueueWorker]: Recovered {$staleJobs->count()} stale SYNCING jobs.");
        }
    }

    /**
     * Reset các job FAILED đã đến hạn retry về PENDING để worker xử lý lại.
     *
     * Điều kiện reset:
     *   - status = FAILED (không reset PERMANENTLY_FAILED — đã hết attempts)
     *   - attempts < max_attempts (còn lượt thử)
     *   - next_retry_at <= NOW hoặc null (đã đến giờ retry)
     *
     * @return void
     */
    private function resetRetryableFailedJobs(): void
    {
        $now = $this->nowStr();

        $query = \Illuminate\Database\Capsule\Manager::table('tbl_mj_dns_queue')
            ->where('status', 'FAILED')
            ->whereRaw('attempts < max_attempts');

        // Force mode (chạy thủ công): bỏ qua next_retry_at để test ngay lập tức
        // Production (cron thật): chỉ reset khi đã đến hạn retry
        if (!$this->forceRun) {
            $query->where(function ($q) use ($now) {
                $q->whereNull('next_retry_at')
                    ->orWhere('next_retry_at', '<=', $now);
            });
        }

        $count = $query->update([
            'status' => 'PENDING',
            'next_retry_at' => null,
            'locked_by' => null,
            'locked_at' => null,
        ]);

        if ($count > 0) {
            $mode = $this->forceRun ? ' [force]' : '';
            logActivity("MJ DNS Manager [QueueWorker]: Reset {$count} FAILED job(s) to PENDING for retry{$mode}.");
        }
    }


    /**
     * Query and process all eligible PENDING jobs.
     *
     * @return void
     */
    private function processJobs(): void
    {
        $serverIds = \Illuminate\Database\Capsule\Manager::table('tbl_mj_dns_servers')
            ->where('is_active', 1)
            ->orderBy('sort_order')
            ->pluck('id')
            ->toArray();

        foreach ($serverIds as $serverId) {
            if ($this->isTimeLimitReached()) {
                logActivity('MJ DNS Manager [QueueWorker]: Time limit reached, stopping.');
                break;
            }

            $server = Server::find($serverId);
            if (!$server) {
                continue;
            }

            // Skip servers in backoff — TRỪ KHI force mode
            if (!$this->forceRun && $server->backoff_until && $server->backoff_until > $this->nowStr()) {
                continue;
            }

            $this->processServerJobs($server);
        }
    }


    /**
     * Process pending jobs for a given server.
     *
     * @param  Server $server
     * @return void
     */

    private function processServerJobs(Server $server): void
    {
        $maxJobs = min($server->max_concurrent, $this->maxJobsPerServer);
        $now = $this->nowStr();
        // Lưu lại thời điểm bắt đầu batch. Nếu lỗi phát sinh >= thời điểm này,
        // tức là server vừa chết ngay trong chu kỳ hiện tại -> cần kích hoạt Rơ-le ngay.
        $batchStartedAt = $now;

        $jobs = \Illuminate\Database\Capsule\Manager::transaction(
            function () use ($server, $maxJobs, $now) {
                return QueueJob::where('status', 'PENDING')
                    ->where('server_id', $server->id)
                    ->where(function ($q) use ($now) {
                        $q->whereNull('next_retry_at')
                            ->orWhere('next_retry_at', '<=', $now);
                    })
                    ->orderBy('priority', 'asc')
                    ->orderBy('created_at', 'asc')
                    ->limit($maxJobs)
                    ->lockForUpdate()
                    ->get();
            }
        );

        if ($jobs->isEmpty()) {
            return;
        }

        $gateway = new DAGateway($server);

        foreach ($jobs as $job) {
            if ($this->isTimeLimitReached()) {
                break;
            }

            // Circuit Breaker MỚI: Nhận diện lỗi phát sinh TRONG CHÍNH batch này (last_error_at >= batchStartedAt).
            // Nếu phát hiện server ngỏm trong lúc nãy, LẬP TỨC ngắt mỏ server này, không phân biệt là auto cron hay ForceRun.
            // Flush phần job thặng dư sang FAILED để không làm mất Time Limit của server khỏe đang đợi đằng sau.
            if ($server->last_error_at && $server->last_error_at >= $batchStartedAt) {
                if ($server->backoff_until && $server->backoff_until > $this->nowStr()) {
                    logActivity("MJ DNS Manager [QueueWorker]: Server {$server->id} entered backoff mode during this batch. Flushing remaining PENDING jobs and moving to next server.");
                    $this->flushServerPendingJobs($server);
                    break;
                }
            }

            $this->executeJob($job, $server, $gateway);

            // Nạp lại trạng thái server mới nhất (nếu failJob vừa cập nhật last_error_at)
            $server->refresh();
        }
    }

    /**
     * Flush toàn bộ PENDING jobs còn lại của một server vào FAILED ngay lập tức
     * khi circuit breaker kích hoạt (server vào backoff).
     *
     * Không chạy từng job qua timeout — flush hàng loạt bằng 1 UPDATE.
     * Worker sẽ retry chúng trong chu kỳ cron tiếp theo sau khi server phục hồi.
     *
     * @param Server $server
     * @return void
     */
    private function flushServerPendingJobs(Server $server): void
    {
        $now = $this->nowStr();
        $backoffMinutes = 2; // Reset lại sau 2 phút — đợi server backoff tạm kết thúc

        $count = \Illuminate\Database\Capsule\Manager::table('tbl_mj_dns_queue')
            ->where('status', 'PENDING')
            ->where('server_id', $server->id)
            ->whereRaw('attempts < max_attempts')
            ->update([
                'status'       => 'FAILED',
                'error_message' => 'Server entered backoff — job deferred to next retry cycle.',
                'next_retry_at' => $this->nowAddMinutes($backoffMinutes),
                'locked_by'    => null,
                'locked_at'    => null,
            ]);

        // Jobs đã hết lượt retry — đánh dấu PERMANENTLY_FAILED
        \Illuminate\Database\Capsule\Manager::table('tbl_mj_dns_queue')
            ->where('status', 'PENDING')
            ->where('server_id', $server->id)
            ->whereRaw('attempts >= max_attempts')
            ->update([
                'status'        => 'PERMANENTLY_FAILED',
                'error_message' => 'Server entered backoff — max attempts exhausted.',
                'completed_at'  => $now,
                'locked_by'     => null,
                'locked_at'     => null,
            ]);

        if ($count > 0) {
            logActivity("MJ DNS Manager [QueueWorker]: Flushed {$count} PENDING jobs of server #{$server->id} to FAILED (next retry in {$backoffMinutes}min).");
        }
    }

    /**
     * Execute a single queue job against the DA server.
     *
     * @param  QueueJob  $job
     * @param  Server    $server
     * @param  DAGateway $gateway
     * @return void
     */
    private function executeJob(QueueJob $job, Server $server, DAGateway $gateway): void
    {
        $workerId = gethostname() . ':' . getmypid();

        $job->update([
            'status' => 'SYNCING',
            'locked_by' => $workerId,
            'locked_at' => $this->nowStr(),
            'started_at' => $this->nowStr(),
            'attempts' => $job->attempts + 1,
        ]);

        // ── QUAN TRỌNG: refresh để $job->attempts phản ánh giá trị mới nhất ──
        // failJob() dùng $job->attempts để check >= max_attempts
        // Nếu không refresh, object vẫn giữ giá trị cũ → không bao giờ PERMANENTLY_FAILED
        $job->refresh();

        $domain = Domain::find($job->domain_id);

        if (!$domain) {
            $this->failJob($job, $server, 'Domain record not found in tbl_mj_dns_domains.', 0, false);
            return;
        }

        $domainName = $domain->domain;
        $payload = is_array($job->payload) ? $job->payload : json_decode($job->payload, true) ?? [];
        $startMs = microtime(true);

        switch ($job->action) {
            case 'CREATE_ZONE':
                $response = $this->handleCreateZone($gateway, $domainName, $payload);
                break;
            case 'DELETE_ZONE':
                $response = $gateway->deleteZone($domainName);
                break;
            case 'ADD_RECORD':
                $response = $this->handleAddRecord($gateway, $domainName, $payload);
                break;
            case 'EDIT_RECORD':
                $response = $this->handleEditRecord($gateway, $domainName, $payload);
                break;
            case 'DELETE_RECORD':
                $response = $this->handleDeleteRecord($gateway, $domainName, $payload, $job);
                break;
            case 'CREATE_REDIRECT':
                $response = $this->handleCreateRedirect($gateway, $domainName, $payload);
                break;
            case 'DELETE_REDIRECT':
                $response = $this->handleDeleteRedirect($gateway, $domainName, $payload, $job);
                break;
            case 'RENEW_SSL':
                $response = $this->handleRenewSsl($gateway, $domainName);
                break;
            case 'ENABLE_DNSSEC':
                $response = $this->handleEnableDnssec($gateway, $domainName, $domain);
                break;
            case 'DISABLE_DNSSEC':
                $response = $this->handleDisableDnssec($gateway, $domainName, $domain);
                break;
            case 'FETCH_DS_RECORDS':
                $response = $this->handleFetchDsRecords($gateway, $domainName, $domain);
                break;
            case 'APPLY_TEMPLATE':
                $response = $this->handleApplyTemplate($gateway, $domainName, $payload);
                break;
            case 'SYNC_ZONE':
                // Pull toàn bộ zone từ DA về DB (đồng bộ ngược). Worker chạy nền,
                // KHÔNG block request client (async-first).
                $response = $gateway->getZone($domainName);
                if ($response->isSuccess()) {
                    $this->pullZoneRecords($gateway, $domainName, $response);
                }
                break;
            case 'CREATE_EMAIL_FWD':
                $response = $this->handleCreateEmailFwd($gateway, $domainName, $payload);
                break;
            case 'DELETE_EMAIL_FWD':
                $response = $this->handleDeleteEmailFwd($gateway, $domainName, $payload);
                break;
            default:
                $response = null;
                break;
        }

        $durationMs = (int) ((microtime(true) - $startMs) * 1000);

        if ($response === null) {
            $this->failJob($job, $server, "Unsupported action: {$job->action}", $durationMs, false);
            return;
        }

        SyncLog::create([
            'queue_id' => $job->id,
            'server_id' => $server->id,
            'http_method' => 'POST',
            'http_status' => $response->httpStatus,
            'response_body' => json_encode($response->data),
            'duration_ms' => $response->durationMs,
            'success' => $response->isSuccess() ? 1 : 0,
            'error_type' => $response->errorCode,
        ]);

        if ($response->isSuccess()) {
            $this->completeJob($job, $server, $domain, $durationMs);
        } else {
            $this->failJob($job, $server, $response->errorMessage ?? 'DA API error', $durationMs, true);
        }
    }

    /**
     * Handle EDIT_RECORD action.
     *
     * Pre-flight: verify old_record.value matches reality on the target server.
     * When a job is reassigned to a fallback server via tryReassignToFallback(),
     * the old_record.value may not match. DA's action=edit with mismatched arecs0
     * will CREATE a new record instead of editing → duplicate records.
     *
     * @param  DAGateway $gateway
     * @param  string    $domainName
     * @param  array     $payload
     * @return \MJ\DnsManager\Gateway\DAResponse
     */
    private function handleEditRecord(DAGateway $gateway, string $domainName, array $payload): \MJ\DnsManager\Gateway\DAResponse
    {
        $payload = $this->correctOldRecordForServer($gateway, $domainName, $payload);

        return $gateway->editRecord($domainName, $payload);
    }

    /**
     * Verify that old_record.value in payload matches the actual record on the DA server.
     * If not, correct it to prevent DA from creating duplicates instead of editing.
     *
     * @param  DAGateway $gateway
     * @param  string    $domainName
     * @param  array     $payload
     * @return array     Corrected payload
     */
    private function correctOldRecordForServer(DAGateway $gateway, string $domainName, array $payload): array
    {
        $old = $payload['old_record'] ?? [];
        if (empty($old)) {
            return $payload;
        }

        try {
            $zoneResponse = $gateway->getZone($domainName);
            if (!$zoneResponse->isSuccess() || !isset($zoneResponse->data['records'])) {
                return $payload;
            }

            $targetName = $old['name'] ?? '';
            $targetType = strtoupper($old['type'] ?? '');
            $targetValue = $old['value'] ?? '';
            $normalizedTargetName = ($targetName === '@') ? '' : $targetName;

            // Collect all records matching name + type
            $nameTypeMatches = [];

            foreach ($zoneResponse->data['records'] as $rec) {
                $recType = strtoupper($rec['type'] ?? '');
                if ($recType !== $targetType) {
                    continue;
                }

                $recName = $this->normalizeDaRecordName($rec['name'] ?? '', $domainName);
                if ($recName !== $normalizedTargetName) {
                    continue;
                }

                $nameTypeMatches[] = $rec;
            }

            if (empty($nameTypeMatches)) {
                // Record doesn't exist on this server at all — let editRecord handle it
                return $payload;
            }

            // Check if exact match exists (old_record.value matches a record on server)
            foreach ($nameTypeMatches as $match) {
                $serverValue = $this->normalizeDaRecordValue($match['value'] ?? '', $targetType);
                if ($serverValue === $targetValue) {
                    return $payload; // Exact match — no correction needed
                }
            }

            // No exact match → old_record.value is stale for this server
            if (count($nameTypeMatches) === 1) {
                // Exactly one record with same name+type → safe to auto-correct
                $correctValue = $this->normalizeDaRecordValue($nameTypeMatches[0]['value'] ?? '', $targetType);
                $payload['old_record']['value'] = $correctValue;

                logActivity("MJ DNS Manager [QueueWorker]: EDIT_RECORD — auto-corrected old_record.value from '{$targetValue}' to '{$correctValue}' for server match.");
            } else {
                // Multiple records with same name+type, none match old value
                $cnt = count($nameTypeMatches);
                logActivity("MJ DNS Manager [QueueWorker]: EDIT_RECORD — WARNING: {$cnt} records match name='{$targetName}' type='{$targetType}' but none match old value '{$targetValue}'. Proceeding with original payload.");
            }
        } catch (\Throwable $e) {
            logActivity('MJ DNS Manager [QueueWorker]: correctOldRecordForServer failed — ' . $e->getMessage());
        }

        return $payload;
    }

    /**
     * Normalize a DA FQDN record name to short WHMCS format.
     * E.g., "ftp.example.com." → "ftp", "example.com." → ""
     *
     * @param  string $daName     Full name from DA API
     * @param  string $domainName Domain name (e.g., "example.com")
     * @return string             Short name (e.g., "ftp", "")
     */
    private function normalizeDaRecordName(string $daName, string $domainName): string
    {
        if ($daName === $domainName . '.') {
            return '';
        }

        $suffix = '.' . $domainName . '.';
        if (substr($daName, -strlen($suffix)) === $suffix) {
            return substr($daName, 0, -strlen($suffix));
        }

        return rtrim($daName, '.');
    }

    /**
     * Convert a DA-format record value back to WHMCS format.
     * Strips trailing dots, removes TXT quotes, extracts MX/SRV target.
     *
     * @param  string $daValue DA-format value
     * @param  string $type    Record type (A, CNAME, MX, TXT, SRV, etc.)
     * @return string          WHMCS-format value
     */
    private function normalizeDaRecordValue(string $daValue, string $type): string
    {
        switch ($type) {
            case 'CNAME':
            case 'NS':
                return rtrim($daValue, '.');

            case 'MX':
                // DA stores "priority target." — WHMCS stores just "target"
                $parts = explode(' ', $daValue, 2);
                if (count($parts) === 2 && is_numeric($parts[0])) {
                    return rtrim(trim($parts[1]), '.');
                }
                return rtrim($daValue, '.');

            case 'TXT':
                // DA stores with surrounding quotes — WHMCS stores without
                $val = trim($daValue, '"');
                return stripslashes($val);

            case 'SRV':
                // DA stores "weight port target." — WHMCS stores just "target"
                $parts = explode(' ', $daValue, 3);
                if (count($parts) === 3) {
                    return rtrim(trim($parts[2]), '.');
                }
                return rtrim($daValue, '.');

            default:
                // A, AAAA, CAA, etc. — no conversion needed
                return $daValue;
        }
    }

    /**
     * Handle DELETE_RECORD action.
     *
     * @param  DAGateway $gateway
     * @param  string    $domainName
     * @param  array     $payload
     * @param  QueueJob  $job
     * @return \MJ\DnsManager\Gateway\DAResponse
     */
    private function handleDeleteRecord(DAGateway $gateway, string $domainName, array $payload, QueueJob $job): \MJ\DnsManager\Gateway\DAResponse
    {
        $response = $gateway->deleteRecord($domainName, $payload);

        if ($response->isSuccess() && isset($payload['record_id'])) {
            try {
                \MJ\DnsManager\Models\Record::where('id', (int) $payload['record_id'])
                    ->where('pending_delete', 1)
                    ->delete();
            } catch (\Exception $e) {
                logActivity("MJ DNS Manager [QueueWorker]: Warning — could not hard-delete record #{$payload['record_id']} from DB after DA delete. " . $e->getMessage());
            }
        }

        return $response;
    }

    /**
     * Handle CREATE_ZONE action.
     *
     * Dùng CMD_API_DOMAIN (tạo domain account) thay vì CMD_API_DNS_ADMIN (tạo zone thuần).
     * DA tự động tạo zone DNS kèm theo khi tạo domain account.
     * Sau khi tạo xong → pull zone records về WHMCS DB.
     *
     * @param  DAGateway $gateway
     * @param  string    $domainName
     * @param  array     $payload
     * @return \MJ\DnsManager\Gateway\DAResponse
     */
    private function handleCreateZone(DAGateway $gateway, string $domainName, array $payload): \MJ\DnsManager\Gateway\DAResponse
    {
        // Gọi CMD_API_DOMAIN action=create — DA tạo domain + zone DNS cùng lúc
        $domainResponse = $gateway->createDomain($domainName, $payload);

        if (!$domainResponse->isSuccess()) {
            return $domainResponse;
        }

        // Pull records từ DA về WHMCS sau khi tạo xong (best-effort)
        $this->pullZoneRecords($gateway, $domainName);

        return $domainResponse;
    }

    /**
     * Handle ADD_RECORD action.
     *
     * @param  DAGateway $gateway
     * @param  string    $domainName
     * @param  array     $payload
     * @return \MJ\DnsManager\Gateway\DAResponse
     */
    private function handleAddRecord(DAGateway $gateway, string $domainName, array $payload): \MJ\DnsManager\Gateway\DAResponse
    {
        return $gateway->addRecord($domainName, $payload);
    }

    /**
     * Mark a job as COMPLETE.
     *
     * @param  QueueJob $job
     * @param  Server   $server
     * @param  Domain   $domain
     * @param  int      $durationMs
     * @return void
     */
    private function completeJob(QueueJob $job, Server $server, Domain $domain, int $durationMs): void
    {
        $job->update([
            'status' => 'COMPLETE',
            'completed_at' => $this->nowStr(),
            'locked_by' => null,
            'locked_at' => null,
            'error_message' => null,
        ]);

        if ($job->action === 'CREATE_ZONE') {
            $domain->update([
                'provisioned_at' => $this->nowStr(),
                'ssl_status'     => 'pending',
            ]);

            // Notify client khi zone DNS được khởi tạo thành công
            if ($job->actor_type === 'client' && (int) $job->actor_id > 0) {
                try {
                    $notif = new \MJ\DnsManager\Services\NotificationService();
                    $notif->notifyClientZoneCreated(
                        (int) $job->actor_id,
                        $domain->domain
                    );
                } catch (\Exception $e) {
                    logActivity('MJ DNS Manager [QueueWorker]: notifyClientZoneCreated exception — ' . $e->getMessage());
                }
            }
        }

        if ($server->backoff_count > 0) {
            $server->update([
                'backoff_count' => 0,
                'backoff_until' => null,
                'last_success_at' => $this->nowStr(),
                'last_error_msg' => null,
            ]);
        } else {
            $server->update(['last_success_at' => $this->nowStr()]);
        }

        // ── Client email notification on record change ────────────────────
        $dnsActions = array('ADD_RECORD', 'EDIT_RECORD', 'DELETE_RECORD');
        if (in_array($job->action, $dnsActions, true) && $job->actor_type === 'client' && $job->actor_id > 0) {
            try {
                $payload     = is_array($job->payload) ? $job->payload : (array) json_decode((string) $job->payload, true);
                $recordType  = strtoupper((string) (isset($payload['type']) ? $payload['type'] : (isset($payload['record_type']) ? $payload['record_type'] : '')));
                $recordName  = (string) (isset($payload['name']) ? $payload['name'] : (isset($payload['record_name']) ? $payload['record_name'] : '@'));
                $recordValue = (string) (isset($payload['value']) ? $payload['value'] : (isset($payload['data']) ? $payload['data'] : ''));

                if ($job->action === 'EDIT_RECORD') {
                    $newRec      = isset($payload['new_record']) ? $payload['new_record'] : array();
                    $recordType  = strtoupper((string) (isset($newRec['type'])  ? $newRec['type']  : $recordType));
                    $recordName  = (string) (isset($newRec['name'])  ? $newRec['name']  : $recordName);
                    $recordValue = (string) (isset($newRec['value']) ? $newRec['value'] : $recordValue);
                }

                if ($recordType !== '') {
                    $notif = new \MJ\DnsManager\Services\NotificationService();
                    $notif->notifyClientRecordChanged(
                        (int) $job->actor_id,
                        $domain->domain,
                        $job->action,
                        $recordType,
                        $recordName,
                        $recordValue
                    );
                }
            } catch (\Exception $e) {
                logActivity('MJ DNS Manager [QueueWorker]: client email exception — ' . $e->getMessage());
            }
        }
    }

    /**
     * Mark a job as FAILED (or PERMANENTLY_FAILED after max attempts).
     * Nếu PERMANENTLY_FAILED do server lỗi nhiều lần → tự reassign sang fallback.
     */
    private function failJob(QueueJob $job, Server $server, string $errorMessage, int $durationMs, bool $retryable): void
    {
        $attempts = $job->attempts;

        $serverBackoffMap = [2 => 2, 3 => 4, 4 => 8, 5 => 16, 6 => 32];
        $newBackoffCount = $server->backoff_count + 1;
        $backoffUntil = isset($serverBackoffMap[$newBackoffCount])
            ? $this->nowAddMinutes($serverBackoffMap[$newBackoffCount])
            : ($newBackoffCount > 6 ? $this->nowAddMinutes(32) : null);

        $server->update([
            'last_error_at' => $this->nowStr(),
            'last_error_msg' => substr($errorMessage, 0, 255),
            'backoff_count' => $newBackoffCount,
            'backoff_until' => $backoffUntil,
        ]);
        $server->refresh();

        $isConnectionError = $this->isConnectionError($errorMessage);

        // true = đã xử lý alert riêng trong nhánh này, KHÔNG gọi triggerCheck() ở cuối
        $skipTriggerCheck = false;

        if (!$retryable || $attempts >= $job->max_attempts) {
            // ── Hết attempts → PERMANENTLY_FAILED ────────────────────────────
            $job->update([
                'status' => 'PERMANENTLY_FAILED',
                'error_message' => $errorMessage,
                'completed_at' => $this->nowStr(),
                'locked_by' => null,
                'locked_at' => null,
            ]);

            // Admin alert (Telegram + Email) via NotificationService
            try {
                $domainObj  = \MJ\DnsManager\Models\Domain::find($job->domain_id);
                $domainName = $domainObj ? $domainObj->domain : 'N/A (domain_id=' . $job->domain_id . ')';
                $payload    = is_array($job->payload) ? $job->payload : (array) json_decode((string) $job->payload, true);
                $recordType = strtoupper((string) (isset($payload['type']) ? $payload['type'] : (isset($payload['record_type']) ? $payload['record_type'] : '')));
                $recordName = (string) (isset($payload['name']) ? $payload['name'] : (isset($payload['record_name']) ? $payload['record_name'] : ''));

                $notif = new \MJ\DnsManager\Services\NotificationService();
                $notif->notifyJobPermanentlyFailed(
                    $job->id,
                    $job->action,
                    $attempts,
                    $job->max_attempts,
                    $errorMessage,
                    $server->hostname,
                    $domainName,
                    $recordType,
                    $recordName
                );
            } catch (\Exception $e) {
                logActivity('MJ DNS Manager [QueueWorker]: admin fail notification exception — ' . $e->getMessage());
            }
        } elseif ($isConnectionError) {
            // ── Lỗi kết nối → instant failover ───────────────────────────────
            $job->update([
                'status' => 'PERMANENTLY_FAILED',
                'error_message' => $errorMessage . ' [Network / Connection failed]',
                'completed_at' => $this->nowStr(),
                'locked_by' => null,
                'locked_at' => null,
            ]);

            $server->update([
                'backoff_until' => $this->nowAddMinutes(15),
                'status_message' => mb_substr('Network / Connection failed: ' . $errorMessage, 0, 250),
            ]);

            // Admin alert via NotificationService
            try {
                $domainObj  = \MJ\DnsManager\Models\Domain::find($job->domain_id);
                $domainName = $domainObj ? $domainObj->domain : 'N/A (domain_id=' . $job->domain_id . ')';
                $payload    = is_array($job->payload) ? $job->payload : (array) json_decode((string) $job->payload, true);
                $recordType = strtoupper((string) (isset($payload['type']) ? $payload['type'] : (isset($payload['record_type']) ? $payload['record_type'] : '')));
                $recordName = (string) (isset($payload['name']) ? $payload['name'] : (isset($payload['record_name']) ? $payload['record_name'] : ''));

                $notif = new \MJ\DnsManager\Services\NotificationService();
                $notif->notifyJobPermanentlyFailed(
                    $job->id,
                    $job->action,
                    $attempts,
                    $job->max_attempts,
                    $errorMessage . ' [Network / Connection failed]',
                    $server->hostname,
                    $domainName,
                    $recordType,
                    $recordName
                );
            } catch (\Exception $e) {
                logActivity('MJ DNS Manager [QueueWorker]: connection fail notification exception — ' . $e->getMessage());
            }
        } else {
            // ── Lỗi logic → retry bình thường ────────────────────────────────
            $backoffMinutes = $this->backoffMinutes[$attempts] ?? 16;
            $job->update([
                'status' => 'FAILED',
                'error_message' => $errorMessage,
                'next_retry_at' => $this->nowAddMinutes($backoffMinutes),
                'locked_by' => null,
                'locked_at' => null,
            ]);
        }

        logActivity("MJ DNS Manager [QueueWorker]: Job #{$job->id} ({$job->action}) failed (attempt {$attempts}/{$job->max_attempts}) — {$errorMessage}");

        if (!$skipTriggerCheck) {
            try {
                $notif = new \MJ\DnsManager\Services\NotificationService();
                $notif->triggerCheck($server->id);
            } catch (\Throwable $e) {
                logActivity('MJ DNS Manager [NotificationService]: triggerCheck exception — ' . $e->getMessage());
            }
        }
    }

    /**
     * Pull DNS records từ DA về WHMCS sau khi CREATE_ZONE thành công.
     * Logic giống RecordController::syncZone() — best-effort, không throw.
     *
     * @param  DAGateway $gateway
     * @param  string    $domainName
     * @return void
     */
    private function pullZoneRecords(DAGateway $gateway, string $domainName, $response = null): void
    {
        try {
            if ($response === null) {
                $response = $gateway->getZone($domainName);
            }

            if (!$response->isSuccess() || !isset($response->data['records'])) {
                logActivity("MJ DNS Manager [QueueWorker]: pullZoneRecords failed for '{$domainName}' — " . ($response->errorMessage ?? 'No records returned'));
                return;
            }

            $domain = Domain::where('domain', $domainName)->first();
            if (!$domain) {
                return;
            }

            $allowedTypes = ['A', 'AAAA', 'CNAME', 'MX', 'TXT', 'NS', 'SOA', 'SRV', 'CAA'];
            $newRecordsData = [];

            foreach ($response->data['records'] as $rec) {
                $type = strtoupper((string) ($rec['type'] ?? ''));
                if (!in_array($type, $allowedTypes)) {
                    continue;
                }

                $name = (string) ($rec['name'] ?? '');
                if ($name === $domainName . '.') {
                    $name = '@';
                } else {
                    $name = str_replace('.' . $domainName . '.', '', $name);
                }

                $value = (string) ($rec['value'] ?? '');
                $ttl = (int) ($rec['ttl'] ?? 3600);
                $priority = null;
                $weight = null;
                $port = null;

                if ($type === 'MX') {
                    $parts = explode(' ', $value, 2);
                    if (count($parts) === 2) {
                        $priority = (int) $parts[0];
                        $value = trim($parts[1]);
                    }
                } elseif ($type === 'SRV') {
                    $parts = explode(' ', $value, 3);
                    if (count($parts) === 3) {
                        $weight = (int) $parts[0];
                        $port = (int) $parts[1];
                        $value = trim($parts[2]);
                    }
                    if (isset($rec['priority'])) {
                        $priority = (int) $rec['priority'];
                    }
                }

                $newRecordsData[] = [
                    'domain_id' => $domain->id,
                    'type' => $type,
                    'name' => $name,
                    'value' => $value,
                    'ttl' => $ttl,
                    'priority' => $priority,
                    'weight' => $weight,
                    'port' => $port,
                    'is_system' => in_array($type, ['NS', 'SOA']) ? 1 : 0,
                    'is_locked' => 0,
                    'pending_delete' => 0,
                    'created_at' => date('Y-m-d H:i:s'),
                    'updated_at' => date('Y-m-d H:i:s'),
                ];
            }

            \WHMCS\Database\Capsule::beginTransaction();
            \MJ\DnsManager\Models\Record::where('domain_id', $domain->id)
                ->where('is_locked', 0)
                ->delete();
            if (!empty($newRecordsData)) {
                \MJ\DnsManager\Models\Record::insert($newRecordsData);
            }
            \WHMCS\Database\Capsule::commit();

            logActivity("MJ DNS Manager [QueueWorker]: Pulled " . count($newRecordsData) . " records for '{$domainName}' after CREATE_ZONE.");
        } catch (\Throwable $e) {
            if (\WHMCS\Database\Capsule::connection()->transactionLevel() > 0) {
                \WHMCS\Database\Capsule::rollBack();
            }
            logActivity("MJ DNS Manager [QueueWorker]: pullZoneRecords exception for '{$domainName}' — " . $e->getMessage());
            // Không throw — CREATE_ZONE vẫn được tính là COMPLETE
        }
    }

    /**
     * Handle CREATE_REDIRECT action.
     */
    private function handleCreateRedirect(DAGateway $gateway, string $domainName, array $payload): \MJ\DnsManager\Gateway\DAResponse
    {
        return $gateway->createRedirect(
            $domainName,
            $payload['source_path'] ?? '/',
            $payload['destination_url'] ?? '',
            $payload['type'] ?? '301'
        );
    }

    /**
     * Handle DELETE_REDIRECT action.
     * Sau khi DA xác nhận xóa → hard delete trong DB.
     */
    private function handleDeleteRedirect(DAGateway $gateway, string $domainName, array $payload, QueueJob $job): \MJ\DnsManager\Gateway\DAResponse
    {
        $response = $gateway->deleteRedirect(
            $domainName,
            $payload['source_path'] ?? '/'
        );

        if ($response->isSuccess() && isset($payload['redirect_id'])) {
            try {
                \MJ\DnsManager\Models\Redirect::where('id', (int) $payload['redirect_id'])
                    ->delete();
            } catch (\Exception $e) {
                logActivity("MJ DNS Manager [QueueWorker]: Warning — could not hard-delete redirect #{$payload['redirect_id']} from DB after DA delete. " . $e->getMessage());
            }
        }

        return $response;
    }

    /**
     * Generate UUID v4 — dùng nội bộ trong QueueWorker
     * Copy từ QueueManager vì QueueWorker không inject QueueManager.
     *
     * @return string
     */
    private function generateUuid(): string
    {
        if (class_exists(\Ramsey\Uuid\Uuid::class)) {
            return \Ramsey\Uuid\Uuid::uuid4()->toString();
        }

        return sprintf(
            '%04x%04x-%04x-%04x-%04x-%04x%04x%04x',
            mt_rand(0, 0xffff),
            mt_rand(0, 0xffff),
            mt_rand(0, 0xffff),
            mt_rand(0, 0x0fff) | 0x4000,
            mt_rand(0, 0x3fff) | 0x8000,
            mt_rand(0, 0xffff),
            mt_rand(0, 0xffff),
            mt_rand(0, 0xffff)
        );
    }

    /**
     * Handle RENEW_SSL action.
     *
     * Gọi DA API để trigger gia hạn Let's Encrypt cert.
     * Sau khi job COMPLETE, SslChecker sẽ tự sync ssl_status
     * từ pending → active ở chu kỳ cron tiếp theo.
     *
     * @param  DAGateway $gateway
     * @param  string    $domainName
     * @return \MJ\DnsManager\Gateway\DAResponse
     */
    private function handleRenewSsl(DAGateway $gateway, string $domainName): \MJ\DnsManager\Gateway\DAResponse
    {
        return $gateway->renewSsl($domainName);
    }

    /**
     * Handle ENABLE_DNSSEC action.
     * Sau khi DA enable thành công → tự dispatch thêm job FETCH_DS_RECORDS
     * để lấy DS Record về lưu vào DB cho client xem.
     */
    private function handleEnableDnssec(
        \MJ\DnsManager\Gateway\DAGateway $gateway,
        string $domainName,
        \MJ\DnsManager\Models\Domain $domain
    ): \MJ\DnsManager\Gateway\DAResponse {
        $response = $gateway->enableDnssec($domainName);

        if ($response->isSuccess()) {
            // Cập nhật trạng thái is_enabled = 1 vào DB ngay
            \MJ\DnsManager\Models\Dnssec::updateOrCreate(
                array('domain_id' => $domain->id),
                array('is_enabled' => 1)
            );

            // Dispatch thêm job FETCH_DS_RECORDS để lấy DS Record về
            try {
                $server = \MJ\DnsManager\Models\Server::where('role', 'primary')
                    ->where('is_active', 1)
                    ->first();
                if ($server) {
                    \MJ\DnsManager\Models\QueueJob::create(array(
                        'batch_id'    => $this->generateUuid(),
                        'domain_id'   => $domain->id,
                        'server_id'   => $server->id,
                        'action'      => 'FETCH_DS_RECORDS',
                        'payload'     => json_encode(array('domain' => $domainName)),
                        'status'      => 'PENDING',
                        'priority'    => 1,
                        'attempts'    => 0,
                        'max_attempts' => 3,
                        'actor_type'  => 'system',
                        'actor_id'    => null,
                        'scheduled_at' => date('Y-m-d H:i:s', strtotime('+30 seconds')),
                        'created_at'  => date('Y-m-d H:i:s'),
                    ));
                }
            } catch (\Throwable $e) {
                logActivity('MJ DNS Manager [QueueWorker]: ENABLE_DNSSEC — could not dispatch FETCH_DS_RECORDS: ' . $e->getMessage());
            }
        }

        return $response;
    }

    /**
     * Handle DISABLE_DNSSEC action.
     * Sau khi DA disable thành công → cập nhật is_enabled = 0 trong DB.
     */
    private function handleDisableDnssec(
        \MJ\DnsManager\Gateway\DAGateway $gateway,
        string $domainName,
        \MJ\DnsManager\Models\Domain $domain
    ): \MJ\DnsManager\Gateway\DAResponse {
        $response = $gateway->disableDnssec($domainName);

        if ($response->isSuccess()) {
            \MJ\DnsManager\Models\Dnssec::where('domain_id', $domain->id)
                ->update(array(
                    'is_enabled'  => 0,
                    'key_tag'     => null,
                    'algorithm'   => null,
                    'digest_type' => null,
                    'digest'      => null,
                    'ds_record_raw' => null,
                ));
        }

        return $response;
    }

    /**
     * Handle FETCH_DS_RECORDS action.
     * Lấy DS Record từ DA sau khi enable DNSSEC thành công
     * → lưu vào tbl_mj_dns_dnssec để client xem và copy sang Registrar.
     */
    private function handleFetchDsRecords(
        \MJ\DnsManager\Gateway\DAGateway $gateway,
        string $domainName,
        \MJ\DnsManager\Models\Domain $domain
    ): \MJ\DnsManager\Gateway\DAResponse {
        $response = $gateway->getDsRecords($domainName);

        if ($response->isSuccess()) {
            $data = $response->data;
            \MJ\DnsManager\Models\Dnssec::updateOrCreate(
                array('domain_id' => $domain->id),
                array(
                    'is_enabled'    => 1,
                    'key_tag'       => $data['key_tag'] ?? null,
                    'algorithm'     => $data['algorithm'] ?? null,
                    'digest_type'   => $data['digest_type'] ?? null,
                    'digest'        => $data['digest'] ?? null,
                    'ds_record_raw' => $data['ds_record'] ?? null,
                    'last_signed_at' => date('Y-m-d H:i:s'),
                )
            );
        }

        return $response;
    }

    /**
     * Check if the worker has exceeded its maximum allowed run time.
     *
     * @return bool
     */
    private function isTimeLimitReached(): bool
    {
        return (microtime(true) - $this->startTime) >= $this->maxRunTime;
    }

    /**
     * Trả về datetime string hiện tại — thay thế helper now() của Laravel
     * để QueueWorker hoạt động cả trong cron lẫn AJAX context (PHP 7).
     *
     * @return string Y-m-d H:i:s
     */
    private function nowStr()
    {
        return date('Y-m-d H:i:s');
    }

    /**
     * Trả về datetime string cộng thêm N phút — thay thế now()->addMinutes().
     *
     * @param  int    $minutes
     * @return string Y-m-d H:i:s
     */
    private function nowAddMinutes($minutes)
    {
        return date('Y-m-d H:i:s', strtotime('+' . (int) $minutes . ' minutes'));
    }

    /**
     * Kiểm tra lỗi có phải do kết nối mạng/server không tới được không.
     * Lỗi kết nối → có thể failover sang server khác ngay.
     * Lỗi logic (auth, conflict) → đổi server cũng không giải quyết được.
     *
     * @param  string $errorMessage
     * @return bool
     */
    private function isConnectionError(string $errorMessage): bool
    {
        $connectionErrors = [
            'cURL error 28',          // Timeout
            'cURL error 7',           // Connection refused
            'cURL error 6',           // Could not resolve host
            'cURL error 35',          // SSL connect error
            'connection_failed',      // DAGateway error code
            'Cannot connect',
            'Cannot reach server',
            'Failed to connect',
            'Connection timed out',
            'timed out',
        ];

        foreach ($connectionErrors as $pattern) {
            if (stripos($errorMessage, $pattern) !== false) {
                return true;
            }
        }

        return false;
    }

    /**
     * Handle APPLY_TEMPLATE action.
     *
     * Flow:
     *   1. Lấy zone hiện tại từ DA (getZone)
     *   2. Xóa sạch tất cả records hiện tại trên DA (trừ NS, SOA)
     *   3. Add từng record mới từ payload lên DA
     *
     * Idempotent: nếu job retry, bước 1-2 sẽ xóa lại đúng trạng thái
     * trước khi add lại — không tạo duplicate.
     *
     * @param  DAGateway $gateway
     * @param  string    $domainName
     * @param  array     $payload    Chứa key 'records' — array records cần add lên DA
     * @return \MJ\DnsManager\Gateway\DAResponse
     */
    private function handleApplyTemplate(
        \MJ\DnsManager\Gateway\DAGateway $gateway,
        $domainName,
        array $payload
    ) {
        $records = isset($payload['records']) && is_array($payload['records'])
            ? $payload['records']
            : array();

        if (empty($records)) {
            return \MJ\DnsManager\Gateway\DAResponse::fail(
                'empty_template_payload',
                'APPLY_TEMPLATE payload không có records.',
                array(),
                null,
                0
            );
        }

        // ── Bước 1: Lấy zone hiện tại từ DA ─────────────────────────────────
        $zoneResponse = $gateway->getZone($domainName);

        if ($zoneResponse->isSuccess() && isset($zoneResponse->data['records'])) {
            $daRecords = $zoneResponse->data['records'];

            // ── Bước 2: Xóa sạch records hiện tại trên DA (trừ NS và SOA) ───
            $protectedTypes = array('NS', 'SOA');

            foreach ($daRecords as $rec) {
                $recType = strtoupper($rec['type'] ?? '');
                if (in_array($recType, $protectedTypes)) {
                    continue;
                }

                // Build payload cho deleteRecord
                $recName  = $rec['name'] ?? '';
                // Chuẩn hoá tên về dạng ngắn (bỏ FQDN suffix)
                $suffix = '.' . $domainName . '.';
                if ($recName === $domainName . '.') {
                    $recName = '';
                } elseif (substr($recName, -strlen($suffix)) === $suffix) {
                    $recName = substr($recName, 0, -strlen($suffix));
                } else {
                    $recName = rtrim($recName, '.');
                }

                $recValue = $rec['value'] ?? '';
                // Chuẩn hoá value về dạng WHMCS để deleteRecord nhận đúng
                switch ($recType) {
                    case 'CNAME':
                    case 'NS':
                        $recValue = rtrim($recValue, '.');
                        break;
                    case 'MX':
                        $parts = explode(' ', $recValue, 2);
                        if (count($parts) === 2 && is_numeric($parts[0])) {
                            $recValue = rtrim(trim($parts[1]), '.');
                        }
                        break;
                    case 'TXT':
                        $recValue = trim($recValue, '"');
                        $recValue = stripslashes($recValue);
                        break;
                    case 'SRV':
                        $parts = explode(' ', $recValue, 3);
                        if (count($parts) === 3) {
                            $recValue = rtrim(trim($parts[2]), '.');
                        }
                        break;
                }

                // Gọi deleteRecord — bỏ qua lỗi "not found" (idempotent)
                $gateway->deleteRecord($domainName, array(
                    'type'     => $recType,
                    'name'     => $recName,
                    'value'    => $recValue,
                    'priority' => 0,
                    'weight'   => 0,
                    'port'     => 0,
                ));
                // Không check response từng record vì deleteRecord đã xử lý idempotent
            }
        }
        // Nếu getZone fail (zone chưa tồn tại trên server) — bỏ qua bước xóa,
        // tiến thẳng sang add records

        // ── Bước 3: Add từng record mới lên DA ───────────────────────────────
        $lastResponse = null;
        $addErrors    = array();

        foreach ($records as $rec) {
            $addResponse = $gateway->addRecord($domainName, array(
                'type'     => $rec['type']     ?? 'A',
                'name'     => $rec['name']     ?? '',
                'value'    => $rec['value']    ?? '',
                'ttl'      => $rec['ttl']      ?? 3600,
                'priority' => $rec['priority'] ?? null,
                'weight'   => $rec['weight']   ?? null,
                'port'     => $rec['port']     ?? null,
            ));

            $lastResponse = $addResponse;

            if (!$addResponse->isSuccess()) {
                $addErrors[] = ($rec['type'] ?? '?') . ' ' . ($rec['name'] ?? '') . ': ' . $addResponse->errorMessage;
            }
        }

        // Nếu có lỗi add → fail job để retry
        if (!empty($addErrors)) {
            $errorMsg = 'APPLY_TEMPLATE: ' . count($addErrors) . '/' . count($records)
                . ' records failed. First error: ' . $addErrors[0];

            return \MJ\DnsManager\Gateway\DAResponse::fail(
                'apply_template_partial_fail',
                $errorMsg,
                array('errors' => $addErrors),
                null,
                0
            );
        }

        // Tất cả records add thành công
        // ── Bước 4: Sync WHMCS DB với trạng thái thực tế trên DA ────────────
        // Pull zone từ DA về để đảm bảo WHMCS DB = DA thực tế
        // Xử lý: NS/SOA DA không cho xóa, records default DA giữ lại, v.v.
        $this->pullZoneRecords($gateway, $domainName);

        // Trả về response của record cuối cùng (hoặc fake OK nếu records rỗng)
        if ($lastResponse !== null) {
            return $lastResponse;
        }

        return \MJ\DnsManager\Gateway\DAResponse::ok(array('applied' => count($records)), 200, 0);
    }

    // ─────────────────────────────────────────────────────────
    // A7 — Email Forwarding Handlers
    // ─────────────────────────────────────────────────────────

    /**
     * Handle CREATE_EMAIL_FWD action.
     *
     * Payload: { source_local, destination_email, email_forward_id, is_catchall }
     * Gọi DA API tạo email forwarder, sau khi thành công đánh dấu synced_at trong DB.
     *
     * @param  \MJ\DnsManager\Gateway\DAGateway $gateway
     * @param  string $domainName
     * @param  array  $payload
     * @return \MJ\DnsManager\Gateway\DAResponse
     */
    private function handleCreateEmailFwd($gateway, string $domainName, array $payload): \MJ\DnsManager\Gateway\DAResponse
    {
        $sourceLocal = $payload['user'] ?? '';
        $destEmail   = $payload['email'] ?? '';
        $forwardId   = (int) ($payload['email_forward_id'] ?? 0);

        if ($sourceLocal === '' || $destEmail === '') {
            return \MJ\DnsManager\Gateway\DAResponse::fail(
                'invalid_payload',
                'CREATE_EMAIL_FWD payload thiếu user hoặc email.',
                [],
                null,
                0
            );
        }

        $response = $gateway->createEmailForwarder($domainName, $sourceLocal, $destEmail);

        if ($response->isSuccess() && $forwardId > 0) {
            // Đánh dấu forwarder đã sync thành công
            \MJ\DnsManager\Models\EmailForward::where('id', $forwardId)
                ->update(['synced_at' => $this->nowStr()]);
        }

        return $response;
    }

    /**
     * Handle DELETE_EMAIL_FWD action.
     *
     * Payload: { source_local, email_forward_id }
     * Gọi DA API xóa email forwarder, sau khi thành công xóa record khỏi DB.
     *
     * @param  \MJ\DnsManager\Gateway\DAGateway $gateway
     * @param  string $domainName
     * @param  array  $payload
     * @return \MJ\DnsManager\Gateway\DAResponse
     */
    private function handleDeleteEmailFwd($gateway, string $domainName, array $payload): \MJ\DnsManager\Gateway\DAResponse
    {
        $sourceLocal = $payload['user'] ?? '';
        $forwardId   = (int) ($payload['email_forward_id'] ?? 0);

        if ($sourceLocal === '') {
            return \MJ\DnsManager\Gateway\DAResponse::fail(
                'invalid_payload',
                'DELETE_EMAIL_FWD payload thiếu user.',
                [],
                null,
                0
            );
        }

        $response = $gateway->deleteEmailForwarder($domainName, $sourceLocal);

        if ($response->isSuccess() && $forwardId > 0) {
            // Xóa forwarder khỏi DB sau khi DA xác nhận xóa thành công
            \MJ\DnsManager\Models\EmailForward::where('id', $forwardId)->delete();
        }

        return $response;
    }
}
