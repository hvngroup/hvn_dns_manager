<div class="mj-dns-admin mj-server-edit" x-data="serverEditor()">
    <div class="mj-d-flex mj-justify-content-between mj-align-items-center mj-mb-4">
        <h2>
            <a href="{$modulelink}&action=servers" class="text-decoration-none mj-text-muted mj-me-2"><i class="bi bi-arrow-left"></i></a>
            <i class="bi bi-server"></i> <span x-text="isEdit ? 'Sửa Server DirectAdmin' : 'Thêm Server DirectAdmin'"></span>
        </h2>
    </div>

    {* Flash message *}
    {if $flash}
    <div class="mj-alert mj-alert-{if $flash.type === 'success'}success{else}danger{/if} mj-alert-dismissible mj-fade mj-show mj-mb-4" role="alert">
        <i class="bi bi-{if $flash.type === 'success'}check-circle{else}exclamation-triangle{/if} mj-me-2"></i>
        {$flash.message|escape:'htmlall'}
        <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
    </div>
    {/if}

    <div class="mj-card mj-shadow-sm mj-border-0">
        <div class="mj-card-body mj-p-4">
            <form method="POST" action="{$modulelink}&action=server_edit" @submit.prevent="saveServer($event)">
                <input type="hidden" name="token" value="{$token}">
                <input type="hidden" name="id" value="{$serverId}" :value="form.id || {$serverId}">

                <div class="mj-row mj-mb-3">
                    <div class="mj-col-md-6">
                        <label class="mj-form-label">Hostname <span class="mj-text-danger">*</span></label>
                        <input type="text" class="mj-form-control font-monospace" name="hostname" x-model="form.hostname" required placeholder="dns4.hvn.vn">
                        <div class="form-text mj-text-muted small"><i class="bi bi-info-circle"></i> Tên hiển thị cho khách hàng (không hiện IP)</div>
                    </div>
                    <div class="mj-col-md-6">
                        <label class="mj-form-label">Địa chỉ IP <span class="mj-text-danger">*</span></label>
                        <input type="text" class="mj-form-control font-monospace" name="ip_address" x-model="form.ip_address" required placeholder="103.xx.xx.13">
                    </div>
                </div>

                <div class="mj-row mj-mb-4">
                    <div class="mj-col-md-3">
                        <label class="mj-form-label">Port <span class="mj-text-danger">*</span></label>
                        <input type="number" class="mj-form-control font-monospace" name="port" x-model="form.port" required min="1" max="65535">
                    </div>
                    <div class="mj-col-md-3 mj-d-flex mj-align-items-center mj-mt-3">
                        <div class="form-check form-switch mj-mt-2">
                            <input class="form-check-input" type="checkbox" id="useSsl" x-model="form.use_ssl" name="use_ssl" value="1">
                            <label class="form-check-label mj-cursor-pointer" for="useSsl">Sử dụng SSL (HTTPS)</label>
                        </div>
                    </div>
                </div>

                <h6 class="mj-border-bottom mj-pb-2 mj-mb-3 mj-mt-4 mj-text-primary mj-fw-bold"><i class="bi bi-shield-lock mj-me-1"></i> Thông tin đăng nhập DirectAdmin</h6>
                <div class="mj-row mj-mb-4">
                    <div class="mj-col-md-6">
                        <label class="mj-form-label">Username <span class="mj-text-danger">*</span></label>
                        <input type="text" class="mj-form-control font-monospace" name="username" x-model="form.username" required>
                    </div>
                    <div class="mj-col-md-6">
                        <label class="mj-form-label">Password <span x-show="!isEdit" class="mj-text-danger">*</span></label>
                        <input type="password" class="mj-form-control font-monospace" name="password" x-model="form.password" :required="!isEdit" placeholder="••••••••">
                        <div class="form-text mj-text-muted small"><i class="bi bi-lock-fill"></i> Mật khẩu mã hóa AES-256. <span x-show="isEdit" class="mj-fw-bold mj-text-warning">Để trống nếu giữ nguyên.</span></div>
                    </div>
                </div>

                <h6 class="mj-border-bottom mj-pb-2 mj-mb-3 mj-mt-4 mj-text-primary mj-fw-bold"><i class="bi bi-globe mj-me-1"></i> Nameservers</h6>
                <div class="mj-mb-4">
                    <label class="mj-form-label">Danh sách Nameserver <span class="mj-text-danger">*</span></label>
                    <textarea class="mj-form-control font-monospace" name="nameservers" rows="4"
                        x-model="form.nameservers"
                        placeholder="ns1.da-apac03.hvn.vn&#10;ns2.da-apac03.hvn.vn&#10;ns3.hvn.vn (tuỳ chọn)"></textarea>
                    <div class="form-text mj-text-muted small">
                        <i class="bi bi-info-circle"></i> Mỗi NS một dòng. <strong>Dòng 1 = NS1, Dòng 2 = NS2</strong> — DirectAdmin yêu cầu ít nhất 2 NS để tạo zone.
                    </div>
                </div>

                <h6 class="mj-border-bottom mj-pb-2 mj-mb-3 mj-mt-4 mj-text-primary mj-fw-bold"><i class="bi bi-hdd-network mj-me-1"></i> Cấu hình luồng xử lý (Queue)</h6>

                <div class="mj-row mj-mb-3">
                    <div class="mj-col-md-6">
                        <label class="mj-form-label mj-d-block">Vai trò <span class="mj-text-danger">*</span></label>
                        <div class="form-check form-check-inline mj-mt-1">
                            <input class="form-check-input" type="radio" name="is_primary" id="roleSec" value="0" :checked="!form.is_primary" @change="form.is_primary = false">
                            <label class="form-check-label mj-cursor-pointer" for="roleSec">Secondary</label>
                        </div>
                        <div class="form-check form-check-inline mj-mt-1">
                            <input class="form-check-input" type="radio" name="is_primary" id="rolePri" value="1" :checked="form.is_primary" @change="form.is_primary = true">
                            <label class="form-check-label mj-cursor-pointer mj-fw-bold mj-text-primary" for="rolePri">Primary <i class="bi bi-star-fill mj-text-warning small"></i></label>
                        </div>
                        <div class="form-text mj-text-muted small"><i class="bi bi-info-circle"></i> Chỉ định 1 Primary cho Zone Transfer.</div>
                    </div>
                    <div class="mj-col-md-6">
                        <label class="mj-form-label">Max Concurrent Jobs <span class="mj-text-danger">*</span></label>
                        <input type="number" class="mj-form-control font-monospace" name="max_concurrent_jobs" x-model="form.max_concurrent_jobs" required min="1" max="500">
                        <div class="form-text mj-text-muted small">Khuyến nghị 50-100 (tùy thuộc tải DA).</div>
                    </div>
                </div>

                <div class="mj-mb-4">
                    <label class="mj-form-label">Ghi chú nội bộ</label>
                    <textarea class="mj-form-control" rows="2" name="notes" x-model="form.notes" placeholder="VD: Server DC Viettel..."></textarea>
                </div>

                <!-- Test Connection Result Area -->
                <template x-if="testStatus !== null">
                    <div class="mj-card mj-mb-4 mj-border-2" :class="{literal}{ 'mj-border-info': testStatus === 'loading', 'mj-border-success': testStatus === 'success', 'mj-border-danger': testStatus === 'error' }{/literal}">
                        <div class="mj-card-header bg-transparent mj-py-2 mj-d-flex mj-justify-content-between mj-align-items-center">
                            <strong><i class="bi bi-plug" :class="{literal}{ 'mj-text-info': testStatus === 'loading', 'mj-text-success': testStatus === 'success', 'mj-text-danger': testStatus === 'error' }{/literal}"></i> Kết quả Test Connection:</strong>
                            <button type="button" class="btn-close" style="font-size: 0.6rem;" @click="testStatus = null"></button>
                        </div>
                        <div class="mj-card-body mj-py-3">
                            <template x-if="testStatus === 'loading'">
                                <div class="mj-text-center mj-py-2 mj-text-info mj-fw-medium">
                                    <span class="mj-spinner-border mj-spinner-border-sm mj-me-2" role="status"></span> Đang kiểm tra kết nối API tới DirectAdmin...
                                </div>
                            </template>
                            <template x-if="testStatus === 'success'">
                                <pre class="mj-mb-0 mj-text-success mj-fw-bold font-monospace mj-p-2 mj-bg-success-subtle mj-rounded" style="white-space: pre-wrap; font-size: 13px;" x-text="testResult"></pre>
                            </template>
                            <template x-if="testStatus === 'error'">
                                <pre class="mj-mb-0 mj-text-danger mj-fw-bold font-monospace mj-p-2 mj-bg-danger-subtle mj-rounded" style="white-space: pre-wrap; font-size: 13px;" x-text="testResult"></pre>
                            </template>
                        </div>
                    </div>
                </template>

                <!-- Form Actions -->
                <div class="mj-d-flex mj-justify-content-between mj-pt-3 mj-border-top">
                    <button type="button" class="mj-btn mj-btn-outline-info" @click="testConn()" :disabled="submitting || testStatus === 'loading'">
                        <i class="bi bi-lightning-charge"></i> Test Connection
                    </button>

                    <div class="mj-gap-2 mj-d-flex">
                        <a href="{$modulelink}&action=servers" class="mj-btn mj-btn-outline-secondary" :class="{literal}{ 'disabled': submitting }{/literal}">Quay lại</a>
                        <button type="submit" class="mj-btn mj-btn-primary" :disabled="submitting">
                            <span x-show="!submitting"><i class="bi bi-save mj-me-1"></i> Lưu Server</span>
                            <span x-show="submitting"><span class="mj-spinner-border mj-spinner-border-sm" role="status"></span> Đang lưu...</span>
                        </button>
                    </div>
                </div>
            </form>
        </div>
    </div>
</div>

<script>
    var MJDNS_SERVER  = {$serverJson};
    var MJDNS_IS_EDIT = {if $isEdit}true{else}false{/if};
    var MJDNS_MODULELINK = '{$modulelink|escape:'javascript'}';
</script>
<script>
{literal}
document.addEventListener('alpine:init', () => {
    Alpine.data('serverEditor', () => ({
        isEdit: MJDNS_IS_EDIT,
        form: MJDNS_SERVER ? {
            id:                  MJDNS_SERVER.id,
            hostname:            MJDNS_SERVER.hostname,
            ip_address:          MJDNS_SERVER.ip_address,
            port:                MJDNS_SERVER.port,
            use_ssl:             MJDNS_SERVER.use_ssl,
            username:            MJDNS_SERVER.username,
            password:            '',
            nameservers:         MJDNS_SERVER.nameservers || '',
            is_primary:          MJDNS_SERVER.is_primary,
            max_concurrent_jobs: MJDNS_SERVER.max_concurrent_jobs,
            notes:               MJDNS_SERVER.notes,
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
                window._mjDnsToast('warning', 'Thiếu thông tin', 'Vui lòng điền đầy đủ Hostname, IP và Username để Test.');
                return;
            }
            if (!this.form.password && !this.isEdit) {
                window._mjDnsToast('warning', 'Thiếu Password', 'Vui lòng nhập Password để Test.');
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

                const url = MJDNS_MODULELINK + '&action=ajax&method=testConnection';
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
