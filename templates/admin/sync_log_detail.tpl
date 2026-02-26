{*
 * File: templates/admin/sync_log_detail.tpl
 * Màn hình: AD-08 — Chi tiết Sync Log Job
 *
 * Variables từ Controller:
 *   $log         - SyncLog object: id, domain, action, details, server, server_full,
 *                  status, attempt, ms, payload, error_msg, next_retry,
 *                  batch_id, actor_type, actor_id, actor_ip, created_at
 *   $modulelink  - Base URL của module (?module=hvn_dns_manager)
 *   $token       - CSRF token
 *}

<div class="hvn-dns-admin hvn-sync-log-detail">

    {* ── Breadcrumb & Header ── *}
    <div class="hvn-d-flex hvn-justify-content-between hvn-align-items-center hvn-mb-4">
        <div>
            <nav class="hvn-mb-1" style="font-size: 0.85rem;">
                <a href="{$modulelink}&action=sync_logs" class="hvn-text-muted text-decoration-none">
                    <i class="bi bi-journal-check"></i> Sync Logs
                </a>
                <span class="hvn-text-muted hvn-mx-1">/</span>
                <span class="hvn-text-dark hvn-fw-bold">Job #{$log.id|escape:'htmlall'}</span>
            </nav>
            <h2 class="hvn-mb-0">
                <i class="bi bi-file-text"></i> Chi tiết Job #{$log.id|escape:'htmlall'}
            </h2>
        </div>
        <div>
            <a href="{$modulelink}&action=sync_logs" class="hvn-btn btn-outline-secondary">
                <i class="bi bi-arrow-left"></i> Quay lại danh sách
            </a>
        </div>
    </div>

    <div class="hvn-row g-4">

        {* ── Cột trái: Thông tin chính ── *}
        <div class="hvn-col-md-8">

            {* Status Banner *}
            {if $log.status == 'complete'}
                <div class="hvn-alert hvn-alert-success hvn-d-flex hvn-align-items-center hvn-mb-4">
                    <i class="bi bi-check-circle-fill hvn-me-2 hvn-fs-4"></i>
                    <div>
                        <strong>Đồng bộ thành công</strong>
                        <div class="small">Hoàn thành trong {$log.ms|escape:'htmlall'}ms • Lần thử: {$log.attempt|escape:'htmlall'}</div>
                    </div>
                </div>
            {elseif $log.status == 'failed'}
                <div class="hvn-alert hvn-alert-danger hvn-d-flex hvn-align-items-center hvn-mb-4">
                    <i class="bi bi-x-circle-fill hvn-me-2 hvn-fs-4"></i>
                    <div>
                        <strong>Đồng bộ thất bại</strong>
                        <div class="small">Lần thử: {$log.attempt|escape:'htmlall'} • Retry tiếp theo: {$log.next_retry|default:'—'|escape:'htmlall'}</div>
                    </div>
                </div>
            {elseif $log.status == 'pending'}
                <div class="hvn-alert hvn-alert-warning hvn-d-flex hvn-align-items-center hvn-mb-4">
                    <i class="bi bi-clock-fill hvn-me-2 hvn-fs-4"></i>
                    <div>
                        <strong>Đang chờ xử lý</strong>
                        <div class="small">Job đang nằm trong hàng đợi, chưa được Cron Worker xử lý</div>
                    </div>
                </div>
            {/if}

            {* Thông tin cơ bản *}
            <div class="hvn-card hvn-shadow-sm hvn-border-0 hvn-mb-4">
                <div class="hvn-card-header">
                    <h6 class="hvn-mb-0"><i class="bi bi-info-circle hvn-text-primary"></i> Thông tin Job</h6>
                </div>
                <div class="hvn-card-body">
                    <table class="table table-sm hvn-mb-0" style="font-size: 13px;">
                        <tbody>
                            <tr>
                                <td class="hvn-text-muted hvn-fw-bold" style="width: 140px;">Domain</td>
                                <td>
                                    <a href="{$modulelink}&action=admin_dns_editor&domain_id={$log.domain_id|escape:'url'}"
                                       class="hvn-fw-bold font-monospace">
                                        {$log.domain|escape:'htmlall'}
                                    </a>
                                </td>
                            </tr>
                            <tr>
                                <td class="hvn-text-muted hvn-fw-bold">Action</td>
                                <td>
                                    <span class="hvn-badge hvn-bg-primary font-monospace" style="font-size: 11px;">
                                        {$log.action|escape:'htmlall'}
                                    </span>
                                    <span class="hvn-text-muted hvn-ms-2">{$log.details|escape:'htmlall'}</span>
                                </td>
                            </tr>
                            <tr>
                                <td class="hvn-text-muted hvn-fw-bold">Server</td>
                                <td class="font-monospace">{$log.server_hostname|escape:'htmlall'}</td>
                            </tr>
                            <tr>
                                <td class="hvn-text-muted hvn-fw-bold">Status</td>
                                <td>
                                    {if $log.status == 'complete'}
                                        <span class="hvn-badge hvn-bg-success">✅ COMPLETE</span>
                                    {elseif $log.status == 'failed'}
                                        <span class="hvn-badge hvn-bg-danger">❌ FAILED</span>
                                    {else}
                                        <span class="hvn-badge hvn-bg-warning hvn-text-dark">🟡 PENDING</span>
                                    {/if}
                                    <span class="hvn-text-muted small hvn-ms-1">(Lần thử {$log.attempt|escape:'htmlall'})</span>
                                </td>
                            </tr>
                            <tr>
                                <td class="hvn-text-muted hvn-fw-bold">Latency</td>
                                <td>{if $log.ms}{$log.ms|escape:'htmlall'}ms{else}<span class="hvn-text-muted">—</span>{/if}</td>
                            </tr>
                            <tr>
                                <td class="hvn-text-muted hvn-fw-bold">Batch ID</td>
                                <td class="font-monospace hvn-text-muted" style="font-size: 11px;">{$log.batch_id|escape:'htmlall'}</td>
                            </tr>
                            <tr>
                                <td class="hvn-text-muted hvn-fw-bold">Actor</td>
                                <td>
                                    {$log.actor_type|escape:'htmlall'} #{$log.actor_id|escape:'htmlall'}
                                    {if $log.actor_ip}
                                        <span class="hvn-text-muted small">[{$log.actor_ip|escape:'htmlall'}]</span>
                                    {/if}
                                </td>
                            </tr>
                            <tr>
                                <td class="hvn-text-muted hvn-fw-bold">Tạo lúc</td>
                                <td>{$log.created_at|escape:'htmlall'}</td>
                            </tr>
                            {if $log.completed_at}
                            <tr>
                                <td class="hvn-text-muted hvn-fw-bold">Hoàn thành</td>
                                <td>{$log.completed_at|escape:'htmlall'}</td>
                            </tr>
                            {/if}
                        </tbody>
                    </table>
                </div>
            </div>

            {* Payload *}
            <div class="hvn-card hvn-shadow-sm hvn-border-0 hvn-mb-4">
                <div class="hvn-card-header hvn-d-flex hvn-justify-content-between hvn-align-items-center">
                    <h6 class="hvn-mb-0"><i class="bi bi-code-slash hvn-text-info"></i> Payload (DNS Record Data)</h6>
                </div>
                <div class="hvn-card-body hvn-p-0">
                    <pre class="hvn-mb-0 hvn-p-3 font-monospace hvn-bg-light hvn-rounded"
                         style="font-size: 11px; max-height: 300px; overflow-y: auto;">{$log.payload|escape:'htmlall'}</pre>
                </div>
            </div>

            {* Error Detail (chỉ hiện khi failed) *}
            {if $log.status == 'failed' && $log.error_msg}
            <div class="hvn-card hvn-border-0 hvn-mb-4" style="border-left: 4px solid var(--hvn-danger) !important;">
                <div class="hvn-card-header hvn-bg-danger-subtle">
                    <h6 class="hvn-mb-0 hvn-text-danger"><i class="bi bi-exclamation-triangle-fill"></i> Chi tiết lỗi</h6>
                </div>
                <div class="hvn-card-body">
                    <pre class="font-monospace hvn-text-danger hvn-mb-2"
                         style="font-size: 12px; white-space: pre-wrap; word-break: break-all;">{$log.error_msg|escape:'htmlall'}</pre>
                    {if $log.next_retry}
                    <div class="small hvn-text-muted">
                        <i class="bi bi-clock"></i> Retry tiếp theo: <strong>{$log.next_retry|escape:'htmlall'}</strong>
                    </div>
                    {/if}
                </div>
            </div>
            {/if}

        </div>

        {* ── Cột phải: Actions & Meta ── *}
        <div class="hvn-col-md-4">

            {* Action Buttons *}
            <div class="hvn-card hvn-shadow-sm hvn-border-0 hvn-mb-4">
                <div class="hvn-card-header">
                    <h6 class="hvn-mb-0"><i class="bi bi-tools"></i> Hành động</h6>
                </div>
                <div class="hvn-card-body">
                    {if $log.status == 'failed' || $log.status == 'pending'}
                    <form method="post" action="{$modulelink}&action=retry_job" class="hvn-mb-2">
                        <input type="hidden" name="token" value="{$token}">
                        <input type="hidden" name="job_id" value="{$log.id|escape:'htmlall'}">
                        <button type="submit" class="hvn-btn hvn-btn-warning w-100">
                            <i class="bi bi-arrow-repeat"></i> Thử lại ngay (Retry)
                        </button>
                    </form>
                    <form method="post" action="{$modulelink}&action=cancel_job" class="hvn-mb-2"
                          onsubmit="return confirm('Xác nhận hủy Job #{$log.id}?')">
                        <input type="hidden" name="token" value="{$token}">
                        <input type="hidden" name="job_id" value="{$log.id|escape:'htmlall'}">
                        <button type="submit" class="hvn-btn btn-outline-danger w-100">
                            <i class="bi bi-x-circle"></i> Hủy Job (Cancel)
                        </button>
                    </form>
                    {/if}
                    <a href="{$modulelink}&action=sync_logs&batch_id={$log.batch_id|escape:'url'}"
                       class="hvn-btn btn-outline-secondary w-100 text-decoration-none hvn-d-block hvn-text-center">
                        <i class="bi bi-collection"></i> Xem tất cả Job trong Batch
                    </a>
                </div>
            </div>

            {* Server Info *}
            <div class="hvn-card hvn-shadow-sm hvn-border-0 hvn-mb-4">
                <div class="hvn-card-header">
                    <h6 class="hvn-mb-0"><i class="bi bi-server hvn-text-secondary"></i> Server thực thi</h6>
                </div>
                <div class="hvn-card-body" style="font-size: 12px;">
                    <div class="hvn-d-flex hvn-justify-content-between hvn-mb-1">
                        <span class="hvn-text-muted">Hostname</span>
                        <span class="font-monospace hvn-fw-bold">{$log.server_hostname|escape:'htmlall'}</span>
                    </div>
                    <div class="hvn-d-flex hvn-justify-content-between hvn-mb-1">
                        <span class="hvn-text-muted">Type</span>
                        <span>
                            {if $log.server_is_primary}
                                <span class="hvn-badge hvn-bg-primary">Primary</span>
                            {else}
                                <span class="hvn-badge hvn-bg-secondary">Secondary</span>
                            {/if}
                        </span>
                    </div>
                    <div class="hvn-d-flex hvn-justify-content-between">
                        <span class="hvn-text-muted">SSL</span>
                        <span>{if $log.server_use_ssl}✅ Có{else}❌ Không{/if}</span>
                    </div>
                </div>
            </div>

            {* DA API Response (nếu có) *}
            {if $log.da_response}
            <div class="hvn-card hvn-shadow-sm hvn-border-0">
                <div class="hvn-card-header">
                    <h6 class="hvn-mb-0"><i class="bi bi-terminal hvn-text-secondary"></i> DA API Response</h6>
                </div>
                <div class="hvn-card-body hvn-p-0">
                    <pre class="hvn-mb-0 hvn-p-3 font-monospace"
                         style="font-size: 11px; max-height: 200px; overflow-y: auto;">{$log.da_response|escape:'htmlall'}</pre>
                </div>
            </div>
            {/if}

        </div>
    </div>

</div>
