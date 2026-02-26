<div class="hvn-dns-admin hvn-audit-detail" x-data="auditDetail()">
    <div class="hvn-d-flex hvn-justify-content-between hvn-align-items-center hvn-mb-4">
        <h2>
            <a href="{$modulelink}&action=audit_trail" class="text-decoration-none hvn-text-muted hvn-me-2"><i class="bi bi-arrow-left"></i></a>
            <i class="bi bi-shield-lock"></i> Audit Entry #<span x-text="log.id"></span>
        </h2>
    </div>

    <div class="hvn-card hvn-shadow-sm hvn-border-0" x-show="log">
        <div class="hvn-card-body hvn-p-4 font-monospace" style="font-size: 0.9rem;">
            
            <table class="table table-sm table-borderless">
                <tbody>
                    <tr>
                        <td class="hvn-text-muted" width="150">Actor:</td>
                        <td class="hvn-fw-bold fs-5 hvn-text-primary" x-text="log.actorFull"></td>
                    </tr>
                    <tr>
                        <td class="hvn-text-muted">Context:</td>
                        <td x-text="log.context"></td>
                    </tr>
                    <tr>
                        <td class="hvn-text-muted">Domain:</td>
                        <td class="hvn-fw-bold" x-text="log.domain"></td>
                    </tr>
                    <tr>
                        <td class="hvn-text-muted">Action:</td>
                        <td class="hvn-fw-bold hvn-bg-warning-subtle d-inline-block hvn-px-2 hvn-rounded hvn-text-dark" x-text="log.action"></td>
                    </tr>
                    <tr>
                        <td class="hvn-text-muted hvn-pt-3">Target:</td>
                        <td class="hvn-pt-3" x-text="log.target"></td>
                    </tr>
                </tbody>
            </table>

            <div class="hvn-card hvn-border-0 hvn-shadow-sm my-4">
                <div class="hvn-card-header hvn-bg-light"><strong>Payload Dữ liệu</strong></div>
                <div class="hvn-card-body hvn-p-0">
                    <table class="table table-bordered hvn-mb-0">
                        <thead class="table-light">
                            <tr>
                                <th width="50%" class="hvn-text-danger">Giá trị cũ (Old Data)</th>
                                <th width="50%" class="hvn-text-success">Giá trị mới (New Data)</th>
                            </tr>
                        </thead>
                        <tbody>
                            <tr>
                                <td class="hvn-p-3 text-break hvn-bg-danger-subtle bg-opacity-10 hvn-text-danger" style="white-space: pre-wrap;" x-text="log.oldVal"></td>
                                <td class="hvn-p-3 text-break hvn-bg-success-subtle bg-opacity-10 hvn-text-success hvn-fw-bold" style="white-space: pre-wrap;" x-text="log.newVal"></td>
                            </tr>
                        </tbody>
                    </table>
                </div>
            </div>

            <table class="table table-sm table-borderless hvn-mt-3 hvn-text-muted">
                <tbody>
                    <tr>
                        <td width="150">IP Address:</td>
                        <td x-text="log.ip"></td>
                    </tr>
                    <tr>
                        <td>User Agent:</td>
                        <td class="text-break" x-text="log.ua"></td>
                    </tr>
                    <tr>
                        <td>Session / Token:</td>
                        <td x-text="log.session"></td>
                    </tr>
                    <tr>
                        <td>Ghi chú (Notes):</td>
                        <td class="fst-italic hvn-text-dark" x-text="log.notes"></td>
                    </tr>
                    <tr>
                        <td>Timestamp:</td>
                        <td class="hvn-fw-bold hvn-text-dark" x-text="log.timeLong"></td>
                    </tr>
                </tbody>
            </table>

            <div class="hvn-d-flex hvn-justify-content-end hvn-pt-3 hvn-border-top hvn-mt-4">
                <a href="{$modulelink}&action=audit_trail" class="hvn-btn hvn-btn-secondary">Quay lại</a>
            </div>
        </div>
    </div>
</div>

<script>
{literal}
document.addEventListener('alpine:init', () => {
    Alpine.data('auditDetail', () => ({
        log: {
            id: '', time: '', actorType: '', actorName: '', domain: '', 
            action: '', details_brief: '', ip: '',
            actorFull: '', context: '', target: '',
            oldVal: '', newVal: '',
            ua: '', session: '',
            notes: '', timeLong: ''
        },

        init() {
            const urlParams = new URLSearchParams(window.location.search);
            const id = urlParams.get('id') || '89201';
            
            // Mock load log by ID
            this.log = {
                id: id, time: '25/02, 14:32', actorType: 'client', actorName: 'Lê C', domain: 'myblog.net', 
                action: 'delete_record', details_brief: 'A @ → 1.2.3.4', ip: '118.70.xx.xx',
                actorFull: 'Lê C - Client #1236', context: 'client_area', target: 'Record #457 (A @)',
                oldVal: '{\n  "name": "@",\n  "type": "A",\n  "value": "1.2.3.4",\n  "ttl": 3600\n}', newVal: 'null',
                ua: 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/120.0', session: 'whmcs_sess_xyz987',
                notes: 'User initiated delete from Client Area.', timeLong: '25/02/2026 14:32:05'
            };
        }
    }));
});
{/literal}
</script>
