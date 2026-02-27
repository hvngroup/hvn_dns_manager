{* record_table.tpl — Partial dùng trong dns_editor.tpl (Alpine x-data="dnsEditor") *}

<div class="mb-3 d-flex justify-content-between align-items-center">
    <div>
        <label for="filterType" class="me-2">Lọc:</label>
        <select id="filterType" class="form-select form-select-sm d-inline-block w-auto" x-model="filterType">
            <option value="all">Tất cả loại</option>
            <option value="A">A</option>
            <option value="AAAA">AAAA</option>
            <option value="CNAME">CNAME</option>
            <option value="MX">MX</option>
            <option value="TXT">TXT</option>
            <option value="SRV">SRV</option>
            <option value="NS">NS</option>
            <option value="CAA">CAA</option>
        </select>
        
        <input type="text" class="form-control form-control-sm d-inline-block w-auto ms-2" placeholder="Tìm kiếm..." x-model="searchQuery">
    </div>
    <a x-bind:href="'index.php?m=hvn_dns_manager&action=record_edit&domain_id=' + domainId" class="btn btn-primary btn-sm">
        <i class="bi bi-plus-lg"></i> Thêm bản ghi
    </a>
</div>

<div class="table-responsive">
    <table class="table table-hover align-middle">
        <thead class="table-light">
            <tr>
                <th>Loại</th>
                <th>Tên</th>
                <th>Giá trị</th>
                <th>TTL</th>
                <th>Trạng thái</th>
                <th class="text-end">Hành động</th>
            </tr>
        </thead>
        <tbody>
            <template x-for="record in filteredRecords" x-bind:key="record.id">
                <tr x-bind:class="record.pending_delete && 'opacity-50'">
                    <td>
                        <span class="badge" x-bind:class="getTypeBadgeClass(record.type)" x-text="record.type"></span>
                        <template x-if="record.is_system">
                            <i class="bi bi-wrench text-muted ms-1" title="Bản ghi hệ thống"></i>
                        </template>
                    </td>
                    <td class="font-monospace" x-text="record.name === '@' ? '{$domain.domain}' : record.name"></td>
                    <td class="font-monospace text-break">
                        <span x-text="record.value.length > 30 ? record.value.substring(0, 30) + '...' : record.value" x-bind:title="record.value"></span>
                        <template x-if="record.type === 'MX' || record.type === 'SRV'">
                            <span class="d-block small text-muted">Priority: <span x-text="record.priority"></span></span>
                        </template>
                        <template x-if="record.type === 'SRV'">
                            <span class="d-block small text-muted">
                                Weight: <span x-text="record.weight"></span> | Port: <span x-text="record.port"></span>
                            </span>
                        </template>
                    </td>
                    <td x-text="formatTTL(record.ttl)"></td>
                    <td>
                        <template x-if="record.sync_status === 'complete'">
                            <span class="text-success"><i class="bi bi-check-circle-fill"></i> Live</span>
                        </template>
                        <template x-if="record.sync_status === 'syncing'">
                            <span class="text-warning"><i class="bi bi-arrow-repeat spin"></i> Syncing</span>
                        </template>
                        <template x-if="record.sync_status === 'pending'">
                            <span class="text-warning"><i class="bi bi-clock"></i> Pending</span>
                        </template>
                        <template x-if="record.sync_status === 'failed'">
                            <div>
                                <span class="text-danger"><i class="bi bi-x-circle-fill"></i> Failed</span>
                                <button class="btn btn-xs btn-outline-danger d-block mt-1 p-0 px-1" x-on:click="retryRecord(record.id)">Retry</button>
                            </div>
                        </template>
                    </td>
                    <td class="text-end">
                        <template x-if="record.is_system || record.is_locked">
                            <i class="bi bi-lock-fill text-muted" title="Bản ghi bị khóa hoặc thuộc hệ thống"></i>
                        </template>
                        <template x-if="!record.is_system && !record.is_locked && !record.pending_delete">
                            <div class="btn-group btn-group-sm">
                                <a x-bind:href="'index.php?m=hvn_dns_manager&action=record_edit&domain_id=' + domainId + '&record_id=' + record.id" class="btn btn-outline-secondary" title="Sửa"><i class="bi bi-pencil"></i></a>
                                <button class="btn btn-outline-danger" x-on:click="deleteRecord(record)" title="Xóa"><i class="bi bi-trash"></i></button>
                            </div>
                        </template>
                        <template x-if="record.pending_delete">
                            <span class="text-muted small fst-italic">Deleting...</span>
                        </template>
                    </td>
                </tr>
            </template>
            <tr x-show="filteredRecords.length === 0">
                <td colspan="6" class="text-center py-4 text-muted">Không tìm thấy bản ghi nào.</td>
            </tr>
        </tbody>
    </table>
</div>

<div class="d-flex justify-content-between align-items-center mt-3">
    <div class="text-muted small">
        Hiển thị <span x-text="filteredRecords.length"></span> / <span x-text="records.length"></span> bản ghi
    </div>
    <nav aria-label="Page navigation" x-show="filteredRecords.length > 10">
        <ul class="pagination pagination-sm mb-0">
            <li class="page-item disabled"><a class="page-link" href="#" aria-label="Previous">&laquo;</a></li>
            <li class="page-item active"><a class="page-link" href="#">1</a></li>
            <li class="page-item"><a class="page-link" href="#">2</a></li>
            <li class="page-item"><a class="page-link" href="#" aria-label="Next">&raquo;</a></li>
        </ul>
    </nav>
</div>
