<?php

namespace HvnGroup\DnsManager\Services;

use HvnGroup\DnsManager\Models\QueueJob;
use HvnGroup\DnsManager\Models\Server;
use HvnGroup\DnsManager\Models\SyncLog;
use HvnGroup\DnsManager\Models\Domain;
use HvnGroup\DnsManager\Gateway\DAGateway;
use HvnGroup\DnsManager\Helpers\SettingsHelper;
use Illuminate\Database\Capsule\Manager as Capsule;

class ReportService
{
    // ─────────────────────────────────────────────────────────────────────────
    // Sync Logs
    // ─────────────────────────────────────────────────────────────────────────

    public function getSyncLogs(): array
    {
        $statusMap = $this->queueStatusMap();

        $logs = QueueJob::with(['domain', 'server'])->orderByDesc('id')->limit(500)->get()
            ->map(function (QueueJob $job) use ($statusMap) {
                $payload = is_array($job->payload) ? $job->payload : [];
                if ($job->action === 'APPLY_TEMPLATE') {
                    $details = isset($payload['template_name'])
                        ? 'Template: ' . $payload['template_name'] . ' (' . count($payload['records'] ?? []) . ' records)'
                        : '';
                } else {
                    $details = !empty($payload['type'])
                        ? trim(($payload['type'] ?? '') . ' ' . ($payload['name'] ?? '') . ' ' . ($payload['value'] ?? ''))
                        : '';
                }
                return [
                    'id' => $job->id,
                    'time' => $job->created_at ? date('Y-m-d H:i', strtotime((string) $job->created_at)) : '',
                    'domain' => $job->domain ? $job->domain->domain : '—',
                    'domain_id' => $job->domain_id,
                    'action' => $job->action ?: '',
                    'details' => $details,
                    'server' => $job->server ? $job->server->hostname : '—',
                    'status' => $statusMap[$job->status] ?? 'pending',
                    'error_brief' => $job->error_message ? mb_substr($job->error_message, 0, 80) : '',
                    'ms' => null,
                ];
            })->values()->toArray();

        return [
            'logs' => $logs,
            'serverHostnames' => Server::where('is_active', true)->orderBy('sort_order')->pluck('hostname')->toArray(),
        ];
    }

    public function getSyncLogDetail(int $jobId): array
    {
        $job = QueueJob::with(['domain', 'server'])->find($jobId);
        if (!$job) {
            return ['log' => null, 'error' => "Job #{$jobId} không tồn tại."];
        }

        $syncLog = SyncLog::where('queue_id', $job->id)->first();
        $payload = is_array($job->payload) ? $job->payload : [];
        $statusMap = $this->queueStatusMap();

        return [
            'error' => null,
            'log' => [
                'id' => $job->id,
                'batch_id' => $job->batch_id,
                'domain' => $job->domain ? $job->domain->domain : '—',
                'domain_id' => $job->domain_id,
                'action' => $job->action,
                'details' => isset($payload['type'])
                    ? trim(($payload['type'] ?? '') . ' ' . ($payload['name'] ?? '') . ' ' . ($payload['value'] ?? ''))
                    : '',
                'server_hostname' => $job->server ? $job->server->hostname : '—',
                'server_is_primary' => $job->server && $job->server->role === 'primary',
                'server_use_ssl' => (bool) ($job->server ? $job->server->use_ssl : false),
                'status' => $statusMap[$job->status] ?? 'pending',
                'attempt' => $job->attempts ?? 0,
                'ms' => $syncLog ? $syncLog->duration_ms : null,
                'actor_type' => strtoupper($job->actor_type ?? 'SYSTEM'),
                'actor_id' => $job->actor_id,
                'actor_ip' => null,
                'created_at' => $job->created_at ? date('Y-m-d H:i:s', strtotime((string) $job->created_at)) : null,
                'completed_at' => $job->completed_at ? date('Y-m-d H:i:s', strtotime((string) $job->completed_at)) : null,
                'next_retry' => $job->next_retry_at ? date('Y-m-d H:i:s', strtotime((string) $job->next_retry_at)) : null,
                'payload' => json_encode($payload, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE),
                'error_msg' => $job->error_message,
                'da_response' => $syncLog ? $syncLog->response_body : null,
            ],
        ];
    }

    public function runPendingJobs(): array
    {
        try {
            $beforePending = QueueJob::whereIn('status', ['PENDING', 'SYNCING'])->count();
            $beforeFailed = QueueJob::whereIn('status', ['FAILED', 'PERMANENTLY_FAILED'])->count();

            $worker = new \HvnGroup\DnsManager\Cron\QueueWorker();
            $worker->run(true);

            $afterPending = QueueJob::whereIn('status', ['PENDING', 'SYNCING'])->count();
            $afterFailed = QueueJob::where('status', 'FAILED')->count();
            $afterPermFailed = QueueJob::where('status', 'PERMANENTLY_FAILED')->count();
            $afterComplete = QueueJob::where('status', 'COMPLETE')->count();
            $processed = max(0, $beforePending - $afterPending);

            return [
                'success' => true,
                'message' => "Đã chạy 1 chu kỳ cron. Xử lý được {$processed} job.",
                'before_pending' => $beforePending,
                'before_failed' => $beforeFailed,
                'after_pending' => $afterPending,
                'after_failed' => $afterFailed,
                'after_perm_failed' => $afterPermFailed,
                'after_complete' => $afterComplete,
                'processed' => $processed,
                'remaining' => $afterPending,
            ];
        } catch (\Throwable $e) {
            return ['success' => false, 'error' => $e->getMessage()];
        }
    }

    public function retryJob(int $jobId): array
    {
        try {
            if ($jobId <= 0) {
                return ['success' => false, 'error' => 'Job ID không hợp lệ.'];
            }
            $job = QueueJob::find($jobId);
            if (!$job) {
                return ['success' => false, 'error' => "Job #{$jobId} không tồn tại."];
            }
            if (!in_array($job->status, ['FAILED', 'PERMANENTLY_FAILED'])) {
                return ['success' => false, 'error' => "Job #{$jobId} không ở trạng thái FAILED (hiện tại: {$job->status})."];
            }

            $job->update([
                'status' => 'PENDING',
                'attempts' => 0,
                'next_retry_at' => null,
                'error_message' => null,
                'locked_by' => null,
                'locked_at' => null,
                'completed_at' => null,
            ]);

            logActivity("HVN DNS Manager: Admin manually retried Job #{$jobId} ({$job->action}) — reset to PENDING.");
            return ['success' => true, 'message' => "Job #{$jobId} đã được reset về PENDING. Bấm \"Đồng bộ Pending\" để chạy ngay."];
        } catch (\Throwable $e) {
            return ['success' => false, 'error' => $e->getMessage()];
        }
    }

    public function retryAllFailed(): array
    {
        try {
            $count = QueueJob::whereIn('status', ['FAILED', 'PERMANENTLY_FAILED'])->count();

            if ($count === 0) {
                return ['success' => true, 'message' => 'Không có job nào đang ở trạng thái FAILED.', 'count' => 0];
            }

            QueueJob::whereIn('status', ['FAILED', 'PERMANENTLY_FAILED'])
                ->update([
                    'status'        => 'PENDING',
                    'attempts'      => 0,
                    'next_retry_at' => null,
                    'error_message' => null,
                    'locked_by'     => null,
                    'locked_at'     => null,
                    'completed_at'  => null,
                ]);

            logActivity("HVN DNS Manager: Admin retried all failed jobs — {$count} jobs reset to PENDING.");

            return [
                'success' => true,
                'message' => "{$count} job đã được reset về PENDING. Bấm \"Đồng bộ Pending\" để chạy ngay.",
                'count'   => $count,
            ];
        } catch (\Throwable $e) {
            return ['success' => false, 'error' => $e->getMessage()];
        }
    }

    public function cancelJob(int $jobId): array
    {
        try {
            if ($jobId <= 0) {
                return ['success' => false, 'error' => 'Job ID không hợp lệ.'];
            }

            $job = QueueJob::find($jobId);
            if (!$job) {
                return ['success' => false, 'error' => "Job #{$jobId} không tồn tại."];
            }

            if (!in_array($job->status, ['PENDING', 'FAILED', 'PERMANENTLY_FAILED'])) {
                return ['success' => false, 'error' => "Không thể hủy job đang ở trạng thái {$job->status}. Chỉ hủy được PENDING hoặc FAILED."];
            }

            $job->update([
                'status'        => 'CANCELLED',
                'completed_at'  => date('Y-m-d H:i:s'),
                'error_message' => 'Cancelled manually by Admin.',
                'locked_by'     => null,
                'locked_at'     => null,
            ]);

            logActivity("HVN DNS Manager: Admin cancelled Job #{$jobId} ({$job->action}) — status set to CANCELLED.");

            return ['success' => true, 'message' => "Job #{$jobId} đã được hủy thành công."];
        } catch (\Throwable $e) {
            return ['success' => false, 'error' => $e->getMessage()];
        }
    }
    
    // ─────────────────────────────────────────────────────────────────────────
    // Audit Trail
    // ─────────────────────────────────────────────────────────────────────────

    public function getAuditLogs(): array
    {
        $logs = Capsule::table('mod_hvndns_audit_trail')->orderByDesc('id')->limit(200)->get();
        $result = [];
        foreach ($logs as $row) {
            $old = json_decode($row->old_value ?? 'null', true);
            $new = json_decode($row->new_value ?? 'null', true);
            $brief = '';
            if ($new && isset($new['type'])) {
                $brief = trim(($new['type'] ?? '') . ' ' . ($new['name'] ?? '') . ' ' . ($new['value'] ?? ''));
            } elseif ($old && isset($old['type'])) {
                $brief = ($old['type'] ?? '') . ' → [xóa]';
            } elseif (!empty($row->context)) {
                $brief = $row->context;
            }
            $result[] = [
                'id' => $row->id,
                'time' => (new \DateTime($row->created_at))->format('d/m, H:i'),
                'actorType' => $row->actor_type,
                'actorName' => $row->actor_name ?: ('ID#' . $row->actor_id),
                'domain' => $row->domain,
                'domain_id' => $row->domain_id,
                'action' => strtolower($row->action),
                'details_brief' => mb_substr($brief, 0, 60),
                'ip' => $row->ip_address,
            ];
        }
        return $result;
    }

    public function getAuditLogDetail(int $id): array
    {
        if ($id <= 0) {
            return ['log' => null, 'error' => 'Thiếu tham số id.'];
        }
        $row = Capsule::table('mod_hvndns_audit_trail')->where('id', $id)->first();
        if (!$row) {
            return ['log' => null, 'error' => "Audit entry #{$id} không tồn tại."];
        }

        $oldVal = $newVal = null;
        if (!empty($row->old_value)) {
            $decoded = json_decode($row->old_value, true);
            $oldVal = $decoded ? json_encode($decoded, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE) : $row->old_value;
        }
        if (!empty($row->new_value)) {
            $decoded = json_decode($row->new_value, true);
            $newVal = $decoded ? json_encode($decoded, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE) : $row->new_value;
        }

        $target = '';
        if ($row->target_type && $row->target_id) {
            $target = ucfirst($row->target_type) . ' #' . $row->target_id;
            if ($row->target_type === 'record') {
                $valArr = json_decode($row->new_value ?? $row->old_value ?? '{}', true);
                if ($valArr && isset($valArr['type'], $valArr['name'])) {
                    $target .= ' (' . $valArr['type'] . ' ' . $valArr['name'] . ')';
                }
            }
        } elseif (!empty($row->context)) {
            $target = $row->context;
        }

        $actorFull = $row->actor_name ?: ucfirst($row->actor_type ?? 'system');
        if ($row->actor_id) {
            $actorFull .= ' — ' . ucfirst($row->actor_type ?? '') . ' #' . $row->actor_id;
        }

        return [
            'error' => null,
            'log' => [
                'id' => $row->id,
                'actorFull' => $actorFull,
                'actorType' => $row->actor_type ?? 'system',
                'context' => $row->context ?? '—',
                'domain' => $row->domain ?? '—',
                'domainId' => $row->domain_id ?? 0,
                'action' => $row->action ?? '—',
                'target' => $target ?: '—',
                'oldVal' => $oldVal ?? '[Không có]',
                'newVal' => $newVal ?? '[Không có]',
                'ip' => $row->ip_address ?? '—',
                'ua' => $row->user_agent ?? '—',
                'session' => $row->session_id ?? '—',
                'notes' => $row->notes ?? '—',
                'timeLong' => $row->created_at ? date('d/m/Y H:i:s', strtotime($row->created_at)) : '—',
            ],
        ];
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Drift Reports
    // ─────────────────────────────────────────────────────────────────────────

    public function getDriftReports(): array
    {
        $reports = Capsule::table('mod_hvndns_drift_reports as dr')
            ->join('mod_hvndns_domains as d', 'dr.domain_id', '=', 'd.id')
            ->select(['dr.id', 'dr.domain_id', 'd.domain', 'dr.drift_type', 'dr.record_type', 'dr.record_name', 'dr.local_value', 'dr.remote_value', 'dr.status', 'dr.detected_at', 'dr.resolved_at'])
            ->orderBy('dr.detected_at', 'desc')->limit(1000)->get();

        $rows = [];
        foreach ($reports as $r) {
            $localArr = json_decode($r->local_value ?? 'null', true);
            $remoteArr = json_decode($r->remote_value ?? 'null', true);
            $whmcsVal = $daVal = null;
            $needsPriority = in_array($r->record_type, ['MX', 'SRV']);

            if (is_array($localArr) && isset($localArr['value'])) {
                $whmcsVal = $localArr['value'];
                if ($needsPriority && !empty($localArr['priority'])) {
                    $whmcsVal = $localArr['priority'] . ' ' . $whmcsVal;
                }
            }
            if (is_array($remoteArr) && isset($remoteArr['value'])) {
                $daVal = $remoteArr['value'];
                if ($needsPriority && !empty($remoteArr['priority'])) {
                    $daVal = $remoteArr['priority'] . ' ' . $daVal;
                }
            }

            $rows[] = [
                'id' => (int) $r->id,
                'domain_id' => (int) $r->domain_id,
                'domain' => $r->domain,
                'type' => $r->drift_type,
                'record_type' => $r->record_type ?? '',
                'record_name' => $r->record_name ?? '',
                'whmcs_val' => $whmcsVal,
                'da_val' => $daVal,
                'status' => $r->status,
                'detected_at' => $r->detected_at ? date('d/m/Y H:i', strtotime($r->detected_at)) : '',
            ];
        }

        $lastRun = SettingsHelper::get('drift_last_run', '');
        $intervalHours = SettingsHelper::getInt('drift_check_interval_hours', 24);

        return [
            'reports' => $rows,
            'lastRun' => $lastRun ? date('d/m/Y H:i', strtotime($lastRun)) : 'Chưa chạy lần nào',
            'nextRun' => $lastRun ? date('d/m/Y H:i', strtotime($lastRun) + $intervalHours * 3600) : '—',
        ];
    }

    public function runDriftCheck(int $domainId): array
    {
        try {
            if (!$domainId)
                return ['success' => false, 'error' => 'Thiếu domain_id'];
            $domain = Domain::find($domainId);
            if (!$domain)
                return ['success' => false, 'error' => 'Domain không tồn tại'];
            $server = $this->getPrimaryServer();
            if (!$server)
                return ['success' => false, 'error' => 'Không có primary server active'];

            $checker = new \HvnGroup\DnsManager\Cron\DriftChecker();
            $drifts = $checker->scanSingleDomain($server, $domain);
            $count = count($drifts);

            return [
                'success' => true,
                'message' => $count > 0 ? "{$count} sai lệch phát hiện — kiểm tra Drift Reports" : "Không có sai lệch — records khớp với DirectAdmin",
                'drifts' => $drifts,
            ];
        } catch (\Throwable $e) {
            return ['success' => false, 'error' => $e->getMessage()];
        }
    }

    public function runDriftScanByName(string $domainName): array
    {
        try {
            if (!$domainName)
                return ['success' => false, 'error' => 'Thiếu domain name'];
            $domain = Domain::where('domain', $domainName)->first();
            if (!$domain)
                return ['success' => false, 'error' => "Domain '{$domainName}' không tồn tại"];
            $server = $this->getPrimaryServer();
            if (!$server)
                return ['success' => false, 'error' => 'Không có primary server active'];

            $checker = new \HvnGroup\DnsManager\Cron\DriftChecker();
            $drifts = $checker->scanSingleDomain($server, $domain);
            $count = count($drifts);

            return [
                'success' => true,
                'message' => $count > 0 ? "{$count} sai lệch phát hiện trên {$domainName}" : "Không có sai lệch — {$domainName} khớp với DirectAdmin",
            ];
        } catch (\Throwable $e) {
            return ['success' => false, 'error' => $e->getMessage()];
        }
    }

    public function runDriftScanAll(): array
    {
        try {
            $checker = new \HvnGroup\DnsManager\Cron\DriftChecker();
            $checker->runForced();

            $openCount = Capsule::table('mod_hvndns_drift_reports')->where('status', 'pending')->count();
            $domainCount = Capsule::table('mod_hvndns_drift_reports')->where('status', 'pending')->distinct('domain_id')->count('domain_id');

            return [
                'success' => true,
                'message' => $openCount > 0 ? "Phát hiện {$openCount} sai lệch trên {$domainCount} domain" : "Không phát hiện sai lệch nào",
            ];
        } catch (\Throwable $e) {
            return ['success' => false, 'error' => $e->getMessage()];
        }
    }

    public function runSslCheck(int $domainId): array
    {
        try {
            if (!$domainId)
                return ['success' => false, 'error' => 'Thiếu domain_id'];
            $domain = Domain::find($domainId);
            if (!$domain)
                return ['success' => false, 'error' => 'Domain không tồn tại'];
            $server = $this->getPrimaryServer();
            if (!$server)
                return ['success' => false, 'error' => 'Không có primary server active'];

            $gateway = new DAGateway($server);
            $response = $gateway->getSslInfo($domain->domain);

            if (!$response->isSuccess()) {
                return ['success' => false, 'error' => 'Không lấy được SSL info: ' . ($response->errorMessage ?? 'unknown')];
            }

            $data = $response->data;
            $sslOn = isset($data['ssl_on']) && $data['ssl_on'] === 'yes';
            $signed = isset($data['signed']) && $data['signed'] === 'yes';

            if ($sslOn && $signed) {
                $expiresAt = (!empty($data['end']) && is_numeric($data['end'])) ? date('Y-m-d H:i:s', (int) $data['end']) : null;
                $domain->update(['ssl_status' => 'active', 'ssl_expires_at' => $expiresAt]);
                return ['success' => true, 'message' => 'Cert active — hết hạn ' . ($expiresAt ?? 'không rõ')];
            }

            $inRetry = isset($data['next_retries'][$domain->domain]);
            $domain->update(['ssl_status' => $inRetry ? 'pending' : 'failed']);
            return [
                'success' => true,
                'message' => $inRetry ? 'Cert chưa có — DA đang retry ACME (pending)' : 'Cert chưa được cấp và không còn trong retry queue (failed)',
            ];
        } catch (\Throwable $e) {
            return ['success' => false, 'error' => $e->getMessage()];
        }
    }


    // ─────────────────────────────────────────────────────────────────────────
    // Drift — Resolve 1 row
    // action: pull | push | delete_da | delete_whmcs | ignore
    // ─────────────────────────────────────────────────────────────────────────

    public function resolveDrift(int $driftId, string $action): array
    {
        try {
            // ── 1. Load drift row ─────────────────────────────────────────
            $drift = \Illuminate\Database\Capsule\Manager::table('mod_hvndns_drift_reports')
                ->where('id', $driftId)
                ->first();

            if (!$drift) {
                return ['success' => false, 'error' => "Drift #{$driftId} không tồn tại."];
            }
            if ($drift->status !== 'pending') {
                return ['success' => false, 'error' => "Drift #{$driftId} đã được xử lý (status: {$drift->status})."];
            }

            // ── 2. Load domain ────────────────────────────────────────────
            $domain = \HvnGroup\DnsManager\Models\Domain::find($drift->domain_id);
            if (!$domain) {
                return ['success' => false, 'error' => 'Domain không tồn tại trong WHMCS.'];
            }

            // ── 3. Decode stored values ───────────────────────────────────
            $localArr = $drift->local_value ? json_decode($drift->local_value, true) : null;
            $remoteArr = $drift->remote_value ? json_decode($drift->remote_value, true) : null;

            // ── 4. Route theo action ──────────────────────────────────────
            switch ($action) {

                case 'pull':
                    return $this->driftPull($drift, $domain, $localArr, $remoteArr);

                case 'push':
                    return $this->driftPush($drift, $domain, $localArr, $remoteArr);

                case 'delete_da':
                    return $this->driftDeleteDa($drift, $domain, $remoteArr);

                case 'delete_whmcs':
                    return $this->driftDeleteWhmcs($drift, $domain, $localArr);

                case 'ignore':
                    \Illuminate\Database\Capsule\Manager::table('mod_hvndns_drift_reports')
                        ->where('id', $driftId)
                        ->update(['status' => 'ignored', 'resolved_at' => date('Y-m-d H:i:s')]);
                    return ['success' => true, 'message' => 'Đã bỏ qua.'];

                default:
                    return ['success' => false, 'error' => "Action không hợp lệ: {$action}"];
            }

        } catch (\Throwable $e) {
            return ['success' => false, 'error' => $e->getMessage()];
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Helpers
    // ─────────────────────────────────────────────────────────────────────────

    // ─────────────────────────────────────────────────────────────────────────
    // Pull: Lấy record từ DA → ghi vào WHMCS DB (không đẩy lên DA)
    //
    // Dùng cho:
    //   - added_on_da  : record chỉ có trên DA → tạo mới trong WHMCS
    //   - modified     : giá trị DA khác WHMCS → ghi đè WHMCS bằng giá trị DA
    // ─────────────────────────────────────────────────────────────────────────

    private function driftPull($drift, $domain, $localArr, $remoteArr): array
    {
        if (!$remoteArr) {
            return ['success' => false, 'error' => 'Không có dữ liệu DA để pull.'];
        }

        $type = strtoupper($drift->record_type);
        $name = $drift->record_name;
        $value = $remoteArr['value'] ?? '';
        $ttl = (int) ($remoteArr['ttl'] ?? 3600);
        $priority = $remoteArr['priority'] ?? null;

        if (empty($value)) {
            return ['success' => false, 'error' => 'Giá trị từ DA rỗng, không thể pull.'];
        }

        \Illuminate\Database\Capsule\Manager::beginTransaction();
        try {
            if ($drift->drift_type === 'added_on_da') {
                // Tạo record mới trong WHMCS — không dispatch queue (đã có trên DA)
                \HvnGroup\DnsManager\Models\Record::create([
                    'domain_id' => $domain->id,
                    'type' => $type,
                    'name' => $name,
                    'value' => $value,
                    'ttl' => $ttl,
                    'priority' => $priority,
                    'weight' => null,
                    'port' => null,
                    'is_system' => 0,
                    'is_locked' => 0,
                    'pending_delete' => 0,
                ]);

            } elseif ($drift->drift_type === 'modified') {
                // Tìm record trong WHMCS và cập nhật giá trị theo DA
                if (!$localArr) {
                    return ['success' => false, 'error' => 'Không có local_value để tìm record WHMCS.'];
                }
                $record = \HvnGroup\DnsManager\Models\Record::where('domain_id', $domain->id)
                    ->where('type', $type)
                    ->where('name', $name)
                    ->where('value', $localArr['value'] ?? '')
                    ->first();

                if (!$record) {
                    // Không tìm thấy exact match — tìm theo type+name
                    $record = \HvnGroup\DnsManager\Models\Record::where('domain_id', $domain->id)
                        ->where('type', $type)
                        ->where('name', $name)
                        ->first();
                }

                if (!$record) {
                    \Illuminate\Database\Capsule\Manager::rollBack();
                    return ['success' => false, 'error' => "Không tìm thấy record {$type} {$name} trong WHMCS."];
                }

                $record->update([
                    'value' => $value,
                    'ttl' => $ttl,
                    'priority' => $priority,
                ]);

                QueueJob::where('domain_id', $domain->id)
                    ->whereIn('status', ['PENDING', 'SYNCING'])
                    ->whereIn('action', ['EDIT_RECORD', 'ADD_RECORD'])
                    ->where('payload', 'LIKE', '%"record_id":' . $record->id . '%')
                    ->update([
                        'status' => 'CANCELLED',
                        'completed_at' => date('Y-m-d H:i:s'),
                        'error_message' => 'Cancelled: record pulled from DA manually.',
                    ]);
            }

            // Đánh dấu drift đã giải quyết
            \Illuminate\Database\Capsule\Manager::table('mod_hvndns_drift_reports')
                ->where('id', $drift->id)
                ->update(['status' => 'resolved', 'resolved_at' => date('Y-m-d H:i:s')]);

            \Illuminate\Database\Capsule\Manager::commit();

            logActivity("HVN DNS Manager [DriftResolve]: PULL {$type} {$name} @ {$domain->domain} — drift #{$drift->id} resolved.");

            return ['success' => true, 'message' => "Pull thành công: {$type} {$name} đã được cập nhật vào WHMCS."];

        } catch (\Throwable $e) {
            \Illuminate\Database\Capsule\Manager::rollBack();
            throw $e;
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Push: Ghi đè DA bằng dữ liệu WHMCS (qua Queue)
    //
    // Dùng cho:
    //   - missing_on_da : record có trong WHMCS nhưng DA thiếu → ADD_RECORD
    //   - modified      : WHMCS là source of truth → EDIT_RECORD trên DA
    // ─────────────────────────────────────────────────────────────────────────

    private function driftPush($drift, $domain, $localArr, $remoteArr): array
    {
        if (!$localArr) {
            return ['success' => false, 'error' => 'Không có dữ liệu WHMCS để push.'];
        }

        $type = strtoupper($drift->record_type);
        $name = $drift->record_name;
        $value = $localArr['value'] ?? '';

        if (empty($value)) {
            return ['success' => false, 'error' => 'Giá trị WHMCS rỗng, không thể push.'];
        }

        // Tìm record trong WHMCS để lấy record_id
        $record = \HvnGroup\DnsManager\Models\Record::where('domain_id', $domain->id)
            ->where('type', $type)
            ->where('name', $name)
            ->where('value', $value)
            ->first();

        if (!$record) {
            $record = \HvnGroup\DnsManager\Models\Record::where('domain_id', $domain->id)
                ->where('type', $type)
                ->where('name', $name)
                ->first();
        }

        $qm = new \HvnGroup\DnsManager\Services\QueueManager();

        if ($drift->drift_type === 'missing_on_da') {
            // Record có trong WHMCS nhưng DA mất → dispatch ADD_RECORD
            $payload = [
                'record_id' => $record ? $record->id : 0,
                'type' => $type,
                'name' => $name,
                'value' => $value,
                'ttl' => (int) ($localArr['ttl'] ?? 3600),
            ];
            if (!empty($localArr['priority'])) {
                $payload['priority'] = $localArr['priority'];
            }
            $batchId = $qm->dispatch($domain->id, 'ADD_RECORD', $payload, 1, 'admin', null);
            $msg = "Push ADD: {$type} {$name} đã được queue lên DA.";

        } else {
            // modified → dispatch EDIT_RECORD: ghi đè DA bằng giá trị WHMCS
            if (!$remoteArr) {
                return ['success' => false, 'error' => 'Không có dữ liệu DA để build edit payload.'];
            }
            $payload = [
                'record_id' => $record ? $record->id : 0,
                'old_record' => [
                    'type' => $type,
                    'name' => $name,
                    'value' => $remoteArr['value'] ?? $value,
                    'priority' => $remoteArr['priority'] ?? null,
                ],
                'new_record' => [
                    'type' => $type,
                    'name' => $name,
                    'value' => $value,
                    'ttl' => (int) ($localArr['ttl'] ?? 3600),
                    'priority' => $localArr['priority'] ?? null,
                ],
            ];
            $batchId = $qm->dispatch($domain->id, 'EDIT_RECORD', $payload, 1, 'admin', null);
            $msg = "Push EDIT: {$type} {$name} đã được queue ghi đè lên DA.";
        }

        // Đánh dấu drift resolved ngay (queue sẽ xử lý async)
        \Illuminate\Database\Capsule\Manager::table('mod_hvndns_drift_reports')
            ->where('id', $drift->id)
            ->update(['status' => 'resolved', 'resolved_at' => date('Y-m-d H:i:s')]);

        logActivity("HVN DNS Manager [DriftResolve]: PUSH {$type} {$name} @ {$domain->domain} — batch {$batchId}, drift #{$drift->id} resolved.");

        return ['success' => true, 'message' => $msg, 'batch_id' => $batchId];
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Delete DA: Xóa record trên DA (record thừa không có trong WHMCS)
    // Dùng cho: added_on_da
    // ─────────────────────────────────────────────────────────────────────────

    private function driftDeleteDa($drift, $domain, $remoteArr): array
    {
        if (!$remoteArr) {
            return ['success' => false, 'error' => 'Không có dữ liệu DA để xóa.'];
        }

        $type = strtoupper($drift->record_type);
        $name = $drift->record_name;
        $value = $remoteArr['value'] ?? '';

        if (empty($value)) {
            return ['success' => false, 'error' => 'Giá trị DA rỗng, không thể xóa.'];
        }

        // Dispatch DELETE_RECORD với record_id = 0 (record không tồn tại trong WHMCS)
        // QueueWorker sẽ gọi DAGateway::deleteRecord() dựa trên payload type+name+value
        $qm = new \HvnGroup\DnsManager\Services\QueueManager();
        $payload = [
            'record_id' => 0,  // Không có record trong WHMCS — worker chỉ cần xóa trên DA
            'type' => $type,
            'name' => $name,
            'value' => $value,
        ];
        if (!empty($remoteArr['priority'])) {
            $payload['priority'] = $remoteArr['priority'];
        }

        $batchId = $qm->dispatch($domain->id, 'DELETE_RECORD', $payload, 1, 'admin', null);

        \Illuminate\Database\Capsule\Manager::table('mod_hvndns_drift_reports')
            ->where('id', $drift->id)
            ->update(['status' => 'resolved', 'resolved_at' => date('Y-m-d H:i:s')]);

        logActivity("HVN DNS Manager [DriftResolve]: DELETE_DA {$type} {$name} @ {$domain->domain} — batch {$batchId}, drift #{$drift->id} resolved.");

        return ['success' => true, 'message' => "Xóa DA: {$type} {$name} đã được queue xóa trên DirectAdmin.", 'batch_id' => $batchId];
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Delete WHMCS: Xóa record khỏi WHMCS DB (record trong WHMCS không nên tồn tại)
    // Dùng cho: missing_on_da (DA đã xóa, WHMCS chưa biết)
    // ─────────────────────────────────────────────────────────────────────────

    private function driftDeleteWhmcs($drift, $domain, $localArr): array
    {
        if (!$localArr) {
            return ['success' => false, 'error' => 'Không có dữ liệu WHMCS để xóa.'];
        }

        $type = strtoupper($drift->record_type);
        $name = $drift->record_name;
        $value = $localArr['value'] ?? '';

        $record = \HvnGroup\DnsManager\Models\Record::where('domain_id', $domain->id)
            ->where('type', $type)
            ->where('name', $name)
            ->where('value', $value)
            ->first();

        if (!$record) {
            $record = \HvnGroup\DnsManager\Models\Record::where('domain_id', $domain->id)
                ->where('type', $type)
                ->where('name', $name)
                ->first();
        }

        \Illuminate\Database\Capsule\Manager::beginTransaction();
        try {
            if ($record) {
                // Xóa thẳng khỏi DB — DA đã không có record này nên không cần queue
                $record->delete();
            }

            \Illuminate\Database\Capsule\Manager::table('mod_hvndns_drift_reports')
                ->where('id', $drift->id)
                ->update(['status' => 'resolved', 'resolved_at' => date('Y-m-d H:i:s')]);

            \Illuminate\Database\Capsule\Manager::commit();

        } catch (\Throwable $e) {
            \Illuminate\Database\Capsule\Manager::rollBack();
            throw $e;
        }

        logActivity("HVN DNS Manager [DriftResolve]: DELETE_WHMCS {$type} {$name} @ {$domain->domain} — drift #{$drift->id} resolved.");

        return ['success' => true, 'message' => "Đã xóa {$type} {$name} khỏi WHMCS DB."];
    }

    private function getPrimaryServer()
    {
        return \HvnGroup\DnsManager\Models\Server::where('is_active', true)
            ->where('role', 'primary')->orderBy('sort_order')->first();
    }

    private function queueStatusMap(): array
    {
        return [
            'COMPLETE'           => 'complete',
            'FAILED'             => 'failed',
            'PERMANENTLY_FAILED' => 'failed',
            'PENDING'            => 'pending',
            'SYNCING'            => 'pending',
            'CANCELLED'          => 'cancelled',
        ];
    }
}