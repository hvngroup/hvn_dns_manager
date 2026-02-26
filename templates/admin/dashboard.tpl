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
        <div class="hvn-col-md-8">
            <div class="hvn-card h-100 hvn-shadow-sm hvn-border-0">
                <div class="hvn-card-header hvn-bg-white hvn-border-bottom-0 hvn-d-flex hvn-justify-content-between hvn-align-items-center">
                    <h5 class="hvn-mb-0 hvn-text-secondary"><i class="bi bi-activity"></i> Sync Pipeline</h5>
                    <div class="hvn-d-flex hvn-gap-1" id="syncChartFilter">
                        <button class="hvn-btn hvn-btn-sm hvn-btn-blue" data-days="7" onclick="syncChartSetRange(7)">7 ngày</button>
                        <button class="hvn-btn hvn-btn-sm hvn-btn-outline-blue" data-days="15" onclick="syncChartSetRange(15)">15 ngày</button>
                        <button class="hvn-btn hvn-btn-sm hvn-btn-outline-blue" data-days="30" onclick="syncChartSetRange(30)">30 ngày</button>
                    </div>
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
                    <div style="height: 140px;">
                        <canvas id="syncChart"></canvas>
                    </div>
                </div>
            </div>
        </div>

        <!-- Tổng quan -->
        <div class="hvn-col-md-4">
            <div class="hvn-card h-100 hvn-shadow-sm hvn-border-0">
                <div class="hvn-card-header hvn-bg-white hvn-border-bottom-0">
                    <h5 class="hvn-mb-0 hvn-text-secondary"><i class="bi bi-pie-chart-fill"></i> Tổng quan</h5>
                </div>
                <div class="hvn-card-body">
                    <div class="hvn-d-flex hvn-justify-content-between hvn-border-bottom hvn-pb-2 hvn-mb-2">
                        <span><i class="bi bi-globe"></i> Domains:</span>
                        <span class="hvn-fw-bold">{$dashboard.stats.domains|default:'342' }</span>
                    </div>
                    <div class="hvn-d-flex hvn-justify-content-between hvn-border-bottom hvn-pb-2 hvn-mb-2">
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
                                <div class="hvn-d-flex hvn-gap-1">
                                    <button class="hvn-btn hvn-btn-sm hvn-btn-outline-secondary" onclick="alert('Đang Test lỗi kết nối server...')">Test</button>
                                    <button class="hvn-btn hvn-btn-sm hvn-btn-outline-danger" onclick="alert('Đã vô hiệu hóa server.')">Disable</button>
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
                            <div class="hvn-d-flex hvn-gap-1">
                                <button class="hvn-btn hvn-btn-sm hvn-btn-outline-secondary">Test</button>
                                <button class="hvn-btn hvn-btn-sm hvn-btn-outline-danger">Disable</button>
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
                            <li class="hvn-list-group-item hvn-py-2" style="background-color: {if $log.status == 'complete'}rgba(25,135,84,0.07){elseif $log.status == 'failed'}rgba(220,53,69,0.07){else}rgba(255,193,7,0.1){/if};">
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
                            <li class="hvn-list-group-item hvn-py-2" style="background-color: rgba(220,53,69,0.07);">
                                <div class="hvn-d-flex w-100 hvn-justify-content-between">
                                    <span><span class="hvn-text-muted hvn-pe-2">14:32</span> ❌ <strong>DELETE_RECORD</strong></span>
                                    <a href="#">myblog.net</a>
                                </div>
                                <div class="hvn-text-muted ps-5 hvn-pt-1">&rarr; dns3.hvn.vn <span class="hvn-badge hvn-bg-danger-subtle hvn-text-danger hvn-fw-normal hvn-ms-1">timeout</span></div>
                                <div class="hvn-text-muted ps-5 hvn-pt-1">&rarr; dns1.hvn.vn <span class="hvn-badge hvn-bg-success-subtle hvn-text-success hvn-fw-normal hvn-ms-1">primary complete</span></div>
                            </li>
                            <li class="hvn-list-group-item hvn-py-2" style="background-color: rgba(25,135,84,0.07);">
                                <div class="hvn-d-flex w-100 hvn-justify-content-between">
                                    <span><span class="hvn-text-muted hvn-pe-2">14:31</span> ✅ <strong>ADD_RECORD</strong></span>
                                    <a href="#">shop.vn</a>
                                </div>
                                <div class="hvn-text-muted ps-5 hvn-pt-1">&rarr; dns1,dns2,dns3 <span class="hvn-badge hvn-bg-success-subtle hvn-text-success hvn-fw-normal hvn-ms-1">complete</span></div>
                            </li>
                            <li class="hvn-list-group-item hvn-py-2" style="background-color: rgba(25,135,84,0.07);">
                                <div class="hvn-d-flex w-100 hvn-justify-content-between">
                                    <span><span class="hvn-text-muted hvn-pe-2">14:30</span> ✅ <strong>EDIT_RECORD</strong></span>
                                    <a href="#">example.com</a>
                                </div>
                                <div class="hvn-text-muted ps-5 hvn-pt-1">&rarr; dns1,dns2,dns3 <span class="hvn-badge hvn-bg-success-subtle hvn-text-success hvn-fw-normal hvn-ms-1">complete</span></div>
                            </li>
                            <li class="hvn-list-group-item hvn-py-2" style="background-color: rgba(255,193,7,0.1);">
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
    var syncChartInstance = null;

    // Generate last N days labels (dd/mm)
    function genLabels(days) {
        var labels = [];
        var now = new Date();
        for (var i = days - 1; i >= 0; i--) {
            var d = new Date(now);
            d.setDate(d.getDate() - i);
            labels.push((d.getDate() < 10 ? '0' : '') + d.getDate() + '/' + (d.getMonth() < 9 ? '0' : '') + (d.getMonth() + 1));
        }
        return labels;
    }

    // Mock 30-day data (complete / failed / pending)
    var allData30 = {
        complete: [85,92,74,110,98,120,135,88,76,95,102,89,115,130,142,98,87,105,118,125,97,88,110,132,145,120,98,115,88,95],
        failed:   [3, 2, 5, 1, 4, 0, 2, 6, 3, 2, 1, 4, 2, 0, 3, 5, 2, 1, 3, 2, 4, 1, 2, 0, 3, 2, 5, 1, 6, 4],
        pending:  [8, 5, 9, 6, 3, 7, 4, 10,5, 8, 6, 7, 5, 4, 6, 8, 9, 5, 7, 4, 6, 9, 5, 3, 7, 6, 4, 8, 5, 7]
    };

    function getSlice(days) {
        return {
            labels: genLabels(days),
            complete: allData30.complete.slice(-days),
            failed:   allData30.failed.slice(-days),
            pending:  allData30.pending.slice(-days)
        };
    }

    function renderChart(days) {
        var ctx = document.getElementById('syncChart');
        if (!ctx || typeof Chart === 'undefined') return;

        var d = getSlice(days);

        if (syncChartInstance) {
            syncChartInstance.data.labels = d.labels;
            syncChartInstance.data.datasets[0].data = d.complete;
            syncChartInstance.data.datasets[1].data = d.failed;
            syncChartInstance.data.datasets[2].data = d.pending;
            syncChartInstance.update();
            return;
        }

        syncChartInstance = new Chart(ctx, {
            type: 'line',
            data: {
                labels: d.labels,
                datasets: [
                    {
                        label: 'Complete',
                        data: d.complete,
                        borderColor: '#198754',
                        backgroundColor: 'rgba(25,135,84,0.12)',
                        borderWidth: 2,
                        fill: true,
                        tension: 0.4,
                        pointRadius: 2,
                        pointHoverRadius: 4
                    },
                    {
                        label: 'Failed',
                        data: d.failed,
                        borderColor: '#dc3545',
                        backgroundColor: 'rgba(220,53,69,0.1)',
                        borderWidth: 2,
                        fill: false,
                        tension: 0.4,
                        pointRadius: 2,
                        pointHoverRadius: 4
                    },
                    {
                        label: 'Pending',
                        data: d.pending,
                        borderColor: '#ffc107',
                        backgroundColor: 'rgba(255,193,7,0.1)',
                        borderWidth: 2,
                        fill: false,
                        tension: 0.4,
                        pointRadius: 2,
                        pointHoverRadius: 4
                    }
                ]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                plugins: {
                    legend: {
                        display: true,
                        position: 'top',
                        labels: { boxWidth: 12, font: { size: 11 }, padding: 8 }
                    },
                    tooltip: {
                        mode: 'index',
                        intersect: false,
                        callbacks: {
                            title: function(items) { return 'Ngày ' + items[0].label; }
                        }
                    }
                },
                scales: {
                    x: {
                        display: true,
                        grid: { display: false },
                        ticks: { font: { size: 10 }, maxRotation: 0, maxTicksLimit: 10 }
                    },
                    y: {
                        display: true,
                        min: 0,
                        grid: { color: 'rgba(0,0,0,0.05)' },
                        ticks: { font: { size: 10 }, maxTicksLimit: 5 }
                    }
                },
                interaction: { mode: 'nearest', axis: 'x', intersect: false }
            }
        });
    }

    // Filter button handler
    window.syncChartSetRange = function(days) {
        renderChart(days);
        // Update active button state
        var btns = document.querySelectorAll('#syncChartFilter button');
        btns.forEach(function(btn) {
            var d = parseInt(btn.getAttribute('data-days'));
            if (d === days) {
                btn.className = btn.className.replace('hvn-btn-outline-blue', 'hvn-btn-blue');
            } else {
                btn.className = btn.className.replace('hvn-btn-blue', 'hvn-btn-outline-blue');
            }
        });
    };

    // Init with 7 days
    renderChart(7);
});
{/literal}
</script>
