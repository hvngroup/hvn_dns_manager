<?php

namespace MJ\DnsManager\Controllers\Admin;

use MJ\DnsManager\Models\Template;
use Illuminate\Database\Capsule\Manager as Capsule;

/**
 * TemplateController — Admin CRUD cho DNS Templates.
 * Gọi từ ajax.php qua action = 'admin_template'.
 */
class TemplateController
{
    public function dispatch($method, array $input)
    {
        switch ($method) {
            case 'list':
                return $this->listTemplates();
            case 'save':
                return $this->saveTemplate($input);
            case 'delete':
                return $this->deleteTemplate($input);
            case 'set_default':
                return $this->setDefault($input);
            case 'clone':
                return $this->cloneTemplate($input);
            default:
                return $this->error('INVALID_METHOD', 'Method không hợp lệ: ' . $method);
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Lấy danh sách tất cả templates (kể cả ẩn)
    // ─────────────────────────────────────────────────────────────────────────
    private function listTemplates()
    {
        $templates = Template::orderBy('is_default', 'desc')
            ->orderBy('name')
            ->get()
            ->map(function ($t) {
                return $this->formatTemplate($t);
            })
            ->values()
            ->toArray();

        return ['success' => true, 'data' => ['templates' => $templates]];
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Tạo mới hoặc cập nhật template
    // ─────────────────────────────────────────────────────────────────────────
    private function saveTemplate(array $input)
    {
        $id          = isset($input['id']) ? (int) $input['id'] : 0;
        $name        = trim($input['name'] ?? '');
        $description = trim($input['description'] ?? '');
        $isVisible   = !empty($input['is_visible_client']) ? 1 : 0;
        $records     = isset($input['records']) && is_array($input['records'])
                        ? $input['records']
                        : [];

        if ($name === '') {
            return $this->error('VALIDATION_ERROR', 'Tên template không được để trống.');
        }

        // Validate từng record trong template
        $allowedTypes = ['A', 'AAAA', 'CNAME', 'MX', 'TXT', 'NS', 'SRV', 'CAA'];
        $cleanedRecords = [];
        foreach ($records as $idx => $rec) {
            $type = strtoupper(trim($rec['type'] ?? ''));
            if (!in_array($type, $allowedTypes)) {
                return $this->error('VALIDATION_ERROR', "Record #" . ($idx + 1) . ": loại '{$type}' không hợp lệ.");
            }
            $recName = trim($rec['name'] ?? '');
            $recValue = trim($rec['value'] ?? '');
            if ($recName === '' || $recValue === '') {
                return $this->error('VALIDATION_ERROR', "Record #" . ($idx + 1) . ": tên và giá trị không được để trống.");
            }
            $cleanedRecords[] = [
                'type'     => $type,
                'name'     => $recName,
                'value'    => $recValue,
                'ttl'      => isset($rec['ttl']) ? (int) $rec['ttl'] : 3600,
                'priority' => isset($rec['priority']) && $rec['priority'] !== '' ? (int) $rec['priority'] : null,
            ];
        }

        try {
            if ($id > 0) {
                // Cập nhật
                $template = Template::find($id);
                if (!$template) {
                    return $this->error('NOT_FOUND', 'Template không tồn tại.');
                }
                $template->update([
                    'name'               => $name,
                    'description'        => $description,
                    'is_visible_client'  => $isVisible,
                    'records_data'       => $cleanedRecords,
                ]);
            } else {
                // Tạo mới
                $template = Template::create([
                    'name'               => $name,
                    'description'        => $description,
                    'is_default'         => 0,
                    'is_visible_client'  => $isVisible,
                    'records_data'       => $cleanedRecords,
                    'created_by_user_id' => null,
                ]);
            }

            return [
                'success' => true,
                'data'    => ['template' => $this->formatTemplate($template)],
                'message' => $id > 0 ? 'Template đã được cập nhật.' : 'Template đã được tạo thành công.',
            ];
        } catch (\Throwable $e) {
            return $this->error('SERVER_ERROR', $e->getMessage());
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Xóa template (không được xóa default)
    // ─────────────────────────────────────────────────────────────────────────
    private function deleteTemplate(array $input)
    {
        $id = (int) ($input['id'] ?? 0);
        if ($id <= 0) {
            return $this->error('VALIDATION_ERROR', 'ID template không hợp lệ.');
        }

        $template = Template::find($id);
        if (!$template) {
            return $this->error('NOT_FOUND', 'Template không tồn tại.');
        }
        if ($template->is_default) {
            return $this->error('NOT_ALLOWED', 'Không thể xóa template đang là mặc định. Hãy đặt template khác làm mặc định trước.');
        }

        $template->delete();

        return ['success' => true, 'message' => 'Template đã được xóa.'];
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Đặt template làm mặc định
    // ─────────────────────────────────────────────────────────────────────────
    private function setDefault(array $input)
    {
        $id = (int) ($input['id'] ?? 0);
        if ($id <= 0) {
            return $this->error('VALIDATION_ERROR', 'ID template không hợp lệ.');
        }

        $template = Template::find($id);
        if (!$template) {
            return $this->error('NOT_FOUND', 'Template không tồn tại.');
        }

        try {
            Capsule::beginTransaction();
            // Bỏ default của tất cả
            Template::query()->update(['is_default' => 0]);
            // Set default cho cái được chọn
            $template->update(['is_default' => 1]);
            Capsule::commit();

            return ['success' => true, 'message' => "Template '{$template->name}' đã được đặt làm mặc định."];
        } catch (\Throwable $e) {
            Capsule::rollBack();
            return $this->error('SERVER_ERROR', $e->getMessage());
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Nhân bản template
    // ─────────────────────────────────────────────────────────────────────────
    private function cloneTemplate(array $input)
    {
        $id = (int) ($input['id'] ?? 0);
        if ($id <= 0) {
            return $this->error('VALIDATION_ERROR', 'ID template không hợp lệ.');
        }

        $source = Template::find($id);
        if (!$source) {
            return $this->error('NOT_FOUND', 'Template nguồn không tồn tại.');
        }

        try {
            $clone = Template::create([
                'name'               => $source->name . ' (Copy)',
                'description'        => $source->description,
                'is_default'         => 0,
                'is_visible_client'  => $source->is_visible_client,
                'records_data'       => $source->records_data,
                'created_by_user_id' => null,
            ]);

            return [
                'success' => true,
                'data'    => ['template' => $this->formatTemplate($clone)],
                'message' => "Đã nhân bản thành '{$clone->name}'.",
            ];
        } catch (\Throwable $e) {
            return $this->error('SERVER_ERROR', $e->getMessage());
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Format output
    // ─────────────────────────────────────────────────────────────────────────
    private function formatTemplate(Template $t)
    {
        $records = is_array($t->records_data) ? $t->records_data : [];
        return [
            'id'            => $t->id,
            'name'          => $t->name,
            'description'   => $t->description,
            'is_default'    => (bool) $t->is_default,
            'is_visible'    => (bool) $t->is_visible_client,
            'records_count' => count($records),
            'records'       => $records,
            'created_at'    => $t->created_at ? $t->created_at->format('d/m/Y H:i') : '',
        ];
    }

    private function error($code, $message)
    {
        return ['success' => false, 'error' => ['code' => $code, 'message' => $message]];
    }
}