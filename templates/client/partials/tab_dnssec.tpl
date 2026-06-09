{* tab_dnssec.tpl — DNSSEC management *}

<div style="border:1px solid #e2e8f0;border-radius:10px;overflow:hidden;">
    {* ── Header ── *}
    <div style="padding:14px 18px;background:#1e293b;display:flex;justify-content:space-between;align-items:center;">
        <h5 style="margin:0;font-size:15px;font-weight:700;color:#fff;"><i class="bi bi-shield-lock"></i> DNSSEC &mdash; Bảo mật phân giải tên miền</h5>
        {if $domain.dnssec_enabled}
            <span style="display:inline-block;padding:3px 10px;border-radius:5px;font-size:12px;font-weight:700;background:#16a34a;color:#fff;border:1px solid rgba(255,255,255,0.3);">Trạng thái: Bật</span>
        {else}
            <span style="display:inline-block;padding:3px 10px;border-radius:5px;font-size:12px;font-weight:700;background:#475569;color:#fff;border:1px solid rgba(255,255,255,0.3);">Trạng thái: Tắt</span>
        {/if}
    </div>

    <div style="padding:20px;">
        {if $domain.dnssec_enabled}
        {* ── DNSSEC ĐANG BẬT ── *}
        <div style="display:flex;justify-content:space-between;align-items:flex-start;margin-bottom:20px;gap:16px;flex-wrap:wrap;">
            <div>
                <div style="font-size:14px;color:#1e293b;margin-bottom:4px;">
                    <strong>Ký Zone lần cuối:</strong> {$domain.dnssec.last_signed|default:'Vừa xong'}
                </div>
                <div style="font-size:14px;color:#198754;"><i class="bi bi-shield-check"></i> Hệ thống đang bảo vệ tên miền này.</div>
            </div>
            <button x-on:click="toggleDnssec(false)" x-bind:disabled="dnssecLoading"
                style="height:34px;padding:0 14px;display:inline-flex;align-items:center;gap:6px;font-size:14px;font-weight:600;background:#fff;border:1.5px solid #fecaca;border-radius:6px;color:#dc2626;cursor:pointer;transition:all .18s;white-space:nowrap;flex-shrink:0;"
                onmouseover="this.style.background='#fef2f2';this.style.borderColor='#fca5a5';" onmouseout="this.style.background='#fff';this.style.borderColor='#fecaca';">
                <span x-show="dnssecLoading" class="spinner-border spinner-border-sm"></span>
                <i x-show="!dnssecLoading" class="bi bi-shield-x"></i> Tắt DNSSEC
            </button>
        </div>

        <h6 style="font-size:14px;font-weight:700;color:#1e293b;border-bottom:1px solid #e2e8f0;padding-bottom:10px;margin-bottom:14px;">Thông số DS Record</h6>

        <div style="background:#eff6ff;border:1px solid #bfdbfe;border-radius:8px;padding:10px 14px;margin-bottom:16px;font-size:14px;color:#1d4ed8;">
            <i class="bi bi-info-circle"></i> Sao chép thông tin bên dưới và nhập vào trang quản lý tên miền tại nhà đăng ký (VD: VNNIC, GoDaddy, Namecheap...)
        </div>

        <div style="overflow-x:auto;margin-bottom:16px;">
            <table style="width:100%;border-collapse:collapse;border:1px solid #e2e8f0;border-radius:8px;overflow:hidden;font-size:14px;">
                <tbody>
                    <tr style="border-bottom:1px solid #e2e8f0;">
                        <td style="padding:10px 14px;font-weight:700;color:#5E636E;background:#f8f9fa;width:180px;white-space:nowrap;">Key Tag</td>
                        <td style="padding:10px 14px;display:flex;justify-content:space-between;align-items:center;">
                            <span id="ds-keytag" style="font-family:monospace;color:#1e293b;">12345</span>
                            <a href="javascript:void(0)" onclick="hvnCopyDnssec('ds-keytag')"
                               style="font-size:12px;color:#ea4544;text-decoration:none;font-weight:600;">Copy</a>
                        </td>
                    </tr>
                    <tr style="border-bottom:1px solid #e2e8f0;">
                        <td style="padding:10px 14px;font-weight:700;color:#5E636E;background:#f8f9fa;">Algorithm</td>
                        <td style="padding:10px 14px;display:flex;justify-content:space-between;align-items:center;">
                            <span id="ds-algo" style="font-family:monospace;color:#1e293b;">13 (ECDSA P-256)</span>
                            <a href="javascript:void(0)" onclick="hvnCopyDnssec('ds-algo')"
                               style="font-size:12px;color:#ea4544;text-decoration:none;font-weight:600;">Copy</a>
                        </td>
                    </tr>
                    <tr style="border-bottom:1px solid #e2e8f0;">
                        <td style="padding:10px 14px;font-weight:700;color:#5E636E;background:#f8f9fa;">Digest Type</td>
                        <td style="padding:10px 14px;display:flex;justify-content:space-between;align-items:center;">
                            <span id="ds-dtype" style="font-family:monospace;color:#1e293b;">2 (SHA-256)</span>
                            <a href="javascript:void(0)" onclick="hvnCopyDnssec('ds-dtype')"
                               style="font-size:12px;color:#ea4544;text-decoration:none;font-weight:600;">Copy</a>
                        </td>
                    </tr>
                    <tr style="border-bottom:1px solid #e2e8f0;">
                        <td style="padding:10px 14px;font-weight:700;color:#5E636E;background:#f8f9fa;">Digest</td>
                        <td style="padding:10px 14px;display:flex;justify-content:space-between;align-items:center;gap:12px;">
                            <span id="ds-digest" style="font-family:monospace;color:#1e293b;word-break:break-all;">49FD46E6C4B45C55D4AC99182315ADF13E2A8B6072BFF1C57EA35B03E10D9B58</span>
                            <a href="javascript:void(0)" onclick="hvnCopyDnssec('ds-digest')"
                               style="font-size:12px;color:#ea4544;text-decoration:none;font-weight:600;white-space:nowrap;">Copy</a>
                        </td>
                    </tr>
                    <tr style="background:#fafbff;">
                        <td style="padding:10px 14px;font-weight:700;color:#5E636E;background:#f0f4ff;">DS Record (Full)</td>
                        <td style="padding:10px 14px;display:flex;justify-content:space-between;align-items:center;gap:12px;">
                            <span id="ds-full" style="font-family:monospace;color:#1e293b;font-size:12px;word-break:break-all;">{$domain.domain}. IN DS 12345 13 2 49FD46E6C4B45C55D4AC...</span>
                            <a href="javascript:void(0)" onclick="hvnCopyDnssec('ds-full')"
                               style="font-size:12px;color:#ea4544;text-decoration:none;font-weight:600;white-space:nowrap;">Copy</a>
                        </td>
                    </tr>
                </tbody>
            </table>
        </div>

        <button onclick="hvnCopyAllDnssec()"
            style="height:32px;padding:0 14px;display:inline-flex;align-items:center;gap:6px;font-size:14px;background:#fff;border:1px solid #dee2e6;border-radius:6px;color:#6c757d;cursor:pointer;margin-bottom:20px;transition:all .18s;"
            onmouseover="this.style.borderColor='#adb5bd';this.style.color='#343a40';" onmouseout="this.style.borderColor='#dee2e6';this.style.color='#6c757d';">
            <i class="bi bi-clipboard"></i> Copy tất cả
        </button>

        <div style="background:#fefce8;border:1px solid #fef08a;border-radius:8px;padding:14px;">
            <h6 style="margin:0 0 8px;font-size:14px;font-weight:700;color:#92400e;"><i class="bi bi-exclamation-triangle-fill" style="color:#ca8a04;"></i> LƯU Ý QUAN TRỌNG:</h6>
            <p style="margin:0;font-size:14px;color:#78350f;">Nếu muốn <strong>TẮT DNSSEC</strong>, hãy làm theo đúng thứ tự: Xóa bản ghi DS tại nhà đăng ký trước &rarr; Chờ 24 giờ cho cache DNS toàn cầu cập nhật &rarr; Mới quay lại trang này bấm "Tắt DNSSEC". Nếu làm ngược lại có thể gây lỗi truy cập tên miền.</p>
        </div>

        {else}
        {* ── DNSSEC CHƯA BẬT ── *}
        <div style="text-align:center;padding:32px 16px;">
            <i class="bi bi-shield-plus" style="font-size:4rem;color:#ea4544;opacity:0.7;display:block;margin-bottom:16px;"></i>
            <h5 style="font-size:16px;font-weight:700;color:#1e293b;margin-bottom:10px;">DNSSEC chưa được kích hoạt</h5>
            <p style="font-size:14px;color:#6c757d;max-width:520px;margin:0 auto 24px;">DNSSEC bảo vệ tên miền của bạn khỏi tấn công giả mạo máy chủ DNS (DNS Spoofing) bằng cách ký số điện tử vào các bản ghi. Khuyến nghị bật cho mọi tên miền quan trọng.</p>

            <button x-on:click="toggleDnssec(true)" x-bind:disabled="dnssecLoading"
                style="height:42px;padding:0 28px;display:inline-flex;align-items:center;gap:8px;font-size:14px;font-weight:700;background:#198754;color:#fff;border:none;border-radius:8px;cursor:pointer;transition:all .18s;box-shadow:0 4px 12px rgba(25,135,84,.3);"
                onmouseover="this.style.background='#157347';this.style.boxShadow='0 6px 16px rgba(25,135,84,.4)';" onmouseout="this.style.background='#198754';this.style.boxShadow='0 4px 12px rgba(25,135,84,.3)';">
                <span x-show="dnssecLoading" class="spinner-border spinner-border-sm"></span>
                <i x-show="!dnssecLoading" class="bi bi-shield-plus"></i>
                Bật DNSSEC
            </button>

            <p style="font-size:12px;color:#6c757d;margin-top:14px;">Sau khi bật, hệ thống sẽ tạo khóa bảo mật. Bạn cần mang thông số DS Record tới nhà đăng ký tên miền để hoàn tất.</p>
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
