<div class="hvn-dns-admin hvn-drift-reports" x-data="driftManager()">
    <div class="hvn-d-flex hvn-justify-content-between hvn-align-items-center hvn-mb-4">
        <h2><i class="bi bi-arrow-left-right"></i> Báo cáo Lệch Dữ liệu (Drift Reports)</h2>
        <div>
            <button class="hvn-btn hvn-btn-outline-primary hvn-me-2" @click="runScan()"><i class="bi bi-search"></i> Quét thủ công</button>
            <a href="{$modulelink}&action=drift_settings" class="hvn-btn hvn-btn-primary"><i class="bi bi-gear"></i> Cài đặt Auto-fix</a>
        </div>
    </div>

    <div class="hvn-card hvn-shadow-sm hvn-border-0 hvn-mb-4">
        <div class="hvn-card-body hvn-bg-light hvn-rounded hvn-d-flex hvn-justify-content-between hvn-align-items-center">
            <div>
                <span class="hvn-text-muted"><i class="bi bi-clock-history"></i> Lần quét gần nhất:</span> 
                <strong>25/02/2026 02:15</strong>
                <span class="mx-3 hvn-text-muted">|</span>
                <span class="hvn-text-muted">Kế tiếp:</span>
                <strong>26/02/2026 02:00</strong>
            </div>
            <div>
                <select class="hvn-form-select hvn-form-select-sm d-inline-block w-auto" x-model="filterStatus">
                    <option value="all">Tất cả báo cáo</option>
                    <option value="pending">Chỉ hiện sự cố (Pending)</option>
                    <option value="resolved">Đã xử lý (Resolved)</option>
                </select>
            </div>
        </div>
    </div>

    <!-- Cảnh báo nếu có drift -->
    <template x-if="driftedDomains.length > 0 && filterStatus !== 'resolved'">
        <div class="alert alert-warning hvn-border-warning hvn-border-start hvn-shadow-sm hvn-mb-4">
            <h5 class="alert-heading hvn-text-warning-emphasis"><i class="bi bi-exclamation-triangle-fill"></i> Phát hiện <span x-text="driftedDomains.length"></span> domain có dữ liệu sai lệch!</h5>
            <p class="hvn-mb-0">Dữ liệu trên WHMCS (được coi là Source of Truth) đang khác biệt so với dữ liệu thực tế trên DirectAdmin Server.</p>
        </div>
    </template>
    
    <template x-if="driftedDomains.length === 0 || (filterStatus === 'pending' && driftedDomains.length === 0)">
        <div class="hvn-text-center py-5 hvn-text-muted">
            <i class="bi bi-shield-check display-1 hvn-text-success hvn-mb-3 opacity-50"></i>
            <h4>Đồng bộ hoàn hảo</h4>
            <p>Không phát hiện sự sai lệch dữ liệu nào giữa WHMCS và DirectAdmin.</p>
        </div>
    </template>

    <!-- Danh sách Domain bị lệch -->
    <div class="accordion" id="driftAccordion">
        <template x-for="(domain, idx) in filteredDomains" :key="domain.id">
            <div class="accordion-item hvn-mb-3 hvn-border-0 hvn-shadow-sm hvn-rounded overflow-hidden">
                <h2 class="accordion-header" :id="'heading' + domain.id">
                    <button class="accordion-button hvn-bg-white hvn-text-dark hvn-fw-bold hvn-border-bottom" type="button" data-bs-toggle="collapse" :data-bs-target="'#collapse' + domain.id" aria-expanded="true" :aria-controls="'collapse' + domain.id">
                        <span class="fs-5 hvn-me-2" x-text="domain.name"></span> 
                        <span class="hvn-badge hvn-bg-danger hvn-rounded-pill" x-text="domain.drifts.length + ' bản ghi lệch'"></span>
                    </button>
                </h2>
                <div :id="'collapse' + domain.id" class="accordion-collapse collapse show" :aria-labelledby="'heading' + domain.id" data-bs-parent="#driftAccordion">
                    <div class="accordion-body hvn-p-0">
                        <ul class="hvn-list-group hvn-list-group-flush">
                            <!-- Loop qua từng Drift trong Domain -->
                            <template x-for="(drift, dIdx) in domain.drifts" :key="drift.id">
                                <li class="hvn-list-group-item hvn-p-4">
                                    <div class="hvn-d-flex hvn-align-items-start">
                                        <div class="hvn-me-3 hvn-mt-1">
                                            <!-- Icon theo loại lỗi -->
                                            <template x-if="drift.type === 'added_on_da'">
                                                <i class="bi bi-patch-plus hvn-text-info fs-3" title="Có trên DA, không có trên WHMCS"></i>
                                            </template>
                                            <template x-if="drift.type === 'missing_on_da'">
                                                <i class="bi bi-patch-minus hvn-text-danger fs-3" title="Có trên WHMCS, thiếu trên DA"></i>
                                            </template>
                                            <template x-if="drift.type === 'modified'">
                                                <i class="bi bi-patch-exclamation hvn-text-warning fs-3" title="Dữ liệu không khớp"></i>
                                            </template>
                                        </div>
                                        <div class="flex-grow-1">
                                            <div class="hvn-d-flex hvn-justify-content-between hvn-align-items-center hvn-mb-2">
                                                <h6 class="hvn-mb-0 hvn-fw-bold">
                                                    <span class="hvn-badge hvn-bg-secondary hvn-me-2" x-text="drift.type"></span>
                                                    <span class="font-monospace" x-text="drift.record_type + ' ' + drift.record_name"></span>
                                                </h6>
                                            </div>
                                            
                                            <div class="hvn-row g-3 hvn-mb-3 font-monospace small">
                                                <div class="hvn-col-md-6">
                                                    <div class="hvn-card hvn-border-0 hvn-bg-light">
                                                        <div class="hvn-card-header hvn-py-1 bg-transparent hvn-border-bottom-0 hvn-text-muted hvn-fw-bold"><i class="bi bi-database"></i> WHMCS (Truth)</div>
                                                        <div class="hvn-card-body hvn-py-2 text-break" x-html="formatRecord(drift.whmcs_val)"></div>
                                                    </div>
                                                </div>
                                                <div class="hvn-col-md-6">
                                                    <div class="hvn-card hvn-border-0 hvn-bg-light">
                                                        <div class="hvn-card-header hvn-py-1 bg-transparent hvn-border-bottom-0 hvn-text-muted hvn-fw-bold"><i class="bi bi-server"></i> DirectAdmin</div>
                                                        <div class="hvn-card-body hvn-py-2 text-break" x-text="drift.da_val || '(Không tồn tại)'"></div>
                                                    </div>
                                                </div>
                                            </div>

                                            <div class="btn-group btn-group-sm">
                                                <template x-if="drift.type === 'added_on_da'">
                                                    <button class="hvn-btn hvn-btn-outline-primary" @click="resolve(domain, drift, 'pull')"><i class="bi bi-box-arrow-in-down"></i> Pull DA → WHMCS</button>
                                                </template>
                                                <template x-if="drift.type === 'added_on_da'">
                                                    <button class="hvn-btn btn-outline-danger" @click="resolve(domain, drift, 'delete_da')"><i class="bi bi-trash"></i> Xóa trên DA</button>
                                                </template>

                                                <template x-if="drift.type === 'missing_on_da'">
                                                    <button class="hvn-btn btn-outline-success" @click="resolve(domain, drift, 'push')"><i class="bi bi-box-arrow-up"></i> Push WHMCS → DA</button>
                                                </template>
                                                <template x-if="drift.type === 'missing_on_da'">
                                                    <button class="hvn-btn btn-outline-danger" @click="resolve(domain, drift, 'delete_whmcs')"><i class="bi bi-trash"></i> Xóa trong WHMCS</button>
                                                </template>

                                                <template x-if="drift.type === 'modified'">
                                                    <button class="hvn-btn hvn-btn-outline-primary" @click="resolve(domain, drift, 'pull')"><i class="bi bi-box-arrow-in-down"></i> Pull DA → WHMCS</button>
                                                </template>
                                                <template x-if="drift.type === 'modified'">
                                                    <button class="hvn-btn btn-outline-success" @click="resolve(domain, drift, 'push')"><i class="bi bi-box-arrow-up"></i> Push WHMCS → DA</button>
                                                </template>

                                                <button class="hvn-btn btn-outline-secondary" @click="resolve(domain, drift, 'ignore')"><i class="bi bi-eye-slash"></i> Bỏ qua</button>
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


</div>

<script>
{literal}
document.addEventListener('alpine:init', () => {
    Alpine.data('driftManager', () => ({
        filterStatus: 'pending',
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

        get driftedDomains() {
            return this.domains.filter(d => d.drifts.length > 0);
        },

        get filteredDomains() {
            if (this.filterStatus === 'all') return this.domains;
            return this.domains.filter(d => d.status === this.filterStatus && d.drifts.length > 0);
        },

        formatRecord(val) {
            if (!val) return '<span class="hvn-text-muted fst-italic">(Không tồn tại)</span>';
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



        runScan() {
            const btn = event.currentTarget;
            let originalContent = btn.innerHTML;
            btn.innerHTML = '<span class="hvn-spinner-border hvn-spinner-border-sm" aria-hidden="true"></span> Đang quét...';
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
