<div class="hvn-dns-admin hvn-servers" x-data="serverManager()">
    <div class="hvn-d-flex hvn-justify-content-between hvn-align-items-center hvn-mb-4">
        <h2><i class="bi bi-server"></i> Quản lý Server DirectAdmin</h2>
        <a href="{$modulelink}&action=server_edit" class="hvn-btn hvn-btn-primary">
            <i class="bi bi-plus-lg"></i> Thêm Server
        </a>
    </div>


    <div class="hvn-row">
        <template x-for="server in servers" :key="server.id">
            <div class="hvn-col-12 hvn-mb-3">
                <div class="hvn-card hvn-shadow-sm hvn-border-0"
                    :class="{
                        'hvn-border-start hvn-border-success': server.status === 'online' && server.is_active,
                        'hvn-border-start hvn-border-warning': server.status === 'warning' && server.is_active,
                        'hvn-border-start hvn-border-danger':  server.status === 'offline' && server.is_active,
                        'hvn-border-start border-secondary opacity-75': !server.is_active
                    }">
                    <div class="hvn-card-body">
                        <div class="hvn-row hvn-align-items-center">

                            <!-- ── Server Info ─────────────────────────── -->
                            <div class="hvn-col-md-3">
                                <h5 class="hvn-card-title hvn-mb-1 hvn-d-flex hvn-align-items-center">
                                    <template x-if="server.status === 'online' && server.is_active">
                                        <span class="hvn-me-2" title="Online">🟢</span>
                                    </template>
                                    <template x-if="server.status === 'warning' && server.is_active">
                                        <span class="hvn-me-2" title="Warning">🟡</span>
                                    </template>
                                    <template x-if="server.status === 'offline' && server.is_active">
                                        <span class="hvn-me-2" title="Offline">🔴</span>
                                    </template>
                                    <template x-if="!server.is_active">
                                        <span class="hvn-me-2" title="Disabled">⚪</span>
                                    </template>

                                    <span x-text="server.hostname"></span>

                                    <template x-if="server.is_primary">
                                        <span class="hvn-badge hvn-bg-primary hvn-ms-2" style="font-size:0.6em;">Primary</span>
                                    </template>
                                    <template x-if="!server.is_primary">
                                        <span class="hvn-badge hvn-bg-secondary hvn-ms-2" style="font-size:0.6em;">Secondary</span>
                                    </template>
                                </h5>
                                <div class="hvn-text-muted hvn-small">
                                    IP: <span class="hvn-font-monospace" x-text="server.ip_address"></span> |
                                    Port: <span x-text="server.port"></span> |
                                    SSL: <span x-text="server.use_ssl ? '✅' : '❌'"></span>
                                </div>
                                <div class="hvn-text-muted hvn-small hvn-mt-1">
                                    Max concurrent: <span x-text="server.max_concurrent_jobs"></span>
                                </div>
                            </div>

                            <!-- ── Stats ──────────────────────────────── -->
                            <div class="hvn-col-md-5 hvn-border-start hvn-border-end hvn-px-4">

                                <!-- Server active + không offline -->
                                <template x-if="server.is_active && server.status !== 'offline'">
                                    <div>
                                        <div class="hvn-row hvn-text-center hvn-mb-1 hvn-mt-2">
                                            <div class="hvn-col hvn-border-end">
                                                <i class="bi bi-activity hvn-text-primary hvn-fs-4 hvn-d-block hvn-mb-1"></i>
                                                <div class="hvn-fw-bold hvn-fs-5">
                                                    <template x-if="server.uptime !== null">
                                                        <span x-text="server.uptime + '%'"></span>
                                                    </template>
                                                    <template x-if="server.uptime === null">
                                                        <span class="hvn-text-muted">N/A</span>
                                                    </template>
                                                </div>
                                                <div class="hvn-text-muted hvn-text-uppercase" style="font-size:0.7rem;letter-spacing:0.5px;">Uptime</div>
                                            </div>
                                            <div class="hvn-col hvn-border-end">
                                                <i class="bi bi-speedometer2 hvn-text-info hvn-fs-4 hvn-d-block hvn-mb-1"></i>
                                                <div class="hvn-fw-bold hvn-fs-5">
                                                    <template x-if="server.latency > 0">
                                                        <span x-text="server.latency + 'ms'"></span>
                                                    </template>
                                                    <template x-if="server.latency === 0">
                                                        <span class="hvn-text-muted">N/A</span>
                                                    </template>
                                                </div>
                                                <div class="hvn-text-muted hvn-text-uppercase" style="font-size:0.7rem;letter-spacing:0.5px;">Avg Latency</div>
                                            </div>
                                            <div class="hvn-col">
                                                <i class="bi bi-shield-check hvn-text-success hvn-fs-4 hvn-d-block hvn-mb-1"></i>
                                                <div class="hvn-fw-bold hvn-text-success hvn-fs-5" x-text="server.last_ok"></div>
                                                <div class="hvn-text-muted hvn-text-uppercase" style="font-size:0.7rem;letter-spacing:0.5px;">Last OK</div>
                                            </div>
                                        </div>
                                        <hr class="my-2">
                                        <div class="hvn-d-flex hvn-justify-content-between hvn-small">
                                            <span><i class="bi bi-clock"></i> Pending: <strong x-text="server.pending_jobs"></strong></span>
                                            <span class="hvn-text-success">Today: <strong x-text="server.today_completed"></strong> complete</span>
                                        </div>
                                    </div>
                                </template>

                                <!-- Server bị disable -->
                                <template x-if="!server.is_active">
                                    <div class="hvn-text-center hvn-text-muted hvn-py-3">
                                        <i class="bi bi-pause-circle hvn-fs-4 hvn-d-block hvn-mb-1"></i>
                                        Server đang bị vô hiệu hóa
                                    </div>
                                </template>

                                <!-- Server offline / backoff -->
                                <template x-if="server.is_active && server.status === 'offline'">
                                    <div>
                                        <div class="hvn-text-danger hvn-fw-bold hvn-mb-1">
                                            <i class="bi bi-exclamation-triangle"></i>
                                            BACKOFF — Retry lúc <span x-text="server.next_retry"></span>
                                            (<span x-text="server.retry_in"></span>)
                                        </div>
                                        <div class="hvn-small hvn-text-muted hvn-mb-1">
                                            Failed: <span x-text="server.failed_count"></span> lần liên tiếp
                                        </div>
                                        <div class="hvn-small hvn-text-danger hvn-bg-danger-subtle hvn-p-1 hvn-rounded hvn-font-monospace" style="font-size:0.75rem;">
                                            Error: <span x-text="server.last_error || '(không rõ)'"></span>
                                        </div>
                                    </div>
                                </template>
                            </div>

                            <!-- ── Actions ────────────────────────────── -->
                            <div class="hvn-col-md-4 hvn-text-end">
                                <button class="hvn-btn hvn-btn-sm hvn-btn-outline-info hvn-mb-1 hvn-w-100 hvn-text-start"
                                    @click="testConnection(server)" :disabled="loading">
                                    <i class="bi bi-plug"></i> Test Connection
                                </button>

                                <a :href="'{$modulelink}&action=server_edit&id=' + server.id"
                                    class="hvn-btn hvn-btn-sm hvn-btn-outline-primary hvn-mb-1 hvn-w-100 hvn-text-start hvn-d-block hvn-text-decoration-none">
                                    <i class="bi bi-pencil"></i> Sửa cấu hình
                                </a>

                                <template x-if="server.is_active">
                                    <button class="hvn-btn hvn-btn-sm hvn-btn-outline-danger hvn-w-100 hvn-text-start"
                                        @click="toggleStatus(server)" :disabled="loading">
                                        <i class="bi bi-pause-fill"></i> Vô hiệu hóa (Disable)
                                    </button>
                                </template>
                                <template x-if="!server.is_active">
                                    <button class="hvn-btn hvn-btn-sm hvn-btn-outline-success hvn-w-100 hvn-text-start"
                                        @click="toggleStatus(server)" :disabled="loading">
                                        <i class="bi bi-play-fill"></i> Kích hoạt (Enable)
                                    </button>
                                </template>

                                <template x-if="server.is_active && server.status === 'offline'">
                                    <button class="hvn-btn hvn-btn-sm hvn-btn-warning hvn-w-100 hvn-text-start hvn-mt-1"
                                        @click="resetBackoff(server)" :disabled="loading">
                                        <i class="bi bi-arrow-repeat"></i> Reset Backoff
                                    </button>
                                </template>
                            </div>

                        </div>
                    </div>
                </div>
            </div>
        </template>
    </div>

    <div class="hvn-alert hvn-alert-info hvn-mt-4">
        <i class="bi bi-info-circle-fill"></i>
        <strong>Ghi chú:</strong> Disable server sẽ dừng nhận queue jobs mới.
        Uptime được tính từ 100 sync log gần nhất.
    </div>
</div>

<script>
    var HVNDNS_SERVERS    = {$serversJson};
    var HVNDNS_MODULELINK = '{$modulelink|escape:'javascript'}';
</script>
<script>
{literal}
document.addEventListener('alpine:init', () => {
    Alpine.data('serverManager', () => ({
        servers:   HVNDNS_SERVERS,
        loading:   false,

        // ── Helper: gọi AJAX POST ─────────────────────────────────────────
        async post(method, body) {
            const fd = new FormData();
            fd.append('method', method);
            for (const [k, v] of Object.entries(body)) {
                fd.append(k, v);
            }
            const res = await fetch(HVNDNS_MODULELINK + '&action=ajax', {
                method: 'POST',
                headers: { 'X-Requested-With': 'XMLHttpRequest' },
                body: fd,
            });
            return res.json();
        },

        // ── Hiện toast (dùng global _hvnToast) ───────────────────────────
        showAlert(msg, type) {
            var title = type === 'error' ? 'Lỗi' : 'Thành công';
            // Bỏ emoji prefix nếu có
            var clean = msg.replace(/^[✅❌⚠️\s]+/, '');
            window._hvnToast(type === 'error' ? 'error' : 'success', title, clean);
        },

        // ── Test Connection ───────────────────────────────────────────────
        async testConnection(server) {
            this.loading = true;
            try {
                const data = await this.post('testConnection', {
                    hostname:   server.hostname,
                    ip_address: server.ip_address,
                    port:       server.port,
                    use_ssl:    server.use_ssl ? '1' : '0',
                    username:   'admin',
                    server_id:  server.id,
                });
                if (data.success) {
                    this.showAlert('✅ ' + server.hostname + ': Kết nối thành công!', 'success');
                } else {
                    this.showAlert('❌ ' + server.hostname + ': ' + (data.error?.message || 'Lỗi không xác định'), 'error');
                }
            } catch (err) {
                this.showAlert('❌ Lỗi mạng: ' + err.message, 'error');
            } finally {
                this.loading = false;
            }
        },

        // ── Toggle Enable / Disable ───────────────────────────────────────
        async toggleStatus(server) {
            const action = server.is_active ? 'vô hiệu hóa' : 'kích hoạt';
            var ok = await window._hvnConfirm({
                title:        'Xác nhận ' + action + ' server?',
                message:      'Bạn có chắc muốn ' + action + ' server ' + server.hostname + '?',
                variant:      server.is_active ? 'danger' : 'info',
                confirmLabel: action.charAt(0).toUpperCase() + action.slice(1),
                cancelLabel:  'Hủy'
            });
            if (!ok) return;

            this.loading = true;
            try {
                const data = await this.post('toggleServerStatus', { server_id: server.id });
                if (data.success) {
                    server.is_active = data.is_active;
                    if (data.is_active) server.status = 'online';
                    this.showAlert('✅ ' + data.message, 'success');
                } else {
                    this.showAlert('❌ ' + (data.error || 'Lỗi không xác định'), 'error');
                }
            } catch (err) {
                this.showAlert('❌ Lỗi mạng: ' + err.message, 'error');
            } finally {
                this.loading = false;
            }
        },

        // ── Reset Backoff ─────────────────────────────────────────────────
        async resetBackoff(server) {
            var ok = await window._hvnConfirm({
                title:        'Reset Backoff?',
                message:      'Reset lỗi và thử lại ngay cho ' + server.hostname + '?\nCác job FAILED sẽ được đưa về PENDING.',
                variant:      'warning',
                confirmLabel: 'Reset Backoff',
                cancelLabel:  'Hủy'
            });
            if (!ok) return;

            this.loading = true;
            try {
                const data = await this.post('resetServerBackoff', { server_id: server.id });
                if (data.success) {
                    server.status       = 'online';
                    server.failed_count = 0;
                    server.next_retry   = null;
                    server.retry_in     = null;
                    server.last_error   = null;
                    this.showAlert('✅ ' + data.message, 'success');
                } else {
                    this.showAlert('❌ ' + (data.error || 'Lỗi không xác định'), 'error');
                }
            } catch (err) {
                this.showAlert('❌ Lỗi mạng: ' + err.message, 'error');
            } finally {
                this.loading = false;
            }
        },
    }));
});
{/literal}
</script>