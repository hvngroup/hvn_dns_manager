<div class="d-flex justify-content-between align-items-center mb-3">
    <div>
        <h5 class="mb-0">Dynamic DNS (DDNS)</h5>
        <small class="text-muted">Tự động cập nhật IP cho thiết bị mạng gắn với tên miền</small>
    </div>
    {if $quota.ddns_mode == 'free' || ($quota.ddns_mode == 'paid' && $domain.has_ddns_addon)}
        <button class="btn btn-primary btn-sm" onclick="alert('Đang mở Modal thêm Token')">
            <i class="bi bi-plus-lg"></i> Tạo DDNS Token
        </button>
    {/if}
</div>

{if $quota.ddns_mode == 'paid' && !$domain.has_ddns_addon}
    <!-- UPSELL DDNS -->
    <div class="card border-warning">
        <div class="card-body text-center py-5">
            <i class="bi bi-router text-warning" style="font-size: 4rem;"></i>
            <h4 class="mt-3">Tính năng Cao cấp: Dynamic DNS</h4>
            <p class="text-muted w-75 mx-auto">Giải pháp hoàn hảo để tự động cập nhật IP động cho tên miền, giúp bạn dễ dàng truy cập Camera, NAS, Server tại nhà từ ngoài Internet.</p>
            
            <ul class="list-unstyled text-start d-inline-block mx-auto mb-4 border p-3 rounded bg-light">
                <li><i class="bi bi-check-circle-fill text-success"></i> Không cần thuê đường truyền IP tĩnh đắt đỏ</li>
                <li><i class="bi bi-check-circle-fill text-success"></i> Hỗ trợ API chuẩn HTTP GET/POST tương thích với Mikrotik, Draytek</li>
                <li><i class="bi bi-check-circle-fill text-success"></i> Cập nhật tức thì với TTL siêu ngắn (5 phút)</li>
            </ul>
            
            <div class="mb-3">
                <span class="fs-5 text-primary fw-bold">Chỉ từ 15.000đ/tháng</span>
            </div>
            
            <a href="cart.php?action=domainoptions" class="btn btn-warning btn-lg px-4 rounded-pill shadow-sm">
                <i class="bi bi-cart-plus"></i> Nâng cấp Gói Dịch vụ
            </a>
            <a href="#" class="btn btn-link ms-2">Tìm hiểu thêm</a>
        </div>
    </div>
{else}
    <!-- DDNS IS ENABLED -->
    <div class="table-responsive mb-4">
        <table class="table table-hover align-middle border">
            <thead class="table-light">
                <tr>
                    <th>Subdomain</th>
                    <th>Nhãn ghi chú</th>
                    <th>IP hiện tại</th>
                    <th>Cập nhật lần cuối</th>
                    <th class="text-end">Hành động</th>
                </tr>
            </thead>
            <tbody>
                <tr>
                    <td class="font-monospace fw-bold text-primary">cam</td>
                    <td>Camera VP Hà Nội</td>
                    <td class="font-monospace">118.70.5.6</td>
                    <td class="text-muted small">2 giờ trước</td>
                    <td class="text-end">
                        <div class="btn-group btn-group-sm">
                            <button class="btn btn-outline-primary" onclick="toggleDetails('ddns-1')"><i class="bi bi-gear"></i></button>
                            <button class="btn btn-outline-danger"><i class="bi bi-trash"></i></button>
                        </div>
                    </td>
                </tr>
                <tr id="ddns-1" style="display: none;" class="bg-light">
                    <td colspan="5" class="p-4">
                        <div class="card border-info">
                            <div class="card-body">
                                <h6>Token cho: <span class="font-monospace text-primary">cam.{$domain.domain}</span></h6>
                                <p class="small text-muted">Copy đường dẫn sau và đưa vào script cập nhật của thiết bị.</p>
                                
                                <label class="small fw-bold mb-1">URL cập nhật GET/POST (API):</label>
                                <div class="input-group input-group-sm mb-4">
                                    <input type="text" class="form-control font-monospace" value="https://whmcs.hvn.vn/modules/addons/hvn_dns_manager/ddns.php?token=a1b2c3d4e5f6g7h8" readonly id="api-url-1">
                                    <button class="btn btn-outline-secondary" onclick="copyText('api-url-1', true)"><i class="bi bi-clipboard"></i> Copy</button>
                                </div>

                                <div class="row">
                                    <div class="col-md-6 mb-3">
                                        <label class="small fw-bold">Script Mikrotik RouterOS:</label>
                                        <textarea class="form-control form-control-sm font-monospace bg-dark text-light" rows="3" readonly id="script-mk">/tool fetch url="https://whmcs.hvn.vn/modules/addons/hvn_dns_manager/ddns.php?token=a1b2c3d4e5f6g7h8" mode=http</textarea>
                                        <button class="btn btn-link btn-sm p-0 mt-1" onclick="copyText('script-mk', true)"><i class="bi bi-clipboard"></i> Copy script</button>
                                    </div>
                                    <div class="col-md-6 mb-3">
                                        <label class="small fw-bold">Cấu hình DrayTek/Modem PPPoE:</label>
                                        <ul class="small mt-1 text-muted list-unstyled">
                                            <li><strong>Provider:</strong> Custom / Custom API</li>
                                            <li><strong>Server:</strong> whmcs.hvn.vn</li>
                                            <li><strong>Path:</strong> /modules/addons/hvn_dns_manager/ddns.php?token=a1...</li>
                                        </ul>
                                    </div>
                                </div>
                                
                                <div class="text-end mt-2">
                                    <button class="btn btn-sm btn-outline-warning"><i class="bi bi-arrow-repeat"></i> Tạo lại mã Token</button>
                                </div>
                            </div>
                        </div>
                    </td>
                </tr>
                <tr>
                    <td class="font-monospace fw-bold text-primary">vpn</td>
                    <td>Router Mikrotik</td>
                    <td class="font-monospace">113.22.1.3</td>
                    <td class="text-muted small">15 phút trước</td>
                    <td class="text-end">
                        <div class="btn-group btn-group-sm">
                            <button class="btn btn-outline-primary" onclick="toggleDetails('ddns-2')"><i class="bi bi-gear"></i></button>
                            <button class="btn btn-outline-danger"><i class="bi bi-trash"></i></button>
                        </div>
                    </td>
                </tr>
            </tbody>
        </table>
    </div>
    
    <div class="alert alert-secondary py-2">
        <i class="bi bi-bar-chart-fill"></i> Đang dùng: <strong>2/{$quota.max_ddns_tokens|default:5}</strong> Token DDNS (Quota Plan)
    </div>
{/if}

<script>
function toggleDetails(id) {
    const row = document.getElementById(id);
    if(row.style.display === 'none') {
        row.style.display = 'table-row';
    } else {
        row.style.display = 'none';
    }
}

function copyText(elementId, isInput = false) {
    const el = document.getElementById(elementId);
    const text = isInput ? el.value : el.innerText;
    navigator.clipboard.writeText(text).then(() => {
        showToast('Đã copy', 'Dữ liệu đã được lưu vào khay nhớ tạm.', 'success');
    });
}
</script>
