# HVN - DirectAdmin DNS Manager
## API_REFERENCE.md — Tài liệu Tham chiếu API

> **Phiên bản**: 1.0  
> **Ngày tạo**: 25/02/2026  
> **Dành cho**: Backend Developer, AI Agent  
> **Tham chiếu**: SPEC.md (Section 6), DB_SCHEMA.md (bảng queue payload)  

---

## Mục lục

**Phần A — DirectAdmin API (External)**
1. [Tổng quan kết nối DA](#a1-tổng-quan-kết-nối-da)
2. [Authentication & Request Format](#a2-authentication--request-format)
3. [DNS Zone Management](#a3-dns-zone-management)
4. [DNS Record Management](#a4-dns-record-management)
5. [DNSSEC Management](#a5-dnssec-management)
6. [SSL / Let's Encrypt](#a6-ssl--lets-encrypt)
7. [Email Forwarding](#a7-email-forwarding)
8. [Error Codes & Gotchas](#a8-error-codes--gotchas)

**Phần B — Internal Ajax API (WHMCS ↔ Browser)**
9. [Tổng quan Internal API](#b1-tổng-quan-internal-api)
10. [Client Area Endpoints](#b2-client-area-endpoints)
11. [Admin Area Endpoints](#b3-admin-area-endpoints)
12. [DDNS External Endpoint](#b4-ddns-external-endpoint)
13. [Response Format chuẩn](#b5-response-format-chuẩn)
14. [Error Codes Dictionary](#b6-error-codes-dictionary)

**Phần C — REST API (Future — Phase 3)**
15. [REST API Specification](#c1-rest-api-specification)

---

# PHẦN A — DIRECTADMIN API (External)

> API giữa WHMCS Cron Worker ↔ DirectAdmin Server.  
> Chỉ được gọi từ `DAGateway` class trong Cron Worker.  
> **TUYỆT ĐỐI KHÔNG** gọi từ Controller hoặc request lifecycle của user.

---

## A1. Tổng quan kết nối DA

### Base URL

```
{protocol}://{ip_address}:{port}

Ví dụ:
https://103.45.67.10:2222
http://103.45.67.10:2222   (không khuyến nghị)
```

Lấy từ `mod_hvndns_servers`: `use_ssl` → `https/http`, `ip_address`, `port`.

### Timeout Settings

| Parameter | Giá trị | Ghi chú |
|-----------|---------|---------|
| Connect timeout | 15 giây | Thời gian chờ thiết lập kết nối TCP |
| Request timeout | 30 giây | Thời gian chờ response hoàn chỉnh |
| SSL verify | `true` (production) | Có thể tắt cho self-signed cert nội bộ |

### GuzzleHTTP Configuration

```php
$client = new \GuzzleHttp\Client([
    'base_uri'        => "https://{$server->ip_address}:{$server->port}",
    'auth'            => [$server->username, $server->getDecryptedPassword()],
    'timeout'         => 30,
    'connect_timeout' => 15,
    'verify'          => true,       // SSL certificate verification
    'http_errors'     => false,      // Không throw exception cho 4xx/5xx
    'headers'         => [
        'User-Agent' => 'HVN-DNS-Manager/1.0',
    ],
]);
```

---

## A2. Authentication & Request Format

### Authentication

DirectAdmin sử dụng **HTTP Basic Authentication**.

```
Authorization: Basic base64(username:password)
```

Yêu cầu: Account phải có quyền **Admin** hoặc **Reseller** để quản lý DNS zones của users khác.

### Request Format

```
POST /CMD_API_DNS_CONTROL HTTP/1.1
Content-Type: application/x-www-form-urlencoded

domain=example.com&action=add&type=A&name=mail&value=103.1.2.3&json=yes
```

**Quy tắc quan trọng**:
- Luôn gửi `json=yes` để nhận response dạng JSON (DA >= 1.61)
- Nếu không có `json=yes`, DA trả response dạng **URL-encoded** (khó parse)
- Content-Type luôn là `application/x-www-form-urlencoded`
- Không dùng JSON body — DA không hỗ trợ

### Response Format (với json=yes)

**Thành công**:
```json
{
    "success": "Record added successfully",
    "result": "Record added"
}
```

**Thất bại**:
```json
{
    "error": "1",
    "text": "Cannot add record",
    "details": "A record with that value already exists"
}
```

**⚠️ GOTCHA**: Trường `"error"` là **string** `"1"`, không phải integer. Kiểm tra bằng `isset($response['error'])` thay vì `$response['error'] === true`.

---

## A3. DNS Zone Management

### A3.1. Tạo Zone mới — `CMD_API_DNS_ADMIN`

> **Dùng khi**: Provisioning domain mới (EPICS: PROV-001)  
> **Queue action**: `CREATE_ZONE`  
> **Yêu cầu quyền**: Admin level

**Request**:
```
POST /CMD_API_DNS_ADMIN
Content-Type: application/x-www-form-urlencoded

domain=example.com
&action=create
&ns1=dns1.hvn.vn
&ns2=dns2.hvn.vn
&json=yes
```

| Parameter | Bắt buộc | Mô tả |
|-----------|----------|-------|
| `domain` | ✅ | Tên miền cần tạo zone |
| `action` | ✅ | Phải là `create` |
| `ns1` | ✅ | Primary nameserver |
| `ns2` | ✅ | Secondary nameserver |
| `json` | ✅ | `yes` |

**Response thành công** (HTTP 200):
```json
{
    "success": "Zone created",
    "result": "Zone for example.com has been created"
}
```

**Response lỗi — Zone đã tồn tại** (HTTP 200, có field error):
```json
{
    "error": "1",
    "text": "Unable to create zone",
    "details": "Zone already exists on this server"
}
```

**Xử lý trong Worker**:
```php
$response = $this->gateway->createZone($domain, 'dns1.hvn.vn', 'dns2.hvn.vn');

if ($response->isSuccess()) {
    // Zone tạo thành công
    return JobResult::complete();
}

if ($response->errorType === 'zone_exists') {
    // Zone đã có → coi như thành công (idempotent)
    $this->logger->info("Zone already exists, treating as success", ['domain' => $domain]);
    return JobResult::complete();
}

// Lỗi khác
return JobResult::failed($response->errorMessage);
```

**⚠️ GOTCHA**: DA chỉ hỗ trợ `ns1` và `ns2` trong lệnh create. `ns3` phải thêm sau bằng `ADD_RECORD` type NS riêng.

---

### A3.2. Xóa Zone — `CMD_API_DNS_ADMIN`

> **Queue action**: `DELETE_ZONE`  
> **Yêu cầu quyền**: Admin level

**Request**:
```
POST /CMD_API_DNS_ADMIN

domain=example.com
&action=delete
&json=yes
```

**Response thành công**:
```json
{
    "success": "Zone deleted",
    "result": "Zone for example.com has been removed"
}
```

**Response lỗi — Zone không tồn tại**:
```json
{
    "error": "1",
    "text": "Unable to delete zone",
    "details": "Zone does not exist"
}
```

**Xử lý**: Zone không tồn tại → coi như đã xóa (idempotent). Log warning.

---

### A3.3. Lấy toàn bộ Zone — `CMD_API_DNS_CONTROL`

> **Dùng khi**: Drift Detection, verify sau sync  
> **KHÔNG qua Queue** — được gọi trực tiếp từ `DriftDetector` cron

**Request**:
```
GET /CMD_API_DNS_CONTROL?domain=example.com&json=yes
```

**Response thành công**:
```json
{
    "records": [
        {
            "type": "NS",
            "name": "",
            "value": "dns1.hvn.vn.",
            "ttl": "86400"
        },
        {
            "type": "NS",
            "name": "",
            "value": "dns2.hvn.vn.",
            "ttl": "86400"
        },
        {
            "type": "A",
            "name": "",
            "value": "103.45.67.89",
            "ttl": "3600"
        },
        {
            "type": "A",
            "name": "mail",
            "value": "103.45.67.90",
            "ttl": "3600"
        },
        {
            "type": "MX",
            "name": "",
            "value": "mail.example.com.",
            "priority": "10",
            "ttl": "3600"
        },
        {
            "type": "TXT",
            "name": "",
            "value": "\"v=spf1 include:_spf.google.com ~all\"",
            "ttl": "3600"
        }
    ],
    "$TTL": "3600"
}
```

**⚠️ GOTCHA quan trọng — Mapping giữa DA và WHMCS**:

| Khác biệt | DA format | WHMCS format | Xử lý |
|-----------|-----------|-------------|--------|
| Root domain name | `""` (empty string) | `"@"` | Parse: `name === "" ? "@" : name` |
| FQDN trailing dot | `"dns1.hvn.vn."` (có dấu chấm) | `"dns1.hvn.vn"` (không có) | Trim trailing dot khi parse |
| TXT value quoting | `"\"v=spf1...\""` (escaped quotes) | `"v=spf1..."` (không quotes) | Strip outer quotes |
| TTL type | `"3600"` (string) | `3600` (integer) | Cast: `(int) $ttl` |
| Priority field | Chỉ có cho MX | Có cho MX và SRV | Kiểm tra `isset($record['priority'])` |
| SRV format | `"0 443 target.com."` (weight port target trong value) | Tách riêng weight, port, value | Parse SRV value: explode space |

**Parser helper**:
```php
class DAResponseParser
{
    /**
     * Parse DA record format → WHMCS record format
     */
    public static function parseRecord(array $daRecord): array
    {
        $name = $daRecord['name'] === '' ? '@' : $daRecord['name'];
        $value = $daRecord['value'];
        $type = strtoupper($daRecord['type']);
        
        // Strip TXT outer quotes
        if ($type === 'TXT' && str_starts_with($value, '"') && str_ends_with($value, '"')) {
            $value = substr($value, 1, -1);
            $value = stripslashes($value);
        }
        
        // Trim FQDN trailing dot (CNAME, MX, NS)
        if (in_array($type, ['CNAME', 'MX', 'NS', 'SRV']) && str_ends_with($value, '.')) {
            $value = rtrim($value, '.');
        }
        
        $result = [
            'type'     => $type,
            'name'     => $name,
            'value'    => $value,
            'ttl'      => (int) ($daRecord['ttl'] ?? 3600),
            'priority' => isset($daRecord['priority']) ? (int) $daRecord['priority'] : null,
        ];
        
        // Parse SRV: value = "weight port target"
        if ($type === 'SRV') {
            $parts = explode(' ', $daRecord['value'], 3);
            if (count($parts) === 3) {
                $result['weight'] = (int) $parts[0];
                $result['port']   = (int) $parts[1];
                $result['value']  = rtrim($parts[2], '.');
            }
        }
        
        return $result;
    }
    
    /**
     * Build DA record format ← WHMCS record format
     * Để gửi lên DA API (add/edit/delete)
     */
    public static function buildDAParams(array $record): array
    {
        $name = $record['name'] === '@' ? '' : $record['name'];
        $value = $record['value'];
        $type = strtoupper($record['type']);
        
        // CNAME, MX, NS cần trailing dot
        if (in_array($type, ['CNAME', 'MX', 'NS']) && !str_ends_with($value, '.')) {
            $value .= '.';
        }
        
        // TXT cần quoted
        if ($type === 'TXT') {
            $value = '"' . addslashes($value) . '"';
        }
        
        // SRV: value = "weight port target."
        if ($type === 'SRV') {
            $target = $record['value'];
            if (!str_ends_with($target, '.')) {
                $target .= '.';
            }
            $value = ($record['weight'] ?? 0) . ' ' . ($record['port'] ?? 0) . ' ' . $target;
        }
        
        $params = [
            'type'  => $type,
            'name'  => $name,
            'value' => $value,
        ];
        
        if (isset($record['priority']) && in_array($type, ['MX', 'SRV'])) {
            $params['priority'] = (string) $record['priority'];
        }
        
        return $params;
    }
}
```

---

## A4. DNS Record Management

### A4.1. Thêm Record — `CMD_API_DNS_CONTROL` action=add

> **Queue action**: `ADD_RECORD`

**Request — Record A**:
```
POST /CMD_API_DNS_CONTROL

domain=example.com
&action=add
&type=A
&name=mail
&value=103.45.67.90
&json=yes
```

**Request — Record MX** (có priority):
```
POST /CMD_API_DNS_CONTROL

domain=example.com
&action=add
&type=MX
&name=
&value=mail.example.com.
&priority=10
&json=yes
```

**Request — Record TXT** (SPF):
```
POST /CMD_API_DNS_CONTROL

domain=example.com
&action=add
&type=TXT
&name=
&value="v=spf1 include:_spf.google.com ~all"
&json=yes
```

**Request — Record SRV**:
```
POST /CMD_API_DNS_CONTROL

domain=example.com
&action=add
&type=SRV
&name=_sip._tcp
&value=0 5060 sip.example.com.
&priority=10
&json=yes
```

**⚠️ GOTCHA**: Tham số `value` cho SRV phải gộp weight, port, target vào 1 chuỗi cách nhau bằng space: `"{weight} {port} {target.}"`

**Request — Record CAA**:
```
POST /CMD_API_DNS_CONTROL

domain=example.com
&action=add
&type=CAA
&name=
&value=0 issue "letsencrypt.org"
&json=yes
```

| Parameter | Bắt buộc | Mô tả |
|-----------|----------|-------|
| `domain` | ✅ | Tên miền |
| `action` | ✅ | `add` |
| `type` | ✅ | A, AAAA, CNAME, MX, TXT, SRV, NS, CAA, PTR |
| `name` | ✅ | Subdomain. Empty string `""` cho root domain |
| `value` | ✅ | Giá trị record. Format tùy type (xem bảng trên) |
| `priority` | MX, SRV | Bắt buộc cho MX và SRV |
| `json` | ✅ | `yes` |

**Response thành công**:
```json
{
    "success": "Record added successfully"
}
```

**Response lỗi — Record trùng**:
```json
{
    "error": "1",
    "text": "Record already exists",
    "details": "A record with name 'mail' and value '103.45.67.90' already exists"
}
```

**⚠️ GOTCHA**: DA kiểm tra trùng bằng combo `(type + name + value)`. Nếu thêm A record `mail → 103.1.2.3` mà đã tồn tại → lỗi. Nhưng thêm A record `mail → 103.1.2.4` (IP khác) thì OK (multiple A records cho load balancing).

---

### A4.2. Sửa Record — `CMD_API_DNS_CONTROL` action=edit

> **Queue action**: `EDIT_RECORD`

**Request**:
```
POST /CMD_API_DNS_CONTROL

domain=example.com
&action=edit
&type=A
&name=mail
&value=103.45.67.91
&aression=mail=103.45.67.90
&ttl=3600
&json=yes
```

| Parameter | Bắt buộc | Mô tả |
|-----------|----------|-------|
| `domain` | ✅ | Tên miền |
| `action` | ✅ | `edit` |
| `type` | ✅ | Loại record |
| `name` | ✅ | Subdomain (giá trị mới nếu đổi tên) |
| `value` | ✅ | Giá trị MỚI |
| `aression` | ✅ | **Giá trị CŨ** — format: `{old_name}={old_value}` |
| `ttl` | ❌ | TTL mới (nếu không gửi → giữ nguyên) |
| `json` | ✅ | `yes` |

**⚠️ GOTCHA CRITICAL — Tham số `aression`**:

Đây là tham số đặc biệt nhất của DA DNS API. DA cần biết record CŨ để identify record nào cần sửa. Format:

```
aression={old_name}={old_value}

Ví dụ:
- Sửa A record "mail" 103.1.2.3 → 103.1.2.4:
  aression=mail=103.45.67.90

- Sửa A record root "@" (name=""):
  aression==103.45.67.89
  (name rỗng, nên bắt đầu bằng dấu =)

- Sửa MX record (cần cả priority trong value cũ):
  aression==10=mail.example.com.

- Sửa TXT record:
  aression=="v=spf1 include:_spf.google.com ~all"
```

**Builder helper**:
```php
public static function buildAressionParam(array $oldRecord): string
{
    $name = $oldRecord['name'] === '@' ? '' : $oldRecord['name'];
    $value = $oldRecord['value'];
    
    // MX/SRV: arression cần priority trong value
    if (in_array($oldRecord['type'], ['MX', 'SRV']) && isset($oldRecord['priority'])) {
        $value = $oldRecord['priority'] . '=' . $value;
    }
    
    // Trailing dot cho CNAME, MX, NS
    if (in_array($oldRecord['type'], ['CNAME', 'MX', 'NS']) && !str_ends_with($value, '.')) {
        $value .= '.';
    }
    
    // TXT: cần quoted
    if ($oldRecord['type'] === 'TXT') {
        $value = '"' . addslashes($value) . '"';
    }
    
    return $name . '=' . $value;
}
```

**Response thành công**:
```json
{
    "success": "Record modified successfully"
}
```

**Response lỗi — Record cũ không tìm thấy**:
```json
{
    "error": "1",
    "text": "Cannot modify record",
    "details": "The original record was not found"
}
```

**Xử lý**: Lỗi "original record not found" → có thể record đã bị sửa/xóa trực tiếp trên DA. Đánh dấu `FAILED` + non-retryable. Drift Detection sẽ phát hiện.

---

### A4.3. Xóa Record — `CMD_API_DNS_CONTROL` action=delete

> **Queue action**: `DELETE_RECORD`

**Request**:
```
POST /CMD_API_DNS_CONTROL

domain=example.com
&action=delete
&type=A
&name=mail
&value=103.45.67.90
&json=yes
```

| Parameter | Bắt buộc | Mô tả |
|-----------|----------|-------|
| `domain` | ✅ | Tên miền |
| `action` | ✅ | `delete` |
| `type` | ✅ | Loại record |
| `name` | ✅ | Subdomain (empty string cho root) |
| `value` | ✅ | **Giá trị CHÍNH XÁC** của record cần xóa |
| `json` | ✅ | `yes` |

**⚠️ GOTCHA**: DA yêu cầu `value` CHÍNH XÁC. Nếu DA lưu `mail.example.com.` (có dot) mà gửi `mail.example.com` (không dot) → không tìm thấy → lỗi. Luôn dùng `DAResponseParser::buildDAParams()` để đảm bảo format.

**Response thành công**:
```json
{
    "success": "Record deleted successfully"
}
```

**Response lỗi**:
```json
{
    "error": "1",
    "text": "Unable to delete record",
    "details": "Record not found"
}
```

**Xử lý**: "Record not found" khi xóa → coi như đã xóa (idempotent). Complete job, log warning.

---

## A5. DNSSEC Management

### A5.1. Bật DNSSEC — `CMD_API_DNS_DNSSEC`

> **Queue action**: `ENABLE_DNSSEC`  
> **Yêu cầu**: `dnssec=1` trong `/usr/local/directadmin/conf/directadmin.conf` trên DA server

**Request**:
```
POST /CMD_API_DNS_DNSSEC

domain=example.com
&action=sign
&json=yes
```

**Response thành công**:
```json
{
    "success": "DNSSEC enabled",
    "result": "Zone example.com has been signed"
}
```

**⚠️ GOTCHA**: DA cần thời gian generate keys (1-5 giây). Response trả về thành công NHƯNG DS Records chưa sẵn sàng ngay. Worker cần gọi thêm `GET DS Records` (A5.3) sau khi enable thành công.

---

### A5.2. Tắt DNSSEC — `CMD_API_DNS_DNSSEC`

> **Queue action**: `DISABLE_DNSSEC`

**Request**:
```
POST /CMD_API_DNS_DNSSEC

domain=example.com
&action=unsign
&json=yes
```

**Response thành công**:
```json
{
    "success": "DNSSEC disabled",
    "result": "Zone example.com has been unsigned"
}
```

---

### A5.3. Lấy DS Records — `CMD_API_DNS_DNSSEC`

> **Gọi sau khi ENABLE_DNSSEC thành công**

**Request**:
```
GET /CMD_API_DNS_DNSSEC?domain=example.com&json=yes
```

**Response**:
```json
{
    "keys": [
        {
            "key_tag": "12345",
            "algorithm": "13",
            "digest_type": "2",
            "digest": "49FD46E6C4B45C55D4AC69B2C14BC2B3D4E5F6A7B8C9D0E1F2A3B4C5D6E7F8A9",
            "ds_record": "example.com. IN DS 12345 13 2 49FD46E6C4B45C55D4AC...",
            "public_key": "AwEAAb..."
        }
    ],
    "signed": "yes"
}
```

**Mapping vào DB** (`mod_hvndns_dnssec`):
```php
$key = $response->data['keys'][0];

DnssecKey::updateOrCreate(
    ['domain_id' => $domainId],
    [
        'is_enabled'     => true,
        'key_tag'        => (int) $key['key_tag'],
        'algorithm'      => (int) $key['algorithm'],
        'digest_type'    => (int) $key['digest_type'],
        'digest'         => $key['digest'],
        'ds_record_raw'  => $key['ds_record'],
        'public_key'     => $key['public_key'] ?? null,
        'last_signed_at' => now(),
    ]
);
```

---

### A5.4. Re-sign Zone — `CMD_API_DNS_DNSSEC`

> **Queue action**: `RESIGN_ZONE`  
> **Gọi tự động**: Sau mỗi batch thay đổi record khi DNSSEC đang enabled

**Request**:
```
POST /CMD_API_DNS_DNSSEC

domain=example.com
&action=sign
&json=yes
```

Cùng lệnh với Enable, nhưng khi zone đã signed thì DA hiểu là re-sign.

---

## A6. SSL / Let's Encrypt

### A6.1. Yêu cầu SSL Certificate — `CMD_API_SSL`

> **Queue action**: `REQUEST_SSL`  
> **Điều kiện**: Domain phải trỏ DNS về server DA đang request

**Request**:
```
POST /CMD_API_SSL

domain=example.com
&action=save
&type=create
&request=letsencrypt
&le_select0=example.com
&le_select1=www.example.com
&le_wc_select0=
&json=yes
```

| Parameter | Mô tả |
|-----------|-------|
| `domain` | Tên miền |
| `action` | `save` |
| `type` | `create` |
| `request` | `letsencrypt` |
| `le_select0` | Domain chính |
| `le_select1` | www subdomain (optional) |
| `le_wc_select0` | Wildcard `*.domain.com` (optional, cần DNS validation) |

**Response thành công**:
```json
{
    "success": "Certificate has been saved.",
    "result": "SSL certificate for example.com has been installed"
}
```

**Response lỗi phổ biến**:

| Lỗi | Nguyên nhân | Retryable? |
|-----|-------------|-----------|
| `"DNS resolution failed"` | Domain chưa trỏ NS về DA | ❌ — Chờ DNS propagate |
| `"Rate limit exceeded"` | Let's Encrypt rate limit (5 cert/tuần/domain) | ❌ — Chờ 7 ngày |
| `"Challenge failed"` | HTTP validation fail | ✅ — Retry sau 10 phút |
| `"Certificate already exists"` | Cert chưa hết hạn | ❌ — Coi như success |

**⚠️ GOTCHA**: Let's Encrypt cần thời gian validate (30-120 giây). DA có thể trả response trước khi cert sẵn sàng. Worker nên đợi 5 giây rồi verify bằng cách gọi lại API check cert status.

---

## A7. Email Forwarding

### A7.1. Tạo Email Forwarder — `CMD_API_EMAIL_FORWARDERS`

> **Queue action**: `CREATE_EMAIL_FWD`

**Request**:
```
POST /CMD_API_EMAIL_FORWARDERS

domain=example.com
&action=create
&user=info
&email=personal@gmail.com
&json=yes
```

| Parameter | Mô tả |
|-----------|-------|
| `domain` | Tên miền |
| `action` | `create` |
| `user` | Local part (VD: `info` cho info@example.com) |
| `email` | Email đích nhận forward |

**Response thành công**:
```json
{
    "success": "Forwarder created",
    "result": "Email forwarder info@example.com -> personal@gmail.com created"
}
```

### A7.2. Xóa Email Forwarder — `CMD_API_EMAIL_FORWARDERS`

**Request**:
```
POST /CMD_API_EMAIL_FORWARDERS

domain=example.com
&action=delete
&select0=info
&json=yes
```

**⚠️ GOTCHA**: Tham số xóa dùng `select0`, `select1`... (numbered selects), không dùng `user`.

---

## A8. Error Codes & Gotchas

### A8.1. Bảng lỗi tổng hợp DA API

| HTTP Status | DA Error Text | `DAResponse.errorType` | Retryable | Hành động |
|-------------|--------------|----------------------|-----------|-----------|
| 200 + no error field | — | `none` | — | Success ✅ |
| 200 + `"error":"1"` | `"Record already exists"` | `dns_conflict` | ❌ | FAILED — Admin xem xét |
| 200 + `"error":"1"` | `"Record not found"` | `dns_conflict` | ❌ | Coi như success nếu DELETE |
| 200 + `"error":"1"` | `"Zone already exists"` | `zone_exists` | ❌ | Coi như success nếu CREATE |
| 200 + `"error":"1"` | `"Zone does not exist"` | `zone_not_found` | ❌ | PERMANENTLY_FAILED |
| 200 + `"error":"1"` | `"Unable to modify"` | `dns_conflict` | ❌ | FAILED — record bị drift |
| 403 | — | `auth_fail` | ❌ | PERMANENTLY_FAILED + Alert Admin |
| 500 | — | `server_error` | ✅ | Exponential Backoff |
| 0 (no response) | — | `timeout` | ✅ | Exponential Backoff |
| Connection refused | — | `network_error` | ✅ | Server-level Backoff |

### A8.2. Danh sách Gotchas quan trọng

| # | Gotcha | Impact | Giải pháp |
|---|--------|--------|-----------|
| 1 | DA `error` field là string `"1"`, không phải boolean | Parse sai → miss error | Kiểm tra `isset($data['error'])` |
| 2 | Root domain name = empty string `""`, không phải `"@"` | Gửi sai name → record tạo ở subdomain "@" | Map `@ ↔ ""` qua Parser |
| 3 | CNAME/MX/NS cần trailing dot trong value | DA reject record thiếu dot | Builder tự thêm dot |
| 4 | TXT value cần escaped quotes | DA lưu/trả sai format | Parser strip/add quotes |
| 5 | `arression` parameter cho edit (không phải `aression`) | Typo → DA ignore, edit fail | Kiểm tra spelling chính xác |
| 6 | SRV value gộp weight+port+target vào 1 string | Parse sai → record lỗi | Explode/implode space |
| 7 | CREATE_ZONE chỉ hỗ trợ ns1+ns2, không có ns3 | Thiếu NS3 record | Add NS3 riêng sau CREATE |
| 8 | Let's Encrypt response trả trước khi cert ready | Cert chưa có ngay | Đợi 5s rồi verify |
| 9 | DA version < 1.61 không hỗ trợ `json=yes` | Response URL-encoded | Kiểm tra version khi Test Connection |
| 10 | DELETE cần value CHÍNH XÁC (bao gồm trailing dot) | Xóa fail do mismatch format | Luôn dùng buildDAParams() |

---

# PHẦN B — INTERNAL AJAX API (WHMCS ↔ Browser)

> API giữa trình duyệt Client/Admin ↔ WHMCS PHP backend.  
> Tất cả gọi qua Ajax (fetch/XHR). Không redirect, không page reload.

---

## B1. Tổng quan Internal API

### Base URL

```
Client Area:
/modules/addons/hvn_dns_manager/ajax.php?action={action}

Admin Area:
/admin/addonmodules.php?module=hvn_dns_manager&ajax=1&action={action}
```

### Authentication

- **Client Area**: WHMCS session cookie + CSRF token (`token` parameter)
- **Admin Area**: WHMCS admin session + CSRF token

### Standard Headers

```
Content-Type: application/json       (request body)
Accept: application/json             (response)
X-CSRF-Token: {whmcs_token}         (CSRF protection)
```

---

## B2. Client Area Endpoints

### B2.1. GET — Lấy danh sách Records

```
GET /ajax.php?action=get_records&domain_id=123

Response 200:
{
    "success": true,
    "data": {
        "domain": {
            "id": 123,
            "domain": "example.com",
            "status": "active",
            "ssl_status": "active",
            "dnssec_enabled": true
        },
        "records": [
            {
                "id": 456,
                "type": "A",
                "name": "@",
                "value": "103.45.67.89",
                "ttl": 3600,
                "priority": null,
                "is_system": false,
                "is_locked": false,
                "pending_delete": false,
                "sync_status": "complete",
                "sync_detail": {
                    "total": 3,
                    "complete": 3,
                    "pending": 0,
                    "failed": 0
                }
            }
        ],
        "quota": {
            "current": 15,
            "limit": 50,
            "percentage": 30
        }
    }
}
```

| Field | Mô tả |
|-------|-------|
| `sync_status` | Aggregate status: `complete`, `syncing`, `pending`, `partial`, `failed` |
| `sync_detail` | Chi tiết per-server count. CHỈ hiện hostname, KHÔNG hiện IP |
| `is_system` | `true` → Client không thể sửa/xóa (NS, SOA) |
| `is_locked` | `true` → Admin đã lock, Client không thể sửa/xóa |

---

### B2.2. POST — Thêm Record

```
POST /ajax.php?action=add_record
Content-Type: application/json
X-CSRF-Token: abc123

{
    "domain_id": 123,
    "type": "A",
    "name": "mail",
    "value": "103.45.67.90",
    "ttl": 3600,
    "priority": null
}

Response 200:
{
    "success": true,
    "data": {
        "record_id": 789,
        "batch_id": "550e8400-e29b-41d4-a716-446655440000"
    },
    "message": "Bản ghi DNS đã được lưu và đang đồng bộ."
}

Response 422 (Validation Error):
{
    "success": false,
    "error": {
        "code": "VALIDATION_ERROR",
        "message": "Địa chỉ IP không hợp lệ. Vui lòng nhập đúng format IPv4.",
        "field": "value",
        "details": {
            "expected": "IPv4 format (VD: 103.45.67.89)",
            "received": "999.999.999.999"
        }
    }
}

Response 429 (Rate Limit):
{
    "success": false,
    "error": {
        "code": "RATE_LIMITED",
        "message": "Bạn đã thực hiện quá nhiều thay đổi. Vui lòng chờ 1 phút.",
        "retry_after": 60
    }
}

Response 403 (Quota Exceeded):
{
    "success": false,
    "error": {
        "code": "QUOTA_EXCEEDED",
        "message": "Bạn đã đạt giới hạn 50 bản ghi cho gói dịch vụ hiện tại.",
        "quota": {
            "current": 50,
            "limit": 50,
            "upgrade_url": "/cart.php?a=add&pid=12"
        }
    }
}
```

---

### B2.3. POST — Sửa Record

```
POST /ajax.php?action=edit_record

{
    "record_id": 789,
    "domain_id": 123,
    "value": "103.45.67.91",
    "ttl": 1800
}

Response 200:
{
    "success": true,
    "data": {
        "record_id": 789,
        "batch_id": "660e8400-e29b-41d4-a716-446655440001"
    },
    "message": "Bản ghi đã được cập nhật và đang đồng bộ."
}

Response 409 (Conflict — Optimistic Locking):
{
    "success": false,
    "error": {
        "code": "RECORD_MODIFIED",
        "message": "Bản ghi này đã được cập nhật bởi người khác. Vui lòng tải lại trang.",
        "current_value": "103.45.67.92",
        "modified_at": "2026-02-25T14:30:22Z"
    }
}
```

---

### B2.4. POST — Xóa Record

```
POST /ajax.php?action=delete_record

{
    "record_id": 789,
    "domain_id": 123
}

Response 200:
{
    "success": true,
    "data": {
        "record_id": 789,
        "batch_id": "770e8400-e29b-41d4-a716-446655440002"
    },
    "message": "Bản ghi đang được xóa..."
}

Response 403:
{
    "success": false,
    "error": {
        "code": "RECORD_PROTECTED",
        "message": "Không thể xóa bản ghi hệ thống (NS/SOA)."
    }
}
```

---

### B2.5. GET — Sync Status Polling

```
GET /ajax.php?action=sync_status&batch_id=550e8400-e29b-41d4-a716-446655440000

Response 200:
{
    "success": true,
    "data": {
        "batch_id": "550e8400-e29b-41d4-a716-446655440000",
        "status": "syncing",
        "total": 3,
        "complete": 2,
        "pending": 0,
        "syncing": 1,
        "failed": 0,
        "servers": [
            {"hostname": "dns1.hvn.vn", "status": "complete"},
            {"hostname": "dns2.hvn.vn", "status": "complete"},
            {"hostname": "dns3.hvn.vn", "status": "syncing", "info": "Đang xử lý..."}
        ]
    }
}
```

**⚠️ Bảo mật**: Field `servers[].hostname` CHỈ hiện hostname, KHÔNG có IP, port, hoặc bất kỳ server detail nào.

---

### B2.6. GET — Sync Status All Records

```
GET /ajax.php?action=sync_status_all&domain_id=123

Response 200:
{
    "success": true,
    "data": {
        "records": {
            "456": {"status": "complete", "complete": 3, "total": 3},
            "789": {"status": "syncing", "complete": 2, "total": 3},
            "790": {"status": "pending", "complete": 0, "total": 3}
        },
        "has_pending": true
    }
}
```

Dùng cho Alpine.js poll toàn bộ records cùng lúc thay vì poll từng batch.

---

### B2.7. DDNS — Token Management

```
POST /ajax.php?action=create_ddns_token

{
    "domain_id": 123,
    "subdomain": "cam",
    "label": "Camera văn phòng HN"
}

Response 200:
{
    "success": true,
    "data": {
        "token_id": 5,
        "plain_token": "a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6q7r8s9t0u1v2w3x4y5z6",
        "url": "https://whmcs.hvn.vn/modules/addons/hvn_dns_manager/ddns.php?token=a1b2c3...",
        "subdomain": "cam",
        "full_hostname": "cam.example.com"
    },
    "message": "Token DDNS đã được tạo. LƯU Ý: Token chỉ hiển thị 1 lần duy nhất!"
}
```

**⚠️ QUAN TRỌNG**: `plain_token` chỉ trả về 1 lần duy nhất trong response tạo. Sau đó DB chỉ lưu SHA-256 hash. Nếu user mất token → phải tạo lại (regenerate).

---

### B2.8. DNSSEC — Toggle

```
POST /ajax.php?action=toggle_dnssec

{
    "domain_id": 123,
    "enable": true
}

Response 200:
{
    "success": true,
    "data": {
        "batch_id": "880e8400-e29b-41d4-a716-446655440003",
        "current_status": "pending"
    },
    "message": "DNSSEC đang được kích hoạt. Vui lòng chờ vài phút để hệ thống tạo khóa bảo mật."
}
```

```
GET /ajax.php?action=get_dnssec&domain_id=123

Response 200 (khi đã enabled):
{
    "success": true,
    "data": {
        "is_enabled": true,
        "key_tag": 12345,
        "algorithm": 13,
        "algorithm_name": "ECDSA P-256",
        "digest_type": 2,
        "digest_type_name": "SHA-256",
        "digest": "49FD46E6C4B45C55D4AC...",
        "ds_record": "12345 13 2 49FD46E6C4B45C55D4AC...",
        "last_signed_at": "2026-02-25T14:30:00Z"
    }
}
```

---

## B3. Admin Area Endpoints

Tất cả Admin endpoints yêu cầu WHMCS Admin session và quyền addon module.

### B3.1. Dashboard Stats

```
GET ?module=hvn_dns_manager&ajax=1&action=dashboard_stats

Response 200:
{
    "success": true,
    "data": {
        "pipeline_24h": {
            "complete": 1247,
            "pending": 23,
            "failed": 12,
            "cancelled": 3
        },
        "servers": [
            {
                "id": 1,
                "hostname": "dns1.hvn.vn",
                "ip_address": "103.xx.xx.10",
                "role": "primary",
                "is_active": true,
                "uptime_percent": 99.8,
                "avg_response_ms": 45,
                "pending_jobs": 12,
                "in_backoff": false
            }
        ],
        "overview": {
            "total_domains": 342,
            "total_records": 6840,
            "active_domains": 335,
            "suspended_domains": 7
        },
        "top_changes_7d": [
            {"domain": "example.com", "changes": 45},
            {"domain": "shop.vn", "changes": 38}
        ],
        "recent_activity": [
            {
                "time": "2026-02-25T14:32:00Z",
                "domain": "myblog.net",
                "action": "DELETE_RECORD",
                "server": "dns3.hvn.vn",
                "status": "failed",
                "error": "timeout"
            }
        ],
        "alerts": {
            "has_critical": true,
            "messages": [
                "dns3.hvn.vn mất kết nối từ 14:30 — 7 job FAILED liên tiếp"
            ]
        }
    }
}
```

---

### B3.2. Server Management

```
POST ?module=hvn_dns_manager&ajax=1&action=test_server

{
    "server_id": 3
}

Response 200:
{
    "success": true,
    "data": {
        "connected": true,
        "da_version": "1.65.0",
        "latency_ms": 42,
        "total_zones": 156,
        "dnssec_available": true,
        "os": "AlmaLinux 8.7"
    },
    "message": "Kết nối thành công!"
}

Response 200 (connection failed):
{
    "success": true,
    "data": {
        "connected": false,
        "error": "Connection timed out after 10000ms",
        "latency_ms": null
    },
    "message": "Không thể kết nối tới server."
}
```

```
POST ?module=hvn_dns_manager&ajax=1&action=toggle_server

{
    "server_id": 3,
    "is_active": false
}

Response 200:
{
    "success": true,
    "data": {
        "server_id": 3,
        "is_active": false,
        "cancelled_jobs": 15
    },
    "message": "Server đã được disable. 15 job PENDING đã chuyển thành CANCELLED."
}
```

---

### B3.3. Retry Operations

```
POST ?module=hvn_dns_manager&ajax=1&action=retry_job

{
    "job_id": 4521
}

Response 200:
{
    "success": true,
    "data": {
        "job_id": 4521,
        "new_status": "PENDING",
        "attempts_reset": true
    },
    "message": "Job đã được đưa lại hàng đợi."
}
```

```
POST ?module=hvn_dns_manager&ajax=1&action=retry_all_failed

Response 200:
{
    "success": true,
    "data": {
        "retried_count": 12,
        "job_ids": [4521, 4522, 4525, ...]
    },
    "message": "12 job đã được đưa lại hàng đợi."
}
```

---

### B3.4. Drift Resolution

```
POST ?module=hvn_dns_manager&ajax=1&action=resolve_drift

{
    "drift_id": 78,
    "resolution": "push_whmcs"
}

Response 200:
{
    "success": true,
    "data": {
        "drift_id": 78,
        "resolution": "push_whmcs",
        "batch_id": "990e8400-e29b-41d4-a716-446655440004"
    },
    "message": "Đang đẩy giá trị WHMCS lên DirectAdmin..."
}
```

---

### B3.5. Bulk Operations

```
POST ?module=hvn_dns_manager&ajax=1&action=bulk_preview

{
    "operation": "change_ip",
    "old_ip": "103.45.67.89",
    "new_ip": "103.45.67.100",
    "scope": "all"
}

Response 200:
{
    "success": true,
    "data": {
        "affected_records": 23,
        "affected_domains": 15,
        "preview": [
            {
                "domain": "example.com",
                "records": [
                    {"id": 456, "name": "@", "old": "103.45.67.89", "new": "103.45.67.100"},
                    {"id": 457, "name": "www", "old": "103.45.67.89", "new": "103.45.67.100"},
                    {"id": 458, "name": "mail", "old": "103.45.67.89", "new": "103.45.67.100"}
                ]
            }
        ]
    }
}
```

```
POST ?module=hvn_dns_manager&ajax=1&action=bulk_execute

{
    "operation": "change_ip",
    "old_ip": "103.45.67.89",
    "new_ip": "103.45.67.100",
    "domain_ids": [123, 124, 125, ...],
    "confirmed": true
}

Response 200:
{
    "success": true,
    "data": {
        "total_domains": 15,
        "total_records": 23,
        "total_jobs": 69,
        "snapshots_created": 15,
        "batch_group_id": "bulk-20260225-143500"
    },
    "message": "Đã tạo 69 job đồng bộ cho 23 bản ghi trên 15 domain. Snapshot đã được tạo."
}
```

---

### B3.6. Snapshot & Rollback

```
POST ?module=hvn_dns_manager&ajax=1&action=create_snapshot

{
    "domain_id": 123
}

Response 200:
{
    "success": true,
    "data": {
        "snapshot_id": 45,
        "record_count": 15,
        "created_at": "2026-02-25T14:35:00Z"
    },
    "message": "Snapshot đã được tạo (15 bản ghi)."
}
```

```
GET ?module=hvn_dns_manager&ajax=1&action=list_snapshots&domain_id=123

Response 200:
{
    "success": true,
    "data": {
        "snapshots": [
            {
                "id": 45,
                "type": "manual",
                "record_count": 15,
                "trigger_info": "Manual snapshot by Admin Vuong",
                "created_at": "2026-02-25T14:35:00Z"
            },
            {
                "id": 44,
                "type": "scheduled",
                "record_count": 14,
                "trigger_info": "Nightly backup",
                "created_at": "2026-02-25T02:00:00Z"
            }
        ]
    }
}
```

```
POST ?module=hvn_dns_manager&ajax=1&action=rollback_preview

{
    "domain_id": 123,
    "snapshot_id": 44
}

Response 200:
{
    "success": true,
    "data": {
        "snapshot_id": 44,
        "current_record_count": 15,
        "snapshot_record_count": 14,
        "diff": {
            "keep": 13,
            "add": 0,
            "modify": 0,
            "delete": 2,
            "deletions": [
                {"type": "A", "name": "test", "value": "1.2.3.4"},
                {"type": "TXT", "name": "_verify", "value": "google-site-verification=..."}
            ]
        }
    }
}
```

```
POST ?module=hvn_dns_manager&ajax=1&action=rollback_execute

{
    "domain_id": 123,
    "snapshot_id": 44,
    "confirmed": true
}

Response 200:
{
    "success": true,
    "data": {
        "pre_rollback_snapshot_id": 46,
        "jobs_created": 6,
        "batch_id": "aa0e8400-e29b-41d4-a716-446655440005"
    },
    "message": "Rollback đang được thực hiện. Snapshot trước rollback đã được tạo (#46)."
}
```

---

## B4. DDNS External Endpoint

> **URL**: `/modules/addons/hvn_dns_manager/ddns.php`  
> **Auth**: Token-based (không cần WHMCS session)  
> **Gọi bởi**: Router, Camera, IoT devices

### B4.1. Update IP

```
GET /modules/addons/hvn_dns_manager/ddns.php
    ?token=a1b2c3d4e5f6...
    &hostname=cam.example.com    (optional — cho tương thích DynDNS)
    &myip=118.70.5.6             (optional — override auto-detect)
```

| Parameter | Bắt buộc | Mô tả |
|-----------|----------|-------|
| `token` | ✅ | DDNS token đã được cấp |
| `hostname` | ❌ | Hostname để update (for DynDNS compatibility). Nếu không gửi → lấy từ token config |
| `myip` | ❌ | IP muốn set. Nếu không gửi → lấy `$_SERVER['REMOTE_ADDR']` |

**Response format**: Plain text (tương thích DynDNS standard để router hiểu)

| Response | HTTP Code | Ý nghĩa |
|----------|-----------|---------|
| `good 118.70.5.6` | 200 | IP đã thay đổi thành công |
| `nochg 118.70.5.6` | 200 | IP không đổi, không cần update |
| `badauth` | 401 | Token không hợp lệ hoặc đã bị revoke |
| `abuse` | 429 | Vượt rate limit (60 req/giờ) |
| `blocked` | 403 | IP bị block do brute force |
| `dnserr` | 500 | Lỗi hệ thống (queue dispatch fail) |
| `notfqdn` | 400 | Hostname format không hợp lệ |

**Ví dụ Router Mikrotik**:
```
/tool fetch url="https://whmcs.hvn.vn/modules/addons/hvn_dns_manager/ddns.php?token=a1b2c3..." mode=http
```

Router đọc response `good {ip}` hoặc `nochg {ip}` → biết đã thành công.

---

## B5. Response Format chuẩn

Tất cả Internal Ajax API (ngoại trừ DDNS endpoint) tuân theo format:

### Success Response

```json
{
    "success": true,
    "data": { ... },
    "message": "Mô tả thành công bằng tiếng Việt."
}
```

### Error Response

```json
{
    "success": false,
    "error": {
        "code": "ERROR_CODE",
        "message": "Mô tả lỗi thân thiện cho user bằng tiếng Việt.",
        "field": "field_name",
        "details": { ... }
    }
}
```

### Pagination Response (cho DataTables server-side)

```json
{
    "success": true,
    "data": {
        "items": [ ... ],
        "pagination": {
            "current_page": 1,
            "per_page": 10,
            "total_items": 342,
            "total_pages": 35
        }
    }
}
```

---

## B6. Error Codes Dictionary

### Validation Errors (4xx)

| Code | HTTP | Mô tả | Khi nào |
|------|------|--------|---------|
| `VALIDATION_ERROR` | 422 | Input không hợp lệ | Sai format IP, FQDN, TTL range |
| `CNAME_CONFLICT` | 422 | CNAME xung đột với record A/MX | Tạo CNAME trùng name với A record |
| `DUPLICATE_MX_PRIORITY` | 422 | MX priority trùng | Cảnh báo (không block) |
| `INVALID_SRV_FORMAT` | 422 | SRV record format sai | Thiếu weight/port/target |
| `INVALID_CAA_TAG` | 422 | CAA tag không hợp lệ | Tag không phải issue/issuewild/iodef |
| `TTL_OUT_OF_RANGE` | 422 | TTL ngoài range 60-86400 | — |

### Authorization Errors (403)

| Code | HTTP | Mô tả | Khi nào |
|------|------|--------|---------|
| `UNAUTHORIZED` | 403 | Không có quyền | Client truy cập domain không phải của mình |
| `DOMAIN_SUSPENDED` | 403 | Domain bị suspend | Client cố sửa DNS khi nợ phí |
| `RECORD_PROTECTED` | 403 | Record bị bảo vệ | Client cố xóa NS/SOA record |
| `RECORD_LOCKED` | 403 | Record bị Admin lock | Client cố sửa record đã locked |
| `FEATURE_DISABLED` | 403 | Tính năng bị tắt | DDNS/DNSSEC/SSL không có trong quota plan |
| `ADMIN_REQUIRED` | 403 | Cần quyền Admin | Client gọi Admin-only endpoint |

### Quota & Rate Limit Errors (429)

| Code | HTTP | Mô tả | Khi nào |
|------|------|--------|---------|
| `QUOTA_EXCEEDED` | 429 | Vượt giới hạn quota | Hết record/redirect/email quota |
| `RATE_LIMITED` | 429 | Vượt rate limit | > 30 changes/phút (Client) |
| `DDNS_RATE_LIMITED` | 429 | Vượt DDNS rate limit | > 60 requests/giờ per token |

### Conflict Errors (409)

| Code | HTTP | Mô tả | Khi nào |
|------|------|--------|---------|
| `RECORD_MODIFIED` | 409 | Record đã bị sửa | Optimistic Locking fail (2 tab cùng sửa) |
| `JOB_CONFLICT` | 409 | Job xung đột | Đã có job PENDING cho cùng record |
| `ADMIN_OVERRIDE` | 409 | Admin đã override | Client bị cancel job do Admin priority |

### Server Errors (500)

| Code | HTTP | Mô tả | Khi nào |
|------|------|--------|---------|
| `INTERNAL_ERROR` | 500 | Lỗi hệ thống | Exception không mong đợi |
| `QUEUE_DISPATCH_FAILED` | 500 | Không thể tạo job | DB write fail |
| `NO_ACTIVE_SERVERS` | 500 | Không có server nào active | Tất cả server bị disable |

**⚠️ Quy tắc hiển thị lỗi**:
- Error code `INTERNAL_ERROR`: **CHỈ hiện message generic** cho Client. Log chi tiết vào Monolog.
- Error code khác: hiện message cụ thể từ response.
- **KHÔNG BAO GIỜ** hiện stack trace, SQL error, hoặc server details cho Client.

---

# PHẦN C — REST API (Future — Phase 3)

> Thiết kế sơ bộ cho REST API phục vụ tích hợp bên ngoài (CI/CD, automation tools).  
> Implement trong Phase 3 (EPIC-14, Story 14.2).

---

## C1. REST API Specification

### Base URL

```
https://whmcs.hvn.vn/modules/addons/hvn_dns_manager/api/v1
```

### Authentication

```
Authorization: Bearer {api_key}
```

API Key được tạo và quản lý trong Client Area (1 key per client). Key lưu dạng SHA-256 hash trong DB (tương tự DDNS token).

### Endpoints

| Method | Endpoint | Mô tả |
|--------|----------|-------|
| `GET` | `/domains` | Danh sách domain của client |
| `GET` | `/domains/{id}` | Chi tiết domain |
| `GET` | `/domains/{id}/records` | Danh sách records |
| `POST` | `/domains/{id}/records` | Thêm record |
| `PUT` | `/domains/{id}/records/{rid}` | Sửa record |
| `DELETE` | `/domains/{id}/records/{rid}` | Xóa record |
| `GET` | `/domains/{id}/records/{rid}/status` | Sync status of record |
| `GET` | `/domains/{id}/dnssec` | Thông tin DNSSEC |
| `POST` | `/domains/{id}/dnssec` | Toggle DNSSEC |
| `GET` | `/domains/{id}/ddns-tokens` | Danh sách DDNS tokens |
| `POST` | `/domains/{id}/ddns-tokens` | Tạo DDNS token |

### Rate Limiting

```
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 95
X-RateLimit-Reset: 1709913600
```

100 requests/phút per API key. Vượt quá → HTTP 429.

### Example Request/Response

```
POST /api/v1/domains/123/records
Authorization: Bearer sk_live_abc123...
Content-Type: application/json

{
    "type": "A",
    "name": "staging",
    "value": "103.45.67.95",
    "ttl": 300
}

Response 201:
{
    "success": true,
    "data": {
        "record": {
            "id": 890,
            "type": "A",
            "name": "staging",
            "value": "103.45.67.95",
            "ttl": 300,
            "created_at": "2026-02-25T14:40:00Z"
        },
        "sync": {
            "batch_id": "bb0e8400-e29b-41d4-a716-446655440006",
            "status": "pending",
            "servers": {
                "total": 3,
                "complete": 0
            }
        }
    }
}
```

**Quan trọng**: REST API đi qua cùng `QueueManager::dispatch()` và `DnsRecordValidator`. Không có shortcut bypass queue.

---

# PHỤ LỤC

## D1. DAGateway → Queue Action Mapping

| Queue Action | DA Command | DA Action | Ghi chú |
|-------------|-----------|-----------|---------|
| `ADD_RECORD` | `CMD_API_DNS_CONTROL` | `add` | — |
| `EDIT_RECORD` | `CMD_API_DNS_CONTROL` | `edit` | Cần `arression` param |
| `DELETE_RECORD` | `CMD_API_DNS_CONTROL` | `delete` | Cần value chính xác |
| `CREATE_ZONE` | `CMD_API_DNS_ADMIN` | `create` | Admin level. Chỉ ns1+ns2 |
| `DELETE_ZONE` | `CMD_API_DNS_ADMIN` | `delete` | Admin level |
| `ENABLE_DNSSEC` | `CMD_API_DNS_DNSSEC` | `sign` | Sau đó GET DS Records |
| `DISABLE_DNSSEC` | `CMD_API_DNS_DNSSEC` | `unsign` | — |
| `RESIGN_ZONE` | `CMD_API_DNS_DNSSEC` | `sign` | Re-sign = cùng lệnh enable |
| `REQUEST_SSL` | `CMD_API_SSL` | `save` + `letsencrypt` | Cần DNS đã trỏ đúng |
| `RENEW_SSL` | `CMD_API_SSL` | `save` + `letsencrypt` | Cùng lệnh request |
| `CREATE_EMAIL_FWD` | `CMD_API_EMAIL_FORWARDERS` | `create` | — |
| `DELETE_EMAIL_FWD` | `CMD_API_EMAIL_FORWARDERS` | `delete` | Dùng `select0` param |
| `CREATE_REDIRECT` | — | — | Config .htaccess qua DA file manager API |
| `EDIT_REDIRECT` | — | — | Config .htaccess qua DA file manager API |
| `DELETE_REDIRECT` | — | — | Config .htaccess qua DA file manager API |

## D2. HTTP Status Code Usage

| Code | Ý nghĩa | Dùng khi |
|------|---------|---------|
| 200 | OK | Mọi request thành công (GET, POST, PUT, DELETE) |
| 201 | Created | REST API: tạo resource mới thành công |
| 400 | Bad Request | Request format sai, thiếu required params |
| 401 | Unauthorized | Token/session không hợp lệ |
| 403 | Forbidden | Không có quyền (domain người khác, feature disabled) |
| 404 | Not Found | Domain/record/resource không tồn tại |
| 409 | Conflict | Optimistic locking fail, job conflict |
| 422 | Unprocessable Entity | Validation error (format đúng nhưng value sai) |
| 429 | Too Many Requests | Rate limit / quota exceeded |
| 500 | Internal Server Error | Exception không mong đợi |

---

> **Tài liệu này là phiên bản sống (living document)**. Cập nhật khi phát hiện DA API behavior mới hoặc thêm endpoint mới.

## Changelog
| Ngày | Thay đổi | Người thực hiện |
|------|----------|-----------------|
| 25/02/2026 | Khởi tạo v1.0 — DA API + Internal Ajax + REST API draft | — |
