<!-- Record Modal -->
<div x-data="{
    isOpen: false,
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
        this.isOpen = false;
    },
    
    saveRecord() {
        this.submitting = true;
        // Mock API call delay
        setTimeout(() => {
            this.submitting = false;
            this.closeModal();
            // Show toast notification
            window.dispatchEvent(new CustomEvent('show-toast', { detail: { title: 'Thành công', msg: 'Đã lưu bản ghi! Hệ thống đang đồng bộ...', type: 'success' } }));
        }, 800);
    }
}" @open-record-modal.window="
    isOpen = true;
    isEdit = $event.detail.isEdit;
    if(isEdit) {
        form = { ...$event.detail.record };
    } else {
        form = { id: null, type: 'A', name: '', value: '', priority: 10, weight: 0, port: 443, ttl: 3600 };
    }
">
    <!-- Custom Alpine Backdrop -->
    <div x-show="isOpen" x-transition.opacity 
         style="position: fixed; top: 0; left: 0; width: 100vw; height: 100vh; background-color: rgba(0,0,0,0.5); z-index: 1040; display: none;"></div>

    <div class="modal fade" :class="{ 'show': isOpen }" :style="isOpen ? 'display: block; z-index: 1045;' : 'display: none;'" 
         tabindex="-1" aria-labelledby="recordModalLabel" aria-hidden="true" @click.self="closeModal()" x-show="isOpen" x-transition.opacity>
        <div class="modal-dialog">
            <div class="modal-content">
                <div class="modal-header">
                    <h5 class="modal-title" id="recordModalLabel" x-text="isEdit ? 'Sửa bản ghi DNS' : 'Thêm bản ghi DNS'"></h5>
                    <button type="button" class="btn-close" @click="closeModal()"></button>
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
</div>

<!-- Toast Container -->
<div class="toast-container position-fixed bottom-0 end-0 p-3" style="z-index: 1080" x-data="{
    show: false,
    title: '',
    msg: '',
    type: 'success',
    timeout: null,
    
    showToastHandler(e) {
        this.title = e.detail.title;
        this.msg = e.detail.msg;
        this.type = e.detail.type || 'success';
        this.show = true;
        
        if(this.timeout) clearTimeout(this.timeout);
        this.timeout = setTimeout(() => { this.show = false; }, 3000);
    }
}" @show-toast.window="showToastHandler($event)">
    <div class="toast align-items-center text-white border-0" :class="{ 'show': show, ['bg-' + type]: true }" :style="show ? 'display: block;' : 'display: none;'" role="alert" aria-live="assertive" aria-atomic="true">
        <div class="d-flex">
            <div class="toast-body">
                <strong x-text="title"></strong><br>
                <span x-html="msg"></span>
            </div>
            <button type="button" class="btn-close btn-close-white me-2 m-auto" @click="show = false" aria-label="Close"></button>
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
                    window.dispatchEvent(new CustomEvent('show-toast', { detail: { title: 'Đã Xóa', msg: `Bản ghi ${record.name} đang được xóa...`, type: 'danger' } }));
                }
            };
            data.retryRecord = function(id) {
                window.dispatchEvent(new CustomEvent('show-toast', { detail: { title: 'Đang thử lại', msg: 'Hệ thống đang đồng bộ lại...', type: 'warning' } }));
            }
        }
    });

    // Keeping function for direct call compatibility if any
    function showToast(title, msg, type = 'success') {
        window.dispatchEvent(new CustomEvent('show-toast', { detail: { title: title, msg: msg, type: type } }));
    }
</script>
