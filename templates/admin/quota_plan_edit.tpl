<div class="hvn-dns-admin hvn-quota-plan-edit" x-data="quotaPlanEditor()">
    <div class="hvn-d-flex hvn-justify-content-between hvn-align-items-center hvn-mb-4">
        <h2>
            <a href="{$modulelink}&action=quota_plans" class="text-decoration-none hvn-text-muted hvn-me-2"><i class="bi bi-arrow-left"></i></a>
            <i class="bi bi-sliders"></i> <span x-text="isEdit ? 'Sửa cấu hình Gói' : 'Tạo Quota Plan mới'"></span>
        </h2>
    </div>

    <div class="hvn-card hvn-shadow-sm hvn-border-0">
        <div class="hvn-card-body hvn-p-4">
            <form @submit.prevent="savePlan">
                <div class="hvn-row hvn-mb-4">
                    <div class="hvn-col-md-6">
                        <label class="form-label hvn-fw-bold">Tên gói <span class="hvn-text-danger">*</span></label>
                        <input type="text" class="hvn-form-control" x-model="form.name" required>
                    </div>
                    <div class="hvn-col-md-6">
                        <label class="form-label hvn-fw-bold">Mô tả nội bộ / Ghi chú</label>
                        <input type="text" class="hvn-form-control hvn-text-muted" x-model="form.description">
                    </div>
                </div>

                <h6 class="hvn-border-bottom hvn-pb-2 hvn-mb-3 hvn-text-primary"><i class="bi bi-speedometer2"></i> Giới hạn số lượng (Nhập 0 để không giới hạn)</h6>
                
                <div class="hvn-row g-3 hvn-mb-4">
                    <div class="hvn-col-md-3">
                        <label class="form-label small hvn-mb-1">Tổng Records</label>
                        <div class="input-group input-group-sm">
                            <input type="number" class="hvn-form-control hvn-form-control-sm hvn-text-center font-monospace font-weight-bold" x-model="form.limit_records" min="0">
                        </div>
                    </div>
                    <div class="hvn-col-md-3">
                        <label class="form-label small hvn-mb-1">Subdomains</label>
                        <div class="input-group input-group-sm">
                            <input type="number" class="hvn-form-control hvn-form-control-sm hvn-text-center font-monospace" x-model="form.limit_subdomains" min="0">
                        </div>
                    </div>
                    <div class="hvn-col-md-3">
                        <label class="form-label small hvn-mb-1">URL Redirects</label>
                        <div class="input-group input-group-sm">
                            <input type="number" class="hvn-form-control hvn-form-control-sm hvn-text-center font-monospace" x-model="form.limit_redirects" min="0">
                        </div>
                    </div>
                    <div class="hvn-col-md-3">
                        <label class="form-label small hvn-mb-1">Email Forwards</label>
                        <div class="input-group input-group-sm">
                            <input type="number" class="hvn-form-control hvn-form-control-sm hvn-text-center font-monospace" x-model="form.limit_emails" min="0">
                        </div>
                    </div>
                </div>

                <h6 class="hvn-border-bottom hvn-pb-2 hvn-mb-3 hvn-text-primary"><i class="bi bi-award"></i> Tính năng Cao cấp (Premium Options)</h6>

                <div class="hvn-row hvn-g-4 hvn-mb-4">
                    <div class="hvn-col-md-6">
                        <div class="hvn-card hvn-bg-light hvn-border-0 hvn-shadow-sm h-100">
                            <div class="hvn-card-body">
                                <div class="form-check form-switch hvn-mb-2">
                                    <input class="form-check-input" type="checkbox" id="featureDNSSEC" x-model="form.dnssec_enabled">
                                    <label class="form-check-label hvn-fw-bold" for="featureDNSSEC">Cho phép sử dụng DNSSEC</label>
                                </div>
                                <p class="small hvn-text-muted hvn-mb-0">Hiển thị tab DNSSEC và cho phép quản lý khóa KSK/ZSK. Mức giá Upsell phụ thuộc Settings hệ thống.</p>
                            </div>
                        </div>
                    </div>
                    <div class="hvn-col-md-6">
                        <div class="hvn-card hvn-bg-light hvn-border-0 hvn-shadow-sm h-100">
                            <div class="hvn-card-body">
                                <div class="form-check form-switch hvn-mb-2">
                                    <input class="form-check-input" type="checkbox" id="featureDDNS" x-model="form.ddns_enabled">
                                    <label class="form-check-label hvn-fw-bold" for="featureDDNS">Cho phép dùng Dynamic DNS</label>
                                </div>
                                <div class="hvn-mt-2" x-show="form.ddns_enabled">
                                    <label class="form-label small hvn-mb-1">Giới hạn số token DDNS:</label>
                                    <div class="input-group input-group-sm w-50">
                                        <input type="number" class="hvn-form-control hvn-form-control-sm hvn-text-center font-monospace" x-model="form.limit_ddns" min="1">
                                        <span class="input-group-text hvn-bg-white">tokens</span>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>

                <div class="hvn-d-flex hvn-justify-content-end hvn-gap-2 hvn-pt-3 hvn-border-top">
                    <a href="{$modulelink}&action=quota_plans" class="hvn-btn hvn-btn-outline-secondary">Hủy</a>
                    <button type="submit" class="hvn-btn hvn-btn-primary">
                        <i class="bi bi-save"></i> <span x-text="isEdit ? 'Cập nhật' : 'Tạo Gói'"></span>
                    </button>
                </div>
            </form>
        </div>
    </div>
</div>

<script>
{literal}
document.addEventListener('alpine:init', () => {
    Alpine.data('quotaPlanEditor', () => ({
        isEdit: false,
        form: { id: null, name: '', description: '', limit_records: 50, limit_subdomains: 10, limit_redirects: 2, limit_emails: 2, dnssec_enabled: false, ddns_enabled: false, limit_ddns: 1 },

        init() {
            // Mock: Check URL for ID
            const urlParams = new URLSearchParams(window.location.search);
            const id = urlParams.get('id');
            if (id) {
                this.isEdit = true;
                // Mock load
                this.form = { id: id, name: 'Pro Tier', description: 'Dành cho khách hàng mua riêng dịch vụ DNS', limit_records: 50, limit_subdomains: 20, limit_redirects: 5, limit_emails: 10, dnssec_enabled: false, ddns_enabled: true, limit_ddns: 2 };
            }
        },

        savePlan() {
            if(!this.form.name) return alert('Vui lòng điền tên Quota Plan.');
            alert('Đã lưu cấu hình Gói!');
            window.location.href = '{/literal}{$modulelink}&action=quota_plans{literal}';
        }
    }));
});
{/literal}
</script>
