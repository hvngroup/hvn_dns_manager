<?php

/**
 * HVN DNS Manager - WHMCS Hooks
 */

if (!defined("WHMCS")) {
    die("This file cannot be accessed directly");
}

use HvnGroup\DnsManager\Migration\Versions\v0_1_0_prototype;
use Illuminate\Database\Capsule\Manager as Capsule;

add_hook('AddonActivation', 1, function($vars) {
    // Only run if this module is being activated
    if ($vars['module'] === 'hvndns') {
        try {
            // Run Phase 0A/0B DB Migration
            $migration = new v0_1_0_prototype();
            $migration->up();

            // Log successful activation migration
            logActivity("HVN DNS Manager: Successfully ran database migrations.");
        } catch (\Exception $e) {
            logActivity("HVN DNS Manager Error: Failed to run migrations - " . $e->getMessage());
            return ['status' => 'error', 'description' => 'Could not run migrations: ' . $e->getMessage()];
        }
    }
});
