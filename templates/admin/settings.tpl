<div class="hvn-dns-admin hvn-settings" x-data="settingsManager()">
    <div class="d-flex justify-content-between align-items-center mb-4">
        <h2><i class="bi bi-gear-fill"></i> Cài đặt Module (Module Settings)</h2>
    </div>

    <div class="row">
        <!-- Vertical Tabs -->
        <div class="col-md-3 mb-4">
            <div class="card shadow-sm border-0">
                <div class="list-group list-group-flush rounded" id="settingsLayoutTabs" role="tablist" style="max-height: 600px; overflow-y: auto;">
                    <button class="list-group-item list-group-item-action d-flex align-items-center active" id="tab-license" data-bs-toggle="list" data-bs-target="#pane-license" role="tab" @click="activeTab = 'license'">
                        <i class="bi bi-key-fill me-3 fs-5 text-warning"></i> 
                        <span class="fw-bold">License & Bản quyền</span>
                    </button>
                    
                    <button class="list-group-item list-group-item-action d-flex align-items-center" id="tab-general" data-bs-toggle="list" data-bs-target="#pane-general" role="tab" @click="activeTab = 'general'">
                        <i class="bi bi-sliders me-3 fs-5 text-secondary"></i> 
                        <span class="fw-bold">Cài đặt Chung</span>
                    </button>

                    <button class="list-group-item list-group-item-action d-flex align-items-center" id="tab-dnssec" data-bs-toggle="list" data-bs-target="#pane-dnssec" role="tab" @click="activeTab = 'dnssec'">
                        <i class="bi bi-shield-check me-3 fs-5 text-success"></i> 
                        <span class="fw-bold">DNSSEC</span>
                    </button>

                    <button class="list-group-item list-group-item-action d-flex align-items-center" id="tab-ddns" data-bs-toggle="list" data-bs-target="#pane-ddns" role="tab" @click="activeTab = 'ddns'">
                        <i class="bi bi-router me-3 fs-5 text-primary"></i> 
                        <span class="fw-bold">Dynamic DNS (DDNS)</span>
                    </button>

                    <button class="list-group-item list-group-item-action d-flex align-items-center" id="tab-ui" data-bs-toggle="list" data-bs-target="#pane-ui" role="tab" @click="activeTab = 'ui'">
                        <i class="bi bi-window me-3 fs-5 text-info"></i> 
                        <span class="fw-bold">Giao diện (UI)</span>
                    </button>
                    
                    <button class="list-group-item list-group-item-action d-flex align-items-center text-muted fst-italic mt-2" disabled>
                        <i class="bi bi-three-dots me-3 fs-5"></i> 
                        <span class="small">Các tab khác (ẩn demo)</span>
                    </button>
                </div>
            </div>
        </div>

        <!-- Tab Content Area -->
        <div class="col-md-9">
            <div class="card shadow-sm border-0 h-100">
                <div class="card-body p-0">
                    <form @submit.prevent="saveSettings()" id="settingsForm">
                        <div class="tab-content" id="nav-tabContent">
                            
                            <!-- TAB: License -->
                            <div class="tab-pane fade show active p-4" id="pane-license" role="tabpanel">
                                <h4 class="mb-4 text-primary border-bottom pb-2"><i class="bi bi-key-fill"></i> Bản quyền Module (License)</h4>
                                
                                <div class="row g-4 mb-4">
                                    <div class="col-md-12">
                                        <label class="form-label fw-bold">License Key <span class="text-danger">*</span></label>
                                        <input type="text" class="form-control font-monospace" x-model="settings.license_key" placeholder="HVN-DNS-XXXXXXXXXXXXXXXX">
                                    </div>
                                    <div class="col-md-12">
                                        <label class="form-label fw-bold">API Endpoint <span class="text-danger">*</span></label>
                                        <input type="url" class="form-control font-monospace" x-model="settings.license_endpoint" placeholder="https://license.hvn.vn/api/v1/check">
                                    </div>
                                </div>

                                <div class="alert alert-success border-success d-flex">
                                    <div class="me-3"><i class="bi bi-check-circle-fill fs-3"></i></div>
                                    <div>
                                        <div class="fw-bold">Trạng thái hiện tại: 🟢 Active (Còn 315 ngày)</div>
                                        <div class="small mt-1">
                                            Loại gói: Enterprise (Không giới hạn server)<br>
                                            Lần check cuối: 25/02/2026 02:00
                                        </div>
                                    </div>
                                </div>
                                <div class="mt-3">
                                    <button type="button" class="btn btn-outline-primary" @click="checkLicense()"><i class="bi bi-arrow-repeat"></i> Check License Ngay</button>
                                </div>
                            </div>

                            <!-- TAB: General -->
                            <div class="tab-pane fade p-4" id="pane-general" role="tabpanel">
                                <h4 class="mb-4 text-primary border-bottom pb-2"><i class="bi bi-sliders"></i> Cài đặt Chung</h4>
                                
                                <div class="mb-4">
                                    <label class="form-label fw-bold">Force Primary Server</label>
                                    <select class="form-select" x-model="settings.primary_server">
                                        <option value="auto">Tự động chọn (Round-robin)</option>
                                        <option value="1">dns1.hvn.vn</option>
                                    </select>
                                    <div class="form-text">Server mặc định đóng vai trò Primary khi tạo Zone DNS mới.</div>
                                </div>

                                <div class="mb-4">
                                    <div class="form-check form-switch mb-2">
                                        <input class="form-check-input" type="checkbox" id="genAutoProvision" x-model="settings.auto_provision">
                                        <label class="form-check-label fw-bold" for="genAutoProvision">Auto-provisioning via WHMCS Hook</label>
                                    </div>
                                    <div class="form-text border-start border-3 border-secondary ps-2 ms-1">
                                        Khi được bật, hệ thống sẽ tự động tạo Zone DNS trên các server khi một đơn hàng Hosting/Domain tương ứng được Active.
                                    </div>
                                </div>
                                
                                <div class="mb-4">
                                    <div class="form-check form-switch mb-2">
                                        <input class="form-check-input" type="checkbox" id="genDebug" x-model="settings.debug_mode">
                                        <label class="form-check-label fw-bold text-danger" for="genDebug">Enable Debug Mode</label>
                                    </div>
                                    <div class="form-text border-start border-3 border-danger ps-2 ms-1">
                                        Ghi lại TẤT CẢ payload request/response từ API DirectAdmin vào log. Thay vì chỉ ghi nhận lỗi. <br>
                                        <strong>⚠️ CHÚ Ý:</strong> Có thể làm phình to DB rất nhanh. Chỉ nên dùng khi đang gỡ lỗi.
                                    </div>
                                </div>
                            </div>

                            <!-- TAB: DNSSEC -->
                            <div class="tab-pane fade p-4" id="pane-dnssec" role="tabpanel">
                                <h4 class="mb-4 text-success border-bottom pb-2"><i class="bi bi-shield-check"></i> Cấu hình DNSSEC (Bảo mật tên miền)</h4>
                                
                                <div class="mb-4">
                                    <label class="form-label fw-bold">Chế độ hoạt động (dnssec_mode) <span class="text-danger">*</span></label>
                                    <div class="card text-dark bg-light border-0">
                                        <div class="card-body">
                                            <div class="form-check mb-3">
                                                <input class="form-check-input" type="radio" name="dnssecMode" id="dnssecOff" value="off" x-model="settings.dnssec_mode">
                                                <label class="form-check-label fw-bold" for="dnssecOff">Off (Vô hiệu hóa)</label>
                                                <div class="small text-muted mt-1">Tắt hoàn toàn DNSSEC, ẩn tab DNSSEC với mọi client. Không thực hiện check hay hiển thị.</div>
                                            </div>
                                            
                                            <div class="form-check mb-3">
                                                <input class="form-check-input" type="radio" name="dnssecMode" id="dnssecFree" value="free" x-model="settings.dnssec_mode">
                                                <label class="form-check-label fw-bold" for="dnssecFree">Free (Miễn phí)</label>
                                                <div class="small text-muted mt-1">Miễn phí cho mọi client (nếu Gói Quota của họ được phép dùng DNSSEC).</div>
                                            </div>
                                            
                                            <div class="form-check">
                                                <input class="form-check-input" type="radio" name="dnssecMode" id="dnssecPaid" value="paid" x-model="settings.dnssec_mode">
                                                <label class="form-check-label fw-bold text-primary" for="dnssecPaid">Paid (Tính năng trả phí)</label>
                                                <div class="small text-muted mt-1">Yêu cầu client phải mua Addon WHMCS. Sẽ hiển thị Upsell Card nếu client chưa mua.</div>
                                            </div>
                                        </div>
                                    </div>
                                </div>

                                <div class="card border-primary mb-4" x-show="settings.dnssec_mode === 'paid'" x-collapse>
                                    <div class="card-header bg-primary text-white fw-bold"><i class="bi bi-cart"></i> Cấu hình Upsell Addon</div>
                                    <div class="card-body bg-light">
                                        <label class="form-label fw-bold">Chọn Addon WHMCS để cấp quyền</label>
                                        <select class="form-select" x-model="settings.dnssec_addon_id">
                                            <option value="">-- Vui lòng cấu hình 1 Addon --</option>
                                            <option value="12">12 - SSL Certificate Addon</option>
                                            <option value="14">14 - Advanced DNS Security</option>
                                        </select>
                                        <div class="form-text mt-2"><i class="bi bi-info-circle"></i> Khi Client đăng ký và có trạng thái Active cho Addon được chọn này, họ sẽ mở khóa được tab DNSSEC.</div>
                                    </div>
                                </div>
                            </div>

                            <!-- TAB: DDNS -->
                            <div class="tab-pane fade p-4" id="pane-ddns" role="tabpanel">
                                <h4 class="mb-4 text-primary border-bottom pb-2"><i class="bi bi-router"></i> Dynamic DNS (DDNS)</h4>
                                
                                <div class="mb-4">
                                    <label class="form-label fw-bold">Chế độ hoạt động (ddns_mode) <span class="text-danger">*</span></label>
                                    <div class="card text-dark bg-light border-0">
                                        <div class="card-body">
                                            <div class="form-check mb-2">
                                                <input class="form-check-input" type="radio" name="ddnsMode" id="ddnsOff" value="off" x-model="settings.ddns_mode">
                                                <label class="form-check-label" for="ddnsOff">Off (Vô hiệu hóa toàn bộ)</label>
                                            </div>
                                            <div class="form-check mb-2">
                                                <input class="form-check-input" type="radio" name="ddnsMode" id="ddnsFree" value="free" x-model="settings.ddns_mode">
                                                <label class="form-check-label fw-bold" for="ddnsFree">Free (Mở miễn phí theo Quota)</label>
                                            </div>
                                            <div class="form-check">
                                                <input class="form-check-input" type="radio" name="ddnsMode" id="ddnsPaid" value="paid" x-model="settings.ddns_mode">
                                                <label class="form-check-label text-primary" for="ddnsPaid">Paid (Upsell qua Addon)</label>
                                            </div>
                                        </div>
                                    </div>
                                </div>

                                <div class="card border-primary mb-4" x-show="settings.ddns_mode === 'paid'" x-collapse>
                                    <div class="card-header bg-primary text-white fw-bold"><i class="bi bi-cart"></i> Cấu hình Upsell Addon</div>
                                    <div class="card-body bg-light">
                                        <select class="form-select" x-model="settings.ddns_addon_id">
                                            <option value="">-- Chọn Addon --</option>
                                            <option value="15">15 - Khóa kích hoạt IP Động (DDNS)</option>
                                        </select>
                                    </div>
                                </div>
                            </div>

                        </div> <!-- end tab-content -->
                        
                        <!-- Footer Action -->
                        <div class="p-4 bg-light border-top text-end rounded-bottom">
                            <button type="submit" class="btn btn-primary px-5" :disabled="isSaving">
                                <span x-show="!isSaving"><i class="bi bi-save"></i> Lưu cài đặt</span>
                                <span x-show="isSaving"><span class="spinner-border spinner-border-sm"></span> Đang lưu...</span>
                            </button>
                        </div>
                    </form>
                </div>
            </div>
        </div>
    </div>
</div>

<script>
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
                    <div class="toast-container position-fixed bottom-0 end-0 p-3">
                        <div class="toast show align-items-center text-bg-success border-0" role="alert">
                            <div class="d-flex">
                                <div class="toast-body">
                                    <i class="bi bi-check-circle-fill me-2"></i> Đã lưu cài đặt thành công!
                                </div>
                                <button type="button" class="btn-close btn-close-white me-2 m-auto" data-bs-dismiss="toast"></button>
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
</script>

<style>
/* Utilities for settings page */
#settingsLayoutTabs .list-group-item {
    border: none;
    border-bottom: 1px solid #f8f9fa;
    padding: 1rem 1.25rem;
}
#settingsLayoutTabs .list-group-item.active {
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
