<div class="mj-dns-admin mj-audit-trail" x-data="auditTrailData()">
    <div class="mj-d-flex mj-justify-content-between mj-align-items-center mj-mb-4">
        <h2><i class="bi bi-shield-check"></i> Nhật ký Kiểm toán (Audit Trail)</h2>
        <div>
            <button class="mj-btn btn-outline-success"><i class="bi bi-file-earmark-spreadsheet"></i> Export CSV</button>
            <button class="mj-btn btn-outline-danger mj-ms-1"><i class="bi bi-file-pdf"></i> Export PDF</button>
        </div>
    </div>

    <div class="alert alert-info mj-py-2">
        <i class="bi bi-lock-fill"></i> Log Audit Trail là <strong>append-only</strong> (chỉ thêm, không được phép sửa/xóa) nhằm đảm bảo tính toàn vẹn của dữ liệu theo chuẩn bảo mật.
    </div>

    <!-- Toolbar Filters -->
    <div class="mj-card mj-shadow-sm mj-border-0 mj-mb-4 mj-bg-light">
        <div class="mj-card-body mj-py-3">
            <div class="mj-row g-2 mj-align-items-center mj-mb-2">
                <div class="mj-col-md-3">
                    <select class="mj-form-select" x-model="filterActor">
                        <option value="">Tất cả Actor (Người thực hiện)</option>
                        <option value="client">Khách hàng</option>
                        <option value="admin">Quản trị viên (Admin)</option>
                        <option value="system">Hệ thống (Cron/System)</option>
                        <option value="api">API / DDNS</option>
                    </select>
                </div>
                <div class="mj-col-md-3">
                    <select class="mj-form-select" x-model="filterAction">
                        <option value="">Tất cả Action</option>
                        <option value="add_record">Thêm bản ghi</option>
                        <option value="edit_record">Sửa bản ghi</option>
                        <option value="delete_record">Xóa bản ghi</option>
                        <option value="enable_dnssec">Bật DNSSEC</option>
                        <option value="ddns_update">Cập nhật DDNS</option>
                        <option value="rollback">Rollback Zone</option>
                    </select>
                </div>
                <div class="mj-col-md-3">
                    <input type="text" class="mj-form-control" placeholder="Tên miền (VD: myblog.net)..." x-model="filterDomain">
                </div>
                <div class="mj-col-md-3">
                    <input type="text" class="mj-form-control" placeholder="Địa chỉ IP..." x-model="filterIp">
                </div>
            </div>
            <div class="mj-row g-2 mj-align-items-center">
                <div class="mj-col-md-4 mj-d-flex mj-align-items-center">
                    <span class="mj-me-2 mj-text-muted mj-fw-bold">Từ:</span> <input type="date" class="mj-form-control mj-form-control-sm" x-model="filterDateFrom">
                </div>
                <div class="mj-col-md-4 mj-d-flex mj-align-items-center">
                    <span class="mj-me-2 mj-text-muted mj-fw-bold">Đến:</span> <input type="date" class="mj-form-control mj-form-control-sm" x-model="filterDateTo">
                </div>
                <div class="mj-col-md-4 mj-d-flex mj-align-items-center mj-justify-content-end" style="gap:6px;">
                    <label class="mj-text-muted small" style="white-space:nowrap;">Hiển:</label>
                    <select class="mj-form-select" style="width:100px;" x-model.number="perPage" @change="currentPage=1">
                        <option value="50">50</option>
                        <option value="100">100</option>
                        <option value="200">200</option>
                        <option value="500">500</option>
                        <option value="0">Tất cả</option>
                    </select>
                    <button class="mj-btn mj-btn-primary" @click="currentPage=1"><i class="bi bi-funnel"></i> Lọc</button>
                    <button class="mj-btn mj-btn-outline-secondary" @click="filterActor='';filterAction='';filterDomain='';filterIp='';filterDateFrom='';filterDateTo='';currentPage=1;"><i class="bi bi-arrow-counterclockwise"></i></button>
                </div>
            </div>
        </div>
    </div>

    <!-- Main Table -->
    <div class="mj-card mj-shadow-sm mj-border-0">
        <div class="mj-card-body mj-p-0">
            <div class="table-responsive">
                <table class="table table-hover align-middle mj-mb-0 text-sm">
                    <thead class="table-dark">
                        <tr>
                            <th class="mj-ps-3">Thời gian</th>
                            <th>Ai (Actor)</th>
                            <th>Domain</th>
                            <th>Hành động</th>
                            <th>Chi tiết ngắn gọn</th>
                            <th>IP</th>
                        </tr>
                    </thead>
                    <tbody>
                        <template x-for="log in pagedLogs" :key="log.id">
                            <tr @click="window.location.href='{$modulelink}&action=audit_detail&id=' + log.id" style="cursor: pointer;">
                                <td class="mj-ps-3 mj-text-muted font-monospace small" x-text="log.time"></td>
                                <td>
                                    <template x-if="log.actorType === 'client'"><span class="mj-badge mj-bg-primary mj-rounded-pill"><i class="bi bi-person"></i> <span x-text="log.actorName"></span></span></template>
                                    <template x-if="log.actorType === 'admin'"><span class="mj-badge mj-bg-danger mj-rounded-pill"><i class="bi bi-wrench"></i> <span x-text="log.actorName"></span></span></template>
                                    <template x-if="log.actorType === 'system'"><span class="mj-badge mj-bg-secondary mj-rounded-pill"><i class="bi bi-robot"></i> <span x-text="log.actorName"></span></span></template>
                                    <template x-if="log.actorType === 'api'"><span class="mj-badge mj-bg-info mj-text-dark mj-rounded-pill"><i class="bi bi-plug"></i> <span x-text="log.actorName"></span></span></template>
                                </td>
                                <td><a :href="'?module=mj_dns_manager&action=admin_dns_editor&domain_id=' + log.domain_id" class="font-monospace text-decoration-none mj-fw-bold" x-text="log.domain" @click.stop></a></td>
                                <td>
                                    <span class="mj-fw-bold font-monospace mj-bg-light mj-p-1 mj-rounded border" x-text="log.action"></span>
                                </td>
                                <td class="small" x-text="log.details_brief"></td>
                                <td class="font-monospace mj-text-muted small" x-text="log.ip"></td>
                            </tr>
                        </template>
                    </tbody>
                </table>
            </div>
        </div>
        
        <div class="mj-card-footer mj-bg-white mj-py-3 mj-d-flex mj-justify-content-between mj-align-items-center">
            <div class="mj-text-muted small">
                Hiển <span x-text="pagedLogs.length"></span> / <span x-text="filteredLogs.length"></span> log
            </div>
            <nav aria-label="Page navigation">
                <ul class="pagination pagination-sm mj-mb-0">
                    <li class="page-item" :class="currentPage===1?'disabled':''">
                        <a class="page-link" href="#" @click.prevent="currentPage>1&&currentPage--">&laquo;</a>
                    </li>
                    <template x-for="p in totalPages" :key="p">
                        <li class="page-item" :class="p===currentPage?'active':''">
                            <a class="page-link" href="#" @click.prevent="currentPage=p" x-text="p"></a>
                        </li>
                    </template>
                    <li class="page-item" :class="currentPage===totalPages?'disabled':''">
                        <a class="page-link" href="#" @click.prevent="currentPage<totalPages&&currentPage++">&raquo;</a>
                    </li>
                </ul>
            </nav>
        </div>
    </div>


</div>

<script>
    var MJDNS_AUDIT_LOGS = {$auditLogsJson};
</script>
{* JS logic moved to assets/js/mj-dns.js (MJ standard §8) *}
