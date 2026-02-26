<div class="hvn-dns-admin hvn-templates" x-data="templateManager()">
    <div class="hvn-d-flex hvn-justify-content-between hvn-align-items-center hvn-mb-4">
        <h2><i class="bi bi-file-text"></i> Quản lý DNS Template</h2>
        <button class="hvn-btn hvn-btn-primary" @click="openModal()"><i class="bi bi-plus-lg"></i> Tạo Template</button>
    </div>

    <div class="hvn-row">
        <!-- Loop Template Items -->
        <template x-for="tpl in templates" :key="tpl.id">
            <div class="hvn-col-md-6 col-lhvn-g-4 hvn-mb-4">
                <div class="hvn-card hvn-shadow-sm h-100 hvn-border-0" :class="{ 'hvn-border-primary hvn-border-start hvn-border-4': tpl.is_default, 'hvn-bg-light': !tpl.is_visible}">
                    <div class="hvn-card-body position-relative">
                        <template x-if="tpl.is_default">
                            <span class="position-absolute tohvn-p-0 end-0 badge hvn-bg-primary hvn-m-2" style="font-size: 0.7rem;"><i class="bi bi-star-fill hvn-text-warning"></i> DEFAULT</span>
                        </template>
                        
                        <h5 class="card-title hvn-text-primary hvn-fw-bold" x-text="tpl.name"></h5>
                        <p class="card-text hvn-text-muted small hvn-mb-3" style="min-height: 40px;" x-text="tpl.description"></p>
                        
                        <div class="hvn-d-flex hvn-justify-content-between hvn-align-items-center hvn-mb-3">
                            <span class="hvn-badge hvn-bg-secondary"><span x-text="tpl.records_count"></span> bản ghi</span>
                            <span class="small" :class="tpl.is_visible ? 'hvn-text-success' : 'hvn-text-danger'">
                                <i class="bi" :class="tpl.is_visible ? 'bi-eye-fill' : 'bi-eye-slash-fill'"></i>
                                <span x-text="tpl.is_visible ? 'Hiển thị Client' : 'Ẩn với Client'"></span>
                            </span>
                        </div>
                        
                        <div class="btn-group w-100">
                            <button class="hvn-btn btn-sm hvn-btn-outline-primary" @click="openModal(tpl)"><i class="bi bi-pencil"></i> Sửa</button>
                            <button class="hvn-btn btn-sm btn-outline-secondary" @click="cloneTemplate(tpl)"><i class="bi bi-stickies"></i> Clone</button>
                            <template x-if="!tpl.is_default">
                                <button class="hvn-btn btn-sm btn-outline-success" @click="setDefault(tpl)"><i class="bi bi-star"></i> Set Default</button>
                            </template>
                            <template x-if="!tpl.is_default">
                                <button class="hvn-btn btn-sm btn-outline-danger" @click="deleteTemplate(tpl)"><i class="bi bi-trash"></i></button>
                            </template>
                        </div>
                    </div>
                </div>
            </div>
        </template>
    </div>

    <!-- Modal Edit/Create Template -->
    <div class="modal fade" id="templateModal" tabindex="-1" aria-hidden="true" data-bs-backdrop="static">
        <div class="modal-dialog modal-xl">
            <div class="modal-content">
                <div class="modal-header hvn-bg-light">
                    <h5 class="modal-title"><i class="bi bi-file-earmark-code"></i> <span x-text="isEdit ? 'Sửa Template: ' + form.name : 'Tạo Template mới'"></span></h5>
                    <button type="button" class="btn-close" @click="closeModal()"></button>
                </div>
                <div class="modal-body hvn-p-0">
                    <div class="hvn-row g-0">
                        <!-- Left Panel: Settings -->
                        <div class="hvn-col-md-4 hvn-border-end hvn-bg-light hvn-p-4 h-100">
                            <div class="hvn-mb-3">
                                <label class="form-label hvn-fw-bold">Tên Template <span class="hvn-text-danger">*</span></label>
                                <input type="text" class="hvn-form-control" x-model="form.name" placeholder="VD: Google Workspace" required>
                            </div>
                            <div class="hvn-mb-3">
                                <label class="form-label hvn-fw-bold">Mô tả hiển thị</label>
                                <textarea class="hvn-form-control" rows="3" x-model="form.description" placeholder="Mô tả cho client hiểu mục đích của mẫu này..."></textarea>
                            </div>
                            <div class="hvn-mb-4">
                                <div class="form-check form-switch">
                                    <input class="form-check-input" type="checkbox" id="tplVisible" x-model="form.is_visible">
                                    <label class="form-check-label" for="tplVisible">Hiển thị cho Khách hàng chọn</label>
                                </div>
                            </div>

                            <div class="hvn-card border-info hvn-bg-info-subtle bg-opacity-10 hvn-mt-4">
                                <div class="hvn-card-header bg-transparent border-info hvn-text-info hvn-fw-bold hvn-py-2"><i class="bi bi-info-circle"></i> Placeholders hỗ trợ</div>
                                <div class="hvn-card-body hvn-py-2 small font-monospace">
                                    <ul class="list-unstyled hvn-mb-0">
                                        <li><code>{literal}{{domain}}{/literal}</code> - Tên miền thực (VD: shop.vn)</li>
                                        <li><code>{literal}{{ip}}{/literal}</code> - IP mặc định của Server</li>
                                        <li><code>{literal}{{ns1}}{/literal}</code> - Primary Nameserver</li>
                                        <li><code>{literal}{{ns2}}{/literal}</code> - Secondary Nameserver</li>
                                    </ul>
                                </div>
                            </div>
                        </div>

                        <!-- Right Panel: Records Editor -->
                        <div class="hvn-col-md-8 hvn-p-4 hvn-bg-white">
                            <div class="hvn-d-flex hvn-justify-content-between hvn-align-items-center hvn-mb-3">
                                <h6 class="hvn-mb-0 hvn-fw-bold">Bản ghi trong Template (<span x-text="form.records.length"></span>)</h6>
                                <button class="hvn-btn btn-sm hvn-btn-outline-primary" @click="addEmptyRecord()"><i class="bi bi-plus-circle"></i> Thêm record</button>
                            </div>

                            <div class="table-responsive" style="max-height: 400px; overflow-y: auto;">
                                <table class="table table-sm table-bordered align-middle hvn-mb-0 font-monospace" style="font-size: 12px">
                                    <thead class="table-light sticky-top">
                                        <tr>
                                            <th width="12%">Loại</th>
                                            <th width="20%">Tên (Name)</th>
                                            <th width="50%">Giá trị (Value) / Priority</th>
                                            <th width="12%">TTL</th>
                                            <th width="6%" class="hvn-text-center"><i class="bi bi-trash"></i></th>
                                        </tr>
                                    </thead>
                                    <tbody>
                                        <template x-for="(rec, idx) in form.records" :key="idx">
                                            <tr>
                                                <td>
                                                    <select class="hvn-form-select hvn-form-select-sm font-monospace" x-model="rec.type">
                                                        <option value="A">A</option><option value="CNAME">CNAME</option>
                                                        <option value="MX">MX</option><option value="TXT">TXT</option>
                                                        <option value="NS">NS</option><option value="SRV">SRV</option>
                                                    </select>
                                                </td>
                                                <td><input type="text" class="hvn-form-control hvn-form-control-sm font-monospace" x-model="rec.name" placeholder="@ hoặc www"></td>
                                                <td>
                                                    <div class="hvn-d-flex">
                                                        <input type="text" class="hvn-form-control hvn-form-control-sm font-monospace" x-model="rec.value" placeholder="Giá trị...">
                                                        <template x-if="rec.type === 'MX' || rec.type === 'SRV'">
                                                            <input type="number" class="hvn-form-control hvn-form-control-sm font-monospace hvn-ms-1" style="width: 60px;" x-model="rec.prio" placeholder="Pri" title="Priority">
                                                        </template>
                                                    </div>
                                                </td>
                                                <td><input type="number" class="hvn-form-control hvn-form-control-sm font-monospace" x-model="rec.ttl"></td>
                                                <td class="hvn-text-center">
                                                    <button class="hvn-btn btn-sm btn-outline-danger hvn-border-0" @click="removeRecord(idx)"><i class="bi bi-x-lg"></i></button>
                                                </td>
                                            </tr>
                                        </template>
                                        <template x-if="form.records.length === 0">
                                            <tr>
                                                <td colspan="5" class="hvn-text-center hvn-py-4 hvn-text-muted fst-italic">
                                                    Chưa có bản ghi nào. Click "Thêm record" để bắt đầu.
                                                </td>
                                            </tr>
                                        </template>
                                    </tbody>
                                </table>
                            </div>
                        </div>
                    </div>
                </div>
                <div class="modal-footer hvn-bg-light">
                    <button type="button" class="hvn-btn btn-outline-secondary" @click="closeModal()">Hủy</button>
                    <button type="button" class="hvn-btn hvn-btn-primary" @click="saveTemplate()">
                        <i class="bi bi-save"></i> <span x-text="isEdit ? 'Lưu thay đổi' : 'Tạo Template'"></span>
                    </button>
                </div>
            </div>
        </div>
    </div>
</div>

<script>
{literal}
document.addEventListener('alpine:init', () => {
    Alpine.data('templateManager', () => ({
        templates: [
            {
                id: 1, name: 'Basic DNS', description: 'NS + A record mặc định cho hosting', is_default: true,
                is_visible: true, records_count: 6,
                records: [
                    { type: 'NS', name: '@', value: '{literal}{{ns1}}{/literal}', ttl: 86400, prio: 0 },
                    { type: 'NS', name: '@', value: '{literal}{{ns2}}{/literal}', ttl: 86400, prio: 0 },
                    { type: 'A', name: '@', value: '{literal}{{ip}}{/literal}', ttl: 3600, prio: 0 },
                    { type: 'A', name: 'www', value: '{literal}{{ip}}{/literal}', ttl: 3600, prio: 0 },
                    { type: 'A', name: 'mail', value: '{literal}{{ip}}{/literal}', ttl: 3600, prio: 0 },
                    { type: 'MX', name: '@', value: 'mail.{literal}{{domain}}{/literal}.', ttl: 3600, prio: 10 }
                ]
            },
            {
                id: 2, name: 'Email Optimized', description: 'Bao gồm MX, SPF, DKIM, DMARC chống vào Spam', is_default: false,
                is_visible: true, records_count: 12, records: []
            },
            {
                id: 3, name: 'Internal Only', description: 'Template nội bộ cho DEV', is_default: false,
                is_visible: false, records_count: 4, records: []
            }
        ],
        
        isEdit: false,
        form: { id: null, name: '', description: '', is_visible: true, records: [] },
        modalInstance: null,

        init() {
            this.$nextTick(() => {
                const el = document.getElementById('templateModal');
                if (el) this.modalInstance = new bootstrap.Modal(el);
            });
        },

        openModal(tpl = null) {
            this.isEdit = !!tpl;
            if(tpl) {
                // deep copy
                this.form = JSON.parse(JSON.stringify(tpl));
                // fill dummy records if empty for demo
                if(this.form.records.length === 0) this.addEmptyRecord();
            } else {
                this.form = { id: Date.now(), name: '', description: '', is_visible: true, records: [] };
                this.addEmptyRecord();
            }
            if(this.modalInstance) this.modalInstance.show();
        },

        closeModal() {
            if(this.modalInstance) this.modalInstance.hide();
        },

        addEmptyRecord() {
            this.form.records.push({ type: 'A', name: '', value: '', ttl: 3600, prio: 10 });
        },

        removeRecord(idx) {
            this.form.records.splice(idx, 1);
        },

        saveTemplate() {
            if(!this.form.name) return alert('Vui lòng điền tên Template');
            this.form.records_count = this.form.records.length;
            
            if(this.isEdit) {
                const idx = this.templates.findIndex(t => t.id === this.form.id);
                if(idx > -1) this.templates[idx] = JSON.parse(JSON.stringify(this.form));
            } else {
                this.form.is_default = false;
                this.templates.push(JSON.parse(JSON.stringify(this.form)));
            }
            alert('Lưu mẫu DNS thành công!');
            this.closeModal();
        },

        cloneTemplate(tpl) {
            let clone = JSON.parse(JSON.stringify(tpl));
            clone.id = Date.now();
            clone.name = clone.name + ' (Copy)';
            clone.is_default = false;
            this.templates.push(clone);
        },

        setDefault(tpl) {
            if(confirm(`Đặt "${tpl.name}" làm mặc định cho tên miền mới?`)) {
                this.templates.forEach(t => t.is_default = false);
                tpl.is_default = true;
            }
        },

        deleteTemplate(tpl) {
            if(confirm(`Xóa vĩnh viễn template "${tpl.name}"?`)) {
                this.templates = this.templates.filter(t => t.id !== tpl.id);
            }
        }
    }));
});
{/literal}
</script>
