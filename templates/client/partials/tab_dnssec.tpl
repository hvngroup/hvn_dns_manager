{* tab_dnssec.tpl — DNSSEC management (luôn mở cho user) *}

<div class="card border-primary">
    <div class="card-header bg-primary text-white d-flex justify-content-between align-items-center">
        <h5 class="mb-0"><i class="bi bi-shield-lock"></i> DNSSEC &mdash; Bảo mật phân giải tên miền</h5>
        {if $domain.dnssec_enabled}
            <span class="badge bg-success border border-light">Trạng thái: Bật</span>
        {else}
            <span class="badge bg-secondary border border-light">Trạng thái: Tắt</span>
        {/if}
    </div>
    
    <div class="card-body">
        {if $domain.dnssec_enabled}
            {* ── DNSSEC ĐANG BẬT ── *}
            <div class="d-flex justify-content-between align-items-center mb-4">
                <div>
                    <strong>Ký Zone lần cuối:</strong> {$domain.dnssec.last_signed|default:'Vừa xong'}<br>
                    <span class="text-success"><i class="bi bi-shield-check"></i> Hệ thống đang bảo vệ tên miền này.</span>
                </div>
                <button class="btn btn-outline-danger" onclick="if(confirm('Bạn có chắc chắn muốn TẮT DNSSEC?')) alert('Mô phỏng tắt DNSSEC thành công')">
                    <i class="bi bi-shield-x"></i> Tắt DNSSEC
                </button>
            </div>

            <h5 class="border-bottom pb-2 mb-3">Thông số DS Record</h5>
            <div class="alert alert-info">
                <i class="bi bi-info-circle"></i> Sao chép thông tin bên dưới và nhập vào trang quản lý tên miền tại nhà đăng ký (VD: VNNIC, GoDaddy, Namecheap...)
            </div>

            <div class="table-responsive mb-3">
                <table class="table table-bordered bg-light">
                    <tbody>
                        <tr>
                            <td class="fw-bold" style="width: 200px;">Key Tag</td>
                            <td class="font-monospace d-flex justify-content-between">
                                <span id="ds-keytag">12345</span>
                                <a href="javascript:void(0)" onclick="hvnCopyDnssec('ds-keytag')">Copy</a>
                            </td>
                        </tr>
                        <tr>
                            <td class="fw-bold">Algorithm</td>
                            <td class="font-monospace d-flex justify-content-between">
                                <span id="ds-algo">13 (ECDSA P-256)</span>
                                <a href="javascript:void(0)" onclick="hvnCopyDnssec('ds-algo')">Copy</a>
                            </td>
                        </tr>
                        <tr>
                            <td class="fw-bold">Digest Type</td>
                            <td class="font-monospace d-flex justify-content-between">
                                <span id="ds-dtype">2 (SHA-256)</span>
                                <a href="javascript:void(0)" onclick="hvnCopyDnssec('ds-dtype')">Copy</a>
                            </td>
                        </tr>
                        <tr>
                            <td class="fw-bold">Digest</td>
                            <td class="font-monospace d-flex justify-content-between">
                                <span id="ds-digest">49FD46E6C4B45C55D4AC99182315ADF13E2A8B6072BFF1C57EA35B03E10D9B58</span>
                                <a href="javascript:void(0)" onclick="hvnCopyDnssec('ds-digest')">Copy</a>
                            </td>
                        </tr>
                        <tr class="table-secondary">
                            <td class="fw-bold">DS Record (Full)</td>
                            <td class="font-monospace d-flex justify-content-between">
                                <span id="ds-full">{$domain.domain}. IN DS 12345 13 2 49FD46E6C4B45C55D4AC...</span>
                                <a href="javascript:void(0)" onclick="hvnCopyDnssec('ds-full')">Copy</a>
                            </td>
                        </tr>
                    </tbody>
                </table>
            </div>
            
            <button class="btn btn-secondary btn-sm mb-4" onclick="hvnCopyAllDnssec()"><i class="bi bi-clipboard"></i> Copy tất cả</button>
            
            <div class="card bg-light border-warning">
                <div class="card-body">
                    <h6 class="text-warning-emphasis"><i class="bi bi-exclamation-triangle-fill text-warning"></i> LƯU Ý QUAN TRỌNG:</h6>
                    <p class="mb-0">Nếu muốn <strong>TẮT DNSSEC</strong>, hãy làm theo đúng thứ tự: Xóa bản ghi DS tại nhà đăng ký trước &rarr; Chờ 24 giờ cho cache DNS toàn cầu cập nhật &rarr; Mới quay lại trang này bấm "Tắt DNSSEC". Nếu làm ngược lại có thể gây lỗi truy cập tên miền.</p>
                </div>
            </div>

        {else}
            {* ── DNSSEC CHƯA BẬT ── *}
            <div class="text-center py-4">
                <i class="bi bi-shield-plus text-primary" style="font-size: 4rem;"></i>
                <h5 class="mt-3 mb-3">DNSSEC chưa được kích hoạt</h5>
                <p class="text-muted w-75 mx-auto mb-4">DNSSEC bảo vệ tên miền của bạn khỏi tấn công giả mạo máy chủ DNS (DNS Spoofing) bằng cách ký số điện tử vào các bản ghi. Khuyến nghị bật cho mọi tên miền quan trọng.</p>
                
                <button class="btn btn-success btn-lg px-4" onclick="alert('Mô phỏng: Đang tạo cặp khóa DNSSEC...')">
                    <i class="bi bi-shield-plus"></i> Bật DNSSEC
                </button>
                
                <p class="small text-muted mt-3">Sau khi bật, hệ thống sẽ tạo khóa bảo mật. Bạn cần mang thông số DS Record tới nhà đăng ký tên miền để hoàn tất.</p>
            </div>
        {/if}
    </div>
</div>

{literal}
<script>
function hvnCopyDnssec(elementId) {
    var text = document.getElementById(elementId).innerText.trim();
    navigator.clipboard.writeText(text).then(function() {
        showToast('Đã copy', 'Dữ liệu đã được lưu vào khay nhớ tạm.', 'success');
    });
}
function hvnCopyAllDnssec() {
    var fields = ['ds-keytag', 'ds-algo', 'ds-dtype', 'ds-digest', 'ds-full'];
    var all = fields.map(function(id) {
        var el = document.getElementById(id);
        return el ? el.innerText.trim() : '';
    }).join('\n');
    navigator.clipboard.writeText(all).then(function() {
        showToast('Đã copy tất cả', 'Toàn bộ DS Record đã lưu vào khay nhớ tạm.', 'success');
    });
}
</script>
{/literal}
