# HVN - DirectAdmin DNS Manager
## Database Schema & Column Dictionary

> **Phiên bản**: 1.0  
> **Ngày tạo**: 25/02/2026  
> **Database Engine**: MySQL 8.0+ / MariaDB 10.6+  
> **Character Set**: `utf8mb4` — Collation: `utf8mb4_unicode_ci`  
> **Tiền tố bảng**: `mod_hvndns_`  
> **ORM**: WHMCS Eloquent (Illuminate\Database\Capsule)  

---

## Mục lục

1. [Tổng quan ERD](#1-tổng-quan-erd)
2. [Quy ước chung](#2-quy-ước-chung)
3. [mod_hvndns_schema_version](#3-mod_hvndns_schema_version) — Quản lý phiên bản schema
4. [mod_hvndns_servers](#4-mod_hvndns_servers) — Cấu hình DA Node
5. [mod_hvndns_domains](#5-mod_hvndns_domains) — Tên miền khách hàng
6. [mod_hvndns_records](#6-mod_hvndns_records) — Bản ghi DNS (Source of Truth)
7. [mod_hvndns_queue](#7-mod_hvndns_queue) — Hàng đợi tác vụ bất đồng bộ
8. [mod_hvndns_sync_logs](#8-mod_hvndns_sync_logs) — Nhật ký đồng bộ
9. [mod_hvndns_audit_trail](#9-mod_hvndns_audit_trail) — Nhật ký kiểm toán
10. [mod_hvndns_record_history](#10-mod_hvndns_record_history) — Lịch sử thay đổi record
11. [mod_hvndns_snapshots](#11-mod_hvndns_snapshots) — Bản sao Zone
12. [mod_hvndns_templates](#12-mod_hvndns_templates) — Mẫu DNS
13. [mod_hvndns_quota_plans](#13-mod_hvndns_quota_plans) — Gói giới hạn tài nguyên
14. [mod_hvndns_dnssec](#14-mod_hvndns_dnssec) — Thông số DNSSEC
15. [mod_hvndns_ddns_tokens](#15-mod_hvndns_ddns_tokens) — Token DDNS
16. [mod_hvndns_redirects](#16-mod_hvndns_redirects) — Chuyển hướng URL
17. [mod_hvndns_email_forwards](#17-mod_hvndns_email_forwards) — Chuyển tiếp Email
18. [mod_hvndns_drift_reports](#18-mod_hvndns_drift_reports) — Báo cáo lệch dữ liệu
19. [mod_hvndns_ip_blacklist](#19-mod_hvndns_ip_blacklist) — Danh sách IP bị chặn
20. [mod_hvndns_notification_cooldowns](#20-mod_hvndns_notification_cooldowns) — Kiểm soát tần suất cảnh báo
21. [Phụ lục: Index Strategy](#21-phụ-lục-index-strategy)
22. [Phụ lục: Data Retention Policy](#22-phụ-lục-data-retention-policy)

---

## 1. Tổng quan ERD

```
                                    ┌──────────────────────┐
                                    │  mod_hvndns_servers   │
                                    │  (DA Node configs)    │
                                    └──────────┬───────────┘
                                               │ 1:N
                    ┌──────────────────────────┼──────────────────────────┐
                    │                          │                          │
                    ▼                          ▼                          ▼
          ┌─────────────────┐      ┌─────────────────────┐    ┌──────────────────┐
          │ mod_hvndns_queue │      │ mod_hvndns_sync_logs │    │ mod_hvndns_drift │
          │ (Job Queue)      │─────▶│ (Sync History)       │    │ _reports          │
          └────────┬────────┘  1:N └─────────────────────┘    └──────────────────┘
                   │                                                    ▲
                   │ N:1                                                │ 1:N
                   ▼                                                    │
          ┌─────────────────────┐                                       │
          │ mod_hvndns_domains   │───────────────────────────────────────┤
          │ (Domain Registry)    │                                       │
          └────────┬────────────┘                                       │
                   │                                                    │
       ┌───────────┼───────────┬──────────────┬──────────────┐         │
       │ 1:N       │ 1:N       │ 1:N          │ 1:N          │ 1:N     │
       ▼           ▼           ▼              ▼              ▼         │
┌───────────┐ ┌──────────┐ ┌──────────┐ ┌───────────┐ ┌──────────────┐│
│mod_hvndns_│ │mod_hvndns│ │mod_hvndns│ │mod_hvndns_ │ │mod_hvndns_   ││
│_records   │ │_snapshots│ │_dnssec   │ │ddns_tokens │ │redirects     ││
│(DNS Recs) │ │(Backups) │ │(DNSSEC)  │ │(DDNS Auth) │ │(URL Forward) ││
└─────┬─────┘ └──────────┘ └──────────┘ └───────────┘ └──────────────┘│
      │ 1:N                                                             │
      ▼                                                                 │
┌───────────────┐       ┌────────────────────┐       ┌────────────────┐
│mod_hvndns_    │       │mod_hvndns_         │       │mod_hvndns_     │
│record_history │       │audit_trail         │       │email_forwards  │
│(Change Log)   │       │(Security Audit)    │       │(Email FWD)     │
└───────────────┘       └────────────────────┘       └────────────────┘

Standalone tables (không có FK):
┌──────────────────────┐  ┌──────────────────────────────┐  ┌─────────────────────┐
│mod_hvndns_templates  │  │mod_hvndns_notification_      │  │mod_hvndns_          │
│(DNS Templates)       │  │cooldowns (Alert Throttle)    │  │ip_blacklist         │
└──────────────────────┘  └──────────────────────────────┘  └─────────────────────┘

┌──────────────────────┐  ┌──────────────────────────────┐
│mod_hvndns_quota_plans│  │mod_hvndns_schema_version     │
│(Service Limits)      │  │(Migration Tracking)          │
└──────────────────────┘  └──────────────────────────────┘
```

**Tổng cộng: 18 bảng**

---

## 2. Quy ước chung

### 2.1. Quy ước đặt tên

| Đối tượng | Quy ước | Ví dụ |
|-----------|---------|-------|
| Tên bảng | `mod_hvndns_` + `snake_case` | `mod_hvndns_queue` |
| Tên cột | `snake_case` | `domain_id`, `created_at` |
| Primary Key | `id` (INT UNSIGNED AUTO_INCREMENT) | `id` |
| Foreign Key | `{table_singular}_id` | `domain_id`, `server_id` |
| Boolean | `is_` hoặc `has_` prefix | `is_active`, `is_system` |
| Timestamp tự động | `created_at`, `updated_at` | — |
| Timestamp sự kiện | `{event}_at` | `completed_at`, `blocked_until` |
| JSON data | `{name}_data` hoặc mô tả rõ | `records_data`, `payload` |
| Encrypted | `{name}_enc` | `password_enc` |
| Hashed | `{name}_hash` | `token_hash` |
| Index | `idx_{columns}` | `idx_domain_type` |
| Unique Index | `uniq_{columns}` | `uniq_domain` |

### 2.2. Kiểu dữ liệu chuẩn

| Mục đích | Kiểu dữ liệu | Lý do |
|----------|--------------|-------|
| Primary Key | `INT UNSIGNED AUTO_INCREMENT` | Đủ cho 4.2 tỷ rows |
| PK bảng log lớn | `BIGINT UNSIGNED AUTO_INCREMENT` | Cho bảng sync_logs, audit_trail, record_history |
| UUID / Batch ID | `CHAR(36)` | UUID v4 format cố định 36 ký tự |
| Domain name | `VARCHAR(253)` | RFC 1035: domain tối đa 253 ký tự |
| Hostname label | `VARCHAR(63)` | RFC 1035: mỗi label tối đa 63 ký tự |
| Subdomain/Name | `VARCHAR(255)` | Bao gồm wildcard và multi-level subdomain |
| DNS Value | `TEXT` | TXT records có thể rất dài (DKIM > 255 chars) |
| IP Address | `VARCHAR(45)` | IPv6 full format tối đa 45 ký tự |
| TTL | `INT UNSIGNED` | Range 0–4294967295, thực tế dùng 60–86400 |
| Port | `SMALLINT UNSIGNED` | Range 0–65535 |
| Priority | `SMALLINT UNSIGNED` | Range 0–65535 (MX, SRV) |
| Status ENUM | `ENUM(...)` | Giới hạn giá trị, tiết kiệm storage |
| Encrypted data | `TEXT` | Chiều dài mã hóa không cố định |
| JSON payload | `JSON` | MySQL native JSON cho query + validate |
| Thời gian (ms) | `INT UNSIGNED` | Duration tính bằng milliseconds |
| Counter nhỏ | `TINYINT UNSIGNED` | Range 0–255 (attempts, backoff_count) |
| Counter vừa | `SMALLINT UNSIGNED` | Range 0–65535 (record_count, max_concurrent) |
| Boolean | `TINYINT(1)` | 0 = false, 1 = true |
| Datetime | `DATETIME` | Không dùng TIMESTAMP (giới hạn 2038) |

### 2.3. Ký hiệu trong tài liệu

| Ký hiệu | Ý nghĩa |
|----------|---------|
| 🔑 PK | Primary Key |
| 🔗 FK | Foreign Key |
| 🔒 ENC | Dữ liệu được mã hóa (AES-256 qua WHMCS Encryption) |
| #️⃣ HASH | Dữ liệu được hash một chiều (SHA-256) |
| 📋 IDX | Có index |
| 🦄 UNIQ | Unique constraint |
| ⚡ AUTO | AUTO_INCREMENT |
| 📌 REQD | NOT NULL (bắt buộc) |
| 🚫 RO | Read-Only từ application (không cho UPDATE/DELETE) |
| 🕐 AUTO-TS | Tự động set bởi MySQL (DEFAULT CURRENT_TIMESTAMP) |

---

## 3. mod_hvndns_schema_version

> **Mục đích**: Theo dõi phiên bản schema database. Mỗi khi module được upgrade, `MigrationRunner` kiểm tra bảng này để biết cần chạy migration nào.

| # | Cột | Kiểu | Ràng buộc | Mô tả |
|---|-----|------|-----------|-------|
| 1 | `id` | INT UNSIGNED | 🔑 PK ⚡ AUTO 📌 REQD | ID tự tăng |
| 2 | `version` | VARCHAR(20) | 🦄 UNIQ 📌 REQD | Phiên bản schema (VD: `1.0.0`, `1.1.0`) theo SemVer |
| 3 | `description` | VARCHAR(255) | NULL | Mô tả ngắn về migration (VD: "Initial schema", "Add DNSSEC tables") |
| 4 | `executed_at` | DATETIME | 📌 REQD 🕐 AUTO-TS | Thời điểm migration được chạy thành công |

**Dung lượng ước tính**: < 100 rows (số phiên bản module release).

```sql
CREATE TABLE mod_hvndns_schema_version (
    id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    version         VARCHAR(20) NOT NULL,
    description     VARCHAR(255) NULL,
    executed_at     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE INDEX uniq_version (version)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

---

## 4. mod_hvndns_servers

> **Mục đích**: Lưu thông tin kết nối và trạng thái của từng DirectAdmin Node (dns1, dns2, dns3...). Đây là bảng cấu hình — Admin quản lý qua giao diện.

| # | Cột | Kiểu | Ràng buộc | Mô tả |
|---|-----|------|-----------|-------|
| 1 | `id` | INT UNSIGNED | 🔑 PK ⚡ AUTO 📌 REQD | ID server nội bộ |
| 2 | `hostname` | VARCHAR(255) | 📌 REQD 🦄 UNIQ | Tên miền hostname của server (VD: `dns1.hvn.vn`). Dùng để hiển thị cho Client — Client KHÔNG BAO GIỜ thấy IP |
| 3 | `ip_address` | VARCHAR(45) | 📌 REQD | Địa chỉ IP thực của server (IPv4 hoặc IPv6). Chỉ dùng nội bộ cho API connection. KHÔNG hiển thị cho Client |
| 4 | `port` | SMALLINT UNSIGNED | 📌 REQD DEFAULT `2222` | Cổng API DirectAdmin. Mặc định 2222 (DA standard) |
| 5 | `username` | VARCHAR(100) | 📌 REQD | Tên đăng nhập DA API. Yêu cầu level Admin hoặc Reseller để có quyền quản lý DNS Zone |
| 6 | `password_enc` | TEXT | 📌 REQD 🔒 ENC | Mật khẩu DA đã mã hóa bằng `WHMCS\Security\Encryption::encode()`. Giải mã bằng `::decode()` chỉ tại thời điểm Cron Worker kết nối. KHÔNG BAO GIỜ log hoặc hiển thị plaintext |
| 7 | `use_ssl` | TINYINT(1) | 📌 REQD DEFAULT `1` | Sử dụng HTTPS khi gọi API? `1` = HTTPS (khuyến nghị), `0` = HTTP. Nếu `1`, base URL = `https://{ip}:{port}` |
| 8 | `role` | ENUM('primary', 'secondary') | 📌 REQD DEFAULT `'secondary'` | Vai trò trong cụm DNS. `primary` = server chính (dùng cho Drift Detection — chỉ cần query 1 server primary). `secondary` = bản sao. Fan-out gửi tới TẤT CẢ server không phân biệt role |
| 9 | `is_active` | TINYINT(1) | 📌 REQD DEFAULT `1` 📋 IDX | Server có đang hoạt động? `1` = active (nhận job mới), `0` = disabled (bảo trì — job mới không fan-out tới server này, job cũ PENDING chuyển CANCELLED) |
| 10 | `max_concurrent` | SMALLINT UNSIGNED | 📌 REQD DEFAULT `50` | Số job tối đa mà Cron Worker được phép xử lý cho server này trong 1 chu kỳ cron. Tránh quá tải API DirectAdmin |
| 11 | `backoff_until` | DATETIME | NULL 📋 IDX | Thời điểm hết thời gian chờ backoff. Nếu `NOW() < backoff_until` → Worker bỏ qua toàn bộ job của server này. `NULL` = server bình thường, không đang backoff |
| 12 | `backoff_count` | TINYINT UNSIGNED | 📌 REQD DEFAULT `0` | Số lần fail liên tiếp gần đây (dùng tính Exponential Backoff). Reset về `0` khi có job thành công |
| 13 | `last_success_at` | DATETIME | NULL | Thời điểm job cuối cùng thành công trên server này. Dùng hiển thị uptime trên Dashboard |
| 14 | `last_error_at` | DATETIME | NULL | Thời điểm lỗi gần nhất. Kết hợp với `last_success_at` để tính % uptime |
| 15 | `last_error_msg` | TEXT | NULL | Nội dung lỗi gần nhất (VD: "Connection timed out after 15000ms"). Chỉ hiển thị cho Admin |
| 16 | `sort_order` | TINYINT UNSIGNED | 📌 REQD DEFAULT `0` | Thứ tự hiển thị trong danh sách Admin. `0` = mặc định theo ID |
| 17 | `notes` | TEXT | NULL | Ghi chú nội bộ của Admin (VD: "Server đặt tại Viettel IDC HN", "Bảo trì mỗi Chủ nhật 2AM") |
| 18 | `created_at` | DATETIME | 📌 REQD 🕐 AUTO-TS | Thời điểm thêm server vào hệ thống |
| 19 | `updated_at` | DATETIME | 📌 REQD 🕐 AUTO-TS | Thời điểm cập nhật gần nhất (auto-update bởi Eloquent) |

**Indexes**:
- `uniq_hostname(hostname)` — Không cho 2 server trùng hostname
- `idx_active(is_active)` — Worker query nhanh server active
- `idx_backoff(backoff_until)` — Worker filter server đang backoff

**Dung lượng ước tính**: 3-10 rows (số DA Node trong hạ tầng).

```sql
CREATE TABLE mod_hvndns_servers (
    id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    hostname        VARCHAR(255) NOT NULL,
    ip_address      VARCHAR(45) NOT NULL,
    port            SMALLINT UNSIGNED NOT NULL DEFAULT 2222,
    username        VARCHAR(100) NOT NULL,
    password_enc    TEXT NOT NULL,
    use_ssl         TINYINT(1) NOT NULL DEFAULT 1,
    role            ENUM('primary','secondary') NOT NULL DEFAULT 'secondary',
    is_active       TINYINT(1) NOT NULL DEFAULT 1,
    max_concurrent  SMALLINT UNSIGNED NOT NULL DEFAULT 50,
    backoff_until   DATETIME NULL,
    backoff_count   TINYINT UNSIGNED NOT NULL DEFAULT 0,
    last_success_at DATETIME NULL,
    last_error_at   DATETIME NULL,
    last_error_msg  TEXT NULL,
    sort_order      TINYINT UNSIGNED NOT NULL DEFAULT 0,
    notes           TEXT NULL,
    created_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    UNIQUE INDEX uniq_hostname (hostname),
    INDEX idx_active (is_active),
    INDEX idx_backoff (backoff_until)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

---

## 5. mod_hvndns_domains

> **Mục đích**: Registry trung tâm cho tất cả tên miền đang sử dụng dịch vụ DNS. Mapping giữa domain ↔ WHMCS Service ↔ Quota Plan. Đây là bảng pivot quan trọng nhất — hầu hết bảng khác đều FK về đây.

| # | Cột | Kiểu | Ràng buộc | Mô tả |
|---|-----|------|-----------|-------|
| 1 | `id` | INT UNSIGNED | 🔑 PK ⚡ AUTO 📌 REQD | ID domain nội bộ trong module |
| 2 | `domain` | VARCHAR(253) | 📌 REQD 🦄 UNIQ | Tên miền đầy đủ (VD: `example.com`, `shop.vn`). Theo RFC 1035 tối đa 253 ký tự. Lưu dạng lowercase, không có dấu chấm cuối. Hỗ trợ IDN (Punycode: `xn--...`) |
| 3 | `whmcs_service_id` | INT UNSIGNED | NULL 📋 IDX | FK tới `tblhosting.id` trong WHMCS. Liên kết domain với dịch vụ Hosting/DNS mà khách đã mua. `NULL` = domain được Admin tạo thủ công không qua order |
| 4 | `whmcs_user_id` | INT UNSIGNED | 📌 REQD 📋 IDX | FK tới `tblclients.id` trong WHMCS. Chủ sở hữu domain. Dùng để kiểm tra quyền truy cập Client Area. BẮT BUỘC — mỗi domain phải thuộc 1 client |
| 5 | `status` | ENUM('active', 'suspended', 'terminated', 'pending_delete') | 📌 REQD DEFAULT `'active'` 📋 IDX | Trạng thái domain: `active` = hoạt động bình thường, Client có thể chỉnh sửa DNS; `suspended` = tạm ngưng (nợ phí), Client chỉ xem readonly, zone vẫn hoạt động trên DA; `terminated` = đã hủy, chuyển sang `pending_delete`; `pending_delete` = đang trong grace period 30 ngày trước khi xóa zone khỏi DA |
| 6 | `ssl_status` | ENUM('none', 'pending', 'active', 'expired', 'failed') | 📌 REQD DEFAULT `'none'` | Trạng thái chứng chỉ SSL Let's Encrypt: `none` = chưa yêu cầu; `pending` = đang chờ cấp phát; `active` = đang hoạt động; `expired` = đã hết hạn; `failed` = cấp phát thất bại |
| 7 | `ssl_expires_at` | DATETIME | NULL | Ngày hết hạn SSL certificate. Cron `ssl_checker` kiểm tra cột này để tự gia hạn khi còn < 7 ngày |
| 8 | `quota_plan_id` | INT UNSIGNED | NULL 🔗 FK | FK tới `mod_hvndns_quota_plans.id`. Gói giới hạn tài nguyên áp dụng cho domain này. `NULL` = không giới hạn (unlimited) hoặc chưa cấu hình |
| 9 | `default_ip` | VARCHAR(45) | NULL | IP mặc định cho domain (dùng khi áp template). Lấy từ WHMCS Product custom field hoặc Admin nhập tay |
| 10 | `notes` | TEXT | NULL | Ghi chú nội bộ Admin (VD: "Khách VIP — ưu tiên xử lý", "Domain đang chờ transfer NS") |
| 11 | `provisioned_at` | DATETIME | NULL | Thời điểm zone được tạo thành công trên TẤT CẢ DA Node. `NULL` = chưa provision xong (vẫn đang queue) |
| 12 | `suspended_at` | DATETIME | NULL | Thời điểm domain bị suspend. Dùng cho báo cáo |
| 13 | `terminated_at` | DATETIME | NULL | Thời điểm domain bị terminate. Grace period 30 ngày tính từ mốc này |
| 14 | `created_at` | DATETIME | 📌 REQD 🕐 AUTO-TS | Thời điểm domain được thêm vào module |
| 15 | `updated_at` | DATETIME | 📌 REQD 🕐 AUTO-TS | Thời điểm cập nhật gần nhất |

**Indexes**:
- `uniq_domain(domain)` — 1 domain chỉ tồn tại 1 lần
- `idx_whmcs_user(whmcs_user_id)` — Query tất cả domain của 1 client
- `idx_whmcs_service(whmcs_service_id)` — Lookup từ WHMCS service
- `idx_status(status)` — Filter theo trạng thái

**Dung lượng ước tính**: 100–5,000 rows.

```sql
CREATE TABLE mod_hvndns_domains (
    id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    domain          VARCHAR(253) NOT NULL,
    whmcs_service_id INT UNSIGNED NULL,
    whmcs_user_id   INT UNSIGNED NOT NULL,
    status          ENUM('active','suspended','terminated','pending_delete') NOT NULL DEFAULT 'active',
    ssl_status      ENUM('none','pending','active','expired','failed') NOT NULL DEFAULT 'none',
    ssl_expires_at  DATETIME NULL,
    quota_plan_id   INT UNSIGNED NULL,
    default_ip      VARCHAR(45) NULL,
    notes           TEXT NULL,
    provisioned_at  DATETIME NULL,
    suspended_at    DATETIME NULL,
    terminated_at   DATETIME NULL,
    created_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    UNIQUE INDEX uniq_domain (domain),
    INDEX idx_whmcs_user (whmcs_user_id),
    INDEX idx_whmcs_service (whmcs_service_id),
    INDEX idx_status (status),
    FOREIGN KEY (quota_plan_id) REFERENCES mod_hvndns_quota_plans(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

---

## 6. mod_hvndns_records

> **Mục đích**: Lưu trữ tất cả bản ghi DNS của từng domain. Đây là **Source of Truth** — dữ liệu ở bảng này là chuẩn, DirectAdmin là target execution. Mọi thay đổi DNS đều ghi vào bảng này TRƯỚC, sau đó mới đồng bộ lên DA qua Queue.

| # | Cột | Kiểu | Ràng buộc | Mô tả |
|---|-----|------|-----------|-------|
| 1 | `id` | INT UNSIGNED | 🔑 PK ⚡ AUTO 📌 REQD | ID bản ghi nội bộ |
| 2 | `domain_id` | INT UNSIGNED | 📌 REQD 🔗 FK 📋 IDX | FK tới `mod_hvndns_domains.id`. Domain sở hữu record này. CASCADE DELETE — xóa domain thì xóa tất cả records |
| 3 | `type` | ENUM('A', 'AAAA', 'CNAME', 'MX', 'TXT', 'SRV', 'NS', 'CAA', 'PTR') | 📌 REQD | Loại bản ghi DNS theo chuẩn RFC. `A` = IPv4 address; `AAAA` = IPv6 address; `CNAME` = Canonical name (alias); `MX` = Mail exchange; `TXT` = Text (SPF, DKIM, verification); `SRV` = Service locator; `NS` = Nameserver; `CAA` = Certificate Authority Authorization; `PTR` = Pointer (reverse DNS) |
| 4 | `name` | VARCHAR(255) | 📌 REQD 📋 IDX | Phần subdomain/host của record. `@` = root domain (VD: `example.com`); `mail` = subdomain (VD: `mail.example.com`); `*` = wildcard; `_dmarc` = DMARC record; `_sip._tcp` = SRV service name. KHÔNG bao gồm domain chính — full name = `{name}.{domain}` |
| 5 | `value` | TEXT | 📌 REQD | Giá trị bản ghi. Nội dung tùy theo `type`: `A` → `103.1.2.3` (IPv4); `AAAA` → `2001:db8::1` (IPv6); `CNAME` → `target.example.com.` (FQDN có dấu chấm cuối); `MX` → `mail.example.com.` (FQDN); `TXT` → `"v=spf1 include:_spf.google.com ~all"` (có thể rất dài — DKIM key); `SRV` → `target.example.com.` (target hostname); `NS` → `dns1.hvn.vn.` (nameserver FQDN); `CAA` → `letsencrypt.org` (CA domain). Dùng TEXT vì TXT record (DKIM) có thể > 255 chars |
| 6 | `ttl` | INT UNSIGNED | 📌 REQD DEFAULT `3600` | Time To Live — thời gian cache record (giây). Range hợp lệ: 60–86400. `60` = 1 phút (thay đổi thường xuyên, VD: DDNS); `300` = 5 phút (thay đổi không thường xuyên); `3600` = 1 giờ (default, phù hợp hầu hết); `86400` = 24 giờ (ít thay đổi, VD: NS, MX). Validator enforce range 60–86400 |
| 7 | `priority` | SMALLINT UNSIGNED | NULL | Độ ưu tiên — chỉ dùng cho `MX` và `SRV`. Range: 0–65535. Với `MX`: số nhỏ = ưu tiên cao (VD: `10` cho primary mail server, `20` cho backup). Với `SRV`: priority of target host. `NULL` cho các record type khác |
| 8 | `weight` | SMALLINT UNSIGNED | NULL | Trọng số — chỉ dùng cho `SRV`. Range: 0–65535. Dùng cân bằng tải giữa các target cùng priority. Giá trị cao = nhận nhiều traffic hơn. `NULL` cho các record type khác |
| 9 | `port` | SMALLINT UNSIGNED | NULL | Cổng dịch vụ — chỉ dùng cho `SRV`. Range: 1–65535. VD: `5060` cho SIP, `443` cho HTTPS. `NULL` cho các record type khác |
| 10 | `is_system` | TINYINT(1) | 📌 REQD DEFAULT `0` | Record hệ thống? `1` = NS và SOA records, được tạo tự động khi provision, CLIENT KHÔNG được sửa/xóa (chỉ Admin). `0` = record thường, Client có quyền CRUD |
| 11 | `is_locked` | TINYINT(1) | 📌 REQD DEFAULT `0` | Record bị khóa bởi Admin? `1` = Admin đã khóa record này, Client không sửa/xóa được dù không phải is_system. Dùng khi Admin muốn bảo vệ record quan trọng (VD: A record chính trỏ về hosting). `0` = bình thường |
| 12 | `pending_delete` | TINYINT(1) | 📌 REQD DEFAULT `0` | Record đang chờ xóa trên DA? `1` = User đã yêu cầu xóa, job DELETE đã vào queue, UI hiển thị "Deleting..." mờ. Chỉ xóa khỏi DB sau khi DA confirm delete thành công. `0` = bình thường |
| 13 | `created_at` | DATETIME | 📌 REQD 🕐 AUTO-TS | Thời điểm record được tạo |
| 14 | `updated_at` | DATETIME | 📌 REQD 🕐 AUTO-TS | Thời điểm sửa gần nhất. Dùng cho Optimistic Locking (kiểm tra trước khi save) |

**Indexes**:
- `idx_domain_type(domain_id, type)` — Lọc records theo domain và type
- `idx_domain_name(domain_id, name)` — Lookup record theo domain + subdomain
- FK: `domain_id → mod_hvndns_domains(id) ON DELETE CASCADE`

**Dung lượng ước tính**: 5,000–100,000 rows (trung bình 20 records/domain × 5,000 domains).

```sql
CREATE TABLE mod_hvndns_records (
    id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    domain_id       INT UNSIGNED NOT NULL,
    type            ENUM('A','AAAA','CNAME','MX','TXT','SRV','NS','CAA','PTR') NOT NULL,
    name            VARCHAR(255) NOT NULL,
    value           TEXT NOT NULL,
    ttl             INT UNSIGNED NOT NULL DEFAULT 3600,
    priority        SMALLINT UNSIGNED NULL,
    weight          SMALLINT UNSIGNED NULL,
    port            SMALLINT UNSIGNED NULL,
    is_system       TINYINT(1) NOT NULL DEFAULT 0,
    is_locked       TINYINT(1) NOT NULL DEFAULT 0,
    pending_delete  TINYINT(1) NOT NULL DEFAULT 0,
    created_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    INDEX idx_domain_type (domain_id, type),
    INDEX idx_domain_name (domain_id, name),
    FOREIGN KEY (domain_id) REFERENCES mod_hvndns_domains(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

---

## 7. mod_hvndns_queue

> **Mục đích**: Bảng trung tâm của kiến trúc bất đồng bộ — lưu mọi tác vụ cần đồng bộ lên DirectAdmin. Cron Worker đọc bảng này mỗi phút để thực thi. Đây là bảng có tần suất READ/WRITE cao nhất trong toàn hệ thống.

| # | Cột | Kiểu | Ràng buộc | Mô tả |
|---|-----|------|-----------|-------|
| 1 | `id` | INT UNSIGNED | 🔑 PK ⚡ AUTO 📌 REQD | ID job nội bộ |
| 2 | `batch_id` | CHAR(36) | 📌 REQD 📋 IDX | UUID v4 nhóm các sub-jobs cùng 1 lệnh dispatch. Khi fan-out ra 3 server, cả 3 job có cùng `batch_id`. Dùng để tính aggregate status (3/3 complete?) và cho Client poll sync status |
| 3 | `domain_id` | INT UNSIGNED | 📌 REQD 🔗 FK 📋 IDX | FK tới `mod_hvndns_domains.id`. Domain mà job này tác động. Dùng để group jobs theo domain |
| 4 | `server_id` | INT UNSIGNED | 📌 REQD 🔗 FK 📋 IDX | FK tới `mod_hvndns_servers.id`. Server đích mà job này sẽ gửi API tới. Mỗi sub-job trong batch nhắm vào 1 server khác nhau |
| 5 | `action` | ENUM('ADD_RECORD', 'EDIT_RECORD', 'DELETE_RECORD', 'CREATE_ZONE', 'DELETE_ZONE', 'CREATE_REDIRECT', 'EDIT_REDIRECT', 'DELETE_REDIRECT', 'CREATE_EMAIL_FWD', 'DELETE_EMAIL_FWD', 'ENABLE_DNSSEC', 'DISABLE_DNSSEC', 'RESIGN_ZONE', 'REQUEST_SSL', 'RENEW_SSL') | 📌 REQD | Loại tác vụ cần thực thi. Mỗi action tương ứng 1 DA API command. Worker sử dụng `DACommandMap` để map action → API endpoint + parameters |
| 6 | `payload` | JSON | 📌 REQD | Dữ liệu chi tiết cho tác vụ ở dạng JSON. Cấu trúc khác nhau tùy action — xem SPEC.md Section 4.2 "Payload JSON format". VD ADD_RECORD: `{"record_id":123, "type":"A", "name":"mail", "value":"103.1.2.3", "ttl":3600}`. VD EDIT_RECORD: `{"record_id":123, "old_value":"1.2.3.4", "new_value":"5.6.7.8", ...}` |
| 7 | `status` | ENUM('PENDING', 'SYNCING', 'COMPLETE', 'FAILED', 'CANCELLED', 'PERMANENTLY_FAILED') | 📌 REQD DEFAULT `'PENDING'` 📋 IDX | Trạng thái job: `PENDING` = chờ Worker xử lý; `SYNCING` = Worker đang xử lý (row locked); `COMPLETE` = DA xác nhận thành công; `FAILED` = lỗi, sẽ retry nếu còn attempts; `CANCELLED` = bị hủy bởi Conflict Resolution hoặc Admin; `PERMANENTLY_FAILED` = hết retry hoặc lỗi non-retryable (auth fail, zone not found) |
| 8 | `priority` | TINYINT UNSIGNED | 📌 REQD DEFAULT `5` | Độ ưu tiên xử lý. `1` = cao nhất (Admin action). `2` = provision/terminate. `5` = default (Client action). `7` = auto resign DNSSEC. `8` = SSL request. `9` = drift auto-fix. Worker pick job ORDER BY priority ASC |
| 9 | `attempts` | TINYINT UNSIGNED | 📌 REQD DEFAULT `0` | Số lần đã thử thực thi (bao gồm lần đầu). Tăng 1 sau mỗi lần Worker xử lý. Khi `attempts >= max_attempts` → chuyển `PERMANENTLY_FAILED` |
| 10 | `max_attempts` | TINYINT UNSIGNED | 📌 REQD DEFAULT `5` | Số lần thử tối đa. Default 5. Có thể override per-action (VD: SSL request cho 3 lần vì Let's Encrypt rate limit) |
| 11 | `next_retry_at` | DATETIME | NULL 📋 IDX | Thời điểm sớm nhất job được phép retry. `NULL` = sẵn sàng ngay (lần chạy đầu). Sau mỗi lần FAILED: `next_retry_at = NOW() + 2^attempts phút`. Worker chỉ pick job khi `next_retry_at IS NULL OR next_retry_at <= NOW()` |
| 12 | `locked_by` | VARCHAR(50) | NULL | Process ID của Worker đang xử lý job. Format: `{hostname}:{pid}` (VD: `whmcs-srv:12345`). Dùng để phát hiện stale lock — nếu `locked_by` có giá trị mà `locked_at` > 5 phút → stale, cần recover |
| 13 | `locked_at` | DATETIME | NULL | Thời điểm Worker lock job. Kết hợp với `locked_by` để phát hiện stale lock |
| 14 | `error_message` | TEXT | NULL | Nội dung lỗi gần nhất từ DA hoặc network. VD: `"Connection timed out after 15000ms"`, `"HTTP 403: Invalid login credentials"`, `"DNS record already exists"`. Được ghi đè mỗi lần retry |
| 15 | `error_type` | VARCHAR(50) | NULL | Phân loại lỗi chuẩn hóa: `timeout`, `auth_fail`, `dns_conflict`, `zone_not_found`, `zone_exists`, `rate_limit`, `server_error`, `network_error`, `unknown`. Dùng để xác định job có retryable không |
| 16 | `actor_type` | ENUM('client', 'admin', 'system', 'api') | 📌 REQD DEFAULT `'client'` | Ai tạo job? `client` = khách hàng từ Client Area; `admin` = quản trị viên từ Admin Area; `system` = tự động (provision, re-sign, SSL renew); `api` = qua DDNS endpoint hoặc REST API. Dùng cho Conflict Resolution (Admin > Client) |
| 17 | `actor_id` | INT UNSIGNED | NULL | ID của người tạo. Nếu `actor_type = 'client'` → `tblclients.id`. Nếu `actor_type = 'admin'` → `tbladmins.id`. Nếu `system/api` → `NULL` |
| 18 | `scheduled_at` | DATETIME | 📌 REQD 🕐 AUTO-TS 📋 IDX | Thời điểm job được tạo và lên lịch. Worker pick job ORDER BY `scheduled_at ASC` (FIFO trong cùng priority) |
| 19 | `started_at` | DATETIME | NULL | Thời điểm Worker bắt đầu xử lý job (set SYNCING). Dùng tính `duration = completed_at - started_at` |
| 20 | `completed_at` | DATETIME | NULL | Thời điểm job hoàn thành (COMPLETE hoặc PERMANENTLY_FAILED). `NULL` = chưa hoàn thành |
| 21 | `created_at` | DATETIME | 📌 REQD 🕐 AUTO-TS | Thời điểm record được INSERT |

**Indexes** (critical — ảnh hưởng trực tiếp performance của Worker):
- `idx_worker_pickup(status, next_retry_at, priority, scheduled_at)` — **INDEX QUAN TRỌNG NHẤT**. Worker query: `WHERE status='PENDING' AND (next_retry_at IS NULL OR next_retry_at <= NOW()) ORDER BY priority ASC, scheduled_at ASC`
- `idx_batch(batch_id)` — Aggregate status query
- `idx_domain_status(domain_id, status)` — Dashboard: pending jobs per domain
- `idx_server_status(server_id, status)` — Dashboard: pending jobs per server
- `idx_locked(locked_by, locked_at)` — Stale job recovery

**Dung lượng ước tính**: 10,000–500,000 rows (tích lũy theo thời gian, cần purge).

```sql
CREATE TABLE mod_hvndns_queue (
    id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    batch_id        CHAR(36) NOT NULL,
    domain_id       INT UNSIGNED NOT NULL,
    server_id       INT UNSIGNED NOT NULL,
    action          ENUM(
                        'ADD_RECORD','EDIT_RECORD','DELETE_RECORD',
                        'CREATE_ZONE','DELETE_ZONE',
                        'CREATE_REDIRECT','EDIT_REDIRECT','DELETE_REDIRECT',
                        'CREATE_EMAIL_FWD','DELETE_EMAIL_FWD',
                        'ENABLE_DNSSEC','DISABLE_DNSSEC','RESIGN_ZONE',
                        'REQUEST_SSL','RENEW_SSL'
                    ) NOT NULL,
    payload         JSON NOT NULL,
    status          ENUM('PENDING','SYNCING','COMPLETE','FAILED','CANCELLED','PERMANENTLY_FAILED')
                    NOT NULL DEFAULT 'PENDING',
    priority        TINYINT UNSIGNED NOT NULL DEFAULT 5,
    attempts        TINYINT UNSIGNED NOT NULL DEFAULT 0,
    max_attempts    TINYINT UNSIGNED NOT NULL DEFAULT 5,
    next_retry_at   DATETIME NULL,
    locked_by       VARCHAR(50) NULL,
    locked_at       DATETIME NULL,
    error_message   TEXT NULL,
    error_type      VARCHAR(50) NULL,
    actor_type      ENUM('client','admin','system','api') NOT NULL DEFAULT 'client',
    actor_id        INT UNSIGNED NULL,
    scheduled_at    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    started_at      DATETIME NULL,
    completed_at    DATETIME NULL,
    created_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    INDEX idx_worker_pickup (status, next_retry_at, priority, scheduled_at),
    INDEX idx_batch (batch_id),
    INDEX idx_domain_status (domain_id, status),
    INDEX idx_server_status (server_id, status),
    INDEX idx_locked (locked_by, locked_at),
    FOREIGN KEY (domain_id) REFERENCES mod_hvndns_domains(id),
    FOREIGN KEY (server_id) REFERENCES mod_hvndns_servers(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

---

## 8. mod_hvndns_sync_logs

> **Mục đích**: Ghi lại chi tiết từng lần Cron Worker gọi API tới DirectAdmin. Mỗi lần xử lý 1 job tạo ra 1 dòng sync_log. Dùng cho troubleshooting, tính uptime, và dashboard metrics.

| # | Cột | Kiểu | Ràng buộc | Mô tả |
|---|-----|------|-----------|-------|
| 1 | `id` | BIGINT UNSIGNED | 🔑 PK ⚡ AUTO 📌 REQD | ID log. Dùng BIGINT vì bảng này tăng nhanh (~150 rows/phút nếu cron chạy đầy tải) |
| 2 | `queue_id` | INT UNSIGNED | 📌 REQD 🔗 FK 📋 IDX | FK tới `mod_hvndns_queue.id`. Job nào sinh ra log entry này |
| 3 | `server_id` | INT UNSIGNED | 📌 REQD 🔗 FK 📋 IDX | FK tới `mod_hvndns_servers.id`. Server nào nhận API call |
| 4 | `http_method` | VARCHAR(10) | NULL | HTTP method đã dùng: `GET` hoặc `POST`. `NULL` nếu không kết nối được |
| 5 | `http_url` | VARCHAR(500) | NULL | URL API đã gọi (đã LOẠI BỎ password — chỉ giữ `https://{hostname}:{port}/CMD_API_...`). KHÔNG BAO GIỜ log URL chứa credentials |
| 6 | `http_status` | SMALLINT UNSIGNED | NULL | HTTP status code trả về: `200` = success; `403` = auth fail; `500` = server error. `NULL` = không nhận được response (timeout, connection refused) |
| 7 | `request_body` | TEXT | NULL | Nội dung request đã gửi (sanitized — loại bỏ password/token). Dùng cho debug khi cần reproduce lỗi |
| 8 | `response_body` | TEXT | NULL | Nội dung response từ DA (raw). Bao gồm error message nếu có. Cắt tối đa 10,000 ký tự để tránh bloat |
| 9 | `duration_ms` | INT UNSIGNED | NULL | Thời gian xử lý request (milliseconds). Từ lúc gửi request đến nhận response. `NULL` nếu timeout trước khi nhận response. Dùng tính average response time trên Dashboard |
| 10 | `success` | TINYINT(1) | 📌 REQD | Kết quả: `1` = DA xác nhận thành công; `0` = thất bại. Dùng tính tỷ lệ success/fail trên Dashboard |
| 11 | `error_type` | VARCHAR(50) | NULL | Phân loại lỗi (copy từ `DAResponse::$errorType`): `timeout`, `auth_fail`, `dns_conflict`, `zone_not_found`, `rate_limit`, `server_error`, `network_error`. `NULL` khi success |
| 12 | `created_at` | DATETIME | 📌 REQD 🕐 AUTO-TS | Thời điểm log được ghi |

**Indexes**:
- `idx_queue(queue_id)` — Xem log của 1 job cụ thể
- `idx_server_time(server_id, created_at)` — Dashboard: lọc log theo server + khoảng thời gian
- `idx_success_time(success, created_at)` — Dashboard: tính tỷ lệ success/fail

**Dung lượng ước tính**: 100,000–5,000,000 rows/năm. **Cần purge > 90 ngày**.

```sql
CREATE TABLE mod_hvndns_sync_logs (
    id              BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    queue_id        INT UNSIGNED NOT NULL,
    server_id       INT UNSIGNED NOT NULL,
    http_method     VARCHAR(10) NULL,
    http_url        VARCHAR(500) NULL,
    http_status     SMALLINT UNSIGNED NULL,
    request_body    TEXT NULL,
    response_body   TEXT NULL,
    duration_ms     INT UNSIGNED NULL,
    success         TINYINT(1) NOT NULL,
    error_type      VARCHAR(50) NULL,
    created_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    INDEX idx_queue (queue_id),
    INDEX idx_server_time (server_id, created_at),
    INDEX idx_success_time (success, created_at),
    FOREIGN KEY (queue_id) REFERENCES mod_hvndns_queue(id),
    FOREIGN KEY (server_id) REFERENCES mod_hvndns_servers(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

---

## 9. mod_hvndns_audit_trail

> **Mục đích**: Nhật ký kiểm toán bảo mật — ghi lại MỌI hành động thay đổi dữ liệu trong hệ thống. Bảng này là **APPEND-ONLY**: KHÔNG BAO GIỜ có lệnh UPDATE hoặc DELETE từ application layer. Dùng cho truy vết bảo mật, giải quyết tranh chấp, và compliance audit.

| # | Cột | Kiểu | Ràng buộc | Mô tả |
|---|-----|------|-----------|-------|
| 1 | `id` | BIGINT UNSIGNED | 🔑 PK ⚡ AUTO 📌 REQD 🚫 RO | ID audit entry. Dùng BIGINT cho bảng tích lũy dài hạn |
| 2 | `actor_type` | ENUM('client', 'admin', 'system', 'api') | 📌 REQD 🚫 RO | Loại người/hệ thống thực hiện hành động: `client` = khách hàng; `admin` = quản trị viên; `system` = tự động (cron, provisioning); `api` = DDNS endpoint hoặc REST API |
| 3 | `actor_id` | INT UNSIGNED | NULL 🚫 RO | ID người thực hiện. `client` → `tblclients.id`; `admin` → `tbladmins.id`; `system/api` → `NULL` |
| 4 | `actor_name` | VARCHAR(255) | NULL 🚫 RO | Tên hiển thị TẠI THỜI ĐIỂM GHI LOG. Lưu trực tiếp vì user có thể đổi tên sau — audit trail cần giữ tên lúc thao tác. VD: "Nguyễn Văn A", "Admin Vuong" |
| 5 | `domain` | VARCHAR(253) | 📌 REQD 📋 IDX 🚫 RO | Tên miền bị tác động. Lưu trực tiếp string (không FK) vì domain có thể bị xóa nhưng audit trail vẫn phải giữ |
| 6 | `domain_id` | INT UNSIGNED | NULL 🚫 RO | FK tới `mod_hvndns_domains.id` tại thời điểm ghi. Có thể `NULL` nếu domain đã bị xóa khỏi DB |
| 7 | `action` | VARCHAR(50) | 📌 REQD 📋 IDX 🚫 RO | Hành động đã thực hiện. Giá trị chuẩn: `add_record`, `edit_record`, `delete_record`, `create_zone`, `delete_zone`, `enable_dnssec`, `disable_dnssec`, `add_redirect`, `edit_redirect`, `delete_redirect`, `add_email_fwd`, `delete_email_fwd`, `load_template`, `zone_rollback`, `change_ssl`, `ddns_update`, `suspend_domain`, `unsuspend_domain`, `terminate_domain`, `override_conflict`, `retry_job`, `bulk_ip_change` |
| 8 | `target_type` | VARCHAR(50) | NULL 🚫 RO | Loại đối tượng bị tác động: `record`, `zone`, `redirect`, `email_forward`, `dnssec`, `ssl`, `domain`, `server`, `template`, `quota` |
| 9 | `target_id` | INT UNSIGNED | NULL 🚫 RO | ID đối tượng bị tác động (VD: record ID, redirect ID). `NULL` nếu tác động toàn zone |
| 10 | `old_value` | JSON | NULL 🚫 RO | Giá trị TRƯỚC thay đổi ở dạng JSON. `NULL` nếu là action tạo mới. VD edit record: `{"type":"A", "name":"mail", "value":"103.1.2.3", "ttl":3600}` |
| 11 | `new_value` | JSON | NULL 🚫 RO | Giá trị SAU thay đổi ở dạng JSON. `NULL` nếu là action xóa. VD edit record: `{"type":"A", "name":"mail", "value":"103.1.2.4", "ttl":3600}` |
| 12 | `context` | VARCHAR(100) | NULL 🚫 RO | Ngữ cảnh thực hiện: `client_editor` = từ Client DNS Editor; `admin_editor` = từ Admin DNS Editor; `admin_global` = từ Admin Global Domain list; `ddns_api` = từ DDNS endpoint; `rest_api` = từ REST API; `cron_provision` = provision tự động; `cron_terminate` = terminate tự động; `cron_drift_fix` = auto-fix drift; `bulk_operation` = thay đổi hàng loạt |
| 13 | `ip_address` | VARCHAR(45) | 📌 REQD 📋 IDX 🚫 RO | Địa chỉ IP nguồn của request. IPv4 hoặc IPv6. Với cron/system: ghi IP server WHMCS |
| 14 | `user_agent` | VARCHAR(500) | NULL 🚫 RO | User-Agent header của trình duyệt/client. Dùng xác định thiết bị. VD: `"Mozilla/5.0 (Windows NT 10.0; Win64)..."` hoặc `"MikroTik/7.x DDNS"`. Với cron: `"HVN-DNS-Worker/1.0"` |
| 15 | `session_id` | VARCHAR(100) | NULL 🚫 RO | WHMCS session ID tại thời điểm thao tác. Dùng liên kết nhiều thao tác trong cùng 1 phiên làm việc. `NULL` cho cron/api |
| 16 | `notes` | TEXT | NULL 🚫 RO | Ghi chú bổ sung. VD: `"Overridden by Admin #5"`, `"Rollback to snapshot #45 created 2026-02-24"`, `"Bulk IP change: 103.1.2.3 → 103.1.2.4 affecting 15 domains"` |
| 17 | `created_at` | DATETIME | 📌 REQD 🕐 AUTO-TS 🚫 RO | Thời điểm ghi log. KHÔNG BAO GIỜ thay đổi |

**⚠️ NGUYÊN TẮC APPEND-ONLY**: Model `AuditTrail` KHÔNG được định nghĩa method `update()`, `delete()`, `save()` (chỉ có `create()`). Không tạo route/endpoint nào cho phép sửa/xóa bảng này.

**Indexes**:
- `idx_domain_time(domain, created_at)` — Truy vết lịch sử 1 domain
- `idx_actor(actor_type, actor_id, created_at)` — Xem mọi thao tác của 1 người
- `idx_action_time(action, created_at)` — Thống kê loại thao tác theo thời gian
- `idx_ip_time(ip_address, created_at)` — Truy vết IP đáng ngờ

**Dung lượng ước tính**: 500,000–10,000,000 rows/năm. **Retention tối thiểu 365 ngày**.

```sql
CREATE TABLE mod_hvndns_audit_trail (
    id              BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    actor_type      ENUM('client','admin','system','api') NOT NULL,
    actor_id        INT UNSIGNED NULL,
    actor_name      VARCHAR(255) NULL,
    domain          VARCHAR(253) NOT NULL,
    domain_id       INT UNSIGNED NULL,
    action          VARCHAR(50) NOT NULL,
    target_type     VARCHAR(50) NULL,
    target_id       INT UNSIGNED NULL,
    old_value       JSON NULL,
    new_value       JSON NULL,
    context         VARCHAR(100) NULL,
    ip_address      VARCHAR(45) NOT NULL,
    user_agent      VARCHAR(500) NULL,
    session_id      VARCHAR(100) NULL,
    notes           TEXT NULL,
    created_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    INDEX idx_domain_time (domain, created_at),
    INDEX idx_actor (actor_type, actor_id, created_at),
    INDEX idx_action_time (action, created_at),
    INDEX idx_ip_time (ip_address, created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

---

## 10. mod_hvndns_record_history

> **Mục đích**: Lưu lịch sử thay đổi chi tiết cho từng DNS record. Mỗi lần record bị tạo/sửa/xóa đều ghi 1 dòng. Khác với audit_trail (ghi ở tầng hành động), record_history ghi ở tầng dữ liệu — cho phép "Undo" thay đổi từng record riêng lẻ.

| # | Cột | Kiểu | Ràng buộc | Mô tả |
|---|-----|------|-----------|-------|
| 1 | `id` | BIGINT UNSIGNED | 🔑 PK ⚡ AUTO 📌 REQD | ID history entry |
| 2 | `record_id` | INT UNSIGNED | 📌 REQD 📋 IDX | FK tới `mod_hvndns_records.id`. Record nào bị thay đổi. Không dùng ON DELETE CASCADE vì muốn giữ history kể cả record đã xóa |
| 3 | `domain_id` | INT UNSIGNED | 📌 REQD 📋 IDX | FK tới `mod_hvndns_domains.id`. Lưu thừa để query nhanh "lịch sử tất cả records của domain X" mà không cần JOIN |
| 4 | `change_type` | ENUM('created', 'updated', 'deleted') | 📌 REQD | Loại thay đổi: `created` = record vừa được tạo mới; `updated` = record bị sửa; `deleted` = record bị xóa |
| 5 | `old_type` | VARCHAR(10) | NULL | Record type TRƯỚC thay đổi. `NULL` nếu `change_type = 'created'` |
| 6 | `old_name` | VARCHAR(255) | NULL | Giá trị name TRƯỚC. `NULL` nếu `created` |
| 7 | `old_value` | TEXT | NULL | Giá trị value TRƯỚC. `NULL` nếu `created` |
| 8 | `old_ttl` | INT UNSIGNED | NULL | TTL TRƯỚC. `NULL` nếu `created` |
| 9 | `old_priority` | SMALLINT UNSIGNED | NULL | Priority TRƯỚC (MX/SRV). `NULL` nếu `created` hoặc không áp dụng |
| 10 | `new_type` | VARCHAR(10) | NULL | Record type SAU thay đổi. `NULL` nếu `change_type = 'deleted'` |
| 11 | `new_name` | VARCHAR(255) | NULL | Giá trị name SAU. `NULL` nếu `deleted` |
| 12 | `new_value` | TEXT | NULL | Giá trị value SAU. `NULL` nếu `deleted` |
| 13 | `new_ttl` | INT UNSIGNED | NULL | TTL SAU. `NULL` nếu `deleted` |
| 14 | `new_priority` | SMALLINT UNSIGNED | NULL | Priority SAU. `NULL` nếu `deleted` hoặc không áp dụng |
| 15 | `changed_by_type` | ENUM('client', 'admin', 'system', 'api') | 📌 REQD | Ai thay đổi |
| 16 | `changed_by_id` | INT UNSIGNED | NULL | ID người thay đổi |
| 17 | `created_at` | DATETIME | 📌 REQD 🕐 AUTO-TS | Thời điểm thay đổi xảy ra |

**Dung lượng ước tính**: 100,000–2,000,000 rows/năm. **Purge > 90 ngày**.

```sql
CREATE TABLE mod_hvndns_record_history (
    id              BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    record_id       INT UNSIGNED NOT NULL,
    domain_id       INT UNSIGNED NOT NULL,
    change_type     ENUM('created','updated','deleted') NOT NULL,
    old_type        VARCHAR(10) NULL,
    old_name        VARCHAR(255) NULL,
    old_value       TEXT NULL,
    old_ttl         INT UNSIGNED NULL,
    old_priority    SMALLINT UNSIGNED NULL,
    new_type        VARCHAR(10) NULL,
    new_name        VARCHAR(255) NULL,
    new_value       TEXT NULL,
    new_ttl         INT UNSIGNED NULL,
    new_priority    SMALLINT UNSIGNED NULL,
    changed_by_type ENUM('client','admin','system','api') NOT NULL,
    changed_by_id   INT UNSIGNED NULL,
    created_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    INDEX idx_record_time (record_id, created_at),
    INDEX idx_domain_time (domain_id, created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

---

## 11. mod_hvndns_snapshots

> **Mục đích**: Lưu bản sao toàn bộ zone DNS tại một thời điểm. Dùng cho Zone Rollback — khi khách cấu hình sai, Admin có thể khôi phục zone về trạng thái trước đó.

| # | Cột | Kiểu | Ràng buộc | Mô tả |
|---|-----|------|-----------|-------|
| 1 | `id` | INT UNSIGNED | 🔑 PK ⚡ AUTO 📌 REQD | ID snapshot |
| 2 | `domain_id` | INT UNSIGNED | 📌 REQD 🔗 FK 📋 IDX | FK tới `mod_hvndns_domains.id`. Domain nào |
| 3 | `snapshot_type` | ENUM('scheduled', 'pre_bulk', 'pre_template', 'manual') | 📌 REQD DEFAULT `'scheduled'` | Lý do tạo snapshot: `scheduled` = nightly cron tự tạo; `pre_bulk` = tự động trước bulk operation; `pre_template` = tự động trước load template; `manual` = Admin bấm nút tạo thủ công |
| 4 | `records_data` | JSON | 📌 REQD | Toàn bộ records của zone ở dạng JSON array. VD: `[{"type":"A","name":"@","value":"1.2.3.4","ttl":3600}, ...]`. Đây là full snapshot, đủ để restore hoàn toàn zone |
| 5 | `record_count` | SMALLINT UNSIGNED | 📌 REQD | Số lượng records trong snapshot. Dùng hiển thị nhanh mà không cần parse JSON |
| 6 | `trigger_info` | VARCHAR(255) | NULL | Thông tin bổ sung: `"Nightly backup 2026-02-25"`, `"Before bulk IP change 1.2.3.4→5.6.7.8"`, `"Before load template: Basic DNS"` |
| 7 | `created_by` | ENUM('system', 'admin') | 📌 REQD DEFAULT `'system'` | Ai tạo snapshot |
| 8 | `created_by_id` | INT UNSIGNED | NULL | Admin ID nếu tạo thủ công |
| 9 | `created_at` | DATETIME | 📌 REQD 🕐 AUTO-TS | Thời điểm tạo snapshot |

**Rolling retention**: Giữ tối đa 30 snapshots/domain. Cron cleanup xóa cũ nhất khi vượt quá.

```sql
CREATE TABLE mod_hvndns_snapshots (
    id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    domain_id       INT UNSIGNED NOT NULL,
    snapshot_type   ENUM('scheduled','pre_bulk','pre_template','manual') NOT NULL DEFAULT 'scheduled',
    records_data    JSON NOT NULL,
    record_count    SMALLINT UNSIGNED NOT NULL,
    trigger_info    VARCHAR(255) NULL,
    created_by      ENUM('system','admin') NOT NULL DEFAULT 'system',
    created_by_id   INT UNSIGNED NULL,
    created_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    INDEX idx_domain_time (domain_id, created_at),
    FOREIGN KEY (domain_id) REFERENCES mod_hvndns_domains(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

---

## 12. mod_hvndns_templates

> **Mục đích**: Lưu các mẫu DNS template do Admin tạo. Áp dụng tự động khi provision domain mới hoặc cho phép Client reset DNS về mẫu.

| # | Cột | Kiểu | Ràng buộc | Mô tả |
|---|-----|------|-----------|-------|
| 1 | `id` | INT UNSIGNED | 🔑 PK ⚡ AUTO 📌 REQD | ID template |
| 2 | `name` | VARCHAR(100) | 📌 REQD 🦄 UNIQ | Tên template. VD: "Basic DNS", "Email Optimized", "E-commerce Full" |
| 3 | `description` | TEXT | NULL | Mô tả chi tiết template dành cho Admin/Client hiểu mục đích |
| 4 | `is_default` | TINYINT(1) | 📌 REQD DEFAULT `0` | Template mặc định? `1` = áp dụng tự động khi provision domain mới. CHỈ ĐƯỢC 1 template là default tại 1 thời điểm |
| 5 | `records_data` | JSON | 📌 REQD | Danh sách records mẫu ở dạng JSON array. Hỗ trợ placeholder: `{{domain}}` = tên miền thực, `{{ip}}` = IP mặc định, `{{ns1}}`, `{{ns2}}`, `{{ns3}}` = nameserver. VD: `[{"type":"NS","name":"@","value":"{{ns1}}."},{"type":"A","name":"@","value":"{{ip}}"}]` |
| 6 | `is_visible_client` | TINYINT(1) | 📌 REQD DEFAULT `1` | Client có thể thấy và chọn template này? `0` = chỉ Admin dùng (VD: template nội bộ) |
| 7 | `created_at` | DATETIME | 📌 REQD 🕐 AUTO-TS | Thời điểm tạo |
| 8 | `updated_at` | DATETIME | 📌 REQD 🕐 AUTO-TS | Thời điểm cập nhật |

```sql
CREATE TABLE mod_hvndns_templates (
    id                  INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name                VARCHAR(100) NOT NULL,
    description         TEXT NULL,
    is_default          TINYINT(1) NOT NULL DEFAULT 0,
    records_data        JSON NOT NULL,
    is_visible_client   TINYINT(1) NOT NULL DEFAULT 1,
    created_at          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    UNIQUE INDEX uniq_name (name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

---

## 13. mod_hvndns_quota_plans

> **Mục đích**: Định nghĩa các gói giới hạn tài nguyên DNS. Map vào WHMCS Product để phân tầng dịch vụ (Basic/Pro/Enterprise).

| # | Cột | Kiểu | Ràng buộc | Mô tả |
|---|-----|------|-----------|-------|
| 1 | `id` | INT UNSIGNED | 🔑 PK ⚡ AUTO 📌 REQD | ID plan |
| 2 | `plan_name` | VARCHAR(100) | 📌 REQD 🦄 UNIQ | Tên gói. VD: "DNS Basic", "DNS Pro", "DNS Enterprise" |
| 3 | `max_records` | SMALLINT UNSIGNED | 📌 REQD DEFAULT `50` | Số bản ghi DNS tối đa cho 1 domain. `0` = unlimited |
| 4 | `max_subdomains` | SMALLINT UNSIGNED | 📌 REQD DEFAULT `20` | Số subdomain riêng biệt tối đa. `0` = unlimited |
| 5 | `max_redirects` | SMALLINT UNSIGNED | 📌 REQD DEFAULT `5` | Số URL redirect tối đa. `0` = unlimited |
| 6 | `max_email_fwd` | SMALLINT UNSIGNED | 📌 REQD DEFAULT `10` | Số email forwarder tối đa. `0` = unlimited |
| 7 | `max_ddns_tokens` | SMALLINT UNSIGNED | 📌 REQD DEFAULT `2` | Số DDNS token tối đa. `0` = unlimited |
| 8 | `ddns_enabled` | TINYINT(1) | 📌 REQD DEFAULT `0` | Gói này cho phép DDNS? `0` = không, `1` = có |
| 9 | `dnssec_enabled` | TINYINT(1) | 📌 REQD DEFAULT `0` | Gói này cho phép DNSSEC? `0` = không, `1` = có |
| 10 | `ssl_enabled` | TINYINT(1) | 📌 REQD DEFAULT `0` | Gói này cho phép Auto-SSL? `0` = không, `1` = có |
| 11 | `created_at` | DATETIME | 📌 REQD 🕐 AUTO-TS | Thời điểm tạo |
| 12 | `updated_at` | DATETIME | 📌 REQD 🕐 AUTO-TS | Thời điểm cập nhật |

```sql
CREATE TABLE mod_hvndns_quota_plans (
    id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    plan_name       VARCHAR(100) NOT NULL,
    max_records     SMALLINT UNSIGNED NOT NULL DEFAULT 50,
    max_subdomains  SMALLINT UNSIGNED NOT NULL DEFAULT 20,
    max_redirects   SMALLINT UNSIGNED NOT NULL DEFAULT 5,
    max_email_fwd   SMALLINT UNSIGNED NOT NULL DEFAULT 10,
    max_ddns_tokens SMALLINT UNSIGNED NOT NULL DEFAULT 2,
    ddns_enabled    TINYINT(1) NOT NULL DEFAULT 0,
    dnssec_enabled  TINYINT(1) NOT NULL DEFAULT 0,
    ssl_enabled     TINYINT(1) NOT NULL DEFAULT 0,
    created_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    UNIQUE INDEX uniq_plan_name (plan_name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

---

## 14. mod_hvndns_dnssec

> **Mục đích**: Lưu thông số DNSSEC (DS Records) cho từng domain. Sau khi enable DNSSEC trên DA, thông tin keys được lưu ở đây để hiển thị cho Client mang đi cấu hình tại nhà đăng ký.

| # | Cột | Kiểu | Ràng buộc | Mô tả |
|---|-----|------|-----------|-------|
| 1 | `id` | INT UNSIGNED | 🔑 PK ⚡ AUTO 📌 REQD | ID entry |
| 2 | `domain_id` | INT UNSIGNED | 📌 REQD 🔗 FK 🦄 UNIQ | FK tới `mod_hvndns_domains.id`. Mỗi domain chỉ có 1 bản DNSSEC config |
| 3 | `is_enabled` | TINYINT(1) | 📌 REQD DEFAULT `0` | DNSSEC hiện đang bật? `1` = enabled trên DA, `0` = disabled |
| 4 | `key_tag` | INT UNSIGNED | NULL | Key Tag identifier. Số nguyên 16-bit (0–65535). Dùng nhận diện key. Lấy từ DA API sau khi enable |
| 5 | `algorithm` | SMALLINT UNSIGNED | NULL | Algorithm number theo IANA. Phổ biến: `8` = RSA/SHA-256; `13` = ECDSA P-256 (khuyến nghị); `14` = ECDSA P-384; `15` = Ed25519 |
| 6 | `digest_type` | SMALLINT UNSIGNED | NULL | Loại digest: `1` = SHA-1 (cũ, không khuyến nghị); `2` = SHA-256 (phổ biến); `4` = SHA-384 |
| 7 | `digest` | VARCHAR(512) | NULL | Chuỗi digest hex. Độ dài tùy thuộc digest_type: SHA-256 = 64 chars, SHA-384 = 96 chars |
| 8 | `ds_record_raw` | TEXT | NULL | Full DS record string đúng format để nhập vào nhà đăng ký. VD: `"12345 13 2 49FD46E6C4B45C55D4AC..."` |
| 9 | `public_key` | TEXT | NULL | DNSKEY public key (base64). Một số registrar yêu cầu |
| 10 | `last_signed_at` | DATETIME | NULL | Thời điểm zone được re-sign gần nhất (sau khi record thay đổi) |
| 11 | `created_at` | DATETIME | 📌 REQD 🕐 AUTO-TS | Thời điểm tạo |
| 12 | `updated_at` | DATETIME | 📌 REQD 🕐 AUTO-TS | Thời điểm cập nhật |

```sql
CREATE TABLE mod_hvndns_dnssec (
    id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    domain_id       INT UNSIGNED NOT NULL,
    is_enabled      TINYINT(1) NOT NULL DEFAULT 0,
    key_tag         INT UNSIGNED NULL,
    algorithm       SMALLINT UNSIGNED NULL,
    digest_type     SMALLINT UNSIGNED NULL,
    digest          VARCHAR(512) NULL,
    ds_record_raw   TEXT NULL,
    public_key      TEXT NULL,
    last_signed_at  DATETIME NULL,
    created_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    UNIQUE INDEX uniq_domain (domain_id),
    FOREIGN KEY (domain_id) REFERENCES mod_hvndns_domains(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

---

## 15. mod_hvndns_ddns_tokens

> **Mục đích**: Quản lý token xác thực cho DDNS endpoint. Router/Camera dùng token để cập nhật IP tự động mà không cần đăng nhập WHMCS.

| # | Cột | Kiểu | Ràng buộc | Mô tả |
|---|-----|------|-----------|-------|
| 1 | `id` | INT UNSIGNED | 🔑 PK ⚡ AUTO 📌 REQD | ID token |
| 2 | `domain_id` | INT UNSIGNED | 📌 REQD 🔗 FK 📋 IDX | FK tới `mod_hvndns_domains.id`. Domain chứa record cần cập nhật |
| 3 | `subdomain` | VARCHAR(255) | 📌 REQD DEFAULT `'@'` | Subdomain mà token này quản lý. `@` = root domain; `cam` = cam.example.com; `vpn` = vpn.example.com. Mỗi subdomain cần token riêng |
| 4 | `token_hash` | CHAR(64) | 📌 REQD 🦄 UNIQ #️⃣ HASH | SHA-256 hash của token gốc. Token gốc chỉ hiển thị 1 lần khi tạo, KHÔNG lưu plaintext. Khi router gửi request, hash token nhận được rồi so sánh với cột này |
| 5 | `label` | VARCHAR(100) | NULL | Nhãn do Client đặt. VD: "Camera văn phòng", "Router Mikrotik tầng 2". Giúp phân biệt khi có nhiều token |
| 6 | `last_ip` | VARCHAR(45) | NULL | IP gần nhất mà router đã report. Dùng so sánh — chỉ dispatch queue khi IP thay đổi (tránh spam) |
| 7 | `last_update_at` | DATETIME | NULL | Thời điểm IP cập nhật gần nhất (IP thực sự thay đổi, không phải mỗi lần gọi API) |
| 8 | `last_request_at` | DATETIME | NULL | Thời điểm request gần nhất (bất kể IP có đổi hay không). Dùng rate limit |
| 9 | `is_active` | TINYINT(1) | 📌 REQD DEFAULT `1` | Token còn hoạt động? `0` = revoked, request sẽ bị từ chối |
| 10 | `request_count` | INT UNSIGNED | 📌 REQD DEFAULT `0` | Tổng số request lifetime. Dùng thống kê |
| 11 | `created_at` | DATETIME | 📌 REQD 🕐 AUTO-TS | Thời điểm tạo token |

```sql
CREATE TABLE mod_hvndns_ddns_tokens (
    id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    domain_id       INT UNSIGNED NOT NULL,
    subdomain       VARCHAR(255) NOT NULL DEFAULT '@',
    token_hash      CHAR(64) NOT NULL,
    label           VARCHAR(100) NULL,
    last_ip         VARCHAR(45) NULL,
    last_update_at  DATETIME NULL,
    last_request_at DATETIME NULL,
    is_active       TINYINT(1) NOT NULL DEFAULT 1,
    request_count   INT UNSIGNED NOT NULL DEFAULT 0,
    created_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE INDEX uniq_token (token_hash),
    INDEX idx_domain_sub (domain_id, subdomain),
    FOREIGN KEY (domain_id) REFERENCES mod_hvndns_domains(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

---

## 16. mod_hvndns_redirects

> **Mục đích**: Lưu cấu hình chuyển hướng URL (301/302/Masked). Được quản lý tách biệt khỏi DNS records vì redirect đòi hỏi web server config, không chỉ DNS.

| # | Cột | Kiểu | Ràng buộc | Mô tả |
|---|-----|------|-----------|-------|
| 1 | `id` | INT UNSIGNED | 🔑 PK ⚡ AUTO 📌 REQD | ID redirect |
| 2 | `domain_id` | INT UNSIGNED | 📌 REQD 🔗 FK 📋 IDX | FK tới `mod_hvndns_domains.id` |
| 3 | `source_path` | VARCHAR(500) | 📌 REQD DEFAULT `'/'` | Đường dẫn nguồn trên domain. `/` = root; `/old-page` = path cụ thể. Không bao gồm domain |
| 4 | `destination_url` | VARCHAR(2000) | 📌 REQD | URL đích đầy đủ. VD: `https://newsite.com/landing`. Phải bắt đầu bằng `http://` hoặc `https://` |
| 5 | `redirect_type` | ENUM('301', '302', 'masked') | 📌 REQD DEFAULT `'301'` | Loại redirect: `301` = Permanent (SEO-friendly); `302` = Temporary; `masked` = URL masking (ẩn URL đích, hiển thị domain nguồn trên thanh địa chỉ) |
| 6 | `masked_title` | VARCHAR(255) | NULL | Tiêu đề trang khi dùng masked redirect. Chỉ áp dụng khi `redirect_type = 'masked'` |
| 7 | `masked_meta_desc` | VARCHAR(500) | NULL | Meta description cho SEO khi masked redirect |
| 8 | `is_active` | TINYINT(1) | 📌 REQD DEFAULT `1` | Redirect có hoạt động? `0` = tạm tắt |
| 9 | `created_at` | DATETIME | 📌 REQD 🕐 AUTO-TS | Thời điểm tạo |
| 10 | `updated_at` | DATETIME | 📌 REQD 🕐 AUTO-TS | Thời điểm cập nhật |

```sql
CREATE TABLE mod_hvndns_redirects (
    id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    domain_id       INT UNSIGNED NOT NULL,
    source_path     VARCHAR(500) NOT NULL DEFAULT '/',
    destination_url VARCHAR(2000) NOT NULL,
    redirect_type   ENUM('301','302','masked') NOT NULL DEFAULT '301',
    masked_title    VARCHAR(255) NULL,
    masked_meta_desc VARCHAR(500) NULL,
    is_active       TINYINT(1) NOT NULL DEFAULT 1,
    created_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    INDEX idx_domain (domain_id),
    UNIQUE INDEX uniq_domain_path (domain_id, source_path),
    FOREIGN KEY (domain_id) REFERENCES mod_hvndns_domains(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

---

## 17. mod_hvndns_email_forwards

> **Mục đích**: Quản lý email forwarding và catch-all. Đồng bộ qua Queue lên DirectAdmin.

| # | Cột | Kiểu | Ràng buộc | Mô tả |
|---|-----|------|-----------|-------|
| 1 | `id` | INT UNSIGNED | 🔑 PK ⚡ AUTO 📌 REQD | ID email forward |
| 2 | `domain_id` | INT UNSIGNED | 📌 REQD 🔗 FK 📋 IDX | FK tới `mod_hvndns_domains.id` |
| 3 | `source_address` | VARCHAR(255) | 📌 REQD | Phần local của email nguồn. VD: `info` (cho info@domain.com), `support`, `*` (catch-all) |
| 4 | `destination_email` | VARCHAR(500) | 📌 REQD | Email đích nhận forward. VD: `personal@gmail.com`. Phải là email hợp lệ |
| 5 | `is_catchall` | TINYINT(1) | 📌 REQD DEFAULT `0` | Có phải catch-all? `1` = mọi email không match forwarder cụ thể sẽ chuyển về `destination_email`. Mỗi domain chỉ có tối đa 1 catch-all |
| 6 | `is_active` | TINYINT(1) | 📌 REQD DEFAULT `1` | Forwarder có hoạt động? |
| 7 | `created_at` | DATETIME | 📌 REQD 🕐 AUTO-TS | Thời điểm tạo |
| 8 | `updated_at` | DATETIME | 📌 REQD 🕐 AUTO-TS | Thời điểm cập nhật |

```sql
CREATE TABLE mod_hvndns_email_forwards (
    id                  INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    domain_id           INT UNSIGNED NOT NULL,
    source_address      VARCHAR(255) NOT NULL,
    destination_email   VARCHAR(500) NOT NULL,
    is_catchall         TINYINT(1) NOT NULL DEFAULT 0,
    is_active           TINYINT(1) NOT NULL DEFAULT 1,
    created_at          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    INDEX idx_domain (domain_id),
    UNIQUE INDEX uniq_domain_source (domain_id, source_address),
    FOREIGN KEY (domain_id) REFERENCES mod_hvndns_domains(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

---

## 18. mod_hvndns_drift_reports

> **Mục đích**: Kết quả scan drift hàng đêm — phát hiện sự khác biệt giữa DNS trên DirectAdmin và DB local WHMCS.

| # | Cột | Kiểu | Ràng buộc | Mô tả |
|---|-----|------|-----------|-------|
| 1 | `id` | INT UNSIGNED | 🔑 PK ⚡ AUTO 📌 REQD | ID report |
| 2 | `domain_id` | INT UNSIGNED | 📌 REQD 🔗 FK 📋 IDX | FK tới `mod_hvndns_domains.id` |
| 3 | `server_id` | INT UNSIGNED | 📌 REQD 🔗 FK | FK tới `mod_hvndns_servers.id`. Server nào bị drift (thường query Primary server) |
| 4 | `drift_type` | ENUM('added_on_da', 'deleted_on_da', 'modified', 'missing_on_da') | 📌 REQD | Loại drift: `added_on_da` = record có trên DA nhưng không có trong WHMCS DB; `deleted_on_da` = record đã bị xóa trên DA nhưng WHMCS DB vẫn còn; `modified` = cả hai đều có nhưng giá trị khác nhau; `missing_on_da` = WHMCS DB có nhưng DA không có (đồng nghĩa sync đang lỗi) |
| 5 | `record_type` | VARCHAR(10) | 📌 REQD | Loại DNS record bị drift (A, CNAME, MX, ...) |
| 6 | `record_name` | VARCHAR(255) | 📌 REQD | Subdomain/name của record bị drift |
| 7 | `local_value` | TEXT | NULL | Giá trị trong WHMCS DB. `NULL` nếu `drift_type = 'added_on_da'` (WHMCS không có) |
| 8 | `remote_value` | TEXT | NULL | Giá trị trên DirectAdmin. `NULL` nếu `drift_type = 'missing_on_da'` (DA không có) |
| 9 | `resolution` | ENUM('pending', 'pull_da', 'push_whmcs', 'ignored', 'auto_fixed') | 📌 REQD DEFAULT `'pending'` 📋 IDX | Cách xử lý: `pending` = chờ Admin quyết định; `pull_da` = lấy giá trị DA ghi đè WHMCS; `push_whmcs` = đẩy giá trị WHMCS ghi đè DA; `ignored` = bỏ qua; `auto_fixed` = module tự sửa (khi auto-fix enabled) |
| 10 | `resolved_by` | INT UNSIGNED | NULL | Admin ID đã xử lý. `NULL` nếu auto_fixed hoặc pending |
| 11 | `resolved_at` | DATETIME | NULL | Thời điểm xử lý |
| 12 | `detected_at` | DATETIME | 📌 REQD 🕐 AUTO-TS | Thời điểm phát hiện drift |

```sql
CREATE TABLE mod_hvndns_drift_reports (
    id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    domain_id       INT UNSIGNED NOT NULL,
    server_id       INT UNSIGNED NOT NULL,
    drift_type      ENUM('added_on_da','deleted_on_da','modified','missing_on_da') NOT NULL,
    record_type     VARCHAR(10) NOT NULL,
    record_name     VARCHAR(255) NOT NULL,
    local_value     TEXT NULL,
    remote_value    TEXT NULL,
    resolution      ENUM('pending','pull_da','push_whmcs','ignored','auto_fixed') NOT NULL DEFAULT 'pending',
    resolved_by     INT UNSIGNED NULL,
    resolved_at     DATETIME NULL,
    detected_at     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    INDEX idx_domain_res (domain_id, resolution),
    INDEX idx_resolution (resolution, detected_at),
    FOREIGN KEY (domain_id) REFERENCES mod_hvndns_domains(id) ON DELETE CASCADE,
    FOREIGN KEY (server_id) REFERENCES mod_hvndns_servers(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

---

## 19. mod_hvndns_ip_blacklist

> **Mục đích**: Danh sách IP bị tạm chặn do phát hiện hành vi brute force trên DDNS endpoint. Auto-expire sau thời gian cấu hình.

| # | Cột | Kiểu | Ràng buộc | Mô tả |
|---|-----|------|-----------|-------|
| 1 | `id` | INT UNSIGNED | 🔑 PK ⚡ AUTO 📌 REQD | ID entry |
| 2 | `ip_address` | VARCHAR(45) | 📌 REQD 🦄 UNIQ | IP bị block (IPv4 hoặc IPv6) |
| 3 | `reason` | VARCHAR(255) | 📌 REQD | Lý do block. VD: `"DDNS brute force: 15 invalid tokens in 5 minutes from this IP"` |
| 4 | `fail_count` | INT UNSIGNED | 📌 REQD DEFAULT `0` | Số lần request thất bại trước khi bị block. Dùng cho thống kê |
| 5 | `blocked_until` | DATETIME | 📌 REQD 📋 IDX | Thời điểm hết hạn block. Cron hoặc ddns.php kiểm tra: `NOW() < blocked_until` → block. Hết hạn → tự bỏ block mà không cần xóa row |
| 6 | `created_at` | DATETIME | 📌 REQD 🕐 AUTO-TS | Thời điểm bắt đầu block |

```sql
CREATE TABLE mod_hvndns_ip_blacklist (
    id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    ip_address      VARCHAR(45) NOT NULL,
    reason          VARCHAR(255) NOT NULL,
    fail_count      INT UNSIGNED NOT NULL DEFAULT 0,
    blocked_until   DATETIME NOT NULL,
    created_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE INDEX uniq_ip (ip_address),
    INDEX idx_expiry (blocked_until)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

---

## 20. mod_hvndns_notification_cooldowns

> **Mục đích**: Kiểm soát tần suất gửi cảnh báo. Tránh spam Admin khi server down kéo dài — cùng 1 loại alert chỉ gửi 1 lần mỗi X phút.

| # | Cột | Kiểu | Ràng buộc | Mô tả |
|---|-----|------|-----------|-------|
| 1 | `id` | INT UNSIGNED | 🔑 PK ⚡ AUTO 📌 REQD | ID entry |
| 2 | `rule_id` | VARCHAR(50) | 📌 REQD | Mã rule cảnh báo: `RULE_01` (5 failed liên tiếp), `RULE_02` (server unreachable), `RULE_03` (queue backlog), v.v. Xem SPEC.md Section 11.2 |
| 3 | `scope_key` | VARCHAR(255) | 📌 REQD | Phạm vi áp dụng cooldown. VD: `server:1` (server_id=1), `global`, `domain:example.com`. Kết hợp với `rule_id` tạo thành unique key |
| 4 | `last_sent_at` | DATETIME | 📌 REQD | Thời điểm alert cuối cùng được gửi. `NotificationService` kiểm tra: `NOW() - last_sent_at < cooldown_seconds` → skip |
| 5 | `send_count` | INT UNSIGNED | 📌 REQD DEFAULT `1` | Số lần đã gửi alert cùng loại (lifetime). Dùng thống kê |
| 6 | `created_at` | DATETIME | 📌 REQD 🕐 AUTO-TS | Thời điểm tạo entry (lần gửi đầu tiên) |

```sql
CREATE TABLE mod_hvndns_notification_cooldowns (
    id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    rule_id         VARCHAR(50) NOT NULL,
    scope_key       VARCHAR(255) NOT NULL,
    last_sent_at    DATETIME NOT NULL,
    send_count      INT UNSIGNED NOT NULL DEFAULT 1,
    created_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE INDEX uniq_rule_scope (rule_id, scope_key)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

---

## 21. Phụ lục: Index Strategy

### 21.1. Tổng hợp tất cả Indexes

| Bảng | Index Name | Columns | Type | Mục đích |
|------|-----------|---------|------|----------|
| servers | `uniq_hostname` | hostname | UNIQUE | Không trùng hostname |
| servers | `idx_active` | is_active | INDEX | Worker filter server active |
| servers | `idx_backoff` | backoff_until | INDEX | Worker filter server đang backoff |
| domains | `uniq_domain` | domain | UNIQUE | Không trùng domain |
| domains | `idx_whmcs_user` | whmcs_user_id | INDEX | Query domains theo client |
| domains | `idx_whmcs_service` | whmcs_service_id | INDEX | Lookup từ WHMCS service |
| domains | `idx_status` | status | INDEX | Filter theo trạng thái |
| records | `idx_domain_type` | domain_id, type | COMPOSITE | Lọc records theo domain + type |
| records | `idx_domain_name` | domain_id, name | COMPOSITE | Lookup record cụ thể |
| **queue** | **`idx_worker_pickup`** | **status, next_retry_at, priority, scheduled_at** | **COMPOSITE** | **🔴 CRITICAL — Worker query chính** |
| queue | `idx_batch` | batch_id | INDEX | Aggregate status |
| queue | `idx_domain_status` | domain_id, status | COMPOSITE | Dashboard per domain |
| queue | `idx_server_status` | server_id, status | COMPOSITE | Dashboard per server |
| queue | `idx_locked` | locked_by, locked_at | COMPOSITE | Stale recovery |
| sync_logs | `idx_queue` | queue_id | INDEX | Log per job |
| sync_logs | `idx_server_time` | server_id, created_at | COMPOSITE | Dashboard metrics |
| sync_logs | `idx_success_time` | success, created_at | COMPOSITE | Success rate |
| audit_trail | `idx_domain_time` | domain, created_at | COMPOSITE | Lịch sử domain |
| audit_trail | `idx_actor` | actor_type, actor_id, created_at | COMPOSITE | Lịch sử user |
| audit_trail | `idx_action_time` | action, created_at | COMPOSITE | Thống kê action |
| audit_trail | `idx_ip_time` | ip_address, created_at | COMPOSITE | Truy vết IP |
| record_history | `idx_record_time` | record_id, created_at | COMPOSITE | Lịch sử record |
| record_history | `idx_domain_time` | domain_id, created_at | COMPOSITE | Lịch sử domain |
| drift_reports | `idx_domain_res` | domain_id, resolution | COMPOSITE | Filter pending drifts |
| drift_reports | `idx_resolution` | resolution, detected_at | COMPOSITE | Dashboard pending count |

### 21.2. Critical Path — Worker Query

Đây là query chạy MỖI PHÚT, quyết định performance toàn hệ thống:

```sql
SELECT * FROM mod_hvndns_queue
WHERE status = 'PENDING'
  AND (next_retry_at IS NULL OR next_retry_at <= NOW())
  AND server_id IN (/* active, non-backoff server IDs */)
ORDER BY priority ASC, scheduled_at ASC
FOR UPDATE SKIP LOCKED
LIMIT 150;
```

Index `idx_worker_pickup(status, next_retry_at, priority, scheduled_at)` PHẢI được sử dụng. Kiểm tra bằng `EXPLAIN` sau khi deploy.

---

## 22. Phụ lục: Data Retention Policy

| Bảng | Retention | Cơ chế xóa | Ghi chú |
|------|-----------|------------|---------|
| schema_version | Vĩnh viễn | Không xóa | < 100 rows |
| servers | Vĩnh viễn | Admin xóa thủ công | < 10 rows |
| domains | 30 ngày sau terminate | Cron cleanup | Soft-delete → hard-delete |
| records | Xóa cùng domain | CASCADE | — |
| **queue** | **30 ngày (COMPLETE/CANCELLED)** | **Cron cleanup** | **Bảng lớn nhất — cần purge thường xuyên** |
| **sync_logs** | **90 ngày** | **Cron cleanup** | **Tăng nhanh nhất** |
| **audit_trail** | **365 ngày (tối thiểu)** | **Maintenance script** | **APPEND-ONLY, archive trước khi xóa** |
| record_history | 90 ngày | Cron cleanup | — |
| snapshots | 30 bản/domain (rolling) | Cron cleanup | Xóa cũ nhất khi vượt quota |
| templates | Vĩnh viễn | Admin xóa thủ công | < 20 rows |
| quota_plans | Vĩnh viễn | Admin xóa thủ công | < 10 rows |
| dnssec | Xóa cùng domain | CASCADE | — |
| ddns_tokens | Xóa cùng domain | CASCADE | — |
| redirects | Xóa cùng domain | CASCADE | — |
| email_forwards | Xóa cùng domain | CASCADE | — |
| drift_reports | 90 ngày | Cron cleanup | Chỉ giữ pending |
| ip_blacklist | Auto-expire | Cron cleanup expired entries | — |
| notification_cooldowns | 7 ngày | Cron cleanup | Không cần giữ lâu |

**Cron cleanup chạy lúc**: 4:00 AM hàng ngày (file `cron/cleanup.php`).

---

> **Tài liệu này là phiên bản sống (living document)**. Mọi thay đổi schema phải được cập nhật tại đây VÀ tạo migration version mới trong `app/Migration/versions/`.

## Changelog

| Ngày | Phiên bản | Thay đổi | Người thực hiện |
|------|-----------|----------|-----------------|
| 25/02/2026 | 1.0 | Khởi tạo — 18 bảng đầy đủ | — |
