<?php

namespace HvnGroup\DnsManager\Controllers\Client;

use WHMCS\Database\Capsule;
use HvnGroup\DnsManager\Models\Domain;

/**
 * Controller mock phục vụ cho Prototype UI Phase 0C.
 * Sẽ được refactor thành controller thật trong Phase 1.
 */
class ClientController
{
    /**
     * Entry point của Client Area (clientarea.php)
     */
    public function dispatch($action, $params)
    {
        if ($action === 'record_edit') {
            return $this->showRecordEdit($params);
        }

        $domainId = isset($_REQUEST['domain_id']) ? (int)$_REQUEST['domain_id'] : 0;

        if ($domainId > 0) {
            return $this->showDnsEditor($params, $domainId);
        }

        return $this->showDomainList($params);
    }

    /**
     * Màn hình record edit riêng rẽ
     */
    private function showRecordEdit($params)
    {
        $serviceId = $params['serviceid'];
        $domainId = isset($_REQUEST['domain_id']) ? (int)$_REQUEST['domain_id'] : 1;
        $recordId = isset($_REQUEST['record_id']) ? (int)$_REQUEST['record_id'] : 0;
        
        $domainInfo = ['id' => $domainId, 'domain' => 'example.com'];
        $recordJson = 'null';
        
        if ($recordId > 0) {
            // Mock editing existing record
            $mockRecord = [
                'id' => $recordId, 'type' => 'A', 'name' => '@', 'value' => '103.45.67.89', 
                'ttl' => 3600, 'priority' => 10, 'weight' => 0, 'port' => 443
            ];
            $recordJson = json_encode($mockRecord);
        }

        return [
            'pagetitle' => ($recordId ? 'Sửa' : 'Thêm') . ' Bản ghi DNS',
            'breadcrumb' => [
                'clientarea.php?action=productdetails&id=' . $serviceId => 'Dịch vụ',
                'clientarea.php?action=productdetails&id=' . $serviceId . '&modop=custom&a=dns_manager&domain_id=' . $domainId => 'DNS Editor',
                '#' => 'Bản ghi',
            ],
            'templatefile' => 'templates/client/record_edit',
            'requirelogin' => true,
            'vars' => [
                'domain' => $domainInfo,
                'recordJson' => $recordJson,
            ]
        ];
    }

    /**
     * Màn hình CL-01: Danh sách Domain
     */
    private function showDomainList($params)
    {
        $serviceId = $params['serviceid'];
        
        // Mock data cho danh sách domains (Lấy từ DB nếu đã có mock_seeder)
        $domains = [];
        if (Capsule::schema()->hasTable('mod_hvndns_domains')) {
            $domains = Domain::where('service_id', $serviceId)->get()->toArray();
        }

        // Mock data phòng trường hợp bảng rỗng
        if (empty($domains)) {
            $domains = [
                ['id' => 1, 'domain' => 'mock-example.com', 'status' => 'active', 'sync_status' => 'complete', 'records_count' => 12],
                ['id' => 2, 'domain' => 'mock-shop.vn', 'status' => 'active', 'sync_status' => 'syncing', 'records_count' => 5],
            ];
        }

        return [
            'pagetitle' => 'Quản lý DNS',
            'breadcrumb' => [
                'clientarea.php?action=productdetails&id=' . $serviceId => 'Dịch vụ',
                '#' => 'DNS',
            ],
            'templatefile' => 'templates/client/domain_list',
            'requirelogin' => true,
            'vars' => [
                'plan_name' => 'DNS Premium (Mock)',
                'service_status' => 'Active',
                'expiry_date' => '31/12/2026',
                'domains' => $domains,
                'default_ns1' => 'dns1.hvn.vn',
                'default_ns2' => 'dns2.hvn.vn',
                'default_ns3' => 'dns3.hvn.vn',
            ]
        ];
    }

    /**
     * Màn hình CL-02: DNS Editor
     */
    private function showDnsEditor($params, $domainId)
    {
        $serviceId = $params['serviceid'];
        
        // Mock data cho giao diện
        $domainInfo = [
            'id' => $domainId,
            'domain' => 'example.com',
            'status' => 'active',
            'dnssec_enabled' => true,
            'ssl_status' => 'active',
            'records_count' => 15,
            'redirects_count' => 3,
            'email_fwds_count' => 2,
            'has_dnssec_addon' => true,
            'has_ddns_addon' => false,
            'dnssec' => ['last_signed' => '25/02/2026 14:30']
        ];
        
        $quota = [
            'max_records' => 50,
            'dnssec_enabled' => true,
            'ddns_enabled' => true,
            'dnssec_mode' => 'paid',
            'ddns_mode' => 'paid',
            'max_ddns_tokens' => 5
        ];

        // Dữ liệu mock records cho Alpine JS
        $records = [
            [
                'id' => 1, 'type' => 'A', 'name' => '@', 'value' => '103.45.67.89', 
                'ttl' => 3600, 'priority' => 0, 'weight' => 0, 'port' => 0,
                'is_system' => false, 'is_locked' => false, 'sync_status' => 'complete', 'pending_delete' => false
            ],
            [
                'id' => 2, 'type' => 'CNAME', 'name' => 'www', 'value' => 'example.com.', 
                'ttl' => 3600, 'priority' => 0, 'weight' => 0, 'port' => 0,
                'is_system' => false, 'is_locked' => false, 'sync_status' => 'syncing', 'pending_delete' => false
            ],
            [
                'id' => 3, 'type' => 'MX', 'name' => '@', 'value' => 'mail.example.com.', 
                'ttl' => 3600, 'priority' => 10, 'weight' => 0, 'port' => 0,
                'is_system' => false, 'is_locked' => false, 'sync_status' => 'complete', 'pending_delete' => false
            ],
            [
                'id' => 4, 'type' => 'NS', 'name' => '@', 'value' => 'dns1.hvn.vn.', 
                'ttl' => 86400, 'priority' => 0, 'weight' => 0, 'port' => 0,
                'is_system' => true, 'is_locked' => true, 'sync_status' => 'complete', 'pending_delete' => false
            ],
            [
                'id' => 5, 'type' => 'TXT', 'name' => '_dmarc', 'value' => 'v=DMARC1; p=none;', 
                'ttl' => 3600, 'priority' => 0, 'weight' => 0, 'port' => 0,
                'is_system' => false, 'is_locked' => false, 'sync_status' => 'failed', 'pending_delete' => false
            ]
        ];

        $templates = [
            ['id' => 1, 'name' => 'Basic DNS', 'description' => 'A + MX Google', 'records_count' => 6, 'is_system' => true],
            ['id' => 2, 'name' => 'Custom Shop', 'description' => 'Mẫu cho shop bán hàng', 'records_count' => 8, 'is_system' => false],
        ];

        return [
            'pagetitle' => 'Quản lý DNS - ' . $domainInfo['domain'],
            'breadcrumb' => [
                'clientarea.php?action=productdetails&id=' . $serviceId => 'Dịch vụ',
                'clientarea.php?action=productdetails&id=' . $serviceId . '#' => 'DNS',
                '#' => $domainInfo['domain'],
            ],
            'templatefile' => 'templates/client/dns_editor',
            'requirelogin' => true,
            'vars' => [
                'domain' => $domainInfo,
                'quota' => $quota,
                'recordsJson' => json_encode($records),
                'templates' => $templates,
            ]
        ];
    }
}
