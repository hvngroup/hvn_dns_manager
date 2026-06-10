<?php

namespace MJ\DnsManager\Services;

defined("WHMCS") or die("Access Denied");

use Illuminate\Database\Capsule\Manager as Capsule;

/**
 * Phân giải tính năng theo billing của end-user (Tầng 3 — chỉ chạy khi mode='paid').
 *
 * Lưu ý schema: module theo dõi domain qua whmcs_user_id / whmcs_domain_id (không
 * lưu service_id). Vì vậy việc kiểm tra "đã mua addon" được thực hiện theo USER:
 * tìm trong các dịch vụ (tblhosting) của user có Product Addon DNSSEC/DDNS đang
 * Active hay không. Đây là cách bám sát schema thực tế của module.
 *
 * @package MJ\DnsManager\Services
 */
class ClientFeatureResolver
{
    /**
     * User có quyền dùng DNSSEC (đã mua addon/option) không.
     *
     * @param  int $userId WHMCS client id (tblhosting.userid)
     * @return bool
     */
    public function userHasDnssec(int $userId): bool
    {
        return $this->hasActiveAddon($userId, ['DNSSEC'])
            || $this->hasConfigOption($userId, ['DNSSEC']);
    }

    /**
     * User có quyền dùng DDNS (đã mua addon/option) không.
     *
     * @param  int $userId WHMCS client id
     * @return bool
     */
    public function userHasDdns(int $userId): bool
    {
        return $this->hasActiveAddon($userId, ['Dynamic DNS', 'DDNS'])
            || $this->hasConfigOption($userId, ['Dynamic DNS', 'DDNS']);
    }

    /**
     * Có Product Addon đang Active khớp tên cho user không.
     *
     * @param  int      $userId
     * @param  string[] $names  Danh sách từ khóa tên addon (LIKE).
     * @return bool
     */
    private function hasActiveAddon(int $userId, array $names): bool
    {
        if ($userId <= 0) {
            return false;
        }
        try {
            return Capsule::table('tblhostingaddons')
                ->join('tblhosting', 'tblhostingaddons.hostingid', '=', 'tblhosting.id')
                ->where('tblhosting.userid', $userId)
                ->where('tblhostingaddons.status', 'Active')
                ->where(function ($q) use ($names) {
                    foreach ($names as $n) {
                        $q->orWhere('tblhostingaddons.name', 'like', '%' . $n . '%');
                    }
                })
                ->exists();
        } catch (\Throwable $e) {
            return false;
        }
    }

    /**
     * Có Configurable Option được chọn (qty > 0) khớp tên cho user không.
     *
     * @param  int      $userId
     * @param  string[] $names
     * @return bool
     */
    private function hasConfigOption(int $userId, array $names): bool
    {
        if ($userId <= 0) {
            return false;
        }
        try {
            return Capsule::table('tblhostingconfigoptions')
                ->join('tblhosting', 'tblhostingconfigoptions.relid', '=', 'tblhosting.id')
                ->join('tblproductconfigoptions', 'tblhostingconfigoptions.configid', '=', 'tblproductconfigoptions.id')
                ->where('tblhosting.userid', $userId)
                ->where('tblhostingconfigoptions.qty', '>', 0)
                ->where(function ($q) use ($names) {
                    foreach ($names as $n) {
                        $q->orWhere('tblproductconfigoptions.optionname', 'like', '%' . $n . '%');
                    }
                })
                ->exists();
        } catch (\Throwable $e) {
            return false;
        }
    }
}
