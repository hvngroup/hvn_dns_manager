<?php

namespace HvnGroup\DnsManager\Services;

use HvnGroup\DnsManager\Gateway\DAGateway;
use HvnGroup\DnsManager\Models\QueueJob;
use HvnGroup\DnsManager\Models\Server;
use HvnGroup\DnsManager\Models\SyncLog;
use Illuminate\Database\Capsule\Manager as Capsule;

class ZoneManager
{
    // ─────────────────────────────────────────────────────────────────────────
    // Server list — dữ liệu cho trang servers
    // ─────────────────────────────────────────────────────────────────────────

    public function getServersForList(): array
    {
        $nowTs = time();
        $todayStart = date('Y-m-d 00:00:00');

        return Server::orderBy('sort_order')->get()->map(function (Server $srv) use ($nowTs, $todayStart) {
            $backoffActive = $srv->backoff_until && strtotime((string) $srv->backoff_until) > $nowTs;

            if ($backoffActive) {
                $status = 'offline';
            } elseif ($srv->backoff_count > 2) {
                $status = 'warning';
            } else {
                $status = 'online';
            }

            $pending = QueueJob::where('server_id', $srv->id)->whereIn('status', ['PENDING', 'SYNCING'])->count();
            $failed = QueueJob::where('server_id', $srv->id)->whereIn('status', ['FAILED', 'PERMANENTLY_FAILED'])->count();
            $todayComplete = QueueJob::where('server_id', $srv->id)->where('status', 'COMPLETE')->where('completed_at', '>=', $todayStart)->count();

            $avgMs = SyncLog::where('server_id', $srv->id)->where('success', 1)->whereNotNull('duration_ms')->orderByDesc('id')->limit(100)->avg('duration_ms');

            $totalLogs = SyncLog::where('server_id', $srv->id)->orderByDesc('id')->limit(100)->count();
            $successLogs = SyncLog::where('server_id', $srv->id)->where('success', 1)->orderByDesc('id')->limit(100)->count();
            $uptime = $totalLogs > 0 ? round(($successLogs / $totalLogs) * 100, 1) : null;

            $lastOk = $srv->last_success_at ? date('d/m H:i', strtotime((string) $srv->last_success_at)) : 'N/A';
            $nextRetry = null;
            $retryIn = null;

            if ($backoffActive) {
                $backoffTs = strtotime((string) $srv->backoff_until);
                $nextRetry = date('H:i', $backoffTs);
                $diffSec = $backoffTs - $nowTs;
                $retryIn = $diffSec < 60 ? 'dưới 1 phút' : round($diffSec / 60) . ' phút nữa';
            }

            return [
                'id' => $srv->id,
                'hostname' => $srv->hostname,
                'ip_address' => $srv->ip_address,
                'port' => $srv->port,
                'use_ssl' => (bool) $srv->use_ssl,
                'username' => $srv->username,
                'is_primary' => $srv->role === 'primary',
                'max_concurrent_jobs' => $srv->max_concurrent,
                'notes' => $srv->notes,
                'is_active' => (bool) $srv->is_active,
                'status' => $status,
                'uptime' => $uptime,
                'latency' => $avgMs ? round($avgMs) : 0,
                'last_ok' => $lastOk,
                'pending_jobs' => $pending,
                'today_completed' => $todayComplete,
                'failed_count' => $srv->backoff_count,
                'next_retry' => $nextRetry,
                'retry_in' => $retryIn,
                'last_error' => $srv->last_error_msg,
            ];
        })->values()->toArray();
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Server edit — load data cho form edit
    // ─────────────────────────────────────────────────────────────────────────

    public function getServerForEdit(int $serverId): array
    {
        $server = null;
        if ($serverId > 0) {
            $srv = Server::find($serverId);
            if ($srv) {
                $server = [
                    'id' => $srv->id,
                    'hostname' => $srv->hostname,
                    'ip_address' => $srv->ip_address,
                    'port' => $srv->port,
                    'use_ssl' => (bool) $srv->use_ssl,
                    'username' => $srv->username,
                    'password' => '',
                    'nameservers' => implode("\n", (array) ($srv->nameservers ?? [])),
                    'is_primary' => $srv->role === 'primary',
                    'max_concurrent_jobs' => $srv->max_concurrent ?? 50,
                    'notes' => $srv->notes ?? '',
                    'sort_order' => $srv->sort_order ?? 0,
                    'is_active' => (bool) $srv->is_active,
                ];
            }
        }

        return [
            'server' => $server,
            'isEdit' => $serverId > 0 && $server !== null,
        ];
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Server save — xử lý POST tạo/cập nhật server
    // Trả về ['success' => true] hoặc ['success' => false, 'error' => '...', 'id' => x]
    // Controller tự xử lý redirect
    // ─────────────────────────────────────────────────────────────────────────

    public function saveServer(array $post): array
    {
        $id = (int) ($post['id'] ?? 0);
        $hostname = trim($post['hostname'] ?? '');
        $ip = trim($post['ip_address'] ?? '');
        $port = (int) ($post['port'] ?? 2222);
        $useSsl = !empty($post['use_ssl']);
        $username = trim($post['username'] ?? '');
        $password = $post['password'] ?? '';

        $nameserversRaw = $post['nameservers'] ?? '';
        $nameservers = array_values(array_filter(array_map('trim', explode("\n", str_replace("\r", '', $nameserversRaw)))));

        $role = !empty($post['is_primary']) ? 'primary' : 'secondary';
        $maxConc = max(1, min(500, (int) ($post['max_concurrent_jobs'] ?? 50)));
        $notes = trim($post['notes'] ?? '');

        if (!$hostname || !$ip || !$username) {
            return ['success' => false, 'error' => 'Hostname, IP và Username là bắt buộc.', 'id' => $id];
        }

        try {
            if ($id > 0) {
                $srv = Server::findOrFail($id);
                $srv->hostname = $hostname;
                $srv->ip_address = $ip;
                $srv->port = $port;
                $srv->use_ssl = $useSsl;
                $srv->username = $username;
                $srv->role = $role;
                $srv->max_concurrent = $maxConc;
                $srv->notes = $notes;
                $srv->nameservers = $nameservers ?: null;

                if ($password !== '') {
                    $encoded = class_exists('\WHMCS\Security\Encryption')
                        ? \WHMCS\Security\Encryption::encode($password)
                        : base64_encode($password);
                    $srv->setAttribute('password_enc', $encoded);
                }

                if ($role === 'primary') {
                    Server::where('role', 'primary')->where('id', '!=', $id)->update(['role' => 'secondary']);
                }

                $srv->save();
                return ['success' => true, 'message' => 'Server đã được cập nhật thành công.'];
            } else {
                if (!$password) {
                    return ['success' => false, 'error' => 'Password là bắt buộc khi tạo server mới.', 'id' => 0];
                }

                $srv = new Server();
                $srv->hostname = $hostname;
                $srv->ip_address = $ip;
                $srv->port = $port;
                $srv->use_ssl = $useSsl;
                $srv->username = $username;
                $srv->password = $password;
                $srv->role = $role;
                $srv->max_concurrent = $maxConc;
                $srv->notes = $notes;
                $srv->nameservers = $nameservers ?: null;
                $srv->is_active = true;
                $srv->backoff_count = 0;
                $srv->sort_order = (int) (Server::max('sort_order') ?? 0) + 1;
                $srv->save();

                if ($role === 'primary') {
                    Server::where('role', 'primary')->where('id', '!=', $srv->id)->update(['role' => 'secondary']);
                }

                return ['success' => true, 'message' => 'Server mới đã được thêm thành công.'];
            }
        } catch (\Exception $e) {
            return ['success' => false, 'error' => 'Lỗi lưu dữ liệu: ' . htmlspecialchars($e->getMessage()), 'id' => $id];
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // AJAX actions — nhận params, trả về array
    // ─────────────────────────────────────────────────────────────────────────

    public function testConnection(array $post): array
    {
        try {
            $serverId = (int) ($post['server_id'] ?? 0);
            $password = $post['password'] ?? '';

            if ($password === '' && $serverId > 0) {
                $existing = Server::find($serverId);
                if (!$existing) {
                    return ['success' => false, 'error' => ['message' => 'Server not found.']];
                }
                $existing->hostname = $post['hostname'] ?? $existing->hostname;
                $existing->ip_address = $post['ip_address'] ?? $existing->ip_address;
                $existing->port = (int) ($post['port'] ?? $existing->port);
                $existing->use_ssl = !empty($post['use_ssl']);
                $existing->username = $post['username'] ?? $existing->username;
                $gateway = new DAGateway($existing);
            } else {
                $server = new Server();
                $server->hostname = $post['hostname'] ?? '';
                $server->ip_address = $post['ip_address'] ?? '';
                $server->port = (int) ($post['port'] ?? 2222);
                $server->use_ssl = !empty($post['use_ssl']);
                $server->username = $post['username'] ?? '';
                $server->password = $password;
                $gateway = new DAGateway($server);
            }

            $result = $gateway->testConnection();

            if ($result->isSuccess()) {
                return ['success' => true, 'data' => ['message' => 'Status: HTTP 200 OK. Kết nối thành công.']];
            }
            return ['success' => false, 'error' => ['message' => "Lỗi: {$result->errorMessage}\nStatus: {$result->httpStatus}"]];

        } catch (\Throwable $e) {
            return ['success' => false, 'error' => ['message' => 'Internal Error: ' . $e->getMessage() . ' in ' . basename($e->getFile()) . ':' . $e->getLine()]];
        }
    }

    public function toggleStatus(int $serverId): array
    {
        try {
            if ($serverId <= 0) {
                return ['success' => false, 'error' => 'Invalid server_id'];
            }
            $srv = Server::find($serverId);
            if (!$srv) {
                return ['success' => false, 'error' => 'Server not found'];
            }
            $srv->is_active = !$srv->is_active;
            $srv->save();
            return [
                'success' => true,
                'is_active' => (bool) $srv->is_active,
                'message' => $srv->is_active
                    ? "Server {$srv->hostname} đã được kích hoạt."
                    : "Server {$srv->hostname} đã bị vô hiệu hóa.",
            ];
        } catch (\Throwable $e) {
            return ['success' => false, 'error' => $e->getMessage()];
        }
    }

    public function resetBackoff(int $serverId): array
    {
        try {
            if ($serverId <= 0) {
                return ['success' => false, 'error' => 'Invalid server_id'];
            }
            $srv = Server::find($serverId);
            if (!$srv) {
                return ['success' => false, 'error' => 'Server not found'];
            }

            $srv->backoff_count = 0;
            $srv->backoff_until = null;
            $srv->last_error_msg = null;
            $srv->save();

            QueueJob::where('server_id', $serverId)
                ->where('status', 'FAILED')
                ->update(['status' => 'PENDING', 'next_retry_at' => null, 'error_message' => null]);

            return [
                'success' => true,
                'message' => "Đã reset backoff cho {$srv->hostname}. Các job FAILED sẽ được retry trong cron tiếp theo.",
            ];
        } catch (\Throwable $e) {
            return ['success' => false, 'error' => $e->getMessage()];
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Zone create / delete (giữ lại từ bản gốc, dùng bởi ProvisioningService)
    // ─────────────────────────────────────────────────────────────────────────

    public function createZone($domainId)
    {
        return true;
    }

    public function deleteZone($domainId)
    {
        return true;
    }
}