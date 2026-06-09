<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css">
    <link rel="stylesheet" href="/modules/addons/hvn_dns_manager/assets/css/hvndns_common.css">
    <link rel="stylesheet" href="/modules/addons/hvn_dns_manager/assets/css/hvndns_client.css">

    {* ── Smarty variables → JS config ── *}
    <script>
        var HVNDNS_CONFIG = {ldelim}
            domainId:   {$domain.id|intval},
            domainName: '{$domain.domain|escape:'javascript'}',
            csrfToken:  '{$csrf_token|escape:'javascript'}',
            records:    {$recordsJson nofilter},
            redirects:  {$redirectsJson|default:'[]' nofilter},
            emails:     {$emailsJson|default:'[]' nofilter},
            ddnsTokens: {$ddnsJson|default:'[]' nofilter},
            templates:  {$templates|@json_encode nofilter}
        {rdelim};
    </script>

    {* ── Alpine component ── *}
    {literal}
    <script>
        document.addEventListener('alpine:init', function() {
            Alpine.data('dnsEditor', function() {
                return {
                    domainId:   HVNDNS_CONFIG.domainId,
                    domainName: HVNDNS_CONFIG.domainName,
                    records:    HVNDNS_CONFIG.records,
                    redirects:  HVNDNS_CONFIG.redirects  || [],
                    emails:     HVNDNS_CONFIG.emails      || [],
                    ddnsTokens: HVNDNS_CONFIG.ddnsTokens  || [],
                    templates:  HVNDNS_CONFIG.templates   || [],

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
                            HVNDNS_CONFIG.csrfToken = res._token;
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
                        fetch('/modules/addons/hvn_dns_manager/ajax.php?action=sync_status_all', {
                            method: 'POST',
                            headers: {
                                'Content-Type': 'application/json',
                                'X-CSRF-Token': HVNDNS_CONFIG.csrfToken
                            },
                            body: JSON.stringify({ domain_id: HVNDNS_CONFIG.domainId })
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
                        hvnConfirm({
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

                            fetch('/modules/addons/hvn_dns_manager/ajax.php?action=sync_zone', {
                                method: 'POST',
                                headers: {
                                    'Content-Type': 'application/json',
                                    'X-CSRF-Token': HVNDNS_CONFIG.csrfToken
                                },
                                body: JSON.stringify({ domain_id: HVNDNS_CONFIG.domainId })
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
                            fetch('/modules/addons/hvn_dns_manager/ajax.php?action=sync_status', {
                                method: 'POST',
                                headers: {
                                    'Content-Type': 'application/json',
                                    'X-CSRF-Token': HVNDNS_CONFIG.csrfToken
                                },
                                body: JSON.stringify({ domain_id: HVNDNS_CONFIG.domainId, batch_id: batchId })
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
                            'A':     'hvn-badge-a',
                            'AAAA':  'hvn-badge-aaaa',
                            'CNAME': 'hvn-badge-cname',
                            'MX':    'hvn-badge-mx',
                            'TXT':   'hvn-badge-txt',
                            'SRV':   'hvn-badge-srv',
                            'NS':    'hvn-badge-ns',
                            'CAA':   'hvn-badge-caa'
                        };
                        return 'badge-dns ' + (classes[type] || 'hvn-badge-ns');
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
                            domain_id: HVNDNS_CONFIG.domainId,
                            type:      this.editForm.type,
                            name:      this.editForm.name,
                            value:     this.editForm.value,
                            ttl:       parseInt(this.editForm.ttl),
                            priority:  parseInt(this.editForm.priority) || 0,
                            weight:    parseInt(this.editForm.weight)   || 0,
                            port:      parseInt(this.editForm.port)     || 0
                        };
                        if (!this.addingNew) { payload.record_id = this.editingId; }

                        fetch('/modules/addons/hvn_dns_manager/ajax.php?action=' + action, {
                            method: 'POST',
                            headers: {
                                'Content-Type': 'application/json',
                                'X-CSRF-Token': HVNDNS_CONFIG.csrfToken
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
                        hvnConfirm({
                            title:   'Xóa bản ghi DNS',
                            msg:     'Bạn có chắc muốn xóa bản ghi:\n' + record.type + ' · ' + record.name + '\n\nHành động này sẽ được đồng bộ lên máy chủ.',
                            variant: 'danger',
                            okText:  'Xóa'
                        }).then(function(ok) {
                            if (!ok) return;
                            record.pending_delete = true;
                            record.sync_status    = 'syncing';
                            fetch('/modules/addons/hvn_dns_manager/ajax.php?action=delete_record', {
                                method: 'POST',
                                headers: {
                                    'Content-Type': 'application/json',
                                    'X-CSRF-Token': HVNDNS_CONFIG.csrfToken
                                },
                                body: JSON.stringify({ domain_id: HVNDNS_CONFIG.domainId, record_id: record.id })
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
                        fetch('/modules/addons/hvn_dns_manager/ajax.php?action=add_redirect', {
                            method: 'POST',
                            headers: {
                                'Content-Type': 'application/json',
                                'X-CSRF-Token': HVNDNS_CONFIG.csrfToken
                            },
                            body: JSON.stringify({
                                domain_id:       HVNDNS_CONFIG.domainId,
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
                        hvnConfirm({
                            title:   'Xóa chuyển hướng',
                            msg:     'Bạn có chắc muốn xóa chuyển hướng:\n' + redirect.source_path + ' → ' + redirect.destination_url,
                            variant: 'danger',
                            okText:  'Xóa'
                        }).then(function(ok) {
                            if (!ok) return;
                            redirect.pending_delete = true;
                            redirect.sync_status    = 'syncing';
                            fetch('/modules/addons/hvn_dns_manager/ajax.php?action=delete_redirect', {
                                method: 'POST',
                                headers: {
                                    'Content-Type': 'application/json',
                                    'X-CSRF-Token': HVNDNS_CONFIG.csrfToken
                                },
                                body: JSON.stringify({ domain_id: HVNDNS_CONFIG.domainId, redirect_id: redirect.id })
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

                        fetch('/modules/addons/hvn_dns_manager/ajax.php?action=email_fwd_create', {
                            method: 'POST',
                            headers: {
                                'Content-Type': 'application/json',
                                'X-CSRF-Token': HVNDNS_CONFIG.csrfToken
                            },
                            body: JSON.stringify({
                                domain_id:         HVNDNS_CONFIG.domainId,
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
                        hvnConfirm({
                            title:   'Xóa email forwarder',
                            msg:     'Bạn có chắc muốn xóa:\n' + email.source_email + ' → ' + email.destination_email,
                            variant: 'danger',
                            okText:  'Xóa'
                        }).then(function(ok) {
                            if (!ok) return;
                            email.pending_delete = true;
                            email.sync_status    = 'pending';

                            fetch('/modules/addons/hvn_dns_manager/ajax.php?action=email_fwd_delete', {
                                method: 'POST',
                                headers: {
                                    'Content-Type': 'application/json',
                                    'X-CSRF-Token': HVNDNS_CONFIG.csrfToken
                                },
                                body: JSON.stringify({
                                    domain_id:  HVNDNS_CONFIG.domainId,
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
                        hvnConfirm({ title: title, msg: msg, variant: variant, okText: enable ? 'Bật DNSSEC' : 'Tắt DNSSEC' })
                        .then(function(ok) {
                            if (!ok) return;
                            self.dnssecLoading = true;
                            fetch('/modules/addons/hvn_dns_manager/ajax.php?action=dnssec_toggle', {
                                method: 'POST',
                                headers: { 'Content-Type': 'application/json', 'X-CSRF-Token': HVNDNS_CONFIG.csrfToken },
                                body: JSON.stringify({ domain_id: HVNDNS_CONFIG.domainId, enable: enable ? 1 : 0 })
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
                        fetch('/modules/addons/hvn_dns_manager/ajax.php?action=ddns_toggle', {
                            method: 'POST',
                            headers: { 'Content-Type': 'application/json', 'X-CSRF-Token': HVNDNS_CONFIG.csrfToken },
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
                        hvnConfirm({
                            title: 'Xóa DDNS Token',
                            msg:   'Xóa DDNS token cho ' + token.subdomain + '?\nThiết bị sẽ không thể cập nhật IP tự động nữa.',
                            variant: 'danger', okText: 'Xóa token'
                        }).then(function(ok) {
                            if (!ok) return;
                            fetch('/modules/addons/hvn_dns_manager/ajax.php?action=ddns_delete', {
                                method: 'POST',
                                headers: { 'Content-Type': 'application/json', 'X-CSRF-Token': HVNDNS_CONFIG.csrfToken },
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
                        fetch('/modules/addons/hvn_dns_manager/ajax.php?action=ddns_create', {
                            method: 'POST',
                            headers: { 'Content-Type': 'application/json', 'X-CSRF-Token': HVNDNS_CONFIG.csrfToken },
                            body: JSON.stringify({
                                domain_id: HVNDNS_CONFIG.domainId,
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
                            var correctUrl = window.location.origin + '/modules/addons/hvn_dns_manager/ddns.php?token=' + rawToken;
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
                        hvnConfirm({
                            title: 'Tạo lại DDNS Token',
                            msg:   'URL cũ sẽ không còn hoạt động. Bạn cần cập nhật lại cấu hình trên thiết bị.',
                            variant: 'warning', okText: 'Tạo lại token'
                        }).then(function(ok) {
                            if (!ok) return;
                            fetch('/modules/addons/hvn_dns_manager/ajax.php?action=ddns_regenerate', {
                                method: 'POST',
                                headers: { 'Content-Type': 'application/json', 'X-CSRF-Token': HVNDNS_CONFIG.csrfToken },
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
                                var correctUrl = window.location.origin + '/modules/addons/hvn_dns_manager/ddns.php?token=' + rawToken;
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

                        fetch('/modules/addons/hvn_dns_manager/ajax.php?action=apply_template', {
                            method: 'POST',
                            headers: {
                                'Content-Type': 'application/json',
                                'X-CSRF-Token': HVNDNS_CONFIG.csrfToken
                            },
                            body: JSON.stringify({
                                domain_id:   HVNDNS_CONFIG.domainId,
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
    </script>
    {/literal}

    {* ══════════════════════════ HTML ══════════════════════════ *}

    <div class="hvn-dns-client" x-data="dnsEditor()">

        <a href="index.php?m=hvn_dns_manager" class="cl-back-link">
            <i class="bi bi-arrow-left"></i> Quay lại danh sách domain
        </a>

        {* ── Domain Info Card ── *}
        <div class="cl-domain-card">
            <div class="cl-domain-name">
                <i class="bi bi-globe2"></i>
                {$domain.domain|escape:'htmlall'}
            </div>
            <div style="display:flex;align-items:center;justify-content:space-between;gap:16px;flex-wrap:wrap;">
                <div style="flex:1;min-width:200px;">
                    {assign var="safe_max" value=$quota.max_records|default:1}
                    {math assign="percent" equation="round((c/m)*100)" c=$domain.records_count m=$safe_max}
                    <div class="cl-quota-row">
                        <span class="cl-quota-label">Bản ghi đang dùng</span>
                        <span class="cl-quota-value" x-text="records.length + ' / {$quota.max_records}'"></span>
                    </div>
                    <div class="cl-progress">
                        <div class="cl-progress-bar {if $percent > 90}cl-progress-danger{elseif $percent > 75}cl-progress-warning{/if}"
                            style="width:{$percent}%" role="progressbar"></div>
                    </div>
                </div>
                <div style="display:flex;gap:8px;flex-shrink:0;">
                    <span class="cl-chip {if $domain.dnssec_enabled}cl-chip-active{else}cl-chip-off{/if}">
                        <i class="bi bi-shield-lock"></i> DNSSEC: {if $domain.dnssec_enabled}Bật{else}Tắt{/if}
                    </span>
                    <span class="cl-chip {if $domain.ssl_status == 'active'}cl-chip-active{elseif $domain.ssl_status == 'pending'}cl-chip-pending{else}cl-chip-off{/if}">
                        <i class="bi bi-lock"></i> SSL: {$domain.ssl_status|capitalize|default:'None'}
                    </span>
                </div>
            </div>
        </div>

        {* ── Tabs ── *}
        <div class="cl-tab-bar">
            <button class="cl-tab-btn" x-bind:class="activeTab === 'records' ? 'cl-tab-active' : ''" x-on:click="activeTab = 'records'" type="button">
                <i class="bi bi-globe2"></i> DNS Records
            </button>
            {if $quota.redirects_enabled}
            <button class="cl-tab-btn" x-bind:class="activeTab === 'redirects' ? 'cl-tab-active' : ''" x-on:click="activeTab = 'redirects'" type="button">
                <i class="bi bi-link-45deg"></i> Redirects
                {if $domain.redirects_count > 0}<span class="cl-tab-count">{$domain.redirects_count}</span>{/if}
            </button>
            {/if}
            {if $quota.email_enabled}
            <button class="cl-tab-btn" x-bind:class="activeTab === 'email' ? 'cl-tab-active' : ''" x-on:click="activeTab = 'email'" type="button">
                <i class="bi bi-envelope"></i> Email
                {if $domain.email_fwds_count > 0}<span class="cl-tab-count">{$domain.email_fwds_count}</span>{/if}
            </button>
            {/if}
            {if $quota.dnssec_enabled}
            <button class="cl-tab-btn" x-bind:class="activeTab === 'dnssec' ? 'cl-tab-active' : ''" x-on:click="activeTab = 'dnssec'" type="button">
                <i class="bi bi-shield-lock"></i> DNSSEC
            </button>
            {/if}
            {if $quota.ddns_enabled}
            <button class="cl-tab-btn" x-bind:class="activeTab === 'ddns' ? 'cl-tab-active' : ''" x-on:click="activeTab = 'ddns'" type="button">
                <i class="bi bi-router"></i> DDNS
            </button>
            {/if}
            {if $quota.templates_enabled}
            <button class="cl-tab-btn" x-bind:class="activeTab === 'templates' ? 'cl-tab-active' : ''" x-on:click="activeTab = 'templates'" type="button">
                <i class="bi bi-files"></i> Templates
            </button>
            {/if}
        </div>

        {* ── Tab Content ── *}
        <div>
            {assign var="partials_dir" value="{$module_dir}templates/client/partials"}

            <div x-show="activeTab === 'records'" x-cloak>
                {include file="$partials_dir/record_table.tpl"}
            </div>
            {if $quota.redirects_enabled}
            <div x-show="activeTab === 'redirects'" x-cloak>
                {include file="$partials_dir/tab_redirects.tpl"}
            </div>
            {/if}
            {if $quota.email_enabled}
            <div x-show="activeTab === 'email'" x-cloak>
                {include file="$partials_dir/tab_email.tpl"}
            </div>
            {/if}
            {if $quota.dnssec_enabled}
            <div x-show="activeTab === 'dnssec'" x-cloak>
                {include file="$partials_dir/tab_dnssec.tpl"}
            </div>
            {/if}
            {if $quota.ddns_enabled}
            <div x-show="activeTab === 'ddns'" x-cloak>
                {include file="$partials_dir/tab_ddns.tpl"}
            </div>
            {/if}
            {if $quota.templates_enabled}
            <div x-show="activeTab === 'templates'" x-cloak>
                {include file="$partials_dir/tab_templates.tpl"}
            </div>
            {/if}
        </div>

    </div>

    {assign var="partials_dir_toast" value="{$module_dir}templates/client/partials"}
    {include file="$partials_dir_toast/toast.tpl"}
    {include file="$partials_dir_toast/confirm_modal.tpl"}

    <script src="https://cdn.jsdelivr.net/npm/alpinejs@3.x.x/dist/cdn.min.js" defer></script>

    {literal}
    <style>
    [x-cloak] { display: none !important; }
    </style>
    {/literal}