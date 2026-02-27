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
                            <th class="hvn-ps-4">Domain</th>
                            <th>Khách hàng</th>
                            <th class="hvn-text-center">Records</th>
                            <th>Sync gần nhất</th>
                            <th>Trạng thái</th>
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
        syncingId: null,     // ID domain đang được force re-sync
        filters: { search: '', status: '', server: '', errorOnly: false },

        init() {
            this.fetchDomains();
        },

        resetFilters() {
            this.filters = { search: '', status: '', server: '', errorOnly: false };
            this.currentPage = 1;
            this.fetchDomains();
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
                    { id: 1, service_id: 101, domain: 'example.com', client_id: 1234, client_name: 'Nguyễn A', records_count: 15, last_sync: '2 phút trước', failed_jobs: 0, status: 'active', sync_status: 'complete' },
                    { id: 2, service_id: 102, domain: 'shop.vn', client_id: 1235, client_name: 'Trần B', records_count: 8, last_sync: '5 phút trước', failed_jobs: 0, status: 'active', sync_status: 'complete' },
                    { id: 3, service_id: 103, domain: 'myblog.net', client_id: 1236, client_name: 'Lê C', records_count: 3, last_sync: '1 giờ trước', failed_jobs: 2, status: 'active', sync_status: 'failed' },
                    { id: 4, service_id: 104, domain: 'old-site.org', client_id: 1237, client_name: 'Phạm D', records_count: 22, last_sync: '3 ngày trước', failed_jobs: 0, status: 'suspended', sync_status: 'complete' }
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
