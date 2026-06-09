<?php

namespace MJ\DnsManager\Services;

use MJ\DnsManager\Models\Record;
use MJ\DnsManager\Helpers\SettingsHelper;

/**
 * QuotaChecker — Kiểm tra giới hạn record trước khi cho phép thêm mới.
 *
 * Lớp 1 (hiện tại): Giới hạn tĩnh từ Admin Settings
 * Lớp 2 (HVND-61) : Giới hạn theo Product Params WHMCS — sẽ thêm sau
 * Lớp 3 (HVND-61) : Override per-domain — sẽ thêm sau
 */
class QuotaChecker
{
    /**
     * Kiểm tra domain có còn quota để thêm record loại $type không.
     *
     * @param  int    $domainId
     * @param  string $type      Loại record: A, AAAA, CNAME, MX, TXT, SRV, NS, CAA
     * @return array  ['allowed' => bool, 'reason' => string|null]
     */
    public function check(int $domainId, string $type): array
    {
        $type = strtoupper($type);

        // ── Lớp 1: Giới hạn tĩnh từ Settings ────────────────────────────

        // 1a. Giới hạn tổng số record
        $totalLimit = SettingsHelper::getInt('total_record_limit', 0);
        if ($totalLimit > 0) {
            $totalCount = Record::where('domain_id', $domainId)
                ->where('pending_delete', 0)
                ->count();

            if ($totalCount >= $totalLimit) {
                return [
                    'allowed' => false,
                    'reason' => "Domain đã đạt giới hạn tối đa {$totalLimit} bản ghi DNS.",
                ];
            }
        }

        // 1b. Giới hạn theo từng loại record
        $typeKey = strtolower($type) . '_record_limit';
        $typeLimit = SettingsHelper::getInt($typeKey, 0);

        if ($typeLimit > 0) {
            $typeCount = Record::where('domain_id', $domainId)
                ->where('type', $type)
                ->where('pending_delete', 0)
                ->count();

            if ($typeCount >= $typeLimit) {
                return [
                    'allowed' => false,
                    'reason' => "Domain đã đạt giới hạn tối đa {$typeLimit} bản ghi loại {$type}.",
                ];
            }
        }

        // ── Lớp 2 & 3: HVND-61 — sẽ implement sau ───────────────────────
        // $productQuota = $this->resolveProductQuota($domainId, $type);
        // if ($productQuota !== null && $typeCount >= $productQuota) { ... }

        return ['allowed' => true, 'reason' => null];
    }

    /**
     * Trả về thông tin quota hiện tại của domain (dùng cho UI hiển thị).
     *
     * @param  int $domainId
     * @return array
     */
    public function getUsage(int $domainId): array
    {
        $totalLimit = SettingsHelper::getInt('total_record_limit', 0);
        $totalCount = Record::where('domain_id', $domainId)
            ->where('pending_delete', 0)
            ->count();

        $perType = [];
        $types = ['A', 'AAAA', 'CNAME', 'MX', 'TXT', 'SRV', 'NS', 'CAA'];

        foreach ($types as $t) {
            $limit = SettingsHelper::getInt(strtolower($t) . '_record_limit', 0);
            $count = Record::where('domain_id', $domainId)
                ->where('type', $t)
                ->where('pending_delete', 0)
                ->count();

            $perType[$t] = [
                'count' => $count,
                'limit' => $limit,
                'full'  => $limit > 0 && $count >= $limit,
            ];
        }

        return [
            'total_count' => $totalCount,
            'total_limit' => $totalLimit,
            'total_full'  => $totalLimit > 0 && $totalCount >= $totalLimit,
            'per_type'    => $perType,
        ];
    }
}