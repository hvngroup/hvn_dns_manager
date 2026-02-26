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
                        <div class="table-responsive">
                            <table class="table table-sm align-middle hvn-mb-0 font-monospace" style="font-size: 12px;">
                                <thead class="table-light">
                                    <tr>
                                        <th class="hvn-ps-3" style="width: 200px;">Loại lỗi</th>
                                        <th><i class="bi bi-database hvn-text-primary"></i> WHMCS DB</th>
                                        <th><i class="bi bi-server hvn-text-secondary"></i> DirectAdmin</th>
                                        <th class="hvn-text-end hvn-pe-3" style="width: 260px;">Hành động</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <!-- Loop qua từng Drift trong Domain -->
                                    <template x-for="(drift, dIdx) in domain.drifts" :key="drift.id">
                                        <tr>
                                            <!-- Cột 1: Loại lỗi -->
                                            <td class="hvn-ps-3">
                                                <template x-if="drift.type === 'added_on_da'">
                                                    <span class="hvn-badge hvn-bg-info hvn-text-dark">
                                                        <i class="bi bi-patch-plus"></i> added_on_da
                                                    </span>
                                                </template>
                                                <template x-if="drift.type === 'missing_on_da'">
                                                    <span class="hvn-badge hvn-bg-danger">
                                                        <i class="bi bi-patch-minus"></i> missing_on_da
                                                    </span>
                                                </template>
                                                <template x-if="drift.type === 'modified'">
                                                    <span class="hvn-badge hvn-bg-warning hvn-text-dark">
                                                        <i class="bi bi-patch-exclamation"></i> modified
                                                    </span>
                                                </template>
                                                <div class="hvn-mt-1 hvn-fw-bold" x-text="drift.record_type + ' ' + drift.record_name"></div>
                                            </td>

                                            <!-- Cột 2: WHMCS DB -->
                                            <td class="text-break" style="max-width: 220px;">
                                                <template x-if="drift.whmcs_val">
                                                    <span x-html="formatRecord(drift.whmcs_val)"></span>
                                                </template>
                                                <template x-if="!drift.whmcs_val">
                                                    <span class="hvn-text-muted fst-italic">(Không tồn tại)</span>
                                                </template>
                                            </td>

                                            <!-- Cột 3: DirectAdmin -->
                                            <td class="text-break" style="max-width: 220px;">
                                                <template x-if="drift.da_val">
                                                    <span x-text="drift.da_val"></span>
                                                </template>
                                                <template x-if="!drift.da_val">
                                                    <span class="hvn-text-muted fst-italic">(Không tồn tại)</span>
                                                </template>
                                            </td>

                                            <!-- Cột 4: Hành động -->
                                            <td class="hvn-text-end hvn-pe-3">
                                                <div class="btn-group btn-group-sm">
                                                    <template x-if="drift.type === 'added_on_da'">
                                                        <button class="hvn-btn hvn-btn-outline-primary" @click="resolve(domain, drift, 'pull')" title="Lấy về WHMCS">
                                                            <i class="bi bi-box-arrow-in-down"></i> Pull
                                                        </button>
                                                    </template>
                                                    <template x-if="drift.type === 'added_on_da'">
                                                        <button class="hvn-btn btn-outline-danger" @click="resolve(domain, drift, 'delete_da')" title="Xóa trên DA">
                                                            <i class="bi bi-trash"></i> Xóa DA
                                                        </button>
                                                    </template>

                                                    <template x-if="drift.type === 'missing_on_da'">
                                                        <button class="hvn-btn btn-outline-success" @click="resolve(domain, drift, 'push')" title="Đẩy lên DA">
                                                            <i class="bi bi-box-arrow-up"></i> Push
                                                        </button>
                                                    </template>
                                                    <template x-if="drift.type === 'missing_on_da'">
                                                        <button class="hvn-btn btn-outline-danger" @click="resolve(domain, drift, 'delete_whmcs')" title="Xóa trong WHMCS">
                                                            <i class="bi bi-trash"></i> Xóa WHMCS
                                                        </button>
                                                    </template>

                                                    <template x-if="drift.type === 'modified'">
                                                        <button class="hvn-btn hvn-btn-outline-primary" @click="resolve(domain, drift, 'pull')" title="Ghi đè bằng dữ liệu DA">
                                                            <i class="bi bi-box-arrow-in-down"></i> Pull
                                                        </button>
                                                    </template>
                                                    <template x-if="drift.type === 'modified'">
                                                        <button class="hvn-btn btn-outline-success" @click="resolve(domain, drift, 'push')" title="Ghi đè DA bằng dữ liệu WHMCS">
                                                            <i class="bi bi-box-arrow-up"></i> Push
                                                        </button>
                                                    </template>

                                                    <button class="hvn-btn btn-outline-secondary" @click="resolve(domain, drift, 'ignore')" title="Bỏ qua lần này">
                                                        <i class="bi bi-eye-slash"></i> Bỏ qua
                                                    </button>
                                                </div>
                                            </td>
                                        </tr>
                                    </template>
                                </tbody>
                            </table>
                        </div>
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
