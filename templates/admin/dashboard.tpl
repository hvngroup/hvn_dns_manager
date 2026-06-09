<div class="hvn-dns-admin" x-data="dashboardManager()" x-init="init()">

    <script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.1/dist/chart.umd.min.js"></script>

    <!-- ── Alert Banner (dynamic) ─────────────────────────────────────── -->
    <template x-if="hasCriticalAlert">
        <div class="alert alert-danger hvn-d-flex hvn-justify-content-between hvn-align-items-center hvn-mb-4">
            <div>
                <i class="bi bi-exclamation-triangle-fill fs-5 hvn-me-2"></i>
                <strong>CẢNH BÁO:</strong>
                <template x-for="msg in alertMessages" :key="msg">
                    <span x-text="msg" class="hvn-ms-1"></span>
                </template>
            </div>
            <div>
                <button class="hvn-btn btn-sm btn-outline-danger hvn-me-2"
                    onclick="location.href='?module=hvn_dns_manager&action=sync_logs'">
                    Xem chi tiết
                </button>
                <button class="hvn-btn btn-sm hvn-btn-danger" @click="hasCriticalAlert = false">
                    <i class="bi bi-x"></i> Dismiss
                </button>
            </div>
        </div>
    </template>

    <!-- ── Row 1: Sync Pipeline + Tổng quan ──────────────────────────── -->
    <div class="hvn-row hvn-mb-4">
        <!-- Sync Pipeline -->
        <div class="hvn-col-md-8">
            <div class="hvn-card h-100 hvn-shadow-sm hvn-border-0">
                <div class="hvn-card-header hvn-bg-white hvn-border-bottom-0 hvn-d-flex hvn-justify-content-between hvn-align-items-center">
                    <h5 class="hvn-mb-0 hvn-text-secondary">
                        <i class="bi bi-activity"></i> Sync Pipeline
                        <!-- Spinner khi đang load -->
                        <span x-show="loading" class="spinner-border spinner-border-sm hvn-ms-2 hvn-text-secondary" role="status"></span>
                        <!-- Thời gian cập nhật gần nhất -->
                        <small x-show="!loading && generatedAt" class="hvn-text-muted hvn-ms-2" style="font-size:0.75rem;" x-text="'cập nhật lúc ' + generatedAt"></small>
                    </h5>
                    <div class="hvn-d-flex hvn-gap-1" id="syncChartFilter">
                        <button class="hvn-btn hvn-btn-sm hvn-btn-blue" :class="chartDays===7?'hvn-btn-blue':'hvn-btn-outline-blue'" @click="setDays(7)">7 ngày</button>
                        <button class="hvn-btn hvn-btn-sm" :class="chartDays===15?'hvn-btn-blue':'hvn-btn-outline-blue'" @click="setDays(15)">15 ngày</button>
                        <button class="hvn-btn hvn-btn-sm" :class="chartDays===30?'hvn-btn-blue':'hvn-btn-outline-blue'" @click="setDays(30)">30 ngày</button>
                    </div>
                </div>
                <div class="hvn-card-body">
                    <!-- 3 số lớn -->
                    <div class="hvn-row hvn-text-center hvn-mb-4">
                        <div class="hvn-col-4 hvn-border-end">
                            <div class="display-6 hvn-text-success hvn-fw-bold" x-text="stats.complete || '—'"></div>
                            <div class="hvn-text-muted text-uppercase small">Complete</div>
                        </div>
                        <div class="hvn-col-4 hvn-border-end">
                            <div class="display-6 hvn-text-warning hvn-fw-bold" x-text="stats.pending || '—'"></div>
                            <div class="hvn-text-muted text-uppercase small">Pending</div>
                        </div>
                        <div class="hvn-col-4">
                            <div class="display-6 hvn-text-danger hvn-fw-bold" x-text="stats.failed || '—'"></div>
                            <div class="hvn-text-muted text-uppercase small">Failed</div>
                        </div>
                    </div>
                    <!-- Chart -->
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
                        <span class="hvn-fw-bold" x-text="stats.domains || '—'"></span>
                    </div>
                    <div class="hvn-d-flex hvn-justify-content-between hvn-border-bottom hvn-pb-2 hvn-mb-2">
                        <span><i class="bi bi-card-list"></i> Records:</span>
                        <span class="hvn-fw-bold" x-text="stats.records || '—'"></span>
                    </div>

                    <h6 class="hvn-text-muted small text-uppercase hvn-mt-3">Top thay đổi 7 ngày</h6>
                    <ul class="list-unstyled hvn-mb-0">
                        <template x-if="topDomains.length === 0">
                            <li class="hvn-text-muted small">Chưa có dữ liệu</li>
                        </template>
                        <template x-for="(d, i) in topDomains" :key="d.domain">
                            <li class="hvn-d-flex hvn-justify-content-between hvn-mb-1">
                                <span class="text-truncate" style="max-width:150px;">
                                    <span x-text="(i+1) + '. '"></span>
                                    <a :href="'?module=hvn_dns_manager&action=domains&search=' + d.domain" x-text="d.domain"></a>
                                </span>
                                <span class="hvn-badge hvn-bg-light hvn-text-dark" x-text="d.changes_count + ' thay đổi'"></span>
                            </li>
                        </template>
                    </ul>
                </div>
            </div>
        </div>
    </div>

    <!-- ── Row 2: Server Health + Activity Feed ───────────────────────── -->
    <div class="hvn-row">
        <!-- Server Health -->
        <div class="hvn-col-md-5 hvn-mb-4">
            <div class="hvn-card hvn-shadow-sm hvn-border-0">
                <div class="hvn-card-header hvn-bg-white hvn-d-flex hvn-justify-content-between hvn-align-items-center hvn-pt-3 hvn-pb-2">
                    <h5 class="hvn-mb-0 hvn-text-secondary"><i class="bi bi-server"></i> Server Health</h5>
                    <a href="?module=hvn_dns_manager&action=servers" class="hvn-btn btn-sm btn-link text-decoration-none">Quản lý</a>
                </div>
                <div class="hvn-list-group hvn-list-group-flush hvn-pb-2">
                    <template x-if="servers.length === 0">
                        <div class="hvn-list-group-item hvn-py-3 hvn-text-muted small">Chưa có server nào.</div>
                    </template>
                    <template x-for="srv in servers" :key="srv.id">
                        <div class="hvn-list-group-item hvn-py-3"
                            :class="srv.status === 'offline' ? 'hvn-bg-danger-subtle' : ''">
                            <div class="hvn-d-flex hvn-justify-content-between hvn-align-items-center hvn-mb-1">
                                <h6 class="hvn-mb-0">
                                    <template x-if="srv.status === 'online'"><span title="Online">🟢</span></template>
                                    <template x-if="srv.status === 'warning'"><span title="Warning">🟡</span></template>
                                    <template x-if="srv.status === 'offline'"><span title="Offline">🔴</span></template>
                                    <span x-text="srv.hostname"></span>
                                    <template x-if="srv.is_primary">
                                        <span class="hvn-badge hvn-bg-primary hvn-ms-1" style="font-size:0.65em">PRI</span>
                                    </template>
                                </h6>
                                <template x-if="srv.status === 'offline'">
                                    <button class="hvn-btn hvn-btn-sm hvn-btn-outline-danger"
                                        onclick="location.href='?module=hvn_dns_manager&action=servers'">
                                        Xử lý
                                    </button>
                                </template>
                            </div>
                            <div class="hvn-d-flex hvn-justify-content-between hvn-text-muted small">
                                <span>
                                    <template x-if="srv.uptime !== null">
                                        <span x-text="srv.uptime + '%'"></span>
                                    </template>
                                    <template x-if="srv.uptime === null"><span>—</span></template>
                                    &bull;
                                    <template x-if="srv.latency"><span x-text="srv.latency + 'ms avg'"></span></template>
                                    <template x-if="!srv.latency"><span>N/A</span></template>
                                </span>
                                <template x-if="srv.pending > 0">
                                    <span><i class="bi bi-clock"></i> <span x-text="srv.pending"></span> pending</span>
                                </template>
                                <template x-if="srv.pending === 0 && srv.failed > 0">
                                    <span class="hvn-text-danger hvn-fw-bold">
                                        <i class="bi bi-exclamation-triangle"></i> <span x-text="srv.failed"></span> failed
                                    </span>
                                </template>
                                <template x-if="srv.pending === 0 && srv.failed === 0">
                                    <span class="hvn-text-success"><i class="bi bi-check-circle"></i> Clear</span>
                                </template>
                            </div>
                            <template x-if="srv.status === 'offline' && srv.last_error">
                                <div class="hvn-text-danger small hvn-mt-1">
                                    <i class="bi bi-exclamation-circle-fill"></i>
                                    <span x-text="srv.last_error"></span>
                                </div>
                            </template>
                        </div>
                    </template>
                </div>
            </div>
        </div>

        <!-- Activity Feed -->
        <div class="hvn-col-md-7 hvn-mb-4">
            <div class="hvn-card hvn-shadow-sm hvn-border-0 h-100">
                <div class="hvn-card-header hvn-bg-white hvn-pt-3 hvn-pb-2 hvn-d-flex hvn-justify-content-between hvn-align-items-center">
                    <h5 class="hvn-mb-0 hvn-text-secondary">
                        <i class="bi bi-journal-text"></i> Hoạt động gần đây
                    </h5>
                    <!-- Spinner live — nhấp nháy khi đang refresh -->
                    <div class="spinner-grow spinner-grow-sm hvn-text-success" role="status" title="Auto-refresh 30s">
                        <span class="visually-hidden">Live</span>
                    </div>
                </div>
                <div class="hvn-card-body hvn-p-0">
                    <ul class="hvn-list-group hvn-list-group-flush font-monospace small">
                        <template x-if="recentActivity.length === 0">
                            <li class="hvn-list-group-item hvn-py-3 hvn-text-muted">Chưa có hoạt động nào.</li>
                        </template>
                        <template x-for="log in recentActivity" :key="log.id">
                            <li class="hvn-list-group-item hvn-py-2"
                                :style="log.status==='complete'
                                    ? 'background:rgba(25,135,84,0.07)'
                                    : log.status==='failed'
                                        ? 'background:rgba(220,53,69,0.07)'
                                        : 'background:rgba(255,193,7,0.1)'">
                                <div class="hvn-d-flex w-100 hvn-justify-content-between">
                                    <span>
                                        <span class="hvn-text-muted hvn-pe-2" x-text="log.time"></span>
                                        <span x-text="log.status==='complete'?'✅':log.status==='failed'?'❌':'⚠️'"></span>
                                        <strong x-text="log.action"></strong>
                                    </span>
                                    <a :href="'?module=hvn_dns_manager&action=domains&search='+log.domain" x-text="log.domain"></a>
                                </div>
                                <div class="hvn-text-muted ps-5 hvn-pt-1">
                                    &rarr; <span x-text="log.server"></span>
                                    <span class="hvn-badge hvn-fw-normal hvn-ms-1"
                                        :class="log.status==='complete'
                                            ? 'hvn-bg-success-subtle hvn-text-success'
                                            : log.status==='failed'
                                                ? 'hvn-bg-danger-subtle hvn-text-danger'
                                                : 'hvn-bg-warning-subtle hvn-text-warning'"
                                        x-text="log.status_text">
                                    </span>
                                </div>
                                <template x-if="log.error_brief">
                                    <div class="hvn-text-danger ps-5 hvn-pt-1" style="font-size:0.75rem;" x-text="log.error_brief"></div>
                                </template>
                            </li>
                        </template>
                    </ul>
                </div>
                <div class="hvn-card-footer hvn-bg-white hvn-border-top-0 hvn-pt-0 hvn-pb-3">
                    <a href="?module=hvn_dns_manager&action=sync_logs" class="hvn-btn btn-light btn-sm w-100">
                        « Xem tất cả Sync Logs »
                    </a>
                </div>
            </div>
        </div>
    </div>
</div>

<script>
var HVNDNS_MODULELINK = '{$modulelink|escape:'javascript'}';
</script>
<script>
{literal}
document.addEventListener('alpine:init', () => {
    Alpine.data('dashboardManager', () => ({
        // ── State ─────────────────────────────────────────────────────────
        loading:          true,
        chartDays:        7,
        stats:            { complete: '—', pending: '—', failed: '—', domains: '—', records: '—' },
        chartData:        null,
        servers:          [],
        recentActivity:   [],
        topDomains:       [],
        hasCriticalAlert: false,
        alertMessages:    [],
        generatedAt:      null,
        chartInstance:    null,
        refreshTimer:     null,

        // ── Init ──────────────────────────────────────────────────────────
        init() {
            this.fetchStats();
            // Auto-refresh mỗi 30 giây
            this.refreshTimer = setInterval(() => { this.fetchStats(); }, 30000);
        },

        // ── Fetch từ API ──────────────────────────────────────────────────
        async fetchStats() {
            this.loading = true;
            try {
                const url = HVNDNS_MODULELINK + '&action=ajax&method=getDashboardStats&days=' + this.chartDays;
                const res  = await fetch(url, { headers: { 'X-Requested-With': 'XMLHttpRequest' } });
                const data = await res.json();

                if (!data.success) return;

                this.stats            = data.stats;
                this.chartData        = data.chartData;
                this.servers          = data.servers;
                this.recentActivity   = data.recentActivity;
                this.topDomains       = data.topDomains || [];
                this.hasCriticalAlert = data.hasCriticalAlert;
                this.alertMessages    = data.alertMessages || [];
                this.generatedAt      = data.generatedAt;

                // Render chart sau khi có data
                this.$nextTick(() => { this.renderChart(); });

            } catch (e) {
                console.error('Dashboard fetch error:', e);
            } finally {
                this.loading = false;
            }
        },

        // ── Đổi khoảng thời gian chart ────────────────────────────────────
        setDays(days) {
            this.chartDays = days;
            this.fetchStats();
        },

        // ── Render / Update Chart.js ──────────────────────────────────────
        renderChart() {
            const ctx = document.getElementById('syncChart');
            if (!ctx || !this.chartData || typeof Chart === 'undefined') return;

            const d = this.chartData;

            if (this.chartInstance) {
                // Update data mà không destroy → không flicker
                this.chartInstance.data.labels              = d.labels;
                this.chartInstance.data.datasets[0].data   = d.complete;
                this.chartInstance.data.datasets[1].data   = d.failed;
                this.chartInstance.data.datasets[2].data   = d.pending;
                this.chartInstance.update('none'); // 'none' = không animate khi update
                return;
            }

            // Khởi tạo lần đầu
            this.chartInstance = new Chart(ctx, {
                type: 'line',
                data: {
                    labels: d.labels,
                    datasets: [
                        {
                            label: 'Complete',
                            data: d.complete,
                            borderColor: '#198754',
                            backgroundColor: 'rgba(25,135,84,0.12)',
                            borderWidth: 2, fill: true, tension: 0.4,
                            pointRadius: 2, pointHoverRadius: 4
                        },
                        {
                            label: 'Failed',
                            data: d.failed,
                            borderColor: '#dc3545',
                            backgroundColor: 'rgba(220,53,69,0.1)',
                            borderWidth: 2, fill: false, tension: 0.4,
                            pointRadius: 2, pointHoverRadius: 4
                        },
                        {
                            label: 'Pending',
                            data: d.pending,
                            borderColor: '#ffc107',
                            backgroundColor: 'rgba(255,193,7,0.1)',
                            borderWidth: 2, fill: false, tension: 0.4,
                            pointRadius: 2, pointHoverRadius: 4
                        }
                    ]
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: false,
                    animation: { duration: 400 },
                    plugins: {
                        legend: {
                            display: true, position: 'top',
                            labels: { boxWidth: 12, font: { size: 11 }, padding: 8 }
                        },
                        tooltip: {
                            mode: 'index', intersect: false,
                            callbacks: { title: (items) => 'Ngày ' + items[0].label }
                        }
                    },
                    scales: {
                        x: {
                            display: true,
                            grid: { display: false },
                            ticks: { font: { size: 10 }, maxRotation: 0, maxTicksLimit: 10 }
                        },
                        y: {
                            display: true, min: 0,
                            grid: { color: 'rgba(0,0,0,0.05)' },
                            ticks: { font: { size: 10 }, maxTicksLimit: 5 }
                        }
                    },
                    interaction: { mode: 'nearest', axis: 'x', intersect: false }
                }
            });
        }
    }));
});
{/literal}
</script>