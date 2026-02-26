<?php

namespace HvnGroup\DnsManager\Services;

/**
 * Dummy Service for Prototype Phase Phase 0A/0B.
 * Will be fully implemented in Phase 1.
 */
class RecordManager
{
    public function addRecord($domainId, $data)
    {
        // Mock success
        return true;
    }

    public function editRecord($recordId, $data)
    {
        // Mock success
        return true;
    }

    public function deleteRecord($recordId)
    {
        // Mock success
        return true;
    }
}
