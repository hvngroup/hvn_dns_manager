<div class="hvn-dns-admin hvn-drift-reports" x-data="driftManager()">
    <div class="d-flex justify-content-between align-items-center mb-4">
        <h2><i class="bi bi-arrow-left-right"></i> Báo cáo Lệch Dữ liệu (Drift Reports)</h2>
        <div>
            <button class="btn btn-outline-primary me-2" @click="runScan()"><i class="bi bi-search"></i> Quét thủ công</button>
            <button class="btn btn-primary" @click="openSettings()"><i class="bi bi-gear"></i> Cài đặt Auto-fix</button>
        </div>
    </div>

    <div class="card shadow-sm border-0 mb-4">
        <div class="card-body bg-light rounded d-flex justify-content-between align-items-center">
            <div>
                <span class="text-muted"><i class="bi bi-clock-history"></i> Lần quét gần nhất:</span> 
                <strong>25/02/2026 02:15</strong>
                <span class="mx-3 text-muted">|</span>
                <span class="text-muted">Kế tiếp:</span>
                <strong>26/02/2026 02:00</strong>
            </div>
            <div>
                <select class="form-select form-select-sm d-inline-block w-auto" x-model="filterStatus">
                    <option value="all">Tất cả báo cáo</option>
                    <option value="pending">Chỉ hiện sự cố (Pending)</option>
                    <option value="resolved">Đã xử lý (Resolved)</option>
                </select>
            </div>
        </div>
    </div>

    <!-- Cảnh báo nếu có drift -->
    <template x-if="driftedDomains.length > 0 && filterStatus !== 'resolved'">
        <div class="alert alert-warning border-warning border-start border-4 shadow-sm mb-4">
            <h5 class="alert-heading text-warning-emphasis"><i class="bi bi-exclamation-triangle-fill"></i> Phát hiện <span x-text="driftedDomains.length"></span> domain có dữ liệu sai lệch!</h5>
            <p class="mb-0">Dữ liệu trên WHMCS (được coi là Source of Truth) đang khác biệt so với dữ liệu thực tế trên DirectAdmin Server.</p>
        </div>
    </template>
    
    <template x-if="driftedDomains.length === 0 || (filterStatus === 'pending' && driftedDomains.length === 0)">
        <div class="text-center py-5 text-muted">
            <i class="bi bi-shield-check display-1 text-success mb-3 opacity-50"></i>
            <h4>Đồng bộ hoàn hảo</h4>
            <p>Không phát hiện sự sai lệch dữ liệu nào giữa WHMCS và DirectAdmin.</p>
        </div>
    </template>

    <!-- Danh sách Domain bị lệch -->
    <div class="accordion" id="driftAccordion">
        <template x-for="(domain, idx) in filteredDomains" :key="domain.id">
            <div class="accordion-item mb-3 border-0 shadow-sm rounded overflow-hidden">
                <h2 class="accordion-header" :id="'heading' + domain.id">
                    <button class="accordion-button bg-white text-dark fw-bold border-bottom" type="button" data-bs-toggle="collapse" :data-bs-target="'#collapse' + domain.id" aria-expanded="true" :aria-controls="'collapse' + domain.id">
                        <span class="fs-5 me-2" x-text="domain.name"></span> 
                        <span class="badge bg-danger rounded-pill" x-text="domain.drifts.length + ' bản ghi lệch'"></span>
                    </button>
                </h2>
                <div :id="'collapse' + domain.id" class="accordion-collapse collapse show" :aria-labelledby="'heading' + domain.id" data-bs-parent="#driftAccordion">
                    <div class="accordion-body p-0">
                        <ul class="list-group list-group-flush">
                            <!-- Loop qua từng Drift trong Domain -->
                            <template x-for="(drift, dIdx) in domain.drifts" :key="drift.id">
                                <li class="list-group-item p-4">
                                    <div class="d-flex align-items-start">
                                        <div class="me-3 mt-1">
                                            <!-- Icon theo loại lỗi -->
                                            <template x-if="drift.type === 'added_on_da'">
                                                <i class="bi bi-patch-plus text-info fs-3" title="Có trên DA, không có trên WHMCS"></i>
                                            </template>
                                            <template x-if="drift.type === 'missing_on_da'">
                                                <i class="bi bi-patch-minus text-danger fs-3" title="Có trên WHMCS, thiếu trên DA"></i>
                                            </template>
                                            <template x-if="drift.type === 'modified'">
                                                <i class="bi bi-patch-exclamation text-warning fs-3" title="Dữ liệu không khớp"></i>
                                            </template>
                                        </div>
                                        <div class="flex-grow-1">
                                            <div class="d-flex justify-content-between align-items-center mb-2">
                                                <h6 class="mb-0 fw-bold">
                                                    <span class="badge bg-secondary me-2" x-text="drift.type"></span>
                                                    <span class="font-monospace" x-text="drift.record_type + ' ' + drift.record_name"></span>
                                                </h6>
                                            </div>
                                            
                                            <div class="row g-3 mb-3 font-monospace small">
                                                <div class="col-md-6">
                                                    <div class="card border-0 bg-light">
                                                        <div class="card-header py-1 bg-transparent border-bottom-0 text-muted fw-bold"><i class="bi bi-database"></i> WHMCS (Truth)</div>
                                                        <div class="card-body py-2 text-break" x-html="formatRecord(drift.whmcs_val)"></div>
                                                    </div>
                                                </div>
                                                <div class="col-md-6">
                                                    <div class="card border-0 bg-light">
                                                        <div class="card-header py-1 bg-transparent border-bottom-0 text-muted fw-bold"><i class="bi bi-server"></i> DirectAdmin</div>
                                                        <div class="card-body py-2 text-break" x-text="drift.da_val || '(Không tồn tại)'"></div>
                                                    </div>
                                                </div>
                                            </div>

                                            <div class="btn-group btn-group-sm">
                                                <template x-if="drift.type === 'added_on_da'">
                                                    <button class="btn btn-outline-primary" @click="resolve(domain, drift, 'pull')"><i class="bi bi-box-arrow-in-down"></i> Pull DA → WHMCS</button>
                                                </template>
                                                <template x-if="drift.type === 'added_on_da'">
                                                    <button class="btn btn-outline-danger" @click="resolve(domain, drift, 'delete_da')"><i class="bi bi-trash"></i> Xóa trên DA</button>
                                                </template>

                                                <template x-if="drift.type === 'missing_on_da'">
                                                    <button class="btn btn-outline-success" @click="resolve(domain, drift, 'push')"><i class="bi bi-box-arrow-up"></i> Push WHMCS → DA</button>
                                                </template>
                                                <template x-if="drift.type === 'missing_on_da'">
                                                    <button class="btn btn-outline-danger" @click="resolve(domain, drift, 'delete_whmcs')"><i class="bi bi-trash"></i> Xóa trong WHMCS</button>
                                                </template>

                                                <template x-if="drift.type === 'modified'">
                                                    <button class="btn btn-outline-primary" @click="resolve(domain, drift, 'pull')"><i class="bi bi-box-arrow-in-down"></i> Pull DA → WHMCS</button>
                                                </template>
                                                <template x-if="drift.type === 'modified'">
                                                    <button class="btn btn-outline-success" @click="resolve(domain, drift, 'push')"><i class="bi bi-box-arrow-up"></i> Push WHMCS → DA</button>
                                                </template>

                                                <button class="btn btn-outline-secondary" @click="resolve(domain, drift, 'ignore')"><i class="bi bi-eye-slash"></i> Bỏ qua</button>
                                            </div>
                                        </div>
                                    </div>
                                </li>
                            </template>
                        </ul>
                    </div>
                </div>
            </div>
        </template>
    </div>

    <!-- Auto Fix Settings Modal -->
    <div class="modal fade" id="autoFixModal" tabindex="-1" aria-hidden="true">
        <div class="modal-dialog">
            <div class="modal-content">
                <div class="modal-header bg-light">
                    <h5 class="modal-title"><i class="bi bi-gear"></i> Cài đặt Drift Auto-fix</h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                </div>
                <div class="modal-body">
                    <p class="text-muted small mb-4">Drift Detection quét dữ liệu Zone từ DirectAdmin mỗi đêm (cron) và so sánh với database WHMCS. Nếu có khác biệt, hệ thống xử lý thế nào?</p>
                    
                    <div class="form-check form-switch fs-5 mb-3">
                        <input class="form-check-input" type="checkbox" id="autoFixToggle" x-model="autoFixEnabled">
                        <label class="form-check-label" for="autoFixToggle">Tự động đẩy WHMCS → DA</label>
                    </div>
                    
                    <div class="alert alert-info border-info mt-3" x-show="autoFixEnabled">
                        <i class="bi bi-info-circle-fill"></i> Hệ thống sẽ <strong class="text-danger">Ghi đè</strong> mọi dữ liệu bị lệch trên DA bằng dữ liệu định quy chuẩn trên WHMCS.
                        <ul class="mb-0 mt-2">
                            <li>Xóa các record có trên DA nhưng không có trên WHMCS</li>
                            <li>Sửa giá trị trên DA thành giá trị trên WHMCS</li>
                            <li>Tạo record trên DA nếu WHMCS có DA chưa có</li>
                        </ul>
                    </div>
                    <div class="alert alert-secondary mt-3" x-show="!autoFixEnabled">
                        Hệ thống chỉ cảnh báo email và tạo báo cáo tại trang này. Quản trị viên phải xử lý thủ công.
                    </div>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-outline-secondary" data-bs-dismiss="modal">Đóng</button>
                    <button type="button" class="btn btn-primary" @click="saveAutoFix()"><i class="bi bi-save"></i> Lưu cài đặt</button>
                </div>
            </div>
        </div>
    </div>
</div>

<script>
{literal}
document.addEventListener('alpine:init', () => {
    Alpine.data('driftManager', () => ({
        filterStatus: 'pending',
        autoFixEnabled: false,
        settingsModal: null,
        domains: [
            {
                id: 1, name: 'example.com', status: 'pending',
                drifts: [
                    { id: 101, type: 'added_on_da', record_type: 'A', record_name: 'test2', whmcs_val: null, da_val: '5.6.7.8' },
                    { id: 102, type: 'modified', record_type: 'TXT', record_name: '@', whmcs_val: 'v=spf1 include:_spf.google.com ~all', da_val: 'v=spf1 include:_spf.zoho.com ~all' }
                ]
            },
            {
                id: 2, name: 'shop.vn', status: 'pending',
                drifts: [
                    { id: 103, type: 'missing_on_da', record_type: 'CNAME', record_name: 'ftp', whmcs_val: 'shop.vn.', da_val: null }
                ]
            }
        ],

        init() {
            this.$nextTick(() => {
                const el = document.getElementById('autoFixModal');
                if (el) this.settingsModal = new bootstrap.Modal(el);
            });
        },

        get driftedDomains() {
            return this.domains.filter(d => d.drifts.length > 0);
        },

        get filteredDomains() {
            if (this.filterStatus === 'all') return this.domains;
            return this.domains.filter(d => d.status === this.filterStatus && d.drifts.length > 0);
        },

        formatRecord(val) {
            if (!val) return '<span class="text-muted fst-italic">(Không tồn tại)</span>';
            // highlight differences could go here
            return val;
        },

        resolve(domain, drift, action) {
            let msg = '';
            if (action === 'push') msg = `Xác nhận: Ghi đè cấu hình DA bằng dữ liệu WHMCS cho ${drift.record_type} ${drift.record_name}?`;
            if (action === 'pull') msg = `Xác nhận: Lấy dữ liệu ${drift.record_type} ${drift.record_name} từ DA cập nhật vào WHMCS?`;
            if (action === 'delete_da') msg = `Xác nhận: XÓA bản ghi ${drift.record_type} ${drift.record_name} trên DA?`;
            if (action === 'delete_whmcs') msg = `Xác nhận: XÓA bản ghi này trong CSDL WHMCS?`;
            if (action === 'ignore') msg = 'Bỏ qua cảnh báo này tới lần quét sau?';
            
            if (confirm(msg)) {
                // Remove drift from domain
                domain.drifts = domain.drifts.filter(d => d.id !== drift.id);
                // Fake saving
                alert('Đã tạo Job đồng bộ (Pending)');
            }
        },

        openSettings() {
            if (this.settingsModal) this.settingsModal.show();
        },

        saveAutoFix() {
            alert('Đã lưu cấu hình Drift Auto-fix!');
            if (this.settingsModal) this.settingsModal.hide();
        },

        runScan() {
            const btn = event.currentTarget;
            let originalContent = btn.innerHTML;
            btn.innerHTML = '<span class="spinner-border spinner-border-sm" aria-hidden="true"></span> Đang quét...';
            btn.disabled = true;

            setTimeout(() => {
                btn.innerHTML = originalContent;
                btn.disabled = false;
                alert('Quét hoàn tất: Không tìm thấy lỗi nào mới.');
            }, 2000);
        }
    }));
});
{/literal}
</script>
