<!-- Server Modal -->
<div class="modal fade" id="serverModal" tabindex="-1" aria-hidden="true" x-data="{
    isEdit: false,
    form: { id: null, hostname: '', ip_address: '', port: 2222, use_ssl: true, username: 'admin', password: '', is_primary: false, max_concurrent_jobs: 50, notes: '' },
    submitting: false,
    testStatus: null, // null, 'loading', 'success', 'error'
    testResult: '',

    closeModal() {
        bootstrap.Modal.getInstance(document.getElementById('serverModal')).hide();
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
    isEdit = !!$event.detail.server;
    if(isEdit) {
        form = { ...$event.detail.server, password: '' }; // Không load pass cũ
    } else {
        form = { id: null, hostname: '', ip_address: '', port: 2222, use_ssl: true, username: 'admin', password: '', is_primary: false, max_concurrent_jobs: 50, notes: '' };
    }
    testStatus = null;
    new bootstrap.Modal(document.getElementById('serverModal')).show();
">
    <div class="modal-dialog modal-lg">
        <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title" x-text="isEdit ? 'Sửa Server DirectAdmin' : 'Thêm Server DirectAdmin'"></h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
            </div>
            <div class="modal-body">
                <form @submit.prevent="saveServer">
                    
                    <div class="row mb-3">
                        <div class="col-md-6">
                            <label class="form-label">Hostname <span class="text-danger">*</span></label>
                            <input type="text" class="form-control" x-model="form.hostname" required placeholder="dns4.hvn.vn">
                            <div class="form-text"><i class="bi bi-info-circle"></i> Tên hiển thị cho khách hàng (không hiện IP)</div>
                        </div>
                        <div class="col-md-6">
                            <label class="form-label">Địa chỉ IP <span class="text-danger">*</span></label>
                            <input type="text" class="form-control" x-model="form.ip_address" required placeholder="103.xx.xx.13">
                        </div>
                    </div>

                    <div class="row mb-4">
                        <div class="col-md-3">
                            <label class="form-label">Port <span class="text-danger">*</span></label>
                            <input type="number" class="form-control" x-model="form.port" required min="1" max="65535">
                        </div>
                        <div class="col-md-3 d-flex align-items-center mt-3">
                            <div class="form-check form-switch mt-2">
                                <input class="form-check-input" type="checkbox" id="useSsl" x-model="form.use_ssl">
                                <label class="form-check-label" for="useSsl">Sử dụng SSL (HTTPS)</label>
                            </div>
                        </div>
                    </div>

                    <h6 class="border-bottom pb-2 mb-3 mt-4 text-primary">Thông tin đăng nhập DirectAdmin</h6>
                    <div class="row mb-4">
                        <div class="col-md-6">
                            <label class="form-label">Username <span class="text-danger">*</span></label>
                            <input type="text" class="form-control" x-model="form.username" required>
                        </div>
                        <div class="col-md-6">
                            <label class="form-label">Password <span x-show="!isEdit" class="text-danger">*</span></label>
                            <input type="password" class="form-control" x-model="form.password" :required="!isEdit" placeholder="••••••••">
                            <div class="form-text text-muted"><i class="bi bi-lock"></i> Mật khẩu được mã hóa AES-256 nội bộ WHMCS. <span x-show="isEdit">Để trống nếu không muốn đổi.</span></div>
                        </div>
                    </div>

                    <h6 class="border-bottom pb-2 mb-3 mt-4 text-primary">Cấu hình luồng xử lý (Queue)</h6>
                    <div class="row mb-3">
                        <div class="col-md-6">
                            <label class="form-label d-block">Vai trò <span class="text-danger">*</span></label>
                            <div class="form-check form-check-inline mt-1">
                                <input class="form-check-input" type="radio" name="role" id="roleSec" :value="false" x-model="form.is_primary">
                                <label class="form-check-label" for="roleSec">Secondary</label>
                            </div>
                            <div class="form-check form-check-inline mt-1">
                                <input class="form-check-input" type="radio" name="role" id="rolePri" :value="true" x-model="form.is_primary">
                                <label class="form-check-label fw-bold text-primary" for="rolePri">Primary</label>
                            </div>
                            <div class="form-text"><i class="bi bi-info-circle"></i> Primary dùng cho Drift Detection, Zone Transfer master. Thường chỉ nên có 1 Primary.</div>
                        </div>
                        <div class="col-md-6">
                            <label class="form-label">Max Concurrent Jobs <span class="text-danger">*</span></label>
                            <input type="number" class="form-control" x-model="form.max_concurrent_jobs" required min="1" max="500">
                            <div class="form-text">Số job tối đa xử lý mỗi chu kỳ cron cho server này. Tùy thuộc vào phần cứng DA.</div>
                        </div>
                    </div>

                    <div class="mb-4">
                        <label class="form-label">Ghi chú nội bộ</label>
                        <textarea class="form-control" rows="2" x-model="form.notes"></textarea>
                    </div>

                    <!-- Test Connection Result Area -->
                    <template x-if="testStatus !== null">
                        <div class="card mb-3" :class="{'border-info': testStatus === 'loading', 'border-success': testStatus === 'success', 'border-danger': testStatus === 'error'}">
                            <div class="card-header bg-transparent py-2 d-flex justify-content-between align-items-center">
                                <strong><i class="bi bi-plug"></i> Kết quả Test Connection:</strong>
                                <button type="button" class="btn-close" style="font-size: 0.5rem;" @click="testStatus = null"></button>
                            </div>
                            <div class="card-body py-2">
                                <template x-if="testStatus === 'loading'">
                                    <div class="text-center py-2 text-info">
                                        <div class="spinner-border spinner-border-sm me-2" role="status"></div> Đang kiểm tra kết nối tới DirectAdmin API...
                                    </div>
                                </template>
                                <template x-if="testStatus === 'success'">
                                    <pre class="mb-0 text-success fw-bold font-monospace" style="white-space: pre-wrap;" x-text="testResult"></pre>
                                </template>
                                <template x-if="testStatus === 'error'">
                                    <pre class="mb-0 text-danger fw-bold font-monospace" style="white-space: pre-wrap;" x-text="testResult"></pre>
                                </template>
                            </div>
                        </div>
                    </template>

                    <!-- Modal Actions -->
                    <div class="d-flex justify-content-between pt-3 border-top">
                        <button type="button" class="btn btn-outline-info" @click="testConn()" :disabled="submitting || testStatus === 'loading'">
                            <i class="bi bi-plug"></i> Test Connection
                        </button>
                        
                        <div class="gap-2 d-flex">
                            <button type="button" class="btn btn-outline-secondary" @click="closeModal()" :disabled="submitting">Hủy</button>
                            <button type="submit" class="btn btn-primary" :disabled="submitting">
                                <span x-show="!submitting"><i class="bi bi-save"></i> Lưu Server</span>
                                <span x-show="submitting"><span class="spinner-border spinner-border-sm" role="status"></span> Đang lưu...</span>
                            </button>
                        </div>
                    </div>
                </form>
            </div>
        </div>
    </div>
</div>
