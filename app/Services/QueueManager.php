<?php

namespace HvnGroup\DnsManager\Services;

/**
 * Dummy Service for Prototype Phase 0A/0B.
 * Will be fully implemented in Phase 1 to handle asynchronous jobs.
 */
class QueueManager
{
    public function dispatch($domainId, $action, $payload, $priority = 5)
    {
        // Mock dispatch success
        return 'mock-batch-id-1234';
    }

    public function processNext()
    {
        // Mock process next
        return true;
    }
}
