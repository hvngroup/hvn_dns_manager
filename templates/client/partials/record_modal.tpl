<!-- Record Modal -->
<div class="modal fade" id="recordModal" tabindex="-1" aria-labelledby="recordModalLabel" aria-hidden="true" x-data="{
    isEdit: false,
    form: { id: null, type: 'A', name: '', value: '', priority: 10, weight: 0, port: 443, ttl: 3600 },
    submitting: false,
    
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
    
    closeModal() {
        bootstrap.Modal.getInstance(document.getElementById('recordModal')).hide();
    },
    
    saveRecord() {
        this.submitting = true;
        // Mock API call delay
        setTimeout(() => {
            this.submitting = false;
            this.closeModal();
            // Show toast notification
            showToast('Thành công', 'Đã lưu bản ghi! Hệ thống đang đồng bộ...', 'success');
        }, 800);
    }
}" @open-record-modal.window="
    isEdit = $event.detail.isEdit;
    if(isEdit) {
        form = { ...$event.detail.record };
    } else {
        form = { id: null, type: 'A', name: '', value: '', priority: 10, weight: 0, port: 443, ttl: 3600 };
    }
    new bootstrap.Modal(document.getElementById('recordModal')).show();
">
    <div class="modal-dialog">
        <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title" id="recordModalLabel" x-text="isEdit ? 'Sửa bản ghi DNS' : 'Thêm bản ghi DNS'"></h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
            </div>
            <div class="modal-body">
                <form @submit.prevent="saveRecord">
                    <div class="mb-3">
                        <label for="recordType" class="form-label">Loại bản ghi <span class="text-danger">*</span></label>
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

                    <div class="mb-3">
                        <label for="recordName" class="form-label">Tên (Subdomain) <span class="text-danger">*</span></label>
                        <div class="input-group">
                            <input type="text" class="form-control" id="recordName" x-model="form.name" :disabled="isEdit" placeholder="@">
                            <span class="input-group-text">.{$domain.domain}</span>
                        </div>
                        <div class="form-text"><i class="bi bi-info-circle"></i> Nhập @ cho domain gốc, * cho wildcard</div>
                    </div>

                    <div class="mb-3">
                        <label for="recordValue" class="form-label">Giá trị <span class="text-danger">*</span></label>
                        <input type="text" class="form-control" id="recordValue" x-model="form.value" required>
                        <div class="form-text text-primary" x-text="helperText"></div>
                    </div>

                    <!-- Extra fields for MX/SRV -->
                    <template x-if="showPriority">
                        <div class="row mb-3">
                            <div class="col-md-4">
                                <label for="recordPriority" class="form-label">Priority <span class="text-danger">*</span></label>
                                <input type="number" class="form-control" id="recordPriority" x-model="form.priority" required min="0" max="65535">
                                <div class="form-text">Số nhỏ = ưu tiên (VD: 10)</div>
                            </div>
                            <template x-if="showWeightPort">
                                <div class="col-md-4">
                                    <label for="recordWeight" class="form-label">Weight</label>
                                    <input type="number" class="form-control" id="recordWeight" x-model="form.weight" min="0" max="65535">
                                </div>
                            </template>
                            <template x-if="showWeightPort">
                                <div class="col-md-4">
                                    <label for="recordPort" class="form-label">Port <span class="text-danger">*</span></label>
                                    <input type="number" class="form-control" id="recordPort" x-model="form.port" required min="1" max="65535">
                                </div>
                            </template>
                        </div>
                    </template>

                    <div class="mb-4">
                        <label for="recordTtl" class="form-label">TTL (Thời gian cache)</label>
                        <select class="form-select" id="recordTtl" x-model="form.ttl">
                            <option value="60">1 phút (60) &mdash; Thay đổi liên tục</option>
                            <option value="300">5 phút (300) &mdash; DDNS</option>
                            <option value="1800">30 phút (1800) &mdash; Thường dùng</option>
                            <option value="3600">1 giờ (3600) &mdash; Mặc định</option>
                            <option value="43200">12 giờ (43200) &mdash; Ít thay đổi</option>
                            <option value="86400">24 giờ (86400) &mdash; Rất ổn định</option>
                        </select>
                    </div>

                    <div class="d-flex justify-content-end gap-2">
                        <button type="button" class="btn btn-outline-secondary" @click="closeModal()" :disabled="submitting">Hủy</button>
                        <button type="submit" class="btn btn-primary" :disabled="submitting">
                            <span x-show="!submitting"><i class="bi bi-save"></i> Lưu bản ghi</span>
                            <span x-show="submitting"><span class="spinner-border spinner-border-sm" role="status" aria-hidden="true"></span> Đang lưu...</span>
                        </button>
                    </div>
                </form>
            </div>
        </div>
    </div>
</div>

<!-- Toast Container -->
<div class="toast-container position-fixed bottom-0 end-0 p-3" style="z-index: 1080">
    <div id="actionToast" class="toast align-items-center text-white border-0" role="alert" aria-live="assertive" aria-atomic="true">
        <div class="d-flex">
            <div class="toast-body" id="toastMessage"></div>
            <button type="button" class="btn-close btn-close-white me-2 m-auto" data-bs-dismiss="toast" aria-label="Close"></button>
        </div>
    </div>
</div>

<script>
    // Alpine functions to trigger global event
    document.addEventListener('alpine:init', () => {
        Alpine.data('modalHelpers', () => ({}));
    });

    // We can merge this into our main Alpine component on dns_editor.tpl -> methods
    // Adding openAddModal and openEditModal directly bound to window.dispatchEvent
    document.addEventListener('alpine:initialized', () => {
        if (Alpine.$data(document.querySelector('.hvn-dns-client'))) {
            const data = Alpine.$data(document.querySelector('.hvn-dns-client'));
            data.openAddModal = function() {
                window.dispatchEvent(new CustomEvent('open-record-modal', { detail: { isEdit: false } }));
            };
            data.openEditModal = function(record) {
                window.dispatchEvent(new CustomEvent('open-record-modal', { detail: { isEdit: true, record: record } }));
            };
            data.deleteRecord = function(record) {
                if(confirm(`Bạn có chắc muốn xóa bản ghi: ${record.name} ${record.type}?`)) {
                    // Mock delete logic
                    showToast('Đã Xóa', `Bản ghi ${record.name} đang được xóa...`, 'danger');
                }
            };
            data.retryRecord = function(id) {
                showToast('Đang thử lại', 'Hệ thống đang đồng bộ lại...', 'warning');
            }
        }
    });

    function showToast(title, msg, type = 'success') {
        const toastEl = document.getElementById('actionToast');
        toastEl.className = `toast align-items-center text-white border-0 bg-${type}`;
        document.getElementById('toastMessage').innerHTML = `<strong>${title}</strong><br>${msg}`;
        const toast = new bootstrap.Toast(toastEl);
        toast.show();
    }
</script>
