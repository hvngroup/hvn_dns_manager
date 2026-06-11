<div class="mj-dns-admin mj-templates" x-data="templateManager()">
    <div class="mj-d-flex mj-justify-content-between mj-align-items-center mj-mb-4">
        <h2><i class="bi bi-file-text"></i> Quản lý DNS Template</h2>
        <a href="{$modulelink}&action=template_edit" class="mj-btn mj-btn-primary">
            <i class="bi bi-plus-lg"></i> Tạo Template
        </a>
    </div>

    <div class="mj-row">
        <template x-for="tpl in templates" x-bind:key="tpl.id">
            <div class="mj-col-md-6 col-lg-4 mj-mb-4">
                <div class="mj-card mj-shadow-sm h-100 mj-border-0"
                    x-bind:class="{
                        'mj-border-start mj-border-start-4 mj-border-primary': tpl.is_default,
                        'mj-bg-light': !tpl.is_visible
                    }">
                    <div class="mj-card-body" style="position:relative;">

                        <template x-if="tpl.is_default">
                            <span style="position:absolute;top:8px;right:8px;"
                                class="mj-badge mj-bg-primary" style="font-size:0.7rem;">
                                <i class="bi bi-star-fill mj-text-warning"></i> DEFAULT
                            </span>
                        </template>

                        <h5 class="mj-card-title mj-text-primary mj-fw-bold" x-text="tpl.name"></h5>
                        <p class="mj-text-muted small mj-mb-3" style="min-height:40px;"
                            x-text="tpl.description || '(Chưa có mô tả)'"></p>

                        <div class="mj-d-flex mj-justify-content-between mj-align-items-center mj-mb-3">
                            <span class="mj-badge mj-bg-secondary">
                                <span x-text="tpl.records_count"></span> bản ghi
                            </span>
                            <span class="small"
                                x-bind:class="tpl.is_visible ? 'mj-text-success' : 'mj-text-danger'">
                                <i class="bi"
                                    x-bind:class="tpl.is_visible ? 'bi-eye-fill' : 'bi-eye-slash-fill'"></i>
                                <span x-text="tpl.is_visible ? 'Hiển thị Client' : 'Ẩn với Client'"></span>
                            </span>
                        </div>

                        <div style="display:flex;gap:6px;flex-wrap:wrap;">
                            <a x-bind:href="'{$modulelink}&action=template_edit&id=' + tpl.id"
                                class="mj-btn mj-btn-sm mj-btn-outline-primary" style="flex:1;text-align:center;">
                                <i class="bi bi-pencil"></i> Sửa
                            </a>
                            <button class="mj-btn mj-btn-sm mj-btn-outline-secondary" style="flex:1;"
                                x-on:click="cloneTemplate(tpl)" x-bind:disabled="saving">
                                <i class="bi bi-stickies"></i> Clone
                            </button>
                            <template x-if="!tpl.is_default">
                                <button class="mj-btn mj-btn-sm mj-btn-outline-success"
                                    x-on:click="setDefault(tpl)" x-bind:disabled="saving">
                                    <i class="bi bi-star"></i> Default
                                </button>
                            </template>
                            <template x-if="!tpl.is_default">
                                <button class="mj-btn mj-btn-sm mj-btn-outline-danger"
                                    x-on:click="deleteTemplate(tpl)" x-bind:disabled="saving">
                                    <i class="bi bi-trash"></i>
                                </button>
                            </template>
                        </div>

                    </div>
                </div>
            </div>
        </template>

        <template x-if="templates.length === 0">
            <div class="mj-col-12">
                <div class="mj-alert mj-alert-info">
                    <i class="bi bi-info-circle mj-me-2"></i>
                    Chưa có template nào. Nhấn <strong>Tạo Template</strong> để bắt đầu.
                </div>
            </div>
        </template>
    </div>
</div>

<script>
var MJDNS_TEMPLATES_DATA   = {$templatesJson};
var MJDNS_ADMIN_MODULELINK = '{$modulelink|escape:'javascript'}';
var MJDNS_CSRF_TOKEN       = '{$token|escape:'javascript'}';
</script>
<script>
{literal}
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
{/literal}
</script>
