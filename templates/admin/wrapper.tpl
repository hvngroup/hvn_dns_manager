<div class="hvn-admin-layout container-fluid px-0">
    <div class="row g-4">
        <!-- Sidebar Navigation -->
        <div class="col-md-3 col-lg-2">
            <div class="list-group list-group-flush rounded shadow-sm border-0 mb-4 sticky-top" style="top: 20px;">
                <div class="list-group-item bg-dark text-white fw-bold py-3 text-center">
                    <i class="bi bi-hdd-network"></i> HVN DNS Manager
                </div>
                <a href="{$modulelink}&action=dashboard" class="list-group-item list-group-item-action {if $action == 'dashboard' || $action == '' }active border-primary border-start border-4 fw-bold{/if}">
                    <i class="bi bi-speedometer2 me-2"></i> Dashboard
                </a>
                <a href="{$modulelink}&action=servers" class="list-group-item list-group-item-action {if $action == 'servers' }active border-primary border-start border-4 fw-bold{/if}">
                    <i class="bi bi-server me-2"></i> Servers
                </a>
                <a href="{$modulelink}&action=domains" class="list-group-item list-group-item-action {if $action == 'domains' || $action == 'dns_editor' }active border-primary border-start border-4 fw-bold{/if}">
                    <i class="bi bi-globe me-2"></i> Domains
                </a>
                <a href="{$modulelink}&action=sync_logs" class="list-group-item list-group-item-action {if $action == 'sync_logs' }active border-primary border-start border-4 fw-bold{/if}">
                    <i class="bi bi-journals me-2"></i> Sync Logs
                </a>
                <a href="{$modulelink}&action=audit_trail" class="list-group-item list-group-item-action {if $action == 'audit_trail' }active border-primary border-start border-4 fw-bold{/if}">
                    <i class="bi bi-shield-lock me-2"></i> Audit Trail
                </a>
                <a href="{$modulelink}&action=templates" class="list-group-item list-group-item-action {if $action == 'templates' }active border-primary border-start border-4 fw-bold{/if}">
                    <i class="bi bi-file-text me-2"></i> Templates
                </a>
                <a href="{$modulelink}&action=quota_plans" class="list-group-item list-group-item-action {if $action == 'quota_plans' }active border-primary border-start border-4 fw-bold{/if}">
                    <i class="bi bi-box-seam me-2"></i> Quota Plans
                </a>
                <a href="{$modulelink}&action=drift_reports" class="list-group-item list-group-item-action {if $action == 'drift_reports' }active border-primary border-start border-4 fw-bold{/if}">
                    <i class="bi bi-arrow-left-right me-2"></i> Drift Reports
                </a>
                <a href="{$modulelink}&action=bulk" class="list-group-item list-group-item-action {if $action == 'bulk' }active border-primary border-start border-4 fw-bold{/if}">
                    <i class="bi bi-lightning-charge me-2"></i> Bulk Operations
                </a>
                <a href="{$modulelink}&action=settings" class="list-group-item list-group-item-action {if $action == 'settings' }active border-primary border-start border-4 fw-bold{/if}">
                    <i class="bi bi-gear me-2"></i> Settings
                </a>
            </div>
        </div>

        <!-- Main Content Area -->
        <div class="col-md-9 col-lg-10">
            <!-- Include Bootstrap 5, Google Fonts & Icons inline for Prototype rendering reliably -->
            <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
            <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
            <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
            <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css">
            <style>
                .hvn-admin-layout, .hvn-admin-layout * {
                    font-family: 'Inter', system-ui, -apple-system, sans-serif !important;
                }
            </style>
            
            <!-- Alpine JS -->
            <script defer src="https://cdn.jsdelivr.net/npm/alpinejs@3.x.x/dist/cdn.min.js"></script>

            <!-- Render The Body Template -->
            {include file="`$template_name`.tpl" }
        </div>
    </div>
</div>
