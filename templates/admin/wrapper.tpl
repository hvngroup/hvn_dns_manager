<!-- Include Custom Pure CSS Utilities, Google Fonts & Icons -->
<link rel="stylesheet" href="../modules/addons/hvn_dns_manager/assets/css/hvndns_common.css?v={$smarty.now}">
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css">
<style>
{literal}
    .hvn-admin-layout, .hvn-admin-layout *:not([class*="bi-"]):not([class*="fa-"]) {
        font-family: 'Inter', system-ui, -apple-system, sans-serif !important;
    }
    .hvn-admin-layout {
        font-size: 15px !important;
    }
    .hvn-admin-layout .small, .hvn-admin-layout small {
        font-size: 0.875em !important;
    }
    .hvn-admin-layout h1, .hvn-admin-layout h2, .hvn-admin-layout h3, .hvn-admin-layout h4, .hvn-admin-layout h5, .hvn-admin-layout h6 {
        font-weight: 600;
    }
{/literal}
</style>

<!-- Alpine JS -->
<script defer src="https://cdn.jsdelivr.net/npm/alpinejs@3.x.x/dist/cdn.min.js"></script>

<div class="hvn-wrapper hvn-admin-layout hvn-container-fluid hvn-px-0">

<!-- ── Global Toast Container ─────────────────────────────────────────── -->
<div id="hvn-toast-root" x-data="hvnToastSystem()" class="hvn-toast-container">
    <template x-for="t in toasts" :key="t.id">
        <div class="hvn-toast" :class="['hvn-toast-' + t.type, t.leaving ? 'hvn-toast-leaving' : '']" role="alert" style="position:relative;overflow:hidden;">
            <div class="hvn-toast-icon" x-html="t.icon"></div>
            <div class="hvn-toast-body">
                <div class="hvn-toast-title" x-text="t.title"></div>
                <div class="hvn-toast-message" x-show="t.message" x-text="t.message"></div>
            </div>
            <button class="hvn-toast-close" @click="dismiss(t.id)" aria-label="Đóng">×</button>
        </div>
    </template>
</div>
<script>
{literal}
document.addEventListener('alpine:init', () => {
    Alpine.data('hvnToastSystem', () => ({
        toasts: [],
        _nextId: 1,

        add(type, title, message, duration) {
            duration = duration || 4000;
            var id = this._nextId++;
            var icons = {
                success: '✓',
                error:   '✕',
                warning: '⚠',
                info:    'ℹ',
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
            window._hvnToast = function(type, title, message, duration) {
                self.add(type, title, message, duration);
            };

            // Listen to custom event (for cross-Alpine-component usage)
            window.addEventListener('hvn:toast', function(e) {
                var d = e.detail || {};
                self.add(d.type || 'info', d.title || d.message || '', d.message || '', d.duration);
            });
        }
    }));
});
{/literal}
</script>

<!-- ── Global Confirm Modal ───────────────────────────────────────────── -->
<div id="hvn-confirm-root" x-data="hvnConfirmModal()">
    <div class="hvn-modal-backdrop" x-show="open" x-transition.opacity style="display:none;" @keydown.escape.window="cancel()" @click.self="cancel()">
        <div class="hvn-modal-box" @click.stop>
            <div class="hvn-modal-header">
                <div class="hvn-modal-header-left">
                    <div class="hvn-modal-icon" :class="'hvn-modal-icon-' + variant">
                        <i class="bi" :class="variant === 'danger' ? 'bi-trash3-fill' : (variant === 'success' ? 'bi-check-circle-fill' : (variant === 'info' ? 'bi-info-circle-fill' : 'bi-exclamation-triangle-fill'))"></i>
                    </div>
                    <h5 class="hvn-modal-title" x-text="title" style="margin:0;align-self:center;"></h5>
                </div>
                <button class="hvn-modal-close" @click="cancel()" type="button" title="Đóng">
                    <i class="bi bi-x-lg"></i>
                </button>
            </div>
            <div class="hvn-modal-body">
                <p class="hvn-modal-message" x-text="message"></p>
            </div>
            <div class="hvn-modal-footer">
                <button class="hvn-modal-btn hvn-modal-btn-cancel" @click="cancel()" x-text="cancelLabel" type="button"></button>
                <button class="hvn-modal-btn" :class="'hvn-modal-btn-ok-' + variant" @click="confirm()" x-text="confirmLabel" x-ref="confirmBtn" type="button"></button>
            </div>
        </div>
    </div>
</div>
<script>
{literal}
document.addEventListener('alpine:init', () => {
    Alpine.data('hvnConfirmModal', () => ({
        open:         false,
        title:        'Xác nhận',
        message:      '',
        variant:      'warning',   // 'danger' | 'warning' | 'info' | 'success'
        confirmLabel: 'Xác nhận',
        cancelLabel:  'Hủy',
        _resolve:     null,

        init() {
            var self = this;
            window._hvnConfirm = function(options) {
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

        get iconHtml() {
            if (this.variant === 'danger') return '🗑';
            if (this.variant === 'success') return '✅';
            if (this.variant === 'info') return 'ℹ️';
            return '⚠️';
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
{/literal}
</script>

    <div class="hvn-row hvn-g-4">
        <!-- Sidebar Navigation -->
        <div class="hvn-col-md-3 hvn-col-lg-2">
            <div class="hvn-list-group hvn-list-group-flush hvn-rounded hvn-shadow-sm hvn-border-0 hvn-mb-4 sticky-top" style="top: 20px;">
                <div class="hvn-list-group-item hvn-bg-dark hvn-text-white hvn-fw-bold hvn-py-3 hvn-text-center">
                    <i class="bi bi-hdd-network"></i> HVN DNS Manager
                </div>
                <a href="{$modulelink}&action=dashboard" class="hvn-list-group-item hvn-list-group-item-action {if $action == 'dashboard' || $action == '' }active hvn-border-primary hvn-border-start hvn-fw-bold{/if}">
                    <i class="bi bi-speedometer2 hvn-me-2"></i> Dashboard
                </a>
                <a href="{$modulelink}&action=servers" class="hvn-list-group-item hvn-list-group-item-action {if $action == 'servers' }active hvn-border-primary hvn-border-start hvn-fw-bold{/if}">
                    <i class="bi bi-server hvn-me-2"></i> Servers
                </a>
                <a href="{$modulelink}&action=domains" class="hvn-list-group-item hvn-list-group-item-action {if $action == 'domains' || $action == 'dns_editor' }active hvn-border-primary hvn-border-start hvn-fw-bold{/if}">
                    <i class="bi bi-globe hvn-me-2"></i> Domains
                </a>
                <a href="{$modulelink}&action=sync_logs" class="hvn-list-group-item hvn-list-group-item-action {if $action == 'sync_logs' }active hvn-border-primary hvn-border-start hvn-fw-bold{/if}">
                    <i class="bi bi-journals hvn-me-2"></i> Sync Logs
                </a>
                <a href="{$modulelink}&action=audit_trail" class="hvn-list-group-item hvn-list-group-item-action {if $action == 'audit_trail' }active hvn-border-primary hvn-border-start hvn-fw-bold{/if}">
                    <i class="bi bi-shield-lock hvn-me-2"></i> Audit Trail
                </a>
                <a href="{$modulelink}&action=templates" class="hvn-list-group-item hvn-list-group-item-action {if $action == 'templates' }active hvn-border-primary hvn-border-start hvn-fw-bold{/if}">
                    <i class="bi bi-file-text hvn-me-2"></i> Templates
                </a>
                <a href="{$modulelink}&action=drift_reports" class="hvn-list-group-item hvn-list-group-item-action {if $action == 'drift_reports' }active hvn-border-primary hvn-border-start hvn-fw-bold{/if}">
                    <i class="bi bi-arrow-left-right hvn-me-2"></i> Drift Reports
                </a>
                <a href="{$modulelink}&action=bulk" class="hvn-list-group-item hvn-list-group-item-action {if $action == 'bulk' }active hvn-border-primary hvn-border-start hvn-fw-bold{/if}">
                    <i class="bi bi-lightning-charge hvn-me-2"></i> Bulk Operations
                </a>
                <a href="{$modulelink}&action=settings" class="hvn-list-group-item hvn-list-group-item-action {if $action == 'settings' }active hvn-border-primary hvn-border-start hvn-fw-bold{/if}">
                    <i class="bi bi-gear hvn-me-2"></i> Settings
                </a>
            </div>
        </div>

        <!-- Main Content Area -->
        <div class="hvn-col-md-9 hvn-col-lg-10">

            <!-- Render The Body Template -->
            {include file="`$template_name`.tpl" }
        </div>
    </div>
</div>
