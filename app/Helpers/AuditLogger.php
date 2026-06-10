<?php

namespace MJ\DnsManager\Helpers;

defined("WHMCS") or die("Access Denied");

use MJ\DnsManager\Models\AuditTrail;

/**
 * AuditLogger — Helper trung tâm ghi nhật ký kiểm toán.
 *
 * Gọi từ: RecordController, RedirectController, AdminController
 * KHÔNG gọi từ: QueueWorker, DAGateway (các thay đổi thật sự xảy ra ở tầng cron)
 *
 * Audit trail ghi lại INTENT của người dùng (họ muốn làm gì),
 * không phải kết quả đồng bộ (sync success/fail → đó là sync_logs).
 */
class AuditLogger
{
    /**
     * Ghi log khi thêm DNS record.
     *
     * @param  int    $domainId
     * @param  string $domain
     * @param  int    $recordId
     * @param  array  $recordData  [type, name, value, ttl, priority, ...]
     * @param  string $actorType   'client' | 'admin' | 'system' | 'api'
     * @param  int|null $actorId
     * @param  string $actorName
     * @return void
     */
    public static function recordAdded(
        int $domainId,
        string $domain,
        int $recordId,
        array $recordData,
        string $actorType,
        $actorId,
        string $actorName
    ): void {
        self::write([
            'actor_type' => $actorType,
            'actor_id' => $actorId,
            'actor_name' => $actorName,
            'domain' => $domain,
            'domain_id' => $domainId,
            'action' => 'add_record',
            'target_type' => 'record',
            'target_id' => $recordId,
            'old_value' => null,
            'new_value' => $recordData,
            'context' => $actorType === 'admin' ? 'admin_editor' : 'client_area',
            'notes' => ($recordData['type'] ?? '') . ' ' . ($recordData['name'] ?? '') . ' added.',
        ]);
    }

    /**
     * Ghi log khi sửa DNS record.
     *
     * @param  int    $domainId
     * @param  string $domain
     * @param  int    $recordId
     * @param  array  $oldData
     * @param  array  $newData
     * @param  string $actorType
     * @param  int|null $actorId
     * @param  string $actorName
     * @return void
     */
    public static function recordEdited(
        int $domainId,
        string $domain,
        int $recordId,
        array $oldData,
        array $newData,
        string $actorType,
        $actorId,
        string $actorName
    ): void {
        self::write([
            'actor_type' => $actorType,
            'actor_id' => $actorId,
            'actor_name' => $actorName,
            'domain' => $domain,
            'domain_id' => $domainId,
            'action' => 'edit_record',
            'target_type' => 'record',
            'target_id' => $recordId,
            'old_value' => $oldData,
            'new_value' => $newData,
            'context' => $actorType === 'admin' ? 'admin_editor' : 'client_area',
            'notes' => ($oldData['type'] ?? '') . ' ' . ($oldData['name'] ?? '') . ' updated.',
        ]);
    }

    /**
     * Ghi log khi xóa DNS record.
     *
     * @param  int    $domainId
     * @param  string $domain
     * @param  int    $recordId
     * @param  array  $recordData  Dữ liệu record trước khi xóa
     * @param  string $actorType
     * @param  int|null $actorId
     * @param  string $actorName
     * @return void
     */
    public static function recordDeleted(
        int $domainId,
        string $domain,
        int $recordId,
        array $recordData,
        string $actorType,
        $actorId,
        string $actorName
    ): void {
        self::write([
            'actor_type' => $actorType,
            'actor_id' => $actorId,
            'actor_name' => $actorName,
            'domain' => $domain,
            'domain_id' => $domainId,
            'action' => 'delete_record',
            'target_type' => 'record',
            'target_id' => $recordId,
            'old_value' => $recordData,
            'new_value' => null,
            'context' => $actorType === 'admin' ? 'admin_editor' : 'client_area',
            'notes' => ($recordData['type'] ?? '') . ' ' . ($recordData['name'] ?? '') . ' deleted.',
        ]);
    }

    /**
     * Ghi log khi thêm redirect.
     */
    public static function redirectAdded(
        int $domainId,
        string $domain,
        int $redirectId,
        array $redirectData,
        string $actorType,
        $actorId,
        string $actorName
    ): void {
        self::write([
            'actor_type' => $actorType,
            'actor_id' => $actorId,
            'actor_name' => $actorName,
            'domain' => $domain,
            'domain_id' => $domainId,
            'action' => 'add_redirect',
            'target_type' => 'redirect',
            'target_id' => $redirectId,
            'old_value' => null,
            'new_value' => $redirectData,
            'context' => $actorType === 'admin' ? 'admin_editor' : 'client_area',
            'notes' => 'Redirect ' . ($redirectData['source_path'] ?? '') . ' → ' . ($redirectData['destination_url'] ?? '') . ' added.',
        ]);
    }

    /**
     * Ghi log khi xóa redirect.
     */
    public static function redirectDeleted(
        int $domainId,
        string $domain,
        int $redirectId,
        array $redirectData,
        string $actorType,
        $actorId,
        string $actorName
    ): void {
        self::write([
            'actor_type' => $actorType,
            'actor_id' => $actorId,
            'actor_name' => $actorName,
            'domain' => $domain,
            'domain_id' => $domainId,
            'action' => 'delete_redirect',
            'target_type' => 'redirect',
            'target_id' => $redirectId,
            'old_value' => $redirectData,
            'new_value' => null,
            'context' => $actorType === 'admin' ? 'admin_editor' : 'client_area',
            'notes' => 'Redirect ' . ($redirectData['source_path'] ?? '') . ' deleted.',
        ]);
    }

    /**
     * Core write — ghi 1 dòng vào audit_trail.
     * Catch mọi exception để không crash luồng chính.
     *
     * @param  array $data
     * @return void
     */
    private static function write(array $data): void
    {
        try {
            AuditTrail::create(array_merge([
                'ip_address' => $_SERVER['REMOTE_ADDR'] ?? '127.0.0.1',
                'user_agent' => isset($_SERVER['HTTP_USER_AGENT'])
                    ? substr($_SERVER['HTTP_USER_AGENT'], 0, 500)
                    : null,
                'session_id' => session_id() ?: null,
            ], $data));
        } catch (\Throwable $e) {
            // Không throw — audit log không được làm crash business logic
            logActivity('MJ DNS Manager [AuditLogger]: Failed to write audit log — ' . $e->getMessage());
        }
    }

    /**
     * Lấy tên actor từ WHMCS DB.
     * Dùng khi không có sẵn tên trong context.
     *
     * @param  string $actorType
     * @param  int|null $actorId
     * @return string
     */
    public static function resolveActorName(string $actorType, $actorId): string
    {
        if (!$actorId) {
            return ucfirst($actorType);
        }

        try {
            if ($actorType === 'client') {
                $row = \WHMCS\Database\Capsule::table('tblclients')
                    ->where('id', $actorId)
                    ->select(['firstname', 'lastname'])
                    ->first();
                return $row ? trim($row->firstname . ' ' . $row->lastname) : 'Client #' . $actorId;
            }

            if ($actorType === 'admin') {
                $row = \WHMCS\Database\Capsule::table('tbladmins')
                    ->where('id', $actorId)
                    ->select(['firstname', 'lastname'])
                    ->first();
                return $row ? trim($row->firstname . ' ' . $row->lastname) : 'Admin #' . $actorId;
            }
        } catch (\Throwable $e) {
            // ignore
        }

        return ucfirst($actorType) . ' #' . $actorId;
    }
}
