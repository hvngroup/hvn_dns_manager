<div class="hvn-dns-admin hvn-drift-reports" x-data="driftManager()">

    <!-- Header -->
    <div class="hvn-d-flex hvn-justify-content-between hvn-align-items-center hvn-mb-4">
        <h2><i class="bi bi-arrow-left-right"></i> Báo cáo Lệch Dữ liệu <span class="hvn-badge" x-show="pendingCount > 0" x-text="pendingCount + ' lệch'"></span></h2>
        <div class="hvn-d-flex" style="gap:8px;">
            <button class="hvn-btn hvn-btn-outline-secondary" @click="runScan()" :disabled="scanning">
                <span x-show="scanning" class="spinner-border spinner-border-sm hvn-me-1"></span>
                <i x-show="!scanning" class="bi bi-search hvn-me-1"></i>
                <span x-show="!scanning" x-text="filterDomain ? 'Quét: ' + filterDomain : 'Quét tất cả'"></span>
                <span x-show="scanning">Đang quét...</span>
            </button>
            <a href="{$modulelink}&action=drift_settings" class="hvn-btn hvn-btn-primary">
                <i class="bi bi-gear"></i> Cài đặt Auto-fix
            </a>
        </div>
    </div>

    <!-- Scan info bar -->
    <div class="hvn-card hvn-border-0 hvn-shadow-sm hvn-mb-3" style="background:#f8fafc;">
        <div class="hvn-card-body hvn-py-2 hvn-d-flex hvn-justify-content-between hvn-align-items-center">
            <div class="small hvn-text-muted hvn-d-flex hvn-align-items-center" style="gap:16px;">
                <span><i class="bi bi-clock-history"></i> Lần quét gần nhất: <strong class="hvn-text-dark">{$driftLastRun}</strong></span>
                <span><i class="bi bi-calendar-event"></i> Kế tiếp: <strong class="hvn-text-dark">{$driftNextRun}</strong></span>
            </div>
            <div class="small hvn-text-muted">
                <i class="bi bi-database hvn-text-primary"></i> WHMCS là <strong>Source of Truth</strong> — dữ liệu trên WHMCS được ưu tiên khi có xung đột.
            </div>
        </div>
    </div>

    <!-- Alert banner -->
    <div x-show="pendingCount > 0" x-transition
         class="alert hvn-d-flex hvn-align-items-center hvn-mb-3"
         style="background:#fef3c7; border-left:4px solid #f59e0b; border-radius:8px;">
        <i class="bi bi-exclamation-triangle-fill hvn-me-3 fs-4" style="color:#d97706;"></i>
        <div>
            <strong style="color:#92400e;">Phát hiện <span x-text="pendingCount"></span> bản ghi sai lệch</strong>
            trên <span x-text="new Set(rows.filter(r=>r.status==='pending').map(r=>r.domain)).size"></span> domain.
            Dữ liệu DirectAdmin đang khác với WHMCS DB.
        </div>
    </div>

    <!-- ── Filter & Sort Bar ──────────────────────────────── -->
    <div class="hvn-card hvn-border-0 hvn-shadow-sm hvn-mb-3">
        <div class="hvn-card-body hvn-py-3">
            <div class="row g-2 hvn-align-items-end">
                <div class="col-12 col-sm-4 col-md-3">
                    <label class="small hvn-text-muted hvn-fw-bold hvn-d-block hvn-mb-1"><i class="bi bi-search"></i> Tìm domain</label>
                    <input type="text" class="form-control form-control-sm" x-model="filterDomain" placeholder="example.com...">
                </div>
                <div class="col-6 col-sm-4 col-md-2">
                    <label class="small hvn-text-muted hvn-fw-bold hvn-d-block hvn-mb-1"><i class="bi bi-funnel"></i> Loại lỗi</label>
                    <select class="form-select form-select-sm" x-model="filterType">
                        <option value="">Tất cả</option>
                        <option value="added_on_da">added_on_da</option>
                        <option value="missing_on_da">missing_on_da</option>
                        <option value="modified">modified</option>
                    </select>
                </div>
                <div class="col-6 col-sm-4 col-md-2">
                    <label class="small hvn-text-muted hvn-fw-bold hvn-d-block hvn-mb-1"><i class="bi bi-circle-half"></i> Trạng thái</label>
                    <select class="form-select form-select-sm" x-model="filterStatus">
                        <option value="">Tất cả</option>
                        <option value="pending">Pending</option>
                        <option value="resolved">Resolved</option>
                        <option value="ignored">Ignored</option>
                    </select>
                </div>
                <div class="col-6 col-sm-4 col-md-2">
                    <label class="small hvn-text-muted hvn-fw-bold hvn-d-block hvn-mb-1"><i class="bi bi-tag"></i> Record type</label>
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
                    <label class="small hvn-text-muted hvn-fw-bold hvn-d-block hvn-mb-1"><i class="bi bi-sort-down"></i> Sắp xếp</label>
                    <select class="form-select form-select-sm" x-model="sortPreset" @change="applyPreset()">
                        <option value="">Tuỳ chỉnh</option>
                        <option value="domain_asc">Domain A→Z</option>
                        <option value="domain_desc">Domain Z→A</option>
                        <option value="type_asc">Loại lỗi A→Z</option>
                        <option value="severity_desc">Nghiêm trọng nhất</option>
                    </select>
                </div>
                <div class="col-12 col-md-1 hvn-d-flex hvn-align-items-end">
                    <button class="hvn-btn hvn-btn-outline-secondary btn-sm w-100" @click="resetFilters()" title="Xoá bộ lọc">
                        <i class="bi bi-x-lg"></i> Reset
                    </button>
                </div>
            </div>
        </div>
    </div>

    <!-- ── Main Table ─────────────────────────────────────── -->
    <div class="hvn-card hvn-border-0 hvn-shadow-sm">
        <div class="hvn-card-body hvn-p-0">
            <div class="table-responsive">
                <table class="table table-hover align-middle hvn-mb-0" style="font-size:13px;">
                    <thead class="table-dark">
                        <tr>
                            <!-- Domain col -->
                            <th class="hvn-ps-4" style="width:18%; cursor:pointer;" @click="toggleSort('domain')">
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
                            <th class="text-center hvn-pe-4" style="width:6%;">Hành động</th>
                        </tr>
                    </thead>
                    <tbody>
                        <template x-for="row in pagedRows" :key="row.id">
                            <tr :class="row.status === 'resolved' ? 'opacity-50' : (row.status === 'ignored' ? 'table-secondary' : '')">

                                <!-- Domain -->
                                <td class="hvn-ps-4">
                                    <div class="hvn-fw-bold hvn-text-dark" x-text="row.domain"></div>
                                    <div class="small hvn-text-muted font-monospace" x-text="'#' + row.domain_id"></div>
                                </td>

                                <!-- Loại lỗi badge -->
                                <td>
                                    <template x-if="row.type === 'added_on_da'">
                                        <span class="hvn-badge" style="background:#dbeafe; color:#1d4ed8;">
                                            <i class="bi bi-patch-plus-fill"></i> added_on_da
                                        </span>
                                    </template>
                                    <template x-if="row.type === 'missing_on_da'">
                                        <span class="hvn-badge" style="background:#fee2e2; color:#b91c1c;">
                                            <i class="bi bi-patch-minus-fill"></i> missing_on_da
                                        </span>
                                    </template>
                                    <template x-if="row.type === 'modified'">
                                        <span class="hvn-badge" style="background:#fef9c3; color:#92400e;">
                                            <i class="bi bi-patch-exclamation-fill"></i> modified
                                        </span>
                                    </template>
                                </td>

                                <!-- Record type + name -->
                                <td>
                                    <span class="hvn-badge hvn-bg-secondary font-monospace hvn-me-1" x-text="row.record_type"></span>
                                    <code class="small" x-text="row.record_name"></code>
                                </td>

                                <!-- WHMCS Val -->
                                <td class="text-break" style="max-width:200px;">
                                    <template x-if="row.whmcs_val">
                                        <code class="small" style="word-break:break-all; color:#1d4ed8;" x-text="row.whmcs_val"></code>
                                    </template>
                                    <template x-if="!row.whmcs_val">
                                        <span class="small hvn-text-muted fst-italic">(Không tồn tại)</span>
                                    </template>
                                </td>

                                <!-- DA Val -->
                                <td class="text-break" style="max-width:200px;">
                                    <template x-if="row.da_val">
                                        <code class="small" style="word-break:break-all; color:#6b7280;" x-text="row.da_val"></code>
                                    </template>
                                    <template x-if="!row.da_val">
                                        <span class="small hvn-text-muted fst-italic">(Không tồn tại)</span>
                                    </template>
                                </td>

                                <!-- Status -->
                                <td class="text-center">
                                    <template x-if="row.status === 'pending'">
                                        <span class="hvn-badge" style="background:#fde68a; color:#92400e;">● Pending</span>
                                    </template>
                                    <template x-if="row.status === 'resolved'">
                                        <span class="hvn-badge hvn-bg-success">✓ Resolved</span>
                                    </template>
                                    <template x-if="row.status === 'ignored'">
                                        <span class="hvn-badge hvn-bg-secondary">— Ignored</span>
                                    </template>
                                </td>

                                <!-- Action buttons -->
                                <td class="text-center hvn-pe-4">
                                    <div x-show="row.status === 'pending'" class="hvn-d-flex hvn-justify-content-center" style="gap:4px; flex-wrap:nowrap;">
                                        <!-- added_on_da: Pull hoặc Xóa DA -->
                                        <template x-if="row.type === 'added_on_da'">
                                            <span class="hvn-d-flex" style="gap:4px;">
                                                <button class="hvn-btn btn-sm hvn-btn-outline-primary" @click="resolve(row, 'pull')" title="Pull: Lấy về WHMCS">
                                                    <i class="bi bi-box-arrow-in-down"></i>
                                                </button>
                                                <button class="hvn-btn btn-sm btn-outline-danger" @click="resolve(row, 'delete_da')" title="Xóa trên DA">
                                                    <i class="bi bi-trash"></i>
                                                </button>
                                            </span>
                                        </template>
                                        <!-- missing_on_da: Push hoặc Xóa WHMCS -->
                                        <template x-if="row.type === 'missing_on_da'">
                                            <span class="hvn-d-flex" style="gap:4px;">
                                                <button class="hvn-btn btn-sm btn-outline-success" @click="resolve(row, 'push')" title="Push: Đẩy lên DA">
                                                    <i class="bi bi-box-arrow-up"></i>
                                                </button>
                                                <button class="hvn-btn btn-sm btn-outline-danger" @click="resolve(row, 'delete_whmcs')" title="Xóa trong WHMCS">
                                                    <i class="bi bi-trash"></i>
                                                </button>
                                            </span>
                                        </template>
                                        <!-- modified: Pull hoặc Push -->
                                        <template x-if="row.type === 'modified'">
                                            <span class="hvn-d-flex" style="gap:4px;">
                                                <button class="hvn-btn btn-sm hvn-btn-outline-primary" @click="resolve(row, 'pull')" title="Pull từ DA">
                                                    <i class="bi bi-box-arrow-in-down"></i>
                                                </button>
                                                <button class="hvn-btn btn-sm btn-outline-success" @click="resolve(row, 'push')" title="Push từ WHMCS">
                                                    <i class="bi bi-box-arrow-up"></i>
                                                </button>
                                            </span>
                                        </template>
                                        <!-- Ignore (tất cả loại) -->
                                        <button class="hvn-btn btn-sm btn-outline-secondary" @click="resolve(row, 'ignore')" title="Bỏ qua">
                                            <i class="bi bi-eye-slash"></i>
                                        </button>
                                    </div>
                                    <!-- Status đã xử lý -->
                                    <span x-show="row.status !== 'pending'" class="small hvn-text-muted">—</span>
                                </td>
                            </tr>
                        </template>

                        <!-- Empty state -->
                        <tr x-show="pagedRows.length === 0">
                            <td colspan="7" class="text-center hvn-py-5 hvn-text-muted">
                                <i class="bi bi-shield-check display-4 hvn-d-block hvn-mb-3" style="color:#4ade80; opacity:.7;"></i>
                                <strong class="hvn-d-block hvn-mb-1">Không có dữ liệu lệch nào</strong>
                                <span class="small">Thay đổi bộ lọc hoặc chạy quét thủ công để kiểm tra.</span>
                            </td>
                        </tr>
                    </tbody>
                </table>
            </div>
        </div>

        <!-- Footer: count + pagination -->
        <div class="hvn-card-footer hvn-bg-light hvn-d-flex hvn-justify-content-between hvn-align-items-center hvn-py-2 hvn-px-4">
            <div class="small hvn-text-muted">
                Hiển thị
                <strong x-text="filteredRows.length === 0 ? 0 : (currentPage - 1) * perPage + 1"></strong>–<strong x-text="Math.min(currentPage * perPage, filteredRows.length)"></strong>
                / <strong x-text="filteredRows.length"></strong> bản ghi lệch
            </div>
            <div class="hvn-d-flex" style="gap:4px;" x-show="totalPages > 1">
                <button class="hvn-btn btn-sm hvn-btn-outline-secondary" @click="currentPage--" :disabled="currentPage <= 1">‹</button>
                <template x-for="p in totalPages" :key="p">
                    <button class="hvn-btn btn-sm"
                            :class="p === currentPage ? 'hvn-btn-primary' : 'hvn-btn-outline-secondary'"
                            @click="currentPage = p" x-text="p"></button>
                </template>
                <button class="hvn-btn btn-sm hvn-btn-outline-secondary" @click="currentPage++" :disabled="currentPage >= totalPages">›</button>
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
    var _hvnDriftRows = {$driftReportsJson};
    var _hvnModuleLink = "{$modulelink|escape:'javascript'}";
</script>
<script>
{literal}
document.addEventListener('alpine:init', () => {
    Alpine.data('driftManager', () => ({
        // ── Filters ────────────────────────────
        filterDomain:     '',
        filterType:       '',
        filterStatus:     'pending',
        filterRecordType: '',
        sortPreset:       '',

        // ── Sort state ─────────────────────────
        sortCol: 'domain',
        sortDir: 'asc',   // 'asc' | 'desc'

        // ── Pagination ─────────────────────────
        currentPage: 1,
        perPage: 20,

        // ── Loading ────────────────────────────
        scanning: false,

        // ── Mock data ──────────────────────────
        // Flat rows: mỗi row là 1 bản ghi lệch độc lập
        rows: _hvnDriftRows,

        // ── Computed ────────────────────────────
        get pendingCount() {
            return this.rows.filter(r => r.status === 'pending').length;
        },

        get filteredRows() {
            let result = this.rows.filter(r => {
                if (this.filterDomain && !r.domain.toLowerCase().includes(this.filterDomain.toLowerCase())) return false;
                if (this.filterType   && r.type        !== this.filterType)       return false;
                if (this.filterStatus && r.status      !== this.filterStatus)     return false;
                if (this.filterRecordType && r.record_type !== this.filterRecordType) return false;
                return true;
            });

            // Sort
            result = result.sort((a, b) => {
                const va = (a[this.sortCol] ?? '').toString().toLowerCase();
                const vb = (b[this.sortCol] ?? '').toString().toLowerCase();
                const cmp = va < vb ? -1 : va > vb ? 1 : 0;
                return this.sortDir === 'asc' ? cmp : -cmp;
            });

            return result;
        },

        get totalPages() {
            return Math.max(1, Math.ceil(this.filteredRows.length / this.perPage));
        },

        get pagedRows() {
            const start = (this.currentPage - 1) * this.perPage;
            return this.filteredRows.slice(start, start + this.perPage);
        },

        // ── Sort helpers ────────────────────────
        toggleSort(col) {
            if (this.sortCol === col) {
                this.sortDir = this.sortDir === 'asc' ? 'desc' : 'asc';
            } else {
                this.sortCol = col;
                this.sortDir = 'asc';
            }
            this.sortPreset = '';
            this.currentPage = 1;
        },

        sortIcon(col) {
            if (this.sortCol !== col) return 'bi-chevron-expand text-secondary opacity-50';
            return this.sortDir === 'asc' ? 'bi-chevron-up' : 'bi-chevron-down';
        },

        applyPreset() {
            const presets = {
                'domain_asc':      { col: 'domain',      dir: 'asc'  },
                'domain_desc':     { col: 'domain',      dir: 'desc' },
                'type_asc':        { col: 'type',        dir: 'asc'  },
                'severity_desc':   { col: 'type',        dir: 'desc' },
            };
            if (presets[this.sortPreset]) {
                this.sortCol = presets[this.sortPreset].col;
                this.sortDir = presets[this.sortPreset].dir;
                this.currentPage = 1;
            }
        },

        resetFilters() {
            this.filterDomain     = '';
            this.filterType       = '';
            this.filterStatus     = 'pending';
            this.filterRecordType = '';
            this.sortCol          = 'domain';
            this.sortDir          = 'asc';
            this.sortPreset       = '';
            this.currentPage      = 1;
        },

        // ── Actions ─────────────────────────────
        async resolve(row, action) {
            const labels = {
                push:          'push',
                pull:          'pull',
                delete_da:     'xóa trên DA',
                delete_whmcs:  'xóa trong WHMCS',
                ignore:        'bỏ qua',
            };
            const msgs = {
                push:         `Push: Ghi đè DA bằng WHMCS cho ${row.record_type} ${row.record_name} (${row.domain})?`,
                pull:         `Pull: Lấy dữ liệu ${row.record_type} ${row.record_name} từ DA cập nhật vào WHMCS?`,
                delete_da:    `XÓA bản ghi ${row.record_type} ${row.record_name} trên DirectAdmin?`,
                delete_whmcs: `XÓA bản ghi ${row.record_type} ${row.record_name} trong CSDL WHMCS?`,
                ignore:       `Bỏ qua cảnh báo ${row.record_type} ${row.record_name} tới lần quét sau?`,
            };

            var ok = await window._hvnConfirm({
                title:        'Xác nhận hành động',
                message:      msgs[action] || 'Xác nhận xử lý bản ghi này?',
                variant:      (action === 'delete_da' || action === 'delete_whmcs') ? 'danger' : 'warning',
                confirmLabel: 'Xác nhận',
                cancelLabel:  'Hủy'
            });
            if (!ok) return;

            // Hiển thị trạng thái đang xử lý
            const originalStatus = row.status;
            row._resolving = true;

            try {
                const res = await fetch(_hvnModuleLink + '&action=ajax', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({
                        method:   'resolveDrift',
                        drift_id: row.id,
                        action:   action,
                    }),
                });

                const data = await res.json();

                if (data.success) {
                    // Cập nhật status trực tiếp trên row — không cần reload
                    row.status = (action === 'ignore') ? 'ignored' : 'resolved';
                    row._resolving = false;

                    window._hvnToast('success', 'Thành công', data.message || 'Đã xử lý thành công.');
                } else {
                    row.status     = originalStatus;
                    row._resolving = false;
                    window._hvnToast('error', 'Lỗi xử lý', data.error || 'Không xác định');
                }

            } catch (e) {
                row.status     = originalStatus;
                row._resolving = false;
                window._hvnToast('error', 'Lỗi mạng', e.message);
            }
        },

        async runScan() {
            this.scanning = true;

            try {
                var url = _hvnModuleLink + '&action=ajax';
                var body = {};

                if (this.filterDomain) {
                    // Scan 1 domain cụ thể — tìm domain_id từ rows hiện có
                    var domainRow = this.rows.find(function(r) {
                        return r.domain === this.filterDomain;
                    }.bind(this));

                    if (!domainRow) {
                        // Không tìm thấy domain_id trong rows hiện tại — vẫn gửi tên domain
                        // Controller sẽ tự tìm
                        body = { method: 'runDriftScanByName', domain: this.filterDomain };
                    } else {
                        body = { method: 'runDriftCheck', domain_id: domainRow.domain_id };
                    }
                } else {
                    // Scan toàn bộ hệ thống
                    body = { method: 'runDriftScanAll' };
                }

                var res = await fetch(url, {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify(body)
                });

                var data = await res.json();

                if (data.success) {
                    // Hiển thị toast và reload để lấy data mới
                    window._hvnToast('success', 'Quét hoàn tất', data.message || '');
                    setTimeout(() => { window.location.reload(); }, 1000);
                } else {
                    window._hvnToast('error', 'Quét thất bại', data.error || 'Lỗi không xác định');
                    this.scanning = false;
                }
            } catch (e) {
                window._hvnToast('error', 'Lỗi mạng', e.message);
                this.scanning = false;
            }
        }
    }));
});
{/literal}
</script>
