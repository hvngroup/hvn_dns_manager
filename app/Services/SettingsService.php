<?php

namespace HvnGroup\DnsManager\Services;

use HvnGroup\DnsManager\Helpers\SettingsHelper;
use Illuminate\Database\Capsule\Manager as Capsule;

class SettingsService
{
    // ─────────────────────────────────────────────────────────────────────────
    // Page data — trả về array settings cho Smarty assign
    // ─────────────────────────────────────────────────────────────────────────

    public function getSettingsForPage(): array
    {
        $rows = Capsule::table('mod_hvndns_settings')->get();
        $settings = [];
        foreach ($rows as $row) {
            $settings[$row->setting_key] = $row->setting_val;
        }

        $get = function ($key, $default = '') use ($settings) {
            return isset($settings[$key]) ? $settings[$key] : $default;
        };
        $b = function ($key, $default = false) use ($get) {
            $val = $get($key, $default ? '1' : '0');
            return $val === '1' || $val === 1 || $val === true;
        };

        return [
            // Module Core
            'module_enabled' => $b('module_enabled', true),
            'default_nameserver_1' => $get('default_nameserver_1', 'dns1.hvn.vn'),
            'default_nameserver_2' => $get('default_nameserver_2', 'dns2.hvn.vn'),
            'default_nameserver_3' => $get('default_nameserver_3', 'dns3.hvn.vn'),
            'default_nameserver_4' => $get('default_nameserver_4', ''),
            'default_nameserver_5' => $get('default_nameserver_5', ''),
            'default_ttl' => (int) $get('default_ttl', 3600),
            // Domain Policy
            'respect_whmcs_dns' => $b('respect_whmcs_dns', false),
            'disable_manage_wrong_ns' => $b('disable_manage_wrong_ns', true),
            'ns_check_method' => $get('ns_check_method', 'dns_lookup'),
            'create_on_preregistrar' => $b('create_on_preregistrar', true),
            'create_on_registration' => $b('create_on_registration', true),
            'create_on_transfer' => $b('create_on_transfer', true),
            'grace_period_days' => (int) $get('grace_period_days', 30),
            // DNS Editor
            'enable_dns_editor' => $b('enable_dns_editor', true),
            'subdomain_limit' => (int) $get('subdomain_limit', 0),
            'allow_modify_a' => $b('allow_modify_a', true),
            'allow_modify_aaaa' => $b('allow_modify_aaaa', true),
            'allow_modify_cname' => $b('allow_modify_cname', true),
            'allow_modify_mx' => $b('allow_modify_mx', true),
            'allow_modify_txt' => $b('allow_modify_txt', true),
            'allow_modify_srv' => $b('allow_modify_srv', true),
            'allow_modify_caa' => $b('allow_modify_caa', true),
            'allow_modify_ns' => $b('allow_modify_ns', false),
            // Record Limits
            'total_record_limit' => (int) $get('total_record_limit', 50),
            'a_record_limit' => (int) $get('a_record_limit', 100),
            'aaaa_record_limit' => (int) $get('aaaa_record_limit', 100),
            'cname_record_limit' => (int) $get('cname_record_limit', 100),
            'mx_record_limit' => (int) $get('mx_record_limit', 100),
            'txt_record_limit' => (int) $get('txt_record_limit', 100),
            'srv_record_limit' => (int) $get('srv_record_limit', 100),
            'caa_record_limit' => (int) $get('caa_record_limit', 20),
            'ns_record_limit' => (int) $get('ns_record_limit', 10),
            // URL Redirect
            'enable_url_redirect' => $b('enable_url_redirect', true),
            'enable_masked_redirect' => $b('enable_masked_redirect', true),
            'masked_hash_key' => '',
            'url_redirect_limit' => (int) $get('url_redirect_limit', 5),
            // Email Forwarding
            'enable_email_forwarder' => $b('enable_email_forwarder', true),
            'enable_email_catchall' => $b('enable_email_catchall', true),
            'email_forwarder_limit' => (int) $get('email_forwarder_limit', 5),
            'email_destination_limit' => (int) $get('email_destination_limit', 10),
            'email_verify_template' => $get('email_verify_template', ''),
            // DDNS
            'ddns_mode' => $b('ddns_mode', false),
            'ddns_rate_limit' => (int) $get('ddns_rate_limit', 60),
            'ddns_token_limit' => (int) $get('ddns_token_limit', 5),
            'enable_ddns_bruteforce' => $b('enable_ddns_bruteforce', true),
            'ddns_bruteforce_threshold' => (int) $get('ddns_bruteforce_threshold', 10),
            'ddns_bruteforce_window' => (int) $get('ddns_bruteforce_window', 3600),
            'ddns_bruteforce_ban_duration' => (int) $get('ddns_bruteforce_ban_duration', 3600),
            // DNSSEC
            'dnssec_mode' => $b('dnssec_mode', false),
            'dnssec_auto_resign' => $b('dnssec_auto_resign', true),
            // SSL
            'enable_auto_ssl' => $b('enable_auto_ssl', true),
            'enable_client_ssl_trigger' => $b('enable_client_ssl_trigger', true),
            'ssl_auto_renew_days' => (int) $get('ssl_auto_renew_days', 7),
            'enable_php_for_domain' => $b('enable_php_for_domain', true),
            // DNS Templates
            'enable_dns_templates' => $b('enable_dns_templates', true),
            'enable_user_custom_templates' => $b('enable_user_custom_templates', false),
            'user_template_limit' => (int) $get('user_template_limit', 10),
            // Client Notification
            'enable_client_notification' => $b('enable_client_notification', false),
            'notification_email_template' => $get('notification_email_template', ''),
            'notify_on_zone_create' => $b('notify_on_zone_create', true),
            'notify_on_record_change' => $b('notify_on_record_change', true),
            'notify_on_zone_delete' => $b('notify_on_zone_delete', true),
            // Admin Alert
            'enable_telegram_alert' => $b('enable_telegram_alert', false),
            'telegram_bot_token' => '',
            'telegram_chat_id' => $get('telegram_chat_id', ''),
            'enable_email_alert' => $b('enable_email_alert', false),
            'alert_email_addresses' => $get('alert_email_addresses', ''),
            'alert_cooldown' => (int) $get('alert_cooldown', 900),
            'alert_failed_threshold' => (int) $get('alert_failed_threshold', 5),
            'alert_unreachable_threshold' => (int) $get('alert_unreachable_threshold', 3),
            'alert_queue_backlog_threshold' => (int) $get('alert_queue_backlog_threshold', 100),
            // UI
            'show_domain_service_link' => $b('show_domain_service_link', true),
            'show_under_domain_menu' => $b('show_under_domain_menu', true),
            'nav_menu_order' => (int) $get('nav_menu_order', 20),
            'show_in_domain_sidebar' => $b('show_in_domain_sidebar', true),
            // Performance
            'fetch_from_ns_on_load' => $b('fetch_from_ns_on_load', false),
            'fetch_from_ns_on_load_admin' => $b('fetch_from_ns_on_load_admin', false),
            'cache_refresh_ttl' => (int) $get('cache_refresh_ttl', 720),
            'large_db_mode' => $b('large_db_mode', false),
            'client_rate_limit' => (int) $get('client_rate_limit', 30),
            // Data Retention
            'snapshot_retention_count' => (int) $get('snapshot_retention_count', 30),
            'queue_completed_retention_days' => (int) $get('queue_completed_retention_days', 30),
            'drift_auto_fix' => $b('drift_auto_fix', false),
            // Queue
            'cron_interval' => (int) $get('cron_interval', 60),
            'job_timeout' => (int) $get('job_timeout', 30),
            'max_retry_attempts' => (int) $get('max_retry_attempts', 5),
            'stale_lock_timeout' => (int) $get('stale_lock_timeout', 300),
            'worker_max_runtime' => (int) $get('worker_max_runtime', 55),
            'conflict_window' => (int) $get('conflict_window', 180),
            // Security
            'restrict_subaccounts' => $b('restrict_subaccounts', true),
            'audit_trail_retention_days' => (int) $get('audit_trail_retention_days', 365),
            'sync_log_retention_days' => (int) $get('sync_log_retention_days', 90),
            'record_history_retention_days' => (int) $get('record_history_retention_days', 90),
            // License
            'license_key' => $get('license_key', ''),
            'license_server_url' => $get('license_server_url', ''),
            'license_grace_days' => (int) $get('license_grace_days', 3),
            'license_check_interval' => (int) $get('license_check_interval', 7),
            'license_last_check' => $get('license_last_check', ''),
            'license_status' => $get('license_status', 'Active'),
            'license_error_message' => $get('license_error_message', ''),
            // Upsell
            'upsell_enable' => $b('upsell_enable', false),
            'upsell_dnssec_addon_id' => (int) $get('upsell_dnssec_addon_id', 0),
            'upsell_ddns_addon_id' => (int) $get('upsell_ddns_addon_id', 0),
            'upsell_quota_addon_ids' => $get('upsell_quota_addon_ids', ''),
            'upsell_display_price' => $b('upsell_display_price', true),
            'upsell_custom_url' => $get('upsell_custom_url', ''),
            'upsell_description' => $get('upsell_description', ''),
            // Telegram placeholder
            'telegram_has_token' => !empty($get('telegram_bot_token', '')),
        ];
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Save settings — nhận input array, trả về array result
    // ─────────────────────────────────────────────────────────────────────────

    public function saveSettings(array $input): array
    {
        try {
            $allowed = [
                'module_enabled',
                'default_nameserver_1',
                'default_nameserver_2',
                'default_nameserver_3',
                'default_nameserver_4',
                'default_nameserver_5',
                'default_ttl',
                'respect_whmcs_dns',
                'disable_manage_wrong_ns',
                'ns_check_method',
                'create_on_preregistrar',
                'create_on_registration',
                'create_on_transfer',
                'grace_period_days',
                'enable_dns_editor',
                'subdomain_limit',
                'allow_modify_a',
                'allow_modify_aaaa',
                'allow_modify_cname',
                'allow_modify_mx',
                'allow_modify_txt',
                'allow_modify_srv',
                'allow_modify_caa',
                'allow_modify_ns',
                'total_record_limit',
                'a_record_limit',
                'aaaa_record_limit',
                'cname_record_limit',
                'mx_record_limit',
                'txt_record_limit',
                'srv_record_limit',
                'caa_record_limit',
                'ns_record_limit',
                'enable_url_redirect',
                'enable_masked_redirect',
                'masked_hash_key',
                'url_redirect_limit',
                'enable_email_forwarder',
                'enable_email_catchall',
                'email_forwarder_limit',
                'email_destination_limit',
                'email_verify_template',
                'ddns_mode',
                'ddns_rate_limit',
                'ddns_token_limit',
                'enable_ddns_bruteforce',
                'ddns_bruteforce_threshold',
                'ddns_bruteforce_window',
                'ddns_bruteforce_ban_duration',
                'dnssec_mode',
                'dnssec_auto_resign',
                'enable_auto_ssl',
                'enable_client_ssl_trigger',
                'ssl_auto_renew_days',
                'enable_php_for_domain',
                'enable_dns_templates',
                'enable_user_custom_templates',
                'user_template_limit',
                'enable_client_notification',
                'notification_email_template',
                'notify_on_zone_create',
                'notify_on_record_change',
                'notify_on_zone_delete',
                'show_domain_service_link',
                'show_under_domain_menu',
                'nav_menu_order',
                'show_in_domain_sidebar',
                'fetch_from_ns_on_load',
                'fetch_from_ns_on_load_admin',
                'cache_refresh_ttl',
                'large_db_mode',
                'client_rate_limit',
                'snapshot_retention_count',
                'queue_completed_retention_days',
                'drift_auto_fix',
                'cron_interval',
                'job_timeout',
                'max_retry_attempts',
                'stale_lock_timeout',
                'worker_max_runtime',
                'conflict_window',
                'restrict_subaccounts',
                'audit_trail_retention_days',
                'sync_log_retention_days',
                'record_history_retention_days',
                'license_key',
                'license_server_url',
                'license_grace_days',
                'license_check_interval',
                'upsell_enable',
                'upsell_dnssec_addon_id',
                'upsell_ddns_addon_id',
                'upsell_quota_addon_ids',
                'upsell_display_price',
                'upsell_custom_url',
                'upsell_description',
                'enable_telegram_alert',
                'telegram_chat_id',
                'enable_email_alert',
                'alert_email_addresses',
                'alert_cooldown',
                'alert_failed_threshold',
                'alert_unreachable_threshold',
                'alert_queue_backlog_threshold',
            ];

            $savedCount = 0;
            foreach ($allowed as $key) {
                if (!array_key_exists($key, $input))
                    continue;
                SettingsHelper::set($key, (string) $input[$key]);
                $savedCount++;
            }

            // Telegram token — encrypt riêng
            if (array_key_exists('telegram_bot_token', $input)) {
                $token = trim((string) $input['telegram_bot_token']);
                if (!empty($token)) {
                    if (class_exists('\WHMCS\Security\Encryption')) {
                        try {
                            $token = \WHMCS\Security\Encryption::encode($token);
                        } catch (\Throwable $e) {
                        }
                    }
                    SettingsHelper::set('telegram_bot_token', $token);
                    $savedCount++;
                }
            }

            return ['success' => true, 'message' => "Đã lưu {$savedCount} settings."];
        } catch (\Throwable $e) {
            return ['success' => false, 'error' => $e->getMessage()];
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Test notifications
    // ─────────────────────────────────────────────────────────────────────────

    public function testNotification(): array
    {
        try {
            $notif = new NotificationService();
            $results = $notif->sendTest();
            return ['success' => true, 'data' => $results];
        } catch (\Throwable $e) {
            return ['success' => false, 'error' => $e->getMessage()];
        }
    }

    public function testEmail(array $input): array
    {
        try {
            $rawEmails = trim($input['email_addresses'] ?? '');
            if (empty($rawEmails)) {
                $rawEmails = SettingsHelper::get('alert_email_addresses', '');
            }
            if (empty($rawEmails)) {
                return ['success' => false, 'error' => 'Chưa cấu hình email nhận alert.'];
            }

            $emails = array_filter(array_map('trim', explode(',', $rawEmails)));
            if (empty($emails)) {
                return ['success' => false, 'error' => 'Không có địa chỉ email hợp lệ.'];
            }

            $notif = new NotificationService();
            $subject = '[HVN DNS] Test Email Alert — ' . date('d/m/Y H:i:s');
            $fields = [
                'Job ID' => '#999 (Test)',
                'Action' => 'EDIT_RECORD',
                'Server' => 'dns1.hvn.vn (35.187.230.233)',
                'Attempts' => '5/5',
                'Lỗi' => "cURL error 28: Failed to connect to 35.187.230.233 port 2222 after 21000 ms: Couldn't connect to server",
                'Hướng xử lý' => 'Vào Admin > Sync Logs để xem chi tiết',
            ];

            $ref = new \ReflectionMethod($notif, 'buildEmailBody');
            $ref->setAccessible(true);
            $htmlBody = $ref->invoke($notif, '🔴 Job PERMANENTLY FAILED (Test Email)', NotificationService::COLOR_DANGER, $fields);

            $sentTo = $failed = [];
            foreach ($emails as $email) {
                if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
                    $failed[] = $email . ' (không hợp lệ)';
                    continue;
                }

                $clientRow = Capsule::table('tblclients')->where('email', $email)->select('id')->first();

                if ($clientRow) {
                    $result = localAPI('SendEmail', [
                        'id' => $clientRow->id,
                        'customtype' => 'general',
                        'customsubject' => $subject,
                        'custommessage' => $htmlBody,
                    ]);
                    if (isset($result['result']) && $result['result'] === 'success') {
                        $sentTo[] = $email;
                    } else {
                        $failed[] = $email . ' (WHMCS error: ' . ($result['message'] ?? '?') . ')';
                    }
                } else {
                    $fromDomain = isset($_SERVER['HTTP_HOST']) ? $_SERVER['HTTP_HOST'] : 'whmcs.local';
                    $headers = 'From: HVN DNS Manager <noreply@' . $fromDomain . '>' . "\r\n"
                        . 'Content-Type: text/html; charset=UTF-8' . "\r\n"
                        . 'MIME-Version: 1.0' . "\r\n";
                    if (@mail($email, $subject, $htmlBody, $headers)) {
                        $sentTo[] = $email . ' (mail())';
                    } else {
                        $failed[] = $email . ' (mail() thất bại)';
                    }
                }
            }

            logActivity('HVN DNS Manager: Test email sent to: ' . implode(', ', $sentTo)
                . (empty($failed) ? '' : ' | Failed: ' . implode(', ', $failed)));

            if (!empty($sentTo)) {
                return ['success' => true, 'sent_to' => implode(', ', $sentTo), 'failed' => $failed];
            }
            return ['success' => false, 'error' => 'Không gửi được. ' . implode('; ', $failed)];

        } catch (\Throwable $e) {
            return ['success' => false, 'error' => $e->getMessage()];
        }
    }
}