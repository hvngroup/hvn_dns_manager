<div class="hvn-dns-admin hvn-snapshot-rollback" x-data="snapshotRollback()">
    <div class="hvn-d-flex hvn-justify-content-between hvn-align-items-center hvn-mb-4">
        <h2>
            <a href="?module=hvn_dns_manager&action=dns_editor&domain={$domain.domain|default:'example.com'}" class="text-decoration-none hvn-text-muted hvn-me-2"><i class="bi bi-arrow-left"></i></a>
            <i class="bi bi-skip-backward-fill"></i> Khôi phục Zone DNS — <span x-text="domainName"></span>
        </h2>
    </div>

    <div class="alert alert-warning hvn-border-warning border-2 hvn-border-start hvn-mb-4">
        <i class="bi bi-exclamation-triangle-fill"></i> <strong>Thao tác nguy hiểm:</strong> Quá trình khôi phục sẽ ghi đè toàn bộ bản ghi trên hệ thống hiện tại. Một Snapshot của trạng thái hiện tại sẽ tự động được tạo trước khi Rollback để đề phòng rủi ro.
    </div>

    <div class="hvn-card hvn-shadow-sm hvn-border-0">
        <div class="hvn-card-body hvn-p-4">
            <h5 class="hvn-mb-4">Chọn một bản sao lưu (Snapshot) để khôi phục trạng thái:</h5>
            
            <form @submit.prevent="confirmRollback">
                <div class="hvn-mb-4">
                    <template x-for="snap in snapshots" :key="snap.id">
                        <div class="form-check hvn-p-3 hvn-border hvn-rounded hvn-mb-2" :class="{ 'hvn-bg-light hvn-border-primary': selectedSnapshot == snap.id}">
                            <input class="form-check-input hvn-ms-1 hvn-mt-1" type="radio" name="snapshotId" :id="'snap_'+snap.id" :value="snap.id" x-model="selectedSnapshot">
                            <label class="form-check-label hvn-ms-3 d-block w-100" :for="'snap_'+snap.id">
                                <div class="hvn-d-flex hvn-justify-content-between hvn-align-items-center">
                                    <div>
                                        <strong class="fs-6" x-text="snap.date"></strong> &mdash; <span x-text="snap.type" class="hvn-text-muted"></span>
                                    </div>
                                    <span class="hvn-badge hvn-bg-secondary"><span x-text="snap.records"></span> records</span>
                                </div>
                            </label>
                        </div>
                    </template>
                </div>

                <div class="hvn-card border-info hvn-bg-light hvn-mb-4" x-show="selectedSnapshot">
                    <div class="hvn-card-header hvn-bg-info hvn-text-white hvn-py-2">
                        <strong><i class="bi bi-eye"></i> Preview Thay Đổi (So với hiện tại)</strong>
                    </div>
                    <div class="hvn-card-body hvn-py-3">
                        <div class="row text-center hvn-mb-3">
                            <div class="col"><span class="hvn-badge hvn-bg-success">🟢 Giữ nguyên: <span x-text="previewData.unchanged"></span></span></div>
                            <div class="col"><span class="hvn-badge hvn-bg-danger">🔴 Xóa đi: <span x-text="previewData.deleted"></span></span></div>
                            <div class="col"><span class="hvn-badge hvn-bg-warning text-dark">🟡 Thay đổi: <span x-text="previewData.changed"></span></span></div>
                            <div class="col"><span class="hvn-badge hvn-bg-primary">🔵 Thêm mới: <span x-text="previewData.added"></span></span></div>
                        </div>
                        <div class="hvn-bg-white hvn-p-3 hvn-border hvn-rounded font-monospace small hvn-shadow-sm">
                            <ul class="list-unstyled hvn-mb-0">
                                <template x-for="diff in previewData.diffs">
                                    <li :class="diff.class" x-html="diff.text"></li>
                                </template>
                            </ul>
                            <div x-show="previewData.diffs.length === 0" class="hvn-text-muted fst-italic hvn-text-center">
                                Không có thay đổi nào.
                            </div>
                        </div>
                    </div>
                </div>

                <div class="hvn-d-flex hvn-justify-content-end hvn-gap-2 hvn-pt-3 hvn-border-top">
                    <a href="?module=hvn_dns_manager&action=dns_editor&domain={$domain.domain|default:'example.com'}" class="hvn-btn hvn-btn-outline-secondary" :class="{ 'disabled': submitting }">Hủy</a>
                    <button type="submit" class="hvn-btn hvn-btn-danger" :disabled="!selectedSnapshot || submitting">
                        <span x-show="!submitting"><i class="bi bi-rewind hvn-me-1"></i> Xác nhận Rollback</span>
                        <span x-show="submitting"><span class="hvn-spinner-border hvn-spinner-border-sm" role="status"></span> Đang xử lý...</span>
                    </button>
                </div>
            </form>
        </div>
    </div>
</div>

<script>
{literal}
document.addEventListener('alpine:init', () => {
    Alpine.data('snapshotRollback', () => ({
        domainName: '{/literal}{$domain.domain|default:'example.com'}{literal}',
        snapshots: [
            { id: 101, date: '25/02/2026 02:00', type: 'Nightly backup', records: 15 },
            { id: 100, date: '24/02/2026 02:00', type: 'Nightly backup', records: 14 },
            { id: 99, date: '23/02/2026 15:30', type: 'Before template load', records: 12 }
        ],
        selectedSnapshot: 101,
        submitting: false,

        get previewData() {
            // Mock preview data based on selection
            if (this.selectedSnapshot == 101) {
                return {
                    unchanged: 13, deleted: 2, changed: 0, added: 0,
                    diffs: [
                        { class: 'hvn-text-danger', text: '[-] A &nbsp;&nbsp;&nbsp;test &nbsp;&rarr; 1.2.3.4' },
                        { class: 'hvn-text-danger', text: '[-] TXT _verify &rarr; google-site-verification=...' }
                    ]
                };
            }
            return { unchanged: 12, deleted: 0, changed: 0, added: 0, diffs: [] };
        },

        confirmRollback() {
            this.submitting = true;
            setTimeout(() => {
                alert('Đã tạo Job khôi phục. Dữ liệu đang đồng bộ xuống các Server DA.');
                window.location.href = '?module=hvn_dns_manager&action=dns_editor&domain=' + this.domainName;
            }, 1500);
        }
    }));
});
{/literal}
</script>
