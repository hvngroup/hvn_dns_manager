{* =====================================================================
   MJ DNS Manager — Admin shell theo archetype Smart Forms (mj-design):
   MjAppbar 1 hàng full-bleed (mark + title + tab menu + version/license)
   + breadcrumb .appbar-crumb canonical + content + footer.
   Assets (tokens → components → mj-dns CSS + mj-dns.js + Alpine) bơm
   INLINE từ disk qua AssetInliner (hooks.md §7.2) — logic JS sống trong
   assets/js/mj-dns.js, template chỉ giữ markup.
   ===================================================================== *}
{$mjAssetsHtml nofilter}

{* Icon: SVG stroke inline theo mj-design (assets/css/mj-icons.css, bơm qua
   AssetInliner). KHÔNG còn icon-font/CDN ngoài — class `bi bi-*` giữ nguyên. *}

{* .mj-dns = scope design-system · .mj-wrapper/.mj-admin-layout = scope rule legacy *}
<div class="mj-dns mj-wrapper mj-admin-layout">
<div class="mj-module-wrap">

    <!-- ── MjAppbar (Smart Forms archetype) ───────────────────────────── -->
    <div class="mj-appbar">
        <div class="mj-appbar-id">
            <div class="mj-mark mj-appbar-mark">MJ</div>
            <div class="mj-appbar-titles">
                <div class="mj-appbar-title">MJ <span>·</span> DNS Manager</div>
                <div class="mj-appbar-sub">ModuleJET · HVN GROUP</div>
            </div>
        </div>
        <nav class="mj-appbar-menu">
            <a href="{$modulelink}&action=dashboard" class="mj-appbar-tab {if $action == 'dashboard' || $action == ''}is-active{/if}">Dashboard</a>
            <a href="{$modulelink}&action=servers" class="mj-appbar-tab {if $action == 'servers' || $action == 'server_edit'}is-active{/if}">Servers</a>
            <a href="{$modulelink}&action=domains" class="mj-appbar-tab {if $action == 'domains' || $action == 'dns_editor' || $action == 'admin_dns_editor' || $action == 'snapshot_rollback'}is-active{/if}">Domains</a>
            <a href="{$modulelink}&action=sync_logs" class="mj-appbar-tab {if $action == 'sync_logs' || $action == 'sync_log_detail'}is-active{/if}">Sync Logs</a>
            <a href="{$modulelink}&action=audit_trail" class="mj-appbar-tab {if $action == 'audit_trail' || $action == 'audit_detail'}is-active{/if}">Audit Trail</a>
            <a href="{$modulelink}&action=templates" class="mj-appbar-tab {if $action == 'templates' || $action == 'template_edit'}is-active{/if}">Templates</a>
            <a href="{$modulelink}&action=drift_reports" class="mj-appbar-tab {if $action == 'drift_reports' || $action == 'drift_settings'}is-active{/if}">Drift</a>
            <a href="{$modulelink}&action=bulk" class="mj-appbar-tab {if $action == 'bulk'}is-active{/if}">Bulk</a>
            <a href="{$modulelink}&action=settings" class="mj-appbar-tab {if $action == 'settings'}is-active{/if}">Settings</a>
        </nav>
        <div class="mj-appbar-meta">
            <span class="mj-appbar-ver">v{$mj_version|default:''}</span>
            <span class="pill {$mj_license_pill|default:'pill-neutral'}">{$mj_license_label|default:'NO KEY'}</span>
        </div>
    </div>

    <!-- ── Breadcrumb (.appbar-crumb canonical) ───────────────────────── -->
    <div class="appbar-crumb">
        <a class="appbar-crumb-link" href="index.php">Home</a>
        <span class="appbar-crumb-sep">/</span>
        <a class="appbar-crumb-link" href="configaddonmods.php">Addons</a>
        <span class="appbar-crumb-sep">/</span>
        <a class="appbar-crumb-link" href="{$modulelink}">MJ - DirectAdmin DNS Manager</a>
        <span class="appbar-crumb-sep">/</span>
        <span class="appbar-crumb-current">{$page_title|default:'Dashboard'}</span>
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
