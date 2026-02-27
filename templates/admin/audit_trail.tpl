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
                    <span class="hvn-me-2 hvn-text-muted hvn-fw-bold">Từ:</span> <input type="date" class="hvn-form-control hvn-form-control-sm">
                </div>
                <div class="hvn-col-md-4 hvn-d-flex hvn-align-items-center">
                    <span class="hvn-me-2 hvn-text-muted hvn-fw-bold">Đến:</span> <input type="date" class="hvn-form-control hvn-form-control-sm">
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
                    <button class="hvn-btn hvn-btn-outline-secondary" @click="filterActor='';filterAction='';filterDomain='';filterIp='';currentPage=1;"><i class="bi bi-arrow-counterclockwise"></i></button>
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
{literal}
document.addEventListener('alpine:init', () => {
    Alpine.data('auditTrailData', () => ({
        filterActor: '', filterAction: '', filterDomain: '', filterIp: '',
        perPage: 50,
        currentPage: 1,

        allLogs: [
            {id:89201,time:'27/02, 14:32',actorType:'client', actorName:'Lê Công',  domain:'myblog.net',      action:'delete_record', details_brief:'A @ → 1.2.3.4 [xóa]',      ip:'118.70.1.10'},
            {id:89200,time:'27/02, 14:30',actorType:'admin',  actorName:'Vuong',    domain:'example.com',     action:'edit_record',   details_brief:'A mail: .90 → .91',       ip:'10.0.0.1'},
            {id:89199,time:'27/02, 14:28',actorType:'system', actorName:'Cron',     domain:'test.org',        action:'enable_dnssec', details_brief:'DNSSEC on',               ip:'WHMCS Server'},
            {id:89198,time:'27/02, 14:25',actorType:'api',    actorName:'DDNS',     domain:'cam.shop.vn',     action:'ddns_update',   details_brief:'IP: .5 → .6',             ip:'118.70.5.6'},
            {id:89197,time:'27/02, 14:22',actorType:'client', actorName:'Hà Minh', domain:'techstore.io',    action:'add_record',    details_brief:'MX 10 mail.ts.io.',       ip:'203.0.113.5'},
            {id:89196,time:'27/02, 14:20',actorType:'admin',  actorName:'Vuong',    domain:'shop.vn',         action:'edit_record',   details_brief:'A @ 103.1 → 103.2',       ip:'10.0.0.1'},
            {id:89195,time:'27/02, 14:18',actorType:'client', actorName:'Trần T',  domain:'startup.dev',     action:'add_record',    details_brief:'TXT v=spf1 …',            ip:'118.70.2.20'},
            {id:89194,time:'27/02, 14:15',actorType:'system', actorName:'Hook',     domain:'myfashion.vn',    action:'add_record',    details_brief:'A @ auto-provision',      ip:'WHMCS Server'},
            {id:89193,time:'27/02, 14:12',actorType:'client', actorName:'Nguyễn A',domain:'saas-platform.io',action:'delete_record', details_brief:'CNAME staging → [xóa]',   ip:'203.0.113.15'},
            {id:89192,time:'27/02, 14:10',actorType:'api',    actorName:'DDNS',     domain:'home.mylab.net',  action:'ddns_update',   details_brief:'IP: .100 → .101',         ip:'27.72.1.101'},
            {id:89191,time:'27/02, 14:08',actorType:'admin',  actorName:'Linh',     domain:'fintech-app.io',  action:'rollback',      details_brief:'Rollback v3 → v2',        ip:'10.0.0.2'},
            {id:89190,time:'27/02, 14:05',actorType:'client', actorName:'Phạm V',  domain:'cloudhosting.net',action:'add_record',    details_brief:'AAAA @ 2001:db8::1',      ip:'203.0.113.25'},
            {id:89189,time:'27/02, 14:02',actorType:'system', actorName:'Cron',     domain:'shop.vn',         action:'edit_record',   details_brief:'SOA serial bump',          ip:'WHMCS Server'},
            {id:89188,time:'27/02, 14:00',actorType:'client', actorName:'Đỗ Hùng', domain:'travel-vn.vn',    action:'add_record',    details_brief:'MX @ smtp.tv.vn.',         ip:'118.70.3.30'},
            {id:89187,time:'27/02, 13:58',actorType:'api',    actorName:'DDNS',     domain:'office.acme.vn',  action:'ddns_update',   details_brief:'IP: .50 → .51',           ip:'14.160.1.51'},
            {id:89186,time:'27/02, 13:55',actorType:'admin',  actorName:'Vuong',    domain:'example.com',     action:'delete_record', details_brief:'TXT _dmarc [xóa]',        ip:'10.0.0.1'},
            {id:89185,time:'27/02, 13:52',actorType:'client', actorName:'Lê Công', domain:'newproject.xyz',  action:'add_record',    details_brief:'A @ 203.0.113.5',          ip:'118.70.1.10'},
            {id:89184,time:'27/02, 13:50',actorType:'client', actorName:'Hà Minh', domain:'elearning.edu.vn',action:'edit_record',   details_brief:'CNAME www: old → new',    ip:'203.0.113.5'},
            {id:89183,time:'27/02, 13:48',actorType:'system', actorName:'Hook',     domain:'digitalagency.com',action:'add_record',   details_brief:'NS ns1.hvn.vn. [auto]',   ip:'WHMCS Server'},
            {id:89182,time:'27/02, 13:45',actorType:'client', actorName:'Trần T',  domain:'media-hub.net',   action:'add_record',    details_brief:'TXT dkim2048 …',           ip:'118.70.2.20'},
            {id:89181,time:'27/02, 13:43',actorType:'api',    actorName:'DDNS',     domain:'router.home.vn',  action:'ddns_update',   details_brief:'IP: .200 → .201',         ip:'113.190.1.201'},
            {id:89180,time:'27/02, 13:41',actorType:'admin',  actorName:'Linh',     domain:'realty.com.vn',   action:'add_record',    details_brief:'CAA 0 issue le.org',      ip:'10.0.0.2'},
            {id:89179,time:'27/02, 13:38',actorType:'client', actorName:'Nguyễn A',domain:'game-portal.net', action:'delete_record', details_brief:'A beta → [xóa]',          ip:'203.0.113.15'},
            {id:89178,time:'27/02, 13:35',actorType:'system', actorName:'Cron',     domain:'healthclinic.vn', action:'add_record',    details_brief:'MX 10 mail.hc.vn.',       ip:'WHMCS Server'},
            {id:89177,time:'27/02, 13:32',actorType:'client', actorName:'Phạm V',  domain:'autoparts.shop',  action:'edit_record',   details_brief:'TXT spf: v1 → v2',        ip:'203.0.113.25'},
            {id:89176,time:'27/02, 13:30',actorType:'api',    actorName:'DDNS',     domain:'cam2.security.vn',action:'ddns_update',   details_brief:'IP: .10 → .11',           ip:'27.72.3.11'},
            {id:89175,time:'27/02, 13:28',actorType:'admin',  actorName:'Vuong',    domain:'fintech-app.io',  action:'edit_record',   details_brief:'A @ 100.20 → 100.21',     ip:'10.0.0.1'},
            {id:89174,time:'27/02, 13:25',actorType:'client', actorName:'Lê Công', domain:'petshop-hanoi.vn',action:'add_record',    details_brief:'A @ 203.0.113.9',          ip:'118.70.1.10'},
            {id:89173,time:'27/02, 13:22',actorType:'system', actorName:'Hook',     domain:'farmfresh.net',   action:'delete_record', details_brief:'CNAME alias-old [auto]',  ip:'WHMCS Server'},
            {id:89172,time:'27/02, 13:20',actorType:'client', actorName:'Hà Minh', domain:'cryptotrade.io',  action:'add_record',    details_brief:'TXT _stripe-verif …',     ip:'203.0.113.5'},
            {id:89171,time:'27/02, 13:18',actorType:'api',    actorName:'DDNS',     domain:'vpn.office.vn',   action:'ddns_update',   details_brief:'IP: .80 → .81',           ip:'113.190.2.81'},
            {id:89170,time:'27/02, 13:15',actorType:'admin',  actorName:'Linh',     domain:'beauty-salon.vn', action:'edit_record',   details_brief:'A @ .7 → .8',             ip:'10.0.0.2'},
            {id:89169,time:'27/02, 13:12',actorType:'client', actorName:'Đỗ Hùng', domain:'b2b-marketplace.com',action:'add_record', details_brief:'NS ns2.hvn.vn.',           ip:'118.70.3.30'},
            {id:89168,time:'27/02, 13:10',actorType:'system', actorName:'Cron',     domain:'artgallery.xyz',  action:'delete_record', details_brief:'A staging [cleanup]',     ip:'WHMCS Server'},
            {id:89167,time:'27/02, 13:08',actorType:'client', actorName:'Trần T',  domain:'insurtech.io',    action:'add_record',    details_brief:'AAAA @ 2001:db8::9',      ip:'118.70.2.20'},
            {id:89166,time:'27/02, 13:05',actorType:'api',    actorName:'DDNS',     domain:'nas.mylab.net',   action:'ddns_update',   details_brief:'IP: .30 → .31',           ip:'27.72.5.31'},
            {id:89165,time:'27/02, 13:02',actorType:'admin',  actorName:'Vuong',    domain:'sme-erp.net',     action:'rollback',      details_brief:'Rollback v5 → v4',        ip:'10.0.0.1'},
            {id:89164,time:'27/02, 13:00',actorType:'client', actorName:'Nguyễn A',domain:'homeremodel.com',  action:'add_record',    details_brief:'TXT acme-challenge …',    ip:'203.0.113.15'},
            {id:89163,time:'27/02, 12:58',actorType:'system', actorName:'Hook',     domain:'kidsedu.vn',      action:'delete_record', details_brief:'A dev [auto-cleanup]',    ip:'WHMCS Server'},
            {id:89162,time:'27/02, 12:55',actorType:'client', actorName:'Phạm V',  domain:'fitness-app.io',  action:'edit_record',   details_brief:'CNAME api: v1 → v2',      ip:'203.0.113.25'},
            {id:89161,time:'27/02, 12:52',actorType:'api',    actorName:'DDNS',     domain:'cam3.factory.vn', action:'ddns_update',   details_brief:'IP: .60 → .61',           ip:'14.160.5.61'},
            {id:89160,time:'27/02, 12:50',actorType:'admin',  actorName:'Linh',     domain:'vietfood-export.com',action:'add_record', details_brief:'A @ 203.0.0.88',          ip:'10.0.0.2'},
            {id:89159,time:'27/02, 12:48',actorType:'client', actorName:'Lê Công', domain:'coworkspace.net', action:'add_record',    details_brief:'MX 20 mx.cw.net.',        ip:'118.70.1.10'},
            {id:89158,time:'27/02, 12:45',actorType:'system', actorName:'Cron',     domain:'smartfarm.vn',    action:'edit_record',   details_brief:'SOA serial refresh',      ip:'WHMCS Server'},
            {id:89157,time:'27/02, 12:43',actorType:'client', actorName:'Hà Minh', domain:'nftmarket.xyz',   action:'add_record',    details_brief:'TXT nft-verify …',        ip:'203.0.113.5'},
            {id:89156,time:'27/02, 12:40',actorType:'api',    actorName:'DDNS',     domain:'printer.office.vn',action:'ddns_update',  details_brief:'IP: .90 → .91',           ip:'113.190.3.91'},
            {id:89155,time:'27/02, 12:38',actorType:'admin',  actorName:'Vuong',    domain:'rental-management.com',action:'edit_record',details_brief:'A @ 45.77 → 45.78',    ip:'10.0.0.1'},
            {id:89154,time:'27/02, 12:35',actorType:'client', actorName:'Đỗ Hùng', domain:'pharmacy-online.vn',action:'delete_record',details_brief:'CNAME old-cdn → [xóa]',  ip:'118.70.3.30'},
            {id:89153,time:'27/02, 12:32',actorType:'system', actorName:'Hook',     domain:'social-analytics.io',action:'add_record', details_brief:'A metrics 10.1.1.1 [auto]',ip:'WHMCS Server'},
            {id:89152,time:'27/02, 12:30',actorType:'client', actorName:'Trần T',  domain:'green-energy.net',action:'edit_record',   details_brief:'TXT dmarc v1 → v2',       ip:'118.70.2.20'},
            {id:89151,time:'27/02, 12:28',actorType:'api',    actorName:'DDNS',     domain:'iot.smartfarm.vn',action:'ddns_update',   details_brief:'IP: .20 → .21',           ip:'27.72.8.21'},
            {id:89150,time:'27/02, 12:25',actorType:'client', actorName:'Phạm V',  domain:'airservice.vn',   action:'add_record',    details_brief:'SRV _sip._tcp 5060',      ip:'203.0.113.25'},
            {id:89149,time:'27/02, 12:22',actorType:'admin',  actorName:'Linh',     domain:'dataops-hub.dev',  action:'edit_record',   details_brief:'CNAME grafana: old → new',ip:'10.0.0.2'},
            {id:89148,time:'27/02, 12:20',actorType:'system', actorName:'Cron',     domain:'legalpro.com.vn',  action:'enable_dnssec', details_brief:'DNSSEC on (auto)',         ip:'WHMCS Server'},
        ],

        get filteredLogs() {
            return this.allLogs.filter(l => {
                if (this.filterActor  && l.actorType !== this.filterActor)         return false;
                if (this.filterAction && l.action    !== this.filterAction)        return false;
                if (this.filterDomain && !l.domain.includes(this.filterDomain))   return false;
                if (this.filterIp     && !l.ip.includes(this.filterIp))           return false;
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
