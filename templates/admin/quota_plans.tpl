<div class="hvn-dns-admin hvn-quota-plans" x-data="quotaPlansManager()">
    <div class="hvn-d-flex hvn-justify-content-between hvn-align-items-center hvn-mb-4">
        <h2><i class="bi bi-box-seam"></i> Quản lý Gói Quota</h2>
        <a href="{$modulelink}&action=quota_plan_edit" class="hvn-btn hvn-btn-primary"><i class="bi bi-plus-lg"></i> Tạo Gói Mới</a>
    </div>

    <div class="alert alert-info border-info hvn-d-flex hvn-align-items-center">
        <i class="bi bi-info-circle-fill hvn-me-3 fs-3"></i>
        <div>
            Mỗi <strong>Quota Plan</strong> định nghĩa giới hạn số lượng bản ghi và quyền sử dụng tính năng cao cấp. Thường sử dụng Model này để cấu hình <code>Module Settings</code> trong WHMCS Products/Services tương ứng với các mức giá khác nhau.
        </div>
    </div>

    <div class="hvn-card hvn-shadow-sm hvn-border-0">
        <div class="hvn-card-body hvn-p-0">
            <div class="table-responsive">
                <table class="table table-hover align-middle hvn-mb-0 hvn-text-center">
                    <thead class="table-dark">
                        <tr>
                            <th class="hvn-ps-4 text-start">Tên Gói</th>
                            <th>Mô tả</th>
                            <th>Tổng Records</th>
                            <th>Subdomains</th>
                            <th>Redirects</th>
                            <th>Email Fwd</th>
                            <th>DDNS Tokens</th>
                            <th>DNSSEC</th>
                            <th class="hvn-pe-4 hvn-text-end">Thao tác</th>
                        </tr>
                    </thead>
                    <tbody>
                        <template x-for="plan in plans" :key="plan.id">
                            <tr>
                                <td class="hvn-ps-4 text-start hvn-fw-bold hvn-text-primary" x-text="plan.name"></td>
                                <td class="text-start hvn-text-muted small" x-text="plan.description"></td>
                                <td class="font-monospace hvn-fw-bold" x-text="formatLimit(plan.limit_records)"></td>
                                <td class="font-monospace hvn-text-muted" x-text="formatLimit(plan.limit_subdomains)"></td>
                                <td class="font-monospace hvn-text-muted" x-text="formatLimit(plan.limit_redirects)"></td>
                                <td class="font-monospace hvn-text-muted" x-text="formatLimit(plan.limit_emails)"></td>
                                <td>
                                    <template x-if="plan.ddns_enabled">
                                        <span class="hvn-badge hvn-bg-success" x-text="formatLimit(plan.limit_ddns) + ' token'"></span>
                                    </template>
                                    <template x-if="!plan.ddns_enabled">
                                        <span class="hvn-badge" style="background: #e2e3e5; color: #6c757d;">❌ Không</span>
                                    </template>
                                </td>
                                <td>
                                    <template x-if="plan.dnssec_enabled">
                                        <span class="hvn-badge hvn-bg-success"><i class="bi bi-shield-check"></i> Có</span>
                                    </template>
                                    <template x-if="!plan.dnssec_enabled">
                                        <span class="hvn-badge" style="background: #e2e3e5; color: #6c757d;">❌ Không</span>
                                    </template>
                                </td>
                                <td class="hvn-pe-4 hvn-text-end">
                                    <a :href="'{$modulelink}&action=quota_plan_edit&id=' + plan.id" class="hvn-btn btn-sm hvn-btn-outline-primary"><i class="bi bi-pencil"></i></a>
                                    <button class="hvn-btn btn-sm btn-outline-danger" @click="deletePlan(plan)"><i class="bi bi-trash"></i></button>
                                </td>
                            </tr>
                        </template>
                    </tbody>
                </table>
            </div>
        </div>
        <div class="hvn-card-footer hvn-bg-light hvn-text-muted small hvn-py-2">
            <i class="bi bi-infinity"></i> Ký hiệu `<span class="fs-5 hvn-fw-bold hvn-text-dark">∞</span>` tương đương với cấu hình không giới hạn (giá trị <code>0</code> trong DB).
        </div>
    </div>


</div>

<script>
{literal}
document.addEventListener('alpine:init', () => {
    Alpine.data('quotaPlansManager', () => ({
        isOpen: false,
        plans: [
            { id: 1, name: 'Basic Tier', description: 'Gói miễn phí đi kèm Shared Hosting', limit_records: 20, limit_subdomains: 10, limit_redirects: 2, limit_emails: 5, dnssec_enabled: false, ddns_enabled: false, limit_ddns: 0 },
            { id: 2, name: 'Pro Tier', description: 'Dành cho khách hàng mua riêng dịch vụ DNS', limit_records: 50, limit_subdomains: 20, limit_redirects: 5, limit_emails: 10, dnssec_enabled: false, ddns_enabled: true, limit_ddns: 2 },
            { id: 3, name: 'Enterprise / VIP', description: 'Dành cho VPS/Server, mọi tính năng mở', limit_records: 0, limit_subdomains: 0, limit_redirects: 0, limit_emails: 0, dnssec_enabled: true, ddns_enabled: true, limit_ddns: 10 }
        ],
        
        formatLimit(val) {
            return (val === 0 || val === '0') ? '∞' : val;
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
