{* tab_email.tpl — Email Forwarding management *}

{* ── Header ── *}
<div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:16px;">
    <h5 style="margin:0;font-size:15px;font-weight:700;color:#1e293b;">Chuyển tiếp Email</h5>
    <button x-on:click="startAddEmail()" x-bind:disabled="addingNewEmail || editingEmailId !== null"
        style="height:34px;padding:0 14px;display:inline-flex;align-items:center;gap:6px;font-size:14px;font-weight:600;font-family:inherit;background:#ea4544;color:#fff;border:none;border-radius:6px;cursor:pointer;transition:all .18s;white-space:nowrap;box-shadow:0 2px 6px rgba(234,69,68,.25);"
        onmouseover="this.style.background='#d32f2f';" onmouseout="this.style.background='#ea4544';">
        <i class="bi bi-plus-lg"></i> Thêm chuyển tiếp
    </button>
</div>

{* ── Bảng ── *}
<div style="overflow-x:auto;margin-bottom:16px;">
    <table style="width:100%;border-collapse:collapse;font-size:14px;font-family:'Inter',system-ui,-apple-system,sans-serif;">
        <thead>
            <tr style="background:#f8f9fa;">
                <th style="padding:10px 8px;font-size:13px;font-weight:600;color:#5E636E;border-bottom:1px solid #dee2e6;white-space:nowrap;">Từ</th>
                <th style="padding:10px 8px;font-size:13px;font-weight:600;color:#5E636E;border-bottom:1px solid #dee2e6;">Chuyển đến</th>
                <th style="padding:10px 8px;font-size:13px;font-weight:600;color:#5E636E;border-bottom:1px solid #dee2e6;width:110px;white-space:nowrap;">Trạng thái</th>
                <th style="padding:10px 8px;font-size:13px;font-weight:600;color:#5E636E;border-bottom:1px solid #dee2e6;width:90px;text-align:right;">Hành động</th>
            </tr>
        </thead>
        <tbody>
            {* ── Dòng thêm mới ── *}
            <tr x-show="addingNewEmail" x-cloak style="background:#fafbff;">
                <td style="padding:10px 8px;" colspan="2">
                    <div style="display:flex;flex-direction:column;gap:10px;">

                        {* Catchall toggle *}
                        <label style="display:flex;align-items:center;gap:8px;font-size:13px;color:#495057;cursor:pointer;margin:0;">
                            <input type="checkbox" x-model="editEmailForm.is_catchall"
                                style="width:14px;height:14px;margin:0;">
                            Bật catch-all (nhận mọi email sai địa chỉ)
                        </label>

                        {* Source — input + domain suffix NGANG HÀNG *}
                        <div style="display:flex;align-items:stretch;height:34px;">

                            {* Normal: input + @domain.vn *}
                            <template x-if="!editEmailForm.is_catchall">
                                <div style="display:flex;align-items:center;width:100%;">
                                    <input type="text"
                                        x-model="editEmailForm.source_local"
                                        placeholder="info"
                                        style="height:34px;padding:0 10px;font-size:13px;font-family:inherit;color:#495057;background:#fff;border:1px solid #dee2e6;border-right:none;border-radius:6px 0 0 6px;width:160px;box-sizing:border-box;outline:none;transition:border-color .18s;"
                                        onfocus="this.style.borderColor='#ea4544';"
                                        onblur="this.style.borderColor='#dee2e6';">
                                    <span style="height:34px;padding:0 10px;display:inline-flex;align-items:center;background:#f8f9fa;border:1px solid #dee2e6;border-radius:0 6px 6px 0;font-size:13px;color:#6c757d;white-space:nowrap;box-sizing:border-box;">
                                        @{$domain.domain}
                                    </span>
                                </div>
                            </template>

                            {* Catchall: *@domain.vn *}
                            <template x-if="editEmailForm.is_catchall">
                                <div style="display:flex;align-items:center;">
                                    <span style="height:34px;padding:0 10px;display:inline-flex;align-items:center;background:#f8f9fa;border:1px solid #dee2e6;border-radius:6px;font-size:13px;color:#6c757d;white-space:nowrap;">
                                        *@{$domain.domain}
                                    </span>
                                </div>
                            </template>

                        </div>

                        {* Destination email *}
                        <div style="display:flex;align-items:center;gap:8px;">
                            <span style="font-size:13px;color:#6c757d;white-space:nowrap;flex-shrink:0;">→ Chuyển đến:</span>
                            <input type="email"
                                x-model="editEmailForm.destination_email"
                                placeholder="personal@gmail.com"
                                style="height:34px;padding:0 10px;font-size:13px;font-family:inherit;color:#495057;background:#fff;border:1px solid #dee2e6;border-radius:6px;flex:1;box-sizing:border-box;outline:none;transition:border-color .18s;"
                                onfocus="this.style.borderColor='#ea4544';"
                                onblur="this.style.borderColor='#dee2e6';">
                        </div>

                    </div>
                </td>
                <td style="padding:10px 8px;">
                    <span style="display:inline-block;padding:3px 8px;border-radius:5px;font-size:12px;font-weight:600;background:#e2e8f0;color:#475569;">Mới</span>
                </td>
                <td style="padding:10px 8px;text-align:right;">
                    <div style="display:inline-flex;align-items:center;gap:6px;">
                        <button x-on:click="saveEditEmail()" x-bind:disabled="savingEmail" title="Lưu"
                            style="width:30px;height:30px;padding:0;display:inline-flex;align-items:center;justify-content:center;background:#198754;border:none;border-radius:6px;color:#fff;cursor:pointer;font-size:14px;transition:all .18s;"
                            onmouseover="this.style.background='#157347';" onmouseout="this.style.background='#198754';">
                            <i class="bi bi-check-lg" x-show="!savingEmail"></i>
                            <i class="bi bi-arrow-repeat spin" x-show="savingEmail"></i>
                        </button>
                        <button x-on:click="cancelEditEmail()" x-bind:disabled="savingEmail" title="Hủy"
                            style="width:30px;height:30px;padding:0;display:inline-flex;align-items:center;justify-content:center;background:#fff;border:1px solid #dee2e6;border-radius:6px;color:#6c757d;cursor:pointer;font-size:14px;transition:all .18s;"
                            onmouseover="this.style.borderColor='#adb5bd';this.style.color='#343a40';" onmouseout="this.style.borderColor='#dee2e6';this.style.color='#6c757d';">
                            <i class="bi bi-x-lg"></i>
                        </button>
                    </div>
                </td>
            </tr>

            {* ── Empty state ── *}
            <tr x-show="emails.length === 0 && !addingNewEmail" x-cloak>
                <td colspan="4" style="text-align:center;padding:32px 8px;color:#6c757d;font-size:14px;">
                    <i class="bi bi-envelope-slash" style="font-size:24px;display:block;margin-bottom:8px;opacity:.4;"></i>
                    Chưa có cấu hình chuyển tiếp email nào.
                </td>
            </tr>

            {* ── Loop ── *}
            <template x-for="email in emails" :key="email.id">
                <tr x-bind:style="email.pending_delete ? 'opacity:0.5' : ''">
                    {* View mode *}
                    <td style="padding:10px 8px;font-size:14px;font-weight:600;color:#1e293b;" x-show="editingEmailId !== email.id">
                        <span x-text="email.source_email"></span>
                        <template x-if="email.is_catchall">
                            <span style="margin-left:6px;display:inline-block;padding:2px 6px;border-radius:4px;font-size:11px;font-weight:600;background:#fef3c7;color:#92400e;">Catch-all</span>
                        </template>
                    </td>
                    <td style="padding:10px 8px;font-size:14px;color:#1e293b;" x-show="editingEmailId !== email.id" x-text="email.destination_email"></td>
                    <td style="padding:10px 8px;font-size:14px;" x-show="editingEmailId !== email.id">
                        <template x-if="email.sync_status === 'pending' || email.sync_status === 'syncing'">
                            <span style="color:#f59e0b;"><i class="bi bi-arrow-repeat spin"></i> Đang đồng bộ</span>
                        </template>
                        <template x-if="email.sync_status === 'failed'">
                            <span style="color:#dc2626;cursor:help;" title="Lỗi đồng bộ"><i class="bi bi-exclamation-triangle-fill"></i> Lỗi</span>
                        </template>
                        <template x-if="email.sync_status === 'synced'">
                            <span style="color:#198754;"><i class="bi bi-check-circle-fill"></i> Live</span>
                        </template>
                    </td>
                    <td style="padding:10px 8px;text-align:right;" x-show="editingEmailId !== email.id">
                        <div style="display:inline-flex;align-items:center;gap:6px;" x-show="!email.pending_delete && email.sync_status !== 'pending' && email.sync_status !== 'syncing'">
                            <button x-on:click="deleteEmail(email)" x-bind:disabled="addingNewEmail || editingEmailId !== null" title="Xóa"
                                style="width:30px;height:30px;padding:0;display:inline-flex;align-items:center;justify-content:center;background:#fff;border:1px solid #fecaca;border-radius:6px;color:#dc2626;cursor:pointer;font-size:14px;transition:all .18s;"
                                onmouseover="this.style.background='#fef2f2';this.style.borderColor='#fca5a5';" onmouseout="this.style.background='#fff';this.style.borderColor='#fecaca';">
                                <i class="bi bi-trash"></i>
                            </button>
                        </div>
                        <span x-show="email.pending_delete" style="font-size:12px;color:#6c757d;"><i class="bi bi-hourglass-split"></i></span>
                        <button x-show="email.sync_status === 'failed'" x-on:click="retryEmail(email.id)" title="Thử lại"
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

{* ── Catch-all note ── *}
<div style="border:1px solid #fef3c7;border-radius:8px;padding:12px 14px;margin-bottom:16px;background:#fffbeb;">
    <div style="display:flex;align-items:flex-start;gap:8px;font-size:13px;color:#92400e;">
        <i class="bi bi-exclamation-triangle-fill" style="margin-top:1px;flex-shrink:0;"></i>
        <span><strong>Catch-all:</strong> Khi bật, mọi email gửi đến địa chỉ không có forwarder sẽ được chuyển đến email đích. Điều này có thể dẫn đến nhận nhiều thư rác (spam).</span>
    </div>
</div>

{* ── Footer quota ── *}
<div style="font-size:14px;color:#6c757d;">
    <i class="bi bi-bar-chart-fill"></i> Đang dùng:
    <strong x-text="emails.length"></strong>/<strong>{$quota.max_email_forwards|default:10}</strong> chuyển tiếp
</div>
