<?php

/**
 * MJ DNS Manager — WHMCS Hook Entry Point
 *
 * Flow hiện tại (Phase 1 MVP):
 *   AcceptOrder  → Insert vào tbl_mj_dns_domains + tbl_mj_dns_queue
 *                → QueueWorker::runOnce() xử lý ngay lập tức
 *                → Nếu thất bại: job ở lại queue để retry
 *
 *   AfterCronJob → QueueWorker->run() xử lý tất cả PENDING jobs
 *                → Chạy mỗi lần WHMCS cron.php được gọi (thường 5 phút/lần)
 *                → Đây là cơ chế chính xử lý ADD_RECORD, EDIT_RECORD, DELETE_RECORD
 */

if (!defined('WHMCS')) {
    die('This file cannot be accessed directly');
}

// Simple internal autoloader for MJ\DnsManager namespace
spl_autoload_register(function ($class) {
    $prefix = 'MJ\\DnsManager\\';
    $base_dir = __DIR__ . '/app/';
    $len = strlen($prefix);
    if (strncmp($prefix, $class, $len) !== 0) {
        return;
    }
    $relative_class = substr($class, $len);
    $file = $base_dir . str_replace('\\', '/', $relative_class) . '.php';
    if (file_exists($file)) {
        require_once $file;
    }
});

use MJ\DnsManager\Hooks\AcceptOrderHook;
use MJ\DnsManager\Cron\QueueWorker;
use MJ\DnsManager\Migration\Versions\v0_1_0_prototype;

// ─── Module Activation ────────────────────────────────────────────────────────

add_hook('AddonActivation', 1, function ($vars) {
    if ($vars['module'] === 'mj_dns_manager') {
        try {
            $migration = new v0_1_0_prototype();
            $migration->up();
            logActivity('MJ DNS Manager: Database migrations completed successfully.');
        } catch (\Exception $e) {
            logActivity('MJ DNS Manager Error: Migration failed — ' . $e->getMessage());
            return ['status' => 'error', 'description' => 'Could not run migrations: ' . $e->getMessage()];
        }
    }
});

// ─── Client Area Navigation ───────────────────────────────────────────────────

add_hook('ClientAreaPrimaryNavbar', 1, function ($primaryNavbar) {
    $primaryNavbar->addChild('MJ - DirectAdmin DNS Manager', [
        'label' => 'Domain Manager',
        'uri' => 'index.php?m=mj_dns_manager',
        'order' => 20,
    ]);
});

// ─── DNS Queue Worker — chạy theo WHMCS Cron (thường mỗi 5 phút) ─────────────

/**
 * AfterCronJob — Fires every time WHMCS crons/cron.php executes.
 *
 * Đây là cơ chế chính để xử lý DNS queue jobs từ Client/Admin:
 *   ADD_RECORD, EDIT_RECORD, DELETE_RECORD, CREATE_ZONE, DELETE_ZONE, ...
 *
 * Điều kiện để hook này hoạt động:
 *   - WHMCS crons/cron.php phải được setup chạy định kỳ
 *   - Bảng tbl_mj_dns_queue phải tồn tại (migration đã chạy)
 *   - Phải có ít nhất 1 server với role=primary và is_active=1
 */
add_hook('AfterCronJob', 1, function ($vars) {
    // Guard: bảng queue phải tồn tại trước khi chạy
    try {
        if (!\WHMCS\Database\Capsule::schema()->hasTable('tbl_mj_dns_queue')) {
            return;
        }
    } catch (\Exception $e) {
        return;
    }

    try {
        $worker = new QueueWorker();
        $worker->run();
    } catch (\Throwable $e) {
        logActivity('MJ DNS Manager [AfterCronJob Error]: ' . $e->getMessage()
            . ' in ' . basename($e->getFile()) . ':' . $e->getLine());
    }

    try {
        $sslChecker = new \MJ\DnsManager\Cron\SslChecker();
        $sslChecker->run();
    } catch (\Throwable $e) {
        logActivity('MJ DNS Manager [SslChecker Error]: ' . $e->getMessage()
            . ' in ' . basename($e->getFile()) . ':' . $e->getLine());
    }

    try {
        $driftChecker = new \MJ\DnsManager\Cron\DriftChecker();
        $driftChecker->run();
    } catch (\Throwable $e) {
        logActivity('MJ DNS Manager [DriftChecker Error]: ' . $e->getMessage()
            . ' in ' . basename($e->getFile()) . ':' . $e->getLine());
    }

    // Force-run SSL/Drift theo yêu cầu admin (async: admin chỉ set flag ở request,
    // cron — được phép gọi DA — thực thi tại đây rồi xóa flag).
    try {
        $report = new \MJ\DnsManager\Services\ReportService();

        $ssl = \MJ\DnsManager\Helpers\SettingsHelper::get('force_ssl_check', '');
        if ($ssl !== '') {
            \MJ\DnsManager\Helpers\SettingsHelper::set('force_ssl_check', '');
            $report->runSslCheck($ssl === 'all' ? 0 : (int) $ssl);
        }

        $drift = \MJ\DnsManager\Helpers\SettingsHelper::get('force_drift_check', '');
        if ($drift !== '') {
            \MJ\DnsManager\Helpers\SettingsHelper::set('force_drift_check', '');
            if ($drift === 'all') {
                $report->runDriftScanAll();
            } elseif (strncmp($drift, 'name:', 5) === 0) {
                $report->runDriftScanByName(substr($drift, 5));
            } elseif (strncmp($drift, 'id:', 3) === 0) {
                $report->runDriftCheck((int) substr($drift, 3));
            }
        }
    } catch (\Throwable $e) {
        logActivity('MJ DNS Manager [ForceRun Error]: ' . $e->getMessage()
            . ' in ' . basename($e->getFile()) . ':' . $e->getLine());
    }
});

// ─── DNS Zone Auto-Provisioning (Accept Order Flow) ───────────────────────────

/**
 * AcceptOrder — Fires when admin accepts an order.
 *
 * Flow:
 *   1. Get domain items from the order
 *   2. Insert into tbl_mj_dns_domains + tbl_mj_dns_queue (PENDING)
 *   3. Call QueueWorker::runOnce() to process immediately (best-effort)
 *   4. If DA API fails: job stays PENDING, AfterCronJob sẽ retry
 */
add_hook('AcceptOrder', 1, function ($params) {
    AcceptOrderHook::handle($params);
});