<?php
/**
 * MJ - DirectAdmin DNS Manager — WHMCS Addon Module
 *
 * Quản lý DNS DirectAdmin theo kiến trúc Queue bất đồng bộ (async-first).
 *
 * @package    MJ\DnsManager
 * @author     ModuleJET (HVN GROUP)
 * @copyright  2026 HVN GROUP / ModuleJET
 * @license    Proprietary
 * @link       https://modulejet.com
 */

defined("WHMCS") or die("Access Denied");

if (!defined('MJ_DNS_DIR')) {
    define('MJ_DNS_DIR', __DIR__);
}

// Simple internal autoloader for MJ\DnsManager namespace
spl_autoload_register(function ($class) {
    $prefix = 'MJ\\DnsManager\\';
    $base_dir = __DIR__ . '/app/';

    // Does the class use the namespace prefix?
    $len = strlen($prefix);
    if (strncmp($prefix, $class, $len) !== 0) {
        return;
    }

    // Get the relative class name
    $relative_class = substr($class, $len);

    // Replace the namespace prefix with the base directory, replace namespace
    // separators with directory separators in the relative class name, append
    // with .php
    $file = $base_dir . str_replace('\\', '/', $relative_class) . '.php';

    // If the file exists, require it
    if (file_exists($file)) {
        require_once $file;
    }
});

use MJ\DnsManager\Controllers\Client\ClientController;
use MJ\DnsManager\Controllers\Admin\AdminController;

/**
 * Define addon module configuration parameters.
 */
function mj_dns_manager_config()
{
    return [
        'name' => 'MJ - DirectAdmin DNS Manager',
        'description' => 'Quản lý DNS DirectAdmin mạnh mẽ với cơ chế Queue Async',
        'author' => '<a href="https://modulejet.com" target="_blank">ModuleJET</a>',
        'language' => 'english',
        'version' => '1.6.0',
        'fields' => [
            'licenseKey' => [
                'FriendlyName' => 'License Key',
                'Type'         => 'text',
                'Size'         => '50',
                'Default'      => '',
                'Description'  => 'Nhập license key ModuleJET. <a href="https://modulejet.com" target="_blank">Mua license</a>',
            ],
        ],
    ];
}

/**
 * Activate — Run database migration when addon is activated.
 */
function mj_dns_manager_activate()
{
    try {
        // ── 1. Chạy migration tạo bảng ───────────────────────────────────
        $migration = new MJ\DnsManager\Migration\Versions\v0_1_0_prototype();
        $migration->up();

        // ── 2. Seed default settings ──────────────────────────────────────
        // Chỉ insert nếu chưa có (idempotent — activate nhiều lần không bị lỗi)
        $defaults = [

            // Module Core
            'module_enabled' => '1',
            'default_nameserver_1' => 'dns1.hvn.vn',
            'default_nameserver_2' => 'dns2.hvn.vn',
            'default_nameserver_3' => 'dns3.hvn.vn',
            'default_nameserver_4' => '',
            'default_nameserver_5' => '',
            'default_ttl' => '3600',

            // Queue & Cron
            'cron_interval' => '60',
            'job_timeout' => '30',
            'max_retry_attempts' => '5',
            'stale_lock_timeout' => '300',
            'worker_max_runtime' => '55',
            'conflict_window' => '180',

            // Record Permissions
            'allow_modify_a' => '1',
            'allow_modify_aaaa' => '1',
            'allow_modify_cname' => '1',
            'allow_modify_mx' => '1',
            'allow_modify_txt' => '1',
            'allow_modify_srv' => '1',
            'allow_modify_caa' => '1',
            'allow_modify_ns' => '0',

            // Record Limits
            'total_record_limit' => '50',
            'a_record_limit' => '100',
            'aaaa_record_limit' => '100',
            'cname_record_limit' => '100',
            'mx_record_limit' => '100',
            'txt_record_limit' => '100',
            'srv_record_limit' => '100',
            'caa_record_limit' => '20',
            'ns_record_limit' => '10',

            // DNS Editor
            'enable_dns_editor' => '1',
            'subdomain_limit' => '0',

            // URL Redirect
            'enable_url_redirect' => '1',
            'enable_masked_redirect' => '1',
            'masked_hash_key' => '',
            'url_redirect_limit' => '5',

            // Email Forwarding
            'enable_email_forwarder' => '1',
            'enable_email_catchall' => '1',
            'email_forwarder_limit' => '5',
            'email_destination_limit' => '10',
            'email_verify_template' => '',

            // DDNS
            'ddns_mode' => 'off',
            'ddns_rate_limit' => '60',
            'ddns_token_limit' => '5',
            'enable_ddns_bruteforce' => '1',
            'ddns_bruteforce_threshold' => '10',
            'ddns_bruteforce_window' => '3600',
            'ddns_bruteforce_ban_duration' => '3600',

            // DNSSEC
            'dnssec_mode' => 'off',
            'dnssec_auto_resign' => '1',

            // SSL
            'enable_auto_ssl' => '1',
            'enable_client_ssl_trigger' => '1',
            'ssl_auto_renew_days' => '7',
            'enable_php_for_domain' => '1',

            // DNS Templates
            'enable_dns_templates' => '1',
            'enable_user_custom_templates' => '0',
            'user_template_limit' => '10',

            // Client Notification
            'enable_client_notification' => '0',
            'notification_email_template' => '',
            'notify_on_zone_create' => '1',
            'notify_on_record_change' => '1',
            'notify_on_zone_delete' => '1',

            // UI / Navigation
            'show_domain_service_link' => '1',
            'show_under_domain_menu' => '1',
            'nav_menu_order' => '20',
            'show_in_domain_sidebar' => '1',

            // Performance & Cache
            'fetch_from_ns_on_load' => '0',
            'fetch_from_ns_on_load_admin' => '0',
            'cache_refresh_ttl' => '720',
            'large_db_mode' => '0',
            'client_rate_limit' => '30',

            // Domain Policy
            'respect_whmcs_dns' => '0',
            'disable_manage_wrong_ns' => '1',
            'ns_check_method' => 'dns_lookup',
            'create_on_preregistrar' => '1',
            'create_on_registration' => '1',
            'create_on_transfer' => '1',
            'grace_period_days' => '30',

            // DA Domain Provisioning
            'da_web_template' => '',
            'da_enable_php' => '1',

            // Security & Access Control
            'restrict_subaccounts' => '1',
            'audit_trail_retention_days' => '365',
            'sync_log_retention_days' => '90',
            'record_history_retention_days' => '90',

            // Data Retention
            'snapshot_retention_count' => '30',
            'queue_completed_retention_days' => '30',
            'drift_auto_fix' => '0',

            // Webhook & Admin Alert (HVND-46)
            'enable_telegram_alert' => '0',
            'telegram_bot_token' => '',
            'telegram_chat_id' => '',
            'enable_email_alert' => '0',
            'alert_email_addresses' => '',
            'alert_cooldown' => '900',
            'alert_failed_threshold' => '5',
            'alert_unreachable_threshold' => '3',
            'alert_queue_backlog_threshold' => '100',
        ];

        foreach ($defaults as $key => $val) {
            $exists = \Illuminate\Database\Capsule\Manager::table('tbl_mj_dns_settings')
                ->where('setting_key', $key)
                ->exists();

            if (!$exists) {
                \Illuminate\Database\Capsule\Manager::table('tbl_mj_dns_settings')->insert([
                    'setting_key' => $key,
                    'setting_val' => $val,
                ]);
            }
        }

        return [
            'status' => 'success',
            'description' => 'MJ DNS Manager đã kích hoạt và tạo bảng database thành công.',
        ];

    } catch (\Exception $e) {
        return [
            'status' => 'error',
            'description' => 'Migration thất bại: ' . $e->getMessage(),
        ];
    }
}

/**
 * Deactivate — Drop all tbl_mj_dns_* tables.
 * ⚠️  Dùng cho dev/reset. Production: cân nhắc trước khi deactivate.
 */
function mj_dns_manager_deactivate()
{
    try {
        $migration = new MJ\DnsManager\Migration\Versions\v0_1_0_prototype();
        $migration->down();

        return [
            'status' => 'success',
            'description' => 'Đã xóa toàn bộ bảng tbl_mj_dns_*.',
        ];
    } catch (\Exception $e) {
        return [
            'status' => 'error',
            'description' => 'Xóa bảng thất bại: ' . $e->getMessage(),
        ];
    }
}

/**
 * Upgrade.
 */
function mj_dns_manager_upgrade($vars)
{
    $version = $vars['version'];
}

/**
 * Client Area Output.
 */
function mj_dns_manager_clientarea($vars)
{
    $action = isset($_GET['action']) ? $_GET['action'] : '';

    $controller = new ClientController();
    return $controller->dispatch($action, $vars);
}

/**
 * Admin Area Output.
 */
function mj_dns_manager_output($vars)
{
    $action = isset($_GET['action']) ? $_GET['action'] : '';

    // Instantiate mock controller for testing Admin UI
    $controller = new AdminController();
    $controller->dispatch($action, $vars);
}
