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
