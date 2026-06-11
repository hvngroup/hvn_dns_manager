<?php

namespace MJ\DnsManager\Services;

defined("WHMCS") or die("Access Denied");

use MJ\DnsManager\Models\QueueJob;
use MJ\DnsManager\Models\Server;
use MJ\DnsManager\Validators\JobValidator;

class QueueManager
{
    /**
     * Dispatch a new DNS job to the Primary server queue.
     *
     * @param  int         $domainId
     * @param  string      $action    VD: 'ADD_RECORD', 'EDIT_RECORD', 'DELETE_RECORD', 'CREATE_ZONE'...
     * @param  array       $payload
     * @param  int         $priority  1 (cao nhất) → 10 (thấp nhất). Mặc định 5.
     * @param  string      $actorType 'client' | 'admin' | 'system' | 'api'. Mặc định 'system'.
     * @param  int|null    $actorId
     * @return string      UUID batch_id
     */
    public function dispatch(
        $domainId,
        $action,
        array $payload,
        $priority = 5,
        $actorType = 'system',
        $actorId = null
    ) {
        $now = date('Y-m-d H:i:s');

        // ── 1. Lấy danh sách Active Servers ───────────────────────────────
        $servers = Server::where('is_active', true)
            ->orderBy('sort_order', 'asc')
            ->get();

        if ($servers->isEmpty()) {
            throw new \RuntimeException('No active DirectAdmin server found. Cannot dispatch job.');
        }

        // ── 2. Validate payload ───────────────────────────────────────────
        $validator = new JobValidator();
        if (!$validator->validate($domainId, $servers->first()->id, $action, $payload, $priority, $actorType)) {
            throw new \InvalidArgumentException(
                'QueueManager::dispatch() — Invalid job data: ' . $validator->getFirstErrorMessage()
            );
        }

        // ── 3. INSERT vào queue (Fan-out) ─────────────────────────────────
        $batchId = $this->generateUuid();
        $maxAttempts = \MJ\DnsManager\Helpers\SettingsHelper::getInt('max_retry_attempts', 5);

        foreach ($servers as $server) {
            QueueJob::create([
                'batch_id' => $batchId,
                'domain_id' => (int) $domainId,
                'server_id' => $server->id,
                'action' => $action,
                'payload' => $payload,
                'status' => 'PENDING', // JobInterface::STATUS_PENDING
                'priority' => (int) $priority,
                'attempts' => 0,
                'max_attempts' => $maxAttempts,
                'actor_type' => $actorType,
                'actor_id' => $actorId,
                'scheduled_at' => $now,
                'created_at' => $now,
            ]);
        }

        return $batchId;
    }

    public function getStatus($batchId)
    {
        $job = QueueJob::where('batch_id', $batchId)->first();
        return $job ? $job->status : null;
    }

    public function cancelPending($batchId)
    {
        return QueueJob::where('batch_id', $batchId)
            ->where('status', 'PENDING')    // JobInterface::STATUS_PENDING
            ->update(['status' => 'CANCELLED']); // JobInterface::STATUS_CANCELLED
    }

    private function generateUuid()
    {
        if (class_exists(\Ramsey\Uuid\Uuid::class)) {
            return \Ramsey\Uuid\Uuid::uuid4()->toString();
        }

        return sprintf(
            '%04x%04x-%04x-%04x-%04x-%04x%04x%04x',
            mt_rand(0, 0xffff),
            mt_rand(0, 0xffff),
            mt_rand(0, 0xffff),
            mt_rand(0, 0x0fff) | 0x4000,
            mt_rand(0, 0x3fff) | 0x8000,
            mt_rand(0, 0xffff),
            mt_rand(0, 0xffff),
            mt_rand(0, 0xffff)
        );
    }
}
