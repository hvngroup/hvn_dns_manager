<div class="mj-dns-admin mj-drift-reports" x-data="driftManager()">

    <!-- Header -->
    <div class="mj-d-flex mj-justify-content-between mj-align-items-center mj-mb-4">
        <h2><i class="bi bi-arrow-left-right"></i> Báo cáo Lệch Dữ liệu <span class="mj-badge" x-show="pendingCount > 0" x-text="pendingCount + ' lệch'"></span></h2>
        <div class="mj-d-flex" style="gap:8px;">
            <button class="mj-btn mj-btn-outline-secondary" @click="runScan()" :disabled="scanning">
                <span x-show="scanning" class="spinner-border spinner-border-sm mj-me-1"></span>
                <i x-show="!scanning" class="bi bi-search mj-me-1"></i>
                <span x-show="!scanning" x-text="filterDomain ? 'Quét: ' + filterDomain : 'Quét tất cả'"></span>
                <span x-show="scanning">Đang quét...</span>
            </button>
            <a href="{$modulelink}&action=drift_settings" class="mj-btn mj-btn-primary">
                <i class="bi bi-gear"></i> Cài đặt Auto-fix
            </a>
        </div>
    </div>

    <!-- Scan info bar -->
    <div class="mj-card mj-border-0 mj-shadow-sm mj-mb-3" style="background:#f8fafc;">
        <div class="mj-card-body mj-py-2 mj-d-flex mj-justify-content-between mj-align-items-center">
            <div class="small mj-text-muted mj-d-flex mj-align-items-center" style="gap:16px;">
                <span><i class="bi bi-clock-history"></i> Lần quét gần nhất: <strong class="mj-text-dark">{$driftLastRun}</strong></span>
                <span><i class="bi bi-calendar-event"></i> Kế tiếp: <strong class="mj-text-dark">{$driftNextRun}</strong></span>
            </div>
            <div class="small mj-text-muted">
                <i class="bi bi-database mj-text-primary"></i> WHMCS là <strong>Source of Truth</strong> — dữ liệu trên WHMCS được ưu tiên khi có xung đột.
            </div>
        </div>
    </div>

    <!-- Alert banner -->
    <div x-show="pendingCount > 0" x-transition
         class="alert mj-d-flex mj-align-items-center mj-mb-3"
         style="background:#fef3c7; border-left:4px solid #f59e0b; border-radius:8px;">
        <i class="bi bi-exclamation-triangle-fill mj-me-3 fs-4" style="color:#d97706;"></i>
        <div>
            <strong style="color:#92400e;">Phát hiện <span x-text="pendingCount"></span> bản ghi sai lệch</strong>
            trên <span x-text="new Set(rows.filter(r=>r.status==='pending').map(r=>r.domain)).size"></span> domain.
            Dữ liệu DirectAdmin đang khác với WHMCS DB.
        </div>
    </div>

    <!-- ── Filter & Sort Bar ──────────────────────────────── -->
    <div class="mj-card mj-border-0 mj-shadow-sm mj-mb-3">
        <div class="mj-card-body mj-py-3">
            <div class="row g-2 mj-align-items-end">
                <div class="col-12 col-sm-4 col-md-3">
                    <label class="small mj-text-muted mj-fw-bold mj-d-block mj-mb-1"><i class="bi bi-search"></i> Tìm domain</label>
                    <input type="text" class="form-control form-control-sm" x-model="filterDomain" placeholder="example.com...">
                </div>
                <div class="col-6 col-sm-4 col-md-2">
                    <label class="small mj-text-muted mj-fw-bold mj-d-block mj-mb-1"><i class="bi bi-funnel"></i> Loại lỗi</label>
                    <select class="form-select form-select-sm" x-model="filterType">
                        <option value="">Tất cả</option>
                        <option value="added_on_da">added_on_da</option>
                        <option value="missing_on_da">missing_on_da</option>
                        <option value="modified">modified</option>
                    </select>
                </div>
                <div class="col-6 col-sm-4 col-md-2">
                    <label class="small mj-text-muted mj-fw-bold mj-d-block mj-mb-1"><i class="bi bi-circle-half"></i> Trạng thái</label>
                    <select class="form-select form-select-sm" x-model="filterStatus">
                        <option value="">Tất cả</option>
                        <option value="pending">Pending</option>
                        <option value="resolved">Resolved</option>
                        <option value="ignored">Ignored</option>
                    </select>
                </div>
                <div class="col-6 col-sm-4 col-md-2">
                    <label class="small mj-text-muted mj-fw-bold mj-d-block mj-mb-1"><i class="bi bi-tag"></i> Record type</label>
                    <select class="form-select form-select-sm" x-model="filterRecordType">
                        <option value="">Tất cả</option>
                        <option value="A">A</option>
                        <option value="AAAA">AAAA</option>
                        <option value="CNAME">CNAME</option>
                        <option value="MX">MX</option>
                        <option value="TXT">TXT</option>
                        <option value="SRV">SRV</option>
                        <option value="NS">NS</option>
                        <option value="CAA">CAA</option>
                    </select>
                </div>
                <div class="col-6 col-sm-4 col-md-2">
                    <label class="small mj-text-muted mj-fw-bold mj-d-block mj-mb-1"><i class="bi bi-sort-down"></i> Sắp xếp</label>
                    <select class="form-select form-select-sm" x-model="sortPreset" @change="applyPreset()">
                        <option value="">Tuỳ chỉnh</option>
                        <option value="domain_asc">Domain A→Z</option>
                        <option value="domain_desc">Domain Z→A</option>
                        <option value="type_asc">Loại lỗi A→Z</option>
                        <option value="severity_desc">Nghiêm trọng nhất</option>
                    </select>
                </div>
                <div class="col-12 col-md-1 mj-d-flex mj-align-items-end">
                    <button class="mj-btn mj-btn-outline-secondary btn-sm w-100" @click="resetFilters()" title="Xoá bộ lọc">
                        <i class="bi bi-x-lg"></i> Reset
                    </button>
                </div>
            </div>
        </div>
    </div>

    <!-- ── Main Table ─────────────────────────────────────── -->
    <div class="mj-card mj-border-0 mj-shadow-sm">
        <div class="mj-card-body mj-p-0">
            <div class="table-responsive">
                <table class="table table-hover align-middle mj-mb-0" style="font-size:13px;">
                    <thead class="table-dark">
                        <tr>
                            <!-- Domain col -->
                            <th class="mj-ps-4" style="width:18%; cursor:pointer;" @click="toggleSort('domain')">
                                <span>Domain</span>
                                <i class="bi" :class="sortIcon('domain')"></i>
                            </th>
                            <!-- Loại lỗi -->
                            <th style="width:14%; cursor:pointer;" @click="toggleSort('type')">
                                <span>Loại lỗi</span>
                                <i class="bi" :class="sortIcon('type')"></i>
                            </th>
                            <!-- Record -->
                            <th style="width:10%; cursor:pointer;" @click="toggleSort('record_type')">
                                <span>Record</span>
                                <i class="bi" :class="sortIcon('record_type')"></i>
                            </th>
                            <!-- WHMCS Data -->
                            <th style="width:22%; cursor:pointer;" @click="toggleSort('whmcs_val')">
                                <i class="bi bi-database" style="color:#60a5fa;"></i>
                                <span>Dữ liệu WHMCS</span>
                                <i class="bi" :class="sortIcon('whmcs_val')"></i>
                            </th>
                            <!-- DA Data -->
                            <th style="width:22%;">
                                <i class="bi bi-server" style="color:#94a3b8;"></i>
                                <span>Dữ liệu DNS Server</span>
                            </th>
                            <!-- Status -->
                            <th class="text-center" style="width:8%; cursor:pointer;" @click="toggleSort('status')">
                                <span>Trạng thái</span>
                                <i class="bi" :class="sortIcon('status')"></i>
                            </th>
                            <!-- Actions -->
                            <th class="text-center mj-pe-4" style="width:6%;">Hành động</th>
                        </tr>
                    </thead>
                    <tbody>
                        <template x-for="row in pagedRows" :key="row.id">
                            <tr :class="row.status === 'resolved' ? 'opacity-50' : (row.status === 'ignored' ? 'table-secondary' : '')">

                                <!-- Domain -->
                                <td class="mj-ps-4">
                                    <div class="mj-fw-bold mj-text-dark" x-text="row.domain"></div>
                                    <div class="small mj-text-muted font-monospace" x-text="'#' + row.domain_id"></div>
                                </td>

                                <!-- Loại lỗi badge -->
                                <td>
                                    <template x-if="row.type === 'added_on_da'">
                                        <span class="mj-badge" style="background:#dbeafe; color:#1d4ed8;">
                                            <i class="bi bi-patch-plus-fill"></i> added_on_da
                                        </span>
                                    </template>
                                    <template x-if="row.type === 'missing_on_da'">
                                        <span class="mj-badge" style="background:#fee2e2; color:#b91c1c;">
                                            <i class="bi bi-patch-minus-fill"></i> missing_on_da
                                        </span>
                                    </template>
                                    <template x-if="row.type === 'modified'">
                                        <span class="mj-badge" style="background:#fef9c3; color:#92400e;">
                                            <i class="bi bi-patch-exclamation-fill"></i> modified
                                        </span>
                                    </template>
                                </td>

                                <!-- Record type + name -->
                                <td>
                                    <span class="mj-badge mj-bg-secondary font-monospace mj-me-1" x-text="row.record_type"></span>
                                    <code class="small" x-text="row.record_name"></code>
                                </td>

                                <!-- WHMCS Val -->
                                <td class="text-break" style="max-width:200px;">
                                    <template x-if="row.whmcs_val">
                                        <code class="small" style="word-break:break-all; color:#1d4ed8;" x-text="row.whmcs_val"></code>
                                    </template>
                                    <template x-if="!row.whmcs_val">
                                        <span class="small mj-text-muted fst-italic">(Không tồn tại)</span>
                                    </template>
                                </td>

                                <!-- DA Val -->
                                <td class="text-break" style="max-width:200px;">
                                    <template x-if="row.da_val">
                                        <code class="small" style="word-break:break-all; color:#6b7280;" x-text="row.da_val"></code>
                                    </template>
                                    <template x-if="!row.da_val">
                                        <span class="small mj-text-muted fst-italic">(Không tồn tại)</span>
                                    </template>
                                </td>

                                <!-- Status -->
                                <td class="text-center">
                                    <template x-if="row.status === 'pending'">
                                        <span class="mj-badge" style="background:#fde68a; color:#92400e;">● Pending</span>
                                    </template>
                                    <template x-if="row.status === 'resolved'">
                                        <span class="mj-badge mj-bg-success">✓ Resolved</span>
                                    </template>
                                    <template x-if="row.status === 'ignored'">
                                        <span class="mj-badge mj-bg-secondary">— Ignored</span>
                                    </template>
                                </td>

                                <!-- Action buttons -->
                                <td class="text-center mj-pe-4">
                                    <div x-show="row.status === 'pending'" class="mj-d-flex mj-justify-content-center" style="gap:4px; flex-wrap:nowrap;">
                                        <!-- added_on_da: Pull hoặc Xóa DA -->
                                        <template x-if="row.type === 'added_on_da'">
                                            <span class="mj-d-flex" style="gap:4px;">
                                                <button class="mj-btn btn-sm mj-btn-outline-primary" @click="resolve(row, 'pull')" title="Pull: Lấy về WHMCS">
                                                    <i class="bi bi-box-arrow-in-down"></i>
                                                </button>
                                                <button class="mj-btn btn-sm btn-outline-danger" @click="resolve(row, 'delete_da')" title="Xóa trên DA">
                                                    <i class="bi bi-trash"></i>
                                                </button>
                                            </span>
                                        </template>
                                        <!-- missing_on_da: Push hoặc Xóa WHMCS -->
                                        <template x-if="row.type === 'missing_on_da'">
                                            <span class="mj-d-flex" style="gap:4px;">
                                                <button class="mj-btn btn-sm btn-outline-success" @click="resolve(row, 'push')" title="Push: Đẩy lên DA">
                                                    <i class="bi bi-box-arrow-up"></i>
                                                </button>
                                                <button class="mj-btn btn-sm btn-outline-danger" @click="resolve(row, 'delete_whmcs')" title="Xóa trong WHMCS">
                                                    <i class="bi bi-trash"></i>
                                                </button>
                                            </span>
                                        </template>
                                        <!-- modified: Pull hoặc Push -->
                                        <template x-if="row.type === 'modified'">
                                            <span class="mj-d-flex" style="gap:4px;">
                                                <button class="mj-btn btn-sm mj-btn-outline-primary" @click="resolve(row, 'pull')" title="Pull từ DA">
                                                    <i class="bi bi-box-arrow-in-down"></i>
                                                </button>
                                                <button class="mj-btn btn-sm btn-outline-success" @click="resolve(row, 'push')" title="Push từ WHMCS">
                                                    <i class="bi bi-box-arrow-up"></i>
                                                </button>
                                            </span>
                                        </template>
                                        <!-- Ignore (tất cả loại) -->
                                        <button class="mj-btn btn-sm btn-outline-secondary" @click="resolve(row, 'ignore')" title="Bỏ qua">
                                            <i class="bi bi-eye-slash"></i>
                                        </button>
                                    </div>
                                    <!-- Status đã xử lý -->
                                    <span x-show="row.status !== 'pending'" class="small mj-text-muted">—</span>
                                </td>
                            </tr>
                        </template>

                        <!-- Empty state -->
                        <tr x-show="pagedRows.length === 0">
                            <td colspan="7" class="text-center mj-py-5 mj-text-muted">
                                <i class="bi bi-shield-check display-4 mj-d-block mj-mb-3" style="color:#4ade80; opacity:.7;"></i>
                                <strong class="mj-d-block mj-mb-1">Không có dữ liệu lệch nào</strong>
                                <span class="small">Thay đổi bộ lọc hoặc chạy quét thủ công để kiểm tra.</span>
                            </td>
                        </tr>
                    </tbody>
                </table>
            </div>
        </div>

        <!-- Footer: count + pagination -->
        <div class="mj-card-footer mj-bg-light mj-d-flex mj-justify-content-between mj-align-items-center mj-py-2 mj-px-4">
            <div class="small mj-text-muted">
                Hiển thị
                <strong x-text="filteredRows.length === 0 ? 0 : (currentPage - 1) * perPage + 1"></strong>–<strong x-text="Math.min(currentPage * perPage, filteredRows.length)"></strong>
                / <strong x-text="filteredRows.length"></strong> bản ghi lệch
            </div>
            <div class="mj-d-flex" style="gap:4px;" x-show="totalPages > 1">
                <button class="mj-btn btn-sm mj-btn-outline-secondary" @click="currentPage--" :disabled="currentPage <= 1">‹</button>
                <template x-for="p in totalPages" :key="p">
                    <button class="mj-btn btn-sm"
                            :class="p === currentPage ? 'mj-btn-primary' : 'mj-btn-outline-secondary'"
                            @click="currentPage = p" x-text="p"></button>
                </template>
                <button class="mj-btn btn-sm mj-btn-outline-secondary" @click="currentPage++" :disabled="currentPage >= totalPages">›</button>
            </div>
            <select class="form-select form-select-sm" x-model.number="perPage" style="max-width:90px;" @change="currentPage=1">
                <option value="20">20 dòng</option>
                <option value="50">50 dòng</option>
                <option value="100">100 dòng</option>
            </select>
        </div>
    </div>

</div>

<script>
    var _mjDnsDriftRows = {$driftReportsJson};
    var _mjDnsModuleLink = "{$modulelink|escape:'javascript'}";
</script>
{* JS logic moved to assets/js/mj-dns.js (MJ standard §8) *}
