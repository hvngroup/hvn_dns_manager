{* tab_ddns.tpl — Dynamic DNS management *}

{* ── Header ── *}
<div style="display:flex;justify-content:space-between;align-items:flex-start;margin-bottom:16px;gap:12px;flex-wrap:wrap;">
    <div>
        <h5 style="margin:0 0 4px;font-size:15px;font-weight:700;color:#1e293b;"><i class="bi bi-router"></i> Dynamic DNS (DDNS)</h5>
        <p style="margin:0;font-size:12px;color:#6c757d;">Tự động cập nhật IP động cho thiết bị mạng (Camera, Router, NAS,...)</p>
    </div>
    <button x-on:click="showCreateDdnsForm = !showCreateDdnsForm"
        style="height:34px;padding:0 14px;display:inline-flex;align-items:center;gap:6px;font-size:14px;font-weight:600;font-family:inherit;background:#ea4544;color:#fff;border:none;border-radius:6px;cursor:pointer;transition:all .18s;white-space:nowrap;box-shadow:0 2px 6px rgba(234,69,68,.25);flex-shrink:0;"
        onmouseover="this.style.background='#d32f2f';" onmouseout="this.style.background='#ea4544';">
        <i class="bi bi-plus-lg"></i> Tạo DDNS Token
    </button>
</div>

{* ── Hướng dẫn nhanh ── *}
<div style="background:#eff6ff;border:1px solid #bfdbfe;border-radius:8px;padding:10px 14px;margin-bottom:16px;font-size:14px;color:#1d4ed8;">
    <i class="bi bi-info-circle"></i>
    <strong>Cách dùng:</strong> Tạo Token → Copy URL API → Dán vào cấu hình DDNS của Router/Camera. Mỗi khi IP thay đổi, thiết bị tự động gọi URL để cập nhật bản ghi DNS.
</div>

{* ── Form tạo Token mới ── *}
{literal}
<div x-show="showCreateDdnsForm" x-cloak style="border:1.5px solid #ea4544;border-radius:8px;overflow:hidden;margin-bottom:16px;">
    <div style="padding:10px 14px;background:#ea4544;display:flex;align-items:center;gap:8px;">
        <strong style="font-size:14px;color:#fff;"><i class="bi bi-plus-circle"></i> Tạo DDNS Token mới</strong>
    </div>
    <div style="padding:16px;">
        <div style="display:flex;gap:12px;flex-wrap:wrap;align-items:flex-end;">
            <div style="flex:1;min-width:160px;">
                <label style="display:block;font-size:12px;font-weight:700;color:#5E636E;margin-bottom:4px;">Subdomain <span style="color:#dc2626;">*</span></label>
                <div style="display:flex;align-items:center;">
                    <input type="text" class="form-control form-control-sm" placeholder="camera1" x-model="newDdnsToken.subdomain"
                        style="height:31px;font-size:14px;border-radius:6px 0 0 6px;">
{/literal}
                    <span style="padding:0 8px;height:31px;display:inline-flex;align-items:center;background:#f8f9fa;border:1px solid #dee2e6;border-left:none;border-radius:0 6px 6px 0;font-size:12px;color:#6c757d;white-space:nowrap;">.{$domain.domain}</span>
{literal}
                </div>
            </div>
            <div style="flex:2;min-width:200px;">
                <label style="display:block;font-size:12px;font-weight:700;color:#5E636E;margin-bottom:4px;">Nhãn ghi chú</label>
                <input type="text" class="form-control form-control-sm" placeholder="VD: Camera tầng 3, Router chi nhánh..." x-model="newDdnsToken.label"
                    style="height:31px;font-size:14px;">
            </div>
            <div style="display:flex;gap:8px;align-items:flex-end;flex-shrink:0;">
                <button x-on:click="createDdnsToken()" x-bind:disabled="ddnsCreating"
                    style="height:31px;padding:0 14px;display:inline-flex;align-items:center;gap:6px;font-size:14px;font-weight:600;background:#ea4544;color:#fff;border:none;border-radius:6px;cursor:pointer;transition:all .18s;"
                    onmouseover="this.style.background='#d32f2f';" onmouseout="this.style.background='#ea4544';">
                    <span x-show="ddnsCreating" class="spinner-border spinner-border-sm" style="width:12px;height:12px;"></span>
                    <i x-show="!ddnsCreating" class="bi bi-check-lg"></i>
                    <span x-text="ddnsCreating ? 'Đang tạo...' : 'Tạo'"></span>
                </button>
                <button x-on:click="showCreateDdnsForm = false"
                    style="height:31px;padding:0 12px;font-size:14px;background:#fff;border:1px solid #dee2e6;border-radius:6px;color:#6c757d;cursor:pointer;transition:all .18s;"
                    onmouseover="this.style.borderColor='#adb5bd';" onmouseout="this.style.borderColor='#dee2e6';">Hủy</button>
            </div>
        </div>
    </div>
</div>
{/literal}

{* ── Banner raw token ── *}
{literal}
<div x-show="ddnsNewRawToken" x-cloak
     style="background:#fefce8;border:1px solid #fde047;border-left:4px solid #f59e0b;border-radius:8px;padding:14px;margin-bottom:16px;">
    <div style="display:flex;justify-content:space-between;align-items:flex-start;gap:12px;">
        <div>
            <strong style="font-size:14px;color:#92400e;"><i class="bi bi-exclamation-triangle-fill"></i> Lưu URL này ngay!</strong>
            <div style="font-size:12px;color:#78350f;margin-top:4px;">Token chỉ hiển thị <strong>1 lần duy nhất</strong>. Sau khi đóng thông báo này, bạn không thể xem lại.</div>
        </div>
        <button x-on:click="ddnsNewRawToken = null"
            style="width:28px;height:28px;padding:0;border:none;background:rgba(0,0,0,0.08);border-radius:6px;color:#6c757d;cursor:pointer;display:inline-flex;align-items:center;justify-content:center;font-size:14px;flex-shrink:0;">
            <i class="bi bi-x-lg"></i>
        </button>
    </div>
    <div style="display:flex;margin-top:10px;">
        <input type="text" class="form-control form-control-sm"
               x-bind:value="'/modules/addons/mj_dns_manager/ddns.php?token=' + ddnsNewRawToken" readonly
               style="height:31px;font-size:12px;font-family:monospace;background:#fff;border-radius:6px 0 0 6px;">
        <button x-on:click="navigator.clipboard.writeText('/modules/addons/mj_dns_manager/ddns.php?token=' + ddnsNewRawToken)"
            style="height:31px;padding:0 12px;font-size:14px;font-weight:600;background:#f59e0b;border:1px solid #f59e0b;border-radius:0 6px 6px 0;color:#fff;cursor:pointer;white-space:nowrap;">
            <i class="bi bi-clipboard"></i> Copy
        </button>
    </div>
</div>
{/literal}

{* ── Bảng danh sách Token ── *}
{literal}
<div style="overflow-x:auto;margin-bottom:12px;">
    <table style="width:100%;border-collapse:collapse;font-size:14px;font-family:'Inter',system-ui,-apple-system,sans-serif;">
        <thead>
            <tr style="background:#f8f9fa;">
                <th style="padding:10px 8px;font-size:13px;font-weight:600;color:#5E636E;border-bottom:1px solid #dee2e6;white-space:nowrap;">Subdomain</th>
                <th style="padding:10px 8px;font-size:13px;font-weight:600;color:#5E636E;border-bottom:1px solid #dee2e6;">Nhãn</th>
                <th style="padding:10px 8px;font-size:13px;font-weight:600;color:#5E636E;border-bottom:1px solid #dee2e6;white-space:nowrap;">IP hiện tại</th>
                <th style="padding:10px 8px;font-size:13px;font-weight:600;color:#5E636E;border-bottom:1px solid #dee2e6;white-space:nowrap;">Cập nhật lần cuối</th>
                <th style="padding:10px 8px;font-size:13px;font-weight:600;color:#5E636E;border-bottom:1px solid #dee2e6;white-space:nowrap;">Số lần gọi</th>
                <th style="padding:10px 8px;font-size:13px;font-weight:600;color:#5E636E;border-bottom:1px solid #dee2e6;white-space:nowrap;">Trạng thái</th>
                <th style="padding:10px 8px;font-size:13px;font-weight:600;color:#5E636E;border-bottom:1px solid #dee2e6;text-align:right;">Hành động</th>
            </tr>
        </thead>
        <tbody>
            <template x-for="token in ddnsTokens" x-bind:key="token.id">
                <tr style="border-bottom:1px solid #f1f5f9;">
                    <td style="padding:10px 8px;">
                        <span style="font-family:monospace;font-weight:700;color:#ea4544;" x-text="token.subdomain"></span>
{/literal}
                        <span style="font-family:monospace;color:#6c757d;font-size:12px;">.{$domain.domain}</span>
{literal}
                    </td>
                    <td style="padding:10px 8px;font-size:14px;color:#495057;" x-text="token.label"></td>
                    <td style="padding:10px 8px;font-family:monospace;font-size:14px;color:#1e293b;" x-text="token.ip"></td>
                    <td style="padding:10px 8px;font-size:12px;color:#6c757d;" x-text="token.updated"></td>
                    <td style="padding:10px 8px;">
                        <span style="display:inline-block;padding:2px 8px;border-radius:4px;font-size:12px;font-weight:600;background:#e2e8f0;color:#1e293b;" x-text="token.requests.toLocaleString()"></span>
                    </td>
                    <td style="padding:10px 8px;">
                        <template x-if="token.active">
                            <span style="display:inline-block;padding:3px 10px;border-radius:5px;font-size:12px;font-weight:700;color:#fff;background:#16a34a;">
                                <i class="bi bi-check-circle"></i> Hoạt động
                            </span>
                        </template>
                        <template x-if="!token.active">
                            <span style="display:inline-block;padding:3px 10px;border-radius:5px;font-size:12px;font-weight:700;color:#fff;background:#475569;">
                                <i class="bi bi-pause-circle"></i> Tạm dừng
                            </span>
                        </template>
                    </td>
                    <td style="padding:10px 8px;text-align:right;">
                        <div style="display:inline-flex;align-items:center;gap:6px;">
                            <button x-on:click="toggleDdnsDetail(token.id)" title="Chi tiết cấu hình"
                                style="width:30px;height:30px;padding:0;display:inline-flex;align-items:center;justify-content:center;background:#fff;border:1px solid #dee2e6;border-radius:6px;color:#6c757d;cursor:pointer;font-size:14px;transition:all .18s;"
                                onmouseover="this.style.borderColor='#adb5bd';this.style.color='#343a40';this.style.background='#f8f9fa';" onmouseout="this.style.borderColor='#dee2e6';this.style.color='#6c757d';this.style.background='#fff';">
                                <i class="bi bi-gear"></i>
                            </button>
                            <button x-on:click="toggleDdnsActive(token.id)" x-bind:title="token.active ? 'Tạm dừng' : 'Kích hoạt'"
                                style="width:30px;height:30px;padding:0;display:inline-flex;align-items:center;justify-content:center;background:#fff;border:1px solid #fef08a;border-radius:6px;color:#ca8a04;cursor:pointer;font-size:14px;transition:all .18s;"
                                onmouseover="this.style.background='#fefce8';this.style.borderColor='#fde047';" onmouseout="this.style.background='#fff';this.style.borderColor='#fef08a';">
                                <i class="bi" x-bind:class="token.active ? 'bi-pause-fill' : 'bi-play-fill'"></i>
                            </button>
                            <button x-on:click="deleteDdnsToken(token.id)" title="Xóa"
                                style="width:30px;height:30px;padding:0;display:inline-flex;align-items:center;justify-content:center;background:#fff;border:1px solid #fecaca;border-radius:6px;color:#dc2626;cursor:pointer;font-size:14px;transition:all .18s;"
                                onmouseover="this.style.background='#fef2f2';this.style.borderColor='#fca5a5';" onmouseout="this.style.background='#fff';this.style.borderColor='#fecaca';">
                                <i class="bi bi-trash"></i>
                            </button>
                        </div>
                    </td>
                </tr>
            </template>

            <template x-if="ddnsTokens.length === 0">
                <tr>
                    <td colspan="7" style="text-align:center;padding:40px 8px;color:#6c757d;">
                        <i class="bi bi-router" style="font-size:2.5rem;opacity:0.3;display:block;margin-bottom:10px;"></i>
                        <div style="font-size:14px;">Chưa có DDNS Token nào. Bấm <strong>"Tạo DDNS Token"</strong> để bắt đầu.</div>
                    </td>
                </tr>
            </template>
        </tbody>
    </table>
</div>
{/literal}

{* ── Chi tiết Token (expandable) ── *}
{literal}
<template x-for="token in ddnsTokens.filter(function(t){ return t.showDetail; })" x-bind:key="'detail-' + token.id">
    <div style="border:1.5px solid #bfdbfe;border-radius:8px;overflow:hidden;margin-bottom:12px;">
        <div style="padding:10px 14px;background:#eff6ff;border-bottom:1px solid #bfdbfe;display:flex;justify-content:space-between;align-items:center;">
            <strong style="font-size:14px;color:#1d4ed8;">
                <i class="bi bi-key"></i> Cấu hình cho:
                <span style="font-family:monospace;" x-text="token.subdomain"></span>
{/literal}
                <span style="font-family:monospace;color:#6c757d;">.{$domain.domain}</span>
{literal}
            </strong>
            <button x-on:click="toggleDdnsDetail(token.id)"
                style="width:28px;height:28px;padding:0;border:none;background:rgba(0,0,0,0.06);border-radius:6px;color:#6c757d;cursor:pointer;display:inline-flex;align-items:center;justify-content:center;font-size:14px;">
                <i class="bi bi-x-lg"></i>
            </button>
        </div>
        <div style="padding:16px;">
            <div style="margin-bottom:16px;">
                <label style="display:block;font-size:12px;font-weight:700;color:#5E636E;margin-bottom:6px;"><i class="bi bi-link-45deg"></i> URL cập nhật (API Endpoint):</label>
                <template x-if="token.token_url">
                    <div>
                        <div style="display:flex;">
                            <input type="text" class="form-control form-control-sm" x-bind:value="token.token_url" readonly
                                style="height:31px;font-size:12px;font-family:monospace;border-radius:6px 0 0 6px;background:#f8f9fa;">
                            <button x-on:click="copyDdnsUrl(token.id)"
                                style="height:31px;padding:0 12px;font-size:14px;font-weight:600;background:#ea4544;border:none;border-radius:0 6px 6px 0;color:#fff;cursor:pointer;white-space:nowrap;">
                                <i class="bi bi-clipboard"></i> Copy
                            </button>
                        </div>
                        <div style="font-size:12px;color:#6c757d;margin-top:4px;">Gọi GET hoặc POST tới URL trên để cập nhật IP. IP nguồn sẽ được tự phát hiện.</div>
                    </div>
                </template>
                <template x-if="!token.token_url">
                    <div style="background:#f8f9fa;border:1px solid #e2e8f0;border-radius:6px;padding:10px 14px;display:flex;align-items:center;gap:8px;font-size:14px;color:#6c757d;">
                        <i class="bi bi-lock-fill"></i>
                        <div>URL không thể hiển thị lại vì lý do bảo mật. Bấm <strong>"Tạo lại Token"</strong> để lấy URL mới.</div>
                    </div>
                </template>
            </div>

            <template x-if="token.token_url">
                <div>
                    <div style="display:grid;grid-template-columns:1fr 1fr;gap:16px;margin-bottom:16px;">
                        <div>
                            <label style="display:block;font-size:12px;font-weight:700;color:#5E636E;margin-bottom:6px;"><i class="bi bi-terminal"></i> Script Mikrotik RouterOS:</label>
                            <div style="background:#1e293b;color:#e2e8f0;border-radius:6px;padding:10px;font-family:monospace;font-size:12px;white-space:pre-wrap;word-break:break-all;" x-text="'/tool fetch url=&quot;' + token.token_url + '&quot; mode=http'"></div>
                            <button x-on:click="copyDdnsMikrotik(token.id)"
                                style="margin-top:6px;height:26px;padding:0 10px;font-size:12px;background:transparent;border:none;color:#ea4544;cursor:pointer;display:inline-flex;align-items:center;gap:4px;font-weight:600;">
                                <i class="bi bi-clipboard"></i> Copy script
                            </button>
                        </div>
                        <div>
                            <label style="display:block;font-size:12px;font-weight:700;color:#5E636E;margin-bottom:6px;"><i class="bi bi-hdd-rack"></i> Cấu hình DrayTek / Modem PPPoE:</label>
                            <ul style="font-size:12px;color:#6c757d;list-style:none;padding:0;margin:0;line-height:1.8;">
                                <li><strong style="color:#495057;">Provider:</strong> Custom / Custom API</li>
                                <li><strong style="color:#495057;">Server:</strong> whmcs.hvn.vn</li>
                                <li><strong style="color:#495057;">Path:</strong> <span style="font-family:monospace;" x-text="token.token_url.replace('https://whmcs.hvn.vn', '')"></span></li>
                                <li><strong style="color:#495057;">Method:</strong> GET</li>
                            </ul>
                        </div>
                    </div>

                    <div style="display:grid;grid-template-columns:1fr 1fr;gap:16px;border-top:1px solid #e2e8f0;padding-top:16px;">
                        <div>
                            <label style="display:block;font-size:12px;font-weight:700;color:#5E636E;margin-bottom:6px;"><i class="bi bi-hdd-network"></i> Cấu hình Camera IP (Hikvision/Dahua):</label>
                            <ul style="font-size:12px;color:#6c757d;list-style:none;padding:0;margin:0;line-height:1.8;">
                                <li><strong style="color:#495057;">DDNS Type:</strong> Custom / NO-IP Compatible</li>
                                <li><strong style="color:#495057;">Server:</strong> whmcs.hvn.vn</li>
                                <li><strong style="color:#495057;">Domain:</strong> <span style="font-family:monospace;" x-text="token.subdomain"></span>
{/literal}
                                .{$domain.domain}
{literal}
                                </li>
                                <li><strong style="color:#495057;">Interval:</strong> 5 phút</li>
                            </ul>
                        </div>
                        <div>
                            <label style="display:block;font-size:12px;font-weight:700;color:#5E636E;margin-bottom:6px;"><i class="bi bi-code-slash"></i> cURL (Linux/macOS):</label>
                            <div style="background:#1e293b;color:#e2e8f0;border-radius:6px;padding:10px;font-family:monospace;font-size:12px;white-space:pre-wrap;word-break:break-all;" x-text="'curl -s &quot;' + token.token_url + '&quot;'"></div>
                        </div>
                    </div>
                </div>
            </template>
            <template x-if="!token.token_url">
                <div style="background:#f8f9fa;border:1px solid #e2e8f0;border-radius:6px;padding:10px 14px;display:flex;align-items:center;gap:8px;font-size:14px;color:#6c757d;margin-top:12px;">
                    <i class="bi bi-lock-fill"></i>
                    <div>Script cấu hình thiết bị không khả dụng. Bấm <strong>"Tạo lại Token"</strong> để lấy URL và script mới.</div>
                </div>
            </template>

            <div style="display:flex;justify-content:flex-end;margin-top:16px;padding-top:14px;border-top:1px solid #e2e8f0;">
                <button x-on:click="regenerateDdnsToken(token.id)"
                    style="height:32px;padding:0 14px;display:inline-flex;align-items:center;gap:6px;font-size:14px;font-weight:600;background:#fff;border:1.5px solid #fef08a;border-radius:6px;color:#ca8a04;cursor:pointer;transition:all .18s;"
                    onmouseover="this.style.background='#fefce8';" onmouseout="this.style.background='#fff';">
                    <i class="bi bi-arrow-repeat"></i> Tạo lại Token
                </button>
            </div>
        </div>
    </div>
</template>
{/literal}

{* ── Quota ── *}
{literal}
<div style="display:flex;justify-content:space-between;align-items:center;margin-top:12px;font-size:14px;color:#6c757d;flex-wrap:wrap;gap:8px;">
    <div>
        <i class="bi bi-bar-chart-fill"></i> Đang dùng: <strong x-text="ddnsTokens.length"></strong> / {/literal}{$quota.max_ddns_tokens|default:5}{literal} Token DDNS
    </div>
    <div>
        <i class="bi bi-clock-history"></i> TTL tự động: <strong>300s (5 phút)</strong> cho bản ghi DDNS
    </div>
</div>
{/literal}