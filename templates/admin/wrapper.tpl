<!-- Include Custom Pure CSS Utilities, Google Fonts & Icons -->
<link rel="stylesheet" href="../modules/addons/mj_dns_manager/assets/css/mj-dns-common.css?v={$smarty.now}">
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css">
<style>
{literal}
    .mj-admin-layout, .mj-admin-layout *:not([class*="bi-"]):not([class*="fa-"]) {
        font-family: 'Inter', system-ui, -apple-system, sans-serif !important;
    }
    .mj-admin-layout {
        font-size: 15px !important;
    }
    .mj-admin-layout .small, .mj-admin-layout small {
        font-size: 0.875em !important;
    }
    .mj-admin-layout h1, .mj-admin-layout h2, .mj-admin-layout h3, .mj-admin-layout h4, .mj-admin-layout h5, .mj-admin-layout h6 {
        font-weight: 600;
    }
{/literal}
</style>

<!-- Alpine JS -->
<script defer src="https://cdn.jsdelivr.net/npm/alpinejs@3.x.x/dist/cdn.min.js"></script>

<div class="mj-wrapper mj-admin-layout mj-container-fluid mj-px-0">

<!-- ── Global Toast Container ─────────────────────────────────────────── -->
<div id="mj-toast-root" x-data="mjDnsToastSystem()" class="mj-toast-container">
    <template x-for="t in toasts" :key="t.id">
        <div class="mj-toast" :class="['mj-toast-' + t.type, t.leaving ? 'mj-toast-leaving' : '']" role="alert" style="position:relative;overflow:hidden;">
            <div class="mj-toast-icon" x-html="t.icon"></div>
            <div class="mj-toast-body">
                <div class="mj-toast-title" x-text="t.title"></div>
                <div class="mj-toast-message" x-show="t.message" x-text="t.message"></div>
            </div>
            <button class="mj-toast-close" @click="dismiss(t.id)" aria-label="Đóng">×</button>
        </div>
    </template>
</div>
<script>
{literal}
document.addEventListener('alpine:init', () => {
    Alpine.data('mjDnsToastSystem', () => ({
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
{/literal}
</script>

<!-- ── Global Confirm Modal ───────────────────────────────────────────── -->
<div id="mj-confirm-root" x-data="mjDnsConfirmModal()">
    <div class="mj-modal-backdrop" x-show="open" x-transition.opacity style="display:none;" @keydown.escape.window="cancel()" @click.self="cancel()">
        <div class="mj-modal-box" @click.stop>
            <div class="mj-modal-header">
                <div class="mj-modal-header-left">
                    <div class="mj-modal-icon" :class="'mj-modal-icon-' + variant">
                        <i class="bi" :class="variant === 'danger' ? 'bi-trash3-fill' : (variant === 'success' ? 'bi-check-circle-fill' : (variant === 'info' ? 'bi-info-circle-fill' : 'bi-exclamation-triangle-fill'))"></i>
                    </div>
                    <h5 class="mj-modal-title" x-text="title" style="margin:0;align-self:center;"></h5>
                </div>
                <button class="mj-modal-close" @click="cancel()" type="button" title="Đóng">
                    <i class="bi bi-x-lg"></i>
                </button>
            </div>
            <div class="mj-modal-body">
                <p class="mj-modal-message" x-text="message"></p>
            </div>
            <div class="mj-modal-footer">
                <button class="mj-modal-btn mj-modal-btn-cancel" @click="cancel()" x-text="cancelLabel" type="button"></button>
                <button class="mj-modal-btn" :class="'mj-modal-btn-ok-' + variant" @click="confirm()" x-text="confirmLabel" x-ref="confirmBtn" type="button"></button>
            </div>
        </div>
    </div>
</div>
<script>
{literal}
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

    <div class="mj-row mj-g-4">
        <!-- Sidebar Navigation -->
        <div class="mj-col-md-3 mj-col-lg-2">
            <div class="mj-list-group mj-list-group-flush mj-rounded mj-shadow-sm mj-border-0 mj-mb-4 sticky-top" style="top: 20px;">
                <div class="mj-list-group-item mj-bg-dark mj-text-white mj-fw-bold mj-py-3 mj-text-center">
                    <i class="bi bi-hdd-network"></i> MJ DNS Manager
                </div>
                <a href="{$modulelink}&action=dashboard" class="mj-list-group-item mj-list-group-item-action {if $action == 'dashboard' || $action == '' }active mj-border-primary mj-border-start mj-fw-bold{/if}">
                    <i class="bi bi-speedometer2 mj-me-2"></i> Dashboard
                </a>
                <a href="{$modulelink}&action=servers" class="mj-list-group-item mj-list-group-item-action {if $action == 'servers' }active mj-border-primary mj-border-start mj-fw-bold{/if}">
                    <i class="bi bi-server mj-me-2"></i> Servers
                </a>
                <a href="{$modulelink}&action=domains" class="mj-list-group-item mj-list-group-item-action {if $action == 'domains' || $action == 'dns_editor' }active mj-border-primary mj-border-start mj-fw-bold{/if}">
                    <i class="bi bi-globe mj-me-2"></i> Domains
                </a>
                <a href="{$modulelink}&action=sync_logs" class="mj-list-group-item mj-list-group-item-action {if $action == 'sync_logs' }active mj-border-primary mj-border-start mj-fw-bold{/if}">
                    <i class="bi bi-journals mj-me-2"></i> Sync Logs
                </a>
                <a href="{$modulelink}&action=audit_trail" class="mj-list-group-item mj-list-group-item-action {if $action == 'audit_trail' }active mj-border-primary mj-border-start mj-fw-bold{/if}">
                    <i class="bi bi-shield-lock mj-me-2"></i> Audit Trail
                </a>
                <a href="{$modulelink}&action=templates" class="mj-list-group-item mj-list-group-item-action {if $action == 'templates' }active mj-border-primary mj-border-start mj-fw-bold{/if}">
                    <i class="bi bi-file-text mj-me-2"></i> Templates
                </a>
                <a href="{$modulelink}&action=drift_reports" class="mj-list-group-item mj-list-group-item-action {if $action == 'drift_reports' }active mj-border-primary mj-border-start mj-fw-bold{/if}">
                    <i class="bi bi-arrow-left-right mj-me-2"></i> Drift Reports
                </a>
                <a href="{$modulelink}&action=bulk" class="mj-list-group-item mj-list-group-item-action {if $action == 'bulk' }active mj-border-primary mj-border-start mj-fw-bold{/if}">
                    <i class="bi bi-lightning-charge mj-me-2"></i> Bulk Operations
                </a>
                <a href="{$modulelink}&action=settings" class="mj-list-group-item mj-list-group-item-action {if $action == 'settings' }active mj-border-primary mj-border-start mj-fw-bold{/if}">
                    <i class="bi bi-gear mj-me-2"></i> Settings
                </a>
            </div>
        </div>

        <!-- Main Content Area -->
        <div class="mj-col-md-9 mj-col-lg-10">

            <!-- Render The Body Template -->
            {include file="`$template_name`.tpl" }
        </div>
    </div>
</div>
