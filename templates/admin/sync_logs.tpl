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
                    <input type="text" class="hvn-form-control" placeholder="Tên miền (VD: myblog.net)..." x-model="filterDomain">
                </div>
                <div class="hvn-col-md-2">
                    <select class="hvn-form-select" x-model="filterStatus">
                        <option value="">Tất cả trạng thái</option>
                        <option value="complete">✅ Complete</option>
                        <option value="pending">🟡 Pending</option>
                        <option value="failed">❌ Failed</option>
                    </select>
                </div>
                <div class="hvn-col-md-2">
                    <select class="hvn-form-select" x-model="filterServer">
                        <option value="">Tất cả Server</option>
                        <option value="dns1.hvn.vn">dns1.hvn.vn</option>
                        <option value="dns2.hvn.vn">dns2.hvn.vn</option>
                        <option value="dns3.hvn.vn">dns3.hvn.vn</option>
                    </select>
                </div>
                <div class="hvn-col-md-2">
                    <select class="hvn-form-select" x-model="filterAction">
                        <option value="">Tất cả Action</option>
                        <option value="ADD_RECORD">ADD_RECORD</option>
                        <option value="EDIT_RECORD">EDIT_RECORD</option>
                        <option value="DELETE_RECORD">DELETE_RECORD</option>
                        <option value="ENABLE_DNSSEC">ENABLE_DNSSEC</option>
                    </select>
                </div>
                <div class="hvn-col-md-3 hvn-text-end hvn-d-flex hvn-align-items-center hvn-justify-content-end" style="gap:6px;">
                    <label class="hvn-small hvn-text-muted" style="white-space:nowrap;">Hiển:</label>
                    <select class="hvn-form-select" style="width:90px;" x-model.number="perPage">
                        <option value="100">100</option>
                        <option value="200">200</option>
                        <option value="500">500</option>
                        <option value="0">Tất cả</option>
                    </select>
                    <button class="hvn-btn hvn-btn-primary"><i class="bi bi-funnel"></i> Lọc</button>
                    <button class="hvn-btn hvn-btn-outline-secondary" @click="filterDomain=''; filterStatus=''; filterServer=''; filterAction=''; currentPage=1;"><i class="bi bi-arrow-counterclockwise"></i></button>
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
                        <template x-for="log in pagedLogs" :key="log.id">
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

    <nav class="hvn-mt-3 hvn-d-flex hvn-align-items-center hvn-justify-content-between">
        <div class="hvn-small hvn-text-muted">
            Hiển <span x-text="pagedLogs.length"></span> / <span x-text="filteredLogs.length"></span> bản ghi
        </div>
        <ul class="hvn-pagination hvn-pagination-sm hvn-mb-0">
            <li class="hvn-page-item" :class="currentPage === 1 ? 'hvn-disabled' : ''">
                <a class="hvn-page-link" href="#" @click.prevent="currentPage > 1 && currentPage--">&#8592;</a>
            </li>
            <template x-for="p in totalPages" :key="p">
                <li class="hvn-page-item" :class="p === currentPage ? 'hvn-active' : ''">
                    <a class="hvn-page-link" href="#" @click.prevent="currentPage = p" x-text="p"></a>
                </li>
            </template>
            <li class="hvn-page-item" :class="currentPage === totalPages ? 'hvn-disabled' : ''">
                <a class="hvn-page-link" href="#" @click.prevent="currentPage < totalPages && currentPage++">&#8594;</a>
            </li>
        </ul>
    </nav>
</div>

<script>
{literal}
document.addEventListener('alpine:init', () => {
    Alpine.data('syncLogsData', () => ({
        filterDomain: '', filterStatus: '', filterServer: '', filterAction: '',
        perPage: 100,
        currentPage: 1,

        allLogs: [
            {id:4521,time:'2026-02-27 14:32',domain:'myblog.net',    action:'DELETE_RECORD',details:'A @ 1.2.3.4',         server:'dns3.hvn.vn',status:'failed',  error_brief:'Connection timeout',ms:null},
            {id:4520,time:'2026-02-27 14:31',domain:'shop.vn',       action:'ADD_RECORD',   details:'A mail 203.0.1.10',  server:'dns1.hvn.vn',status:'complete',error_brief:'',ms:89},
            {id:4519,time:'2026-02-27 14:31',domain:'shop.vn',       action:'ADD_RECORD',   details:'A mail 203.0.1.10',  server:'dns2.hvn.vn',status:'complete',error_brief:'',ms:92},
            {id:4518,time:'2026-02-27 14:31',domain:'shop.vn',       action:'ADD_RECORD',   details:'A mail 203.0.1.10',  server:'dns3.hvn.vn',status:'failed',  error_brief:'Connection timeout',ms:null},
            {id:4517,time:'2026-02-27 14:28',domain:'techstore.io',  action:'EDIT_RECORD',  details:'MX @ mail.ts.io.',   server:'dns1.hvn.vn',status:'complete',error_brief:'',ms:110},
            {id:4516,time:'2026-02-27 14:25',domain:'startup.dev',   action:'ADD_RECORD',   details:'TXT @ v=spf1 ...',   server:'dns2.hvn.vn',status:'complete',error_brief:'',ms:76},
            {id:4515,time:'2026-02-27 14:20',domain:'myfashion.vn',  action:'DELETE_RECORD',details:'CNAME www',           server:'dns1.hvn.vn',status:'failed',  error_brief:'Auth failed',ms:null},
            {id:4514,time:'2026-02-27 14:18',domain:'eatventure.com',action:'ADD_RECORD',   details:'A api 10.0.0.5',     server:'dns3.hvn.vn',status:'complete',error_brief:'',ms:55},
            {id:4513,time:'2026-02-27 14:15',domain:'saas-platform.io',action:'EDIT_RECORD',details:'A @ 198.51.100.1',  server:'dns1.hvn.vn',status:'complete',error_brief:'',ms:88},
            {id:4512,time:'2026-02-27 14:10',domain:'travel-vn.vn',  action:'ADD_RECORD',   details:'MX @ smtp.tv.vn.',   server:'dns2.hvn.vn',status:'failed',  error_brief:'DA api error 500',ms:null},
            {id:4511,time:'2026-02-27 14:08',domain:'cloudhosting.net',action:'ADD_RECORD', details:'AAAA @ 2001:db8::1',server:'dns1.hvn.vn',status:'complete',error_brief:'',ms:134},
            {id:4510,time:'2026-02-27 14:05',domain:'newproject.xyz',action:'ADD_RECORD',   details:'A @ 203.0.113.5',    server:'dns3.hvn.vn',status:'complete',error_brief:'',ms:67},
            {id:4509,time:'2026-02-27 14:01',domain:'digitalagency.com',action:'EDIT_RECORD',details:'CNAME cdn',         server:'dns2.hvn.vn',status:'complete',error_brief:'',ms:91},
            {id:4508,time:'2026-02-27 13:58',domain:'elearning.edu.vn',action:'DELETE_RECORD',details:'A old.srv',       server:'dns1.hvn.vn',status:'complete',error_brief:'',ms:45},
            {id:4507,time:'2026-02-27 13:55',domain:'media-hub.net', action:'ADD_RECORD',   details:'TXT dkim2048',       server:'dns3.hvn.vn',status:'failed',  error_brief:'Timed out 30s',ms:null},
            {id:4506,time:'2026-02-27 13:52',domain:'fintech-app.io',action:'EDIT_RECORD',  details:'A @ 100.20.30.40',   server:'dns2.hvn.vn',status:'complete',error_brief:'',ms:102},
            {id:4505,time:'2026-02-27 13:50',domain:'realty.com.vn', action:'ADD_RECORD',   details:'CAA 0 issue le.org', server:'dns1.hvn.vn',status:'pending', error_brief:'',ms:null},
            {id:4504,time:'2026-02-27 13:47',domain:'game-portal.net',action:'DELETE_RECORD',details:'A beta',            server:'dns3.hvn.vn',status:'complete',error_brief:'',ms:58},
            {id:4503,time:'2026-02-27 13:44',domain:'healthclinic.vn',action:'ADD_RECORD',  details:'MX 10 mail.hc.vn.', server:'dns1.hvn.vn',status:'complete',error_brief:'',ms:79},
            {id:4502,time:'2026-02-27 13:41',domain:'autoparts.shop',action:'EDIT_RECORD',  details:'TXT spf update',     server:'dns2.hvn.vn',status:'failed',  error_brief:'ssh: no route',ms:null},
            {id:4501,time:'2026-02-27 13:39',domain:'logistics-pro.com',action:'ADD_RECORD',details:'A cdn 1.2.3.200',   server:'dns3.hvn.vn',status:'complete',error_brief:'',ms:61},
            {id:4500,time:'2026-02-27 13:36',domain:'myportfolio.dev',action:'EDIT_RECORD', details:'CNAME @ www2',       server:'dns1.hvn.vn',status:'complete',error_brief:'',ms:84},
            {id:4499,time:'2026-02-27 13:33',domain:'petshop-hanoi.vn',action:'ADD_RECORD', details:'A @ 203.0.113.9',    server:'dns2.hvn.vn',status:'complete',error_brief:'',ms:95},
            {id:4498,time:'2026-02-27 13:30',domain:'farmfresh.net', action:'DELETE_RECORD',details:'CNAME alias-old',    server:'dns1.hvn.vn',status:'complete',error_brief:'',ms:53},
            {id:4497,time:'2026-02-27 13:27',domain:'cryptotrade.io',action:'ADD_RECORD',   details:'TXT _ stripe-verif', server:'dns3.hvn.vn',status:'pending', error_brief:'',ms:null},
            {id:4496,time:'2026-02-27 13:24',domain:'beauty-salon.vn',action:'EDIT_RECORD', details:'A @ 198.51.100.7',   server:'dns1.hvn.vn',status:'complete',error_brief:'',ms:70},
            {id:4495,time:'2026-02-27 13:21',domain:'b2b-marketplace.com',action:'ADD_RECORD',details:'NS ns2.hvn.vn.', server:'dns2.hvn.vn',status:'failed',  error_brief:'Permission denied',ms:null},
            {id:4494,time:'2026-02-27 13:18',domain:'artgallery.xyz',action:'DELETE_RECORD',details:'A staging',          server:'dns3.hvn.vn',status:'complete',error_brief:'',ms:47},
            {id:4493,time:'2026-02-27 13:15',domain:'insurtech.io',  action:'ADD_RECORD',   details:'AAAA @ 2001:db8::9',server:'dns1.hvn.vn',status:'complete',error_brief:'',ms:121},
            {id:4492,time:'2026-02-27 13:12',domain:'sme-erp.net',   action:'EDIT_RECORD',  details:'MX @ mx2.sme.net.', server:'dns2.hvn.vn',status:'failed',  error_brief:'Timeout 15s',ms:null},
            {id:4491,time:'2026-02-27 13:09',domain:'homeremodel.com',action:'ADD_RECORD',  details:'TXT acme-challenge',server:'dns1.hvn.vn',status:'complete',error_brief:'',ms:63},
            {id:4490,time:'2026-02-27 13:06',domain:'kidsedu.vn',    action:'DELETE_RECORD',details:'A dev.kidsedu.vn',   server:'dns3.hvn.vn',status:'complete',error_brief:'',ms:44},
            {id:4489,time:'2026-02-27 13:03',domain:'fitness-app.io',action:'EDIT_RECORD',  details:'CNAME api v2',       server:'dns2.hvn.vn',status:'pending', error_brief:'',ms:null},
            {id:4488,time:'2026-02-27 13:00',domain:'vietfood-export.com',action:'ADD_RECORD',details:'A @ 203.0.0.88', server:'dns1.hvn.vn',status:'complete',error_brief:'',ms:81},
            {id:4487,time:'2026-02-27 12:57',domain:'coworkspace.net',action:'ADD_RECORD',  details:'MX 20 mx.cw.net.',  server:'dns3.hvn.vn',status:'complete',error_brief:'',ms:74},
            {id:4486,time:'2026-02-27 12:54',domain:'smartfarm.vn',  action:'EDIT_RECORD',  details:'A iot 10.0.1.50',   server:'dns1.hvn.vn',status:'failed',  error_brief:'ssl error handshake',ms:null},
            {id:4485,time:'2026-02-27 12:51',domain:'nftmarket.xyz',action:'ADD_RECORD',    details:'TXT nft-verify',     server:'dns2.hvn.vn',status:'complete',error_brief:'',ms:66},
            {id:4484,time:'2026-02-27 12:48',domain:'rental-management.com',action:'EDIT_RECORD',details:'A @ 45.77.1.2',server:'dns3.hvn.vn',status:'failed', error_brief:'Max retries exceeded',ms:null},
            {id:4483,time:'2026-02-27 12:45',domain:'pharmacy-online.vn',action:'DELETE_RECORD',details:'CNAME old-cdn', server:'dns1.hvn.vn',status:'complete',error_brief:'',ms:52},
            {id:4482,time:'2026-02-27 12:42',domain:'social-analytics.io',action:'ADD_RECORD',details:'A metrics 10.1.1.1',server:'dns2.hvn.vn',status:'complete',error_brief:'',ms:87},
            {id:4481,time:'2026-02-27 12:39',domain:'green-energy.net',action:'EDIT_RECORD',details:'TXT dmarc v1',      server:'dns3.hvn.vn',status:'complete',error_brief:'',ms:69},
            {id:4480,time:'2026-02-27 12:36',domain:'airservice.vn', action:'ADD_RECORD',   details:'SRV _sip._tcp 5060',server:'dns1.hvn.vn',status:'pending', error_brief:'',ms:null},
            {id:4479,time:'2026-02-27 12:33',domain:'dataops-hub.dev',action:'EDIT_RECORD', details:'CNAME grafana',      server:'dns2.hvn.vn',status:'complete',error_brief:'',ms:93},
            {id:4478,time:'2026-02-27 12:30',domain:'legalpro.com.vn',action:'ADD_RECORD',  details:'A @ 203.0.113.50',  server:'dns3.hvn.vn',status:'failed',  error_brief:'DA 403 Forbidden',ms:null},
            {id:4477,time:'2026-02-27 12:27',domain:'example.com',   action:'ENABLE_DNSSEC',details:'KSK algo13',        server:'dns1.hvn.vn',status:'complete',error_brief:'',ms:310},
            {id:4476,time:'2026-02-27 12:24',domain:'techstore.io',  action:'ADD_RECORD',   details:'CAA 0 issue pki.io',server:'dns2.hvn.vn',status:'complete',error_brief:'',ms:58},
            {id:4475,time:'2026-02-27 12:21',domain:'startup.dev',   action:'DELETE_RECORD',details:'A preview',          server:'dns1.hvn.vn',status:'complete',error_brief:'',ms:41},
            {id:4474,time:'2026-02-27 12:18',domain:'shop.vn',       action:'EDIT_RECORD',  details:'A @ 103.1.2.200',   server:'dns3.hvn.vn',status:'failed',  error_brief:'Connection refused',ms:null},
            {id:4473,time:'2026-02-27 12:15',domain:'myblog.net',    action:'ADD_RECORD',   details:'TXT google-verify',  server:'dns2.hvn.vn',status:'complete',error_brief:'',ms:77},
            {id:4472,time:'2026-02-27 12:12',domain:'saas-platform.io',action:'ADD_RECORD', details:'CNAME status.io',   server:'dns1.hvn.vn',status:'complete',error_brief:'',ms:85},
            {id:4471,time:'2026-02-27 12:09',domain:'cloudhosting.net',action:'EDIT_RECORD',details:'A db 192.168.1.10', server:'dns3.hvn.vn',status:'pending', error_brief:'',ms:null},
            {id:4470,time:'2026-02-27 12:06',domain:'digitalagency.com',action:'DELETE_RECORD',details:'AAAA test-ipv6',server:'dns2.hvn.vn',status:'complete',error_brief:'',ms:48},
            {id:4469,time:'2026-02-27 12:03',domain:'fintech-app.io',action:'ADD_RECORD',   details:'A pay 198.51.10.1', server:'dns1.hvn.vn',status:'complete',error_brief:'',ms:99},
            {id:4468,time:'2026-02-27 12:00',domain:'game-portal.net',action:'EDIT_RECORD', details:'CNAME cdn2 cf.net.', server:'dns3.hvn.vn',status:'complete',error_brief:'',ms:72},
        ],

        get filteredLogs() {
            return this.allLogs.filter(l => {
                if (this.filterDomain && !l.domain.includes(this.filterDomain)) return false;
                if (this.filterStatus && l.status !== this.filterStatus) return false;
                if (this.filterServer && l.server !== this.filterServer) return false;
                if (this.filterAction && l.action !== this.filterAction) return false;
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

        retryJob(log) {
            if (!confirm('Thu lai job #' + log.id + ' tren server ' + log.server + '?')) return;
            log.status = 'pending';
            log.error_brief = 'retrying...';
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
