{* tab_ddns.tpl — Dynamic DNS management (luôn mở cho user) *}
{literal}
<div x-data="{
    tokens: [
        { id: 1, subdomain: 'cam', label: 'Camera VP Hà Nội', ip: '118.70.5.6', updated: '2 giờ trước', requests: 1248, active: true, showDetail: false, token_url: 'https://whmcs.hvn.vn/modules/addons/hvn_dns_manager/ddns.php?token=a1b2c3d4e5f6g7h8' },
        { id: 2, subdomain: 'vpn', label: 'Router Mikrotik VP HCM', ip: '113.22.1.3', updated: '15 phút trước', requests: 5620, active: true, showDetail: false, token_url: 'https://whmcs.hvn.vn/modules/addons/hvn_dns_manager/ddns.php?token=x9y8z7w6v5u4t3s2' },
        { id: 3, subdomain: 'nas', label: 'Synology NAS Nhà riêng', ip: '14.186.92.40', updated: '1 ngày trước', requests: 312, active: false, showDetail: false, token_url: 'https://whmcs.hvn.vn/modules/addons/hvn_dns_manager/ddns.php?token=m1n2o3p4q5r6s7t8' }
    ],
    showCreateForm: false,
    newToken: { subdomain: '', label: '' },

    toggleDetail(id) {
        this.tokens = this.tokens.map(function(t) {
            if (t.id === id) t.showDetail = !t.showDetail;
            return t;
        });
    },

    toggleActive(id) {
        this.tokens = this.tokens.map(function(t) {
            if (t.id === id) t.active = !t.active;
            return t;
        });
        var token = this.tokens.find(function(t) { return t.id === id; });
        showToast(token.active ? 'Đã bật' : 'Đã tắt', 'Token ' + token.subdomain + ' đã ' + (token.active ? 'kích hoạt' : 'vô hiệu hóa'), token.active ? 'success' : 'warning');
    },

    deleteToken(id) {
        var token = this.tokens.find(function(t) { return t.id === id; });
        if (confirm('Xóa DDNS token cho ' + token.subdomain + '? Thiết bị sẽ không thể cập nhật IP nữa.')) {
            this.tokens = this.tokens.filter(function(t) { return t.id !== id; });
            showToast('Đã xóa', 'Token ' + token.subdomain + ' đã bị xóa', 'danger');
        }
    },

    createToken() {
        if (!this.newToken.subdomain.trim()) {
            alert('Vui lòng nhập subdomain');
            return;
        }
        var newId = Date.now();
        this.tokens.push({
            id: newId,
            subdomain: this.newToken.subdomain,
            label: this.newToken.label || 'Token mới',
            ip: 'Chưa cập nhật',
            updated: 'Vừa tạo',
            requests: 0,
            active: true,
            showDetail: true,
            token_url: 'https://whmcs.hvn.vn/modules/addons/hvn_dns_manager/ddns.php?token=' + Math.random().toString(36).substring(2, 18)
        });
        this.newToken = { subdomain: '', label: '' };
        this.showCreateForm = false;
        showToast('Thành công', 'DDNS Token đã được tạo', 'success');
    },

    copyUrl(tokenId) {
        var token = this.tokens.find(function(t) { return t.id === tokenId; });
        if (token) {
            navigator.clipboard.writeText(token.token_url).then(function() {
                showToast('Đã copy', 'URL đã được lưu vào khay nhớ tạm', 'success');
            });
        }
    },

    copyMikrotik(tokenId) {
        var token = this.tokens.find(function(t) { return t.id === tokenId; });
        if (token) {
            var script = '/tool fetch url="' + token.token_url + '" mode=http';
            navigator.clipboard.writeText(script).then(function() {
                showToast('Đã copy', 'Script Mikrotik đã được lưu vào khay nhớ tạm', 'success');
            });
        }
    }
}">
{/literal}

    {* ── Header ── *}
    <div class="d-flex justify-content-between align-items-center mb-3">
        <div>
            <h5 class="mb-0"><i class="bi bi-router"></i> Dynamic DNS (DDNS)</h5>
            <small class="text-muted">Tự động cập nhật IP động cho thiết bị mạng (Camera, Router, NAS,...)</small>
        </div>
        <button class="btn btn-primary btn-sm" x-on:click="showCreateForm = !showCreateForm">
            <i class="bi bi-plus-lg"></i> Tạo DDNS Token
        </button>
    </div>

    {* ── Hướng dẫn nhanh ── *}
    <div class="alert alert-info py-2 mb-3">
        <i class="bi bi-info-circle"></i>
        <strong>Cách dùng:</strong> Tạo Token → Copy URL API → Dán vào cấu hình DDNS của Router/Camera. Mỗi khi IP thay đổi, thiết bị tự động gọi URL để cập nhật bản ghi DNS.
    </div>

    {* ── Form tạo Token mới ── *}
{literal}
    <div x-show="showCreateForm" x-cloak class="card border-primary mb-4">
        <div class="card-header bg-primary text-white py-2">
            <strong><i class="bi bi-plus-circle"></i> Tạo DDNS Token mới</strong>
        </div>
        <div class="card-body">
            <div class="row">
                <div class="col-md-4 mb-2">
                    <label class="form-label small fw-bold">Subdomain <span class="text-danger">*</span></label>
                    <div class="input-group input-group-sm">
                        <input type="text" class="form-control font-monospace" placeholder="camera1" x-model="newToken.subdomain">
{/literal}
                        <span class="input-group-text">.{$domain.domain}</span>
{literal}
                    </div>
                </div>
                <div class="col-md-5 mb-2">
                    <label class="form-label small fw-bold">Nhãn ghi chú</label>
                    <input type="text" class="form-control form-control-sm" placeholder="VD: Camera tầng 3, Router chi nhánh..." x-model="newToken.label">
                </div>
                <div class="col-md-3 mb-2 d-flex align-items-end gap-2">
                    <button class="btn btn-primary btn-sm" x-on:click="createToken()"><i class="bi bi-check-lg"></i> Tạo</button>
                    <button class="btn btn-outline-secondary btn-sm" x-on:click="showCreateForm = false">Hủy</button>
                </div>
            </div>
        </div>
    </div>
{/literal}

    {* ── Bảng danh sách Token ── *}
{literal}
    <div class="table-responsive mb-3">
        <table class="table table-hover align-middle border">
            <thead class="table-light">
                <tr>
                    <th>Subdomain</th>
                    <th>Nhãn</th>
                    <th>IP hiện tại</th>
                    <th>Cập nhật lần cuối</th>
                    <th>Số lần gọi</th>
                    <th>Trạng thái</th>
                    <th class="text-end">Hành động</th>
                </tr>
            </thead>
            <tbody>
                <template x-for="token in tokens" x-bind:key="token.id">
                    <tr>
                        <td>
                            <span class="font-monospace fw-bold text-primary" x-text="token.subdomain"></span>
{/literal}
                            <span class="font-monospace text-muted">.{$domain.domain}</span>
{literal}
                        </td>
                        <td x-text="token.label"></td>
                        <td class="font-monospace" x-text="token.ip"></td>
                        <td class="text-muted small" x-text="token.updated"></td>
                        <td>
                            <span class="badge bg-light text-dark" x-text="token.requests.toLocaleString()"></span>
                        </td>
                        <td>
                            <template x-if="token.active">
                                <span class="badge bg-success"><i class="bi bi-check-circle"></i> Hoạt động</span>
                            </template>
                            <template x-if="!token.active">
                                <span class="badge bg-secondary"><i class="bi bi-pause-circle"></i> Tạm dừng</span>
                            </template>
                        </td>
                        <td class="text-end">
                            <div class="btn-group btn-group-sm">
                                <button class="btn btn-outline-primary" x-on:click="toggleDetail(token.id)" title="Chi tiết cấu hình">
                                    <i class="bi bi-gear"></i>
                                </button>
                                <button class="btn btn-outline-warning" x-on:click="toggleActive(token.id)" x-bind:title="token.active ? 'Tạm dừng' : 'Kích hoạt'">
                                    <i class="bi" x-bind:class="token.active ? 'bi-pause-fill' : 'bi-play-fill'"></i>
                                </button>
                                <button class="btn btn-outline-danger" x-on:click="deleteToken(token.id)" title="Xóa">
                                    <i class="bi bi-trash"></i>
                                </button>
                            </div>
                        </td>
                    </tr>
                </template>
            </tbody>
        </table>
    </div>
{/literal}

    {* ── Chi tiết Token (expandable) ── *}
{literal}
    <template x-for="token in tokens.filter(function(t){ return t.showDetail; })" x-bind:key="'detail-' + token.id">
        <div class="card border-info mb-3">
            <div class="card-header bg-info bg-opacity-10 d-flex justify-content-between align-items-center py-2">
                <strong>
                    <i class="bi bi-key"></i> Cấu hình cho:
                    <span class="font-monospace text-primary" x-text="token.subdomain"></span>
{/literal}
                    <span class="font-monospace text-muted">.{$domain.domain}</span>
{literal}
                </strong>
                <button class="btn btn-sm btn-outline-secondary" x-on:click="toggleDetail(token.id)"><i class="bi bi-x-lg"></i></button>
            </div>
            <div class="card-body">

                <div class="mb-4">
                    <label class="small fw-bold mb-1"><i class="bi bi-link-45deg"></i> URL cập nhật (API Endpoint):</label>
                    <div class="input-group input-group-sm">
                        <input type="text" class="form-control font-monospace bg-light" x-bind:value="token.token_url" readonly>
                        <button class="btn btn-outline-primary" x-on:click="copyUrl(token.id)"><i class="bi bi-clipboard"></i> Copy</button>
                    </div>
                    <div class="form-text">Gọi GET hoặc POST tới URL trên để cập nhật IP. IP nguồn sẽ được tự phát hiện.</div>
                </div>

                <div class="row">
                    <div class="col-md-6 mb-3">
                        <label class="small fw-bold"><i class="bi bi-terminal"></i> Script Mikrotik RouterOS:</label>
                        <div class="bg-dark text-light rounded p-2 font-monospace small" style="white-space: pre-wrap;" x-text="'/tool fetch url=&quot;' + token.token_url + '&quot; mode=http'"></div>
                        <button class="btn btn-link btn-sm p-0 mt-1" x-on:click="copyMikrotik(token.id)"><i class="bi bi-clipboard"></i> Copy script</button>
                    </div>
                    <div class="col-md-6 mb-3">
                        <label class="small fw-bold"><i class="bi bi-hdd-rack"></i> Cấu hình DrayTek / Modem PPPoE:</label>
                        <ul class="small mt-1 text-muted list-unstyled mb-0">
                            <li><strong>Provider:</strong> Custom / Custom API</li>
                            <li><strong>Server:</strong> whmcs.hvn.vn</li>
                            <li><strong>Path:</strong> <span class="font-monospace" x-text="token.token_url.replace('https://whmcs.hvn.vn', '')"></span></li>
                            <li><strong>Method:</strong> GET</li>
                        </ul>
                    </div>
                </div>

                <div class="row border-top pt-3 mt-2">
                    <div class="col-md-6">
                        <label class="small fw-bold"><i class="bi bi-hdd-network"></i> Cấu hình Camera IP (Hikvision/Dahua):</label>
                        <ul class="small mt-1 text-muted list-unstyled mb-0">
                            <li><strong>DDNS Type:</strong> Custom / NO-IP Compatible</li>
                            <li><strong>Server:</strong> whmcs.hvn.vn</li>
                            <li><strong>Domain:</strong> <span class="font-monospace" x-text="token.subdomain"></span>.{$domain.domain}</li>
                            <li><strong>Interval:</strong> 5 phút</li>
                        </ul>
                    </div>
                    <div class="col-md-6">
                        <label class="small fw-bold"><i class="bi bi-code-slash"></i> cURL (Linux/macOS):</label>
                        <div class="bg-dark text-light rounded p-2 font-monospace small mt-1" style="white-space: pre-wrap;" x-text="'curl -s &quot;' + token.token_url + '&quot;'"></div>
                    </div>
                </div>

                <div class="d-flex justify-content-end mt-3 pt-2 border-top gap-2">
                    <button class="btn btn-sm btn-outline-warning" x-on:click="showToast('Đã tạo lại', 'Token mới đã được sinh. Cần cập nhật lại URL trên thiết bị.', 'warning')">
                        <i class="bi bi-arrow-repeat"></i> Tạo lại Token
                    </button>
                </div>
            </div>
        </div>
    </template>
{/literal}

    {* ── Quota ── *}
{literal}
    <div class="d-flex justify-content-between align-items-center mt-3">
        <div class="text-muted small">
            <i class="bi bi-bar-chart-fill"></i> Đang dùng: <strong x-text="tokens.length"></strong> / {/literal}{$quota.max_ddns_tokens|default:5}{literal} Token DDNS
        </div>
        <div class="text-muted small">
            <i class="bi bi-clock-history"></i> TTL tự động: <strong>300s (5 phút)</strong> cho bản ghi DDNS
        </div>
    </div>
{/literal}

</div>
