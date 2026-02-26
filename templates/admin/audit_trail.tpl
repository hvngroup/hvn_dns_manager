<div class="hvn-dns-admin hvn-audit-trail" x-data="auditTrailData()">
    <div class="hvn-d-flex hvn-justify-content-between hvn-align-items-center hvn-mb-4">
        <h2><i class="bi bi-shield-check"></i> Nhật ký Kiểm toán (Audit Trail)</h2>
        <div>
            <button class="hvn-btn btn-outline-success"><i class="bi bi-file-earmark-spreadsheet"></i> Export CSV</button>
            <button class="hvn-btn btn-outline-danger hvn-ms-1"><i class="bi bi-file-pdf"></i> Export PDF</button>
        </div>
    </div>

    <div class="alert alert-info hvn-py-2">
        <i class="bi bi-lock-fill"></i> Log Audit Trail là <strong>append-only</strong> (chỉ thêm, không được phép sửa/xóa) nhằm đảm bảo tính toàn vẹn của dữ liệu theo chuẩn bảo mật.
    </div>

    <!-- Toolbar Filters -->
    <div class="hvn-card hvn-shadow-sm hvn-border-0 hvn-mb-4 hvn-bg-light">
        <div class="hvn-card-body hvn-py-3">
            <div class="hvn-row g-2 hvn-align-items-center hvn-mb-2">
                <div class="hvn-col-md-3">
                    <select class="hvn-form-select">
                        <option value="">Tất cả Actor (Người thực hiện)</option>
                        <option value="client">Khách hàng</option>
                        <option value="admin">Quản trị viên (Admin)</option>
                        <option value="system">Hệ thống (Cron/System)</option>
                        <option value="api">API / DDNS</option>
                    </select>
                </div>
                <div class="hvn-col-md-3">
                    <select class="hvn-form-select">
                        <option value="">Tất cả Action</option>
                        <option value="add_record">Thêm bản ghi</option>
                        <option value="edit_record">Sửa bản ghi</option>
                        <option value="delete_record">Xóa bản ghi</option>
                        <option value="enable_dnssec">Bật DNSSEC</option>
                        <option value="ddns_update">Cập nhật DDNS</option>
                        <option value="rollback">Rollback Zone</option>
                    </select>
                </div>
                <div class="hvn-col-md-3">
                    <input type="text" class="hvn-form-control" placeholder="Tên miền (VD: myblog.net)...">
                </div>
                <div class="hvn-col-md-3">
                    <input type="text" class="hvn-form-control" placeholder="Địa chỉ IP...">
                </div>
            </div>
            <div class="hvn-row g-2 hvn-align-items-center">
                <div class="hvn-col-md-4 hvn-d-flex hvn-align-items-center">
                    <span class="hvn-me-2 hvn-text-muted hvn-fw-bold">Từ:</span> <input type="date" class="hvn-form-control hvn-form-control-sm">
                </div>
                <div class="hvn-col-md-4 hvn-d-flex hvn-align-items-center">
                    <span class="hvn-me-2 hvn-text-muted hvn-fw-bold">Đến:</span> <input type="date" class="hvn-form-control hvn-form-control-sm">
                </div>
                <div class="hvn-col-md-4 hvn-text-end">
                    <button class="hvn-btn hvn-btn-primary"><i class="bi bi-funnel"></i> Lọc dữ liệu</button>
                </div>
            </div>
        </div>
    </div>

    <!-- Main Table -->
    <div class="hvn-card hvn-shadow-sm hvn-border-0">
        <div class="hvn-card-body hvn-p-0">
            <div class="table-responsive">
                <table class="table table-hover align-middle hvn-mb-0 text-sm">
                    <thead class="table-dark">
                        <tr>
                            <th class="hvn-ps-3">Thời gian</th>
                            <th>Ai (Actor)</th>
                            <th>Domain</th>
                            <th>Hành động</th>
                            <th>Chi tiết ngắn gọn</th>
                            <th>IP</th>
                        </tr>
                    </thead>
                    <tbody>
                        <template x-for="log in logs" :key="log.id">
                            <tr @click="openModal(log)" style="cursor: pointer;">
                                <td class="hvn-ps-3 hvn-text-muted font-monospace small" x-text="log.time"></td>
                                <td>
                                    <template x-if="log.actorType === 'client'"><span class="hvn-badge hvn-bg-primary hvn-rounded-pill"><i class="bi bi-person"></i> <span x-text="log.actorName"></span></span></template>
                                    <template x-if="log.actorType === 'admin'"><span class="hvn-badge hvn-bg-danger hvn-rounded-pill"><i class="bi bi-wrench"></i> <span x-text="log.actorName"></span></span></template>
                                    <template x-if="log.actorType === 'system'"><span class="hvn-badge hvn-bg-secondary hvn-rounded-pill"><i class="bi bi-robot"></i> <span x-text="log.actorName"></span></span></template>
                                    <template x-if="log.actorType === 'api'"><span class="hvn-badge hvn-bg-info hvn-text-dark hvn-rounded-pill"><i class="bi bi-plug"></i> <span x-text="log.actorName"></span></span></template>
                                </td>
                                <td><a :href="'?module=hvn_dns_manager&action=admin_dns_editor&domain_id=' + log.domain" class="font-monospace text-decoration-none hvn-fw-bold" x-text="log.domain" @click.stop></a></td>
                                <td>
                                    <span class="hvn-fw-bold font-monospace hvn-bg-light hvn-p-1 hvn-rounded border" x-text="log.action"></span>
                                </td>
                                <td class="small" x-text="log.details_brief"></td>
                                <td class="font-monospace hvn-text-muted small" x-text="log.ip"></td>
                            </tr>
                        </template>
                    </tbody>
                </table>
            </div>
        </div>
        
        <div class="hvn-card-footer hvn-bg-white hvn-py-3 hvn-d-flex hvn-justify-content-between hvn-align-items-center">
            <div class="hvn-text-muted small">
                Hiển thị 10 / 5,234 log
            </div>
            <nav aria-label="Page navigation">
                <ul class="pagination pagination-sm hvn-mb-0">
                    <li class="page-item disabled"><a class="page-link" href="#">&laquo;</a></li>
                    <li class="page-item active"><a class="page-link" href="#">1</a></li>
                    <li class="page-item"><a class="page-link" href="#">2</a></li>
                    <li class="page-item"><a class="page-link" href="#">3</a></li>
                    <li class="page-item"><a class="page-link" href="#">&raquo;</a></li>
                </ul>
            </nav>
        </div>
    </div>

    <!-- Custom Alpine Backdrop -->
    <div x-show="isOpen" x-transition.opacity 
         style="position: fixed; top: 0; left: 0; width: 100vw; height: 100vh; background-color: rgba(0,0,0,0.5); z-index: 1040; display: none;"></div>

    <!-- Audit Detail Modal -->
    <div class="modal fade" :class="{ 'show': isOpen }" :style="isOpen ? 'display: block; z-index: 1045;' : 'display: none;'" 
         tabindex="-1" aria-hidden="true" @click.self="closeModal()" x-show="isOpen" x-transition.opacity>
        <div class="modal-dialog modal-lg">
            <div class="modal-content" x-show="selectedLog">
                <template x-if="selectedLog">
                    <div>
                        <div class="modal-header hvn-bg-dark hvn-text-white">
                            <h5 class="modal-title"><i class="bi bi-shield-lock"></i> Audit Entry #<span x-text="selectedLog.id"></span></h5>
                            <button type="button" class="btn-close btn-close-white" @click="closeModal()" aria-label="Close"></button>
                        </div>
                        <div class="modal-body font-monospace hvn-p-4 hvn-bg-light" style="font-size: 0.9rem;">
                            
                            <table class="table table-sm table-borderless">
                                <tbody>
                                    <tr>
                                        <td class="hvn-text-muted" width="150">Actor:</td>
                                        <td class="hvn-fw-bold fs-5 hvn-text-primary" x-text="selectedLog.actorFull"></td>
                                    </tr>
                                    <tr>
                                        <td class="hvn-text-muted">Context:</td>
                                        <td x-text="selectedLog.context"></td>
                                    </tr>
                                    <tr>
                                        <td class="hvn-text-muted">Domain:</td>
                                        <td class="hvn-fw-bold" x-text="selectedLog.domain"></td>
                                    </tr>
                                    <tr>
                                        <td class="hvn-text-muted">Action:</td>
                                        <td class="hvn-fw-bold hvn-bg-warning-subtle d-inline-block hvn-px-2 hvn-rounded hvn-text-dark" x-text="selectedLog.action"></td>
                                    </tr>
                                    <tr>
                                        <td class="hvn-text-muted hvn-pt-3">Target:</td>
                                        <td class="hvn-pt-3" x-text="selectedLog.target"></td>
                                    </tr>
                                </tbody>
                            </table>

                            <div class="hvn-card hvn-border-0 hvn-shadow-sm my-3">
                                <div class="hvn-card-header hvn-bg-white"><strong>Payload Dữ liệu</strong></div>
                                <div class="hvn-card-body hvn-p-0">
                                    <table class="table table-bordered hvn-mb-0">
                                        <thead class="table-light">
                                            <tr>
                                                <th width="50%" class="hvn-text-danger">Giá trị cũ (Old Data)</th>
                                                <th width="50%" class="hvn-text-success">Giá trị mới (New Data)</th>
                                            </tr>
                                        </thead>
                                        <tbody>
                                            <tr>
                                                <td class="hvn-p-3 text-break hvn-bg-danger-subtle bg-opacity-10 hvn-text-danger" style="white-space: pre-wrap;" x-text="selectedLog.oldVal"></td>
                                                <td class="hvn-p-3 text-break hvn-bg-success-subtle bg-opacity-10 hvn-text-success hvn-fw-bold" style="white-space: pre-wrap;" x-text="selectedLog.newVal"></td>
                                            </tr>
                                        </tbody>
                                    </table>
                                </div>
                            </div>

                            <table class="table table-sm table-borderless hvn-mt-3 hvn-text-muted">
                                <tbody>
                                    <tr>
                                        <td width="150">IP Address:</td>
                                        <td x-text="selectedLog.ip"></td>
                                    </tr>
                                    <tr>
                                        <td>User Agent:</td>
                                        <td class="text-break" x-text="selectedLog.ua"></td>
                                    </tr>
                                    <tr>
                                        <td>Session / Token:</td>
                                        <td x-text="selectedLog.session"></td>
                                    </tr>
                                    <tr>
                                        <td>Ghi chú (Notes):</td>
                                        <td class="fst-italic hvn-text-dark" x-text="selectedLog.notes"></td>
                                    </tr>
                                    <tr>
                                        <td>Timestamp:</td>
                                        <td class="hvn-fw-bold hvn-text-dark" x-text="selectedLog.timeLong"></td>
                                    </tr>
                                </tbody>
                            </table>

                        </div>
                        <div class="modal-footer">
                            <button type="button" class="hvn-btn btn-secondary" @click="closeModal()">Đóng</button>
                        </div>
                    </div>
                </template>
            </div>
        </div>
    </div>
</div>

<script>
{literal}
document.addEventListener('alpine:init', () => {
    Alpine.data('auditTrailData', () => ({
        isOpen: false,
        logs: [
            {
                id: 89201, time: '25/02, 14:32', actorType: 'client', actorName: 'Lê C', domain: 'myblog.net', 
                action: 'delete_record', details_brief: 'A @ → 1.2.3.4', ip: '118.70.xx.xx',
                actorFull: 'Lê C - Client #1236', context: 'client_area', target: 'Record #457 (A @)',
                oldVal: '{\n  "name": "@",\n  "type": "A",\n  "value": "1.2.3.4",\n  "ttl": 3600\n}', newVal: 'null',
                ua: 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/120.0', session: 'whmcs_sess_xyz987',
                notes: 'User initiated delete from Client Area.', timeLong: '25/02/2026 14:32:05'
            },
            {
                id: 89200, time: '25/02, 14:30', actorType: 'admin', actorName: 'Vuong', domain: 'example.com', 
                action: 'edit_record', details_brief: 'A mail: .3 → .4 | Overridden', ip: '10.0.0.1',
                actorFull: 'Vuong Nguyen - Admin #2', context: 'admin_editor', target: 'Record #456 (A mail)',
                oldVal: '{\n  "value": "103.45.67.90",\n  "ttl": 3600\n}', newVal: '{\n  "value": "103.45.67.91",\n  "ttl": 3600\n}',
                ua: 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)', session: 'whmcs_sess_abc123',
                notes: 'Overridden by Admin — cancelled client job', timeLong: '25/02/2026 14:30:22'
            },
            {
                id: 89199, time: '25/02, 14:28', actorType: 'system', actorName: 'Cron', domain: 'test.org', 
                action: 'enable_dnssec', details_brief: 'DNSSEC on', ip: 'WHMCS Server',
                actorFull: 'System Automation', context: 'cron_hook', target: 'Domain test.org Setting',
                oldVal: '{ "dnssec_enabled": false}', newVal: '{ "dnssec_enabled": true}',
                ua: 'WHMCS/8.8.0 CLI', session: 'cron',
                notes: 'Auto enabled via hook AddonActivation', timeLong: '25/02/2026 14:28:00'
            },
            {
                id: 89198, time: '25/02, 14:25', actorType: 'api', actorName: 'DDNS', domain: 'cam.shop.vn', 
                action: 'ddns_update', details_brief: 'IP: .5 → .6', ip: '118.70.5.6',
                actorFull: 'API Token Auth', context: 'api_endpoint', target: 'Record #992 (A cam)',
                oldVal: '{\n  "value": "118.70.5.5"\n}', newVal: '{\n  "value": "118.70.5.6"\n}',
                ua: 'Mikrotik/6.49.10 Fetch', session: 'token_a1b2c3d...',
                notes: 'DDNS IP automatically updated by router.', timeLong: '25/02/2026 14:25:32'
            }
        ],
        selectedLog: null,

        openModal(log) {
            this.selectedLog = log;
            this.isOpen = true;
        },

        closeModal() {
            this.isOpen = false;
        }
    }));
});
{/literal}
</script>
