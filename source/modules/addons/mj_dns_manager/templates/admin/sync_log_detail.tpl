{*
 * File: templates/admin/sync_log_detail.tpl
 * Màn hình: AD-08 — Chi tiết Sync Log Job
 *
 * Variables từ Controller:
 *   $log         - SyncLog object: id, domain, action, details, server, server_full,
 *                  status, attempt, ms, payload, error_msg, next_retry,
 *                  batch_id, actor_type, actor_id, actor_ip, created_at
 *   $modulelink  - Base URL của module (?module=mj_dns_manager)
 *   $token       - CSRF token
 *}

<div class="mj-dns-admin mj-sync-log-detail">

    {* ── Breadcrumb & Header ── *}
    <div class="mj-d-flex mj-justify-content-between mj-align-items-center mj-mb-4">
        <div>
            <nav class="mj-mb-1" style="font-size: 0.85rem;">
                <a href="{$modulelink}&action=sync_logs" class="mj-text-muted text-decoration-none">
                    <i class="bi bi-journal-check"></i> Sync Logs
                </a>
                <span class="mj-text-muted mj-mx-1">/</span>
                <span class="mj-text-dark mj-fw-bold">Job #{$log.id|escape:'htmlall'}</span>
            </nav>
            <h2 class="mj-mb-0">
                <i class="bi bi-file-text"></i> Chi tiết Job #{$log.id|escape:'htmlall'}
            </h2>
        </div>
        <div>
            <a href="{$modulelink}&action=sync_logs" class="mj-btn btn-outline-secondary">
                <i class="bi bi-arrow-left"></i> Quay lại danh sách
            </a>
        </div>
    </div>

    <div class="mj-row g-4">

        {* ── Cột trái: Thông tin chính ── *}
        <div class="mj-col-md-8">

            {* Status Banner *}
            {if $log.status == 'complete'}
                <div class="mj-alert mj-alert-success mj-d-flex mj-align-items-center mj-mb-4">
                    <i class="bi bi-check-circle-fill mj-me-2 mj-fs-4"></i>
                    <div>
                        <strong>Đồng bộ thành công</strong>
                        <div class="small">Hoàn thành trong {$log.ms|escape:'htmlall'}ms • Lần thử: {$log.attempt|escape:'htmlall'}</div>
                    </div>
                </div>
            {elseif $log.status == 'failed'}
                <div class="mj-alert mj-alert-danger mj-d-flex mj-align-items-center mj-mb-4">
                    <i class="bi bi-x-circle-fill mj-me-2 mj-fs-4"></i>
                    <div>
                        <strong>Đồng bộ thất bại</strong>
                        <div class="small">Lần thử: {$log.attempt|escape:'htmlall'} • Retry tiếp theo: {$log.next_retry|default:'—'|escape:'htmlall'}</div>
                    </div>
                </div>
            {elseif $log.status == 'pending'}
                <div class="mj-alert mj-alert-warning mj-d-flex mj-align-items-center mj-mb-4">
                    <i class="bi bi-clock-fill mj-me-2 mj-fs-4"></i>
                    <div>
                        <strong>Đang chờ xử lý</strong>
                        <div class="small">Job đang nằm trong hàng đợi, chưa được Cron Worker xử lý</div>
                    </div>
                </div>
            {elseif $log.status == 'cancelled'}
                <div class="mj-alert mj-alert-secondary mj-d-flex mj-align-items-center mj-mb-4">
                    <i class="bi bi-slash-circle-fill mj-me-2 mj-fs-4"></i>
                    <div>
                        <strong>Đã hủy</strong>
                        <div class="small">Job đã bị hủy thủ công bởi Admin — sẽ không được xử lý.</div>
                    </div>
                </div>
            {/if}

            {* Thông tin cơ bản *}
            <div class="mj-card mj-shadow-sm mj-border-0 mj-mb-4">
                <div class="mj-card-header">
                    <h6 class="mj-mb-0"><i class="bi bi-info-circle mj-text-primary"></i> Thông tin Job</h6>
                </div>
                <div class="mj-card-body">
                    <table class="table table-sm mj-mb-0" style="font-size: 13px;">
                        <tbody>
                            <tr>
                                <td class="mj-text-muted mj-fw-bold" style="width: 140px;">Domain</td>
                                <td>
                                    <a href="{$modulelink}&action=admin_dns_editor&domain_id={$log.domain_id|escape:'url'}"
                                       class="mj-fw-bold font-monospace">
                                        {$log.domain|escape:'htmlall'}
                                    </a>
                                </td>
                            </tr>
                            <tr>
                                <td class="mj-text-muted mj-fw-bold">Action</td>
                                <td>
                                    <span class="mj-badge mj-bg-primary font-monospace" style="font-size: 11px;">
                                        {$log.action|escape:'htmlall'}
                                    </span>
                                    <span class="mj-text-muted mj-ms-2">{$log.details|escape:'htmlall'}</span>
                                </td>
                            </tr>
                            <tr>
                                <td class="mj-text-muted mj-fw-bold">Server</td>
                                <td class="font-monospace">{$log.server_hostname|escape:'htmlall'}</td>
                            </tr>
                            <tr>
                                <td class="mj-text-muted mj-fw-bold">Status</td>
                                <td>
                                    {if $log.status == 'complete'}
                                        <span class="mj-badge mj-bg-success">✅ COMPLETE</span>
                                    {elseif $log.status == 'failed'}
                                        <span class="mj-badge mj-bg-danger">❌ FAILED</span>
                                    {elseif $log.status == 'cancelled'}
                                        <span class="mj-badge mj-bg-secondary">⛔ CANCELLED</span>
                                    {else}
                                        <span class="mj-badge mj-bg-warning mj-text-dark">🟡 PENDING</span>
                                    {/if}
                                    <span class="mj-text-muted small mj-ms-1">(Lần thử {$log.attempt|escape:'htmlall'})</span>
                                </td>
                            </tr>
                            <tr>
                                <td class="mj-text-muted mj-fw-bold">Latency</td>
                                <td>{if $log.ms}{$log.ms|escape:'htmlall'}ms{else}<span class="mj-text-muted">—</span>{/if}</td>
                            </tr>
                            <tr>
                                <td class="mj-text-muted mj-fw-bold">Batch ID</td>
                                <td class="font-monospace mj-text-muted" style="font-size: 11px;">{$log.batch_id|escape:'htmlall'}</td>
                            </tr>
                            <tr>
                                <td class="mj-text-muted mj-fw-bold">Actor</td>
                                <td>
                                    {$log.actor_type|escape:'htmlall'} #{$log.actor_id|escape:'htmlall'}
                                    {if $log.actor_ip}
                                        <span class="mj-text-muted small">[{$log.actor_ip|escape:'htmlall'}]</span>
                                    {/if}
                                </td>
                            </tr>
                            <tr>
                                <td class="mj-text-muted mj-fw-bold">Tạo lúc</td>
                                <td>{$log.created_at|escape:'htmlall'}</td>
                            </tr>
                            {if $log.completed_at}
                            <tr>
                                <td class="mj-text-muted mj-fw-bold">Hoàn thành</td>
                                <td>{$log.completed_at|escape:'htmlall'}</td>
                            </tr>
                            {/if}
                        </tbody>
                    </table>
                </div>
            </div>

            {* Payload *}
            <div class="mj-card mj-shadow-sm mj-border-0 mj-mb-4">
                <div class="mj-card-header mj-d-flex mj-justify-content-between mj-align-items-center">
                    <h6 class="mj-mb-0"><i class="bi bi-code-slash mj-text-info"></i> Payload (DNS Record Data)</h6>
                </div>
                <div class="mj-card-body mj-p-0">
                    <pre class="mj-mb-0 mj-p-3 font-monospace mj-bg-light mj-rounded"
                         style="font-size: 11px; max-height: 300px; overflow-y: auto;">{$log.payload|escape:'htmlall'}</pre>
                </div>
            </div>

            {* Error Detail (chỉ hiện khi failed) *}
            {if $log.status == 'failed' && $log.error_msg}
            <div class="mj-card mj-border-0 mj-mb-4" style="border-left: 4px solid var(--mj-danger) !important;">
                <div class="mj-card-header mj-bg-danger-subtle">
                    <h6 class="mj-mb-0 mj-text-danger"><i class="bi bi-exclamation-triangle-fill"></i> Chi tiết lỗi</h6>
                </div>
                <div class="mj-card-body">
                    <pre class="font-monospace mj-text-danger mj-mb-2"
                         style="font-size: 12px; white-space: pre-wrap; word-break: break-all;">{$log.error_msg|escape:'htmlall'}</pre>
                    {if $log.next_retry}
                    <div class="small mj-text-muted">
                        <i class="bi bi-clock"></i> Retry tiếp theo: <strong>{$log.next_retry|escape:'htmlall'}</strong>
                    </div>
                    {/if}
                </div>
            </div>
            {/if}

        </div>

        {* ── Cột phải: Actions & Meta ── *}
        <div class="mj-col-md-4">

            {* Action Buttons *}
        <div class="mj-card mj-shadow-sm mj-border-0 mj-mb-4"
             x-data="jobActions({
                 jobId:      {$log.id|intval},
                 jobStatus:  '{$log.status|escape:'javascript'}',
                 moduleLink: '{$modulelink|escape:'javascript'}'
             })">
            <div class="mj-card-header">
                <h6 class="mj-mb-0"><i class="bi bi-tools"></i> Hành động</h6>
            </div>
            <div class="mj-card-body">

                {* Retry *}
                {if $log.status == 'failed' || $log.status == 'pending'}
                <button
                    class="mj-btn mj-btn-warning w-100 mj-mb-2"
                    @click="retryJob()"
                    :disabled="loading"
                    x-show="canAct"
                >
                    <i class="bi bi-arrow-repeat"></i>
                    <span x-text="loading && lastAction==='retry' ? 'Đang xử lý...' : 'Thử lại ngay (Retry)'"></span>
                </button>

                {* Cancel *}
                <button
                    class="mj-btn btn-outline-danger w-100 mj-mb-2"
                    @click="cancelJob()"
                    :disabled="loading"
                    x-show="canAct"
                >
                    <i class="bi bi-x-circle"></i>
                    <span x-text="loading && lastAction==='cancel' ? 'Đang hủy...' : 'Hủy Job (Cancel)'"></span>
                </button>
                {/if}



                <a href="{$modulelink}&action=sync_logs"
                   class="mj-btn btn-outline-secondary w-100 text-decoration-none mj-d-block mj-text-center">
                    <i class="bi bi-arrow-left"></i> Quay lại Sync Logs
                </a>
            </div>
        </div>

            {* Server Info *}
            <div class="mj-card mj-shadow-sm mj-border-0 mj-mb-4">
                <div class="mj-card-header">
                    <h6 class="mj-mb-0"><i class="bi bi-server mj-text-secondary"></i> Server thực thi</h6>
                </div>
                <div class="mj-card-body" style="font-size: 12px;">
                    <div class="mj-d-flex mj-justify-content-between mj-mb-1">
                        <span class="mj-text-muted">Hostname</span>
                        <span class="font-monospace mj-fw-bold">{$log.server_hostname|escape:'htmlall'}</span>
                    </div>
                    <div class="mj-d-flex mj-justify-content-between mj-mb-1">
                        <span class="mj-text-muted">Type</span>
                        <span>
                            {if $log.server_is_primary}
                                <span class="mj-badge mj-bg-primary">Primary</span>
                            {else}
                                <span class="mj-badge mj-bg-secondary">Secondary</span>
                            {/if}
                        </span>
                    </div>
                    <div class="mj-d-flex mj-justify-content-between">
                        <span class="mj-text-muted">SSL</span>
                        <span>{if $log.server_use_ssl}✅ Có{else}❌ Không{/if}</span>
                    </div>
                </div>
            </div>

            {* DA API Response (nếu có) *}
            {if $log.da_response}
            <div class="mj-card mj-shadow-sm mj-border-0">
                <div class="mj-card-header">
                    <h6 class="mj-mb-0"><i class="bi bi-terminal mj-text-secondary"></i> DA API Response</h6>
                </div>
                <div class="mj-card-body mj-p-0">
                    <pre class="mj-mb-0 mj-p-3 font-monospace"
                         style="font-size: 11px; max-height: 200px; overflow-y: auto;">{$log.da_response|escape:'htmlall'}</pre>
                </div>
            </div>
            {/if}

        </div>
    </div>

</div>

{* JS logic moved to assets/js/mj-dns.js (MJ standard §8) *}
