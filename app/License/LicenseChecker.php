<?php

namespace MJ\DnsManager\License;

defined("WHMCS") or die("Access Denied");

use MJ\DnsManager\Helpers\SettingsHelper;

/**
 * Kiểm tra license module (Tầng 1 — ModuleJET/HVN GROUP → Reseller).
 *
 * Chỉ kiểm tra "module có quyền chạy trên WHMCS này không" — KHÔNG kiểm tra
 * per-feature (DNSSEC/DDNS thuộc về FeatureGate/ClientFeatureResolver).
 *
 * Nguyên tắc fail-safe (chuẩn MJ): lỗi license KHÔNG được làm sập admin area.
 * Trạng thái dùng để gating được đọc fail-open qua FeatureGate::isModuleLicensed().
 * verify() (remote call-home) chỉ chạy khi admin bấm "Recheck" hoặc cron license —
 * KHÔNG gọi trong request lifecycle thông thường.
 *
 * @package MJ\DnsManager\License
 */
class LicenseChecker
{
    /** @var array Cấu hình từ license-config.php (có thể bị Settings ghi đè). */
    private array $config;

    public function __construct()
    {
        $defaults = ['server_url' => '', 'secret' => '', 'check_interval' => 86400, 'grace_days' => 15];
        $file = __DIR__ . '/license-config.php';
        $loaded = is_file($file) ? (array) include $file : [];
        $this->config = array_merge($defaults, $loaded);

        // Settings ưu tiên cao hơn file cấu hình.
        $url = SettingsHelper::get('license_server_url', '');
        if ($url !== '') {
            $this->config['server_url'] = $url;
        }
        $secret = SettingsHelper::get('license_secret_key', '');
        if ($secret !== '') {
            $this->config['secret'] = $secret;
        }
    }

    /**
     * Remote call-home tới license server, cache kết quả vào Settings.
     *
     * @param  string $licenseKey
     * @return LicenseResponse
     */
    public function verify(string $licenseKey = ''): LicenseResponse
    {
        if ($licenseKey === '') {
            $licenseKey = (string) SettingsHelper::get('license_key', '');
        }
        if ($licenseKey === '' || $this->config['server_url'] === '') {
            // Chưa cấu hình license → không kết luận Invalid (fail-open).
            return LicenseResponse::connectionFailed();
        }

        $result = $this->remoteCheck($licenseKey);

        // Cache trạng thái để FeatureGate đọc nhanh (fail-open).
        if (!$result->isConnectionFailed()) {
            SettingsHelper::set('license_status', $result->status);
            SettingsHelper::set('license_last_check', date('Y-m-d H:i:s'));
            if ($result->hasLocalKey()) {
                SettingsHelper::set('license_local_key', $result->localKey);
            }
        }

        return $result;
    }

    /**
     * Gọi HTTP tới license server. Trả ConnectionFailed nếu không liên lạc được.
     *
     * @param  string $licenseKey
     * @return LicenseResponse
     */
    private function remoteCheck(string $licenseKey): LicenseResponse
    {
        $postData = [
            'licensekey' => $licenseKey,
            'domain'     => $_SERVER['SERVER_NAME'] ?? '',
            'ip'         => $_SERVER['SERVER_ADDR'] ?? gethostbyname((string) gethostname()),
            'dir'        => dirname(__DIR__, 2),
        ];

        try {
            $ch = curl_init($this->config['server_url']);
            curl_setopt_array($ch, [
                CURLOPT_POST           => true,
                CURLOPT_POSTFIELDS     => http_build_query($postData),
                CURLOPT_RETURNTRANSFER => true,
                CURLOPT_TIMEOUT        => 10,
                CURLOPT_SSL_VERIFYPEER => true,
            ]);
            $raw = curl_exec($ch);
            $httpCode = (int) curl_getinfo($ch, CURLINFO_HTTP_CODE);
            curl_close($ch);

            if ($httpCode !== 200 || !is_string($raw) || $raw === '') {
                return LicenseResponse::connectionFailed();
            }

            return $this->parseRemote($raw);
        } catch (\Throwable $e) {
            return LicenseResponse::connectionFailed();
        }
    }

    /**
     * Parse phản hồi từ WHMCS Software Licensing Addon.
     *
     * @param  string $raw
     * @return LicenseResponse
     */
    private function parseRemote(string $raw): LicenseResponse
    {
        $r = new LicenseResponse();

        // WHMCS Licensing trả về các cặp <key>value</key>.
        if (preg_match('/<status>(.*?)<\/status>/is', $raw, $m)) {
            $r->status = trim($m[1]);
        }
        if (preg_match('/<localkey>(.*?)<\/localkey>/is', $raw, $m)) {
            $r->localKey = trim($m[1]);
        }
        if (preg_match('/<registereddate>(.*?)<\/registereddate>/is', $raw, $m)) {
            $r->validUntil = trim($m[1]);
        }
        $r->supportActive = $r->isValid();

        if ($r->status === '') {
            $r->status = 'Invalid';
        }
        return $r;
    }
}
