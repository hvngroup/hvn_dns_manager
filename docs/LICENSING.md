# MJ - DirectAdmin DNS Manager
## LICENSING.md — License & Monetization Strategy

> **Phiên bản**: 2.0  
> **Ngày tạo**: 26/02/2026  
> **Dành cho**: Developer, Product Owner, Sales Team  
> **License Server**: WHMCS Software Licensing Addon ($99.95 one-time)  

---

## Mục lục

1. [Mô hình Kinh doanh 2 Tầng](#1-mô-hình-kinh-doanh-2-tầng)
2. [Tầng 1 — License Module (Bán cho Reseller)](#2-tầng-1--license-module)
3. [Tầng 2 — Gói Dịch vụ Client (Bán cho End-user)](#3-tầng-2--gói-dịch-vụ-client)
4. [WHMCS Product Structure — Cấu hình bán hàng](#4-whmcs-product-structure)
5. [License System — Kiến trúc & Tích hợp](#5-license-system)
6. [Feature Gating — Logic Khóa/Mở tính năng](#6-feature-gating)
7. [Luồng Hoạt động Chi tiết](#7-luồng-hoạt-động)
8. [Client Area — Upsell & Upgrade](#8-client-area--upsell)
9. [Admin Area — Cấu hình Gói dịch vụ](#9-admin-area)
10. [Database & Settings bổ sung](#10-database--settings-bổ-sung)
11. [Tác động tới các Tài liệu khác](#11-tác-động-tài-liệu)

---

## 1. Mô hình Kinh doanh 2 Tầng

### 1.1. Tổng quan

```
┌─────────────────────────────────────────────────────────────────────────┐
│                                                                         │
│   TẦNG 1 — BÁN MODULE (License)                                       │
│   ─────────────────────────────                                        │
│   Người bán:  HVN Group                                                │
│   Người mua:  Nhà cung cấp Hosting / Registrar / ISP (= "Reseller")   │
│   Sản phẩm:   Module HVN DNS Manager (BẢN ĐẦY ĐỦ — tất cả tính năng)│
│   License:    WHMCS Software Licensing Addon                           │
│   Thanh toán: Annually / Lifetime                                      │
│                                                                         │
│   → License bao gồm 100% tính năng (DNSSEC, DDNS, SSL, v.v.)         │
│   → KHÔNG tách add-on ở tầng này                                      │
│   → Reseller toàn quyền quyết định bán gói nào cho client của họ      │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                                    │  Reseller cài module lên WHMCS của họ
                                    │  rồi BÁN DỊCH VỤ cho khách hàng cuối
                                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                                                                         │
│   TẦNG 2 — BÁN DỊCH VỤ (Client Product)                               │
│   ──────────────────────────────────────                                │
│   Người bán:  Reseller (hoặc chính HVN Group)                         │
│   Người mua:  Khách hàng cuối (end-user sở hữu domain)                │
│   Sản phẩm:   Gói DNS Management — phân tầng theo tính năng           │
│   Billing:    WHMCS Product + Product Addons + Configurable Options    │
│   Thanh toán: Monthly / Annually                                       │
│                                                                         │
│   Gói cơ bản (DNS Basic):  DNS Editor, Redirect, Email, Templates     │
│   Gói nâng cao (DNS Pro):  + Auto-SSL + nâng limit records            │
│   Add-on trả phí riêng:    DNSSEC ($X/tháng), Dynamic DNS ($X/tháng) │
│                                                                         │
│   → DNSSEC và Dynamic DNS là ADD-ON mà CLIENT mua thêm                │
│   → Reseller tự định giá, tự tạo gói trên WHMCS của họ               │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

### 1.2. Sơ đồ mối quan hệ

```
┌────────────┐                ┌──────────────────┐               ┌──────────────┐
│  HVN Group  │───License────▶│  Reseller A       │───Gói DNS───▶│ Client cuối  │
│  (Phát triển│   (Tầng 1)    │  (Hosting Company)│   (Tầng 2)   │ (End-user)   │
│   module)   │               │                    │               │              │
│             │               │  Cài module HVN    │               │ Mua gói DNS  │
│             │               │  DNS Manager lên   │               │ Basic $2/th  │
│             │               │  WHMCS của họ      │               │              │
│             │               │                    │               │ Mua thêm     │
│             │               │  Tự tạo gói bán:   │               │ DNSSEC $1/th │
│             │               │  DNS Basic $2/th   │               │              │
│             │               │  DNS Pro   $5/th   │               │ Mua thêm     │
│             │               │  DNSSEC    $1/th   │               │ DDNS   $1/th │
│             │               │  DDNS      $1/th   │               │              │
└────────────┘                └──────────────────┘               └──────────────┘

Tương tự cho Reseller B, C, D...
Mỗi Reseller tự định giá, tự marketing.
HVN chỉ bán LICENSE module (full features).
```

### 1.3. Quy tắc quan trọng

```
✅ HVN bán LICENSE cho Reseller        → 1 sản phẩm duy nhất (full features)
✅ Reseller bán GÓI DỊCH VỤ cho Client → Tùy ý phân tầng / định giá
✅ Module hỗ trợ SẴN cơ chế phân gói   → Quota Plans + Product Addons
✅ DNSSEC / DDNS = tính năng trả phí    → Client mua add-on qua WHMCS billing

❌ HVN KHÔNG bán DNSSEC/DDNS add-on riêng ở tầng license
❌ HVN KHÔNG can thiệp vào giá bán của Reseller
❌ Module KHÔNG hardcode giá tiền — Reseller tự set trên WHMCS
```

---

## 2. Tầng 1 — License Module

### 2.1. Sản phẩm License

| Thông tin | Giá trị |
|-----------|---------|
| Tên sản phẩm | HVN DNS Manager — License |
| Bao gồm | 100% tính năng module (DNS, DNSSEC, DDNS, SSL, Redirect, Email, v.v.) |
| Giới hạn | 1 license = 1 WHMCS installation (bind domain + IP) |
| Billing | Annually ($XX/year) hoặc Lifetime ($XXX one-time) |
| Support & Updates | Included năm đầu. Sau đó cần gia hạn support riêng |
| License Server | WHMCS HVN Group + Software Licensing Addon |
| Delivery | Download module files từ Client Area HVN sau khi thanh toán |

### 2.2. Cấu hình trên WHMCS HVN (License Server)

```
Setup > Products/Services > Create New Product

Tab Details:
  Product Type:      Other
  Product Group:     HVN Software Products
  Product Name:      HVN DNS Manager — License
  Description:       Module quản lý DNS bất đồng bộ cho WHMCS + DirectAdmin.
                     Bao gồm tất cả tính năng. Không giới hạn số domain/client.

Tab Pricing:
  Payment Type:      Recurring
  Annually:          $XX.00/year
  Biennially:        $XX.00/2years (giảm giá)
  
Tab Module Settings:
  Module Name:       Software Licensing
  Key Prefix:        mj_dns-
  Key Length:         16
  Allow Reissue:     ✅ (cho phép Reseller đổi domain/IP khi migrate server)
  Allow Domain Conflict:  ❌ (1 license = 1 domain WHMCS duy nhất)
  Allow IP Conflict:      ❌ (1 license = 1 IP server duy nhất)
  Support/Updates Addon:  [HVN DNS Manager — Support & Updates]

Product Addon:
  Name:              HVN DNS Manager — Support & Updates
  Description:       Nhận bản cập nhật module + hỗ trợ kỹ thuật qua ticket
  Billing:           Annually ($XX/year)
  Show on Order:     ✅
  Note:              Năm đầu miễn phí (included với license)
```

### 2.3. License Validation — Cách hoạt động

```
Module cài trên WHMCS Reseller "call home" mỗi 24h:

┌─────────────────────────┐         ┌──────────────────────────────┐
│  WHMCS Reseller A        │         │  WHMCS HVN (License Server)  │
│                           │         │                               │
│  Module HVN DNS Manager   │  HTTPS  │  Software Licensing Addon     │
│  license_key: mj_dns-XXX │────────▶│                               │
│  domain: reseller-a.com  │         │  Verify:                      │
│  ip: 103.xx.xx.xx        │         │  ├─ Key exists? ✅             │
│                           │◀────────│  ├─ Status Active? ✅          │
│  Response:                │         │  ├─ Domain match? ✅           │
│  status = Active          │         │  ├─ IP match? ✅               │
│  localkey = encrypted...  │         │  └─ Support active? ✅         │
│                           │         │                               │
│  → Module hoạt động ✅    │         │  Return: Active + local key   │
└─────────────────────────┘         └──────────────────────────────┘

Offline (HVN server down):
  → Local key cache hợp lệ 15 ngày
  → Module vẫn chạy bình thường
  → Sau 15 ngày không check được → Grace period 7 ngày (có cảnh báo)
  → Sau 22 ngày → Module ngưng hoạt động
```

---

## 3. Tầng 2 — Gói Dịch vụ Client

### 3.1. Bảng phân tầng dịch vụ gợi ý

> Đây là **GỢI Ý** cho Reseller. Reseller tự tạo gói và định giá trên WHMCS của họ.
> Module cung cấp cơ chế Quota Plans + Feature Flags để hỗ trợ phân tầng.

```
┌─────────────────────────┬────────────┬────────────┬──────────────┐
│ Tính năng               │ DNS Basic  │ DNS Pro    │ DNS Business │
│                         │ (Giá thấp) │ (Giá vừa) │ (Giá cao)    │
├─────────────────────────┼────────────┼────────────┼──────────────┤
│ DNS Record Editor       │     ✅     │     ✅     │      ✅      │
│ Số records tối đa       │     20     │     50     │   Unlimited  │
│ Số subdomains           │     10     │     20     │   Unlimited  │
│ Sync Tracker            │     ✅     │     ✅     │      ✅      │
│ DNS Templates           │     ✅     │     ✅     │      ✅      │
│ URL Redirect (301/302)  │     2      │     5      │   Unlimited  │
│ Masked Redirect         │     ❌     │     ✅     │      ✅      │
│ Email Forwarding        │     2      │     5      │      20      │
│ Email Catch-all         │     ❌     │     ✅     │      ✅      │
│ Auto-SSL (Let's Encrypt)│     ❌     │     ✅     │      ✅      │
├─────────────────────────┼────────────┼────────────┼──────────────┤
│ 🔒 DNSSEC Management    │     ❌     │     ❌     │      ✅      │
│    (hoặc mua add-on)    │  Add-on $X │  Add-on $X │   Included   │
├─────────────────────────┼────────────┼────────────┼──────────────┤
│ 🔒 Dynamic DNS          │     ❌     │     ❌     │      ✅      │
│    (hoặc mua add-on)    │  Add-on $X │  Add-on $X │   Included   │
│    Số DDNS tokens        │     —      │     —      │      5       │
└─────────────────────────┴────────────┴────────────┴──────────────┘

Giá gợi ý (Reseller tự set):
  DNS Basic:    20,000₫/tháng   hoặc  200,000₫/năm
  DNS Pro:      50,000₫/tháng   hoặc  500,000₫/năm
  DNS Business: 100,000₫/tháng  hoặc 1,000,000₫/năm
  Add-on DNSSEC:   20,000₫/tháng
  Add-on DDNS:     20,000₫/tháng
```

### 3.2. Client mua dịch vụ — 3 cách

```
CÁCH 1: Mua gói đã bao gồm tính năng
  Client mua "DNS Business" → tự động có DNSSEC + DDNS
  → Module đọc Quota Plan gắn với Product → unlock features

CÁCH 2: Mua add-on riêng lẻ
  Client đang dùng "DNS Basic" → muốn thêm DNSSEC
  → Mua Product Addon "DNSSEC Add-on" ($X/tháng) trên WHMCS
  → Module detect addon active → unlock DNSSEC cho domain đó

CÁCH 3: Upgrade gói
  Client đang dùng "DNS Basic" → upgrade lên "DNS Pro"
  → WHMCS Product Upgrade flow
  → Module đọc Quota Plan mới → unlock features mới
```

---

## 4. WHMCS Product Structure

> Cấu hình trên WHMCS CỦA RESELLER (hoặc HVN khi bán trực tiếp cho client).

### 4.1. Product Group

```
Setup > Products/Services > Product Groups

Group Name:     DNS Management Services
Group Headline: Quản lý DNS chuyên nghiệp cho tên miền của bạn
```

### 4.2. Products (Gói dịch vụ)

```
── Product 1: DNS Basic ──
  Product Type:    Other
  Module:          HVN DNS Manager (addon module)
  Pricing:         Monthly / Annually
  
  Custom Fields:
    domain_name (Text, Required) — Domain cần quản lý DNS
  
  Module Settings → Quota Plan: "DNS Basic"

── Product 2: DNS Pro ──
  Product Type:    Other
  Module:          HVN DNS Manager
  Pricing:         Monthly / Annually
  Module Settings → Quota Plan: "DNS Pro"

── Product 3: DNS Business ──
  Product Type:    Other
  Module:          HVN DNS Manager
  Pricing:         Monthly / Annually
  Module Settings → Quota Plan: "DNS Business"
```

### 4.3. Product Addons (Tính năng mua thêm)

```
Setup > Products/Services > Product Addons

── Addon 1: DNSSEC Management ──
  Name:           DNSSEC Management
  Description:    Bảo mật DNS bằng chữ ký số. Tự động tạo DS Records.
  Billing:        Monthly ($X) / Annually ($X)
  Applicable:     [DNS Basic, DNS Pro]      ← Không áp cho Business (đã có sẵn)
  Show on Order:  ✅
  
  → Khi client mua addon này cho dịch vụ DNS của họ
  → Module detect: tblhostingaddons có addon "DNSSEC Management" active
  → Unlock DNSSEC cho domain thuộc dịch vụ đó

── Addon 2: Dynamic DNS ──
  Name:           Dynamic DNS (DDNS)
  Description:    Tự động cập nhật IP cho Camera, NAS, VPN Router.
  Billing:        Monthly ($X) / Annually ($X)
  Applicable:     [DNS Basic, DNS Pro]
  Show on Order:  ✅
  
  → Tương tự: detect addon active → unlock DDNS

── Addon 3: Extra DNS Records Pack ──
  Name:           Extra DNS Records (+50)
  Description:    Thêm 50 bản ghi DNS cho domain.
  Billing:        Monthly ($X)
  Applicable:     [DNS Basic, DNS Pro]
  Show on Order:  ✅
  
  → Module cộng thêm 50 vào max_records của Quota Plan
```

### 4.4. Configurable Options (Tùy chọn khi đặt hàng — thay thế cho Addon)

```
Reseller cũng có thể dùng Configurable Options thay vì Product Addons:

Setup > Products/Services > Configurable Options

Option Group: "DNS Add-on Features"
Applied Products: [DNS Basic, DNS Pro]

Option 1: "DNSSEC"
  Type: Checkbox
  Checked: +$X/month
  Unchecked: $0.00

Option 2: "Dynamic DNS"
  Type: Checkbox
  Checked: +$X/month
  Unchecked: $0.00

Option 3: "Extra Records"
  Type: Dropdown
  Values:
    - Included (default, $0.00)
    - +50 Records ($X/month)
    - +100 Records ($X/month)
    - Unlimited ($X/month)
```

### 4.5. Mapping — Module đọc WHMCS Product config như thế nào

```php
/**
 * Xác định tính năng nào client được dùng
 * dựa trên WHMCS Product + Addons + Configurable Options
 */
class ClientFeatureResolver
{
    /**
     * Kiểm tra client có quyền dùng DNSSEC cho domain này không
     * 
     * @param int $serviceId  WHMCS hosting service ID (tblhosting.id)
     * @return bool
     */
    public function canUseDnssec(int $serviceId): bool
    {
        // 1. Kiểm tra Quota Plan gắn với Product
        $domain = Domain::where('whmcs_service_id', $serviceId)->first();
        if ($domain?->quotaPlan?->dnssec_enabled) {
            return true; // Gói đã bao gồm (VD: DNS Business)
        }
        
        // 2. Kiểm tra Product Addon "DNSSEC Management" active
        $hasAddon = $this->hasActiveAddon($serviceId, 'DNSSEC Management');
        if ($hasAddon) {
            return true; // Client đã mua addon riêng
        }
        
        // 3. Kiểm tra Configurable Option "DNSSEC" enabled
        $hasOption = $this->hasConfigOption($serviceId, 'DNSSEC', checked: true);
        if ($hasOption) {
            return true; // Client đã chọn option khi đặt hàng
        }
        
        return false;
    }
    
    /**
     * Kiểm tra Product Addon đang active
     */
    private function hasActiveAddon(int $serviceId, string $addonName): bool
    {
        // Query: tblhostingaddons 
        //   WHERE hostingid = $serviceId 
        //   AND name LIKE '%$addonName%' 
        //   AND status = 'Active'
        return \WHMCS\Database\Capsule::table('tblhostingaddons')
            ->where('hostingid', $serviceId)
            ->where('name', 'like', "%{$addonName}%")
            ->where('status', 'Active')
            ->exists();
    }
    
    /**
     * Kiểm tra Configurable Option
     */
    private function hasConfigOption(int $serviceId, string $optionName, bool $checked): bool
    {
        // Query: tblhostingconfigoptions 
        //   JOIN tblproductconfigoptions ON optionid
        //   WHERE relid = $serviceId
        //   AND optionname LIKE '%$optionName%'
        //   AND qty > 0 (checked = true)
        return \WHMCS\Database\Capsule::table('tblhostingconfigoptions')
            ->join('tblproductconfigoptions', 'tblhostingconfigoptions.configid', '=', 'tblproductconfigoptions.id')
            ->where('tblhostingconfigoptions.relid', $serviceId)
            ->where('tblproductconfigoptions.optionname', 'like', "%{$optionName}%")
            ->where('tblhostingconfigoptions.qty', '>', 0)
            ->exists();
    }
    
    /**
     * Tương tự cho DDNS
     */
    public function canUseDdns(int $serviceId): bool
    {
        $domain = Domain::where('whmcs_service_id', $serviceId)->first();
        if ($domain?->quotaPlan?->ddns_enabled) return true;
        if ($this->hasActiveAddon($serviceId, 'Dynamic DNS')) return true;
        if ($this->hasConfigOption($serviceId, 'Dynamic DNS', checked: true)) return true;
        return false;
    }
    
    /**
     * Lấy max records (Quota Plan + Extra Records addon)
     */
    public function getMaxRecords(int $serviceId): int
    {
        $domain = Domain::where('whmcs_service_id', $serviceId)->first();
        $baseLimit = $domain?->quotaPlan?->max_records ?? 50;
        
        // Cộng thêm Extra Records addon
        $extraPack = $this->getConfigOptionValue($serviceId, 'Extra Records');
        // "Included" = 0, "+50 Records" = 50, "+100 Records" = 100, "Unlimited" = 0 (unlimited)
        
        if ($baseLimit === 0) return 0; // Đã unlimited từ Quota Plan
        if ($extraPack === 0 && str_contains($extraLabel, 'Unlimited')) return 0;
        
        return $baseLimit + (int) $extraPack;
    }
}
```

---

## 5. License System — Kiến trúc & Tích hợp

### 5.1. File Structure

```
app/License/
├── LicenseChecker.php            ← Check license (local + remote call home)
├── LicenseResponse.php           ← Response object từ license server
├── LicenseException.php          ← Exception khi license invalid
│
app/Services/
├── ClientFeatureResolver.php     ← Xác định features per-client per-domain
│                                    (Quota Plan + WHMCS Addons + Config Options)
```

**Phân tách rõ ràng**:
- `LicenseChecker` → Tầng 1: Module có license hợp lệ không? (HVN → Reseller)
- `ClientFeatureResolver` → Tầng 2: Client cụ thể có quyền dùng DNSSEC/DDNS không? (Reseller → End-user)

### 5.2. LicenseChecker Class

```php
<?php

namespace HvnGroup\DnsManager\License;

/**
 * Tích hợp WHMCS Software Licensing Addon.
 * Module "call home" về license server HVN để verify.
 * 
 * License ở tầng này chỉ kiểm tra:
 * - Module có quyền chạy trên WHMCS này không?
 * - License còn Active không?
 * - Support/Updates còn hạn không?
 * 
 * KHÔNG kiểm tra per-feature (DNSSEC/DDNS).
 * Per-feature check nằm ở ClientFeatureResolver.
 */
class LicenseChecker
{
    private string $licenseServerUrl;
    private string $secretKey;
    private int $localKeyGraceDays = 15;
    private int $checkInterval = 86400; // 24 giờ

    public function __construct()
    {
        $this->licenseServerUrl = SettingsHelper::get(
            'license_server_url',
            'https://billing.hvngroup.vn/modules/servers/licensing/verify.php'
        );
        $this->secretKey = SettingsHelper::get('license_secret_key', '');
    }

    /**
     * Kiểm tra license module
     * 
     * @return LicenseResponse
     *   ->isValid()         Module có quyền chạy
     *   ->isSuspended()     License bị tạm ngưng (nợ phí)
     *   ->isExpired()       License hết hạn
     *   ->hasSupport()      Có quyền nhận updates + support
     */
    public function check(string $licenseKey, string $localKey = ''): LicenseResponse
    {
        // 1. Thử local key trước (nhanh, offline)
        if (!empty($localKey)) {
            $localResult = $this->validateLocalKey($localKey, $licenseKey);
            if ($localResult->isValid() && !$localResult->isExpiringSoon()) {
                return $localResult;
            }
        }

        // 2. Remote check (call home tới HVN)
        $remoteResult = $this->remoteCheck($licenseKey);

        // 3. Remote thất bại (HVN server down) → fallback grace period
        if (!$remoteResult->isValid() && !empty($localKey)) {
            $graceResult = $this->validateLocalKey($localKey, $licenseKey, useGracePeriod: true);
            if ($graceResult->isValid()) {
                return $graceResult;
            }
        }

        return $remoteResult;
    }

    /**
     * Remote check tới license server HVN
     */
    private function remoteCheck(string $licenseKey): LicenseResponse
    {
        $postData = [
            'licensekey' => $licenseKey,
            'domain'     => $_SERVER['SERVER_NAME'] ?? '',
            'ip'         => $this->getServerIp(),
            'dir'        => dirname(__DIR__, 2),
        ];

        try {
            $ch = curl_init($this->licenseServerUrl);
            curl_setopt_array($ch, [
                CURLOPT_POST           => true,
                CURLOPT_POSTFIELDS     => http_build_query($postData),
                CURLOPT_RETURNTRANSFER => true,
                CURLOPT_TIMEOUT        => 10,
                CURLOPT_SSL_VERIFYPEER => true,
            ]);
            $response = curl_exec($ch);
            $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
            curl_close($ch);

            if ($httpCode !== 200 || empty($response)) {
                return LicenseResponse::connectionFailed();
            }

            return LicenseResponse::fromRemote($response, $this->secretKey);
        } catch (\Exception $e) {
            return LicenseResponse::connectionFailed();
        }
    }

    private function validateLocalKey(string $localKey, string $licenseKey, bool $useGracePeriod = false): LicenseResponse
    {
        // Decrypt + validate local key
        // (Dựa trên check_sample_code.php từ WHMCS Licensing Addon)
    }

    private function getServerIp(): string
    {
        return $_SERVER['SERVER_ADDR'] ?? gethostbyname(gethostname());
    }
}
```

### 5.3. LicenseResponse Object

```php
<?php

namespace HvnGroup\DnsManager\License;

class LicenseResponse
{
    public string $status;        // 'Active', 'Suspended', 'Expired', 'Invalid', 'ConnectionFailed'
    public string $licenseKey;
    public string $registeredDomain;
    public string $validUntil;
    public string $localKey;      // Encrypted local key mới để cache
    public bool   $supportActive; // Support & Updates addon active?
    public ?string $message;

    public function isValid(): bool
    {
        return $this->status === 'Active';
    }

    public function isSuspended(): bool
    {
        return $this->status === 'Suspended';
    }

    public function isExpired(): bool
    {
        return $this->status === 'Expired';
    }

    public function hasSupport(): bool
    {
        return $this->supportActive;
    }

    public function hasLocalKey(): bool
    {
        return !empty($this->localKey);
    }

    public function isExpiringSoon(): bool
    {
        $expiry = strtotime($this->validUntil);
        return ($expiry - time()) < (3 * 86400);
    }

    public static function connectionFailed(): self
    {
        $r = new self();
        $r->status = 'ConnectionFailed';
        $r->message = 'Không thể kết nối tới license server.';
        return $r;
    }
}
```

---

## 6. Feature Gating — Logic Khóa/Mở tính năng

### 6.1. 3 lớp Gating (Thiết kế đúng)

```
LỚP 1: MODULE LICENSE (LicenseChecker)
  │     Câu hỏi: "Module có quyền chạy trên WHMCS này không?"
  │     Ai quyết định: HVN Group (bán license)
  │     → Invalid / Expired → BLOCK TOÀN BỘ MODULE
  │     → Active → cho phép, kiểm tiếp Lớp 2
  │
  ▼
LỚP 2: ADMIN SETTINGS (SettingsHelper) — 3 trạng thái
  │     Câu hỏi: "Reseller muốn xử lý tính năng này thế nào?"
  │     Ai quyết định: Reseller (admin WHMCS)
  │
  │     dnssec_mode / ddns_mode có 3 giá trị:
  │
  │     "off"   → TẮT hoàn toàn. Không ai dùng được.
  │               Tab ẩn khỏi Client Area + Admin Settings hiện "Disabled".
  │               Dùng khi: Reseller không muốn cung cấp tính năng này,
  │               hoặc DA server chưa hỗ trợ DNSSEC.
  │
  │     "free"  → BẬT MIỄN PHÍ cho TẤT CẢ client.
  │               SKIP Lớp 3 (không check billing).
  │               Mọi client đều thấy tab + dùng được ngay.
  │               Dùng khi: Reseller muốn cung cấp miễn phí như giá trị
  │               gia tăng, không thu phí riêng.
  │
  │     "paid"  → BẬT nhưng CLIENT PHẢI MUA addon/nâng gói.
  │               Chuyển sang Lớp 3 kiểm tra billing.
  │               Dùng khi: Reseller muốn bán DNSSEC/DDNS như premium.
  │
  ▼
LỚP 3: CLIENT FEATURE (ClientFeatureResolver) — Chỉ chạy khi mode = "paid"
       Câu hỏi: "Client CỤ THỂ này đã MUA tính năng này chưa?"
       Ai quyết định: Billing system (WHMCS Product/Addon/ConfigOption)
       
       Kiểm tra theo thứ tự:
       (a) Quota Plan gắn với Product → dnssec_enabled / ddns_enabled?
       (b) Product Addon "DNSSEC Management" active?
       (c) Configurable Option "DNSSEC" checked?
       → BẤT KỲ nguồn nào = true → CLIENT ĐƯỢC DÙNG

       Nếu tất cả = false → CLIENT BỊ KHÓA (hiện Upsell)
```

### 6.2. Decision Matrix — DNSSEC

| Lớp 1: License | Lớp 2: `dnssec_mode` | Lớp 3: WHMCS Billing | Kết quả | UI |
|---------------|---------------------|----------------------|---------|-----|
| ❌ Invalid | — | — | ❌ Module không chạy | Trang License Invalid |
| ✅ Active | `"off"` | — | ❌ Tắt hoàn toàn | Tab DNSSEC ẩn |
| ✅ Active | `"free"` | *(skip — không check)* | ✅ **DNSSEC miễn phí** | Tab hiện, dùng ngay |
| ✅ Active | `"paid"` | ✅ Quota Plan có | ✅ **DNSSEC hoạt động** | Tab hiện (gói đã bao gồm) |
| ✅ Active | `"paid"` | ✅ Addon active | ✅ **DNSSEC hoạt động** | Tab hiện (mua addon) |
| ✅ Active | `"paid"` | ✅ ConfigOption checked | ✅ **DNSSEC hoạt động** | Tab hiện (chọn option) |
| ✅ Active | `"paid"` | ❌ Chưa mua gì | ❌ Chưa mua | Tab hiện 🔒 + Upsell card |

Tương tự cho DDNS với `ddns_mode`.

### 6.3. FeatureGate Class (Viết lại đúng)

```php
<?php

namespace HvnGroup\DnsManager\Services;

/**
 * Feature Gating — 3 lớp kiểm tra
 * 
 * Lớp 1: License → LicenseChecker (module level)
 * Lớp 2: Admin Settings → SettingsHelper (reseller level)
 * Lớp 3: Client Feature → ClientFeatureResolver (end-user level)
 */
class FeatureGate
{
    private static ?LicenseResponse $license = null;
    private static ?ClientFeatureResolver $resolver = null;

    // ── Lớp 1: Module License ──

    public static function isModuleLicensed(): bool
    {
        return self::getLicense()->isValid();
    }

    private static function getLicense(): LicenseResponse
    {
        if (self::$license === null) {
            $checker = new LicenseChecker();
            self::$license = $checker->check(
                SettingsHelper::get('license_key', ''),
                SettingsHelper::get('license_local_key', '')
            );
            if (self::$license->hasLocalKey()) {
                SettingsHelper::set('license_local_key', self::$license->localKey);
            }
        }
        return self::$license;
    }

    // ── Lớp 2: Admin Settings — 3 trạng thái (off / free / paid) ──

    /**
     * Lấy mode cho DNSSEC: 'off', 'free', 'paid'
     */
    public static function getDnssecMode(): string
    {
        if (!self::isModuleLicensed()) return 'off';
        return SettingsHelper::get('dnssec_mode', 'off');
    }

    /**
     * Lấy mode cho DDNS: 'off', 'free', 'paid'
     */
    public static function getDdnsMode(): string
    {
        if (!self::isModuleLicensed()) return 'off';
        return SettingsHelper::get('ddns_mode', 'off');
    }

    // ── Lớp 3: Client Feature (per-service) — Chỉ khi mode = 'paid' ──

    /**
     * Client cụ thể có quyền dùng DNSSEC?
     * 
     * Logic:
     *   mode = 'off'  → false (tắt hoàn toàn)
     *   mode = 'free'  → true (miễn phí cho tất cả)
     *   mode = 'paid' → check billing (Quota Plan + Addon + ConfigOption)
     * 
     * @param int $serviceId  WHMCS tblhosting.id
     */
    public static function canClientUseDnssec(int $serviceId): bool
    {
        $mode = self::getDnssecMode();
        
        if ($mode === 'off') return false;
        if ($mode === 'free') return true; // Miễn phí → skip Lớp 3
        
        // mode === 'paid' → check billing
        return self::getResolver()->canUseDnssec($serviceId);
    }

    /**
     * Client cụ thể có quyền dùng DDNS?
     */
    public static function canClientUseDdns(int $serviceId): bool
    {
        $mode = self::getDdnsMode();
        
        if ($mode === 'off') return false;
        if ($mode === 'free') return true;
        
        return self::getResolver()->canUseDdns($serviceId);
    }

    /**
     * Lý do tại sao tính năng bị khóa (cho UI hiển thị đúng)
     * 
     * @return string|null  null = không bị khóa
     *   'module_unlicensed' → Module không có license
     *   'feature_off'       → Admin tắt hoàn toàn → ẩn tab
     *   'not_purchased'     → mode=paid nhưng client chưa mua → hiện upsell
     */
    public static function getDnssecLockReason(int $serviceId): ?string
    {
        if (!self::isModuleLicensed()) return 'module_unlicensed';
        
        $mode = self::getDnssecMode();
        if ($mode === 'off') return 'feature_off';
        if ($mode === 'free') return null; // Không bị khóa
        
        // mode === 'paid'
        if (!self::getResolver()->canUseDnssec($serviceId)) {
            return 'not_purchased';
        }
        return null; // Đã mua → không bị khóa
    }

    public static function getDdnsLockReason(int $serviceId): ?string
    {
        if (!self::isModuleLicensed()) return 'module_unlicensed';
        
        $mode = self::getDdnsMode();
        if ($mode === 'off') return 'feature_off';
        if ($mode === 'free') return null;
        
        if (!self::getResolver()->canUseDdns($serviceId)) {
            return 'not_purchased';
        }
        return null;
    }

    private static function getResolver(): ClientFeatureResolver
    {
        if (self::$resolver === null) {
            self::$resolver = new ClientFeatureResolver();
        }
        return self::$resolver;
    }

    private static function maskKey(string $key): string
    {
        if (strlen($key) <= 10) return $key;
        return substr($key, 0, 8) . '••••••' . substr($key, -4);
    }
}
```

---

## 7. Luồng Hoạt động Chi tiết

### 7.1. FLOW: Reseller mua License từ HVN

```
Reseller                    WHMCS HVN (License Server)
────────                    ──────────────────────────
    │                              │
    │  1. Đặt hàng:               │
    │     HVN DNS Manager License │
    │     + Support & Updates      │
    │─────────────────────────────▶│
    │                              │
    │                              │  2. Thanh toán OK
    │                              │     → Generate key: mj_dns-XXXXXXXX
    │                              │     → Email key + download link
    │                              │
    │  3. Download module files    │
    │◀─────────────────────────────│
    │                              │
    │  4. Upload lên WHMCS Reseller│
    │  5. Activate module          │
    │  6. Nhập license key         │
    │  7. Module call home → Active│
    │                              │
    │  8. Tạo gói bán cho client:  │
    │     DNS Basic / Pro / Biz    │
    │     + DNSSEC addon           │
    │     + DDNS addon             │
    │                              │
    │  → Reseller sẵn sàng bán! ✅ │
```

### 7.2. FLOW: Client mua gói DNS + mua thêm DNSSEC

```
Client (End-user)        WHMCS Reseller                Module HVN DNS
─────────────────        ──────────────                ──────────────
    │                         │                              │
    │  1. Đặt hàng:           │                              │
    │     DNS Basic            │                              │
    │     domain: example.com  │                              │
    │─────────────────────────▶│                              │
    │                         │                              │
    │                         │  2. Thanh toán OK             │
    │                         │     → Create Service          │
    │                         │     → Trigger hook             │
    │                         │─────────────────────────────▶│
    │                         │                              │
    │                         │                              │  3. AfterModuleCreate:
    │                         │                              │     Tạo domain
    │                         │                              │     Áp Quota Plan "Basic"
    │                         │                              │     Tạo zone trên DA
    │                         │                              │
    │  4. Mở DNS Editor        │                              │
    │     Tab DNSSEC: 🔒       │                              │
    │     "Tính năng cần mua   │                              │
    │      thêm. Nâng cấp →"   │                              │
    │                         │                              │
    │  5. Click "Nâng cấp"    │                              │
    │     → WHMCS order page   │                              │
    │─────────────────────────▶│                              │
    │                         │                              │
    │  6. Mua addon:           │                              │
    │     "DNSSEC Management"  │                              │
    │     $20,000₫/tháng       │                              │
    │─────────────────────────▶│                              │
    │                         │                              │
    │                         │  7. Addon activated            │
    │                         │     tblhostingaddons:          │
    │                         │     status = Active            │
    │                         │                              │
    │  8. Quay lại DNS Editor  │                              │
    │     Tab DNSSEC: ✅        │                              │
    │     Nút "Bật DNSSEC"     │                              │
    │     xuất hiện!            │                              │
    │                         │                              │
    │  9. Bật DNSSEC           │                              │
    │─────────────────────────────────────────────────────────▶│
    │                         │                              │
    │                         │                              │  10. FeatureGate check:
    │                         │                              │      Lớp 1: License ✅
    │                         │                              │      Lớp 2: Settings ✅
    │                         │                              │      Lớp 3: Addon active ✅
    │                         │                              │      → Dispatch ENABLE_DNSSEC
    │                         │                              │
    │  11. DNSSEC activated! ✅ │                              │
    │      DS Records hiển thị │                              │
```

### 7.3. FLOW: Client hủy addon DNSSEC

```
Client hủy addon "DNSSEC Management" (qua WHMCS):

1. WHMCS set addon status = 'Cancelled' / 'Terminated'
2. Lần tiếp theo client mở DNS Editor:
   → FeatureGate::canClientUseDnssec() = false
   → Tab DNSSEC hiện trạng thái locked + thông báo
3. DNSSEC đã enabled trên DA → KHÔNG tự disable
   (Zone vẫn signed, bảo vệ domain)
4. Client muốn tắt DNSSEC → phải mua lại addon trước
5. RESIGN_ZONE jobs vẫn chạy trong 30 ngày (grace)
   sau đó dừng re-sign (zone vẫn signed nhưng có thể stale)
```

---

## 8. Client Area — Upsell & Upgrade

### 8.1. UI theo 3 trạng thái

```
Smarty template logic cho tab DNSSEC / DDNS:

{* Lấy lock reason từ Controller *}
{assign var="dnssecLock" value=$feature_locks.dnssec}
{assign var="ddnsLock" value=$feature_locks.ddns}

{* ── Trạng thái 1: mode = "off" (feature_off) ── *}
{* Tab ẨN HOÀN TOÀN — không hiện gì *}

{* ── Trạng thái 2: mode = "free" (lock = null) ── *}
{* Tab HIỆN bình thường — client dùng ngay, không upsell *}

{* ── Trạng thái 3: mode = "paid" + đã mua (lock = null) ── *}
{* Tab HIỆN bình thường — giống trạng thái 2 *}

{* ── Trạng thái 4: mode = "paid" + chưa mua (not_purchased) ── *}
{* Tab HIỆN với 🔒 + Upsell Card bên trong *}
```

### 8.2. Tab Navigation — Hiển thị theo lock reason

```
┌───────────────────────────────────────────────────────────────────┐
│                                                                   │
│  Khi dnssec_mode = "off":                                        │
│  [DNS Records] [Redirects] [Email] [Templates]                   │
│  (Tab DNSSEC không hiện)                                         │
│                                                                   │
│  Khi dnssec_mode = "free" HOẶC ("paid" + đã mua):              │
│  [DNS Records] [Redirects] [Email] [DNSSEC] [Templates]         │
│  (Tab DNSSEC hiện bình thường, click vào dùng ngay)              │
│                                                                   │
│  Khi dnssec_mode = "paid" + CHƯA mua:                           │
│  [DNS Records] [Redirects] [Email] [🔒 DNSSEC] [Templates]      │
│  (Tab hiện với icon khóa, click vào thấy Upsell Card)           │
│                                                                   │
└───────────────────────────────────────────────────────────────────┘

Tương tự cho DDNS tab.
```

### 8.3. Upsell Card — Chỉ hiện khi `not_purchased`

```
┌──────────────────────────────────────────────────────────────────┐
│ [DNS Records] [Redirects] [Email] [🔒 DNSSEC] [🔒 DDNS] [Tmpl] │
│                                    ════════                       │
│                                                                   │
│  ┌────────────────────────────────────────────────────────────┐  │
│  │                                                            │  │
│  │         🔒 DNSSEC — Bảo mật DNS Nâng cao                  │  │
│  │                                                            │  │
│  │   {$upsell_dnssec_description}                             │  │
│  │   (Nội dung cấu hình bởi Reseller trong Settings)          │  │
│  │                                                            │  │
│  │   ✓ Tự động tạo và quản lý DS Records                     │  │
│  │   ✓ Auto re-sign zone khi thay đổi records                │  │
│  │   ✓ Hướng dẫn cấu hình tại nhà đăng ký                   │  │
│  │                                                            │  │
│  │   {if $upsell_dnssec_price}                                │  │
│  │     Chỉ từ {$upsell_dnssec_price}/tháng                   │  │
│  │   {/if}                                                    │  │
│  │                                                            │  │
│  │   {if $upsell_dnssec_url}                                  │  │
│  │     [🛒 Kích hoạt DNSSEC]     ← Link tới WHMCS cart       │  │
│  │   {/if}                                                    │  │
│  │                                                            │  │
│  │   {if $upgrade_url}                                        │  │
│  │     Hoặc [📦 Nâng cấp gói dịch vụ]                       │  │
│  │   {/if}                                                    │  │
│  │                                                            │  │
│  └────────────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────────┘
```

### 8.4. Khi Reseller chọn mode = "free" — Không có gì đặc biệt

```
Khi dnssec_mode = "free":
  → Tab DNSSEC hiện bình thường
  → Không có 🔒 icon
  → Không có upsell card
  → Client bấm "Bật DNSSEC" → hoạt động ngay
  → Giống hệt khi mode = "paid" + đã mua
  → Reseller KHÔNG cần tạo Product Addon trên WHMCS
```

---

## 9. Admin Area — Cấu hình Gói dịch vụ

### 9.1. Admin Dashboard — License Widget

```
┌────────────────────────────────────────────┐
│  📋 License                                 │
│                                             │
│  Key:          mj_dns-A12B••••D89F          │
│  Status:       🟢 Active                    │
│  Registered:   billing.reseller-a.com       │
│  Valid Until:  2027-02-26                   │
│  Support:      ✅ Active (đến 2027-02-26)   │
│                                             │
│  [🔄 Recheck]                              │
└────────────────────────────────────────────┘
```

### 9.2. Admin Settings — Tab DNSSEC & DDNS Mode

```
Tab [DNSSEC] trong trang Settings (AD-12):

  ── Chế độ DNSSEC ──

  Chế độ hoạt động: *
  (●) Tắt (Off)
      Tính năng DNSSEC bị ẩn hoàn toàn.
      Không client nào có thể sử dụng.
      
  ( ) Miễn phí (Free)
      TẤT CẢ client được sử dụng DNSSEC miễn phí.
      Không cần mua thêm addon hay nâng gói.
      Tab DNSSEC hiện cho mọi client.
      
  ( ) Trả phí (Paid)
      Client phải mua addon hoặc sử dụng gói dịch vụ
      có bao gồm DNSSEC mới được sử dụng.
      Client chưa mua sẽ thấy trang giới thiệu + nút mua.

  ┌────────────────────────────────────────────────────┐
  │  ℹ️ Hướng dẫn:                                     │
  │  • Tắt: Dùng khi DA chưa enable DNSSEC hoặc       │
  │    không muốn cung cấp tính năng này.              │
  │  • Miễn phí: Dùng khi muốn tạo giá trị gia tăng  │
  │    cho tất cả khách hàng mà không thu phí.         │
  │  • Trả phí: Dùng khi muốn bán DNSSEC như dịch     │
  │    vụ premium. Cần tạo Product Addon trên WHMCS.   │
  └────────────────────────────────────────────────────┘

  ── Cấu hình khi chọn "Trả phí" ──
  (Phần này chỉ hiện khi chọn Paid)

  DNSSEC Auto Re-sign:
  [✓] Tự động ký lại zone sau mỗi thay đổi record

  ── Nội dung trang giới thiệu (Upsell) ──
  (Phần này chỉ hiện khi chọn Paid)

  Addon Product ID:
  [____12____]
  ℹ️ ID của Product Addon "DNSSEC" trong WHMCS

  Mô tả tính năng:
  [__Bảo vệ domain khỏi tấn công DNS Spoofing...__]
  
  Giá hiển thị:
  [__20,000₫/tháng__]


── Tương tự cho tab [DDNS] ──

  Chế độ hoạt động: *
  (●) Tắt (Off)
  ( ) Miễn phí (Free)
  ( ) Trả phí (Paid)

  (Cấu hình tương tự DNSSEC)
```

---

## 10. Database & Settings bổ sung

### 10.1. Settings mới (thêm vào SETTINGS.md)

**Nhóm License** (thay thế setting #50, #43 cũ trong SETTINGS.md):

| # | Setting Key | Type | Default | Mô tả |
|---|------------|------|---------|-------|
| 97 | `license_key` | String | `""` | License key module (mj_dns-XXXXXXXX) |
| 98 | `license_local_key` | Text | `""` | Cached encrypted local key. Auto-update mỗi remote check |
| 99 | `license_last_check` | DateTime | `""` | Thời điểm remote check gần nhất |
| 100 | `license_status` | String | `""` | Cached: Active/Suspended/Expired |
| 101 | `license_server_url` | String | `"https://billing.hvngroup.vn/modules/servers/licensing/verify.php"` | URL license server HVN |
| 102 | `license_secret_key` | String (Enc) | `""` | Secret key cho local key encryption |
| 103 | `license_check_interval` | Integer | `86400` | Khoảng cách remote check (giây). Default 24h |
| 104 | `license_grace_days` | Integer | `7` | Grace period sau khi hết hạn (ngày) |

**Nhóm Premium Features — 3 trạng thái** (THAY THẾ `enable_dnssec` và `enable_ddns` boolean cũ):

| # | Setting Key | Type | Default | Values | Mô tả |
|---|------------|------|---------|--------|-------|
| 105 | `dnssec_mode` | Select | `"off"` | `"off"`, `"free"`, `"paid"` | **Off**: Tắt hoàn toàn, tab ẩn. **Free**: Miễn phí cho tất cả client, không check billing. **Paid**: Client phải mua addon/nâng gói, hiện upsell khi chưa mua |
| 106 | `ddns_mode` | Select | `"off"` | `"off"`, `"free"`, `"paid"` | Tương tự DNSSEC. Off/Free/Paid |

**Nhóm Upsell Configuration** (chỉ áp dụng khi mode = "paid"):

| # | Setting Key | Type | Default | Mô tả |
|---|------------|------|---------|-------|
| 107 | `upsell_dnssec_addon_id` | Integer | `0` | WHMCS Product Addon ID cho DNSSEC. Chỉ cần set khi `dnssec_mode = "paid"` |
| 108 | `upsell_ddns_addon_id` | Integer | `0` | WHMCS Product Addon ID cho DDNS |
| 109 | `upsell_product_group_id` | Integer | `0` | WHMCS Product Group ID cho link "Nâng cấp gói" |
| 110 | `upsell_dnssec_description` | Text | `"Bảo vệ domain..."` | Mô tả hiện trên upsell card DNSSEC |
| 111 | `upsell_ddns_description` | Text | `"Tự động cập nhật IP..."` | Mô tả hiện trên upsell card DDNS |
| 112 | `upsell_dnssec_price_display` | String | `""` | Giá hiển thị DNSSEC (cosmetic, VD: "20,000₫/tháng") |
| 113 | `upsell_ddns_price_display` | String | `""` | Giá hiển thị DDNS (cosmetic) |

**Lưu ý quan trọng cho SETTINGS.md**: Settings #50 (`enable_dnssec` boolean) và #43 (`enable_ddns` boolean) trong SETTINGS.md cần được **THAY THẾ** bằng #105 (`dnssec_mode` select) và #106 (`ddns_mode` select). Không dùng boolean nữa vì cần 3 trạng thái.

### 10.2. Files mới / sửa

```
app/License/
├── LicenseChecker.php              ← Check license module (Tầng 1)
├── LicenseResponse.php             ← Response object
└── LicenseException.php            ← Exceptions

app/Services/
├── ClientFeatureResolver.php       ← MỚI: Check per-client features (Tầng 3)
│                                      Query WHMCS tblhostingaddons + configoptions
├── FeatureGate.php                 ← VIẾT LẠI: 3 lớp (License → Settings → Client)
└── UpsellHelper.php                ← MỚI: Build upsell URLs

templates/client/partials/
├── feature_upsell.tpl              ← Upsell card reusable
└── feature_locked_tab.tpl          ← Tab header với 🔒 icon

templates/admin/partials/
├── license_widget.tpl              ← Dashboard license info
└── license_invalid.tpl             ← Full page khi license invalid
```

---

## 11. Tác động tới các Tài liệu khác

| Tài liệu | Cần cập nhật |
|-----------|-------------|
| **AGENT.md** | Thêm LICENSING.md vào tham chiếu. Thêm rule: "DNSSEC/DDNS code PHẢI check FeatureGate 3 lớp". Thêm: ClientFeatureResolver vào danh sách Services |
| **SETTINGS.md** | Thêm 15 settings mới (#97-111). Tổng: 96 → 111 settings. Thêm nhóm "License" và nhóm "Upsell & Billing" |
| **DB_SCHEMA.md** | Không cần bảng mới (dùng `tbl_mj_dns_settings`). Ghi chú: FeatureGate query `tblhostingaddons` và `tblhostingconfigoptions` (bảng WHMCS native) |
| **SPEC.md** | Thêm Tầng 0 "License Check" trước Tầng 1 Presentation trong kiến trúc. Thêm flow: License check + Feature gating |
| **EPICS.md** | Thêm EPIC: License Integration (LicenseChecker, FeatureGate). Thêm Story: Upsell UI + ClientFeatureResolver |
| **WIREFRAME.md** | Thêm: Upsell cards (CL-06, CL-07 khi locked). Admin License Widget. License Invalid page |
| **TEST_PLAN.md** | Thêm: License check mock tests, FeatureGate 3-layer tests, ClientFeatureResolver tests (mock WHMCS tables), Upsell URL generation |
| **PROTOTYPE.md** | Mock: license = Active (luôn). FeatureGate mock: domain 1-4 có DNSSEC, domain 5-8 không có → demo cả 2 trạng thái |
| **Antigravity Rules** | Thêm rule: "DNSSEC/DDNS features PHẢI wrap trong FeatureGate::canClientUseDnssec/Ddns($serviceId)" |

---

## Phụ lục: So sánh các phiên bản

| Khía cạnh | v1.0 (sai) | v2.0 | v2.1 (hiện tại) |
|-----------|-----------|------|-----------------|
| DNSSEC/DDNS add-on bán cho ai? | Reseller (license level) | End-user (WHMCS billing) | End-user (WHMCS billing) |
| License bao gồm gì? | Core + tùy chọn add-on | Full features | Full features |
| Feature mode | Boolean on/off | Boolean on/off | **3 trạng thái: off/free/paid** |
| Reseller muốn cho free? | Không hỗ trợ | Không hỗ trợ | **`free` mode — skip billing check** |
| Setting key | `enable_dnssec` (bool) | `enable_dnssec` (bool) | **`dnssec_mode` (select: off/free/paid)** |
| UI khi feature tắt | Tab ẩn | Tab ẩn | Tab ẩn (`off`) |
| UI khi free | N/A | N/A | **Tab hiện, dùng ngay (`free`)** |
| UI khi paid + chưa mua | N/A | Upsell card | Upsell card (`paid` + `not_purchased`) |
| UI khi paid + đã mua | N/A | Tab hiện | Tab hiện (`paid` + purchased) |
| Admin Settings UI | Checkbox | Checkbox | **Radio 3 options + conditional fields** |

---

> **Tài liệu này là phiên bản sống (living document)**.

## Changelog
| Ngày | Thay đổi | Người thực hiện |
|------|----------|-----------------|
| 26/02/2026 | v1.0 — Bản đầu (SAI: DNSSEC/DDNS ở tầng license) | — |
| 26/02/2026 | v2.0 — Viết lại: 2 tầng đúng. DNSSEC/DDNS bán cho end-user qua WHMCS billing | — |
| 26/02/2026 | v2.1 — Thêm 3 trạng thái off/free/paid cho DNSSEC & DDNS. Reseller có thể cho free | — |
