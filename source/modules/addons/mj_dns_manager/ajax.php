<?php

use WHMCS\Database\Capsule;
use MJ\DnsManager\Controllers\Client\RecordController;

// Bắt đầu kiểm soát đầu ra (Output Buffering)
ob_start();

require_once __DIR__ . '/../../../init.php';

// Autoload cho namespace MJ\DnsManager
spl_autoload_register(function ($class) {
    $prefix   = 'MJ\\DnsManager\\';
    $base_dir = __DIR__ . '/app/';
    $len = strlen($prefix);
    if (strncmp($prefix, $class, $len) !== 0) {
        return;
    }
    $relative_class = substr($class, $len);
    $file = $base_dir . str_replace('\\', '/', $relative_class) . '.php';
    if (file_exists($file)) {
        require_once  $file;
    }
});

header('Content-Type: application/json');

// ── Đọc JSON body MỘT LẦN DUY NHẤT ngay tại đây ────────────────────────────
// php://input chỉ đọc được 1 lần — phải cache lại để dùng xuyên suốt file
$rawBody   = file_get_contents('php://input');
$jsonInput = json_decode($rawBody, true);
$jsonInput = is_array($jsonInput) ? $jsonInput : array();

// ── Xác định action ─────────────────────────────────────────────────────────
$action = isset($_GET['action']) ? $_GET['action'] : '';

// ── CSRF & Auth ─────────────────────────────────────────────────────────────
if ($action === 'admin_record' || $action === 'admin_template') {

    // Kiểm tra admin session
    $adminId = isset($_SESSION['adminid']) ? (int) $_SESSION['adminid'] : 0;
    if (!$adminId) {
        ob_clean();
        echo json_encode(array('success' => false, 'error' => array('code' => 'UNAUTHORIZED', 'message' => 'Yêu cầu quyền Admin.')));
        exit;
    }

    // WHMCS admin token
    $adminToken = '';
    if (!empty($_SESSION['whmcs']['token'])) {
        $adminToken = $_SESSION['whmcs']['token'];
    } elseif (!empty($_SESSION['token'])) {
        $adminToken = $_SESSION['token'];
    }

    // Token từ request: ưu tiên header → POST → GET → JSON body
    $requestToken = '';
    if (!empty($_SERVER['HTTP_X_CSRF_TOKEN'])) {
        $requestToken = $_SERVER['HTTP_X_CSRF_TOKEN'];
    } elseif (!empty($_POST['token'])) {
        $requestToken = $_POST['token'];
    } elseif (!empty($_GET['token'])) {
        $requestToken = $_GET['token'];
    } elseif (!empty($jsonInput['token'])) {
        $requestToken = $jsonInput['token'];
    }

    if (!empty($adminToken) && (empty($requestToken) || $requestToken !== $adminToken)) {
        ob_clean();
        echo json_encode(array('success' => false, 'error' => array('code' => 'CSRF_FAILED', 'message' => 'CSRF Token không hợp lệ.')));
        exit;
    }

    $userId = 0;

} else {

    // Client actions
    $token = '';
    if (!empty($_SERVER['HTTP_X_CSRF_TOKEN'])) {
        $token = $_SERVER['HTTP_X_CSRF_TOKEN'];
    } elseif (!empty($_REQUEST['token'])) {
        $token = $_REQUEST['token'];
    }

    $sessionToken = isset($_SESSION['tkval']) ? $_SESSION['tkval'] : '';
    $csrfValid    = (!empty($token) && !empty($sessionToken) && $token === $sessionToken);

    if (!$csrfValid) {
        ob_clean();
        echo json_encode(array('success' => false, 'error' => array('code' => 'CSRF_FAILED', 'message' => 'CSRF Token is invalid or missing.')));
        exit;
    }

    $userId = isset($_SESSION['uid']) ? (int) $_SESSION['uid'] : 0;
    if (!$userId && $action !== 'test') {
        ob_clean();
        echo json_encode(array('success' => false, 'error' => array('code' => 'UNAUTHORIZED', 'message' => 'Vui lòng đăng nhập để thực hiện chức năng này.')));
        exit;
    }
}

// ── Routing ─────────────────────────────────────────────────────────────────
try {
    switch ($action) {

        case 'add_record':
        case 'edit_record':
        case 'delete_record':
        case 'sync_status':
        case 'sync_status_all':
        case 'sync_zone':
        case 'get_all_records':
            $controller = new RecordController();
            $response   = $controller->dispatch($action, $_REQUEST, $userId);
            $newToken   = isset($_SESSION['tkval']) ? $_SESSION['tkval'] : '';
            if (!empty($newToken)) {
                $response['_token'] = $newToken;
            }
            ob_clean();
            echo json_encode($response);
            break;

        case 'get_redirects':
        case 'add_redirect':
        case 'delete_redirect':
            $controller = new \MJ\DnsManager\Controllers\Client\RedirectController();
            $response   = $controller->dispatch($action, $_REQUEST, $userId);
            $newToken   = isset($_SESSION['tkval']) ? $_SESSION['tkval'] : '';
            if (!empty($newToken)) {
                $response['_token'] = $newToken;
            }
            ob_clean();
            echo json_encode($response);
            break;

        // ── Admin DNS record actions ──────────────────────────────────────
        case 'admin_record':
            // admin_record vẫn có thể dùng $_REQUEST vì JS gửi form-data hoặc JSON
            $method          = !empty($jsonInput['method']) ? $jsonInput['method'] : (isset($_REQUEST['method']) ? $_REQUEST['method'] : '');
            $adminController = new \MJ\DnsManager\Controllers\Admin\AdminController();
            $adminController->handleAdminRecordAjax($method);
            break;

        // ── Admin Template CRUD ───────────────────────────────────────────
        case 'admin_template':
            // $jsonInput đã được parse ở trên — lấy method từ JSON body
            $method = isset($jsonInput['method']) ? $jsonInput['method'] : '';

            // Fallback: nếu không có trong JSON thì thử $_REQUEST (form-data)
            if ($method === '') {
                $method = isset($_REQUEST['method']) ? $_REQUEST['method'] : '';
            }

            // $jsonInput là input đầy đủ; nếu rỗng fallback về $_REQUEST
            $input = !empty($jsonInput) ? $jsonInput : $_REQUEST;

            $templateController = new \MJ\DnsManager\Controllers\Admin\TemplateController();
            $response           = $templateController->dispatch($method, $input);
            ob_clean();
            echo json_encode($response);
            break;

        // ── Client Apply Template ─────────────────────────────────────────
        case 'apply_template':
            $input           = !empty($jsonInput) ? $jsonInput : $_REQUEST;
            $templateService = new \MJ\DnsManager\Services\TemplateService();
            $response        = $templateService->applyTemplate($input, $userId);
            $newToken        = isset($_SESSION['tkval']) ? $_SESSION['tkval'] : '';
            if (!empty($newToken)) {
                $response['_token'] = $newToken;
            }
            ob_clean();
            echo json_encode($response);
            break;

        // ── DDNS ─────────────────────────────────────────────────────────
        case 'ddns_list':
        case 'ddns_create':
        case 'ddns_toggle':
        case 'ddns_delete':
        case 'ddns_regenerate':
            $svc   = new \MJ\DnsManager\Services\DdnsService();
            $input = !empty($jsonInput) ? $jsonInput : $_REQUEST;

            if ($action === 'ddns_list') {
                $response = $svc->getTokens((int) ($input['domain_id'] ?? 0), $userId);
            } elseif ($action === 'ddns_create') {
                $response = $svc->createToken($input, $userId);
            } elseif ($action === 'ddns_toggle') {
                $response = $svc->toggleActive((int) ($input['token_id'] ?? 0), $userId);
            } elseif ($action === 'ddns_delete') {
                $response = $svc->deleteToken((int) ($input['token_id'] ?? 0), $userId);
            } elseif ($action === 'ddns_regenerate') {
                $response = $svc->regenerateToken((int) ($input['token_id'] ?? 0), $userId);
            }

            $newToken = isset($_SESSION['tkval']) ? $_SESSION['tkval'] : '';
            if (!empty($newToken)) {
                $response['_token'] = $newToken;
            }
            ob_clean();
            echo json_encode($response);
            break;

        // ── Email Forwarding ──────────────────────────────────────────────
        case 'email_fwd_list':
        case 'email_fwd_create':
        case 'email_fwd_delete':
            $input = !empty($jsonInput) ? $jsonInput : $_REQUEST;

            $emailAction = substr($action, strlen('email_fwd_')); // list / create / delete
            $ctrl        = new \MJ\DnsManager\Controllers\Client\EmailForwardController();
            $response    = $ctrl->dispatch($emailAction, $input, $userId);

            $newToken = isset($_SESSION['tkval']) ? $_SESSION['tkval'] : '';
            if (!empty($newToken)) {
                $response['_token'] = $newToken;
            }
            ob_clean();
            echo json_encode($response);
            break;

        // ── DNSSEC ───────────────────────────────────────────────────────
        case 'dnssec_status':
        case 'dnssec_toggle':

            $svc   = new \MJ\DnsManager\Services\DnssecService();
            $input = !empty($jsonInput) ? $jsonInput : $_REQUEST;

            if ($action === 'dnssec_status') {
                $response = $svc->getStatus((int) ($input['domain_id'] ?? 0), $userId);
            } else {
                $enable   = !empty($input['enable']);
                $response = $svc->toggle((int) ($input['domain_id'] ?? 0), $userId, $enable);
            }

            $newToken = isset($_SESSION['tkval']) ? $_SESSION['tkval'] : '';
            if (!empty($newToken)) {
                $response['_token'] = $newToken;
            }
            ob_clean();
            echo json_encode($response);
            break;

        default:
            ob_clean();
            echo json_encode(array(
                'success' => false,
                'error'   => array('code' => 'INVALID_ACTION', 'message' => 'Action không hợp lệ.')
            ));
            break;
    }

} catch (\Throwable $e) {
    ob_clean();
    // Log chi tiết kỹ thuật phía server, KHÔNG leak ra client (05-security.md)
    if (function_exists('logActivity')) {
        logActivity('MJ DNS Manager AJAX error: ' . $e->getMessage()
            . ' in ' . $e->getFile() . ':' . $e->getLine());
    }
    echo json_encode(array(
        'success' => false,
        'error'   => array(
            'code'    => 'SERVER_ERROR',
            'message' => 'Đã xảy ra lỗi. Vui lòng thử lại sau.'
        )
    ));
}