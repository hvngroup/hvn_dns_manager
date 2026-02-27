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
            const id = parseInt(urlParams.get('id')) || 89201;

            // Mock dataset — khớp với audit_trail.tpl allLogs
            const mockDb = {
                89201: {
                    id: 89201, time: '27/02, 14:32', actorType: 'client', actorName: 'Lê Công', domain: 'myblog.net',
                    action: 'delete_record', details_brief: 'A @ → 1.2.3.4 [xóa]', ip: '118.70.1.10',
                    actorFull: 'Lê Công - Client #1236', context: 'client_area', target: 'Record #457 (A @)',
                    oldVal: '{\n  "name": "@",\n  "type": "A",\n  "value": "1.2.3.4",\n  "ttl": 3600\n}',
                    newVal: '[Đã xóa — record không còn tồn tại]',
                    ua: 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/120.0',
                    session: 'whmcs_sess_xyz987',
                    notes: 'User initiated delete from Client Area.', timeLong: '27/02/2026 14:32:05'
                },
                89200: {
                    id: 89200, time: '27/02, 14:30', actorType: 'admin', actorName: 'Vuong', domain: 'example.com',
                    action: 'edit_record', details_brief: 'A mail: .90 → .91', ip: '10.0.0.1',
                    actorFull: 'Vuong Nguyen - Admin #2', context: 'admin_editor', target: 'Record #456 (A mail)',
                    oldVal: '{\n  "type": "A",\n  "name": "mail",\n  "value": "103.45.67.90",\n  "ttl": 3600\n}',
                    newVal: '{\n  "type": "A",\n  "name": "mail",\n  "value": "103.45.67.91",\n  "ttl": 3600\n}',
                    ua: 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)',
                    session: 'whmcs_sess_abc123',
                    notes: 'Overridden by Admin — cancelled client job', timeLong: '27/02/2026 14:30:22'
                },
                89199: {
                    id: 89199, time: '27/02, 14:28', actorType: 'system', actorName: 'Cron', domain: 'test.org',
                    action: 'enable_dnssec', details_brief: 'DNSSEC on', ip: 'WHMCS Server',
                    actorFull: 'System Automation — Cron Hook', context: 'cron_hook', target: 'Domain test.org / DNSSEC Setting',
                    oldVal: '{\n  "dnssec_enabled": false\n}',
                    newVal: '{\n  "dnssec_enabled": true,\n  "algorithm": 13,\n  "key_tag": 12345\n}',
                    ua: 'WHMCS/8.8.0 CLI', session: 'cron',
                    notes: 'Auto-enabled via hook AddonActivation', timeLong: '27/02/2026 14:28:00'
                },
                89198: {
                    id: 89198, time: '27/02, 14:25', actorType: 'api', actorName: 'DDNS', domain: 'cam.shop.vn',
                    action: 'ddns_update', details_brief: 'IP: .5 → .6', ip: '118.70.5.6',
                    actorFull: 'API Token — DDNS Client', context: 'api_endpoint', target: 'Record #992 (A cam)',
                    oldVal: '{\n  "type": "A",\n  "name": "cam",\n  "value": "118.70.5.5"\n}',
                    newVal: '{\n  "type": "A",\n  "name": "cam",\n  "value": "118.70.5.6"\n}',
                    ua: 'Mikrotik/6.49.10 Fetch', session: 'token_a1b2c3d...',
                    notes: 'DDNS IP automatically updated by router.', timeLong: '27/02/2026 14:25:32'
                },
                89197: {
                    id: 89197, time: '27/02, 14:22', actorType: 'client', actorName: 'Hà Minh', domain: 'techstore.io',
                    action: 'add_record', details_brief: 'MX 10 mail.ts.io.', ip: '203.0.113.5',
                    actorFull: 'Hà Minh - Client #2301', context: 'client_area', target: 'Record #993 (MX @)',
                    oldVal: '[Không có — record mới được tạo]',
                    newVal: '{\n  "type": "MX",\n  "name": "@",\n  "priority": 10,\n  "value": "mail.ts.io.",\n  "ttl": 14400\n}',
                    ua: 'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X)',
                    session: 'whmcs_sess_mno456',
                    notes: 'New MX record added via Client DNS Editor', timeLong: '27/02/2026 14:22:18'
                },
                89191: {
                    id: 89191, time: '27/02, 14:08', actorType: 'admin', actorName: 'Linh', domain: 'fintech-app.io',
                    action: 'rollback', details_brief: 'Rollback v3 → v2', ip: '10.0.0.2',
                    actorFull: 'Linh Tran - Admin #3', context: 'admin_panel', target: 'Zone Snapshot v3',
                    oldVal: '{\n  "snapshot_id": "snap_v3",\n  "records_count": 12,\n  "created_at": "2026-02-27 12:00"\n}',
                    newVal: '{\n  "restored_snapshot": "snap_v2",\n  "records_count": 10,\n  "restored_at": "2026-02-27 14:08"\n}',
                    ua: 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)',
                    session: 'whmcs_sess_admin003',
                    notes: 'Manual rollback triggered by Admin after failed deployment', timeLong: '27/02/2026 14:08:44'
                },
            };

            // Tìm log theo ID, fallback về 89201 nếu không có
            this.log = mockDb[id] ?? mockDb[89201];
        }
    }));
});
{/literal}
</script>
