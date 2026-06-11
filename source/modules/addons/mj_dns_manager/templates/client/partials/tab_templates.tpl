{* tab_templates.tpl — Load DNS Template *}

{* ── Card chính ── *}
<div style="border:1px solid #e2e8f0;border-radius:8px;overflow:hidden;margin-bottom:16px;">
    <div style="padding:12px 16px;background:#f8f9fa;border-bottom:1px solid #e2e8f0;">
        <h5 style="margin:0;font-size:15px;font-weight:700;color:#1e293b;">Nạp mẫu DNS (Templates)</h5>
    </div>
    <div style="padding:16px;">
        <p style="font-size:14px;color:#495057;margin:0 0 14px;">Chọn một mẫu DNS dựng sẵn để áp dụng nhanh cho tên miền <strong style="color:#ea4544;" x-text="domainName"></strong>:</p>

        <div>
            <template x-for="(tpl, index) in templates" x-bind:key="tpl.id">
                <div style="border:1px solid #e2e8f0;border-radius:8px;padding:12px 14px;margin-bottom:8px;display:flex;justify-content:space-between;align-items:center;transition:background .15s;"
                     x-bind:style="index === 0 ? 'background:#fafbff;border-color:#cbd5e1;' : 'background:#fff;'">
                    <div style="display:flex;align-items:flex-start;gap:10px;">
                        <input type="radio" name="template_id"
                               x-bind:id="'tpl_' + tpl.id"
                               x-bind:value="tpl.id"
                               x-bind:checked="index === 0"
                               style="width:16px;height:16px;margin:0;flex-shrink:0;margin-top:2px;cursor:pointer;float:none;accent-color:#ea4544;">
                        <label x-bind:for="'tpl_' + tpl.id" style="cursor:pointer;margin:0;">
                            <div style="display:flex;align-items:center;gap:8px;margin-bottom:4px;">
                                <strong style="font-size:14px;color:#1e293b;" x-text="tpl.name"></strong>
                                <span style="padding:2px 8px;border-radius:4px;font-size:11px;font-weight:600;background:#e2e8f0;color:#475569;" x-text="tpl.records_count + ' bản ghi'"></span>
                                <template x-if="tpl.is_system">
                                    <span style="padding:2px 8px;border-radius:4px;font-size:11px;font-weight:600;background:#dbeafe;color:#1d4ed8;"><i class="bi bi-robot"></i> System</span>
                                </template>
                            </div>
                            <div style="font-size:12px;color:#6c757d;" x-text="tpl.description"></div>
                        </label>
                    </div>
                    <button type="button" x-on:click="openTemplatePreview(tpl.id)"
                        style="height:30px;padding:0 12px;display:inline-flex;align-items:center;gap:5px;font-size:12px;font-weight:500;background:#fff;border:1px solid #dee2e6;border-radius:6px;color:#6c757d;cursor:pointer;transition:all .18s;white-space:nowrap;flex-shrink:0;"
                        onmouseover="this.style.borderColor='#adb5bd';this.style.color='#343a40';" onmouseout="this.style.borderColor='#dee2e6';this.style.color='#6c757d';">
                        <i class="bi bi-eye"></i> Xem trước
                    </button>
                </div>
            </template>
            <template x-if="templates.length === 0">
                <div style="padding:24px;text-align:center;font-size:14px;color:#6c757d;background:#fefce8;border:1px solid #fef08a;border-radius:8px;">
                    <i class="bi bi-exclamation-triangle-fill" style="color:#ca8a04;margin-right:6px;"></i>
                    Chưa có mẫu DNS nào được cấu hình trong hệ thống.
                </div>
            </template>
        </div>
    </div>
</div>

{* ── Template Preview Modal ── *}
{literal}
<div x-show="showTemplatePreview" x-cloak
     style="position:fixed;top:0;left:0;width:100%;height:100%;display:flex;justify-content:center;align-items:center;background:rgba(0,0,0,0.5);z-index:1050;">
    <div style="background:#fff;border-radius:10px;box-shadow:0 20px 60px rgba(0,0,0,0.2);width:100%;max-width:700px;max-height:90vh;overflow-y:auto;margin:16px;">

        <div style="padding:14px 18px;background:#1e293b;border-radius:10px 10px 0 0;display:flex;justify-content:space-between;align-items:center;position:sticky;top:0;z-index:1;">
            <h5 style="margin:0;font-size:14px;font-weight:700;color:#fff;"><i class="bi bi-search"></i> Kiểm tra bản ghi trong mẫu</h5>
            <button type="button" x-on:click="closeTemplatePreview()"
                style="width:28px;height:28px;padding:0;border:none;background:rgba(255,255,255,0.15);border-radius:6px;color:#fff;cursor:pointer;display:inline-flex;align-items:center;justify-content:center;font-size:14px;transition:all .18s;"
                onmouseover="this.style.background='rgba(255,255,255,0.25)';" onmouseout="this.style.background='rgba(255,255,255,0.15)';">
                <i class="bi bi-x-lg"></i>
            </button>
        </div>

        <div style="padding:16px 18px;">
            <div style="background:#fef2f2;border:1px solid #fecaca;border-radius:8px;padding:10px 14px;margin-bottom:14px;font-size:14px;color:#991b1b;">
                <strong><i class="bi bi-exclamation-triangle-fill"></i> CẢNH BÁO:</strong>
                Nếu tiếp tục nạp mẫu này, toàn bộ <strong x-text="records.length"></strong> bản ghi DNS hiện tại sẽ bị xóa sạch và thay thế hoàn toàn bởi cấu hình bên dưới.
            </div>

            <div style="overflow-x:auto;">
                <table style="width:100%;border-collapse:collapse;font-size:14px;">
                    <thead>
                        <tr style="background:#f8f9fa;">
                            <th style="padding:8px;font-size:12px;font-weight:600;color:#5E636E;border-bottom:1px solid #dee2e6;white-space:nowrap;">Loại</th>
                            <th style="padding:8px;font-size:12px;font-weight:600;color:#5E636E;border-bottom:1px solid #dee2e6;">Tên bản ghi</th>
                            <th style="padding:8px;font-size:12px;font-weight:600;color:#5E636E;border-bottom:1px solid #dee2e6;">Giá trị</th>
                            <th style="padding:8px;font-size:12px;font-weight:600;color:#5E636E;border-bottom:1px solid #dee2e6;white-space:nowrap;">TTL</th>
                        </tr>
                    </thead>
                    <tbody>
                        <template x-for="rec in previewTemplateRecords" x-bind:key="rec.name + rec.type">
                            <tr style="border-bottom:1px solid #f1f5f9;">
                                <td style="padding:8px;">
                                    <span class="badge" x-bind:class="getTypeBadgeClass(rec.type)" x-text="rec.type"></span>
                                </td>
                                <td style="padding:8px;font-size:14px;font-weight:600;color:#1e293b;" x-text="rec.name"></td>
                                <td style="padding:8px;font-size:14px;color:#495057;max-width:300px;word-break:break-word;" x-text="rec.value"></td>
                                <td style="padding:8px;font-size:14px;color:#6c757d;" x-text="formatTTL(rec.ttl)"></td>
                            </tr>
                        </template>
                        <template x-if="previewTemplateRecords.length === 0">
                            <tr>
                                <td colspan="4" style="text-align:center;padding:24px;color:#6c757d;font-size:14px;">Mẫu này không có dữ liệu bản ghi.</td>
                            </tr>
                        </template>
                    </tbody>
                </table>
            </div>

            <div style="margin-top:14px;padding:12px 14px;background:#f8f9fa;border:1px solid #e2e8f0;border-radius:8px;display:flex;align-items:center;gap:10px;">
                <input type="checkbox" id="confirmTemplatePreview"
                       x-model="$data.confirmPreviewCheck" style="width:16px;height:16px;margin:0;float:none;flex-shrink:0;cursor:pointer;accent-color:#ea4544;">
                <label for="confirmTemplatePreview" style="font-size:14px;font-weight:600;color:#dc2626;cursor:pointer;margin:0;">
                    Tôi hiểu và vẫn muốn áp dụng thay thế toàn bộ bản ghi DNS.
                </label>
            </div>
        </div>

        <div style="padding:12px 18px;border-top:1px solid #e2e8f0;display:flex;justify-content:flex-end;gap:8px;position:sticky;bottom:0;background:#fff;border-radius:0 0 10px 10px;">
            <button type="button" x-on:click="closeTemplatePreview()"
                style="height:34px;padding:0 16px;font-size:14px;font-weight:500;background:#fff;border:1px solid #dee2e6;border-radius:6px;color:#6c757d;cursor:pointer;transition:all .18s;"
                onmouseover="this.style.borderColor='#adb5bd';" onmouseout="this.style.borderColor='#dee2e6';">
                Đóng
            </button>
            <button type="button"
                x-bind:disabled="!$data.confirmPreviewCheck || applyingTemplate"
                x-on:click="applyTemplate()"
                style="height:34px;padding:0 16px;font-size:14px;font-weight:700;background:#f59e0b;border:none;border-radius:6px;color:#fff;cursor:pointer;transition:all .18s;box-shadow:0 2px 6px rgba(245,158,11,.3);display:inline-flex;align-items:center;gap:6px;"
                onmouseover="this.style.background='#d97706';" onmouseout="this.style.background='#f59e0b';">
                <template x-if="!applyingTemplate">
                    <span><i class="bi bi-lightning-charge-fill"></i> Nạp mẫu DNS này</span>
                </template>
                <template x-if="applyingTemplate">
                    <span><span class="spinner-border spinner-border-sm" style="width:13px;height:13px;border-width:2px;"></span> Đang áp dụng...</span>
                </template>
            </button>
        </div>
    </div>
</div>
{/literal}
