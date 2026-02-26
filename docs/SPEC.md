# HVN - DirectAdmin DNS Manager
## Technical Specification Document (SPEC)

> **Phiên bản**: 1.0  
> **Ngày tạo**: 25/02/2026  
> **Phân loại**: Tài liệu kỹ thuật nội bộ — Dành cho Developer & DevOps  
> **Tham chiếu**: Kế hoạch phát triển v2.0 & Epics/Stories Document v1.0  

---

## Mục lục

1. [Tổng quan Hệ thống](#1-tổng-quan-hệ-thống)
2. [Yêu cầu Hệ thống & Môi trường](#2-yêu-cầu-hệ-thống--môi-trường)
3. [Kiến trúc Hệ thống (System Architecture)](#3-kiến-trúc-hệ-thống)
4. [Database Schema](#4-database-schema)
5. [Luồng Hoạt động Chi tiết (Flow Diagrams)](#5-luồng-hoạt-động-chi-tiết)
6. [API Specification — DA Gateway](#6-api-specification--da-gateway)
7. [Queue Engine Specification](#7-queue-engine-specification)
8. [Cron Worker Specification](#8-cron-worker-specification)
9. [Security Specification](#9-security-specification)
10. [Frontend Specification](#10-frontend-specification)
11. [Webhook & Notification Specification](#11-webhook--notification-specification)
12. [Performance Targets & Constraints](#12-performance-targets--constraints)
13. [Error Handling & Recovery Matrix](#13-error-handling--recovery-matrix)
14. [Deployment & Configuration Guide](#14-deployment--configuration-guide)

---

## 1. Tổng quan Hệ thống

### 1.1. Định nghĩa

**HVN - DirectAdmin DNS Manager** là một WHMCS Addon Module cho phép khách hàng và quản trị viên quản lý bản ghi DNS thông qua giao diện WHMCS, đồng bộ bất đồng bộ (Queue-based) tới cụm máy chủ DirectAdmin (multi-node).

### 1.2. Nguyên tắc thiết kế cốt lõi

- **Async-First**: Mọi thao tác thay đổi DNS đều đi qua hàng đợi (Queue). Không có bất kỳ API call nào tới DirectAdmin xảy ra trong request lifecycle của người dùng.
- **WHMCS-Native**: Sử dụng tối đa hạ tầng có sẵn của WHMCS (Eloquent ORM, Smarty Template, Monolog, Hook System) thay vì tự build lại.
- **Fan-out Multi-Node**: Một thay đổi DNS tạo ra N job song song cho N server DirectAdmin active.
- **Fail-Safe**: Hệ thống được thiết kế để chịu lỗi — DA server down không ảnh hưởng trải nghiệm người dùng, queue tự retry khi server phục hồi.
- **Single Source of Truth**: WHMCS Database là nguồn dữ liệu chính thức (authoritative). DirectAdmin là target execution layer.

### 1.3. Phạm vi Module

```
┌─────────────────────────────────────────────────┐
│                   WHMCS Server                   │
│                                                  │
│  ┌──────────────┐    ┌───────────────────────┐  │
│  │ Client Area  │───▶│   mod_hvndns_*        │  │
│  │ (Browser)    │    │   MySQL Tables         │  │
│  └──────────────┘    │   (Source of Truth)     │  │
│  ┌──────────────┐    └──────────┬────────────┘  │
│  │ Admin Area   │───▶           │               │
│  │ (Browser)    │               │               │
│  └──────────────┘               │               │
│  ┌──────────────┐               ▼               │
│  │ DDNS Client  │───▶  ┌──────────────────┐    │
│  │ (Router/IoT) │      │  Cron Worker      │    │
│  └──────────────┘      │  (1 min interval) │    │
│                         └────────┬─────────┘    │
│                                  │               │
└──────────────────────────────────┼───────────────┘
                                   │ HTTPS API
                    ┌──────────────┼──────────────┐
                    ▼              ▼               ▼
              ┌──────────┐  ┌──────────┐   ┌──────────┐
              │  dns1     │  │  dns2     │   │  dns3     │
              │  .hvn.vn  │  │  .hvn.vn  │   │  .hvn.vn  │
              │ (Primary) │  │(Secondary)│   │(Secondary)│
              └──────────┘  └──────────┘   └──────────┘
              DirectAdmin    DirectAdmin    DirectAdmin
```

---

## 2. Yêu cầu Hệ thống & Môi trường

### 2.1. WHMCS Server (Host)

| Thành phần | Yêu cầu tối thiểu | Khuyến nghị |
|------------|-------------------|-------------|
| WHMCS | 8.0+ | 8.9+ (Eloquent 9.x) |
| PHP | 7.4 | 8.1+ (fibers, enum support) |
| MySQL/MariaDB | 5.7 / 10.3 | 8.0 / 10.6+ |
| PHP Extensions | `curl`, `json`, `openssl`, `mbstring` | + `intl` cho IDN domain |
| Cron | System crontab hoặc WHMCS built-in cron | System crontab (chính xác hơn) |
| Disk Space | 50MB (module code) | + 500MB cho logs/snapshots |
| RAM | 256MB PHP memory_limit | 512MB (cho bulk operations) |

### 2.2. DirectAdmin Server (Target)

| Thành phần | Yêu cầu |
|------------|---------|
| DirectAdmin | 1.61+ (JSON API support) |
| API Access | Admin hoặc Reseller level account |
| API Port | 2222 (default) hoặc custom |
| SSL | Khuyến nghị HTTPS cho API communication |
| DNS Server | BIND/Named với DNSSEC support enabled |
| DNSSEC | `dnssec=1` trong `/usr/local/directadmin/conf/directadmin.conf` |

### 2.3. Network Requirements

| Kết nối | Yêu cầu |
|---------|---------|
| WHMCS → DA Nodes | Outbound HTTPS port 2222 (hoặc custom) |
| WHMCS → Telegram API | Outbound HTTPS 443 (cho webhook notifications) |
| WHMCS → Let's Encrypt | Outbound HTTPS 443 (qua DA proxy) |
| Client → WHMCS | Inbound HTTPS 443 (standard web) |
| Router/IoT → WHMCS | Inbound HTTPS 443 (DDNS endpoint) |

---

## 3. Kiến trúc Hệ thống

### 3.1. Kiến trúc Hệ thống (Layer Architecture)

```
┌─────────────────────────────────────────────────────────────┐
│                  TẦNG 0: LICENSE & FEATURE GATE              │
│                                                              │
│   ├── LicenseChecker         (Module license valid? call home)│
│   ├── FeatureGate            (dnssec_mode / ddns_mode)        │
│   └── ClientFeatureResolver  (Client đã mua addon? query DB)  │
├─────────────────────────────────────────────────────────────┤
│                  TẦNG 1: PRESENTATION LAYER                  │
│                                                              │
│   Client Area (Smarty + Alpine.js)                          │
│   ├── DNS Record Editor (CRUD)                              │
│   ├── Sync Tracker (Ajax Polling)                           │
│   ├── DDNS Token Manager                                    │
│   └── DNSSEC Panel                                          │
│                                                              │
│   Admin Area (Smarty + Alpine.js)                           │
│   ├── Dashboard & Metrics                                   │
│   ├── Server Management                                     │
│   ├── Global Domain Manager                                 │
│   ├── Sync Logs & Audit Trail                               │
│   └── Template & Quota Config                               │
├─────────────────────────────────────────────────────────────┤
│                  TẦNG 2: APPLICATION LAYER                   │
│                                                              │
│   Controllers                                                │
│   ├── ClientDnsController    (xử lý request Client Area)    │
│   ├── AdminDnsController     (xử lý request Admin Area)     │
│   ├── DdnsController         (xử lý DDNS API endpoint)      │
│   └── AjaxController         (xử lý Ajax polling/actions)   │
│                                                              │
│   Services                                                   │
│   ├── DnsRecordService       (business logic CRUD record)   │
│   ├── QueueManager           (dispatch & track jobs)        │
│   ├── ConflictResolver       (phát hiện & xử lý xung đột)  │
│   ├── QuotaEnforcer          (kiểm tra giới hạn)           │
│   ├── SnapshotService        (tạo & restore snapshots)      │
│   └── NotificationService    (gửi alerts Telegram/Email)    │
│                                                              │
│   Validators                                                 │
│   ├── DnsRecordValidator     (validate A/AAAA/MX/TXT/...)  │
│   ├── ConflictValidator      (kiểm tra CNAME conflict RFC) │
│   └── InputSanitizer         (XSS/SQLi protection)         │
├─────────────────────────────────────────────────────────────┤
│                  TẦNG 3: NODE ROUTER LAYER                   │
│                                                              │
│   ServerRegistry                                             │
│   ├── getActiveServers()      → List<Server>                │
│   ├── getServerById($id)      → Server                      │
│   ├── getServerHealth($id)    → HealthStatus                │
│   └── isServerInBackoff($id)  → bool                        │
│                                                              │
│   Fan-out Logic: 1 dispatch → N sub-jobs (1 per server)     │
├─────────────────────────────────────────────────────────────┤
│                  TẦNG 4: QUEUE & WORKER LAYER                │
│                                                              │
│   Queue Storage: mod_hvndns_queue (MySQL)                    │
│   ├── Status: PENDING → SYNCING → COMPLETE / FAILED         │
│   ├── Batch grouping via batch_id (UUID)                     │
│   └── Exponential Backoff tracking per server                │
│                                                              │
│   Cron Worker: queue_worker.php (runs every 1 min)           │
│   ├── Pick PENDING jobs (WHERE next_retry_at <= NOW())      │
│   ├── Row-level locking (SELECT ... FOR UPDATE)             │
│   ├── Execute via DAGateway                                  │
│   ├── Write sync_logs                                        │
│   ├── Write audit_trail                                      │
│   └── Trigger notifications on failure threshold             │
├─────────────────────────────────────────────────────────────┤
│                  TẦNG 5: DA GATEWAY LAYER                    │
│                                                              │
│   DAGateway (GuzzleHTTP wrapper)                             │
│   ├── Connection pool per server                             │
│   ├── Timeout: 15s connect, 30s request                     │
│   ├── Auth: HTTP Basic over HTTPS                           │
│   └── Response parser: DA format → DAResponse object         │
│                                                              │
│   Target: DirectAdmin API (CMD_API_DNS_CONTROL, etc.)        │
└─────────────────────────────────────────────────────────────┘
```

### 3.2. Cấu trúc Thư mục Module

```
modules/addons/hvn_dns_manager/
│
├── hvn_dns_manager.php              # Entry point (WHMCS addon functions)
├── hooks.php                         # WHMCS Hook registrations
├── cron/
│   └── queue_worker.php              # Cron worker entry point
│
├── app/
│   ├── Controllers/
│   │   ├── ClientDnsController.php
│   │   ├── AdminDnsController.php
│   │   ├── DdnsController.php
│   │   └── AjaxController.php
│   │
│   ├── Services/
│   │   ├── QueueManager.php
│   │   ├── DnsRecordService.php
│   │   ├── ConflictResolver.php
│   │   ├── QuotaEnforcer.php
│   │   ├── SnapshotService.php
│   │   ├── DriftDetector.php
│   │   └── NotificationService.php
│   │
│   ├── Models/
│   │   ├── Server.php                # Eloquent: mod_hvndns_servers
│   │   ├── Domain.php                # Eloquent: mod_hvndns_domains
│   │   ├── DnsRecord.php             # Eloquent: mod_hvndns_records
│   │   ├── QueueJob.php              # Eloquent: mod_hvndns_queue
│   │   ├── SyncLog.php               # Eloquent: mod_hvndns_sync_logs
│   │   ├── AuditTrail.php            # Eloquent: mod_hvndns_audit_trail
│   │   ├── DnssecKey.php             # Eloquent: mod_hvndns_dnssec
│   │   ├── DdnsToken.php             # Eloquent: mod_hvndns_ddns_tokens
│   │   ├── Snapshot.php              # Eloquent: mod_hvndns_snapshots
│   │   ├── RecordHistory.php         # Eloquent: mod_hvndns_record_history
│   │   ├── Template.php              # Eloquent: mod_hvndns_templates
│   │   ├── QuotaPlan.php             # Eloquent: mod_hvndns_quota_plans
│   │   ├── DriftReport.php           # Eloquent: mod_hvndns_drift_reports
│   │   └── IpBlacklist.php           # Eloquent: mod_hvndns_ip_blacklist
│   │
│   ├── Gateway/
│   │   ├── DAGateway.php             # GuzzleHTTP wrapper cho DA API
│   │   ├── DAResponse.php            # Standardized response object
│   │   └── DACommandMap.php          # Mapping action → DA API command
│   │
│   ├── Validators/
│   │   ├── DnsRecordValidator.php
│   │   ├── ConflictValidator.php
│   │   └── InputSanitizer.php
│   │
│   ├── Migration/
│   │   ├── MigrationRunner.php       # Schema migration engine
│   │   ├── versions/
│   │   │   ├── v1_0_0.php            # Initial schema
│   │   │   ├── v1_1_0.php            # Phase 2 additions
│   │   │   └── v1_2_0.php            # Phase 3 additions
│   │   └── SchemaVersion.php         # Eloquent: mod_hvndns_schema_version
│   │
│   └── Helpers/
│       ├── CryptoHelper.php          # Encrypt/decrypt DA passwords
│       ├── DnsFormatHelper.php       # Format/parse DNS values
│       └── ResponseHelper.php        # JSON response builder
│
├── templates/
│   ├── client/
│   │   ├── dns_editor.tpl
│   │   ├── sync_tracker.tpl
│   │   ├── ddns_manager.tpl
│   │   └── dnssec_panel.tpl
│   │
│   └── admin/
│       ├── dashboard.tpl
│       ├── server_config.tpl
│       ├── domain_list.tpl
│       ├── dns_editor_admin.tpl
│       ├── sync_logs.tpl
│       ├── audit_trail.tpl
│       ├── templates_manager.tpl
│       ├── quota_plans.tpl
│       ├── drift_report.tpl
│       └── bulk_operations.tpl
│
├── assets/
│   ├── css/
│   │   └── hvndns.css
│   ├── js/
│   │   ├── alpine.min.js             # Alpine.js (CDN fallback)
│   │   ├── dns-editor.js
│   │   ├── sync-tracker.js
│   │   └── admin-dashboard.js
│   └── img/
│       └── logo.svg
│
└── docs/
    ├── CHANGELOG.md
    ├── API.md                         # REST API documentation
    └── INSTALL.md
```

---

## 4. Database Schema

### 4.1. Entity Relationship Diagram (ERD)

```
mod_hvndns_servers (1)────────(N) mod_hvndns_queue
        │                              │
        │                              │ batch_id
        │                              │
mod_hvndns_domains (1)───────(N) mod_hvndns_records
        │         │                    │
        │         │                    │
        │         ├──(N) mod_hvndns_queue
        │         ├──(N) mod_hvndns_snapshots
        │         ├──(N) mod_hvndns_dnssec
        │         ├──(N) mod_hvndns_ddns_tokens
        │         ├──(N) mod_hvndns_drift_reports
        │         └──(1) mod_hvndns_quota_plans (via WHMCS product)
        │
        └──────────(N) mod_hvndns_audit_trail

mod_hvndns_queue (1)─────────(N) mod_hvndns_sync_logs
mod_hvndns_records (1)───────(N) mod_hvndns_record_history
```

### 4.2. Định nghĩa Bảng Chi tiết

#### `mod_hvndns_servers` — Cấu hình DA Node

```sql
CREATE TABLE mod_hvndns_servers (
    id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    hostname        VARCHAR(255) NOT NULL,          -- dns1.hvn.vn
    ip_address      VARCHAR(45) NOT NULL,            -- IPv4 hoặc IPv6
    port            SMALLINT UNSIGNED DEFAULT 2222,
    username        VARCHAR(100) NOT NULL,           -- DA admin username
    password_enc    TEXT NOT NULL,                    -- AES encrypted via WHMCS
    use_ssl         TINYINT(1) DEFAULT 1,
    role            ENUM('primary','secondary') DEFAULT 'secondary',
    is_active       TINYINT(1) DEFAULT 1,
    max_concurrent  SMALLINT UNSIGNED DEFAULT 50,    -- max jobs/cron cycle
    backoff_until   DATETIME NULL,                   -- NULL = không đang backoff
    backoff_count   TINYINT UNSIGNED DEFAULT 0,      -- số lần fail liên tiếp
    last_success_at DATETIME NULL,
    last_error_at   DATETIME NULL,
    last_error_msg  TEXT NULL,
    created_at      DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at      DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    INDEX idx_active (is_active),
    INDEX idx_backoff (backoff_until)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

**Ghi chú kỹ thuật**:
- `password_enc`: Sử dụng `WHMCS\Security\Encryption::encode()` để mã hóa. Decrypt bằng `::decode()` chỉ khi Cron Worker cần kết nối.
- `backoff_until`: Nếu `NOW() < backoff_until`, Worker sẽ bỏ qua server này. Reset về `NULL` khi có job thành công.
- `max_concurrent`: Worker sẽ `LIMIT` số job lấy ra cho server này mỗi chu kỳ cron.

---

#### `mod_hvndns_domains` — Mapping Domain ↔ WHMCS Service

```sql
CREATE TABLE mod_hvndns_domains (
    id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    domain          VARCHAR(253) NOT NULL,           -- RFC 1035: max 253 chars
    whmcs_service_id INT UNSIGNED NULL,              -- FK tới tblhosting.id
    whmcs_user_id   INT UNSIGNED NOT NULL,           -- FK tới tblclients.id
    status          ENUM('active','suspended','terminated','pending_delete') DEFAULT 'active',
    ssl_status      ENUM('none','pending','active','expired','failed') DEFAULT 'none',
    ssl_expires_at  DATETIME NULL,
    quota_plan_id   INT UNSIGNED NULL,               -- FK tới mod_hvndns_quota_plans
    notes           TEXT NULL,                        -- Admin notes
    provisioned_at  DATETIME NULL,                   -- Thời điểm zone tạo xong trên DA
    terminated_at   DATETIME NULL,
    created_at      DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at      DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    UNIQUE INDEX idx_domain (domain),
    INDEX idx_whmcs_user (whmcs_user_id),
    INDEX idx_whmcs_service (whmcs_service_id),
    INDEX idx_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

**Ghi chú kỹ thuật**:
- `domain` là UNIQUE — không có 2 service quản lý cùng 1 domain.
- `whmcs_service_id` là nullable vì Admin có thể tạo domain thủ công không gắn product.
- Khi `status = 'suspended'`, Client Area hiển thị read-only, không cho chỉnh sửa.
- Khi `status = 'terminated'` → `pending_delete` → cron xóa zone sau 30 ngày grace period.

---

#### `mod_hvndns_records` — Bản ghi DNS (Source of Truth)

```sql
CREATE TABLE mod_hvndns_records (
    id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    domain_id       INT UNSIGNED NOT NULL,
    type            ENUM('A','AAAA','CNAME','MX','TXT','SRV','NS','CAA','PTR') NOT NULL,
    name            VARCHAR(255) NOT NULL,           -- subdomain part (@ cho root)
    value           TEXT NOT NULL,                    -- IP, hostname, text value
    ttl             INT UNSIGNED DEFAULT 3600,        -- seconds
    priority        SMALLINT UNSIGNED NULL,           -- MX, SRV only
    weight          SMALLINT UNSIGNED NULL,           -- SRV only
    port            SMALLINT UNSIGNED NULL,           -- SRV only
    is_system       TINYINT(1) DEFAULT 0,            -- 1 = NS/SOA records, client không sửa được
    is_locked       TINYINT(1) DEFAULT 0,            -- 1 = Admin lock, client không sửa được
    pending_delete  TINYINT(1) DEFAULT 0,            -- 1 = đang chờ xóa trên DA
    created_at      DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at      DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    INDEX idx_domain_type (domain_id, type),
    INDEX idx_domain_name (domain_id, name),
    FOREIGN KEY (domain_id) REFERENCES mod_hvndns_domains(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

**Ghi chú kỹ thuật**:
- `name = '@'` đại diện cho root domain (ví dụ: `example.com` thay vì `sub.example.com`).
- `is_system = 1` cho NS records và SOA — Client không thể sửa/xóa, chỉ Admin mới có quyền.
- `pending_delete = 1` → UI hiển thị record mờ với badge "Deleting...", xóa khỏi DB sau khi DA confirm.
- `value` dùng TEXT vì TXT record có thể rất dài (DKIM keys > 255 chars).

---

#### `mod_hvndns_queue` — Hàng đợi Tác vụ (Heart of the System)

```sql
CREATE TABLE mod_hvndns_queue (
    id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    batch_id        CHAR(36) NOT NULL,               -- UUID v4 nhóm các sub-jobs
    domain_id       INT UNSIGNED NOT NULL,
    server_id       INT UNSIGNED NOT NULL,            -- Target DA node
    action          ENUM(
                        'ADD_RECORD','EDIT_RECORD','DELETE_RECORD',
                        'CREATE_ZONE','DELETE_ZONE',
                        'CREATE_REDIRECT','EDIT_REDIRECT','DELETE_REDIRECT',
                        'CREATE_EMAIL_FWD','DELETE_EMAIL_FWD',
                        'ENABLE_DNSSEC','DISABLE_DNSSEC','RESIGN_ZONE',
                        'REQUEST_SSL','RENEW_SSL'
                    ) NOT NULL,
    payload         JSON NOT NULL,                    -- Chi tiết tác vụ (record data, etc.)
    status          ENUM('PENDING','SYNCING','COMPLETE','FAILED','CANCELLED','PERMANENTLY_FAILED') 
                    DEFAULT 'PENDING',
    priority        TINYINT UNSIGNED DEFAULT 5,       -- 1 = cao nhất, 10 = thấp nhất
    attempts        TINYINT UNSIGNED DEFAULT 0,
    max_attempts    TINYINT UNSIGNED DEFAULT 5,
    next_retry_at   DATETIME NULL,                    -- Exponential backoff schedule
    locked_by       VARCHAR(50) NULL,                 -- Worker process ID (lock mechanism)
    locked_at       DATETIME NULL,
    error_message   TEXT NULL,                        -- Lỗi gần nhất
    actor_type      ENUM('client','admin','system','api') DEFAULT 'client',
    actor_id        INT UNSIGNED NULL,                -- WHMCS user/admin ID
    scheduled_at    DATETIME DEFAULT CURRENT_TIMESTAMP,
    started_at      DATETIME NULL,
    completed_at    DATETIME NULL,
    created_at      DATETIME DEFAULT CURRENT_TIMESTAMP,
    
    INDEX idx_status_schedule (status, next_retry_at, scheduled_at),
    INDEX idx_batch (batch_id),
    INDEX idx_domain_status (domain_id, status),
    INDEX idx_server_status (server_id, status),
    INDEX idx_locked (locked_by, locked_at),
    FOREIGN KEY (domain_id) REFERENCES mod_hvndns_domains(id),
    FOREIGN KEY (server_id) REFERENCES mod_hvndns_servers(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

**Ghi chú kỹ thuật**:
- **`batch_id`**: UUID v4 tạo bởi `QueueManager::dispatch()`. Khi fan-out ra 3 server, cả 3 job có cùng `batch_id`. Dùng để tính aggregate status.
- **`locked_by`**: Chứa `hostname:pid` của Worker process đang xử lý. Dùng kèm `locked_at` để phát hiện stale lock (> 5 phút = stale).
- **`priority`**: Job từ Admin có priority = 1 (cao nhất), Client = 5, System (auto-resign, auto-renew SSL) = 8. Worker pick job theo priority ASC.
- **`payload` JSON format** tùy theo action:

```json
// ADD_RECORD
{
    "record_id": 123,
    "type": "A",
    "name": "mail",
    "value": "103.1.2.3",
    "ttl": 3600
}

// EDIT_RECORD
{
    "record_id": 123,
    "old_value": "103.1.2.3",
    "new_value": "103.1.2.4",
    "type": "A",
    "name": "mail",
    "ttl": 3600
}

// DELETE_RECORD
{
    "record_id": 123,
    "type": "A",
    "name": "mail",
    "value": "103.1.2.3"
}

// CREATE_ZONE
{
    "template_id": 1,
    "records": [
        {"type": "NS", "name": "@", "value": "dns1.hvn.vn."},
        {"type": "NS", "name": "@", "value": "dns2.hvn.vn."},
        {"type": "NS", "name": "@", "value": "dns3.hvn.vn."},
        {"type": "A", "name": "@", "value": "103.1.2.3"}
    ]
}

// ENABLE_DNSSEC
{
    "action": "enable"
}

// REQUEST_SSL
{
    "type": "letsencrypt",
    "domain": "example.com",
    "www": true
}
```

---

#### `mod_hvndns_sync_logs` — Nhật ký Đồng bộ

```sql
CREATE TABLE mod_hvndns_sync_logs (
    id              BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    queue_id        INT UNSIGNED NOT NULL,
    server_id       INT UNSIGNED NOT NULL,
    http_method     VARCHAR(10) NULL,                -- GET, POST
    http_url        VARCHAR(500) NULL,               -- DA API endpoint (masked password)
    http_status     SMALLINT UNSIGNED NULL,           -- 200, 403, 500, NULL (timeout)
    request_body    TEXT NULL,                        -- Sanitized (no passwords)
    response_body   TEXT NULL,                        -- Raw DA response
    duration_ms     INT UNSIGNED NULL,                -- Thời gian xử lý (ms)
    success         TINYINT(1) NOT NULL,
    error_type      VARCHAR(50) NULL,                -- timeout, auth_fail, dns_conflict, etc.
    created_at      DATETIME DEFAULT CURRENT_TIMESTAMP,
    
    INDEX idx_queue (queue_id),
    INDEX idx_server_time (server_id, created_at),
    INDEX idx_success (success, created_at),
    FOREIGN KEY (queue_id) REFERENCES mod_hvndns_queue(id),
    FOREIGN KEY (server_id) REFERENCES mod_hvndns_servers(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

---

#### `mod_hvndns_audit_trail` — Nhật ký Kiểm toán (Append-Only)

```sql
CREATE TABLE mod_hvndns_audit_trail (
    id              BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    actor_type      ENUM('client','admin','system','api') NOT NULL,
    actor_id        INT UNSIGNED NULL,               -- WHMCS user/admin ID
    actor_name      VARCHAR(255) NULL,               -- Tên hiển thị tại thời điểm ghi
    domain          VARCHAR(253) NOT NULL,
    domain_id       INT UNSIGNED NULL,
    action          VARCHAR(50) NOT NULL,             -- add_record, edit_record, enable_dnssec, zone_rollback, ...
    target_type     VARCHAR(50) NULL,                -- record, redirect, dnssec, zone, ssl
    target_id       INT UNSIGNED NULL,
    old_value       JSON NULL,                        -- Giá trị trước thay đổi
    new_value       JSON NULL,                        -- Giá trị sau thay đổi
    context         VARCHAR(100) NULL,               -- "client_editor", "admin_editor", "ddns_api", "cron_provision"
    ip_address      VARCHAR(45) NOT NULL,
    user_agent      VARCHAR(500) NULL,
    session_id      VARCHAR(100) NULL,
    notes           TEXT NULL,                        -- "Overridden by Admin", "Rollback to snapshot #45"
    created_at      DATETIME DEFAULT CURRENT_TIMESTAMP,
    
    INDEX idx_domain_time (domain, created_at),
    INDEX idx_actor (actor_type, actor_id, created_at),
    INDEX idx_action (action, created_at),
    INDEX idx_ip (ip_address, created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

**QUAN TRỌNG — NGUYÊN TẮC APPEND-ONLY**:
- Bảng này **KHÔNG BAO GIỜ** có lệnh UPDATE hoặc DELETE từ application layer.
- Không tạo Eloquent method `update()` hay `delete()` trong Model `AuditTrail`.
- Retention: giữ tối thiểu 365 ngày. Xóa bản ghi cũ chỉ qua maintenance script riêng có log.

---

#### Các bảng bổ trợ (Phase 2 & 3)

```sql
-- mod_hvndns_dnssec
CREATE TABLE mod_hvndns_dnssec (
    id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    domain_id       INT UNSIGNED NOT NULL UNIQUE,
    is_enabled      TINYINT(1) DEFAULT 0,
    key_tag         INT UNSIGNED NULL,
    algorithm       SMALLINT UNSIGNED NULL,           -- 13 = ECDSA P-256, 8 = RSA SHA-256
    digest_type     SMALLINT UNSIGNED NULL,           -- 2 = SHA-256, 4 = SHA-384
    digest          VARCHAR(512) NULL,
    ds_record_raw   TEXT NULL,                        -- Full DS record string
    last_signed_at  DATETIME NULL,
    created_at      DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at      DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (domain_id) REFERENCES mod_hvndns_domains(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- mod_hvndns_ddns_tokens
CREATE TABLE mod_hvndns_ddns_tokens (
    id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    domain_id       INT UNSIGNED NOT NULL,
    subdomain       VARCHAR(255) NOT NULL DEFAULT '@',
    token_hash      CHAR(64) NOT NULL,               -- SHA-256 hash of token
    last_ip         VARCHAR(45) NULL,
    last_update_at  DATETIME NULL,
    is_active       TINYINT(1) DEFAULT 1,
    request_count   INT UNSIGNED DEFAULT 0,           -- Lifetime request counter
    created_at      DATETIME DEFAULT CURRENT_TIMESTAMP,
    UNIQUE INDEX idx_token (token_hash),
    INDEX idx_domain_sub (domain_id, subdomain),
    FOREIGN KEY (domain_id) REFERENCES mod_hvndns_domains(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- mod_hvndns_snapshots
CREATE TABLE mod_hvndns_snapshots (
    id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    domain_id       INT UNSIGNED NOT NULL,
    snapshot_type   ENUM('scheduled','pre_bulk','pre_template','manual') DEFAULT 'scheduled',
    records_data    JSON NOT NULL,                    -- Full zone snapshot
    record_count    SMALLINT UNSIGNED NOT NULL,
    trigger_info    VARCHAR(255) NULL,               -- "Nightly backup" / "Before bulk IP change"
    created_at      DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_domain_time (domain_id, created_at),
    FOREIGN KEY (domain_id) REFERENCES mod_hvndns_domains(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- mod_hvndns_record_history
CREATE TABLE mod_hvndns_record_history (
    id              BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    record_id       INT UNSIGNED NOT NULL,
    domain_id       INT UNSIGNED NOT NULL,
    change_type     ENUM('created','updated','deleted') NOT NULL,
    old_type        VARCHAR(10) NULL,
    old_name        VARCHAR(255) NULL,
    old_value       TEXT NULL,
    old_ttl         INT UNSIGNED NULL,
    new_type        VARCHAR(10) NULL,
    new_name        VARCHAR(255) NULL,
    new_value       TEXT NULL,
    new_ttl         INT UNSIGNED NULL,
    changed_by_type ENUM('client','admin','system','api') NOT NULL,
    changed_by_id   INT UNSIGNED NULL,
    created_at      DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_record (record_id, created_at),
    INDEX idx_domain (domain_id, created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- mod_hvndns_templates
CREATE TABLE mod_hvndns_templates (
    id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name            VARCHAR(100) NOT NULL,
    description     TEXT NULL,
    is_default      TINYINT(1) DEFAULT 0,
    records_data    JSON NOT NULL,                    -- Template records with {{placeholders}}
    created_at      DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at      DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- mod_hvndns_quota_plans
CREATE TABLE mod_hvndns_quota_plans (
    id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    plan_name       VARCHAR(100) NOT NULL,
    max_records     SMALLINT UNSIGNED DEFAULT 50,
    max_subdomains  SMALLINT UNSIGNED DEFAULT 20,
    max_redirects   SMALLINT UNSIGNED DEFAULT 5,
    max_email_fwd   SMALLINT UNSIGNED DEFAULT 10,
    ddns_enabled    TINYINT(1) DEFAULT 0,
    dnssec_enabled  TINYINT(1) DEFAULT 0,
    created_at      DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at      DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- mod_hvndns_drift_reports
CREATE TABLE mod_hvndns_drift_reports (
    id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    domain_id       INT UNSIGNED NOT NULL,
    server_id       INT UNSIGNED NOT NULL,
    drift_type      ENUM('added_on_da','deleted_on_da','modified','missing_on_da') NOT NULL,
    record_type     VARCHAR(10) NOT NULL,
    record_name     VARCHAR(255) NOT NULL,
    local_value     TEXT NULL,
    remote_value    TEXT NULL,
    resolution      ENUM('pending','pull_da','push_whmcs','ignored','auto_fixed') DEFAULT 'pending',
    resolved_by     INT UNSIGNED NULL,
    resolved_at     DATETIME NULL,
    detected_at     DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_domain_status (domain_id, resolution),
    FOREIGN KEY (domain_id) REFERENCES mod_hvndns_domains(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- mod_hvndns_ip_blacklist
CREATE TABLE mod_hvndns_ip_blacklist (
    id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    ip_address      VARCHAR(45) NOT NULL,
    reason          VARCHAR(255) NOT NULL,
    blocked_until   DATETIME NOT NULL,
    created_at      DATETIME DEFAULT CURRENT_TIMESTAMP,
    UNIQUE INDEX idx_ip (ip_address),
    INDEX idx_expiry (blocked_until)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- mod_hvndns_schema_version
CREATE TABLE mod_hvndns_schema_version (
    id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    version         VARCHAR(20) NOT NULL,
    description     VARCHAR(255) NULL,
    executed_at     DATETIME DEFAULT CURRENT_TIMESTAMP,
    UNIQUE INDEX idx_version (version)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

---

## 5. Luồng Hoạt động Chi tiết

### 5.1. FLOW-01: Client Thêm Bản ghi DNS (Core Flow)

Đây là luồng quan trọng nhất, mô tả toàn bộ lifecycle từ lúc user nhấn "Save" đến khi DNS thực sự thay đổi trên server.

**Ghi chú Cache Strategy (tham chiếu SETTINGS.md #68-70)**:
Khi Client mở DNS Editor, hệ thống load records theo setting `fetch_from_ns_on_load`:
- `false` (mặc định): Load từ `mod_hvndns_records` (< 50ms). Background refresh nếu cache > `cache_refresh_ttl`
- `true`: Gọi DA API getZone() realtime (500-1500ms), so sánh + update DB, rồi render

```
CLIENT BROWSER                  WHMCS SERVER                           DATABASE                        CRON WORKER                     DIRECTADMIN NODES
─────────────                   ────────────                           ────────                        ───────────                     ─────────────────
     │                               │                                     │                               │                               │
     │  1. POST /dns/add             │                                     │                               │                               │
     │  {type:A, name:mail,          │                                     │                               │                               │
     │   value:103.1.2.3, ttl:3600}  │                                     │                               │                               │
     │──────────────────────────────▶│                                     │                               │                               │
     │                               │                                     │                               │                               │
     │                               │  2. InputSanitizer::clean()         │                               │                               │
     │                               │  3. DnsRecordValidator::validate()  │                               │                               │
     │                               │     ├─ IP format check (A record)   │                               │                               │
     │                               │     ├─ CNAME conflict check (RFC)   │                               │                               │
     │                               │     └─ TTL range check (60-86400)   │                               │                               │
     │                               │                                     │                               │                               │
     │                               │  4. QuotaEnforcer::check()          │                               │                               │
     │                               │     └─ Đếm record hiện tại         │                               │                               │
     │                               │        vs quota plan limit          │                               │                               │
     │                               │                                     │                               │                               │
     │                               │  5. ConflictResolver::check()       │                               │                               │
     │                               │     └─ Có job PENDING trùng record? │                               │                               │
     │                               │                                     │                               │                               │
     │                               │  6. INSERT mod_hvndns_records       │                               │                               │
     │                               │─────────────────────────────────────▶│  record_id = 456              │                               │
     │                               │                                     │                               │                               │
     │                               │  7. QueueManager::dispatch(         │                               │                               │
     │                               │       domain_id, ADD_RECORD,        │                               │                               │
     │                               │       {record_id: 456, ...})        │                               │                               │
     │                               │                                     │                               │                               │
     │                               │     ServerRegistry::getActive()     │                               │                               │
     │                               │     └─ Returns [dns1, dns2, dns3]   │                               │                               │
     │                               │                                     │                               │                               │
     │                               │  8. INSERT 3x mod_hvndns_queue      │                               │                               │
     │                               │     batch_id = "abc-123-def"        │                               │                               │
     │                               │─────────────────────────────────────▶│  job #1 → dns1 PENDING        │                               │
     │                               │─────────────────────────────────────▶│  job #2 → dns2 PENDING        │                               │
     │                               │─────────────────────────────────────▶│  job #3 → dns3 PENDING        │                               │
     │                               │                                     │                               │                               │
     │                               │  9. INSERT mod_hvndns_audit_trail   │                               │                               │
     │                               │─────────────────────────────────────▶│  actor=client, action=add     │                               │
     │                               │                                     │                               │                               │
     │  10. JSON {success: true,     │                                     │                               │                               │
     │      batch_id: "abc-123-def", │                                     │                               │                               │
     │      message: "Đã lưu!"}     │                                     │                               │                               │
     │◀──────────────────────────────│                                     │                               │                               │
     │                               │                                     │                               │                               │
     │  UI: Record xuất hiện với     │                                     │                               │                               │
     │  badge 🟡 "Pending"           │                                     │                               │                               │
     │  Bắt đầu poll Ajax/5s        │                                     │                               │                               │
     │                               │                                     │                               │                               │
     ═══════════ THỜI GIAN TRÔI QUA (0-60 GIÂY) ════════════════════════════                               │                               │
     │                               │                                     │                               │                               │
     │                               │                                     │  11. Cron trigger (mỗi phút)  │                               │
     │                               │                                     │                               │                               │
     │                               │                                     │  12. SELECT * FROM queue      │                               │
     │                               │                                     │      WHERE status='PENDING'    │                               │
     │                               │                                     │      AND next_retry_at<=NOW() │                               │
     │                               │                                     │      AND server not in backoff │                               │
     │                               │                                     │      ORDER BY priority ASC,    │                               │
     │                               │                                     │      created_at ASC            │                               │
     │                               │                                     │      FOR UPDATE SKIP LOCKED    │                               │
     │                               │                                     │◀─────────────────────────────│                               │
     │                               │                                     │                               │                               │
     │                               │                                     │  13. UPDATE status='SYNCING',  │                               │
     │                               │                                     │      locked_by='worker:12345' │                               │
     │                               │                                     │◀─────────────────────────────│                               │
     │                               │                                     │                               │                               │
     │                               │                                     │                               │  14. DAGateway::addRecord()   │
     │                               │                                     │                               │      POST dns1:2222            │
     │                               │                                     │                               │──────────────────────────────▶│
     │                               │                                     │                               │                               │  15. DA processes:
     │                               │                                     │                               │                               │      Update zone file
     │                               │                                     │                               │                               │      Restart named
     │                               │                                     │                               │  16. HTTP 200 {success}        │
     │                               │                                     │                               │◀──────────────────────────────│
     │                               │                                     │                               │                               │
     │                               │                                     │  17. UPDATE queue              │                               │
     │                               │                                     │      SET status='COMPLETE',    │                               │
     │                               │                                     │      completed_at=NOW()        │                               │
     │                               │                                     │◀─────────────────────────────│                               │
     │                               │                                     │                               │                               │
     │                               │                                     │  18. INSERT sync_log           │                               │
     │                               │                                     │◀─────────────────────────────│                               │
     │                               │                                     │                               │                               │
     │                               │                                     │  (Lặp lại 14-18 cho dns2, dns3)│                               │
     │                               │                                     │                               │                               │
     ═══════════ AJAX POLLING ═══════════════════════════════════════════════                               │                               │
     │                               │                                     │                               │                               │
     │  19. GET /ajax/sync-status    │                                     │                               │                               │
     │      ?batch_id=abc-123-def    │                                     │                               │                               │
     │──────────────────────────────▶│                                     │                               │                               │
     │                               │  20. QueueManager::getStatus()      │                               │                               │
     │                               │──────────────────────────────────────▶│ SELECT COUNT by status       │                               │
     │                               │                                     │  WHERE batch_id="abc-123-def" │                               │
     │                               │  21. Aggregate: 3/3 COMPLETE        │                               │                               │
     │  22. JSON {status:"complete", │                                     │                               │                               │
     │      servers: {dns1:✅,        │                                     │                               │                               │
     │      dns2:✅, dns3:✅}}        │                                     │                               │                               │
     │◀──────────────────────────────│                                     │                               │                               │
     │                               │                                     │                               │                               │
     │  UI: Badge chuyển sang        │                                     │                               │                               │
     │  🟢 "Live on all servers"     │                                     │                               │                               │
     │  Toast: "✅ Record đã live!"   │                                     │                               │                               │
     │  Dừng polling.                │                                     │                               │                               │
     ▼                               ▼                                     ▼                               ▼                               ▼
```

**Tổng thời gian end-to-end**: User nhấn Save (0s) → UI phản hồi (0.2s) → DNS live trên tất cả server (60-180s tùy chu kỳ cron).

---

### 5.2. FLOW-02: Cron Worker — Chi tiết xử lý 1 chu kỳ

```
queue_worker.php khởi chạy
        │
        ▼
┌─────────────────────────────────┐
│ 1. Acquire process lock         │ ── Kiểm tra file /tmp/hvndns_worker.lock
│    (flock hoặc DB lock)         │    Nếu lock tồn tại & process còn sống → EXIT
│    Timeout: 55 giây             │    Tạo lock với PID hiện tại
└────────────┬────────────────────┘
             │
             ▼
┌─────────────────────────────────┐
│ 2. Recover stale jobs           │ ── UPDATE queue SET status='FAILED',
│                                  │    error_message='Stale job recovered'
│                                  │    WHERE status='SYNCING'
│                                  │    AND locked_at < NOW() - INTERVAL 5 MINUTE
└────────────┬────────────────────┘
             │
             ▼
┌─────────────────────────────────┐
│ 3. Load active servers          │ ── SELECT * FROM servers
│    Filter out backoff servers   │    WHERE is_active=1
│                                  │    AND (backoff_until IS NULL
│                                  │         OR backoff_until <= NOW())
└────────────┬────────────────────┘
             │
             ▼
┌─────────────────────────────────┐
│ 4. Fetch pending jobs           │ ── SELECT * FROM queue
│    (grouped by server,          │    WHERE status='PENDING'
│     respect max_concurrent)     │    AND next_retry_at <= NOW()
│                                  │    AND server_id IN (active_server_ids)
│                                  │    ORDER BY priority ASC, created_at ASC
│                                  │    FOR UPDATE SKIP LOCKED
│                                  │    LIMIT (sum of max_concurrent)
└────────────┬────────────────────┘
             │
             ▼
┌─────────────────────────────────┐
│ 5. Process loop                 │
│    FOR EACH job:                │
│    ├── SET status='SYNCING'     │
│    │   SET locked_by=worker:PID │
│    │   SET started_at=NOW()     │
│    │                             │
│    ├── Build DAGateway instance │
│    │   for job.server_id        │
│    │                             │
│    ├── Execute command           │
│    │   (addRecord/editRecord/..)│
│    │                             │
│    ├── IF success:              │
│    │   ├── SET status='COMPLETE'│
│    │   ├── SET completed_at     │
│    │   ├── Reset server backoff │
│    │   └── Write sync_log       │
│    │                             │
│    ├── IF failure:              │
│    │   ├── attempts++           │
│    │   ├── IF attempts >=       │
│    │   │   max_attempts:        │
│    │   │   SET PERMANENTLY_FAIL │
│    │   ├── ELSE:                │
│    │   │   SET status='FAILED'  │
│    │   │   SET next_retry_at =  │
│    │   │   NOW() + 2^attempts   │
│    │   │   minutes              │
│    │   ├── Update server        │
│    │   │   backoff_count++      │
│    │   └── Write sync_log       │
│    │                             │
│    ├── Check notification        │
│    │   threshold                 │
│    │                             │
│    └── Check elapsed time        │
│        IF > 55s → BREAK         │
└────────────┬────────────────────┘
             │
             ▼
┌─────────────────────────────────┐
│ 6. Release process lock         │
│    Delete lock file             │
│    Log summary:                 │
│    "Processed X jobs:           │
│     Y complete, Z failed"      │
└─────────────────────────────────┘
```

---

### 5.3. FLOW-03: Conflict Resolution

```
SCENARIO: Admin sửa record "mail.example.com" trong khi Client
          đã sửa record đó 1 phút trước và job đang PENDING.

Client sửa record (T=0)
        │
        ▼
┌──────────────────────────────┐
│ QueueManager::dispatch()     │
│ → Job #100 (client, PENDING) │
│ → batch_id = "client-batch"  │
└──────────────────────────────┘
        │
        │  ... 1 phút sau ...
        │
Admin sửa cùng record (T=60s)
        │
        ▼
┌──────────────────────────────┐
│ ConflictResolver::check()    │
│                               │
│ Query: SELECT FROM queue     │
│   WHERE domain_id = X        │
│   AND action = 'EDIT_RECORD' │
│   AND payload->record_id = Y │
│   AND status = 'PENDING'     │
│   AND created_at > NOW()     │
│       - INTERVAL 3 MINUTE    │
│                               │
│ Result: Job #100 found!      │
│                               │
│ Actor mới = admin             │
│ Actor cũ  = client            │
│ → ADMIN-PRIORITY rule         │
└──────────┬───────────────────┘
           │
           ▼
┌──────────────────────────────┐
│ 1. Cancel client jobs:       │
│    UPDATE queue              │
│    SET status='CANCELLED'    │
│    WHERE batch_id =          │
│    "client-batch"            │
│    AND status='PENDING'      │
│                               │
│ 2. Audit trail:              │
│    "Job #100 cancelled -     │
│     Overridden by Admin #5"  │
│                               │
│ 3. Dispatch new admin jobs:  │
│    Job #101 → dns1 PENDING   │
│    Job #102 → dns2 PENDING   │
│    Job #103 → dns3 PENDING   │
│    (priority = 1, admin)     │
│                               │
│ 4. Update record in DB       │
│    with admin's new value    │
└──────────────────────────────┘
```

---

### 5.4. FLOW-04: DDNS Update (Router/Camera)

```
ROUTER (Mikrotik)                WHMCS                              DATABASE              CRON
──────────────                   ─────                              ────────              ────
     │                               │                                  │                   │
     │  GET /ddns.php?               │                                  │                   │
     │  token=abc123&                │                                  │                   │
     │  hostname=cam.example.com     │                                  │                   │
     │──────────────────────────────▶│                                  │                   │
     │                               │                                  │                   │
     │                               │  1. Check IP blacklist           │                   │
     │                               │     SELECT FROM ip_blacklist     │                   │
     │                               │     WHERE ip = REMOTE_ADDR       │                   │
     │                               │     AND blocked_until > NOW()    │                   │
     │                               │                                  │                   │
     │                               │  2. Validate token               │                   │
     │                               │     SELECT FROM ddns_tokens      │                   │
     │                               │     WHERE token_hash =           │                   │
     │                               │     SHA256('abc123')             │                   │
     │                               │     AND is_active = 1            │                   │
     │                               │                                  │                   │
     │                               │  3. Rate limit check             │                   │
     │                               │     COUNT requests in last hour  │                   │
     │                               │     IF > 60 → HTTP 429           │                   │
     │                               │                                  │                   │
     │                               │  4. Compare IP                   │                   │
     │                               │     current = REMOTE_ADDR        │                   │
     │                               │     stored  = last_ip            │                   │
     │                               │                                  │                   │
     │                               │  IF same_ip:                     │                   │
     │  "nochg 103.1.2.3"           │     Return "nochg"               │                   │
     │◀──────────────────────────────│                                  │                   │
     │                               │                                  │                   │
     │                               │  IF different_ip:                │                   │
     │                               │  5. Update ddns_tokens.last_ip   │                   │
     │                               │  6. Update records.value         │                   │
     │                               │  7. QueueManager::dispatch(      │                   │
     │                               │       EDIT_RECORD, {new_ip})     │                   │
     │                               │  8. Audit trail:                 │                   │
     │                               │     actor=api, context=ddns      │                   │
     │                               │                                  │                   │
     │  "good 118.70.5.6"           │                                  │                   │
     │◀──────────────────────────────│                                  │                   │
     │                               │                                  │                   │
     │                               │                                  │   (Cron xử lý     │
     │                               │                                  │    như FLOW-01)    │
     ▼                               ▼                                  ▼                   ▼
```

---

### 5.5. FLOW-05: Provisioning khi Khách mua Dịch vụ

```
WHMCS ORDER FLOW                    MODULE HOOKS                     RESULT
────────────────                    ────────────                     ──────

Client đặt hàng
"DNS Management"
cho domain example.com
        │
        ▼
Thanh toán thành công
        │
        ▼
WHMCS tạo Service
(tblhosting.id = 789)
        │
        ▼
WHMCS gọi Module::Create()
        │
        ▼
┌──────────────────────────────────────────────────────────────┐
│ Hook: AfterModuleCreate                                       │
│                                                               │
│ 1. Tạo mod_hvndns_domains:                                   │
│    domain = "example.com"                                     │
│    whmcs_service_id = 789                                     │
│    whmcs_user_id = 456                                        │
│    status = "active"                                          │
│    quota_plan_id = (từ WHMCS Product config)                  │
│                                                               │
│ 2. Load default template:                                     │
│    SELECT FROM templates WHERE is_default = 1                 │
│    Records: NS dns1/dns2/dns3, SOA, default A                │
│                                                               │
│ 3. Replace placeholders:                                      │
│    {{domain}} → example.com                                   │
│    {{ip}} → (từ Product custom field hoặc default)           │
│                                                               │
│ 4. INSERT records (từ template)                               │
│    → mod_hvndns_records (is_system=1 cho NS/SOA)             │
│                                                               │
│ 5. QueueManager::dispatch(CREATE_ZONE, {                      │
│       template_records: [...],                                │
│       actor_type: 'system'                                    │
│    })                                                         │
│    → Fan-out: 3 jobs cho dns1, dns2, dns3                    │
│                                                               │
│ 6. Audit trail: "Zone created via auto-provision"             │
└──────────────────────────────────────────────────────────────┘
        │
        ▼ (Cron xử lý trong 1-3 phút)
        │
        ▼
Zone "example.com" xuất hiện trên cả 3 DA Node
        │
        ▼
Client mở DNS Editor → thấy NS records + default A record sẵn sàng
```

---

### 5.6. FLOW-06: Drift Detection (Chạy hàng đêm)

```
CRON (2:00 AM daily)
        │
        ▼
┌──────────────────────────────────────────┐
│ DriftDetector::run()                      │
│                                           │
│ FOR EACH active domain:                  │
│   │                                       │
│   ├─ 1. Throttle: sleep(1s) giữa mỗi    │
│   │     domain (tránh overload DA)        │
│   │                                       │
│   ├─ 2. DAGateway::getZone($domain)      │
│   │     → Lấy toàn bộ records từ DA      │
│   │     (chỉ cần query 1 server Primary) │
│   │                                       │
│   ├─ 3. Local records:                    │
│   │     SELECT FROM mod_hvndns_records    │
│   │     WHERE domain_id = X              │
│   │                                       │
│   ├─ 4. DIFF algorithm:                  │
│   │     ┌───────────────────────────────┐│
│   │     │ Compare bằng composite key:   ││
│   │     │ (type + name + value)          ││
│   │     │                                ││
│   │     │ DA có, Local không có          ││
│   │     │ → drift_type: "added_on_da"   ││
│   │     │                                ││
│   │     │ Local có, DA không có          ││
│   │     │ → drift_type: "missing_on_da" ││
│   │     │                                ││
│   │     │ Cả hai có nhưng value khác     ││
│   │     │ → drift_type: "modified"       ││
│   │     │                                ││
│   │     │ (Bỏ qua NS/SOA system records ││
│   │     │  vì DA có thể tự thay đổi)    ││
│   │     └───────────────────────────────┘│
│   │                                       │
│   ├─ 5. IF drift found:                  │
│   │     INSERT mod_hvndns_drift_reports   │
│   │                                       │
│   └─ 6. IF auto_fix enabled:             │
│         Push WHMCS → DA cho mỗi drift    │
│         (dispatch EDIT/ADD/DELETE jobs)    │
│                                           │
│ AFTER all domains:                        │
│   IF total_drift > 0:                     │
│     NotificationService::send(            │
│       "Drift detected: X domains          │
│        have Y mismatched records")        │
│                                           │
│ Create nightly snapshot for all domains   │
└──────────────────────────────────────────┘
```

---

## 6. API Specification — DA Gateway

### 6.1. DirectAdmin API Endpoints sử dụng

| Action | DA Command | HTTP Method | Parameters |
|--------|-----------|-------------|------------|
| Get Zone | `CMD_API_DNS_CONTROL` | GET | `domain`, `json=yes` |
| Add Record | `CMD_API_DNS_CONTROL` | POST | `domain`, `action=add`, `type`, `name`, `value` |
| Edit Record | `CMD_API_DNS_CONTROL` | POST | `domain`, `action=edit`, `type`, `name`, `value`, `aression` (old value) |
| Delete Record | `CMD_API_DNS_CONTROL` | POST | `domain`, `action=delete`, `type`, `name`, `value` |
| Create Zone | `CMD_API_DNS_ADMIN` | POST | `domain`, `action=create`, `ns1`, `ns2` |
| Delete Zone | `CMD_API_DNS_ADMIN` | POST | `domain`, `action=delete` |
| Enable DNSSEC | `CMD_API_DNS_DNSSEC` | POST | `domain`, `action=enable` |
| Disable DNSSEC | `CMD_API_DNS_DNSSEC` | POST | `domain`, `action=disable` |
| Get DS Records | `CMD_API_DNS_DNSSEC` | GET | `domain`, `json=yes` |
| SSL Request | `CMD_API_SSL` | POST | `domain`, `action=save`, `type=letsencrypt` |
| Create Email Fwd | `CMD_API_EMAIL_FORWARDERS` | POST | `domain`, `user`, `email` |

### 6.2. DAGateway Class Interface

```php
class DAGateway
{
    /**
     * Constructor - khởi tạo kết nối tới 1 DA server
     * 
     * @param Server $server  Eloquent model từ mod_hvndns_servers
     */
    public function __construct(Server $server);

    /**
     * Kiểm tra kết nối tới DA server
     * Gọi CMD_API_SHOW_ALL_USERS để verify auth + connectivity
     * 
     * @return DAResponse  {success: bool, version: string, latency_ms: int}
     * @throws DAConnectionException  Khi không kết nối được
     */
    public function testConnection(): DAResponse;

    /**
     * Lấy toàn bộ DNS zone của domain
     * 
     * @param string $domain  Tên miền (example.com)
     * @return DAResponse     {success: bool, records: array}
     */
    public function getZone(string $domain): DAResponse;

    /**
     * Thêm bản ghi DNS
     * 
     * @param string $domain  Tên miền
     * @param array  $record  ['type'=>'A', 'name'=>'mail', 'value'=>'1.2.3.4', 'ttl'=>3600]
     * @return DAResponse
     */
    public function addRecord(string $domain, array $record): DAResponse;

    /**
     * Sửa bản ghi DNS
     * 
     * @param string $domain    Tên miền
     * @param array  $oldRecord Record cũ (dùng để DA identify)
     * @param array  $newRecord Record mới
     * @return DAResponse
     */
    public function editRecord(string $domain, array $oldRecord, array $newRecord): DAResponse;

    /**
     * Xóa bản ghi DNS
     * 
     * @param string $domain  Tên miền
     * @param array  $record  Record cần xóa
     * @return DAResponse
     */
    public function deleteRecord(string $domain, array $record): DAResponse;

    /**
     * Tạo DNS zone mới
     * 
     * @param string $domain  Tên miền
     * @param string $ns1     Primary nameserver (dns1.hvn.vn)
     * @param string $ns2     Secondary nameserver (dns2.hvn.vn)
     * @return DAResponse
     */
    public function createZone(string $domain, string $ns1, string $ns2): DAResponse;

    /**
     * Xóa DNS zone
     */
    public function deleteZone(string $domain): DAResponse;

    /**
     * Bật/tắt DNSSEC
     */
    public function enableDnssec(string $domain): DAResponse;
    public function disableDnssec(string $domain): DAResponse;
    public function getDsRecords(string $domain): DAResponse;

    /**
     * Yêu cầu chứng chỉ Let's Encrypt
     */
    public function requestSsl(string $domain, bool $includeWww = true): DAResponse;
}
```

### 6.3. DAResponse Object

```php
class DAResponse
{
    public bool   $success;          // true/false
    public int    $httpStatus;       // 200, 403, 500, 0 (timeout)
    public string $errorType;        // 'none', 'timeout', 'auth_fail', 'dns_conflict',
                                     // 'zone_exists', 'zone_not_found', 'rate_limit', 'unknown'
    public string $errorMessage;     // Human-readable error
    public array  $data;             // Parsed response data
    public string $rawResponse;      // Raw DA response body
    public int    $durationMs;       // Request duration in milliseconds

    public function isSuccess(): bool;
    public function isRetryable(): bool;  // timeout, rate_limit → true; auth_fail → false
}
```

**Retryable Error Classification**:

| Error Type | Retryable | Hành động |
|------------|-----------|-----------|
| `timeout` | ✅ Yes | Exponential backoff |
| `rate_limit` | ✅ Yes | Backoff 60 giây |
| `server_error` (5xx) | ✅ Yes | Exponential backoff |
| `auth_fail` (403) | ❌ No | PERMANENTLY_FAILED, alert Admin |
| `dns_conflict` | ❌ No | FAILED, cần Admin xem xét |
| `zone_not_found` | ❌ No | FAILED, domain có thể đã bị xóa trên DA |
| `zone_exists` | ⚠️ Conditional | Nếu CREATE_ZONE → coi như success |

---

## 7. Queue Engine Specification

### 7.1. QueueManager Interface

```php
class QueueManager
{
    /**
     * Dispatch job mới vào queue (fan-out ra tất cả active servers)
     * 
     * @param int    $domainId   ID domain trong mod_hvndns_domains
     * @param string $action     Action enum (ADD_RECORD, EDIT_RECORD, ...)
     * @param array  $payload    Dữ liệu chi tiết cho action
     * @param string $actorType  'client' | 'admin' | 'system' | 'api'
     * @param int|null $actorId  WHMCS user/admin ID
     * @param int    $priority   1-10 (1 = highest)
     * 
     * @return string  batch_id (UUID v4)
     */
    public function dispatch(
        int $domainId,
        string $action,
        array $payload,
        string $actorType = 'client',
        ?int $actorId = null,
        int $priority = 5
    ): string;

    /**
     * Lấy aggregate status của 1 batch
     * 
     * @return object {
     *     status: 'pending'|'syncing'|'complete'|'partial'|'failed',
     *     total: int,
     *     complete: int,
     *     pending: int,
     *     syncing: int,
     *     failed: int,
     *     servers: [{hostname, status, error_message}]
     * }
     */
    public function getBatchStatus(string $batchId): object;

    /**
     * Hủy tất cả job PENDING trong batch
     */
    public function cancelBatch(string $batchId, string $reason = ''): int;

    /**
     * Retry tất cả job FAILED (reset về PENDING)
     * 
     * @param array|null $jobIds  Nếu null → retry ALL failed
     * @return int  Số job đã retry
     */
    public function retryFailed(?array $jobIds = null): int;
}
```

### 7.2. Deduplication Logic

```
Khi QueueManager::dispatch() được gọi:

1. Kiểm tra xem có job trùng đang PENDING không:
   SELECT id FROM queue
   WHERE domain_id = :domain_id
     AND action = :action
     AND JSON_EXTRACT(payload, '$.record_id') = :record_id
     AND status = 'PENDING'
     AND created_at > NOW() - INTERVAL 5 MINUTE

2. Nếu TÌM THẤY job trùng:
   a. Nếu cùng actor_type (VD: client → client):
      → UPDATE job cũ SET payload = new_payload
      → KHÔNG tạo job mới (dedup)
      → Return batch_id cũ
      
   b. Nếu khác actor_type (VD: client → admin):
      → Chuyển sang ConflictResolver (xem FLOW-03)

3. Nếu KHÔNG tìm thấy:
   → Tạo job mới bình thường (fan-out)
```

### 7.3. Job Priority Matrix

| Actor Type | Action Type | Priority Value | Ghi chú |
|------------|------------|----------------|---------|
| Admin | Mọi action | 1 | Luôn xử lý trước |
| System | CREATE_ZONE | 2 | Provisioning ưu tiên cao |
| System | DELETE_ZONE | 2 | Cleanup ưu tiên cao |
| Client | ADD/EDIT/DELETE_RECORD | 5 | Default |
| System | RESIGN_ZONE | 7 | Không gấp, chạy sau record changes |
| System | REQUEST_SSL / RENEW_SSL | 8 | Background task |
| System | Drift auto-fix | 9 | Lowest, chạy off-peak |

---

## 8. Cron Worker Specification

### 8.1. Execution Parameters

| Parameter | Giá trị | Ghi chú |
|-----------|---------|---------|
| Interval | 1 phút | Qua WHMCS cron hoặc system crontab |
| Max Runtime | 55 giây | Tự kill trước khi cron tiếp theo chạy |
| Lock Mechanism | File lock (`flock`) | `/tmp/hvndns_worker.lock` |
| Stale Lock Timeout | 5 phút | Lock cũ hơn 5 phút → force release |
| Max Jobs Per Cycle | `SUM(server.max_concurrent)` | Ví dụ: 3 server × 50 = 150 jobs max |
| Job Timeout | 30 giây/job | GuzzleHTTP request timeout |
| Logging | Monolog channel `hvndns_worker` | Level: info (summary), debug (per-job) |

### 8.2. Exponential Backoff Formula

```
next_retry_at = NOW() + (2 ^ attempts) phút

Attempts | Delay     | Thời gian chờ
---------|-----------|---------------
1        | 2^1 = 2   | 2 phút
2        | 2^2 = 4   | 4 phút  
3        | 2^3 = 8   | 8 phút
4        | 2^4 = 16  | 16 phút
5        | MAX       | PERMANENTLY_FAILED (cần Admin)

Tổng thời gian retry tối đa: 2 + 4 + 8 + 16 = 30 phút
Sau 30 phút nếu server vẫn lỗi → dừng retry, chờ Admin.
```

### 8.3. Server-Level Backoff

```
Server backoff KHÁC với Job backoff:

Khi 1 server liên tiếp fail 3+ jobs trong 5 phút:
  → server.backoff_until = NOW() + (2 ^ backoff_count) phút
  → Worker SKIP toàn bộ job của server này cho đến khi hết backoff

Khi 1 job trên server đó thành công:
  → server.backoff_count = 0
  → server.backoff_until = NULL
  → Worker resume xử lý server bình thường

Mục đích: Tránh Worker cố gắng đẩy hàng trăm job
vào 1 server đang down → lãng phí thời gian cron cycle.
```

---

## 9. Security Specification

### 9.1. Authentication & Authorization

| Context | Mechanism | Chi tiết |
|---------|-----------|----------|
| Client → WHMCS | WHMCS Session Auth | Tự động qua WHMCS authentication |
| Admin → WHMCS | WHMCS Admin Auth | Role-based, cần addon permission |
| WHMCS → DA | HTTP Basic Auth over HTTPS | Username/password encrypted trong DB |
| Router → DDNS | Token-based (SHA-256) | Stateless, không dùng session |
| Webhook → Telegram | Bot Token | Stored encrypted |

### 9.2. Data Encryption

| Data | Encryption | Storage |
|------|-----------|---------|
| DA Server password | WHMCS `Encryption::encode()` (AES-256) | `mod_hvndns_servers.password_enc` |
| DDNS Token | SHA-256 hash (one-way) | `mod_hvndns_ddns_tokens.token_hash` |
| Telegram Bot Token | WHMCS `Encryption::encode()` | Module settings |
| Audit Trail | Plaintext (append-only, integrity > encryption) | `mod_hvndns_audit_trail` |

### 9.3. Input Validation Rules

```php
class DnsRecordValidator
{
    // A Record: IPv4 format
    // Regex: /^(\d{1,3}\.){3}\d{1,3}$/
    // Thêm: Từng octet phải 0-255
    // Chặn: Private IP (10.x, 172.16-31.x, 192.168.x) → cảnh báo, không block
    
    // AAAA Record: IPv6 format
    // Sử dụng filter_var($value, FILTER_VALIDATE_IP, FILTER_FLAG_IPV6)
    
    // CNAME Record: 
    // - Value phải là FQDN hợp lệ (kết thúc bằng dấu chấm hoặc tự thêm)
    // - Name KHÔNG được trùng với bất kỳ A/AAAA/MX record nào (RFC 1912)
    // - Không cho CNAME tại root (@) nếu domain có MX record
    
    // MX Record:
    // - Value phải là FQDN (KHÔNG được là IP — RFC 2181)
    // - Priority: 0-65535
    // - Cảnh báo nếu trùng priority với MX khác
    
    // TXT Record:
    // - Max length: 4096 chars (sẽ tự split thành 255-char chunks cho DA)
    // - Validate SPF syntax nếu bắt đầu bằng "v=spf1"
    // - Validate DKIM nếu name chứa "_domainkey"
    
    // SRV Record:
    // - Name format: _service._protocol (VD: _sip._tcp)
    // - Priority: 0-65535
    // - Weight: 0-65535
    // - Port: 1-65535
    // - Target: FQDN
    
    // CAA Record:
    // - Flag: 0 hoặc 128
    // - Tag: 'issue', 'issuewild', 'iodef'
    // - Value: CA domain hoặc mailto: URI
    
    // NS Record:
    // - Chỉ Admin mới được sửa (is_system check)
    // - Value phải là FQDN
    
    // TTL (tất cả record types):
    // - Range: 60 - 86400 giây (1 phút - 24 giờ)
    // - Default: 3600 (1 giờ)
    
    // Name (tất cả record types):
    // - Max length: 63 chars per label, 253 chars total
    // - Allowed: a-z, 0-9, hyphen (-)
    // - Không bắt đầu hoặc kết thúc bằng hyphen
    // - Wildcard: chỉ cho phép "*" ở đầu (*.example.com)
    // - "@" = root domain
}
```

### 9.4. DDNS Anti-Brute Force

```
Request arrives at ddns.php
        │
        ├─ 1. Check IP Blacklist
        │     SELECT FROM ip_blacklist
        │     WHERE ip = REMOTE_ADDR AND blocked_until > NOW()
        │     → HIT: return 403 immediately (no processing)
        │
        ├─ 2. Validate Token (SHA-256 lookup)
        │     → MISS: increment fail counter for IP
        │     → IF fail_count >= 10 in 5 minutes:
        │         INSERT ip_blacklist (block 1 hour)
        │         Log: "IP blocked: brute force DDNS"
        │         return 403
        │     → ELSE: return 401 "badauth"
        │
        ├─ 3. Rate Limit (valid token)
        │     COUNT requests WHERE token_hash = X
        │     AND created_at > NOW() - 1 HOUR
        │     → IF > 60: return 429 "abuse"
        │
        └─ 4. Process normally
```

### 9.5. XSS & SQL Injection Prevention

- Tất cả user input đi qua `InputSanitizer::clean()` trước khi xử lý.
- Sử dụng Eloquent ORM (parameterized queries) — KHÔNG BAO GIỜ nối chuỗi SQL.
- Smarty templates tự auto-escape HTML. Dùng `{$var|escape:'htmlall'}` cho data động.
- CSP header cho các trang Admin/Client: `script-src 'self' cdnjs.cloudflare.com`.

---

## 10. Frontend Specification

### 10.1. Technology Stack

| Component | Library | Version | CDN / Bundled |
|-----------|---------|---------|--------------|
| CSS Framework | Bootstrap | 5.3.x | CDN |
| JS Reactivity | Alpine.js | 3.x | CDN + local fallback |
| DataTables | DataTables.net | 1.13.x | CDN |
| Icons | Bootstrap Icons | 1.11.x | CDN |
| Charts (Admin) | Chart.js | 4.x | CDN |
| Template Engine | Smarty | WHMCS built-in | Bundled |

### 10.2. Ajax Endpoints

| Endpoint | Method | Auth | Mục đích |
|----------|--------|------|----------|
| `?action=get_records&domain_id=X` | GET | Client/Admin | Lấy danh sách records |
| `?action=add_record` | POST | Client/Admin | Thêm record |
| `?action=edit_record` | POST | Client/Admin | Sửa record |
| `?action=delete_record` | POST | Client/Admin | Xóa record |
| `?action=sync_status&batch_id=X` | GET | Client/Admin | Polling sync status |
| `?action=sync_status_all&domain_id=X` | GET | Client/Admin | Status tất cả records |
| `?action=retry_job&job_id=X` | POST | Admin only | Retry 1 job |
| `?action=retry_all_failed` | POST | Admin only | Retry all failed |
| `?action=test_server&server_id=X` | POST | Admin only | Test DA connection |
| `?action=dashboard_stats` | GET | Admin only | Dashboard metrics |

### 10.3. Sync Status Polling Logic

```javascript
// Alpine.js component: SyncTracker
{
    polling: false,
    interval: null,
    
    startPolling(batchId) {
        this.polling = true;
        this.interval = setInterval(async () => {
            const res = await fetch(`?action=sync_status&batch_id=${batchId}`);
            const data = await res.json();
            
            this.updateBadge(data.status);
            
            // Dừng polling khi hoàn thành hoặc fail hết
            if (data.status === 'complete' || data.status === 'failed') {
                this.stopPolling();
                this.showToast(data.status);
            }
        }, 5000); // Poll mỗi 5 giây
    },
    
    stopPolling() {
        clearInterval(this.interval);
        this.polling = false;
    }
}

// Badge mapping:
// 'pending'  → 🟡 "Pending"
// 'syncing'  → 🔄 "Syncing (2/3)"  
// 'complete' → 🟢 "Live on all servers"
// 'partial'  → ⚠️ "Partially synced"
// 'failed'   → 🔴 "Sync failed"
```

---

## 11. Webhook & Notification Specification

### 11.1. Telegram Integration

```php
class NotificationService
{
    /**
     * Gửi alert qua Telegram Bot API
     * POST https://api.telegram.org/bot{TOKEN}/sendMessage
     * 
     * Message format (Markdown):
     * 
     * 🚨 *HVN DNS Alert*
     * 
     * *Type:* Server Unreachable
     * *Server:* dns2.hvn.vn (103.xx.xx.11)
     * *Failed Jobs:* 7 consecutive
     * *Since:* 2026-02-25 14:32:00
     * 
     * [View Dashboard](https://whmcs.hvn.vn/admin/...)
     */
    public function sendTelegram(string $message): bool;
    
    /**
     * Gửi alert qua Email (WHMCS mail system)
     */
    public function sendEmail(string $subject, string $body): bool;
}
```

### 11.2. Alert Trigger Rules

| Rule ID | Condition | Alert Type | Cooldown |
|---------|-----------|-----------|----------|
| `RULE_01` | ≥ 5 FAILED jobs liên tiếp trên 1 server | 🔴 Critical | 15 phút |
| `RULE_02` | Server unreachable ≥ 3 lần liên tiếp | 🔴 Critical | 15 phút |
| `RULE_03` | Queue backlog > 100 PENDING jobs > 10 phút | 🟡 Warning | 30 phút |
| `RULE_04` | Server vào backoff mode | 🟡 Warning | 30 phút |
| `RULE_05` | PERMANENTLY_FAILED job detected | 🔴 Critical | Mỗi job |
| `RULE_06` | Drift detected (nightly scan) | 🟠 Info | 24 giờ |
| `RULE_07` | SSL certificate expiring < 7 ngày | 🟡 Warning | 24 giờ |

---

## 12. Performance Targets & Constraints

### 12.1. Response Time Targets

| Operation | Target | Max Acceptable |
|-----------|--------|---------------|
| Client nhấn Save → UI phản hồi | < 200ms | 500ms |
| Client DNS Editor page load (50 records) | < 1s | 2s |
| Admin Dashboard load | < 2s | 3s |
| Admin Sync Logs (10K rows, server-side) | < 1s | 2s |
| DDNS endpoint response | < 100ms | 200ms |
| Queue dispatch (including fan-out 3 servers) | < 50ms | 100ms |
| Cron Worker: 1 job execution | < 30s | 30s (timeout) |
| End-to-end: Save → Live on all servers | < 3 phút | 5 phút |

### 12.2. Capacity Targets

| Metric | Target |
|--------|--------|
| Max domains managed | 5,000+ |
| Max records per domain | 500 |
| Max queue jobs per cron cycle | 150 (configurable) |
| Max concurrent API calls per DA server | 50 (configurable) |
| Sync logs retention | 90 ngày |
| Audit trail retention | 365 ngày (min) |
| Snapshots per domain | 30 (rolling) |
| Record history retention | 90 ngày |

### 12.3. Database Optimization Notes

- **Bảng `queue`**: Index composite `(status, next_retry_at, scheduled_at)` là critical path cho Worker. Phải đảm bảo query plan dùng index này.
- **Bảng `sync_logs`**: Sẽ tăng nhanh nhất (~150 rows/phút nếu cron chạy đầy tải). Cần partition theo tháng hoặc auto-purge > 90 ngày.
- **Bảng `audit_trail`**: Append-only, sẽ tích lũy lớn. Index trên `(domain, created_at)` cho search. Cân nhắc archive sau 1 năm.
- **Query N+1 Warning**: Khi load DNS Editor, dùng `with('records')` eager loading. KHÔNG query từng record riêng lẻ.

---

## 13. Error Handling & Recovery Matrix

| Tình huống | Phát hiện bởi | Xử lý tự động | Admin Action |
|------------|--------------|----------------|--------------|
| DA Server timeout | Cron Worker | Retry + Backoff | Monitor dashboard |
| DA Server auth fail | Cron Worker | PERMANENTLY_FAILED + Alert | Kiểm tra password DA |
| DA Server unreachable | Cron Worker | Server-level backoff + Alert | Kiểm tra network/firewall |
| DNS record conflict trên DA | Cron Worker | FAILED (non-retryable) | Xem sync log, manual fix |
| Zone not found trên DA | Cron Worker | FAILED + Alert | Re-provision hoặc tạo zone thủ công |
| Cron Worker crash | Stale job recovery | Tự phục hồi lần chạy tiếp theo | Kiểm tra error log |
| DB connection lost | Cron Worker | Worker tự exit, retry lần sau | Kiểm tra MySQL |
| Queue overload (>1000 pending) | Dashboard Alert | Tự xử lý dần | Tăng cron frequency hoặc max_concurrent |
| Drift detected | Nightly cron | Auto-fix (nếu enabled) | Review drift report |
| SSL renewal failed | SSL cron | Retry 3 lần, sau đó alert | Kiểm tra DNS pointing |
| DDNS brute force | ddns.php | Auto-block IP | Review blacklist |
| Client-Admin conflict | ConflictResolver | Admin-Priority auto-resolve | Xem audit trail |
| Data corruption | Integrity check | Alert | Restore từ snapshot |

---

## 14. Deployment & Configuration Guide

### 14.1. Cài đặt Module

```bash
# 1. Upload module files
cp -r hvn_dns_manager/ /path/to/whmcs/modules/addons/

# 2. Set permissions
chown -R www-data:www-data /path/to/whmcs/modules/addons/hvn_dns_manager/
chmod -R 755 /path/to/whmcs/modules/addons/hvn_dns_manager/

# 3. Activate trong WHMCS Admin
# → Setup → Addon Modules → HVN - DirectAdmin DNS Manager → Activate
# → Database tables tự động được tạo

# 4. Cấu hình Cron (nếu dùng system crontab)
echo "* * * * * php /path/to/whmcs/modules/addons/hvn_dns_manager/cron/queue_worker.php" >> /etc/crontab

# 5. Cấu hình nightly jobs
echo "0 2 * * * php /path/to/whmcs/modules/addons/hvn_dns_manager/cron/drift_detector.php" >> /etc/crontab
echo "5 2 * * * php /path/to/whmcs/modules/addons/hvn_dns_manager/cron/snapshot_creator.php" >> /etc/crontab
echo "0 3 * * * php /path/to/whmcs/modules/addons/hvn_dns_manager/cron/ssl_checker.php" >> /etc/crontab
echo "0 4 * * * php /path/to/whmcs/modules/addons/hvn_dns_manager/cron/cleanup.php" >> /etc/crontab
```

### 14.2. Post-install Checklist

```
□ Module activated trong WHMCS Admin
□ Database tables đã được tạo (kiểm tra mod_hvndns_schema_version)
□ Thêm ít nhất 1 DA Server → Test Connection thành công
□ Tạo Default DNS Template
□ Tạo ít nhất 1 Quota Plan → Map vào WHMCS Product
□ Cron queue_worker chạy đúng mỗi phút (kiểm tra WHMCS Activity Log)
□ Tạo 1 domain test → thêm record → verify trên DA
□ Cấu hình Telegram Webhook → Test notification
□ Cấu hình nightly cron (drift + snapshot + cleanup)
□ Backup database trước khi go-live
```

### 14.3. Module Settings (Admin Configurable)

Hệ thống có **111 settings** chia thành 21 nhóm. Chi tiết đầy đủ tại **SETTINGS.md**.

Dưới đây là tóm tắt các nhóm:

| Nhóm | Số lượng | Mô tả |
|------|---------|-------|
| Module Core | 8 | License, nameservers, default TTL |
| Domain Policy | 7 | NS check, pre-registrar hook, grace period |
| DNS Editor | 2 | Enable/disable, subdomain limit |
| Record Permissions | 8 | Bật/tắt quyền sửa từng loại record |
| Record Limits | 8 | Giới hạn số lượng từng loại record |
| URL Redirect | 4 | Enable, masked, hash key, limit |
| Email Forwarding | 5 | Enable, catch-all, alias/destination limits |
| DDNS | 7 | Mode (off/free/paid), rate limit, brute force config |
| DNSSEC | 2 | Mode (off/free/paid), auto re-sign |
| SSL / Let's Encrypt | 4 | Auto-SSL, client trigger, renew days |
| DNS Templates | 3 | Enable, user custom, limit |
| Client Notification | 5 | Email notification cho client khi DNS thay đổi |
| UI / Navigation | 4 | Menu visibility, order |
| Performance & Cache | 5 | Fetch strategy, cache TTL, rate limit |
| DA Provisioning | 2 | Web template, PHP enable |
| Queue & Cron | 6 | Interval, timeout, retry, conflict window |
| Webhook & Alert | 9 | Telegram, email, thresholds, cooldown |
| Security | 4 | Sub-account restriction, retention policies |
| Data Retention | 3 | Snapshot, queue, drift retention |
| License | 8 | Cấu hình License key, API Endpoint |
| Upsell | 7 | Tích hợp giới thiệu/bán Addon cho client |

---

> **Tài liệu này là phiên bản sống (living document)**. Cập nhật mỗi khi có thay đổi kiến trúc hoặc thông số kỹ thuật.

## Changelog
| Ngày | Thay đổi | Người thực hiện |
|------|----------|-----------------|
| 26/02/2026 | Thêm Tầng 0 (License/Feature Gate) và cập nhật 111 Settings | — |
| 25/02/2026 | Khởi tạo SPEC v1.0 — Toàn bộ 14 sections | — |
