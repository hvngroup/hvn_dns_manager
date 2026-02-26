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

    <div class="hvn-row">
        <!-- Main Table -->
        <div class="hvn-col-md-8">
            <div class="hvn-card hvn-shadow-sm hvn-border-0">
                <div class="hvn-card-body hvn-p-0">
                    <div class="table-responsive">
                        <table class="table table-hover align-middle hvn-mb-0 font-monospace text-sm" style="font-size: 0.85rem">
                            <thead class="table-light">
                                <tr>
                                    <th class="hvn-ps-3">Thời gian</th>
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
                                    <tr @click="selectLog(log)" style="cursor: pointer;" :class="{ 'table-active': selectedLog && selectedLog.id === log.id}">
                                        <td class="hvn-ps-3" x-text="log.time"></td>
                                        <td><a :href="'?module=hvn_dns_manager&action=admin_dns_editor&domain_id=' + log.domain" x-text="log.domain" @click.stop></a></td>
                                        <td>
                                            <div class="hvn-fw-bold" x-text="log.action"></div>
                                            <div class="small hvn-text-muted" x-text="log.details"></div>
                                        </td>
                                        <td x-text="log.server"></td>
                                        <td>
                                            <template x-if="log.status === 'complete'"><span class="hvn-badge hvn-bg-success">✅</span></template>
                                            <template x-if="log.status === 'failed'"><span class="hvn-badge hvn-bg-danger">❌</span></template>
                                            <template x-if="log.status === 'pending'"><span class="hvn-badge hvn-bg-warning hvn-text-dark">🟡</span></template>
                                            <div class="small hvn-text-muted" x-text="log.error_brief"></div>
                                        </td>
                                        <td x-text="log.ms || '--'"></td>
                                        <td class="hvn-text-end hvn-pe-3">
                                            <template x-if="log.status === 'failed'">
                                                <button class="hvn-btn btn-sm btn-outline-warning" @click.stop="retryJob(log)"><i class="bi bi-arrow-repeat"></i></button>
                                            </template>
                                            <button class="hvn-btn btn-sm btn-light border"><i class="bi bi-search"></i></button>
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
        
        <!-- Detail Panel -->
        <div class="hvn-col-md-4">
            <div class="hvn-card hvn-shadow-sm hvn-border-0 sticky-top" style="top: 20px;">
                <div class="hvn-card-header hvn-bg-white hvn-pt-3">
                    <h6 class="hvn-mb-0 hvn-text-primary"><i class="bi bi-info-circle"></i> Chi tiết Job #<span x-text="selectedLog ? selectedLog.id : '---'"></span></h6>
                </div>
                <div class="hvn-card-body hvn-bg-light hvn-p-3" style="font-size: 0.85rem;" x-show="selectedLog">
                    <template x-if="selectedLog">
                        <div>
                            <div class="hvn-row hvn-border-bottom hvn-pb-2 hvn-mb-2">
                                <div class="hvn-col-4 hvn-text-muted hvn-fw-bold">Domain:</div>
                                <div class="hvn-col-8 font-monospace hvn-text-primary hvn-fw-bold"><a :href="'?module=hvn_dns_manager&action=admin_dns_editor&domain_id=' + selectedLog.domain" x-text="selectedLog.domain"></a></div>
                            </div>
                            <div class="hvn-row hvn-border-bottom hvn-pb-2 hvn-mb-2">
                                <div class="hvn-col-4 hvn-text-muted hvn-fw-bold">Action:</div>
                                <div class="hvn-col-8 font-monospace" x-text="selectedLog.action"></div>
                            </div>
                            <div class="hvn-row hvn-border-bottom hvn-pb-2 hvn-mb-2">
                                <div class="hvn-col-4 hvn-text-muted hvn-fw-bold">Payload:</div>
                                <div class="hvn-col-8 text-wrap text-break font-monospace hvn-bg-white border hvn-p-1 hvn-rounded" x-text="selectedLog.payload"></div>
                            </div>
                            <div class="hvn-row hvn-border-bottom hvn-pb-2 hvn-mb-2">
                                <div class="hvn-col-4 hvn-text-muted hvn-fw-bold">Server:</div>
                                <div class="hvn-col-8" x-text="selectedLog.serverFull"></div>
                            </div>
                            <div class="hvn-row hvn-border-bottom hvn-pb-2 hvn-mb-2" :class="{ 'hvn-bg-danger-subtle': selectedLog.status === 'failed' }">
                                <div class="hvn-col-4 hvn-text-muted hvn-fw-bold">Status:</div>
                                <div class="hvn-col-8 hvn-fw-bold">
                                    <span x-text="selectedLog.status.toUpperCase()"></span>
                                    <span class="hvn-text-muted hvn-fw-normal"> (Attempt <span x-text="selectedLog.attempt"></span>)</span>
                                </div>
                            </div>
                            <template x-if="selectedLog.status === 'failed'">
                                <div class="hvn-row hvn-border-bottom hvn-pb-2 hvn-mb-2 hvn-bg-danger-subtle">
                                    <div class="hvn-col-4 hvn-text-danger hvn-fw-bold">Error:</div>
                                    <div class="hvn-col-8 hvn-text-danger font-monospace text-break" x-text="selectedLog.errorMsg"></div>
                                </div>
                            </template>
                            <template x-if="selectedLog.status === 'failed'">
                                <div class="hvn-row hvn-border-bottom hvn-pb-2 hvn-mb-2">
                                    <div class="hvn-col-4 hvn-text-warning hvn-fw-bold">Next retry:</div>
                                    <div class="hvn-col-8" x-text="selectedLog.nextRetry"></div>
                                </div>
                            </template>
                            <div class="hvn-row hvn-border-bottom hvn-pb-2 hvn-mb-2">
                                <div class="hvn-col-4 hvn-text-muted hvn-fw-bold">Batch:</div>
                                <div class="hvn-col-8 font-monospace hvn-text-muted" x-text="selectedLog.batchId"></div>
                            </div>
                            <div class="hvn-row hvn-border-bottom hvn-pb-2 hvn-mb-2">
                                <div class="hvn-col-4 hvn-text-muted hvn-fw-bold">Actor:</div>
                                <div class="hvn-col-8" x-text="selectedLog.actor"></div>
                            </div>
                            <div class="hvn-row hvn-mb-3">
                                <div class="hvn-col-4 hvn-text-muted hvn-fw-bold">Created:</div>
                                <div class="hvn-col-8" x-text="selectedLog.created"></div>
                            </div>

                            <div class="d-grid gahvn-p-2">
                                <template x-if="selectedLog.status === 'failed' || selectedLog.status === 'pending'">
                                    <button class="hvn-btn hvn-btn-warning btn-sm" @click="retryJob(selectedLog)"><i class="bi bi-arrow-repeat"></i> Thử lại ngay (Retry)</button>
                                </template>
                                <template x-if="selectedLog.status === 'failed' || selectedLog.status === 'pending'">
                                    <button class="hvn-btn btn-outline-danger btn-sm" @click="alert('Đã hủy Job.')"><i class="bi bi-x-circle"></i> Hủy (Cancel Job)</button>
                                </template>
                                <button class="hvn-btn btn-outline-secondary btn-sm" @click="copyDebug(selectedLog)"><i class="bi bi-clipboard"></i> Copy Debug Info</button>
                            </div>
                        </div>
                    </template>
                </div>
                <div class="hvn-card-body hvn-text-center hvn-text-muted" x-show="!selectedLog">
                    <i class="bi bi-hand-index fs-1 hvn-mt-4 hvn-mb-2 hvn-d-block"></i>
                    Ấn vào một bản ghi bên trái để xem chi tiết
                </div>
            </div>
        </div>
    </div>
</div>

<script>
{literal}
document.addEventListener('alpine:init', () => {
    Alpine.data('syncLogsData', () => ({
        logs: [
            {
                id: 4521, time: '14:32', domain: 'myblog.net', action: 'DELETE_RECORD', details: 'A @ 1.2.3.4', 
                server: 'dns3.hvn.vn', status: 'failed', error_brief: 'tmout', ms: null,
                payload: '{ "type":"A","name":"@","value":"1.2.3.4" }',
                serverFull: 'dns3.hvn.vn (103.xx.xx.12:2222)', attempt: '3/5',
                errorMsg: 'Connection timed out after 15000ms', nextRetry: '14:48 (16 phút)',
                batchId: 'abc-123-def (syncing)', actor: 'Client #1236 (Lê C) [118.70.xx.xx]',
                created: '25/02/2026 14:30:15'
            },
            {
                id: 4520, time: '14:31', domain: 'shop.vn', action: 'ADD_RECORD', details: 'A mail', 
                server: 'dns1.hvn.vn', status: 'complete', error_brief: '', ms: 89,
                payload: '{ "type":"A","name":"mail","value":"10.0.0.1" }',
                serverFull: 'dns1.hvn.vn (103.xx.xx.10:2222)', attempt: '1/5',
                errorMsg: '', nextRetry: '',
                batchId: 'xyz-987-abc (complete)', actor: 'Client #1235 (Trần B) [1.1.1.1]',
                created: '25/02/2026 14:31:00'
            },
            {
                id: 4519, time: '14:31', domain: 'shop.vn', action: 'ADD_RECORD', details: 'A mail', 
                server: 'dns2.hvn.vn', status: 'complete', error_brief: '', ms: 92,
                payload: '{ "type":"A","name":"mail","value":"10.0.0.1" }',
                serverFull: 'dns2.hvn.vn (103.xx.xx.11:2222)', attempt: '1/5',
                errorMsg: '', nextRetry: '',
                batchId: 'xyz-987-abc (complete)', actor: 'Client #1235 (Trần B) [1.1.1.1]',
                created: '25/02/2026 14:31:00'
            },
            {
                id: 4518, time: '14:31', domain: 'shop.vn', action: 'ADD_RECORD', details: 'A mail', 
                server: 'dns3.hvn.vn', status: 'failed', error_brief: 'tmout', ms: null,
                payload: '{ "type":"A","name":"mail","value":"10.0.0.1" }',
                serverFull: 'dns3.hvn.vn (103.xx.xx.12:2222)', attempt: '1/5',
                errorMsg: 'Connection timed out after 15000ms', nextRetry: '14:35',
                batchId: 'xyz-987-abc (syncing)', actor: 'Client #1235 (Trần B) [1.1.1.1]',
                created: '25/02/2026 14:31:00'
            }
        ],
        selectedLog: null,

        selectLog(log) {
            this.selectedLog = log;
        },

        retryJob(log) {
            alert(`Đang thử gửi lại Job #${log.id} tới server ${log.server}...`);
            log.status = 'pending';
            log.error_brief = 'retrying';
            setTimeout(() => {
                log.status = 'complete';
                log.error_brief = '';
                log.ms = Math.floor(Math.random() * 100) + 30;
                log.errorMsg = '';
            }, 1000);
        },

        copyDebug(log) {
            const data = JSON.stringify(log, null, 2);
            navigator.clipboard.writeText(data).then(() => {
                alert('Đã copy debug info vào Clipboard.');
            });
        }
    }));
});
{/literal}
</script>
