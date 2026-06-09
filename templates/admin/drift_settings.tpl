<div class="hvn-dns-admin hvn-drift-settings" x-data="driftSettings()">
    <div class="hvn-d-flex hvn-justify-content-between hvn-align-items-center hvn-mb-4">
        <h2>
            <a href="{$modulelink}&action=drift_reports" class="text-decoration-none hvn-text-muted hvn-me-2"><i class="bi bi-arrow-left"></i></a>
            <i class="bi bi-gear"></i> Cài đặt Drift Auto-fix
        </h2>
    </div>

    <div class="hvn-card hvn-shadow-sm hvn-border-0">
        <div class="hvn-card-body hvn-p-4">
            <p class="hvn-text-muted hvn-mb-4">Drift Detection quét dữ liệu Zone từ DirectAdmin mỗi đêm (cron) và so sánh với database WHMCS. Nếu có khác biệt, hệ thống xử lý thế nào?</p>
            
            <form @submit.prevent="saveAutoFix">
                <div class="form-check form-switch fs-5 hvn-mb-3">
                    <input class="form-check-input" type="checkbox" id="autoFixToggle" x-model="autoFixEnabled">
                    <label class="form-check-label" for="autoFixToggle">Tự động đẩy WHMCS → DA</label>
                </div>
                
                <div class="alert alert-info border-info hvn-mt-3" x-show="autoFixEnabled">
                    <i class="bi bi-info-circle-fill"></i> Hệ thống sẽ <strong class="hvn-text-danger">Ghi đè</strong> mọi dữ liệu bị lệch trên DA bằng dữ liệu định quy chuẩn trên WHMCS.
                    <ul class="hvn-mb-0 hvn-mt-2 fs-6">
                        <li>Xóa các record có trên DA nhưng không có trên WHMCS</li>
                        <li>Sửa giá trị trên DA thành giá trị trên WHMCS</li>
                        <li>Tạo record trên DA nếu WHMCS có DA chưa có</li>
                    </ul>
                </div>
                <div class="alert alert-secondary hvn-mt-3 fs-6" x-show="!autoFixEnabled">
                    Hệ thống chỉ cảnh báo email và tạo báo cáo tại trang Drift Reports. Quản trị viên phải xử lý thủ công.
                </div>

                <div class="hvn-d-flex hvn-justify-content-end hvn-gap-2 hvn-pt-4 hvn-border-top hvn-mt-4">
                    <a href="{$modulelink}&action=drift_reports" class="hvn-btn hvn-btn-outline-secondary">Hủy</a>
                    <button type="submit" class="hvn-btn hvn-btn-primary"><i class="bi bi-save"></i> Lưu cài đặt</button>
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
            window._hvnToast('success', 'Đã lưu', 'Cấu hình Drift Auto-fix đã được lưu!');
            window.location.href = '{/literal}{$modulelink}&action=drift_reports{literal}';
        }
    }));
});
{/literal}
</script>
