<div class="hvn-dns-admin hvn-settings" x-data="settingsManager()">
    <div class="hvn-d-flex hvn-justify-content-between hvn-align-items-center hvn-mb-4">
        <h2><i class="bi bi-gear-fill"></i> Cài đặt Module (Module Settings)</h2>
    </div>

    <div class="hvn-row">
        <!-- Vertical Tabs -->
        <div class="hvn-col-md-3 hvn-mb-4">
            <div class="hvn-card hvn-shadow-sm hvn-border-0">
                <div class="hvn-list-group hvn-list-group-flush hvn-rounded" id="settingsLayoutTabs" role="tablist" style="max-height: 600px; overflow-y: auto;">
                    <button class="hvn-list-group-item hvn-list-group-item-action hvn-d-flex hvn-align-items-center active" id="tab-license" data-bs-toggle="list" data-bs-target="#pane-license" role="tab" @click="activeTab = 'license'">
                        <i class="bi bi-key-fill hvn-me-3 fs-5 hvn-text-warning"></i> 
                        <span class="hvn-fw-bold">License & Bản quyền</span>
                    </button>
                    
                    <button class="hvn-list-group-item hvn-list-group-item-action hvn-d-flex hvn-align-items-center" id="tab-general" data-bs-toggle="list" data-bs-target="#pane-general" role="tab" @click="activeTab = 'general'">
                        <i class="bi bi-sliders hvn-me-3 fs-5 hvn-text-secondary"></i> 
                        <span class="hvn-fw-bold">Cài đặt Chung</span>
                    </button>

                    <button class="hvn-list-group-item hvn-list-group-item-action hvn-d-flex hvn-align-items-center" id="tab-dnssec" data-bs-toggle="list" data-bs-target="#pane-dnssec" role="tab" @click="activeTab = 'dnssec'">
                        <i class="bi bi-shield-check hvn-me-3 fs-5 hvn-text-success"></i> 
                        <span class="hvn-fw-bold">DNSSEC</span>
                    </button>

                    <button class="hvn-list-group-item hvn-list-group-item-action hvn-d-flex hvn-align-items-center" id="tab-ddns" data-bs-toggle="list" data-bs-target="#pane-ddns" role="tab" @click="activeTab = 'ddns'">
                        <i class="bi bi-router hvn-me-3 fs-5 hvn-text-primary"></i> 
                        <span class="hvn-fw-bold">Dynamic DNS (DDNS)</span>
                    </button>

                    <button class="hvn-list-group-item hvn-list-group-item-action hvn-d-flex hvn-align-items-center" id="tab-ui" data-bs-toggle="list" data-bs-target="#pane-ui" role="tab" @click="activeTab = 'ui'">
                        <i class="bi bi-window hvn-me-3 fs-5 hvn-text-info"></i> 
                        <span class="hvn-fw-bold">Giao diện (UI)</span>
                    </button>
                    
                    <button class="hvn-list-group-item hvn-list-group-item-action hvn-d-flex hvn-align-items-center hvn-text-muted fst-italic hvn-mt-2" disabled>
                        <i class="bi bi-three-dots hvn-me-3 fs-5"></i> 
                        <span class="small">Các tab khác (ẩn demo)</span>
                    </button>
                </div>
            </div>
        </div>

        <!-- Tab Content Area -->
        <div class="hvn-col-md-9">
            <div class="hvn-card hvn-shadow-sm hvn-border-0 h-100">
                <div class="hvn-card-body hvn-p-0">
                    <form @submit.prevent="saveSettings()" id="settingsForm">
                        <div class="tab-content" id="nav-tabContent">
                            
                            <!-- TAB: License -->
                            <div class="tab-pane fade show active hvn-p-4" id="pane-license" role="tabpanel">
                                <h4 class="hvn-mb-4 hvn-text-primary hvn-border-bottom hvn-pb-2"><i class="bi bi-key-fill"></i> Bản quyền Module (License)</h4>
                                
                                <div class="hvn-row hvn-g-4 hvn-mb-4">
                                    <div class="hvn-col-md-12">
                                        <label class="form-label hvn-fw-bold">License Key <span class="hvn-text-danger">*</span></label>
                                        <input type="text" class="hvn-form-control font-monospace" x-model="settings.license_key" placeholder="HVN-DNS-XXXXXXXXXXXXXXXX">
                                    </div>
                                    <div class="hvn-col-md-12">
                                        <label class="form-label hvn-fw-bold">API Endpoint <span class="hvn-text-danger">*</span></label>
                                        <input type="url" class="hvn-form-control font-monospace" x-model="settings.license_endpoint" placeholder="https://license.hvn.vn/api/v1/check">
                                    </div>
                                </div>

                                <div class="alert alert-success hvn-border-success hvn-d-flex">
                                    <div class="hvn-me-3"><i class="bi bi-check-circle-fill fs-3"></i></div>
                                    <div>
                                        <div class="hvn-fw-bold">Trạng thái hiện tại: 🟢 Active (Còn 315 ngày)</div>
                                        <div class="small hvn-mt-1">
                                            Loại gói: Enterprise (Không giới hạn server)<br>
                                            Lần check cuối: 25/02/2026 02:00
                                        </div>
                                    </div>
                                </div>
                                <div class="hvn-mt-3">
                                    <button type="button" class="hvn-btn hvn-btn-outline-primary" @click="checkLicense()"><i class="bi bi-arrow-repeat"></i> Check License Ngay</button>
                                </div>
                            </div>

                            <!-- TAB: General -->
                            <div class="tab-pane fade hvn-p-4" id="pane-general" role="tabpanel">
                                <h4 class="hvn-mb-4 hvn-text-primary hvn-border-bottom hvn-pb-2"><i class="bi bi-sliders"></i> Cài đặt Chung</h4>
                                
                                <div class="hvn-mb-4">
                                    <label class="form-label hvn-fw-bold">Force Primary Server</label>
                                    <select class="hvn-form-select" x-model="settings.primary_server">
                                        <option value="auto">Tự động chọn (Round-robin)</option>
                                        <option value="1">dns1.hvn.vn</option>
                                    </select>
                                    <div class="form-text">Server mặc định đóng vai trò Primary khi tạo Zone DNS mới.</div>
                                </div>

                                <div class="hvn-mb-4">
                                    <div class="form-check form-switch hvn-mb-2">
                                        <input class="form-check-input" type="checkbox" id="genAutoProvision" x-model="settings.auto_provision">
                                        <label class="form-check-label hvn-fw-bold" for="genAutoProvision">Auto-provisioning via WHMCS Hook</label>
                                    </div>
                                    <div class="form-text hvn-border-start border-3 border-secondary hvn-ps-2 hvn-ms-1">
                                        Khi được bật, hệ thống sẽ tự động tạo Zone DNS trên các server khi một đơn hàng Hosting/Domain tương ứng được Active.
                                    </div>
                                </div>
                                
                                <div class="hvn-mb-4">
                                    <div class="form-check form-switch hvn-mb-2">
                                        <input class="form-check-input" type="checkbox" id="genDebug" x-model="settings.debug_mode">
                                        <label class="form-check-label hvn-fw-bold hvn-text-danger" for="genDebug">Enable Debug Mode</label>
                                    </div>
                                    <div class="form-text hvn-border-start border-3 hvn-border-danger hvn-ps-2 hvn-ms-1">
                                        Ghi lại TẤT CẢ payload request/response từ API DirectAdmin vào log. Thay vì chỉ ghi nhận lỗi. <br>
                                        <strong>⚠️ CHÚ Ý:</strong> Có thể làm phình to DB rất nhanh. Chỉ nên dùng khi đang gỡ lỗi.
                                    </div>
                                </div>
                            </div>

                            <!-- TAB: DNSSEC -->
                            <div class="tab-pane fade hvn-p-4" id="pane-dnssec" role="tabpanel">
                                <h4 class="hvn-mb-4 hvn-text-success hvn-border-bottom hvn-pb-2"><i class="bi bi-shield-check"></i> Cấu hình DNSSEC (Bảo mật tên miền)</h4>
                                
                                <div class="hvn-mb-4">
                                    <label class="form-label hvn-fw-bold">Chế độ hoạt động (dnssec_mode) <span class="hvn-text-danger">*</span></label>
                                    <div class="hvn-card hvn-text-dark hvn-bg-light hvn-border-0">
                                        <div class="hvn-card-body">
                                            <div class="form-check hvn-mb-3">
                                                <input class="form-check-input" type="radio" name="dnssecMode" id="dnssecOff" value="off" x-model="settings.dnssec_mode">
                                                <label class="form-check-label hvn-fw-bold" for="dnssecOff">Off (Vô hiệu hóa)</label>
                                                <div class="small hvn-text-muted hvn-mt-1">Tắt hoàn toàn DNSSEC, ẩn tab DNSSEC với mọi client. Không thực hiện check hay hiển thị.</div>
                                            </div>
                                            
                                            <div class="form-check hvn-mb-3">
                                                <input class="form-check-input" type="radio" name="dnssecMode" id="dnssecFree" value="free" x-model="settings.dnssec_mode">
                                                <label class="form-check-label hvn-fw-bold" for="dnssecFree">Free (Miễn phí)</label>
                                                <div class="small hvn-text-muted hvn-mt-1">Miễn phí cho mọi client (nếu Gói Quota của họ được phép dùng DNSSEC).</div>
                                            </div>
                                            
                                            <div class="form-check">
                                                <input class="form-check-input" type="radio" name="dnssecMode" id="dnssecPaid" value="paid" x-model="settings.dnssec_mode">
                                                <label class="form-check-label hvn-fw-bold hvn-text-primary" for="dnssecPaid">Paid (Tính năng trả phí)</label>
                                                <div class="small hvn-text-muted hvn-mt-1">Yêu cầu client phải mua Addon WHMCS. Sẽ hiển thị Upsell Card nếu client chưa mua.</div>
                                            </div>
                                        </div>
                                    </div>
                                </div>

                                <div class="hvn-card hvn-border-primary hvn-mb-4" x-show="settings.dnssec_mode === 'paid'" x-collapse>
                                    <div class="hvn-card-header hvn-bg-primary hvn-text-white hvn-fw-bold"><i class="bi bi-cart"></i> Cấu hình Upsell Addon</div>
                                    <div class="hvn-card-body hvn-bg-light">
                                        <label class="form-label hvn-fw-bold">Chọn Addon WHMCS để cấp quyền</label>
                                        <select class="hvn-form-select" x-model="settings.dnssec_addon_id">
                                            <option value="">-- Vui lòng cấu hình 1 Addon --</option>
                                            <option value="12">12 - SSL Certificate Addon</option>
                                            <option value="14">14 - Advanced DNS Security</option>
                                        </select>
                                        <div class="form-text hvn-mt-2"><i class="bi bi-info-circle"></i> Khi Client đăng ký và có trạng thái Active cho Addon được chọn này, họ sẽ mở khóa được tab DNSSEC.</div>
                                    </div>
                                </div>
                            </div>

                            <!-- TAB: DDNS -->
                            <div class="tab-pane fade hvn-p-4" id="pane-ddns" role="tabpanel">
                                <h4 class="hvn-mb-4 hvn-text-primary hvn-border-bottom hvn-pb-2"><i class="bi bi-router"></i> Dynamic DNS (DDNS)</h4>
                                
                                <div class="hvn-mb-4">
                                    <label class="form-label hvn-fw-bold">Chế độ hoạt động (ddns_mode) <span class="hvn-text-danger">*</span></label>
                                    <div class="hvn-card hvn-text-dark hvn-bg-light hvn-border-0">
                                        <div class="hvn-card-body">
                                            <div class="form-check hvn-mb-2">
                                                <input class="form-check-input" type="radio" name="ddnsMode" id="ddnsOff" value="off" x-model="settings.ddns_mode">
                                                <label class="form-check-label" for="ddnsOff">Off (Vô hiệu hóa toàn bộ)</label>
                                            </div>
                                            <div class="form-check hvn-mb-2">
                                                <input class="form-check-input" type="radio" name="ddnsMode" id="ddnsFree" value="free" x-model="settings.ddns_mode">
                                                <label class="form-check-label hvn-fw-bold" for="ddnsFree">Free (Mở miễn phí theo Quota)</label>
                                            </div>
                                            <div class="form-check">
                                                <input class="form-check-input" type="radio" name="ddnsMode" id="ddnsPaid" value="paid" x-model="settings.ddns_mode">
                                                <label class="form-check-label hvn-text-primary" for="ddnsPaid">Paid (Upsell qua Addon)</label>
                                            </div>
                                        </div>
                                    </div>
                                </div>

                                <div class="hvn-card hvn-border-primary hvn-mb-4" x-show="settings.ddns_mode === 'paid'" x-collapse>
                                    <div class="hvn-card-header hvn-bg-primary hvn-text-white hvn-fw-bold"><i class="bi bi-cart"></i> Cấu hình Upsell Addon</div>
                                    <div class="hvn-card-body hvn-bg-light">
                                        <select class="hvn-form-select" x-model="settings.ddns_addon_id">
                                            <option value="">-- Chọn Addon --</option>
                                            <option value="15">15 - Khóa kích hoạt IP Động (DDNS)</option>
                                        </select>
                                    </div>
                                </div>
                            </div>

                        </div> <!-- end tab-content -->
                        
                        <!-- Footer Action -->
                        <div class="hvn-p-4 hvn-bg-light hvn-border-top hvn-text-end hvn-rounded-bottom">
                            <button type="submit" class="hvn-btn hvn-btn-primary px-5" :disabled="isSaving">
                                <span x-show="!isSaving"><i class="bi bi-save"></i> Lưu cài đặt</span>
                                <span x-show="isSaving"><span class="hvn-spinner-border hvn-spinner-border-sm"></span> Đang lưu...</span>
                            </button>
                        </div>
                    </form>
                </div>
            </div>
        </div>
    </div>
</div>

<script>
{literal}
document.addEventListener('alpine:init', () => {
    Alpine.data('settingsManager', () => ({
        activeTab: 'license',
        isSaving: false,
        
        settings: {
            license_key: 'HVN-DNS-DEMO-TRIAL-KEY',
            license_endpoint: 'https://license.hvn.vn/api/v1/check',
            
            primary_server: 'auto',
            auto_provision: true,
            debug_mode: false,
            
            dnssec_mode: 'paid',
            dnssec_addon_id: '14',
            
            ddns_mode: 'free',
            ddns_addon_id: ''
        },

        saveSettings() {
            this.isSaving = true;
            setTimeout(() => {
                this.isSaving = false;
                
                // Show toast notification
                const toastHtml = `
                    <div class="toast-container position-fixed bottohvn-m-0 end-0 hvn-p-3">
                        <div class="toast show hvn-align-items-center text-hvn-bg-success hvn-border-0" role="alert">
                            <div class="hvn-d-flex">
                                <div class="toast-body">
                                    <i class="bi bi-check-circle-fill hvn-me-2"></i> Đã lưu cài đặt thành công!
                                </div>
                                <button type="button" class="btn-close btn-close-white hvn-me-2 m-auto" data-bs-dismiss="toast"></button>
                            </div>
                        </div>
                    </div>`;
                document.body.insertAdjacentHTML('beforeend', toastHtml);
                setTimeout(() => {
                    const toastEl = document.querySelector('.toast-container:last-child');
                    if (toastEl) toastEl.remove();
                }, 3000);
            }, 800);
        },

        checkLicense() {
            let btn = event.currentTarget;
            let icon = btn.querySelector('i');
            icon.classList.add('bi-spin');
            
            setTimeout(() => {
                icon.classList.remove('bi-spin');
                alert('License hợp lệ! Trạng thái: Active (Enterprise)');
            }, 1000);
        }
    }));
});
{/literal}
</script>

<style>
/* Utilities for settings page */
#settingsLayoutTabs .hvn-list-group-item {
    border: none;
    hvn-border-bottom: 1px solid #f8f9fa;
    padding: 1rem 1.25rem;
}
#settingsLayoutTabs .hvn-list-group-item.active {
    background-color: #f8f9fa;
    color: #495057;
    border-left: 4px solid #0d6efd;
}
.bi-spin {
    animation: spin 1s linear infinite;
    display: inline-block;
}
@keyframes spin { 100% { transform: rotate(360deg); } }
</style>
