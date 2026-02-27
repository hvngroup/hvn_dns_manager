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
            'sync_log_detail',
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

        // Mock data cho Sync Log Detail
        if ($template === 'sync_log_detail') {
            $jobId = (int) ($_GET['id'] ?? 0);

            // Mock dataset khớp với sync_logs.tpl
            $mockLogs = [
                4521 => ['id'=>4521,'domain'=>'myblog.net','domain_id'=>101,'action'=>'DELETE_RECORD','details'=>'A @ 1.2.3.4','server_hostname'=>'dns3.hvn.vn','server_is_primary'=>false,'server_use_ssl'=>true,'status'=>'failed','attempt'=>3,'ms'=>null,'batch_id'=>'b1a2c3d4-e5f6-7890-abcd-ef1234567890','actor_type'=>'CLIENT','actor_id'=>42,'actor_ip'=>'203.0.113.10','created_at'=>'2026-02-27 14:32:00','completed_at'=>null,'next_retry'=>'2026-02-27 14:47:00','payload'=>"{\n  \"type\": \"A\",\n  \"name\": \"@\",\n  \"value\": \"1.2.3.4\",\n  \"ttl\": 14400\n}",'error_msg'=>"Connection timeout after 30s\nServer: dns3.hvn.vn:2222\nDA API endpoint: /CMD_API_DNS_CONTROL\nAttempt: 3/5",'da_response'=>null],
                4520 => ['id'=>4520,'domain'=>'shop.vn','domain_id'=>102,'action'=>'ADD_RECORD','details'=>'A mail 203.0.1.10','server_hostname'=>'dns1.hvn.vn','server_is_primary'=>true,'server_use_ssl'=>true,'status'=>'complete','attempt'=>1,'ms'=>89,'batch_id'=>'c2b3d4e5-f6a7-8901-bcde-f01234567891','actor_type'=>'CLIENT','actor_id'=>55,'actor_ip'=>'203.0.113.20','created_at'=>'2026-02-27 14:31:00','completed_at'=>'2026-02-27 14:31:05','next_retry'=>null,'payload'=>"{\n  \"type\": \"A\",\n  \"name\": \"mail\",\n  \"value\": \"203.0.1.10\",\n  \"ttl\": 14400\n}",'error_msg'=>null,'da_response'=>"error=0\ntext=Command completed successfully"],
                4519 => ['id'=>4519,'domain'=>'shop.vn','domain_id'=>102,'action'=>'ADD_RECORD','details'=>'A mail 203.0.1.10','server_hostname'=>'dns2.hvn.vn','server_is_primary'=>false,'server_use_ssl'=>true,'status'=>'complete','attempt'=>1,'ms'=>92,'batch_id'=>'c2b3d4e5-f6a7-8901-bcde-f01234567891','actor_type'=>'CLIENT','actor_id'=>55,'actor_ip'=>'203.0.113.20','created_at'=>'2026-02-27 14:31:00','completed_at'=>'2026-02-27 14:31:06','next_retry'=>null,'payload'=>"{\n  \"type\": \"A\",\n  \"name\": \"mail\",\n  \"value\": \"203.0.1.10\",\n  \"ttl\": 14400\n}",'error_msg'=>null,'da_response'=>"error=0\ntext=Command completed successfully"],
                4518 => ['id'=>4518,'domain'=>'shop.vn','domain_id'=>102,'action'=>'ADD_RECORD','details'=>'A mail 203.0.1.10','server_hostname'=>'dns3.hvn.vn','server_is_primary'=>false,'server_use_ssl'=>true,'status'=>'failed','attempt'=>3,'ms'=>null,'batch_id'=>'c2b3d4e5-f6a7-8901-bcde-f01234567891','actor_type'=>'CLIENT','actor_id'=>55,'actor_ip'=>'203.0.113.20','created_at'=>'2026-02-27 14:31:00','completed_at'=>null,'next_retry'=>'2026-02-27 14:46:00','payload'=>"{\n  \"type\": \"A\",\n  \"name\": \"mail\",\n  \"value\": \"203.0.1.10\",\n  \"ttl\": 14400\n}",'error_msg'=>"Connection timeout after 30s\nServer: dns3.hvn.vn:2222",'da_response'=>null],
                4515 => ['id'=>4515,'domain'=>'myfashion.vn','domain_id'=>103,'action'=>'DELETE_RECORD','details'=>'CNAME www','server_hostname'=>'dns1.hvn.vn','server_is_primary'=>true,'server_use_ssl'=>false,'status'=>'failed','attempt'=>5,'ms'=>null,'batch_id'=>'d3c4e5f6-a7b8-9012-cdef-012345678902','actor_type'=>'ADMIN','actor_id'=>1,'actor_ip'=>'10.0.0.1','created_at'=>'2026-02-27 14:20:00','completed_at'=>null,'next_retry'=>null,'payload'=>"{\n  \"type\": \"CNAME\",\n  \"name\": \"www\",\n  \"value\": \"myfashion.vn.\",\n  \"ttl\": 14400\n}",'error_msg'=>"Auth failed: Invalid DirectAdmin credentials\nUsername: dns_sync_user\nServer: dns1.hvn.vn:2222\nHTTP 401 Unauthorized",'da_response'=>"error=1\ntext=Authentication Failed\ndetails=Invalid username or password"],
                4505 => ['id'=>4505,'domain'=>'realty.com.vn','domain_id'=>104,'action'=>'ADD_RECORD','details'=>'CAA 0 issue le.org','server_hostname'=>'dns1.hvn.vn','server_is_primary'=>true,'server_use_ssl'=>true,'status'=>'pending','attempt'=>0,'ms'=>null,'batch_id'=>'e4d5f6a7-b8c9-0123-def0-123456789003','actor_type'=>'CLIENT','actor_id'=>88,'actor_ip'=>'203.0.113.50','created_at'=>'2026-02-27 13:50:00','completed_at'=>null,'next_retry'=>null,'payload'=>"{\n  \"type\": \"CAA\",\n  \"name\": \"@\",\n  \"flags\": 0,\n  \"tag\": \"issue\",\n  \"value\": \"letsencrypt.org\",\n  \"ttl\": 3600\n}",'error_msg'=>null,'da_response'=>null],
            ];

            // Tìm log theo ID, fallback về log đầu tiên nếu không tìm thấy
            $log = $mockLogs[$jobId] ?? reset($mockLogs);
            $smarty->assign('log', $log);
            $smarty->assign('token', $_SESSION['whmcs']['token'] ?? 'mock_csrf_token_prototype');
        }
        
        // Render wrapper (chứa sidebar + nội dung chính)
        try {
            $smarty->display('wrapper.tpl');
        } catch (\Exception $e) {
            echo "<div class='alert alert-danger'>Lỗi render template: " . $e->getMessage() . "</div>";
        }
    }
}
