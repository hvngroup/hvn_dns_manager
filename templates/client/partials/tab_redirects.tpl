{* tab_redirects.tpl — URL Redirect management *}

{* ── Header ── *}
<div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:16px;">
    <h5 style="margin:0;font-size:15px;font-weight:700;color:#1e293b;">Chuyển hướng URL</h5>
    <button x-on:click="startAddRedirect()" x-bind:disabled="addingNewRedirect || editingRedirectId !== null"
        style="height:34px;padding:0 14px;display:inline-flex;align-items:center;gap:6px;font-size:14px;font-weight:600;font-family:inherit;background:#ea4544;color:#fff;border:none;border-radius:6px;cursor:pointer;transition:all .18s;white-space:nowrap;box-shadow:0 2px 6px rgba(234,69,68,.25);"
        onmouseover="this.style.background='#d32f2f';" onmouseout="this.style.background='#ea4544';">
        <i class="bi bi-plus-lg"></i> Thêm chuyển hướng
    </button>
</div>

{* ── Bảng ── *}
<div style="overflow-x:auto;margin-bottom:12px;">
    <table style="width:100%;border-collapse:collapse;font-size:14px;font-family:'Inter',system-ui,-apple-system,sans-serif;">
        <thead>
            <tr style="background:#f8f9fa;">
                <th style="padding:10px 8px;font-size:13px;font-weight:600;color:#5E636E;border-bottom:1px solid #dee2e6;white-space:nowrap;">Nguồn</th>
                <th style="padding:10px 8px;font-size:13px;font-weight:600;color:#5E636E;border-bottom:1px solid #dee2e6;">Đích</th>
                <th style="padding:10px 8px;font-size:13px;font-weight:600;color:#5E636E;border-bottom:1px solid #dee2e6;width:110px;white-space:nowrap;">Loại</th>
                <th style="padding:10px 8px;font-size:13px;font-weight:600;color:#5E636E;border-bottom:1px solid #dee2e6;width:110px;white-space:nowrap;">Trạng thái</th>
                <th style="padding:10px 8px;font-size:13px;font-weight:600;color:#5E636E;border-bottom:1px solid #dee2e6;width:110px;text-align:right;">Hành động</th>
            </tr>
        </thead>
        <tbody>
            {* ── Dòng thêm mới ── *}
            <tr x-show="addingNewRedirect" x-cloak style="background:#fafbff;">
                <td style="padding:10px 8px;">
                    <div style="display:flex;align-items:center;gap:0;">
                        <span style="padding:0 8px;height:31px;display:inline-flex;align-items:center;background:#f8f9fa;border:1px solid #dee2e6;border-right:none;border-radius:6px 0 0 6px;font-size:12px;color:#6c757d;white-space:nowrap;">{$domain.domain}</span>
                        <input type="text" class="form-control form-control-sm" x-model="editRedirectForm.source" placeholder="/path"
                            style="border-radius:0 6px 6px 0;height:31px;font-size:14px;">
                    </div>
                </td>
                <td style="padding:10px 8px;">
                    <input type="text" class="form-control form-control-sm" x-model="editRedirectForm.destination" placeholder="https://..."
                        style="height:31px;font-size:14px;">
                </td>
                <td style="padding:10px 8px;">
                    <select class="form-select form-select-sm" x-model="editRedirectForm.type"
                        style="height:36px;padding-top:0;padding-bottom:0;font-size:14px;">
                        <option value="301">301 - Vĩnh viễn</option>
                        <option value="302">302 - Tạm thời</option>
                    </select>
                </td>
                <td style="padding:10px 8px;">
                    <span style="display:inline-block;padding:3px 8px;border-radius:5px;font-size:12px;font-weight:600;background:#e2e8f0;color:#475569;">Mới</span>
                </td>
                <td style="padding:10px 8px;text-align:right;">
                    <div style="display:inline-flex;align-items:center;gap:6px;">
                        <button x-on:click="saveEditRedirect()" x-bind:disabled="savingRedirect" title="Lưu"
                            style="width:30px;height:30px;padding:0;display:inline-flex;align-items:center;justify-content:center;background:#198754;border:none;border-radius:6px;color:#fff;cursor:pointer;font-size:14px;transition:all .18s;"
                            onmouseover="this.style.background='#157347';" onmouseout="this.style.background='#198754';">
                            <i class="bi bi-check-lg" x-show="!savingRedirect"></i>
                            <i class="bi bi-arrow-repeat" x-show="savingRedirect"></i>
                        </button>
                        <button x-on:click="cancelEditRedirect()" x-bind:disabled="savingRedirect" title="Hủy"
                            style="width:30px;height:30px;padding:0;display:inline-flex;align-items:center;justify-content:center;background:#fff;border:1px solid #dee2e6;border-radius:6px;color:#6c757d;cursor:pointer;font-size:14px;transition:all .18s;"
                            onmouseover="this.style.borderColor='#adb5bd';this.style.color='#343a40';" onmouseout="this.style.borderColor='#dee2e6';this.style.color='#6c757d';">
                            <i class="bi bi-x-lg"></i>
                        </button>
                    </div>
                </td>
            </tr>

            {* ── Empty state ── *}
            <tr x-show="redirects.length === 0 && !addingNewRedirect" x-cloak>
                <td colspan="5" style="text-align:center;padding:32px 8px;color:#6c757d;font-size:14px;">
                    Chưa có cấu hình chuyển hướng nào.
                </td>
            </tr>

            {* ── Loop ── *}
            <template x-for="redirect in redirects" :key="redirect.id">
                <tr x-bind:style="redirect.pending_delete ? 'opacity:0.5' : ''">
                    {* View mode *}
                    <td style="padding:10px 8px;font-size:14px;color:#1e293b;" x-show="editingRedirectId !== redirect.id" x-text="redirect.source_path"></td>
                    <td style="padding:10px 8px;font-size:14px;color:#1e293b;word-break:break-all;" x-show="editingRedirectId !== redirect.id" x-text="redirect.destination_url"></td>
                    <td style="padding:10px 8px;" x-show="editingRedirectId !== redirect.id">
                        <span class="badge" x-bind:class="getTypeRedirectBadgeClass(redirect.type)" x-text="redirect.type"></span>
                        <span style="display:block;font-size:11px;color:#6c757d;margin-top:2px;" x-text="getTypeRedirectLabel(redirect.type)"></span>
                    </td>
                    <td style="padding:10px 8px;font-size:14px;" x-show="editingRedirectId !== redirect.id">
                        <template x-if="redirect.sync_status === 'syncing' || redirect.sync_status === 'pending'">
                            <span style="color:#f59e0b;font-size:14px;"><i class="bi bi-arrow-repeat spin"></i> Đang đồng bộ</span>
                        </template>
                        <template x-if="redirect.sync_status === 'failed'">
                            <span style="color:#dc2626;font-size:14px;cursor:help;" title="Lỗi đồng bộ"><i class="bi bi-exclamation-triangle-fill"></i> Lỗi</span>
                        </template>
                        <template x-if="redirect.sync_status !== 'syncing' && redirect.sync_status !== 'pending' && redirect.sync_status !== 'failed'">
                            <span style="color:#198754;font-size:14px;"><i class="bi bi-check-circle-fill"></i> Live</span>
                        </template>
                    </td>
                    <td style="padding:10px 8px;text-align:right;" x-show="editingRedirectId !== redirect.id">
                        <div style="display:inline-flex;align-items:center;gap:6px;"
                             x-show="!redirect.pending_delete && redirect.sync_status !== 'syncing' && redirect.sync_status !== 'pending'">
                            <button x-on:click="deleteRedirect(redirect)" x-bind:disabled="addingNewRedirect || editingRedirectId !== null" title="Xóa"
                                style="width:30px;height:30px;padding:0;display:inline-flex;align-items:center;justify-content:center;background:#fff;border:1px solid #fecaca;border-radius:6px;color:#dc2626;cursor:pointer;font-size:14px;transition:all .18s;"
                                onmouseover="this.style.background='#fef2f2';this.style.borderColor='#fca5a5';" onmouseout="this.style.background='#fff';this.style.borderColor='#fecaca';">
                                <i class="bi bi-trash"></i>
                            </button>
                        </div>
                        <button x-show="redirect.sync_status === 'failed'" x-on:click="retryRedirect(redirect.id)" title="Thử lại"
                            style="width:30px;height:30px;padding:0;display:inline-flex;align-items:center;justify-content:center;background:#fff;border:1px solid #fef08a;border-radius:6px;color:#ca8a04;cursor:pointer;font-size:14px;transition:all .18s;"
                            onmouseover="this.style.background='#fefce8';" onmouseout="this.style.background='#fff';">
                            <i class="bi bi-arrow-clockwise"></i>
                        </button>
                    </td>
                </tr>
            </template>
        </tbody>
    </table>
</div>

{* ── Footer quota ── *}
<div style="font-size:14px;color:#6c757d;margin-top:8px;">
    <i class="bi bi-bar-chart-fill"></i> Đang dùng:
    <strong x-text="redirects.length"></strong>/<strong>{$quota.max_redirects|default:5}</strong> chuyển hướng
</div>