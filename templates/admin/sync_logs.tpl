<div class="hvn-dns-admin hvn-sync-logs" x-data="syncLogsData()">
    <div class="hvn-d-flex hvn-justify-content-between hvn-align-items-center hvn-mb-4">
        <h2><i class="bi bi-journal-check"></i> Lịch sử Đồng bộ (Sync Logs)</h2>
        <div>
            <button class="hvn-btn btn-outline-success"><i class="bi bi-file-earmark-spreadsheet"></i> Export CSV</button>
            <button class="hvn-btn hvn-btn-warning hvn-ms-2" @click="alert('Đang thử kết nối lại toàn bộ job thất bại...')"><i class="bi bi-arrow-repeat"></i> Retry All Failed (12)</button>
        </div>
    </div>

    <!-- Toolbar Filters -->
    <div class="hvn-card hvn-shadow-sm hvn-border-0 hvn-mb-4 hvn-bg-light">
        <div class="hvn-card-body hvn-py-3">
            <div class="hvn-row g-2 hvn-align-items-center">
                <div class="hvn-col-md-3">
                    <input type="text" class="hvn-form-control" placeholder="Tên miền (VD: myblog.net)...">
                </div>
                <div class="hvn-col-md-2">
                    <select class="hvn-form-select">
                        <option value="">Tất cả trạng thái</option>
                        <option value="complete">✅ Complete</option>
                        <option value="pending">🟡 Pending</option>
                        <option value="failed">❌ Failed</option>
                    </select>
                </div>
                <div class="hvn-col-md-2">
                    <select class="hvn-form-select">
                        <option value="">Tất cả Server</option>
                        <option value="dns1.hvn.vn">dns1.hvn.vn</option>
                        <option value="dns2.hvn.vn">dns2.hvn.vn</option>
                        <option value="dns3.hvn.vn">dns3.hvn.vn</option>
                    </select>
                </div>
                <div class="hvn-col-md-2">
                    <select class="hvn-form-select">
                        <option value="">Tất cả Action</option>
                        <option value="ADD_RECORD">ADD_RECORD</option>
                        <option value="EDIT_RECORD">EDIT_RECORD</option>
                        <option value="DELETE_RECORD">DELETE_RECORD</option>
                        <option value="ENABLE_DNSSEC">ENABLE_DNSSEC</option>
                    </select>
                </div>
                <div class="hvn-col-md-3 hvn-text-end">
                    <button class="hvn-btn hvn-btn-primary"><i class="bi bi-funnel"></i> Lọc</button>
                    <button class="hvn-btn btn-outline-secondary"><i class="bi bi-arrow-counterclockwise"></i></button>
                </div>
            </div>
            <div class="hvn-row hvn-mt-2 g-2">
                <div class="hvn-col-md-4 hvn-d-flex hvn-align-items-center">
                    <span class="hvn-me-2 small">Từ:</span> <input type="date" class="hvn-form-control hvn-form-control-sm">
                </div>
                <div class="hvn-col-md-4 hvn-d-flex hvn-align-items-center">
                    <span class="hvn-me-2 small">Đến:</span> <input type="date" class="hvn-form-control hvn-form-control-sm">
                </div>
            </div>
        </div>
    </div>

    <!-- Main Table (full-width) -->
    <div class="hvn-card hvn-shadow-sm hvn-border-0">
        <div class="hvn-card-body hvn-p-0">
            <div class="table-responsive">
                <table class="table table-hover align-middle hvn-mb-0 font-monospace" style="font-size: 12px">
                    <thead class="table-light">
                        <tr>
                            <th class="hvn-ps-3">ID</th>
                            <th>Thời gian</th>
                            <th>Domain</th>
                            <th>Action</th>
                            <th>Server</th>
                            <th>Status</th>
                            <th>ms</th>
                            <th class="hvn-text-end hvn-pe-3"></th>
                        </tr>
                    </thead>
                    <tbody>
                        <template x-for="log in logs" :key="log.id">
                            <tr>
                                <td class="hvn-ps-3 hvn-text-muted" x-text="'#' + log.id"></td>
                                <td x-text="log.time"></td>
                                <td>
                                    <a :href="'?module=hvn_dns_manager&action=admin_dns_editor&domain_id=' + log.domain" x-text="log.domain"></a>
                                </td>
                                <td>
                                    <div class="hvn-fw-bold" x-text="log.action"></div>
                                    <div class="small hvn-text-muted" x-text="log.details"></div>
                                </td>
                                <td x-text="log.server"></td>
                                <td>
                                    <template x-if="log.status === 'complete'"><span class="hvn-badge hvn-bg-success">✅ Complete</span></template>
                                    <template x-if="log.status === 'failed'"><span class="hvn-badge hvn-bg-danger">❌ Failed</span></template>
                                    <template x-if="log.status === 'pending'"><span class="hvn-badge hvn-bg-warning hvn-text-dark">🟡 Pending</span></template>
                                    <div class="small hvn-text-danger" x-text="log.error_brief"></div>
                                </td>
                                <td x-text="log.ms || '--'"></td>
                                <td class="hvn-text-end hvn-pe-3">
                                    <template x-if="log.status === 'failed'">
                                        <button class="hvn-btn btn-sm btn-outline-warning hvn-me-1" @click="retryJob(log)">
                                            <i class="bi bi-arrow-repeat"></i>
                                        </button>
                                    </template>
                                    <a :href="'?module=hvn_dns_manager&action=sync_log_detail&id=' + log.id"
                                       class="hvn-btn btn-sm btn-light border text-decoration-none">
                                        <i class="bi bi-search"></i> Chi tiết
                                    </a>
                                </td>
                            </tr>
                        </template>
                    </tbody>
                </table>
            </div>
        </div>
    </div>

    <nav class="hvn-mt-3">
        <ul class="pagination pagination-sm hvn-justify-content-end">
            <li class="page-item disabled"><a class="page-link" href="#">Previous</a></li>
            <li class="page-item active"><a class="page-link" href="#">1</a></li>
            <li class="page-item"><a class="page-link" href="#">2</a></li>
            <li class="page-item"><a class="page-link" href="#">3</a></li>
            <li class="page-item"><a class="page-link" href="#">Next</a></li>
        </ul>
    </nav>
</div>

<script>
{literal}
document.addEventListener('alpine:init', () => {
    Alpine.data('syncLogsData', () => ({
        logs: [
            {
                id: 4521, time: '14:32', domain: 'myblog.net', action: 'DELETE_RECORD', details: 'A @ 1.2.3.4',
                server: 'dns3.hvn.vn', status: 'failed', error_brief: 'tmout', ms: null
            },
            {
                id: 4520, time: '14:31', domain: 'shop.vn', action: 'ADD_RECORD', details: 'A mail',
                server: 'dns1.hvn.vn', status: 'complete', error_brief: '', ms: 89
            },
            {
                id: 4519, time: '14:31', domain: 'shop.vn', action: 'ADD_RECORD', details: 'A mail',
                server: 'dns2.hvn.vn', status: 'complete', error_brief: '', ms: 92
            },
            {
                id: 4518, time: '14:31', domain: 'shop.vn', action: 'ADD_RECORD', details: 'A mail',
                server: 'dns3.hvn.vn', status: 'failed', error_brief: 'tmout', ms: null
            }
        ],

        retryJob(log) {
            alert(`Đang thử gửi lại Job #${log.id} tới server ${log.server}...`);
            log.status = 'pending';
            log.error_brief = 'retrying';
            setTimeout(() => {
                log.status = 'complete';
                log.error_brief = '';
                log.ms = Math.floor(Math.random() * 100) + 30;
            }, 1000);
        }
    }));
});
{/literal}
</script>
