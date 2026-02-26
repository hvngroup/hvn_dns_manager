<div class="hvn-dns-admin hvn-bulk-operations" x-data="bulkManager()">
    <div class="d-flex justify-content-between align-items-center mb-4">
        <h2><i class="bi bi-lightning-charge"></i> Thao tác Hàng loạt (Bulk Operations)</h2>
    </div>

    <div class="alert alert-info border-info d-flex align-items-center mb-4">
        <i class="bi bi-info-circle-fill me-3 fs-3"></i>
        <div>
            Sử dụng tính năng này để thay đổi cấu hình DNS của hàng trăm domain cùng một lúc (VD: khi đổi IP Server).
            Hệ thống sẽ <strong>tự động tạo Zone Snapshot</strong> cho từng domain trước khi thực hiện để đảm bảo an toàn.
        </div>
    </div>

    <div class="row">
        <!-- Sidebar Selection -->
        <div class="col-md-4 mb-4">
            <div class="card shadow-sm border-0 h-100">
                <div class="card-header bg-light fw-bold py-3"><i class="bi bi-tools"></i> Chọn thao tác</div>
                <div class="list-group list-group-flush rounded-bottom">
                    <button class="list-group-item list-group-item-action py-3 d-flex align-items-center" 
                            :class="{'active bg-primary border-primary': operation === 'change_ip'}" 
                            @click="operation = 'change_ip'; resetState()">
                        <i class="bi bi-input-cursor-text fs-4 me-3"></i>
                        <div>
                            <div class="fw-bold">Thay đổi IP hàng loạt</div>
                            <small class="opacity-75" :class="{'text-white': operation === 'change_ip'}">Thay thế IP cũ bằng IP mới trên mọi domain</small>
                        </div>
                    </button>
                    <button class="list-group-item list-group-item-action py-3 d-flex align-items-center" 
                            :class="{'active bg-primary border-primary': operation === 'apply_template'}" 
                            @click="operation = 'apply_template'; resetState()">
                        <i class="bi bi-file-earmark-code fs-4 me-3"></i>
                        <div>
                            <div class="fw-bold">Áp dụng Template hàng loạt</div>
                            <small class="opacity-75" :class="{'text-white': operation === 'apply_template'}">Ghi đè DNS template lên các domain đã chọn</small>
                        </div>
                    </button>
                </div>
            </div>
        </div>

        <!-- Main Form Area -->
        <div class="col-md-8 mb-4">
            <div class="card shadow-sm border-0 h-100">
                <div class="card-header bg-light fw-bold py-3">
                    <span x-show="operation === 'change_ip'"><i class="bi bi-input-cursor-text"></i> Cấu hình Thay đổi IP</span>
                    <span x-show="operation === 'apply_template'"><i class="bi bi-file-earmark-code"></i> Cấu hình Áp dụng Template</span>
                </div>
                <div class="card-body p-4">
                    
                    <!-- FORM: Change IP -->
                    <template x-if="operation === 'change_ip'">
                        <div class="row g-4 mb-4">
                            <div class="col-md-6">
                                <label class="form-label fw-bold">IP Cũ (Sẽ bị thay thế)</label>
                                <input type="text" class="form-control font-monospace" x-model="formIp.oldIp" placeholder="103.45.67.89">
                            </div>
                            <div class="col-md-6">
                                <label class="form-label fw-bold text-success">IP Mới (Sẽ áp dụng)</label>
                                <input type="text" class="form-control font-monospace border-success" x-model="formIp.newIp" placeholder="103.45.67.100">
                            </div>
                        </div>
                    </template>

                    <!-- FORM: Apply Template -->
                    <template x-if="operation === 'apply_template'">
                        <div class="mb-4">
                            <label class="form-label fw-bold">Chọn Template DNS</label>
                            <select class="form-select" x-model="formTemplate.templateId">
                                <option value="">-- Vui lòng chọn --</option>
                                <option value="1">Basic DNS (Chứa 6 bản ghi)</option>
                                <option value="2">Email Optimized (Chứa 12 bản ghi)</option>
                                <option value="3">Google Workspace (Chứa 10 bản ghi)</option>
                            </select>
                            <div class="form-text text-danger mt-2"><i class="bi bi-exclamation-triangle-fill"></i> Mọi bản ghi hiện tại của các domain (ngoại trừ record bị khóa) sẽ bị XÓA và thay bằng các bản ghi trong template.</div>
                        </div>
                    </template>

                    <h6 class="border-bottom pb-2 mb-3 mt-4 text-primary">Phạm vi áp dụng (Scope)</h6>
                    
                    <div class="mb-4">
                        <div class="form-check mb-2">
                            <input class="form-check-input" type="radio" name="scopeRadio" id="scopeAll" value="all" x-model="scope">
                            <label class="form-check-label fw-bold" for="scopeAll">Tất cả domain hệ thống quản lý</label>
                        </div>
                        <div class="form-check mb-2">
                            <input class="form-check-input" type="radio" name="scopeRadio" id="scopeServer" value="server" x-model="scope">
                            <label class="form-check-label" for="scopeServer">Chỉ domain nằm trên Server cụ thể:</label>
                        </div>
                        <div class="ms-4 mb-3" x-show="scope === 'server'">
                            <select class="form-select form-select-sm w-50" x-model="scopeServerId">
                                <option value="1">dns1.hvn.vn (156 domains)</option>
                                <option value="2">dns2.hvn.vn (120 domains)</option>
                                <option value="3">dns3.hvn.vn (66 domains)</option>
                            </select>
                        </div>
                        <div class="form-check mb-2">
                            <input class="form-check-input" type="radio" name="scopeRadio" id="scopeManual" value="manual" x-model="scope">
                            <label class="form-check-label" for="scopeManual">Chọn thủ công / Nhập thủ công</label>
                        </div>
                        <div class="ms-4" x-show="scope === 'manual'">
                            <textarea class="form-control form-control-sm font-monospace" rows="3" placeholder="Nhập tên miền, mỗi dòng 1 domain..."></textarea>
                        </div>
                    </div>

                    <div class="text-end">
                        <button class="btn btn-primary" @click="scanPreview()" :disabled="isScanning">
                            <span x-show="!isScanning"><i class="bi bi-search"></i> Quét & Báo trước kết quả</span>
                            <span x-show="isScanning"><span class="spinner-border spinner-border-sm"></span> Đang quét...</span>
                        </button>
                    </div>

                </div>
            </div>
        </div>
    </div>

    <!-- PREVIEW AREA -->
    <div class="card shadow border-0 mb-4" x-show="preview.scanned" x-collapse>
        <div class="card-header bg-dark text-white fw-bold py-3"><i class="bi bi-eye"></i> Preview Kết quả Thao tác</div>
        <div class="card-body p-4 bg-light">
            <template x-if="preview.domains.length === 0">
                <div class="text-center py-4 text-muted">
                    <i class="bi bi-search display-4 mb-3 text-secondary opacity-50"></i>
                    <h5>Không có kết quả</h5>
                    <p>Không tìm thấy bản ghi/domain nào phù hợp với thông số bạn đã nhập.</p>
                </div>
            </template>

            <template x-if="preview.domains.length > 0">
                <div>
                    <div class="alert alert-success border-success">
                        <h5 class="alert-heading"><i class="bi bi-check-circle-fill"></i> Sẵn sàng thực hiện</h5>
                        Tìm thấy <strong><span x-text="preview.totalRecords"></span> bản ghi</strong> trên <strong><span x-text="preview.domains.length"></span> domain</strong> bị ảnh hưởng bởi thay đổi này.
                    </div>

                    <div class="list-group mb-4" style="max-height: 300px; overflow-y: auto;">
                        <template x-for="(dom, idx) in preview.domains" :key="idx">
                            <label class="list-group-item d-flex justify-content-between align-items-center">
                                <div>
                                    <input class="form-check-input me-2" type="checkbox" checked disabled>
                                    <span class="fw-bold" x-text="dom.name"></span>
                                    <small class="text-muted ms-2" x-text="dom.summary"></small>
                                </div>
                            </label>
                        </template>
                    </div>

                    <div class="alert alert-warning text-dark border-warning small ps-4 pe-3 py-2">
                        <i class="bi bi-shield-check me-2"></i> Hệ thống sẽ tự tạo <strong><span x-text="preview.domains.length"></span> snapshot</strong> trước khi thực hiện để đảm bảo an toàn. Tùy thuộc vào số lượng, có thể mất vài phút.
                    </div>

                    <div class="d-flex justify-content-between align-items-center">
                        <button class="btn btn-outline-secondary" @click="resetState()">Hủy bỏ</button>
                        <button class="btn btn-danger px-4" @click="executeBulk()" :disabled="isExecuting">
                            <span x-show="!isExecuting"><i class="bi bi-lightning-fill"></i> Thực hiện Thay đổi ngay!</span>
                            <span x-show="isExecuting"><span class="spinner-border spinner-border-sm"></span> Đang tiến hành...</span>
                        </button>
                    </div>

                    <!-- Progress Bar (shown when executing) -->
                    <div class="mt-4" x-show="isExecuting || isDone">
                        <div class="d-flex justify-content-between small mb-1 fw-bold">
                            <span>Tiến trình: <span x-text="progress.done"></span>/<span x-text="preview.domains.length"></span> domain</span>
                            <span x-text="Math.round((progress.done / preview.domains.length) * 100) + '%'"></span>
                        </div>
                        <div class="progress mb-2" style="height: 15px;">
                            <div class="progress-bar progress-bar-striped progress-bar-animated bg-success" role="progressbar" :style="`width: ${(progress.done / preview.domains.length) * 100}%`"></div>
                        </div>
                        <div class="d-flex small text-muted justify-content-between">
                            <div>
                                <span class="badge bg-success me-1">✅ <span x-text="progress.success"></span> thành công</span>
                                <span class="badge bg-warning text-dark me-1">⟳ <span x-text="progress.working"></span> đang xử lý</span>
                                <span class="badge bg-danger">❌ <span x-text="progress.fails"></span> lỗi</span>
                            </div>
                            <!-- Stop feature demo only -->
                            <button class="btn btn-sm btn-outline-danger py-0 border-0" x-show="isExecuting">Dừng lại</button>
                        </div>
                    </div>

                </div>
            </template>
        </div>
    </div>
</div>

<script>
document.addEventListener('alpine:init', () => {
    Alpine.data('bulkManager', () => ({
        operation: 'change_ip',
        
        formIp: { oldIp: '', newIp: '' },
        formTemplate: { templateId: '' },
        
        scope: 'all',
        scopeServerId: '1',

        isScanning: false,
        isExecuting: false,
        isDone: false,
        
        preview: {
            scanned: false,
            totalRecords: 0,
            domains: []
        },

        progress: {
            done: 0, success: 0, fails: 0, working: 0
        },

        resetState() {
            this.preview.scanned = false;
            this.isScanning = false;
            this.isExecuting = false;
            this.isDone = false;
            this.progress = { done: 0, success: 0, fails: 0, working: 0 };
        },

        scanPreview() {
            // Validation
            if (this.operation === 'change_ip' && (!this.formIp.oldIp || !this.formIp.newIp)) {
                return alert('Vui lòng nhập IP cũ và Mới!');
            }
            if (this.operation === 'apply_template' && !this.formTemplate.templateId) {
                return alert('Vui lòng chọn Template!');
            }

            this.resetState();
            this.isScanning = true;

            // Fake scan latency
            setTimeout(() => {
                this.isScanning = false;
                this.preview.scanned = true;
                
                // MOCK result
                if (this.operation === 'change_ip' && this.formIp.oldIp === '12.34.56.78') {
                    // Empty state demo
                    this.preview.domains = [];
                    this.preview.totalRecords = 0;
                } else {
                    // Filled state demo
                    this.preview.totalRecords = 23;
                    this.preview.domains = [
                        { name: 'example.com', summary: '3 records (A @, A www, A mail)' },
                        { name: 'shop.vn', summary: '2 records (A @, A www)' },
                        { name: 'myblog.net', summary: '1 record (A @)' },
                        { name: 'test.org', summary: '1 record (A @)' },
                        { name: 'demo1.io', summary: '2 records (A @, A mx)' },
                    ];
                }
            }, 1000);
        },

        executeBulk() {
            if(!confirm('Cảnh báo thay đổi hàng loạt. Vui lòng xác nhận bạn muốn tiếp tục?')) return;
            
            this.isExecuting = true;
            this.progress = { done: 0, success: 0, fails: 0, working: 2 };

            // Mock execution progress
            let total = this.preview.domains.length;
            let current = 0;
            
            let interval = setInterval(() => {
                current++;
                this.progress.done = current;
                this.progress.success = current;
                
                if (current >= total) {
                    clearInterval(interval);
                    this.isExecuting = false;
                    this.isDone = true;
                    this.progress.working = 0;
                    alert('Hoàn tất thao tác hàng loạt!');
                }
            }, 600);
        }
    }));
});
</script>
