<script>
if (!window.Alpine) {
    var s = document.createElement('script');
    s.src = 'https://cdn.jsdelivr.net/npm/alpinejs@3.x.x/dist/cdn.min.js';
    s.defer = true;
    document.head.appendChild(s);
}
</script>
<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css">

<div class="hvn-dns-client hvn-record-edit" x-data="recordEditor()">
    <!-- Header -->
    <div class="d-flex justify-content-between align-items-center mb-4">
        <a :href="'index.php?m=hvn_dns_manager&domain_id=' + domainId" class="text-decoration-none text-muted">
            <i class="bi bi-arrow-left"></i> Quay lại cấu hình bản ghi
        </a>
    </div>

    <div class="card border-0 shadow-sm">
        <div class="card-header bg-white border-bottom-0 pt-4 pb-0">
            <h4 class="mb-0">
                <i class="bi bi-hdd-network text-primary"></i> <span x-text="isEdit ? 'Sửa bản ghi DNS' : 'Thêm bản ghi DNS'"></span>
            </h4>
        </div>
        <div class="card-body p-4">
            <form @submit.prevent="saveRecord">
                <div class="row">
                    <div class="col-md-6 mb-3">
                        <label for="recordType" class="form-label fw-bold">Loại bản ghi <span class="text-danger">*</span></label>
                        <select class="form-select" id="recordType" x-model="form.type" :disabled="isEdit">
                            <option value="A">A &mdash; Trỏ tới địa chỉ IPv4</option>
                            <option value="AAAA">AAAA &mdash; Trỏ tới địa chỉ IPv6</option>
                            <option value="CNAME">CNAME &mdash; Bí danh (Alias)</option>
                            <option value="MX">MX &mdash; Máy chủ nhận email</option>
                            <option value="TXT">TXT &mdash; Văn bản (SPF, DKIM, ...)</option>
                            <option value="SRV">SRV &mdash; Dịch vụ (SIP, XMPP,...)</option>
                            <option value="CAA">CAA &mdash; Ủy quyền chứng chỉ SSL</option>
                        </select>
                    </div>

                    <div class="col-md-6 mb-3">
                        <label for="recordName" class="form-label fw-bold">Tên (Subdomain) <span class="text-danger">*</span></label>
                        <div class="input-group">
                            <input type="text" class="form-control" id="recordName" x-model="form.name" :disabled="isEdit" placeholder="@">
                            <span class="input-group-text bg-light text-muted">.{$domain.domain}</span>
                        </div>
                        <div class="form-text"><i class="bi bi-info-circle"></i> Nhập @ cho domain gốc, * cho wildcard</div>
                    </div>
                </div>

                <div class="mb-3">
                    <label for="recordValue" class="form-label fw-bold">Giá trị <span class="text-danger">*</span></label>
                    <input type="text" class="form-control font-monospace" id="recordValue" x-model="form.value" required>
                    <div class="form-text text-primary mt-1" x-text="helperText"></div>
                </div>

                <!-- Extra fields for MX/SRV -->
                <template x-if="showPriority">
                    <div class="card border-light bg-light mb-3">
                        <div class="card-body py-3 row">
                            <div class="col-md-4">
                                <label for="recordPriority" class="form-label fw-bold mb-1">Priority <span class="text-danger">*</span></label>
                                <input type="number" class="form-control form-control-sm font-monospace" id="recordPriority" x-model="form.priority" required min="0" max="65535">
                                <div class="form-text small">Số nhỏ = ưu tiên (VD: 10)</div>
                            </div>
                            <template x-if="showWeightPort">
                                <div class="col-md-4">
                                    <label for="recordWeight" class="form-label fw-bold mb-1">Weight</label>
                                    <input type="number" class="form-control form-control-sm font-monospace" id="recordWeight" x-model="form.weight" min="0" max="65535">
                                </div>
                            </template>
                            <template x-if="showWeightPort">
                                <div class="col-md-4">
                                    <label for="recordPort" class="form-label fw-bold mb-1">Port <span class="text-danger">*</span></label>
                                    <input type="number" class="form-control form-control-sm font-monospace" id="recordPort" x-model="form.port" required min="1" max="65535">
                                </div>
                            </template>
                        </div>
                    </div>
                </template>

                <div class="row">
                    <div class="col-md-6 mb-4">
                        <label for="recordTtl" class="form-label fw-bold">TTL (Thời gian cache)</label>
                        <select class="form-select font-monospace" id="recordTtl" x-model="form.ttl">
                            <option value="60">1 phút (60) &mdash; Thay đổi liên tục</option>
                            <option value="300">5 phút (300) &mdash; DDNS</option>
                            <option value="1800">30 phút (1800) &mdash; Thường dùng</option>
                            <option value="3600">1 giờ (3600) &mdash; Mặc định</option>
                            <option value="43200">12 giờ (43200) &mdash; Ít thay đổi</option>
                            <option value="86400">24 giờ (86400) &mdash; Rất ổn định</option>
                        </select>
                    </div>
                </div>

                <div class="d-flex justify-content-end gap-2 pt-3 border-top mt-2">
                    <a :href="'index.php?m=hvn_dns_manager&domain_id=' + domainId" class="btn btn-outline-secondary" :class="{'disabled': submitting}">Hủy</a>
                    <button type="submit" class="btn btn-primary" :disabled="submitting">
                        <span x-show="!submitting"><i class="bi bi-save me-1"></i> Lưu bản ghi</span>
                        <span x-show="submitting"><span class="spinner-border spinner-border-sm me-1" role="status" aria-hidden="true"></span> Đang xử lý...</span>
                    </button>
                </div>
            </form>
        </div>
    </div>
</div>

<script>
{literal}
document.addEventListener('alpine:init', () => {
    Alpine.data('recordEditor', () => ({
        isEdit: false,
        domainId: {/literal}{$domain.id}{literal},
        form: { id: null, type: 'A', name: '', value: '', priority: 10, weight: 0, port: 443, ttl: 3600 },
        submitting: false,
        recordJson: {/literal}'{$recordJson|escape:'javascript'}'{literal},
        
        init() {
            if (this.recordJson && this.recordJson !== 'null' && this.recordJson !== '') {
                try {
                    const parsed = JSON.parse(this.recordJson);
                    if (parsed && Object.keys(parsed).length > 0) {
                        this.isEdit = true;
                        this.form = { ...this.form, ...parsed };
                    }
                } catch(e) {
                    console.error("Lỗi parse record JSON", e);
                }
            } else {
                const urlParams = new URLSearchParams(window.location.search);
                const type = urlParams.get('type');
                if (type) {
                    this.form.type = type;
                }
            }
        },
        
        get helperText() {
            const helpers = {
                'A': 'Trỏ tới địa chỉ IPv4 (VD: 103.45.67.89)',
                'AAAA': 'Trỏ tới địa chỉ IPv6',
                'CNAME': 'Bí danh (Alias), phải là FQDN',
                'MX': 'Máy chủ nhận email (cần điền Priority)',
                'TXT': 'Văn bản (Dùng cho SPF, DKIM, xác minh...)',
                'SRV': 'Dịch vụ (cần Priority, Weight, Port)',
                'NS': 'Máy chủ phân giải tên miền',
                'CAA': 'Ủy quyền chứng chỉ SSL'
            };
            return helpers[this.form.type] || '';
        },
        
        get showPriority() { return ['MX', 'SRV'].includes(this.form.type); },
        get showWeightPort() { return this.form.type === 'SRV'; },
        
        saveRecord() {
            this.submitting = true;
            // Mock API save
            setTimeout(() => {
                alert('Đã lưu bản ghi thành công!');
                window.location.href = `index.php?m=hvn_dns_manager&domain_id=${this.domainId}`;
            }, 800);
        }
    }));
});
{/literal}
</script>

<script src="https://cdn.jsdelivr.net/npm/alpinejs@3.x.x/dist/cdn.min.js" defer></script>
