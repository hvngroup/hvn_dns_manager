<div class="hvn-dns-admin hvn-domains" x-data="domainList()">
    <div class="hvn-d-flex hvn-justify-content-between hvn-align-items-center hvn-mb-4">
        <h2><i class="bi bi-globe"></i> Quản lý Domain</h2>
    </div>

    <!-- Toolbar Filters -->
    <div class="hvn-card hvn-shadow-sm hvn-border-0 hvn-mb-4 hvn-bg-light">
        <div class="hvn-card-body hvn-py-3">
            <div class="hvn-row g-2 hvn-align-items-center">
                <div class="hvn-col-md-4">
                    <div class="input-group">
                        <span class="input-group-text hvn-bg-white"><i class="bi bi-search"></i></span>
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
                    <div class="form-check form-switch hvn-mb-0">
                        <input class="form-check-input" type="checkbox" id="errorOnly" x-model="filters.errorOnly" @change="fetchDomains()">
                        <label class="form-check-label hvn-text-danger" for="errorOnly">Chỉ domain có lỗi</label>
                    </div>
                </div>
                <div class="hvn-col-md-2 hvn-text-end">
                    <button class="hvn-btn btn-outline-secondary" @click="resetFilters()"><i class="bi bi-arrow-counterclockwise"></i> Reset</button>
                </div>
            </div>
        </div>
    </div>

    <!-- Domain Table -->
    <div class="hvn-card hvn-shadow-sm hvn-border-0">
        <div class="hvn-card-body hvn-p-0">
            <div class="table-responsive">
                <table class="table table-hover align-middle hvn-mb-0">
                    <thead class="table-light">
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
                                <tr>
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
                                        <template x-if="domain.status === 'active'">
                                            <template x-if="domain.sync_status === 'complete'">
                                                <span class="hvn-badge hvn-bg-success">🟢 Active</span>
                                            </template>
                                            <template x-if="domain.sync_status === 'syncing'">
                                                <span class="hvn-badge hvn-bg-info"><span class="hvn-spinner-border hvn-spinner-border-sm" role="status" aria-hidden="true" style="width: 0.75rem; height: 0.75rem;"></span> Syncing</span>
                                            </template>
                                            <template x-if="domain.sync_status === 'failed'">
                                                <span class="hvn-badge hvn-bg-warning hvn-text-dark">🟡 Sync Failed</span>
                                            </template>
                                        </template>
                                        <template x-if="domain.status !== 'active'">
                                            <span class="hvn-badge hvn-bg-danger" x-text="'🔴 ' + domain.status"></span>
                                        </template>
                                    </td>
                                    <td class="hvn-text-end hvn-pe-4">
                                        <a :href="'?module=hvn_dns_manager&action=admin_dns_editor&domain_id=' + domain.id" class="hvn-btn btn-sm hvn-btn-outline-primary">
                                            <i class="bi bi-sliders"></i> DNS
                                        </a>
                                        <div class="dropdown d-inline-block">
                                            <button class="hvn-btn btn-sm btn-outline-secondary dropdown-toggle" type="button" data-bs-toggle="dropdown">
                                                <i class="bi bi-three-dots-vertical"></i>
                                            </button>
                                            <ul class="dropdown-menu dropdown-menu-end">
                                                <li><a class="dropdown-item" href="#"><i class="bi bi-arrow-repeat hvn-text-warning"></i> Force Re-sync</a></li>
                                                <li><a class="dropdown-item" href="#"><i class="bi bi-journal-text"></i> Xem Audit Trail</a></li>
                                                <li><hr class="dropdown-divider"></li>
                                                <li><a class="dropdown-item" :href="'clientsservices.php?userid=' + domain.client_id + '&id=' + domain.service_id"><i class="bi bi-box"></i> Quản lý Service WHMCS</a></li>
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
            <div class="hvn-text-muted small">
                Hiển thị <span x-text="domains.length"></span> / <span x-text="totalRecords"></span> domain
            </div>
            <nav aria-label="Page navigation" x-show="totalPages > 1">
                <ul class="pagination pagination-sm hvn-mb-0">
                    <li class="page-item" :class="{ 'disabled': currentPage === 1}">
                        <a class="page-link" href="#" @click.prevent="goToPage(currentPage - 1)">&laquo;</a>
                    </li>
                    <li class="page-item active"><a class="page-link" href="#" x-text="currentPage"></a></li>
                    <li class="page-item" :class="{ 'disabled': currentPage === totalPages}">
                        <a class="page-link" href="#" @click.prevent="goToPage(currentPage + 1)">&raquo;</a>
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
        totalPages: 35,
        currentPage: 1,
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
