<div class="card border-primary">
    <div class="card-header bg-primary text-white d-flex justify-content-between align-items-center">
        <h5 class="mb-0">DNSSEC &mdash; Bảo mật phân giải tên miền</h5>
        {if $domain.dnssec_enabled}
            <span class="badge bg-success border border-light">Trạng thái: Bật</span>
        {else}
            <span class="badge bg-secondary border border-light">Trạng thái: Tắt</span>
        {/if}
    </div>
    
    <div class="card-body">
        {if $domain.dnssec_enabled}
            <!-- DNSSEC IS ENABLED -->
            <div class="d-flex justify-content-between align-items-center mb-4">
                <div>
                    <strong>Ký Zone lần cuối:</strong> {$domain.dnssec.last_signed|default:'Vừa xong'}<br>
                    <span class="text-success"><i class="bi bi-shield-check"></i> Hệ thống đang bảo vệ tên miền này.</span>
                </div>
                <button class="btn btn-outline-danger" onclick="if(confirm('Bạn có chắc chắn muốn TẮT DNSSEC?')) alert('Mô phỏng tắt DNSSEC thành công')">
                    Tắt DNSSEC
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
                                <a href="javascript:void(0)" onclick="copyText('ds-keytag')">Copy</a>
                            </td>
                        </tr>
                        <tr>
                            <td class="fw-bold">Algorithm</td>
                            <td class="font-monospace d-flex justify-content-between">
                                <span id="ds-algo">13 (ECDSA P-256)</span>
                                <a href="javascript:void(0)" onclick="copyText('ds-algo')">Copy</a>
                            </td>
                        </tr>
                        <tr>
                            <td class="fw-bold">Digest Type</td>
                            <td class="font-monospace d-flex justify-content-between">
                                <span id="ds-dtype">2 (SHA-256)</span>
                                <a href="javascript:void(0)" onclick="copyText('ds-dtype')">Copy</a>
                            </td>
                        </tr>
                        <tr>
                            <td class="fw-bold">Digest</td>
                            <td class="font-monospace d-flex justify-content-between">
                                <span id="ds-digest">49FD46E6C4B45C55D4AC99182315ADF13...</span>
                                <a href="javascript:void(0)" onclick="copyText('ds-digest')">Copy</a>
                            </td>
                        </tr>
                        <tr class="table-secondary">
                            <td class="fw-bold">DS Record (Full)</td>
                            <td class="font-monospace d-flex justify-content-between">
                                <span id="ds-full">example.com. IN DS 12345 13 2 49FD46...</span>
                                <a href="javascript:void(0)" onclick="copyText('ds-full')">Copy</a>
                            </td>
                        </tr>
                    </tbody>
                </table>
            </div>
            
            <button class="btn btn-secondary btn-sm mb-4"><i class="bi bi-clipboard"></i> Copy tất cả</button>
            
            <div class="card bg-light border-warning">
                <div class="card-body">
                    <h6 class="text-warning-emphasis"><i class="bi bi-exclamation-triangle-fill text-warning"></i> LƯU Ý QUAN TRỌNG:</h6>
                    <p class="mb-0">Nếu muốn <strong>TẮT DNSSEC</strong>, hãy làm theo đúng thứ tự: Xóa bản ghi DS tại hệ thống của tên miền (Nhà Đăng Ký) trước -> Chờ 24 giờ cho cache cập nhật -> Mới quay lại trang này bấm "Tắt DNSSEC". Nếu làm ngược lại có thể gây lỗi truy cập tên miền.</p>
                </div>
            </div>

        {else}
            <!-- DNSSEC IS DISABLED -->
            {if $quota.dnssec_mode == 'paid' && !$domain.has_dnssec_addon}
                <!-- UPSELL DNSSEC -->
                <div class="text-center py-4">
                    <i class="bi bi-shield-lock text-warning" style="font-size: 4rem;"></i>
                    <h4 class="mt-3">Tính năng Cao cấp: DNSSEC Protection</h4>
                    <p class="text-muted w-75 mx-auto">Bảo vệ tên miền của bạn khỏi các cuộc tấn công DNS Spoofing và Cache Poisoning với công nghệ ký số DNSSEC tiêu chuẩn.</p>
                    
                    <ul class="list-unstyled text-start d-inline-block mx-auto mb-4 border p-3 rounded bg-light">
                        <li><i class="bi bi-check-circle-fill text-success"></i> Ngăn chặn giả mạo website &amp; đánh cắp dữ liệu</li>
                        <li><i class="bi bi-check-circle-fill text-success"></i> Tăng độ tin cậy với người dùng &amp; điểm tín nhiệm hòm thư</li>
                        <li><i class="bi bi-check-circle-fill text-success"></i> Tương thích hoàn hảo với mọi nhà đăng ký tên miền</li>
                    </ul>
                    
                    <div class="mb-3">
                        <span class="fs-5 text-primary fw-bold">Chỉ từ 25.000đ/tháng</span>
                    </div>
                    
                    <a href="cart.php?action=domainoptions" class="btn btn-warning btn-lg px-4 rounded-pill shadow-sm">
                        <i class="bi bi-cart-plus"></i> Nâng cấp Gói Dịch vụ
                    </a>
                    <a href="#" class="btn btn-link ms-2">Tìm hiểu thêm</a>
                </div>
            {else}
                <!-- CAN ENABLE DNSSEC -->
                <div class="text-center py-4">
                    <h5 class="mb-3">DNSSEC chưa được kích hoạt</h5>
                    <p class="text-muted w-75 mx-auto mb-4">DNSSEC bảo vệ tên miền của bạn khỏi tấn công giả mạo máy chủ DNS (DNS Spoofing) bằng cách ký số điện tử vào các bản ghi. Dành cho các khách hàng có yêu cầu cao về bảo mật.</p>
                    
                    <button class="btn btn-success btn-lg px-4" onclick="alert('Mô phỏng: Đang tạo cặp khóa DNSSEC...')">
                        <i class="bi bi-shield-plus"></i> Bật DNSSEC
                    </button>
                    
                    <p class="small text-muted mt-3">Sau khi bật, hệ thống sẽ tạo khóa bảo mật. Bạn cần mang thông số cấu hình tới Nhà đăng ký tên miền.</p>
                </div>
            {/if}
        {/if}
    </div>
</div>

<script>
function copyText(elementId) {
    const text = document.getElementById(elementId).innerText.trim();
    navigator.clipboard.writeText(text).then(() => {
        showToast('Đã copy', 'Dữ liệu đã được lưu vào khay nhớ tạm.', 'success');
    });
}
</script>
