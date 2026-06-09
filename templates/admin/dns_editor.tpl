<!-- Admin DNS Editor — dữ liệu thật từ DB -->
{if !$domain}
    <div class="alert alert-danger mj-mb-4">
        <i class="bi bi-exclamation-triangle-fill mj-me-2"></i>
        <strong>Lỗi:</strong> {$editorError|default:'Domain không tồn tại hoặc thiếu tham số domain_id.'|escape:'htmlall'}
        <a href="?module=mj_dns_manager&action=domains" class="mj-btn btn-outline-danger btn-sm mj-ms-3">← Về danh sách</a>
    </div>
{else}
<div class="mj-dns-admin mj-dns-editor" x-data="adminDnsEditor()">
    
    <!-- Admin Warning Banner -->
    <div class="alert alert-warning mj-border-warning border-2 mj-border-start mj-d-flex mj-align-items-center mj-mb-4">
        <i class="bi bi-wrench-adjustable fs-4 mj-text-warning mj-me-3"></i>
        <div class="flex-grow-1">
            <h6 class="mj-mb-1 mj-fw-bold mj-text-dark">ADMIN MODE — Chế độ Quản trị</h6>
            <div class="mj-mb-0 mj-text-dark">
                Đang quản lý DNS: <strong>{$domain.domain|escape:'htmlall'}</strong> — Khách hàng: <a href="clientssummary.php?userid={$domain.client_id|escape:'htmlall'}" class="mj-fw-bold">{$domain.client_name|escape:'htmlall'} (#{$domain.client_id|escape:'htmlall'})</a>
            </div>
            <ul class="mj-mb-0 small mj-text-dark mj-mt-1 mj-ps-3">
                <li>Bỏ qua Rate Limit. Các thao tác sẽ Override dữ liệu nếu Client đang chỉnh sửa (Conflict Resolution: Admin-Priority).</li>
                <li>Có quyền sửa/xóa/khóa bản ghi System (NS, SOA, CAA mặc định).</li>
            </ul>
        </div>
        <a href="?module=mj_dns_manager&action=domains" class="mj-btn btn-outline-dark btn-sm">Đóng / Về danh sách</a>
    </div>

    <!-- Toolbar Admin -->
    <div class="mj-card mj-shadow-sm mj-border-0 mj-mb-4 mj-bg-light">
        <div class="mj-card-body mj-py-2 mj-px-3 mj-d-flex mj-justify-content-between mj-align-items-center">
            <div class="btn-group">
                <button class="mj-btn mj-btn-primary" @click="openAddModal()"><i class="bi bi-plus-lg"></i> Thêm bản ghi</button>
                <a href="?module=mj_dns_manager&action=snapshot_rollback&domain={$domain.domain}" class="mj-btn btn-outline-secondary" title="Khôi phục Zone từ Snapshot"><i class="bi bi-skip-backward-fill"></i> Rollback</a>
                <button class="mj-btn btn-outline-secondary" @click="takeSnapshot()" title="Tạo ngay 1 bản lưu trạng thái hiện tại"><i class="bi bi-camera-fill"></i> Snapshot</button>
                <a href="?module=mj_dns_manager&action=audit_trail&domain={$domain.domain}" class="mj-btn btn-outline-secondary" title="Xem lịch sử thay đổi của tên miền này"><i class="bi bi-clipboard2-data"></i> History</a>
            </div>
            <div class="mj-text-end">
                <span class="mj-badge mj-bg-secondary">Total: <span x-text="records.length"></span> Records</span>
            </div>
        </div>
    </div>

    <!-- Reuse the Client DNS Editor structure but inject admin-specific variables if needed -->
    <!-- Note: In a real implementation, you might pass a variable like $isAdmin=true to partials -->
    
    <!-- Search bar -->
    <div class="mj-card mj-shadow-sm mj-border-0 mj-mb-3 mj-bg-light">
        <div class="mj-card-body mj-py-2 mj-px-3">
            <div class="mj-d-flex mj-align-items-center" style="gap:10px;">
                <i class="bi bi-search mj-text-muted"></i>
                <input type="text" class="mj-form-control mj-form-control-sm"
                       style="max-width:300px;"
                       placeholder="Lọc nhanh theo tên, giá trị..."
                       x-model="searchQuery">
                <span class="mj-text-muted mj-small" x-show="searchQuery">
                    — <span x-text="filteredRecords.length"></span> kết quả
                </span>
            </div>
        </div>
    </div>

    <!-- No records empty state -->
    <template x-if="filteredRecords.length === 0">
        <div class="mj-card mj-border-0 mj-shadow-sm mj-text-center mj-py-5 mj-text-muted">
            <i class="bi bi-inbox" style="font-size:2.5rem;opacity:.4;"></i>
            <div class="mj-mt-2">Không có bản ghi nào phù hợp.</div>
        </div>
    </template>

    <!-- Groups: lặp qua từng type có trong filteredRecords -->
    <template x-for="group in recordsByType" :key="group.type">
        <div class="mj-card mj-shadow-sm mj-border-0 mj-mb-3">

            <!-- Group Header -->
            <div class="mj-card-header mj-d-flex mj-align-items-center mj-justify-content-between"
                 :style="'background:' + typeColor(group.type) + '18; border-left: 4px solid ' + typeColor(group.type) + ';'"
                 style="cursor:pointer;" @click="toggleGroup(group.type)">
                <div class="mj-d-flex mj-align-items-center" style="gap:10px;">
                    <!-- Type pill -->
                    <span class="mj-badge mj-fw-bold mj-small" style="font-size:.7rem; letter-spacing:.08em; padding:3px 10px; border-radius:99px; color:#fff;"
                          :style="'background:' + typeColor(group.type)">
                        <span x-text="group.type"></span>
                    </span>
                    <span class="mj-fw-bold" x-text="typeLabel(group.type)"></span>
                    <span class="mj-badge mj-bg-secondary mj-small" x-text="group.records.length + ' bản ghi'"></span>
                    <!-- failed indicator -->
                    <template x-if="group.records.some(r => r.sync_status === 'failed')">
                        <span class="mj-badge" style="background:#dc3545;font-size:.65rem;">
                            <i class="bi bi-exclamation-triangle"></i> Có lỗi sync
                        </span>
                    </template>
                </div>
                <div class="mj-d-flex mj-align-items-center" style="gap:8px;">
                    <button class="mj-btn mj-btn-sm"
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
                <table class="mj-table mj-table-hover mj-align-middle mj-mb-0" style="font-size:14px;">
                    <thead>
                        <tr style="background:#f8f9fa; font-size:14px; text-transform:uppercase; letter-spacing:.05em; color:#6c757d;">
                            <th class="mj-ps-3" style="width:30%;">Tên (Name)</th>
                            <th style="width:8%;">TTL</th>
                            <th>Giá trị (Value)</th>
                            <th style="width:12%;">Khóa / Sys</th>
                            <th style="width:10%;">Sync</th>
                            <th class="mj-text-end mj-pe-3" style="width:100px;">Hành động</th>
                        </tr>
                    </thead>
                    <tbody>
                        <template x-for="record in group.records" :key="record.id">
                            <tr :style="record.pending_delete ? 'opacity:.5;' : ''">
                                <!-- Name -->
                                <td class="mj-ps-3" style="font-family:monospace; font-weight:600;"
                                    x-text="record.name === '@' ? '{$domain.domain|default:'domain.com'}' : record.name + '.{$domain.domain|default:'domain.com'}'">
                                </td>
                                <!-- TTL -->
                                <td class="mj-text-muted mj-small" x-text="record.ttl ? record.ttl + 's' : '3600s'"></td>
                                <!-- Value -->
                                <td style="font-family:monospace; word-break:break-all; max-width:260px;">
                                    <span x-text="record.value"></span>
                                    <template x-if="record.priority">
                                        <span class="mj-text-muted mj-small"> (priority: <span x-text="record.priority"></span>)</span>
                                    </template>
                                </td>
                                <!-- Lock / System -->
                                <td>
                                    <div class="mj-d-flex mj-align-items-center" style="gap:6px; flex-wrap:wrap;">
                                        <template x-if="record.is_system">
                                            <span style="font-size:.65rem; padding:2px 6px; background:#343a40; color:#fff; border-radius:4px;">
                                                <i class="bi bi-gear-fill"></i> SYS
                                            </span>
                                        </template>
                                        <label class="mj-d-flex mj-align-items-center mj-gap-1" style="cursor:pointer; user-select:none; font-size:14px;" title="Khóa không cho Client sửa">
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
                                <td class="mj-text-end mj-pe-3">
                                    <template x-if="!record.pending_delete">
                                        <div class="mj-d-flex mj-justify-content-end" style="gap:4px;">
                                            <button class="mj-btn mj-btn-sm mj-btn-outline-secondary" @click="openEditModal(record)" title="Sửa">
                                                <i class="bi bi-pencil"></i>
                                            </button>
                                            <button class="mj-btn mj-btn-sm mj-btn-outline-danger" @click="deleteRecord(record)" title="Xóa">
                                                <i class="bi bi-trash"></i>
                                            </button>
                                        </div>
                                    </template>
                                    <template x-if="record.pending_delete">
                                        <span class="mj-text-muted" style="font-size:14px; font-style:italic;">
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
    var _adminRecords  = {$recordsJson|default:'[]'};
    var _mjDnsDomainName = "{$domain.domain|escape:'javascript'}";
    var _mjDnsDomainId   = {$domainId|default:0};
    var _mjDnsModuleLink = "{$modulelink|escape:'javascript'}";
    var _mjDnsCsrfToken  = "{$token|escape:'javascript'}";
</script>
<script>
{literal}
document.addEventListener('alpine:init', () => {

    // ── Helper fetch admin AJAX ──────────────────────────────────────────
    async function adminAjax(method, body) {
        // Gửi token qua body để WHMCS admin verify (addonmodules.php tự check session)
        var payload = Object.assign({}, body, { token: _mjDnsCsrfToken });

        var res = await fetch(_mjDnsModuleLink + '&action=ajax&method=' + method, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(payload)
        });
        return await res.json();
    }

    // ── recordModal: override submitRecord để gọi API thật ──────────────
    // Ghi đè component gốc từ record_modal.tpl
    Alpine.data('recordModal', () => ({
        open: false,
        isEdit: false,
        submitting: false,
        form: { type: '', name: '@', ttl: '3600', value: '', priority: 10, weight: 20, port: 443, caa_tag: 'issue' },
        errors: {},

        openModal(detail) {
            this.errors = {};
            this.submitting = false;
            this.isEdit = !!detail.isEdit;
            if (detail.isEdit && detail.record) {
                var r = detail.record;
                this.form = {
                    id: r.id,
                    type: r.type || '',
                    name: r.name || '@',
                    ttl: String(r.ttl || 3600),
                    value: r.value || '',
                    priority: r.priority || 10,
                    weight: r.weight || 20,
                    port: r.port || 443,
                    caa_tag: r.caa_tag || 'issue'
                };
            } else {
                this.form = { type: detail.prefillType || '', name: '@', ttl: '3600', value: '', priority: 10, weight: 20, port: 443, caa_tag: 'issue' };
            }
            this.open = true;
            document.body.style.overflow = 'hidden';
        },

        close() {
            if (this.submitting) return;
            this.open = false;
            document.body.style.overflow = '';
        },

        validate() {
            this.errors = {};
            if (!this.form.type)  { this.errors.type  = 'Vui lòng chọn loại bản ghi.'; }
            if (!this.form.name || this.form.name.trim() === '')  { this.errors.name  = 'Tên không được trống.'; }
            if (!this.form.value || this.form.value.trim() === '') { this.errors.value = 'Giá trị không được trống.'; }
            return Object.keys(this.errors).length === 0;
        },

        async submitRecord() {
            if (!this.validate()) return;
            this.submitting = true;

            try {
                var method = this.isEdit ? 'adminEditRecord' : 'adminAddRecord';
                var payload = {
                    domain_id: _mjDnsDomainId,
                    type:      this.form.type,
                    name:      this.form.name,
                    value:     this.form.value,
                    ttl:       parseInt(this.form.ttl) || 3600,
                    priority:  this.form.priority,
                    weight:    this.form.weight,
                    port:      this.form.port,
                };
                if (this.isEdit) {
                    payload.record_id = this.form.id;
                }

                var data = await adminAjax(method, payload);

                if (!data.success) {
                    this.errors.general = (data.error && data.error.message) ? data.error.message : 'Lỗi không xác định';
                    this.submitting = false;
                    return;
                }

                window.dispatchEvent(new CustomEvent('record-saved', {
                    detail: {
                        isEdit:    this.isEdit,
                        record_id: data.data ? data.data.record_id : null,
                        record:    { ...this.form, id: this.isEdit ? this.form.id : (data.data ? data.data.record_id : Date.now()), sync_status: 'syncing' }
                    }
                }));

                this.submitting = false;
                this.close();
            } catch (e) {
                this.errors.general = 'Lỗi kết nối. Vui lòng thử lại.';
                this.submitting = false;
            }
        }
    }));

    // ── adminDnsEditor ───────────────────────────────────────────────────
    Alpine.data('adminDnsEditor', () => ({
        searchQuery: '',
        records: _adminRecords,
        expandedGroups: ['A', 'MX', 'CNAME', 'TXT', 'SRV', 'NS', 'CAA', 'AAAA'],
        _typeOrder: ['A', 'AAAA', 'CNAME', 'MX', 'TXT', 'NS', 'SRV', 'CAA'],

        init() {
            // Lắng nghe event record-saved từ modal
            var self = this;
            window.addEventListener('record-saved', function(e) {
                var d = e.detail;
                if (d.isEdit) {
                    // Cập nhật record hiện có
                    for (var i = 0; i < self.records.length; i++) {
                        if (self.records[i].id === d.record.id) {
                            self.records[i] = Object.assign({}, self.records[i], d.record, { sync_status: 'syncing' });
                            break;
                        }
                    }
                } else {
                    // Thêm record mới
                    self.records.unshift(Object.assign({ is_system: false, is_locked: false, pending_delete: false }, d.record));
                }
            });
        },

        get filteredRecords() {
            if (!this.searchQuery) return this.records;
            var text = this.searchQuery.toLowerCase();
            return this.records.filter(function(r) {
                return r.name.toLowerCase().indexOf(text) >= 0
                    || r.value.toLowerCase().indexOf(text) >= 0
                    || r.type.toLowerCase().indexOf(text) >= 0;
            });
        },

        get recordsByType() {
            var map = {};
            this.filteredRecords.forEach(function(r) {
                if (!map[r.type]) map[r.type] = [];
                map[r.type].push(r);
            });
            var self = this;
            var known = this._typeOrder.filter(function(t) { return map[t]; });
            var others = Object.keys(map).filter(function(t) { return self._typeOrder.indexOf(t) < 0; }).sort();
            return known.concat(others).map(function(type) { return { type: type, records: map[type] }; });
        },

        toggleGroup(type) {
            var idx = this.expandedGroups.indexOf(type);
            if (idx >= 0) { this.expandedGroups.splice(idx, 1); }
            else { this.expandedGroups.push(type); }
        },

        typeColor(type) {
            var c = { A:'#0d6efd', AAAA:'#6610f2', CNAME:'#20c997', MX:'#fd7e14', TXT:'#6f42c1', NS:'#6c757d', SRV:'#0dcaf0', CAA:'#dc3545' };
            return c[type] || '#495057';
        },

        typeLabel(type) {
            var l = { A:'IPv4 Address', AAAA:'IPv6 Address', CNAME:'Canonical Name', MX:'Mail Exchange', TXT:'Text Record', NS:'Name Server', SRV:'Service Record', CAA:'CA Authorization' };
            return l[type] || type + ' Record';
        },

        openAddModal(prefillType) {
            window.dispatchEvent(new CustomEvent('open-record-modal', {
                detail: { isEdit: false, prefillType: prefillType || '' }
            }));
        },

        openEditModal(record) {
            window.dispatchEvent(new CustomEvent('open-record-modal', {
                detail: { isEdit: true, record: record }
            }));
        },

        takeSnapshot() {
            window._mjDnsToast('info', 'Snapshot', 'Đang tạo Snapshot thủ công...');
        },

        async deleteRecord(record) {
            var ok = await window._mjDnsConfirm({
                title:        'Xóa bản ghi?',
                message:      'Admin: Xóa vĩnh viễn bản ghi ' + record.type + ' ' + record.name + '?\nViệc xóa trực tiếp sẽ override cả cấu hình đang pending của Client.',
                variant:      'danger',
                confirmLabel: 'Xóa vĩnh viễn',
                cancelLabel:  'Hủy'
            });
            if (!ok) return;
            
            record.pending_delete = true;

            var data = await adminAjax('adminDeleteRecord', {
                domain_id: _mjDnsDomainId,
                record_id: record.id
            });

            if (data.success) {
                // Đánh dấu pending_delete, polling sẽ tự xóa sau khi COMPLETE
                // Hoặc xóa ngay khỏi UI
                var self = this;
                setTimeout(function() {
                    self.records = self.records.filter(function(r) { return r.id !== record.id; });
                }, 1500);
            } else {
                record.pending_delete = false;
                window._mjDnsToast('error', 'Lỗi', data.error?.message || 'Không xác định');
            }
        },

        async toggleLock(record) {
            var data = await adminAjax('adminToggleLock', {
                record_id: record.id,
                is_locked: record.is_locked
            });

            if (!data.success) {
                // Revert nếu lỗi
                record.is_locked = !record.is_locked;
                window._mjDnsToast('error', 'Lỗi đổi trạng thái', data.error?.message || 'Không xác định');
            } else {
                window._mjDnsToast('success', 'Thành công', 'Đã lưu trạng thái Lock bản ghi.');
            }
        }
    }));
});
{/literal}
</script>
{/if}
