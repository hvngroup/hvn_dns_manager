<?php

namespace MJ\DnsManager\Controllers\Client;

use WHMCS\Database\Capsule;
use MJ\DnsManager\Models\Domain;
use MJ\DnsManager\Models\Redirect;
use MJ\DnsManager\Models\QueueJob;
use MJ\DnsManager\Services\QueueManager;
use MJ\DnsManager\Helpers\AuditLogger;

class RedirectController
{
    /** @var QueueManager */
    private $queue;

    public function __construct()
    {
        $this->queue = new QueueManager();
    }

    public function dispatch($action, $params, $userId)
    {
        $input = json_decode(file_get_contents('php://input'), true);
        if (!is_array($input)) {
            $input = $params;
        }

        switch ($action) {
            case 'get_redirects':
                return $this->getRedirects($input, $userId);
            case 'add_redirect':
                return $this->addRedirect($input, $userId);
            case 'delete_redirect':
                return $this->deleteRedirect($input, $userId);
            default:
                throw new \Exception('Unknown redirect action: ' . $action);
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Helper: lấy domain và kiểm tra quyền
    // ─────────────────────────────────────────────────────────────────────────

    private function getDomainOrError($domainId, $userId)
    {
        $domain = Domain::where('id', $domainId)
            ->where('whmcs_user_id', $userId)
            ->first();

        if (!$domain) {
            throw new \Exception('Domain không tồn tại hoặc bạn không có quyền truy cập.');
        }
        if ($domain->status !== 'active') {
            throw new \Exception('Domain không ở trạng thái Active, không thể thay đổi Redirect.');
        }

        return $domain;
    }

    private function errorResponse($code, $message, $field = null)
    {
        $error = ['code' => $code, 'message' => $message];
        if ($field !== null) {
            $error['field'] = $field;
        }
        return ['success' => false, 'error' => $error];
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Lấy danh sách Redirect
    // ─────────────────────────────────────────────────────────────────────────

    private function getRedirects(array $input, $userId)
    {
        $domainId = (int) ($input['domain_id'] ?? 0);
        $domain = $this->getDomainOrError($domainId, $userId);

        $redirects = Redirect::where('domain_id', $domainId)
            ->orderBy('created_at', 'desc')
            ->get();

        // Gắn sync_status từ queue
        $pendingJobs = QueueJob::where('domain_id', $domainId)
            ->whereIn('action', ['CREATE_REDIRECT', 'DELETE_REDIRECT'])
            ->whereIn('status', ['PENDING', 'SYNCING'])
            ->get()
            ->keyBy(function ($job) {
                $payload = $job->payload;
                return $payload['redirect_id'] ?? 0;
            });

        $items = [];
        foreach ($redirects as $r) {
            $job = $pendingJobs->get($r->id);
            $syncStatus = $job ? strtolower($job->status) : 'complete';

            $items[] = [
                'id' => $r->id,
                'source_path' => $r->source_path,
                'destination_url' => $r->destination_url,
                'type' => $r->type,
                'sync_status' => $syncStatus,
            ];
        }

        return [
            'success' => true,
            'data' => ['redirects' => $items],
        ];
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Thêm Redirect
    // ─────────────────────────────────────────────────────────────────────────

    private function addRedirect(array $input, $userId)
    {
        // Kiểm tra tính năng có được bật không
        if (!\MJ\DnsManager\Helpers\SettingsHelper::getBool('enable_url_redirect', true)) {
            return $this->errorResponse('DISABLED', 'Tính năng URL Redirect hiện đang bị vô hiệu hóa.');
        }

        $domainId = (int) ($input['domain_id'] ?? 0);
        $domain = $this->getDomainOrError($domainId, $userId);

        // Kiểm tra quota
        $redirectLimit = \MJ\DnsManager\Helpers\SettingsHelper::getInt('url_redirect_limit', 5);
        if ($redirectLimit > 0) {
            $currentCount = \MJ\DnsManager\Models\Redirect::where('domain_id', $domainId)->count();
            if ($currentCount >= $redirectLimit) {
                return $this->errorResponse(
                    'QUOTA_EXCEEDED',
                    "Domain đã đạt giới hạn {$redirectLimit} redirect. Vui lòng xóa redirect cũ trước.",
                    'source_path'
                );
            }
        }

        // Validate
        $sourcePath = trim($input['source_path'] ?? '/');
        $destinationUrl = trim($input['destination_url'] ?? '');
        $type = $input['type'] ?? '301';

        if (empty($sourcePath) || $sourcePath[0] !== '/') {
            return $this->errorResponse('VALIDATION_ERROR', 'Source path phải bắt đầu bằng dấu /.', 'source_path');
        }
        if (strlen($sourcePath) > 500) {
            return $this->errorResponse('VALIDATION_ERROR', 'Source path không được vượt quá 500 ký tự.', 'source_path');
        }
        if (empty($destinationUrl)) {
            return $this->errorResponse('VALIDATION_ERROR', 'Destination URL không được để trống.', 'destination_url');
        }
        if (!filter_var($destinationUrl, FILTER_VALIDATE_URL)) {
            return $this->errorResponse('VALIDATION_ERROR', 'Destination URL không hợp lệ. Phải bắt đầu bằng http:// hoặc https://', 'destination_url');
        }
        if (strlen($destinationUrl) > 2000) {
            return $this->errorResponse('VALIDATION_ERROR', 'Destination URL không được vượt quá 2000 ký tự.', 'destination_url');
        }
        if (!in_array($type, ['301', '302'], true)) {
            return $this->errorResponse('VALIDATION_ERROR', 'Loại redirect phải là 301 hoặc 302.', 'type');
        }

        // Kiểm tra trùng source_path trong cùng domain
        $exists = Redirect::where('domain_id', $domainId)
            ->where('source_path', $sourcePath)
            ->first();
        if ($exists) {
            return $this->errorResponse('DUPLICATE_REDIRECT', 'Path "' . $sourcePath . '" đã có redirect. Hãy xóa redirect cũ trước.', 'source_path');
        }

        try {
            Capsule::beginTransaction();

            $redirect = Redirect::create([
                'domain_id' => $domainId,
                'source_path' => $sourcePath,
                'destination_url' => $destinationUrl,
                'type' => $type,
            ]);

            $payload = [
                'redirect_id'     => $redirect->id,
                'source_path'     => $sourcePath,
                'destination_url' => $destinationUrl,
                'redirect_type'   => $type,
            ];

            $batchId = $this->queue->dispatch(
                $domainId,
                'CREATE_REDIRECT',
                $payload,
                5,        // PRIORITY_CLIENT
                'client',
                $userId
            );

            Capsule::commit();

            AuditLogger::redirectAdded(
                $domainId,
                $domain->domain,
                $redirect->id,
                ['source_path' => $sourcePath, 'destination_url' => $destinationUrl, 'type' => $type],
                'client',
                $userId,
                AuditLogger::resolveActorName('client', $userId)
            );

            return [
                'success' => true,
                'data' => ['redirect_id' => $redirect->id, 'batch_id' => $batchId],
                'message' => 'Redirect đã được lưu và đang chờ đồng bộ.',
            ];
        } catch (\Throwable $e) {
            Capsule::rollBack();
            throw $e;
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Xóa Redirect
    // ─────────────────────────────────────────────────────────────────────────

    private function deleteRedirect(array $input, $userId)
    {
        $domainId = (int) ($input['domain_id'] ?? 0);
        $redirectId = (int) ($input['redirect_id'] ?? 0);

        $domain = $this->getDomainOrError($domainId, $userId);

        $redirect = Redirect::where('id', $redirectId)
            ->where('domain_id', $domainId)
            ->first();

        if (!$redirect) {
            throw new \Exception('Redirect không tồn tại.');
        }

        try {
            Capsule::beginTransaction();

            $payload = [
                'redirect_id' => $redirect->id,
                'source_path' => $redirect->source_path,
            ];

            $batchId = $this->queue->dispatch(
                $domainId,
                'DELETE_REDIRECT',
                $payload,
                5,        // PRIORITY_CLIENT
                'client',
                $userId
            );

            Capsule::commit();

            AuditLogger::redirectDeleted(
                $domainId,
                $domain->domain,
                $redirect->id,
                ['source_path' => $redirect->source_path, 'destination_url' => $redirect->destination_url, 'type' => $redirect->type],
                'client',
                $userId,
                AuditLogger::resolveActorName('client', $userId)
            );

            return [
                'success' => true,
                'data' => ['redirect_id' => $redirect->id, 'batch_id' => $batchId],
                'message' => 'Redirect đang được xóa...',
            ];
        } catch (\Throwable $e) {
            Capsule::rollBack();
            throw $e;
        }
    }
}