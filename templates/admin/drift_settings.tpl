<div class="mj-dns-admin mj-drift-settings" x-data="driftSettings()">
    <div class="mj-d-flex mj-justify-content-between mj-align-items-center mj-mb-4">
        <h2>
            <a href="{$modulelink}&action=drift_reports" class="text-decoration-none mj-text-muted mj-me-2"><i class="bi bi-arrow-left"></i></a>
            <i class="bi bi-gear"></i> Cài đặt Drift Auto-fix
        </h2>
    </div>

    <div class="mj-card mj-shadow-sm mj-border-0">
        <div class="mj-card-body mj-p-4">
            <p class="mj-text-muted mj-mb-4">Drift Detection quét dữ liệu Zone từ DirectAdmin mỗi đêm (cron) và so sánh với database WHMCS. Nếu có khác biệt, hệ thống xử lý thế nào?</p>
            
            <form @submit.prevent="saveAutoFix">
                <div class="form-check form-switch fs-5 mj-mb-3">
                    <input class="form-check-input" type="checkbox" id="autoFixToggle" x-model="autoFixEnabled">
                    <label class="form-check-label" for="autoFixToggle">Tự động đẩy WHMCS → DA</label>
                </div>
                
                <div class="alert alert-info border-info mj-mt-3" x-show="autoFixEnabled">
                    <i class="bi bi-info-circle-fill"></i> Hệ thống sẽ <strong class="mj-text-danger">Ghi đè</strong> mọi dữ liệu bị lệch trên DA bằng dữ liệu định quy chuẩn trên WHMCS.
                    <ul class="mj-mb-0 mj-mt-2 fs-6">
                        <li>Xóa các record có trên DA nhưng không có trên WHMCS</li>
                        <li>Sửa giá trị trên DA thành giá trị trên WHMCS</li>
                        <li>Tạo record trên DA nếu WHMCS có DA chưa có</li>
                    </ul>
                </div>
                <div class="alert alert-secondary mj-mt-3 fs-6" x-show="!autoFixEnabled">
                    Hệ thống chỉ cảnh báo email và tạo báo cáo tại trang Drift Reports. Quản trị viên phải xử lý thủ công.
                </div>

                <div class="mj-d-flex mj-justify-content-end mj-gap-2 mj-pt-4 mj-border-top mj-mt-4">
                    <a href="{$modulelink}&action=drift_reports" class="mj-btn mj-btn-outline-secondary">Hủy</a>
                    <button type="submit" class="mj-btn mj-btn-primary"><i class="bi bi-save"></i> Lưu cài đặt</button>
                </div>
            </form>
        </div>
    </div>
</div>

<script>
{literal}
document.addEventListener('alpine:init', () => {
    Alpine.data('driftSettings', () => ({
        autoFixEnabled: false,

        init() {
            // Mock load settings
            this.autoFixEnabled = false;
        },

        saveAutoFix() {
            window._mjDnsToast('success', 'Đã lưu', 'Cấu hình Drift Auto-fix đã được lưu!');
            window.location.href = '{/literal}{$modulelink}&action=drift_reports{literal}';
        }
    }));
});
{/literal}
</script>
