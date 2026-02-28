<!-- Load Template Dialog -->
<div class="card border-secondary mb-4">
    <div class="card-header bg-light">
        <h5 class="mb-0">Nạp mẫu DNS (Templates)</h5>
    </div>
    <div class="card-body">
        <p>Chọn một mẫu DNS dựng sẵn để áp dụng nhanh cho tên miền <strong class="text-primary" x-text="domainName"></strong>:</p>
        
        <div class="mb-3">
            <template x-for="(tpl, index) in templates" x-bind:key="tpl.id">
                <div class="form-check mb-3 p-3 border rounded d-flex justify-content-between align-items-center" x-bind:class="{ 'bg-light': index === 0 }">
                    <div>
                        <input class="form-check-input ms-1 mt-2" type="radio" name="template_id" x-bind:id="'tpl_' + tpl.id" x-bind:value="tpl.id" x-bind:checked="index === 0">
                        <label class="form-check-label ms-2 d-block w-100" x-bind:for="'tpl_' + tpl.id">
                            <strong x-text="tpl.name"></strong>
                            <span class="badge bg-secondary ms-2" x-text="tpl.records_count + ' bản ghi'"></span>
                            <div class="text-muted small mt-1" x-text="tpl.description"></div>
                            <template x-if="tpl.is_system">
                                <span class="badge bg-info text-dark mt-2"><i class="bi bi-robot"></i> System Template</span>
                            </template>
                        </label>
                    </div>
                    <div>
                        <button type="button" class="btn btn-sm btn-outline-primary" x-on:click="openTemplatePreview(tpl.id)">
                            <i class="bi bi-eye"></i> Xem trước
                        </button>
                    </div>
                </div>
            </template>
            <template x-if="templates.length === 0">
                <div class="alert alert-warning">Chưa có mẫu DNS nào được cấu hình trong hệ thống.</div>
            </template>
        </div>

    </div>
</div>

{* ── Template Preview Modal (Inline x-show) ── *}
{literal}
<div x-show="showTemplatePreview" x-cloak class="position-fixed top-0 start-0 w-100 h-100 d-flex justify-content-center align-items-center" style="background: rgba(0,0,0,0.5); z-index: 1050;">
    <div class="card shadow-lg w-100" style="max-width: 700px; max-height: 90vh; overflow-y: auto;">
        <div class="card-header bg-dark text-white d-flex justify-content-between align-items-center position-sticky top-0" style="z-index: 1;">
            <h5 class="mb-0"><i class="bi bi-search"></i> Kiểm tra bản ghi trong mẫu</h5>
            <button type="button" class="btn-close btn-close-white shadow-none" x-on:click="closeTemplatePreview()"></button>
        </div>
        <div class="card-body">
            <div class="alert alert-danger px-3 py-2 mb-3">
                <strong><i class="bi bi-exclamation-triangle-fill"></i> CẢNH BÁO:</strong> 
                Nếu tiếp tục nạp mẫu này, toàn bộ <strong x-text="records.length"></strong> bản ghi DNS hiện tại sẽ bị xóa sạch và thay thế hoàn toàn bởi cấu hình bên dưới.
            </div>

            <div class="table-responsive">
                <table class="table table-sm table-bordered table-striped" style="font-size: 0.9em;">
                    <thead class="table-light">
                        <tr>
                            <th>Loại</th>
                            <th>Tên bản ghi</th>
                            <th>Giá trị</th>
                            <th>TTL</th>
                        </tr>
                    </thead>
                    <tbody>
                        <template x-for="rec in previewTemplateRecords" x-bind:key="rec.name + rec.type">
                            <tr>
                                <td>
                                    <span class="badge" x-bind:class="getTypeBadgeClass(rec.type)" x-text="rec.type"></span>
                                </td>
                                <td class="font-monospace fw-bold" x-text="rec.name"></td>
                                <td class="font-monospace text-wrap" style="max-width: 300px; overflow-wrap: break-word;" x-text="rec.value"></td>
                                <td x-text="formatTTL(rec.ttl)"></td>
                            </tr>
                        </template>
                        <template x-if="previewTemplateRecords.length === 0">
                            <tr>
                                <td colspan="4" class="text-center text-muted">Mẫu này không có dữ liệu bản ghi.</td>
                            </tr>
                        </template>
                    </tbody>
                </table>
            </div>
            <div class="form-check mt-3 ps-4 py-2 bg-light border rounded">
                <input class="form-check-input border-secondary" type="checkbox" id="confirmTemplatePreview" x-model="$data.confirmPreviewCheck">
                <label class="form-check-label fw-bold text-danger ms-1" for="confirmTemplatePreview">
                    Tôi hiểu và vẫn muốn áp dụng thay thế toàn bộ bản ghi DNS.
                </label>
            </div>
        </div>
        <div class="card-footer text-end position-sticky bottom-0 bg-white" style="z-index: 1;">
            <button type="button" class="btn btn-secondary me-2" x-on:click="closeTemplatePreview()">Đóng</button>
            <button type="button" class="btn btn-warning fw-bold" x-bind:disabled="!$data.confirmPreviewCheck" x-on:click="applyTemplate()">
                <i class="bi bi-lightning-charge-fill"></i> Nạp mẫu DNS này
            </button>
        </div>
    </div>
</div>
{/literal}
