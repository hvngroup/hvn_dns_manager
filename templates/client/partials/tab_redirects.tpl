<div class="d-flex justify-content-between align-items-center mb-3">
    <h5 class="mb-0">Chuyển hướng URL</h5>
    <button class="btn btn-primary btn-sm" x-on:click="startAddRedirect()" x-bind:disabled="addingNewRedirect || editingRedirectId !== null">
        <i class="bi bi-plus-lg"></i> Thêm chuyển hướng
    </button>
</div>

<div class="table-responsive mb-3">
    <table class="table table-hover align-middle">
        <thead class="table-light">
            <tr>
                <th>Nguồn</th>
                <th>Đích</th>
                <th>Loại</th>
                <th>Trạng thái</th>
                <th class="text-end" style="min-width: 120px;">Hành động</th>
            </tr>
        </thead>
        <tbody>
            {* ── Dòng thêm mới (nếu đang ở chế độ thêm) ── *}
            <tr x-show="addingNewRedirect" class="hvn-inline-add" x-cloak>
                <td>
                    <div class="input-group input-group-sm">
                        <span class="input-group-text d-none d-sm-block">{$domain.domain}</span>
                        <input type="text" class="form-control" x-model="editRedirectForm.source" placeholder="/path">
                    </div>
                </td>
                <td>
                    <input type="text" class="form-control" x-model="editRedirectForm.destination" placeholder="https://...">
                    <input type="text" class="form-control mt-1" x-model="editRedirectForm.title" placeholder="Tiêu đề trang (chỉ cho Masked)" x-show="editRedirectForm.type === 'masked'">
                </td>
                <td>
                    <select class="form-select" x-model="editRedirectForm.type">
                        <option value="301">301 - Vĩnh viễn</option>
                        <option value="302">302 - Tạm thời</option>
                        <option value="masked">Masked - Trang ảo</option>
                    </select>
                </td>
                <td><span class="badge bg-secondary">Mới</span></td>
                <td class="text-end">
                    <button class="btn btn-sm btn-success" x-on:click="saveEditRedirect()" x-bind:disabled="savingRedirect">
                        <i class="bi bi-check-lg" x-show="!savingRedirect"></i>
                        <i class="bi bi-arrow-repeat spin" x-show="savingRedirect"></i>
                    </button>
                    <button class="btn btn-sm btn-outline-secondary" x-on:click="cancelEditRedirect()" x-bind:disabled="savingRedirect">
                        <i class="bi bi-x-lg"></i>
                    </button>
                </td>
            </tr>

            {* ── No redirects message ── *}
            <tr x-show="redirects.length === 0 && !addingNewRedirect" x-cloak>
                <td colspan="5" class="text-center text-muted py-4">
                    Chưa có cấu hình chuyển hướng nào.
                </td>
            </tr>

            {* ── Loop qua danh sách Redirects ── *}
            <template x-for="redirect in redirects" :key="redirect.id">
                <tr x-bind:class="{ 'opacity-50': redirect.pending_delete, 'hvn-inline-edit': editingRedirectId === redirect.id }">
                    
                    {* ── View mode ── *}
                    <td class="font-monospace" x-show="editingRedirectId !== redirect.id" x-text="redirect.source"></td>
                    <td x-show="editingRedirectId !== redirect.id">
                        <div class="font-monospace text-break" x-text="redirect.destination"></div>
                        <div class="small text-muted mt-1" x-show="redirect.type === 'masked'">
                            Title: "<span x-text="redirect.title"></span>"
                        </div>
                    </td>
                    <td x-show="editingRedirectId !== redirect.id">
                        <span class="badge" x-bind:class="getTypeRedirectBadgeClass(redirect.type)" x-text="redirect.type === 'masked' ? 'Masked' : redirect.type"></span>
                        <span class="d-block small text-muted mt-1" x-text="getTypeRedirectLabel(redirect.type)"></span>
                    </td>
                    <td x-show="editingRedirectId !== redirect.id">
                        <template x-if="redirect.sync_status === 'syncing'">
                            <span class="text-warning"><i class="bi bi-arrow-repeat spin"></i> Đang đồng bộ</span>
                        </template>
                        <template x-if="redirect.sync_status === 'failed'">
                            <span class="text-danger" title="Lỗi đồng bộ" style="cursor:help;">
                                <i class="bi bi-exclamation-triangle-fill"></i> Lỗi
                            </span>
                        </template>
                        <template x-if="redirect.sync_status !== 'syncing' && redirect.sync_status !== 'failed'">
                            <span class="text-success"><i class="bi bi-check-circle-fill"></i> Live</span>
                        </template>
                    </td>
                    <td class="text-end" x-show="editingRedirectId !== redirect.id">
                        <div class="btn-group btn-group-sm" x-show="!redirect.pending_delete && redirect.sync_status !== 'syncing'">
                            <button class="btn btn-outline-secondary" x-on:click="startEditRedirect(redirect)" x-bind:disabled="addingNewRedirect || editingRedirectId !== null">
                                <i class="bi bi-pencil"></i>
                            </button>
                            <button class="btn btn-outline-danger" x-on:click="deleteRedirect(redirect)" x-bind:disabled="addingNewRedirect || editingRedirectId !== null">
                                <i class="bi bi-trash"></i>
                            </button>
                        </div>
                        <button class="btn btn-sm btn-outline-warning" x-show="redirect.sync_status === 'failed'" x-on:click="retryRedirect(redirect.id)" title="Thử lại">
                            <i class="bi bi-arrow-clockwise"></i>
                        </button>
                    </td>

                    {* ── Edit mode ── *}
                    <td x-show="editingRedirectId === redirect.id">
                        <div class="input-group input-group-sm">
                            <span class="input-group-text d-none d-sm-block">{$domain.domain}</span>
                            <input type="text" class="form-control" x-model="editRedirectForm.source">
                        </div>
                    </td>
                    <td x-show="editingRedirectId === redirect.id">
                        <input type="text" class="form-control" x-model="editRedirectForm.destination">
                        <input type="text" class="form-control mt-1" x-model="editRedirectForm.title" placeholder="Tiêu đề trang" x-show="editRedirectForm.type === 'masked'">
                    </td>
                    <td x-show="editingRedirectId === redirect.id">
                        <select class="form-select" x-model="editRedirectForm.type">
                            <option value="301">301 - Vĩnh viễn</option>
                            <option value="302">302 - Tạm thời</option>
                            <option value="masked">Masked - Trang ảo</option>
                        </select>
                    </td>
                    <td x-show="editingRedirectId === redirect.id"><span class="badge bg-secondary">Đang sửa</span></td>
                    <td class="text-end" x-show="editingRedirectId === redirect.id">
                        <button class="btn btn-sm btn-success" x-on:click="saveEditRedirect()" x-bind:disabled="savingRedirect">
                            <i class="bi bi-check-lg" x-show="!savingRedirect"></i>
                            <i class="bi bi-arrow-repeat spin" x-show="savingRedirect"></i>
                        </button>
                        <button class="btn btn-sm btn-outline-secondary" x-on:click="cancelEditRedirect()" x-bind:disabled="savingRedirect">
                            <i class="bi bi-x-lg"></i>
                        </button>
                    </td>
                </tr>
            </template>
        </tbody>
    </table>
</div>

<div class="alert alert-secondary py-2">
    <i class="bi bi-bar-chart-fill"></i> Đang dùng: <strong x-text="redirects.length"></strong>/<strong>{$quota.max_redirects|default:5}</strong> chuyển hướng
</div>
