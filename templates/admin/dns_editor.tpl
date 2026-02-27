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
    
    <!-- Search bar -->
    <div class="hvn-card hvn-shadow-sm hvn-border-0 hvn-mb-3 hvn-bg-light">
        <div class="hvn-card-body hvn-py-2 hvn-px-3">
            <div class="hvn-d-flex hvn-align-items-center" style="gap:10px;">
                <i class="bi bi-search hvn-text-muted"></i>
                <input type="text" class="hvn-form-control hvn-form-control-sm"
                       style="max-width:300px;"
                       placeholder="Lọc nhanh theo tên, giá trị..."
                       x-model="searchQuery">
                <span class="hvn-text-muted hvn-small" x-show="searchQuery">
                    — <span x-text="filteredRecords.length"></span> kết quả
                </span>
            </div>
        </div>
    </div>

    <!-- No records empty state -->
    <template x-if="filteredRecords.length === 0">
        <div class="hvn-card hvn-border-0 hvn-shadow-sm hvn-text-center hvn-py-5 hvn-text-muted">
            <i class="bi bi-inbox" style="font-size:2.5rem;opacity:.4;"></i>
            <div class="hvn-mt-2">Không có bản ghi nào phù hợp.</div>
        </div>
    </template>

    <!-- Groups: lặp qua từng type có trong filteredRecords -->
    <template x-for="group in recordsByType" :key="group.type">
        <div class="hvn-card hvn-shadow-sm hvn-border-0 hvn-mb-3">

            <!-- Group Header -->
            <div class="hvn-card-header hvn-d-flex hvn-align-items-center hvn-justify-content-between"
                 :style="'background:' + typeColor(group.type) + '18; border-left: 4px solid ' + typeColor(group.type) + ';'"
                 style="cursor:pointer;" @click="toggleGroup(group.type)">
                <div class="hvn-d-flex hvn-align-items-center" style="gap:10px;">
                    <!-- Type pill -->
                    <span class="hvn-badge hvn-fw-bold hvn-small" style="font-size:.7rem; letter-spacing:.08em; padding:3px 10px; border-radius:99px; color:#fff;"
                          :style="'background:' + typeColor(group.type)">
                        <span x-text="group.type"></span>
                    </span>
                    <span class="hvn-fw-bold" x-text="typeLabel(group.type)"></span>
                    <span class="hvn-badge hvn-bg-secondary hvn-small" x-text="group.records.length + ' bản ghi'"></span>
                    <!-- failed indicator -->
                    <template x-if="group.records.some(r => r.sync_status === 'failed')">
                        <span class="hvn-badge" style="background:#dc3545;font-size:.65rem;">
                            <i class="bi bi-exclamation-triangle"></i> Có lỗi sync
                        </span>
                    </template>
                </div>
                <div class="hvn-d-flex hvn-align-items-center" style="gap:8px;">
                    <button class="hvn-btn hvn-btn-sm"
                            :style="'background:' + typeColor(group.type) + '; color:#fff; border:none; font-size:14px;'"
                            @click.stop="openAddModal(group.type)"
                            title="Thêm bản ghi loại này">
                        <i class="bi bi-plus-lg"></i> Thêm <span x-text="group.type"></span>
                    </button>
                    <i class="bi" :class="expandedGroups.includes(group.type) ? 'bi-chevron-up' : 'bi-chevron-down'" style="font-size:.85rem;opacity:.6;"></i>
                </div>
            </div>

            <!-- Group Table (collapsible) -->
            <div x-show="expandedGroups.includes(group.type)" style="overflow-x:auto;">
                <table class="hvn-table hvn-table-hover hvn-align-middle hvn-mb-0" style="font-size:14px;">
                    <thead>
                        <tr style="background:#f8f9fa; font-size:14px; text-transform:uppercase; letter-spacing:.05em; color:#6c757d;">
                            <th class="hvn-ps-3" style="width:30%;">Tên (Name)</th>
                            <th style="width:8%;">TTL</th>
                            <th>Giá trị (Value)</th>
                            <th style="width:12%;">Khóa / Sys</th>
                            <th style="width:10%;">Sync</th>
                            <th class="hvn-text-end hvn-pe-3" style="width:100px;">Hành động</th>
                        </tr>
                    </thead>
                    <tbody>
                        <template x-for="record in group.records" :key="record.id">
                            <tr :style="record.pending_delete ? 'opacity:.5;' : ''">
                                <!-- Name -->
                                <td class="hvn-ps-3" style="font-family:monospace; font-weight:600;"
                                    x-text="record.name === '@' ? '{$domain.domain|default:'domain.com'}' : record.name + '.{$domain.domain|default:'domain.com'}'">
                                </td>
                                <!-- TTL -->
                                <td class="hvn-text-muted hvn-small" x-text="record.ttl ? record.ttl + 's' : '3600s'"></td>
                                <!-- Value -->
                                <td style="font-family:monospace; word-break:break-all; max-width:260px;">
                                    <span x-text="record.value"></span>
                                    <template x-if="record.priority">
                                        <span class="hvn-text-muted hvn-small"> (priority: <span x-text="record.priority"></span>)</span>
                                    </template>
                                </td>
                                <!-- Lock / System -->
                                <td>
                                    <div class="hvn-d-flex hvn-align-items-center" style="gap:6px; flex-wrap:wrap;">
                                        <template x-if="record.is_system">
                                            <span style="font-size:.65rem; padding:2px 6px; background:#343a40; color:#fff; border-radius:4px;">
                                                <i class="bi bi-gear-fill"></i> SYS
                                            </span>
                                        </template>
                                        <label class="hvn-d-flex hvn-align-items-center hvn-gap-1" style="cursor:pointer; user-select:none; font-size:14px;" title="Khóa không cho Client sửa">
                                            <input type="checkbox" :id="'lock_'+record.id" x-model="record.is_locked" @change="toggleLock(record)">
                                            <span x-text="record.is_locked ? 'Khóa' : 'Mở'"></span>
                                        </label>
                                    </div>
                                </td>
                                <!-- Sync status -->
                                <td>
                                    <template x-if="record.sync_status === 'complete'">
                                        <span style="color:#198754; font-size:14px; font-weight:600;"><i class="bi bi-check-circle-fill"></i> Live</span>
                                    </template>
                                    <template x-if="record.sync_status === 'syncing'">
                                        <span style="color:#0dcaf0; font-size:14px; font-weight:600;"><i class="bi bi-arrow-repeat"></i> Syncing</span>
                                    </template>
                                    <template x-if="record.sync_status === 'failed'">
                                        <span style="color:#dc3545; font-size:14px; font-weight:600;"><i class="bi bi-x-circle-fill"></i> Failed</span>
                                    </template>
                                </td>
                                <!-- Actions -->
                                <td class="hvn-text-end hvn-pe-3">
                                    <template x-if="!record.pending_delete">
                                        <div class="hvn-d-flex hvn-justify-content-end" style="gap:4px;">
                                            <button class="hvn-btn hvn-btn-sm hvn-btn-outline-secondary" @click="openEditModal(record)" title="Sửa">
                                                <i class="bi bi-pencil"></i>
                                            </button>
                                            <button class="hvn-btn hvn-btn-sm hvn-btn-outline-danger" @click="deleteRecord(record)" title="Xóa">
                                                <i class="bi bi-trash"></i>
                                            </button>
                                        </div>
                                    </template>
                                    <template x-if="record.pending_delete">
                                        <span class="hvn-text-muted" style="font-size:14px; font-style:italic;">
                                            <i class="bi bi-hourglass-split"></i> Deleting...
                                        </span>
                                    </template>
                                </td>
                            </tr>
                        </template>
                    </tbody>
                </table>
            </div>
        </div>
    </template>


    <!-- Modals -->
    <!-- Reuse Record Modal logic from Client -->
    {include file="../client/partials/record_modal.tpl" }

</div>

<script>
    var _adminRecords = {$recordsJson|default:'[{"id":1,"type":"A","name":"@","value":"203.0.113.10","ttl":3600,"is_system":false,"is_locked":false,"pending_delete":false,"sync_status":"complete"},{"id":2,"type":"MX","name":"@","value":"mail.example.com.","priority":10,"ttl":3600,"is_system":false,"is_locked":true,"pending_delete":false,"sync_status":"complete"},{"id":3,"type":"CNAME","name":"www","value":"example.com.","ttl":3600,"is_system":false,"is_locked":false,"pending_delete":false,"sync_status":"syncing"},{"id":4,"type":"TXT","name":"@","value":"v=spf1 include:mailgun.org ~all","ttl":600,"is_system":false,"is_locked":false,"pending_delete":false,"sync_status":"complete"},{"id":5,"type":"NS","name":"@","value":"ns1.hvn.vn.","ttl":86400,"is_system":true,"is_locked":true,"pending_delete":false,"sync_status":"complete"},{"id":6,"type":"AAAA","name":"ipv6","value":"2001:db8::1","ttl":3600,"is_system":false,"is_locked":false,"pending_delete":false,"sync_status":"failed"}]'};
</script>
<script>
{literal}
document.addEventListener('alpine:init', () => {
    Alpine.data('adminDnsEditor', () => ({
        searchQuery: '',
        records: _adminRecords,
        expandedGroups: ['A', 'MX', 'CNAME', 'TXT', 'SRV', 'NS', 'CAA', 'AAAA'],

        // Canonical order for record types
        _typeOrder: ['A', 'AAAA', 'CNAME', 'MX', 'TXT', 'NS', 'SRV', 'CAA'],

        get filteredRecords() {
            if (this.searchQuery === '') return this.records;
            const text = this.searchQuery.toLowerCase();
            return this.records.filter(r =>
                r.name.toLowerCase().includes(text) ||
                r.value.toLowerCase().includes(text) ||
                r.type.toLowerCase().includes(text)
            );
        },

        // Group filteredRecords by type, maintain canonical order
        get recordsByType() {
            const map = {};
            this.filteredRecords.forEach(r => {
                if (!map[r.type]) map[r.type] = [];
                map[r.type].push(r);
            });
            // Order: canonical first, then unknowns alphabetically
            const knownOrder = this._typeOrder.filter(t => map[t]);
            const others = Object.keys(map).filter(t => !this._typeOrder.includes(t)).sort();
            return [...knownOrder, ...others].map(type => ({ type, records: map[type] }));
        },

        toggleGroup(type) {
            const idx = this.expandedGroups.indexOf(type);
            if (idx >= 0) {
                this.expandedGroups.splice(idx, 1);
            } else {
                this.expandedGroups.push(type);
            }
        },

        typeColor(type) {
            const colors = {
                'A':    '#0d6efd',
                'AAAA': '#6610f2',
                'CNAME':'#20c997',
                'MX':   '#fd7e14',
                'TXT':  '#6f42c1',
                'NS':   '#6c757d',
                'SRV':  '#0dcaf0',
                'CAA':  '#dc3545',
            };
            return colors[type] || '#495057';
        },

        typeLabel(type) {
            const labels = {
                'A':    'IPv4 Address',
                'AAAA': 'IPv6 Address',
                'CNAME':'Canonical Name',
                'MX':   'Mail Exchange',
                'TXT':  'Text Record',
                'NS':   'Name Server',
                'SRV':  'Service Record',
                'CAA':  'CA Authorization',
            };
            return labels[type] || type + ' Record';
        },

        openAddModal(prefillType) {
            window.dispatchEvent(new CustomEvent('open-record-modal', {
                detail: { isEdit: false, prefillType: prefillType || '' }
            }));
        },
        openEditModal(record) {
            window.dispatchEvent(new CustomEvent('open-record-modal', { detail: { isEdit: true, record: record } }));
        },
        deleteRecord(record) {
            if (confirm('Admin Privilege: Xoa vinh vien ban ghi ' + record.name + ' (' + record.type + ')?')) {
                record.pending_delete = true;
                setTimeout(() => {
                    this.records = this.records.filter(r => r.id !== record.id);
                }, 1000);
            }
        },
        toggleLock(record) {
            alert((record.is_locked ? 'KHOA' : 'MO KHOA') + ' ban ghi thanh cong.');
        }
    }));
});
{/literal}
</script>
