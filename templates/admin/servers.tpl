<div class="mj-dns-admin mj-servers" x-data="serverManager()">
    <div class="mj-d-flex mj-justify-content-between mj-align-items-center mj-mb-4">
        <h2><i class="bi bi-server"></i> Quản lý Server DirectAdmin</h2>
        <a href="{$modulelink}&action=server_edit" class="mj-btn mj-btn-primary">
            <i class="bi bi-plus-lg"></i> Thêm Server
        </a>
    </div>


    <div class="mj-row">
        <template x-for="server in servers" :key="server.id">
            <div class="mj-col-12 mj-mb-3">
                <div class="mj-card mj-shadow-sm mj-border-0"
                    :class="{
                        'mj-border-start mj-border-success': server.status === 'online' && server.is_active,
                        'mj-border-start mj-border-warning': server.status === 'warning' && server.is_active,
                        'mj-border-start mj-border-danger':  server.status === 'offline' && server.is_active,
                        'mj-border-start border-secondary opacity-75': !server.is_active
                    }">
                    <div class="mj-card-body">
                        <div class="mj-row mj-align-items-center">

                            <!-- ── Server Info ─────────────────────────── -->
                            <div class="mj-col-md-3">
                                <h5 class="mj-card-title mj-mb-1 mj-d-flex mj-align-items-center">
                                    <template x-if="server.status === 'online' && server.is_active">
                                        <span class="mj-me-2" title="Online">🟢</span>
                                    </template>
                                    <template x-if="server.status === 'warning' && server.is_active">
                                        <span class="mj-me-2" title="Warning">🟡</span>
                                    </template>
                                    <template x-if="server.status === 'offline' && server.is_active">
                                        <span class="mj-me-2" title="Offline">🔴</span>
                                    </template>
                                    <template x-if="!server.is_active">
                                        <span class="mj-me-2" title="Disabled">⚪</span>
                                    </template>

                                    <span x-text="server.hostname"></span>

                                    <template x-if="server.is_primary">
                                        <span class="mj-badge mj-bg-primary mj-ms-2" style="font-size:0.6em;">Primary</span>
                                    </template>
                                    <template x-if="!server.is_primary">
                                        <span class="mj-badge mj-bg-secondary mj-ms-2" style="font-size:0.6em;">Secondary</span>
                                    </template>
                                </h5>
                                <div class="mj-text-muted mj-small">
                                    IP: <span class="mj-font-monospace" x-text="server.ip_address"></span> |
                                    Port: <span x-text="server.port"></span> |
                                    SSL: <span x-text="server.use_ssl ? '✅' : '❌'"></span>
                                </div>
                                <div class="mj-text-muted mj-small mj-mt-1">
                                    Max concurrent: <span x-text="server.max_concurrent_jobs"></span>
                                </div>
                            </div>

                            <!-- ── Stats ──────────────────────────────── -->
                            <div class="mj-col-md-5 mj-border-start mj-border-end mj-px-4">

                                <!-- Server active + không offline -->
                                <template x-if="server.is_active && server.status !== 'offline'">
                                    <div>
                                        <div class="mj-row mj-text-center mj-mb-1 mj-mt-2">
                                            <div class="mj-col mj-border-end">
                                                <i class="bi bi-activity mj-text-primary mj-fs-4 mj-d-block mj-mb-1"></i>
                                                <div class="mj-fw-bold mj-fs-5">
                                                    <template x-if="server.uptime !== null">
                                                        <span x-text="server.uptime + '%'"></span>
                                                    </template>
                                                    <template x-if="server.uptime === null">
                                                        <span class="mj-text-muted">N/A</span>
                                                    </template>
                                                </div>
                                                <div class="mj-text-muted mj-text-uppercase" style="font-size:0.7rem;letter-spacing:0.5px;">Uptime</div>
                                            </div>
                                            <div class="mj-col mj-border-end">
                                                <i class="bi bi-speedometer2 mj-text-info mj-fs-4 mj-d-block mj-mb-1"></i>
                                                <div class="mj-fw-bold mj-fs-5">
                                                    <template x-if="server.latency > 0">
                                                        <span x-text="server.latency + 'ms'"></span>
                                                    </template>
                                                    <template x-if="server.latency === 0">
                                                        <span class="mj-text-muted">N/A</span>
                                                    </template>
                                                </div>
                                                <div class="mj-text-muted mj-text-uppercase" style="font-size:0.7rem;letter-spacing:0.5px;">Avg Latency</div>
                                            </div>
                                            <div class="mj-col">
                                                <i class="bi bi-shield-check mj-text-success mj-fs-4 mj-d-block mj-mb-1"></i>
                                                <div class="mj-fw-bold mj-text-success mj-fs-5" x-text="server.last_ok"></div>
                                                <div class="mj-text-muted mj-text-uppercase" style="font-size:0.7rem;letter-spacing:0.5px;">Last OK</div>
                                            </div>
                                        </div>
                                        <hr class="my-2">
                                        <div class="mj-d-flex mj-justify-content-between mj-small">
                                            <span><i class="bi bi-clock"></i> Pending: <strong x-text="server.pending_jobs"></strong></span>
                                            <span class="mj-text-success">Today: <strong x-text="server.today_completed"></strong> complete</span>
                                        </div>
                                    </div>
                                </template>

                                <!-- Server bị disable -->
                                <template x-if="!server.is_active">
                                    <div class="mj-text-center mj-text-muted mj-py-3">
                                        <i class="bi bi-pause-circle mj-fs-4 mj-d-block mj-mb-1"></i>
                                        Server đang bị vô hiệu hóa
                                    </div>
                                </template>

                                <!-- Server offline / backoff -->
                                <template x-if="server.is_active && server.status === 'offline'">
                                    <div>
                                        <div class="mj-text-danger mj-fw-bold mj-mb-1">
                                            <i class="bi bi-exclamation-triangle"></i>
                                            BACKOFF — Retry lúc <span x-text="server.next_retry"></span>
                                            (<span x-text="server.retry_in"></span>)
                                        </div>
                                        <div class="mj-small mj-text-muted mj-mb-1">
                                            Failed: <span x-text="server.failed_count"></span> lần liên tiếp
                                        </div>
                                        <div class="mj-small mj-text-danger mj-bg-danger-subtle mj-p-1 mj-rounded mj-font-monospace" style="font-size:0.75rem;">
                                            Error: <span x-text="server.last_error || '(không rõ)'"></span>
                                        </div>
                                    </div>
                                </template>
                            </div>

                            <!-- ── Actions ────────────────────────────── -->
                            <div class="mj-col-md-4 mj-text-end">
                                <button class="mj-btn mj-btn-sm mj-btn-outline-info mj-mb-1 mj-w-100 mj-text-start"
                                    @click="testConnection(server)" :disabled="loading">
                                    <i class="bi bi-plug"></i> Test Connection
                                </button>

                                <a :href="'{$modulelink}&action=server_edit&id=' + server.id"
                                    class="mj-btn mj-btn-sm mj-btn-outline-primary mj-mb-1 mj-w-100 mj-text-start mj-d-block mj-text-decoration-none">
                                    <i class="bi bi-pencil"></i> Sửa cấu hình
                                </a>

                                <template x-if="server.is_active">
                                    <button class="mj-btn mj-btn-sm mj-btn-outline-danger mj-w-100 mj-text-start"
                                        @click="toggleStatus(server)" :disabled="loading">
                                        <i class="bi bi-pause-fill"></i> Vô hiệu hóa (Disable)
                                    </button>
                                </template>
                                <template x-if="!server.is_active">
                                    <button class="mj-btn mj-btn-sm mj-btn-outline-success mj-w-100 mj-text-start"
                                        @click="toggleStatus(server)" :disabled="loading">
                                        <i class="bi bi-play-fill"></i> Kích hoạt (Enable)
                                    </button>
                                </template>

                                <template x-if="server.is_active && server.status === 'offline'">
                                    <button class="mj-btn mj-btn-sm mj-btn-warning mj-w-100 mj-text-start mj-mt-1"
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

    <div class="mj-alert mj-alert-info mj-mt-4">
        <i class="bi bi-info-circle-fill"></i>
        <strong>Ghi chú:</strong> Disable server sẽ dừng nhận queue jobs mới.
        Uptime được tính từ 100 sync log gần nhất.
    </div>
</div>

<script>
    var MJDNS_SERVERS    = {$serversJson};
    var MJDNS_MODULELINK = '{$modulelink|escape:'javascript'}';
</script>
<script>
{literal}
document.addEventListener('alpine:init', () => {
    Alpine.data('serverManager', () => ({
        servers:   MJDNS_SERVERS,
        loading:   false,

        // ── Helper: gọi AJAX POST ─────────────────────────────────────────
        async post(method, body) {
            const fd = new FormData();
            fd.append('method', method);
            for (const [k, v] of Object.entries(body)) {
                fd.append(k, v);
            }
            const res = await fetch(MJDNS_MODULELINK + '&action=ajax', {
                method: 'POST',
                headers: { 'X-Requested-With': 'XMLHttpRequest' },
                body: fd,
            });
            return res.json();
        },

        // ── Hiện toast (dùng global _mjDnsToast) ───────────────────────────
        showAlert(msg, type) {
            var title = type === 'error' ? 'Lỗi' : 'Thành công';
            // Bỏ emoji prefix nếu có
            var clean = msg.replace(/^[✅❌⚠️\s]+/, '');
            window._mjDnsToast(type === 'error' ? 'error' : 'success', title, clean);
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
            var ok = await window._mjDnsConfirm({
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
            var ok = await window._mjDnsConfirm({
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