{* record_table.tpl — Inline Add/Edit DNS Records *}

{* ── Toolbar ── *}
<div style="display:flex;align-items:center;justify-content:space-between;gap:8px;margin-bottom:14px;flex-wrap:wrap;">

    {* Nhóm trái: Lọc + Tìm kiếm + Sync — tất cả nằm 1 hàng ngang *}
    <div style="display:flex;align-items:center;gap:8px;flex-wrap:nowrap;">

        <span style="font-size:13px;font-weight:500;color:#6c757d;white-space:nowrap;">Lọc:</span>

        <select id="filterType" x-model="filterType"
            style="width:130px;height:34px;padding:0 28px 0 10px;font-size:13px;font-family:inherit;color:#495057;background-color:#fff;border:1px solid #dee2e6;border-radius:6px;appearance:none;background-image:url('data:image/svg+xml,%3Csvg xmlns=%27http://www.w3.org/2000/svg%27 width=%2710%27 height=%2710%27 viewBox=%270 0 24 24%27 fill=%27none%27 stroke=%27%2364748b%27 stroke-width=%272%27 stroke-linecap=%27round%27 stroke-linejoin=%27round%27%3E%3Cpolyline points=%276 9 12 15 18 9%27%3E%3C/polyline%3E%3C/svg%3E');background-repeat:no-repeat;background-position:right 8px center;cursor:pointer;transition:border-color .18s;box-sizing:border-box;flex-shrink:0;">
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

        <input type="text" x-model="searchQuery" placeholder="Tìm kiếm..."
            style="width:180px;height:34px;padding:0 10px;font-size:13px;font-family:inherit;color:#495057;background:#fff;border:1px solid #dee2e6;border-radius:6px;transition:border-color .18s,box-shadow .18s;outline:none;box-sizing:border-box;flex-shrink:0;"
            onfocus="this.style.borderColor='#ea4544';this.style.boxShadow='0 0 0 3px rgba(234,69,68,.12)';"
            onblur="this.style.borderColor='#dee2e6';this.style.boxShadow='none';">
        {*
        <button x-on:click="syncZone()" x-bind:disabled="isSyncingZone" title="Đồng bộ từ máy chủ"
            style="width:34px;height:34px;padding:0;display:inline-flex;align-items:center;justify-content:center;background:#fff;border:1px solid #dee2e6;border-radius:6px;color:#6c757d;cursor:pointer;transition:all .18s;font-size:14px;box-sizing:border-box;flex-shrink:0;"
            onmouseover="this.style.borderColor='#adb5bd';this.style.color='#343a40';"
            onmouseout="this.style.borderColor='#dee2e6';this.style.color='#6c757d';">
            <template x-if="!isSyncingZone"><i class="bi bi-arrow-clockwise"></i></template>
            <template x-if="isSyncingZone"><i class="bi bi-arrow-clockwise cl-spin-icon"></i></template>
        </button>
        *}
    </div>

    <button x-on:click="startAdd()" x-bind:disabled="addingNew || isSyncingZone"
        style="height:34px;padding:0 16px;display:inline-flex;align-items:center;gap:6px;font-size:13px;font-weight:600;font-family:inherit;background:#ea4544;color:#fff;border:none;border-radius:6px;cursor:pointer;transition:all .18s;white-space:nowrap;box-shadow:0 2px 6px rgba(234,69,68,.25);box-sizing:border-box;flex-shrink:0;"
        onmouseover="this.style.background='#d32f2f';this.style.boxShadow='0 4px 12px rgba(234,69,68,.35)';"
        onmouseout="this.style.background='#ea4544';this.style.boxShadow='0 2px 6px rgba(234,69,68,.25)';">
        <i class="bi bi-plus-lg"></i> Thêm bản ghi
    </button>

</div>

{* ── Bảng Records ── *}
<div class="table-responsive">
    <table class="table table-hover align-middle mb-0" style="font-size:14px;font-family:'Inter',system-ui,-apple-system,sans-serif;">
        <thead>
            <tr style="background:#f8f9fa;">
                <th style="width:90px;padding:10px 8px;font-size:13px;font-weight:600;color:#5E636E;border-bottom:1px solid #dee2e6;border-top:none;white-space:nowrap;">Loại</th>
                <th style="width:140px;padding:10px 8px;font-size:13px;font-weight:600;color:#5E636E;border-bottom:1px solid #dee2e6;border-top:none;white-space:nowrap;">Tên</th>
                <th style="padding:10px 8px;font-size:13px;font-weight:600;color:#5E636E;border-bottom:1px solid #dee2e6;border-top:none;">Giá trị</th>
                <th style="width:70px;padding:10px 8px;font-size:13px;font-weight:600;color:#5E636E;border-bottom:1px solid #dee2e6;border-top:none;white-space:nowrap;">TTL</th>
                <th style="width:110px;padding:10px 8px;font-size:13px;font-weight:600;color:#5E636E;border-bottom:1px solid #dee2e6;border-top:none;white-space:nowrap;">Trạng thái</th>
                <th style="width:110px;padding:10px 8px;font-size:13px;font-weight:600;color:#5E636E;border-bottom:1px solid #dee2e6;border-top:none;text-align:right;">Hành động</th>
            </tr>
        </thead>
        <tbody>

            {* ══════ ROW THÊM MỚI (đầu bảng) ══════ *}
            <template x-if="addingNew">
                <tr class="mj-inline-add">
                    <td style="padding:10px 8px;">
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
                    <td style="padding:10px 8px; ">
                        <div class="input-group input-group-sm">
                            <input type="text" class="form-control" x-model="editForm.name" placeholder="@">
                            <span class="input-group-text small text-muted" x-text="'.' + domainName" style="font-size:10px;padding:2px 4px;"></span>
                        </div>
                    </td>
                    <td style="padding:10px 8px;">
                        <input type="text" class="form-control form-control-sm" x-model="editForm.value" placeholder="Nhập giá trị...">
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
                    <td style="padding:10px 8px;">
                        <select class="form-select form-select-sm" x-model="editForm.ttl"
                            style="height:36px;padding-top:0;padding-bottom:0;font-size:13px;">
                            <option value="60">1m</option>
                            <option value="300">5m</option>
                            <option value="1800">30m</option>
                            <option value="3600">1h</option>
                            <option value="14400">4h</option>
                            <option value="86400">24h</option>
                        </select>
                    </td>
                    <td style="padding:10px 8px;">
                        <span class="badge bg-light text-dark"><i class="bi bi-pencil-square"></i> Mới</span>
                    </td>
                    <td style="padding:10px 8px;text-align:right;">
                        <div style="display:inline-flex;align-items:center;gap:6px;">
                            <button x-on:click="saveEdit()" x-bind:disabled="saving" title="Lưu"
                                style="width:30px;height:30px;padding:0;display:inline-flex;align-items:center;justify-content:center;background:#198754;border:none;border-radius:6px;color:#fff;cursor:pointer;font-size:13px;transition:all .18s;"
                                onmouseover="this.style.background='#157347';"
                                onmouseout="this.style.background='#198754';">
                                <template x-if="!saving"><i class="bi bi-check-lg"></i></template>
                                <template x-if="saving"><span class="spinner-border spinner-border-sm" style="width:12px;height:12px;"></span></template>
                            </button>
                            <button x-on:click="cancelEdit()" x-bind:disabled="saving" title="Hủy"
                                style="width:30px;height:30px;padding:0;display:inline-flex;align-items:center;justify-content:center;background:#fff;border:1px solid #dee2e6;border-radius:6px;color:#6c757d;cursor:pointer;font-size:13px;transition:all .18s;"
                                onmouseover="this.style.borderColor='#adb5bd';this.style.color='#343a40';"
                                onmouseout="this.style.borderColor='#dee2e6';this.style.color='#6c757d';">
                                <i class="bi bi-x-lg"></i>
                            </button>
                        </div>
                    </td>
                </tr>
            </template>

            {* ══════ DANH SÁCH RECORD ══════ *}
            <template x-for="record in filteredRecords" x-bind:key="record.id">
                <tr x-bind:class="(record.pending_delete ? 'opacity-50' : '') + (editingId === record.id ? ' mj-inline-edit' : '')">

                    {* ── Chế độ HIỂN THỊ ── *}
                    <template x-if="editingId !== record.id">
                        <td style="padding:10px 8px;">
                            <span class="badge" x-bind:class="getTypeBadgeClass(record.type)" x-text="record.type"></span>
                            <template x-if="record.is_system">
                                <i class="bi bi-wrench text-muted ms-1" title="Bản ghi hệ thống"></i>
                            </template>
                        </td>
                    </template>

                    {* Cột Tên — bỏ font-monospace, dùng sans-serif 14px *}
                    <template x-if="editingId !== record.id">
                        <td style="padding:10px 8px;font-size:14px;font-family:'Inter',system-ui,-apple-system,sans-serif;color:#1e293b;" x-text="record.name === '@' ? domainName : record.name"></td>
                    </template>

                    {* Cột Giá trị — bỏ font-monospace, dùng sans-serif 14px *}
                    <template x-if="editingId !== record.id">
                        <td class="text-break" style="padding:10px 8px;font-size:14px;font-family:'Inter',system-ui,-apple-system,sans-serif;color:#1e293b;">
                            <span x-text="record.value.length > 40 ? record.value.substring(0, 40) + '...' : record.value" x-bind:title="record.value"></span>
                            <template x-if="record.type === 'MX' || record.type === 'SRV'">
                                <span class="d-block small text-muted" style="font-size:12px;">Priority: <span x-text="record.priority"></span></span>
                            </template>
                            <template x-if="record.type === 'SRV'">
                                <span class="d-block small text-muted" style="font-size:12px;">W: <span x-text="record.weight"></span> | P: <span x-text="record.port"></span></span>
                            </template>
                        </td>
                    </template>

                    <template x-if="editingId !== record.id">
                        <td style="padding:10px 8px;font-size:14px;color:#495057;" x-text="formatTTL(record.ttl)"></td>
                    </template>
                    <template x-if="editingId !== record.id">
                        <td style="padding:10px 8px;font-size:14px;">
                            <template x-if="record.sync_status === 'complete'">
                                <span style="color:#198754;font-size:13px;"><i class="bi bi-check-circle-fill"></i> Live</span>
                            </template>
                            <template x-if="record.sync_status === 'syncing'">
                                <span style="color:#f59e0b;font-size:13px;"><i class="bi bi-arrow-repeat spin"></i> Syncing</span>
                            </template>
                            <template x-if="record.sync_status === 'pending'">
                                <span style="color:#f59e0b;font-size:13px;"><i class="bi bi-clock"></i> Pending</span>
                            </template>
                            <template x-if="record.sync_status === 'failed'">
                                <div>
                                    <span style="color:#dc2626;font-size:13px;"><i class="bi bi-x-circle-fill"></i> Failed</span>
                                    <button class="btn btn-xs btn-outline-danger d-block mt-1 p-0 px-1" x-on:click="retryRecord(record.id)">Retry</button>
                                </div>
                            </template>
                        </td>
                    </template>
                    <template x-if="editingId !== record.id">
                        <td style="padding:10px 8px;text-align:right;">
                            <template x-if="record.is_system || record.is_locked">
                                <i class="bi bi-lock-fill text-muted" title="Bản ghi hệ thống / bị khóa"></i>
                            </template>
                            <template x-if="!record.is_system && !record.is_locked && !record.pending_delete">
                                <div style="display:inline-flex;align-items:center;gap:6px;">
                                    <button x-on:click="startEdit(record)" title="Sửa"
                                        style="width:30px;height:30px;padding:0;display:inline-flex;align-items:center;justify-content:center;background:#fff;border:1px solid #dee2e6;border-radius:6px;color:#6c757d;cursor:pointer;font-size:13px;transition:all .18s;"
                                        onmouseover="this.style.borderColor='#adb5bd';this.style.color='#343a40';this.style.background='#f8f9fa';"
                                        onmouseout="this.style.borderColor='#dee2e6';this.style.color='#6c757d';this.style.background='#fff';">
                                        <i class="bi bi-pencil"></i>
                                    </button>
                                    <button x-on:click="deleteRecord(record)" title="Xóa"
                                        style="width:30px;height:30px;padding:0;display:inline-flex;align-items:center;justify-content:center;background:#fff;border:1px solid #fecaca;border-radius:6px;color:#dc2626;cursor:pointer;font-size:13px;transition:all .18s;"
                                        onmouseover="this.style.background='#fef2f2';this.style.borderColor='#fca5a5';"
                                        onmouseout="this.style.background='#fff';this.style.borderColor='#fecaca';">
                                        <i class="bi bi-trash"></i>
                                    </button>
                                </div>
                            </template>
                            <template x-if="record.pending_delete">
                                <span style="color:#6c757d;font-size:12px;font-style:italic;">Đang xóa...</span>
                            </template>
                        </td>
                    </template>

                    {* ── Chế độ EDIT INLINE ── *}
                    <template x-if="editingId === record.id">
                        <td style="padding:10px 8px;">
                            <span class="badge" x-bind:class="getTypeBadgeClass(record.type)" x-text="record.type"></span>
                        </td>
                    </template>
                    <template x-if="editingId === record.id">
                        <td style="padding:10px 8px;">
                            <input type="text" class="form-control form-control-sm" x-model="editForm.name">
                        </td>
                    </template>
                    <template x-if="editingId === record.id">
                        <td style="padding:10px 8px;">
                            <input type="text" class="form-control form-control-sm" x-model="editForm.value">
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
                        <td style="padding:10px 8px;">
                            <select class="form-select form-select-sm" x-model="editForm.ttl"
                                style="height:36px;padding-top:0;padding-bottom:0;font-size:13px;">
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
                        <td style="padding:10px 8px;">
                            <span class="badge bg-warning text-dark"><i class="bi bi-pencil-square"></i> Đang sửa</span>
                        </td>
                    </template>
                    <template x-if="editingId === record.id">
                        <td style="padding:10px 8px;text-align:right;">
                            <div style="display:inline-flex;align-items:center;gap:6px;">
                                <button x-on:click="saveEdit()" x-bind:disabled="saving" title="Lưu"
                                    style="width:30px;height:30px;padding:0;display:inline-flex;align-items:center;justify-content:center;background:#198754;border:none;border-radius:6px;color:#fff;cursor:pointer;font-size:13px;transition:all .18s;"
                                    onmouseover="this.style.background='#157347';"
                                    onmouseout="this.style.background='#198754';">
                                    <template x-if="!saving"><i class="bi bi-check-lg"></i></template>
                                    <template x-if="saving"><span class="spinner-border spinner-border-sm" style="width:12px;height:12px;"></span></template>
                                </button>
                                <button x-on:click="cancelEdit()" x-bind:disabled="saving" title="Hủy"
                                    style="width:30px;height:30px;padding:0;display:inline-flex;align-items:center;justify-content:center;background:#fff;border:1px solid #dee2e6;border-radius:6px;color:#6c757d;cursor:pointer;font-size:13px;transition:all .18s;"
                                    onmouseover="this.style.borderColor='#adb5bd';this.style.color='#343a40';"
                                    onmouseout="this.style.borderColor='#dee2e6';this.style.color='#6c757d';">
                                    <i class="bi bi-x-lg"></i>
                                </button>
                            </div>
                        </td>
                    </template>

                </tr>
            </template>

            {* ── Empty state ── *}
            <tr x-show="filteredRecords.length === 0 && !addingNew">
                <td colspan="6" style="text-align:center;padding:32px 8px;color:#6c757d;font-size:14px;">Không tìm thấy bản ghi nào.</td>
            </tr>
        </tbody>
    </table>
</div>

{* ── Footer ── *}
<div style="display:flex;justify-content:space-between;align-items:center;margin-top:12px;">
    <div style="font-size:13px;color:#6c757d;">
        Hiển thị <span x-text="filteredRecords.length"></span> / <span x-text="records.length"></span> bản ghi
    </div>
</div>
