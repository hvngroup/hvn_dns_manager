<div class="hvn-dns-admin hvn-server-edit" x-data="serverEditor()">
    <div class="hvn-d-flex hvn-justify-content-between hvn-align-items-center hvn-mb-4">
        <h2>
            <a href="{$modulelink}&action=servers" class="text-decoration-none hvn-text-muted hvn-me-2"><i class="bi bi-arrow-left"></i></a>
            <i class="bi bi-server"></i> <span x-text="isEdit ? 'Sửa Server DirectAdmin' : 'Thêm Server DirectAdmin'"></span>
        </h2>
    </div>

    {* Flash message *}
    {if $flash}
    <div class="hvn-alert hvn-alert-{if $flash.type === 'success'}success{else}danger{/if} hvn-alert-dismissible hvn-fade hvn-show hvn-mb-4" role="alert">
        <i class="bi bi-{if $flash.type === 'success'}check-circle{else}exclamation-triangle{/if} hvn-me-2"></i>
        {$flash.message|escape:'htmlall'}
        <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
    </div>
    {/if}

    <div class="hvn-card hvn-shadow-sm hvn-border-0">
        <div class="hvn-card-body hvn-p-4">
            <form method="POST" action="{$modulelink}&action=server_edit" @submit.prevent="saveServer($event)">
                <input type="hidden" name="token" value="{$token}">
                <input type="hidden" name="id" value="{$serverId}" :value="form.id || {$serverId}">

                <div class="hvn-row hvn-mb-3">
                    <div class="hvn-col-md-6">
                        <label class="hvn-form-label">Hostname <span class="hvn-text-danger">*</span></label>
                        <input type="text" class="hvn-form-control font-monospace" name="hostname" x-model="form.hostname" required placeholder="dns4.hvn.vn">
                        <div class="form-text hvn-text-muted small"><i class="bi bi-info-circle"></i> Tên hiển thị cho khách hàng (không hiện IP)</div>
                    </div>
                    <div class="hvn-col-md-6">
                        <label class="hvn-form-label">Địa chỉ IP <span class="hvn-text-danger">*</span></label>
                        <input type="text" class="hvn-form-control font-monospace" name="ip_address" x-model="form.ip_address" required placeholder="103.xx.xx.13">
                    </div>
                </div>

                <div class="hvn-row hvn-mb-4">
                    <div class="hvn-col-md-3">
                        <label class="hvn-form-label">Port <span class="hvn-text-danger">*</span></label>
                        <input type="number" class="hvn-form-control font-monospace" name="port" x-model="form.port" required min="1" max="65535">
                    </div>
                    <div class="hvn-col-md-3 hvn-d-flex hvn-align-items-center hvn-mt-3">
                        <div class="form-check form-switch hvn-mt-2">
                            <input class="form-check-input" type="checkbox" id="useSsl" x-model="form.use_ssl" name="use_ssl" value="1">
                            <label class="form-check-label hvn-cursor-pointer" for="useSsl">Sử dụng SSL (HTTPS)</label>
                        </div>
                    </div>
                </div>

                <h6 class="hvn-border-bottom hvn-pb-2 hvn-mb-3 hvn-mt-4 hvn-text-primary hvn-fw-bold"><i class="bi bi-shield-lock hvn-me-1"></i> Thông tin đăng nhập DirectAdmin</h6>
                <div class="hvn-row hvn-mb-4">
                    <div class="hvn-col-md-6">
                        <label class="hvn-form-label">Username <span class="hvn-text-danger">*</span></label>
                        <input type="text" class="hvn-form-control font-monospace" name="username" x-model="form.username" required>
                    </div>
                    <div class="hvn-col-md-6">
                        <label class="hvn-form-label">Password <span x-show="!isEdit" class="hvn-text-danger">*</span></label>
                        <input type="password" class="hvn-form-control font-monospace" name="password" x-model="form.password" :required="!isEdit" placeholder="••••••••">
                        <div class="form-text hvn-text-muted small"><i class="bi bi-lock-fill"></i> Mật khẩu mã hóa AES-256. <span x-show="isEdit" class="hvn-fw-bold hvn-text-warning">Để trống nếu giữ nguyên.</span></div>
                    </div>
                </div>

                <h6 class="hvn-border-bottom hvn-pb-2 hvn-mb-3 hvn-mt-4 hvn-text-primary hvn-fw-bold"><i class="bi bi-globe hvn-me-1"></i> Nameservers</h6>
                <div class="hvn-mb-4">
                    <label class="hvn-form-label">Danh sách Nameserver <span class="hvn-text-danger">*</span></label>
                    <textarea class="hvn-form-control font-monospace" name="nameservers" rows="4"
                        x-model="form.nameservers"
                        placeholder="ns1.da-apac03.hvn.vn&#10;ns2.da-apac03.hvn.vn&#10;ns3.hvn.vn (tuỳ chọn)"></textarea>
                    <div class="form-text hvn-text-muted small">
                        <i class="bi bi-info-circle"></i> Mỗi NS một dòng. <strong>Dòng 1 = NS1, Dòng 2 = NS2</strong> — DirectAdmin yêu cầu ít nhất 2 NS để tạo zone.
                    </div>
                </div>

                <h6 class="hvn-border-bottom hvn-pb-2 hvn-mb-3 hvn-mt-4 hvn-text-primary hvn-fw-bold"><i class="bi bi-hdd-network hvn-me-1"></i> Cấu hình luồng xử lý (Queue)</h6>

                <div class="hvn-row hvn-mb-3">
                    <div class="hvn-col-md-6">
                        <label class="hvn-form-label hvn-d-block">Vai trò <span class="hvn-text-danger">*</span></label>
                        <div class="form-check form-check-inline hvn-mt-1">
                            <input class="form-check-input" type="radio" name="is_primary" id="roleSec" value="0" :checked="!form.is_primary" @change="form.is_primary = false">
                            <label class="form-check-label hvn-cursor-pointer" for="roleSec">Secondary</label>
                        </div>
                        <div class="form-check form-check-inline hvn-mt-1">
                            <input class="form-check-input" type="radio" name="is_primary" id="rolePri" value="1" :checked="form.is_primary" @change="form.is_primary = true">
                            <label class="form-check-label hvn-cursor-pointer hvn-fw-bold hvn-text-primary" for="rolePri">Primary <i class="bi bi-star-fill hvn-text-warning small"></i></label>
                        </div>
                        <div class="form-text hvn-text-muted small"><i class="bi bi-info-circle"></i> Chỉ định 1 Primary cho Zone Transfer.</div>
                    </div>
                    <div class="hvn-col-md-6">
                        <label class="hvn-form-label">Max Concurrent Jobs <span class="hvn-text-danger">*</span></label>
                        <input type="number" class="hvn-form-control font-monospace" name="max_concurrent_jobs" x-model="form.max_concurrent_jobs" required min="1" max="500">
                        <div class="form-text hvn-text-muted small">Khuyến nghị 50-100 (tùy thuộc tải DA).</div>
                    </div>
                </div>

                <div class="hvn-mb-4">
                    <label class="hvn-form-label">Ghi chú nội bộ</label>
                    <textarea class="hvn-form-control" rows="2" name="notes" x-model="form.notes" placeholder="VD: Server DC Viettel..."></textarea>
                </div>

                <!-- Test Connection Result Area -->
                <template x-if="testStatus !== null">
                    <div class="hvn-card hvn-mb-4 hvn-border-2" :class="{literal}{ 'hvn-border-info': testStatus === 'loading', 'hvn-border-success': testStatus === 'success', 'hvn-border-danger': testStatus === 'error' }{/literal}">
                        <div class="hvn-card-header bg-transparent hvn-py-2 hvn-d-flex hvn-justify-content-between hvn-align-items-center">
                            <strong><i class="bi bi-plug" :class="{literal}{ 'hvn-text-info': testStatus === 'loading', 'hvn-text-success': testStatus === 'success', 'hvn-text-danger': testStatus === 'error' }{/literal}"></i> Kết quả Test Connection:</strong>
                            <button type="button" class="btn-close" style="font-size: 0.6rem;" @click="testStatus = null"></button>
                        </div>
                        <div class="hvn-card-body hvn-py-3">
                            <template x-if="testStatus === 'loading'">
                                <div class="hvn-text-center hvn-py-2 hvn-text-info hvn-fw-medium">
                                    <span class="hvn-spinner-border hvn-spinner-border-sm hvn-me-2" role="status"></span> Đang kiểm tra kết nối API tới DirectAdmin...
                                </div>
                            </template>
                            <template x-if="testStatus === 'success'">
                                <pre class="hvn-mb-0 hvn-text-success hvn-fw-bold font-monospace hvn-p-2 hvn-bg-success-subtle hvn-rounded" style="white-space: pre-wrap; font-size: 13px;" x-text="testResult"></pre>
                            </template>
                            <template x-if="testStatus === 'error'">
                                <pre class="hvn-mb-0 hvn-text-danger hvn-fw-bold font-monospace hvn-p-2 hvn-bg-danger-subtle hvn-rounded" style="white-space: pre-wrap; font-size: 13px;" x-text="testResult"></pre>
                            </template>
                        </div>
                    </div>
                </template>

                <!-- Form Actions -->
                <div class="hvn-d-flex hvn-justify-content-between hvn-pt-3 hvn-border-top">
                    <button type="button" class="hvn-btn hvn-btn-outline-info" @click="testConn()" :disabled="submitting || testStatus === 'loading'">
                        <i class="bi bi-lightning-charge"></i> Test Connection
                    </button>

                    <div class="hvn-gap-2 hvn-d-flex">
                        <a href="{$modulelink}&action=servers" class="hvn-btn hvn-btn-outline-secondary" :class="{literal}{ 'disabled': submitting }{/literal}">Quay lại</a>
                        <button type="submit" class="hvn-btn hvn-btn-primary" :disabled="submitting">
                            <span x-show="!submitting"><i class="bi bi-save hvn-me-1"></i> Lưu Server</span>
                            <span x-show="submitting"><span class="hvn-spinner-border hvn-spinner-border-sm" role="status"></span> Đang lưu...</span>
                        </button>
                    </div>
                </div>
            </form>
        </div>
    </div>
</div>

<script>
    var HVNDNS_SERVER  = {$serverJson};
    var HVNDNS_IS_EDIT = {if $isEdit}true{else}false{/if};
    var HVNDNS_MODULELINK = '{$modulelink|escape:'javascript'}';
</script>
<script>
{literal}
document.addEventListener('alpine:init', () => {
    Alpine.data('serverEditor', () => ({
        isEdit: HVNDNS_IS_EDIT,
        form: HVNDNS_SERVER ? {
            id:                  HVNDNS_SERVER.id,
            hostname:            HVNDNS_SERVER.hostname,
            ip_address:          HVNDNS_SERVER.ip_address,
            port:                HVNDNS_SERVER.port,
            use_ssl:             HVNDNS_SERVER.use_ssl,
            username:            HVNDNS_SERVER.username,
            password:            '',
            nameservers:         HVNDNS_SERVER.nameservers || '',
            is_primary:          HVNDNS_SERVER.is_primary,
            max_concurrent_jobs: HVNDNS_SERVER.max_concurrent_jobs,
            notes:               HVNDNS_SERVER.notes,
        } : {
            id: null, hostname: '', ip_address: '', port: 2222, use_ssl: true,
            username: 'admin', password: '', nameservers: '', is_primary: false, max_concurrent_jobs: 50, notes: ''
        },
        submitting: false,
        testStatus: null,
        testResult: '',

        saveServer(event) {
            this.submitting = true;
            // Submit native form — POST to controller
            event.target.submit();
        },

        async testConn() {
            if (!this.form.hostname || !this.form.ip_address || !this.form.username) {
                window._hvnToast('warning', 'Thiếu thông tin', 'Vui lòng điền đầy đủ Hostname, IP và Username để Test.');
                return;
            }
            if (!this.form.password && !this.isEdit) {
                window._hvnToast('warning', 'Thiếu Password', 'Vui lòng nhập Password để Test.');
                return;
            }

            this.testStatus = 'loading';
            this.testResult = '';

            try {
                const formData = new FormData();
                formData.append('hostname',   this.form.hostname);
                formData.append('ip_address', this.form.ip_address);
                formData.append('port',       this.form.port);
                formData.append('use_ssl',    this.form.use_ssl ? '1' : '0');
                formData.append('username',   this.form.username);
                formData.append('password',   this.form.password);
                if (this.form.id) {
                    formData.append('server_id', this.form.id);
                }

                const url = HVNDNS_MODULELINK + '&action=ajax&method=testConnection';
                const res  = await fetch(url, {
                    method: 'POST',
                    headers: { 'X-Requested-With': 'XMLHttpRequest' },
                    body: formData
                });
                const data = await res.json();

                if (data.success) {
                    this.testStatus = 'success';
                    this.testResult = '✅ Kết nối thành công!\n' + (data.data?.message || '');
                } else {
                    this.testStatus = 'error';
                    this.testResult = '❌ Lỗi kết nối!\n' + (data.error?.message || 'Unknown error');
                }
            } catch (e) {
                this.testStatus = 'error';
                this.testResult = '❌ Lỗi kết nối!\n' + e.message;
            }
        }
    }));
});
{/literal}
</script>
