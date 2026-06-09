<?php

namespace MJ\DnsManager\Services;

defined("WHMCS") or die("Access Denied");

use MJ\DnsManager\Models\Domain;
use MJ\DnsManager\Models\EmailForward;

/**
 * EmailForwardService — Business logic cho Email Forwarding.
 *
 * Tuân thủ kiến trúc Async-First:
 * - KHÔNG gọi DAGateway trực tiếp
 * - Mọi thay đổi → QueueManager::dispatch() → Cron Worker
 */
class EmailForwardService
{
    /**
     * Lấy danh sách email forwarders của domain.
     *
     * @param  int $domainId
     * @param  int $userId   WHMCS client ID (để xác minh ownership)
     * @return array
     */
    public function list(int $domainId, int $userId): array
    {
        $domain = $this->getDomainForUser($domainId, $userId);
        if (!$domain) {
            return [
                'success' => false,
                'error'   => ['code' => 'DOMAIN_NOT_FOUND', 'message' => 'Domain không tồn tại hoặc không thuộc về bạn.'],
            ];
        }

        $forwarders = EmailForward::forDomain($domainId)
            ->orderBy('is_catchall', 'DESC')
            ->orderBy('source_local', 'ASC')
            ->get()
            ->map(function ($fwd) use ($domain) {
                return [
                    'id'                => $fwd->id,
                    'source_local'      => $fwd->source_local,
                    'source_email'      => $fwd->is_catchall ? '*@' . $domain->domain : $fwd->source_local . '@' . $domain->domain,
                    'destination_email' => $fwd->destination_email,
                    'is_catchall'       => $fwd->is_catchall,
                    'sync_status'       => $fwd->isSynced() ? 'synced' : 'pending',
                    'created_at'        => $fwd->created_at ? $fwd->created_at->toIso8601String() : null,
                ];
            });

        return [
            'success' => true,
            'data'    => [
                'domain'     => $domain->domain,
                'forwarders' => $forwarders,
            ],
        ];
    }

    /**
     * Tạo email forwarder mới.
     *
     * @param  int    $domainId
     * @param  int    $userId
     * @param  string $sourceLocal     Local part (VD: "info")
     * @param  string $destEmail       Email đích
     * @param  bool   $isCatchall      Có phải catchall không
     * @return array
     */
    public function create(int $domainId, int $userId, string $sourceLocal, string $destEmail, bool $isCatchall = false): array
    {
        $domain = $this->getDomainForUser($domainId, $userId);
        if (!$domain) {
            return [
                'success' => false,
                'error'   => ['code' => 'DOMAIN_NOT_FOUND', 'message' => 'Domain không tồn tại hoặc không thuộc về bạn.'],
            ];
        }

        // Validate fields
        $validationError = $this->validateForwarder($sourceLocal, $destEmail, $isCatchall);
        if ($validationError) {
            return ['success' => false, 'error' => $validationError];
        }

        // Kiểm tra trùng source_local (hoặc catchall đã tồn tại)
        $exists = EmailForward::forDomain($domainId)
            ->where(function ($q) use ($sourceLocal, $isCatchall) {
                if ($isCatchall) {
                    $q->where('is_catchall', true);
                } else {
                    $q->where('source_local', $sourceLocal)->where('is_catchall', false);
                }
            })
            ->exists();

        if ($exists) {
            $msg = $isCatchall
                ? 'Catch-all đã được thiết lập cho domain này.'
                : "Forwarder với địa chỉ nguồn '{$sourceLocal}' đã tồn tại.";
            return [
                'success' => false,
                'error'   => ['code' => 'DUPLICATE_FORWARDER', 'message' => $msg],
            ];
        }

        // Lưu vào DB
        $forward = EmailForward::create([
            'domain_id'         => $domainId,
            'source_local'      => $isCatchall ? '*' : $sourceLocal,
            'destination_email' => $destEmail,
            'is_catchall'       => $isCatchall,
            'synced_at'         => null, // chưa sync
        ]);

        // Dispatch job vào Queue
        $queueManager = new QueueManager();
        $queueManager->dispatch($domainId, 'CREATE_EMAIL_FWD', [
            'user'             => $isCatchall ? '*' : $sourceLocal,  // DA API param: local part
            'email'            => $destEmail,                         // DA API param: destination
            'is_catchall'      => $isCatchall,
            'email_forward_id' => $forward->id,                       // metadata nội bộ
        ]);

        $sourceEmail = $isCatchall ? '*@' . $domain->domain : $sourceLocal . '@' . $domain->domain;

        return [
            'success' => true,
            'data'    => [
                'forward_id'  => $forward->id,
                'source_email' => $sourceEmail,
                'sync_status' => 'pending',
            ],
            'message' => "Email forwarder {$sourceEmail} đã được tạo và đang đồng bộ.",
        ];
    }

    /**
     * Xóa email forwarder.
     *
     * @param  int $domainId
     * @param  int $userId
     * @param  int $forwardId
     * @return array
     */
    public function delete(int $domainId, int $userId, int $forwardId): array
    {
        $domain = $this->getDomainForUser($domainId, $userId);
        if (!$domain) {
            return [
                'success' => false,
                'error'   => ['code' => 'DOMAIN_NOT_FOUND', 'message' => 'Domain không tồn tại hoặc không thuộc về bạn.'],
            ];
        }

        $forward = EmailForward::forDomain($domainId)->where('id', $forwardId)->first();
        if (!$forward) {
            return [
                'success' => false,
                'error'   => ['code' => 'FORWARDER_NOT_FOUND', 'message' => 'Forwarder không tồn tại.'],
            ];
        }

        // Dispatch DELETE job — Worker sẽ xóa DB sau khi DA xác nhận
        $queueManager = new QueueManager();
        $queueManager->dispatch($domainId, 'DELETE_EMAIL_FWD', [
            'user'             => $forward->source_local,  // DA API param: local part
            'email_forward_id' => $forward->id,            // metadata nội bộ
        ]);

        return [
            'success' => true,
            'message' => 'Email forwarder đang được xóa...',
        ];
    }

    /**
     * Validate các trường của email forwarder.
     *
     * @param  string $sourceLocal
     * @param  string $destEmail
     * @param  bool   $isCatchall
     * @return array|null  null nếu hợp lệ, array error nếu không hợp lệ
     */
    private function validateForwarder(string $sourceLocal, string $destEmail, bool $isCatchall): ?array
    {
        // Validate destination email
        if (empty($destEmail) || !filter_var($destEmail, FILTER_VALIDATE_EMAIL)) {
            return [
                'code'    => 'VALIDATION_ERROR',
                'message' => 'Địa chỉ email đích không hợp lệ.',
                'field'   => 'destination_email',
            ];
        }

        // Validate source local (chỉ khi không phải catchall)
        if (!$isCatchall) {
            if (empty($sourceLocal)) {
                return [
                    'code'    => 'VALIDATION_ERROR',
                    'message' => 'Địa chỉ nguồn không được để trống.',
                    'field'   => 'source_local',
                ];
            }
            if (!preg_match('/^[a-zA-Z0-9._+\-]{1,64}$/', $sourceLocal)) {
                return [
                    'code'    => 'VALIDATION_ERROR',
                    'message' => 'Địa chỉ nguồn chỉ được chứa chữ cái, số, và các ký tự . _ + -',
                    'field'   => 'source_local',
                ];
            }
        }

        return null;
    }

    /**
     * Lấy Domain và kiểm tra ownership theo client user.
     *
     * @param  int $domainId
     * @param  int $userId    WHMCS client ID
     * @return Domain|null
     */
    private function getDomainForUser(int $domainId, int $userId): ?Domain
    {
        return Domain::where('id', $domainId)
            ->where('whmcs_user_id', $userId)
            ->where('status', 'active')
            ->first();
    }
}
