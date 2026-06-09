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
                    <select class="hvn-form-select" x-model="filterActor">
                        <option value="">Tất cả Actor (Người thực hiện)</option>
                        <option value="client">Khách hàng</option>
                        <option value="admin">Quản trị viên (Admin)</option>
                        <option value="system">Hệ thống (Cron/System)</option>
                        <option value="api">API / DDNS</option>
                    </select>
                </div>
                <div class="hvn-col-md-3">
                    <select class="hvn-form-select" x-model="filterAction">
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
                    <input type="text" class="hvn-form-control" placeholder="Tên miền (VD: myblog.net)..." x-model="filterDomain">
                </div>
                <div class="hvn-col-md-3">
                    <input type="text" class="hvn-form-control" placeholder="Địa chỉ IP..." x-model="filterIp">
                </div>
            </div>
            <div class="hvn-row g-2 hvn-align-items-center">
                <div class="hvn-col-md-4 hvn-d-flex hvn-align-items-center">
                    <span class="hvn-me-2 hvn-text-muted hvn-fw-bold">Từ:</span> <input type="date" class="hvn-form-control hvn-form-control-sm" x-model="filterDateFrom">
                </div>
                <div class="hvn-col-md-4 hvn-d-flex hvn-align-items-center">
                    <span class="hvn-me-2 hvn-text-muted hvn-fw-bold">Đến:</span> <input type="date" class="hvn-form-control hvn-form-control-sm" x-model="filterDateTo">
                </div>
                <div class="hvn-col-md-4 hvn-d-flex hvn-align-items-center hvn-justify-content-end" style="gap:6px;">
                    <label class="hvn-text-muted small" style="white-space:nowrap;">Hiển:</label>
                    <select class="hvn-form-select" style="width:100px;" x-model.number="perPage" @change="currentPage=1">
                        <option value="50">50</option>
                        <option value="100">100</option>
                        <option value="200">200</option>
                        <option value="500">500</option>
                        <option value="0">Tất cả</option>
                    </select>
                    <button class="hvn-btn hvn-btn-primary" @click="currentPage=1"><i class="bi bi-funnel"></i> Lọc</button>
                    <button class="hvn-btn hvn-btn-outline-secondary" @click="filterActor='';filterAction='';filterDomain='';filterIp='';filterDateFrom='';filterDateTo='';currentPage=1;"><i class="bi bi-arrow-counterclockwise"></i></button>
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
                        <template x-for="log in pagedLogs" :key="log.id">
                            <tr @click="window.location.href='{$modulelink}&action=audit_detail&id=' + log.id" style="cursor: pointer;">
                                <td class="hvn-ps-3 hvn-text-muted font-monospace small" x-text="log.time"></td>
                                <td>
                                    <template x-if="log.actorType === 'client'"><span class="hvn-badge hvn-bg-primary hvn-rounded-pill"><i class="bi bi-person"></i> <span x-text="log.actorName"></span></span></template>
                                    <template x-if="log.actorType === 'admin'"><span class="hvn-badge hvn-bg-danger hvn-rounded-pill"><i class="bi bi-wrench"></i> <span x-text="log.actorName"></span></span></template>
                                    <template x-if="log.actorType === 'system'"><span class="hvn-badge hvn-bg-secondary hvn-rounded-pill"><i class="bi bi-robot"></i> <span x-text="log.actorName"></span></span></template>
                                    <template x-if="log.actorType === 'api'"><span class="hvn-badge hvn-bg-info hvn-text-dark hvn-rounded-pill"><i class="bi bi-plug"></i> <span x-text="log.actorName"></span></span></template>
                                </td>
                                <td><a :href="'?module=hvn_dns_manager&action=admin_dns_editor&domain_id=' + log.domain_id" class="font-monospace text-decoration-none hvn-fw-bold" x-text="log.domain" @click.stop></a></td>
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
                Hiển <span x-text="pagedLogs.length"></span> / <span x-text="filteredLogs.length"></span> log
            </div>
            <nav aria-label="Page navigation">
                <ul class="pagination pagination-sm hvn-mb-0">
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
    var HVNDNS_AUDIT_LOGS = {$auditLogsJson};
</script>
<script>
{literal}
document.addEventListener('alpine:init', () => {
    Alpine.data('auditTrailData', () => ({
        filterActor: '', filterAction: '', filterDomain: '', filterIp: '',
        filterDateFrom: '', filterDateTo: '',
        perPage: 50,
        currentPage: 1,

        allLogs: HVNDNS_AUDIT_LOGS,

        get filteredLogs() {
            return this.allLogs.filter(l => {
                if (this.filterActor  && l.actorType !== this.filterActor)         return false;
                if (this.filterAction && l.action    !== this.filterAction)        return false;
                if (this.filterDomain && !l.domain.includes(this.filterDomain))   return false;
                if (this.filterIp     && !l.ip.includes(this.filterIp))           return false;

                // Filter theo ngày — log.time format: "dd/mm, HH:ii"
                // Parse sang "YYYY-MM-DD" để so sánh với filterDateFrom/filterDateTo
                if (this.filterDateFrom || this.filterDateTo) {
                    // log.time dạng "01/04, 04:30" → tách lấy "01/04"
                    var parts = l.time ? l.time.split(', ') : [];
                    var logDate = null;
                    if (parts.length >= 1) {
                        var dmParts = parts[0].split('/');
                        if (dmParts.length === 2) {
                            var year = new Date().getFullYear();
                            // Format YYYY-MM-DD để so sánh string
                            logDate = year + '-' + dmParts[1].padStart(2,'0') + '-' + dmParts[0].padStart(2,'0');
                        }
                    }
                    if (!logDate) return false;
                    if (this.filterDateFrom && logDate < this.filterDateFrom) return false;
                    if (this.filterDateTo   && logDate > this.filterDateTo)   return false;
                }

                return true;
            });
        },

        get pagedLogs() {
            if (!this.perPage) return this.filteredLogs;
            const start = (this.currentPage - 1) * this.perPage;
            return this.filteredLogs.slice(start, start + this.perPage);
        },

        get totalPages() {
            if (!this.perPage) return 1;
            return Math.max(1, Math.ceil(this.filteredLogs.length / this.perPage));
        },
    }));
});
{/literal}
</script>
