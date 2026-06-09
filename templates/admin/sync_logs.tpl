<div class="hvn-dns-admin hvn-sync-logs" x-data="syncLogsData()">
    <div class="hvn-d-flex hvn-justify-content-between hvn-align-items-center hvn-mb-4">
        <h2><i class="bi bi-journal-check"></i> Lịch sử Đồng bộ (Sync Logs)</h2>
        <div>
            <button class="hvn-btn btn-outline-success" @click="exportCsv()"><i class="bi bi-file-earmark-spreadsheet"></i> Export CSV</button>
            <button
                class="hvn-btn hvn-btn-warning hvn-ms-2"
                @click="retryAllFailed()"
                :disabled="retrying"
                x-show="failedCount > 0"
            >
                <i class="bi bi-arrow-repeat"></i>
                <span x-text="retrying ? 'Đang reset...' : 'Retry All Failed (' + failedCount + ')'"></span>
            </button>
            <button
                class="hvn-btn hvn-btn-primary hvn-ms-2"
                @click="runPendingJobs()"
                :disabled="syncing"
            ><i class="bi bi-play-circle"></i> <span x-text="syncing ? 'Đang đồng bộ...' : 'Đồng bộ Pending'"></span></button>
        </div>
    </div>

    <!-- Toolbar Filters -->
    <div class="hvn-card hvn-shadow-sm hvn-border-0 hvn-mb-4 hvn-bg-light">
        <div class="hvn-card-body hvn-py-3">
            <div class="hvn-row g-2 hvn-align-items-center">
                <div class="hvn-col-md-3">
                    <input type="text" class="hvn-form-control" placeholder="Tên miền (VD: myblog.net)..." x-model="filterDomain">
                </div>
                <div class="hvn-col-md-2">
                    <select class="hvn-form-select" x-model="filterStatus">
                        <option value="">Tất cả trạng thái</option>
                        <option value="complete">✅ Complete</option>
                        <option value="pending">🟡 Pending</option>
                        <option value="failed">❌ Failed</option>
                    </select>
                </div>
                <div class="hvn-col-md-2">
                    <select class="hvn-form-select" x-model="filterServer">
                        <option value="">Tất cả Server</option>
                        {foreach from=$serverHostnames item=hostname}
                        <option value="{$hostname|escape:'htmlall'}">{$hostname|escape:'htmlall'}</option>
                        {/foreach}
                    </select>
                </div>
                <div class="hvn-col-md-2">
                    <select class="hvn-form-select" x-model="filterAction">
                        <option value="">Tất cả Action</option>
                        <option value="ADD_RECORD">ADD_RECORD</option>
                        <option value="EDIT_RECORD">EDIT_RECORD</option>
                        <option value="DELETE_RECORD">DELETE_RECORD</option>
                        <option value="ENABLE_DNSSEC">ENABLE_DNSSEC</option>
                        <option value="APPLY_TEMPLATE">APPLY_TEMPLATE</option>
                    </select>
                </div>
                <div class="hvn-col-md-3 hvn-text-end hvn-d-flex hvn-align-items-center hvn-justify-content-end" style="gap:6px;">
                    <label class="hvn-small hvn-text-muted" style="white-space:nowrap;">Hiển:</label>
                    <select class="hvn-form-select" style="width:90px;" x-model.number="perPage">
                        <option value="100">100</option>
                        <option value="200">200</option>
                        <option value="500">500</option>
                        <option value="0">Tất cả</option>
                    </select>
                    <button class="hvn-btn hvn-btn-primary"><i class="bi bi-funnel"></i> Lọc</button>
                    <button class="hvn-btn hvn-btn-outline-secondary" @click="filterDomain=''; filterStatus=''; filterServer=''; filterAction=''; currentPage=1;"><i class="bi bi-arrow-counterclockwise"></i></button>
                </div>
            </div>
            <div class="hvn-row hvn-mt-2 g-2">
                <div class="hvn-col-md-4 hvn-d-flex hvn-align-items-center">
                    <span class="hvn-me-2 small">Từ:</span> <input type="date" class="hvn-form-control hvn-form-control-sm">
                </div>
                <div class="hvn-col-md-4 hvn-d-flex hvn-align-items-center">
                    <span class="hvn-me-2 small">Đến:</span> <input type="date" class="hvn-form-control hvn-form-control-sm">
                </div>
            </div>
        </div>
    </div>

    <!-- Main Table (full-width) -->
    <div class="hvn-card hvn-shadow-sm hvn-border-0">
        <div class="hvn-card-body hvn-p-0">
            <div class="table-responsive">
                <table class="table table-hover align-middle hvn-mb-0 font-monospace" style="font-size: 12px">
                    <thead class="table-light">
                        <tr>
                            <th class="hvn-ps-3 hvn-sortable" @click="setSort('id')">
                                ID <span x-text="sortIcon('id')"></span>
                            </th>
                            <th class="hvn-sortable" @click="setSort('time')">
                                Thời gian <span x-text="sortIcon('time')"></span>
                            </th>
                            <th class="hvn-sortable" @click="setSort('domain')">
                                Domain <span x-text="sortIcon('domain')"></span>
                            </th>
                            <th class="hvn-sortable" @click="setSort('action')">
                                Action <span x-text="sortIcon('action')"></span>
                            </th>
                            <th class="hvn-sortable" @click="setSort('server')">
                                Server <span x-text="sortIcon('server')"></span>
                            </th>
                            <th class="hvn-sortable" @click="setSort('status')">
                                Status <span x-text="sortIcon('status')"></span>
                            </th>
                            <th class="hvn-sortable" @click="setSort('ms')">
                                ms <span x-text="sortIcon('ms')"></span>
                            </th>
                            <th class="hvn-text-end hvn-pe-3"></th>
                        </tr>
                    </thead>
                    <tbody>
                        <template x-for="log in pagedLogs" :key="log.id">
                            <tr>
                                <td class="hvn-ps-3 hvn-text-muted" x-text="'#' + log.id"></td>
                                <td x-text="log.time"></td>
                                <td>
                                    <a :href="'?module=hvn_dns_manager&action=admin_dns_editor&domain_id=' + log.domain_id" x-text="log.domain"></a>
                                </td>
                                <td>
                                    <div class="hvn-fw-bold" x-text="log.action || '—'"></div>
                                    <div class="small hvn-text-muted" x-text="log.details || ''"></div>
                                </td>
                                <td x-text="log.server"></td>
                                <td>
                                    <template x-if="log.status === 'complete'"><span class="hvn-badge hvn-bg-success">✅ Complete</span></template>
                                    <template x-if="log.status === 'failed'"><span class="hvn-badge hvn-bg-danger">❌ Failed</span></template>
                                    <template x-if="log.status === 'pending'"><span class="hvn-badge hvn-bg-warning hvn-text-dark">🟡 Pending</span></template>
                                    <template x-if="log.status === 'cancelled'"><span class="hvn-badge hvn-bg-secondary">⛔ Cancelled</span></template>
                                    <div class="small hvn-text-danger" x-text="log.error_brief"></div>
                                </td>
                                <td x-text="log.ms || '--'"></td>
                                <td class="hvn-text-end hvn-pe-3">
                                    <template x-if="log.status === 'failed'">
                                        <button class="hvn-btn btn-sm btn-outline-warning hvn-me-1" @click="retryJob(log)">
                                            <i class="bi bi-arrow-repeat"></i>
                                        </button>
                                    </template>
                                    <a :href="'?module=hvn_dns_manager&action=sync_log_detail&id=' + log.id"
                                       class="hvn-btn btn-sm btn-light border text-decoration-none">
                                        <i class="bi bi-search"></i> Chi tiết
                                    </a>
                                </td>
                            </tr>
                        </template>
                    </tbody>
                </table>
            </div>
        </div>
    </div>

    <nav class="hvn-mt-3 hvn-d-flex hvn-align-items-center hvn-justify-content-between">
        <div class="hvn-small hvn-text-muted">
            Hiển <span x-text="pagedLogs.length"></span> / <span x-text="filteredLogs.length"></span> bản ghi
        </div>
        <ul class="hvn-pagination hvn-pagination-sm hvn-mb-0">
            <li class="hvn-page-item" :class="currentPage === 1 ? 'hvn-disabled' : ''">
                <a class="hvn-page-link" href="#" @click.prevent="currentPage > 1 && currentPage--">&#8592;</a>
            </li>
            <template x-for="p in totalPages" :key="p">
                <li class="hvn-page-item" :class="p === currentPage ? 'hvn-active' : ''">
                    <a class="hvn-page-link" href="#" @click.prevent="currentPage = p" x-text="p"></a>
                </li>
            </template>
            <li class="hvn-page-item" :class="currentPage === totalPages ? 'hvn-disabled' : ''">
                <a class="hvn-page-link" href="#" @click.prevent="currentPage < totalPages && currentPage++">&#8594;</a>
            </li>
        </ul>
    </nav>
</div>

<style>
{literal}
.hvn-sortable {
    cursor: pointer;
    user-select: none;
    white-space: nowrap;
}
.hvn-sortable:hover {
    background-color: rgba(0,0,0,.06);
}
.hvn-sortable span {
    font-size: 10px;
    opacity: 0.6;
    margin-left: 2px;
}
{/literal}
</style>

<script>
    var HVNDNS_SYNC_LOGS   = {$syncLogsJson};
    var HVNDNS_MODULE_LINK = '{$modulelink}';
</script>
<script>
{literal}
document.addEventListener('alpine:init', () => {
    Alpine.data('syncLogsData', () => ({
        filterDomain: '', filterStatus: '', filterServer: '', filterAction: '',
        perPage: 100,
        currentPage: 1,
        sortBy: 'id',
        sortDir: 'desc',
        syncing: false,
        retrying: false,

        allLogs: HVNDNS_SYNC_LOGS,

        get failedCount() {
            return this.allLogs.filter(function(l) {
                return l.status === 'failed';
            }).length;
        },

        get filteredLogs() {
            var filtered = this.allLogs.filter(function(l) {
                if (this.filterDomain && l.domain.indexOf(this.filterDomain) === -1) return false;
                if (this.filterStatus && l.status !== this.filterStatus) return false;
                if (this.filterServer && l.server !== this.filterServer) return false;
                if (this.filterAction && l.action !== this.filterAction) return false;
                return true;
            }.bind(this));
            var key = this.sortBy;
            var dir = this.sortDir === 'asc' ? 1 : -1;
            return filtered.sort(function(a, b) {
                var av = a[key] !== undefined ? a[key] : '';
                var bv = b[key] !== undefined ? b[key] : '';
                if (typeof av === 'number' && typeof bv === 'number') return (av - bv) * dir;
                return String(av).localeCompare(String(bv)) * dir;
            });
        },

        setSort: function(col) {
            if (this.sortBy === col) {
                this.sortDir = this.sortDir === 'asc' ? 'desc' : 'asc';
            } else {
                this.sortBy = col;
                this.sortDir = (col === 'id' || col === 'time') ? 'desc' : 'asc';
            }
            this.currentPage = 1;
        },

        sortIcon: function(col) {
            if (this.sortBy !== col) return '⇅';
            return this.sortDir === 'asc' ? '▲' : '▼';
        },

        get pagedLogs() {
            if (!this.perPage) return this.filteredLogs;
            var start = (this.currentPage - 1) * this.perPage;
            return this.filteredLogs.slice(start, start + this.perPage);
        },

        get totalPages() {
            if (!this.perPage) return 1;
            return Math.max(1, Math.ceil(this.filteredLogs.length / this.perPage));
        },
        
        retryAllFailed: async function() {
            var count = this.failedCount;
            if (count === 0) {
                window._hvnToast('warning', 'Không có job FAILED', 'Không có job nào cần retry.');
                return;
            }
            var ok = await window._hvnConfirm({
                title:        'Retry tất cả ' + count + ' job FAILED?',
                message:      'Các job FAILED sẽ được reset về PENDING.\nChúng sẽ được xử lý khi bấm "Đồng bộ Pending".',
                variant:      'warning',
                confirmLabel: 'Reset ' + count + ' job',
                cancelLabel:  'Hủy'
            });
            if (!ok) return;

            var self = this;
            self.retrying = true;

            fetch(HVNDNS_MODULE_LINK + '&action=ajax', {
                method: 'POST',
                headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
                body: 'method=retryAllFailed'
            })
            .then(function(r) { return r.json(); })
            .then(function(data) {
                self.retrying = false;
                if (data.success) {
                    self.allLogs.forEach(function(l) {
                        if (l.status === 'failed') {
                            l.status = 'pending';
                            l.error_brief = '';
                        }
                    });
                    window._hvnToast('success', 'Reset thành công', data.message || '');
                } else {
                    window._hvnToast('error', 'Lỗi', data.error || 'Lỗi không xác định');
                }
            })
            .catch(function() {
                self.retrying = false;
                window._hvnToast('error', 'Lỗi kết nối', 'Vui lòng thử lại.');
            });
        },

        retryJob: async function(log) {
            var ok = await window._hvnConfirm({
                title:        'Retry job #' + log.id + '?',
                message:      'Job sẽ được reset về PENDING và xử lý khi bấm "Đồng bộ Pending".',
                variant:      'warning',
                confirmLabel: 'Retry',
                cancelLabel:  'Hủy'
            });
            if (!ok) return;
            var self = this;
            fetch(HVNDNS_MODULE_LINK + '&action=ajax', {
                method: 'POST',
                headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
                body: 'method=retryJob&job_id=' + log.id
            })
            .then(function(r) { return r.json(); })
            .then(function(data) {
                if (data.success) {
                    log.status = 'pending';
                    log.error_brief = '';
                    window._hvnToast('success', 'Job đã reset', data.message || 'Job #' + log.id + ' đã về PENDING.');
                } else {
                    window._hvnToast('error', 'Lỗi', data.error || 'Lỗi không xác định');
                }
            })
            .catch(function() {
                window._hvnToast('error', 'Lỗi kết nối', 'Vui lòng thử lại.');
            });
        },

        exportCsv: function() {
            var rows = this.filteredLogs;
            if (!rows.length) {
                window._hvnToast('warning', 'Không có dữ liệu', 'Không có bản ghi nào phù hợp bộ lọc để export.');
                return;
            }

            // Header
            var headers = ['ID', 'Thoi gian', 'Domain', 'Action', 'Chi tiet', 'Server', 'Trang thai', 'Loi', 'ms'];

            // Escape cell: bọc nháy kép, escape nháy kép bên trong
            var esc = function(val) {
                if (val === null || val === undefined) return '';
                return '"' + String(val).replace(/"/g, '""') + '"';
            };

            var lines = [headers.map(esc).join(',')];
            rows.forEach(function(l) {
                lines.push([
                    l.id,
                    esc(l.time),
                    esc(l.domain),
                    esc(l.action),
                    esc(l.details),
                    esc(l.server),
                    esc(l.status),
                    esc(l.error_brief),
                    l.ms !== null && l.ms !== undefined ? l.ms : ''
                ].join(','));
            });

            // BOM UTF-8 để Excel đọc được tiếng Việt
            var bom = '\uFEFF';
            var csvContent = bom + lines.join('\r\n');
            var blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' });
            var url = URL.createObjectURL(blob);
            var a = document.createElement('a');
            var now = new Date();
            var ts = now.getFullYear()
                + ('0'+(now.getMonth()+1)).slice(-2)
                + ('0'+now.getDate()).slice(-2)
                + '_'
                + ('0'+now.getHours()).slice(-2)
                + ('0'+now.getMinutes()).slice(-2);
            a.href = url;
            a.download = 'sync_logs_' + ts + '.csv';
            document.body.appendChild(a);
            a.click();
            document.body.removeChild(a);
            URL.revokeObjectURL(url);
        },

        runPendingJobs: async function() {
            var ok = await window._hvnConfirm({
                title:        'Chạy job PENDING?',
                message:      'Toàn bộ job đang PENDING sẽ được đồng bộ ngay.\nJob FAILED sẽ không bị ảnh hưởng.',
                variant:      'info',
                confirmLabel: 'Đồng bộ ngay',
                cancelLabel:  'Hủy'
            });
            if (!ok) return;
            var self = this;
            self.syncing = true;
            fetch(HVNDNS_MODULE_LINK + '&action=ajax', {
                method: 'POST',
                headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
                body: 'method=runPendingJobs'
            })
            .then(function(r) { return r.json(); })
            .then(function(data) {
                self.syncing = false;
                if (data.success) {
                    window._hvnToast('success', 'Đồng bộ hoàn tất', (data.message || '') + ' — Đã xử lý: ' + (data.processed || 0) + ' job');
                    setTimeout(function() { window.location.reload(); }, 1200);
                } else {
                    window._hvnToast('error', 'Lỗi đồng bộ', data.error || 'Lỗi không xác định');
                }
            })
            .catch(function() {
                self.syncing = false;
                window._hvnToast('error', 'Lỗi kết nối', 'Vui lòng thử lại.');
            });
        }
    }));
});
{/literal}
</script>