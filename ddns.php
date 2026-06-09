<?php
/**
 * ddns.php — Public DDNS Update Endpoint
 *
 * Được gọi bởi Router/Camera/thiết bị mạng để cập nhật IP tự động.
 * Không yêu cầu login WHMCS — xác thực qua token.
 *
 * Cách dùng:
 *   GET /modules/addons/hvn_dns_manager/ddns.php?token={token}
 *   GET /modules/addons/hvn_dns_manager/ddns.php?token={token}&ip={override_ip}
 *
 * Response (plain text, tương thích No-IP/DynDNS protocol):
 *   good {ip}     — Cập nhật thành công, IP mới là {ip}
 *   nochg {ip}    — IP không đổi, không cần cập nhật
 *   badauth       — Token không hợp lệ hoặc bị tắt
 *   abuse         — IP bị block do gọi quá nhiều
 *   dnserr        — Lỗi khi cập nhật DNS record
 *   nohost        — Không tìm thấy subdomain/domain
 */

// ── Bootstrap WHMCS ──────────────────────────────────────────────────────────
if (!defined('WHMCS')) {
    // Đây là file được gọi trực tiếp từ bên ngoài — cần init WHMCS
    require_once __DIR__ . '/../../../init.php';
}

// ── Autoloader ───────────────────────────────────────────────────────────────
spl_autoload_register(function ($class) {
    $prefix  = 'HvnGroup\\DnsManager\\';
    $baseDir = __DIR__ . '/app/';
    $len     = strlen($prefix);
    if (strncmp($prefix, $class, $len) !== 0) {
        return;
    }
    $file = $baseDir . str_replace('\\', '/', substr($class, $len)) . '.php';
    if (file_exists($file)) {
        require_once $file;
    }
});

// ── Response helper (plain text — tương thích DynDNS protocol) ───────────────
function ddns_respond($code, $ip = '')
{
    header('Content-Type: text/plain; charset=utf-8');
    header('Cache-Control: no-store, no-cache');

    $msg = $ip ? $code . ' ' . $ip : $code;
    echo $msg;

    // Ghi log ngắn gọn
    logActivity('HVN DNS Manager [DDNS]: ' . $msg . ' — IP: ' . ($_SERVER['REMOTE_ADDR'] ?? '?'));
    exit;
}

// ── Lấy IP thực của request ───────────────────────────────────────────────────
function ddns_get_client_ip()
{
    // Ưu tiên X-Forwarded-For nếu có (đứng sau proxy/load balancer)
    if (!empty($_SERVER['HTTP_X_FORWARDED_FOR'])) {
        $ips = explode(',', $_SERVER['HTTP_X_FORWARDED_FOR']);
        $ip  = trim($ips[0]);
        if (filter_var($ip, FILTER_VALIDATE_IP, FILTER_FLAG_NO_PRIV_RANGE | FILTER_FLAG_NO_RES_RANGE)) {
            return $ip;
        }
    }
    return $_SERVER['REMOTE_ADDR'] ?? '0.0.0.0';
}

// ════════════════════════════════════════════════════════════════════════════
// MAIN
// ════════════════════════════════════════════════════════════════════════════

use HvnGroup\DnsManager\Models\DdnsToken;
use HvnGroup\DnsManager\Models\IpBlacklist;
use HvnGroup\DnsManager\Models\Domain;
use HvnGroup\DnsManager\Models\Record;
use HvnGroup\DnsManager\Services\QueueManager;
use HvnGroup\DnsManager\Helpers\SettingsHelper;
use Illuminate\Database\Capsule\Manager as Capsule;

// ── 1. Kiểm tra module có bật không ──────────────────────────────────────────
try {
    $ddnsEnabled = SettingsHelper::isModeEnabled('ddns_mode');
    if (!$ddnsEnabled) {
        ddns_respond('dnserr');
    }
} catch (\Throwable $e) {
    ddns_respond('dnserr');
}

// ── 2. Lấy token từ request ───────────────────────────────────────────────────
$rawToken = trim($_REQUEST['token'] ?? '');
if (empty($rawToken)) {
    ddns_respond('badauth');
}

// ── 3. Lấy IP cần cập nhật ────────────────────────────────────────────────────
// Nếu thiết bị tự override IP (một số router gửi kèm), dùng giá trị đó
// Ngược lại dùng IP nguồn của request
$clientIp = ddns_get_client_ip();
$overrideIp = trim($_REQUEST['ip'] ?? $_REQUEST['myip'] ?? '');

if (!empty($overrideIp) && filter_var($overrideIp, FILTER_VALIDATE_IP)) {
    $newIp = $overrideIp;
} else {
    $newIp = $clientIp;
}

// Validate IP cuối cùng
if (!filter_var($newIp, FILTER_VALIDATE_IP)) {
    ddns_respond('dnserr');
}

// ── 4. Kiểm tra IP có bị block không ─────────────────────────────────────────
try {
    $blocked = IpBlacklist::where('ip_address', $clientIp)
        ->where('blocked_until', '>', date('Y-m-d H:i:s'))
        ->exists();
    if ($blocked) {
        ddns_respond('abuse');
    }
} catch (\Throwable $e) {
    // Bảng chưa tồn tại hoặc lỗi — bỏ qua, tiếp tục
}

// ── 5. Rate limit — kiểm tra số lần gọi trong 1 phút ────────────────────────
try {
    $rateLimit  = SettingsHelper::getInt('ddns_rate_limit', 60); // giây
    $windowKey  = 'ddns_rl_' . md5($clientIp);
    $now        = time();

    // Dùng bảng settings để lưu tạm rate limit state (nhẹ, không cần bảng riêng)
    $rlRow = Capsule::table('mod_hvndns_settings')
        ->where('setting_key', $windowKey)
        ->first();

    if ($rlRow) {
        $rlData = json_decode($rlRow->setting_val, true);
        $windowStart = $rlData['start'] ?? 0;
        $count       = $rlData['count'] ?? 0;

        if (($now - $windowStart) < $rateLimit) {
            // Còn trong window
            if ($count >= 10) {
                // Quá 10 request trong 1 window → block IP
                $bruteEnabled = SettingsHelper::getBool('enable_ddns_bruteforce', true);
                if ($bruteEnabled) {
                    $banDuration = SettingsHelper::getInt('ddns_bruteforce_ban_duration', 3600);
                    IpBlacklist::updateOrCreate(
                        ['ip_address' => $clientIp],
                        [
                            'reason'        => 'DDNS rate limit exceeded',
                            'blocked_until' => date('Y-m-d H:i:s', $now + $banDuration),
                        ]
                    );
                }
                ddns_respond('abuse');
            }
            // Tăng count
            Capsule::table('mod_hvndns_settings')
                ->where('setting_key', $windowKey)
                ->update(['setting_val' => json_encode(['start' => $windowStart, 'count' => $count + 1])]);
        } else {
            // Window mới — reset
            Capsule::table('mod_hvndns_settings')
                ->where('setting_key', $windowKey)
                ->update(['setting_val' => json_encode(['start' => $now, 'count' => 1])]);
        }
    } else {
        // Lần đầu tiên
        Capsule::table('mod_hvndns_settings')->insert([
            'setting_key' => $windowKey,
            'setting_val' => json_encode(['start' => $now, 'count' => 1]),
        ]);
    }
} catch (\Throwable $e) {
    // Rate limit lỗi → bỏ qua, tiếp tục xử lý
}

// ── 6. Tìm token trong DB ─────────────────────────────────────────────────────
// Token được lưu dạng SHA-256 hash
$tokenHash = hash('sha256', $rawToken);

try {
    $tokenRow = DdnsToken::where('token_hash', $tokenHash)
        ->where('is_active', 1)
        ->first();
} catch (\Throwable $e) {
    ddns_respond('dnserr');
}

if (!$tokenRow) {
    ddns_respond('badauth');
}

// ── 7. Load domain ────────────────────────────────────────────────────────────
try {
    $domain = Domain::find($tokenRow->domain_id);
} catch (\Throwable $e) {
    ddns_respond('nohost');
}

if (!$domain || $domain->status !== 'active') {
    ddns_respond('nohost');
}

$subdomain  = $tokenRow->subdomain;
$domainName = $domain->domain;

// Tên record đầy đủ để hiển thị log
$fqdn = ($subdomain === '@') ? $domainName : $subdomain . '.' . $domainName;

// ── 8. Kiểm tra IP có thay đổi không ─────────────────────────────────────────
if ($tokenRow->last_ip === $newIp) {
    // IP không đổi — cập nhật last_request_at và request_count, không dispatch job
    $tokenRow->update([
        'last_request_at' => date('Y-m-d H:i:s'),
        'request_count'   => $tokenRow->request_count + 1,
    ]);
    ddns_respond('nochg', $newIp);
}

// ── 9. Tìm record A hiện tại trong WHMCS DB ──────────────────────────────────
try {
    $record = Record::where('domain_id', $domain->id)
        ->where('type', 'A')
        ->where('name', $subdomain)
        ->first();
} catch (\Throwable $e) {
    ddns_respond('dnserr');
}

// ── 10. Dispatch queue job ────────────────────────────────────────────────────
try {
    $qm = new QueueManager();

    if ($record) {
        // Record đã tồn tại → EDIT
        $oldIp = $record->value;

        $record->update([
            'value'      => $newIp,
            'updated_at' => date('Y-m-d H:i:s'),
        ]);

        $qm->dispatch($domain->id, 'EDIT_RECORD', [
            'record_id'  => $record->id,
            'old_record' => [
                'type'  => 'A',
                'name'  => $subdomain,
                'value' => $oldIp,
            ],
            'new_record' => [
                'type'  => 'A',
                'name'  => $subdomain,
                'value' => $newIp,
                'ttl'   => 300,  // TTL ngắn cho DDNS — 5 phút
            ],
        ], 1, 'system', null);

    } else {
        // Record chưa có → CREATE
        $newRecord = Record::create([
            'domain_id'      => $domain->id,
            'type'           => 'A',
            'name'           => $subdomain,
            'value'          => $newIp,
            'ttl'            => 300,
            'is_system'      => 0,
            'is_locked'      => 0,
            'pending_delete' => 0,
        ]);

        $qm->dispatch($domain->id, 'ADD_RECORD', [
            'record_id' => $newRecord->id,
            'type'      => 'A',
            'name'      => $subdomain,
            'value'     => $newIp,
            'ttl'       => 300,
        ], 1, 'system', null);
    }
} catch (\Throwable $e) {
    logActivity('HVN DNS Manager [DDNS]: Queue dispatch failed for ' . $fqdn . ' — ' . $e->getMessage());
    ddns_respond('dnserr');
}

// ── 11. Cập nhật token stats ──────────────────────────────────────────────────
try {
    $tokenRow->update([
        'last_ip'         => $newIp,
        'last_update_at'  => date('Y-m-d H:i:s'),
        'last_request_at' => date('Y-m-d H:i:s'),
        'request_count'   => $tokenRow->request_count + 1,
    ]);
} catch (\Throwable $e) {
    // Non-critical — không cần crash
}

logActivity("HVN DNS Manager [DDNS]: Updated {$fqdn} → {$newIp} (was: " . ($record ? $record->value : 'new') . ')');

// ── 12. Trả về kết quả ────────────────────────────────────────────────────────
ddns_respond('good', $newIp);