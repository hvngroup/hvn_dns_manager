<div class="hvn-dns-admin hvn-audit-trail" x-data="auditTrailData()">
    <div class="d-flex justify-content-between align-items-center mb-4">
        <h2><i class="bi bi-shield-check"></i> Nhật ký Kiểm toán (Audit Trail)</h2>
        <div>
            <button class="btn btn-outline-success"><i class="bi bi-file-earmark-spreadsheet"></i> Export CSV</button>
            <button class="btn btn-outline-danger ms-1"><i class="bi bi-file-pdf"></i> Export PDF</button>
        </div>
    </div>

    <div class="alert alert-info py-2">
        <i class="bi bi-lock-fill"></i> Log Audit Trail là <strong>append-only</strong> (chỉ thêm, không được phép sửa/xóa) nhằm đảm bảo tính toàn vẹn của dữ liệu theo chuẩn bảo mật.
    </div>

    <!-- Toolbar Filters -->
    <div class="card shadow-sm border-0 mb-4 bg-light">
        <div class="card-body py-3">
            <div class="row g-2 align-items-center mb-2">
                <div class="col-md-3">
                    <select class="form-select">
                        <option value="">Tất cả Actor (Người thực hiện)</option>
                        <option value="client">Khách hàng</option>
                        <option value="admin">Quản trị viên (Admin)</option>
                        <option value="system">Hệ thống (Cron/System)</option>
                        <option value="api">API / DDNS</option>
                    </select>
                </div>
                <div class="col-md-3">
                    <select class="form-select">
                        <option value="">Tất cả Action</option>
                        <option value="add_record">Thêm bản ghi</option>
                        <option value="edit_record">Sửa bản ghi</option>
                        <option value="delete_record">Xóa bản ghi</option>
                        <option value="enable_dnssec">Bật DNSSEC</option>
                        <option value="ddns_update">Cập nhật DDNS</option>
                        <option value="rollback">Rollback Zone</option>
                    </select>
                </div>
                <div class="col-md-3">
                    <input type="text" class="form-control" placeholder="Tên miền (VD: myblog.net)...">
                </div>
                <div class="col-md-3">
                    <input type="text" class="form-control" placeholder="Địa chỉ IP...">
                </div>
            </div>
            <div class="row g-2 align-items-center">
                <div class="col-md-4 d-flex align-items-center">
                    <span class="me-2 text-muted fw-bold">Từ:</span> <input type="date" class="form-control form-control-sm">
                </div>
                <div class="col-md-4 d-flex align-items-center">
                    <span class="me-2 text-muted fw-bold">Đến:</span> <input type="date" class="form-control form-control-sm">
                </div>
                <div class="col-md-4 text-end">
                    <button class="btn btn-primary"><i class="bi bi-funnel"></i> Lọc dữ liệu</button>
                </div>
            </div>
        </div>
    </div>

    <!-- Main Table -->
    <div class="card shadow-sm border-0">
        <div class="card-body p-0">
            <div class="table-responsive">
                <table class="table table-hover align-middle mb-0 text-sm">
                    <thead class="table-dark">
                        <tr>
                            <th class="ps-3">Thời gian</th>
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
                                <td class="ps-3 text-muted font-monospace small" x-text="log.time"></td>
                                <td>
                                    <template x-if="log.actorType === 'client'"><span class="badge bg-primary rounded-pill"><i class="bi bi-person"></i> <span x-text="log.actorName"></span></span></template>
                                    <template x-if="log.actorType === 'admin'"><span class="badge bg-danger rounded-pill"><i class="bi bi-wrench"></i> <span x-text="log.actorName"></span></span></template>
                                    <template x-if="log.actorType === 'system'"><span class="badge bg-secondary rounded-pill"><i class="bi bi-robot"></i> <span x-text="log.actorName"></span></span></template>
                                    <template x-if="log.actorType === 'api'"><span class="badge bg-info text-dark rounded-pill"><i class="bi bi-plug"></i> <span x-text="log.actorName"></span></span></template>
                                </td>
                                <td><a :href="'?module=hvn_dns_manager&action=admin_dns_editor&domain_id=' + log.domain" class="font-monospace text-decoration-none fw-bold" x-text="log.domain" @click.stop></a></td>
                                <td>
                                    <span class="fw-bold font-monospace bg-light p-1 rounded border" x-text="log.action"></span>
                                </td>
                                <td class="small" x-text="log.details_brief"></td>
                                <td class="font-monospace text-muted small" x-text="log.ip"></td>
                            </tr>
                        </template>
                    </tbody>
                </table>
            </div>
        </div>
        
        <div class="card-footer bg-white py-3 d-flex justify-content-between align-items-center">
            <div class="text-muted small">
                Hiển thị 10 / 5,234 log
            </div>
            <nav aria-label="Page navigation">
                <ul class="pagination pagination-sm mb-0">
                    <li class="page-item disabled"><a class="page-link" href="#">&laquo;</a></li>
                    <li class="page-item active"><a class="page-link" href="#">1</a></li>
                    <li class="page-item"><a class="page-link" href="#">2</a></li>
                    <li class="page-item"><a class="page-link" href="#">3</a></li>
                    <li class="page-item"><a class="page-link" href="#">&raquo;</a></li>
                </ul>
            </nav>
        </div>
    </div>

    <!-- Audit Detail Modal -->
    <div class="modal fade" id="auditModal" tabindex="-1" aria-hidden="true">
        <div class="modal-dialog modal-lg">
            <div class="modal-content" x-show="selectedLog">
                <template x-if="selectedLog">
                    <div>
                        <div class="modal-header bg-dark text-white">
                            <h5 class="modal-title"><i class="bi bi-shield-lock"></i> Audit Entry #<span x-text="selectedLog.id"></span></h5>
                            <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal" aria-label="Close"></button>
                        </div>
                        <div class="modal-body font-monospace p-4 bg-light" style="font-size: 0.9rem;">
                            
                            <table class="table table-sm table-borderless">
                                <tbody>
                                    <tr>
                                        <td class="text-muted" width="150">Actor:</td>
                                        <td class="fw-bold fs-5 text-primary" x-text="selectedLog.actorFull"></td>
                                    </tr>
                                    <tr>
                                        <td class="text-muted">Context:</td>
                                        <td x-text="selectedLog.context"></td>
                                    </tr>
                                    <tr>
                                        <td class="text-muted">Domain:</td>
                                        <td class="fw-bold" x-text="selectedLog.domain"></td>
                                    </tr>
                                    <tr>
                                        <td class="text-muted">Action:</td>
                                        <td class="fw-bold bg-warning-subtle d-inline-block px-2 rounded text-dark" x-text="selectedLog.action"></td>
                                    </tr>
                                    <tr>
                                        <td class="text-muted pt-3">Target:</td>
                                        <td class="pt-3" x-text="selectedLog.target"></td>
                                    </tr>
                                </tbody>
                            </table>

                            <div class="card border-0 shadow-sm my-3">
                                <div class="card-header bg-white"><strong>Payload Dữ liệu</strong></div>
                                <div class="card-body p-0">
                                    <table class="table table-bordered mb-0">
                                        <thead class="table-light">
                                            <tr>
                                                <th width="50%" class="text-danger">Giá trị cũ (Old Data)</th>
                                                <th width="50%" class="text-success">Giá trị mới (New Data)</th>
                                            </tr>
                                        </thead>
                                        <tbody>
                                            <tr>
                                                <td class="p-3 text-break bg-danger-subtle bg-opacity-10 text-danger" style="white-space: pre-wrap;" x-text="selectedLog.oldVal"></td>
                                                <td class="p-3 text-break bg-success-subtle bg-opacity-10 text-success fw-bold" style="white-space: pre-wrap;" x-text="selectedLog.newVal"></td>
                                            </tr>
                                        </tbody>
                                    </table>
                                </div>
                            </div>

                            <table class="table table-sm table-borderless mt-3 text-muted">
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
                                        <td class="fst-italic text-dark" x-text="selectedLog.notes"></td>
                                    </tr>
                                    <tr>
                                        <td>Timestamp:</td>
                                        <td class="fw-bold text-dark" x-text="selectedLog.timeLong"></td>
                                    </tr>
                                </tbody>
                            </table>

                        </div>
                        <div class="modal-footer">
                            <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Đóng</button>
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
            new bootstrap.Modal(document.getElementById('auditModal')).show();
        }
    }));
});
{/literal}
</script>
