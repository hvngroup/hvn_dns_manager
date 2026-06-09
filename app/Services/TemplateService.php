<?php

namespace HvnGroup\DnsManager\Services;

use HvnGroup\DnsManager\Models\Domain;
use HvnGroup\DnsManager\Models\Record;
use HvnGroup\DnsManager\Models\Template;
use HvnGroup\DnsManager\Helpers\AuditLogger;
use HvnGroup\DnsManager\Security\InputSanitizer;
use HvnGroup\DnsManager\Validators\DnsRecordValidator;
use Illuminate\Database\Capsule\Manager as Capsule;

/**
 * TemplateService — Xử lý áp dụng DNS Template cho client.
 *
 * Logic chính của applyTemplate():
 *   1. Kiểm tra domain thuộc user và đang active
 *   2. Kiểm tra template tồn tại và được phép hiển thị cho client
 *   3. Xóa toàn bộ record hiện tại (trừ is_locked)
 *   4. Insert records từ template (thay thế placeholder {{domain}}, {{ip}}, ...)
 *   5. Đẩy job APPLY_TEMPLATE vào queue kèm theo toàn bộ records mới
 *      để QueueWorker sync lên DirectAdmin
 *   6. Trả về danh sách records mới
 */
class TemplateService
{
    /** @var QueueManager */
    private $queue;

    public function __construct()
    {
        $this->queue = new QueueManager();
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Entry point từ ajax.php
    // ─────────────────────────────────────────────────────────────────────────
    public function applyTemplate(array $input, $userId)
    {
        $domainId   = (int) ($input['domain_id']   ?? 0);
        $templateId = (int) ($input['template_id'] ?? 0);

        if ($domainId <= 0 || $templateId <= 0) {
            return $this->error('VALIDATION_ERROR', 'Thiếu domain_id hoặc template_id.');
        }

        // 1. Kiểm tra domain
        $domain = Domain::where('id', $domainId)
            ->where('whmcs_user_id', $userId)
            ->first();

        if (!$domain) {
            return $this->error('NOT_FOUND', 'Domain không tồn tại hoặc bạn không có quyền truy cập.');
        }
        if ($domain->status !== 'active') {
            return $this->error('DOMAIN_NOT_ACTIVE', 'Domain không ở trạng thái Active.');
        }

        // 2. Kiểm tra template
        $template = Template::find($templateId);
        if (!$template) {
            return $this->error('NOT_FOUND', 'Template không tồn tại.');
        }
        if (!$template->is_visible_client) {
            return $this->error('NOT_ALLOWED', 'Template này không được phép sử dụng.');
        }

        $recordsData = is_array($template->records_data) ? $template->records_data : array();
        if (empty($recordsData)) {
            return $this->error('EMPTY_TEMPLATE', 'Template này không có bản ghi nào.');
        }

        // 3. Lấy IP mặc định từ server primary để thay placeholder {{ip}}
        $defaultIp = $this->resolveDefaultIp();

        // 4. Chuẩn bị records mới (thay placeholder)
        $newRecordsData = array();
        foreach ($recordsData as $rec) {
            $type  = strtoupper(trim($rec['type'] ?? ''));
            $name  = $this->replacePlaceholders(trim($rec['name']  ?? ''), $domain->domain, $defaultIp);
            $value = $this->replacePlaceholders(trim($rec['value'] ?? ''), $domain->domain, $defaultIp);
            $ttl   = isset($rec['ttl'])      ? (int) $rec['ttl']      : 3600;
            $prio  = (isset($rec['priority']) && $rec['priority'] !== null)
                     ? (int) $rec['priority'] : null;

            if (!in_array($type, DnsRecordValidator::ALLOWED_TYPES)) {
                continue;
            }
            if ($name === '' || $value === '') {
                continue;
            }

            $newRecordsData[] = array(
                'domain_id'      => $domainId,
                'type'           => $type,
                'name'           => $name,
                'value'          => $value,
                'ttl'            => $ttl,
                'priority'       => $prio,
                'weight'         => null,
                'port'           => null,
                'is_system'      => in_array($type, array('NS', 'SOA')) ? 1 : 0,
                'is_locked'      => 0,
                'pending_delete' => 0,
                'created_at'     => date('Y-m-d H:i:s'),
                'updated_at'     => date('Y-m-d H:i:s'),
            );
        }

        // Bỏ qua records NS/SOA từ template — DA vẫn giữ chúng,
        // và pullZoneRecords() sau khi job complete sẽ sync về từ DA
        $newRecordsData = array_filter($newRecordsData, function ($r) {
            return !in_array($r['type'], array('NS', 'SOA'));
        });
        $newRecordsData = array_values($newRecordsData);

        if (empty($newRecordsData)) {
            return $this->error('EMPTY_TEMPLATE', 'Không có bản ghi hợp lệ nào trong template sau khi xử lý.');
        }

        try {
            Capsule::beginTransaction();

            // 5. Xóa toàn bộ record hiện tại (trừ is_locked và trừ NS/SOA)
            // NS và SOA không bao giờ được DA xóa → giữ lại trong WHMCS DB
            Record::where('domain_id', $domainId)
                ->where('is_locked', 0)
                ->whereNotIn('type', ['NS', 'SOA'])
                ->delete();

            // 6. Insert records mới từ template vào DB
            $insertData = array_map(function ($r) {
                $row = $r;
                unset($row['sync_status']);
                return $row;
            }, $newRecordsData);

            Record::insert($insertData);

            // 7. Lấy record_id vừa insert để đưa vào payload cho QueueWorker
            // QueueWorker cần records kèm id để có thể add lên DA đúng cách
            $insertedRecords = Record::where('domain_id', $domainId)
                ->where('is_locked', 0)
                ->get()
                ->map(function ($r) {
                    return array(
                        'record_id' => $r->id,
                        'type'      => $r->type,
                        'name'      => $r->name,
                        'value'     => $r->value,
                        'ttl'       => $r->ttl ?? 3600,
                        'priority'  => $r->priority,
                        'weight'    => $r->weight,
                        'port'      => $r->port,
                    );
                })
                ->values()
                ->toArray();

            // 8. Dispatch job APPLY_TEMPLATE vào queue với đầy đủ records
            // QueueWorker sẽ: xóa sạch zone DA → add lại từng record
            $batchId = $this->queue->dispatch(
                $domainId,
                'APPLY_TEMPLATE',
                array(
                    'template_id'   => $templateId,
                    'template_name' => $template->name,
                    'records'       => $insertedRecords,
                ),
                3,        // priority cao hơn client thường (5) vì là bulk
                'client',
                $userId
            );

            Capsule::commit();

            // 9. Audit log
            AuditLogger::recordAdded(
                $domainId,
                $domain->domain,
                0,
                array(
                    'action'        => 'apply_template',
                    'template_id'   => $templateId,
                    'template_name' => $template->name,
                    'records_count' => count($insertedRecords),
                ),
                'client',
                $userId,
                AuditLogger::resolveActorName('client', $userId)
            );

            // 10. Format records để trả về cho JS
            $freshRecords = array_map(function ($r) {
                return array(
                    'id'             => $r['record_id'],
                    'type'           => $r['type'],
                    'name'           => $r['name'],
                    'value'          => $r['value'],
                    'ttl'            => $r['ttl'],
                    'priority'       => $r['priority'],
                    'weight'         => $r['weight'],
                    'port'           => $r['port'],
                    'is_system'      => in_array($r['type'], array('NS', 'SOA')),
                    'is_locked'      => false,
                    'pending_delete' => false,
                    'sync_status'    => 'syncing',
                );
            }, $insertedRecords);

            return array(
                'success' => true,
                'data'    => array(
                    'records'       => $freshRecords,
                    'batch_id'      => $batchId,
                    'template_name' => $template->name,
                ),
                'message' => "Đã áp dụng template '{$template->name}'. " . count($freshRecords) . " bản ghi đang được đồng bộ lên máy chủ.",
            );

        } catch (\Throwable $e) {
            if (Capsule::connection()->transactionLevel() > 0) {
                Capsule::rollBack();
            }
            return $this->error('SERVER_ERROR', $e->getMessage());
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Lấy danh sách templates hiển thị cho client
    // ─────────────────────────────────────────────────────────────────────────
    public function getClientTemplates()
    {
        return Template::where('is_visible_client', true)
            ->orderBy('is_default', 'desc')
            ->orderBy('name')
            ->get()
            ->map(function ($t) {
                $records = is_array($t->records_data) ? $t->records_data : array();
                return array(
                    'id'            => $t->id,
                    'name'          => $t->name,
                    'description'   => $t->description,
                    'records_count' => count($records),
                    'is_system'     => ($t->created_by_user_id === null),
                    'records'       => $records,
                );
            })
            ->values()
            ->toArray();
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Helpers
    // ─────────────────────────────────────────────────────────────────────────

    private function replacePlaceholders($str, $domainName, $defaultIp)
    {
        $ns1 = \HvnGroup\DnsManager\Helpers\SettingsHelper::get('default_nameserver_1', '');
        $ns2 = \HvnGroup\DnsManager\Helpers\SettingsHelper::get('default_nameserver_2', '');
        $ns3 = \HvnGroup\DnsManager\Helpers\SettingsHelper::get('default_nameserver_3', '');

        $replacements = array(
            '{{domain}}' => $domainName,
            '{{ip}}'     => $defaultIp,
            '{{ns1}}'    => $ns1,
            '{{ns2}}'    => $ns2,
            '{{ns3}}'    => $ns3,
        );

        return str_replace(array_keys($replacements), array_values($replacements), $str);
    }

    private function resolveDefaultIp()
    {
        try {
            $server = \HvnGroup\DnsManager\Models\Server::where('role', 'primary')
                ->where('is_active', 1)
                ->first();
            if ($server && !empty($server->ip)) {
                return $server->ip;
            }
        } catch (\Throwable $e) {
            // Không crash nếu không tìm được
        }
        return '';
    }

    private function error($code, $message)
    {
        return array('success' => false, 'error' => array('code' => $code, 'message' => $message));
    }
}