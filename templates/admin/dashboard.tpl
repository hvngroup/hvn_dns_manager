<div class="hvn-dns-admin">
    <!-- Thêm thư viện Chart.js nếu theme WHMCS chưa có -->
    <script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.1/dist/chart.umd.min.js"></script>

    <!-- Alert Banner -->
    {if $dashboard.hasCriticalAlert}
    <div class="alert alert-danger hvn-d-flex hvn-justify-content-between hvn-align-items-center hvn-mb-4">
        <div>
            <i class="bi bi-exclamation-triangle-fill fs-5 hvn-me-2"></i>
            <strong>CẢNH BÁO:</strong> dns3.hvn.vn mất kết nối từ 14:30 &mdash; 7 job FAILED liên tiếp.
        </div>
        <div>
            <button class="hvn-btn btn-sm btn-outline-danger hvn-me-2">Xem chi tiết</button>
            <button class="hvn-btn btn-sm btn-outline-danger hvn-me-2">Retry All</button>
            <button class="hvn-btn btn-sm hvn-btn-danger"><i class="bi bi-x"></i> Dismiss</button>
        </div>
    </div>
    {/if}

    <div class="hvn-row hvn-mb-4">
        <!-- Sync Pipeline -->
        <div class="hvn-col-md-8">
            <div class="hvn-card h-100 hvn-shadow-sm hvn-border-0">
                <div class="hvn-card-header hvn-bg-white hvn-border-bottom-0 hvn-pt-3 hvn-pb-0">
                    <h5 class="hvn-mb-0 hvn-text-secondary"><i class="bi bi-activity"></i> Sync Pipeline &mdash; 24 giờ qua</h5>
                </div>
                <div class="hvn-card-body">
                    <div class="hvn-row hvn-text-center hvn-mb-4">
                        <div class="hvn-col-4 hvn-border-end">
                            <div class="display-6 hvn-text-success hvn-fw-bold">{$dashboard.stats.complete|default:'1,247' }</div>
                            <div class="hvn-text-muted text-uppercase small">Complete</div>
                        </div>
                        <div class="hvn-col-4 hvn-border-end">
                            <div class="display-6 hvn-text-warning hvn-fw-bold">{$dashboard.stats.pending|default:'23' }</div>
                            <div class="hvn-text-muted text-uppercase small">Pending</div>
                        </div>
                        <div class="hvn-col-4">
                            <div class="display-6 hvn-text-danger hvn-fw-bold">{$dashboard.stats.failed|default:'12' }</div>
                            <div class="hvn-text-muted text-uppercase small">Failed</div>
                        </div>
                    </div>
                    <!-- Mock Sparkline Chart -->
                    <div style="height: 100px;">
                        <canvas id="syncChart"></canvas>
                    </div>
                </div>
            </div>
        </div>

        <!-- Tổng quan -->
        <div class="hvn-col-md-4">
            <div class="hvn-card h-100 hvn-shadow-sm hvn-border-0">
                <div class="hvn-card-header hvn-bg-white hvn-border-bottom-0 hvn-pt-3 hvn-pb-0">
                    <h5 class="hvn-mb-0 hvn-text-secondary"><i class="bi bi-pie-chart-fill"></i> Tổng quan</h5>
                </div>
                <div class="hvn-card-body">
                    <div class="hvn-d-flex hvn-justify-content-between hvn-border-bottom hvn-pb-2 hvn-mb-2">
                        <span><i class="bi bi-globe"></i> Domains:</span>
                        <span class="hvn-fw-bold">{$dashboard.stats.domains|default:'342' }</span>
                    </div>
                    <div class="hvn-d-flex hvn-justify-content-between hvn-border-bottom hvn-pb-3 hvn-mb-3">
                        <span><i class="bi bi-card-list"></i> Records:</span>
                        <span class="hvn-fw-bold">{$dashboard.stats.records|default:'6,840' }</span>
                    </div>
                    
                    <h6 class="hvn-text-muted small text-uppercase">Top thay đổi 7 ngày</h6>
                    <ul class="list-unstyled hvn-mb-0">
                        {foreach from=$dashboard.topDomains item=d name=top}
                            <li class="hvn-d-flex hvn-justify-content-between hvn-mb-1">
                                <span class="text-truncate" style="max-width: 150px;">{$smarty.foreach.top.iteration}. <a href="?module=hvn_dns_manager&action=domains&search={$d.domain}">{$d.domain}</a></span>
                                <span class="hvn-badge hvn-bg-light hvn-text-dark">{$d.changes_count} thay đổi</span>
                            </li>
                        {foreachelse}
                            <li class="hvn-d-flex hvn-justify-content-between hvn-mb-1">
                                <span>1. example.com</span>
                                <span class="hvn-badge hvn-bg-light hvn-text-dark">45 thay đổi</span>
                            </li>
                            <li class="hvn-d-flex hvn-justify-content-between hvn-mb-1">
                                <span>2. shop.vn</span>
                                <span class="hvn-badge hvn-bg-light hvn-text-dark">38 thay đổi</span>
                            </li>
                            <li class="hvn-d-flex hvn-justify-content-between hvn-mb-1">
                                <span>3. myblog.net</span>
                                <span class="hvn-badge hvn-bg-light hvn-text-dark">22 thay đổi</span>
                            </li>
                        {/foreach}
                    </ul>
                </div>
            </div>
        </div>
    </div>

    <div class="hvn-row">
        <!-- Server Health -->
        <div class="hvn-col-md-5 hvn-mb-4">
            <div class="hvn-card hvn-shadow-sm hvn-border-0">
                <div class="hvn-card-header hvn-bg-white hvn-d-flex hvn-justify-content-between hvn-align-items-center hvn-pt-3 hvn-pb-2">
                    <h5 class="hvn-mb-0 hvn-text-secondary"><i class="bi bi-server"></i> Server Health</h5>
                    <a href="?module=hvn_dns_manager&action=servers" class="hvn-btn btn-sm btn-link text-decoration-none">Quản lý</a>
                </div>
                <div class="hvn-list-group hvn-list-group-flush hvn-pb-2">
                    {foreach from=$dashboard.servers item=srv}
                    <div class="hvn-list-group-item hvn-py-3">
                        <div class="hvn-d-flex hvn-justify-content-between hvn-align-items-center hvn-mb-1">
                            <h6 class="hvn-mb-0">
                                {if $srv.status == 'online' }
                                    <span class="hvn-text-success" title="Online">🟢</span>
                                {elseif $srv.status == 'offline' }
                                    <span class="hvn-text-danger" title="Offline">🔴</span>
                                {else}
                                    <span class="hvn-text-warning" title="Warning">🟡</span>
                                {/if}
                                {$srv.hostname}
                                {if $srv.is_primary}
                                    <span class="hvn-badge hvn-bg-primary hvn-ms-1" style="font-size: 0.65em">PRI</span>
                                {/if}
                            </h6>
                            {if $srv.status == 'offline' }
                                <div class="btn-group btn-group-sm">
                                    <button class="hvn-btn btn-outline-secondary" onclick="alert('Đang Test lỗi kết nối server...')">Test</button>
                                    <button class="hvn-btn btn-outline-danger" onclick="alert('Đã vô hiệu hóa server.')">Disable</button>
                                </div>
                            {/if}
                        </div>
                        <div class="hvn-d-flex hvn-justify-content-between hvn-text-muted small">
                            <span>{$srv.uptime|default:'99.9' }% &bull; {$srv.latency|default:'45' }ms avg</span>
                            {if $srv.pending > 0}
                                <span><i class="bi bi-clock"></i> {$srv.pending} pending</span>
                            {elseif $srv.failed > 0}
                                <span class="hvn-text-danger hvn-fw-bold"><i class="bi bi-exclamation-triangle"></i> {$srv.failed} failed</span>
                            {else}
                                <span class="hvn-text-success"><i class="bi bi-check-circle"></i> Clear</span>
                            {/if}
                        </div>
                        {if $srv.status == 'offline' }
                            <div class="hvn-text-danger small hvn-mt-1"><i class="bi bi-exclamation-circle-fill"></i> Timeout (Failed 7 times)</div>
                        {/if}
                    </div>
                    {foreachelse}
                    <div class="hvn-list-group-item hvn-py-3">
                        <div class="hvn-d-flex hvn-justify-content-between hvn-align-items-center hvn-mb-1">
                            <h6 class="hvn-mb-0"><span class="hvn-text-success">🟢</span> dns1.hvn.vn <span class="hvn-badge hvn-bg-primary hvn-ms-1" style="font-size: 0.65em">PRI</span></h6>
                        </div>
                        <div class="hvn-d-flex hvn-justify-content-between hvn-text-muted small">
                            <span>99.8% &bull; 45ms avg</span>
                            <span><i class="bi bi-clock"></i> 12 pending</span>
                        </div>
                    </div>
                    <div class="hvn-list-group-item hvn-py-3">
                        <div class="hvn-d-flex hvn-justify-content-between hvn-align-items-center hvn-mb-1">
                            <h6 class="hvn-mb-0"><span class="hvn-text-success">🟢</span> dns2.hvn.vn</h6>
                        </div>
                        <div class="hvn-d-flex hvn-justify-content-between hvn-text-muted small">
                            <span>99.5% &bull; 52ms avg</span>
                            <span><i class="bi bi-clock"></i> 12 pending</span>
                        </div>
                    </div>
                    <div class="hvn-list-group-item hvn-py-3 hvn-bg-danger-subtle bg-opacity-10">
                        <div class="hvn-d-flex hvn-justify-content-between hvn-align-items-center hvn-mb-1">
                            <h6 class="hvn-mb-0 hvn-fw-bold"><span class="hvn-text-danger">🔴</span> dns3.hvn.vn</h6>
                            <div class="btn-group btn-group-sm">
                                <button class="hvn-btn btn-outline-secondary">Test</button>
                                <button class="hvn-btn btn-outline-danger">Disable</button>
                            </div>
                        </div>
                        <div class="hvn-d-flex hvn-justify-content-between hvn-text-muted small">
                            <span class="hvn-text-danger">97.1% &bull; timeout</span>
                            <span class="hvn-text-danger hvn-fw-bold"><i class="bi bi-exclamation-triangle"></i> 7 failed</span>
                        </div>
                    </div>
                    {/foreach}
                </div>
            </div>
        </div>

        <!-- Recent Activity -->
        <div class="hvn-col-md-7 hvn-mb-4">
            <div class="hvn-card hvn-shadow-sm hvn-border-0 h-100">
                <div class="hvn-card-header hvn-bg-white hvn-pt-3 hvn-pb-2 hvn-d-flex hvn-justify-content-between hvn-align-items-center">
                    <h5 class="hvn-mb-0 hvn-text-secondary"><i class="bi bi-journal-text"></i> Hoạt động gần đây (Live)</h5>
                    <div class="spinner-grow spinner-grow-sm hvn-text-success" role="status" title="Live update">
                        <span class="visually-hidden">Loading...</span>
                    </div>
                </div>
                <div class="hvn-card-body hvn-p-0">
                    <ul class="hvn-list-group hvn-list-group-flush font-monospace small">
                        {foreach from=$dashboard.recentActivity item=log}
                            <li class="hvn-list-group-item hvn-py-2 hvn-border-start border-{if $log.status == 'complete' }success{elseif $log.status == 'failed' }danger{else}warning{/if}">
                                <div class="hvn-d-flex w-100 hvn-justify-content-between">
                                    <span>
                                        <span class="hvn-text-muted hvn-pe-2">{$log.time}</span>
                                        {if $log.status == 'complete' }✅{elseif $log.status == 'failed' }❌{else}⚠️{/if} 
                                        <strong>{$log.action}</strong>
                                    </span>
                                    <a href="?module=hvn_dns_manager&action=domains&search={$log.domain}">{$log.domain}</a>
                                </div>
                                <div class="hvn-text-muted ps-5 hvn-pt-1">
                                    &rarr; {$log.server} <span class="hvn-badge {if $log.status == 'complete' }hvn-bg-success-subtle hvn-text-success{elseif $log.status == 'failed' }hvn-bg-danger-subtle hvn-text-danger{else}hvn-bg-warning-subtle hvn-text-warning{/if} hvn-fw-normal hvn-ms-1">{$log.status_text}</span>
                                </div>
                            </li>
                        {foreachelse}
                            <li class="hvn-list-group-item hvn-py-2 hvn-border-start hvn-border-danger">
                                <div class="hvn-d-flex w-100 hvn-justify-content-between">
                                    <span><span class="hvn-text-muted hvn-pe-2">14:32</span> ❌ <strong>DELETE_RECORD</strong></span>
                                    <a href="#">myblog.net</a>
                                </div>
                                <div class="hvn-text-muted ps-5 hvn-pt-1">&rarr; dns3.hvn.vn <span class="hvn-badge hvn-bg-danger-subtle hvn-text-danger hvn-fw-normal hvn-ms-1">timeout</span></div>
                                <div class="hvn-text-muted ps-5 hvn-pt-1">&rarr; dns1.hvn.vn <span class="hvn-badge hvn-bg-success-subtle hvn-text-success hvn-fw-normal hvn-ms-1">primary complete</span></div>
                            </li>
                            <li class="hvn-list-group-item hvn-py-2 hvn-border-start hvn-border-success">
                                <div class="hvn-d-flex w-100 hvn-justify-content-between">
                                    <span><span class="hvn-text-muted hvn-pe-2">14:31</span> ✅ <strong>ADD_RECORD</strong></span>
                                    <a href="#">shop.vn</a>
                                </div>
                                <div class="hvn-text-muted ps-5 hvn-pt-1">&rarr; dns1,dns2,dns3 <span class="hvn-badge hvn-bg-success-subtle hvn-text-success hvn-fw-normal hvn-ms-1">complete</span></div>
                            </li>
                            <li class="hvn-list-group-item hvn-py-2 hvn-border-start hvn-border-success">
                                <div class="hvn-d-flex w-100 hvn-justify-content-between">
                                    <span><span class="hvn-text-muted hvn-pe-2">14:30</span> ✅ <strong>EDIT_RECORD</strong></span>
                                    <a href="#">example.com</a>
                                </div>
                                <div class="hvn-text-muted ps-5 hvn-pt-1">&rarr; dns1,dns2,dns3 <span class="hvn-badge hvn-bg-success-subtle hvn-text-success hvn-fw-normal hvn-ms-1">complete</span></div>
                            </li>
                            <li class="hvn-list-group-item hvn-py-2 hvn-border-start hvn-border-warning">
                                <div class="hvn-d-flex w-100 hvn-justify-content-between">
                                    <span><span class="hvn-text-muted hvn-pe-2">14:28</span> ⚠️ <strong>ENABLE_DNSSEC</strong></span>
                                    <a href="#">test.org</a>
                                </div>
                                <div class="hvn-text-muted ps-5 hvn-pt-1">&rarr; dns3.hvn.vn <span class="hvn-badge hvn-bg-warning-subtle hvn-text-warning hvn-fw-normal hvn-ms-1">retrying...</span></div>
                            </li>
                        {/foreach}
                    </ul>
                </div>
                <div class="hvn-card-footer hvn-bg-white hvn-border-top-0 hvn-pt-0 hvn-pb-3">
                    <a href="?module=hvn_dns_manager&action=sync_logs" class="hvn-btn btn-light btn-sm w-100">« Xem tất cả Sync Logs &rarr; »</a>
                </div>
            </div>
        </div>
    </div>
</div>

<script>
{literal}
document.addEventListener('DOMContentLoaded', function() {
    // Render Mock Sparkline Chart
    const ctx = document.getElementById('syncChart');
    if (ctx && typeof Chart !== 'undefined') {
        new Chart(ctx, {
            type: 'line',
            data: {
                labels: ['0h','1h','2h','3h','4h','5h','6h','7h','8h','9h','10h','11h','12h','13h','14h','15h','16h','17h','18h','19h','20h','21h','22h','23h'],
                datasets: [{
                    label: 'Sync Jobs',
                    data: [12, 19, 15, 8, 5, 2, 4, 30, 45, 60, 50, 40, 45, 55, 65, 80, 90, 75, 40, 30, 25, 20, 15, 10],
                    borderColor: 'rgb(75, 192, 192)',
                    backgroundColor: 'rgba(75, 192, 192, 0.2)',
                    borderWidth: 2,
                    fill: true,
                    tension: 0.4,
                    pointRadius: 0
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                plugins: {
                    legend: { display: false },
                    tooltip: {
                        mode: 'index',
                        intersect: false,
                    }
                },
                scales: {
                    x: { display: false },
                    y: { display: false, min: 0 }
                },
                interaction: {
                    mode: 'nearest',
                    axis: 'x',
                    intersect: false
                }
            }
        });
    }
});
{/literal}
</script>
