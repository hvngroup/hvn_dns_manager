<?php

namespace MJ\DnsManager\Helpers;

use Illuminate\Database\Capsule\Manager as Capsule;

class SettingsHelper
{
    private static $cache = null;

    protected static function loadCache()
    {
        if (self::$cache === null) {
            try {
                $settings = Capsule::table('tbl_mj_dns_settings')->get();
                self::$cache = [];
                foreach ($settings as $setting) {
                    self::$cache[$setting->setting_key] = $setting->setting_val;
                }
            } catch (\Exception $e) {
                // Return default values when tables not migrated yet
                self::$cache = [];
            }
        }
    }

    public static function get($key, $default = null)
    {
        self::loadCache();
        return isset(self::$cache[$key]) ? self::$cache[$key] : $default;
    }

    public static function set($key, $value)
    {
        self::loadCache();
        $exists = Capsule::table('tbl_mj_dns_settings')->where('setting_key', $key)->exists();
        if ($exists) {
            Capsule::table('tbl_mj_dns_settings')->where('setting_key', $key)->update(['setting_val' => $value]);
        } else {
            Capsule::table('tbl_mj_dns_settings')->insert([
                'setting_key' => $key,
                'setting_val' => $value
            ]);
        }
        self::$cache[$key] = $value;
    }

    public static function getBool($key, $default = false)
    {
        $val = self::get($key, $default);
        return $val === "1" || $val === 1 || $val === true || $val === "true";
    }

    public static function getInt($key, $default = 0)
    {
        return (int) self::get($key, $default);
    }

    /**
     * Đọc giá trị của một feature 3-mode (off/free/paid).
     *
     * @param  string $key     Khóa setting (vd 'dnssec_mode', 'ddns_mode').
     * @param  string $default Giá trị mặc định nếu không hợp lệ.
     * @return string Một trong: 'off' | 'free' | 'paid'.
     */
    public static function getMode($key, $default = 'off')
    {
        $mode = strtolower(trim((string) self::get($key, $default)));
        return in_array($mode, ['off', 'free', 'paid'], true) ? $mode : $default;
    }

    /**
     * Kiểm tra một feature 3-mode có đang BẬT không (mode khác 'off').
     *
     * Dùng cho các setting lưu chuỗi 'off'/'free'/'paid' — KHÔNG dùng getBool()
     * vì getBool() luôn trả false với chuỗi 'free'/'paid'. Việc phân biệt
     * free vs paid (quyền Premium) do FeatureGate đảm nhiệm.
     *
     * @param  string $key Khóa setting (vd 'dnssec_mode', 'ddns_mode').
     * @return bool
     */
    public static function isModeEnabled($key)
    {
        return self::getMode($key) !== 'off';
    }
}
