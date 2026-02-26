<!-- Rollback Modal (Admin Only) -->
<div class="modal fade" id="rollbackModal" tabindex="-1" aria-hidden="true" x-data="{
    snapshots: [
        { id: 101, date: '25/02/2026 02:00', type: 'Nightly backup', records: 15 },
        { id: 100, date: '24/02/2026 02:00', type: 'Nightly backup', records: 14 },
        { id: 99, date: '23/02/2026 15:30', type: 'Before template load', records: 12 }
    ],
    selectedSnapshot: 101,
    submitting: false,

    closeModal() {
        bootstrap.Modal.getInstance(document.getElementById('rollbackModal')).hide();
    },

    confirmRollback() {
        this.submitting = true;
        setTimeout(() => {
            this.submitting = false;
            this.closeModal();
            alert('Đã tạo Job khôi phục. Dữ liệu đang đồng bộ xuống các Server DA.');
        }, 1500);
    }
}" @open-rollback-modal.window="new bootstrap.Modal(document.getElementById('rollbackModal')).show()">
    <div class="modal-dialog modal-lg">
        <div class="modal-content">
            <div class="modal-header bg-warning">
                <h5 class="modal-title text-dark"><i class="bi bi-skip-backward-fill"></i> Khôi phục Zone DNS — {$domain.domain}</h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
            </div>
            <div class="modal-body">
                <p>Chọn một bản sao lưu (Snapshot) để khôi phục trạng thái:</p>
                
                <div class="mb-4">
                    <template x-for="snap in snapshots" :key="snap.id">
                        <div class="form-check p-2 border rounded mb-2" :class="{ 'bg-light border-primary': selectedSnapshot == snap.id}">
                            <input class="form-check-input ms-1 mt-2" type="radio" name="snapshotId" :id="'snap_'+snap.id" :value="snap.id" x-model="selectedSnapshot">
                            <label class="form-check-label ms-2 d-block w-100" :for="'snap_'+snap.id">
                                <strong x-text="snap.date"></strong> &mdash; <span x-text="snap.type"></span>
                                <span class="badge bg-secondary ms-2"><span x-text="snap.records"></span> records</span>
                            </label>
                        </div>
                    </template>
                </div>

                <div class="card border-info bg-light">
                    <div class="card-header bg-info text-white py-2">
                        <strong><i class="bi bi-eye"></i> Preview Thay Đổi (So với hiện tại)</strong>
                    </div>
                    <div class="card-body py-2">
                        <div class="row text-center mb-2 mt-2">
                            <div class="col"><span class="badge bg-success">🟢 Giữ nguyên: 13</span></div>
                            <div class="col"><span class="badge bg-danger">🔴 Xóa đi: 2</span></div>
                            <div class="col"><span class="badge bg-warning text-dark">🟡 Thay đổi: 0</span></div>
                            <div class="col"><span class="badge bg-primary">🔵 Thêm mới: 0</span></div>
                        </div>
                        <ul class="list-unstyled mb-0 font-monospace small">
                            <li class="text-danger">[-] A &nbsp;&nbsp;&nbsp;test &nbsp;&rarr; 1.2.3.4</li>
                            <li class="text-danger">[-] TXT _verify &rarr; google-site-verification=...</li>
                        </ul>
                    </div>
                </div>
                
                <div class="alert alert-danger mt-3 mb-0">
                    <i class="bi bi-exclamation-triangle-fill"></i> <strong>Thao tác nguy hiểm:</strong> Quá trình khôi phục sẽ ghi đè toàn bộ bản ghi trên hệ thống hiện tại. Một Snapshot của trạng thái hiện tại sẽ tự động được tạo trước khi Rollback để đề phòng rủi ro.
                </div>
            </div>
            <div class="modal-footer">
                <button type="button" class="btn btn-outline-secondary" @click="closeModal()" :disabled="submitting">Hủy</button>
                <button type="button" class="btn btn-danger" @click="confirmRollback()" :disabled="submitting">
                    <span x-show="!submitting"><i class="bi bi-rewind"></i> Xác nhận Rollback</span>
                    <span x-show="submitting"><span class="spinner-border spinner-border-sm"></span> Đang xử lý...</span>
                </button>
            </div>
        </div>
    </div>
</div>
