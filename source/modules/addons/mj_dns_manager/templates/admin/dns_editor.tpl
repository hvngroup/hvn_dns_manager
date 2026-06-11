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
{* JS logic moved to assets/js/mj-dns.js (MJ standard §8) *}
{/if}
