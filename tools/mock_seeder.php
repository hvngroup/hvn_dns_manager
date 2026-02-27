<?php

// mock_seeder.php
// Công cụ đổ dữ liệu giả (mock data) cho HVN DNS Manager
// Sử dụng cho Phase 0A (UI-First Prototype)

require_once __DIR__ . '/../vendor/autoload.php';

// Cố gắng include WHMCS init.php nếu có thể
$whmcsInit = dirname(__DIR__, 4) . '/init.php';
if (file_exists($whmcsInit)) {
    require_once $whmcsInit;
} else {
    // Standalone connection for testing (nếu chạy độc lập ngoài WHMCS)
    if (class_exists('Illuminate\Database\Capsule\Manager')) {
        $capsule = new Illuminate\Database\Capsule\Manager;
        $capsule->addConnection([
            'driver'    => 'mysql',
            'host'      => '127.0.0.1',
            'database'  => 'whmcs',
            'username'  => 'root',
            'password'  => '',
            'charset'   => 'utf8mb4',
            'collation' => 'utf8mb4_unicode_ci',
            'prefix'    => '',
        ]);
        $capsule->setAsGlobal();
        $capsule->bootEloquent();
    } else {
        die("Error: Capsule Manager not found. Run 'composer install' or execute within WHMCS environment.\n");
    }
}

use Illuminate\Database\Capsule\Manager as Capsule;

function truncateAll() {
    Capsule::statement('SET FOREIGN_KEY_CHECKS=0;');
    $tables = [
        'mod_hvndns_notification_cooldowns', 'mod_hvndns_ip_blacklist', 'mod_hvndns_drift_reports',
        'mod_hvndns_email_forwards', 'mod_hvndns_redirects', 'mod_hvndns_ddns_tokens',
        'mod_hvndns_dnssec', 'mod_hvndns_templates', 'mod_hvndns_snapshots',
        'mod_hvndns_record_history', 'mod_hvndns_audit_trail', 'mod_hvndns_sync_logs',
        'mod_hvndns_queue', 'mod_hvndns_records', 'mod_hvndns_domains',
        'mod_hvndns_servers', 'mod_hvndns_settings',
        'mod_hvndns_schema_version'
    ];
    foreach ($tables as $table) {
        if (Capsule::schema()->hasTable($table)) {
            Capsule::table($table)->truncate();
        }
    }
    Capsule::statement('SET FOREIGN_KEY_CHECKS=1;');
    echo "[OK] Truncated all tables.\n";
}

function seedSettings() {
    $settings = [
        ['setting_key' => 'module_enabled', 'setting_val' => '1'],
        ['setting_key' => 'license_key', 'setting_val' => 'hvndns-TESTKEY'],
        ['setting_key' => 'default_nameserver_1', 'setting_val' => 'dns1.hvn.vn'],
        ['setting_key' => 'default_nameserver_2', 'setting_val' => 'dns2.hvn.vn'],
        ['setting_key' => 'default_ttl', 'setting_val' => '3600'],
        ['setting_key' => 'admin_debug_mode', 'setting_val' => '1']
    ];
    Capsule::table('mod_hvndns_settings')->insert($settings);
    echo "[OK] Seeded settings.\n";
}

function seedServers() {
    $servers = [
        [
            'hostname' => 'da1.hvn.vn',
            'ip_address' => '103.111.9.111',
            'port' => 2222,
            'username' => 'admin',
            'password_enc' => 'encrypted_mock_password', // Mock encrypted
            'role' => 'primary',
            'is_active' => 1,
            'max_concurrent' => 50
        ],
        [
            'hostname' => 'da2.hvn.vn',
            'ip_address' => '103.111.9.112',
            'port' => 2222,
            'username' => 'admin',
            'password_enc' => 'encrypted_mock_password',
            'role' => 'secondary',
            'is_active' => 1,
            'max_concurrent' => 50
        ]
    ];
    Capsule::table('mod_hvndns_servers')->insert($servers);
    echo "[OK] Seeded DirectAdmin servers.\n";
}

function seedDomainsAndRecords() {
    $userId = 1; // mock client ID

    // Domain 1: Example.com
    $domainId1 = Capsule::table('mod_hvndns_domains')->insertGetId([
        'domain' => 'example.com',
        'whmcs_user_id' => $userId,
        'status' => 'active',
        'provisioned_at' => date('Y-m-d H:i:s')
    ]);

    $records = [
        ['domain_id' => $domainId1, 'type' => 'A', 'name' => '@', 'value' => '192.168.1.1', 'ttl' => 3600, 'is_system' => 1],
        ['domain_id' => $domainId1, 'type' => 'CNAME', 'name' => 'www', 'value' => 'example.com.', 'ttl' => 3600, 'is_system' => 0],
        ['domain_id' => $domainId1, 'type' => 'MX', 'name' => '@', 'value' => 'mail.example.com.', 'priority' => 10, 'ttl' => 3600, 'is_system' => 0]
    ];
    Capsule::table('mod_hvndns_records')->insert($records);

    // Domain 2: My-shop.vn
    $domainId2 = Capsule::table('mod_hvndns_domains')->insertGetId([
        'domain' => 'my-shop.vn',
        'whmcs_user_id' => $userId,
        'status' => 'active',
        'provisioned_at' => date('Y-m-d H:i:s')
    ]);

    $records2 = [
        ['domain_id' => $domainId2, 'type' => 'A', 'name' => '@', 'value' => '10.0.0.5', 'ttl' => 3600, 'is_system' => 0],
        ['domain_id' => $domainId2, 'type' => 'TXT', 'name' => '@', 'value' => '"v=spf1 -all"', 'ttl' => 3600, 'is_system' => 0]
    ];
    Capsule::table('mod_hvndns_records')->insert($records2);
    
    echo "[OK] Seeded domains and DNS records.\n";
    return [$domainId1, $domainId2];
}

function seedQueueAndLogs($domainIds) {
    if (empty($domainIds)) return;
    $domainId = $domainIds[0];
    
    $jobId = Capsule::table('mod_hvndns_queue')->insertGetId([
        'batch_id' => '123e4567-e89b-12d3-a456-426614174000',
        'domain_id' => $domainId,
        'server_id' => 1,
        'action' => 'ADD_RECORD',
        'payload' => json_encode(['type' => 'A', 'name' => 'test', 'value' => '1.2.3.4']),
        'status' => 'COMPLETE',
        'attempts' => 1,
        'actor_type' => 'client',
        'actor_id' => 1,
        'started_at' => date('Y-m-d H:i:s'),
        'completed_at' => date('Y-m-d H:i:s')
    ]);

    Capsule::table('mod_hvndns_sync_logs')->insert([
        'queue_id' => $jobId,
        'server_id' => 1,
        'http_method' => 'POST',
        'http_url' => '/CMD_API_DNS_CONTROL',
        'http_status' => 200,
        'request_body' => 'domain=example.com&action=add&type=A&name=test&value=1.2.3.4',
        'response_body' => 'error=0&text=Record Added',
        'duration_ms' => 150,
        'success' => 1
    ]);

    Capsule::table('mod_hvndns_queue')->insert([
        'batch_id' => '123e4567-e89b-12d3-a456-426614174001',
        'domain_id' => $domainIds[1],
        'server_id' => 1,
        'action' => 'EDIT_RECORD',
        'payload' => json_encode(['old_value' => '1.1.1.1', 'new_value' => '8.8.8.8']),
        'status' => 'FAILED',
        'attempts' => 3,
        'error_message' => 'Connection timeout from DirectAdmin server',
        'next_retry_at' => date('Y-m-d H:i:s', strtotime('+5 minutes')),
        'actor_type' => 'client',
        'actor_id' => 1
    ]);

    echo "[OK] Seeded queue jobs and sync logs.\n";
}

function seedAuditTrail() {
    Capsule::table('mod_hvndns_audit_trail')->insert([
        'actor_type' => 'admin',
        'actor_id' => 1,
        'actor_name' => 'Administrator',
        'domain' => 'example.com',
        'domain_id' => 1,
        'action' => 'domain_suspended',
        'context' => 'Billing overdue (Mock Data)',
        'ip_address' => '192.168.0.100',
        'user_agent' => 'Mozilla/5.0'
    ]);
    echo "[OK] Seeded audit trail.\n";
}

try {
    echo "=== Starting Mock Seeder Phase 0A ===\n";
    truncateAll();
    seedSettings();
    seedServers();
    $domainIds = seedDomainsAndRecords();
    seedQueueAndLogs($domainIds);
    seedAuditTrail();
    
    // Lưu phiên bản schema
    Capsule::table('mod_hvndns_schema_version')->insert([
        'version' => 'v0.1.0-prototype',
        'description' => 'Initial Mock Seeder run',
        'executed_at' => date('Y-m-d H:i:s')
    ]);

    echo "=== Mock Seeding Completed Successfully! ===\n";
} catch (\Exception $e) {
    echo "ERROR SEEDING DATA: " . $e->getMessage() . "\n";
}
