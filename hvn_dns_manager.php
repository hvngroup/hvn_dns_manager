<?php
/**
 * WHMCS SDK Sample Addon Module
 *
 * An addon module allows you to add additional functionality to WHMCS. It
 * can provide both client and admin facing user interfaces, as well as
 * utilise hook functionality within WHMCS.
 *
 * @see https://developers.whmcs.com/addon-modules/
 */

if (!defined("WHMCS")) {
    die("This file cannot be accessed directly");
}

// Simple internal autoloader for HvnGroup\DnsManager namespace
spl_autoload_register(function ($class) {
    $prefix = 'HvnGroup\\DnsManager\\';
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
        require $file;
    }
});

use HvnGroup\DnsManager\Controllers\Client\ClientController;
use HvnGroup\DnsManager\Controllers\Admin\AdminController;
use HvnGroup\DnsManager\Migration\Versions\v0_1_0_prototype;
use Illuminate\Database\Capsule\Manager as Capsule;

/**
 * Define addon module configuration parameters.
 */
function hvn_dns_manager_config()
{
    return [
        'name' => 'HVN - DirectAdmin DNS Manager',
        'description' => 'Quản lý DNS DirectAdmin mạnh mẽ với cơ chế Queue Async',
        'author' => 'Vuongnm',
        'language' => 'english',
        'version' => '1.5',
        'fields' => []
    ];
}

/**
 * Activate.
 *
 * Chạy DB migration trực tiếp trong hàm activate của module — đây là nơi WHMCS
 * dành riêng cho logic kích hoạt addon module. Migration là idempotent
 * (kiểm tra hasTable trước khi tạo) nên kích hoạt lại nhiều lần vẫn an toàn.
 */
function hvn_dns_manager_activate()
{
    try {
        $migration = new v0_1_0_prototype();
        $migration->up();

        // Ghi version vào bảng tracking (UNIQUE trên version đảm bảo không trùng)
        $version = '0.1.0';
        $alreadyStamped = Capsule::table('mod_hvndns_schema_version')
            ->where('version', $version)
            ->exists();
        if (!$alreadyStamped) {
            Capsule::table('mod_hvndns_schema_version')->insert([
                'version' => $version,
                'description' => 'Initial prototype schema',
                'executed_at' => date('Y-m-d H:i:s'),
            ]);
        }

        logActivity('HVN DNS Manager: Khởi tạo cơ sở dữ liệu thành công (schema ' . $version . ').');

        return [
            'status' => 'success',
            'description' => 'Bật thành công. Đã khởi tạo cơ sở dữ liệu.',
        ];
    } catch (\Exception $e) {
        logActivity('HVN DNS Manager Error: Migration khi kích hoạt thất bại - ' . $e->getMessage());

        return [
            'status' => 'error',
            'description' => 'Không thể khởi tạo cơ sở dữ liệu: ' . $e->getMessage(),
        ];
    }
}

/**
 * Deactivate.
 */
function hvn_dns_manager_deactivate()
{
    // Do not drop tables on deactivate to prevent data loss
    return [
        'status' => 'success',
        'description' => 'Tắt thành công.',
    ];
}

/**
 * Upgrade.
 */
function hvn_dns_manager_upgrade($vars)
{
    $version = $vars['version'];
}

/**
 * Client Area Output.
 */
function hvn_dns_manager_clientarea($vars)
{
    $action = isset($_REQUEST['action']) ? $_REQUEST['action'] : '';
    
    $controller = new ClientController();
    return $controller->dispatch($action, $vars);
}

/**
 * Admin Area Output.
 */
function hvn_dns_manager_output($vars)
{
    $action = isset($_REQUEST['action']) ? $_REQUEST['action'] : '';
    
    // Instantiate mock controller for testing Admin UI
    $controller = new AdminController();
    $controller->dispatch($action, $vars);
}
