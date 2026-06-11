<div class="mj-dns-admin mj-domains" x-data="domainList()">
    <div class="mj-d-flex mj-justify-content-between mj-align-items-center mj-mb-4">
        <h2><i class="bi bi-globe"></i> Quản lý Domain</h2>
    </div>

    <!-- Toolbar Filters -->
    <div class="mj-card mj-shadow-sm mj-border-0 mj-mb-4 mj-bg-light">
        <div class="mj-card-body mj-py-3">
            <div class="mj-row g-2 mj-align-items-center">
                <div class="mj-col-md-4">
                    <div class="mj-input-group">
                        <span class="mj-input-group-text mj-bg-white"><i class="bi bi-search"></i></span>
                        <input type="text" class="mj-form-control" placeholder="Tìm kiếm tên miền..." x-model="filters.search" @input.debounce.500ms="fetchDomains()">
                    </div>
                </div>
                <div class="mj-col-md-2">
                    <select class="mj-form-select" x-model="filters.status" @change="fetchDomains()">
                        <option value="">Tất cả trạng thái</option>
                        <option value="active">🟢 Active</option>
                        <option value="pending">🟡 Pending</option>
                        <option value="suspended">🟠 Suspended</option>
                        <option value="terminated">🔴 Terminated</option>
                    </select>
                </div>
                <div class="mj-col-md-2">
                    <select class="mj-form-select" x-model="filters.server" @change="fetchDomains()">
                        <option value="">Tất cả Server</option>
                    </select>
                </div>
                <div class="mj-col-md-2 mj-d-flex mj-align-items-center">
                    <div class="mj-form-check mj-form-switch mj-mb-0">
                        <input class="mj-form-check-input" type="checkbox" id="errorOnly" x-model="filters.errorOnly" @change="fetchDomains()">
                        <label class="mj-form-check-label mj-text-danger" for="errorOnly">Chỉ domain có lỗi</label>
                    </div>
                </div>
                <div class="mj-col-md-2 mj-text-end mj-d-flex mj-justify-content-end mj-align-items-center mj-gap-1">
                    <select class="mj-form-select" style="width:auto;" x-model="perPage" @change="currentPage=1; fetchDomains()">
                        <option value="25">25/trang</option>
                        <option value="50" selected>50/trang</option>
                        <option value="100">100/trang</option>
                    </select>
                    <button class="mj-btn mj-btn-sm mj-btn-outline-secondary" @click="resetFilters()"><i class="bi bi-arrow-counterclockwise"></i></button>
                </div>
            </div>
        </div>
    </div>

    <!-- Domain Table -->
    <div class="mj-card mj-shadow-sm mj-border-0">
        <div class="mj-card-body mj-p-0">
            <div class="mj-table-responsive" style="overflow: visible;">
                <table class="mj-table mj-table-hover mj-align-middle mj-mb-0">
                    <thead class="mj-table-light">
                        <tr>
                            <th class="mj-ps-4" style="cursor:pointer;white-space:nowrap;" @click="sortBy('domain')">
                                Domain
                                <span class="mj-text-muted" style="font-size:.7rem;">
                                    <span x-text="sortCol === 'domain' ? (sortDir === 'asc' ? '&#9650;' : '&#9660;') : '&#8597;'"></span>
                                </span>
                            </th>
                            <th style="cursor:pointer;white-space:nowrap;" @click="sortBy('client_name')">
                                Khách hàng
                                <span class="mj-text-muted" style="font-size:.7rem;">
                                    <span x-text="sortCol === 'client_name' ? (sortDir === 'asc' ? '&#9650;' : '&#9660;') : '&#8597;'"></span>
                                </span>
                            </th>
                            <th class="mj-text-center" style="cursor:pointer;white-space:nowrap;" @click="sortBy('records_count')">
                                Records
                                <span class="mj-text-muted" style="font-size:.7rem;">
                                    <span x-text="sortCol === 'records_count' ? (sortDir === 'asc' ? '&#9650;' : '&#9660;') : '&#8597;'"></span>
                                </span>
                            </th>
                            <th style="cursor:pointer;white-space:nowrap;" @click="sortBy('failed_jobs')">
                                Sync gần nhất
                                <span class="mj-text-muted" style="font-size:.7rem;">
                                    <span x-text="sortCol === 'failed_jobs' ? (sortDir === 'asc' ? '&#9650;' : '&#9660;') : '&#8597;'"></span>
                                </span>
                            </th>
                            <th style="cursor:pointer;white-space:nowrap;" @click="sortBy('status')">
                                Trạng thái
                                <span class="mj-text-muted" style="font-size:.7rem;">
                                    <span x-text="sortCol === 'status' ? (sortDir === 'asc' ? '&#9650;' : '&#9660;') : '&#8597;'"></span>
                                </span>
                            </th>
                            <th class="mj-text-end mj-pe-4">Hành động</th>
                        </tr>
                    </thead>
                    <tbody>
                        <!-- Loading State -->
                        <template x-if="loading">
                            <tr>
                                <td colspan="6" class="mj-text-center py-5 mj-text-muted">
                                    <div class="mj-spinner-border mj-text-primary mj-mb-2" role="status"></div>
                                    <br>Đang tải dữ liệu...
                                </td>
                            </tr>
                        </template>

                        <!-- Empty State -->
                        <template x-if="!loading && domains.length === 0">
                            <tr>
                                <td colspan="6" class="mj-text-center py-5 mj-text-muted">
                                    <i class="bi bi-inbox fs-1 mj-d-block mj-mb-3"></i>
                                    Không tìm thấy dữ liệu phù hợp với bộ lọc hiện tại.
                                </td>
                            </tr>
                        </template>

                        <!-- Data Rows -->
                        <template x-if="!loading && domains.length > 0">
                            <template x-for="domain in domains" :key="domain.id">
                                <tr :style="syncingId === domain.id ? 'background: rgba(13,110,253,0.05);' : ''">
                                    <td class="mj-ps-4 font-monospace mj-fw-bold">
                                        <a :href="'?module=mj_dns_manager&action=admin_dns_editor&domain_id=' + domain.id" class="text-decoration-none">
                                            <span x-text="domain.domain"></span>
                                        </a>
                                    </td>
                                    <td>
                                        <a :href="'clientssummary.php?userid=' + domain.client_id" class="text-decoration-none" target="_blank">
                                            <span x-text="domain.client_name"></span> <span class="mj-text-muted small">#<span x-text="domain.client_id"></span></span>
                                        </a>
                                    </td>
                                    <td class="mj-text-center" x-text="domain.records_count"></td>
                                    <td>
                                        <div x-text="domain.last_sync"></div>
                                        <template x-if="domain.failed_jobs > 0">
                                            <div class="mj-text-danger small"><i class="bi bi-exclamation-triangle"></i> <span x-text="domain.failed_jobs"></span> fail</div>
                                        </template>
                                    </td>
                                    <td>
                                        <!-- Đang force re-sync: hiện spinner -->
                                        <template x-if="syncingId === domain.id">
                                            <span class="mj-badge" style="background:#0d6efd;color:#fff;">
                                                <span class="mj-spinner-border mj-spinner-border-sm" style="width:.7rem;height:.7rem;" role="status"></span>
                                                Re-syncing...
                                            </span>
                                        </template>
                                        <!-- Trạng thái bình thường -->
                                        <template x-if="syncingId !== domain.id && domain.status === 'active'">
                                            <span>
                                                <template x-if="domain.sync_status === 'complete'">
                                                    <span class="mj-badge mj-bg-success">&#x1F7E2; Active</span>
                                                </template>
                                                <template x-if="domain.sync_status === 'syncing'">
                                                    <span class="mj-badge mj-bg-info"><span class="mj-spinner-border mj-spinner-border-sm" role="status" style="width:.75rem;height:.75rem;"></span> Syncing</span>
                                                </template>
                                                <template x-if="domain.sync_status === 'failed'">
                                                    <span class="mj-badge mj-bg-warning mj-text-dark">&#x1F7E1; Sync Failed</span>
                                                </template>
                                            </span>
                                        </template>
                                        <template x-if="syncingId !== domain.id && domain.status !== 'active'">
                                            <span class="mj-badge mj-bg-danger" x-text="domain.status"></span>
                                        </template>
                                    </td>
                                    <td class="mj-text-end mj-pe-4" style="white-space: nowrap;">
                                        <a :href="'{$modulelink}&action=admin_dns_editor&domain_id=' + domain.id"
                                           class="mj-btn mj-btn-sm mj-btn-blue mj-me-1">
                                            <i class="bi bi-sliders"></i> DNS
                                        </a>
                                        <div class="mj-dropdown mj-d-inline-block" style="position: relative;">
                                            <button class="mj-btn mj-btn-sm mj-btn-outline-secondary mj-dropdown-toggle"
                                                    type="button"
                                                    :disabled="syncingId === domain.id"
                                                    @click.stop="openDropdown($event)">
                                                <i class="bi bi-three-dots-vertical"></i>
                                            </button>
                                            <ul class="mj-dropdown-menu mj-dropdown-menu-end">
                                                <li><a class="mj-dropdown-item" :href="'{$modulelink}&action=admin_dns_editor&domain_id=' + domain.id"><i class="bi bi-sliders mj-text-primary"></i> S&#x1EED;a DNS Records</a></li>
                                                <li><a class="mj-dropdown-item" href="#" @click.prevent="forceResync(domain)"><i class="bi bi-arrow-repeat mj-text-warning"></i> Force Re-sync</a></li>
                                                <li><a class="mj-dropdown-item" href="#"><i class="bi bi-journal-text"></i> Xem Audit Trail</a></li>
                                                <li><a class="mj-dropdown-item" href="#" @click.prevent="checkSsl(domain)">
                                                    <i class="bi bi-shield-lock mj-text-info"></i> Check SSL
                                                </a></li>
                                                <li><a class="mj-dropdown-item" href="#" @click.prevent="checkDrift(domain)">
                                                    <i class="bi bi-arrow-left-right mj-text-warning"></i> Check Drift
                                                </a></li>
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
        <div class="mj-card-footer mj-bg-white mj-py-3 mj-d-flex mj-justify-content-between mj-align-items-center">
            <div class="mj-text-muted mj-small">
                Hiển thị <span x-text="domains.length"></span> / <span x-text="totalRecords"></span> domain
                &nbsp;&bull;&nbsp; Trang <span x-text="currentPage"></span>/<span x-text="totalPages"></span>
            </div>
            <nav aria-label="Page navigation" x-show="totalPages > 1">
                <ul class="mj-pagination mj-pagination-sm mj-mb-0">
                    <li class="mj-page-item" :class="{literal}{'mj-disabled': currentPage === 1}{/literal}">
                        <a class="mj-page-link" href="#" @click.prevent="goToPage(currentPage - 1)">&laquo;</a>
                    </li>
                    <li class="mj-page-item mj-active"><a class="mj-page-link" href="#" x-text="currentPage"></a></li>
                    <li class="mj-page-item" :class="{literal}{'mj-disabled': currentPage === totalPages}{/literal}">
                        <a class="mj-page-link" href="#" @click.prevent="goToPage(currentPage + 1)">&raquo;</a>
                    </li>
                </ul>
            </nav>
        </div>
    </div>
</div>

<script>
    var MJDNS_DOMAINS_INIT = {$domainsJson};
    var MJDNS_TOTAL_DOMAINS = {$totalDomains};
    var MJDNS_TOTAL_PAGES = {$totalPages};
    var MJDNS_CURRENT_PAGE = {$currentPage};
</script>
{* JS logic moved to assets/js/mj-dns.js (MJ standard §8) *}
