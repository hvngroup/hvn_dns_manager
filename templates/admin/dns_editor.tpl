<!-- Kế thừa/Tái sử dụng template dns_editor của Client nhưng thêm Admin View -->
<div class="hvn-dns-admin hvn-dns-editor" x-data="adminDnsEditor()">
    
    <!-- Admin Warning Banner -->
    <div class="alert alert-warning hvn-border-warning border-2 hvn-border-start hvn-d-flex hvn-align-items-center hvn-mb-4">
        <i class="bi bi-wrench-adjustable fs-4 hvn-text-warning hvn-me-3"></i>
        <div class="flex-grow-1">
            <h6 class="hvn-mb-1 hvn-fw-bold hvn-text-dark">ADMIN MODE — Chế độ Quản trị</h6>
            <div class="hvn-mb-0 hvn-text-dark">
                Đang quản lý cấu hình DNS mang tên <strong>{$domain.domain}</strong> thuộc về Khách hàng: <a href="clientssummary.php?userid={$domain.client_id}" class="hvn-fw-bold">{$domain.client_name} (#{$domain.client_id})</a>
            </div>
            <ul class="hvn-mb-0 small hvn-text-dark hvn-mt-1 hvn-ps-3">
                <li>Bỏ qua Rate Limit. Các thao tác sẽ Override dữ liệu nếu Client đang chỉnh sửa (Conflict Resolution: Admin-Priority).</li>
                <li>Có quyền sửa/xóa/khóa bản ghi System (NS, SOA, CAA mặc định).</li>
            </ul>
        </div>
        <a href="?module=hvn_dns_manager&action=domains" class="hvn-btn btn-outline-dark btn-sm">Đóng / Về danh sách</a>
    </div>

    <!-- Toolbar Admin -->
    <div class="hvn-card hvn-shadow-sm hvn-border-0 hvn-mb-4 hvn-bg-light">
        <div class="hvn-card-body hvn-py-2 hvn-px-3 hvn-d-flex hvn-justify-content-between hvn-align-items-center">
            <div class="btn-group">
                <button class="hvn-btn hvn-btn-primary" @click="openAddModal()"><i class="bi bi-plus-lg"></i> Thêm bản ghi</button>
                <a href="?module=hvn_dns_manager&action=snapshot_rollback&domain={$domain.domain}" class="hvn-btn btn-outline-secondary" title="Khôi phục Zone từ Snapshot"><i class="bi bi-skip-backward-fill"></i> Rollback</a>
                <button class="hvn-btn btn-outline-secondary" onclick="alert('Đang tạo Snapshot thủ công...')" title="Tạo ngay 1 bản lưu trạng thái hiện tại"><i class="bi bi-camera-fill"></i> Snapshot</button>
                <a href="?module=hvn_dns_manager&action=audit_trail&domain={$domain.domain}" class="hvn-btn btn-outline-secondary" title="Xem lịch sử thay đổi của tên miền này"><i class="bi bi-clipboard2-data"></i> History</a>
            </div>
            <div class="hvn-text-end">
                <span class="hvn-badge hvn-bg-secondary">Total: <span x-text="records.length"></span> Records</span>
            </div>
        </div>
    </div>

    <!-- Reuse the Client DNS Editor structure but inject admin-specific variables if needed -->
    <!-- Note: In a real implementation, you might pass a variable like $isAdmin=true to partials -->
    
    <div class="hvn-card hvn-shadow-sm hvn-mb-4 hvn-border-0">
        <div class="hvn-card-header hvn-bg-white">
            <h5 class="hvn-mb-0">DNS Records</h5>
        </div>
        <div class="hvn-card-body hvn-p-0">
            <!-- Tái sử dụng bảng records nhưng bằng Alpine logic của Admin -->
            <div class="hvn-p-3 hvn-border-bottom hvn-bg-light hvn-d-flex hvn-justify-content-between">
                <div>
                     <input type="text" class="hvn-form-control hvn-form-control-sm d-inline-block w-auto" placeholder="Tìm kiếm..." x-model="searchQuery">
                </div>
            </div>
            
            <table class="table table-hover align-middle hvn-mb-0">
                <thead class="table-light">
                    <tr>
                        <th class="hvn-ps-3">Loại</th>
                        <th>Tên (Name)</th>
                        <th>Giá trị (Value)</th>
                        <th>Khóa / Hệ thống</th>
                        <th>Trạng thái Sync</th>
                        <th class="hvn-text-end hvn-pe-3">Hành động</th>
                    </tr>
                </thead>
                <tbody>
                    <template x-for="record in filteredRecords" :key="record.id">
                        <tr :class="{ 'table-secondary opacity-75': record.pending_delete}">
                            <td class="hvn-ps-3">
                                <span class="hvn-badge hvn-bg-secondary" x-text="record.type"></span>
                            </td>
                            <td class="font-monospace" x-text="record.name === '@' ? '{$domain.domain}' : record.name"></td>
                            <td class="font-monospace text-wrap" style="max-width: 250px; word-break: break-all;" x-text="record.value"></td>
                            <td>
                                <!-- Admin view: Show system/lock status clearly and allow toggle -->
                                <template x-if="record.is_system">
                                    <span class="hvn-badge hvn-bg-dark" title="System Record"><i class="bi bi-gear"></i> System</span>
                                </template>
                                <div class="form-check form-switch hvn-mt-1" title="Khóa không cho Client sửa">
                                    <input class="form-check-input" type="checkbox" :id="'lock_'+record.id" x-model="record.is_locked" @change="toggleLock(record)">
                                    <label class="form-check-label small" :for="'lock_'+record.id">Khóa</label>
                                </div>
                            </td>
                            <td>
                                <template x-if="record.sync_status === 'complete'">
                                    <span class="hvn-text-success small hvn-fw-bold"><i class="bi bi-check-circle-fill"></i> Live</span>
                                </template>
                                <template x-if="record.sync_status === 'syncing'">
                                    <span class="hvn-text-info small hvn-fw-bold"><i class="bi bi-arrow-repeat spin"></i> Syncing</span>
                                </template>
                                <template x-if="record.sync_status === 'failed'">
                                    <span class="hvn-text-danger small hvn-fw-bold"><i class="bi bi-x-circle-fill"></i> Failed (Timeout)</span>
                                </template>
                            </td>
                            <td class="hvn-text-end hvn-pe-3">
                                <template x-if="!record.pending_delete">
                                    <div class="btn-group btn-group-sm">
                                        <button class="hvn-btn btn-outline-secondary" @click="openEditModal(record)"><i class="bi bi-pencil"></i></button>
                                        <button class="hvn-btn btn-outline-danger" @click="deleteRecord(record)"><i class="bi bi-trash"></i></button>
                                    </div>
                                </template>
                                <template x-if="record.pending_delete">
                                    <span class="hvn-text-muted small fst-italic">Deleting...</span>
                                </template>
                            </td>
                        </tr>
                    </template>
                </tbody>
            </table>
        </div>
    </div>

    <!-- Modals -->
    <!-- Reuse Record Modal logic from Client -->
    {include file="../client/partials/record_modal.tpl" }

</div>

<script>
{literal}
document.addEventListener('alpine:init', () => {
    Alpine.data('adminDnsEditor', () => ({
        searchQuery: '',
        records: {$recordsJson|default:'[]' }, // Passed from Controller

        get filteredRecords() {
            if(this.searchQuery === '') return this.records;
            const text = this.searchQuery.toLowerCase();
            return this.records.filter(r => 
                r.name.toLowerCase().includes(text) || 
                r.value.toLowerCase().includes(text) || 
                r.type.toLowerCase().includes(text)
            );
        },

        openAddModal() {
            window.dispatchEvent(new CustomEvent('open-record-modal', { detail: { isEdit: false } }));
        },
        openEditModal(record) {
            window.dispatchEvent(new CustomEvent('open-record-modal', { detail: { isEdit: true, record: record } }));
        },
        deleteRecord(record) {
            if(confirm(`Admin Privilege: Xóa vĩnh viễn bản ghi ${record.name} (${record.type})?`)) {
                record.pending_delete = true;
                setTimeout(() => {
                    this.records = this.records.filter(r => r.id !== record.id);
                    showToast('Đã xóa', 'Record deleted and sync started.', 'success'); // Requires showToast function
                }, 1000);
            }
        },
        toggleLock(record) {
            alert(`Đã ${record.is_locked ? 'KHÓA' : 'MỞ KHÓA' } bản ghi: Client không thể chỉnh sửa bản ghi bị khóa.`);
        }
    }));
});
{/literal}
</script>
