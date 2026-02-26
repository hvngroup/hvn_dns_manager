# HVN - DirectAdmin DNS Manager
## SETTINGS.md — Admin Configuration Reference

> **Phiên bản**: 1.0  
> **Ngày tạo**: 25/02/2026  
> **Dành cho**: Developer, Admin, AI Agent  
> **Tham chiếu từ**: Cấu hình module DNS Suite v1.25 (legacy) + Thiết kế mới  
> **Lưu trữ DB**: Bảng `tbladdonsettings` (WHMCS native) hoặc bảng riêng `mod_hvndns_settings`  

---

## Mục lục

1. [Tổng quan Hệ thống Settings](#1-tổng-quan-hệ-thống-settings)
2. [Module Core — Cấu hình Lõi](#2-module-core)
3. [Server DirectAdmin — Kết nối DA](#3-server-directadmin)
4. [Domain Policy — Chính sách Tên miền](#4-domain-policy)
5. [DNS Editor — Quyền Chỉnh sửa](#5-dns-editor)
6. [Record Permissions — Bật/Tắt theo Loại Record](#6-record-permissions)
7. [Record Limits — Giới hạn theo Loại Record](#7-record-limits)
8. [URL Redirect — Chuyển hướng](#8-url-redirect)
9. [Email Forwarding — Chuyển tiếp Email](#9-email-forwarding)
10. [DDNS — Dynamic DNS](#10-ddns)
11. [DNSSEC](#11-dnssec)
12. [SSL / Let's Encrypt](#12-ssl--lets-encrypt)
13. [DNS Templates](#13-dns-templates)
14. [Client Notification — Thông báo Email](#14-client-notification)
15. [UI / Navigation — Hiển thị Menu](#15-ui--navigation)
16. [Performance & Cache](#16-performance--cache)
17. [DA Domain Provisioning — Cấu hình Tạo Domain](#17-da-domain-provisioning)
18. [Queue & Cron — Hàng đợi](#18-queue--cron)
19. [Webhook & Admin Alert](#19-webhook--admin-alert)
20. [Security & Access Control](#20-security--access-control)
21. [Data Retention — Lưu trữ Dữ liệu](#21-data-retention)
22. [License](#22-license)
23. [Upsell](#23-upsell)
24. [Bảng Tổng hợp Settings](#24-bảng-tổng-hợp-settings)

---

## 1. Tổng quan Hệ thống Settings

### 1.1. Cách lưu trữ

Settings được lưu trong bảng `mod_hvndns_settings` (key-value):

```sql
CREATE TABLE mod_hvndns_settings (
    id          INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    setting_key VARCHAR(100) NOT NULL,
    setting_val TEXT NULL,
    created_at  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE INDEX uniq_key (setting_key)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

Truy xuất qua helper:

```php
// Đọc
$value = SettingsHelper::get('default_ttl', 3600); // default fallback

// Ghi
SettingsHelper::set('default_ttl', 3600);

// Đọc boolean
$enabled = SettingsHelper::getBool('enable_dnssec', false);

// Đọc integer
$limit = SettingsHelper::getInt('a_record_limit', 100);
```

### 1.2. Phân nhóm hiển thị Admin

Trang Admin Settings chia thành các tab:

```
[Chung] [Servers] [Domain Policy] [DNS Editor] [Limits] [Redirects] 
[Email] [DDNS] [DNSSEC] [SSL] [Templates] [Notifications] [UI] [Performance] [Queue] [Security]
```

### 1.3. Quy ước Key

- Tất cả key dùng `snake_case`
- Boolean: giá trị `"1"` = true, `"0"` hoặc `""` = false
- Integer: giá trị string, cast khi đọc
- `0` trong limit = unlimited (không giới hạn)
- `-1` trong limit = disabled (tắt hoàn toàn tính năng)

---

## 2. Module Core

> **Tab Admin**: Chung  
> **Ảnh hưởng**: Toàn bộ module

| # | Setting Key | Label | Type | Default | Mô tả |
|---|------------|-------|------|---------|-------|
| 1 | `module_enabled` | Kích hoạt Module | Boolean | `1` | Bật/tắt toàn bộ module. Khi tắt: Client Area ẩn, Cron Worker dừng, Admin vẫn truy cập được trang settings |
| 2 | `license_key` | License Key | String | `""` | Khóa bản quyền module (nếu bán thương mại). Để trống = không kiểm tra license. Format: `hvndns-XXXXXXXX` |
| 3 | `default_nameserver_1` | Nameserver 1 | String | `"dns1.hvn.vn"` | NS1 mặc định. BẮT BUỘC có giá trị. Dùng khi tạo zone mới + hiển thị hướng dẫn cho client |
| 4 | `default_nameserver_2` | Nameserver 2 | String | `"dns2.hvn.vn"` | NS2 mặc định. BẮT BUỘC có giá trị |
| 5 | `default_nameserver_3` | Nameserver 3 | String | `"dns3.hvn.vn"` | NS3 mặc định. Có thể để trống nếu chỉ có 2 server |
| 6 | `default_nameserver_4` | Nameserver 4 | String | `""` | NS4 (tùy chọn). Để trống = không sử dụng |
| 7 | `default_nameserver_5` | Nameserver 5 | String | `""` | NS5 (tùy chọn). Để trống = không sử dụng |
| 8 | `default_ttl` | TTL mặc định | Integer | `3600` | TTL mặc định khi tạo record mới (giây). Client có thể override khi thêm record. Range: 60–86400 |

**Validation**:
- `default_nameserver_1` và `default_nameserver_2` KHÔNG được trống
- `default_ttl` phải trong range 60–86400
- `license_key` nếu có → validate format qua API (hoặc offline check)

**Liên kết**:
- NS1-5 → Dùng trong SPEC.md FLOW-05 (Provisioning) khi tạo NS records cho zone mới
- NS1-5 → Hiển thị trên Client Area CL-01 (WIREFRAME.md) phần "Nameserver cần trỏ về"
- `default_ttl` → Giá trị mặc định trong Modal CL-03 (WIREFRAME.md) dropdown TTL

---

## 3. Server DirectAdmin

> **Tab Admin**: Servers  
> **Lưu trữ**: Bảng `mod_hvndns_servers` (KHÔNG lưu trong settings)  
> **Xem chi tiết**: DB_SCHEMA.md Section 4

Phần này đã được thiết kế đầy đủ trong DB_SCHEMA.md bảng `mod_hvndns_servers` với multi-server support. Không cần thêm settings riêng — mỗi server là 1 row trong bảng.

**Khác biệt với module cũ**: Module cũ chỉ hỗ trợ 1 DA server (single fields). Module mới hỗ trợ N servers (bảng riêng).

---

## 4. Domain Policy

> **Tab Admin**: Domain Policy  
> **Ảnh hưởng**: Quy tắc khi nào domain được quản lý, khi nào client được sửa DNS

| # | Setting Key | Label | Type | Default | Mô tả |
|---|------------|-------|------|---------|-------|
| 9 | `respect_whmcs_dns` | Tuân theo cài đặt DNS Management của WHMCS | Boolean | `0` | Khi bật: Module chỉ quản lý domain có setting "DNS Management" = Enabled trong WHMCS Domain settings. Khi tắt: Module quản lý TẤT CẢ domain không phân biệt |
| 10 | `disable_manage_wrong_ns` | Chặn quản lý khi NS chưa đúng | Boolean | `1` | Khi bật: Client KHÔNG thể sửa DNS nếu domain chưa trỏ NS về nameserver mặc định (NS1-5). Module kiểm tra NS thực tế qua `dns_get_record()` hoặc `dig`. Hiển thị thông báo: "Vui lòng trỏ nameserver về dns1/2/3.hvn.vn trước khi quản lý DNS" |
| 11 | `ns_check_method` | Phương thức kiểm tra NS | Select | `"dns_lookup"` | Cách kiểm tra NS đã trỏ đúng chưa: `dns_lookup` = PHP `dns_get_record()` realtime (chính xác nhưng chậm ~1s); `whois` = WHOIS lookup; `skip` = bỏ qua kiểm tra (luôn cho phép) |
| 12 | `create_on_preregistrar` | Tạo zone trước khi đăng ký domain | Boolean | `1` | Hook `PreRegistrarRegisterDomain`: Tạo zone trên DA TRƯỚC khi domain đăng ký xong tại Registry. **Cần thiết** cho một số registry (VD: .vn) yêu cầu NS phải có zone hoạt động trước khi accept domain |
| 13 | `create_on_registration` | Tạo zone sau khi đăng ký domain | Boolean | `1` | Hook `AfterRegistrarRegistration`: Tạo zone sau khi domain đăng ký thành công. Nếu `create_on_preregistrar` = true thì hook này sẽ skip (zone đã tạo rồi) |
| 14 | `create_on_transfer` | Tạo zone sau khi transfer domain | Boolean | `1` | Hook `AfterRegistrarTransfer`: Tạo zone khi domain transfer về WHMCS thành công |
| 15 | `grace_period_days` | Số ngày giữ zone sau khi hủy | Integer | `30` | Khi domain bị terminate, zone vẫn giữ trên DA thêm N ngày trước khi xóa thật. Cho phép khôi phục nếu hủy nhầm |

**Validation**:
- `grace_period_days` range 0–365. `0` = xóa ngay khi terminate

**Logic kiểm tra NS** (`disable_manage_wrong_ns = true`):
```php
// Khi client mở DNS Editor:
$actualNS = dns_get_record($domain, DNS_NS);
$expectedNS = [$settings->get('default_nameserver_1'), ...]; // loại bỏ empty

$nsMatch = !empty(array_intersect(
    array_column($actualNS, 'target'),
    $expectedNS
));

if (!$nsMatch) {
    return Response::error('NS_NOT_CONFIGURED', 
        'Vui lòng trỏ nameserver về ' . implode(', ', $expectedNS) . ' trước khi quản lý DNS.');
}
```

**⚠️ Lưu ý quan trọng — `create_on_preregistrar`**:

Một số Registry (đặc biệt VNNIC quản lý `.vn`) yêu cầu nameserver phải có zone file hoạt động trước khi chấp nhận đăng ký domain. Nếu tắt setting này, domain `.vn` có thể bị Registry reject vì NS không resolve được.

Luồng khi `create_on_preregistrar = true`:
```
1. Client đặt hàng domain trên WHMCS
2. WHMCS trigger hook PreRegistrarRegisterDomain
3. Module tạo zone trên DA (Primary) → zone hoạt động
4. WHMCS gửi lệnh đăng ký tới Registrar
5. Registrar gửi EPP create tới Registry
6. Registry kiểm tra NS → zone tồn tại → ACCEPT ✅
```

---

## 5. DNS Editor

> **Tab Admin**: DNS Editor  
> **Ảnh hưởng**: Tính năng chỉnh sửa DNS trong Client Area

| # | Setting Key | Label | Type | Default | Mô tả |
|---|------------|-------|------|---------|-------|
| 16 | `enable_dns_editor` | Bật DNS Editor | Boolean | `1` | Tắt = Client không thể xem/sửa DNS records. Admin vẫn sửa được |
| 17 | `subdomain_limit` | Giới hạn Subdomain | Integer | `0` | Số subdomain tối đa cho 1 domain. `0` = unlimited. `-1` = disable (không cho tạo subdomain). Subdomain = số unique values trong cột `name` (trừ `@`) |

**Liên kết**: Override bởi Quota Plan nếu domain có `quota_plan_id` — Quota Plan luôn ưu tiên hơn global settings.

---

## 6. Record Permissions

> **Tab Admin**: DNS Editor  
> **Ảnh hưởng**: Bật/tắt quyền chỉnh sửa từng loại record cho CLIENT. Admin luôn có quyền.

| # | Setting Key | Label | Type | Default | Mô tả |
|---|------------|-------|------|---------|-------|
| 18 | `allow_modify_a` | Cho phép sửa A record | Boolean | `1` | Client có thể thêm/sửa/xóa A records |
| 19 | `allow_modify_aaaa` | Cho phép sửa AAAA record | Boolean | `1` | Client có thể thêm/sửa/xóa AAAA records |
| 20 | `allow_modify_cname` | Cho phép sửa CNAME record | Boolean | `1` | Client có thể thêm/sửa/xóa CNAME records |
| 21 | `allow_modify_mx` | Cho phép sửa MX record | Boolean | `1` | Client có thể thêm/sửa/xóa MX records |
| 22 | `allow_modify_txt` | Cho phép sửa TXT record | Boolean | `1` | Client có thể thêm/sửa/xóa TXT records |
| 23 | `allow_modify_srv` | Cho phép sửa SRV record | Boolean | `1` | Client có thể thêm/sửa/xóa SRV records |
| 24 | `allow_modify_caa` | Cho phép sửa CAA record | Boolean | `1` | Client có thể thêm/sửa/xóa CAA records |
| 25 | `allow_modify_ns` | Cho phép sửa NS record | Boolean | `0` | Client có thể sửa NS records. **MẶC ĐỊNH TẮT** — NS records thường là system records, chỉ Admin nên sửa |

**Logic trong DNS Editor UI**:
```php
// Khi render form "Thêm bản ghi" → chỉ hiện record types được phép
$allowedTypes = [];
foreach (['a','aaaa','cname','mx','txt','srv','caa','ns'] as $type) {
    if (SettingsHelper::getBool("allow_modify_{$type}", true)) {
        $allowedTypes[] = strtoupper($type);
    }
}
// Dropdown "Loại bản ghi" chỉ chứa $allowedTypes

// Khi submit → validate server-side
if (!SettingsHelper::getBool("allow_modify_" . strtolower($type))) {
    return Response::error('RECORD_TYPE_DISABLED', 
        "Bạn không có quyền sửa bản ghi loại {$type}.");
}
```

---

## 7. Record Limits

> **Tab Admin**: Limits  
> **Ảnh hưởng**: Giới hạn số lượng record theo từng loại cho CLIENT. `0` = unlimited.

| # | Setting Key | Label | Type | Default | Mô tả |
|---|------------|-------|------|---------|-------|
| 26 | `a_record_limit` | Giới hạn A records | Integer | `100` | Số A records tối đa cho 1 domain |
| 27 | `aaaa_record_limit` | Giới hạn AAAA records | Integer | `100` | Số AAAA records tối đa |
| 28 | `cname_record_limit` | Giới hạn CNAME records | Integer | `100` | Số CNAME records tối đa |
| 29 | `mx_record_limit` | Giới hạn MX records | Integer | `100` | Số MX records tối đa |
| 30 | `txt_record_limit` | Giới hạn TXT records | Integer | `100` | Số TXT records tối đa |
| 31 | `srv_record_limit` | Giới hạn SRV records | Integer | `100` | Số SRV records tối đa |
| 32 | `caa_record_limit` | Giới hạn CAA records | Integer | `20` | Số CAA records tối đa |
| 33 | `ns_record_limit` | Giới hạn NS records | Integer | `10` | Số NS records tối đa |

**Quan hệ với Quota Plan**:

Hệ thống có 2 lớp giới hạn:

```
Global Settings (Section 7)     ← Áp dụng cho TẤT CẢ domain
        ↓
Quota Plan (mod_hvndns_quota_plans) ← Override cho domain có quota_plan_id
        ↓
Admin Override per-domain        ← Admin đặt exception riêng cho 1 domain cụ thể
```

**Thứ tự ưu tiên**: Admin Override > Quota Plan > Global Settings.

Quota Plan có `max_records` (tổng tất cả loại). Global Settings có limit riêng **từng loại**. Enforcement kiểm tra CẢ HAI:

```php
// 1. Kiểm tra per-type limit (Global Settings)
$typeLimit = SettingsHelper::getInt("{$type}_record_limit", 100);
$currentTypeCount = DnsRecord::where('domain_id', $domainId)
    ->where('type', $type)->active()->count();
if ($typeLimit > 0 && $currentTypeCount >= $typeLimit) {
    throw new QuotaExceededException("Đã đạt giới hạn {$typeLimit} bản ghi {$type}.");
}

// 2. Kiểm tra total limit (Quota Plan)
if ($domain->quotaPlan) {
    $totalLimit = $domain->quotaPlan->max_records;
    $totalCount = DnsRecord::where('domain_id', $domainId)->active()->count();
    if ($totalLimit > 0 && $totalCount >= $totalLimit) {
        throw new QuotaExceededException("Đã đạt giới hạn {$totalLimit} bản ghi cho gói dịch vụ.");
    }
}
```

---

## 8. URL Redirect

> **Tab Admin**: Redirects

| # | Setting Key | Label | Type | Default | Mô tả |
|---|------------|-------|------|---------|-------|
| 34 | `enable_url_redirect` | Bật URL Forwarding | Boolean | `1` | Cho phép client tạo chuyển hướng 301/302 |
| 35 | `enable_masked_redirect` | Bật Masked URL Forwarding | Boolean | `1` | Cho phép client tạo masked redirect (ẩn URL đích). Cần `enable_url_redirect = true` |
| 36 | `masked_hash_key` | Hash Key cho Connector | String | `""` | Khóa bí mật dùng mã hóa URL đích trong masked redirect connector. PHẢI thay đổi giá trị mặc định trước khi dùng. Min 8 ký tự |
| 37 | `url_redirect_limit` | Giới hạn Redirect/domain | Integer | `5` | Số redirect tối đa cho 1 domain. `0` = unlimited |

**Validation**:
- `masked_hash_key` min 8 ký tự nếu `enable_masked_redirect = true`
- `masked_hash_key` lưu encrypted trong DB (dùng WHMCS Encryption)

---

## 9. Email Forwarding

> **Tab Admin**: Email

| # | Setting Key | Label | Type | Default | Mô tả |
|---|------------|-------|------|---------|-------|
| 38 | `enable_email_forwarder` | Bật Email Forwarding | Boolean | `1` | Cho phép client tạo email forwarder (info@domain.com → gmail) |
| 39 | `enable_email_catchall` | Bật Email Catch-all | Boolean | `1` | Cho phép client bật catch-all (nhận tất cả email không match forwarder) |
| 40 | `email_forwarder_limit` | Giới hạn Email Alias/domain | Integer | `5` | Số email alias (forwarder) tối đa cho 1 domain. `0` = unlimited |
| 41 | `email_destination_limit` | Giới hạn Destination/domain | Integer | `10` | Tổng số email đích (tất cả forwarder cộng lại) tối đa cho 1 domain. `0` = unlimited |
| 42 | `email_verify_template` | Email Template Xác minh | Select (WHMCS Email Templates) | `""` | Template email gửi cho client khi thêm destination email mới (xác minh email đích tồn tại). Để trống = không yêu cầu xác minh |

**Logic xác minh email destination**:

Khi `email_verify_template` có giá trị:
```
1. Client thêm forwarder: info@domain.com → personal@gmail.com
2. Hệ thống gửi email xác minh tới personal@gmail.com (dùng WHMCS mail template)
3. Email chứa link verify với token hết hạn 24h
4. Client (hoặc chủ email đích) click link → xác nhận
5. Forwarder được kích hoạt → dispatch queue tạo trên DA
```

Nếu `email_verify_template` trống → bỏ qua bước xác minh, tạo forwarder ngay.

---

## 10. DDNS

> **Tab Admin**: DDNS

| # | Setting Key | Label | Type | Default | Mô tả |
|---|------------|-------|------|---------|-------|
| 43 | `ddns_mode` | Chế độ DDNS | Select | `"off"` | `off`: Tắt hoàn toàn<br>`free`: Tự do sử dụng<br>`paid`: Yêu cầu gói trả phí / addon |
| 44 | `ddns_rate_limit` | Giới hạn Request/giờ | Integer | `60` | Số request DDNS tối đa mỗi giờ per token |
| 45 | `ddns_token_limit` | Giới hạn Token/domain | Integer | `5` | Số DDNS token tối đa cho 1 domain |
| 46 | `enable_ddns_bruteforce` | Bật Brute Force Detection | Boolean | `1` | Phát hiện và block IP gửi token sai liên tục |
| 47 | `ddns_bruteforce_threshold` | Ngưỡng Brute Force | Integer | `10` | Số lần gửi token sai trước khi block IP |
| 48 | `ddns_bruteforce_window` | Cửa sổ kiểm tra (giây) | Integer | `3600` | Khoảng thời gian đếm số lần fail (mặc định 1 giờ) |
| 49 | `ddns_bruteforce_ban_duration` | Thời gian Block IP (giây) | Integer | `3600` | Thời gian block IP sau khi bị phát hiện brute force (mặc định 1 giờ) |

**Override bởi Quota Plan**: Quota Plan có `ddns_enabled` (boolean) và `max_ddns_tokens`. Nếu Quota Plan tắt DDNS thì global setting không ảnh hưởng.

---

## 11. DNSSEC

> **Tab Admin**: DNSSEC

| # | Setting Key | Label | Type | Default | Mô tả |
|---|------------|-------|------|---------|-------|
| 50 | `dnssec_mode` | Chế độ DNSSEC | Select | `"off"` | `off`: Tắt hoàn toàn<br>`free`: Tự do sử dụng<br>`paid`: Yêu cầu gói trả phí / addon. (Yêu cầu DA server bật `dnssec=1`) |
| 51 | `dnssec_auto_resign` | Tự động Re-sign Zone | Boolean | `1` | Tự động dispatch job RESIGN_ZONE sau mỗi batch thay đổi record khi DNSSEC đang enabled |

**Override bởi Quota Plan**: `dnssec_enabled` trong Quota Plan.

---

## 12. SSL / Let's Encrypt

> **Tab Admin**: SSL

| # | Setting Key | Label | Type | Default | Mô tả |
|---|------------|-------|------|---------|-------|
| 52 | `enable_auto_ssl` | Bật Auto-SSL cho domain mới | Boolean | `1` | Tự động request Let's Encrypt SSL khi tạo zone mới trên DA |
| 53 | `enable_client_ssl_trigger` | Cho phép Client trigger SSL | Boolean | `1` | Cho phép client bấm nút "Yêu cầu SSL" trong Client Area để request/renew Let's Encrypt thủ công |
| 54 | `ssl_auto_renew_days` | Gia hạn SSL trước (ngày) | Integer | `7` | Cron `ssl_checker` tự gia hạn cert khi còn ≤ N ngày trước hết hạn |
| 55 | `enable_php_for_domain` | Bật PHP cho domain trên DA | Boolean | `1` | Khi tạo domain trên DA, bật quyền chạy PHP (cần cho URL forwarding, connector). DA account phải có PHP privilege |

**Override bởi Quota Plan**: `ssl_enabled` trong Quota Plan.

---

## 13. DNS Templates

> **Tab Admin**: Templates

| # | Setting Key | Label | Type | Default | Mô tả |
|---|------------|-------|------|---------|-------|
| 56 | `enable_dns_templates` | Bật DNS Templates | Boolean | `1` | Cho phép client load DNS template từ danh sách admin tạo sẵn |
| 57 | `enable_user_custom_templates` | Cho phép User tạo Template riêng | Boolean | `0` | Cho phép client tự tạo DNS template từ zone hiện tại để dùng lại. MẶC ĐỊNH TẮT |
| 58 | `user_template_limit` | Giới hạn Template/user | Integer | `10` | Số template tối đa mà 1 client được tạo. `0` = unlimited |

**Ghi chú**: Templates do Admin tạo lưu trong `mod_hvndns_templates`. Templates do User tạo cũng lưu cùng bảng nhưng thêm cột `created_by_user_id` để phân biệt.

---

## 14. Client Notification

> **Tab Admin**: Notifications (phần Client Email)

| # | Setting Key | Label | Type | Default | Mô tả |
|---|------------|-------|------|---------|-------|
| 59 | `enable_client_notification` | Bật Email thông báo cho Client | Boolean | `0` | Khi bật: Client nhận email mỗi khi DNS thay đổi thành công (zone created, record altered, zone removed) |
| 60 | `notification_email_template` | Email Template Thông báo | Select (WHMCS Email Templates) | `""` | Template WHMCS dùng gửi notification cho client. Cần tạo template với merge fields: `{$domain}`, `{$action}`, `{$record_type}`, `{$record_name}`, `{$record_value}` |
| 61 | `notify_on_zone_create` | Thông báo khi tạo Zone | Boolean | `1` | Gửi email khi zone mới được tạo thành công |
| 62 | `notify_on_record_change` | Thông báo khi thay đổi Record | Boolean | `1` | Gửi email khi record được thêm/sửa/xóa thành công |
| 63 | `notify_on_zone_delete` | Thông báo khi xóa Zone | Boolean | `1` | Gửi email khi zone bị xóa |

**Logic**: Notification chỉ gửi SAU KHI sync thành công (tất cả server COMPLETE), KHÔNG gửi khi chỉ lưu vào queue.

---

## 15. UI / Navigation

> **Tab Admin**: UI

| # | Setting Key | Label | Type | Default | Mô tả |
|---|------------|-------|------|---------|-------|
| 64 | `show_domain_service_link` | Hiện link trong Domain Admin | Boolean | `1` | Hiển thị link "DNS Manager" trên trang Domain Service trong Admin Area. Click → mở DNS Editor admin cho domain đó |
| 65 | `show_under_domain_menu` | Hiện trong menu Domain (Client) | Boolean | `1` | Hiển thị link "Quản lý DNS" trong menu Domain dropdown của Client Area |
| 66 | `nav_menu_order` | Thứ tự Menu | Integer | `20` | Vị trí sắp xếp menu item trong Client Area navigation. Số nhỏ = hiện trước |
| 67 | `show_in_domain_sidebar` | Hiện trong Sidebar Domain Detail | Boolean | `1` | Hiển thị link "DNS Manager" trong sidebar trang chi tiết domain (Client Area) |

**Implementation**: Qua WHMCS Hooks `ClientAreaPrimaryNavbar`, `ClientAreaSecondarySidebar`.

---

## 16. Performance & Cache

> **Tab Admin**: Performance

| # | Setting Key | Label | Type | Default | Mô tả |
|---|------------|-------|------|---------|-------|
| 68 | `fetch_from_ns_on_load` | Fetch từ NS mỗi lần load (Client) | Boolean | `0` | `true`: Mỗi khi client mở DNS Editor → gọi DA API lấy zone mới nhất (chính xác nhưng chậm ~1s). `false`: Load từ DB local (nhanh, dùng cache) |
| 69 | `fetch_from_ns_on_load_admin` | Fetch từ NS mỗi lần load (Admin) | Boolean | `0` | Tương tự nhưng cho Admin Area. Admin thường cần data chính xác hơn |
| 70 | `cache_refresh_ttl` | TTL Cache Zone (giây) | Integer | `720` | Thời gian tối đa cache zone data trước khi bắt buộc fetch lại từ DA. Chỉ áp dụng khi `fetch_from_ns_on_load = false`. `720` = 12 phút |
| 71 | `large_db_mode` | Chế độ Database lớn | Boolean | `0` | Khi bật: Trang Admin Global Domains KHÔNG load tất cả domain (tránh timeout). Chỉ cho phép tìm kiếm theo tên. Bật khi có > 2000 domains |
| 72 | `client_rate_limit` | Giới hạn thay đổi/phút (Client) | Integer | `30` | Số thay đổi DNS tối đa mỗi phút cho 1 client. Chống spam/abuse |

**⚠️ Về `fetch_from_ns_on_load`**:

Module mới dùng kiến trúc Queue (WHMCS DB là source of truth). Tuy nhiên vẫn giữ option fetch từ NS để:
- Phát hiện drift real-time (nếu ai đó sửa trực tiếp trên DA)
- Đảm bảo data chính xác cho Admin troubleshooting

Khi `fetch_from_ns_on_load = false` (mặc định):
```
Client mở DNS Editor → Load từ mod_hvndns_records (< 50ms)
                      → Nếu last_fetched > cache_refresh_ttl
                        → Background fetch từ DA → update DB → next load sẽ mới
```

Khi `fetch_from_ns_on_load = true`:
```
Client mở DNS Editor → Gọi DAGateway::getZone() (500-1500ms)
                      → So sánh với DB → update nếu khác
                      → Render records
```

---

## 17. DA Domain Provisioning

> **Tab Admin**: Domain Policy (nhóm Provisioning)

| # | Setting Key | Label | Type | Default | Mô tả |
|---|------------|-------|------|---------|-------|
| 73 | `da_web_template` | Web Template File | String | `""` | Tên file zip (VD: `webtemplate.zip`) chứa files sẽ extract vào `public_html` của domain mới trên DA. Để trống = không upload web template. File phải đặt tại vị trí cấu hình trong DA |
| 74 | `da_enable_php` | Bật PHP cho domain | Boolean | `1` | Khi tạo domain trên DA, enable PHP execution. DA account phải có PHP privilege. Cần cho URL Forwarding connector hoạt động |

**Ghi chú**: Settings này truyền vào DA API khi tạo domain mới (CREATE_ZONE enhanced). Khác với tạo zone DNS thuần, tạo domain trên DA có thể bao gồm tạo cả user/hosting account tùy cách setup.

---

## 18. Queue & Cron

> **Tab Admin**: Queue  
> **Ảnh hưởng**: Cấu hình hoạt động Cron Worker và Queue Engine

| # | Setting Key | Label | Type | Default | Mô tả |
|---|------------|-------|------|---------|-------|
| 75 | `cron_interval` | Tần suất Cron (giây) | Integer | `60` | Khoảng thời gian giữa các lần chạy Cron Worker. Mặc định 60 giây (1 phút). Giảm xuống 30 → sync nhanh hơn nhưng tốn CPU |
| 76 | `job_timeout` | Timeout mỗi Job (giây) | Integer | `30` | Thời gian tối đa cho 1 API call tới DA. Vượt quá → timeout → retry |
| 77 | `max_retry_attempts` | Số lần Retry tối đa | Integer | `5` | Sau N lần fail liên tiếp → PERMANENTLY_FAILED. Range 1–10 |
| 78 | `stale_lock_timeout` | Timeout Stale Lock (giây) | Integer | `300` | Job ở trạng thái SYNCING quá N giây → coi là stale (cron crash) → recover |
| 79 | `worker_max_runtime` | Thời gian chạy tối đa Worker (giây) | Integer | `55` | Worker tự thoát sau N giây để tránh overlap với cron tiếp theo. Nên < `cron_interval` |
| 80 | `conflict_window` | Cửa sổ Conflict (giây) | Integer | `180` | Khoảng thời gian kiểm tra xung đột khi tạo job mới. VD: 180 = 3 phút → nếu có job PENDING cho cùng record trong 3 phút → trigger conflict resolution |

---

## 19. Webhook & Admin Alert

> **Tab Admin**: Notifications (phần Admin Alert)  
> **Đã thiết kế trong**: SPEC.md Section 11, WIREFRAME.md AD-12

| # | Setting Key | Label | Type | Default | Mô tả |
|---|------------|-------|------|---------|-------|
| 81 | `enable_telegram_alert` | Bật Telegram Alert | Boolean | `0` | Gửi cảnh báo qua Telegram Bot |
| 82 | `telegram_bot_token` | Telegram Bot Token | String (Encrypted) | `""` | Token của Telegram Bot. Lưu encrypted |
| 83 | `telegram_chat_id` | Telegram Chat ID | String | `""` | Chat ID hoặc Group ID nhận alert |
| 84 | `enable_email_alert` | Bật Email Alert | Boolean | `0` | Gửi cảnh báo qua email |
| 85 | `alert_email_addresses` | Email nhận Alert | String | `""` | Danh sách email, phân tách bằng dấu phẩy. VD: `admin@hvn.vn, devops@hvn.vn` |
| 86 | `alert_cooldown` | Cooldown giữa 2 Alert (giây) | Integer | `900` | Khoảng cách tối thiểu giữa 2 alert cùng loại. Chống spam khi server down kéo dài |
| 87 | `alert_failed_threshold` | Ngưỡng Job Failed liên tiếp | Integer | `5` | Gửi alert khi có ≥ N job FAILED liên tiếp trên 1 server |
| 88 | `alert_unreachable_threshold` | Ngưỡng Server Unreachable | Integer | `3` | Gửi alert khi server mất kết nối ≥ N lần liên tiếp |
| 89 | `alert_queue_backlog_threshold` | Ngưỡng Queue Tồn đọng | Integer | `100` | Gửi alert khi có > N job PENDING tồn đọng quá 10 phút |

---

## 20. Security & Access Control

> **Tab Admin**: Security

| # | Setting Key | Label | Type | Default | Mô tả |
|---|------------|-------|------|---------|-------|
| 90 | `restrict_subaccounts` | Giới hạn Sub-accounts | Boolean | `1` | Khi bật: Sub-accounts (contacts) chỉ được quản lý DNS nếu tài khoản chính có quyền "Domain Management". Dùng WHMCS Contact permissions |
| 91 | `audit_trail_retention_days` | Lưu Audit Trail (ngày) | Integer | `365` | Số ngày giữ audit trail. Tối thiểu 365 |
| 92 | `sync_log_retention_days` | Lưu Sync Logs (ngày) | Integer | `90` | Số ngày giữ sync logs |
| 93 | `record_history_retention_days` | Lưu Record History (ngày) | Integer | `90` | Số ngày giữ lịch sử thay đổi record |

---

## 21. Data Retention

> **Tab Admin**: Performance (nhóm Retention)

| # | Setting Key | Label | Type | Default | Mô tả |
|---|------------|-------|------|---------|-------|
| 94 | `snapshot_retention_count` | Số Snapshot giữ lại/domain | Integer | `30` | Rolling retention — giữ N snapshot mới nhất, xóa cũ nhất khi vượt quá |
| 95 | `queue_completed_retention_days` | Lưu Queue COMPLETE (ngày) | Integer | `30` | Số ngày giữ job đã hoàn thành trong bảng queue trước khi cleanup |
| 96 | `drift_auto_fix` | Tự động sửa Drift | Boolean | `0` | Khi bật: Nightly drift detection tự push WHMCS → DA mà không cần Admin xác nhận. WHMCS là source of truth |

---

## 22. License

> **Tab Admin**: License

| # | Setting Key | Label | Type | Default | Mô tả |
|---|------------|-------|------|---------|-------|
| 97 | `license_key` | License Key | String | `""` | Khóa bản quyền Module |
| 98 | `license_local_key` | Local Key | Text | `""` | Khóa xác thực offline nội bộ, tự động sinh từ server |
| 99 | `license_server_url` | License Server URL | String | `""` | Địa chỉ máy chủ cấp phép bản quyền |
| 100 | `license_grace_days` | Grace Days | Integer | `3` | Số ngày cho phép tiếp tục sử dụng khi hết hạn bản quyền hoặc không kết nối được server |
| 101 | `license_check_interval` | Chu kỳ kiểm tra (ngày) | Integer | `7` | Số ngày giữa các lần gọi API server check license |
| 102 | `license_last_check` | Lần kiểm tra cuối | String | `""` | Timestamp lần kiểm tra bản quyền gần nhất |
| 103 | `license_status` | Trạng thái License | String | `""` | Trạng thái bản quyền (Active, Suspended, Expired...) |
| 104 | `license_error_message` | Thông báo lỗi License | String | `""` | Ghi nhận lỗi chi tiết nếu kiểm tra bản quyền thất bại |

---

## 23. Upsell

> **Tab Admin**: Upsell

| # | Setting Key | Label | Type | Default | Mô tả |
|---|------------|-------|------|---------|-------|
| 105 | `upsell_enable` | Bật module Upsell | Boolean | `0` | Cho phép hiển thị các gói nâng cấp/addon DNS |
| 106 | `upsell_dnssec_addon_id` | ID Addon DNSSEC | Integer | `0` | Product/Addon ID trong WHMCS dùng để nâng cấp tính năng DNSSEC |
| 107 | `upsell_ddns_addon_id` | ID Addon DDNS | Integer | `0` | Product/Addon ID trong WHMCS dùng để nâng cấp tính năng DDNS |
| 108 | `upsell_quota_addon_ids` | IDs Addon Quota/Limits | String | `""` | Danh sách ID Addon nâng giới hạn DNS records (phân cách bằng dấu phẩy) |
| 109 | `upsell_display_price` | Hiển thị giá Upsell | Boolean | `1` | Hiển thị giá trực tiếp trên Client Area khi quảng cáo tính năng |
| 110 | `upsell_custom_url` | URL tùy chỉnh | String | `""` | Đường dẫn tùy chỉnh nếu click vào tính năng cần nâng cấp (ghi đè link mặc định) |
| 111 | `upsell_description` | Mô tả chung Upsell | Text | `""` | Nội dung tiếp thị nâng cấp hiển thị trên giao diện giới hạn tính năng |

---

## 24. Bảng Tổng hợp Settings

**Tổng: 111 settings** phân bổ theo nhóm:

| Nhóm | Số lượng | Settings # |
|------|---------|-----------|
| Module Core | 8 | 1–8 |
| Domain Policy | 7 | 9–15 |
| DNS Editor | 2 | 16–17 |
| Record Permissions | 8 | 18–25 |
| Record Limits | 8 | 26–33 |
| URL Redirect | 4 | 34–37 |
| Email Forwarding | 5 | 38–42 |
| DDNS | 7 | 43–49 |
| DNSSEC | 2 | 50–51 |
| SSL / Let's Encrypt | 4 | 52–55 |
| DNS Templates | 3 | 56–58 |
| Client Notification | 5 | 59–63 |
| UI / Navigation | 4 | 64–67 |
| Performance & Cache | 5 | 68–72 |
| DA Provisioning | 2 | 73–74 |
| Queue & Cron | 6 | 75–80 |
| Webhook & Alert | 9 | 81–89 |
| Security & Access | 4 | 90–93 |
| Data Retention | 3 | 94–96 |
| License | 8 | 97–104 |
| Upsell | 7 | 105–111 |
| **TỔNG** | **111** | |

### Tác động tới các tài liệu khác

| Tài liệu | Cần cập nhật |
|-----------|-------------|
| **DB_SCHEMA.md** | Thêm bảng `mod_hvndns_settings` (Section 1). Thêm cột `created_by_user_id` vào `mod_hvndns_templates` cho user custom templates |
| **SPEC.md** | Section 14 (Module Settings) → thay bảng settings cũ (17 items) bằng reference tới SETTINGS.md (96 items). Thêm `fetch_from_ns_on_load` vào flow DNS Editor |
| **WIREFRAME.md** | AD-12 Notification Settings → mở rộng thêm tab cho tất cả nhóm settings. Thêm wireframe trang Settings đầy đủ |
| **EPICS.md** | Thêm issues cho: Record Permissions UI, Domain Policy hooks (pre-registrar, on-transfer), Client Notification email, NS check logic, Cache strategy |
| **API_REFERENCE.md** | Thêm endpoint GET/POST settings cho Admin Ajax API |
| **AGENT.md** | Thêm SETTINGS.md vào danh sách tài liệu tham chiếu |
| **TEST_PLAN.md** | Thêm test cases cho: settings validation, permission enforcement, NS check, rate limit, cache TTL |

---

> **Tài liệu này là phiên bản sống (living document)**. Cập nhật khi thêm/bớt settings.

## Changelog
| Ngày | Thay đổi | Người thực hiện |
|------|----------|-----------------|
| 26/02/2026 | Thay đổi cài đặt DDNS & DNSSEC, bổ sung License & Upsell (111 settings) | — |
| 25/02/2026 | Khởi tạo v1.0 — 96 settings từ legacy analysis + thiết kế mới | — |
