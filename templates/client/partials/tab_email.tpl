<div class="d-flex justify-content-between align-items-center mb-3">
    <h5 class="mb-0">Chuyển tiếp Email</h5>
    <button class="btn btn-primary btn-sm" x-on:click="startAddEmail()" x-bind:disabled="addingNewEmail || editingEmailId !== null">
        <i class="bi bi-plus-lg"></i> Thêm chuyển tiếp
    </button>
</div>

<div class="table-responsive mb-4">
    <table class="table table-hover align-middle">
        <thead class="table-light">
            <tr>
                <th>Từ</th>
                <th>Chuyển đến</th>
                <th>Trạng thái</th>
                <th class="text-end" style="min-width: 120px;">Hành động</th>
            </tr>
        </thead>
        <tbody>
            {* ── Dòng thêm mới (nếu đang ở chế độ thêm) ── *}
            <tr x-show="addingNewEmail" class="hvn-inline-add" x-cloak>
                <td>
                    <div class="input-group input-group-sm">
                        <input type="text" class="form-control" x-model="editEmailForm.source" placeholder="info">
                        <span class="input-group-text">@{$domain.domain}</span>
                    </div>
                </td>
                <td>
                    <input type="email" class="form-control form-control-sm" x-model="editEmailForm.destination" placeholder="personal@gmail.com">
                </td>
                <td><span class="badge bg-secondary">Mới</span></td>
                <td class="text-end">
                    <button class="btn btn-sm btn-success" x-on:click="saveEditEmail()" x-bind:disabled="savingEmail">
                        <i class="bi bi-check-lg" x-show="!savingEmail"></i>
                        <i class="bi bi-arrow-repeat spin" x-show="savingEmail"></i>
                    </button>
                    <button class="btn btn-sm btn-outline-secondary" x-on:click="cancelEditEmail()" x-bind:disabled="savingEmail">
                        <i class="bi bi-x-lg"></i>
                    </button>
                </td>
            </tr>

            {* ── No emails message ── *}
            <tr x-show="emails.length === 0 && !addingNewEmail" x-cloak>
                <td colspan="4" class="text-center text-muted py-4">
                    Chưa có cấu hình chuyển tiếp email nào.
                </td>
            </tr>

            {* ── Loop qua danh sách Forwards ── *}
            <template x-for="email in emails" :key="email.id">
                <tr x-bind:class="{ 'opacity-50': email.pending_delete, 'hvn-inline-edit': editingEmailId === email.id }">
                    
                    {* ── View mode ── *}
                    <td class="font-monospace fw-bold" x-show="editingEmailId !== email.id" x-text="email.source"></td>
                    <td class="font-monospace" x-show="editingEmailId !== email.id" x-text="email.destination"></td>
                    <td x-show="editingEmailId !== email.id">
                        <template x-if="email.sync_status === 'syncing'">
                            <span class="text-warning"><i class="bi bi-arrow-repeat spin"></i> Đang đồng bộ</span>
                        </template>
                        <template x-if="email.sync_status === 'failed'">
                            <span class="text-danger" title="Lỗi đồng bộ" style="cursor:help;">
                                <i class="bi bi-exclamation-triangle-fill"></i> Lỗi
                            </span>
                        </template>
                        <template x-if="email.sync_status !== 'syncing' && email.sync_status !== 'failed'">
                            <span class="text-success"><i class="bi bi-check-circle-fill"></i> Live</span>
                        </template>
                    </td>
                    <td class="text-end" x-show="editingEmailId !== email.id">
                        <div class="btn-group btn-group-sm" x-show="!email.pending_delete && email.sync_status !== 'syncing'">
                            <button class="btn btn-outline-secondary" x-on:click="startEditEmail(email)" x-bind:disabled="addingNewEmail || editingEmailId !== null"><i class="bi bi-pencil"></i></button>
                            <button class="btn btn-outline-danger" x-on:click="deleteEmail(email)" x-bind:disabled="addingNewEmail || editingEmailId !== null"><i class="bi bi-trash"></i></button>
                        </div>
                        <button class="btn btn-sm btn-outline-warning" x-show="email.sync_status === 'failed'" x-on:click="retryEmail(email.id)" title="Thử lại">
                            <i class="bi bi-arrow-clockwise"></i>
                        </button>
                    </td>

                    {* ── Edit mode ── *}
                    <td x-show="editingEmailId === email.id">
                        <div class="input-group input-group-sm">
                            <input type="text" class="form-control" x-model="editEmailForm.source">
                            <span class="input-group-text">@{$domain.domain}</span>
                        </div>
                    </td>
                    <td x-show="editingEmailId === email.id">
                        <input type="email" class="form-control form-control-sm" x-model="editEmailForm.destination">
                    </td>
                    <td x-show="editingEmailId === email.id"><span class="badge bg-secondary">Đang sửa</span></td>
                    <td class="text-end" x-show="editingEmailId === email.id">
                        <button class="btn btn-sm btn-success" x-on:click="saveEditEmail()" x-bind:disabled="savingEmail">
                            <i class="bi bi-check-lg" x-show="!savingEmail"></i>
                            <i class="bi bi-arrow-repeat spin" x-show="savingEmail"></i>
                        </button>
                        <button class="btn btn-sm btn-outline-secondary" x-on:click="cancelEditEmail()" x-bind:disabled="savingEmail">
                            <i class="bi bi-x-lg"></i>
                        </button>
                    </td>
                </tr>
            </template>
        </tbody>
    </table>
</div>

<div class="card mb-3 border-secondary">
    <div class="card-header bg-light">
        <h6 class="mb-0">Catch-all (Nhận mọi email)</h6>
    </div>
    <div class="card-body">
        <div class="form-check form-switch mb-2">
            <input class="form-check-input" type="checkbox" id="catchallToggle">
            <label class="form-check-label" for="catchallToggle">
                Chuyển mọi email gửi tới sai địa chỉ về email này:
            </label>
        </div>
        <div class="input-group input-group-sm w-50 mb-2">
            <span class="input-group-text">*@{$domain.domain} &rarr;</span>
            <input type="email" class="form-control" placeholder="backup@gmail.com" disabled>
            <button class="btn btn-outline-secondary" disabled>Lưu</button>
        </div>
        <div class="text-warning small">
            <i class="bi bi-exclamation-triangle-fill"></i> <strong>Cảnh báo:</strong> Bật catch-all đồng nghĩa với việc bạn sẽ nhận tất cả thư rác (spam) gửi tới tên miền của mình.
        </div>
    </div>
</div>

<div class="alert alert-secondary py-2">
    <i class="bi bi-bar-chart-fill"></i> Đang dùng: <strong x-text="emails.length"></strong>/<strong>{$quota.max_email_forwards|default:10}</strong> chuyển tiếp
</div>

{literal}
<script>
    document.getElementById('catchallToggle').addEventListener('change', function() {
        var inputs = this.closest('.card-body').querySelectorAll('input[type="email"], button');
        inputs.forEach(function(el) { el.disabled = !this.checked; }.bind(this));
    });
</script>
{/literal}
