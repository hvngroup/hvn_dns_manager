<?php

namespace MJ\DnsManager\Services;

defined("WHMCS") or die("Access Denied");

use MJ\DnsManager\Helpers\SettingsHelper;

/**
 * Feature Gating cho DNSSEC & DDNS — entry point DUY NHẤT để check quyền dùng.
 *
 * 3 lớp:
 *   Lớp 1 — Module License (isModuleLicensed, fail-open theo trạng thái cache).
 *   Lớp 2 — Admin Settings: dnssec_mode/ddns_mode ∈ {off, free, paid}.
 *   Lớp 3 — Client billing (ClientFeatureResolver) — chỉ khi mode='paid'.
 *
 * KHÔNG check thủ công dnssec_mode/ddns_mode ở nơi khác — luôn đi qua class này.
 *
 * @package MJ\DnsManager\Services
 */
class FeatureGate
{
    /** @var ClientFeatureResolver|null */
    private static ?ClientFeatureResolver $resolver = null;

    // ── Lớp 1: Module License ──────────────────────────────────────────────

    /**
     * Module có license hợp lệ không (fail-open: chỉ chặn khi cache = 'Invalid').
     *
     * Tránh làm sập module khi license server tạm thời không liên lạc được
     * (chuẩn MJ: license fail KHÔNG crash WHMCS, chỉ banner).
     *
     * @return bool
     */
    public static function isModuleLicensed(): bool
    {
        $status = (string) SettingsHelper::get('license_status', '');
        return $status !== 'Invalid' && $status !== 'Suspended' && $status !== 'Expired';
    }

    // ── Lớp 2: Admin Settings (off / free / paid) ──────────────────────────

    /**
     * Mode DNSSEC: 'off' | 'free' | 'paid' ('off' nếu module chưa licensed).
     *
     * @return string
     */
    public static function getDnssecMode(): string
    {
        if (!self::isModuleLicensed()) {
            return 'off';
        }
        return SettingsHelper::getMode('dnssec_mode');
    }

    /**
     * Mode DDNS: 'off' | 'free' | 'paid'.
     *
     * @return string
     */
    public static function getDdnsMode(): string
    {
        if (!self::isModuleLicensed()) {
            return 'off';
        }
        return SettingsHelper::getMode('ddns_mode');
    }

    // ── Lớp 3: Client feature (theo userId) ────────────────────────────────

    /**
     * Client có quyền dùng DNSSEC không.
     *   off  → false ; free → true ; paid → check billing.
     *
     * @param  int $userId WHMCS client id (whmcs_user_id của domain)
     * @return bool
     */
    public static function canClientUseDnssec(int $userId): bool
    {
        $mode = self::getDnssecMode();
        if ($mode === 'off') {
            return false;
        }
        if ($mode === 'free') {
            return true;
        }
        return self::resolver()->userHasDnssec($userId);
    }

    /**
     * Client có quyền dùng DDNS không.
     *
     * @param  int $userId WHMCS client id
     * @return bool
     */
    public static function canClientUseDdns(int $userId): bool
    {
        $mode = self::getDdnsMode();
        if ($mode === 'off') {
            return false;
        }
        if ($mode === 'free') {
            return true;
        }
        return self::resolver()->userHasDdns($userId);
    }

    /**
     * Lý do tính năng DNSSEC bị khóa (cho UI). null = không khóa.
     *   'module_unlicensed' | 'feature_off' | 'not_purchased'
     *
     * @param  int $userId
     * @return string|null
     */
    public static function getDnssecLockReason(int $userId): ?string
    {
        if (!self::isModuleLicensed()) {
            return 'module_unlicensed';
        }
        $mode = SettingsHelper::getMode('dnssec_mode');
        if ($mode === 'off') {
            return 'feature_off';
        }
        if ($mode === 'free') {
            return null;
        }
        return self::resolver()->userHasDnssec($userId) ? null : 'not_purchased';
    }

    /**
     * Lý do tính năng DDNS bị khóa (cho UI). null = không khóa.
     *
     * @param  int $userId
     * @return string|null
     */
    public static function getDdnsLockReason(int $userId): ?string
    {
        if (!self::isModuleLicensed()) {
            return 'module_unlicensed';
        }
        $mode = SettingsHelper::getMode('ddns_mode');
        if ($mode === 'off') {
            return 'feature_off';
        }
        if ($mode === 'free') {
            return null;
        }
        return self::resolver()->userHasDdns($userId) ? null : 'not_purchased';
    }

    /**
     * @return ClientFeatureResolver
     */
    private static function resolver(): ClientFeatureResolver
    {
        if (self::$resolver === null) {
            self::$resolver = new ClientFeatureResolver();
        }
        return self::$resolver;
    }
}
