{* =====================================================================
   MJ DNS Manager — Admin shell (templates-layout.md: Header / Nav /
   Breadcrumb / Content / Footer). Assets (tokens → components → mj-dns
   CSS + mj-dns.js + Alpine) bơm INLINE từ disk qua AssetInliner —
   không <link>/<script src> vào modules/addons/* (hooks.md §7.2).
   Logic JS sống trong assets/js/mj-dns.js — template chỉ giữ markup.
   ===================================================================== *}
{$mjAssetsHtml nofilter}

{* Bootstrap-icons cho icon trong page body (deviation [MJ-INTERNAL] đã ghi
   nhận trong README — sẽ thay dần bằng SVG stroke theo mj-design). *}
<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css">

{* .mj-dns = scope design-system · .mj-wrapper/.mj-admin-layout = scope rule legacy *}
<div class="mj-dns mj-wrapper mj-admin-layout">
<div class="mj-module-wrap">

    <!-- ── Header ─────────────────────────────────────────────────────── -->
    <div class="mj-header">
        <div class="mj-header__left">
            <div class="mj-header__icon">MJ</div>
            <span class="mj-header__title">DirectAdmin DNS Manager</span>
        </div>
        <div class="mj-header__right">
            <a href="https://modulejet.com" target="_blank" rel="noopener">
                <span class="mj-header__brand-text">ModuleJET</span>
                <span class="mj-header__brand-arrow">↗</span>
            </a>
        </div>
    </div>

    <!-- ── Navigation ─────────────────────────────────────────────────── -->
    <nav class="mj-nav">
        <a href="{$modulelink}&action=dashboard" class="mj-nav__item {if $action == 'dashboard' || $action == ''}mj-nav__item--active{/if}">
            <span class="mj-nav__icon"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="3" width="7" height="7" rx="1"/><rect x="14" y="3" width="7" height="7" rx="1"/><rect x="3" y="14" width="7" height="7" rx="1"/><rect x="14" y="14" width="7" height="7" rx="1"/></svg></span>
            Dashboard
        </a>
        <a href="{$modulelink}&action=servers" class="mj-nav__item {if $action == 'servers' || $action == 'server_edit'}mj-nav__item--active{/if}">
            <span class="mj-nav__icon"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><rect x="2" y="2" width="20" height="8" rx="2"/><rect x="2" y="14" width="20" height="8" rx="2"/><line x1="6" y1="6" x2="6.01" y2="6"/><line x1="6" y1="18" x2="6.01" y2="18"/></svg></span>
            Servers
        </a>
        <a href="{$modulelink}&action=domains" class="mj-nav__item {if $action == 'domains' || $action == 'dns_editor' || $action == 'admin_dns_editor' || $action == 'snapshot_rollback'}mj-nav__item--active{/if}">
            <span class="mj-nav__icon"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"/><line x1="2" y1="12" x2="22" y2="12"/><path d="M12 2a15.3 15.3 0 0 1 4 10 15.3 15.3 0 0 1-4 10 15.3 15.3 0 0 1-4-10 15.3 15.3 0 0 1 4-10z"/></svg></span>
            Domains
        </a>
        <a href="{$modulelink}&action=sync_logs" class="mj-nav__item {if $action == 'sync_logs' || $action == 'sync_log_detail'}mj-nav__item--active{/if}">
            <span class="mj-nav__icon"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><path d="M14 2v6h6"/><path d="M16 13H8"/><path d="M16 17H8"/></svg></span>
            Sync Logs
        </a>
        <a href="{$modulelink}&action=audit_trail" class="mj-nav__item {if $action == 'audit_trail' || $action == 'audit_detail'}mj-nav__item--active{/if}">
            <span class="mj-nav__icon"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/></svg></span>
            Audit Trail
        </a>
        <a href="{$modulelink}&action=templates" class="mj-nav__item {if $action == 'templates' || $action == 'template_edit'}mj-nav__item--active{/if}">
            <span class="mj-nav__icon"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><path d="M14 2v6h6"/></svg></span>
            Templates
        </a>
        <a href="{$modulelink}&action=drift_reports" class="mj-nav__item {if $action == 'drift_reports' || $action == 'drift_settings'}mj-nav__item--active{/if}">
            <span class="mj-nav__icon"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><polyline points="17 1 21 5 17 9"/><path d="M3 11V9a4 4 0 0 1 4-4h14"/><polyline points="7 23 3 19 7 15"/><path d="M21 13v2a4 4 0 0 1-4 4H3"/></svg></span>
            Drift Reports
        </a>
        <a href="{$modulelink}&action=bulk" class="mj-nav__item {if $action == 'bulk'}mj-nav__item--active{/if}">
            <span class="mj-nav__icon"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><polygon points="13 2 3 14 12 14 11 22 21 10 12 10 13 2"/></svg></span>
            Bulk Operations
        </a>
        <a href="{$modulelink}&action=settings" class="mj-nav__item {if $action == 'settings'}mj-nav__item--active{/if}">
            <span class="mj-nav__icon"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="3"/><path d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 1 1-2.83 2.83l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 1 1-4 0v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 1 1-2.83-2.83l.06-.06a1.65 1.65 0 0 0 .33-1.82 1.65 1.65 0 0 0-1.51-1H3a2 2 0 1 1 0-4h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 1 1 2.83-2.83l.06.06a1.65 1.65 0 0 0 1.82.33H9a1.65 1.65 0 0 0 1-1.51V3a2 2 0 1 1 4 0v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 1 1 2.83 2.83l-.06.06a1.65 1.65 0 0 0-.33 1.82V9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 1 1 0 4h-.09a1.65 1.65 0 0 0-1.51 1z"/></svg></span>
            Settings
        </a>
    </nav>

    <!-- ── Breadcrumb ─────────────────────────────────────────────────── -->
    <div class="mj-breadcrumb">
        <a href="index.php">Home</a>
        <span class="mj-breadcrumb__sep">/</span>
        <a href="configaddonmods.php">Addons</a>
        <span class="mj-breadcrumb__sep">/</span>
        <a href="{$modulelink}">MJ - DirectAdmin DNS Manager</a>
        <span class="mj-breadcrumb__sep">/</span>
        <span class="mj-breadcrumb__current">{$page_title|default:'Dashboard'}</span>
    </div>

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
