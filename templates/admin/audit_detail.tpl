{if $auditError}
<div class="alert alert-danger mj-mb-4">
    <i class="bi bi-exclamation-triangle-fill mj-me-2"></i>
    <strong>Lỗi:</strong> {$auditError|escape:'htmlall'}
    <a href="{$modulelink}&action=audit_trail" class="mj-btn btn-outline-danger btn-sm mj-ms-3">← Về danh sách</a>
</div>
{else}

<div class="mj-dns-admin mj-audit-detail" x-data="auditDetail()">
    <div class="mj-d-flex mj-justify-content-between mj-align-items-center mj-mb-4">
        <h2>
            <a href="{$modulelink}&action=audit_trail" class="text-decoration-none mj-text-muted mj-me-2">
                <i class="bi bi-arrow-left"></i>
            </a>
            <i class="bi bi-shield-lock"></i> Audit Entry #<span x-text="log.id"></span>
        </h2>
    </div>

    <div class="mj-card mj-shadow-sm mj-border-0">
        <div class="mj-card-body mj-p-4 font-monospace" style="font-size: 0.9rem;">

            <table class="table table-sm table-borderless">
                <tbody>
                    <tr>
                        <td class="mj-text-muted" width="160">Actor:</td>
                        <td>
                            <span class="mj-fw-bold fs-5 mj-text-primary" x-text="log.actorFull"></span>
                            &nbsp;
                            <template x-if="log.actorType === 'client'">
                                <span class="mj-badge mj-bg-primary mj-rounded-pill" style="font-size:.7rem;">
                                    <i class="bi bi-person"></i> Client
                                </span>
                            </template>
                            <template x-if="log.actorType === 'admin'">
                                <span class="mj-badge mj-bg-danger mj-rounded-pill" style="font-size:.7rem;">
                                    <i class="bi bi-wrench"></i> Admin
                                </span>
                            </template>
                            <template x-if="log.actorType === 'system'">
                                <span class="mj-badge mj-bg-secondary mj-rounded-pill" style="font-size:.7rem;">
                                    <i class="bi bi-robot"></i> System
                                </span>
                            </template>
                            <template x-if="log.actorType === 'api'">
                                <span class="mj-badge mj-bg-info mj-text-dark mj-rounded-pill" style="font-size:.7rem;">
                                    <i class="bi bi-plug"></i> API
                                </span>
                            </template>
                        </td>
                    </tr>
                    <tr>
                        <td class="mj-text-muted">Context:</td>
                        <td x-text="log.context"></td>
                    </tr>
                    <tr>
                        <td class="mj-text-muted">Domain:</td>
                        <td>
                            <a :href="'?module=mj_dns_manager&action=admin_dns_editor&domain_id=' + log.domainId"
                               class="mj-fw-bold text-decoration-none font-monospace"
                               x-text="log.domain"></a>
                        </td>
                    </tr>
                    <tr>
                        <td class="mj-text-muted">Action:</td>
                        <td>
                            <span class="mj-fw-bold mj-bg-warning-subtle mj-px-2 mj-py-1 mj-rounded mj-text-dark d-inline-block"
                                  style="font-size:.85rem; letter-spacing:.04em;"
                                  x-text="log.action"></span>
                        </td>
                    </tr>
                    <tr>
                        <td class="mj-text-muted mj-pt-3">Target:</td>
                        <td class="mj-pt-3" x-text="log.target"></td>
                    </tr>
                </tbody>
            </table>

            <!-- Payload diff table -->
            <div class="mj-card mj-border-0 mj-shadow-sm my-4">
                <div class="mj-card-header mj-bg-light">
                    <strong><i class="bi bi-code-square mj-me-1"></i> Payload Dữ liệu</strong>
                </div>
                <div class="mj-card-body mj-p-0">
                    <table class="table table-bordered mj-mb-0">
                        <thead class="table-light">
                            <tr>
                                <th width="50%" class="mj-text-danger">
                                    <i class="bi bi-dash-circle mj-me-1"></i> Giá trị cũ (Old Data)
                                </th>
                                <th width="50%" class="mj-text-success">
                                    <i class="bi bi-plus-circle mj-me-1"></i> Giá trị mới (New Data)
                                </th>
                            </tr>
                        </thead>
                        <tbody>
                            <tr>
                                <td class="mj-p-3 text-break mj-text-danger"
                                    style="white-space: pre-wrap; background: rgba(220,53,69,.05);"
                                    x-text="log.oldVal"></td>
                                <td class="mj-p-3 text-break mj-text-success mj-fw-bold"
                                    style="white-space: pre-wrap; background: rgba(25,135,84,.05);"
                                    x-text="log.newVal"></td>
                            </tr>
                        </tbody>
                    </table>
                </div>
            </div>

            <!-- Meta info -->
            <table class="table table-sm table-borderless mj-mt-3 mj-text-muted">
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
                        <td class="fst-italic mj-text-dark" x-text="log.notes"></td>
                    </tr>
                    <tr>
                        <td>Timestamp:</td>
                        <td class="mj-fw-bold mj-text-dark" x-text="log.timeLong"></td>
                    </tr>
                </tbody>
            </table>

            <div class="mj-d-flex mj-justify-content-end mj-pt-3 mj-border-top mj-mt-4">
                <a href="{$modulelink}&action=audit_trail" class="mj-btn mj-btn-secondary">
                    <i class="bi bi-arrow-left mj-me-1"></i> Quay lại
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