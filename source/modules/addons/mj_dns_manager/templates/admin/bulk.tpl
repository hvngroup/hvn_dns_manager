<div class="mj-dns-admin mj-bulk-operations" x-data="bulkManager()">
    <div class="mj-d-flex mj-justify-content-between mj-align-items-center mj-mb-4">
        <h2><i class="bi bi-lightning-charge"></i> Thao tác Hàng loạt (Bulk Operations)</h2>
    </div>

    <div class="alert alert-info border-info mj-d-flex mj-align-items-center mj-mb-4">
        <i class="bi bi-info-circle-fill mj-me-3 fs-3"></i>
        <div>
            Sử dụng tính năng này để thay đổi cấu hình DNS của hàng trăm domain cùng một lúc (VD: khi đổi IP Server).
            Hệ thống sẽ <strong>tự động tạo Zone Snapshot</strong> cho từng domain trước khi thực hiện để đảm bảo an toàn.
        </div>
    </div>

    <div class="mj-row">
        <!-- Sidebar Selection -->
        <div class="mj-col-md-4 mj-mb-4">
            <div class="mj-card mj-shadow-sm mj-border-0 h-100">
                <div class="mj-card-header mj-bg-light mj-fw-bold mj-py-3"><i class="bi bi-tools"></i> Chọn thao tác</div>
                <div class="mj-list-group mj-list-group-flush mj-rounded-bottom">
                    <button class="mj-list-group-item mj-list-group-item-action mj-py-3 mj-d-flex mj-align-items-center" 
                            :class="{ 'active mj-bg-primary mj-border-primary': operation === 'change_ip' }" 
                            @click="operation = 'change_ip'; resetState()">
                        <i class="bi bi-input-cursor-text fs-4 mj-me-3"></i>
                        <div>
                            <div class="mj-fw-bold">Thay đổi IP hàng loạt</div>
                            <small class="opacity-75" :class="{ 'mj-text-white': operation === 'change_ip' }">Thay thế IP cũ bằng IP mới trên mọi domain</small>
                        </div>
                    </button>
                    <button class="mj-list-group-item mj-list-group-item-action mj-py-3 mj-d-flex mj-align-items-center" 
                            :class="{ 'active mj-bg-primary mj-border-primary': operation === 'apply_template' }" 
                            @click="operation = 'apply_template'; resetState()">
                        <i class="bi bi-file-earmark-code fs-4 mj-me-3"></i>
                        <div>
                            <div class="mj-fw-bold">Áp dụng Template hàng loạt</div>
                            <small class="opacity-75" :class="{ 'mj-text-white': operation === 'apply_template' }">Ghi đè DNS template lên các domain đã chọn</small>
                        </div>
                    </button>
                </div>
            </div>
        </div>

        <!-- Main Form Area -->
        <div class="mj-col-md-8 mj-mb-4">
            <div class="mj-card mj-shadow-sm mj-border-0 h-100">
                <div class="mj-card-header mj-bg-light mj-fw-bold mj-py-3">
                    <span x-show="operation === 'change_ip'"><i class="bi bi-input-cursor-text"></i> Cấu hình Thay đổi IP</span>
                    <span x-show="operation === 'apply_template'"><i class="bi bi-file-earmark-code"></i> Cấu hình Áp dụng Template</span>
                </div>
                <div class="mj-card-body mj-p-4">
                    
                    <!-- FORM: Change IP -->
                    <template x-if="operation === 'change_ip'">
                        <div class="mj-row mj-g-4 mj-mb-4">
                            <div class="mj-col-md-6">
                                <label class="form-label mj-fw-bold">IP Cũ (Sẽ bị thay thế)</label>
                                <input type="text" class="mj-form-control font-monospace" x-model="formIp.oldIp" placeholder="103.45.67.89">
                            </div>
                            <div class="mj-col-md-6">
                                <label class="form-label mj-fw-bold mj-text-success">IP Mới (Sẽ áp dụng)</label>
                                <input type="text" class="mj-form-control font-monospace mj-border-success" x-model="formIp.newIp" placeholder="103.45.67.100">
                            </div>
                        </div>
                    </template>

                    <!-- FORM: Apply Template -->
                    <template x-if="operation === 'apply_template'">
                        <div class="mj-mb-4">
                            <label class="form-label mj-fw-bold">Chọn Template DNS</label>
                            <select class="mj-form-select" x-model="formTemplate.templateId">
                                <option value="">-- Vui lòng chọn --</option>
                                <option value="1">Basic DNS (Chứa 6 bản ghi)</option>
                                <option value="2">Email Optimized (Chứa 12 bản ghi)</option>
                                <option value="3">Google Workspace (Chứa 10 bản ghi)</option>
                            </select>
                            <div class="form-text mj-text-danger mj-mt-2"><i class="bi bi-exclamation-triangle-fill"></i> Mọi bản ghi hiện tại của các domain (ngoại trừ record bị khóa) sẽ bị XÓA và thay bằng các bản ghi trong template.</div>
                        </div>
                    </template>

                    <h6 class="mj-border-bottom mj-pb-2 mj-mb-3 mj-mt-4 mj-text-primary">Phạm vi áp dụng (Scope)</h6>
                    
                    <div class="mj-mb-4">
                        <div class="form-check mj-mb-2">
                            <input class="form-check-input" type="radio" name="scopeRadio" id="scopeAll" value="all" x-model="scope">
                            <label class="form-check-label mj-fw-bold" for="scopeAll">Tất cả domain hệ thống quản lý</label>
                        </div>
                        <div class="form-check mj-mb-2">
                            <input class="form-check-input" type="radio" name="scopeRadio" id="scopeServer" value="server" x-model="scope">
                            <label class="form-check-label" for="scopeServer">Chỉ domain nằm trên Server cụ thể:</label>
                        </div>
                        <div class="mj-ms-4 mj-mb-3" x-show="scope === 'server'">
                            <select class="mj-form-select mj-form-select-sm w-50" x-model="scopeServerId">
                                <option value="1">dns1.hvn.vn (156 domains)</option>
                                <option value="2">dns2.hvn.vn (120 domains)</option>
                                <option value="3">dns3.hvn.vn (66 domains)</option>
                            </select>
                        </div>
                        <div class="form-check mj-mb-2">
                            <input class="form-check-input" type="radio" name="scopeRadio" id="scopeManual" value="manual" x-model="scope">
                            <label class="form-check-label" for="scopeManual">Chọn thủ công / Nhập thủ công</label>
                        </div>
                        <div class="mj-ms-4" x-show="scope === 'manual'">
                            <textarea class="mj-form-control mj-form-control-sm font-monospace" rows="3" placeholder="Nhập tên miền, mỗi dòng 1 domain..."></textarea>
                        </div>
                    </div>

                    <div class="mj-text-end">
                        <button class="mj-btn mj-btn-primary" @click="scanPreview()" :disabled="isScanning">
                            <span x-show="!isScanning"><i class="bi bi-search"></i> Quét & Báo trước kết quả</span>
                            <span x-show="isScanning"><span class="mj-spinner-border mj-spinner-border-sm"></span> Đang quét...</span>
                        </button>
                    </div>

                </div>
            </div>
        </div>
    </div>

    <!-- PREVIEW AREA -->
    <div class="mj-card mj-shadow mj-border-0 mj-mb-4" x-show="preview.scanned" x-collapse>
        <div class="mj-card-header mj-bg-dark mj-text-white mj-fw-bold mj-py-3"><i class="bi bi-eye"></i> Preview Kết quả Thao tác</div>
        <div class="mj-card-body mj-p-4 mj-bg-light">
            <template x-if="preview.domains.length === 0">
                <div class="mj-text-center mj-py-4 mj-text-muted">
                    <i class="bi bi-search display-4 mj-mb-3 mj-text-secondary opacity-50"></i>
                    <h5>Không có kết quả</h5>
                    <p>Không tìm thấy bản ghi/domain nào phù hợp với thông số bạn đã nhập.</p>
                </div>
            </template>

            <template x-if="preview.domains.length > 0">
                <div>
                    <div class="alert alert-success mj-border-success">
                        <h5 class="alert-heading"><i class="bi bi-check-circle-fill"></i> Sẵn sàng thực hiện</h5>
                        Tìm thấy <strong><span x-text="preview.totalRecords"></span> bản ghi</strong> trên <strong><span x-text="preview.domains.length"></span> domain</strong> bị ảnh hưởng bởi thay đổi này.
                    </div>

                    <div class="mj-list-group mj-mb-4" style="max-height: 300px; overflow-y: auto;">
                        <template x-for="(dom, idx) in preview.domains" :key="idx">
                            <label class="mj-list-group-item mj-d-flex mj-justify-content-between mj-align-items-center">
                                <div>
                                    <input class="form-check-input mj-me-2" type="checkbox" checked disabled>
                                    <span class="mj-fw-bold" x-text="dom.name"></span>
                                    <small class="mj-text-muted mj-ms-2" x-text="dom.summary"></small>
                                </div>
                            </label>
                        </template>
                    </div>

                    <div class="alert alert-warning mj-text-dark mj-border-warning small mj-ps-4 mj-pe-3 mj-py-2">
                        <i class="bi bi-shield-check mj-me-2"></i> Hệ thống sẽ tự tạo <strong><span x-text="preview.domains.length"></span> snapshot</strong> trước khi thực hiện để đảm bảo an toàn. Tùy thuộc vào số lượng, có thể mất vài phút.
                    </div>

                    <div class="mj-d-flex mj-justify-content-between mj-align-items-center">
                        <button class="mj-btn btn-outline-secondary" @click="resetState()">Hủy bỏ</button>
                        <button class="mj-btn mj-btn-danger mj-px-4" @click="executeBulk()" :disabled="isExecuting">
                            <span x-show="!isExecuting"><i class="bi bi-lightning-fill"></i> Thực hiện Thay đổi ngay!</span>
                            <span x-show="isExecuting"><span class="mj-spinner-border mj-spinner-border-sm"></span> Đang tiến hành...</span>
                        </button>
                    </div>

                    <!-- Progress Bar (shown when executing) -->
                    <div class="mj-mt-4" x-show="isExecuting || isDone">
                        <div class="mj-d-flex mj-justify-content-between small mj-mb-1 mj-fw-bold">
                            <span>Tiến trình: <span x-text="progress.done"></span>/<span x-text="preview.domains.length"></span> domain</span>
                            <span x-text="Math.round((progress.done / preview.domains.length) * 100) + '%'"></span>
                        </div>
                        <div class="mj-progress mj-mb-2" style="height: 15px;">
                            <div class="mj-progress-bar mj-progress-bar-striped mj-progress-bar-animated mj-bg-success" role="progressbar" :style="`width: ${ (progress.done / preview.domains.length) * 100 }%`"></div>
                        </div>
                        <div class="mj-d-flex small mj-text-muted mj-justify-content-between">
                            <div>
                                <span class="mj-badge mj-bg-success mj-me-1">✅ <span x-text="progress.success"></span> thành công</span>
                                <span class="mj-badge mj-bg-warning mj-text-dark mj-me-1">⟳ <span x-text="progress.working"></span> đang xử lý</span>
                                <span class="mj-badge mj-bg-danger">❌ <span x-text="progress.fails"></span> lỗi</span>
                            </div>
                            <!-- Stop feature demo only -->
                            <button class="mj-btn btn-sm btn-outline-danger mj-py-0 mj-border-0" x-show="isExecuting">Dừng lại</button>
                        </div>
                    </div>

                </div>
            </template>
        </div>
    </div>
</div>

{* JS logic moved to assets/js/mj-dns.js (MJ standard §8) *}
