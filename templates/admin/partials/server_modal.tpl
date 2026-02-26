<!-- Server Modal Component -->
<div x-data="{
    isOpen: false,
    isEdit: false,
    form: { id: null, hostname: '', ip_address: '', port: 2222, use_ssl: true, username: 'admin', password: '', is_primary: false, max_concurrent_jobs: 50, notes: '' },
    submitting: false,
    testStatus: null, // null, 'loading', 'success', 'error'
    testResult: '',

    closeModal() {
        this.isOpen = false;
        this.testStatus = null;
    },

    saveServer() {
        this.submitting = true;
        setTimeout(() => {
            this.submitting = false;
            alert('Lưu server thành công (Mock)!');
            this.closeModal();
        }, 800);
    },

    testConn() {
        if(!this.form.hostname || !this.form.ip_address || !this.form.username || (!this.form.password && !this.isEdit)) {
            alert('Vui lòng điền đầy đủ Hostname, IP, Username và Password để Test.');
            return;
        }

        this.testStatus = 'loading';
        setTimeout(() => {
            // Mock random success/fail for demo
            if(Math.random() > 0.3) {
                this.testStatus = 'success';
                this.testResult = '✅ Kết nối thành công!\nDirectAdmin v1.65.0\nLatency: 42ms\nDNS Zones: 156\nDNSSEC: Enabled';
            } else {
                this.testStatus = 'error';
                this.testResult = '❌ Lỗi kết nối!\nConnection timed out (15000ms)';
            }
        }, 1500);
    }
}" @open-server-modal.window="
    isOpen = true;
    isEdit = !!$event.detail.server;
    if(isEdit) {
        form = { ...$event.detail.server, password: '' }; // Không load pass cũ
    } else {
        form = { id: null, hostname: '', ip_address: '', port: 2222, use_ssl: true, username: 'admin', password: '', is_primary: false, max_concurrent_jobs: 50, notes: '' };
    }
    testStatus = null;
">
    <!-- Custom Alpine Backdrop -->
    <div x-show="isOpen" x-transition.opacity 
         style="position: fixed; top: 0; left: 0; width: 100vw; height: 100vh; background-color: rgba(0,0,0,0.5); z-index: 1040; display: none;"></div>

    <!-- Modal Container -->
    <div class="modal fade" :class="{ 'show': isOpen }" :style="isOpen ? 'display: block; z-index: 1045;' : 'display: none;'" 
         tabindex="-1" aria-hidden="true" @click.self="closeModal()" x-show="isOpen" x-transition.opacity>
    <div class="modal-dialog modal-lg">
        <div class="modal-content">
            <div class="modal-header hvn-bg-light hvn-border-bottom">
                <h5 class="modal-title hvn-fw-bold"><i class="bi bi-server hvn-text-primary"></i> <span x-text="isEdit ? 'Sửa Server DirectAdmin' : 'Thêm Server DirectAdmin'"></span></h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
            </div>
            <div class="modal-body hvn-p-4">
                <form @submit.prevent="saveServer">
                    
                    <div class="hvn-row hvn-mb-3">
                        <div class="hvn-col-md-6">
                            <label class="hvn-form-label">Hostname <span class="hvn-text-danger">*</span></label>
                            <input type="text" class="hvn-form-control font-monospace" x-model="form.hostname" required placeholder="dns4.hvn.vn">
                            <div class="form-text hvn-text-muted small"><i class="bi bi-info-circle"></i> Tên hiển thị cho khách hàng (không hiện IP)</div>
                        </div>
                        <div class="hvn-col-md-6">
                            <label class="hvn-form-label">Địa chỉ IP <span class="hvn-text-danger">*</span></label>
                            <input type="text" class="hvn-form-control font-monospace" x-model="form.ip_address" required placeholder="103.xx.xx.13">
                        </div>
                    </div>

                    <div class="hvn-row hvn-mb-4">
                        <div class="hvn-col-md-3">
                            <label class="hvn-form-label">Port <span class="hvn-text-danger">*</span></label>
                            <input type="number" class="hvn-form-control font-monospace" x-model="form.port" required min="1" max="65535">
                        </div>
                        <div class="hvn-col-md-3 hvn-d-flex hvn-align-items-center hvn-mt-3">
                            <div class="form-check form-switch hvn-mt-2">
                                <input class="form-check-input" type="checkbox" id="useSsl" x-model="form.use_ssl">
                                <label class="form-check-label hvn-cursor-pointer" for="useSsl">Sử dụng SSL (HTTPS)</label>
                            </div>
                        </div>
                    </div>

                    <h6 class="hvn-border-bottom hvn-pb-2 hvn-mb-3 hvn-mt-4 hvn-text-primary hvn-fw-bold"><i class="bi bi-shield-lock hvn-me-1"></i> Thông tin đăng nhập DirectAdmin</h6>
                    <div class="hvn-row hvn-mb-4">
                        <div class="hvn-col-md-6">
                            <label class="hvn-form-label">Username <span class="hvn-text-danger">*</span></label>
                            <input type="text" class="hvn-form-control font-monospace" x-model="form.username" required>
                        </div>
                        <div class="hvn-col-md-6">
                            <label class="hvn-form-label">Password <span x-show="!isEdit" class="hvn-text-danger">*</span></label>
                            <input type="password" class="hvn-form-control font-monospace" x-model="form.password" :required="!isEdit" placeholder="••••••••">
                            <div class="form-text hvn-text-muted small"><i class="bi bi-lock-fill"></i> Mật khẩu mã hóa AES-256. <span x-show="isEdit" class="hvn-fw-bold hvn-text-warning">Để trống nếu giữ nguyên.</span></div>
                        </div>
                    </div>

                    <h6 class="hvn-border-bottom hvn-pb-2 hvn-mb-3 hvn-mt-4 hvn-text-primary hvn-fw-bold"><i class="bi bi-hdd-network hvn-me-1"></i> Cấu hình luồng xử lý (Queue)</h6>
                    <div class="hvn-row hvn-mb-3">
                        <div class="hvn-col-md-6">
                            <label class="hvn-form-label hvn-d-block">Vai trò <span class="hvn-text-danger">*</span></label>
                            <div class="form-check form-check-inline hvn-mt-1">
                                <input class="form-check-input" type="radio" name="role" id="roleSec" :value="false" x-model="form.is_primary">
                                <label class="form-check-label hvn-cursor-pointer" for="roleSec">Secondary</label>
                            </div>
                            <div class="form-check form-check-inline hvn-mt-1">
                                <input class="form-check-input" type="radio" name="role" id="rolePri" :value="true" x-model="form.is_primary">
                                <label class="form-check-label hvn-cursor-pointer hvn-fw-bold hvn-text-primary" for="rolePri">Primary <i class="bi bi-star-fill hvn-text-warning small"></i></label>
                            </div>
                            <div class="form-text hvn-text-muted small"><i class="bi bi-info-circle"></i> Chỉ định 1 Primary cho Zone Transfer.</div>
                        </div>
                        <div class="hvn-col-md-6">
                            <label class="hvn-form-label">Max Concurrent Jobs <span class="hvn-text-danger">*</span></label>
                            <input type="number" class="hvn-form-control font-monospace" x-model="form.max_concurrent_jobs" required min="1" max="500">
                            <div class="form-text hvn-text-muted small">Khuyến nghị 50-100 (tùy thuộc tải DA).</div>
                        </div>
                    </div>

                    <div class="hvn-mb-4">
                        <label class="hvn-form-label">Ghi chú nội bộ</label>
                        <textarea class="hvn-form-control" rows="2" x-model="form.notes" placeholder="VD: Server DC Viettel..."></textarea>
                    </div>

                    <!-- Test Connection Result Area -->
                    <template x-if="testStatus !== null">
                        <div class="hvn-card hvn-mb-4 hvn-border-2" :class="{ 'hvn-border-info': testStatus === 'loading', 'hvn-border-success': testStatus === 'success', 'hvn-border-danger': testStatus === 'error' }">
                            <div class="hvn-card-header bg-transparent hvn-py-2 hvn-d-flex hvn-justify-content-between hvn-align-items-center">
                                <strong><i class="bi bi-plug" :class="{ 'hvn-text-info': testStatus === 'loading', 'hvn-text-success': testStatus === 'success', 'hvn-text-danger': testStatus === 'error' }"></i> Kết quả Test Connection:</strong>
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

                    <!-- Modal Actions -->
                    <div class="hvn-d-flex hvn-justify-content-between hvn-pt-3">
                        <button type="button" class="hvn-btn hvn-btn-outline-info" @click="testConn()" :disabled="submitting || testStatus === 'loading'">
                            <i class="bi bi-lightning-charge"></i> Test Connection
                        </button>
                        
                        <div class="hvn-gap-2 hvn-d-flex">
                            <button type="button" class="hvn-btn hvn-btn-outline-secondary" @click="closeModal()" :disabled="submitting">Hủy bỏ</button>
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
</div>
