# HVN - DirectAdmin DNS Manager
## PROTOTYPE.md — Mock Data & UI Prototyping Plan

> **Phiên bản**: 1.0  
> **Ngày tạo**: 26/02/2026  
> **Mục đích**: Tạo prototype giao diện hoàn chỉnh với mock data trước khi code backend  
> **Thời lượng**: 4–5 ngày (với AI Tool hỗ trợ)  
> **Dành cho**: Frontend Developer, UI Reviewer, AI Agent  
> **Tham chiếu**: WIREFRAME.md, DB_SCHEMA.md, SETTINGS.md, API_REFERENCE.md  

---

## Mục lục

1. [Chiến lược Prototype](#1-chiến-lược-prototype)
2. [Tech Stack & AI Tools](#2-tech-stack--ai-tools)
3. [Phase 0A — Mock Data Seeder](#3-phase-0a--mock-data-seeder)
4. [Phase 0B — Client Area Prototype](#4-phase-0b--client-area-prototype)
5. [Phase 0C — Admin Area Prototype](#5-phase-0c--admin-area-prototype)
6. [Phase 0D — Review & Sign-off](#6-phase-0d--review--sign-off)
7. [Mock API Layer](#7-mock-api-layer)
8. [Quy tắc Prototype Code](#8-quy-tắc-prototype-code)
9. [Checklist Nghiệm thu Prototype](#9-checklist-nghiệm-thu-prototype)
10. [Chuyển tiếp Prototype → Production](#10-chuyển-tiếp-prototype--production)

---

## 1. Chiến lược Prototype

### 1.1. Nguyên tắc

```
UI-First: Giao diện chạy THẬT trong WHMCS, data GIẢ từ mock
─────────────────────────────────────────────────────────────

┌──────────────┐     ┌──────────────────┐     ┌────────────────┐
│  Smarty +     │────▶│  Mock API Layer   │────▶│  Mock Data     │
│  Alpine.js    │     │  (Fake JSON)      │     │  (Seeded DB)   │
│  (Template    │◀────│                   │◀────│                │
│   thật)       │     │  KHÔNG gọi DA     │     │  19 bảng có    │
│               │     │  KHÔNG gọi Queue  │     │  data giả      │
└──────────────┘     └──────────────────┘     └────────────────┘
       │
       ▼
  WHMCS Theme thật (Twenty-One / Six)
  URL thật (clientarea.php, admin/addonmodules.php)
  CSS riêng (hvndns.css — không phụ thuộc theme)
```

**Giao diện thật**: Smarty templates render trong WHMCS, đúng URL routing, đúng theme.

**Data giả**: Mock seeder tạo dữ liệu đa dạng trong 19 bảng DB — đủ kịch bản hiển thị.

**API giả**: Ajax endpoints trả JSON cứng (hardcoded hoặc đọc từ mock DB) — UI hoạt động hoàn chỉnh nhưng không gọi DirectAdmin, không chạy Queue.

**Tương tác giả**: Bấm "Thêm record" → modal mở → submit → fake success response → record xuất hiện với badge Pending → tự chuyển sang Live sau 3 giây (simulate sync). Toàn bộ bằng Alpine.js client-side.

### 1.2. Timeline (Với AI Tool hỗ trợ)

```
Ngày 1 (4h)     ──▶  Phase 0A: Mock Data Seeder + DB tables
                      ├─ Tạo 19 bảng (migration)
                      ├─ Seed data giả (500+ rows)
                      └─ SettingsHelper + default settings

Ngày 2 (6h)     ──▶  Phase 0B: Client Area (8 màn hình)
                      ├─ CL-01: Domain List
                      ├─ CL-02: DNS Editor (màn chính)
                      ├─ CL-03: Modal Add/Edit Record
                      ├─ CL-04–08: Tabs (Redirect, Email, DNSSEC, DDNS, Template)
                      └─ Mock Ajax + Alpine.js interactions

Ngày 3 (6h)     ──▶  Phase 0C: Admin Area (12 màn hình)
                      ├─ AD-01: Dashboard + Charts
                      ├─ AD-02–03: Server Management
                      ├─ AD-04–05: Domain List + Admin DNS Editor
                      ├─ AD-06–07: Sync Logs + Audit Trail
                      └─ AD-08–12: Templates, Quota, Drift, Bulk, Settings

Ngày 4 (4h)     ──▶  Phase 0C tiếp: Polish + Responsive
                      ├─ Mobile responsive testing
                      ├─ Cross-browser check
                      ├─ Animation polish (transitions, spinners)
                      └─ CSS fine-tuning

Ngày 5 (3h)     ──▶  Phase 0D: Review + Sign-off
                      ├─ Demo walkthrough
                      ├─ Thu thập feedback
                      ├─ Sửa UI theo feedback
                      └─ Sign-off → Chuyển tiếp Phase 1

Tổng: ~23 giờ làm việc (4–5 ngày)
```

---

## 2. Tech Stack & AI Tools

### 2.1. Frontend Stack (Production-ready, giữ nguyên khi chuyển Phase 1)

| Component | Library | Ghi chú |
|-----------|---------|---------|
| Template Engine | Smarty (WHMCS built-in) | Templates viết lần này GIỮ NGUYÊN cho production |
| CSS | Custom `hvndns.css` + Bootstrap 5.3 CDN | CSS riêng, KHÔNG phụ thuộc WHMCS theme |
| JS Reactivity | Alpine.js 3.x CDN | Interactions, polling simulation, state management |
| DataTables | DataTables.net 1.13.x CDN | Admin tables (Sync Logs, Audit Trail, Domains) |
| Charts | Chart.js 4.x CDN | Admin Dashboard metrics |
| Icons | Bootstrap Icons 1.11.x CDN | Status badges, action buttons |
| Fonts | System fonts (WHMCS native) | Không thêm custom fonts |

### 2.2. AI Tools cho Acceleration

| Công việc | AI Tool | Tiết kiệm |
|-----------|---------|-----------|
| Sinh Smarty template từ WIREFRAME.md | Claude / Antigravity Agent | ~60% thời gian code HTML |
| Sinh CSS responsive layouts | Claude / Antigravity Agent | ~50% thời gian CSS |
| Sinh Alpine.js components | Claude / Antigravity Agent | ~50% thời gian JS |
| Sinh Mock Data SQL | Claude | ~80% thời gian viết INSERT statements |
| Sinh Mock API responses | Claude | ~70% thời gian |
| Review responsive trên nhiều viewport | Antigravity Browser Agent | ~40% thời gian QA |
| Sinh Chart.js config cho Dashboard | Claude | ~60% thời gian |

### 2.3. Quy tắc dùng AI Tool cho Prototype

```
✅ DÙNG AI ĐỂ:
- Sinh HTML/CSS/JS từ wireframe mô tả
- Sinh mock data đa dạng (nhiều trạng thái, edge cases)
- Sinh Chart.js configurations
- Debug layout responsive

❌ KHÔNG DÙNG AI ĐỂ:
- Sinh business logic backend (chưa tới Phase 1)
- Sinh DAGateway hoặc Queue code
- Sinh production Controllers/Services
```

---

## 3. Phase 0A — Mock Data Seeder

> **Thời gian**: Ngày 1 (4 giờ)  
> **Output**: 19 bảng DB có data, SettingsHelper hoạt động, default settings seeded

### 3.1. Tạo Database Tables

Chạy migration tạo toàn bộ 19 bảng từ DB_SCHEMA.md. Đây là code PRODUCTION (giữ nguyên).

```php
// File: app/Migration/versions/v0_1_0_prototype.php
// Tạo tất cả 19 bảng + seed default settings
// Code migration NÀY sẽ giữ nguyên cho Phase 1
```

### 3.2. Mock Data Specification

#### `mod_hvndns_settings` — 111 default settings

```php
// Seed toàn bộ 111 settings từ SETTINGS.md (gồm cả License, Upsell tabs)
// Các thông số cần Fix cứng để Demo Feature Gating 3 trạng thái:
// - license_status = "Active"
// - dnssec_mode = "paid"
// - ddns_mode = "paid"
// - upsell_dnssec_addon_id = 14
// - upsell_ddns_addon_id = 15
```

#### `mod_hvndns_servers` — 3 servers

```
┌────┬───────────────┬──────────────┬──────┬─────────┬────────┬─────────────┐
│ id │ hostname      │ ip_address   │ port │ role    │ active │ status demo │
├────┼───────────────┼──────────────┼──────┼─────────┼────────┼─────────────┤
│ 1  │ dns1.hvn.vn   │ 103.200.21.1 │ 2222 │ primary │ true   │ Healthy     │
│ 2  │ dns2.hvn.vn   │ 103.200.21.2 │ 2222 │ second. │ true   │ Healthy     │
│ 3  │ dns3.hvn.vn   │ 103.200.21.3 │ 2222 │ second. │ true   │ Backoff     │
└────┴───────────────┴──────────────┴──────┴─────────┴────────┴─────────────┘

Server 3 mock: backoff_until = NOW() + 10min, backoff_count = 3,
last_error_msg = "Connection timed out after 15000ms"
→ Demo trạng thái server có vấn đề trên Dashboard
```

#### `mod_hvndns_domains` — 8 domains (phủ tất cả status & addons)

Bảng này giả lập query join với `tblhostingaddons` để quyết định Premium Features:

```
┌────┬──────────────────────┬───────────┬────────────────┬───────────┬───────────────┬────────────────┐
│ id │ domain               │ user_id   │ status         │ ssl       │ Addon DNSSEC  │ Addon DDNS     │
├────┼──────────────────────┼───────────┼────────────────┼───────────┼───────────────┼────────────────┤
│ 1  │ hvngroup.vn          │ 1         │ active         │ active    │ Active (14)   │ None           │
│ 2  │ example.com          │ 1         │ active         │ none      │ Active (14)   │ None           │
│ 3  │ shop-demo.vn         │ 2         │ active         │ pending   │ Active (14)   │ Active (15)    │
│ 4  │ myblog.net           │ 2         │ active         │ active    │ Active (14)   │ None           │
│ 5  │ old-site.org         │ 3         │ suspended      │ expired   │ None          │ None           │
│ 6  │ cancelled.io         │ 3         │ pending_delete │ none      │ Cancelled (14)│ None           │
│ 7  │ big-records.com      │ 1         │ active         │ active    │ (Mock mode=free)│ None           │
│ 8  │ ddns-test.hvn.vn     │ 2         │ active         │ none      │ None          │ (Mock mode=free)│
└────┴──────────────────────┴───────────┴────────────────┴───────────┴───────────────┴────────────────┘

Domain 1-4: Có mua DNSSEC Addon (14) → Tab DNSSEC hiện bình thường, ko bị Upsell.
Domain 5-6: Không Có Addon (hoặc đã hủy) → Tab DNSSEC sẽ render màn hình Upsell Card.
Domain 7: Đặc biệt mock setting global `dnssec_mode = "free"` → Toàn bộ khách mở được và không thấy Upsell.
Domain 8:ặc biệt mock setting global `ddns_mode = "free"` → DDNS Tab mở bình thường không bị Upsell.
Domain 7, 8 có mục đích là Mock dynamic Setting đổi chiều on-the-fly.
```

#### `mod_hvndns_records` — ~120 records (đa dạng types + statuses)

```
Phân bố theo domain:
- hvngroup.vn:     20 records (NS×3, SOA, A×5, AAAA×2, CNAME×3, MX×2, TXT×3, SRV×1, CAA×1)
- example.com:     15 records
- shop-demo.vn:    12 records
- myblog.net:       8 records
- old-site.org:    10 records (suspended — readonly demo)
- big-records.com: 50 records (pagination demo)
- ddns-test.hvn.vn: 5 records

Đặc biệt:
- Một số records có is_system = true (NS, SOA) → demo lock icon
- Một số records có is_locked = true → demo admin lock
- Một số records có pending_delete = true → demo "Deleting..." state
```

#### `mod_hvndns_queue` — 50 jobs (phủ tất cả statuses)

```
Phân bố status:
- PENDING:            8 jobs  (đang chờ — demo badge vàng)
- SYNCING:            3 jobs  (đang xử lý — demo spinner)
- COMPLETE:          25 jobs  (xong — demo tích xanh)
- FAILED:             6 jobs  (lỗi — demo badge đỏ + retry button)
- CANCELLED:          3 jobs  (bị hủy — demo conflict resolution)
- PERMANENTLY_FAILED: 2 jobs  (hết retry — demo cảnh báo)

Phân bố batch:
- Mỗi batch có 3 sub-jobs (1 per server)
- Batch "syncing": 1 job đang SYNCING → demo "Syncing"
- Batch "all complete": 3 COMPLETE → demo "Live on all servers"

Phân bố thời gian:
- Jobs trong 24h qua (cho Dashboard metrics)
- Jobs spread đều theo giờ (cho sparkline chart)
```

#### `mod_hvndns_sync_logs` — 200 rows

```
- Mỗi queue job có 1 sync_log
- Mix: success (HTTP 200) + failed (timeout, auth_fail, dns_conflict)
- duration_ms: random 30–500ms cho success, NULL cho timeout
- Spread trong 7 ngày qua (cho Dashboard metrics)
```

#### `mod_hvndns_audit_trail` — 100 rows

```
Actor types: client (60%), admin (25%), system (10%), api (5%)
Actions: add_record, edit_record, delete_record, create_zone, 
         enable_dnssec, zone_rollback, override_conflict, ddns_update
IP addresses: mix 3-4 IPs khác nhau
Contexts: client_editor, admin_editor, cron_provision, ddns_api
Timespan: 30 ngày qua
```

#### `mod_hvndns_record_history` — 60 rows

```
change_types: created (40%), updated (40%), deleted (20%)
Có old_value và new_value cho updated entries
```

#### `mod_hvndns_snapshots` — 10 snapshots

```
- 6 scheduled (nightly)
- 2 pre_template
- 1 pre_bulk
- 1 manual
Cho 3 domains khác nhau (hvngroup.vn, example.com, myblog.net)
```

#### `mod_hvndns_templates` — 4 templates

```
1. "Basic DNS" (default) — NS×3 + A @ → 6 records
2. "Email Optimized" — NS + MX + SPF + DKIM + DMARC → 12 records
3. "Google Workspace" — NS + Google MX + SPF → 10 records
4. "Internal Only" (is_visible_client=false) — Test template → 4 records
```

#### `mod_hvndns_quota_plans` — 3 plans

```
1. "DNS Basic"      — 20 records, 10 subdomains, 2 redirects, 5 email, DDNS off
2. "DNS Pro"        — 50 records, 20 subdomains, 5 redirects, 10 email, DDNS on, SSL on
3. "DNS Enterprise" — unlimited (0), DDNS on, DNSSEC on, SSL on
```

#### `mod_hvndns_dnssec` — 2 domains

```
- hvngroup.vn: enabled, có DS records đầy đủ
- myblog.net: disabled
```

#### `mod_hvndns_ddns_tokens` — 3 tokens

```
- ddns-test.hvn.vn: "cam" (active, last_ip = 118.70.5.6, updated 2h ago)
- ddns-test.hvn.vn: "vpn" (active, last_ip = 113.22.1.3, updated 15min ago)
- hvngroup.vn: "office" (revoked — is_active=false)
```

#### `mod_hvndns_redirects` — 5 redirects

```
- hvngroup.vn / → https://www.hvngroup.vn (301)
- example.com /promo → https://sale.example.com (302)
- example.com /app → https://app.other.io (masked, title="My App")
- shop-demo.vn / → https://shopee.vn/shop-demo (301)
- myblog.net /old → https://myblog.net/new (301)
```

#### `mod_hvndns_email_forwards` — 6 forwarders

```
- hvngroup.vn: info → admin@gmail.com, support → team@hvngroup.vn
- example.com: hello → personal@gmail.com, * (catch-all) → backup@gmail.com
- shop-demo.vn: order → owner@gmail.com
- myblog.net: contact → blogger@gmail.com
```

#### `mod_hvndns_drift_reports` — 4 drifts

```
- example.com: added_on_da (A test2 → 5.6.7.8) — pending
- example.com: modified (TXT @ SPF khác nhau) — pending
- shop-demo.vn: missing_on_da (CNAME ftp) — pending
- hvngroup.vn: modified (A www IP khác) — auto_fixed (resolved)
```

#### `mod_hvndns_ip_blacklist` — 2 IPs

```
- 192.168.1.100: blocked (expires in 30 min) — brute force DDNS
- 10.0.0.50: expired (blocked_until < now) — đã hết hạn
```

#### `mod_hvndns_notification_cooldowns` — 3 entries

```
- RULE_01 + server:3 → last_sent 10 min ago
- RULE_02 + server:3 → last_sent 10 min ago  
- RULE_06 + global → last_sent 12h ago (drift detection)
```

### 3.3. Seeder Script

```php
// File: tools/mock_seeder.php
// Chạy: php tools/mock_seeder.php [--fresh] [--table=domains] [--count=100]
//
// --fresh: Drop và recreate tất cả data
// --table: Chỉ seed 1 bảng cụ thể
// --count: Override số lượng rows (cho big-data testing)
//
// Script này KHÔNG dùng cho production — chỉ dùng development/staging

class MockSeeder
{
    public function run(bool $fresh = false): void
    {
        if ($fresh) {
            $this->truncateAllTables();
        }
        
        $this->seedSettings();        // 96 rows
        $this->seedServers();          // 3 rows
        $this->seedQuotaPlans();       // 3 rows
        $this->seedTemplates();        // 4 rows
        $this->seedDomains();          // 8 rows
        $this->seedRecords();          // ~120 rows
        $this->seedQueue();            // 50 rows
        $this->seedSyncLogs();         // 200 rows
        $this->seedAuditTrail();       // 100 rows
        $this->seedRecordHistory();    // 60 rows
        $this->seedSnapshots();        // 10 rows
        $this->seedDnssec();           // 2 rows
        $this->seedDdnsTokens();       // 3 rows
        $this->seedRedirects();        // 5 rows
        $this->seedEmailForwards();    // 6 rows
        $this->seedDriftReports();     // 4 rows
        $this->seedIpBlacklist();      // 2 rows
        $this->seedNotifCooldowns();   // 3 rows
        
        echo "✅ Seeded ~670 rows across 19 tables\n";
    }
}
```

---

## 4. Phase 0B — Client Area Prototype

> **Thời gian**: Ngày 2 (6 giờ)  
> **Output**: 8 màn hình Client hoạt động trong WHMCS với mock data  
> **Tham chiếu**: WIREFRAME.md CL-01 → CL-08

### 4.1. File Structure

```
templates/client/
├── domain_list.tpl          ← CL-01: Danh sách Domain
├── dns_editor.tpl           ← CL-02: DNS Editor (màn chính + tabs container)
├── partials/
│   ├── record_table.tpl     ← Bảng records (tách riêng để reuse admin)
│   ├── record_modal.tpl     ← CL-03: Modal Add/Edit Record
│   ├── tab_redirects.tpl    ← CL-04: Tab Redirects
│   ├── tab_email.tpl        ← CL-05: Tab Email Forwarding
│   ├── tab_dnssec.tpl       ← CL-06: Tab DNSSEC
│   ├── tab_ddns.tpl         ← CL-07: Tab DDNS
│   ├── tab_templates.tpl    ← CL-08: Load Template Dialog
│   ├── sync_badge.tpl       ← Component: Status badge (reusable)
│   └── quota_bar.tpl        ← Component: Usage bar (reusable)
│
assets/
├── css/
│   └── hvndns.css           ← CSS riêng toàn module (KHÔNG phụ thuộc theme)
├── js/
│   ├── dns-editor.js        ← Alpine.js: DNS Editor logic
│   ├── sync-tracker.js      ← Alpine.js: Polling simulation
│   ├── record-modal.js      ← Alpine.js: Add/Edit modal logic
│   ├── mock-api.js          ← Mock: Fake API responses cho prototype
│   └── notifications.js     ← Toast notification helper
```

### 4.2. Checklist từng Màn hình

#### CL-01: Danh sách Domain

```
□ Hiển thị 8 mock domains với đúng status badges
□ Mỗi domain card hiện: tên, số records, NS, trạng thái
□ Badge: 🟢Active, 🟡Syncing (có job pending), 🔴Suspended
□ Domain suspended (old-site.org) hiện mờ hơn
□ Nút "Quản lý DNS →" navigate đến CL-02
□ Box nameserver info + nút "Copy tất cả"
□ Responsive: mobile stack thành cards dọc
```

#### CL-02: DNS Editor — Màn hình chính

```
□ Header: domain name + quota bar (15/50 records) + DNSSEC badge + SSL badge
□ Tab navigation: [DNS Records] [Redirects(3)] [Email(2)] [DNSSEC] [DDNS] [Templates]
□ Tab count badges hiển thị đúng số từ mock data
□ Tabs DDNS / DNSSEC ẩn nếu quota plan không cho phép
□ Bộ lọc: dropdown type + search box + nút "Thêm bản ghi"
□ Filter hoạt động client-side (Alpine.js filter)
□ Bảng records: cột Type (badge màu), Name, Value, TTL (human-readable), Status, Actions
□ Records is_system hiện 🔒 không có nút sửa/xóa
□ Records is_locked hiện 🔒 với tooltip "Bị Admin khóa"
□ Records pending_delete hiện mờ + "Deleting..."
□ Sync badges phản ánh mock queue status:
  - Records có batch all COMPLETE → 🟢 Live
  - Records có batch syncing → 🔄 Syncing
  - Records có batch all PENDING → 🟡 Pending
  - Records có batch FAILED → 🔴 Failed + [Retry]
□ Pagination: 10 records/page, navigation buttons
□ Record type dropdown chỉ hiện types được bật (tham chiếu SETTINGS.md #18-25)
□ Responsive: table scroll horizontal trên mobile
```

#### CL-03: Modal Add/Edit Record

```
□ Modal mở khi click "Thêm bản ghi" hoặc icon ✏️
□ Dropdown type: chỉ hiện allowed types + mô tả helper cho mỗi type
□ Fields động: Priority/Weight/Port hiện khi chọn MX hoặc SRV
□ Helper text thay đổi theo type (A → "Địa chỉ IPv4", CNAME → "Tên miền đích")
□ TTL dropdown: 1 phút, 5 phút, 30 phút, 1 giờ (default), 12 giờ, 24 giờ, Tùy chỉnh
□ Validation hiện real-time (Alpine.js): IP format, FQDN, TTL range
□ Submit: nút chuyển spinner → fake success → modal đóng
□ Record mới xuất hiện trong bảng với badge 🟡 Pending
□ Sau 3 giây → badge tự chuyển 🟢 Live (simulate sync)
□ Toast: "✅ Đã lưu! Bản ghi đang được đồng bộ..."
□ Edit mode: title đổi, Type + Name disabled, pre-fill values
□ Xóa: confirm dialog → record mờ → biến mất sau 2 giây
```

#### CL-04: Tab Redirects

```
□ Bảng 5 mock redirects: Source, Destination, Type (301/302/masked), Status
□ Nút "Thêm chuyển hướng" → modal
□ Modal: source path, destination URL, type radio (301/302/masked)
□ Masked fields (title, meta desc) hiện khi chọn Masked
□ Quota info: "Đang dùng 3/5 chuyển hướng"
```

#### CL-05: Tab Email Forwarding

```
□ Bảng mock email forwarders
□ Nút "Thêm chuyển tiếp" → modal (source local part + destination email)
□ Catch-all toggle: checkbox + input email + cảnh báo spam
□ Quota info: "Đang dùng 2/5 chuyển tiếp"
```

#### CL-06: Tab DNSSEC

```
□ Trạng thái Enabled: bảng DS Records (Key Tag, Algorithm, Digest Type, Digest)
□ Nút Copy từng field + "Copy tất cả"
□ Hướng dẫn cấu hình nhà đăng ký (accordion expandable)
□ Cảnh báo khi tắt DNSSEC (xóa DS tại registrar trước)
□ Trạng thái Disabled: nút "Bật DNSSEC" + mô tả tính năng
□ Chỉ hiện tab nếu quota plan cho phép
```

#### CL-07: Tab DDNS

```
□ Bảng 2 mock tokens: subdomain, label, IP hiện tại, last update
□ Nút "Tạo DDNS Token" → modal (chọn subdomain + nhập label)
□ Click ⚙️ → panel chi tiết: URL endpoint, hướng dẫn Mikrotik/DrayTek
□ Code blocks có nút Copy
□ Token revoked hiện mờ + badge "Đã thu hồi"
□ Nút "Tạo lại Token" + "Xóa Token" với confirm dialog
□ Quota info: "Đang dùng 2/5 token"
```

#### CL-08: Load Template Dialog

```
□ Radio chọn 3 templates (template 4 ẩn vì is_visible_client=false)
□ Mỗi template hiện: tên, mô tả, số records
□ Cảnh báo XÓA TOÀN BỘ records hiện tại
□ Checkbox "Tôi hiểu..." bắt buộc tick
□ Nút "Áp dụng" disabled khi chưa tick
```

---

## 5. Phase 0C — Admin Area Prototype

> **Thời gian**: Ngày 3-4 (10 giờ)  
> **Output**: 12 màn hình Admin hoạt động trong WHMCS  
> **Tham chiếu**: WIREFRAME.md AD-01 → AD-12

### 5.1. File Structure

```
templates/admin/
├── dashboard.tpl             ← AD-01: Dashboard
├── server_list.tpl           ← AD-02: Server Management
├── server_modal.tpl          ← AD-03: Modal Add/Edit Server
├── domain_list.tpl           ← AD-04: Global Domain List
├── dns_editor_admin.tpl      ← AD-05: Admin DNS Editor
├── sync_logs.tpl             ← AD-06: Sync Logs
├── audit_trail.tpl           ← AD-07: Audit Trail
├── template_manager.tpl      ← AD-08: Template Manager
├── quota_plans.tpl           ← AD-09: Quota Plans
├── drift_reports.tpl         ← AD-10: Drift Reports
├── bulk_operations.tpl       ← AD-11: Bulk Operations
├── settings.tpl              ← AD-12: Module Settings (16 tabs)
├── partials/
│   ├── sidebar.tpl           ← Sidebar navigation (reuse mọi trang)
│   ├── alert_banner.tpl      ← Alert banner (reuse mọi trang)
│   ├── server_card.tpl       ← Server card component
│   └── activity_feed.tpl     ← Recent activity feed
│
assets/js/
├── admin-dashboard.js        ← Chart.js + activity feed polling
├── admin-datatables.js       ← DataTable configs (server-side mock)
├── admin-settings.js         ← Settings tabs + save logic
└── admin-bulk.js             ← Bulk operations preview + progress
```

### 5.2. Checklist từng Màn hình

#### AD-01: Dashboard

```
□ Alert Banner đỏ: "dns3.hvn.vn mất kết nối — 7 job FAILED" (mock từ server 3)
□ Sync Pipeline 24h: 3 widget số lớn (Complete: 1247, Pending: 23, Failed: 12)
□ Sparkline chart (Chart.js): line chart jobs theo giờ trong 24h
□ Server Health: 3 cards (2 xanh, 1 đỏ) với uptime %, avg ms, pending count
□ Server đỏ: hiện backoff info + nút [Test] [Disable]
□ Tổng quan: Total domains (8), Total records (120), Top 5 changes
□ Activity Feed: 10 dòng gần nhất từ mock sync_logs, auto-scroll
□ Auto-refresh mỗi 30 giây (mock: data không đổi nhưng animation chạy)
□ Sidebar navigation: highlight "Dashboard" active
□ Responsive: widgets stack dọc trên tablet
```

#### AD-02: Server Management

```
□ 3 server cards (layout từ WIREFRAME AD-02)
□ Card xanh: hostname, IP, port, SSL, role, metrics (uptime, avg ms, pending, today complete)
□ Card đỏ (server 3): backoff info, error message, [Reset Backoff]
□ Nút [Test Connection]: fake loading 2s → fake result (success hoặc fail)
□ Nút [Disable]: confirm → card chuyển xám + badge "Disabled"
□ Nút [+ Thêm Server] → modal AD-03
```

#### AD-03: Modal Add/Edit Server

```
□ Form: hostname, IP, port, username, password (masked), SSL toggle
□ Role radio: Primary / Secondary
□ Max concurrent input
□ Notes textarea
□ Nút [Test Connection]: inline result box (version, latency, zones, DNSSEC)
□ Nút [Lưu Server]: fake save → modal đóng → server xuất hiện trong list
```

#### AD-04: Global Domain List

```
□ DataTable server-side: Domain, Client, Records, Last Sync, Status
□ Search box + 4 filter dropdowns (status, server, quota, errors only)
□ Click domain → navigate AD-05
□ Click client name → WHMCS client profile (external link)
□ Badge domain có FAILED jobs → highlight đỏ
□ Pagination mock: 8 domains, show "1-8 / 8"
```

#### AD-05: Admin DNS Editor

```
□ Banner: "🔧 ADMIN MODE — Đang quản lý thay cho: Nguyễn A (#1234)"
□ Tất cả tính năng CL-02 + thêm:
  - Không bị rate limit (thông báo ẩn)
  - Sửa/xóa được records is_system
  - Nút [🔒Lock] / [🔓Unlock] trên mỗi record
  - Toolbar: [Snapshot] [Rollback] [Xem History]
□ Click [Rollback] → dialog chọn snapshot → preview diff → confirm
□ Rollback dialog: hiện danh sách 3-4 mock snapshots + diff preview
```

#### AD-06: Sync Logs

```
□ DataTable: Time, Domain, Action, Server, Status, Duration, [Detail]
□ 200 mock rows với server-side pagination (giả lập)
□ Filter bar: status, server, action, domain, date range
□ Nút [Retry All Failed (6 jobs)]: fake retry → toast success
□ Click [Detail] → panel mở: full job info, payload JSON, DA response, error
□ Nút [Export CSV]: fake download (hoặc alert "Demo mode")
```

#### AD-07: Audit Trail

```
□ DataTable: Time, Actor (icon + name), Domain, Action, Detail, IP
□ 100 mock rows
□ Filter: actor type, action, domain, IP, date range
□ Click row → popup full detail (old_value JSON, new_value JSON, user agent, session, notes)
□ Nút [Export CSV] [Export PDF]
□ Actor icons: 👤Client, 🔧Admin, ⚙️System, 🔌API
```

#### AD-08: Template Manager

```
□ 4 mock templates dạng card
□ Template default: badge [DEFAULT]
□ Template internal: badge "Ẩn khỏi Client"
□ Click [Sửa] → template editor inline: bảng records + placeholder hints
□ Nút [Set Default], [Clone], [Xóa]
□ Nút [+ Tạo Template]
```

#### AD-09: Quota Plans

```
□ Bảng 3 plans: tên, records, subdomains, redirects, email, DDNS, DNSSEC, SSL
□ ∞ hiện cho giá trị 0 (unlimited)
□ ✅/❌ hiện cho boolean features
□ Click [Sửa] → modal form
```

#### AD-10: Drift Reports

```
□ Header: "Lần scan gần nhất: ... | Kế tiếp: ..."
□ Filter: [Tất cả] [Chỉ Pending]
□ 3 domain cards có drift, mỗi card liệt kê records lệch
□ Mỗi drift record: type, WHMCS value, DA value
□ 3 nút action: [Pull DA→WHMCS] [Push WHMCS→DA] [Bỏ qua]
□ Toggle "Tự động sửa drift" checkbox
□ 1 domain resolved (hvngroup.vn) hiện mờ với badge "Auto-fixed"
```

#### AD-11: Bulk Operations

```
□ Radio: Thay đổi IP hàng loạt / Áp dụng Template hàng loạt
□ IP change form: Old IP, New IP, Scope radio
□ Nút [Quét & Preview] → fake result: "23 records trên 15 domains"
□ Danh sách checkboxes domain bị ảnh hưởng
□ Nút [Thực hiện] → progress bar animation (fake 0% → 100% trong 5 giây)
□ Kết quả: "✅ 15 thành công, 0 lỗi"
```

#### AD-12: Module Settings

```
□ 16 tabs navigation (từ SETTINGS.md 19 nhóm, gộp một số nhỏ)
□ Tab [Chung]: Module enabled, license, NS1-5, default TTL
□ Tab [Domain Policy]: respect WHMCS DNS, NS check, pre-registrar hooks, grace period
□ Tab [DNS Editor]: enable editor, subdomain limit
□ Tab [Permissions]: 8 checkboxes bật/tắt record types
□ Tab [Limits]: 8 inputs giới hạn per-type + info text "0 = unlimited"
□ Tab [Redirects]: enable redirect, masked, hash key, limit
□ Tab [Email]: enable forwarder, catch-all, limits, verify template dropdown
□ Tab [DDNS]: enable, rate limit, token limit, brute force config
□ Tab [DNSSEC]: enable, auto resign
□ Tab [SSL]: auto SSL, client trigger, renew days, PHP enable
□ Tab [Templates]: enable templates, user custom, limit
□ Tab [Thông báo Client]: enable, email template, notify triggers
□ Tab [UI]: domain service link, menu visibility, menu order
□ Tab [Performance]: fetch strategy, cache TTL, large DB mode, rate limit
□ Tab [Queue]: cron interval, timeout, retry, stale lock, conflict window
□ Tab [Alert Admin]: Telegram config, email config, thresholds, cooldown
□ Mỗi tab: nút [💾 Lưu] → fake save → toast "Đã lưu thành công!"
□ Validation real-time: NS không trống, TTL range, hash key min length
```

---

## 6. Phase 0D — Review & Sign-off

> **Thời gian**: Ngày 5 (3 giờ)

### 6.1. Demo Walkthrough

```
Agenda (60 phút):

1. Client Area walkthrough (20 phút)
   □ Login WHMCS Client → mở dịch vụ DNS
   □ Duyệt domain list → mở DNS Editor
   □ Demo thêm/sửa/xóa record → xem animation
   □ Demo các tab: Redirects, Email, DNSSEC, DDNS, Templates
   □ Demo domain suspended (readonly)
   □ Demo responsive (thu nhỏ browser)

2. Admin Area walkthrough (30 phút)
   □ Mở Dashboard → xem metrics, charts, server health
   □ Server Management → test connection, disable server
   □ Global Domains → search, click vào domain → Admin DNS Editor
   □ Sync Logs → filter, detail view, retry
   □ Audit Trail → filter by actor, export
   □ Templates → tạo/sửa template
   □ Settings → duyệt qua 16 tabs
   □ Drift Reports → xem drifts, action buttons
   □ Bulk Operations → preview flow

3. Thu thập feedback (10 phút)
   □ Ghi nhận issues vào checklist
   □ Phân loại: Must-fix / Nice-to-have / Backlog
```

### 6.2. Feedback Template

```markdown
## Prototype Review — [Ngày]

### Must-fix (Sửa trước khi bắt đầu Phase 1)
- [ ] ...

### Nice-to-have (Sửa trong Phase 1)
- [ ] ...

### Backlog (Xem xét sau)
- [ ] ...

### Sign-off
- [ ] Product Owner: _______ (Tên + Ngày)
- [ ] Lead Developer: _______ (Tên + Ngày)
```

---

## 7. Mock API Layer

> Tất cả Ajax calls trong prototype đi qua Mock API thay vì backend thật.

### 7.1. Cách hoạt động

```javascript
// File: assets/js/mock-api.js

const MOCK_DELAY = 300; // Giả lập network delay (ms)
const SYNC_SIMULATE_DELAY = 3000; // Giả lập sync time (ms)

const MockAPI = {
    /**
     * Mock: Thêm record
     * Trả fake success, thêm record vào Alpine.js state,
     * tự chuyển status pending → live sau 3 giây
     */
    async addRecord(data) {
        await this._delay(MOCK_DELAY);
        
        const fakeId = Math.floor(Math.random() * 10000) + 1000;
        const fakeBatchId = this._uuid();
        
        // Simulate sync: chuyển trạng thái sau N giây
        setTimeout(() => {
            window.dispatchEvent(new CustomEvent('sync-complete', {
                detail: { batchId: fakeBatchId, recordId: fakeId }
            }));
        }, SYNC_SIMULATE_DELAY);
        
        return {
            success: true,
            data: { record_id: fakeId, batch_id: fakeBatchId },
            message: 'Bản ghi DNS đã được lưu và đang đồng bộ.'
        };
    },

    /**
     * Mock: Sync status polling
     * Lần đầu trả "syncing", lần sau trả "complete"
     */
    async syncStatus(batchId) {
        await this._delay(100);
        
        const state = this._getSyncState(batchId);
        return {
            success: true,
            data: {
                batch_id: batchId,
                status: state,
                total: 1,
                complete: state === 'complete' ? 1 : state === 'syncing' ? 1 : 0,
                servers: [
                    { hostname: 'dns1.hvn.vn', status: state === 'complete' ? 'complete' : 'syncing', info: state === 'complete' ? '' : 'Đang xử lý...' }
                ]
            }
        };
    },

    /**
     * Mock: Dashboard stats
     * Đọc từ mock DB hoặc trả hardcoded
     */
    async dashboardStats() {
        await this._delay(MOCK_DELAY);
        return {
            success: true,
            data: {
                pipeline_24h: { complete: 1247, pending: 23, failed: 12, cancelled: 3 },
                servers: [
                    { id: 1, hostname: 'dns1.hvn.vn', uptime_percent: 99.8, avg_response_ms: 45, pending_jobs: 12, in_backoff: false },
                    { id: 2, hostname: 'dns2.hvn.vn', uptime_percent: 99.5, avg_response_ms: 52, pending_jobs: 12, in_backoff: false },
                    { id: 3, hostname: 'dns3.hvn.vn', uptime_percent: 97.1, avg_response_ms: null, pending_jobs: 7, in_backoff: true },
                ],
                overview: { total_domains: 8, total_records: 120, active_domains: 6 },
                alerts: { has_critical: true, messages: ['dns3.hvn.vn mất kết nối từ 14:30 — 7 job FAILED liên tiếp'] }
            }
        };
    },

    // ... Mock cho tất cả endpoints khác

    _delay: (ms) => new Promise(r => setTimeout(r, ms)),
    _uuid: () => crypto.randomUUID?.() || 'mock-' + Date.now(),
    _syncStates: {},
    _getSyncState(batchId) {
        if (!this._syncStates[batchId]) {
            this._syncStates[batchId] = { created: Date.now(), state: 'pending' };
        }
        const elapsed = Date.now() - this._syncStates[batchId].created;
        if (elapsed > SYNC_SIMULATE_DELAY) return 'complete';
        if (elapsed > MOCK_DELAY) return 'syncing';
        return 'pending';
    }
};
```

### 7.2. Chuyển đổi Mock → Real API

Khi bước vào Phase 1, thay MockAPI bằng real API chỉ cần đổi 1 file:

```javascript
// Phase 0 (Prototype):
const API = MockAPI;

// Phase 1 (Production):
const API = RealAPI; // Gọi Ajax endpoint thật

// Alpine.js components KHÔNG đổi — chỉ đổi API source
```

---

## 8. Quy tắc Prototype Code

### 8.1. Code giữ lại cho Production

```
✅ GIỮ NGUYÊN (production-ready):
- Tất cả Smarty templates (.tpl)
- CSS (hvndns.css)
- Alpine.js components (dns-editor.js, sync-tracker.js, ...)
- Chart.js configurations
- DataTable configurations
- Database migration (v0_1_0)
- SettingsHelper class
- Template partials / reusable components
- Responsive layouts
- Accessibility attributes (aria-*)
```

### 8.2. Code thay thế trong Phase 1

```
🔄 THAY THẾ khi vào Phase 1:
- mock-api.js → Real Ajax calls tới PHP endpoints
- Mock seeder → Không dùng nữa (data thật từ provisioning)
- Hardcoded demo data trong templates → Dynamic data từ Controller
- Fake sync simulation → Real polling tới sync_status endpoint
```

### 8.3. Code xóa sau Prototype

```
🗑️ XÓA sau Phase 0:
- tools/mock_seeder.php (hoặc giữ cho dev environment)
- mock-api.js (thay bằng real-api.js)
- Bất kỳ `<!-- MOCK -->` comments
```

---

## 9. Checklist Nghiệm thu Prototype

### 9.1. Client Area

```
CL-01 Domain List:
□ Hiển thị đúng 8 domains với status badges
□ Nút "Quản lý DNS" navigate đúng
□ Nameserver info box + Copy button hoạt động
□ Responsive mobile OK

CL-02 DNS Editor:
□ Header: quota bar, DNSSEC badge, SSL badge hiển thị đúng
□ Tab navigation: count badges đúng, active tab highlight
□ Tab ẩn/hiện theo quota plan settings
□ Filter type dropdown hoạt động
□ Search filter hoạt động (client-side)
□ Bảng records: đủ cột, badge màu đúng, TTL human-readable
□ System records (NS): icon 🔒, không có nút sửa/xóa
□ Locked records: icon 🔒 + tooltip
□ Pending delete records: mờ + "Deleting..."
□ Sync badges đúng trạng thái (Live, Syncing, Pending, Failed)
□ Pagination hoạt động
□ Responsive: table scroll trên mobile

CL-03 Modal Add/Edit:
□ Type dropdown chỉ hiện allowed types
□ Fields động theo type (Priority cho MX/SRV)
□ Helper text thay đổi theo type
□ TTL dropdown hoạt động
□ Validation real-time hiển thị lỗi
□ Submit → spinner → success → record xuất hiện → badge chuyển
□ Edit mode: Type + Name disabled, pre-fill đúng
□ Delete: confirm → fade out

CL-04 Redirects:
□ Bảng hiển thị mock data
□ Modal thêm mới hoạt động
□ Masked fields hiện khi chọn Masked
□ Quota info đúng

CL-05 Email:
□ Bảng forwarders + catch-all toggle
□ Quota info đúng

CL-06 DNSSEC:
□ Enabled state: DS Record table + Copy buttons
□ Disabled state: nút Enable + mô tả
□ Hướng dẫn nhà đăng ký rõ ràng

CL-07 DDNS:
□ Token table + detail panel
□ Hướng dẫn Mikrotik/DrayTek + code Copy
□ Token revoked hiện mờ

CL-08 Templates:
□ Radio chọn 3 templates (template 4 ẩn)
□ Cảnh báo + checkbox bắt buộc
□ Nút disabled khi chưa tick
```

### 9.2. Admin Area

```
AD-01 Dashboard:
□ Alert banner hiển thị + dismiss hoạt động
□ 3 widget pipeline có số đúng
□ Chart sparkline render đúng
□ Server health cards: 2 xanh + 1 đỏ
□ Overview stats đúng
□ Activity feed hiển thị
□ Sidebar navigation active highlight

AD-02/03 Servers:
□ 3 server cards đúng layout
□ Test Connection animation + result
□ Disable toggle hoạt động
□ Modal Add/Edit form đầy đủ fields

AD-04/05 Domains + Admin Editor:
□ DataTable search + filter
□ Click → Admin DNS Editor
□ Admin banner hiển thị
□ Lock/Unlock buttons
□ Rollback dialog + snapshot list + diff preview

AD-06 Sync Logs:
□ DataTable 200 rows pagination
□ Filter bar hoạt động
□ Detail panel mở/đóng
□ Retry All button
□ Export button

AD-07 Audit Trail:
□ DataTable + filters
□ Detail popup
□ Actor icons đúng
□ Export buttons

AD-08/09 Templates + Quota:
□ Template cards + editor
□ Quota table: ∞ cho unlimited, ✅/❌ cho features

AD-10 Drift Reports:
□ 3 domain cards + action buttons
□ Resolved domain mờ

AD-11 Bulk Operations:
□ Preview flow hoạt động
□ Progress bar animation

AD-12 Settings:
□ 16 tabs navigate đúng
□ Tất cả form fields render
□ Save button + toast
□ Validation hiển thị lỗi
```

### 9.3. Cross-cutting

```
□ CSS riêng (hvndns.css) hoạt động với WHMCS Twenty-One theme
□ CSS riêng hoạt động với WHMCS Six theme
□ Không conflict với CSS WHMCS native
□ Alpine.js không conflict với WHMCS jQuery
□ Bootstrap 5 CDN load thành công
□ Tất cả CDN (Alpine, DataTables, Chart.js, Bootstrap Icons) load OK
□ Responsive: Desktop (1920px), Laptop (1366px), Tablet (768px), Mobile (375px)
□ Toast notifications hiển thị đúng vị trí
□ Loading spinners smooth
□ Transitions/animations mượt (không giật)
□ Không console errors trong browser DevTools
```

---

## 10. Chuyển tiếp Prototype → Production

### 10.1. Mapping Phase 0 → Phase 1

```
Phase 0 hoàn thành:
├── ✅ 19 bảng DB tạo xong (migration production-ready)
├── ✅ SettingsHelper hoạt động (production-ready)
├── ✅ 96 default settings seeded (production-ready)
├── ✅ 20 Smarty templates (production-ready)
├── ✅ CSS riêng (production-ready)
├── ✅ Alpine.js components (production-ready, chỉ đổi API source)
├── ✅ Chart.js + DataTables configs (production-ready)
├── ✅ Reusable partials (badge, quota bar, sidebar)
├── 🔄 mock-api.js → cần thay bằng real API
├── 🗑️ mock_seeder.php → không cần nữa

Phase 1 bắt đầu:
├── Code Eloquent Models (18 models)
├── Code DAGateway + DAResponseParser
├── Code QueueManager + Cron Worker
├── Code Controllers (gọi Services → trả JSON đúng format mock-api đã dùng)
├── Code Services (DnsRecordService, ConflictResolver, QuotaEnforcer)
├── Code Validators
├── Thay mock-api.js → real fetch() calls
├── Hook WHMCS (provisioning, menu)
└── Test end-to-end
```

### 10.2. API Contract

Mock API đã thiết lập **API contract** — response format mà frontend expect. Backend Phase 1 PHẢI trả đúng format này:

```
Prototype mock-api.js trả:
{
    "success": true,
    "data": { "record_id": 789, "batch_id": "uuid" },
    "message": "Bản ghi DNS đã được lưu..."
}

Phase 1 Controller PHẢI trả:
{
    "success": true,
    "data": { "record_id": 789, "batch_id": "uuid" },  ← CÙNG STRUCTURE
    "message": "Bản ghi DNS đã được lưu..."
}
```

Nếu backend thay đổi response structure → frontend sẽ vỡ. **Mock API chính là API contract**.

---

> **Tài liệu này hết hiệu lực sau khi Phase 0D sign-off hoàn thành và Phase 1 bắt đầu.**

## Changelog
| Ngày | Thay đổi | Người thực hiện |
|------|----------|-----------------|
| 26/02/2026 | Khởi tạo v1.0 — Full prototype plan | — |
