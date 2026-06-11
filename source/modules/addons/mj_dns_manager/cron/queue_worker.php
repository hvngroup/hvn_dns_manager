<?php

/**
 * MJ DNS Manager — Dedicated Cron Worker Entry Point
 *
 * Requirements:
 * - WHMCS 8.x
 * - PHP CLI 7.4+
 * 
 * Usage:
 * Set up a system cronjob to run this file every minute.
 * * * * * php -q /path/to/whmcs/modules/addons/mj_dns_manager/cron/queue_worker.php
 */

// Define WHMCS context
if (!defined('WHMCS')) {
    define('WHMCS', true);
}

// Find WHMCS init.php
$initPath = dirname(__DIR__, 4) . '/init.php';
if (file_exists($initPath)) {
    require_once $initPath;
} elseif (file_exists(dirname(__DIR__, 3) . '/init.php')) {
    // Fallback if installed differently
    require_once dirname(__DIR__, 3) . '/init.php';
} else {
    die("FATAL: Cannot find WHMCS init.php\n");
}

// Prevent running from browser (must be CLI)
if (php_sapi_name() !== 'cli') {
    die("FATAL: This script can only be run from the command line.\n");
}

// Simple internal autoloader for MJ\DnsManager namespace
spl_autoload_register(function ($class) {
    $prefix = 'MJ\\DnsManager\\';
    $base_dir = dirname(__DIR__) . '/app/';

    $len = strlen($prefix);
    if (strncmp($prefix, $class, $len) !== 0) {
        return;
    }

    $relative_class = substr($class, $len);
    $file = $base_dir . str_replace('\\', '/', $relative_class) . '.php';

    if (file_exists($file)) {
        require $file;
    }
});

use MJ\DnsManager\Cron\QueueWorker;

// Execute the worker
try {
    $worker = new QueueWorker();
    $worker->run();
} catch (\Throwable $e) {
    if (function_exists('logActivity')) {
        logActivity('MJ DNS Manager [Cron Fatal Error]: ' . $e->getMessage());
    }
    echo "Worker failed: " . $e->getMessage() . "\n";
    exit(1);
}

exit(0);
