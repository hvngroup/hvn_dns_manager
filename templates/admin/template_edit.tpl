<div class="hvn-dns-admin hvn-template-edit" x-data="templateEditor()">
    <div class="hvn-d-flex hvn-justify-content-between hvn-align-items-center hvn-mb-4">
        <h2>
            <a href="{$modulelink}&action=templates" class="text-decoration-none hvn-text-muted hvn-me-2"><i class="bi bi-arrow-left"></i></a>
            <i class="bi bi-file-earmark-code"></i> <span x-text="isEdit ? 'Sửa Template: ' + form.name : 'Tạo Template mới'"></span>
        </h2>
    </div>

    <div class="hvn-card hvn-shadow-sm hvn-border-0">
        <div class="hvn-card-body hvn-p-0">
            <form @submit.prevent="saveTemplate">
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
                            <button type="button" class="hvn-btn btn-sm hvn-btn-outline-primary" @click="addEmptyRecord()"><i class="bi bi-plus-circle"></i> Thêm record</button>
                        </div>

                        <div class="table-responsive">
                            <table class="table table-sm table-bordered align-middle hvn-mb-0 font-monospace" style="font-size: 12px">
                                <thead class="table-light">
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
                                                    <input type="text" class="hvn-form-control hvn-form-control-sm font-monospace w-100" x-model="rec.value" placeholder="Giá trị...">
                                                    <template x-if="rec.type === 'MX' || rec.type === 'SRV'">
                                                        <input type="number" class="hvn-form-control hvn-form-control-sm font-monospace hvn-ms-1" style="width: 60px; min-width: 60px;" x-model="rec.prio" placeholder="Pri" title="Priority">
                                                    </template>
                                                </div>
                                            </td>
                                            <td><input type="number" class="hvn-form-control hvn-form-control-sm font-monospace" x-model="rec.ttl"></td>
                                            <td class="hvn-text-center">
                                                <button type="button" class="hvn-btn btn-sm btn-outline-danger hvn-border-0" @click="removeRecord(idx)"><i class="bi bi-x-lg"></i></button>
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

                <!-- Form Actions -->
                <div class="hvn-d-flex hvn-justify-content-end hvn-gap-2 hvn-p-3 hvn-bg-light hvn-border-top">
                    <a href="{$modulelink}&action=templates" class="hvn-btn hvn-btn-outline-secondary">Hủy</a>
                    <button type="submit" class="hvn-btn hvn-btn-primary">
                        <i class="bi bi-save"></i> <span x-text="isEdit ? 'Lưu thay đổi' : 'Tạo Template'"></span>
                    </button>
                </div>
            </form>
        </div>
    </div>
</div>

<script>
{literal}
document.addEventListener('alpine:init', () => {
    Alpine.data('templateEditor', () => ({
        isEdit: false,
        form: { id: null, name: '', description: '', is_visible: true, records: [] },

        init() {
            // Mock: Check URL for ID
            const urlParams = new URLSearchParams(window.location.search);
            const id = urlParams.get('id');
            if (id) {
                this.isEdit = true;
                // Mock load
                this.form = {
                    id: id, name: 'Basic DNS', description: 'NS + A record mặc định cho hosting', is_default: true,
                    is_visible: true, records_count: 6,
                    records: [
                        { type: 'NS', name: '@', value: '{{ns1}}', ttl: 86400, prio: 0 },
                        { type: 'NS', name: '@', value: '{{ns2}}', ttl: 86400, prio: 0 },
                        { type: 'A', name: '@', value: '{{ip}}', ttl: 3600, prio: 0 },
                        { type: 'A', name: 'www', value: '{{ip}}', ttl: 3600, prio: 0 },
                        { type: 'A', name: 'mail', value: '{{ip}}', ttl: 3600, prio: 0 },
                        { type: 'MX', name: '@', value: 'mail.{{domain}}.', ttl: 3600, prio: 10 }
                    ]
                };
            } else {
                this.addEmptyRecord();
            }
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
            
            alert('Lưu mẫu DNS thành công!');
            window.location.href = '{/literal}{$modulelink}&action=templates{literal}';
        }
    }));
});
{/literal}
</script>
