{* record_table.tpl — Inline Add/Edit DNS Records *}

{* ── Toolbar ── *}
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
    <button class="btn btn-primary btn-sm" x-on:click="startAdd()" x-bind:disabled="addingNew">
        <i class="bi bi-plus-lg"></i> Thêm bản ghi
    </button>
</div>

{* ── Bảng Records ── *}
<div class="table-responsive">
    <table class="table table-hover align-middle mb-0">
        <thead class="table-light">
            <tr>
                <th style="width:90px">Loại</th>
                <th style="width:140px">Tên</th>
                <th>Giá trị</th>
                <th style="width:70px">TTL</th>
                <th style="width:100px">Trạng thái</th>
                <th style="width:100px" class="text-end">Hành động</th>
            </tr>
        </thead>
        <tbody>

            {* ══════ ROW THÊM MỚI (đầu bảng) ══════ *}
            <template x-if="addingNew">
                <tr class="hvn-inline-add">
                    <td>
                        <select class="form-select form-select-sm" x-model="editForm.type">
                            <option value="A">A</option>
                            <option value="AAAA">AAAA</option>
                            <option value="CNAME">CNAME</option>
                            <option value="MX">MX</option>
                            <option value="TXT">TXT</option>
                            <option value="SRV">SRV</option>
                            <option value="CAA">CAA</option>
                        </select>
                    </td>
                    <td>
                        <div class="input-group input-group-sm">
                            <input type="text" class="form-control" x-model="editForm.name" placeholder="@">
                            <span class="input-group-text small text-muted" x-text="'.' + domainName" style="font-size:10px; padding:2px 4px"></span>
                        </div>
                    </td>
                    <td>
                        <input type="text" class="form-control form-control-sm font-monospace" x-model="editForm.value" placeholder="Nhập giá trị...">
                        {* Extra fields inline *}
                        <template x-if="needsPriority(editForm.type)">
                            <div class="d-flex gap-1 mt-1">
                                <input type="number" class="form-control form-control-sm" style="width:70px" x-model="editForm.priority" placeholder="Pri" min="0" max="65535">
                                <template x-if="needsSrv(editForm.type)">
                                    <input type="number" class="form-control form-control-sm" style="width:70px" x-model="editForm.weight" placeholder="Weight" min="0">
                                </template>
                                <template x-if="needsSrv(editForm.type)">
                                    <input type="number" class="form-control form-control-sm" style="width:70px" x-model="editForm.port" placeholder="Port" min="1">
                                </template>
                            </div>
                        </template>
                    </td>
                    <td>
                        <select class="form-select form-select-sm" x-model="editForm.ttl">
                            <option value="60">1m</option>
                            <option value="300">5m</option>
                            <option value="1800">30m</option>
                            <option value="3600">1h</option>
                            <option value="14400">4h</option>
                            <option value="86400">24h</option>
                        </select>
                    </td>
                    <td>
                        <span class="badge bg-light text-dark"><i class="bi bi-pencil-square"></i> Mới</span>
                    </td>
                    <td class="text-end">
                        <div class="btn-group btn-group-sm">
                            <button class="btn btn-success" x-on:click="saveEdit()" x-bind:disabled="saving" title="Lưu">
                                <template x-if="!saving"><i class="bi bi-check-lg"></i></template>
                                <template x-if="saving"><span class="spinner-border spinner-border-sm" style="width:12px;height:12px"></span></template>
                            </button>
                            <button class="btn btn-outline-secondary" x-on:click="cancelEdit()" x-bind:disabled="saving" title="Hủy">
                                <i class="bi bi-x-lg"></i>
                            </button>
                        </div>
                    </td>
                </tr>
            </template>

            {* ══════ DANH SÁCH RECORD ══════ *}
            <template x-for="record in filteredRecords" x-bind:key="record.id">
                <tr x-bind:class="(record.pending_delete && 'opacity-50') + (editingId === record.id ? ' hvn-inline-edit' : '')">

                    {* ── Chế độ HIỂN THỊ (không đang edit) ── *}
                    <template x-if="editingId !== record.id">
                        <td>
                            <span class="badge" x-bind:class="getTypeBadgeClass(record.type)" x-text="record.type"></span>
                            <template x-if="record.is_system">
                                <i class="bi bi-wrench text-muted ms-1" title="Bản ghi hệ thống"></i>
                            </template>
                        </td>
                    </template>
                    <template x-if="editingId !== record.id">
                        <td class="font-monospace" x-text="record.name === '@' ? domainName : record.name"></td>
                    </template>
                    <template x-if="editingId !== record.id">
                        <td class="font-monospace text-break">
                            <span x-text="record.value.length > 40 ? record.value.substring(0, 40) + '...' : record.value" x-bind:title="record.value"></span>
                            <template x-if="record.type === 'MX' || record.type === 'SRV'">
                                <span class="d-block small text-muted">Priority: <span x-text="record.priority"></span></span>
                            </template>
                            <template x-if="record.type === 'SRV'">
                                <span class="d-block small text-muted">W: <span x-text="record.weight"></span> | P: <span x-text="record.port"></span></span>
                            </template>
                        </td>
                    </template>
                    <template x-if="editingId !== record.id">
                        <td x-text="formatTTL(record.ttl)"></td>
                    </template>
                    <template x-if="editingId !== record.id">
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
                    </template>
                    <template x-if="editingId !== record.id">
                        <td class="text-end">
                            <template x-if="record.is_system || record.is_locked">
                                <i class="bi bi-lock-fill text-muted" title="Bản ghi hệ thống / bị khóa"></i>
                            </template>
                            <template x-if="!record.is_system && !record.is_locked && !record.pending_delete">
                                <div class="btn-group btn-group-sm">
                                    <button class="btn btn-outline-secondary" x-on:click="startEdit(record)" title="Sửa"><i class="bi bi-pencil"></i></button>
                                    <button class="btn btn-outline-danger" x-on:click="deleteRecord(record)" title="Xóa"><i class="bi bi-trash"></i></button>
                                </div>
                            </template>
                            <template x-if="record.pending_delete">
                                <span class="text-muted small fst-italic">Đang xóa...</span>
                            </template>
                        </td>
                    </template>

                    {* ── Chế độ EDIT INLINE ── *}
                    <template x-if="editingId === record.id">
                        <td>
                            <span class="badge" x-bind:class="getTypeBadgeClass(record.type)" x-text="record.type"></span>
                        </td>
                    </template>
                    <template x-if="editingId === record.id">
                        <td>
                            <input type="text" class="form-control form-control-sm font-monospace" x-model="editForm.name">
                        </td>
                    </template>
                    <template x-if="editingId === record.id">
                        <td>
                            <input type="text" class="form-control form-control-sm font-monospace" x-model="editForm.value">
                            <template x-if="needsPriority(editForm.type)">
                                <div class="d-flex gap-1 mt-1">
                                    <input type="number" class="form-control form-control-sm" style="width:70px" x-model="editForm.priority" placeholder="Pri" min="0">
                                    <template x-if="needsSrv(editForm.type)">
                                        <input type="number" class="form-control form-control-sm" style="width:70px" x-model="editForm.weight" placeholder="Weight">
                                    </template>
                                    <template x-if="needsSrv(editForm.type)">
                                        <input type="number" class="form-control form-control-sm" style="width:70px" x-model="editForm.port" placeholder="Port">
                                    </template>
                                </div>
                            </template>
                        </td>
                    </template>
                    <template x-if="editingId === record.id">
                        <td>
                            <select class="form-select form-select-sm" x-model="editForm.ttl">
                                <option value="60">1m</option>
                                <option value="300">5m</option>
                                <option value="1800">30m</option>
                                <option value="3600">1h</option>
                                <option value="14400">4h</option>
                                <option value="86400">24h</option>
                            </select>
                        </td>
                    </template>
                    <template x-if="editingId === record.id">
                        <td>
                            <span class="badge bg-warning text-dark"><i class="bi bi-pencil-square"></i> Đang sửa</span>
                        </td>
                    </template>
                    <template x-if="editingId === record.id">
                        <td class="text-end">
                            <div class="btn-group btn-group-sm">
                                <button class="btn btn-success" x-on:click="saveEdit()" x-bind:disabled="saving" title="Lưu">
                                    <template x-if="!saving"><i class="bi bi-check-lg"></i></template>
                                    <template x-if="saving"><span class="spinner-border spinner-border-sm" style="width:12px;height:12px"></span></template>
                                </button>
                                <button class="btn btn-outline-secondary" x-on:click="cancelEdit()" x-bind:disabled="saving" title="Hủy">
                                    <i class="bi bi-x-lg"></i>
                                </button>
                            </div>
                        </td>
                    </template>

                </tr>
            </template>

            {* ── Empty state ── *}
            <tr x-show="filteredRecords.length === 0 && !addingNew">
                <td colspan="6" class="text-center py-4 text-muted">Không tìm thấy bản ghi nào.</td>
            </tr>
        </tbody>
    </table>
</div>

{* ── Footer ── *}
<div class="d-flex justify-content-between align-items-center mt-3">
    <div class="text-muted small">
        Hiển thị <span x-text="filteredRecords.length"></span> / <span x-text="records.length"></span> bản ghi
    </div>
</div>
