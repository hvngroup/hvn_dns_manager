{*
 * Partial: Record Add/Edit Modal
 * Dùng chung: templates/admin/dns_editor.tpl + templates/client/dns_editor.tpl
 *
 * Trigger: window.dispatchEvent(new CustomEvent('open-record-modal', { detail: { isEdit: false } }))
 *          window.dispatchEvent(new CustomEvent('open-record-modal', { detail: { isEdit: true, record: {...} } }))
 *}
<div class="mj-modal-overlay"
     x-data="recordModal()"
     x-show="open"
     @open-record-modal.window="openModal($event.detail)"
     @keydown.escape.window="close()"
     style="display:none;"
     aria-modal="true"
     role="dialog">

    <div class="mj-modal-backdrop" @click="close()"></div>

    <div class="mj-modal-dialog">
        <div class="mj-modal-content">

            <!-- Header -->
            <div class="mj-modal-header">
                <h5 class="mj-modal-title">
                    <i class="bi" :class="isEdit ? 'bi-pencil-square' : 'bi-plus-square'"></i>
                    <span x-text="isEdit ? 'Sửa DNS Record' : 'Thêm DNS Record'"></span>
                </h5>
                <button type="button" class="mj-btn-close" @click="close()" aria-label="Đóng">
                    <i class="bi bi-x-lg"></i>
                </button>
            </div>

            <!-- Body -->
            <div class="mj-modal-body">
                <form @submit.prevent="submitRecord()" id="recordForm">

                    <!-- Record Type -->
                    <div class="mj-mb-3">
                        <label class="mj-form-label mj-fw-bold" for="rec_type">Loại bản ghi <span class="mj-text-danger">*</span></label>
                        <select id="rec_type" class="mj-form-select" x-model="form.type" :disabled="isEdit">
                            <option value="">-- Chọn loại --</option>
                            <option value="A">A — IPv4 Address</option>
                            <option value="AAAA">AAAA — IPv6 Address</option>
                            <option value="CNAME">CNAME — Canonical Name</option>
                            <option value="MX">MX — Mail Exchange</option>
                            <option value="TXT">TXT — Text Record</option>
                            <option value="SRV">SRV — Service Record</option>
                            <option value="NS">NS — Name Server</option>
                            <option value="CAA">CAA — CA Authorization</option>
                        </select>
                        <template x-if="errors.type">
                            <div class="mj-text-danger mj-small mj-mt-1" x-text="errors.type"></div>
                        </template>
                    </div>

                    <!-- Name -->
                    <div class="mj-mb-3">
                        <label class="mj-form-label mj-fw-bold" for="rec_name">Tên (Name) <span class="mj-text-danger">*</span></label>
                        <div class="mj-input-group">
                            <input type="text" id="rec_name" class="mj-form-control"
                                   placeholder="@ hoặc subdomain"
                                   x-model="form.name">
                            <span class="mj-input-group-text mj-text-muted mj-small">.{$domain.domain|default:'domain.com'}</span>
                        </div>
                        <div class="mj-small mj-text-muted mj-mt-1">Dùng <code>@</code> cho root domain. Nhập subdomain không kèm domain gốc.</div>
                        <template x-if="errors.name">
                            <div class="mj-text-danger mj-small mj-mt-1" x-text="errors.name"></div>
                        </template>
                    </div>

                    <!-- TTL -->
                    <div class="mj-mb-3">
                        <label class="mj-form-label mj-fw-bold" for="rec_ttl">TTL (giây)</label>
                        <select id="rec_ttl" class="mj-form-select" x-model="form.ttl">
                            <option value="60">60s — 1 phút</option>
                            <option value="300">300s — 5 phút</option>
                            <option value="600">600s — 10 phút</option>
                            <option value="3600">3600s — 1 giờ (thường dùng)</option>
                            <option value="14400">14400s — 4 giờ</option>
                            <option value="86400">86400s — 24 giờ</option>
                        </select>
                    </div>

                    <!-- Value / Content (fields thay đổi theo type) -->

                    <!-- A / AAAA / CNAME / NS -->
                    <template x-if="['A','AAAA','CNAME','NS'].includes(form.type)">
                        <div class="mj-mb-3">
                            <label class="mj-form-label mj-fw-bold" for="rec_value">
                                <span x-text="form.type === 'A' ? 'Địa chỉ IPv4' : form.type === 'AAAA' ? 'Địa chỉ IPv6' : form.type === 'CNAME' ? 'Điểm đến (CNAME Target)' : 'Name Server'"></span>
                                <span class="mj-text-danger">*</span>
                            </label>
                            <input type="text" id="rec_value" class="mj-form-control"
                                   :placeholder="form.type === 'A' ? '203.0.113.1' : form.type === 'AAAA' ? '2001:db8::1' : form.type === 'CNAME' ? 'target.example.com.' : 'ns1.example.com.'"
                                   x-model="form.value">
                            <template x-if="errors.value">
                                <div class="mj-text-danger mj-small mj-mt-1" x-text="errors.value"></div>
                            </template>
                        </div>
                    </template>

                    <!-- TXT -->
                    <template x-if="form.type === 'TXT'">
                        <div class="mj-mb-3">
                            <label class="mj-form-label mj-fw-bold" for="rec_txt">Nội dung TXT <span class="mj-text-danger">*</span></label>
                            <textarea id="rec_txt" class="mj-form-control" rows="3"
                                      placeholder='v=spf1 include:_spf.example.com ~all'
                                      x-model="form.value"></textarea>
                            <div class="mj-small mj-text-muted mj-mt-1">Bao gồm dấu ngoặc kép nếu cần. VD: <code>"v=spf1 ..."</code></div>
                            <template x-if="errors.value">
                                <div class="mj-text-danger mj-small mj-mt-1" x-text="errors.value"></div>
                            </template>
                        </div>
                    </template>

                    <!-- MX -->
                    <template x-if="form.type === 'MX'">
                        <div>
                            <div class="mj-mb-3">
                                <label class="mj-form-label mj-fw-bold" for="rec_mx_host">Mail Server <span class="mj-text-danger">*</span></label>
                                <input type="text" id="rec_mx_host" class="mj-form-control"
                                       placeholder="mail.example.com."
                                       x-model="form.value">
                                <template x-if="errors.value">
                                    <div class="mj-text-danger mj-small mj-mt-1" x-text="errors.value"></div>
                                </template>
                            </div>
                            <div class="mj-mb-3">
                                <label class="mj-form-label mj-fw-bold" for="rec_priority">Priority (Ưu tiên)</label>
                                <input type="number" id="rec_priority" class="mj-form-control" min="0" max="65535"
                                       placeholder="10"
                                       x-model.number="form.priority">
                            </div>
                        </div>
                    </template>

                    <!-- SRV -->
                    <template x-if="form.type === 'SRV'">
                        <div>
                            <div class="mj-row mj-mb-3">
                                <div class="mj-col">
                                    <label class="mj-form-label mj-fw-bold">Priority</label>
                                    <input type="number" class="mj-form-control" min="0" max="65535" placeholder="10" x-model.number="form.priority">
                                </div>
                                <div class="mj-col">
                                    <label class="mj-form-label mj-fw-bold">Weight</label>
                                    <input type="number" class="mj-form-control" min="0" max="65535" placeholder="20" x-model.number="form.weight">
                                </div>
                                <div class="mj-col">
                                    <label class="mj-form-label mj-fw-bold">Port</label>
                                    <input type="number" class="mj-form-control" min="1" max="65535" placeholder="443" x-model.number="form.port">
                                </div>
                            </div>
                            <div class="mj-mb-3">
                                <label class="mj-form-label mj-fw-bold" for="rec_srv_target">Target <span class="mj-text-danger">*</span></label>
                                <input type="text" id="rec_srv_target" class="mj-form-control"
                                       placeholder="target.example.com."
                                       x-model="form.value">
                                <template x-if="errors.value">
                                    <div class="mj-text-danger mj-small mj-mt-1" x-text="errors.value"></div>
                                </template>
                            </div>
                        </div>
                    </template>

                    <!-- CAA -->
                    <template x-if="form.type === 'CAA'">
                        <div>
                            <div class="mj-row mj-mb-3">
                                <div class="mj-col-3">
                                    <label class="mj-form-label mj-fw-bold">Flag</label>
                                    <input type="number" class="mj-form-control" min="0" max="255" placeholder="0" x-model.number="form.priority">
                                </div>
                                <div class="mj-col">
                                    <label class="mj-form-label mj-fw-bold">Tag</label>
                                    <select class="mj-form-select" x-model="form.caa_tag">
                                        <option value="issue">issue</option>
                                        <option value="issuewild">issuewild</option>
                                        <option value="iodef">iodef</option>
                                    </select>
                                </div>
                            </div>
                            <div class="mj-mb-3">
                                <label class="mj-form-label mj-fw-bold" for="rec_caa_value">Value <span class="mj-text-danger">*</span></label>
                                <input type="text" id="rec_caa_value" class="mj-form-control"
                                       placeholder='"letsencrypt.org"'
                                       x-model="form.value">
                            </div>
                        </div>
                    </template>

                    <!-- Error tổng -->
                    <template x-if="errors.general">
                        <div class="mj-alert mj-alert-danger mj-mt-2" x-text="errors.general"></div>
                    </template>

                </form>
            </div>

            <!-- Footer -->
            <div class="mj-modal-footer">
                <button type="button" class="mj-btn mj-btn-outline-secondary" @click="close()" :disabled="submitting">
                    Hủy
                </button>
                <button type="submit" form="recordForm" class="mj-btn mj-btn-primary" :disabled="submitting || !form.type">
                    <span x-show="submitting" class="mj-spinner-border mj-spinner-border-sm mj-me-1" style="width:.85rem;height:.85rem;"></span>
                    <span x-text="submitting ? 'Đang lưu...' : (isEdit ? 'Cập nhật' : 'Thêm bản ghi')"></span>
                </button>
            </div>

        </div>
    </div>
</div>

{* ── CSS cho modal (chỉ inject 1 lần nếu chưa có) ── *}
<style>
{literal}
.mj-modal-overlay {
    position: fixed; inset: 0; z-index: 1050;
    display: flex; align-items: center; justify-content: center;
    /* backdrop-filter đặt ở đây để KHÔNG tạo stacking context trong overlay */
    backdrop-filter: blur(2px);
}
.mj-modal-backdrop {
    position: absolute; inset: 0; z-index: 0;
    background: rgba(0,0,0,0.45);
    /* KHÔNG dùng backdrop-filter ở đây — sẽ tạo stacking context mới
       khiến modal-dialog (z-index:1) vẫn bị blur theo backdrop */
}
.mj-modal-dialog {
    position: relative; z-index: 10;
    width: 100%; max-width: 540px;
    margin: 1rem;
    animation: mjDnsModalIn .2s ease;
}
@keyframes mjDnsModalIn {
    from { transform: translateY(-20px); opacity: 0; }
    to   { transform: translateY(0);     opacity: 1; }
}
.mj-modal-content {
    background: #fff;
    border-radius: 10px;
    box-shadow: 0 10px 40px rgba(0,0,0,0.2);
    overflow: hidden;
}
.mj-modal-header {
    display: flex; align-items: center; justify-content: space-between;
    padding: 1rem 1.25rem;
    border-bottom: 1px solid var(--mj-border-color, #dee2e6);
    background: #fafafa;
}
.mj-modal-title { margin: 0; font-size: 1rem; font-weight: 600; display: flex; align-items: center; gap: 8px; }
.mj-btn-close {
    background: none; border: none; cursor: pointer;
    width: 30px; height: 30px; border-radius: 6px;
    display: flex; align-items: center; justify-content: center;
    color: #666; transition: background .15s;
}
.mj-btn-close:hover { background: #f0f0f0; color: #333; }
.mj-modal-body { padding: 1.25rem; max-height: 70vh; overflow-y: auto; }
.mj-modal-footer {
    display: flex; justify-content: flex-end; gap: 8px;
    padding: .875rem 1.25rem;
    border-top: 1px solid var(--mj-border-color, #dee2e6);
    background: #fafafa;
}
{/literal}
</style>
