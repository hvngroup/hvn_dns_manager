<?php

namespace HvnGroup\DnsManager\Services;

use HvnGroup\DnsManager\Models\Domain;
use HvnGroup\DnsManager\Models\Dnssec;
use HvnGroup\DnsManager\Services\QueueManager;

class DnssecService
{
    // ─────────────────────────────────────────────────────────
    // Lấy trạng thái DNSSEC hiện tại của domain
    // ─────────────────────────────────────────────────────────

    public function getStatus(int $domainId, int $userId): array
    {
        $domain = Domain::where('id', $domainId)
            ->where('whmcs_user_id', $userId)
            ->first();

        if (!$domain) {
            return array('success' => false, 'error' => 'Domain không tồn tại.');
        }

        $dnssec = Dnssec::where('domain_id', $domainId)->first();

        return array(
            'success'     => true,
            'is_enabled'  => $dnssec ? (bool) $dnssec->is_enabled : false,
            'key_tag'     => $dnssec ? $dnssec->key_tag : null,
            'algorithm'   => $dnssec ? $dnssec->algorithm : null,
            'digest_type' => $dnssec ? $dnssec->digest_type : null,
            'digest'      => $dnssec ? $dnssec->digest : null,
            'ds_record'   => $dnssec ? $dnssec->ds_record_raw : null,
            'last_signed' => $dnssec && $dnssec->last_signed_at
                ? date('d/m/Y H:i', strtotime((string) $dnssec->last_signed_at))
                : null,
        );
    }

    // ─────────────────────────────────────────────────────────
    // Bật hoặc tắt DNSSEC — dispatch job vào queue
    // ─────────────────────────────────────────────────────────

    public function toggle(int $domainId, int $userId, bool $enable): array
    {
        // Kiểm tra admin có bật tính năng DNSSEC không
        if (!\HvnGroup\DnsManager\Helpers\SettingsHelper::getBool('dnssec_mode', false)) {
            return array('success' => false, 'error' => 'Tính năng DNSSEC chưa được kích hoạt trên hệ thống.');
        }

        $domain = Domain::where('id', $domainId)
            ->where('whmcs_user_id', $userId)
            ->first();

        if (!$domain) {
            return array('success' => false, 'error' => 'Domain không tồn tại.');
        }

        $action = $enable ? 'ENABLE_DNSSEC' : 'DISABLE_DNSSEC';

        $qm = new QueueManager();
        $batchId = $qm->dispatch(
            $domainId,
            $action,
            array('domain' => $domain->domain),
            1,
            'client',
            $userId
        );

        $msg = $enable
            ? 'Yêu cầu bật DNSSEC đã được gửi. Hệ thống sẽ xử lý trong vài phút.'
            : 'Yêu cầu tắt DNSSEC đã được gửi. Hãy đảm bảo đã xóa DS Record tại Registrar trước.';

        return array(
            'success'  => true,
            'message'  => $msg,
            'batch_id' => $batchId,
        );
    }   
}