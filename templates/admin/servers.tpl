<div class="hvn-dns-admin hvn-servers" x-data="serverManager()">
    <div class="d-flex justify-content-between align-items-center mb-4">
        <h2><i class="bi bi-server"></i> Quản lý Server DirectAdmin</h2>
        <button class="btn btn-primary" @click="openModal()"><i class="bi bi-plus-lg"></i> Thêm Server</button>
    </div>

    <div class="row">
        <!-- Loop qua các server -->
        <template x-for="server in servers" :key="server.id">
            <div class="col-12 mb-3">
                <div class="card shadow-sm border-0" :class="{'border-start border-4 border-success': server.status === 'online' && server.is_active, 'border-start border-4 border-danger': server.status === 'offline' && server.is_active, 'border-start border-4 border-secondary opacity-75': !server.is_active}">
                    <div class="card-body">
                        <div class="row align-items-center">
                            <!-- Server Info Info -->
                            <div class="col-md-3">
                                <h5 class="card-title mb-1 d-flex align-items-center">
                                    <template x-if="server.status === 'online' && server.is_active">
                                        <span class="text-success me-2" title="Online">🟢</span>
                                    </template>
                                    <template x-if="server.status === 'offline' && server.is_active">
                                        <span class="text-danger me-2" title="Offline">🔴</span>
                                    </template>
                                    <template x-if="!server.is_active">
                                        <span class="text-secondary me-2" title="Disabled">⚪</span>
                                    </template>
                                    
                                    <span x-text="server.hostname"></span>
                                    
                                    <template x-if="server.is_primary">
                                        <span class="badge bg-primary ms-2" style="font-size: 0.6em;">Primary</span>
                                    </template>
                                    <template x-if="!server.is_primary">
                                        <span class="badge bg-secondary ms-2" style="font-size: 0.6em;">Secondary</span>
                                    </template>
                                </h5>
                                <div class="text-muted small">
                                    IP: <span class="font-monospace" x-text="server.ip_address"></span> | 
                                    Port: <span x-text="server.port"></span> | 
                                    SSL: <span x-text="server.use_ssl ? '✅' : '❌'"></span>
                                </div>
                                <div class="text-muted small mt-1">
                                    Max concurrent: <span x-text="server.max_concurrent_jobs"></span>
                                </div>
                            </div>
                            
                            <!-- Stats -->
                            <div class="col-md-5 border-start border-end px-4">
                                <template x-if="server.is_active && server.status !== 'offline'">
                                    <div>
                                        <div class="row text-center mb-1">
                                            <div class="col">
                                                <div class="fw-bold"><span x-text="server.uptime"></span>%</div>
                                                <div class="small text-muted">Uptime</div>
                                            </div>
                                            <div class="col">
                                                <div class="fw-bold"><span x-text="server.latency"></span>ms</div>
                                                <div class="small text-muted">Avg Latency</div>
                                            </div>
                                            <div class="col">
                                                <div class="fw-bold text-success"><span x-text="server.last_ok"></span></div>
                                                <div class="small text-muted">Last OK</div>
                                            </div>
                                        </div>
                                        <hr class="my-2">
                                        <div class="d-flex justify-content-between small">
                                            <span><i class="bi bi-clock"></i> Pending: <strong x-text="server.pending_jobs"></strong></span>
                                            <span class="text-success">Today: <strong x-text="server.today_completed"></strong> complete</span>
                                        </div>
                                    </div>
                                </template>
                                
                                <template x-if="!server.is_active">
                                    <div class="text-center text-muted py-3">
                                        <i class="bi bi-pause-circle fs-4 d-block mb-1"></i>
                                        Server đang bị vô hiệu hóa
                                    </div>
                                </template>
                                
                                <template x-if="server.is_active && server.status === 'offline'">
                                    <div>
                                        <div class="text-danger fw-bold mb-1">
                                            <i class="bi bi-exclamation-triangle"></i> BACKOFF: Retry lúc <span x-text="server.next_retry"></span> (<span x-text="server.retry_in"></span>)
                                        </div>
                                        <div class="small text-muted mb-1">
                                            Failed: <span x-text="server.failed_count"></span> liên tiếp | Last error: timeout
                                        </div>
                                        <div class="small text-danger bg-danger-subtle p-1 rounded font-monospace" style="font-size: 0.75rem;">
                                            Error: <span x-text="server.last_error"></span>
                                        </div>
                                    </div>
                                </template>
                            </div>
                            
                            <!-- Actions -->
                            <div class="col-md-4 text-end">
                                <button class="btn btn-sm btn-outline-info mb-1 w-100 text-start" @click="testConnection(server)">
                                    <i class="bi bi-plug"></i> Test Connection
                                </button>
                                <button class="btn btn-sm btn-outline-primary mb-1 w-100 text-start" @click="openModal(server)">
                                    <i class="bi bi-pencil"></i> Sửa cấu hình
                                </button>
                                <template x-if="server.is_active">
                                    <button class="btn btn-sm btn-outline-danger w-100 text-start" @click="toggleStatus(server)">
                                        <i class="bi bi-pause-fill"></i> Vô hiệu hóa (Disable)
                                    </button>
                                </template>
                                <template x-if="!server.is_active">
                                    <button class="btn btn-sm btn-outline-success w-100 text-start" @click="toggleStatus(server)">
                                        <i class="bi bi-play-fill"></i> Kích hoạt (Enable)
                                    </button>
                                </template>
                                <template x-if="server.is_active && server.status === 'offline'">
                                    <button class="btn btn-sm btn-warning w-100 text-start mt-1" @click="resetBackoff(server)">
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

    <div class="alert alert-info mt-4">
        <i class="bi bi-info-circle-fill"></i> <strong>Ghi chú:</strong> Disable server sẽ dừng nhận queue jobs (nếu là primary của zone). Job PENDING hiện tại đang gán cho server này sẽ chuyển sang CANCELLED hoặc gán lại (re-assign) cho server khác tùy cấu hình.
    </div>

    {include file="./partials/server_modal.tpl"}
</div>

<script>
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

        openModal(server = null) {
            window.dispatchEvent(new CustomEvent('open-server-modal', { detail: { server } }));
        },

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
</script>
