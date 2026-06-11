<?php

namespace MJ\DnsManager\Hooks;

defined("WHMCS") or die("Access Denied");

use MJ\DnsManager\Models\Domain;
use MJ\DnsManager\Models\Template;
use MJ\DnsManager\Services\QueueManager;
use MJ\DnsManager\Cron\QueueWorker;
use WHMCS\Database\Capsule;

/**
 * AcceptOrderHook — Tạo DNS zone khi domain được cấp phát trên WHMCS.
 *
 * Nguồn kích hoạt (đăng ký trong hooks.php):
 *   - AcceptOrder              → khi admin/cron chấp nhận đơn (duyệt order)
 *   - AfterRegistrarRegistration → khi domain đăng ký thành công qua registrar
 *   - AfterRegistrarTransfer     → khi domain transfer thành công
 *
 * Flow mỗi domain (idempotent):
 *   1. firstOrCreate bản ghi tbl_mj_dns_domains
 *   2. Dispatch job CREATE_ZONE (PENDING) vào tbl_mj_dns_queue
 *   3. runOnce() best-effort; lỗi DA → job ở lại queue cho cron retry
 *
 * Mọi lỗi ghi WHMCS Activity Log, không bao giờ ném ra trình duyệt.
 */
class AcceptOrderHook
{
    use HookGuard;

    /**
     * Hook AcceptOrder — duyệt mọi domain registration thuộc đơn.
     *
     * @param array $params WHMCS hook params: orderid, userid
     */
    public static function handle(array $params): void
    {
        $orderId = (int) ($params['orderid'] ?? 0);
        if ($orderId === 0) {
            return;
        }

        try {
            $userId = (int) ($params['userid'] ?? Capsule::table('tblorders')->where('id', $orderId)->value('userid'));
            if ($userId === 0) {
                logActivity("MJ DNS Manager [AcceptOrder]: Could not determine userid for order #{$orderId}");
                return;
            }

            try {
                $domainItems = Capsule::table('tbldomains')
                    ->where('orderid', $orderId)
                    ->select(['id', 'userid', 'domain', 'status'])
                    ->get();
            } catch (\Exception $e) {
                logActivity("MJ DNS Manager [AcceptOrder]: Failed to query domains for order #{$orderId} — " . $e->getMessage());
                return;
            }

            if ($domainItems->isEmpty()) {
                logActivity("MJ DNS Manager [AcceptOrder]: Order #{$orderId} has no domain registrations. Skipped silently.");
                return;
            }

            foreach ($domainItems as $tblDomain) {
                self::provisionDomain(
                    trim((string) $tblDomain->domain),
                    (int) $tblDomain->id,
                    (int) ($tblDomain->userid ?: $userId),
                    'AcceptOrder'
                );
            }
        } catch (\Throwable $t) {
            logActivity("MJ DNS Manager [CRITICAL ERROR in AcceptOrder]: " . $t->getMessage() . " at " . basename($t->getFile()) . ':' . $t->getLine());
        }
    }

    /**
     * Hook AfterRegistrarRegistration / AfterRegistrarTransfer — provision 1 domain.
     *
     * Bù đắp trường hợp domain được cấp qua registrar mà KHÔNG đi qua luồng
     * AcceptOrder (ví dụ đăng ký trực tiếp, hoặc order auto-accept đã chạy nhưng
     * domain register sau). Idempotent nên gọi nhiều lần không tạo trùng.
     *
     * @param array $params WHMCS registrar hook params (có domainid, domain/domainname, userid)
     */
    public static function handleRegistrar(array $params): void
    {
        try {
            $whmcsDomainId = (int) ($params['domainid'] ?? 0);
            $domainName    = trim((string) ($params['domain'] ?? $params['domainname'] ?? ''));
            $userId        = (int) ($params['userid'] ?? 0);

            // Bổ sung thông tin thiếu từ tbldomains nếu cần.
            if ($whmcsDomainId > 0 && ($domainName === '' || $userId === 0)) {
                $row = Capsule::table('tbldomains')->where('id', $whmcsDomainId)->select(['domain', 'userid'])->first();
                if ($row) {
                    $domainName = $domainName !== '' ? $domainName : trim((string) $row->domain);
                    $userId     = $userId > 0 ? $userId : (int) $row->userid;
                }
            }

            if ($domainName === '' || $userId === 0) {
                return; // thiếu dữ liệu — bỏ qua im lặng
            }

            self::provisionDomain($domainName, $whmcsDomainId, $userId, 'Registrar');
        } catch (\Throwable $t) {
            logActivity("MJ DNS Manager [CRITICAL ERROR in Registrar hook]: " . $t->getMessage() . " at " . basename($t->getFile()) . ':' . $t->getLine());
        }
    }

    /**
     * Logic provision dùng chung — tạo bản ghi domain + dispatch CREATE_ZONE.
     *
     * @param string $domainName    FQDN
     * @param int    $whmcsDomainId tbldomains.id (0 nếu không rõ)
     * @param int    $userId        tblclients.id
     * @param string $source        nhãn nguồn để log
     */
    private static function provisionDomain(string $domainName, int $whmcsDomainId, int $userId, string $source = 'system'): void
    {
        if (!self::isValidFqdn($domainName)) {
            logActivity("MJ DNS Manager [{$source}]: Skipped '{$domainName}' — not a valid FQDN.");
            return;
        }

        try {
            // Step 1: Idempotent domain record
            $domain = Domain::firstOrCreate(
                ['domain' => $domainName],
                [
                    'whmcs_domain_id' => $whmcsDomainId ?: null,
                    'whmcs_user_id'   => $userId,
                    'status'          => 'active',
                ]
            );

            // Backfill liên kết WHMCS nếu bản ghi cũ còn thiếu.
            $dirty = false;
            if ($whmcsDomainId > 0 && empty($domain->whmcs_domain_id)) {
                $domain->whmcs_domain_id = $whmcsDomainId;
                $dirty = true;
            }
            if ($userId > 0 && empty($domain->whmcs_user_id)) {
                $domain->whmcs_user_id = $userId;
                $dirty = true;
            }
            if ($dirty) {
                $domain->save();
            }

            // Step 2 + 3: dispatch CREATE_ZONE
            $template = Template::where('is_default', true)->first();
            $payload  = [
                'domain'      => $domainName,
                'template_id' => $template ? $template->id : null,
                'actor_ip'    => $_SERVER['REMOTE_ADDR'] ?? '127.0.0.1',
            ];

            $batchId = (new QueueManager())->dispatch(
                $domain->id,
                'CREATE_ZONE',
                $payload,
                1,          // priority cao nhất (system provision)
                'system',
                null
            );

            logActivity("MJ DNS Manager [{$source}]: CREATE_ZONE queued for '{$domainName}' (batch: {$batchId})");

            // Step 4: best-effort xử lý ngay; lỗi DA → giữ PENDING cho cron retry.
            try {
                (new QueueWorker())->runOnce($batchId);
            } catch (\Exception $e) {
                logActivity("MJ DNS Manager [{$source}]: Immediate sync failed for '{$domainName}' — will retry via cron. Error: " . $e->getMessage());
            }
        } catch (\Exception $e) {
            logActivity("MJ DNS Manager [{$source}]: Exception for '{$domainName}' — " . $e->getMessage());
        }
    }
}
