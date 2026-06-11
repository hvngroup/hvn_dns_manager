/* == templates/admin/dashboard.tpl == */
(function () {
document.addEventListener('alpine:init', () => {
    Alpine.data('dashboardManager', () => ({
        // ── State ─────────────────────────────────────────────────────────
        loading:          true,
        chartDays:        7,
        stats:            { complete: '—', pending: '—', failed: '—', domains: '—', records: '—' },
        chartData:        null,
        servers:          [],
        recentActivity:   [],
        topDomains:       [],
        hasCriticalAlert: false,
        alertMessages:    [],
        generatedAt:      null,
        chartInstance:    null,
        refreshTimer:     null,

        // ── Init ──────────────────────────────────────────────────────────
        init() {
            this.fetchStats();
            // Auto-refresh mỗi 30 giây
            this.refreshTimer = setInterval(() => { this.fetchStats(); }, 30000);
        },

        // ── Fetch từ API ──────────────────────────────────────────────────
        async fetchStats() {
            this.loading = true;
            try {
                const url = MJDNS_MODULELINK + '&action=ajax&method=getDashboardStats&days=' + this.chartDays;
                const res  = await fetch(url, { headers: { 'X-Requested-With': 'XMLHttpRequest' } });
                const data = await res.json();

                if (!data.success) return;

                this.stats            = data.stats;
                this.chartData        = data.chartData;
                this.servers          = data.servers;
                this.recentActivity   = data.recentActivity;
                this.topDomains       = data.topDomains || [];
                this.hasCriticalAlert = data.hasCriticalAlert;
                this.alertMessages    = data.alertMessages || [];
                this.generatedAt      = data.generatedAt;

                // Render chart sau khi có data
                this.$nextTick(() => { this.renderChart(); });

            } catch (e) {
                console.error('Dashboard fetch error:', e);
            } finally {
                this.loading = false;
            }
        },

        // ── Đổi khoảng thời gian chart ────────────────────────────────────
        setDays(days) {
            this.chartDays = days;
            this.fetchStats();
        },

        // ── Render / Update Chart.js ──────────────────────────────────────
        renderChart() {
            const ctx = document.getElementById('syncChart');
            if (!ctx || !this.chartData || typeof Chart === 'undefined') return;

            const d = this.chartData;

            if (this.chartInstance) {
                // Update data mà không destroy → không flicker
                this.chartInstance.data.labels              = d.labels;
                this.chartInstance.data.datasets[0].data   = d.complete;
                this.chartInstance.data.datasets[1].data   = d.failed;
                this.chartInstance.data.datasets[2].data   = d.pending;
                this.chartInstance.update('none'); // 'none' = không animate khi update
                return;
            }

            // Khởi tạo lần đầu
            this.chartInstance = new Chart(ctx, {
                type: 'line',
                data: {
                    labels: d.labels,
                    datasets: [
                        {
                            label: 'Complete',
                            data: d.complete,
                            borderColor: '#198754',
                            backgroundColor: 'rgba(25,135,84,0.12)',
                            borderWidth: 2, fill: true, tension: 0.4,
                            pointRadius: 2, pointHoverRadius: 4
                        },
                        {
                            label: 'Failed',
                            data: d.failed,
                            borderColor: '#dc3545',
                            backgroundColor: 'rgba(220,53,69,0.1)',
                            borderWidth: 2, fill: false, tension: 0.4,
                            pointRadius: 2, pointHoverRadius: 4
                        },
                        {
                            label: 'Pending',
                            data: d.pending,
                            borderColor: '#ffc107',
                            backgroundColor: 'rgba(255,193,7,0.1)',
                            borderWidth: 2, fill: false, tension: 0.4,
                            pointRadius: 2, pointHoverRadius: 4
                        }
                    ]
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: false,
                    animation: { duration: 400 },
                    plugins: {
                        legend: {
                            display: true, position: 'top',
                            labels: { boxWidth: 12, font: { size: 11 }, padding: 8 }
                        },
                        tooltip: {
                            mode: 'index', intersect: false,
                            callbacks: { title: (items) => 'Ngày ' + items[0].label }
                        }
                    },
                    scales: {
                        x: {
                            display: true,
                            grid: { display: false },
                            ticks: { font: { size: 10 }, maxRotation: 0, maxTicksLimit: 10 }
                        },
                        y: {
                            display: true, min: 0,
                            grid: { color: 'rgba(0,0,0,0.05)' },
                            ticks: { font: { size: 10 }, maxTicksLimit: 5 }
                        }
                    },
                    interaction: { mode: 'nearest', axis: 'x', intersect: false }
                }
            });
        }
    }));
});
})();

/* == templates/admin/sync_logs.tpl == */
(function () {
document.addEventListener('alpine:init', () => {
    Alpine.data('syncLogsData', () => ({
        filterDomain: '', filterStatus: '', filterServer: '', filterAction: '',
        perPage: 100,
        currentPage: 1,
        sortBy: 'id',
        sortDir: 'desc',
        syncing: false,
        retrying: false,

        allLogs: MJDNS_SYNC_LOGS,

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
                window._mjDnsToast('warning', 'Không có job FAILED', 'Không có job nào cần retry.');
                return;
            }
            var ok = await window._mjDnsConfirm({
                title:        'Retry tất cả ' + count + ' job FAILED?',
                message:      'Các job FAILED sẽ được reset về PENDING.\nChúng sẽ được xử lý khi bấm "Đồng bộ Pending".',
                variant:      'warning',
                confirmLabel: 'Reset ' + count + ' job',
                cancelLabel:  'Hủy'
            });
            if (!ok) return;

            var self = this;
            self.retrying = true;

            fetch(MJDNS_MODULE_LINK + '&action=ajax', {
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
                    window._mjDnsToast('success', 'Reset thành công', data.message || '');
                } else {
                    window._mjDnsToast('error', 'Lỗi', data.error || 'Lỗi không xác định');
                }
            })
            .catch(function() {
                self.retrying = false;
                window._mjDnsToast('error', 'Lỗi kết nối', 'Vui lòng thử lại.');
            });
        },

        retryJob: async function(log) {
            var ok = await window._mjDnsConfirm({
                title:        'Retry job #' + log.id + '?',
                message:      'Job sẽ được reset về PENDING và xử lý khi bấm "Đồng bộ Pending".',
                variant:      'warning',
                confirmLabel: 'Retry',
                cancelLabel:  'Hủy'
            });
            if (!ok) return;
            var self = this;
            fetch(MJDNS_MODULE_LINK + '&action=ajax', {
                method: 'POST',
                headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
                body: 'method=retryJob&job_id=' + log.id
            })
            .then(function(r) { return r.json(); })
            .then(function(data) {
                if (data.success) {
                    log.status = 'pending';
                    log.error_brief = '';
                    window._mjDnsToast('success', 'Job đã reset', data.message || 'Job #' + log.id + ' đã về PENDING.');
                } else {
                    window._mjDnsToast('error', 'Lỗi', data.error || 'Lỗi không xác định');
                }
            })
            .catch(function() {
                window._mjDnsToast('error', 'Lỗi kết nối', 'Vui lòng thử lại.');
            });
        },

        exportCsv: function() {
            var rows = this.filteredLogs;
            if (!rows.length) {
                window._mjDnsToast('warning', 'Không có dữ liệu', 'Không có bản ghi nào phù hợp bộ lọc để export.');
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
            var bom = '﻿';
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
            var ok = await window._mjDnsConfirm({
                title:        'Chạy job PENDING?',
                message:      'Toàn bộ job đang PENDING sẽ được đồng bộ ngay.\nJob FAILED sẽ không bị ảnh hưởng.',
                variant:      'info',
                confirmLabel: 'Đồng bộ ngay',
                cancelLabel:  'Hủy'
            });
            if (!ok) return;
            var self = this;
            self.syncing = true;
            fetch(MJDNS_MODULE_LINK + '&action=ajax', {
                method: 'POST',
                headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
                body: 'method=runPendingJobs'
            })
            .then(function(r) { return r.json(); })
            .then(function(data) {
                self.syncing = false;
                if (data.success) {
                    window._mjDnsToast('success', 'Đồng bộ hoàn tất', (data.message || '') + ' — Đã xử lý: ' + (data.processed || 0) + ' job');
                    setTimeout(function() { window.location.reload(); }, 1200);
                } else {
                    window._mjDnsToast('error', 'Lỗi đồng bộ', data.error || 'Lỗi không xác định');
                }
            })
            .catch(function() {
                self.syncing = false;
                window._mjDnsToast('error', 'Lỗi kết nối', 'Vui lòng thử lại.');
            });
        }
    }));
});
})();

/* == templates/admin/sync_log_detail.tpl == */
(function () {
document.addEventListener('alpine:init', () => {
    Alpine.data('jobActions', function(cfg) {
        return {
            jobId:      cfg.jobId,
            jobStatus:  cfg.jobStatus,
            moduleLink: cfg.moduleLink,
            loading:    false,
            lastAction: '',
            resultMsg:  '',
            resultOk:   false,

            get canAct() {
                return !this.loading && this.jobStatus !== 'cancelled' && this.jobStatus !== 'complete';
            },

            retryJob: async function() {
                var ok = await window._mjDnsConfirm({
                    title:        'Retry Job #' + this.jobId + '?',
                    message:      'Job sẽ về PENDING và được xử lý khi Cron Worker chạy.',
                    variant:      'warning',
                    confirmLabel: 'Retry',
                    cancelLabel:  'Hủy'
                });
                if (!ok) return;

                var self = this;
                self.loading    = true;
                self.lastAction = 'retry';

                fetch(self.moduleLink + '&action=ajax', {
                    method:  'POST',
                    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
                    body:    'method=retryJob&job_id=' + self.jobId
                })
                .then(function(r) { return r.json(); })
                .then(function(data) {
                    self.loading = false;
                    if (data.success) {
                        window._mjDnsToast('success', 'Thành công', data.message);
                        self.jobStatus = 'pending';
                    } else {
                        window._mjDnsToast('error', 'Lỗi', data.error || 'Lỗi không xác định');
                    }
                })
                .catch(function() {
                    self.loading = false;
                    window._mjDnsToast('error', 'Lỗi mạng', 'Lỗi kết nối, vui lòng thử lại.');
                });
            },

            cancelJob: async function() {
                var ok = await window._mjDnsConfirm({
                    title:        'Xác nhận hủy Job #' + this.jobId + '?',
                    message:      'Job sẽ chuyển sang trạng thái CANCELLED và không thể tự động khôi phục.',
                    variant:      'danger',
                    confirmLabel: 'Hủy Job',
                    cancelLabel:  'Không hủy'
                });
                if (!ok) return;

                var self = this;
                self.loading    = true;
                self.lastAction = 'cancel';

                fetch(self.moduleLink + '&action=ajax', {
                    method:  'POST',
                    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
                    body:    'method=cancelJob&job_id=' + self.jobId
                })
                .then(function(r) { return r.json(); })
                .then(function(data) {
                    self.loading = false;
                    if (data.success) {
                        window._mjDnsToast('success', 'Đã hủy', data.message);
                        self.jobStatus = 'cancelled';
                    } else {
                        window._mjDnsToast('error', 'Lỗi', data.error || 'Lỗi không xác định');
                    }
                })
                .catch(function() {
                    self.loading = false;
                    window._mjDnsToast('error', 'Lỗi mạng', 'Lỗi kết nối, vui lòng thử lại.');
                });
            }
        };
    });
});
})();

/* == templates/admin/audit_trail.tpl == */
(function () {
document.addEventListener('alpine:init', () => {
    Alpine.data('auditTrailData', () => ({
        filterActor: '', filterAction: '', filterDomain: '', filterIp: '',
        filterDateFrom: '', filterDateTo: '',
        perPage: 50,
        currentPage: 1,

        allLogs: MJDNS_AUDIT_LOGS,

        get filteredLogs() {
            return this.allLogs.filter(l => {
                if (this.filterActor  && l.actorType !== this.filterActor)         return false;
                if (this.filterAction && l.action    !== this.filterAction)        return false;
                if (this.filterDomain && !l.domain.includes(this.filterDomain))   return false;
                if (this.filterIp     && !l.ip.includes(this.filterIp))           return false;

                // Filter theo ngày — log.time format: "dd/mm, HH:ii"
                // Parse sang "YYYY-MM-DD" để so sánh với filterDateFrom/filterDateTo
                if (this.filterDateFrom || this.filterDateTo) {
                    // log.time dạng "01/04, 04:30" → tách lấy "01/04"
                    var parts = l.time ? l.time.split(', ') : [];
                    var logDate = null;
                    if (parts.length >= 1) {
                        var dmParts = parts[0].split('/');
                        if (dmParts.length === 2) {
                            var year = new Date().getFullYear();
                            // Format YYYY-MM-DD để so sánh string
                            logDate = year + '-' + dmParts[1].padStart(2,'0') + '-' + dmParts[0].padStart(2,'0');
                        }
                    }
                    if (!logDate) return false;
                    if (this.filterDateFrom && logDate < this.filterDateFrom) return false;
                    if (this.filterDateTo   && logDate > this.filterDateTo)   return false;
                }

                return true;
            });
        },

        get pagedLogs() {
            if (!this.perPage) return this.filteredLogs;
            const start = (this.currentPage - 1) * this.perPage;
            return this.filteredLogs.slice(start, start + this.perPage);
        },

        get totalPages() {
            if (!this.perPage) return 1;
            return Math.max(1, Math.ceil(this.filteredLogs.length / this.perPage));
        },
    }));
});
})();

/* == templates/admin/audit_detail.tpl == */
(function () {
document.addEventListener('alpine:init', () => {
    Alpine.data('auditDetail', () => ({
        log: _AUDIT_LOG,
        init() {}
    }));
});
})();
