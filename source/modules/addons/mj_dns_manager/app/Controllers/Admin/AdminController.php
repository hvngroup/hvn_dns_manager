<?php

namespace MJ\DnsManager\Controllers\Admin;

defined("WHMCS") or die("Access Denied");

use MJ\DnsManager\Services\DashboardService;
use MJ\DnsManager\Services\ZoneManager;
use MJ\DnsManager\Services\RecordManager;
use MJ\DnsManager\Services\ReportService;
use MJ\DnsManager\Services\SettingsService;
use MJ\DnsManager\Security\Csrf;
use Illuminate\Database\Capsule\Manager as Capsule;

class AdminController
{
    private \Smarty $smarty;

    // ─────────────────────────────────────────────────────────────────────────
    // Dispatch
    // ─────────────────────────────────────────────────────────────────────────

    public function dispatch($action, $params): void
    {
        if ($action === 'ajax') {
            $this->handleAjax($params);
            return;
        }

        if (!$this->tablesExist()) {
            echo '<div style="margin:30px;padding:20px;background:#fff3cd;border:1px solid #ffc107;border-radius:6px">
                <h4>⚠️ Database chưa được khởi tạo</h4>
                <p>Bảng <code>tbl_mj_dns_*</code> chưa tồn tại. Vui lòng:</p>
                <ol>
                    <li>Vào <strong>Admin &rsaquo; Addons &rsaquo; MJ DNS Manager</strong></li>
                    <li>Bấm <strong>Deactivate</strong> rồi <strong>Activate</strong> lại module</li>
                    <li>Migration sẽ tự chạy và tạo các bảng</li>
                </ol>
            </div>';
            return;
        }

        $validActions = [
            'servers',
            'domains',
            'dns_editor',
            'admin_dns_editor',
            'sync_logs',
            'sync_log_detail',
            'audit_trail',
            'templates',
            'drift_reports',
            'bulk',
            'settings',
            'server_edit',
            'template_edit',
            'drift_settings',
            'audit_detail',
            'snapshot_rollback',
            'ajax',
        ];

        $actionTemplateMap = [
            'admin_dns_editor' => 'dns_editor',
        ];

        $template = in_array($action, $validActions)
            ? ($actionTemplateMap[$action] ?? $action)
            : 'dashboard';

        global $templates_compiledir;
        $this->smarty = new \Smarty();
        $this->smarty->template_dir = dirname(dirname(dirname(__DIR__))) . '/templates/admin/';
        $this->smarty->compile_dir  = $templates_compiledir;
        $this->smarty->error_reporting = E_ALL & ~E_NOTICE & ~E_WARNING;

        $pageTitles = [
            'dashboard'         => 'Dashboard',
            'servers'           => 'Servers',
            'server_edit'       => 'Server',
            'domains'           => 'Domains',
            'dns_editor'        => 'DNS Editor',
            'sync_logs'         => 'Sync Logs',
            'sync_log_detail'   => 'Sync Log',
            'audit_trail'       => 'Audit Trail',
            'audit_detail'      => 'Audit Detail',
            'templates'         => 'Templates',
            'template_edit'     => 'Template',
            'drift_reports'     => 'Drift Reports',
            'drift_settings'    => 'Drift Settings',
            'bulk'              => 'Bulk Operations',
            'snapshot_rollback' => 'Snapshot Rollback',
            'settings'          => 'Settings',
        ];

        $this->smarty->assign('modulelink', $params['modulelink']);
        $this->smarty->assign('action',        $action ?: 'dashboard');
        $this->smarty->assign('template_name', $template);
        $this->smarty->assign('page_title',    $pageTitles[$template] ?? 'Dashboard');
        $this->smarty->assign('mj_version',    (string) ($params['version'] ?? ''));

        // Pill trạng thái license trên appbar (đọc cache fail-open — không call-home).
        try {
            $licStatus = (string) \MJ\DnsManager\Helpers\SettingsHelper::get('license_status', '');
        } catch (\Throwable $e) {
            $licStatus = '';
        }
        $licMap = [
            'Active'    => ['pill-success', 'LICENSED'],
            'Invalid'   => ['pill-danger',  'INVALID'],
            'Expired'   => ['pill-warning', 'EXPIRED'],
            'Suspended' => ['pill-danger',  'SUSPENDED'],
        ];
        [$licPill, $licLabel] = $licMap[$licStatus] ?? ['pill-neutral', 'NO KEY'];
        $this->smarty->assign('mj_license_pill',  $licPill);
        $this->smarty->assign('mj_license_label', $licLabel);
        // Assets inline từ disk (config + CSS + JS + Alpine) — hooks.md §7.2/§7.3.
        $this->smarty->assign('mjAssetsHtml',  \MJ\DnsManager\Helpers\AssetInliner::adminHtml($params));
        // Admin self-token (CSRF) — mọi AJAX/form mutation phải gửi kèm token này.
        $this->smarty->assign('token',         Csrf::adminToken());

        // Bọc toàn bộ action + render: lỗi service/template KHÔNG được phép trả
        // HTTP 500 trắng trang — log vào Activity Log + hiện thông báo MJ có chi tiết.
        try {
        switch ($template) {
            case 'dashboard':
                $this->actionDashboard();
                break;
            case 'sync_logs':
                $this->actionSyncLogs();
                break;
            case 'sync_log_detail':
                $this->actionSyncLogDetail();
                break;
            case 'servers':
                $this->actionServers();
                break;
            case 'server_edit':
                $this->actionServerEdit();
                break;
            case 'domains':
                $this->actionDomains();
                break;
            case 'audit_trail':
                $this->actionAuditTrail();
                break;
            case 'audit_detail':
                $this->actionAuditDetail();
                break;
            case 'dns_editor':
                $this->actionAdminDnsEditor();
                break;
            case 'settings':
                $this->actionSettings();
                break;
            case 'drift_reports':
                $this->actionDriftReports();
                break;
            case 'templates':
                $this->actionTemplates();
                break;
            case 'template_edit':
                $this->actionTemplateEdit();
                break;
            default:
                break;
        }

            $this->smarty->display('wrapper.tpl');
        } catch (\Throwable $e) {
            logActivity('MJ DNS Manager [Admin/' . $template . ']: ' . $e->getMessage()
                . ' @ ' . basename($e->getFile()) . ':' . $e->getLine());
            echo '<div style="margin:24px;padding:16px 20px;background:#FDECEC;border:1px solid #F5BDBD;'
                . 'border-radius:10px;font-family:Inter,system-ui,sans-serif;color:#A52828;line-height:1.6;">'
                . '<strong>MJ DNS Manager — Không tải được trang &ldquo;' . htmlspecialchars($template) . '&rdquo;.</strong><br>'
                . 'Lỗi đã ghi vào <em>Utilities &rsaquo; Logs &rsaquo; Activity Log</em>. Chi tiết: '
                . '<code style="background:#fff;padding:2px 6px;border-radius:4px;">' . htmlspecialchars($e->getMessage()) . '</code>'
                . '</div>';
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // AJAX dispatcher
    // ─────────────────────────────────────────────────────────────────────────

    private function handleAjax(array $params): void
    {
        while (ob_get_level()) {
            ob_end_clean();
        }
        header('Content-Type: application/json; charset=utf-8');

        // Parse JSON body nếu có
        $contentType = isset($_SERVER['CONTENT_TYPE']) ? $_SERVER['CONTENT_TYPE'] : '';
        if (strpos($contentType, 'application/json') !== false) {
            $raw = file_get_contents('php://input');
            if ($raw) {
                $decoded = json_decode($raw, true);
                if (is_array($decoded)) {
                    $_POST = array_merge($_POST, $decoded);
                }
            }
        }

        // CSRF [WHMCS-REQUIRED]: mọi mutation (non-GET) phải có admin self-token hợp lệ.
        // GET chỉ-đọc không áp CSRF (không gây side-effect). So sánh bằng hash_equals().
        $requestMethod = strtoupper($_SERVER['REQUEST_METHOD'] ?? 'GET');
        if ($requestMethod !== 'GET' && !Csrf::validateAdmin(Csrf::tokenFromRequest())) {
            http_response_code(403);
            echo json_encode(['success' => false, 'error' => ['code' => 'CSRF_FAILED', 'message' => 'CSRF Token không hợp lệ.']]);
            exit;
        }

        $method = isset($_POST['method']) ? $_POST['method'] : (isset($_GET['method']) ? $_GET['method'] : '');

        $methodMap = [
            // Dashboard
            'getDashboardStats'    => 'ajaxGetDashboardStats',
            // Queue / Jobs
            'runPendingJobs'       => 'ajaxRunPendingJobs',
            'retryJob'             => 'ajaxRetryJob',
            'retryAllFailed'       => 'ajaxRetryAllFailed',
            'cancelJob'            => 'ajaxCancelJob',
            // Server
            'testConnection'       => 'ajaxTestConnection',
            'toggleServerStatus'   => 'ajaxToggleServerStatus',
            'resetServerBackoff'   => 'ajaxResetServerBackoff',
            // DNS Records (Admin)
            'adminAddRecord'       => 'ajaxAdminAddRecord',
            'adminEditRecord'      => 'ajaxAdminEditRecord',
            'adminDeleteRecord'    => 'ajaxAdminDeleteRecord',
            'adminToggleLock'      => 'ajaxAdminToggleLock',
            // Settings
            'saveSettings'         => 'ajaxSaveSettings',
            'testNotification'     => 'ajaxTestNotification',
            'testEmail'            => 'ajaxTestEmail',
            // Drift / SSL
            'runSslCheck'          => 'ajaxRunSslCheck',
            'runDriftCheck'        => 'ajaxRunDriftCheck',
            'runDriftScanByName'   => 'ajaxRunDriftScanByName',
            'runDriftScanAll'      => 'ajaxRunDriftScanAll',
            'resolveDrift'         => 'ajaxResolveDrift',
        ];

        if (isset($methodMap[$method])) {
            $callable = $methodMap[$method];
            $this->$callable();
        } else {
            echo json_encode(['success' => false, 'error' => 'Invalid ajax method']);
        }
        exit;
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Page actions — chỉ gọi Service, assign Smarty
    // ─────────────────────────────────────────────────────────────────────────

    private function actionDashboard(): void
    {
        $this->smarty->assign('dashboard', (new DashboardService())->getPageData());
    }

    private function actionSyncLogs(): void
    {
        $data = (new ReportService())->getSyncLogs();
        $this->smarty->assign('syncLogsJson',    json_encode($data['logs'], JSON_UNESCAPED_UNICODE | JSON_HEX_TAG));
        $this->smarty->assign('serverHostnames', $data['serverHostnames']);
    }

    private function actionSyncLogDetail(): void
    {
        $data = (new ReportService())->getSyncLogDetail((int) ($_GET['id'] ?? 0));
        $this->smarty->assign('log',   $data['log'] ?? null);
        $this->smarty->assign('error', $data['error'] ?? null);
    }

    private function actionServers(): void
    {
        $servers = (new ZoneManager())->getServersForList();
        $this->smarty->assign('serversJson', json_encode($servers, JSON_UNESCAPED_UNICODE | JSON_HEX_TAG));
    }

    private function actionServerEdit(): void
    {
        $flash = $_SESSION['mj_dns_flash'] ?? null;
        unset($_SESSION['mj_dns_flash']);
        $this->smarty->assign('flash', $flash);

        if ($_SERVER['REQUEST_METHOD'] === 'POST') {
            // CSRF [WHMCS-REQUIRED]: form lưu server gửi kèm hidden input "token".
            if (!Csrf::validateAdmin((string) ($_POST['token'] ?? ''))) {
                $this->redirectToServerEdit((int) ($_GET['id'] ?? 0), 'error', 'CSRF Token không hợp lệ. Vui lòng tải lại trang và thử lại.');
                return;
            }

            $result = (new ZoneManager())->saveServer($_POST);
            if ($result['success']) {
                $this->redirectToServers($result['message']);
            } else {
                $this->redirectToServerEdit($result['id'] ?? 0, 'error', $result['error']);
            }
            return;
        }

        $serverId = (int) ($_GET['id'] ?? 0);
        $data     = (new ZoneManager())->getServerForEdit($serverId);
        $this->smarty->assign('serverJson', json_encode($data['server'], JSON_UNESCAPED_UNICODE | JSON_HEX_TAG));
        $this->smarty->assign('isEdit',     $data['isEdit']);
        $this->smarty->assign('serverId',   $serverId);
    }

    private function actionDomains(): void
    {
        // Logic query đơn giản — giữ thẳng trong controller
        $search       = trim($_GET['search'] ?? '');
        $filterStatus = trim($_GET['status'] ?? '');
        $page         = max(1, (int) ($_GET['page'] ?? 1));
        $perPage      = 50;

        $query = \MJ\DnsManager\Models\Domain::orderBy('domain');
        if ($search)       $query->where('domain', 'like', '%' . $search . '%');
        if ($filterStatus) $query->where('status', $filterStatus);

        $total   = $query->count();
        $domains = $query->skip(($page - 1) * $perPage)->limit($perPage)->get();

        $userIds = $domains->pluck('whmcs_user_id')->filter()->unique()->toArray();
        $clients = [];
        if (!empty($userIds)) {
            $rows = Capsule::table('tblclients')->whereIn('id', $userIds)->select(['id', 'firstname', 'lastname'])->get();
            foreach ($rows as $row) {
                $clients[$row->id] = trim($row->firstname . ' ' . $row->lastname);
            }
        }

        $domainIds   = $domains->pluck('id')->toArray();
        $failedCounts = $lastSyncs = [];
        if (!empty($domainIds)) {
            $failedCounts = \MJ\DnsManager\Models\QueueJob::whereIn('domain_id', $domainIds)
                ->whereIn('status', ['FAILED', 'PERMANENTLY_FAILED'])
                ->selectRaw('domain_id, count(*) as cnt')->groupBy('domain_id')
                ->pluck('cnt', 'domain_id')->toArray();
            $lastSyncs = \MJ\DnsManager\Models\QueueJob::whereIn('domain_id', $domainIds)
                ->whereNotNull('completed_at')
                ->selectRaw('domain_id, max(completed_at) as last_completed')->groupBy('domain_id')
                ->pluck('last_completed', 'domain_id')->toArray();
        }

        $result = $domains->map(function ($d) use ($clients, $failedCounts, $lastSyncs) {
            $failed    = $failedCounts[$d->id] ?? 0;
            $lastSyncRaw = $lastSyncs[$d->id] ?? null;
            $lastSync  = $lastSyncRaw ? (new \DateTime($lastSyncRaw))->format('d/m H:i') : 'Chưa đồng bộ';
            return [
                'id'           => $d->id,
                'service_id'   => $d->whmcs_domain_id ?? 0,
                'domain'       => $d->domain,
                'client_id'    => $d->whmcs_user_id,
                'client_name'  => $clients[$d->whmcs_user_id] ?? '(Unknown)',
                'records_count' => \MJ\DnsManager\Models\Record::where('domain_id', $d->id)->count(),
                'last_sync'    => $lastSync,
                'failed_jobs'  => $failed,
                'status'       => $d->status,
                'sync_status'  => $failed > 0 ? 'failed' : 'complete',
            ];
        })->values()->toArray();

        $this->smarty->assign('domainsJson',  json_encode($result, JSON_UNESCAPED_UNICODE | JSON_HEX_TAG));
        $this->smarty->assign('totalDomains', $total);
        $this->smarty->assign('totalPages',   (int) ceil($total / $perPage));
        $this->smarty->assign('currentPage',  $page);
    }

    private function actionAuditTrail(): void
    {
        $logs = (new ReportService())->getAuditLogs();
        $this->smarty->assign('auditLogsJson', json_encode($logs, JSON_UNESCAPED_UNICODE | JSON_HEX_TAG));
    }

    private function actionAuditDetail(): void
    {
        $data = (new ReportService())->getAuditLogDetail((int) ($_GET['id'] ?? 0));
        $this->smarty->assign('auditLog',   isset($data['log'])
            ? json_encode($data['log'], JSON_UNESCAPED_UNICODE | JSON_HEX_TAG)
            : null);
        $this->smarty->assign('auditError', $data['error'] ?? null);
    }

    private function actionAdminDnsEditor(): void
    {
        $domainId = (int) ($_GET['domain_id'] ?? 0);
        $data     = (new RecordManager())->getRecordsForEditor($domainId);
        $this->smarty->assign('editorError', $data['error'] ?? null);
        $this->smarty->assign('domain',      $data['domain'] ?? null);
        $this->smarty->assign('recordsJson', json_encode($data['records'] ?? [], JSON_UNESCAPED_UNICODE | JSON_HEX_TAG));
        $this->smarty->assign('domainId',    $domainId);
    }

    private function actionSettings(): void
    {
        $settings = (new SettingsService())->getSettingsForPage();
        $this->smarty->assign('settingsJson', json_encode($settings, JSON_UNESCAPED_UNICODE | JSON_HEX_TAG));
    }

    private function actionDriftReports(): void
    {
        $data = (new ReportService())->getDriftReports();
        $this->smarty->assign('driftReportsJson', json_encode($data['reports'], JSON_UNESCAPED_UNICODE | JSON_HEX_TAG));
        $this->smarty->assign('driftLastRun',     $data['lastRun']);
        $this->smarty->assign('driftNextRun',     $data['nextRun']);
    }

    private function actionTemplates(): void
    {
        $templates = \MJ\DnsManager\Models\Template::orderBy('is_default', 'desc')
            ->orderBy('name')
            ->get()
            ->map(function ($t) {
                $records = is_array($t->records_data) ? $t->records_data : [];
                return [
                    'id'            => $t->id,
                    'name'          => $t->name,
                    'description'   => $t->description,
                    'is_default'    => (bool) $t->is_default,
                    'is_visible'    => (bool) $t->is_visible_client,
                    'records_count' => count($records),
                    'records'       => $records,
                    'created_at'    => $t->created_at
                        ? $t->created_at->format('d/m/Y H:i') : '',
                ];
            })
            ->values()
            ->toArray();

        $this->smarty->assign(
            'templatesJson',
            json_encode($templates, JSON_UNESCAPED_UNICODE | JSON_HEX_TAG)
        );
    }

    private function actionTemplateEdit(): void
    {
        $flash = $_SESSION['mj_dns_flash'] ?? null;
        unset($_SESSION['mj_dns_flash']);
        $this->smarty->assign('flash', $flash);

        $id       = (int) ($_GET['id'] ?? 0);
        $isEdit   = $id > 0;
        $template = null;

        if ($isEdit) {
            $row = \MJ\DnsManager\Models\Template::find($id);
            if ($row) {
                $records = is_array($row->records_data) ? $row->records_data : [];
                // Chuẩn hoá field: backend dùng 'priority', template_edit.tpl dùng 'prio'
                foreach ($records as &$rec) {
                    if (!isset($rec['prio']) && isset($rec['priority'])) {
                        $rec['prio'] = $rec['priority'];
                    }
                }
                unset($rec);
                $template = [
                    'id'          => $row->id,
                    'name'        => $row->name,
                    'description' => $row->description,
                    'is_default'  => (bool) $row->is_default,
                    'is_visible'  => (bool) $row->is_visible_client,
                    'records'     => $records,
                ];
            }
        }

        $this->smarty->assign('isEdit',       $isEdit);
        $this->smarty->assign('templateJson', json_encode($template, JSON_UNESCAPED_UNICODE | JSON_HEX_TAG));
    }

    // ─────────────────────────────────────────────────────────────────────────
    // AJAX handlers — chỉ gọi Service, echo JSON
    // ─────────────────────────────────────────────────────────────────────────

    private function ajaxGetDashboardStats(): void
    {
        $days = (int) ($_GET['days'] ?? 7);
        if (!in_array($days, [7, 15, 30])) $days = 7;
        echo json_encode((new DashboardService())->getStats($days));
    }

    private function ajaxRunPendingJobs(): void
    {
        echo json_encode((new ReportService())->runPendingJobs());
    }

    private function ajaxRetryJob(): void
    {
        echo json_encode((new ReportService())->retryJob((int) ($_POST['job_id'] ?? 0)));
    }

    private function ajaxRetryAllFailed(): void
    {
        echo json_encode((new ReportService())->retryAllFailed());
    }

    private function ajaxCancelJob(): void
    {
        echo json_encode((new ReportService())->cancelJob((int) ($_POST['job_id'] ?? 0)));
    }

    private function ajaxTestConnection(): void
    {
        echo json_encode((new ZoneManager())->testConnection($_POST));
    }

    private function ajaxToggleServerStatus(): void
    {
        echo json_encode((new ZoneManager())->toggleStatus((int) ($_POST['server_id'] ?? 0)));
    }

    private function ajaxResetServerBackoff(): void
    {
        echo json_encode((new ZoneManager())->resetBackoff((int) ($_POST['server_id'] ?? 0)));
    }

    private function ajaxAdminAddRecord(): void
    {
        $input = json_decode(file_get_contents('php://input'), true) ?: $_POST;
        echo json_encode((new RecordManager())->addRecord($input, 'admin'));
    }

    private function ajaxAdminEditRecord(): void
    {
        $input = json_decode(file_get_contents('php://input'), true) ?: $_POST;
        echo json_encode((new RecordManager())->editRecord($input, 'admin'));
    }

    private function ajaxAdminDeleteRecord(): void
    {
        $input = json_decode(file_get_contents('php://input'), true) ?: $_POST;
        echo json_encode((new RecordManager())->deleteRecord($input, 'admin'));
    }

    private function ajaxAdminToggleLock(): void
    {
        $input = json_decode(file_get_contents('php://input'), true) ?: $_POST;
        echo json_encode((new RecordManager())->toggleLock($input));
    }

    private function ajaxSaveSettings(): void
    {
        $input = json_decode(file_get_contents('php://input'), true) ?: $_POST;
        echo json_encode((new SettingsService())->saveSettings($input));
    }

    private function ajaxTestNotification(): void
    {
        echo json_encode((new SettingsService())->testNotification());
    }

    private function ajaxTestEmail(): void
    {
        $input = json_decode(file_get_contents('php://input'), true) ?: [];
        echo json_encode((new SettingsService())->testEmail($input));
    }

    // Async-first: các nút "Run now" KHÔNG gọi DA trong request admin. Chúng chỉ
    // ghi force-flag; AfterCronJob (cron context, được phép gọi DA) sẽ thực thi.
    private function ajaxRunSslCheck(): void
    {
        $id = (int) ($_POST['domain_id'] ?? 0);
        \MJ\DnsManager\Helpers\SettingsHelper::set('force_ssl_check', $id > 0 ? (string) $id : 'all');
        echo json_encode([
            'success' => true,
            'data'    => ['scheduled' => true],
            'message' => 'Đã lên lịch kiểm tra SSL. Kết quả cập nhật sau chu kỳ cron tiếp theo (vài phút) — tải lại trang để xem.',
        ]);
    }

    private function ajaxRunDriftCheck(): void
    {
        $id = (int) ($_POST['domain_id'] ?? 0);
        \MJ\DnsManager\Helpers\SettingsHelper::set('force_drift_check', $id > 0 ? ('id:' . $id) : 'all');
        echo json_encode([
            'success' => true,
            'data'    => ['scheduled' => true],
            'message' => 'Đã lên lịch quét drift. Kết quả cập nhật sau chu kỳ cron tiếp theo (vài phút) — tải lại trang để xem.',
        ]);
    }

    private function ajaxRunDriftScanByName(): void
    {
        $name = trim($_POST['domain'] ?? '');
        if ($name === '') {
            echo json_encode(['success' => false, 'error' => 'Thiếu tên domain.']);
            return;
        }
        \MJ\DnsManager\Helpers\SettingsHelper::set('force_drift_check', 'name:' . $name);
        echo json_encode([
            'success' => true,
            'data'    => ['scheduled' => true],
            'message' => 'Đã lên lịch quét drift cho ' . $name . '. Tải lại trang sau vài phút để xem kết quả.',
        ]);
    }

    private function ajaxRunDriftScanAll(): void
    {
        \MJ\DnsManager\Helpers\SettingsHelper::set('force_drift_check', 'all');
        echo json_encode([
            'success' => true,
            'data'    => ['scheduled' => true],
            'message' => 'Đã lên lịch quét drift toàn bộ domain. Tải lại trang sau vài phút để xem kết quả.',
        ]);
    }

    private function ajaxResolveDrift(): void
    {
        $input = json_decode(file_get_contents('php://input'), true) ?: $_POST;
        $driftId = (int) ($input['drift_id'] ?? 0);
        $action = trim($input['action'] ?? '');

        if ($driftId <= 0 || empty($action)) {
            echo json_encode(['success' => false, 'error' => 'Thiếu drift_id hoặc action.']);
            return;
        }

        $allowed = ['pull', 'push', 'delete_da', 'delete_whmcs', 'ignore'];
        if (!in_array($action, $allowed, true)) {
            echo json_encode(['success' => false, 'error' => "Action không hợp lệ: {$action}"]);
            return;
        }

        echo json_encode((new \MJ\DnsManager\Services\ReportService())->resolveDrift($driftId, $action));
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Public gateway cho ajax.php (admin record actions)
    // ─────────────────────────────────────────────────────────────────────────

    public function handleAdminRecordAjax(string $method): void
    {
        $input = json_decode(file_get_contents('php://input'), true) ?: $_POST;
        $svc   = new RecordManager();

        switch ($method) {
            case 'adminAddRecord':
                echo json_encode($svc->addRecord($input, 'admin'));
                break;
            case 'adminEditRecord':
                echo json_encode($svc->editRecord($input, 'admin'));
                break;
            case 'adminDeleteRecord':
                echo json_encode($svc->deleteRecord($input, 'admin'));
                break;
            case 'adminToggleLock':
                echo json_encode($svc->toggleLock($input));
                break;
            default:
                echo json_encode(['success' => false, 'error' => ['message' => 'Invalid admin method.']]);
        }
        exit;
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Helpers
    // ─────────────────────────────────────────────────────────────────────────

    private function tablesExist(): bool
    {
        try {
            return Capsule::schema()->hasTable('tbl_mj_dns_queue');
        } catch (\Exception $e) {
            return false;
        }
    }

    // Dùng bởi ServerService::saveServer() để redirect sau khi lưu
    public function redirectToServers(string $msg): void
    {
        $_SESSION['mj_dns_flash'] = ['type' => 'success', 'message' => $msg];
        header('Location: addonmodules.php?module=mj_dns_manager&action=servers');
        exit;
    }

    public function redirectToServerEdit(int $id, string $type, string $msg): void
    {
        $_SESSION['mj_dns_flash'] = ['type' => $type, 'message' => $msg];
        $url = 'addonmodules.php?module=mj_dns_manager&action=server_edit';
        if ($id > 0) {
            $url .= '&id=' . $id;
        }
        header('Location: ' . $url);
        exit;
    }
}
