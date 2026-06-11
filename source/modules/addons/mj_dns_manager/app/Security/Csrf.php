<?php

namespace MJ\DnsManager\Security;

defined("WHMCS") or die("Access Denied");

/**
 * CSRF token helper — chuẩn MJ ([WHMCS-REQUIRED]).
 *
 * - Admin: token tự phát theo session (self-issued), KHÔNG dựa vào
 *   $_SESSION['whmcs']['token'] / $_SESSION['token'] vì các key này không được
 *   populate ổn định trong một addon request → check sẽ luôn fail hoặc bị bỏ qua.
 * - Client: dùng token client-area chính chủ của WHMCS ($_SESSION['tkval']).
 *
 * Mọi so sánh dùng hash_equals() (chống timing attack) — không dùng ==/===/!==.
 *
 * @package MJ\DnsManager\Security
 */
class Csrf
{
    /** Khóa lưu admin self-token trong session. */
    private const ADMIN_SESSION_KEY = 'mj_dns_admin_csrf';

    /**
     * Lấy (hoặc khởi tạo) admin self-token cho session hiện tại.
     */
    public static function adminToken(): string
    {
        if (empty($_SESSION[self::ADMIN_SESSION_KEY]) || !is_string($_SESSION[self::ADMIN_SESSION_KEY])) {
            $_SESSION[self::ADMIN_SESSION_KEY] = bin2hex(random_bytes(32));
        }
        return $_SESSION[self::ADMIN_SESSION_KEY];
    }

    /**
     * Verify token admin gửi lên bằng so sánh hằng-thời-gian.
     */
    public static function validateAdmin(string $sent): bool
    {
        return $sent !== '' && hash_equals(self::adminToken(), $sent);
    }

    /**
     * Token client-area của WHMCS (do WHMCS phát hành, populate ở client area).
     */
    public static function clientToken(): string
    {
        return isset($_SESSION['tkval']) ? (string) $_SESSION['tkval'] : '';
    }

    /**
     * Verify token client gửi lên bằng so sánh hằng-thời-gian.
     */
    public static function validateClient(string $sent): bool
    {
        $expected = self::clientToken();
        return $expected !== '' && $sent !== '' && hash_equals($expected, $sent);
    }

    /**
     * Trích token từ request theo thứ tự ưu tiên: header → POST → JSON body → GET.
     *
     * @param array $jsonInput Body JSON đã parse (nếu có).
     */
    public static function tokenFromRequest(array $jsonInput = []): string
    {
        if (!empty($_SERVER['HTTP_X_CSRF_TOKEN'])) {
            return (string) $_SERVER['HTTP_X_CSRF_TOKEN'];
        }
        if (!empty($_POST['token'])) {
            return (string) $_POST['token'];
        }
        if (!empty($jsonInput['token'])) {
            return (string) $jsonInput['token'];
        }
        if (!empty($_GET['token'])) {
            return (string) $_GET['token'];
        }
        return '';
    }
}
