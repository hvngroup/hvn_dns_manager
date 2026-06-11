<div class="mj-dns-admin" x-data="dashboardManager()" x-init="init()">

    <!-- ── Alert Banner (dynamic) ─────────────────────────────────────── -->
    <template x-if="hasCriticalAlert">
        <div class="alert alert-danger mj-d-flex mj-justify-content-between mj-align-items-center mj-mb-4">
            <div>
                <i class="bi bi-exclamation-triangle-fill fs-5 mj-me-2"></i>
                <strong>CẢNH BÁO:</strong>
                <template x-for="msg in alertMessages" :key="msg">
                    <span x-text="msg" class="mj-ms-1"></span>
                </template>
            </div>
            <div>
                <button class="mj-btn btn-sm btn-outline-danger mj-me-2"
                    @click="location.href='?module=mj_dns_manager&action=sync_logs'">
                    Xem chi tiết
                </button>
                <button class="mj-btn btn-sm mj-btn-danger" @click="hasCriticalAlert = false">
                    <i class="bi bi-x"></i> Dismiss
                </button>
            </div>
        </div>
    </template>

    <!-- ── Row 1: Sync Pipeline + Tổng quan ──────────────────────────── -->
    <div class="mj-row mj-mb-4">
        <!-- Sync Pipeline -->
        <div class="mj-col-md-8">
            <div class="mj-card h-100 mj-shadow-sm mj-border-0">
                <div class="mj-card-header mj-bg-white mj-border-bottom-0 mj-d-flex mj-justify-content-between mj-align-items-center">
                    <h5 class="mj-mb-0 mj-text-secondary">
                        <i class="bi bi-activity"></i> Sync Pipeline
                        <!-- Spinner khi đang load -->
                        <span x-show="loading" class="spinner-border spinner-border-sm mj-ms-2 mj-text-secondary" role="status"></span>
                        <!-- Thời gian cập nhật gần nhất -->
                        <small x-show="!loading && generatedAt" class="mj-text-muted mj-ms-2" style="font-size:0.75rem;" x-text="'cập nhật lúc ' + generatedAt"></small>
                    </h5>
                    <div class="mj-d-flex mj-gap-1" id="syncChartFilter">
                        <button class="mj-btn mj-btn-sm mj-btn-blue" :class="chartDays===7?'mj-btn-blue':'mj-btn-outline-blue'" @click="setDays(7)">7 ngày</button>
                        <button class="mj-btn mj-btn-sm" :class="chartDays===15?'mj-btn-blue':'mj-btn-outline-blue'" @click="setDays(15)">15 ngày</button>
                        <button class="mj-btn mj-btn-sm" :class="chartDays===30?'mj-btn-blue':'mj-btn-outline-blue'" @click="setDays(30)">30 ngày</button>
                    </div>
                </div>
                <div class="mj-card-body">
                    <!-- 3 số lớn -->
                    <div class="mj-row mj-text-center mj-mb-4">
                        <div class="mj-col-4 mj-border-end">
                            <div class="display-6 mj-text-success mj-fw-bold" x-text="stats.complete || '—'"></div>
                            <div class="mj-text-muted text-uppercase small">Complete</div>
                        </div>
                        <div class="mj-col-4 mj-border-end">
                            <div class="display-6 mj-text-warning mj-fw-bold" x-text="stats.pending || '—'"></div>
                            <div class="mj-text-muted text-uppercase small">Pending</div>
                        </div>
                        <div class="mj-col-4">
                            <div class="display-6 mj-text-danger mj-fw-bold" x-text="stats.failed || '—'"></div>
                            <div class="mj-text-muted text-uppercase small">Failed</div>
                        </div>
                    </div>
                    <!-- Chart (inline SVG — zero CDN, render bởi mj-dns.js) -->
                    <div id="syncChart" class="mj-sync-chart" style="height: 160px;"></div>
                </div>
            </div>
        </div>

        <!-- Tổng quan -->
        <div class="mj-col-md-4">
            <div class="mj-card h-100 mj-shadow-sm mj-border-0">
                <div class="mj-card-header mj-bg-white mj-border-bottom-0">
                    <h5 class="mj-mb-0 mj-text-secondary"><i class="bi bi-pie-chart-fill"></i> Tổng quan</h5>
                </div>
                <div class="mj-card-body">
                    <div class="mj-d-flex mj-justify-content-between mj-border-bottom mj-pb-2 mj-mb-2">
                        <span><i class="bi bi-globe"></i> Domains:</span>
                        <span class="mj-fw-bold" x-text="stats.domains || '—'"></span>
                    </div>
                    <div class="mj-d-flex mj-justify-content-between mj-border-bottom mj-pb-2 mj-mb-2">
                        <span><i class="bi bi-card-list"></i> Records:</span>
                        <span class="mj-fw-bold" x-text="stats.records || '—'"></span>
                    </div>

                    <h6 class="mj-text-muted small text-uppercase mj-mt-3">Top thay đổi 7 ngày</h6>
                    <ul class="list-unstyled mj-mb-0">
                        <template x-if="topDomains.length === 0">
                            <li class="mj-text-muted small">Chưa có dữ liệu</li>
                        </template>
                        <template x-for="(d, i) in topDomains" :key="d.domain">
                            <li class="mj-d-flex mj-justify-content-between mj-mb-1">
                                <span class="text-truncate" style="max-width:150px;">
                                    <span x-text="(i+1) + '. '"></span>
                                    <a :href="'?module=mj_dns_manager&action=domains&search=' + d.domain" x-text="d.domain"></a>
                                </span>
                                <span class="mj-badge mj-bg-light mj-text-dark" x-text="d.changes_count + ' thay đổi'"></span>
                            </li>
                        </template>
                    </ul>
                </div>
            </div>
        </div>
    </div>

    <!-- ── Row 2: Server Health + Activity Feed ───────────────────────── -->
    <div class="mj-row">
        <!-- Server Health -->
        <div class="mj-col-md-5 mj-mb-4">
            <div class="mj-card mj-shadow-sm mj-border-0">
                <div class="mj-card-header mj-bg-white mj-d-flex mj-justify-content-between mj-align-items-center mj-pt-3 mj-pb-2">
                    <h5 class="mj-mb-0 mj-text-secondary"><i class="bi bi-server"></i> Server Health</h5>
                    <a href="?module=mj_dns_manager&action=servers" class="mj-btn btn-sm btn-link text-decoration-none">Quản lý</a>
                </div>
                <div class="mj-list-group mj-list-group-flush mj-pb-2">
                    <template x-if="servers.length === 0">
                        <div class="mj-list-group-item mj-py-3 mj-text-muted small">Chưa có server nào.</div>
                    </template>
                    <template x-for="srv in servers" :key="srv.id">
                        <div class="mj-list-group-item mj-py-3"
                            :class="srv.status === 'offline' ? 'mj-bg-danger-subtle' : ''">
                            <div class="mj-d-flex mj-justify-content-between mj-align-items-center mj-mb-1">
                                <h6 class="mj-mb-0">
                                    <template x-if="srv.status === 'online'"><span title="Online">🟢</span></template>
                                    <template x-if="srv.status === 'warning'"><span title="Warning">🟡</span></template>
                                    <template x-if="srv.status === 'offline'"><span title="Offline">🔴</span></template>
                                    <span x-text="srv.hostname"></span>
                                    <template x-if="srv.is_primary">
                                        <span class="mj-badge mj-bg-primary mj-ms-1" style="font-size:0.65em">PRI</span>
                                    </template>
                                </h6>
                                <template x-if="srv.status === 'offline'">
                                    <button class="mj-btn mj-btn-sm mj-btn-outline-danger"
                                        @click="location.href='?module=mj_dns_manager&action=servers'">
                                        Xử lý
                                    </button>
                                </template>
                            </div>
                            <div class="mj-d-flex mj-justify-content-between mj-text-muted small">
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
                                    <span class="mj-text-danger mj-fw-bold">
                                        <i class="bi bi-exclamation-triangle"></i> <span x-text="srv.failed"></span> failed
                                    </span>
                                </template>
                                <template x-if="srv.pending === 0 && srv.failed === 0">
                                    <span class="mj-text-success"><i class="bi bi-check-circle"></i> Clear</span>
                                </template>
                            </div>
                            <template x-if="srv.status === 'offline' && srv.last_error">
                                <div class="mj-text-danger small mj-mt-1">
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
        <div class="mj-col-md-7 mj-mb-4">
            <div class="mj-card mj-shadow-sm mj-border-0 h-100">
                <div class="mj-card-header mj-bg-white mj-pt-3 mj-pb-2 mj-d-flex mj-justify-content-between mj-align-items-center">
                    <h5 class="mj-mb-0 mj-text-secondary">
                        <i class="bi bi-journal-text"></i> Hoạt động gần đây
                    </h5>
                    <!-- Spinner live — nhấp nháy khi đang refresh -->
                    <div class="spinner-grow spinner-grow-sm mj-text-success" role="status" title="Auto-refresh 30s">
                        <span class="visually-hidden">Live</span>
                    </div>
                </div>
                <div class="mj-card-body mj-p-0">
                    <ul class="mj-list-group mj-list-group-flush font-monospace small">
                        <template x-if="recentActivity.length === 0">
                            <li class="mj-list-group-item mj-py-3 mj-text-muted">Chưa có hoạt động nào.</li>
                        </template>
                        <template x-for="log in recentActivity" :key="log.id">
                            <li class="mj-list-group-item mj-py-2"
                                :style="log.status==='complete'
                                    ? 'background:rgba(25,135,84,0.07)'
                                    : log.status==='failed'
                                        ? 'background:rgba(220,53,69,0.07)'
                                        : 'background:rgba(255,193,7,0.1)'">
                                <div class="mj-d-flex w-100 mj-justify-content-between">
                                    <span>
                                        <span class="mj-text-muted mj-pe-2" x-text="log.time"></span>
                                        <span x-text="log.status==='complete'?'✅':log.status==='failed'?'❌':'⚠️'"></span>
                                        <strong x-text="log.action"></strong>
                                    </span>
                                    <a :href="'?module=mj_dns_manager&action=domains&search='+log.domain" x-text="log.domain"></a>
                                </div>
                                <div class="mj-text-muted ps-5 mj-pt-1">
                                    &rarr; <span x-text="log.server"></span>
                                    <span class="mj-badge mj-fw-normal mj-ms-1"
                                        :class="log.status==='complete'
                                            ? 'mj-bg-success-subtle mj-text-success'
                                            : log.status==='failed'
                                                ? 'mj-bg-danger-subtle mj-text-danger'
                                                : 'mj-bg-warning-subtle mj-text-warning'"
                                        x-text="log.status_text">
                                    </span>
                                </div>
                                <template x-if="log.error_brief">
                                    <div class="mj-text-danger ps-5 mj-pt-1" style="font-size:0.75rem;" x-text="log.error_brief"></div>
                                </template>
                            </li>
                        </template>
                    </ul>
                </div>
                <div class="mj-card-footer mj-bg-white mj-border-top-0 mj-pt-0 mj-pb-3">
                    <a href="?module=mj_dns_manager&action=sync_logs" class="mj-btn btn-light btn-sm w-100">
                        « Xem tất cả Sync Logs »
                    </a>
                </div>
            </div>
        </div>
    </div>
</div>

<script>
var MJDNS_MODULELINK = '{$modulelink|escape:'javascript'}';
</script>
{* JS logic moved to assets/js/mj-dns.js (MJ standard §8) *}