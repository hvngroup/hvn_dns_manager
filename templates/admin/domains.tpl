<div class="hvn-dns-admin hvn-domains" x-data="domainList()">
    <div class="hvn-d-flex hvn-justify-content-between hvn-align-items-center hvn-mb-4">
        <h2><i class="bi bi-globe"></i> Quản lý Domain</h2>
    </div>

    <!-- Toolbar Filters -->
    <div class="hvn-card hvn-shadow-sm hvn-border-0 hvn-mb-4 hvn-bg-light">
        <div class="hvn-card-body hvn-py-3">
            <div class="hvn-row g-2 hvn-align-items-center">
                <div class="hvn-col-md-4">
                    <div class="hvn-input-group">
                        <span class="hvn-input-group-text hvn-bg-white"><i class="bi bi-search"></i></span>
                        <input type="text" class="hvn-form-control" placeholder="Tìm kiếm tên miền..." x-model="filters.search" @input.debounce.500ms="fetchDomains()">
                    </div>
                </div>
                <div class="hvn-col-md-2">
                    <select class="hvn-form-select" x-model="filters.status" @change="fetchDomains()">
                        <option value="">Tất cả trạng thái</option>
                        <option value="active">🟢 Active</option>
                        <option value="pending">🟡 Pending</option>
                        <option value="suspended">🟠 Suspended</option>
                        <option value="terminated">🔴 Terminated</option>
                    </select>
                </div>
                <div class="hvn-col-md-2">
                    <select class="hvn-form-select" x-model="filters.server" @change="fetchDomains()">
                        <option value="">Tất cả Server</option>
                        <option value="dns1.hvn.vn">dns1.hvn.vn</option>
                        <option value="dns2.hvn.vn">dns2.hvn.vn</option>
                    </select>
                </div>
                <div class="hvn-col-md-2 hvn-d-flex hvn-align-items-center">
                    <div class="hvn-form-check hvn-form-switch hvn-mb-0">
                        <input class="hvn-form-check-input" type="checkbox" id="errorOnly" x-model="filters.errorOnly" @change="fetchDomains()">
                        <label class="hvn-form-check-label hvn-text-danger" for="errorOnly">Chỉ domain có lỗi</label>
                    </div>
                </div>
                <div class="hvn-col-md-2 hvn-text-end hvn-d-flex hvn-justify-content-end hvn-align-items-center hvn-gap-1">
                    <select class="hvn-form-select" style="width:auto;" x-model="perPage" @change="currentPage=1; fetchDomains()">
                        <option value="25">25/trang</option>
                        <option value="50" selected>50/trang</option>
                        <option value="100">100/trang</option>
                    </select>
                    <button class="hvn-btn hvn-btn-sm hvn-btn-outline-secondary" @click="resetFilters()"><i class="bi bi-arrow-counterclockwise"></i></button>
                </div>
            </div>
        </div>
    </div>

    <!-- Domain Table -->
    <div class="hvn-card hvn-shadow-sm hvn-border-0">
        <div class="hvn-card-body hvn-p-0">
            <div class="hvn-table-responsive" style="overflow: visible;">
                <table class="hvn-table hvn-table-hover hvn-align-middle hvn-mb-0">
                    <thead class="hvn-table-light">
                        <tr>
                            <th class="hvn-ps-4" style="cursor:pointer;white-space:nowrap;" @click="sortBy('domain')">
                                Domain
                                <span class="hvn-text-muted" style="font-size:.7rem;">
                                    <span x-text="sortCol === 'domain' ? (sortDir === 'asc' ? '&#9650;' : '&#9660;') : '&#8597;'"></span>
                                </span>
                            </th>
                            <th style="cursor:pointer;white-space:nowrap;" @click="sortBy('client_name')">
                                Khách hàng
                                <span class="hvn-text-muted" style="font-size:.7rem;">
                                    <span x-text="sortCol === 'client_name' ? (sortDir === 'asc' ? '&#9650;' : '&#9660;') : '&#8597;'"></span>
                                </span>
                            </th>
                            <th class="hvn-text-center" style="cursor:pointer;white-space:nowrap;" @click="sortBy('records_count')">
                                Records
                                <span class="hvn-text-muted" style="font-size:.7rem;">
                                    <span x-text="sortCol === 'records_count' ? (sortDir === 'asc' ? '&#9650;' : '&#9660;') : '&#8597;'"></span>
                                </span>
                            </th>
                            <th style="cursor:pointer;white-space:nowrap;" @click="sortBy('failed_jobs')">
                                Sync gần nhất
                                <span class="hvn-text-muted" style="font-size:.7rem;">
                                    <span x-text="sortCol === 'failed_jobs' ? (sortDir === 'asc' ? '&#9650;' : '&#9660;') : '&#8597;'"></span>
                                </span>
                            </th>
                            <th style="cursor:pointer;white-space:nowrap;" @click="sortBy('status')">
                                Trạng thái
                                <span class="hvn-text-muted" style="font-size:.7rem;">
                                    <span x-text="sortCol === 'status' ? (sortDir === 'asc' ? '&#9650;' : '&#9660;') : '&#8597;'"></span>
                                </span>
                            </th>
                            <th class="hvn-text-end hvn-pe-4">Hành động</th>
                        </tr>
                    </thead>
                    <tbody>
                        <!-- Loading State -->
                        <template x-if="loading">
                            <tr>
                                <td colspan="6" class="hvn-text-center py-5 hvn-text-muted">
                                    <div class="hvn-spinner-border hvn-text-primary hvn-mb-2" role="status"></div>
                                    <br>Đang tải dữ liệu...
                                </td>
                            </tr>
                        </template>

                        <!-- Empty State -->
                        <template x-if="!loading && domains.length === 0">
                            <tr>
                                <td colspan="6" class="hvn-text-center py-5 hvn-text-muted">
                                    <i class="bi bi-inbox fs-1 hvn-d-block hvn-mb-3"></i>
                                    Không tìm thấy dữ liệu phù hợp với bộ lọc hiện tại.
                                </td>
                            </tr>
                        </template>

                        <!-- Data Rows -->
                        <template x-if="!loading && domains.length > 0">
                            <template x-for="domain in domains" :key="domain.id">
                                <tr :style="syncingId === domain.id ? 'background: rgba(13,110,253,0.05);' : ''">
                                    <td class="hvn-ps-4 font-monospace hvn-fw-bold">
                                        <a :href="'?module=hvn_dns_manager&action=admin_dns_editor&domain_id=' + domain.id" class="text-decoration-none">
                                            <span x-text="domain.domain"></span>
                                        </a>
                                    </td>
                                    <td>
                                        <a :href="'clientssummary.php?userid=' + domain.client_id" class="text-decoration-none" target="_blank">
                                            <span x-text="domain.client_name"></span> <span class="hvn-text-muted small">#<span x-text="domain.client_id"></span></span>
                                        </a>
                                    </td>
                                    <td class="hvn-text-center" x-text="domain.records_count"></td>
                                    <td>
                                        <div x-text="domain.last_sync"></div>
                                        <template x-if="domain.failed_jobs > 0">
                                            <div class="hvn-text-danger small"><i class="bi bi-exclamation-triangle"></i> <span x-text="domain.failed_jobs"></span> fail</div>
                                        </template>
                                    </td>
                                    <td>
                                        <!-- Đang force re-sync: hiện spinner -->
                                        <template x-if="syncingId === domain.id">
                                            <span class="hvn-badge" style="background:#0d6efd;color:#fff;">
                                                <span class="hvn-spinner-border hvn-spinner-border-sm" style="width:.7rem;height:.7rem;" role="status"></span>
                                                Re-syncing...
                                            </span>
                                        </template>
                                        <!-- Trạng thái bình thường -->
                                        <template x-if="syncingId !== domain.id && domain.status === 'active'">
                                            <span>
                                                <template x-if="domain.sync_status === 'complete'">
                                                    <span class="hvn-badge hvn-bg-success">&#x1F7E2; Active</span>
                                                </template>
                                                <template x-if="domain.sync_status === 'syncing'">
                                                    <span class="hvn-badge hvn-bg-info"><span class="hvn-spinner-border hvn-spinner-border-sm" role="status" style="width:.75rem;height:.75rem;"></span> Syncing</span>
                                                </template>
                                                <template x-if="domain.sync_status === 'failed'">
                                                    <span class="hvn-badge hvn-bg-warning hvn-text-dark">&#x1F7E1; Sync Failed</span>
                                                </template>
                                            </span>
                                        </template>
                                        <template x-if="syncingId !== domain.id && domain.status !== 'active'">
                                            <span class="hvn-badge hvn-bg-danger" x-text="domain.status"></span>
                                        </template>
                                    </td>
                                    <td class="hvn-text-end hvn-pe-4" style="white-space: nowrap;">
                                        <a :href="'{$modulelink}&action=admin_dns_editor&domain_id=' + domain.id"
                                           class="hvn-btn hvn-btn-sm hvn-btn-blue hvn-me-1">
                                            <i class="bi bi-sliders"></i> DNS
                                        </a>
                                        <div class="hvn-dropdown hvn-d-inline-block" style="position: relative;">
                                            <button class="hvn-btn hvn-btn-sm hvn-btn-outline-secondary hvn-dropdown-toggle"
                                                    type="button"
                                                    :disabled="syncingId === domain.id"
                                                    @click.stop="openDropdown($event)">
                                                <i class="bi bi-three-dots-vertical"></i>
                                            </button>
                                            <ul class="hvn-dropdown-menu hvn-dropdown-menu-end">
                                                <li><a class="hvn-dropdown-item" :href="'{$modulelink}&action=admin_dns_editor&domain_id=' + domain.id"><i class="bi bi-sliders hvn-text-primary"></i> S&#x1EED;a DNS Records</a></li>
                                                <li><a class="hvn-dropdown-item" href="#" @click.prevent="forceResync(domain)"><i class="bi bi-arrow-repeat hvn-text-warning"></i> Force Re-sync</a></li>
                                                <li><a class="hvn-dropdown-item" href="#"><i class="bi bi-journal-text"></i> Xem Audit Trail</a></li>
                                                <li><hr class="hvn-dropdown-divider"></li>
                                                <li><a class="hvn-dropdown-item" :href="'clientsservices.php?userid=' + domain.client_id + '&id=' + domain.service_id"><i class="bi bi-box"></i> Qu&#x1EA3;n l&#xFD; Service WHMCS</a></li>
                                            </ul>
                                        </div>
                                    </td>
                                </tr>
                            </template>
                        </template>
                    </tbody>
                </table>
            </div>
        </div>
        
        <!-- Pagination -->
        <div class="hvn-card-footer hvn-bg-white hvn-py-3 hvn-d-flex hvn-justify-content-between hvn-align-items-center">
            <div class="hvn-text-muted hvn-small">
                Hiển thị <span x-text="domains.length"></span> / <span x-text="totalRecords"></span> domain
                &nbsp;&bull;&nbsp; Trang <span x-text="currentPage"></span>/<span x-text="totalPages"></span>
            </div>
            <nav aria-label="Page navigation" x-show="totalPages > 1">
                <ul class="hvn-pagination hvn-pagination-sm hvn-mb-0">
                    <li class="hvn-page-item" :class="{literal}{'hvn-disabled': currentPage === 1}{/literal}">
                        <a class="hvn-page-link" href="#" @click.prevent="goToPage(currentPage - 1)">&laquo;</a>
                    </li>
                    <li class="hvn-page-item hvn-active"><a class="hvn-page-link" href="#" x-text="currentPage"></a></li>
                    <li class="hvn-page-item" :class="{literal}{'hvn-disabled': currentPage === totalPages}{/literal}">
                        <a class="hvn-page-link" href="#" @click.prevent="goToPage(currentPage + 1)">&raquo;</a>
                    </li>
                </ul>
            </nav>
        </div>
    </div>
</div>

<script>
{literal}
document.addEventListener('alpine:init', () => {
    Alpine.data('domainList', () => ({
        loading: false,
        domains: [],
        totalRecords: 342,
        totalPages: 7,
        currentPage: 1,
        perPage: 50,
        syncingId: null,
        sortCol: 'domain',
        sortDir: 'asc',
        filters: { search: '', status: '', server: '', errorOnly: false },

        init() {
            this.fetchDomains();
        },

        resetFilters() {
            this.filters = { search: '', status: '', server: '', errorOnly: false };
            this.sortCol = 'domain';
            this.sortDir = 'asc';
            this.currentPage = 1;
            this.fetchDomains();
        },

        sortBy(col) {
            if (this.sortCol === col) {
                this.sortDir = this.sortDir === 'asc' ? 'desc' : 'asc';
            } else {
                this.sortCol = col;
                this.sortDir = 'asc';
            }
            // Client-side sort trên data hiện tại
            this.domains = [...this.domains].sort((a, b) => {
                var va = a[col] ?? '';
                var vb = b[col] ?? '';
                if (typeof va === 'number' && typeof vb === 'number') {
                    return this.sortDir === 'asc' ? va - vb : vb - va;
                }
                return this.sortDir === 'asc'
                    ? String(va).localeCompare(String(vb))
                    : String(vb).localeCompare(String(va));
            });
        },

        goToPage(page) {
            if(page >= 1 && page <= this.totalPages) {
                this.currentPage = page;
                this.fetchDomains();
            }
        },

        // Dropdown trong table: dùng position:fixed để thoát overflow
        openDropdown(event) {
            var btn = event.currentTarget;
            var menu = btn.nextElementSibling;
            var isOpen = menu.classList.contains('hvn-show');

            // Đóng tất cả dropdown đang mở
            document.querySelectorAll('.hvn-dropdown-menu.hvn-show').forEach(function(m) {
                m.classList.remove('hvn-show');
                m.style.position = '';
                m.style.top = '';
                m.style.right = '';
                m.style.left = '';
                m.style.minWidth = '';
            });

            if (!isOpen) {
                var rect = btn.getBoundingClientRect();
                menu.style.position = 'fixed';
                menu.style.top = (rect.bottom + 4) + 'px';
                menu.style.right = (window.innerWidth - rect.right) + 'px';
                menu.style.left = 'auto';
                menu.style.minWidth = '200px';
                menu.classList.add('hvn-show');
            }
        },

        // Force re-sync: đặt syncingId → gọi API → clear khi xong
        async forceResync(domain) {
            if (this.syncingId !== null) return; // tránh double-click
            this.syncingId = domain.id;

            // Đóng dropdown
            document.querySelectorAll('.hvn-dropdown-menu.hvn-show').forEach(function(m) {
                m.classList.remove('hvn-show');
            });

            try {
                // TODO: thay bằng AJAX thực tế khi backend sẵn sàng
                // const res = await fetch(window.HVNDNS_BASE_URL + '&action=ajax&method=forceResync', {
                //     method: 'POST',
                //     headers: { 'Content-Type': 'application/json', 'X-Requested-With': 'XMLHttpRequest' },
                //     body: JSON.stringify({ domain_id: domain.id })
                // });
                // const data = await res.json();

                // Mock: giả lập 2.5s xử lý
                await new Promise(r => setTimeout(r, 2500));

                // Cập nhật trạng thái domain trong list
                var idx = this.domains.findIndex(d => d.id === domain.id);
                if (idx !== -1) {
                    this.domains[idx].sync_status = 'complete';
                    this.domains[idx].failed_jobs = 0;
                    this.domains[idx].last_sync = 'Vừa xong';
                }
            } catch (e) {
                console.error('Force re-sync thất bại:', e);
            } finally {
                this.syncingId = null;
            }
        },

        fetchDomains() {
            this.loading = true;
            
            // Mock delay
            setTimeout(() => {
                let mockData = [
                    { id: 1,  service_id: 101, domain: 'example.com',        client_id: 1234, client_name: 'Nguyễn Văn An',      records_count: 15, last_sync: '2 phút trước',    failed_jobs: 0, status: 'active',     sync_status: 'complete' },
                    { id: 2,  service_id: 102, domain: 'shop.vn',             client_id: 1235, client_name: 'Trần Thị Bích',      records_count: 8,  last_sync: '5 phút trước',    failed_jobs: 0, status: 'active',     sync_status: 'complete' },
                    { id: 3,  service_id: 103, domain: 'myblog.net',           client_id: 1236, client_name: 'Lê Hồng Cường',      records_count: 3,  last_sync: '1 giờ trước',     failed_jobs: 2, status: 'active',     sync_status: 'failed'   },
                    { id: 4,  service_id: 104, domain: 'old-site.org',         client_id: 1237, client_name: 'Phạm Minh Dũng',     records_count: 22, last_sync: '3 ngày trước',    failed_jobs: 0, status: 'suspended',  sync_status: 'complete' },
                    { id: 5,  service_id: 105, domain: 'techstore.io',         client_id: 1238, client_name: 'Hoàng Thu Hà',       records_count: 31, last_sync: '10 phút trước',   failed_jobs: 0, status: 'active',     sync_status: 'complete' },
                    { id: 6,  service_id: 106, domain: 'startup.dev',          client_id: 1239, client_name: 'Vũ Quốc Hùng',      records_count: 7,  last_sync: 'Vừa xong',        failed_jobs: 0, status: 'active',     sync_status: 'syncing'  },
                    { id: 7,  service_id: 107, domain: 'myfashion.vn',         client_id: 1240, client_name: 'Đặng Thị Kim',      records_count: 18, last_sync: '30 phút trước',   failed_jobs: 1, status: 'active',     sync_status: 'failed'   },
                    { id: 8,  service_id: 108, domain: 'eatventure.com',       client_id: 1241, client_name: 'Ngô Văn Long',       records_count: 12, last_sync: '2 giờ trước',     failed_jobs: 0, status: 'active',     sync_status: 'complete' },
                    { id: 9,  service_id: 109, domain: 'saas-platform.io',     client_id: 1242, client_name: 'Bùi Thị Lan',       records_count: 45, last_sync: '15 phút trước',   failed_jobs: 0, status: 'active',     sync_status: 'complete' },
                    { id: 10, service_id: 110, domain: 'travel-vn.vn',         client_id: 1243, client_name: 'Đinh Văn Mạnh',     records_count: 9,  last_sync: '5 ngày trước',    failed_jobs: 5, status: 'active',     sync_status: 'failed'   },
                    { id: 11, service_id: 111, domain: 'cloudhosting.net',     client_id: 1244, client_name: 'Lý Thị Nhi',        records_count: 27, last_sync: '1 phút trước',    failed_jobs: 0, status: 'active',     sync_status: 'complete' },
                    { id: 12, service_id: 112, domain: 'newproject.xyz',       client_id: 1245, client_name: 'Trương Văn Oanh',   records_count: 4,  last_sync: 'Chưa đồng bộ',    failed_jobs: 0, status: 'pending',   sync_status: 'complete' },
                    { id: 13, service_id: 113, domain: 'digitalagency.com',    client_id: 1246, client_name: 'Phan Thị Phượng',   records_count: 56, last_sync: '3 phút trước',    failed_jobs: 0, status: 'active',     sync_status: 'complete' },
                    { id: 14, service_id: 114, domain: 'elearning.edu.vn',     client_id: 1247, client_name: 'Cao Quang Quân',    records_count: 33, last_sync: '45 phút trước',   failed_jobs: 0, status: 'active',     sync_status: 'complete' },
                    { id: 15, service_id: 115, domain: 'media-hub.net',        client_id: 1248, client_name: 'Hồ Thị Rằm',       records_count: 19, last_sync: '2 giờ trước',     failed_jobs: 3, status: 'active',     sync_status: 'failed'   },
                    { id: 16, service_id: 116, domain: 'fintech-app.io',       client_id: 1249, client_name: 'Võ Văn Sơn',       records_count: 38, last_sync: '20 phút trước',   failed_jobs: 0, status: 'active',     sync_status: 'syncing'  },
                    { id: 17, service_id: 117, domain: 'realty.com.vn',        client_id: 1250, client_name: 'Mai Thị Trang',     records_count: 14, last_sync: '7 ngày trước',    failed_jobs: 0, status: 'suspended',  sync_status: 'complete' },
                    { id: 18, service_id: 118, domain: 'game-portal.net',      client_id: 1251, client_name: 'Dương Hữu Uy',     records_count: 62, last_sync: '8 phút trước',    failed_jobs: 0, status: 'active',     sync_status: 'complete' },
                    { id: 19, service_id: 119, domain: 'healthclinic.vn',      client_id: 1252, client_name: 'Lưu Thị Vân',      records_count: 11, last_sync: '1 ngày trước',    failed_jobs: 0, status: 'active',     sync_status: 'complete' },
                    { id: 20, service_id: 120, domain: 'autoparts.shop',       client_id: 1253, client_name: 'Kiều Xuân Xuyên',  records_count: 5,  last_sync: '4 giờ trước',     failed_jobs: 7, status: 'active',     sync_status: 'failed'   },
                    { id: 21, service_id: 121, domain: 'logistics-pro.com',    client_id: 1254, client_name: 'Nghiêm Thị Yến',   records_count: 29, last_sync: '6 phút trước',    failed_jobs: 0, status: 'active',     sync_status: 'complete' },
                    { id: 22, service_id: 122, domain: 'myportfolio.dev',      client_id: 1255, client_name: 'Thái Văn Zinc',    records_count: 6,  last_sync: '25 phút trước',   failed_jobs: 0, status: 'active',     sync_status: 'complete' },
                    { id: 23, service_id: 123, domain: 'petshop-hanoi.vn',     client_id: 1256, client_name: 'Chu Thị Ánh',      records_count: 16, last_sync: '12 phút trước',   failed_jobs: 0, status: 'active',     sync_status: 'complete' },
                    { id: 24, service_id: 124, domain: 'farmfresh.net',        client_id: 1257, client_name: 'Ân Văn Bảo',       records_count: 8,  last_sync: 'Chưa đồng bộ',    failed_jobs: 0, status: 'pending',   sync_status: 'complete' },
                    { id: 25, service_id: 125, domain: 'cryptotrade.io',       client_id: 1258, client_name: 'Mộc Thị Cẩm',     records_count: 41, last_sync: '35 phút trước',   failed_jobs: 2, status: 'active',     sync_status: 'failed'   },
                    { id: 26, service_id: 126, domain: 'beauty-salon.vn',      client_id: 1259, client_name: 'Tôn Văn Đạt',     records_count: 10, last_sync: '3 phút trước',    failed_jobs: 0, status: 'active',     sync_status: 'complete' },
                    { id: 27, service_id: 127, domain: 'b2b-marketplace.com',  client_id: 1260, client_name: 'Ứng Thị Ê',       records_count: 73, last_sync: '18 phút trước',   failed_jobs: 0, status: 'active',     sync_status: 'complete' },
                    { id: 28, service_id: 128, domain: 'artgallery.xyz',       client_id: 1261, client_name: 'Đào Văn Phong',    records_count: 24, last_sync: '2 ngày trước',    failed_jobs: 0, status: 'suspended',  sync_status: 'complete' },
                    { id: 29, service_id: 129, domain: 'insurtech.io',         client_id: 1262, client_name: 'Hà Thị Giang',    records_count: 52, last_sync: 'Vừa xong',        failed_jobs: 0, status: 'active',     sync_status: 'syncing'  },
                    { id: 30, service_id: 130, domain: 'sme-erp.net',          client_id: 1263, client_name: 'Lã Công Hiếu',    records_count: 17, last_sync: '50 phút trước',   failed_jobs: 4, status: 'active',     sync_status: 'failed'   },
                    { id: 31, service_id: 131, domain: 'homeremodel.com',      client_id: 1264, client_name: 'Tạ Thị Ích',      records_count: 9,  last_sync: '7 phút trước',    failed_jobs: 0, status: 'active',     sync_status: 'complete' },
                    { id: 32, service_id: 132, domain: 'kidsedu.vn',           client_id: 1265, client_name: 'Uông Văn Khoa',   records_count: 13, last_sync: '40 phút trước',   failed_jobs: 0, status: 'active',     sync_status: 'complete' },
                    { id: 33, service_id: 133, domain: 'fitness-app.io',       client_id: 1266, client_name: 'Văn Thị Liễu',    records_count: 28, last_sync: '1 giờ trước',     failed_jobs: 1, status: 'active',     sync_status: 'failed'   },
                    { id: 34, service_id: 134, domain: 'vietfood-export.com',  client_id: 1267, client_name: 'Xương Đức Minh',  records_count: 35, last_sync: '11 phút trước',   failed_jobs: 0, status: 'active',     sync_status: 'complete' },
                    { id: 35, service_id: 135, domain: 'coworkspace.net',      client_id: 1268, client_name: 'Yêm Thị Ngọc',   records_count: 20, last_sync: '6 ngày trước',    failed_jobs: 0, status: 'terminated', sync_status: 'complete' },
                    { id: 36, service_id: 136, domain: 'smartfarm.vn',         client_id: 1269, client_name: 'Zimbra Văn Ổn',  records_count: 11, last_sync: '22 phút trước',   failed_jobs: 0, status: 'active',     sync_status: 'complete' },
                    { id: 37, service_id: 137, domain: 'nftmarket.xyz',        client_id: 1270, client_name: 'Ạch Thị Phong',  records_count: 47, last_sync: '4 phút trước',    failed_jobs: 0, status: 'active',     sync_status: 'syncing'  },
                    { id: 38, service_id: 138, domain: 'rental-management.com', client_id: 1271, client_name: 'Bạch Quang Quý', records_count: 25, last_sync: '1 giờ trước',    failed_jobs: 6, status: 'active',     sync_status: 'failed'   },
                    { id: 39, service_id: 139, domain: 'pharmacy-online.vn',   client_id: 1272, client_name: 'Cạnh Thị Ré',   records_count: 16, last_sync: '9 phút trước',    failed_jobs: 0, status: 'active',     sync_status: 'complete' },
                    { id: 40, service_id: 140, domain: 'social-analytics.io',  client_id: 1273, client_name: 'Đạc Văn Sen',   records_count: 58, last_sync: '28 phút trước',   failed_jobs: 0, status: 'active',     sync_status: 'complete' },
                    { id: 41, service_id: 141, domain: 'green-energy.net',     client_id: 1274, client_name: 'Ếch Thị Tâm',   records_count: 14, last_sync: '14 phút trước',   failed_jobs: 0, status: 'active',     sync_status: 'complete' },
                    { id: 42, service_id: 142, domain: 'airservice.vn',        client_id: 1275, client_name: 'Gan Văn Uy',    records_count: 7,  last_sync: '10 ngày trước',   failed_jobs: 0, status: 'suspended',  sync_status: 'complete' },
                    { id: 43, service_id: 143, domain: 'dataops-hub.dev',      client_id: 1276, client_name: 'Hán Thị Vui',   records_count: 39, last_sync: 'Vừa xong',        failed_jobs: 0, status: 'active',     sync_status: 'syncing'  },
                    { id: 44, service_id: 144, domain: 'legalpro.com.vn',      client_id: 1277, client_name: 'Ích Văn Xứng',  records_count: 21, last_sync: '33 phút trước',   failed_jobs: 3, status: 'active',     sync_status: 'failed'   },
                ];


                if(this.filters.search) {
                    mockData = mockData.filter(d => d.domain.includes(this.filters.search));
                }
                if(this.filters.status) {
                    mockData = mockData.filter(d => d.status === this.filters.status);
                }
                if(this.filters.errorOnly) {
                    mockData = mockData.filter(d => d.failed_jobs > 0 || d.sync_status === 'failed');
                }

                this.domains = mockData;
                this.loading = false;
            }, 600);
        }
    }));
});
{/literal}
</script>
