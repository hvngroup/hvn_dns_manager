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
