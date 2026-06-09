<?php

namespace MJ\DnsManager\Controllers\Client;

defined("WHMCS") or die("Access Denied");

use WHMCS\Database\Capsule;
// ← XÓA: use MJ\DnsManager\Contracts\JobInterface;  (không cần nữa)
use MJ\DnsManager\Models\Domain;
use MJ\DnsManager\Models\Record;
use MJ\DnsManager\Models\QueueJob;
use MJ\DnsManager\Services\QueueManager;
use MJ\DnsManager\Validators\DnsRecordValidator;
use MJ\DnsManager\Validators\ConflictValidator;
use MJ\DnsManager\Security\InputSanitizer;
use MJ\DnsManager\Helpers\AuditLogger;

class RecordController
{
    /** @var QueueManager */
    private $queue;

    /** @var DnsRecordValidator */
    private $validator;

    /** @var ConflictValidator */
    private $conflictValidator;

    public function __construct()
    {
        $this->queue = new QueueManager();
        $this->validator = new DnsRecordValidator();
        $this->conflictValidator = new ConflictValidator();
    }

    public function dispatch($action, $params, $userId)
    {
        $input = json_decode(file_get_contents('php://input'), true);
        if (!is_array($input)) {
            $input = $params;
        }

        switch ($action) {
            case 'add_record':
                return $this->addRecord($input, $userId);
            case 'edit_record':
                return $this->editRecord($input, $userId);
            case 'delete_record':
                return $this->deleteRecord($input, $userId);
            case 'sync_zone':
                return $this->syncZone($input, $userId);
            case 'sync_status':
                return $this->getSyncStatus($input, $userId);
            case 'sync_status_all':
                return $this->getSyncStatusAll($input, $userId);
            case 'get_all_records':
                return $this->getAllRecords($input, $userId);
            default:
                throw new \Exception('Unknown action: ' . $action);
        }
    }

    private function getDomainOrError($domainId, $userId)
    {
        $domain = Domain::where('id', $domainId)
            ->where('whmcs_user_id', $userId)
            ->first();

        if (!$domain) {
            throw new \Exception('Domain không tồn tại hoặc bạn không có quyền truy cập.');
        }
        if ($domain->status !== 'active') {
            throw new \Exception('Domain không ở trạng thái Active, không thể thay đổi DNS.');
        }

        return $domain;
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Thêm Record
    // ─────────────────────────────────────────────────────────────────────────

    private function addRecord(array $input, $userId)
    {
        // Kiểm tra module có bị admin tắt không
        if (!\MJ\DnsManager\Helpers\SettingsHelper::getBool('enable_dns_editor', true)) {
            return $this->errorResponse('DISABLED', 'Tính năng DNS Editor hiện đang bị vô hiệu hóa.');
        }

        $domainId = (int) ($input['domain_id'] ?? 0);
        $domain = $this->getDomainOrError($domainId, $userId);

        if (!$this->validator->validate($input)) {
            $err = $this->validator->getFirstError();
            return $this->errorResponse('VALIDATION_ERROR', $err['message'], $err['field']);
        }

        $type     = strtoupper(InputSanitizer::clean($input['type']));

        // Kiểm tra admin có cho phép thêm loại record này không
        $allowKey = 'allow_modify_' . strtolower($type);
        if (!\MJ\DnsManager\Helpers\SettingsHelper::getBool($allowKey, true)) {
            return $this->errorResponse('NOT_ALLOWED', "Bạn không có quyền thêm bản ghi loại {$type}.");
        }

        $name     = InputSanitizer::cleanRecordName($input['name']);
        $value    = InputSanitizer::cleanRecordValue($type, $input['value']);
        $ttl      = (int) ($input['ttl'] ?? 3600);
        $priority = ($input['priority'] ?? '') !== '' ? (int) $input['priority'] : null;
        $weight   = ($input['weight'] ?? '') !== '' ? (int) $input['weight'] : null;
        $port     = ($input['port'] ?? '') !== '' ? (int) $input['port'] : null;

        // ── HVND-62: Kiểm tra Quota ───────────────────────────────────────────
        $totalLimit = \MJ\DnsManager\Helpers\SettingsHelper::getInt('total_record_limit', 50);
        if ($totalLimit > 0) {
            $currentTotal = Record::where('domain_id', $domainId)
                ->where('pending_delete', 0)
                ->count();
            if ($currentTotal >= $totalLimit) {
                return $this->errorResponse(
                    'QUOTA_EXCEEDED',
                    "Đã đạt giới hạn {$totalLimit} bản ghi cho domain này. Vui lòng liên hệ hỗ trợ để nâng cấp.",
                    'type'
                );
            }
        }

        $typeKey   = strtolower($type) . '_record_limit';
        $typeLimit = \MJ\DnsManager\Helpers\SettingsHelper::getInt($typeKey, 0);
        if ($typeLimit > 0) {
            $currentTypeCount = Record::where('domain_id', $domainId)
                ->where('type', $type)
                ->where('pending_delete', 0)
                ->count();
            if ($currentTypeCount >= $typeLimit) {
                return $this->errorResponse(
                    'QUOTA_EXCEEDED',
                    "Đã đạt giới hạn {$typeLimit} bản ghi {$type} cho domain này.",
                    'type'
                );
            }
        }
        // ── End Quota Check ───────────────────────────────────────────────────

        $conflictMsg = $this->conflictValidator->checkAddConflict($domainId, $type, $name);
        if ($conflictMsg !== null) {
            return $this->errorResponse('CNAME_CONFLICT', $conflictMsg, 'name');
        }

        try {
            Capsule::beginTransaction();

            $record = Record::create([
                'domain_id'      => $domainId,
                'type'           => $type,
                'name'           => $name,
                'value'          => $value,
                'ttl'            => $ttl,
                'priority'       => $priority,
                'weight'         => $weight,
                'port'           => $port,
                'is_system'      => 0,
                'is_locked'      => 0,
                'pending_delete' => 0,
            ]);

            $payload = ['record_id' => $record->id, 'type' => $type, 'name' => $name, 'value' => $value, 'ttl' => $ttl];
            if ($priority !== null) $payload['priority'] = $priority;
            if ($weight !== null)   $payload['weight']   = $weight;
            if ($port !== null)     $payload['port']      = $port;

            $batchId = $this->queue->dispatch(
                $domainId,
                'ADD_RECORD',
                $payload,
                5,
                'client',
                $userId
            );

            Capsule::commit();

            AuditLogger::recordAdded(
                $domainId,
                $domain->domain,
                $record->id,
                ['type' => $type, 'name' => $name, 'value' => $value, 'ttl' => $ttl, 'priority' => $priority],
                'client',
                $userId,
                AuditLogger::resolveActorName('client', $userId)
            );

            return [
                'success' => true,
                'data'    => ['record_id' => $record->id, 'batch_id' => $batchId],
                'message' => 'Bản ghi DNS đã được lưu và đang chờ đồng bộ.',
            ];
        } catch (\Throwable $e) {
            Capsule::rollBack();
            throw $e;
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Sửa Record
    // ─────────────────────────────────────────────────────────────────────────

    private function editRecord(array $input, $userId)
    {
        $domainId = (int) ($input['domain_id'] ?? 0);
        $recordId = (int) ($input['record_id'] ?? 0);

        $domain = $this->getDomainOrError($domainId, $userId);

        $record = Record::where('id', $recordId)->where('domain_id', $domainId)->first();
        if (!$record) {
            throw new \Exception('Bản ghi không tồn tại.');
        }
        if ($record->is_system || $record->is_locked || $record->pending_delete) {
            return $this->errorResponse('RECORD_PROTECTED', 'Bản ghi này bị khóa, đang xóa hoặc là bản ghi hệ thống nên không thể sửa.');
        }

        $input['type'] = $record->type;
        if (!$this->validator->validate($input)) {
            $err = $this->validator->getFirstError();
            return $this->errorResponse('VALIDATION_ERROR', $err['message'], $err['field']);
        }

        // Kiểm tra admin có cho phép chỉnh sửa loại record này không
        $allowKey = 'allow_modify_' . strtolower($record->type);
        if (!\MJ\DnsManager\Helpers\SettingsHelper::getBool($allowKey, true)) {
            return $this->errorResponse('NOT_ALLOWED', "Bạn không có quyền chỉnh sửa bản ghi loại {$record->type}.");
        }

        $name = InputSanitizer::cleanRecordName($input['name']);
        $value = InputSanitizer::cleanRecordValue($record->type, $input['value']);
        $ttl = (int) ($input['ttl'] ?? 3600);
        $priority = ($input['priority'] ?? '') !== '' ? (int) $input['priority'] : null;
        $weight = ($input['weight'] ?? '') !== '' ? (int) $input['weight'] : null;
        $port = ($input['port'] ?? '') !== '' ? (int) $input['port'] : null;

        if ($name !== $record->name) {
            $conflictMsg = $this->conflictValidator->checkAddConflict($domainId, $record->type, $name, $recordId);
            if ($conflictMsg !== null) {
                return $this->errorResponse('CNAME_CONFLICT', $conflictMsg, 'name');
            }
        }

        $oldRecord = $record->toArray();

        try {
            Capsule::beginTransaction();

            $record->update([
                'name' => $name,
                'value' => $value,
                'ttl' => $ttl,
                'priority' => $priority,
                'weight' => $weight,
                'port' => $port,
            ]);

            $payload = [
                'record_id' => $record->id,
                'old_record' => [
                    'name' => $oldRecord['name'],
                    'value' => $oldRecord['value'],
                    'type' => $oldRecord['type'],
                    'priority' => $oldRecord['priority'],
                ],
                'new_record' => [
                    'name' => $name,
                    'value' => $value,
                    'type' => $record->type,
                    'ttl' => $ttl,
                    'priority' => $priority,
                    'weight' => $weight,
                    'port' => $port,
                ],
            ];

            $batchId = $this->queue->dispatch(
                $domainId,
                'EDIT_RECORD',  // ← string trực tiếp
                $payload,
                5,              // PRIORITY_CLIENT
                'client',       // ACTOR_CLIENT
                $userId
            );

            Capsule::commit();

            // Ghi audit log sau khi commit thành công
            AuditLogger::recordEdited(
                $domainId,
                $domain->domain,
                $record->id,
                ['type' => $oldRecord['type'], 'name' => $oldRecord['name'], 'value' => $oldRecord['value'], 'ttl' => $oldRecord['ttl'] ?? 3600],
                ['type' => $record->type, 'name' => $name, 'value' => $value, 'ttl' => $ttl, 'priority' => $priority],
                'client',
                $userId,
                AuditLogger::resolveActorName('client', $userId)
            );

            return [
                'success' => true,
                'data' => ['record_id' => $record->id, 'batch_id' => $batchId],
                'message' => 'Bản ghi đã được cập nhật và đang chờ đồng bộ.',
            ];
        } catch (\Throwable $e) {
            Capsule::rollBack();
            throw $e;
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Xóa Record
    // ─────────────────────────────────────────────────────────────────────────

    private function deleteRecord(array $input, $userId)
    {
        $domainId = (int) ($input['domain_id'] ?? 0);
        $recordId = (int) ($input['record_id'] ?? 0);

        $domain = $this->getDomainOrError($domainId, $userId);

        $record = Record::where('id', $recordId)->where('domain_id', $domainId)->first();
        if (!$record) {
            throw new \Exception('Bản ghi không tồn tại.');
        }
        if ($record->is_system || $record->is_locked) {
            return $this->errorResponse('RECORD_PROTECTED', 'Không thể xóa bản ghi hệ thống hoặc bản ghi đã bị khóa.');
        }

        try {
            Capsule::beginTransaction();

            $record->update(['pending_delete' => 1]);

            $payload = [
                'record_id' => $record->id,
                'type' => $record->type,
                'name' => $record->name,
                'value' => $record->value,
            ];

            $batchId = $this->queue->dispatch(
                $domainId,
                'DELETE_RECORD',  // ← string trực tiếp
                $payload,
                5,                // PRIORITY_CLIENT
                'client',         // ACTOR_CLIENT
                $userId
            );

            Capsule::commit();

            // Ghi audit log sau khi commit thành công
            AuditLogger::recordDeleted(
                $domainId,
                $domain->domain,
                $record->id,
                ['type' => $record->type, 'name' => $record->name, 'value' => $record->value, 'ttl' => $record->ttl ?? 3600],
                'client',
                $userId,
                AuditLogger::resolveActorName('client', $userId)
            );

            return [
                'success' => true,
                'data' => ['record_id' => $record->id, 'batch_id' => $batchId],
                'message' => 'Bản ghi đang được xóa...',
            ];
        } catch (\Throwable $e) {
            Capsule::rollBack();
            throw $e;
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Sync Status
    // ─────────────────────────────────────────────────────────────────────────

    private function getSyncStatus(array $input, $userId)
    {
        $batchId = $input['batch_id'] ?? '';
        if (!$batchId) {
            throw new \Exception('Batch ID is required.');
        }

        $job = QueueJob::with('server')
            ->where('batch_id', $batchId)
            ->where('actor_type', 'client')
            ->where('actor_id', $userId)
            ->first();

        if (!$job) {
            throw new \Exception('Job not found.');
        }

        return [
            'success' => true,
            'data' => [
                'batch_id' => $batchId,
                'status' => strtolower($job->status),
                'error_message' => $job->error_message,
                'server' => [
                    'hostname' => $job->server ? $job->server->hostname : 'Unknown',
                    'status' => strtolower($job->status),
                ],
            ],
        ];
    }

    private function getSyncStatusAll(array $input, $userId)
    {
        $domainId = (int) ($input['domain_id'] ?? 0);
        $domain = $this->getDomainOrError($domainId, $userId);

        $jobs = QueueJob::with('server')
            ->where('domain_id', $domainId)
            ->whereIn('status', ['PENDING', 'SYNCING'])
            ->orderBy('id', 'desc')
            ->get();

        $recordsStatus = [];
        foreach ($jobs as $job) {
            $payload = $job->payload;
            if (isset($payload['record_id'])) {
                $rid = $payload['record_id'];
                $recordsStatus[$rid] = [
                    'status' => strtolower($job->status),
                    'server' => $job->server ? $job->server->hostname : 'Unknown',
                ];
            }
        }

        return [
            'success' => true,
            'data' => [
                'records' => $recordsStatus,
                'has_pending' => $jobs->count() > 0,
            ],
        ];
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Sync Zone
    // ─────────────────────────────────────────────────────────────────────────

    private function syncZone(array $input, $userId)
    {
        $domainId = (int) ($input['domain_id'] ?? 0);
        $this->getDomainOrError($domainId, $userId);

        // Async-first: KHÔNG gọi DA trong request lifecycle của client.
        // Dispatch job SYNC_ZONE để QueueWorker pull zone từ DA về DB; client
        // poll trạng thái qua action 'sync_status' với batch_id trả về.
        $qm = new \MJ\DnsManager\Services\QueueManager();
        $batchId = $qm->dispatch(
            $domainId,
            'SYNC_ZONE',
            [],
            5,
            'client',
            $userId
        );

        return [
            'success' => true,
            'data' => ['batch_id' => $batchId],
            'message' => 'Đang đồng bộ bản ghi từ máy chủ. Vui lòng đợi trong giây lát.',
        ];
    }

    private function getAllRecords(array $input, $userId)
    {
        $domainId = (int) ($input['domain_id'] ?? 0);
        $domain = $this->getDomainOrError($domainId, $userId);

        $records = Record::where('domain_id', $domainId)
            ->orderBy('type')->orderBy('name')->get();

        return [
            'success' => true,
            'data' => ['records' => $records->toArray()],
        ];
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Helper
    // ─────────────────────────────────────────────────────────────────────────

    private function errorResponse($code, $message, $field = null)
    {
        $error = ['code' => $code, 'message' => $message];
        if ($field !== null) {
            $error['field'] = $field;
        }
        return ['success' => false, 'error' => $error];
    }
}
