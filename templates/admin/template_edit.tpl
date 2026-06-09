<div class="hvn-dns-admin hvn-template-edit" x-data="templateEditor()">
    <div class="hvn-d-flex hvn-justify-content-between hvn-align-items-center hvn-mb-4">
        <h2>
            <a href="{$modulelink}&action=templates"
                class="text-decoration-none hvn-text-muted hvn-me-2">
                <i class="bi bi-arrow-left"></i>
            </a>
            <i class="bi bi-file-earmark-code"></i>
            <span x-text="isEdit ? 'Sửa Template: ' + form.name : 'Tạo Template mới'"></span>
        </h2>
    </div>

    {* Flash message nếu redirect về sau lỗi *}
    {if $flash}
    <div class="hvn-alert hvn-alert-{$flash.type|default:'info'} hvn-mb-3">
        {$flash.message|escape:'htmlall'}
    </div>
    {/if}

    <div class="hvn-card hvn-shadow-sm hvn-border-0">
        <div class="hvn-card-body hvn-p-0">
            <form x-on:submit.prevent="saveTemplate">
                <div class="hvn-row g-0">

                    <!-- Left Panel: Settings -->
                    <div class="hvn-col-md-4 hvn-border-end hvn-bg-light hvn-p-4">
                        <div class="hvn-mb-3">
                            <label class="form-label hvn-fw-bold">
                                Tên Template <span class="hvn-text-danger">*</span>
                            </label>
                            <input type="text" class="hvn-form-control"
                                x-model="form.name"
                                placeholder="VD: Google Workspace" required>
                        </div>
                        <div class="hvn-mb-3">
                            <label class="form-label hvn-fw-bold">Mô tả hiển thị</label>
                            <textarea class="hvn-form-control" rows="3"
                                x-model="form.description"
                                placeholder="Mô tả cho client hiểu mục đích của mẫu này...">
                            </textarea>
                        </div>
                        <div class="hvn-mb-4">
                            <div class="form-check form-switch">
                                <input class="form-check-input" type="checkbox"
                                    id="tplVisible" x-model="form.is_visible">
                                <label class="form-check-label" for="tplVisible">
                                    Hiển thị cho Khách hàng chọn
                                </label>
                            </div>
                        </div>

                        <div class="hvn-card hvn-border-0 hvn-bg-info-subtle hvn-mt-4">
                            <div class="hvn-card-header hvn-text-info hvn-fw-bold hvn-py-2">
                                <i class="bi bi-info-circle"></i> Placeholders hỗ trợ
                            </div>
                            <div class="hvn-card-body hvn-py-2 small font-monospace">
                                <ul class="list-unstyled hvn-mb-0">
                                    <li><code>{literal}{{domain}}{/literal}</code> — Tên miền thực</li>
                                    <li><code>{literal}{{ip}}{/literal}</code> — IP mặc định Server</li>
                                    <li><code>{literal}{{ns1}}{/literal}</code> — Primary Nameserver</li>
                                    <li><code>{literal}{{ns2}}{/literal}</code> — Secondary Nameserver</li>
                                </ul>
                            </div>
                        </div>
                    </div>

                    <!-- Right Panel: Records Editor -->
                    <div class="hvn-col-md-8 hvn-p-4 hvn-bg-white">
                        <div class="hvn-d-flex hvn-justify-content-between hvn-align-items-center hvn-mb-3">
                            <h6 class="hvn-mb-0 hvn-fw-bold">
                                Bản ghi trong Template
                                (<span x-text="form.records.length"></span>)
                            </h6>
                            <button type="button"
                                class="hvn-btn hvn-btn-sm hvn-btn-outline-primary"
                                x-on:click="addEmptyRecord()">
                                <i class="bi bi-plus-circle"></i> Thêm record
                            </button>
                        </div>

                        <div class="table-responsive">
                            <table class="table table-sm table-bordered align-middle hvn-mb-0"
                                style="font-size:12px;">
                                <thead class="table-light">
                                    <tr>
                                        <th style="width:12%">Loại</th>
                                        <th style="width:20%">Tên (Name)</th>
                                        <th style="width:48%">Giá trị / Priority</th>
                                        <th style="width:12%">TTL</th>
                                        <th style="width:8%;text-align:center;">
                                            <i class="bi bi-trash"></i>
                                        </th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <template x-for="(rec, idx) in form.records" x-bind:key="idx">
                                        <tr>
                                            <td>
                                                <select class="hvn-form-select hvn-form-select-sm font-monospace"
                                                    x-model="rec.type">
                                                    <option value="A">A</option>
                                                    <option value="AAAA">AAAA</option>
                                                    <option value="CNAME">CNAME</option>
                                                    <option value="MX">MX</option>
                                                    <option value="TXT">TXT</option>
                                                    <option value="NS">NS</option>
                                                    <option value="SRV">SRV</option>
                                                    <option value="CAA">CAA</option>
                                                </select>
                                            </td>
                                            <td>
                                                <input type="text"
                                                    class="hvn-form-control hvn-form-control-sm font-monospace"
                                                    x-model="rec.name"
                                                    placeholder="@ hoặc www">
                                            </td>
                                            <td>
                                                <div class="hvn-d-flex hvn-gap-1">
                                                    <input type="text"
                                                        class="hvn-form-control hvn-form-control-sm font-monospace"
                                                        x-model="rec.value"
                                                        placeholder="Giá trị...">
                                                    <template x-if="rec.type === 'MX' || rec.type === 'SRV'">
                                                        <input type="number"
                                                            class="hvn-form-control hvn-form-control-sm font-monospace"
                                                            style="width:60px;min-width:60px;"
                                                            x-model="rec.prio"
                                                            placeholder="Pri"
                                                            title="Priority">
                                                    </template>
                                                </div>
                                            </td>
                                            <td>
                                                <input type="number"
                                                    class="hvn-form-control hvn-form-control-sm font-monospace"
                                                    x-model="rec.ttl">
                                            </td>
                                            <td style="text-align:center;">
                                                <button type="button"
                                                    class="hvn-btn hvn-btn-sm hvn-btn-outline-danger hvn-border-0"
                                                    x-on:click="removeRecord(idx)">
                                                    <i class="bi bi-x-lg"></i>
                                                </button>
                                            </td>
                                        </tr>
                                    </template>
                                    <template x-if="form.records.length === 0">
                                        <tr>
                                            <td colspan="5"
                                                class="hvn-text-center hvn-py-4 hvn-text-muted fst-italic">
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
                    <a href="{$modulelink}&action=templates"
                        class="hvn-btn hvn-btn-outline-secondary">Hủy</a>
                    <button type="submit" class="hvn-btn hvn-btn-primary"
                        x-bind:disabled="saving">
                        <template x-if="!saving">
                            <span>
                                <i class="bi bi-save"></i>
                                <span x-text="isEdit ? 'Lưu thay đổi' : 'Tạo Template'"></span>
                            </span>
                        </template>
                        <template x-if="saving">
                            <span>
                                <span class="spinner-border spinner-border-sm"
                                    style="width:13px;height:13px;border-width:2px;"></span>
                                Đang lưu...
                            </span>
                        </template>
                    </button>
                </div>
            </form>
        </div>
    </div>
</div>

<script>
var HVNDNS_TEMPLATE_EDIT_DATA = {$templateJson};
var HVNDNS_IS_EDIT             = {if $isEdit}true{else}false{/if};
var HVNDNS_ADMIN_MODULELINK    = '{$modulelink|escape:'javascript'}';
var HVNDNS_CSRF_TOKEN          = '{$token|escape:'javascript'}';
</script>
<script>
{literal}
document.addEventListener('alpine:init', function() {
    Alpine.data('templateEditor', function() {
        return {
            isEdit: HVNDNS_IS_EDIT,
            saving: false,
            form: {
                id:          null,
                name:        '',
                description: '',
                is_visible:  true,
                records:     []
            },

            init: function() {
                if (HVNDNS_IS_EDIT && HVNDNS_TEMPLATE_EDIT_DATA) {
                    var d = HVNDNS_TEMPLATE_EDIT_DATA;
                    this.form = {
                        id:          d.id,
                        name:        d.name        || '',
                        description: d.description || '',
                        is_visible:  d.is_visible !== false,
                        records:     d.records     || []
                    };
                } else {
                    // Tạo mới: bắt đầu với 1 record rỗng
                    this.addEmptyRecord();
                }
            },

            addEmptyRecord: function() {
                this.form.records.push({
                    type:  'A',
                    name:  '',
                    value: '',
                    ttl:   3600,
                    prio:  null
                });
            },

            removeRecord: function(idx) {
                this.form.records.splice(idx, 1);
            },

            saveTemplate: function() {
                var self = this;

                if (!self.form.name.trim()) {
                    window._hvnToast('warning', 'Thiếu thông tin',
                        'Vui lòng điền tên Template.');
                    return;
                }

                // Validate records
                for (var i = 0; i < self.form.records.length; i++) {
                    var rec = self.form.records[i];
                    if (!rec.name.trim() || !rec.value.trim()) {
                        window._hvnToast('warning', 'Thiếu thông tin',
                            'Record #' + (i + 1) + ': tên và giá trị không được để trống.');
                        return;
                    }
                }

                self.saving = true;

                // Chuẩn hoá records: đổi 'prio' → 'priority' cho backend
                var records = self.form.records.map(function(rec) {
                    return {
                        type:     rec.type,
                        name:     rec.name,
                        value:    rec.value,
                        ttl:      parseInt(rec.ttl) || 3600,
                        priority: rec.prio !== null && rec.prio !== ''
                                    ? parseInt(rec.prio) : null
                    };
                });

                var payload = {
                    method:            'save',
                    id:                self.form.id || 0,
                    name:              self.form.name.trim(),
                    description:       self.form.description.trim(),
                    is_visible_client: self.form.is_visible ? 1 : 0,
                    records:           records
                };

                fetch('/modules/addons/hvn_dns_manager/ajax.php?action=admin_template', {
                    method:  'POST',
                    headers: {
                        'Content-Type': 'application/json',
                        'X-CSRF-TOKEN': HVNDNS_CSRF_TOKEN
                    },
                    body: JSON.stringify(payload)
                })
                .then(function(r) { return r.json(); })
                .then(function(res) {
                    self.saving = false;
                    if (res.success) {
                        window._hvnToast('success', 'Thành công',
                            res.message || 'Template đã được lưu.');
                        // Redirect về danh sách sau 800ms để toast hiển thị
                        setTimeout(function() {
                            window.location.href = HVNDNS_ADMIN_MODULELINK
                                + '&action=templates';
                        }, 800);
                    } else {
                        var msg = (res.error && res.error.message)
                            ? res.error.message : 'Lỗi không xác định.';
                        window._hvnToast('error', 'Lỗi lưu template', msg);
                    }
                })
                .catch(function() {
                    self.saving = false;
                    window._hvnToast('error', 'Lỗi kết nối', 'Vui lòng thử lại.');
                });
            }
        };
    });
});
{/literal}
</script>
