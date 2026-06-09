# Google Antigravity — Rules & Workflows
## HVN - DirectAdmin DNS Manager

> **Mục đích**: Bộ cấu hình Rules và Workflows cho Google Antigravity IDE, điều phối Agent phát triển module HVN DNS Manager đúng theo kiến trúc, convention, và quy trình đã thiết kế.
>
> **Cách cài đặt**: Copy các file vào đúng vị trí trong workspace theo cấu trúc bên dưới.

---

## Cấu trúc File

```
modules/addons/hvn_dns_manager/          ← Workspace root
│
├── .agent/
│   ├── rules/
│   │   ├── 01-project-context.md        ← Always On — Context dự án
│   │   ├── 02-architecture.md           ← Always On — Kiến trúc bất đồng bộ
│   │   ├── 03-code-style.md             ← Always On — Coding conventions
│   │   ├── 04-database.md               ← Glob: **/*.php — DB conventions
│   │   ├── 05-security.md               ← Always On — Security rules
│   │   ├── 06-da-api.md                 ← Glob: **/Gateway/** — DA API gotchas
│   │   ├── 07-frontend.md               ← Glob: **/*.tpl, **/*.js — Frontend rules
│   │   └── 08-testing.md                ← Glob: **/tests/** — Testing conventions
│   │
│   └── workflows/
│       ├── implement-issue.md           ← /implement — Implement 1 issue
│       ├── implement-story.md           ← /implement-story — Implement toàn bộ story
│       ├── review-code.md               ← /review — Review code file
│       ├── generate-tests.md            ← /test — Sinh test cho file/issue
│       ├── create-model.md              ← /model — Tạo Eloquent Model
│       ├── create-migration.md          ← /migration — Tạo DB migration
│       ├── create-controller.md         ← /controller — Tạo Controller + Ajax endpoint
│       ├── create-template.md           ← /template — Tạo Smarty template
│       ├── debug-fix.md                 ← /fix — Debug và sửa bug
│       ├── check-status.md              ← /status — Kiểm tra tiến độ dự án
│       ├── release-check.md             ← /release — Pre-release checklist
│       └── da-api-reference.md          ← /da-api — Tra cứu DA API nhanh
│
├── docs/
│   ├── AGENT.md
│   ├── PLAN.md
│   ├── EPICS.md
│   ├── SPEC.md
│   ├── DB_SCHEMA.md
│   ├── API_REFERENCE.md
│   ├── WIREFRAME.md
│   └── TEST_PLAN.md
│
└── (source code...)
```

---

# PHẦN 1 — RULES (Quy tắc luôn hoạt động)

> Rules là system instructions — Agent tự động tuân thủ mà không cần trigger.
> Mỗi file `.md` trong `.agent/rules/` là 1 rule riêng biệt.

---

## File: `.agent/rules/01-project-context.md`

```markdown
---
activation: always
---

# HVN DNS Manager — Project Context

## Thông tin dự án
- **Tên module**: HVN - DirectAdmin DNS Manager
- **Nền tảng**: WHMCS 8.x Addon Module
- **Ngôn ngữ**: PHP 7.4+ (target PHP 8.1)
- **Database**: MySQL/MariaDB qua WHMCS Eloquent ORM (Capsule)
- **Frontend**: Smarty Template + Native CSS (WHMCS) + Pure CSS + Alpine.js 3.x
- **Namespace gốc**: `HvnGroup\DnsManager`
- **Tiền tố DB**: `mod_hvndns_`

## Tài liệu tham chiếu (theo thứ tự ưu tiên)
Khi cần thông tin chi tiết, đọc các file trong `docs/`:
1. `docs/AGENT.md` — Quy tắc điều phối tối thượng
2. `docs/DB_SCHEMA.md` — Database schema, định nghĩa cột, indexes
3. `docs/API_REFERENCE.md` — DA API + Internal Ajax API + Error Codes
4. `docs/SPEC.md` — Kiến trúc hệ thống, flow diagrams
5. `docs/EPICS.md` — User stories, acceptance criteria, issue list
6. `docs/TEST_PLAN.md` — Test cases, fixtures, checklists
7. `docs/WIREFRAME.md` — Phác thảo giao diện
8. `docs/PLAN.md` — Kế hoạch phát triển tổng thể

## Quy tắc tham chiếu theo ngữ cảnh
- Code database (Model, migration, query) → đọc `docs/DB_SCHEMA.md`
- Code gọi DA API (Gateway, parser) → đọc `docs/API_REFERENCE.md` Phần A
- Code Ajax endpoint (Controller, response) → đọc `docs/API_REFERENCE.md` Phần B
- Code giao diện (template, JS) → đọc `docs/WIREFRAME.md`
- Code luồng xử lý (Service, Queue, Cron) → đọc `docs/SPEC.md`
- Viết test → đọc `docs/TEST_PLAN.md`
- Implement issue → đọc `docs/EPICS.md`

## Phase hiện tại
Dự án đang ở **Phase 1 (MVP)**. Chỉ implement các tính năng thuộc Phase 1:
- Queue core + Cron Worker
- DNS Record CRUD (A, AAAA, CNAME, MX, TXT, SRV, NS, CAA)
- Client DNS Editor + Sync Tracker
- Admin: Server Config, Domain List, Sync Logs, Retry
- Auto-provisioning (WHMCS hooks)

CHƯA implement (Phase 2-3): DNSSEC, DDNS API, URL Redirect, Masked Redirect, Auto-SSL, Email Forwarding, Drift Detection, Bulk Operations, REST API.
```

---

## File: `.agent/rules/02-architecture.md`

```markdown
---
activation: always
---

# Kiến trúc Bất đồng bộ — Quy tắc Tuyệt đối

## Nguyên tắc Async-First
Mọi thao tác thay đổi DNS PHẢI đi qua hàng đợi (Queue). KHÔNG BAO GIỜ gọi API DirectAdmin trong request lifecycle của Client hoặc Admin.

### TUYỆT ĐỐI CẤM
- Gọi API DirectAdmin trong Controller hoặc Service khi xử lý HTTP request
- Sử dụng `curl_init()`, `file_get_contents()`, `HTTPSocket` tới DA server trong bất kỳ file nào ngoài `cron/` và `Gateway/`
- Chờ đợi response từ DA trước khi trả kết quả cho user
- Import hoặc sử dụng class `DAGateway` trong Controller

### BẮT BUỘC
- Mọi thay đổi DNS → `QueueManager::dispatch()` → Lưu DB → Trả JSON success cho user
- Chỉ các file trong `cron/` mới được gọi `DAGateway`
- Response cho user phải hoàn thành trong < 200ms (chỉ write DB)

### Ngoại lệ duy nhất
`DAGateway::testConnection()` được gọi từ Admin Controller khi bấm nút "Test Connection" — đây là hành động diagnostic có chủ đích.

## Primary-only Push
- `QueueManager::dispatch()` từ danh sách server active, chỉ tạo 1 job cho Primary Server
- Các Secondary Server sẽ được đồng bộ tự động qua cơ chế của DA Cluster (AXFR/IXFR)
- Không tạo sub-job cho các server phụ

## WHMCS là Source of Truth
- Database WHMCS (`mod_hvndns_records`) là nguồn dữ liệu chính thức
- DirectAdmin là target execution layer, KHÔNG phải source of truth
- Khi có xung đột, dữ liệu WHMCS được ưu tiên
```

---

## File: `.agent/rules/03-code-style.md`

```markdown
---
activation: always
---

# PHP Coding Conventions

## Naming
- Class: `PascalCase` (VD: `QueueManager`, `DnsRecordValidator`)
- Method/Function: `camelCase` (VD: `dispatch()`, `getActiveServers()`)
- Variable: `camelCase` (VD: `$batchId`, `$domainId`)
- Constant: `UPPER_SNAKE_CASE` (VD: `MAX_RETRY`, `STATUS_PENDING`)
- DB table: `mod_hvndns_` + `snake_case` (VD: `mod_hvndns_queue`)
- DB column: `snake_case` (VD: `domain_id`, `created_at`)

## Cấu trúc code
- Mọi class trong `app/` PHẢI có namespace `HvnGroup\DnsManager\{SubDir}`
- Mọi public method PHẢI có PHPDoc với `@param`, `@return`, `@throws`
- Mọi method PHẢI có type declarations cho parameters và return types
- Visibility LUÔN explicit (`public`, `private`, `protected`)

## Controller Pattern
- Controller KHÔNG chứa business logic
- Controller chỉ: nhận request → gọi Service → trả response
- Business logic đặt trong `Services/`
- Validation đặt trong `Validators/`

## Response Format (cho mọi Ajax endpoint)
```json
// Success
{"success": true, "data": {...}, "message": "..."}

// Error
{"success": false, "error": {"code": "ERROR_CODE", "message": "...", "field": "..."}}
```

## Logging
- Sử dụng Monolog qua WHMCS (KHÔNG tự tạo file .txt)
- `info` — sự kiện bình thường (dispatch, complete)
- `warning` — có vấn đề nhưng tiếp tục được (retry, backoff)
- `error` — lỗi cần chú ý (connection fail, auth fail)
- KHÔNG BAO GIỜ log: passwords, tokens, credentials, stack traces chứa credentials
```

---

## File: `.agent/rules/04-database.md`

```markdown
---
activation: always
---

# Database Conventions

## Quy tắc tuyệt đối
- Sử dụng Eloquent ORM cho MỌI database operation
- KHÔNG BAO GIỜ dùng raw SQL: `DB::raw()`, `mysql_query()`, nối chuỗi SQL
- Tiền tố TẤT CẢ bảng: `mod_hvndns_`
- Mã hóa password DA: `WHMCS\Security\Encryption::encode()` / `decode()`
- Bảng `mod_hvndns_audit_trail` là APPEND-ONLY: CHỈ INSERT, KHÔNG UPDATE/DELETE

## 18 bảng trong hệ thống (chi tiết tại docs/DB_SCHEMA.md)
schema_version, servers, domains, records, queue, sync_logs, audit_trail,
record_history, snapshots, templates, quota_plans, dnssec, ddns_tokens,
redirects, email_forwards, drift_reports, ip_blacklist, notification_cooldowns

## Eloquent Model rules
- `$table` = tên bảng đầy đủ với tiền tố
- `$fillable` = lấy CHÍNH XÁC từ DB_SCHEMA.md
- `$casts`: TINYINT(1) → `'boolean'`, INT → `'integer'`, JSON → `'array'`
- `$hidden` = fields nhạy cảm (password_enc, token_hash, ip_address cho client-facing)
- Relationships tham chiếu ERD trong DB_SCHEMA.md

## Đặc biệt theo Model
- `AuditTrail`: Block `update()` và `delete()` bằng RuntimeException
- `Server`: password qua mutator encrypt/decrypt, KHÔNG để trong `$fillable`
- `DdnsToken`: `token_hash` là SHA-256 one-way, plain token chỉ hiện 1 lần
- `QueueJob`, `Snapshot`, `Template`: JSON columns cast `'array'`
- `IpBlacklist`: scope `active()` filter by `blocked_until > now()`

## Migration
- Dùng WHMCS Hook `AfterModuleActivate` để chạy migration tự động
- Migration PHẢI idempotent (kiểm tra `hasTable` trước khi create)
- Quản lý version qua `mod_hvndns_schema_version`
- KHÔNG dùng `DROP TABLE` trong production migration
```

---

## File: `.agent/rules/05-security.md`

```markdown
---
activation: always
---

# Security Rules — Không Thỏa Hiệp

## Input Validation
- MỌI user input → `InputSanitizer::clean()` → `DnsRecordValidator::validate()`
- KHÔNG trust bất kỳ input nào từ user mà không validate
- CSRF protection qua WHMCS token system cho mọi POST request

## Data Protection
- Client Area KHÔNG BAO GIỜ thấy: server IP, port, password, raw error từ DA
- Client chỉ thấy: server hostname (dns1.hvn.vn), thông báo lỗi thân thiện
- Error message cho client: generic "Đồng bộ thất bại", KHÔNG leak technical details
- Admin Area: hiển thị đầy đủ nhưng password luôn masked (••••••)

## Forbidden Operations
- KHÔNG sử dụng: `eval()`, `exec()`, `shell_exec()`, `system()`
- KHÔNG lưu DDNS token plaintext (phải SHA-256 hash)
- KHÔNG expose raw DA error message, stack trace, SQL error cho client
- KHÔNG tạo endpoint nào cho phép UPDATE/DELETE bảng `audit_trail`

## Encryption
- DA Server password: `WHMCS\Security\Encryption::encode()` (AES-256)
- DDNS Token: SHA-256 hash (one-way) — plain token chỉ hiển thị 1 lần khi tạo
- Telegram Bot Token: `WHMCS\Security\Encryption::encode()`
```

---

## File: `.agent/rules/06-da-api.md`

```markdown
---
activation:
  glob: "**/Gateway/**"
---

# DirectAdmin API — Quy tắc khi code Gateway

## LUÔN dùng DAResponseParser
KHÔNG BAO GIỜ build DA API parameters thủ công. Luôn dùng:
- `DAResponseParser::buildDAParams()` để chuyển WHMCS format → DA format
- `DAResponseParser::parseRecord()` để chuyển DA format → WHMCS format
- `DAResponseParser::buildAressionParam()` để build tham số edit record

## 10 Gotchas bắt buộc (chi tiết: docs/API_REFERENCE.md Section A8)
1. Root domain name: WHMCS `"@"` ↔ DA `""` (empty string)
2. CNAME/MX/NS value: cần trailing dot `.` khi gửi lên DA
3. TXT value: cần escaped quotes khi gửi, strip quotes khi parse
4. SRV value: gộp `"weight port target."` vào 1 string
5. Edit record: tham số tên `arression` (KHÔNG phải `aression`)
6. DA error field: string `"1"` — kiểm tra `isset()` không phải `=== true`
7. CREATE_ZONE: chỉ ns1 + ns2, ns3 phải thêm bằng ADD_RECORD riêng
8. DELETE record not found → coi như success (idempotent)
9. CREATE_ZONE zone exists → coi như success (idempotent)
10. Let's Encrypt: response trả trước khi cert ready, cần đợi + verify

## Error Classification
- `timeout`, `rate_limit`, `server_error`, `network_error` → Retryable
- `auth_fail` → PERMANENTLY_FAILED + alert Admin
- `dns_conflict`, `zone_not_found` → FAILED non-retryable
- `zone_exists` (khi CREATE) → coi như success

## GuzzleHTTP Config
- Connect timeout: 15 giây
- Request timeout: 30 giây
- Luôn gửi `json=yes` để nhận JSON response
- Content-Type: `application/x-www-form-urlencoded` (DA không hỗ trợ JSON body)
- HTTP errors: `false` (không throw exception cho 4xx/5xx, tự handle)
```

---

## File: `.agent/rules/07-frontend.md`

```markdown
---
activation:
  glob:
    - "**/*.tpl"
    - "**/*.js"
    - "**/assets/**"
---

# Frontend Rules

## Tech Stack
- Template Engine: Smarty (WHMCS built-in)
- CSS: Native CSS (WHMCS) + Pure CSS (Không Bootstrap)
- JS Reactivity: Alpine.js 3.x (CDN + local fallback)
- DataTables: DataTables.net 1.13.x (CDN)
- Charts (Admin): Chart.js 4.x (CDN)
- KHÔNG dùng jQuery trừ khi WHMCS theme yêu cầu
- KHÔNG dùng Vue.js, React, hoặc bất kỳ framework nào cần build step

## Smarty Template Rules
- Escape MỌI dynamic data: `{$var|escape:'htmlall'}`
- Form PHẢI có CSRF token: `<input type="hidden" name="token" value="{$token}">`
- Tham chiếu WIREFRAME.md cho layout từng màn hình
- Client templates: `templates/client/` → WIREFRAME CL-01 đến CL-08
- Admin templates: `templates/admin/` → WIREFRAME AD-01 đến AD-12

## Alpine.js Rules
- Mọi API call qua `fetch()` với JSON (KHÔNG dùng jQuery Ajax)
- Error handling cho MỌI fetch call (try-catch)
- Loading state cho mọi action (spinner/disabled button)
- Sync Status Polling: 5 giây interval, tự dừng khi complete/failed

## Bảo mật Frontend
- KHÔNG hiển thị server IP, port, credentials cho Client
- Client chỉ thấy hostname (dns1.hvn.vn)
- Error messages thân thiện tiếng Việt, không technical details
- CSP header: `script-src 'self' cdnjs.cloudflare.com`
```

---

## File: `.agent/rules/08-testing.md`

```markdown
---
activation:
  glob: "**/tests/**"
---

# Testing Rules

## Cấu trúc Test
- `tests/Unit/` → Mock everything, test 1 class (target < 30s total)
- `tests/Integration/` → Real MySQL, mock DA API (target < 2 min)
- `tests/E2E/` → Real browser + DA Sandbox (target < 15 min)
- `tests/Security/` → Injection, XSS, auth bypass
- `tests/Performance/` → Response time, load test
- `tests/Fixtures/TestData.php` → Shared test data

## Naming Convention
- File: mirror cấu trúc `app/` — VD: `app/Services/QueueManager.php` → `tests/Unit/Services/QueueManagerTest.php`
- Method: `test_{what}_{scenario}_{expected}`
- VD: `test_valid_ipv4_accepted`, `test_dispatch_creates_jobs_for_all_active_servers`

## Pattern
- Arrange → Act → Assert (AAA)
- 1 assert per concept (có thể nhiều assert cùng 1 behavior)
- Luôn dùng `TestData` fixtures, KHÔNG hardcode giá trị trong test method

## Mock Rules
- Mock DA API: GuzzleHTTP MockHandler — KHÔNG gọi DA thật trong Unit/Integration
- Unit test: KHÔNG chạm database
- Integration test: dùng MySQL test database, cleanup after each test

## Coverage Target
- `Services/` ≥ 80%
- `Validators/` ≥ 90%
- `Gateway/` ≥ 80%
- `Controllers/` ≥ 60%

## Regression (PHẢI pass 100% trước deploy)
REG-001..005 Queue, REG-006..010 DNS, REG-011..015 Security,
REG-016..018 Provisioning, REG-019..020 Database
```

---

# PHẦN 2 — WORKFLOWS (Quy trình kích hoạt theo yêu cầu)

> Workflows là saved prompts — trigger bằng `/workflow-name` trong chat.
> Mỗi file `.md` trong `.agent/workflows/` là 1 workflow.

---

## File: `.agent/workflows/implement-issue.md`

```markdown
# Implement Issue

Quy trình implement 1 issue cụ thể từ EPICS.md.

## Input
User cung cấp Issue ID (VD: QUEUE-001, CLIENT-006, ADMIN-010)

## Steps

1. **Tìm Issue** trong `docs/EPICS.md`:
   - Đọc mô tả issue, Story Point
   - Đọc Acceptance Criteria (AC) của Story chứa issue đó
   - Xác định issue thuộc Phase nào — nếu không phải Phase hiện tại, CẢNH BÁO

2. **Tham chiếu tài liệu phù hợp**:
   - Database → đọc `docs/DB_SCHEMA.md` cho bảng liên quan
   - DA API → đọc `docs/API_REFERENCE.md` Phần A
   - Ajax endpoint → đọc `docs/API_REFERENCE.md` Phần B
   - UI/Template → đọc `docs/WIREFRAME.md`
   - Flow logic → đọc `docs/SPEC.md`

3. **Kiểm tra dependencies**:
   - Issue phụ thuộc issue nào khác?
   - Class/table/service cần thiết đã tồn tại chưa?
   - Nếu thiếu → liệt kê và hỏi có tạo dependency trước không

4. **Kiểm tra test plan**:
   - Tìm test cases liên quan trong `docs/TEST_PLAN.md`
   - Nếu có → viết test TRƯỚC code (TDD)

5. **Sinh code**:
   - Tuân thủ tất cả Rules đã định nghĩa
   - Code hoàn chỉnh, chạy được — KHÔNG sinh stub/placeholder
   - Bao gồm PHPDoc, type hints, error handling, logging

6. **Sinh test**:
   - Viết Unit Test cho logic mới
   - Dùng TestData fixtures, mock dependencies

7. **Xác nhận AC**:
   - Liệt kê từng AC của Story
   - Đánh dấu AC nào đã đáp ứng, AC nào chưa
   - Đề xuất bước tiếp theo nếu cần
```

---

## File: `.agent/workflows/implement-story.md`

```markdown
# Implement Story

Quy trình implement toàn bộ 1 Story (nhiều Issues).

## Input
User cung cấp Story ID (VD: Story 1.1, Story 2.1, Story 3.2)

## Steps

1. **Đọc Story** trong `docs/EPICS.md`:
   - Liệt kê TẤT CẢ Issues trong Story
   - Đọc Acceptance Criteria tổng thể

2. **Phân tích dependency**:
   - Sắp xếp Issues theo thứ tự phụ thuộc
   - Đề xuất thứ tự implement

3. **Implement từng Issue** theo thứ tự:
   - Dùng quy trình `/implement` cho mỗi issue
   - Sau mỗi issue, confirm với user trước khi tiếp

4. **Tổng kết Story**:
   - Liệt kê tất cả AC
   - Đánh dấu pass/fail cho từng AC
   - Liệt kê files đã tạo/sửa
   - Đề xuất test cần chạy
```

---

## File: `.agent/workflows/review-code.md`

```markdown
# Review Code

Review 1 file hoặc tập file, kiểm tra tuân thủ convention và phát hiện bug.

## Steps

1. **Đọc file** cần review

2. **Kiểm tra conventions** (theo Rules):
   - [ ] Namespace đúng cấu trúc thư mục?
   - [ ] PHPDoc đầy đủ cho public methods?
   - [ ] Type declarations cho params và return?
   - [ ] Naming convention (PascalCase class, camelCase method)?
   - [ ] Không có raw SQL?
   - [ ] Không gọi DA API trong Controller?
   - [ ] User input qua Sanitizer + Validator?
   - [ ] Response format đúng chuẩn JSON?
   - [ ] Logging đúng level, không log sensitive data?
   - [ ] CSRF token trong forms?
   - [ ] Smarty escape dynamic data?

3. **Kiểm tra bảo mật**:
   - [ ] Không leak server IP/credentials cho client?
   - [ ] Password encrypted?
   - [ ] Audit trail ghi đúng?
   - [ ] Không có eval/exec/shell_exec?

4. **Kiểm tra logic**:
   - [ ] Có xử lý error cases?
   - [ ] Có edge cases chưa handle?
   - [ ] Có race condition tiềm ẩn?
   - [ ] Performance OK? (N+1 query? missing index?)

5. **Output**:
   - Danh sách vấn đề tìm thấy (severity: Critical/Major/Minor/Cosmetic)
   - Đề xuất fix cho mỗi vấn đề
   - Điểm đánh giá tổng: ✅ Pass / ⚠️ Pass with notes / ❌ Fail
```

---

## File: `.agent/workflows/generate-tests.md`

```markdown
# Generate Tests

Sinh test cases cho 1 file hoặc 1 issue.

## Steps

1. **Xác định scope**:
   - User chỉ định file cụ thể HOẶC Issue ID
   - Nếu Issue ID → tìm test cases trong `docs/TEST_PLAN.md`

2. **Phân tích code** cần test:
   - Liệt kê tất cả public methods
   - Xác định: input types, output types, side effects, exceptions

3. **Sinh test file**:
   - Đặt đúng vị trí: `tests/Unit/` hoặc `tests/Integration/`
   - Naming: `{ClassName}Test.php`
   - Method naming: `test_{what}_{scenario}_{expected}`
   - Dùng TestData fixtures từ `tests/Fixtures/TestData.php`
   - Pattern: Arrange → Act → Assert

4. **Test categories** phải bao gồm:
   - Happy path (input hợp lệ → output đúng)
   - Validation errors (input sai → exception/error)
   - Edge cases (null, empty, max length, boundary values)
   - Error handling (DA timeout, DB fail)
   - Security (injection attempts, unauthorized access)

5. **Verify test chạy được**:
   - Suggest: `phpunit --filter {TestClassName}`
   - Check mock setup đúng
```

---

## File: `.agent/workflows/create-model.md`

```markdown
# Create Eloquent Model

Tạo 1 Eloquent Model mới theo chuẩn DB_SCHEMA.md.

## Input
User chỉ định tên bảng (VD: `mod_hvndns_servers`, hoặc tên ngắn `servers`)

## Steps

1. **Đọc schema** từ `docs/DB_SCHEMA.md`:
   - Tìm bảng tương ứng
   - Liệt kê tất cả cột, data types, constraints

2. **Tạo Model file** tại `app/Models/{ModelName}.php`:
   - `$table` = tên bảng đầy đủ
   - `$fillable` = TẤT CẢ cột có thể mass assign (trừ id, timestamps, encrypted fields)
   - `$casts` = mapping type (boolean, integer, array)
   - `$hidden` = fields nhạy cảm
   - Relationships dựa trên ERD
   - Scopes thường dùng

3. **Áp dụng quy tắc đặc biệt** (nếu có):
   - AuditTrail → Block update/delete
   - Server → Encrypt/decrypt password mutator
   - DdnsToken → Hash token methods
   - IpBlacklist → Active/expired scopes

4. **Output**: File Model hoàn chỉnh, sẵn sàng sử dụng
```

---

## File: `.agent/workflows/create-migration.md`

```markdown
# Create Database Migration

Tạo migration file cho phiên bản mới.

## Input
User chỉ định version (VD: v1_0_0) và mô tả thay đổi

## Steps

1. **Tạo file** tại `app/Migration/versions/{version}.php`

2. **Đọc DB_SCHEMA.md** cho bảng cần tạo/sửa

3. **Sinh migration code**:
   - Dùng `Illuminate\Database\Capsule\Manager as Capsule`
   - Kiểm tra `hasTable()` trước khi `create()` (idempotent)
   - Tạo indexes theo DB_SCHEMA.md
   - Foreign keys cho referential integrity
   - KHÔNG dùng `DROP TABLE` (chỉ add columns, add tables)

4. **Cập nhật** `schema_version` entry

5. **Verify** migration có thể chạy 2 lần không lỗi
```

---

## File: `.agent/workflows/create-controller.md`

```markdown
# Create Controller + Ajax Endpoint

Tạo Controller mới với Ajax endpoints.

## Steps

1. **Đọc API_REFERENCE.md Phần B** cho endpoints cần tạo

2. **Tạo Controller** tại `app/Controllers/{Name}Controller.php`:
   - Controller KHÔNG chứa business logic (chỉ gọi Service)
   - Mỗi action method: nhận params → gọi Service → trả ResponseHelper

3. **Tạo/cập nhật route** trong entry point

4. **Response format**: tuân thủ chuẩn JSON (success/error)

5. **Security**:
   - CSRF check cho POST
   - Permission check (client chỉ truy cập domain của mình)
   - Rate limit check nếu cần
   - Input sanitization

6. **Đọc WIREFRAME.md** nếu endpoint phục vụ UI cụ thể
```

---

## File: `.agent/workflows/create-template.md`

```markdown
# Create Smarty Template

Tạo template mới cho Client hoặc Admin Area.

## Input
User chỉ định màn hình (VD: CL-02, AD-01)

## Steps

1. **Đọc WIREFRAME.md** cho màn hình tương ứng

2. **Tạo file .tpl** tại `templates/client/` hoặc `templates/admin/`

3. **Quy tắc**:
   - CSS Grid / Flexbox (Pure CSS)
   - Escape dynamic data: `{$var|escape:'htmlall'}`
   - CSRF token trong forms
   - Alpine.js cho reactivity (x-data, x-show, x-on)
   - KHÔNG dùng inline JavaScript (tách ra file .js riêng)
   - Responsive: hoạt động trên mobile

4. **Tích hợp Alpine.js** component nếu cần:
   - Tạo file JS tại `assets/js/`
   - Polling, loading states, toast notifications

5. **KHÔNG hiển thị** server IP/credentials cho client templates
```

---

## File: `.agent/workflows/debug-fix.md`

```markdown
# Debug & Fix Bug

Quy trình tìm và sửa bug.

## Input
User mô tả bug (error message, behavior sai, screenshot)

## Steps

1. **Phân tích bug**:
   - Xác định component bị lỗi (Queue? Gateway? Validator? UI?)
   - Tìm file/function liên quan
   - Đọc error logs nếu có

2. **Tái hiện**:
   - Xác định input gây lỗi
   - Trace qua code flow (tham chiếu SPEC.md flow diagrams)

3. **Tìm root cause**:
   - Kiểm tra: input validation? logic error? DA API format? race condition?
   - Kiểm tra gotchas DA API (docs/API_REFERENCE.md A8)

4. **Fix**:
   - Sửa code tối thiểu (không refactor ngoài scope)
   - Giữ backward compatible
   - Thêm logging nếu bug khó detect

5. **Viết regression test**:
   - Test case tái hiện bug → pass sau khi fix
   - Thêm vào regression suite nếu critical

6. **Verify** fix không break tính năng khác
```

---

## File: `.agent/workflows/check-status.md`

```markdown
# Check Project Status

Tổng kết tiến độ dự án.

## Steps

1. **Scan workspace**: liệt kê files đã tạo trong `app/`, `templates/`, `tests/`

2. **Map với EPICS.md**:
   - Đối chiếu files → Issues
   - Đánh dấu: ✅ Done, 🔨 In Progress, ⬜ Not Started

3. **Output bảng tiến độ**:
   ```
   Phase 1 MVP:
   EPIC-01 Foundation:     ████████░░ 80% (4/5 stories)
   EPIC-02 Queue & Cron:   ██████░░░░ 60% (2/3 stories)
   EPIC-03 DNS Editor:     ████░░░░░░ 40% (1/3 stories)
   ...
   ```

4. **Liệt kê blockers** nếu có dependencies chưa hoàn thành

5. **Đề xuất** issue tiếp theo nên implement
```

---

## File: `.agent/workflows/release-check.md`

```markdown
# Pre-Release Checklist

Kiểm tra đầy đủ trước khi deploy (từ TEST_PLAN.md Section 14).

## Steps

1. **Code Quality**:
   - [ ] Tất cả Unit Tests pass
   - [ ] Tất cả Integration Tests pass
   - [ ] Code coverage ≥ 80% cho Services/ và Validators/
   - [ ] Không có TODO/FIXME trong code production
   - [ ] PHPDoc đầy đủ

2. **Security**:
   - [ ] Security Tests pass
   - [ ] DA password encrypted trong DB
   - [ ] Client responses không chứa server credentials
   - [ ] CSRF enforced trên POST endpoints
   - [ ] Audit trail ghi đúng

3. **Performance**:
   - [ ] Client add record < 200ms
   - [ ] Admin Dashboard < 2s
   - [ ] DDNS endpoint < 100ms
   - [ ] DB queries dùng đúng indexes

4. **Database**:
   - [ ] Migration chạy OK (fresh + upgrade)
   - [ ] Migration idempotent
   - [ ] Backup trước deploy

5. **Regression Suite**: 20 critical tests PHẢI pass 100%

6. **Output**: Checklist với ✅/❌ cho từng item
```

---

## File: `.agent/workflows/da-api-reference.md`

```markdown
# DA API Quick Reference

Tra cứu nhanh DirectAdmin API command.

## Steps

1. **User hỏi** về DA API command hoặc action cụ thể

2. **Đọc `docs/API_REFERENCE.md` Phần A** và trả lời:
   - Request format (URL, method, parameters)
   - Response format (success + error examples)
   - Gotchas liên quan
   - Error handling (retryable hay không)
   - Code example sử dụng DAGateway

3. **Nếu liên quan đến format mapping** (WHMCS ↔ DA):
   - Hiển thị bảng format differences
   - Chỉ ra DAResponseParser method cần dùng

4. **Nếu liên quan đến error handling**:
   - Hiển thị error classification table
   - Chỉ ra Worker nên handle thế nào
```

---

# PHẦN 3 — HƯỚNG DẪN CÀI ĐẶT

## Cài đặt Rules

```bash
# Tạo thư mục
mkdir -p modules/addons/hvn_dns_manager/.agent/rules

# Copy 8 file rules vào
# 01-project-context.md
# 02-architecture.md
# 03-code-style.md
# 04-database.md
# 05-security.md
# 06-da-api.md
# 07-frontend.md
# 08-testing.md
```

## Cài đặt Workflows

```bash
# Tạo thư mục
mkdir -p modules/addons/hvn_dns_manager/.agent/workflows

# Copy 12 file workflows vào
# implement-issue.md
# implement-story.md
# review-code.md
# generate-tests.md
# create-model.md
# create-migration.md
# create-controller.md
# create-template.md
# debug-fix.md
# check-status.md
# release-check.md
# da-api-reference.md
```

## Verify trong Antigravity

1. Mở workspace `modules/addons/hvn_dns_manager/` trong Antigravity
2. Click `...` → `Customizations`
3. Kiểm tra **Rules**: thấy 8 rules (4 Always On, 4 Glob-based)
4. Kiểm tra **Workflows**: thấy 12 workflows
5. Test: gõ `/implement` trong chat → thấy workflow suggestion
6. Test: gõ `/test` → thấy generate-tests workflow

## Sử dụng hàng ngày

```
# Implement 1 issue
/implement QUEUE-001

# Implement 1 story
/implement-story Story 2.1

# Review code
/review app/Services/QueueManager.php

# Sinh test
/test app/Services/QueueManager.php

# Tạo Model mới
/model servers

# Tạo migration
/migration v1_0_0

# Debug bug
/fix "Sync status hiện sai — luôn hiện Pending dù DA đã confirm"

# Kiểm tra tiến độ
/status

# Trước khi deploy
/release

# Tra cứu DA API
/da-api CMD_API_DNS_CONTROL edit
```

---

## Changelog
| Ngày | Thay đổi |
|------|----------|
| 25/02/2026 | Khởi tạo v1.0 — 8 Rules + 12 Workflows |
