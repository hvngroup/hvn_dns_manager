{* =====================================================================
   MJ DNS Manager — Admin shell chuẩn mj-design (giống Smart Forms):
   .appbar canonical 3 tầng — appbar-top (dark: brand · version · license)
   → appbar-menu (light bar: tab điều hướng) → appbar-crumb (breadcrumb)
   → content → footer.
   Assets (tokens → components → mj-dns → mj-icons + mj-dns.js + Alpine) bơm
   INLINE từ disk qua AssetInliner (hooks.md §7.2) — logic JS sống trong
   assets/js/mj-dns.js, template chỉ giữ markup.
   ===================================================================== *}
{$mjAssetsHtml nofilter}

{* Icon: SVG stroke inline theo mj-design (assets/css/mj-icons.css, bơm qua
   AssetInliner). KHÔNG còn icon-font/CDN ngoài — class `bi bi-*` giữ nguyên. *}

{* .mj-dns = scope design-system · .mj-wrapper/.mj-admin-layout = scope rule legacy *}
<div class="mj-dns mj-wrapper mj-admin-layout">
<div class="mj-module-wrap">

    <!-- ── Appbar (MJ Design System — 3 tầng canonical như Smart Forms):
         appbar-top (brand · version · license) → appbar-menu (nav) → appbar-crumb -->
    <header class="appbar">
        <div class="appbar-top">
            <div class="appbar-brand">
                <div class="appbar-brand-mark">MJ</div>
                <div class="appbar-brand-text">
                    <div class="appbar-brand-title">DNS <span>·</span> Manager</div>
                    <div class="appbar-brand-sub">HVN · ModuleJET</div>
                </div>
            </div>
            <span class="appbar-meta">DirectAdmin DNS Manager · <strong>v{$mj_version|default:''}</strong></span>
            <div class="appbar-spacer"></div>
            <span class="pill {$mj_license_pill|default:'pill-neutral'}">{$mj_license_label|default:'NO KEY'}</span>
        </div>

        <nav class="appbar-menu" aria-label="MJ DNS Manager">
            <div class="appbar-menu-slot {if $action == 'dashboard' || $action == ''}active{/if}">
                <a class="appbar-menu-item" href="{$modulelink}&action=dashboard"><i class="bi bi-speedometer2"></i> Dashboard</a>
            </div>
            <div class="appbar-menu-slot {if $action == 'servers' || $action == 'server_edit'}active{/if}">
                <a class="appbar-menu-item" href="{$modulelink}&action=servers"><i class="bi bi-server"></i> Servers</a>
            </div>
            <div class="appbar-menu-slot {if $action == 'domains' || $action == 'dns_editor' || $action == 'admin_dns_editor' || $action == 'snapshot_rollback'}active{/if}">
                <a class="appbar-menu-item" href="{$modulelink}&action=domains"><i class="bi bi-globe"></i> Domains</a>
            </div>
            <div class="appbar-menu-slot {if $action == 'sync_logs' || $action == 'sync_log_detail'}active{/if}">
                <a class="appbar-menu-item" href="{$modulelink}&action=sync_logs"><i class="bi bi-arrow-repeat"></i> Sync Logs</a>
            </div>
            <div class="appbar-menu-slot {if $action == 'audit_trail' || $action == 'audit_detail'}active{/if}">
                <a class="appbar-menu-item" href="{$modulelink}&action=audit_trail"><i class="bi bi-journal-text"></i> Audit Trail</a>
            </div>
            <div class="appbar-menu-slot {if $action == 'templates' || $action == 'template_edit'}active{/if}">
                <a class="appbar-menu-item" href="{$modulelink}&action=templates"><i class="bi bi-files"></i> Templates</a>
            </div>
            <div class="appbar-menu-slot {if $action == 'drift_reports' || $action == 'drift_settings'}active{/if}">
                <a class="appbar-menu-item" href="{$modulelink}&action=drift_reports"><i class="bi bi-shield-check"></i> Drift</a>
            </div>
            <div class="appbar-menu-slot {if $action == 'bulk'}active{/if}">
                <a class="appbar-menu-item" href="{$modulelink}&action=bulk"><i class="bi bi-stack"></i> Bulk</a>
            </div>
            <div class="appbar-menu-slot {if $action == 'settings'}active{/if}">
                <a class="appbar-menu-item" href="{$modulelink}&action=settings"><i class="bi bi-gear"></i> Settings</a>
            </div>
        </nav>

        <div class="appbar-crumb">
            <a class="appbar-crumb-link" href="index.php">Home</a>
            <span class="appbar-crumb-sep">/</span>
            <a class="appbar-crumb-link" href="configaddonmods.php">Addons</a>
            <span class="appbar-crumb-sep">/</span>
            <a class="appbar-crumb-link" href="{$modulelink}">MJ - DirectAdmin DNS Manager</a>
            <span class="appbar-crumb-sep">/</span>
            <span class="appbar-crumb-current">{$page_title|default:'Dashboard'}</span>
        </div>
    </header>

    <!-- ── Global Toast Container ─────────────────────────────────────── -->
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

    <!-- ── Global Confirm Modal ───────────────────────────────────────── -->
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

    <!-- ── Content ────────────────────────────────────────────────────── -->
    <div class="mj-content-area">
        {include file="`$template_name`.tpl"}
    </div>

    <!-- ── Footer ─────────────────────────────────────────────────────── -->
    <div class="mj-footer">
        <span class="mj-footer__title">ModuleJET — DirectAdmin DNS Manager v{$mj_version|default:''}</span>
        <span class="mj-footer__copyright">Copyright &copy; {$smarty.now|date_format:'%Y'} ModuleJET (HVN GROUP). All rights reserved.</span>
    </div>

</div>
</div>
