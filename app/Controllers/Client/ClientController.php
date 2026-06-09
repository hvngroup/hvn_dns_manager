<?php

namespace HvnGroup\DnsManager\Controllers\Client;

use WHMCS\Database\Capsule;
use HvnGroup\DnsManager\Models\Domain;
use HvnGroup\DnsManager\Services\TemplateService;

/**
 * ClientController — Entry point cho Client Area của HVN DNS Manager.
 */
class ClientController
{
    /**
     * Entry point của Client Area (clientarea.php)
     */
    public function dispatch($action, $params)
    {
        $userId = isset($_SESSION['uid']) ? (int) $_SESSION['uid'] : 0;

        if ($action === 'record_edit') {
            return $this->showRecordEdit($params);
        }

        $domainId = isset($_REQUEST['domain_id']) ? (int) $_REQUEST['domain_id'] : 0;

        if ($domainId > 0) {
            return $this->showDnsEditor($params, $domainId, $userId);
        }

        return $this->showDomainList($params, $userId);
    }

    /**
     * Build base URL for module links
     */
    private function getModuleLink($params)
    {
        return isset($params['modulelink']) ? $params['modulelink'] : 'index.php?m=hvn_dns_manager';
    }

    /**
     * Màn hình record edit riêng rẽ
     */
    private function showRecordEdit($params)
    {
        $moduleLink = $this->getModuleLink($params);
        $domainId   = isset($_REQUEST['domain_id']) ? (int) $_REQUEST['domain_id'] : 1;
        $recordId   = isset($_REQUEST['record_id']) ? (int) $_REQUEST['record_id'] : 0;

        $domainInfo = array('id' => $domainId, 'domain' => 'example.com');
        $recordJson = 'null';

        if ($recordId > 0) {
            $mockRecord = array(
                'id'       => $recordId,
                'type'     => 'A',
                'name'     => '@',
                'value'    => '103.45.67.89',
                'ttl'      => 3600,
                'priority' => 10,
                'weight'   => 0,
                'port'     => 443,
            );
            $recordJson = json_encode($mockRecord);
        }

        return array(
            'pagetitle'    => ($recordId ? 'Sửa' : 'Thêm') . ' Bản ghi DNS',
            'breadcrumb'   => array(
                'index.php?m=hvn_dns_manager' => 'Domain Manager',
                '#'                           => 'Bản ghi',
            ),
            'templatefile' => 'templates/client/record_edit',
            'requirelogin' => true,
            'vars'         => array(
                'modulelink' => $moduleLink,
                'domain'     => $domainInfo,
                'recordJson' => $recordJson,
            ),
        );
    }

    /**
     * Màn hình CL-01: Danh sách Domain
     */
    private function showDomainList($params, $userId = 0)
    {
        $moduleLink    = $this->getModuleLink($params);
        $whmcsDomainId = isset($params['domainid']) ? $params['domainid'] : 0;

        $domains = array();
        if (Capsule::schema()->hasTable('mod_hvndns_domains')) {
            $query = Domain::query();
            if ($userId > 0) {
                $query->where('whmcs_user_id', $userId);
            } elseif ($whmcsDomainId > 0) {
                $query->where('whmcs_domain_id', $whmcsDomainId);
            }
            $domains = $query->get()->toArray();
        }

        // Lấy nameservers từ Primary server
        $ns = array();
        if (Capsule::schema()->hasTable('mod_hvndns_servers')) {
            $primaryServer = \HvnGroup\DnsManager\Models\Server::where('role', 'primary')
                ->where('is_active', 1)->first();
            if ($primaryServer && is_array($primaryServer->nameservers) && count($primaryServer->nameservers) > 0) {
                $ns = $primaryServer->nameservers;
            } else {
                $firstServer = \HvnGroup\DnsManager\Models\Server::where('is_active', 1)->first();
                if ($firstServer && is_array($firstServer->nameservers) && count($firstServer->nameservers) > 0) {
                    $ns = $firstServer->nameservers;
                }
            }
        }

        if (empty($ns)) {
            $ns = array(
                \HvnGroup\DnsManager\Helpers\SettingsHelper::get('default_nameserver_1', ''),
                \HvnGroup\DnsManager\Helpers\SettingsHelper::get('default_nameserver_2', ''),
                \HvnGroup\DnsManager\Helpers\SettingsHelper::get('default_nameserver_3', ''),
                \HvnGroup\DnsManager\Helpers\SettingsHelper::get('default_nameserver_4', ''),
                \HvnGroup\DnsManager\Helpers\SettingsHelper::get('default_nameserver_5', ''),
            );
            $ns = array_values(array_filter($ns));
        }

        return array(
            'pagetitle'    => 'Quản lý DNS',
            'breadcrumb'   => array(
                'index.php?m=hvn_dns_manager' => 'Domain Manager',
                '#'                           => 'Danh sách',
            ),
            'templatefile' => 'templates/client/domain_list',
            'requirelogin' => true,
            'vars'         => array(
                'modulelink'  => $moduleLink,
                'plan_name'   => 'DNS Standard',
                'service_status' => 'Active',
                'expiry_date' => '27/02/2027',
                'domains'     => $domains,
                'default_ns1' => isset($ns[0]) ? $ns[0] : '',
                'default_ns2' => isset($ns[1]) ? $ns[1] : '',
                'default_ns3' => isset($ns[2]) ? $ns[2] : '',
                'default_ns4' => isset($ns[3]) ? $ns[3] : '',
                'default_ns5' => isset($ns[4]) ? $ns[4] : '',
            ),
        );
    }

    /**
     * Màn hình CL-02: DNS Editor
     */
    private function showDnsEditor($params, $domainId, $userId = 0)
    {
        $moduleLink = $this->getModuleLink($params);

        $domainParams = Domain::where('id', $domainId)->first();
        if (!$domainParams) {
            die('Domain không tồn tại.');
        }

        $domainInfo = array(
            'id'              => $domainId,
            'domain'          => $domainParams->domain,
            'status'          => $domainParams->status,
            'dnssec_enabled'  => false,
            'ssl_status'      => 'active',
            'records_count'   => 0,
            'redirects_count' => 0,
            'email_fwds_count' => 0,
            'has_dnssec_addon' => true,
            'has_ddns_addon'   => true,
            'dnssec'           => array(),
        );

        $quota = array(
            'max_records'        => \HvnGroup\DnsManager\Helpers\SettingsHelper::getInt('total_record_limit', 50),
            'dnssec_enabled'     => \HvnGroup\DnsManager\Helpers\SettingsHelper::isModeEnabled('dnssec_mode'),
            'ddns_enabled'       => \HvnGroup\DnsManager\Helpers\SettingsHelper::isModeEnabled('ddns_mode'),
            'templates_enabled'  => \HvnGroup\DnsManager\Helpers\SettingsHelper::getBool('enable_dns_templates', true),
            'redirects_enabled'  => \HvnGroup\DnsManager\Helpers\SettingsHelper::getBool('enable_url_redirect', true),
            'email_enabled'      => \HvnGroup\DnsManager\Helpers\SettingsHelper::getBool('enable_email_forwarder', true),
            'max_redirects'      => \HvnGroup\DnsManager\Helpers\SettingsHelper::getInt('url_redirect_limit', 5),
            'max_email_forwards' => \HvnGroup\DnsManager\Helpers\SettingsHelper::getInt('email_forwarder_limit', 5),
            'max_ddns_tokens'    => \HvnGroup\DnsManager\Helpers\SettingsHelper::getInt('ddns_token_limit', 5),
        );

        // Records
        $dbRecords = \HvnGroup\DnsManager\Models\Record::where('domain_id', $domainId)
            ->orderBy('type')
            ->orderBy('name')
            ->get();
        $records = $dbRecords->toArray();
        $domainInfo['records_count'] = count($records);

        // Redirects
        $dbRedirects = \HvnGroup\DnsManager\Models\Redirect::where('domain_id', $domainId)
            ->orderBy('created_at', 'desc')
            ->get();
        $redirects = array();
        foreach ($dbRedirects as $r) {
            $redirects[] = array(
                'id'              => $r->id,
                'source_path'     => $r->source_path,
                'destination_url' => $r->destination_url,
                'type'            => $r->type,
                'sync_status'     => 'complete',
            );
        }
        $domainInfo['redirects_count'] = count($redirects);

        // ── Email Forwards ───────────────────────────────────────────────────────
        // KHÔNG bọc trong if email_enabled — phải luôn load để truyền vào JS
        $emails = array();
        try {
            $dbEmails = \HvnGroup\DnsManager\Models\EmailForward::where('domain_id', $domainId)
                ->orderBy('is_catchall', 'desc')
                ->orderBy('source_local', 'asc')
                ->get();

            foreach ($dbEmails as $fwd) {
                $emails[] = array(
                    'id'                => $fwd->id,
                    'source_local'      => $fwd->source_local,
                    'source_email'      => $fwd->is_catchall
                        ? '*@' . $domainParams->domain
                        : $fwd->source_local . '@' . $domainParams->domain,
                    'destination_email' => $fwd->destination_email,
                    'is_catchall'       => (bool) $fwd->is_catchall,
                    'sync_status'       => $fwd->synced_at ? 'synced' : 'pending',
                    'pending_delete'    => false,
                );
            }
        } catch (\Throwable $e) {
            $emails = array();
            logActivity('HVN DNS Manager [ClientController]: Email load error — ' . $e->getMessage());
        }
        $domainInfo['email_fwds_count'] = count($emails);

        // DDNS tokens
        $ddnsTokens = array();
        if ($quota['ddns_enabled']) {
            $rawTokens = \HvnGroup\DnsManager\Models\DdnsToken::where('domain_id', $domainId)
                ->orderBy('created_at', 'desc')
                ->get();

            foreach ($rawTokens as $t) {
                $ddnsTokens[] = array(
                    'id'          => $t->id,
                    'subdomain'   => $t->subdomain,
                    'label'       => $t->label ? $t->label : $t->subdomain,
                    'ip'          => $t->last_ip ? $t->last_ip : 'Chưa cập nhật',
                    'updated'     => $t->last_update_at
                        ? date('d/m/Y H:i', strtotime((string) $t->last_update_at))
                        : 'Chưa có',
                    'requests'    => (int) $t->request_count,
                    'active'      => (bool) $t->is_active,
                    'showDetail'  => false,
                    'token_url'   => '',
                    'domain_name' => $domainParams->domain,
                );
            }
        }

        // ── Templates: load từ DB thật qua TemplateService ──────────────────
        $templates = array();
        if ($quota['templates_enabled']) {
            try {
                $templateService = new TemplateService();
                $templates = $templateService->getClientTemplates();
            } catch (\Throwable $e) {
                // Không crash nếu bảng chưa tồn tại, fallback về mảng rỗng
                $templates = array();
            }
        }

        return array(
            'pagetitle'    => 'Quản lý DNS - ' . $domainInfo['domain'],
            'breadcrumb'   => array(
                'index.php?m=hvn_dns_manager' => 'Domain Manager',
                '#'                           => $domainInfo['domain'],
            ),
            'templatefile' => 'templates/client/dns_editor',
            'requirelogin' => true,
            'vars'         => array(
                'modulelink'    => $moduleLink,
                'module_dir'    => realpath(__DIR__ . '/../../../') . '/',
                'domain'        => $domainInfo,
                'quota'         => $quota,
                'recordsJson'   => json_encode($records),
                'redirectsJson' => json_encode($redirects),
                'ddnsJson'      => json_encode($ddnsTokens),
                'templates'     => $templates,
                'csrf_token'    => isset($_SESSION['tkval']) ? $_SESSION['tkval'] : '',
                'emailsJson'    => json_encode($emails),
            ),
        );
    }
}
