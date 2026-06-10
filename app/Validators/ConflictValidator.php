<?php

namespace MJ\DnsManager\Validators;

defined("WHMCS") or die("Access Denied");

use MJ\DnsManager\Models\Record;

/**
 * ConflictValidator — Kiểm tra xung đột RFC giữa các DNS record.
 *
 * Theo SPEC.md Section 9.3 và RFC 1912 / RFC 2181:
 *   - CNAME không được trùng name với A, AAAA, MX record
 *   - CNAME tại root (@) không được tồn tại nếu domain có MX
 *   - Không có 2 CNAME cùng name
 *
 * Được gọi từ RecordController TRƯỚC khi lưu vào DB và dispatch Queue.
 *
 * @package MJ\DnsManager\Validators
 * @since   1.0.0
 */
class ConflictValidator
{
    /**
     * Kiểm tra xung đột khi thêm record mới.
     *
     * Trả về null nếu không có xung đột.
     * Trả về string mô tả lỗi nếu có xung đột.
     *
     * @param  int    $domainId  ID domain trong tbl_mj_dns_domains.
     * @param  string $type      Loại record mới (A, CNAME, MX, ...).
     * @param  string $name      Name của record mới (@ hoặc subdomain).
     * @param  int    $excludeId ID record cần bỏ qua khi check (dùng khi edit).
     * @return string|null       Null nếu OK, message lỗi nếu có conflict.
     */
    public function checkAddConflict($domainId, $type, $name, $excludeId = null)
    {
        $type = strtoupper(trim($type));
        $name = trim($name);

        // ── Rule 1: Thêm CNAME — kiểm tra name đã có A/AAAA/MX không ────────
        if ($type === 'CNAME') {
            return $this->checkCnameConflict($domainId, $name, $excludeId);
        }

        // ── Rule 2: Thêm A/AAAA/MX — kiểm tra name đã có CNAME không ────────
        if (in_array($type, ['A', 'AAAA', 'MX'])) {
            return $this->checkAgainstExistingCname($domainId, $type, $name, $excludeId);
        }

        return null; // Không có conflict
    }

    /**
     * Kiểm tra xung đột CNAME theo RFC 1912.
     *
     * CNAME không được tồn tại cùng name với bất kỳ record nào khác.
     * - Nếu name đã có A/AAAA/MX → không được tạo CNAME
     * - Nếu name đã có CNAME → không được tạo thêm CNAME trùng name
     * - CNAME tại @ không hợp lệ nếu domain có bất kỳ record nào khác
     *
     * @param  int    $domainId
     * @param  string $name
     * @param  int|null $excludeId
     * @return string|null
     */
    public function checkCnameConflict($domainId, $name, $excludeId = null)
    {
        $query = Record::where('domain_id', $domainId)
            ->where('name', $name)
            ->where('pending_delete', 0);

        if ($excludeId !== null) {
            $query->where('id', '!=', $excludeId);
        }

        $existingTypes = $query->pluck('type')->toArray();

        if (empty($existingTypes)) {
            return null; // Không có record cùng name → OK
        }

        // Nếu đã có CNAME cùng name → duplicate CNAME
        if (in_array('CNAME', $existingTypes)) {
            return "Đã tồn tại CNAME record với name '{$name}'. Không thể tạo thêm CNAME trùng name.";
        }

        // Nếu đã có A, AAAA, hoặc MX cùng name → CNAME conflict (RFC 1912)
        $conflicting = array_intersect($existingTypes, ['A', 'AAAA', 'MX', 'NS', 'SOA']);
        if (!empty($conflicting)) {
            $conflictList = implode(', ', array_unique($conflicting));
            return "Không thể tạo CNAME cho '{$name}' vì đã tồn tại record loại {$conflictList} cùng name (vi phạm RFC 1912). Hãy xóa các record xung đột trước.";
        }

        return null;
    }

    /**
     * Kiểm tra xem name đã có CNAME chưa khi thêm A/AAAA/MX.
     *
     * Nếu name đã có CNAME → không được thêm A/AAAA/MX vào cùng name.
     *
     * @param  int    $domainId
     * @param  string $newType   A, AAAA hoặc MX
     * @param  string $name
     * @param  int|null $excludeId
     * @return string|null
     */
    private function checkAgainstExistingCname($domainId, $newType, $name, $excludeId = null)
    {
        $query = Record::where('domain_id', $domainId)
            ->where('name', $name)
            ->where('type', 'CNAME')
            ->where('pending_delete', 0);

        if ($excludeId !== null) {
            $query->where('id', '!=', $excludeId);
        }

        $cnameExists = $query->exists();

        if ($cnameExists) {
            return "Không thể tạo {$newType} record cho '{$name}' vì đã tồn tại CNAME cùng name (vi phạm RFC 1912). Hãy xóa CNAME trước.";
        }

        return null;
    }
}
