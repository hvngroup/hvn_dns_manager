<?php

namespace MJ\DnsManager\Hooks;

use MJ\DnsManager\Models\Domain;
use MJ\DnsManager\Models\Template;
use MJ\DnsManager\Services\QueueManager;
use MJ\DnsManager\Cron\QueueWorker;
use WHMCS\Database\Capsule;

/**
 * AcceptOrderHook — Creates DNS zone immediately when admin accepts an order.
 *
 * Flow:
 *   1. Extract domain items from the accepted order
 *   2. Insert into tbl_mj_dns_domains (idempotent)
 *   3. Dispatch CREATE_ZONE job to tbl_mj_dns_queue (PENDING)
 *   4. Call QueueWorker::runOnce() to process immediately (best-effort)
 *
 * Error handling:
 *   - If DA server unreachable: job stays PENDING, cron will retry
 *   - If no domain items in order: hook exits silently
 *   - All errors are logged to WHMCS Activity Log, never thrown to browser
 */
class AcceptOrderHook
{
    use HookGuard;

    /**
     * @param  array $params WHMCS hook params: orderid (int), userid (int), status (string)
     * @return void
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

            // Get domain items from this order
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
                return; // No domain items in this order, skip silently
            }

            $queueManager = new QueueManager();
            $worker = new QueueWorker();
            $clientIp = $_SERVER['REMOTE_ADDR'] ?? '127.0.0.1';

            foreach ($domainItems as $tblDomain) {

                $domainName = trim($tblDomain->domain);

                // Guard: must be valid FQDN
                if (!self::isValidFqdn($domainName)) {
                    logActivity("MJ DNS Manager [AcceptOrder]: Skipped '{$domainName}' — not a valid FQDN.");
                    continue;
                }

                try {
                    // Step 1: Idempotent domain record (may already exist if re-accepted)
                    $domain = Domain::firstOrCreate(
                        ['domain' => $domainName],
                        [
                            'whmcs_domain_id' => $tblDomain->id,
                            'whmcs_user_id' => $userId,
                            'status' => 'active',
                        ]
                    );

                    // Step 2: Build CREATE_ZONE payload
                    $template = Template::where('is_default', true)->first();
                    $payload = [
                        'domain' => $domainName,
                        'template_id' => $template ? $template->id : null,
                        'actor_ip' => $clientIp,
                    ];

                    // Step 3: Dispatch to queue (DB write only, < 50ms)
                    $batchId = $queueManager->dispatch(
                        $domain->id,
                        'CREATE_ZONE',
                        $payload,
                        1,        // priority = 1 (highest, system provision)
                        'system',
                        null
                    );

                    logActivity("MJ DNS Manager [AcceptOrder]: CREATE_ZONE queued for '{$domainName}' (batch: {$batchId})");

                    // Step 4: Try to process immediately (best-effort, non-blocking)
                    try {
                        $worker->runOnce($batchId);
                    } catch (\Exception $e) {
                        // DA server offline or error → job stays PENDING for cron retry
                        logActivity("MJ DNS Manager [AcceptOrder]: Immediate sync failed for '{$domainName}' — will retry via cron. Error: " . $e->getMessage());
                    }
                } catch (\Exception $e) {
                    logActivity("MJ DNS Manager [AcceptOrder]: Exception for '{$domainName}' — " . $e->getMessage());
                }
            }
        } catch (\Throwable $t) {
            logActivity("MJ DNS Manager [CRITICAL ERROR in AcceptOrder]: " . $t->getMessage() . " at " . basename($t->getFile()) . ':' . $t->getLine());
        }
    }
}
