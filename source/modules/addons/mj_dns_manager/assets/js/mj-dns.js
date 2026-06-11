/* =========================================================================
 * MJ DNS Manager — mj-dns.js (single IIFE, MJ standard §8)
 * =========================================================================
 * Assembled from authored sections (core + per-template components).
 * Delivered INLINE from disk by AssetInliner (hooks.md §7.2) — Alpine.js
 * loads DEFERRED after this file, so alpine:init registrations below run
 * before Alpine boots.
 * NOTE: no 'use strict' — page components were moved verbatim from legacy
 * inline templates; sloppy-mode globals must keep working until each
 * component is individually hardened.
 * ========================================================================= */
(function () {


/* ====================================================================
   CORE — config, Utils, CSRF fetch guard, toast + confirm components
   ==================================================================== */

// Config: admin pages inject window.mjDnsConfig (AssetInliner); client
// pages keep the legacy per-page window.MJDNS_CONFIG blob. Read both.
var CFG = window.mjDnsConfig || {};

function mjDnsCsrf() {
    if (CFG.csrfToken) { return CFG.csrfToken; }
    if (window.MJDNS_CONFIG && window.MJDNS_CONFIG.csrfToken) { return window.MJDNS_CONFIG.csrfToken; }
    return '';
}

/* ================================================================
   UTILITIES
   ================================================================ */
var Utils = {
    esc: function (s) {
        return String(s == null ? '' : s)
            .replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;')
            .replace(/"/g, '&quot;').replace(/'/g, '&#039;');
    },

    toast: function (msg, type, title) {
        if (typeof window._mjDnsToast === 'function') {
            window._mjDnsToast(type || 'info', title || msg, title ? msg : '');
        }
    },

    confirm: function (options) {
        if (typeof window._mjDnsConfirm === 'function') { return window._mjDnsConfirm(options); }
        return Promise.resolve(window.confirm(typeof options === 'string' ? options : (options && options.message) || ''));
    },

    /**
     * fetch() wrapper [WHMCS-REQUIRED]:
     *  - X-Requested-With là routing hint, KHÔNG phải auth;
     *  - tự đính CSRF token trên mọi method khác GET/HEAD;
     *  - tự refresh token client từ res._token (WHMCS xoay tkval);
     *  - lỗi mạng nổi lên thành toast, trả {success:false}.
     */
    fetchJson: async function (url, opts) {
        opts = opts || {};
        opts.headers = Object.assign({ 'X-Requested-With': 'XMLHttpRequest' }, opts.headers || {});

        var method = (opts.method || 'GET').toUpperCase();
        if (method !== 'GET' && method !== 'HEAD') {
            var token = mjDnsCsrf();
            if (!opts.headers['X-CSRF-Token']) { opts.headers['X-CSRF-Token'] = token; }
            if (opts.body instanceof URLSearchParams && !opts.body.has('token')) { opts.body.append('token', token); }
            if (opts.body instanceof FormData && !opts.body.has('token')) { opts.body.append('token', token); }
        }

        try {
            var res = await (await fetch(url, opts)).json();
            if (res && res._token && window.MJDNS_CONFIG) { window.MJDNS_CONFIG.csrfToken = res._token; }
            return res;
        } catch (e) {
            Utils.toast('Lỗi mạng: ' + e.message, 'error');
            return { success: false, error: { code: 'NETWORK', message: e.message } };
        }
    }
};

/* ================================================================
   CSRF FETCH GUARD (belt-and-braces)
   Đính X-CSRF-Token cho MỌI fetch() mutation tới URL của module —
   kể cả code cũ gọi fetch() trực tiếp. Backend vẫn chặn nếu thiếu.
   ================================================================ */
(function () {
    if (window.__mjDnsFetchPatched) { return; }
    window.__mjDnsFetchPatched = true;
    var origFetch = window.fetch;
    if (typeof origFetch !== 'function') { return; }
    window.fetch = function (input, init) {
        try {
            var url = (typeof input === 'string') ? input : (input && input.url) || '';
            var method = ((init && init.method) || (typeof input === 'object' && input && input.method) || 'GET').toUpperCase();
            if (url.indexOf('mj_dns_manager') !== -1 && method !== 'GET' && method !== 'HEAD') {
                init = init || {};
                var h = new Headers(init.headers || (typeof input === 'object' && input ? input.headers : undefined) || {});
                if (!h.has('X-CSRF-Token')) { h.set('X-CSRF-Token', mjDnsCsrf()); }
                init.headers = h;
            }
        } catch (e) { /* fail-open vào fetch gốc — backend vẫn chặn nếu thiếu token */ }
        return origFetch.call(this, input, init);
    };
})();

/* ================================================================
   ALPINE — GLOBAL TOAST SYSTEM (moved from templates/admin/wrapper.tpl)
   ================================================================ */
document.addEventListener('alpine:init', () => {
    Alpine.data('mjDnsToastSystem', () => ({
        toasts: [],
        _nextId: 1,

        add(type, title, message, duration) {
            duration = duration || 4000;
            var id = this._nextId++;
            // Inline stroke SVGs (24×24, currentColor) — không dùng unicode/emoji làm icon.
            var svg = function (path) {
                return '<svg viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">' + path + '</svg>';
            };
            var icons = {
                success: svg('<path d="M20 6L9 17l-5-5"/>'),
                error:   svg('<line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/>'),
                warning: svg('<path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"/><line x1="12" y1="9" x2="12" y2="13"/><line x1="12" y1="17" x2="12.01" y2="17"/>'),
                info:    svg('<circle cx="12" cy="12" r="10"/><line x1="12" y1="16" x2="12" y2="12"/><line x1="12" y1="8" x2="12.01" y2="8"/>'),
            };
            this.toasts.push({ id: id, type: type, title: title, message: message || '', icon: icons[type] || icons.info, leaving: false });

            setTimeout(() => { this.dismiss(id); }, duration);
        },

        dismiss(id) {
            var t = this.toasts.find(function(x) { return x.id === id; });
            if (!t || t.leaving) return;
            t.leaving = true;
            setTimeout(() => {
                this.toasts = this.toasts.filter(function(x) { return x.id !== id; });
            }, 270);
        },

        init() {
            var self = this;
            // Expose global API
            window._mjDnsToast = function(type, title, message, duration) {
                self.add(type, title, message, duration);
            };

            // Listen to custom event (for cross-Alpine-component usage)
            window.addEventListener('mjdns:toast', function(e) {
                var d = e.detail || {};
                self.add(d.type || 'info', d.title || d.message || '', d.message || '', d.duration);
            });
        }
    }));
});

/* ================================================================
   ALPINE — GLOBAL CONFIRM MODAL (moved from templates/admin/wrapper.tpl)
   ================================================================ */
document.addEventListener('alpine:init', () => {
    Alpine.data('mjDnsConfirmModal', () => ({
        open:         false,
        title:        'Xác nhận',
        message:      '',
        variant:      'warning',   // 'danger' | 'warning' | 'info' | 'success'
        confirmLabel: 'Xác nhận',
        cancelLabel:  'Hủy',
        _resolve:     null,

        init() {
            var self = this;
            window._mjDnsConfirm = function(options) {
                if (typeof options === 'string') {
                    options = { message: options };
                }
                return new Promise(function(resolve) {
                    self.title        = options.title        || 'Xác nhận';
                    self.message      = options.message      || '';
                    self.variant      = options.variant      || 'warning';
                    self.confirmLabel = options.confirmLabel || 'Xác nhận';
                    self.cancelLabel  = options.cancelLabel  || 'Hủy';
                    self._resolve     = resolve;
                    self.open         = true;
                    // Focus confirm button after paint
                    setTimeout(function() {
                        if (self.$refs && self.$refs.confirmBtn) {
                            self.$refs.confirmBtn.focus();
                        }
                    }, 50);
                });
            };
        },

        confirm() {
            this.open = false;
            if (this._resolve) { this._resolve(true); this._resolve = null; }
        },

        cancel() {
            this.open = false;
            if (this._resolve) { this._resolve(false); this._resolve = null; }
        }
    }));
});

/* ================================================================
   BOOT
   ================================================================ */
function boot() {
    // Body class scope cho CSS ẩn content-header — chỉ trang admin module.
    if (CFG.context === 'admin') {
        document.body.classList.add('mj-dns-app-page');
    }
}
if (document.readyState === 'loading') { document.addEventListener('DOMContentLoaded', boot); }
else { boot(); }

window.mjDns = { Utils: Utils, csrf: mjDnsCsrf, cfg: CFG };


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


/* == templates/admin/dns_editor.tpl == */
(function () {
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
})();

/* == templates/admin/domains.tpl == */
(function () {
document.addEventListener('alpine:init', () => {
    Alpine.data('domainList', () => ({
        loading: false,
        domains: MJDNS_DOMAINS_INIT,
        totalRecords: MJDNS_TOTAL_DOMAINS,
        totalPages: MJDNS_TOTAL_PAGES,
        currentPage: MJDNS_CURRENT_PAGE,
        perPage: 50,
        syncingId: null,
        sortCol: 'domain',
        sortDir: 'asc',
        filters: { search: '', status: '', server: '', errorOnly: false },

        init() {
            // Data pre-loaded from server — no AJAX needed on init
        },

        resetFilters() {
            this.filters = { search: '', status: '', server: '', errorOnly: false };
            this.sortCol = 'domain';
            this.sortDir = 'asc';
            this.currentPage = 1;
            this.fetchDomains();
        },

        sortBy(col) {
            if (this.sortCol === col) {
                this.sortDir = this.sortDir === 'asc' ? 'desc' : 'asc';
            } else {
                this.sortCol = col;
                this.sortDir = 'asc';
            }
            this.domains = [...this.domains].sort((a, b) => {
                var va = a[col] ?? '';
                var vb = b[col] ?? '';
                if (typeof va === 'number' && typeof vb === 'number') {
                    return this.sortDir === 'asc' ? va - vb : vb - va;
                }
                return this.sortDir === 'asc'
                    ? String(va).localeCompare(String(vb))
                    : String(vb).localeCompare(String(va));
            });
        },

        goToPage(page) {
            if (page >= 1 && page <= this.totalPages) {
                var url = new URL(window.location.href);
                url.searchParams.set('page', page);
                window.location.href = url.toString();
            }
        },

        openDropdown(event) {
            var btn = event.currentTarget;
            var menu = btn.nextElementSibling;
            var isOpen = menu.classList.contains('mj-show');
            document.querySelectorAll('.mj-dropdown-menu.mj-show').forEach(function(m) {
                m.classList.remove('mj-show');
                m.style.position = '';
                m.style.top = '';
                m.style.right = '';
                m.style.left = '';
                m.style.minWidth = '';
            });
            if (!isOpen) {
                var rect = btn.getBoundingClientRect();
                menu.style.position = 'fixed';
                menu.style.top = (rect.bottom + 4) + 'px';
                menu.style.right = (window.innerWidth - rect.right) + 'px';
                menu.style.left = 'auto';
                menu.style.minWidth = '200px';
                menu.classList.add('mj-show');
            }
        },

        async forceResync(domain) {
            if (this.syncingId !== null) return;
            this.syncingId = domain.id;
            document.querySelectorAll('.mj-dropdown-menu.mj-show').forEach(function(m) {
                m.classList.remove('mj-show');
            });
            try {
                await new Promise(r => setTimeout(r, 2500));
                var idx = this.domains.findIndex(d => d.id === domain.id);
                if (idx !== -1) {
                    this.domains[idx].sync_status = 'complete';
                    this.domains[idx].failed_jobs = 0;
                    this.domains[idx].last_sync = 'Vừa xong';
                }
            } catch (e) {
                console.error('Force re-sync thất bại:', e);
            } finally {
                this.syncingId = null;
            }
        },

        fetchDomains() {
            this.loading = true;
            var url = new URL(window.location.href);
            if (this.filters.search) {
                url.searchParams.set('search', this.filters.search);
            } else {
                url.searchParams.delete('search');
            }
            if (this.filters.status) {
                url.searchParams.set('status', this.filters.status);
            } else {
                url.searchParams.delete('status');
            }
            url.searchParams.set('page', '1');
            window.location.href = url.toString();
        },

        // ── Check SSL per domain ──────────────────────────────────────────
        async checkSsl(domain) {
            document.querySelectorAll('.mj-dropdown-menu.mj-show').forEach(function(m) {
                m.classList.remove('mj-show');
            });

            var res = await fetch(
                '?module=mj_dns_manager&action=ajax&method=runSslCheck',
                {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ domain_id: domain.id })
                }
            );
            var data = await res.json();

            if (data.success) {
                window._mjDnsToast('success', 'Kiểm tra SSL OK', data.message);
            } else {
                window._mjDnsToast('error', 'Lỗi kiểm tra SSL', data.error || 'Lỗi không xác định');
            }
        },

        // ── Check Drift per domain ────────────────────────────────────────
        async checkDrift(domain) {
            document.querySelectorAll('.mj-dropdown-menu.mj-show').forEach(function(m) {
                m.classList.remove('mj-show');
            });

            var ok = await window._mjDnsConfirm({
                title:        'Check Drift: ' + domain.domain + '?',
                message:      'Hệ thống sẽ so sánh records trong WHMCS với DirectAdmin.\n(Thao tác này mất vài giây)',
                variant:      'info',
                confirmLabel: 'Kiểm tra',
                cancelLabel:  'Hủy'
            });
            if (!ok) return;

            var res = await fetch(
                '?module=mj_dns_manager&action=ajax&method=runDriftCheck',
                {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ domain_id: domain.id })
                }
            );
            var data = await res.json();

            if (data.success) {
                var msg = data.message;
                if (data.drifts && data.drifts.length > 0) {
                    msg += '\n\nĐã phát hiện lệch dữ liệu, xem tại Drift Reports.';
                    window._mjDnsToast('warning', 'Phát hiện lệch dữ liệu', msg, 6000);
                } else {
                    window._mjDnsToast('success', 'Đồng bộ hoàn hảo', msg);
                }
            } else {
                window._mjDnsToast('error', 'Lỗi kiểm tra Drift', data.error || 'Lỗi không xác định');
            }
        },
    }));
});
})();

/* == templates/admin/drift_reports.tpl == */
(function () {
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
        rows: _mjDnsDriftRows,

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

            var ok = await window._mjDnsConfirm({
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
                const res = await fetch(_mjDnsModuleLink + '&action=ajax', {
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

                    window._mjDnsToast('success', 'Thành công', data.message || 'Đã xử lý thành công.');
                } else {
                    row.status     = originalStatus;
                    row._resolving = false;
                    window._mjDnsToast('error', 'Lỗi xử lý', data.error || 'Không xác định');
                }

            } catch (e) {
                row.status     = originalStatus;
                row._resolving = false;
                window._mjDnsToast('error', 'Lỗi mạng', e.message);
            }
        },

        async runScan() {
            this.scanning = true;

            try {
                var url = _mjDnsModuleLink + '&action=ajax';
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
                    window._mjDnsToast('success', 'Quét hoàn tất', data.message || '');
                    setTimeout(() => { window.location.reload(); }, 1000);
                } else {
                    window._mjDnsToast('error', 'Quét thất bại', data.error || 'Lỗi không xác định');
                    this.scanning = false;
                }
            } catch (e) {
                window._mjDnsToast('error', 'Lỗi mạng', e.message);
                this.scanning = false;
            }
        }
    }));
});
})();

/* == templates/admin/drift_settings.tpl == */
(function () {
document.addEventListener('alpine:init', () => {
    Alpine.data('driftSettings', () => ({
        autoFixEnabled: false,

        init() {
            // Mock load settings
            this.autoFixEnabled = false;
        },

        saveAutoFix() {
            window._mjDnsToast('success', 'Đã lưu', 'Cấu hình Drift Auto-fix đã được lưu!');
            window.location.href = MJDNS_DRIFT_SETTINGS_MODULELINK + '&action=drift_reports';
        }
    }));
});
})();

/* == templates/admin/bulk.tpl == */
(function () {
document.addEventListener('alpine:init', () => {
    Alpine.data('bulkManager', () => ({
        operation: 'change_ip',

        formIp: { oldIp: '', newIp: '' },
        formTemplate: { templateId: '' },

        scope: 'all',
        scopeServerId: '1',

        isScanning: false,
        isExecuting: false,
        isDone: false,

        preview: {
            scanned: false,
            totalRecords: 0,
            domains: []
        },

        progress: {
            done: 0, success: 0, fails: 0, working: 0
        },

        resetState() {
            this.preview.scanned = false;
            this.isScanning = false;
            this.isExecuting = false;
            this.isDone = false;
            this.progress = { done: 0, success: 0, fails: 0, working: 0 };
        },

        scanPreview() {
            // Validation
            if (this.operation === 'change_ip' && (!this.formIp.oldIp || !this.formIp.newIp)) {
                window._mjDnsToast('warning', 'Thiếu thông tin', 'Vui lòng nhập IP cũ và IP Mới!');
                return;
            }
            if (this.operation === 'apply_template' && !this.formTemplate.templateId) {
                window._mjDnsToast('warning', 'Chưa chọn Template', 'Vui lòng chọn Template trước khi quét!');
                return;
            }

            this.resetState();
            this.isScanning = true;

            // Fake scan latency
            setTimeout(() => {
                this.isScanning = false;
                this.preview.scanned = true;

                // MOCK result
                if (this.operation === 'change_ip' && this.formIp.oldIp === '12.34.56.78') {
                    // Empty state demo
                    this.preview.domains = [];
                    this.preview.totalRecords = 0;
                } else {
                    // Filled state demo
                    this.preview.totalRecords = 23;
                    this.preview.domains = [
                        { name: 'example.com', summary: '3 records (A @, A www, A mail)' },
                        { name: 'shop.vn', summary: '2 records (A @, A www)' },
                        { name: 'myblog.net', summary: '1 record (A @)' },
                        { name: 'test.org', summary: '1 record (A @)' },
                        { name: 'demo1.io', summary: '2 records (A @, A mx)' },
                    ];
                }
            }, 1000);
        },

        async executeBulk() {
            var ok = await window._mjDnsConfirm({
                title:        'Xác nhận thao tác hàng loạt',
                message:      'Cảnh báo: Thao tác này sẽ thay đổi DNS trên tất cả các domain đã chọn. Bạn có chắc chắn muốn tiếp tục?',
                variant:      'danger',
                confirmLabel: 'Thực hiện',
                cancelLabel:  'Hủy'
            });
            if (!ok) return;

            this.isExecuting = true;
            this.progress = { done: 0, success: 0, fails: 0, working: 2 };

            // Mock execution progress
            var total = this.preview.domains.length;
            var current = 0;
            var self = this;

            var interval = setInterval(function() {
                current++;
                self.progress.done = current;
                self.progress.success = current;

                if (current >= total) {
                    clearInterval(interval);
                    self.isExecuting = false;
                    self.isDone = true;
                    self.progress.working = 0;
                    window._mjDnsToast('success', 'Hoàn tất', 'Thao tác hàng loạt đã hoàn thành thành công!');
                }
            }, 600);
        }
    }));
});
})();


/* == templates/admin/servers.tpl == */
(function () {
document.addEventListener('alpine:init', () => {
    Alpine.data('serverManager', () => ({
        servers:   MJDNS_SERVERS,
        loading:   false,

        // ── Helper: gọi AJAX POST ─────────────────────────────────────────
        async post(method, body) {
            const fd = new FormData();
            fd.append('method', method);
            for (const [k, v] of Object.entries(body)) {
                fd.append(k, v);
            }
            const res = await fetch(MJDNS_MODULELINK + '&action=ajax', {
                method: 'POST',
                headers: { 'X-Requested-With': 'XMLHttpRequest' },
                body: fd,
            });
            return res.json();
        },

        // ── Hiện toast (dùng global _mjDnsToast) ───────────────────────────
        showAlert(msg, type) {
            var title = type === 'error' ? 'Lỗi' : 'Thành công';
            // Bỏ emoji prefix nếu có
            var clean = msg.replace(/^[✅❌⚠️\s]+/, '');
            window._mjDnsToast(type === 'error' ? 'error' : 'success', title, clean);
        },

        // ── Test Connection ───────────────────────────────────────────────
        async testConnection(server) {
            this.loading = true;
            try {
                const data = await this.post('testConnection', {
                    hostname:   server.hostname,
                    ip_address: server.ip_address,
                    port:       server.port,
                    use_ssl:    server.use_ssl ? '1' : '0',
                    username:   'admin',
                    server_id:  server.id,
                });
                if (data.success) {
                    this.showAlert('✅ ' + server.hostname + ': Kết nối thành công!', 'success');
                } else {
                    this.showAlert('❌ ' + server.hostname + ': ' + (data.error?.message || 'Lỗi không xác định'), 'error');
                }
            } catch (err) {
                this.showAlert('❌ Lỗi mạng: ' + err.message, 'error');
            } finally {
                this.loading = false;
            }
        },

        // ── Toggle Enable / Disable ───────────────────────────────────────
        async toggleStatus(server) {
            const action = server.is_active ? 'vô hiệu hóa' : 'kích hoạt';
            var ok = await window._mjDnsConfirm({
                title:        'Xác nhận ' + action + ' server?',
                message:      'Bạn có chắc muốn ' + action + ' server ' + server.hostname + '?',
                variant:      server.is_active ? 'danger' : 'info',
                confirmLabel: action.charAt(0).toUpperCase() + action.slice(1),
                cancelLabel:  'Hủy'
            });
            if (!ok) return;

            this.loading = true;
            try {
                const data = await this.post('toggleServerStatus', { server_id: server.id });
                if (data.success) {
                    server.is_active = data.is_active;
                    if (data.is_active) server.status = 'online';
                    this.showAlert('✅ ' + data.message, 'success');
                } else {
                    this.showAlert('❌ ' + (data.error || 'Lỗi không xác định'), 'error');
                }
            } catch (err) {
                this.showAlert('❌ Lỗi mạng: ' + err.message, 'error');
            } finally {
                this.loading = false;
            }
        },

        // ── Reset Backoff ─────────────────────────────────────────────────
        async resetBackoff(server) {
            var ok = await window._mjDnsConfirm({
                title:        'Reset Backoff?',
                message:      'Reset lỗi và thử lại ngay cho ' + server.hostname + '?\nCác job FAILED sẽ được đưa về PENDING.',
                variant:      'warning',
                confirmLabel: 'Reset Backoff',
                cancelLabel:  'Hủy'
            });
            if (!ok) return;

            this.loading = true;
            try {
                const data = await this.post('resetServerBackoff', { server_id: server.id });
                if (data.success) {
                    server.status       = 'online';
                    server.failed_count = 0;
                    server.next_retry   = null;
                    server.retry_in     = null;
                    server.last_error   = null;
                    this.showAlert('✅ ' + data.message, 'success');
                } else {
                    this.showAlert('❌ ' + (data.error || 'Lỗi không xác định'), 'error');
                }
            } catch (err) {
                this.showAlert('❌ Lỗi mạng: ' + err.message, 'error');
            } finally {
                this.loading = false;
            }
        },
    }));
});
})();

/* == templates/admin/server_edit.tpl == */
(function () {
document.addEventListener('alpine:init', () => {
    Alpine.data('serverEditor', () => ({
        isEdit: MJDNS_IS_EDIT,
        form: MJDNS_SERVER ? {
            id:                  MJDNS_SERVER.id,
            hostname:            MJDNS_SERVER.hostname,
            ip_address:          MJDNS_SERVER.ip_address,
            port:                MJDNS_SERVER.port,
            use_ssl:             MJDNS_SERVER.use_ssl,
            username:            MJDNS_SERVER.username,
            password:            '',
            nameservers:         MJDNS_SERVER.nameservers || '',
            is_primary:          MJDNS_SERVER.is_primary,
            max_concurrent_jobs: MJDNS_SERVER.max_concurrent_jobs,
            notes:               MJDNS_SERVER.notes,
        } : {
            id: null, hostname: '', ip_address: '', port: 2222, use_ssl: true,
            username: 'admin', password: '', nameservers: '', is_primary: false, max_concurrent_jobs: 50, notes: ''
        },
        submitting: false,
        testStatus: null,
        testResult: '',

        saveServer(event) {
            this.submitting = true;
            // Submit native form — POST to controller
            event.target.submit();
        },

        async testConn() {
            if (!this.form.hostname || !this.form.ip_address || !this.form.username) {
                window._mjDnsToast('warning', 'Thiếu thông tin', 'Vui lòng điền đầy đủ Hostname, IP và Username để Test.');
                return;
            }
            if (!this.form.password && !this.isEdit) {
                window._mjDnsToast('warning', 'Thiếu Password', 'Vui lòng nhập Password để Test.');
                return;
            }

            this.testStatus = 'loading';
            this.testResult = '';

            try {
                const formData = new FormData();
                formData.append('hostname',   this.form.hostname);
                formData.append('ip_address', this.form.ip_address);
                formData.append('port',       this.form.port);
                formData.append('use_ssl',    this.form.use_ssl ? '1' : '0');
                formData.append('username',   this.form.username);
                formData.append('password',   this.form.password);
                if (this.form.id) {
                    formData.append('server_id', this.form.id);
                }

                const url = MJDNS_MODULELINK + '&action=ajax&method=testConnection';
                const res  = await fetch(url, {
                    method: 'POST',
                    headers: { 'X-Requested-With': 'XMLHttpRequest' },
                    body: formData
                });
                const data = await res.json();

                if (data.success) {
                    this.testStatus = 'success';
                    this.testResult = '✅ Kết nối thành công!\n' + (data.data?.message || '');
                } else {
                    this.testStatus = 'error';
                    this.testResult = '❌ Lỗi kết nối!\n' + (data.error?.message || 'Unknown error');
                }
            } catch (e) {
                this.testStatus = 'error';
                this.testResult = '❌ Lỗi kết nối!\n' + e.message;
            }
        }
    }));
});
})();

/* == templates/admin/settings.tpl == */
(function () {
document.addEventListener('alpine:init', function() {
    Alpine.data('settingsManager', function() {
        return {
            activeTab: 'general',
            isSaving: false,
            savedMsg: false,
            isTesting: false,
            isTestingEmail: false,
            telegramResult: { ok: false, msg: '' },
            emailResult: { ok: false, msg: '' },

            s: Object.assign({
                // Fallback defaults nếu PHP không truyền
                module_enabled: true,
                default_nameserver_1: 'dns1.hvn.vn',
                default_nameserver_2: 'dns2.hvn.vn',
                default_nameserver_3: 'dns3.hvn.vn',
                default_nameserver_4: '',
                default_nameserver_5: '',
                default_ttl: 3600,
                enable_telegram_alert: false,
                telegram_bot_token: '',
                telegram_chat_id: '',
                telegram_has_token: false,
                enable_email_alert: false,
                alert_email_addresses: '',
                alert_cooldown: 900,
                alert_failed_threshold: 5,
                alert_unreachable_threshold: 3,
                alert_queue_backlog_threshold: 100,
                notify_client_on_record_create: false,
            }, typeof MJDNS_SETTINGS !== 'undefined' ? MJDNS_SETTINGS : {}),

            saveSettings: function() {
                var self = this;
                this.isSaving = true;

                // Convert boolean → "1"/"0" cho PHP
                var data = {};
                for (var k in this.s) {
                    if (typeof this.s[k] === 'boolean') {
                        data[k] = this.s[k] ? '1' : '0';
                    } else {
                        data[k] = this.s[k];
                    }
                }

                fetch(window.location.href + '&action=ajax&method=saveSettings', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify(data)
                })
                .then(function(r) { return r.json(); })
                .then(function(res) {
                    self.isSaving = false;
                    if (res.success) {
                        self.savedMsg = true;
                        window._mjDnsToast('success', 'Đã lưu', 'Cài đặt đã được lưu thành công.');
                        setTimeout(function() { self.savedMsg = false; }, 3000);
                    } else {
                        window._mjDnsToast('error', 'Lỗi lưu settings', res.error || 'Không xác định');
                    }
                })
                .catch(function(e) {
                    self.isSaving = false;
                    window._mjDnsToast('error', 'Lỗi kết nối', 'Không thể kết nối khi lưu settings. Vui lòng thử lại.');
                });
            },

            sendTestNotification: function() {
                var self = this;
                this.isTesting = true;
                this.telegramResult = { ok: false, msg: '' };
                fetch(window.location.href + '&action=ajax&method=testNotification', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({})
                })
                .then(function(r) { return r.json(); })
                .then(function(res) {
                    self.isTesting = false;
                    if (res.success) {
                        if (res.data && res.data.telegram === true)
                            self.telegramResult = { ok: true, msg: 'Telegram ✅' };
                        else if (res.data && res.data.telegram === false)
                            self.telegramResult = { ok: false, msg: 'Telegram ❌' };
                        else
                            self.telegramResult = { ok: true, msg: 'Đã gửi' };
                    } else {
                        self.telegramResult = { ok: false, msg: 'Lỗi: ' + (res.error || 'Không xác định') };
                    }
                })
                .catch(function(e) {
                    self.isTesting = false;
                    self.telegramResult = { ok: false, msg: 'Lỗi kết nối' };
                });
            },

            sendTestEmail: function() {
                var self = this;
                if (!this.s.alert_email_addresses || !this.s.alert_email_addresses.trim()) {
                    this.emailResult = { ok: false, msg: 'Chưa nhập email trong alert_email_addresses' };
                    return;
                }
                this.isTestingEmail = true;
                this.emailResult = { ok: false, msg: '' };
                fetch(window.location.href + '&action=ajax&method=testEmail', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ email_addresses: this.s.alert_email_addresses })
                })
                .then(function(r) { return r.json(); })
                .then(function(res) {
                    self.isTestingEmail = false;
                    if (res.success) {
                        self.emailResult = { ok: true, msg: 'Email ✅ ' + (res.sent_to || '') };
                    } else {
                        self.emailResult = { ok: false, msg: 'Email ❌ ' + (res.error || 'Không xác định') };
                    }
                })
                .catch(function() {
                    self.isTestingEmail = false;
                    self.emailResult = { ok: false, msg: 'Email ❌ Lỗi kết nối' };
                });
            },



            checkLicense: function() {
                var self = this;
                var btn  = event.currentTarget;
                var icon = btn.querySelector('i');
                icon.classList.add('mj-spin');
                setTimeout(function() {
                    icon.classList.remove('mj-spin');
                    self.s.license_status    = 'Active';
                    self.s.license_last_check = new Date().toLocaleString('vi-VN');
                    window._mjDnsToast('success', 'License hợp lệ', 'Trạng thái: Active');
                }, 1200);
            }
        };
    });
});
})();

/* == templates/admin/snapshot_rollback.tpl == */
(function () {
document.addEventListener('alpine:init', () => {
    Alpine.data('snapshotRollback', () => ({
        domainName: MJDNS_SNAP_DOMAIN,
        snapshots: [
            { id: 101, date: '25/02/2026 02:00', type: 'Nightly backup', records: 15 },
            { id: 100, date: '24/02/2026 02:00', type: 'Nightly backup', records: 14 },
            { id: 99, date: '23/02/2026 15:30', type: 'Before template load', records: 12 }
        ],
        selectedSnapshot: 101,
        submitting: false,

        get previewData() {
            // Mock preview data based on selection
            if (this.selectedSnapshot == 101) {
                return {
                    unchanged: 13, deleted: 2, changed: 0, added: 0,
                    diffs: [
                        { class: 'mj-text-danger', text: '[-] A &nbsp;&nbsp;&nbsp;test &nbsp;&rarr; 1.2.3.4' },
                        { class: 'mj-text-danger', text: '[-] TXT _verify &rarr; google-site-verification=...' }
                    ]
                };
            }
            return { unchanged: 12, deleted: 0, changed: 0, added: 0, diffs: [] };
        },

        async confirmRollback() {
            var ok = await window._mjDnsConfirm({
                title:        'Xác nhận Rollback',
                message:      'Rollback sẽ ghi đè hệ thống bằng Snapshot này.\nMột snapshot backup nội bộ sẽ được tự động tạo trước khi ghi đè.',
                variant:      'warning',
                confirmLabel: 'Xác nhận Rollback',
                cancelLabel:  'Hủy'
            });
            if (!ok) return;

            this.submitting = true;
            setTimeout(() => {
                window._mjDnsToast('success', 'Job Khôi Phục', 'Đã tạo Job khôi phục. Dữ liệu đang đồng bộ xuống các Server DA.');
                setTimeout(() => {
                     window.location.href = '?module=mj_dns_manager&action=dns_editor&domain=' + this.domainName;
                }, 1500);
            }, 1000);
        }
    }));
});
})();

/* == templates/admin/templates.tpl == */
(function () {
document.addEventListener('alpine:init', function() {
    Alpine.data('templateManager', function() {
        return {
            templates: MJDNS_TEMPLATES_DATA || [],
            saving:    false,

            _fetch: function(payload) {
                return fetch('/modules/addons/mj_dns_manager/ajax.php?action=admin_template', {
                    method:  'POST',
                    headers: {
                        'Content-Type':  'application/json',
                        'X-CSRF-TOKEN':  MJDNS_CSRF_TOKEN
                    },
                    body: JSON.stringify(payload)
                }).then(function(r) { return r.json(); });
            },

            cloneTemplate: function(tpl) {
                var self = this;
                self.saving = true;
                self._fetch({ method: 'clone', id: tpl.id })
                .then(function(res) {
                    self.saving = false;
                    if (res.success && res.data && res.data.template) {
                        self.templates.push(res.data.template);
                        window._mjDnsToast('success', 'Đã nhân bản',
                            res.message || 'Nhân bản thành công.');
                    } else {
                        var msg = (res.error && res.error.message)
                            ? res.error.message : 'Lỗi nhân bản.';
                        window._mjDnsToast('error', 'Lỗi', msg);
                    }
                })
                .catch(function() {
                    self.saving = false;
                    window._mjDnsToast('error', 'Lỗi kết nối', 'Vui lòng thử lại.');
                });
            },

            setDefault: function(tpl) {
                var self = this;
                window._mjDnsConfirm({
                    title:        'Đặt làm mặc định?',
                    message:      'Template "' + tpl.name + '" sẽ dùng làm mặc định khi tạo domain mới.',
                    variant:      'info',
                    confirmLabel: 'Lưu thay đổi',
                    cancelLabel:  'Hủy'
                }).then(function(ok) {
                    if (!ok) return;
                    self.saving = true;
                    self._fetch({ method: 'set_default', id: tpl.id })
                    .then(function(res) {
                        self.saving = false;
                        if (res.success) {
                            self.templates.forEach(function(t) { t.is_default = false; });
                            var found = self.templates.find(function(t) { return t.id === tpl.id; });
                            if (found) found.is_default = true;
                            window._mjDnsToast('success', 'Đã cập nhật',
                                res.message || 'Đã đặt làm mặc định.');
                        } else {
                            var msg = (res.error && res.error.message)
                                ? res.error.message : 'Lỗi.';
                            window._mjDnsToast('error', 'Lỗi', msg);
                        }
                    })
                    .catch(function() {
                        self.saving = false;
                        window._mjDnsToast('error', 'Lỗi kết nối', 'Vui lòng thử lại.');
                    });
                });
            },

            deleteTemplate: function(tpl) {
                var self = this;
                window._mjDnsConfirm({
                    title:        'Xóa Template?',
                    message:      'Xóa vĩnh viễn "' + tpl.name + '"? Không thể hoàn tác.',
                    variant:      'danger',
                    confirmLabel: 'Xóa vĩnh viễn',
                    cancelLabel:  'Hủy'
                }).then(function(ok) {
                    if (!ok) return;
                    self.saving = true;
                    self._fetch({ method: 'delete', id: tpl.id })
                    .then(function(res) {
                        self.saving = false;
                        if (res.success) {
                            self.templates = self.templates.filter(function(t) {
                                return t.id !== tpl.id;
                            });
                            window._mjDnsToast('success', 'Đã xóa',
                                res.message || 'Template đã bị xóa.');
                        } else {
                            var msg = (res.error && res.error.message)
                                ? res.error.message : 'Lỗi xóa.';
                            window._mjDnsToast('error', 'Lỗi', msg);
                        }
                    })
                    .catch(function() {
                        self.saving = false;
                        window._mjDnsToast('error', 'Lỗi kết nối', 'Vui lòng thử lại.');
                    });
                });
            }
        };
    });
});
})();

/* == templates/admin/template_edit.tpl == */
(function () {
document.addEventListener('alpine:init', function() {
    Alpine.data('templateEditor', function() {
        return {
            isEdit: MJDNS_IS_EDIT,
            saving: false,
            form: {
                id:          null,
                name:        '',
                description: '',
                is_visible:  true,
                records:     []
            },

            init: function() {
                if (MJDNS_IS_EDIT && MJDNS_TEMPLATE_EDIT_DATA) {
                    var d = MJDNS_TEMPLATE_EDIT_DATA;
                    this.form = {
                        id:          d.id,
                        name:        d.name        || '',
                        description: d.description || '',
                        is_visible:  d.is_visible !== false,
                        records:     d.records     || []
                    };
                } else {
                    // Tạo mới: bắt đầu với 1 record rỗng
                    this.addEmptyRecord();
                }
            },

            addEmptyRecord: function() {
                this.form.records.push({
                    type:  'A',
                    name:  '',
                    value: '',
                    ttl:   3600,
                    prio:  null
                });
            },

            removeRecord: function(idx) {
                this.form.records.splice(idx, 1);
            },

            saveTemplate: function() {
                var self = this;

                if (!self.form.name.trim()) {
                    window._mjDnsToast('warning', 'Thiếu thông tin',
                        'Vui lòng điền tên Template.');
                    return;
                }

                // Validate records
                for (var i = 0; i < self.form.records.length; i++) {
                    var rec = self.form.records[i];
                    if (!rec.name.trim() || !rec.value.trim()) {
                        window._mjDnsToast('warning', 'Thiếu thông tin',
                            'Record #' + (i + 1) + ': tên và giá trị không được để trống.');
                        return;
                    }
                }

                self.saving = true;

                // Chuẩn hoá records: đổi 'prio' → 'priority' cho backend
                var records = self.form.records.map(function(rec) {
                    return {
                        type:     rec.type,
                        name:     rec.name,
                        value:    rec.value,
                        ttl:      parseInt(rec.ttl) || 3600,
                        priority: rec.prio !== null && rec.prio !== ''
                                    ? parseInt(rec.prio) : null
                    };
                });

                var payload = {
                    method:            'save',
                    id:                self.form.id || 0,
                    name:              self.form.name.trim(),
                    description:       self.form.description.trim(),
                    is_visible_client: self.form.is_visible ? 1 : 0,
                    records:           records
                };

                fetch('/modules/addons/mj_dns_manager/ajax.php?action=admin_template', {
                    method:  'POST',
                    headers: {
                        'Content-Type': 'application/json',
                        'X-CSRF-TOKEN': MJDNS_CSRF_TOKEN
                    },
                    body: JSON.stringify(payload)
                })
                .then(function(r) { return r.json(); })
                .then(function(res) {
                    self.saving = false;
                    if (res.success) {
                        window._mjDnsToast('success', 'Thành công',
                            res.message || 'Template đã được lưu.');
                        // Redirect về danh sách sau 800ms để toast hiển thị
                        setTimeout(function() {
                            window.location.href = MJDNS_ADMIN_MODULELINK
                                + '&action=templates';
                        }, 800);
                    } else {
                        var msg = (res.error && res.error.message)
                            ? res.error.message : 'Lỗi không xác định.';
                        window._mjDnsToast('error', 'Lỗi lưu template', msg);
                    }
                })
                .catch(function() {
                    self.saving = false;
                    window._mjDnsToast('error', 'Lỗi kết nối', 'Vui lòng thử lại.');
                });
            }
        };
    });
});
})();


/* ============================================================
 * 40-client.part.js — MJ DNS Manager · Client-area JS logic
 * Assembled into assets/js/mj-dns.js by the build process.
 * ZERO Smarty syntax in this file.
 * ============================================================ */

/* == templates/client/partials/toast.tpl == */
(function () {
    // Client-only: trang admin dùng biến thể trong core (tránh đè Alpine.data trùng tên).
    if (((window.mjDnsConfig || {}).context) === 'admin') { return; }
    function showToast(title, msg, type) {
        type = type || 'success';
        window.dispatchEvent(new CustomEvent('show-toast', { detail: { title: title, msg: msg, type: type } }));
    }
    window.showToast = showToast;
})();

/* == templates/client/partials/confirm_modal.tpl == */
(function () {
    // Client-only: trang admin dùng biến thể trong core (tránh đè Alpine.data trùng tên).
    if (((window.mjDnsConfig || {}).context) === 'admin') { return; }
    document.addEventListener('alpine:init', function() {
        Alpine.data('mjDnsConfirmModal', function() {
            return {
                show: false,
                title: '',
                msg: '',
                variant: 'danger',
                okText: 'Xác nhận',
                cancelText: 'Hủy',
                _resolve: null,

                init: function() {
                    var self = this;
                    window.addEventListener('show-confirm', function(e) {
                        self.open(e.detail);
                    });
                },

                open: function(opts) {
                    this.title      = opts.title      || 'Xác nhận';
                    this.msg        = opts.msg        || '';
                    this.variant    = opts.variant    || 'danger';
                    this.okText     = opts.okText     || 'Xác nhận';
                    this.cancelText = opts.cancelText || 'Hủy';
                    this.show = true;
                    var self = this;
                    return new Promise(function(resolve) {
                        self._resolve = resolve;
                    });
                },

                onOk: function() {
                    this.show = false;
                    this._resolve = null;
                    window.dispatchEvent(new CustomEvent('confirm-result', { detail: { ok: true } }));
                },

                onCancel: function() {
                    this.show = false;
                    this._resolve = null;
                    window.dispatchEvent(new CustomEvent('confirm-result', { detail: { ok: false } }));
                }
            };
        });
    });

    /**
     * mjDnsConfirm(opts) — Thay thế confirm() native
     * opts: { title, msg, variant: 'danger'|'warning'|'info', okText, cancelText }
     * Returns: Promise<boolean>
     */
    function mjDnsConfirm(opts) {
        return new Promise(function(resolve) {
            function handler(e) {
                window.removeEventListener('confirm-result', handler);
                resolve(e.detail.ok);
            }
            window.addEventListener('confirm-result', handler);
            window.dispatchEvent(new CustomEvent('show-confirm', { detail: opts }));
        });
    }
    window.mjDnsConfirm = mjDnsConfirm;
})();

/* == templates/client/partials/tab_dnssec.tpl == */
(function () {
    // Client-only: trang admin dùng biến thể trong core (tránh đè Alpine.data trùng tên).
    if (((window.mjDnsConfig || {}).context) === 'admin') { return; }
    function mjDnsCopyDnssec(elementId) {
        var text = document.getElementById(elementId).innerText.trim();
        navigator.clipboard.writeText(text).then(function() {
            showToast('Đã copy', 'Dữ liệu đã được lưu vào khay nhớ tạm.', 'success');
        });
    }
    function mjDnsCopyAllDnssec() {
        var fields = ['ds-keytag', 'ds-algo', 'ds-dtype', 'ds-digest', 'ds-full'];
        var all = fields.map(function(id) {
            var el = document.getElementById(id);
            return el ? el.innerText.trim() : '';
        }).join('\n');
        navigator.clipboard.writeText(all).then(function() {
            showToast('Đã copy tất cả', 'Toàn bộ DS Record đã lưu vào khay nhớ tạm.', 'success');
        });
    }
    window.mjDnsCopyDnssec    = mjDnsCopyDnssec;
    window.mjDnsCopyAllDnssec = mjDnsCopyAllDnssec;
})();

/* == templates/client/domain_list.tpl == */
(function () {
    // Client-only: trang admin dùng biến thể trong core (tránh đè Alpine.data trùng tên).
    if (((window.mjDnsConfig || {}).context) === 'admin') { return; }
    function copyToClipboard(selector, btn) {
        var text = document.querySelector(selector).innerText.replace(/\s+/g, ' ').trim();
        navigator.clipboard.writeText(text).then(function() {
            var originalText = btn.innerHTML;
            btn.innerHTML = '<i class="bi bi-check2"></i> Đã copy';
            btn.classList.replace('btn-outline-secondary', 'btn-success');
            setTimeout(function() {
                btn.innerHTML = originalText;
                btn.classList.replace('btn-success', 'btn-outline-secondary');
            }, 2000);
        });
    }

    /* Delegated handler for [data-mj-copy-ns] buttons */
    document.addEventListener('click', function(e) {
        var btn = e.target.closest('[data-mj-copy-ns]');
        if (!btn) return;
        var selector = btn.getAttribute('data-mj-copy-ns');
        copyToClipboard(selector, btn);
    });
})();

/* == templates/client/dns_editor.tpl == */
(function () {
    // Client-only: trang admin dùng biến thể trong core (tránh đè Alpine.data trùng tên).
    if (((window.mjDnsConfig || {}).context) === 'admin') { return; }
        document.addEventListener('alpine:init', function() {
            Alpine.data('dnsEditor', function() {
                return {
                    domainId:   MJDNS_CONFIG.domainId,
                    domainName: MJDNS_CONFIG.domainName,
                    records:    MJDNS_CONFIG.records,
                    redirects:  MJDNS_CONFIG.redirects  || [],
                    emails:     MJDNS_CONFIG.emails      || [],
                    ddnsTokens: MJDNS_CONFIG.ddnsTokens  || [],
                    templates:  MJDNS_CONFIG.templates   || [],

                    confirmPreviewCheck: false,
                    filterType:  'all',
                    searchQuery: '',
                    activeTab:   'records',

                    // ── Inline editing state (DNS) ──
                    editingId:     null,
                    addingNew:     false,
                    editForm:      { type: 'A', name: '', value: '', ttl: 3600, priority: 10, weight: 0, port: 443 },
                    saving:        false,
                    isSyncingZone: false,
                    _originalForm: null,

                    // ── Inline editing state (Redirects) ──
                    editingRedirectId:  null,
                    addingNewRedirect:  false,
                    editRedirectForm:   { source: '/', destination: 'https://', type: '301', title: '' },
                    savingRedirect:     false,

                    // ── Inline editing state (Email) ──
                    editingEmailId: null,
                    addingNewEmail: false,
                    editEmailForm:  { source_local: '', destination_email: '', is_catchall: false },
                    savingEmail:    false,

                    // ── DNSSEC state ──
                    dnssecLoading: false,

                    // ── Templates state ──
                    showTemplatePreview:   false,
                    previewTemplateId:     null,
                    previewTemplateRecords: [],
                    applyingTemplate:      false,   // ← THÊM MỚI

                    // ── DDNS state ──
                    showCreateDdnsForm: false,
                    newDdnsToken:       { subdomain: '', label: '' },
                    ddnsCreating:       false,
                    ddnsNewRawToken:    null,

                    // ─────────────────────────────────────────────────────────
                    // Init
                    // ─────────────────────────────────────────────────────────
                    init: function() {
                        var self = this;
                        setInterval(function() { self.pollSyncStatus(); }, 5000);
                    },

                    // ─────────────────────────────────────────────────────────
                    // Helper: refresh CSRF token từ response
                    // ─────────────────────────────────────────────────────────
                    _refreshToken: function(res) {
                        if (res && res._token) {
                            MJDNS_CONFIG.csrfToken = res._token;
                        }
                    },

                    // ─────────────────────────────────────────────────────────
                    // Polling sync status
                    // ─────────────────────────────────────────────────────────
                    pollSyncStatus: function() {
                        var hasPending = this.records.some(function(r) {
                                return r.sync_status === 'syncing' || r.sync_status === 'pending';
                            })
                            || this.redirects.some(function(r) {
                                return r.sync_status === 'syncing' || r.sync_status === 'pending';
                            })
                            || this.emails.some(function(r) {
                                return r.sync_status === 'syncing' || r.sync_status === 'pending';
                            });

                        if (!hasPending) return;

                        var self = this;
                        fetch('/modules/addons/mj_dns_manager/ajax.php?action=sync_status_all', {
                            method: 'POST',
                            headers: {
                                'Content-Type': 'application/json',
                                'X-CSRF-Token': MJDNS_CONFIG.csrfToken
                            },
                            body: JSON.stringify({ domain_id: MJDNS_CONFIG.domainId })
                        })
                        .then(function(r) { return r.json(); })
                        .then(function(res) {
                            self._refreshToken(res);
                            if (!res.success || !res.data) return;
                            var statusMap = res.data.records || {};

                            self.records.forEach(function(r) {
                                if (r.sync_status === 'syncing' || r.sync_status === 'pending') {
                                    r.sync_status = statusMap[r.id] ? statusMap[r.id].status : 'complete';
                                    if (r.sync_status === 'complete' && r.pending_delete) {
                                        self.records = self.records.filter(function(x) { return x.id !== r.id; });
                                    }
                                }
                            });

                            self.redirects.forEach(function(r) {
                                if (r.sync_status === 'syncing' || r.sync_status === 'pending') {
                                    r.sync_status = statusMap[r.id] ? statusMap[r.id].status : 'complete';
                                    if (r.sync_status === 'complete' && r.pending_delete) {
                                        self.redirects = self.redirects.filter(function(x) { return x.id !== r.id; });
                                    }
                                }
                            });
                        })
                        .catch(function(err) { console.error('Polling error:', err); });
                    },

                    // ─────────────────────────────────────────────────────────
                    // Sync Zone
                    // ─────────────────────────────────────────────────────────
                    syncZone: function() {
                        var self = this;
                        mjDnsConfirm({
                            title:   'Đồng bộ từ máy chủ',
                            msg:     'Bạn có chắc muốn đồng bộ lại toàn bộ bản ghi từ máy chủ? Các thiết lập chưa lưu hoặc đang lỗi có thể bị ghi đè.',
                            variant: 'warning',
                            okText:  'Đồng bộ ngay'
                        }).then(function(ok) {
                            if (!ok) return;
                            self.isSyncingZone = true;

                            window.dispatchEvent(new CustomEvent('show-toast', {
                                detail: { title: 'Đang kết nối', msg: 'Đang lấy dữ liệu mới nhất từ máy chủ...', type: 'warning' }
                            }));

                            fetch('/modules/addons/mj_dns_manager/ajax.php?action=sync_zone', {
                                method: 'POST',
                                headers: {
                                    'Content-Type': 'application/json',
                                    'X-CSRF-Token': MJDNS_CONFIG.csrfToken
                                },
                                body: JSON.stringify({ domain_id: MJDNS_CONFIG.domainId })
                            })
                            .then(function(r) { return r.text(); })
                            .then(function(text) {
                                var res;
                                try { res = JSON.parse(text); } catch(e) {
                                    self.isSyncingZone = false;
                                    window.dispatchEvent(new CustomEvent('show-toast', {
                                        detail: { title: 'Lỗi server', msg: 'Phản hồi không hợp lệ.', type: 'danger' }
                                    }));
                                    return;
                                }
                                self._refreshToken(res);
                                if (!res.success) {
                                    self.isSyncingZone = false;
                                    var errMsg = (res.error && res.error.message) ? res.error.message : 'Lỗi gửi yêu cầu đồng bộ.';
                                    window.dispatchEvent(new CustomEvent('show-toast', {
                                        detail: { title: 'Đồng bộ thất bại', msg: errMsg, type: 'danger' }
                                    }));
                                    return;
                                }
                                var batchId = (res.data && res.data.batch_id) ? res.data.batch_id : '';
                                if (!batchId) {
                                    self.isSyncingZone = false;
                                    window.dispatchEvent(new CustomEvent('show-toast', {
                                        detail: { title: 'Đã gửi yêu cầu', msg: 'Đồng bộ đang chạy nền.', type: 'warning' }
                                    }));
                                    return;
                                }
                                window.dispatchEvent(new CustomEvent('show-toast', {
                                    detail: { title: 'Đang đồng bộ', msg: 'Đang lấy bản ghi mới nhất từ máy chủ, vui lòng đợi...', type: 'warning' }
                                }));
                                self._pollSyncZone(batchId, 0);
                            })
                            .catch(function() {
                                self.isSyncingZone = false;
                                window.dispatchEvent(new CustomEvent('show-toast', {
                                    detail: { title: 'Lỗi kết nối', msg: 'Vui lòng kiểm tra mạng và thử lại.', type: 'danger' }
                                }));
                            });
                        });
                    },

                    // ─────────────────────────────────────────────────────────
                    // Poll trạng thái đồng bộ zone (SYNC_ZONE) → reload khi xong
                    // ─────────────────────────────────────────────────────────
                    _pollSyncZone: function(batchId, attempt) {
                        var self = this;
                        if (attempt > 30) {
                            self.isSyncingZone = false;
                            window.dispatchEvent(new CustomEvent('show-toast', {
                                detail: { title: 'Đang xử lý', msg: 'Đồng bộ vẫn đang chạy nền. Hãy tải lại trang sau giây lát.', type: 'warning' }
                            }));
                            return;
                        }
                        setTimeout(function() {
                            fetch('/modules/addons/mj_dns_manager/ajax.php?action=sync_status', {
                                method: 'POST',
                                headers: {
                                    'Content-Type': 'application/json',
                                    'X-CSRF-Token': MJDNS_CONFIG.csrfToken
                                },
                                body: JSON.stringify({ domain_id: MJDNS_CONFIG.domainId, batch_id: batchId })
                            })
                            .then(function(r) { return r.json(); })
                            .then(function(res) {
                                self._refreshToken(res);
                                var status = (res.data && res.data.status) ? res.data.status : '';
                                if (status === 'complete') {
                                    self.isSyncingZone = false;
                                    window.dispatchEvent(new CustomEvent('show-toast', {
                                        detail: { title: 'Thành công', msg: 'Đã đồng bộ bản ghi từ máy chủ!', type: 'success' }
                                    }));
                                    setTimeout(function() { window.location.reload(); }, 800);
                                } else if (status === 'failed' || status === 'permanently_failed' || status === 'cancelled') {
                                    self.isSyncingZone = false;
                                    window.dispatchEvent(new CustomEvent('show-toast', {
                                        detail: { title: 'Đồng bộ thất bại', msg: 'Máy chủ báo lỗi khi đồng bộ. Vui lòng thử lại sau.', type: 'danger' }
                                    }));
                                } else {
                                    self._pollSyncZone(batchId, attempt + 1);
                                }
                            })
                            .catch(function() { self._pollSyncZone(batchId, attempt + 1); });
                        }, 3000);
                    },

                    // ─────────────────────────────────────────────────────────
                    // Filtered records
                    // ─────────────────────────────────────────────────────────
                    get filteredRecords() {
                        var self = this;
                        return this.records.filter(function(record) {
                            var typeMatch   = self.filterType === 'all' || record.type === self.filterType;
                            var searchMatch = self.searchQuery === ''
                                || record.name.toLowerCase().indexOf(self.searchQuery.toLowerCase()) !== -1
                                || record.value.toLowerCase().indexOf(self.searchQuery.toLowerCase()) !== -1;
                            return typeMatch && searchMatch;
                        });
                    },

                    // ─────────────────────────────────────────────────────────
                    // Helpers
                    // ─────────────────────────────────────────────────────────
                    getTypeBadgeClass: function(type) {
                        var classes = {
                            'A':     'mj-badge-a',
                            'AAAA':  'mj-badge-aaaa',
                            'CNAME': 'mj-badge-cname',
                            'MX':    'mj-badge-mx',
                            'TXT':   'mj-badge-txt',
                            'SRV':   'mj-badge-srv',
                            'NS':    'mj-badge-ns',
                            'CAA':   'mj-badge-caa'
                        };
                        return 'badge-dns ' + (classes[type] || 'mj-badge-ns');
                    },

                    formatTTL: function(ttl) {
                        var map = { 60:'1m', 300:'5m', 1800:'30m', 3600:'1h', 14400:'4h', 43200:'12h', 86400:'24h' };
                        return map[ttl] || ttl + 's';
                    },

                    needsSrv: function(type)      { return type === 'SRV'; },
                    needsPriority: function(type)  { return type === 'MX' || type === 'SRV'; },
                    needsTitle: function(type)     { return type === 'masked'; },

                    // ─────────────────────────────────────────────────────────
                    // DNS Record CRUD
                    // ─────────────────────────────────────────────────────────
                    startAdd: function() {
                        this.cancelEdit();
                        this.addingNew = true;
                        this.editForm  = { type: 'A', name: '', value: '', ttl: 3600, priority: 10, weight: 0, port: 443 };
                    },

                    startEdit: function(record) {
                        this.addingNew  = false;
                        this.editingId  = record.id;
                        this.editForm   = {
                            type:     record.type,
                            name:     record.name === '@' ? this.domainName : record.name,
                            value:    record.value,
                            ttl:      record.ttl,
                            priority: record.priority  || 10,
                            weight:   record.weight    || 0,
                            port:     record.port      || 443
                        };
                        this._originalForm = {
                            name:     this.editForm.name,
                            value:    this.editForm.value,
                            ttl:      this.editForm.ttl,
                            priority: this.editForm.priority,
                            weight:   this.editForm.weight,
                            port:     this.editForm.port
                        };
                    },

                    cancelEdit: function() {
                        this.editingId     = null;
                        this.addingNew     = false;
                        this.saving        = false;
                        this._originalForm = null;
                    },

                    saveEdit: function() {
                        if (!this.editForm.value.trim()) {
                            window.dispatchEvent(new CustomEvent('show-toast', {
                                detail: { title: 'Lỗi', msg: 'Vui lòng nhập giá trị bản ghi', type: 'danger' }
                            }));
                            return;
                        }
                        var inputName = this.editForm.name.trim();
                        if (!inputName || inputName === this.domainName) {
                            this.editForm.name = '@';
                        }

                        if (!this.addingNew && this._originalForm) {
                            var orig = this._originalForm;
                            var cur  = this.editForm;
                            var curName  = (!cur.name.trim() || cur.name.trim() === this.domainName) ? '@' : cur.name.trim();
                            var origName = (!orig.name.trim() || orig.name.trim() === this.domainName) ? '@' : orig.name.trim();
                            var noChange = (
                                curName === origName &&
                                cur.value.trim() === String(orig.value).trim() &&
                                parseInt(cur.ttl) === parseInt(orig.ttl) &&
                                (parseInt(cur.priority) || 0) === (parseInt(orig.priority) || 0) &&
                                (parseInt(cur.weight)   || 0) === (parseInt(orig.weight)   || 0) &&
                                (parseInt(cur.port)     || 0) === (parseInt(orig.port)     || 0)
                            );
                            if (noChange) {
                                window.dispatchEvent(new CustomEvent('show-toast', {
                                    detail: { title: 'Không có thay đổi', msg: 'Vui lòng thay đổi ít nhất một trường trước khi lưu.', type: 'warning' }
                                }));
                                return;
                            }
                        }

                        this.saving = true;
                        var self    = this;
                        var action  = this.addingNew ? 'add_record' : 'edit_record';
                        var payload = {
                            domain_id: MJDNS_CONFIG.domainId,
                            type:      this.editForm.type,
                            name:      this.editForm.name,
                            value:     this.editForm.value,
                            ttl:       parseInt(this.editForm.ttl),
                            priority:  parseInt(this.editForm.priority) || 0,
                            weight:    parseInt(this.editForm.weight)   || 0,
                            port:      parseInt(this.editForm.port)     || 0
                        };
                        if (!this.addingNew) { payload.record_id = this.editingId; }

                        fetch('/modules/addons/mj_dns_manager/ajax.php?action=' + action, {
                            method: 'POST',
                            headers: {
                                'Content-Type': 'application/json',
                                'X-CSRF-Token': MJDNS_CONFIG.csrfToken
                            },
                            body: JSON.stringify(payload)
                        })
                        .then(function(r) { return r.json(); })
                        .then(function(res) {
                            self._refreshToken(res);
                            self.saving = false;
                            if (!res.success) {
                                var errMsg = res.error && res.error.code === 'QUOTA_EXCEEDED'
                                    ? res.error.message
                                    : (res.error ? res.error.message : 'Lỗi không xác định');
                                window.dispatchEvent(new CustomEvent('show-toast', {
                                    detail: { title: 'Lỗi', msg: errMsg, type: 'danger' }
                                }));
                                return;
                            }
                            if (self.addingNew) {
                                var newRecord = Object.assign({}, payload, {
                                    id:             res.data.record_id,
                                    is_system:      false,
                                    is_locked:      false,
                                    sync_status:    'syncing',
                                    pending_delete: false
                                });
                                self.records.unshift(newRecord);
                                window.dispatchEvent(new CustomEvent('show-toast', {
                                    detail: { title: 'Đã thêm', msg: self.editForm.type + ' ' + self.editForm.name + ' đang đồng bộ...', type: 'success' }
                                }));
                            } else {
                                var idx = -1;
                                for (var i = 0; i < self.records.length; i++) {
                                    if (self.records[i].id === self.editingId) { idx = i; break; }
                                }
                                if (idx >= 0) {
                                    Object.assign(self.records[idx], payload, { sync_status: 'syncing' });
                                }
                                window.dispatchEvent(new CustomEvent('show-toast', {
                                    detail: { title: 'Đã cập nhật', msg: self.editForm.type + ' ' + self.editForm.name + ' đang đồng bộ...', type: 'success' }
                                }));
                            }
                            self.cancelEdit();
                        })
                        .catch(function() {
                            self.saving = false;
                            window.dispatchEvent(new CustomEvent('show-toast', {
                                detail: { title: 'Lỗi kết nối', msg: 'Vui lòng thử lại.', type: 'danger' }
                            }));
                        });
                    },

                    deleteRecord: function(record) {
                        var self = this;
                        mjDnsConfirm({
                            title:   'Xóa bản ghi DNS',
                            msg:     'Bạn có chắc muốn xóa bản ghi:\n' + record.type + ' · ' + record.name + '\n\nHành động này sẽ được đồng bộ lên máy chủ.',
                            variant: 'danger',
                            okText:  'Xóa'
                        }).then(function(ok) {
                            if (!ok) return;
                            record.pending_delete = true;
                            record.sync_status    = 'syncing';
                            fetch('/modules/addons/mj_dns_manager/ajax.php?action=delete_record', {
                                method: 'POST',
                                headers: {
                                    'Content-Type': 'application/json',
                                    'X-CSRF-Token': MJDNS_CONFIG.csrfToken
                                },
                                body: JSON.stringify({ domain_id: MJDNS_CONFIG.domainId, record_id: record.id })
                            })
                            .then(function(r) { return r.json(); })
                            .then(function(res) {
                                self._refreshToken(res);
                                if (!res.success) {
                                    record.pending_delete = false;
                                    record.sync_status    = 'complete';
                                    window.dispatchEvent(new CustomEvent('show-toast', {
                                        detail: { title: 'Lỗi', msg: res.error.message, type: 'danger' }
                                    }));
                                    return;
                                }
                                window.dispatchEvent(new CustomEvent('show-toast', {
                                    detail: { title: 'Đang xóa', msg: 'Bản ghi ' + record.name + ' đang được xóa...', type: 'warning' }
                                }));
                            })
                            .catch(function() {
                                record.pending_delete = false;
                                record.sync_status    = 'complete';
                                window.dispatchEvent(new CustomEvent('show-toast', {
                                    detail: { title: 'Lỗi kết nối', msg: 'Vui lòng thử lại.', type: 'danger' }
                                }));
                            });
                        });
                    },

                    retryRecord: function(id) {
                        for (var i = 0; i < this.records.length; i++) {
                            if (this.records[i].id === id) { this.records[i].sync_status = 'syncing'; break; }
                        }
                        window.dispatchEvent(new CustomEvent('show-toast', {
                            detail: { title: 'Đang thử lại', msg: 'Hệ thống đang đồng bộ lại...', type: 'warning' }
                        }));
                    },

                    // ─────────────────────────────────────────────────────────
                    // Redirects CRUD
                    // ─────────────────────────────────────────────────────────
                    startAddRedirect: function() {
                        this.cancelEditRedirect();
                        this.addingNewRedirect  = true;
                        this.editRedirectForm   = { source: '/', destination: 'https://', type: '301', title: '' };
                    },

                    startEditRedirect: function(redirect) {
                        this.addingNewRedirect  = false;
                        this.editingRedirectId  = redirect.id;
                        this.editRedirectForm   = {
                            source:      redirect.source_path,
                            destination: redirect.destination_url,
                            type:        redirect.type,
                            title:       redirect.masked_title || ''
                        };
                    },

                    cancelEditRedirect: function() {
                        this.editingRedirectId = null;
                        this.addingNewRedirect  = false;
                        this.savingRedirect     = false;
                    },

                    saveEditRedirect: function() {
                        var src = this.editRedirectForm.source.trim();
                        var dst = this.editRedirectForm.destination.trim();
                        if (!src || !dst) {
                            window.dispatchEvent(new CustomEvent('show-toast', {
                                detail: { title: 'Lỗi', msg: 'Vui lòng nhập nguồn và đích chuyển hướng', type: 'danger' }
                            }));
                            return;
                        }
                        if (src.charAt(0) !== '/') {
                            window.dispatchEvent(new CustomEvent('show-toast', {
                                detail: { title: 'Lỗi', msg: 'Đường dẫn nguồn phải bắt đầu bằng /', type: 'danger' }
                            }));
                            return;
                        }
                        if (dst.indexOf('http://') !== 0 && dst.indexOf('https://') !== 0) {
                            window.dispatchEvent(new CustomEvent('show-toast', {
                                detail: { title: 'Lỗi', msg: 'URL đích phải bắt đầu bằng http:// hoặc https://', type: 'danger' }
                            }));
                            return;
                        }
                        if (!this.addingNewRedirect) {
                            window.dispatchEvent(new CustomEvent('show-toast', {
                                detail: { title: 'Thông báo', msg: 'Chỉnh sửa redirect chưa được hỗ trợ. Hãy xóa và tạo lại.', type: 'warning' }
                            }));
                            return;
                        }
                        this.savingRedirect = true;
                        var self = this;
                        fetch('/modules/addons/mj_dns_manager/ajax.php?action=add_redirect', {
                            method: 'POST',
                            headers: {
                                'Content-Type': 'application/json',
                                'X-CSRF-Token': MJDNS_CONFIG.csrfToken
                            },
                            body: JSON.stringify({
                                domain_id:       MJDNS_CONFIG.domainId,
                                source_path:     self.editRedirectForm.source,
                                destination_url: self.editRedirectForm.destination,
                                type:            self.editRedirectForm.type
                            })
                        })
                        .then(function(r) { return r.json(); })
                        .then(function(res) {
                            self._refreshToken(res);
                            self.savingRedirect = false;
                            if (!res.success) {
                                window.dispatchEvent(new CustomEvent('show-toast', {
                                    detail: { title: 'Lỗi thêm redirect', msg: res.error ? res.error.message : 'Lỗi không xác định', type: 'danger' }
                                }));
                                return;
                            }
                            var newRedirect = {
                                id:              res.data.redirect_id,
                                source_path:     self.editRedirectForm.source,
                                destination_url: self.editRedirectForm.destination,
                                type:            self.editRedirectForm.type,
                                sync_status:     'syncing',
                                pending_delete:  false
                            };
                            self.redirects.unshift(newRedirect);
                            window.dispatchEvent(new CustomEvent('show-toast', {
                                detail: { title: 'Đã thêm', msg: 'Chuyển hướng từ ' + self.editRedirectForm.source + ' đang đồng bộ...', type: 'success' }
                            }));
                            self.cancelEditRedirect();
                        })
                        .catch(function() {
                            self.savingRedirect = false;
                            window.dispatchEvent(new CustomEvent('show-toast', {
                                detail: { title: 'Lỗi kết nối', msg: 'Vui lòng thử lại.', type: 'danger' }
                            }));
                        });
                    },

                    deleteRedirect: function(redirect) {
                        var self = this;
                        mjDnsConfirm({
                            title:   'Xóa chuyển hướng',
                            msg:     'Bạn có chắc muốn xóa chuyển hướng:\n' + redirect.source_path + ' → ' + redirect.destination_url,
                            variant: 'danger',
                            okText:  'Xóa'
                        }).then(function(ok) {
                            if (!ok) return;
                            redirect.pending_delete = true;
                            redirect.sync_status    = 'syncing';
                            fetch('/modules/addons/mj_dns_manager/ajax.php?action=delete_redirect', {
                                method: 'POST',
                                headers: {
                                    'Content-Type': 'application/json',
                                    'X-CSRF-Token': MJDNS_CONFIG.csrfToken
                                },
                                body: JSON.stringify({ domain_id: MJDNS_CONFIG.domainId, redirect_id: redirect.id })
                            })
                            .then(function(r) { return r.json(); })
                            .then(function(res) {
                                self._refreshToken(res);
                                if (!res.success) {
                                    redirect.pending_delete = false;
                                    redirect.sync_status    = 'complete';
                                    window.dispatchEvent(new CustomEvent('show-toast', {
                                        detail: { title: 'Lỗi', msg: res.error ? res.error.message : 'Lỗi xóa redirect', type: 'danger' }
                                    }));
                                }
                            })
                            .catch(function() {
                                redirect.pending_delete = false;
                                redirect.sync_status    = 'complete';
                            });
                        });
                    },

                    retryRedirect: function(id) {
                        for (var i = 0; i < this.redirects.length; i++) {
                            if (this.redirects[i].id === id) { this.redirects[i].sync_status = 'syncing'; break; }
                        }
                    },

                    getTypeRedirectBadgeClass: function(type) {
                        var classes = { '301': 'bg-primary', '302': 'bg-info text-dark', 'masked': 'bg-dark' };
                        return classes[type] || 'bg-secondary';
                    },

                    getTypeRedirectLabel: function(type) {
                        var labels = { '301': 'Vĩnh viễn', '302': 'Tạm thời', 'masked': 'Trang ảo' };
                        return labels[type] || '';
                    },

                    // ─────────────────────────────────────────────────────────
                    // Email Forwards
                    // ─────────────────────────────────────────────────────────
                    startAddEmail: function() {
                        this.cancelEditEmail();
                        this.addingNewEmail = true;
                        this.editEmailForm  = { source_local: '', destination_email: '', is_catchall: false };
                    },

                    cancelEditEmail: function() {
                        this.editingEmailId = null;
                        this.addingNewEmail  = false;
                        this.savingEmail     = false;
                    },

                    saveEditEmail: function() {
                        var self = this;

                        var isCatchall = self.editEmailForm.is_catchall;
                        var srcLocal   = (self.editEmailForm.source_local || '').trim();
                        var destEmail  = (self.editEmailForm.destination_email || '').trim();

                        // Validate
                        if (!isCatchall && srcLocal === '') {
                            window.dispatchEvent(new CustomEvent('show-toast', {
                                detail: { title: 'Lỗi', msg: 'Vui lòng nhập địa chỉ nguồn.', type: 'danger' }
                            }));
                            return;
                        }
                        if (destEmail === '') {
                            window.dispatchEvent(new CustomEvent('show-toast', {
                                detail: { title: 'Lỗi', msg: 'Vui lòng nhập email đích.', type: 'danger' }
                            }));
                            return;
                        }

                        self.savingEmail = true;

                        fetch('/modules/addons/mj_dns_manager/ajax.php?action=email_fwd_create', {
                            method: 'POST',
                            headers: {
                                'Content-Type': 'application/json',
                                'X-CSRF-Token': MJDNS_CONFIG.csrfToken
                            },
                            body: JSON.stringify({
                                domain_id:         MJDNS_CONFIG.domainId,
                                source_local:      srcLocal,
                                destination_email: destEmail,
                                is_catchall:       isCatchall ? 1 : 0
                            })
                        })
                        .then(function(r) { return r.json(); })
                        .then(function(res) {
                            self._refreshToken(res);
                            self.savingEmail = false;
                            if (!res.success) {
                                var msg = (res.error && res.error.message) ? res.error.message : 'Lỗi không xác định.';
                                window.dispatchEvent(new CustomEvent('show-toast', {
                                    detail: { title: 'Lỗi', msg: msg, type: 'danger' }
                                }));
                                return;
                            }
                            // Thêm vào danh sách local
                            var domainName = self.domainName;
                            var newEmail = {
                                id:                res.data.forward_id,
                                source_local:      isCatchall ? '*' : srcLocal,
                                source_email:      isCatchall ? '*@' + domainName : srcLocal + '@' + domainName,
                                destination_email: destEmail,
                                is_catchall:       isCatchall,
                                sync_status:       'pending',
                                pending_delete:    false
                            };
                            self.emails.unshift(newEmail);
                            self.cancelEditEmail();
                            window.dispatchEvent(new CustomEvent('show-toast', {
                                detail: {
                                    title: 'Đã thêm',
                                    msg:   'Forwarder ' + newEmail.source_email + ' đang đồng bộ...',
                                    type:  'success'
                                }
                            }));
                        })
                        .catch(function() {
                            self.savingEmail = false;
                            window.dispatchEvent(new CustomEvent('show-toast', {
                                detail: { title: 'Lỗi kết nối', msg: 'Vui lòng thử lại.', type: 'danger' }
                            }));
                        });
                    },

                    deleteEmail: function(email) {
                        var self = this;
                        mjDnsConfirm({
                            title:   'Xóa email forwarder',
                            msg:     'Bạn có chắc muốn xóa:\n' + email.source_email + ' → ' + email.destination_email,
                            variant: 'danger',
                            okText:  'Xóa'
                        }).then(function(ok) {
                            if (!ok) return;
                            email.pending_delete = true;
                            email.sync_status    = 'pending';

                            fetch('/modules/addons/mj_dns_manager/ajax.php?action=email_fwd_delete', {
                                method: 'POST',
                                headers: {
                                    'Content-Type': 'application/json',
                                    'X-CSRF-Token': MJDNS_CONFIG.csrfToken
                                },
                                body: JSON.stringify({
                                    domain_id:  MJDNS_CONFIG.domainId,
                                    forward_id: email.id
                                })
                            })
                            .then(function(r) { return r.json(); })
                            .then(function(res) {
                                self._refreshToken(res);
                                if (!res.success) {
                                    email.pending_delete = false;
                                    email.sync_status    = 'synced';
                                    var msg = (res.error && res.error.message) ? res.error.message : 'Lỗi xóa.';
                                    window.dispatchEvent(new CustomEvent('show-toast', {
                                        detail: { title: 'Lỗi', msg: msg, type: 'danger' }
                                    }));
                                    return;
                                }
                                // Xóa khỏi local list ngay
                                self.emails = self.emails.filter(function(e) { return e.id !== email.id; });
                                window.dispatchEvent(new CustomEvent('show-toast', {
                                    detail: { title: 'Đã xóa', msg: 'Email forwarder đã được xóa.', type: 'warning' }
                                }));
                            })
                            .catch(function() {
                                email.pending_delete = false;
                                email.sync_status    = 'synced';
                                window.dispatchEvent(new CustomEvent('show-toast', {
                                    detail: { title: 'Lỗi kết nối', msg: 'Vui lòng thử lại.', type: 'danger' }
                                }));
                            });
                        });
                    },

                    retryEmail: function(id) {
                        // Hiện tại service chưa có retry endpoint — chỉ báo trạng thái
                        for (var i = 0; i < this.emails.length; i++) {
                            if (this.emails[i].id === id) {
                                this.emails[i].sync_status = 'pending';
                                break;
                            }
                        }
                        window.dispatchEvent(new CustomEvent('show-toast', {
                            detail: { title: 'Đang thử lại', msg: 'Hệ thống đang đồng bộ lại...', type: 'warning' }
                        }));
                    },

                    // ─────────────────────────────────────────────────────────
                    // DNSSEC
                    // ─────────────────────────────────────────────────────────
                    toggleDnssec: function(enable) {
                        var self    = this;
                        var title   = enable ? 'Bật DNSSEC' : 'Tắt DNSSEC';
                        var msg     = enable
                            ? 'Bật DNSSEC cho domain này? Sau khi bật bạn cần mang DS Record tới nhà đăng ký tên miền để hoàn tất.'
                            : 'Hãy XÓA DS Record tại nhà đăng ký TRƯỚC, sau đó mới tắt. Nếu tắt trước domain có thể không phân giải được.';
                        var variant = enable ? 'warning' : 'danger';
                        mjDnsConfirm({ title: title, msg: msg, variant: variant, okText: enable ? 'Bật DNSSEC' : 'Tắt DNSSEC' })
                        .then(function(ok) {
                            if (!ok) return;
                            self.dnssecLoading = true;
                            fetch('/modules/addons/mj_dns_manager/ajax.php?action=dnssec_toggle', {
                                method: 'POST',
                                headers: { 'Content-Type': 'application/json', 'X-CSRF-Token': MJDNS_CONFIG.csrfToken },
                                body: JSON.stringify({ domain_id: MJDNS_CONFIG.domainId, enable: enable ? 1 : 0 })
                            })
                            .then(function(r) { return r.json(); })
                            .then(function(res) {
                                self._refreshToken(res);
                                self.dnssecLoading = false;
                                var type = res.success ? 'warning' : 'danger';
                                var title2 = res.success ? (enable ? 'Đang bật DNSSEC' : 'Đang tắt DNSSEC') : 'Lỗi';
                                var msg2   = res.success ? res.message : (res.error ? res.error.message : 'Lỗi không xác định');
                                window.dispatchEvent(new CustomEvent('show-toast', {
                                    detail: { title: title2, msg: msg2, type: type }
                                }));
                            })
                            .catch(function() {
                                self.dnssecLoading = false;
                                window.dispatchEvent(new CustomEvent('show-toast', {
                                    detail: { title: 'Lỗi kết nối', msg: 'Vui lòng thử lại.', type: 'danger' }
                                }));
                            });
                        });
                    },

                    // ─────────────────────────────────────────────────────────
                    // DDNS
                    // ─────────────────────────────────────────────────────────
                    toggleDdnsDetail: function(id) {
                        var idx = this.ddnsTokens.findIndex(function(t) { return t.id === id; });
                        if (idx !== -1) {
                            this.ddnsTokens[idx] = Object.assign({}, this.ddnsTokens[idx], {
                                showDetail: !this.ddnsTokens[idx].showDetail
                            });
                        }
                    },

                    toggleDdnsActive: function(id) {
                        var self = this;
                        fetch('/modules/addons/mj_dns_manager/ajax.php?action=ddns_toggle', {
                            method: 'POST',
                            headers: { 'Content-Type': 'application/json', 'X-CSRF-Token': MJDNS_CONFIG.csrfToken },
                            body: JSON.stringify({ token_id: id })
                        })
                        .then(function(r) { return r.json(); })
                        .then(function(res) {
                            self._refreshToken(res);
                            if (!res.success) {
                                window.dispatchEvent(new CustomEvent('show-toast', {
                                    detail: { title: 'Lỗi', msg: (res.error && res.error.message) ? res.error.message : 'Lỗi', type: 'danger' }
                                }));
                                return;
                            }
                            var idx = self.ddnsTokens.findIndex(function(t) { return t.id === id; });
                            if (idx !== -1) {
                                self.ddnsTokens[idx] = Object.assign({}, self.ddnsTokens[idx], { active: res.is_active });
                            }
                            window.dispatchEvent(new CustomEvent('show-toast', {
                                detail: { title: res.is_active ? 'Đã bật' : 'Đã tắt', msg: res.message, type: res.is_active ? 'success' : 'warning' }
                            }));
                        });
                    },

                    deleteDdnsToken: function(id) {
                        var token = this.ddnsTokens.find(function(t) { return t.id === id; });
                        if (!token) return;
                        var self = this;
                        mjDnsConfirm({
                            title: 'Xóa DDNS Token',
                            msg:   'Xóa DDNS token cho ' + token.subdomain + '?\nThiết bị sẽ không thể cập nhật IP tự động nữa.',
                            variant: 'danger', okText: 'Xóa token'
                        }).then(function(ok) {
                            if (!ok) return;
                            fetch('/modules/addons/mj_dns_manager/ajax.php?action=ddns_delete', {
                                method: 'POST',
                                headers: { 'Content-Type': 'application/json', 'X-CSRF-Token': MJDNS_CONFIG.csrfToken },
                                body: JSON.stringify({ token_id: id })
                            })
                            .then(function(r) { return r.json(); })
                            .then(function(res) {
                                self._refreshToken(res);
                                if (!res.success) {
                                    window.dispatchEvent(new CustomEvent('show-toast', {
                                        detail: { title: 'Lỗi', msg: res.error || 'Lỗi xóa token', type: 'danger' }
                                    }));
                                    return;
                                }
                                self.ddnsTokens = self.ddnsTokens.filter(function(t) { return t.id !== id; });
                                window.dispatchEvent(new CustomEvent('show-toast', {
                                    detail: { title: 'Đã xóa', msg: 'Token ' + token.subdomain + ' đã bị xóa', type: 'warning' }
                                }));
                            });
                        });
                    },

                    createDdnsToken: function() {
                        if (!this.newDdnsToken.subdomain.trim()) {
                            window.dispatchEvent(new CustomEvent('show-toast', {
                                detail: { title: 'Lỗi', msg: 'Vui lòng nhập subdomain', type: 'danger' }
                            }));
                            return;
                        }
                        this.ddnsCreating = true;
                        var self = this;
                        fetch('/modules/addons/mj_dns_manager/ajax.php?action=ddns_create', {
                            method: 'POST',
                            headers: { 'Content-Type': 'application/json', 'X-CSRF-Token': MJDNS_CONFIG.csrfToken },
                            body: JSON.stringify({
                                domain_id: MJDNS_CONFIG.domainId,
                                subdomain: self.newDdnsToken.subdomain,
                                label:     self.newDdnsToken.label
                            })
                        })
                        .then(function(r) { return r.json(); })
                        .then(function(res) {
                            self._refreshToken(res);
                            self.ddnsCreating = false;
                            if (!res.success) {
                                window.dispatchEvent(new CustomEvent('show-toast', {
                                    detail: { title: 'Lỗi tạo token', msg: res.error || 'Lỗi', type: 'danger' }
                                }));
                                return;
                            }
                            var rawToken   = res.data.raw_token;
                            var correctUrl = window.location.origin + '/modules/addons/mj_dns_manager/ddns.php?token=' + rawToken;
                            var newToken   = Object.assign({}, res.data, { showDetail: true, token_url: correctUrl });
                            self.ddnsTokens.unshift(newToken);
                            self.ddnsNewRawToken        = rawToken;
                            self.newDdnsToken           = { subdomain: '', label: '' };
                            self.showCreateDdnsForm     = false;
                            window.dispatchEvent(new CustomEvent('show-toast', {
                                detail: { title: 'Thành công', msg: 'DDNS Token đã được tạo', type: 'success' }
                            }));
                        })
                        .catch(function() {
                            self.ddnsCreating = false;
                            window.dispatchEvent(new CustomEvent('show-toast', {
                                detail: { title: 'Lỗi kết nối', msg: 'Vui lòng thử lại.', type: 'danger' }
                            }));
                        });
                    },

                    regenerateDdnsToken: function(id) {
                        var self = this;
                        mjDnsConfirm({
                            title: 'Tạo lại DDNS Token',
                            msg:   'URL cũ sẽ không còn hoạt động. Bạn cần cập nhật lại cấu hình trên thiết bị.',
                            variant: 'warning', okText: 'Tạo lại token'
                        }).then(function(ok) {
                            if (!ok) return;
                            fetch('/modules/addons/mj_dns_manager/ajax.php?action=ddns_regenerate', {
                                method: 'POST',
                                headers: { 'Content-Type': 'application/json', 'X-CSRF-Token': MJDNS_CONFIG.csrfToken },
                                body: JSON.stringify({ token_id: id })
                            })
                            .then(function(r) { return r.json(); })
                            .then(function(res) {
                                self._refreshToken(res);
                                if (!res.success) {
                                    window.dispatchEvent(new CustomEvent('show-toast', {
                                        detail: { title: 'Lỗi', msg: res.error || 'Lỗi tạo lại token', type: 'danger' }
                                    }));
                                    return;
                                }
                                var rawToken   = res.data.raw_token;
                                var correctUrl = window.location.origin + '/modules/addons/mj_dns_manager/ddns.php?token=' + rawToken;
                                var idx = self.ddnsTokens.findIndex(function(t) { return t.id === id; });
                                if (idx !== -1) {
                                    self.ddnsTokens[idx] = Object.assign({}, res.data, { showDetail: true, token_url: correctUrl });
                                }
                                self.ddnsNewRawToken = rawToken;
                                window.dispatchEvent(new CustomEvent('show-toast', {
                                    detail: { title: 'Token mới đã tạo', msg: 'Cập nhật URL mới trên thiết bị của bạn.', type: 'warning' }
                                }));
                            })
                            .catch(function() {
                                window.dispatchEvent(new CustomEvent('show-toast', {
                                    detail: { title: 'Lỗi kết nối', msg: 'Vui lòng thử lại.', type: 'danger' }
                                }));
                            });
                        });
                    },

                    copyDdnsUrl: function(tokenId) {
                        var token = this.ddnsTokens.find(function(t) { return t.id === tokenId; });
                        if (!token) return;
                        navigator.clipboard.writeText(token.token_url).then(function() {
                            window.dispatchEvent(new CustomEvent('show-toast', {
                                detail: { title: 'Đã copy', msg: 'URL đã được lưu vào khay nhớ tạm', type: 'success' }
                            }));
                        });
                    },

                    copyDdnsMikrotik: function(tokenId) {
                        var token = this.ddnsTokens.find(function(t) { return t.id === tokenId; });
                        if (!token) return;
                        var script = '/tool fetch url="' + token.token_url + '" mode=http';
                        navigator.clipboard.writeText(script).then(function() {
                            window.dispatchEvent(new CustomEvent('show-toast', {
                                detail: { title: 'Đã copy', msg: 'Script Mikrotik đã được lưu', type: 'success' }
                            }));
                        });
                    },

                    // ─────────────────────────────────────────────────────────
                    // Templates Preview & Apply  ← ĐÃ SỬA HOÀN CHỈNH
                    // ─────────────────────────────────────────────────────────
                    openTemplatePreview: function(templateId) {
                        var template = this.templates.find(function(t) { return t.id === templateId; });
                        if (template) {
                            this.previewTemplateId      = template.id;
                            this.previewTemplateRecords = template.records || [];
                            this.confirmPreviewCheck    = false;
                            this.showTemplatePreview    = true;
                        }
                    },

                    closeTemplatePreview: function() {
                        this.showTemplatePreview    = false;
                        this.previewTemplateId      = null;
                        this.previewTemplateRecords = [];
                    },

                    applyTemplate: function() {
                        var self = this;
                        if (!self.previewTemplateId) return;
                        if (self.applyingTemplate)   return;

                        self.applyingTemplate = true;

                        fetch('/modules/addons/mj_dns_manager/ajax.php?action=apply_template', {
                            method: 'POST',
                            headers: {
                                'Content-Type': 'application/json',
                                'X-CSRF-Token': MJDNS_CONFIG.csrfToken
                            },
                            body: JSON.stringify({
                                domain_id:   MJDNS_CONFIG.domainId,
                                template_id: self.previewTemplateId
                            })
                        })
                        .then(function(r) { return r.json(); })
                        .then(function(res) {
                            self._refreshToken(res);
                            self.applyingTemplate = false;

                            if (!res.success) {
                                var errMsg = (res.error && res.error.message)
                                    ? res.error.message
                                    : 'Lỗi không xác định khi áp dụng template.';
                                window.dispatchEvent(new CustomEvent('show-toast', {
                                    detail: { title: 'Áp dụng thất bại', msg: errMsg, type: 'danger' }
                                }));
                                return;
                            }

                            if (res.data && res.data.records) {
                                self.records = res.data.records;
                            }

                            self.closeTemplatePreview();

                            var templateName = (res.data && res.data.template_name) ? res.data.template_name : 'template';
                            window.dispatchEvent(new CustomEvent('show-toast', {
                                detail: {
                                    title: 'Đã áp dụng thành công',
                                    msg:   'Mẫu "' + templateName + '" đã được nạp. Các bản ghi đang được đồng bộ lên máy chủ.',
                                    type:  'success'
                                }
                            }));

                            self.activeTab = 'records';
                        })
                        .catch(function() {
                            self.applyingTemplate = false;
                            window.dispatchEvent(new CustomEvent('show-toast', {
                                detail: { title: 'Lỗi kết nối', msg: 'Vui lòng kiểm tra mạng và thử lại.', type: 'danger' }
                            }));
                        });
                    }
                };
            });
        });
})();

})();
