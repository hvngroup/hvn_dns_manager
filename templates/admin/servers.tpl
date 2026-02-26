<div class="hvn-dns-admin hvn-servers" x-data="serverManager()">
    <div class="hvn-d-flex hvn-justify-content-between hvn-align-items-center hvn-mb-4">
        <h2><i class="bi bi-server"></i> Quản lý Server DirectAdmin</h2>
        <a href="{$modulelink}&action=server_edit" class="hvn-btn hvn-btn-primary"><i class="bi bi-plus-lg"></i> Thêm Server</a>
    </div>

    <div class="hvn-row">
        <!-- Loop qua các server -->
        <template x-for="server in servers" :key="server.id">
            <div class="hvn-col-12 hvn-mb-3">
                <div class="hvn-card hvn-shadow-sm hvn-border-0" :class="{ 'hvn-border-start hvn-border-success': server.status === 'online' && server.is_active, 'hvn-border-start hvn-border-danger': server.status === 'offline' && server.is_active, 'hvn-border-start border-secondary opacity-75': !server.is_active }">
                    <div class="hvn-card-body">
                        <div class="hvn-row hvn-align-items-center">
                            <!-- Server Info Info -->
                            <div class="hvn-col-md-3">
                                <h5 class="card-title hvn-mb-1 hvn-d-flex hvn-align-items-center">
                                    <template x-if="server.status === 'online' && server.is_active">
                                        <span class="hvn-text-success hvn-me-2" title="Online">🟢</span>
                                    </template>
                                    <template x-if="server.status === 'offline' && server.is_active">
                                        <span class="hvn-text-danger hvn-me-2" title="Offline">🔴</span>
                                    </template>
                                    <template x-if="!server.is_active">
                                        <span class="hvn-text-secondary hvn-me-2" title="Disabled">⚪</span>
                                    </template>
                                    
                                    <span x-text="server.hostname"></span>
                                    
                                    <template x-if="server.is_primary">
                                        <span class="hvn-badge hvn-bg-primary hvn-ms-2" style="font-size: 0.6em;">Primary</span>
                                    </template>
                                    <template x-if="!server.is_primary">
                                        <span class="hvn-badge hvn-bg-secondary hvn-ms-2" style="font-size: 0.6em;">Secondary</span>
                                    </template>
                                </h5>
                                <div class="hvn-text-muted small">
                                    IP: <span class="font-monospace" x-text="server.ip_address"></span> | 
                                    Port: <span x-text="server.port"></span> | 
                                    SSL: <span x-text="server.use_ssl ? '✅' : '❌'"></span>
                                </div>
                                <div class="hvn-text-muted small hvn-mt-1">
                                    Max concurrent: <span x-text="server.max_concurrent_jobs"></span>
                                </div>
                            </div>
                            
                            <!-- Stats -->
                            <div class="hvn-col-md-5 hvn-border-start hvn-border-end hvn-px-4">
                                <template x-if="server.is_active && server.status !== 'offline'">
                                    <div>
                                        <div class="hvn-row hvn-text-center hvn-mb-1 mt-2">
                                            <div class="hvn-col hvn-border-end">
                                                <i class="bi bi-activity hvn-text-primary hvn-fs-4 hvn-d-block mb-1"></i>
                                                <div class="hvn-fw-bold hvn-fs-5"><span x-text="server.uptime"></span>%</div>
                                                <div class="hvn-text-muted text-uppercase" style="font-size: 0.7rem; letter-spacing: 0.5px;">Uptime</div>
                                            </div>
                                            <div class="hvn-col hvn-border-end">
                                                <i class="bi bi-speedometer2 hvn-text-info hvn-fs-4 hvn-d-block mb-1"></i>
                                                <div class="hvn-fw-bold hvn-fs-5"><span x-text="server.latency"></span>ms</div>
                                                <div class="hvn-text-muted text-uppercase" style="font-size: 0.7rem; letter-spacing: 0.5px;">Avg Latency</div>
                                            </div>
                                            <div class="hvn-col">
                                                <i class="bi bi-shield-check hvn-text-success hvn-fs-4 hvn-d-block mb-1"></i>
                                                <div class="hvn-fw-bold hvn-text-success hvn-fs-5"><span x-text="server.last_ok"></span></div>
                                                <div class="hvn-text-muted text-uppercase" style="font-size: 0.7rem; letter-spacing: 0.5px;">Last OK</div>
                                            </div>
                                        </div>
                                        <hr class="my-2">
                                        <div class="hvn-d-flex hvn-justify-content-between small">
                                            <span><i class="bi bi-clock"></i> Pending: <strong x-text="server.pending_jobs"></strong></span>
                                            <span class="hvn-text-success">Today: <strong x-text="server.today_completed"></strong> complete</span>
                                        </div>
                                    </div>
                                </template>
                                
                                <template x-if="!server.is_active">
                                    <div class="hvn-text-center hvn-text-muted hvn-py-3">
                                        <i class="bi bi-pause-circle fs-4 hvn-d-block hvn-mb-1"></i>
                                        Server đang bị vô hiệu hóa
                                    </div>
                                </template>
                                
                                <template x-if="server.is_active && server.status === 'offline'">
                                    <div>
                                        <div class="hvn-text-danger hvn-fw-bold hvn-mb-1">
                                            <i class="bi bi-exclamation-triangle"></i> BACKOFF: Retry lúc <span x-text="server.next_retry"></span> (<span x-text="server.retry_in"></span>)
                                        </div>
                                        <div class="small hvn-text-muted hvn-mb-1">
                                            Failed: <span x-text="server.failed_count"></span> liên tiếp | Last error: timeout
                                        </div>
                                        <div class="small hvn-text-danger hvn-bg-danger-subtle hvn-p-1 hvn-rounded font-monospace" style="font-size: 0.75rem;">
                                            Error: <span x-text="server.last_error"></span>
                                        </div>
                                    </div>
                                </template>
                            </div>
                            
                            <!-- Actions -->
                            <div class="hvn-col-md-4 hvn-text-end">
                                <button class="hvn-btn btn-sm btn-outline-info hvn-mb-1 w-100 text-start" @click="testConnection(server)">
                                    <i class="bi bi-plug"></i> Test Connection
                                </button>
                                <a :href="'{$modulelink}&action=server_edit&id=' + server.id" class="hvn-btn btn-sm hvn-btn-outline-primary hvn-mb-1 w-100 text-start hvn-d-block text-decoration-none">
                                    <i class="bi bi-pencil"></i> Sửa cấu hình
                                </a>
                                <template x-if="server.is_active">
                                    <button class="hvn-btn btn-sm btn-outline-danger w-100 text-start" @click="toggleStatus(server)">
                                        <i class="bi bi-pause-fill"></i> Vô hiệu hóa (Disable)
                                    </button>
                                </template>
                                <template x-if="!server.is_active">
                                    <button class="hvn-btn btn-sm btn-outline-success w-100 text-start" @click="toggleStatus(server)">
                                        <i class="bi bi-play-fill"></i> Kích hoạt (Enable)
                                    </button>
                                </template>
                                <template x-if="server.is_active && server.status === 'offline'">
                                    <button class="hvn-btn btn-sm hvn-btn-warning w-100 text-start hvn-mt-1" @click="resetBackoff(server)">
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

    <div class="alert alert-info hvn-mt-4">
        <i class="bi bi-info-circle-fill"></i> <strong>Ghi chú:</strong> Disable server sẽ dừng nhận queue jobs (nếu là primary của zone). Job PENDING hiện tại đang gán cho server này sẽ chuyển sang CANCELLED hoặc gán lại (re-assign) cho server khác tùy cấu hình.
    </div>


</div>

<script>
{literal}
document.addEventListener('alpine:init', () => {
    Alpine.data('serverManager', () => ({
        servers: [
            {
                id: 1, hostname: 'dns1.hvn.vn', ip_address: '103.45.67.10', port: 2222, use_ssl: true,
                username: 'admin', is_primary: true, max_concurrent_jobs: 50, notes: 'Hà Nội DC',
                is_active: true, status: 'online', uptime: 99.8, latency: 45, last_ok: '2 min ago',
                pending_jobs: 12, today_completed: 425
            },
            {
                id: 2, hostname: 'dns2.hvn.vn', ip_address: '103.45.67.11', port: 2222, use_ssl: true,
                username: 'admin', is_primary: false, max_concurrent_jobs: 50, notes: 'HCM DC',
                is_active: true, status: 'online', uptime: 99.5, latency: 52, last_ok: '2 min ago',
                pending_jobs: 12, today_completed: 423
            },
            {
                id: 3, hostname: 'dns3.hvn.vn', ip_address: '103.45.67.12', port: 2222, use_ssl: true,
                username: 'admin', is_primary: false, max_concurrent_jobs: 50, notes: 'Cloud Backup',
                is_active: true, status: 'offline', uptime: 97.1, latency: 0, last_ok: '15 min ago',
                pending_jobs: 0, today_completed: 120,
                next_retry: '14:48', retry_in: '4 phút nữa', failed_count: 7, last_error: 'Connection timed out after 15000ms'
            }
        ],



        testConnection(server) {
            // Mock API Call
            alert(`Đang test kết nối đến ${server.hostname} (${server.ip_address}:${server.port})...\n\nGiả lập: Thành công! Latency: 42ms.`);
        },

        toggleStatus(server) {
            const action = server.is_active ? 'vô hiệu hóa' : 'kích hoạt';
            if(confirm(`Bạn có chắc muốn ${action} server ${server.hostname}?`)) {
                server.is_active = !server.is_active;
                // Nếu activate lại thì mock status online luôn
                if(server.is_active) {
                    server.status = 'online';
                }
            }
        },

        resetBackoff(server) {
            if(confirm(`Reset lỗi và thử lại ngay lập tức cho ${server.hostname}?`)) {
                server.status = 'online';
                server.failed_count = 0;
            }
        }
    }));
});
{/literal}
</script>
