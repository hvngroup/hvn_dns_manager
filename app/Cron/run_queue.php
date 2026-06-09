<?php

/**
 * HVN DNS Manager — Cron Entry Point
 *
 * This file is the WHMCS-registered cron entry point.
 * All actual cron logic lives in app/Cron/QueueWorker.php.
 *
 * Register in WHMCS Admin > Configuration > Automation Settings:
 *   File path: modules/addons/hvn_dns_manager/app/Cron/run_queue.php
 *
 * Or via system cron (more reliable):
 *   * * * * * php /path/to/whmcs/app/Cron/run_queue.php
 */

// ─── Bootstrap WHMCS ───────────────────────────────────────────────────────────
// Traverse up from app/Cron/ to find WHMCS init.php
$whmcsRoot = dirname(__DIR__, 4); // hvn_dns_manager/app/Cron → modules/addons → modules → whmcs_root

if (!file_exists($whmcsRoot . '/init.php')) {
    // Fallback: try to find init.php by checking known relative paths
    $candidatePaths = [
        dirname(__DIR__, 4) . '/init.php',
        dirname(__DIR__, 5) . '/init.php',
    ];

    $found = false;
    foreach ($candidatePaths as $path) {
        if (file_exists($path)) {
            $whmcsRoot = dirname($path);
            $found = true;
            break;
        }
    }

    if (!$found) {
        die('ERROR: Cannot find WHMCS init.php. Please verify the cron file path.');
    }
}

define('WHMCS_APP_ROOT', $whmcsRoot);

// Only allow cron execution (not HTTP)
if (!defined('STDIN') && php_sapi_name() !== 'cli') {
    // Allow WHMCS scheduled task calls (they run via HTTP internally)
    // but not direct browser access
    if (empty($_SERVER['argv'])) {
        header('HTTP/1.0 403 Forbidden');
        die('Direct browser access is not allowed.');
    }
}

// ─── Run the Queue Worker ──────────────────────────────────────────────────────
use HvnGroup\DnsManager\Cron\QueueWorker;

$worker = new QueueWorker();
$worker->run();
