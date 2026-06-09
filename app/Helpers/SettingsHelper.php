<?php

namespace HvnGroup\DnsManager\Helpers;

use Illuminate\Database\Capsule\Manager as Capsule;

class SettingsHelper
{
    private static $cache = null;

    protected static function loadCache()
    {
        if (self::$cache === null) {
            try {
                $settings = Capsule::table('mod_hvndns_settings')->get();
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
        $exists = Capsule::table('mod_hvndns_settings')->where('setting_key', $key)->exists();
        if ($exists) {
            Capsule::table('mod_hvndns_settings')->where('setting_key', $key)->update(['setting_val' => $value]);
        } else {
            Capsule::table('mod_hvndns_settings')->insert([
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
}
