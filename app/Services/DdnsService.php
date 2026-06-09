<?php

namespace HvnGroup\DnsManager\Services;

use HvnGroup\DnsManager\Models\DdnsToken;
use HvnGroup\DnsManager\Models\Domain;
use HvnGroup\DnsManager\Models\Record;
use HvnGroup\DnsManager\Helpers\SettingsHelper;

class DdnsService
{
    // ─────────────────────────────────────────────────────────────────────────
    // Lấy danh sách token của 1 domain — dùng cho tab DDNS
    // ─────────────────────────────────────────────────────────────────────────

    public function getTokens(int $domainId, int $userId): array
    {
        $domain = Domain::where('id', $domainId)
            ->where('whmcs_user_id', $userId)
            ->first();

        if (!$domain) {
            return ['success' => false, 'error' => 'Domain không tồn tại.'];
        }

        $tokens = DdnsToken::where('domain_id', $domainId)
            ->orderBy('created_at', 'desc')
            ->get()
            ->map(function (DdnsToken $t) use ($domain) {
                return $this->formatToken($t, $domain->domain);
            })
            ->toArray();

        return ['success' => true, 'data' => $tokens];
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Tạo token mới
    // ─────────────────────────────────────────────────────────────────────────

    public function createToken(array $input, int $userId): array
    {
        $domainId = (int) ($input['domain_id'] ?? 0);
        $subdomain = trim($input['subdomain'] ?? '');
        $label = trim($input['label'] ?? '');

        if (!$domainId || !$subdomain) {
            return ['success' => false, 'error' => 'Thiếu domain_id hoặc subdomain.'];
        }

        // Validate subdomain — chỉ chấp nhận alphanumeric + hyphen
        if (!preg_match('/^[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?$/', $subdomain) && $subdomain !== '@') {
            return ['success' => false, 'error' => 'Subdomain không hợp lệ. Chỉ dùng chữ cái, số và dấu gạch ngang.'];
        }

        $domain = Domain::where('id', $domainId)
            ->where('whmcs_user_id', $userId)
            ->first();

        if (!$domain) {
            return ['success' => false, 'error' => 'Domain không tồn tại.'];
        }

        // Kiểm tra quota
        $maxTokens = SettingsHelper::getInt('ddns_token_limit', 5);
        $currentCount = DdnsToken::where('domain_id', $domainId)->count();
        if ($currentCount >= $maxTokens) {
            return ['success' => false, 'error' => "Đã đạt giới hạn {$maxTokens} token DDNS cho domain này."];
        }

        // Kiểm tra subdomain chưa có token
        $exists = DdnsToken::where('domain_id', $domainId)
            ->where('subdomain', $subdomain)
            ->exists();
        if ($exists) {
            return ['success' => false, 'error' => "Subdomain '{$subdomain}' đã có token DDNS. Xóa token cũ trước."];
        }

        // Sinh token ngẫu nhiên
        $rawToken = $this->generateRawToken();

        $token = DdnsToken::create([
            'domain_id' => $domainId,
            'subdomain' => $subdomain,
            'token_hash' => hash('sha256', $rawToken),
            'label' => $label ?: $subdomain,
            'is_active' => 1,
            'request_count' => 0,
        ]);

        // Notify client
            try {
                $notif = new \HvnGroup\DnsManager\Services\NotificationService();
                $notif->notifyClientDdnsTokenCreated(
                    $userId,
                    $domain->domain,
                    $subdomain,
                    $label
                );
            } catch (\Exception $e) {
                logActivity('HVN DNS Manager [DdnsService]: notifyClientDdnsTokenCreated exception — ' . $e->getMessage());
            }

        // Trả về raw token 1 lần duy nhất — sau đó không thể xem lại
        return [
            'success' => true,
            'message' => 'Token đã được tạo thành công.',
            'data' => array_merge(
                $this->formatToken($token, $domain->domain),
                ['raw_token' => $rawToken]  // Chỉ trả về lần này
            ),
        ];
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Tạo lại token (regenerate) — xóa token cũ, sinh token mới
    // ─────────────────────────────────────────────────────────────────────────

    public function regenerateToken(int $tokenId, int $userId): array
    {
        $token = $this->findTokenOwnedBy($tokenId, $userId);
        if (!$token) {
            return ['success' => false, 'error' => 'Token không tồn tại.'];
        }

        $rawToken = $this->generateRawToken();
        $token->update(['token_hash' => hash('sha256', $rawToken)]);

        $domain = Domain::find($token->domain_id);

        return [
            'success' => true,
            'message' => 'Token đã được tạo lại. Cập nhật URL mới trên thiết bị của bạn.',
            'data' => array_merge(
                $this->formatToken($token->fresh(), $domain ? $domain->domain : ''),
                ['raw_token' => $rawToken]
            ),
        ];
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Bật/tắt token
    // ─────────────────────────────────────────────────────────────────────────

    public function toggleActive(int $tokenId, int $userId): array
    {
        $token = $this->findTokenOwnedBy($tokenId, $userId);
        if (!$token) {
            return ['success' => false, 'error' => 'Token không tồn tại.'];
        }

        $token->update(['is_active' => $token->is_active ? 0 : 1]);

        return [
            'success' => true,
            'is_active' => (bool) $token->fresh()->is_active,
            'message' => $token->is_active ? 'Token đã được kích hoạt.' : 'Token đã bị tạm dừng.',
        ];
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Xóa token
    // ─────────────────────────────────────────────────────────────────────────

    public function deleteToken(int $tokenId, int $userId): array
    {
        $token = $this->findTokenOwnedBy($tokenId, $userId);
        if (!$token) {
            return ['success' => false, 'error' => 'Token không tồn tại.'];
        }

        $token->delete();

        return ['success' => true, 'message' => 'Token đã được xóa.'];
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Helpers
    // ─────────────────────────────────────────────────────────────────────────

    private function findTokenOwnedBy(int $tokenId, int $userId)
    {
        return DdnsToken::where('id', $tokenId)
            ->whereHas('domain', function ($q) use ($userId) {
                $q->where('whmcs_user_id', $userId);
            })
            ->first();
    }

    private function formatToken(DdnsToken $t, string $domainName): array
    {
        $baseUrl = $this->getDdnsBaseUrl();
        $tokenUrl = $baseUrl . '?token=' . urlencode($t->token_hash) . '&subdomain=' . urlencode($t->subdomain);

        return [
            'id' => $t->id,
            'subdomain' => $t->subdomain,
            'label' => $t->label ?? $t->subdomain,
            'ip' => $t->last_ip ?? 'Chưa cập nhật',
            'updated' => $t->last_update_at
                ? date('d/m/Y H:i', strtotime((string) $t->last_update_at))
                : 'Chưa có',
            'requests' => (int) $t->request_count,
            'active' => (bool) $t->is_active,
            'showDetail' => false,
            'token_url' => $tokenUrl,
            'domain_name' => $domainName,
        ];
    }

    private function generateRawToken(): string
    {
        return bin2hex(random_bytes(24)); // 48 ký tự hex
    }

    private function getDdnsBaseUrl(): string
    {
        // Lấy base URL WHMCS — dùng HTTP_HOST nếu có
        if (!empty($_SERVER['HTTP_HOST'])) {
            $scheme = (!empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off') ? 'https' : 'http';
            $host = rtrim($_SERVER['HTTP_HOST'], '/');
            return $scheme . '://' . $host . '/modules/addons/hvn_dns_manager/ddns.php';
        }
        return '/modules/addons/hvn_dns_manager/ddns.php';
    }
}