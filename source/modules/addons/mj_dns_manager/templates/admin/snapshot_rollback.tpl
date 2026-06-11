<div class="mj-dns-admin mj-snapshot-rollback" x-data="snapshotRollback()">
    <div class="mj-d-flex mj-justify-content-between mj-align-items-center mj-mb-4">
        <h2>
            <a href="?module=mj_dns_manager&action=dns_editor&domain={$domain.domain|default:'example.com'}" class="text-decoration-none mj-text-muted mj-me-2"><i class="bi bi-arrow-left"></i></a>
            <i class="bi bi-skip-backward-fill"></i> Khôi phục Zone DNS — <span x-text="domainName"></span>
        </h2>
    </div>

    <div class="alert alert-warning mj-border-warning border-2 mj-border-start mj-mb-4">
        <i class="bi bi-exclamation-triangle-fill"></i> <strong>Thao tác nguy hiểm:</strong> Quá trình khôi phục sẽ ghi đè toàn bộ bản ghi trên hệ thống hiện tại. Một Snapshot của trạng thái hiện tại sẽ tự động được tạo trước khi Rollback để đề phòng rủi ro.
    </div>

    <div class="mj-card mj-shadow-sm mj-border-0">
        <div class="mj-card-body mj-p-4">
            <h5 class="mj-mb-4">Chọn một bản sao lưu (Snapshot) để khôi phục trạng thái:</h5>
            
            <form @submit.prevent="confirmRollback">
                <div class="mj-mb-4">
                    <template x-for="snap in snapshots" :key="snap.id">
                        <div class="form-check mj-p-3 mj-border mj-rounded mj-mb-2" :class="{ 'mj-bg-light mj-border-primary': selectedSnapshot == snap.id}">
                            <input class="form-check-input mj-ms-1 mj-mt-1" type="radio" name="snapshotId" :id="'snap_'+snap.id" :value="snap.id" x-model="selectedSnapshot">
                            <label class="form-check-label mj-ms-3 d-block w-100" :for="'snap_'+snap.id">
                                <div class="mj-d-flex mj-justify-content-between mj-align-items-center">
                                    <div>
                                        <strong class="fs-6" x-text="snap.date"></strong> &mdash; <span x-text="snap.type" class="mj-text-muted"></span>
                                    </div>
                                    <span class="mj-badge mj-bg-secondary"><span x-text="snap.records"></span> records</span>
                                </div>
                            </label>
                        </div>
                    </template>
                </div>

                <div class="mj-card border-info mj-bg-light mj-mb-4" x-show="selectedSnapshot">
                    <div class="mj-card-header mj-bg-info mj-text-white mj-py-2">
                        <strong><i class="bi bi-eye"></i> Preview Thay Đổi (So với hiện tại)</strong>
                    </div>
                    <div class="mj-card-body mj-py-3">
                        <div class="row text-center mj-mb-3">
                            <div class="col"><span class="mj-badge mj-bg-success">🟢 Giữ nguyên: <span x-text="previewData.unchanged"></span></span></div>
                            <div class="col"><span class="mj-badge mj-bg-danger">🔴 Xóa đi: <span x-text="previewData.deleted"></span></span></div>
                            <div class="col"><span class="mj-badge mj-bg-warning text-dark">🟡 Thay đổi: <span x-text="previewData.changed"></span></span></div>
                            <div class="col"><span class="mj-badge mj-bg-primary">🔵 Thêm mới: <span x-text="previewData.added"></span></span></div>
                        </div>
                        <div class="mj-bg-white mj-p-3 mj-border mj-rounded font-monospace small mj-shadow-sm">
                            <ul class="list-unstyled mj-mb-0">
                                <template x-for="diff in previewData.diffs">
                                    <li :class="diff.class" x-html="diff.text"></li>
                                </template>
                            </ul>
                            <div x-show="previewData.diffs.length === 0" class="mj-text-muted fst-italic mj-text-center">
                                Không có thay đổi nào.
                            </div>
                        </div>
                    </div>
                </div>

                <div class="mj-d-flex mj-justify-content-end mj-gap-2 mj-pt-3 mj-border-top">
                    <a href="?module=mj_dns_manager&action=dns_editor&domain={$domain.domain|default:'example.com'}" class="mj-btn mj-btn-outline-secondary" :class="{ 'disabled': submitting }">Hủy</a>
                    <button type="submit" class="mj-btn mj-btn-danger" :disabled="!selectedSnapshot || submitting">
                        <span x-show="!submitting"><i class="bi bi-rewind mj-me-1"></i> Xác nhận Rollback</span>
                        <span x-show="submitting"><span class="mj-spinner-border mj-spinner-border-sm" role="status"></span> Đang xử lý...</span>
                    </button>
                </div>
            </form>
        </div>
    </div>
</div>

<script>
    var MJDNS_SNAP_DOMAIN = '{$domain.domain|default:'example.com'|escape:'javascript'}';
</script>
{* JS logic moved to assets/js/mj-dns.js (MJ standard §8) *}
