<?php

namespace MJ\DnsManager\License;

defined("WHMCS") or die("Access Denied");

/**
 * Đối tượng kết quả kiểm tra license module (Tầng 1 — HVN/ModuleJET → Reseller).
 *
 * @package MJ\DnsManager\License
 */
class LicenseResponse
{
    /** @var string 'Active'|'Suspended'|'Expired'|'Invalid'|'ConnectionFailed' */
    public string $status = 'Invalid';

    /** @var string Local key đã mã hóa để cache (rỗng nếu không có). */
    public string $localKey = '';

    /** @var string Thời điểm hết hạn (Y-m-d) nếu biết. */
    public string $validUntil = '';

    /** @var bool Addon Support & Updates còn hạn? */
    public bool $supportActive = false;

    /** @var string|null Thông điệp kèm theo (cho banner admin). */
    public ?string $message = null;

    /**
     * Module có quyền chạy không.
     *
     * @return bool
     */
    public function isValid(): bool
    {
        return $this->status === 'Active';
    }

    /**
     * License bị tạm ngưng (thường do nợ phí).
     *
     * @return bool
     */
    public function isSuspended(): bool
    {
        return $this->status === 'Suspended';
    }

    /**
     * License đã hết hạn.
     *
     * @return bool
     */
    public function isExpired(): bool
    {
        return $this->status === 'Expired';
    }

    /**
     * Không kết nối được license server (cần dùng grace period).
     *
     * @return bool
     */
    public function isConnectionFailed(): bool
    {
        return $this->status === 'ConnectionFailed';
    }

    /**
     * Có local key mới để cache không.
     *
     * @return bool
     */
    public function hasLocalKey(): bool
    {
        return $this->localKey !== '';
    }

    /**
     * Tạo response khi không kết nối được license server.
     *
     * @return self
     */
    public static function connectionFailed(): self
    {
        $r = new self();
        $r->status = 'ConnectionFailed';
        $r->message = 'Không thể kết nối tới license server.';
        return $r;
    }

    /**
     * Tạo response Active (dùng khi cache local key hợp lệ).
     *
     * @param  string $validUntil
     * @return self
     */
    public static function active(string $validUntil = ''): self
    {
        $r = new self();
        $r->status = 'Active';
        $r->validUntil = $validUntil;
        $r->supportActive = true;
        return $r;
    }
}
