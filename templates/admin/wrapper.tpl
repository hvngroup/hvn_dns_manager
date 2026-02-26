<!-- Include Custom Pure CSS Utilities, Google Fonts & Icons -->
<link rel="stylesheet" href="../modules/addons/hvn_dns_manager/assets/css/hvndns_common.css">
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css">
<style>
{literal}
    .hvn-admin-layout, .hvn-admin-layout * {
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
    <div class="hvn-row hvn-g-4">
        <!-- Sidebar Navigation -->
        <div class="hvn-col-md-3 hvn-col-lg-2">
            <div class="hvn-list-group hvn-list-group-flush hvn-rounded hvn-shadow-sm hvn-border-0 hvn-mb-4 sticky-top" style="top: 20px;">
                <div class="hvn-list-group-item hvn-bg-dark hvn-text-white hvn-fw-bold hvn-py-3 hvn-text-center">
                    <i class="bi bi-hdd-network"></i> HVN DNS Manager
                </div>
                <a href="{$modulelink}&action=dashboard" class="hvn-list-group-item hvn-list-group-item-action {if $action == 'dashboard' || $action == '' }active hvn-border-primary hvn-border-start hvn-border-4 hvn-fw-bold{/if}">
                    <i class="bi bi-speedometer2 hvn-me-2"></i> Dashboard
                </a>
                <a href="{$modulelink}&action=servers" class="hvn-list-group-item hvn-list-group-item-action {if $action == 'servers' }active hvn-border-primary hvn-border-start hvn-border-4 hvn-fw-bold{/if}">
                    <i class="bi bi-server hvn-me-2"></i> Servers
                </a>
                <a href="{$modulelink}&action=domains" class="hvn-list-group-item hvn-list-group-item-action {if $action == 'domains' || $action == 'dns_editor' }active hvn-border-primary hvn-border-start hvn-border-4 hvn-fw-bold{/if}">
                    <i class="bi bi-globe hvn-me-2"></i> Domains
                </a>
                <a href="{$modulelink}&action=sync_logs" class="hvn-list-group-item hvn-list-group-item-action {if $action == 'sync_logs' }active hvn-border-primary hvn-border-start hvn-border-4 hvn-fw-bold{/if}">
                    <i class="bi bi-journals hvn-me-2"></i> Sync Logs
                </a>
                <a href="{$modulelink}&action=audit_trail" class="hvn-list-group-item hvn-list-group-item-action {if $action == 'audit_trail' }active hvn-border-primary hvn-border-start hvn-border-4 hvn-fw-bold{/if}">
                    <i class="bi bi-shield-lock hvn-me-2"></i> Audit Trail
                </a>
                <a href="{$modulelink}&action=templates" class="hvn-list-group-item hvn-list-group-item-action {if $action == 'templates' }active hvn-border-primary hvn-border-start hvn-border-4 hvn-fw-bold{/if}">
                    <i class="bi bi-file-text hvn-me-2"></i> Templates
                </a>
                <a href="{$modulelink}&action=quota_plans" class="hvn-list-group-item hvn-list-group-item-action {if $action == 'quota_plans' }active hvn-border-primary hvn-border-start hvn-border-4 hvn-fw-bold{/if}">
                    <i class="bi bi-box-seam hvn-me-2"></i> Quota Plans
                </a>
                <a href="{$modulelink}&action=drift_reports" class="hvn-list-group-item hvn-list-group-item-action {if $action == 'drift_reports' }active hvn-border-primary hvn-border-start hvn-border-4 hvn-fw-bold{/if}">
                    <i class="bi bi-arrow-left-right hvn-me-2"></i> Drift Reports
                </a>
                <a href="{$modulelink}&action=bulk" class="hvn-list-group-item hvn-list-group-item-action {if $action == 'bulk' }active hvn-border-primary hvn-border-start hvn-border-4 hvn-fw-bold{/if}">
                    <i class="bi bi-lightning-charge hvn-me-2"></i> Bulk Operations
                </a>
                <a href="{$modulelink}&action=settings" class="hvn-list-group-item hvn-list-group-item-action {if $action == 'settings' }active hvn-border-primary hvn-border-start hvn-border-4 hvn-fw-bold{/if}">
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
