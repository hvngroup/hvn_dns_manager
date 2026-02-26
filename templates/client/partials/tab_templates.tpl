<!-- Load Template Dialog -->
<div class="card border-secondary mb-4">
    <div class="card-header bg-light">
        <h5 class="mb-0">Nạp mẫu DNS (Templates)</h5>
    </div>
    <div class="card-body">
        <p>Chọn một mẫu DNS dựng sẵn để áp dụng nhanh cho tên miền <strong>{$domain.domain}</strong>:</p>
        
        <form @submit.prevent="if(confirm('CẢNH BÁO: Thao tác này sẽ XÓA TOÀN BỘ bản ghi hiện tại và áp dụng mẫu mới. Hệ thống sẽ tự động tạo bản backup. Bạn chắc chắn muốn tiếp tục?')) alert('Đang áp dụng mẫu DNS (Mock)...')">
            <div class="mb-3">
                {foreach from=$templates item=tpl}
                <div class="form-check mb-3 p-3 border rounded {if $tpl@first}bg-light{/if}">
                    <input class="form-check-input ms-1 mt-2" type="radio" name="template_id" id="tpl_{$tpl.id}" value="{$tpl.id}" {if $tpl@first}checked{/if}>
                    <label class="form-check-label ms-2 d-block w-100" for="tpl_{$tpl.id}">
                        <strong>{$tpl.name}</strong>
                        <span class="badge bg-secondary ms-2">{$tpl.records_count} bản ghi</span>
                        <div class="text-muted small mt-1">{$tpl.description}</div>
                        {if $tpl.is_system}
                            <span class="badge bg-info text-dark mt-2"><i class="bi bi-robot"></i> System Template</span>
                        {/if}
                    </label>
                </div>
                {foreachelse}
                <div class="alert alert-warning">Chưa có mẫu DNS nào được cấu hình trong hệ thống.</div>
                {/foreach}
            </div>

            <div class="alert alert-danger">
                <h6 class="alert-heading"><i class="bi bi-exclamation-triangle-fill"></i> CẢNH BÁO:</h6>
                <p class="mb-2">Thao tác này sẽ <strong>XÓA TOÀN BỘ</strong> bản ghi DNS hiện tại và thay bằng mẫu đã chọn.</p>
                <div class="form-check mt-2">
                    <input class="form-check-input" type="checkbox" id="confirmTemplate" required>
                    <label class="form-check-label fw-bold" for="confirmTemplate">
                        Tôi hiểu và muốn tiếp tục nạp mẫu DNS
                    </label>
                </div>
            </div>

            <div class="text-end">
                <button type="submit" class="btn btn-warning" id="btnLoadTemplate">
                    <i class="bi bi-lightning-charge-fill"></i> Nạp mẫu DNS này
                </button>
            </div>
        </form>
    </div>
</div>

<script>
    document.getElementById('confirmTemplate')?.addEventListener('change', function(e) {
        document.getElementById('btnLoadTemplate').disabled = !e.target.checked;
    });
    // Trigger initial state
    if(document.getElementById('confirmTemplate')) {
        document.getElementById('btnLoadTemplate').disabled = !document.getElementById('confirmTemplate').checked;
    }
</script>
