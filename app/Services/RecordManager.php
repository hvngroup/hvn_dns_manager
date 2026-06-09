<?php

namespace MJ\DnsManager\Services;

defined("WHMCS") or die("Access Denied");

use MJ\DnsManager\Models\Domain;
use MJ\DnsManager\Models\Record;
use MJ\DnsManager\Models\QueueJob;
use MJ\DnsManager\Helpers\AuditLogger;
use MJ\DnsManager\Validators\DnsRecordValidator;
use MJ\DnsManager\Security\InputSanitizer;
use Illuminate\Database\Capsule\Manager as Capsule;

class RecordManager
{
    /** @var QueueManager */
    private $queue;

    public function __construct()
    {
        $this->queue = new QueueManager();
    }

    // ─────────────────────────────────────────────────────────────────────────
    // DNS Editor — load data cho trang admin_dns_editor
    // ─────────────────────────────────────────────────────────────────────────

    public function getRecordsForEditor(int $domainId): array
    {
        if ($domainId <= 0) {
            return ['domain' => null, 'records' => [], 'error' => 'Thiếu tham số domain_id.'];
        }

        $d = Domain::find($domainId);
        if (!$d) {
            return ['domain' => null, 'records' => [], 'error' => "Domain #{$domainId} không tồn tại."];
        }

        $clientName = '(Unknown)';
        if ($d->whmcs_user_id) {
            $client = Capsule::table('tblclients')
                ->where('id', $d->whmcs_user_id)
                ->select(['firstname', 'lastname'])
                ->first();
            if ($client) {
                $clientName = trim($client->firstname . ' ' . $client->lastname);
            }
        }

        $records = Record::where('domain_id', $domainId)
            ->orderBy('type')->orderBy('name')->get();

        // Batch-query jobs để resolve sync_status
        $jobsByRecord = [];
        $recentJobs = QueueJob::where('domain_id', $domainId)
            ->whereIn('action', ['ADD_RECORD', 'EDIT_RECORD', 'DELETE_RECORD'])
            ->orderByDesc('id')->get();

        foreach ($recentJobs as $job) {
            $payload = is_array($job->payload) ? $job->payload : [];
            $rid = (int) ($payload['record_id'] ?? 0);
            if ($rid > 0 && !isset($jobsByRecord[$rid])) {
                $jobsByRecord[$rid] = $job->status;
            }
        }

        $syncStatusMap = [
            'COMPLETE' => 'complete',
            'FAILED' => 'failed',
            'PERMANENTLY_FAILED' => 'failed',
            'PENDING' => 'syncing',
            'SYNCING' => 'syncing',
            'CANCELLED' => 'syncing',
        ];

        $recordsArr = $records->map(function (Record $r) use ($jobsByRecord, $syncStatusMap) {
            $rawStatus = $jobsByRecord[$r->id] ?? 'COMPLETE';
            return [
                'id' => $r->id,
                'type' => $r->type,
                'name' => $r->name,
                'value' => $r->value,
                'ttl' => $r->ttl ?? 3600,
                'priority' => $r->priority,
                'weight' => $r->weight,
                'port' => $r->port,
                'is_system' => (bool) $r->is_system,
                'is_locked' => (bool) $r->is_locked,
                'pending_delete' => (bool) $r->pending_delete,
                'sync_status' => $syncStatusMap[$rawStatus] ?? 'complete',
            ];
        })->values()->toArray();

        return [
            'error' => null,
            'domain' => [
                'id' => $d->id,
                'domain' => $d->domain,
                'client_id' => $d->whmcs_user_id,
                'client_name' => $clientName,
                'status' => $d->status,
            ],
            'records' => $recordsArr,
        ];
    }

    // ─────────────────────────────────────────────────────────────────────────
    // CRUD — nhận array input, trả về array result
    // ─────────────────────────────────────────────────────────────────────────

    public function addRecord(array $input, string $actorType = 'admin', int $actorId = null): array
    {
        try {
            $domainId = (int) ($input['domain_id'] ?? 0);
            $domain = Domain::find($domainId);
            if (!$domain) {
                return ['success' => false, 'error' => ['message' => 'Domain không tồn tại.']];
            }

            $validator = new DnsRecordValidator();
            if (!$validator->validate($input)) {
                $err = $validator->getFirstError();
                return ['success' => false, 'error' => ['message' => $err['message'], 'field' => $err['field'] ?? null]];
            }

            $type = strtoupper(InputSanitizer::clean($input['type']));
            $name = InputSanitizer::cleanRecordName($input['name']);
            $value = InputSanitizer::cleanRecordValue($type, $input['value']);
            $ttl = (int) ($input['ttl'] ?? 3600);
            $priority = ($input['priority'] ?? '') !== '' ? (int) $input['priority'] : null;
            $weight = ($input['weight'] ?? '') !== '' ? (int) $input['weight'] : null;
            $port = ($input['port'] ?? '') !== '' ? (int) $input['port'] : null;

            // ── HVND-62: Kiểm tra Quota (admin path) ─────────────────────────────────
            $totalLimit = \MJ\DnsManager\Helpers\SettingsHelper::getInt('total_record_limit', 50);
            if ($totalLimit > 0) {
                $currentTotal = Record::where('domain_id', $domainId)
                    ->where('pending_delete', 0)
                    ->count();
                if ($currentTotal >= $totalLimit) {
                    return ['success' => false, 'error' => [
                        'message' => "Domain đã đạt giới hạn {$totalLimit} bản ghi DNS.",
                        'field'   => 'type',
                    ]];
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
                    return ['success' => false, 'error' => [
                        'message' => "Domain đã đạt giới hạn {$typeLimit} bản ghi {$type}.",
                        'field'   => 'type',
                    ]];
                }
            }
            // ── End HVND-62 ───────────────────────────────────────────────────────────

            Capsule::beginTransaction();

            $record = Record::create([
                'domain_id' => $domainId,
                'type' => $type,
                'name' => $name,
                'value' => $value,
                'ttl' => $ttl,
                'priority' => $priority,
                'weight' => $weight,
                'port' => $port,
                'is_system' => 0,
                'is_locked' => 0,
                'pending_delete' => 0,
            ]);

            $payload = ['record_id' => $record->id, 'type' => $type, 'name' => $name, 'value' => $value, 'ttl' => $ttl];
            if ($priority !== null)
                $payload['priority'] = $priority;
            if ($weight !== null)
                $payload['weight'] = $weight;
            if ($port !== null)
                $payload['port'] = $port;

            $batchId = $this->queue->dispatch($domainId, 'ADD_RECORD', $payload, 1, $actorType, $actorId);

            Capsule::commit();

            AuditLogger::recordAdded(
                $domainId,
                $domain->domain,
                $record->id,
                ['type' => $type, 'name' => $name, 'value' => $value, 'ttl' => $ttl, 'priority' => $priority],
                $actorType,
                $actorId,
                ucfirst($actorType)
            );

            return [
                'success' => true,
                'data' => ['record_id' => $record->id, 'batch_id' => $batchId],
                'message' => 'Bản ghi đã được thêm và đang đồng bộ.',
            ];
        } catch (\Throwable $e) {
            if (Capsule::connection()->transactionLevel() > 0)
                Capsule::rollBack();
            return ['success' => false, 'error' => ['message' => $e->getMessage()]];
        }
    }

    public function editRecord(array $input, string $actorType = 'admin', int $actorId = null): array
    {
        try {
            $domainId = (int) ($input['domain_id'] ?? 0);
            $recordId = (int) ($input['record_id'] ?? 0);

            $domain = Domain::find($domainId);
            if (!$domain) {
                return ['success' => false, 'error' => ['message' => 'Domain không tồn tại.']];
            }

            $record = Record::where('id', $recordId)->where('domain_id', $domainId)->first();
            if (!$record) {
                return ['success' => false, 'error' => ['message' => 'Bản ghi không tồn tại.']];
            }

            $input['type'] = $record->type;
            $validator = new DnsRecordValidator();
            if (!$validator->validate($input)) {
                $err = $validator->getFirstError();
                return ['success' => false, 'error' => ['message' => $err['message'], 'field' => $err['field'] ?? null]];
            }

            $name = InputSanitizer::cleanRecordName($input['name']);
            $value = InputSanitizer::cleanRecordValue($record->type, $input['value']);
            $ttl = (int) ($input['ttl'] ?? 3600);
            $priority = ($input['priority'] ?? '') !== '' ? (int) $input['priority'] : null;
            $weight = ($input['weight'] ?? '') !== '' ? (int) $input['weight'] : null;
            $port = ($input['port'] ?? '') !== '' ? (int) $input['port'] : null;
            $oldData = ['type' => $record->type, 'name' => $record->name, 'value' => $record->value, 'ttl' => $record->ttl ?? 3600];

            Capsule::beginTransaction();

            $record->update(['name' => $name, 'value' => $value, 'ttl' => $ttl, 'priority' => $priority, 'weight' => $weight, 'port' => $port]);

            $batchId = $this->queue->dispatch($domainId, 'EDIT_RECORD', [
                'record_id' => $record->id,
                'old_record' => ['name' => $oldData['name'], 'value' => $oldData['value'], 'type' => $oldData['type'], 'priority' => $record->getOriginal('priority')],
                'new_record' => ['name' => $name, 'value' => $value, 'type' => $record->type, 'ttl' => $ttl, 'priority' => $priority, 'weight' => $weight, 'port' => $port],
            ], 1, $actorType, $actorId);

            Capsule::commit();

            AuditLogger::recordEdited(
                $domainId,
                $domain->domain,
                $record->id,
                $oldData,
                ['type' => $record->type, 'name' => $name, 'value' => $value, 'ttl' => $ttl],
                $actorType,
                $actorId,
                ucfirst($actorType)
            );

            return [
                'success' => true,
                'data' => ['record_id' => $record->id, 'batch_id' => $batchId],
                'message' => 'Bản ghi đã được cập nhật và đang đồng bộ.',
            ];
        } catch (\Throwable $e) {
            if (Capsule::connection()->transactionLevel() > 0)
                Capsule::rollBack();
            return ['success' => false, 'error' => ['message' => $e->getMessage()]];
        }
    }

    public function deleteRecord(array $input, string $actorType = 'admin', int $actorId = null): array
    {
        try {
            $domainId = (int) ($input['domain_id'] ?? 0);
            $recordId = (int) ($input['record_id'] ?? 0);

            $domain = Domain::find($domainId);
            if (!$domain) {
                return ['success' => false, 'error' => ['message' => 'Domain không tồn tại.']];
            }

            $record = Record::where('id', $recordId)->where('domain_id', $domainId)->first();
            if (!$record) {
                return ['success' => false, 'error' => ['message' => 'Bản ghi không tồn tại.']];
            }

            $oldData = ['type' => $record->type, 'name' => $record->name, 'value' => $record->value, 'ttl' => $record->ttl ?? 3600];

            Capsule::beginTransaction();

            $record->update(['pending_delete' => 1]);

            $batchId = $this->queue->dispatch($domainId, 'DELETE_RECORD', [
                'record_id' => $record->id,
                'type' => $record->type,
                'name' => $record->name,
                'value' => $record->value,
            ], 1, $actorType, $actorId);

            Capsule::commit();

            AuditLogger::recordDeleted(
                $domainId,
                $domain->domain,
                $record->id,
                $oldData,
                $actorType,
                $actorId,
                ucfirst($actorType)
            );

            return [
                'success' => true,
                'data' => ['record_id' => $record->id, 'batch_id' => $batchId],
                'message' => 'Bản ghi đang được xóa.',
            ];
        } catch (\Throwable $e) {
            if (Capsule::connection()->transactionLevel() > 0)
                Capsule::rollBack();
            return ['success' => false, 'error' => ['message' => $e->getMessage()]];
        }
    }

    public function toggleLock(array $input): array
    {
        try {
            $recordId = (int) ($input['record_id'] ?? 0);
            $locked = !empty($input['is_locked']);

            $record = Record::find($recordId);
            if (!$record) {
                return ['success' => false, 'error' => ['message' => 'Bản ghi không tồn tại.']];
            }

            $record->update(['is_locked' => $locked ? 1 : 0]);

            return [
                'success' => true,
                'data' => ['is_locked' => (bool) $record->is_locked],
                'message' => $locked ? 'Đã khóa bản ghi.' : 'Đã mở khóa bản ghi.',
            ];
        } catch (\Throwable $e) {
            return ['success' => false, 'error' => ['message' => $e->getMessage()]];
        }
    }
}
