<div class="hvn-dns-admin hvn-quota-plans" x-data="quotaPlansManager()">
    <div class="d-flex justify-content-between align-items-center mb-4">
        <h2><i class="bi bi-box-seam"></i> Quản lý Gói Quota</h2>
        <button class="btn btn-primary" @click="openModal()"><i class="bi bi-plus-lg"></i> Tạo Gói Mới</button>
    </div>

    <div class="alert alert-info border-info d-flex align-items-center">
        <i class="bi bi-info-circle-fill me-3 fs-3"></i>
        <div>
            Mỗi <strong>Quota Plan</strong> định nghĩa giới hạn số lượng bản ghi và quyền sử dụng tính năng cao cấp. Thường sử dụng Model này để cấu hình <code>Module Settings</code> trong WHMCS Products/Services tương ứng với các mức giá khác nhau.
        </div>
    </div>

    <div class="card shadow-sm border-0">
        <div class="card-body p-0">
            <div class="table-responsive">
                <table class="table table-hover align-middle mb-0 text-center">
                    <thead class="table-dark">
                        <tr>
                            <th class="ps-4 text-start">Tên Gói</th>
                            <th>Mô tả</th>
                            <th>Tổng Records</th>
                            <th>Subdomains</th>
                            <th>Redirects</th>
                            <th>Email Fwd</th>
                            <th>DDNS Tokens</th>
                            <th>DNSSEC</th>
                            <th class="pe-4 text-end">Thao tác</th>
                        </tr>
                    </thead>
                    <tbody>
                        <template x-for="plan in plans" :key="plan.id">
                            <tr>
                                <td class="ps-4 text-start fw-bold text-primary" x-text="plan.name"></td>
                                <td class="text-start text-muted small" x-text="plan.description"></td>
                                <td class="font-monospace fw-bold" x-text="formatLimit(plan.limit_records)"></td>
                                <td class="font-monospace text-muted" x-text="formatLimit(plan.limit_subdomains)"></td>
                                <td class="font-monospace text-muted" x-text="formatLimit(plan.limit_redirects)"></td>
                                <td class="font-monospace text-muted" x-text="formatLimit(plan.limit_emails)"></td>
                                <td>
                                    <template x-if="plan.ddns_enabled">
                                        <span class="badge bg-success" x-text="formatLimit(plan.limit_ddns) + ' token'"></span>
                                    </template>
                                    <template x-if="!plan.ddns_enabled">
                                        <span class="badge" style="background: #e2e3e5; color: #6c757d;">❌ Không</span>
                                    </template>
                                </td>
                                <td>
                                    <template x-if="plan.dnssec_enabled">
                                        <span class="badge bg-success"><i class="bi bi-shield-check"></i> Có</span>
                                    </template>
                                    <template x-if="!plan.dnssec_enabled">
                                        <span class="badge" style="background: #e2e3e5; color: #6c757d;">❌ Không</span>
                                    </template>
                                </td>
                                <td class="pe-4 text-end">
                                    <button class="btn btn-sm btn-outline-primary" @click="openModal(plan)"><i class="bi bi-pencil"></i></button>
                                    <button class="btn btn-sm btn-outline-danger" @click="deletePlan(plan)"><i class="bi bi-trash"></i></button>
                                </td>
                            </tr>
                        </template>
                    </tbody>
                </table>
            </div>
        </div>
        <div class="card-footer bg-light text-muted small py-2">
            <i class="bi bi-infinity"></i> Ký hiệu `<span class="fs-5 fw-bold text-dark">∞</span>` tương đương với cấu hình không giới hạn (giá trị <code>0</code> trong DB).
        </div>
    </div>

    <!-- Edit Modal -->
    <div class="modal fade" id="quotaModal" tabindex="-1" aria-hidden="true">
        <div class="modal-dialog modal-lg">
            <div class="modal-content">
                <div class="modal-header bg-light">
                    <h5 class="modal-title"><i class="bi bi-sliders"></i> <span x-text="isEdit ? 'Sửa cấu hình Gói' : 'Tạo Quota Plan mới'"></span></h5>
                    <button type="button" class="btn-close" @click="closeModal()"></button>
                </div>
                <div class="modal-body p-4">
                    <div class="row mb-4">
                        <div class="col-md-6">
                            <label class="form-label fw-bold">Tên gói <span class="text-danger">*</span></label>
                            <input type="text" class="form-control" x-model="form.name" required>
                        </div>
                        <div class="col-md-6">
                            <label class="form-label fw-bold">Mô tả nội bộ / Ghi chú</label>
                            <input type="text" class="form-control text-muted" x-model="form.description">
                        </div>
                    </div>

                    <h6 class="border-bottom pb-2 mb-3 text-primary"><i class="bi bi-speedometer2"></i> Giới hạn số lượng (Nhập 0 để không giới hạn)</h6>
                    
                    <div class="row g-3 mb-4">
                        <div class="col-md-3">
                            <label class="form-label small mb-1">Tổng Records</label>
                            <div class="input-group input-group-sm">
                                <input type="number" class="form-control form-control-sm text-center font-monospace font-weight-bold" x-model="form.limit_records" min="0">
                            </div>
                        </div>
                        <div class="col-md-3">
                            <label class="form-label small mb-1">Subdomains</label>
                            <div class="input-group input-group-sm">
                                <input type="number" class="form-control form-control-sm text-center font-monospace" x-model="form.limit_subdomains" min="0">
                            </div>
                        </div>
                        <div class="col-md-3">
                            <label class="form-label small mb-1">URL Redirects</label>
                            <div class="input-group input-group-sm">
                                <input type="number" class="form-control form-control-sm text-center font-monospace" x-model="form.limit_redirects" min="0">
                            </div>
                        </div>
                        <div class="col-md-3">
                            <label class="form-label small mb-1">Email Forwards</label>
                            <div class="input-group input-group-sm">
                                <input type="number" class="form-control form-control-sm text-center font-monospace" x-model="form.limit_emails" min="0">
                            </div>
                        </div>
                    </div>

                    <h6 class="border-bottom pb-2 mb-3 text-primary"><i class="bi bi-award"></i> Tính năng Cao cấp (Premium Options)</h6>

                    <div class="row g-4">
                        <div class="col-md-6">
                            <div class="card bg-light border-0 shadow-sm h-100">
                                <div class="card-body">
                                    <div class="form-check form-switch mb-2">
                                        <input class="form-check-input" type="checkbox" id="featureDNSSEC" x-model="form.dnssec_enabled">
                                        <label class="form-check-label fw-bold" for="featureDNSSEC">Cho phép sử dụng DNSSEC</label>
                                    </div>
                                    <p class="small text-muted mb-0">Hiển thị tab DNSSEC và cho phép quản lý khóa KSK/ZSK. Mức giá Upsell phụ thuộc Settings hệ thống.</p>
                                </div>
                            </div>
                        </div>
                        <div class="col-md-6">
                            <div class="card bg-light border-0 shadow-sm h-100">
                                <div class="card-body">
                                    <div class="form-check form-switch mb-2">
                                        <input class="form-check-input" type="checkbox" id="featureDDNS" x-model="form.ddns_enabled">
                                        <label class="form-check-label fw-bold" for="featureDDNS">Cho phép dùng Dynamic DNS</label>
                                    </div>
                                    <div class="mt-2" x-show="form.ddns_enabled">
                                        <label class="form-label small mb-1">Giới hạn số token DDNS:</label>
                                        <div class="input-group input-group-sm w-50">
                                            <input type="number" class="form-control form-control-sm text-center font-monospace" x-model="form.limit_ddns" min="1">
                                            <span class="input-group-text bg-white">tokens</span>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>

                </div>
                <div class="modal-footer bg-light">
                    <button type="button" class="btn btn-outline-secondary" @click="closeModal()">Hủy</button>
                    <button type="button" class="btn btn-primary" @click="savePlan()">
                        <i class="bi bi-save"></i> <span x-text="isEdit ? 'Cập nhật' : 'Tạo Gói'"></span>
                    </button>
                </div>
            </div>
        </div>
    </div>
</div>

<script>
{literal}
document.addEventListener('alpine:init', () => {
    Alpine.data('quotaPlansManager', () => ({
        plans: [
            { id: 1, name: 'Basic Tier', description: 'Gói miễn phí đi kèm Shared Hosting', limit_records: 20, limit_subdomains: 10, limit_redirects: 2, limit_emails: 5, dnssec_enabled: false, ddns_enabled: false, limit_ddns: 0 },
            { id: 2, name: 'Pro Tier', description: 'Dành cho khách hàng mua riêng dịch vụ DNS', limit_records: 50, limit_subdomains: 20, limit_redirects: 5, limit_emails: 10, dnssec_enabled: false, ddns_enabled: true, limit_ddns: 2 },
            { id: 3, name: 'Enterprise / VIP', description: 'Dành cho VPS/Server, mọi tính năng mở', limit_records: 0, limit_subdomains: 0, limit_redirects: 0, limit_emails: 0, dnssec_enabled: true, ddns_enabled: true, limit_ddns: 10 }
        ],
        
        isEdit: false,
        form: { id: null, name: '', description: '', limit_records: 0, limit_subdomains: 0, limit_redirects: 0, limit_emails: 0, dnssec_enabled: false, ddns_enabled: false, limit_ddns: 0 },
        modalInstance: null,

        init() {
            this.$nextTick(() => {
                const el = document.getElementById('quotaModal');
                if (el) this.modalInstance = new bootstrap.Modal(el);
            });
        },

        formatLimit(val) {
            return (val === 0 || val === '0') ? '∞' : val;
        },

        openModal(plan = null) {
            this.isEdit = !!plan;
            if(plan) {
                this.form = JSON.parse(JSON.stringify(plan));
            } else {
                this.form = { id: Date.now(), name: '', description: '', limit_records: 50, limit_subdomains: 10, limit_redirects: 2, limit_emails: 2, dnssec_enabled: false, ddns_enabled: false, limit_ddns: 1 };
            }
            if(this.modalInstance) this.modalInstance.show();
        },

        closeModal() {
            if(this.modalInstance) this.modalInstance.hide();
        },

        savePlan() {
            if(!this.form.name) return alert('Vui lòng điền tên Quota Plan.');
            
            if(this.isEdit) {
                const idx = this.plans.findIndex(p => p.id === this.form.id);
                if(idx > -1) this.plans[idx] = JSON.parse(JSON.stringify(this.form));
            } else {
                this.plans.push(JSON.parse(JSON.stringify(this.form)));
            }
            alert('Đã lưu cấu hình Gói!');
            this.closeModal();
        },

        deletePlan(plan) {
            if(confirm(`Cảnh báo: Xóa gói "${plan.name}" có thể gây lỗi nạp Quota cho các dịch vụ đang sử dụng gói này. Bạn chắc chắn chứ?`)) {
                this.plans = this.plans.filter(p => p.id !== plan.id);
            }
        }
    }));
});
{/literal}
</script>
