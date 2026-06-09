<?php

namespace HvnGroup\DnsManager\Cron;

use HvnGroup\DnsManager\Gateway\DAGateway;
use HvnGroup\DnsManager\Models\Domain;
use HvnGroup\DnsManager\Models\QueueJob;
use HvnGroup\DnsManager\Models\Server;
use HvnGroup\DnsManager\Services\QueueManager;

/**
 * SslChecker — Chạy trong AfterCronJob, thực hiện 2 việc:
 *
 *   1. syncSslStatus(): gọi DA API kiểm tra cert thực tế cho domain
 *      đang ssl_status='pending' → update ssl_status + ssl_expires_at
 *
 *   2. triggerRenewals(): domain ssl_status='active' sắp hết hạn
 *      (< 30 ngày) → dispatch job RENEW_SSL vào queue
 *
 * Flow ssl_status:
 *   none → (CREATE_ZONE complete) → pending
 *   pending → (SslChecker sync) → active | failed
 *   active → (SslChecker renewal) → pending → active (lặp lại)
 */
class SslChecker
{
    /** @var QueueManager */
    private $queueManager;

    /**
     * Số ngày trước khi hết hạn thì trigger renewal.
     * DA mặc định là 30 ngày (letsencrypt_renew_before_expiry_days).
     *
     * @var int
     */
    private $renewBeforeDays = 30;

    public function __construct()
    {
        $this->queueManager = new QueueManager();
    }

    /**
     * Entry point — gọi từ AfterCronJob hook.
     *
     * @return void
     */
    public function run(): void
    {
        // Không chạy nếu admin tắt tính năng auto SSL
        if (!\HvnGroup\DnsManager\Helpers\SettingsHelper::getBool('enable_auto_ssl', true)) {
            return;
        }

        // Đọc số ngày renewal từ Settings
        $this->renewBeforeDays = \HvnGroup\DnsManager\Helpers\SettingsHelper::getInt('ssl_auto_renew_days', 30);

        $server = Server::where('is_active', true)
            ->where('role', 'primary')
            ->orderBy('sort_order')
            ->first();

        if (!$server) {
            return;
        }

        $gateway = new DAGateway($server);

        $this->syncSslStatus($gateway);
        $this->triggerRenewals($server);
    }

    /**
     * Bước 1 — Sync trạng thái cert từ DA về DB.
     *
     * Chỉ xử lý domain đang ssl_status='pending' (cert chưa confirm).
     * Logic dựa trên response thực tế từ CMD_API_SSL:
     *   - ssl_on=yes + signed=yes + end (timestamp) → cert active
     *   - ssl_on=no hoặc signed≠yes → cert chưa có
     *   - domain trong next_retries → DA đang retry ACME (giữ pending)
     *   - domain không trong next_retries + chưa có cert → failed
     *
     * @param  DAGateway $gateway
     * @return void
     */
    private function syncSslStatus(DAGateway $gateway): void
    {
        $domains = Domain::whereIn('ssl_status', ['pending', 'none'])
            ->where('status', 'active')
            ->get();

        if ($domains->isEmpty()) {
            return;
        }

        foreach ($domains as $domain) {
            try {
                $response = $gateway->getSslInfo($domain->domain);

                if (!$response->isSuccess()) {
                    logActivity("HVN DNS Manager [SslChecker]: getSslInfo failed for '{$domain->domain}' — " . ($response->errorMessage ?? 'unknown error'));
                    continue;
                }

                $data = $response->data;
                $sslOn = isset($data['ssl_on']) && $data['ssl_on'] === 'yes';
                $signed = isset($data['signed']) && $data['signed'] === 'yes';

                if (!$sslOn || !$signed) {
                    // Cert chưa issued — kiểm tra DA có đang retry không
                    $inRetryQueue = isset($data['next_retries'])
                        && is_array($data['next_retries'])
                        && isset($data['next_retries'][$domain->domain]);

                    if ($inRetryQueue) {
                        // DA đang xử lý ACME → giữ pending, không làm gì
                        continue;
                    }

                    $domain->update(['ssl_status' => 'failed']);

                    // Alert Telegram + Email via NotificationService — tuân theo toggle settings
                    try {
                        $notif = new \HvnGroup\DnsManager\Services\NotificationService();
                        $notif->notifySslFailed($domain->domain);
                    } catch (\Exception $e) {
                        // Silent — không để notification crash SslChecker
                    }

                    logActivity("HVN DNS Manager [SslChecker]: '{$domain->domain}' — cert not issued and not in retry queue. Marked failed.");
                    continue;
                }

                // Cert đã issued — lấy ngày hết hạn từ Unix timestamp 'end'
                $expiresAt = null;
                if (!empty($data['end']) && is_numeric($data['end'])) {
                    $expiresAt = date('Y-m-d H:i:s', (int) $data['end']);
                }

                $domain->update([
                    'ssl_status' => 'active',
                    'ssl_expires_at' => $expiresAt,
                ]);

                logActivity("HVN DNS Manager [SslChecker]: '{$domain->domain}' — cert active, expires {$expiresAt}.");
            } catch (\Throwable $e) {
                logActivity("HVN DNS Manager [SslChecker]: Exception syncing '{$domain->domain}' — " . $e->getMessage());
            }
        }
    }

    /**
     * Bước 2 — Dispatch job RENEW_SSL cho domain sắp hết hạn.
     *
     * Điều kiện:
     *   - ssl_status = 'active'
     *   - ssl_expires_at <= NOW + 30 ngày
     *   - Chưa có job RENEW_SSL đang PENDING/SYNCING
     *
     * Sau khi dispatch → set ssl_status = 'pending' ngay
     * để không trigger renewal lặp lại ở chu kỳ cron tiếp theo.
     *
     * @param  Server $server
     * @return void
     */
    private function triggerRenewals(Server $server): void
    {
        $threshold = date('Y-m-d H:i:s', strtotime('+' . $this->renewBeforeDays . ' days'));

        $domains = Domain::where('ssl_status', 'active')
            ->where('status', 'active')
            ->whereNotNull('ssl_expires_at')
            ->where('ssl_expires_at', '<=', $threshold)
            ->get();

        if ($domains->isEmpty()) {
            return;
        }

        foreach ($domains as $domain) {
            try {
                // Tránh dispatch trùng nếu job RENEW_SSL đã đang chạy
                $alreadyQueued = QueueJob::where('domain_id', $domain->id)
                    ->whereIn('status', ['PENDING', 'SYNCING'])
                    ->where('action', 'RENEW_SSL')
                    ->exists();

                if ($alreadyQueued) {
                    continue;
                }

                $this->queueManager->dispatch(
                    $domain->id,
                    'RENEW_SSL',
                    ['domain' => $domain->domain],
                    3,        // priority 3 — thấp hơn user action (1-2)
                    'system',
                    null
                );

                // Set pending ngay để không trigger renewal lại lần sau
                $domain->update(['ssl_status' => 'pending']);

                logActivity("HVN DNS Manager [SslChecker]: '{$domain->domain}' — RENEW_SSL dispatched (expires {$domain->ssl_expires_at}).");
            } catch (\Throwable $e) {
                logActivity("HVN DNS Manager [SslChecker]: Renewal exception for '{$domain->domain}' — " . $e->getMessage());
            }
        }
    }
}
