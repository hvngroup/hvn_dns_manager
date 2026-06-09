<?php

namespace MJ\DnsManager\Controllers\Client;

use MJ\DnsManager\Services\EmailForwardService;

/**
 * EmailForwardController — Nhận Ajax request từ Client Area.
 *
 * Controller KHÔNG chứa business logic.
 * Controller chỉ: nhận request → gọi Service → trả JSON response.
 */
class EmailForwardController
{
    /** @var EmailForwardService */
    private $service;

    public function __construct()
    {
        $this->service = new EmailForwardService();
    }

    /**
     * Dispatch request đến method phù hợp dựa vào action.
     *
     * @param  string $action
     * @param  array  $input   Parsed request input
     * @param  int    $userId  WHMCS client ID
     * @return array
     */
    public function dispatch(string $action, array $input, int $userId): array
    {
        switch ($action) {
            case 'list':
                return $this->handleList($input, $userId);
            case 'create':
                return $this->handleCreate($input, $userId);
            case 'delete':
                return $this->handleDelete($input, $userId);
            default:
                return [
                    'success' => false,
                    'error'   => ['code' => 'INVALID_ACTION', 'message' => "Action không hợp lệ: {$action}"],
                ];
        }
    }

    /**
     * GET — Lấy danh sách email forwarders.
     *
     * @param  array $input  { domain_id }
     * @param  int   $userId
     * @return array
     */
    private function handleList(array $input, int $userId): array
    {
        $domainId = (int) ($input['domain_id'] ?? 0);
        if ($domainId <= 0) {
            return $this->missingParam('domain_id');
        }

        return $this->service->list($domainId, $userId);
    }

    /**
     * POST — Tạo email forwarder mới.
     *
     * @param  array $input  { domain_id, source_local, destination_email, is_catchall? }
     * @param  int   $userId
     * @return array
     */
    private function handleCreate(array $input, int $userId): array
    {
        $domainId    = (int) ($input['domain_id'] ?? 0);
        $sourceLocal = trim($input['source_local'] ?? '');
        $destEmail   = trim($input['destination_email'] ?? '');
        $isCatchall  = !empty($input['is_catchall']);

        if ($domainId <= 0) {
            return $this->missingParam('domain_id');
        }

        if (!$isCatchall && $sourceLocal === '') {
            return $this->missingParam('source_local');
        }

        if ($destEmail === '') {
            return $this->missingParam('destination_email');
        }

        return $this->service->create($domainId, $userId, $sourceLocal, $destEmail, $isCatchall);
    }

    /**
     * POST — Xóa email forwarder.
     *
     * @param  array $input  { domain_id, forward_id }
     * @param  int   $userId
     * @return array
     */
    private function handleDelete(array $input, int $userId): array
    {
        $domainId  = (int) ($input['domain_id'] ?? 0);
        $forwardId = (int) ($input['forward_id'] ?? 0);

        if ($domainId <= 0) {
            return $this->missingParam('domain_id');
        }
        if ($forwardId <= 0) {
            return $this->missingParam('forward_id');
        }

        return $this->service->delete($domainId, $userId, $forwardId);
    }

    /**
     * Helper: trả lỗi thiếu parameter.
     *
     * @param  string $param
     * @return array
     */
    private function missingParam(string $param): array
    {
        return [
            'success' => false,
            'error'   => [
                'code'    => 'MISSING_PARAM',
                'message' => "Thiếu tham số bắt buộc: {$param}",
                'field'   => $param,
            ],
        ];
    }
}
