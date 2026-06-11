<?php

namespace MJ\DnsManager\Helpers;

defined("WHMCS") or die("Access Denied");

use MJ\DnsManager\Security\Csrf;

/**
 * Bơm asset của module INLINE từ disk — chuẩn MJ (hooks.md §7.2/§7.3).
 *
 * KHÔNG dùng <link>/<script src> trỏ vào modules/addons/* vì các host
 * cPanel/CloudLinux chạy sau Nginx thường trả 403 cho đường dẫn tĩnh đó,
 * khiến trang admin trắng style. Đọc file phía server và nhả <style>/<script>
 * bỏ qua hẳn tầng HTTP — render giống nhau trên mọi web server.
 *
 * Thứ tự bắt buộc (§7.3): config → CSS (tokens → components → mj-dns)
 * → mj-dns.js → Alpine loader. Fail-safe: lỗi đọc file trả '' — không
 * bao giờ làm sập trang.
 *
 * @package MJ\DnsManager\Helpers
 */
class AssetInliner
{
    /** Phiên bản Alpine.js dùng khi fallback CDN (vendor file ưu tiên hơn). */
    private const ALPINE_VERSION = '3.14.8';

    /**
     * Khối CSS + JS inline (dùng chung admin & client).
     */
    public static function inlineAssets(): string
    {
        $dir = self::moduleDir() . '/assets';
        $out = '';
        try {
            $css = '';
            foreach (['css/tokens.css', 'css/components.css', 'css/mj-dns.css'] as $rel) {
                $f = $dir . '/' . $rel;
                if (!is_readable($f)) {
                    continue;
                }
                $chunk = (string) file_get_contents($f);
                // Cascade đã chốt bằng thứ tự nối — @import giữa stylesheet là không hợp lệ.
                $chunk = preg_replace('/^[ \t]*@import[^;]+;[ \t]*\r?\n?/m', '', $chunk);
                $css  .= "\n" . $chunk;
            }
            if ($css !== '') {
                $out .= '<style id="mj-dns-css">' . $css . '</style>';
            }

            $js = $dir . '/js/mj-dns.js';
            if (is_readable($js)) {
                $out .= '<script id="mj-dns-js">' . file_get_contents($js) . '</script>';
            }
        } catch (\Throwable $e) {
            return '';
        }
        return $out;
    }

    /**
     * Alpine.js: ưu tiên vendor local (inline từ disk — zero CDN), chưa có
     * vendor thì fallback CDN (ghi chú đóng gói: thả alpine.min.js 3.14.8
     * vào assets/js/vendor/ trước khi build thương mại).
     */
    public static function alpineLoader(): string
    {
        $vendor = self::moduleDir() . '/assets/js/vendor/alpine.min.js';
        try {
            if (is_readable($vendor)) {
                return '<script id="mj-dns-alpine" defer>' . file_get_contents($vendor) . '</script>';
            }
        } catch (\Throwable $e) {
            // rơi xuống CDN
        }
        return '<script id="mj-dns-alpine" defer src="https://cdn.jsdelivr.net/npm/alpinejs@'
            . self::ALPINE_VERSION . '/dist/cdn.min.js"></script>';
    }

    /**
     * Google Fonts (Inter + JetBrains Mono) — typography chuẩn mj-design.
     */
    public static function fontsHtml(): string
    {
        return '<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>'
            . '<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700'
            . '&family=JetBrains+Mono:wght@400;500;600&display=swap" rel="stylesheet">';
    }

    /**
     * Payload đầy đủ cho ADMIN (render trong wrapper.tpl):
     * config (kèm CSRF self-token) → fonts → assets inline → Alpine.
     */
    public static function adminHtml(array $vars): string
    {
        $config = [
            'context'    => 'admin',
            'modulelink' => (string) ($vars['modulelink'] ?? 'addonmodules.php?module=mj_dns_manager'),
            'version'    => (string) ($vars['version'] ?? ''),
            // [WHMCS-REQUIRED] CSRF self-token — frontend phải gửi lại trên mọi POST.
            'csrfToken'  => Csrf::adminToken(),
        ];

        return '<script>window.mjDnsConfig=' . json_encode($config, JSON_HEX_TAG | JSON_HEX_APOS | JSON_HEX_QUOT) . ';</script>'
            . self::fontsHtml()
            . self::inlineAssets()
            . self::alpineLoader();
    }

    /**
     * Payload đầy đủ cho CLIENT (nhả qua hook ClientAreaHeadOutput, page-scoped):
     * config (token client-area WHMCS) → fonts → assets inline → Alpine.
     * Trang client tự set window.MJDNS_CONFIG (domainId, records…) — đây chỉ
     * là lớp nền: context + token mặc định.
     */
    public static function clientHtml(): string
    {
        $config = [
            'context'   => 'client',
            'csrfToken' => Csrf::clientToken(),
        ];

        return '<script>window.mjDnsConfig=' . json_encode($config, JSON_HEX_TAG | JSON_HEX_APOS | JSON_HEX_QUOT) . ';</script>'
            . self::fontsHtml()
            . self::inlineAssets()
            . self::alpineLoader();
    }

    private static function moduleDir(): string
    {
        return defined('MJ_DNS_DIR') ? MJ_DNS_DIR : dirname(__DIR__, 2);
    }
}
