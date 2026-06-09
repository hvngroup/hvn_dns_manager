<?php

namespace HvnGroup\DnsManager\Validators;

use HvnGroup\DnsManager\Contracts\JobInterface;

class JobValidator
{
    /** @var array */
    private $errors = [];

    public function validate($domainId, $serverId, $action, array $payload, $priority = 5, $actorType = 'system')
    {
        $this->errors = [];

        $this->validateDomainId($domainId);
        $this->validateServerId($serverId);
        $this->validateAction($action);
        $this->validatePriority($priority);
        $this->validateActorType($actorType);

        if (!isset($this->errors['action'])) {
            $this->validatePayload($action, $payload);
        }

        return empty($this->errors);
    }

    public function getErrors()
    {
        return $this->errors;
    }

    public function getFirstErrorMessage()
    {
        if (empty($this->errors)) {
            return '';
        }
        reset($this->errors);
        return current($this->errors);
    }

    private function validateDomainId($domainId)
    {
        if (!is_int($domainId) && !ctype_digit((string) $domainId)) {
            $this->addError('domain_id', 'domain_id phải là số nguyên dương.');
            return;
        }
        if ((int) $domainId <= 0) {
            $this->addError('domain_id', 'domain_id phải lớn hơn 0.');
        }
    }

    private function validateServerId($serverId)
    {
        if (!is_int($serverId) && !ctype_digit((string) $serverId)) {
            $this->addError('server_id', 'server_id phải là số nguyên dương.');
            return;
        }
        if ((int) $serverId <= 0) {
            $this->addError('server_id', 'server_id phải lớn hơn 0.');
        }
    }

    private function validateAction($action)
    {
        if (!is_string($action) || $action === '') {
            $this->addError('action', 'action không được để trống.');
            return;
        }
        if (!in_array($action, JobInterface::VALID_ACTIONS)) {
            $this->addError('action', "action '{$action}' không hợp lệ. Các action được phép: " . implode(', ', JobInterface::VALID_ACTIONS) . '.');
        }
    }

    private function validatePriority($priority)
    {
        $p = (int) $priority;
        if ($p < 1 || $p > 10) {
            $this->addError('priority', 'priority phải từ 1 (cao nhất) đến 10 (thấp nhất).');
        }
    }

    private function validateActorType($actorType)
    {
        if (!in_array($actorType, JobInterface::VALID_ACTOR_TYPES)) {
            $this->addError('actor_type', "actor_type '{$actorType}' không hợp lệ. Các giá trị hợp lệ: " . implode(', ', JobInterface::VALID_ACTOR_TYPES) . '.');
        }
    }

    private function validatePayload($action, array $payload)
    {
        $requiredKeys = JobInterface::PAYLOAD_REQUIRED_KEYS[$action] ?? [];

        foreach ($requiredKeys as $key) {
            if (!array_key_exists($key, $payload) || $payload[$key] === null || $payload[$key] === '') {
                $this->addError("payload.{$key}", "Payload thiếu trường bắt buộc '{$key}' cho action {$action}.");
            }
        }

        if ($action === 'EDIT_RECORD') {
            $this->validateEditRecordPayload($payload);
        }
    }

    private function validateEditRecordPayload(array $payload)
    {
        foreach (array('name', 'value', 'type') as $k) {
            if (!isset($payload['old_record'][$k]) || $payload['old_record'][$k] === '') {
                $this->addError("payload.old_record.{$k}", "old_record phải có trường '{$k}'.");
            }
        }
        foreach (array('name', 'value', 'type', 'ttl') as $k) {
            if (!isset($payload['new_record'][$k]) || $payload['new_record'][$k] === '') {
                $this->addError("payload.new_record.{$k}", "new_record phải có trường '{$k}'.");
            }
        }
    }

    private function addError($field, $message)
    {
        if (!isset($this->errors[$field])) {
            $this->errors[$field] = $message;
        }
    }
}