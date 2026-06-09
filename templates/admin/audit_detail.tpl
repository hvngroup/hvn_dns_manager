{if $auditError}
<div class="alert alert-danger hvn-mb-4">
    <i class="bi bi-exclamation-triangle-fill hvn-me-2"></i>
    <strong>Lỗi:</strong> {$auditError|escape:'htmlall'}
    <a href="{$modulelink}&action=audit_trail" class="hvn-btn btn-outline-danger btn-sm hvn-ms-3">← Về danh sách</a>
</div>
{else}

<div class="hvn-dns-admin hvn-audit-detail" x-data="auditDetail()">
    <div class="hvn-d-flex hvn-justify-content-between hvn-align-items-center hvn-mb-4">
        <h2>
            <a href="{$modulelink}&action=audit_trail" class="text-decoration-none hvn-text-muted hvn-me-2">
                <i class="bi bi-arrow-left"></i>
            </a>
            <i class="bi bi-shield-lock"></i> Audit Entry #<span x-text="log.id"></span>
        </h2>
    </div>

    <div class="hvn-card hvn-shadow-sm hvn-border-0">
        <div class="hvn-card-body hvn-p-4 font-monospace" style="font-size: 0.9rem;">

            <table class="table table-sm table-borderless">
                <tbody>
                    <tr>
                        <td class="hvn-text-muted" width="160">Actor:</td>
                        <td>
                            <span class="hvn-fw-bold fs-5 hvn-text-primary" x-text="log.actorFull"></span>
                            &nbsp;
                            <template x-if="log.actorType === 'client'">
                                <span class="hvn-badge hvn-bg-primary hvn-rounded-pill" style="font-size:.7rem;">
                                    <i class="bi bi-person"></i> Client
                                </span>
                            </template>
                            <template x-if="log.actorType === 'admin'">
                                <span class="hvn-badge hvn-bg-danger hvn-rounded-pill" style="font-size:.7rem;">
                                    <i class="bi bi-wrench"></i> Admin
                                </span>
                            </template>
                            <template x-if="log.actorType === 'system'">
                                <span class="hvn-badge hvn-bg-secondary hvn-rounded-pill" style="font-size:.7rem;">
                                    <i class="bi bi-robot"></i> System
                                </span>
                            </template>
                            <template x-if="log.actorType === 'api'">
                                <span class="hvn-badge hvn-bg-info hvn-text-dark hvn-rounded-pill" style="font-size:.7rem;">
                                    <i class="bi bi-plug"></i> API
                                </span>
                            </template>
                        </td>
                    </tr>
                    <tr>
                        <td class="hvn-text-muted">Context:</td>
                        <td x-text="log.context"></td>
                    </tr>
                    <tr>
                        <td class="hvn-text-muted">Domain:</td>
                        <td>
                            <a :href="'?module=hvn_dns_manager&action=admin_dns_editor&domain_id=' + log.domainId"
                               class="hvn-fw-bold text-decoration-none font-monospace"
                               x-text="log.domain"></a>
                        </td>
                    </tr>
                    <tr>
                        <td class="hvn-text-muted">Action:</td>
                        <td>
                            <span class="hvn-fw-bold hvn-bg-warning-subtle hvn-px-2 hvn-py-1 hvn-rounded hvn-text-dark d-inline-block"
                                  style="font-size:.85rem; letter-spacing:.04em;"
                                  x-text="log.action"></span>
                        </td>
                    </tr>
                    <tr>
                        <td class="hvn-text-muted hvn-pt-3">Target:</td>
                        <td class="hvn-pt-3" x-text="log.target"></td>
                    </tr>
                </tbody>
            </table>

            <!-- Payload diff table -->
            <div class="hvn-card hvn-border-0 hvn-shadow-sm my-4">
                <div class="hvn-card-header hvn-bg-light">
                    <strong><i class="bi bi-code-square hvn-me-1"></i> Payload Dữ liệu</strong>
                </div>
                <div class="hvn-card-body hvn-p-0">
                    <table class="table table-bordered hvn-mb-0">
                        <thead class="table-light">
                            <tr>
                                <th width="50%" class="hvn-text-danger">
                                    <i class="bi bi-dash-circle hvn-me-1"></i> Giá trị cũ (Old Data)
                                </th>
                                <th width="50%" class="hvn-text-success">
                                    <i class="bi bi-plus-circle hvn-me-1"></i> Giá trị mới (New Data)
                                </th>
                            </tr>
                        </thead>
                        <tbody>
                            <tr>
                                <td class="hvn-p-3 text-break hvn-text-danger"
                                    style="white-space: pre-wrap; background: rgba(220,53,69,.05);"
                                    x-text="log.oldVal"></td>
                                <td class="hvn-p-3 text-break hvn-text-success hvn-fw-bold"
                                    style="white-space: pre-wrap; background: rgba(25,135,84,.05);"
                                    x-text="log.newVal"></td>
                            </tr>
                        </tbody>
                    </table>
                </div>
            </div>

            <!-- Meta info -->
            <table class="table table-sm table-borderless hvn-mt-3 hvn-text-muted">
                <tbody>
                    <tr>
                        <td width="160">IP Address:</td>
                        <td class="font-monospace" x-text="log.ip"></td>
                    </tr>
                    <tr>
                        <td>User Agent:</td>
                        <td class="text-break" x-text="log.ua"></td>
                    </tr>
                    <tr>
                        <td>Session / Token:</td>
                        <td class="font-monospace" x-text="log.session"></td>
                    </tr>
                    <tr>
                        <td>Ghi chú (Notes):</td>
                        <td class="fst-italic hvn-text-dark" x-text="log.notes"></td>
                    </tr>
                    <tr>
                        <td>Timestamp:</td>
                        <td class="hvn-fw-bold hvn-text-dark" x-text="log.timeLong"></td>
                    </tr>
                </tbody>
            </table>

            <div class="hvn-d-flex hvn-justify-content-end hvn-pt-3 hvn-border-top hvn-mt-4">
                <a href="{$modulelink}&action=audit_trail" class="hvn-btn hvn-btn-secondary">
                    <i class="bi bi-arrow-left hvn-me-1"></i> Quay lại
                </a>
            </div>
        </div>
    </div>
</div>

<script>
    var _AUDIT_LOG = {$auditLog};
</script>
<script>
{literal}
document.addEventListener('alpine:init', () => {
    Alpine.data('auditDetail', () => ({
        log: _AUDIT_LOG,
        init() {}
    }));
});
{/literal}
</script>

{/if}