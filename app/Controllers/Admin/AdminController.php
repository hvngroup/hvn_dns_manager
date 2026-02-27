<?php

namespace HvnGroup\DnsManager\Controllers\Admin;

/**
 * Controller mock phục vụ cho Prototype UI Phase 0D (Admin).
 * Sẽ được refactor thành logic thật trong Phase 2/3.
 */
class AdminController
{
    /**
     * Entry point của Admin Area
     */
    public function dispatch($action, $params)
    {
        $template = 'dashboard';
        
        $validActions = [
            'servers', 'domains', 'dns_editor', 'admin_dns_editor', 'sync_logs', 
            'audit_trail', 'templates', 'quota_plans', 
            'drift_reports', 'bulk', 'settings',
            'server_edit', 'quota_plan_edit', 'template_edit',
            'drift_settings', 'audit_detail', 'snapshot_rollback'
        ];

        // Alias: action name → template name
        $actionTemplateMap = [
            'admin_dns_editor' => 'dns_editor',
        ];

        if (in_array($action, $validActions)) {
            $template = $actionTemplateMap[$action] ?? $action;
        }

        // Setup Smarty cho Admin Area
        global $templates_compiledir;
        $smarty = new \Smarty();
        $smarty->template_dir = dirname(dirname(dirname(__DIR__))) . '/templates/admin/';
        $smarty->compile_dir = $templates_compiledir;
        
        // Disable notice/warning for missing variables in mock dev
        $smarty->error_reporting = E_ALL & ~E_NOTICE & ~E_WARNING;

        $smarty->assign('modulelink', $params['modulelink']);
        $smarty->assign('action', $action ?: 'dashboard');
        $smarty->assign('template_name', $template);
        
        // Mock data cho Dashboard
        if ($template === 'dashboard') {
            $smarty->assign('dashboard', ['hasCriticalAlert' => true]);
        }
        
        // Render wrapper (chứa sidebar + nội dung chính)
        try {
            $smarty->display('wrapper.tpl');
        } catch (\Exception $e) {
            echo "<div class='alert alert-danger'>Lỗi render template: " . $e->getMessage() . "</div>";
        }
    }
}
