# HVN - DirectAdmin DNS Manager
## Tài liệu Epics, User Stories & Issues

> **Phiên bản**: 1.0  
> **Ngày tạo**: 25/02/2026  
> **Dự án**: HVN - DirectAdmin DNS Manager  
> **Phương pháp**: Agile/Scrum — Chia theo 3 Phase  

---

## Quy ước ký hiệu

| Ký hiệu | Ý nghĩa |
|----------|----------|
| **EPIC** | Nhóm tính năng lớn, đại diện cho 1 mục tiêu kinh doanh/kỹ thuật cụ thể |
| **Story** | Một đơn vị công việc mô tả từ góc nhìn người dùng (User Story) hoặc kỹ thuật (Technical Story) |
| **Issue** | Tác vụ con cụ thể, có thể giao cho 1 developer, estimate được thời gian |
| **AC** | Acceptance Criteria — Tiêu chí nghiệm thu |
| 🟢 | Phase 1 — MVP |
| 🔵 | Phase 2 — Enterprise Core |
| 🟣 | Phase 3 — Add-on Values |

**Ước lượng Story Points**: 1 SP ≈ 0.5 ngày làm việc của 1 developer

---

# PHASE 1 — MVP 🟢
> **Mục tiêu**: Thay thế module v1.25, vận hành được với 1 DA Node, kiến trúc Queue bất đồng bộ hoạt động ổn định.  
> **Thời lượng ước tính**: 5–7 tuần

---

## EPIC-01: Nền tảng Hạ tầng Module (Foundation) 🟢
> *Xây dựng bộ khung kỹ thuật cốt lõi: cấu trúc thư mục, database schema, cơ chế cài đặt/nâng cấp tự động, và kết nối cơ bản tới DirectAdmin.*

### Story 1.1 — Khung Module WHMCS
**Là** một developer, **tôi cần** bộ khung module chuẩn WHMCS với cấu trúc thư mục, file cấu hình, hook đăng ký, **để** toàn bộ team có nền tảng code chung ngay từ đầu.

| Issue | Mô tả | SP |
|-------|--------|-----|
| `FOUND-001` | Tạo cấu trúc thư mục module chuẩn: `modules/addons/hvn_dns_manager/` với các thư mục con `controllers/`, `models/`, `views/`, `lib/`, `cron/`, `hooks/` | 1 |
| `FOUND-002` | Viết file `hvn_dns_manager.php` (entry point) với các hàm bắt buộc: `_config()`, `_activate()`, `_deactivate()`, `_upgrade()` | 2 |
| `FOUND-003` | Đăng ký hook `AfterModuleActivate` để chạy database migration tự động khi kích hoạt module | 1 |
| `FOUND-004` | Xây dựng hệ thống `version_tracking` (bảng `mod_hvndns_schema_version`) để quản lý migration schema qua các phiên bản | 2 |
| `FOUND-005` | Cấu hình Monolog Logger chuyên dụng cho module: channel `hvndns`, output ra WHMCS Activity Log + file rotate | 1 |

**AC**:
- Module xuất hiện trong Addons của WHMCS Admin sau khi activate
- Tất cả bảng DB được tạo tự động, không cần chạy SQL thủ công
- Logger ghi được log ở 3 level: `info`, `warning`, `error`
- Deactivate module không làm mất dữ liệu (chỉ disable, không drop table)

---

### Story 1.2 — Database Schema (Toàn bộ bảng cốt lõi)
**Là** một developer, **tôi cần** thiết kế và tạo đầy đủ các bảng CSDL cốt lõi, **để** các tính năng về sau có nền dữ liệu sẵn sàng.

| Issue | Mô tả | SP |
|-------|--------|-----|
| `FOUND-006` | Tạo bảng `mod_hvndns_servers` — Lưu thông tin kết nối các DA Node (hostname, IP, port, user, encrypted password, role, is_active, max_concurrent_jobs) | 2 |
| `FOUND-007` | Tạo bảng `mod_hvndns_domains` — Mapping domain ↔ WHMCS service_id ↔ server_id, trạng thái active/suspended | 2 |
| `FOUND-008` | Tạo bảng `mod_hvndns_records` — Bản ghi DNS local (domain_id, type, name, value, ttl, priority) làm source of truth | 2 |
| `FOUND-009` | Tạo bảng `mod_hvndns_queue` — Hàng đợi tác vụ (domain_id, server_id, action, payload JSON, status ENUM, attempts, scheduled_at, completed_at, error_message) | 3 |
| `FOUND-010` | Tạo bảng `mod_hvndns_sync_logs` — Lịch sử đồng bộ chi tiết (queue_id, server_id, http_code, response, duration_ms, ip_address) | 2 |
| `FOUND-011` | Tạo bảng `mod_hvndns_audit_trail` — Nhật ký kiểm toán không thể chỉnh sửa (actor_type, actor_id, domain, action, old_value, new_value, ip_address, user_agent) | 2 |
| `FOUND-012` | Viết Eloquent Model cho tất cả các bảng trên, kèm relationship (Domain hasMany Records, Queue belongsTo Server, v.v.) | 3 |
| `FOUND-013` | Tạo indexes tối ưu: composite index trên `queue(status, scheduled_at)`, index trên `records(domain_id, type)`, index trên `audit_trail(domain, created_at)` | 1 |

**AC**:
- Tất cả bảng sử dụng tiền tố `mod_hvndns_`
- Password DA server được mã hóa bằng `encrypt()` của WHMCS, không lưu plaintext
- Bảng `audit_trail` không có route UPDATE/DELETE từ application layer
- Migration có thể chạy lại (idempotent) mà không lỗi

---

### Story 1.3 — DA Gateway (Lớp giao tiếp DirectAdmin)
**Là** hệ thống, **tôi cần** một lớp kết nối API tới DirectAdmin dựa trên GuzzleHTTP, **để** mọi tương tác với DA đều đi qua 1 cổng duy nhất, kiểm soát được timeout, retry và logging.

| Issue | Mô tả | SP |
|-------|--------|-----|
| `FOUND-014` | Viết class `DAGateway` bọc GuzzleHTTP: constructor nhận server config, tự build base URL (https://ip:port), xử lý auth basic | 3 |
| `FOUND-015` | Implement các method cốt lõi: `getZone($domain)`, `addRecord(...)`, `editRecord(...)`, `deleteRecord(...)` mapping với API endpoint DA (`CMD_API_DNS_CONTROL`) | 3 |
| `FOUND-016` | Xử lý lỗi: bắt `ConnectException`, `RequestException`, `TimeoutException` → trả về object `DAResponse` thống nhất có `success`, `error_code`, `message`, `raw_response` | 2 |
| `FOUND-017` | Viết method `testConnection($serverId)` để Admin kiểm tra kết nối nhanh tới 1 DA Node | 1 |
| `FOUND-018` | Unit Test: mock GuzzleHTTP, test 5 scenarios (success, timeout, auth fail, DNS record conflict, server unreachable) | 2 |

**AC**:
- Không có bất kỳ lệnh `curl_init()` hay `HTTPSocket` nào trong toàn bộ codebase
- Timeout mặc định 15 giây, configurable qua Admin Settings
- Mọi request/response được log qua Monolog ở level `debug`
- `testConnection` trả kết quả trong < 5 giây

---

## EPIC-02: Hệ thống Queue & Cron Worker 🟢
> *Trái tim của kiến trúc bất đồng bộ: nhận job từ DB, xử lý tuần tự, ghi log, tự xử lý lỗi cơ bản.*

### Story 2.1 — Queue Manager (Quản lý hàng đợi)
**Là** hệ thống, **tôi cần** một Queue Manager chịu trách nhiệm tạo job, cập nhật trạng thái, và cung cấp interface cho các controller gọi tới, **để** mọi thay đổi DNS đều đi qua hàng đợi thay vì gọi API trực tiếp.

| Issue | Mô tả | SP |
|-------|--------|-----|
| `QUEUE-001` | Viết class `QueueManager` với method `dispatch($domainId, $action, $payload)`: validate input → tạo 1 row `PENDING` trong `mod_hvndns_queue` → return `job_id` | 2 |
| `QUEUE-002` | Implement logic **Fan-out**: khi dispatch, tự query tất cả server `is_active = 1` → tạo N sub-jobs (1 job/server) cùng `batch_id` | 3 |
| `QUEUE-003` | Method `getStatus($batchId)`: trả về aggregate status (all_complete / partial / all_failed / pending) dựa trên trạng thái các sub-jobs cùng batch | 2 |
| `QUEUE-004` | Method `cancelPending($batchId)`: hủy các job chưa xử lý (dùng cho Conflict Resolution khi Admin ghi đè) | 1 |
| `QUEUE-005` | Xử lý deduplication: nếu cùng 1 domain + cùng 1 record + cùng action đang có job `PENDING`, replace job cũ thay vì tạo thêm job mới | 2 |

**AC**:
- Mỗi lần dispatch tạo đúng N job = số server active
- Tất cả sub-jobs cùng batch có chung `batch_id` (UUID)
- `dispatch()` hoàn thành trong < 50ms (chỉ write DB, không gọi API)
- Deduplication không ảnh hưởng đến job đang `SYNCING`

---

### Story 2.2 — Cron Worker (Xử lý nền)
**Là** hệ thống, **tôi cần** một Cron Worker chạy định kỳ 1-3 phút, tự quét job PENDING và thực thi qua DA Gateway, **để** DNS được cập nhật tự động mà không cần user chờ đợi.

| Issue | Mô tả | SP |
|-------|--------|-----|
| `QUEUE-006` | Viết file `cron/queue_worker.php` đăng ký qua WHMCS Cron hook, chạy mỗi phút | 2 |
| `QUEUE-007` | Logic chính: query `WHERE status = 'PENDING' AND scheduled_at <= NOW()` → sắp xếp theo `created_at ASC` → xử lý tuần tự theo server (tránh đẩy dồn 1 server) | 3 |
| `QUEUE-008` | Implement job lifecycle: `PENDING` → set `SYNCING` + lock row → gọi `DAGateway` → thành công set `COMPLETE` / thất bại set `FAILED` + ghi `error_message` | 3 |
| `QUEUE-009` | Cơ chế **Stale Job Recovery**: nếu job ở `SYNCING` quá 5 phút (cron crash giữa chừng) → tự chuyển về `FAILED` với message "Worker timeout — stale job recovered" | 2 |
| `QUEUE-010` | Giới hạn `max_concurrent_jobs` per server: không xử lý quá N job/lần cho cùng 1 DA Node (lấy từ config `mod_hvndns_servers`) | 1 |
| `QUEUE-011` | Ghi `mod_hvndns_sync_logs` sau mỗi job: HTTP status code, response body, thời gian xử lý (ms), server_id | 2 |

**AC**:
- Worker không crash nếu 1 job lỗi — tiếp tục xử lý job tiếp theo
- Không có 2 worker instance xử lý cùng 1 job (row-level locking)
- Log ghi đầy đủ cho mỗi job dù thành công hay thất bại
- Worker tự thoát nếu chạy quá 55 giây (tránh overlap cron tiếp theo)

---

### Story 2.3 — Auto-healing & Exponential Backoff
**Là** sysadmin, **tôi cần** hệ thống tự động giãn thời gian retry khi DA Node gặp sự cố, **để** tránh DDoS nội bộ vào server đang quá tải và tự phục hồi khi server online lại.

| Issue | Mô tả | SP |
|-------|--------|-----|
| `QUEUE-012` | Implement Exponential Backoff: lần 1 retry sau 2 phút, lần 2 sau 4 phút, lần 3 sau 8 phút, lần 4 sau 16 phút, lần 5 đánh dấu `PERMANENTLY_FAILED` | 2 |
| `QUEUE-013` | Backoff áp dụng **per-server**: server A đang backoff không ảnh hưởng xử lý job của server B và C | 2 |
| `QUEUE-014` | Thêm cột `attempts` và `next_retry_at` vào bảng queue. Worker chỉ pick job khi `next_retry_at <= NOW()` | 1 |
| `QUEUE-015` | Khi server chuyển từ FAILED → COMPLETE (tức phục hồi), reset backoff counter về 0 cho server đó | 1 |

**AC**:
- Sau 5 lần fail liên tiếp, job dừng retry và cần Admin can thiệp
- Thời gian backoff được ghi rõ trong sync_logs
- Server khỏe mạnh không bị ảnh hưởng bởi server đang lỗi

---

## EPIC-03: DNS Editor — Giao diện Khách hàng 🟢
> *Giao diện chính để khách hàng quản lý bản ghi DNS với trải nghiệm tức thời (Zero Latency).*

### Story 3.1 — Trang quản lý DNS chính (Client Area)
**Là** khách hàng, **tôi muốn** xem và quản lý tất cả bản ghi DNS của domain mình trên một giao diện trực quan, **để** tôi không cần truy cập DirectAdmin hay liên hệ support.

| Issue | Mô tả | SP |
|-------|--------|-----|
| `CLIENT-001` | Tạo Client Area page (`clientarea.tpl`) hiển thị bảng DNS records của domain đang chọn: cột Name, Type, Value, TTL, Status, Actions | 3 |
| `CLIENT-002` | DataTable hỗ trợ filter theo Type (A, AAAA, CNAME, MX, TXT, SRV, NS, CAA), search theo Name/Value | 2 |
| `CLIENT-003` | Mỗi record hiển thị **Sync Status Badge**: 🟢 `Live` / 🔄 `Syncing (2/3)` / 🟡 `Pending` / 🔴 `Failed` — dựa trên aggregate status của batch | 2 |
| `CLIENT-004` | Tích hợp Alpine.js cho reactive UI: khi status thay đổi (poll Ajax mỗi 5 giây), badge tự cập nhật không cần reload trang | 3 |
| `CLIENT-005` | Responsive layout: hoạt động tốt trên mobile (Bootstrap 5 grid collapse) | 1 |

**AC**:
- Trang load xong trong < 1 giây cho domain có 50 records
- Badge status chính xác phản ánh trạng thái thực tế trên queue
- Không hiển thị thông tin nhạy cảm (server IP, password) cho client
- Giao diện hòa hợp với theme WHMCS Six/Twenty-One

---

### Story 3.2 — CRUD Bản ghi DNS (Zero Latency)
**Là** khách hàng, **tôi muốn** thêm, sửa, xóa bản ghi DNS và nhận phản hồi thành công ngay lập tức (< 0.2s), **để** tôi không phải chờ đợi API DirectAdmin phản hồi.

| Issue | Mô tả | SP |
|-------|--------|-----|
| `CLIENT-006` | Form **Thêm Record**: modal popup với các trường Name, Type (dropdown), Value, TTL (mặc định 3600), Priority (hiện khi MX/SRV). Submit qua Ajax | 3 |
| `CLIENT-007` | **Validation phía server** trước khi lưu queue: kiểm tra format IP (cho A/AAAA), FQDN (cho CNAME/MX/NS), syntax TXT/SPF, giá trị Priority hợp lệ, SRV format (priority weight port target) | 3 |
| `CLIENT-008` | **Validation chống xung đột**: không cho tạo CNAME trùng name với record A đã có (vi phạm RFC), cảnh báo duplicate MX cùng priority | 2 |
| `CLIENT-009` | Luồng lưu: Validate OK → Lưu `mod_hvndns_records` → Gọi `QueueManager::dispatch('ADD', $payload)` → Trả JSON success cho UI → UI hiển thị record mới với badge `Pending` | 2 |
| `CLIENT-010` | Form **Sửa Record**: pre-fill giá trị hiện tại, submit tạo job `EDIT`. Ghi audit trail (old_value → new_value) | 2 |
| `CLIENT-011` | Nút **Xóa Record**: confirm dialog → tạo job `DELETE` → UI ẩn record hoặc hiển thị trạng thái "Deleting..." | 2 |
| `CLIENT-012` | **Rate Limiting client**: tối đa 30 thay đổi/phút/domain. Vượt quá → trả lỗi 429 kèm thông báo thân thiện | 1 |

**AC**:
- Từ lúc nhấn Save đến UI phản hồi ≤ 200ms
- Không có trường hợp nào record được lưu vào queue mà không qua validation
- Mọi thay đổi đều tạo dòng trong `audit_trail`
- Xóa record không xóa khỏi DB ngay mà đánh dấu `pending_delete`, chỉ xóa thật sau khi DA confirm

---

### Story 3.3 — Sync Tracker (Theo dõi đồng bộ real-time)
**Là** khách hàng, **tôi muốn** biết chính xác bản ghi nào đã được đẩy lên server thành công, bản ghi nào đang chờ, **để** tôi yên tâm rằng thay đổi đang được xử lý.

| Issue | Mô tả | SP |
|-------|--------|-----|
| `CLIENT-013` | API endpoint `/ajax/sync-status?domain_id=X` trả về danh sách record kèm aggregate status mới nhất | 2 |
| `CLIENT-014` | Alpine.js component `SyncTracker`: poll endpoint mỗi 5 giây, cập nhật badge tương ứng. Khi tất cả job COMPLETE → dừng poll | 2 |
| `CLIENT-015` | Hiển thị chi tiết khi hover/click badge: "Synced to 2/3 servers — dns3.hvn.vn: retrying in 4 min" (chỉ hiện tên server, không hiện IP) | 2 |
| `CLIENT-016` | Toast notification khi record chuyển từ Pending/Syncing → Live: "✅ Record A mail.domain.com đã hoạt động trên tất cả server" | 1 |

**AC**:
- Polling tự dừng khi không có job pending (tiết kiệm request)
- Thông tin server hiển thị cho client chỉ gồm hostname, không có IP/port/password
- Trạng thái cập nhật mượt (no page flicker)

---

## EPIC-04: Admin Dashboard & Quản trị cơ bản 🟢
> *Giao diện Admin tối thiểu để cấu hình server, xem log, và quản lý domain.*

### Story 4.1 — Cấu hình Server DirectAdmin
**Là** admin, **tôi muốn** thêm/sửa/xóa các DA Server Node trong giao diện WHMCS, **để** module biết kết nối tới đâu khi đồng bộ DNS.

| Issue | Mô tả | SP |
|-------|--------|-----|
| `ADMIN-001` | Trang danh sách Server: bảng hiển thị tất cả server trong `mod_hvndns_servers` với cột Hostname, IP, Role, Status (🟢/🔴), Pending Jobs | 2 |
| `ADMIN-002` | Form Thêm/Sửa Server: hostname, IP, port, username, password (masked input), SSL toggle, role (Primary/Secondary), max_concurrent_jobs | 2 |
| `ADMIN-003` | Nút **Test Connection**: gọi `DAGateway::testConnection()` → hiển thị kết quả realtime (success + phiên bản DA / fail + error message) | 1 |
| `ADMIN-004` | Nút **Disable/Enable Server**: tắt server khỏi fan-out mà không xóa config (dùng khi bảo trì) | 1 |
| `ADMIN-005` | Validation: không cho xóa server nếu còn job PENDING/SYNCING. Phải disable và xử lý hết job trước | 1 |

**AC**:
- Password được mã hóa trước khi lưu DB, form Edit hiển thị `••••••••`
- Test Connection timeout sau 10 giây với thông báo rõ ràng
- Disable server → các job mới không fan-out tới server đó, job cũ đang pending chuyển thành CANCELLED

---

### Story 4.2 — Quản lý Domain toàn cục
**Là** admin, **tôi muốn** xem danh sách tất cả domain đang sử dụng dịch vụ DNS, và truy cập nhanh vào DNS Editor của bất kỳ domain nào, **để** hỗ trợ khách hàng mà không cần login as client.

| Issue | Mô tả | SP |
|-------|--------|-----|
| `ADMIN-006` | Trang Global Domains: DataTable với cột Domain, Client Name, Server Node, Total Records, Last Sync, Status | 2 |
| `ADMIN-007` | Search/Filter: tìm theo domain name, client ID, server, status (active/suspended) | 1 |
| `ADMIN-008` | Click domain → mở **DNS Editor giống Client** nhưng với quyền Admin (không bị rate limit, có thể override conflict) | 2 |
| `ADMIN-009` | Badge hiển thị nếu domain đang có job FAILED chưa được xử lý | 1 |

**AC**:
- Trang load < 2 giây cho 500+ domains (server-side pagination)
- Admin thao tác trên DNS Editor tạo audit trail với `actor_type = 'admin'`

---

### Story 4.3 — Sync Logs & One-Click Retry
**Là** admin, **tôi muốn** xem toàn bộ lịch sử đồng bộ và retry nhanh các job lỗi, **để** xử lý sự cố mà không cần SSH vào server.

| Issue | Mô tả | SP |
|-------|--------|-----|
| `ADMIN-010` | Trang Sync Logs: DataTable hiển thị `mod_hvndns_sync_logs` join `queue` — cột: Time, Domain, Action, Server, Status, Duration, Error | 3 |
| `ADMIN-011` | Filter nâng cao: theo status (COMPLETE/FAILED), theo server, theo khoảng thời gian, theo domain | 1 |
| `ADMIN-012` | Nút **Retry** trên từng job FAILED: set lại status = PENDING, reset attempts = 0 | 1 |
| `ADMIN-013` | Nút **Retry All Failed**: bulk update tất cả job FAILED → PENDING (có confirm dialog cảnh báo số lượng) | 1 |
| `ADMIN-014` | Export Logs: xuất CSV/Excel cho audit compliance | 2 |

**AC**:
- DataTable hỗ trợ 10,000+ rows với server-side processing
- Retry không tạo job mới mà reuse job cũ (giữ nguyên lịch sử attempts)
- Export bao gồm tất cả cột + raw response từ DA

---

### Story 4.4 — Admin Settings Page
**Là** admin, **tôi muốn** cấu hình toàn bộ module qua giao diện trực quan với các tab phân nhóm,
**để** không cần sửa code hay DB khi thay đổi chính sách.

| Issue | Mô tả | SP |
|-------|--------|-----|
| `ADMIN-015` | Tạo bảng `mod_hvndns_settings` + SettingsHelper class (get/set/getBool/getInt) | 2 |
| `ADMIN-016` | Tạo trang Admin Settings với tab navigation (16 tabs) — render form từ settings config | 3 |
| `ADMIN-017` | Ajax save settings + validation (NS không trống, TTL range, hash key min length...) | 2 |
| `ADMIN-018` | Implement Record Permissions logic: filter allowed types trong DNS Editor dropdown + server-side enforce | 2 |
| `ADMIN-019` | Implement Record Limits per-type: kiểm tra trước khi dispatch, kết hợp 3 lớp (Global → Quota Plan → Override) | 2 |
| `ADMIN-020` | Implement Domain Policy: NS check logic (`disable_manage_wrong_ns`), pre-registrar hook, on-transfer hook | 3 |
| `ADMIN-021` | Implement Client Notification: gửi email qua WHMCS mail system sau khi sync complete | 2 |
| `ADMIN-022` | Implement Cache Strategy: `fetch_from_ns_on_load` + background refresh + `cache_refresh_ttl` | 2 |
| `ADMIN-023` | Implement UI/Navigation hooks: `ClientAreaPrimaryNavbar`, sidebar link, domain service link, menu order | 1 |
| `ADMIN-024` | Seed default settings values khi module activate lần đầu (96 settings với defaults từ SETTINGS.md) | 1 |

**AC**:
- Tất cả 96 settings có thể xem và sửa qua giao diện Admin
- Settings lưu vào `mod_hvndns_settings`, đọc qua SettingsHelper
- Validation chặn giá trị không hợp lệ trước khi lưu
- Record Permissions ẩn record type bị tắt khỏi dropdown Client + chặn server-side
- Record Limits enforce đúng thứ tự ưu tiên 3 lớp
- NS check chặn Client sửa DNS khi NS chưa trỏ đúng
- Client notification chỉ gửi sau sync complete (không gửi khi lưu queue)
- Cache strategy hoạt động đúng theo setting
- Menu items hiển thị/ẩn + đúng thứ tự theo settings

---

## EPIC-05: Provisioning tự động (WHMCS Product Lifecycle) 🟢
> *Tự động tạo/xóa zone DNS khi khách hàng mua/hủy dịch vụ trên WHMCS.*

### Story 5.1 — Auto-provision Zone khi mua dịch vụ
**Là** khách hàng, **khi** tôi mua gói dịch vụ DNS trên WHMCS và thanh toán thành công, **tôi mong** zone DNS được tạo sẵn trên tất cả server với template mặc định, **để** tôi chỉ cần vào chỉnh sửa mà không phải chờ support tạo thủ công.

| Issue | Mô tả | SP |
|-------|--------|-----|
| `PROV-001` | Hook `AfterModuleCreate`: tạo row trong `mod_hvndns_domains`, dispatch job `CREATE_ZONE` fan-out ra tất cả active server | 2 |
| `PROV-002` | Áp DNS Template mặc định: lấy template từ `mod_hvndns_templates` → tạo các record chuẩn (NS records trỏ dns1/2/3, SOA, default A record) | 2 |
| `PROV-003` | Hook `AfterModuleTerminate`: dispatch job `DELETE_ZONE` → xóa zone trên tất cả DA Node → soft-delete domain trong DB (giữ lại 30 ngày cho rollback) | 2 |
| `PROV-004` | Hook `AfterModuleSuspend` / `AfterModuleUnsuspend`: đánh dấu domain suspended → Client không thể chỉnh sửa DNS nhưng zone vẫn hoạt động trên server | 1 |

**AC**:
- Từ lúc thanh toán đến zone xuất hiện trên DA: ≤ 3 phút (1 chu kỳ cron)
- Template mặc định có thể cấu hình bởi Admin
- Terminate không xóa vĩnh viễn ngay, có grace period 30 ngày

---

# PHASE 2 — ENTERPRISE CORE 🔵
> **Mục tiêu**: Multi-server hoàn chỉnh, Dashboard metrics, URL Forwarding, Conflict Resolution, Webhook cảnh báo.  
> **Thời lượng ước tính**: 4–6 tuần  
> **Điều kiện bắt đầu**: Phase 1 đã deploy stable ≥ 2 tuần trên production

---

## EPIC-06: Dashboard & Metrics toàn diện 🔵
> *Bảng điều khiển trung tâm cho Admin với số liệu real-time về sức khỏe hệ thống.*

### Story 6.1 — Admin Dashboard chính
**Là** admin, **tôi muốn** mở module và thấy ngay tổng quan tình trạng hệ thống bằng các con số và biểu đồ, **để** phát hiện sự cố sớm mà không cần đào sâu vào logs.

| Issue | Mô tả | SP |
|-------|--------|-----|
| `DASH-001` | Widget **Sync Pipeline 24h**: 3 ô số lớn hiển thị Pending / Complete / Failed kèm biểu đồ mini sparkline | 3 |
| `DASH-002` | Widget **Server Health**: danh sách server với % uptime (tính từ sync_logs success/total), response time trung bình, icon trạng thái | 2 |
| `DASH-003` | Widget **Tổng quan**: tổng domain quản lý, tổng records, top 5 domain thay đổi nhiều nhất trong 7 ngày | 2 |
| `DASH-004` | **Alert Banner đỏ**: tự hiện khi phát hiện FAILED rate > 20% trong 1 giờ qua hoặc bất kỳ server nào unreachable 3 lần liên tiếp | 2 |
| `DASH-005` | Auto-refresh dashboard mỗi 30 giây bằng Ajax (không full reload) | 1 |

**AC**:
- Dashboard load xong trong < 2 giây
- Dữ liệu metrics tính từ aggregate query, không scan toàn bộ bảng mỗi lần
- Alert banner hiển thị cả trên các trang admin khác của module (persistent alert)

---

## EPIC-07: URL Forwarding & Auto-SSL 🔵
> *Cho phép khách hàng tạo redirect 301/302 và masked redirect, tự động phát hành SSL cho domain.*

### Story 7.1 — Standard Redirect (301/302)
**Là** khách hàng, **tôi muốn** tạo chuyển hướng URL từ domain của tôi tới một địa chỉ khác, **để** khi ai đó truy cập domain cũ sẽ được chuyển tới trang mới tự động.

| Issue | Mô tả | SP |
|-------|--------|-----|
| `REDIR-001` | Tab "Redirects" trong DNS Editor: bảng hiển thị các redirect hiện có (Source Path, Destination URL, Type 301/302, Status) | 2 |
| `REDIR-002` | Form tạo redirect: Source Path (default `/`), Destination URL (validate format), Type (301 Permanent / 302 Temporary) | 2 |
| `REDIR-003` | Queue job `CREATE_REDIRECT`: tạo cấu hình .htaccess hoặc Apache redirect rule trên DA qua API | 3 |
| `REDIR-004` | Sửa / Xóa redirect: tương tự CRUD record, đi qua queue | 2 |

**AC**:
- Redirect hoạt động trong < 3 phút sau khi tạo
- Validate destination URL phải là URL hợp lệ (http/https)
- Không cho redirect vòng tròn (A → B → A)

---

### Story 7.2 — Masked Redirect
**Là** khách hàng, **tôi muốn** tạo chuyển hướng mà thanh địa chỉ trình duyệt vẫn hiển thị domain của tôi (URL masking), **để** người truy cập không biết nội dung đến từ nơi khác.

| Issue | Mô tả | SP |
|-------|--------|-----|
| `REDIR-005` | Implement Masked Redirect: tạo VirtualHost trên DA với reverse proxy hoặc iframe connector | 5 |
| `REDIR-006` | Hash-based security: URL đích được mã hóa trong config, không expose trực tiếp trong HTML source | 2 |
| `REDIR-007` | Tùy chọn SEO: cho phép set custom Title, Meta Description cho trang masked | 1 |

**AC**:
- Masked page load < 2 giây
- View Source không lộ destination URL gốc (nếu dùng reverse proxy)
- Hoạt động với cả HTTP và HTTPS destination

---

### Story 7.3 — Auto-SSL (Let's Encrypt Integration)
**Là** khách hàng, **tôi muốn** domain sử dụng DNS service được tự động cấp chứng chỉ SSL miễn phí, **để** trình duyệt không cảnh báo "Not Secure" khi dùng HTTPS redirect.

| Issue | Mô tả | SP |
|-------|--------|-----|
| `SSL-001` | Queue job `REQUEST_SSL`: gọi DA API để trigger Let's Encrypt certificate issuance cho domain | 3 |
| `SSL-002` | Tracking trạng thái SSL: cột `ssl_status` trong `mod_hvndns_domains` (none/pending/active/expired) | 1 |
| `SSL-003` | Auto-renewal hook: cronjob kiểm tra cert sắp hết hạn (< 7 ngày) → tự dispatch job gia hạn | 2 |
| `SSL-004` | UI hiển thị trạng thái SSL: icon khóa xanh + ngày hết hạn trong Client Area | 1 |

**AC**:
- SSL được cấp trong < 10 phút sau khi DNS đã propagate
- Auto-renewal chạy ngầm, khách hàng không cần thao tác
- Nếu cấp SSL thất bại, ghi rõ lý do trong sync_logs (DNS chưa trỏ đúng, rate limit Let's Encrypt, v.v.)

---

## EPIC-08: Conflict Resolution & Webhook 🔵
> *Xử lý xung đột khi nhiều người cùng sửa, và thông báo cảnh báo tự động cho SysAdmin.*

### Story 8.1 — Conflict Resolution (Admin-Priority)
**Là** hệ thống, **tôi cần** phát hiện và xử lý xung đột khi Admin và Client cùng sửa 1 record trong thời gian ngắn, **để** không có 2 job mâu thuẫn chạy đồng thời.

| Issue | Mô tả | SP |
|-------|--------|-----|
| `CONF-001` | Detect conflict: khi tạo job mới, kiểm tra xem cùng record có job `PENDING` chưa xử lý trong 3 phút không | 2 |
| `CONF-002` | Admin-Priority: nếu job mới từ Admin và job cũ từ Client → cancel job Client, giữ job Admin. Ghi audit trail "Overridden by Admin" | 2 |
| `CONF-003` | Client-Client conflict (cùng account, 2 tab): áp dụng **Optimistic Locking** — kiểm tra `updated_at` trước khi lưu, nếu record đã bị sửa → trả lỗi "Record đã được cập nhật, vui lòng tải lại trang" | 2 |
| `CONF-004` | Admin-Admin conflict: hiển thị warning "Admin [name] vừa sửa record này [X] giây trước. Ghi đè?" với nút xác nhận | 2 |

**AC**:
- Không bao giờ có 2 job PENDING conflict cho cùng 1 record + cùng action
- Client nhận thông báo rõ ràng khi bị override, không mất dữ liệu âm thầm
- Audit trail ghi đầy đủ cả 2 phía (ai tạo, ai bị cancel)

---

### Story 8.2 — Webhook Notifications
**Là** sysadmin, **tôi muốn** nhận cảnh báo tức thì qua Telegram/Email khi hệ thống gặp sự cố, **để** ứng cứu kịp thời mà không cần ngồi theo dõi dashboard 24/7.

| Issue | Mô tả | SP |
|-------|--------|-----|
| `NOTIF-001` | Admin Settings: cấu hình Telegram Bot Token + Chat ID, Email nhận cảnh báo (nhiều email, phân tách bằng dấu phẩy) | 2 |
| `NOTIF-002` | Trigger rule: ≥ 5 job FAILED liên tiếp trên cùng 1 server → gửi alert | 2 |
| `NOTIF-003` | Trigger rule: server unreachable ≥ 3 lần liên tiếp → gửi alert "Server [hostname] mất kết nối" | 1 |
| `NOTIF-004` | Trigger rule: queue backlog > 100 jobs pending > 10 phút → gửi alert "Queue đang tắc nghẽn" | 1 |
| `NOTIF-005` | Nút **Test Notification**: gửi tin nhắn test để verify cấu hình đúng | 1 |
| `NOTIF-006` | Cooldown: không gửi cùng 1 loại alert quá 1 lần / 15 phút (chống spam) | 1 |

**AC**:
- Telegram message gửi đi trong < 5 giây sau khi trigger
- Alert có đủ context: server nào, bao nhiêu job lỗi, lỗi gì, link vào dashboard
- Cooldown hoạt động đúng — không spam admin khi server down kéo dài

---

# PHASE 3 — ADD-ON VALUES 🟣
> **Mục tiêu**: Hoàn thiện tất cả tính năng cao cấp: DDNS, DNSSEC, Drift Check, Quota, Audit Trail UI, Rollback.  
> **Thời lượng ước tính**: 4–5 tuần  
> **Điều kiện bắt đầu**: Phase 2 stable ≥ 2 tuần

---

## EPIC-09: DDNS API cho thiết bị IoT 🟣
> *Cung cấp endpoint DDNS để router/camera tự cập nhật IP khi thay đổi.*

### Story 9.1 — DDNS Endpoint & Token Management
**Là** khách hàng sử dụng IP động, **tôi muốn** được cấp một URL DDNS để cấu hình vào router Mikrotik/DrayTek, **để** khi IP thay đổi, bản ghi DNS tự động cập nhật mà không cần vào WHMCS chỉnh tay.

| Issue | Mô tả | SP |
|-------|--------|-----|
| `DDNS-001` | Tạo bảng `mod_hvndns_ddns_tokens` (domain_id, subdomain, token SHA256, last_ip, last_update, is_active) | 1 |
| `DDNS-002` | Client UI: nút "Tạo DDNS Token" cho 1 subdomain → sinh token ngẫu nhiên → hiển thị URL dạng `https://whmcs.hvn.vn/modules/addons/hvn_dns_manager/ddns.php?token=xxx` | 2 |
| `DDNS-003` | Endpoint `ddns.php`: nhận GET request → validate token → lấy IP từ `$_SERVER['REMOTE_ADDR']` → so sánh với `last_ip` → nếu khác thì dispatch job `EDIT` A record qua Queue | 3 |
| `DDNS-004` | Response chuẩn: trả `good [new_ip]` hoặc `nochg [current_ip]` (tương thích format DynDNS chuẩn để router hiểu) | 1 |
| `DDNS-005` | Client UI hiển thị: URL endpoint, hướng dẫn cấu hình cho Mikrotik (`/tool fetch`), DrayTek (DDNS settings), và router phổ thông | 2 |

**AC**:
- Endpoint phản hồi trong < 100ms
- Chỉ cập nhật khi IP thực sự thay đổi (tránh spam queue)
- Token có thể revoke/regenerate bất kỳ lúc nào

---

### Story 9.2 — Anti-Brute Force cho DDNS
**Là** hệ thống, **tôi cần** chống lạm dụng DDNS endpoint để bảo vệ queue khỏi bị flood, **và** block IP tấn công tự động.

| Issue | Mô tả | SP |
|-------|--------|-----|
| `DDNS-006` | Rate limit: tối đa 60 request/giờ per token. Vượt quá → trả HTTP 429 + ghi log | 1 |
| `DDNS-007` | Brute force detection: ≥ 10 request với token sai từ cùng 1 IP trong 5 phút → block IP 1 giờ | 2 |
| `DDNS-008` | Bảng `mod_hvndns_ip_blacklist` lưu IP bị block + thời gian hết hạn block | 1 |
| `DDNS-009` | Admin UI: xem danh sách IP đang bị block, nút unblock thủ công | 1 |

**AC**:
- IP bị block nhận HTTP 403 ngay tại entry point, không tốn resource xử lý
- Auto-unblock sau thời gian hết hạn
- Legitimate token vẫn hoạt động bình thường dưới rate limit

---

## EPIC-10: DNSSEC Management 🟣
> *Cho phép khách hàng bật/tắt DNSSEC và xem DS Records để cấu hình tại nhà đăng ký.*

### Story 10.1 — Enable/Disable DNSSEC
**Là** khách hàng quan tâm đến bảo mật DNS, **tôi muốn** bật DNSSEC cho domain từ giao diện WHMCS và nhận được thông số DS Record, **để** mang đi cấu hình tại nhà đăng ký tên miền mà không cần nhờ support.

| Issue | Mô tả | SP |
|-------|--------|-----|
| `DNSSEC-001` | Tab "DNSSEC" trong DNS Editor: hiển thị trạng thái hiện tại (Enabled/Disabled), nút Toggle | 2 |
| `DNSSEC-002` | Toggle Enable: dispatch job `ENABLE_DNSSEC` vào queue → Cron gọi DA API enable DNSSEC → DA generate keys | 3 |
| `DNSSEC-003` | Sau khi enable thành công: Cron gọi DA API lấy DS Record info → lưu vào `mod_hvndns_dnssec` (domain_id, key_tag, algorithm, digest_type, digest) | 2 |
| `DNSSEC-004` | Client UI hiển thị bảng DS Records: Key Tag, Algorithm, Digest Type, Digest — kèm nút Copy và hướng dẫn "Mang thông tin này đến nhà đăng ký tên miền để hoàn tất cấu hình DNSSEC" | 2 |
| `DNSSEC-005` | Toggle Disable: dispatch job `DISABLE_DNSSEC` → xóa keys trên DA → cảnh báo "Hãy xóa DS Record tại nhà đăng ký trước khi tắt, nếu không domain sẽ bị lỗi phân giải" | 2 |
| `DNSSEC-006` | Auto re-sign: sau mỗi lần Cron sync thành công 1 batch thay đổi record, tự dispatch thêm job `RESIGN_ZONE` để ký lại zone | 2 |

**AC**:
- DS Record hiển thị chính xác khớp với output từ DA
- Cảnh báo rõ ràng về thứ tự thao tác (enable DA trước, add DS tại registrar sau / xóa DS tại registrar trước, disable DA sau)
- Re-sign tự động không cần user can thiệp

---

## EPIC-11: Data Integrity & Rollback 🟣
> *Đảm bảo dữ liệu DNS trên WHMCS và DirectAdmin luôn đồng nhất, có khả năng phục hồi khi sai sót.*

### Story 11.1 — Drift Detection (Chống lệch dữ liệu)
**Là** admin, **tôi muốn** hệ thống tự động phát hiện khi DNS trên DirectAdmin bị thay đổi trực tiếp (không qua WHMCS), **để** tôi biết và quyết định xử lý trước khi gây ảnh hưởng.

| Issue | Mô tả | SP |
|-------|--------|-----|
| `DRIFT-001` | Cron job chạy hàng đêm (2:00 AM): gọi DA API `getZone()` cho từng domain → so sánh với `mod_hvndns_records` | 3 |
| `DRIFT-002` | Thuật toán diff: phát hiện record thêm trên DA mà WHMCS không có, record xóa trên DA mà WHMCS vẫn còn, record sửa giá trị khác nhau | 3 |
| `DRIFT-003` | Lưu kết quả drift vào `mod_hvndns_drift_reports` (domain_id, drift_type, local_value, remote_value, detected_at) | 1 |
| `DRIFT-004` | Dashboard alert: hiển thị số domain có drift, link vào trang chi tiết | 1 |
| `DRIFT-005` | Trang Drift Resolution: cho mỗi domain bị drift, Admin chọn "Pull from DA → WHMCS" hoặc "Push WHMCS → DA" hoặc "Ignore" | 3 |
| `DRIFT-006` | Option **Auto-fix**: toggle cho phép tự động push WHMCS → DA mỗi đêm mà không cần xác nhận (cho Admin muốn WHMCS là single source of truth) | 1 |

**AC**:
- Drift detection hoàn thành cho 500 domains trong < 30 phút
- Không gây load spike trên DA (throttle 1 request/giây)
- Report lưu lại lịch sử drift để phân tích pattern

---

### Story 11.2 — Zone Snapshot & Rollback
**Là** admin, **tôi muốn** khôi phục DNS của một domain về trạng thái trước đó khi khách hàng cấu hình sai làm sập website, **để** giảm thiểu thời gian downtime.

| Issue | Mô tả | SP |
|-------|--------|-----|
| `SNAP-001` | Per-record changelog: mỗi khi record bị sửa/xóa qua queue, lưu giá trị cũ vào `mod_hvndns_record_history` (record_id, old_type, old_name, old_value, old_ttl, changed_at, changed_by) | 2 |
| `SNAP-002` | Full zone snapshot: cron hàng đêm (sau drift check) lưu toàn bộ records của domain vào `mod_hvndns_snapshots` (domain_id, snapshot_data JSON, created_at) — giữ tối đa 30 snapshots | 2 |
| `SNAP-003` | Admin UI — Record History: xem timeline thay đổi của từng record, nút "Revert to this version" | 2 |
| `SNAP-004` | Admin UI — Zone Rollback: chọn snapshot theo ngày → preview diff (hiện tại vs snapshot) → confirm → dispatch batch job restore tất cả records | 3 |
| `SNAP-005` | Auto-cleanup: xóa snapshots cũ hơn 30 ngày, record_history cũ hơn 90 ngày | 1 |

**AC**:
- Rollback 1 zone hoàn tất (dispatch đầy đủ job) trong < 5 giây
- Preview diff rõ ràng: record nào sẽ bị thêm/sửa/xóa
- Rollback action tạo audit trail đặc biệt "ZONE_ROLLBACK by Admin [name]"

---

## EPIC-12: Quota & Template Management 🟣
> *Giới hạn tài nguyên theo gói dịch vụ và quản lý DNS template.*

### Story 12.1 — Data Quota (Giới hạn theo gói dịch vụ)
**Là** admin, **tôi muốn** giới hạn số lượng record/redirect/forwarder mà mỗi khách hàng được tạo dựa trên gói dịch vụ WHMCS, **để** phân tầng dịch vụ và bán upsell gói cao hơn.

| Issue | Mô tả | SP |
|-------|--------|-----|
| `QUOTA-001` | Bảng `mod_hvndns_quota_plans` (plan_name, max_records, max_subdomains, max_redirects, max_email_forwards, ddns_enabled, dnssec_enabled) | 1 |
| `QUOTA-002` | Admin UI: CRUD quota plans, mapping plan → WHMCS Product/Product Group | 2 |
| `QUOTA-003` | Enforcement: trước khi dispatch job ADD, kiểm tra quota → nếu vượt → trả lỗi "Bạn đã đạt giới hạn X records cho gói dịch vụ hiện tại. Vui lòng nâng cấp." | 2 |
| `QUOTA-004` | Client UI: hiển thị usage bar "Đang dùng 15/50 records" trong DNS Editor header | 1 |
| `QUOTA-005` | Admin có thể override quota cho từng domain cụ thể (exception) | 1 |

**AC**:
- Quota check xảy ra trước khi job vào queue (không tốn resource xử lý rồi mới báo lỗi)
- Thông báo vượt quota thân thiện, có link tới trang nâng cấp dịch vụ
- Admin override được log trong audit trail

---

### Story 12.2 — DNS Template Management
**Là** admin, **tôi muốn** tạo và quản lý các mẫu DNS template, **để** áp dụng tự động cho domain mới hoặc cho phép khách hàng reset DNS nhanh.

| Issue | Mô tả | SP |
|-------|--------|-----|
| `TMPL-001` | Bảng `mod_hvndns_templates` (template_name, description, is_default, records JSON) | 1 |
| `TMPL-002` | Admin UI: tạo/sửa/xóa template. Editor cho phép thêm record với placeholder `{{domain}}`, `{{ip}}` | 3 |
| `TMPL-003` | Đánh dấu 1 template là "Default" — tự động áp dụng khi provision domain mới | 1 |
| `TMPL-004` | Client "Load Template": dropdown chọn template → confirm "Thao tác này sẽ XÓA toàn bộ record hiện tại và thay bằng template. Tiếp tục?" → dispatch batch DELETE + ADD | 2 |
| `TMPL-005` | Trước khi load template, tự tạo snapshot zone hiện tại để rollback nếu cần | 1 |

**AC**:
- Placeholder `{{domain}}` được thay bằng domain thực tế khi áp dụng
- Load template tạo snapshot trước → an toàn
- Admin có thể tạo nhiều template cho nhiều use case (basic, email, e-commerce, ...)

---

## EPIC-13: Audit Trail UI & Email Forwarding 🟣
> *Giao diện kiểm toán bảo mật cao cấp và quản lý chuyển tiếp email.*

### Story 13.1 — Audit Trail Dashboard
**Là** admin/compliance officer, **tôi muốn** xem nhật ký kiểm toán chi tiết mọi thay đổi DNS trong hệ thống, **để** truy vết khi có sự cố bảo mật hoặc tranh chấp tên miền.

| Issue | Mô tả | SP |
|-------|--------|-----|
| `AUDIT-001` | Trang Audit Trail: DataTable từ `mod_hvndns_audit_trail` — cột: Time, Actor (Client/Admin/System/API), Domain, Action, Old Value, New Value, IP Address | 3 |
| `AUDIT-002` | Filter: theo actor type, theo domain, theo action type, theo khoảng thời gian, theo IP address | 2 |
| `AUDIT-003` | Detail view: click vào 1 dòng → popup hiển thị full detail bao gồm User Agent, Session ID, và context (VD: "Changed via Admin DNS Editor" / "Changed via DDNS API") | 2 |
| `AUDIT-004` | Export: CSV / PDF cho audit compliance, kèm checksum SHA256 để chứng minh log không bị tamper | 2 |
| `AUDIT-005` | Retention policy: audit log giữ tối thiểu 1 năm, có thể cấu hình lên 3 năm | 1 |

**AC**:
- Audit log là **append-only** — không có API hay UI nào cho phép sửa/xóa
- Export PDF kèm checksum verifiable
- Tìm kiếm nhanh trong 1 triệu+ records (indexed query)

---

### Story 13.2 — Email Forwarding
**Là** khách hàng, **tôi muốn** tạo email forwarding (ví dụ: info@domain.com → gmail cá nhân) và catch-all, **để** nhận email mà không cần hosting email riêng.

| Issue | Mô tả | SP |
|-------|--------|-----|
| `EMAIL-001` | Tab "Email" trong DNS Editor: bảng email forwarders hiện có (Source, Destination, Status) | 2 |
| `EMAIL-002` | Form tạo forwarder: source address (local part), destination email (validate format) | 1 |
| `EMAIL-003` | Queue job `CREATE_EMAIL_FORWARD`: gọi DA API tạo email forwarder | 2 |
| `EMAIL-004` | Catch-all toggle: bật/tắt catch-all email cho domain → tất cả email không match forwarder cụ thể sẽ chuyển về 1 địa chỉ | 1 |
| `EMAIL-005` | Tự động tạo MX record phù hợp khi bật email forwarding (nếu chưa có) | 1 |

**AC**:
- Email forwarding hoạt động trong < 3 phút sau khi tạo
- Validate destination email format trước khi lưu queue
- Catch-all có cảnh báo "Sẽ nhận tất cả spam email gửi tới domain"

---

## EPIC-14: Bulk Operations & REST API (Tương lai) 🟣
> *Thao tác hàng loạt cho Admin và API cho tích hợp bên ngoài.*

### Story 14.1 — Bulk Operations cho Admin
**Là** admin, **tôi muốn** thực hiện thay đổi DNS hàng loạt cho nhiều domain cùng lúc, **để** xử lý nhanh khi migrate server hoặc thay đổi IP hạ tầng.

| Issue | Mô tả | SP |
|-------|--------|-----|
| `BULK-001` | Trang Bulk Operations: chọn nhiều domain (checkbox) hoặc chọn theo filter (tất cả domain trên server X) | 2 |
| `BULK-002` | Action "Thay đổi IP": nhập old IP → new IP → hệ thống tìm tất cả record A/AAAA match → preview danh sách domain/record bị ảnh hưởng → confirm → dispatch batch jobs | 3 |
| `BULK-003` | Action "Áp dụng Template": chọn template → áp cho tất cả domain đã chọn (tự tạo snapshot trước) | 2 |
| `BULK-004` | Progress tracker: thanh tiến trình hiển thị "Đã xử lý 45/120 domains..." với option cancel giữa chừng | 2 |

**AC**:
- Preview bắt buộc trước khi execute — không cho chạy blind
- Snapshot tự động trước mỗi bulk operation
- Cancel giữa chừng chỉ dừng job chưa dispatch, không rollback job đã complete

---

### Story 14.2 — REST API cho tích hợp bên ngoài (Roadmap)
**Là** khách hàng enterprise, **tôi muốn** tích hợp quản lý DNS vào hệ thống CI/CD hoặc automation tool của mình qua API, **để** tự động hóa quy trình deploy.

| Issue | Mô tả | SP |
|-------|--------|-----|
| `API-001` | Thiết kế REST API spec: `GET /api/domains`, `GET /api/domains/{id}/records`, `POST /api/records`, `PUT /api/records/{id}`, `DELETE /api/records/{id}` | 2 |
| `API-002` | Authentication: API Key (Bearer Token) per client, quản lý trong Client Area | 2 |
| `API-003` | Rate limiting: 100 requests/phút per API key | 1 |
| `API-004` | Response format chuẩn JSON với pagination, error codes, và status tracking | 2 |
| `API-005` | API Documentation page (Swagger/OpenAPI hoặc trang docs tĩnh) | 3 |

**AC**:
- API tương thích chuẩn RESTful
- Mọi action qua API đi qua cùng Queue system (không bypass)
- Rate limit và quota áp dụng giống Client UI

---

# TỔNG HỢP

## Thống kê theo Phase

| Phase | Số Epic | Số Story | Số Issue | Tổng SP | Thời gian ước tính |
|-------|---------|----------|----------|---------|---------------------|
| 🟢 Phase 1 — MVP | 5 | 12 | 56 | ~105 SP | 5–7 tuần |
| 🔵 Phase 2 — Enterprise | 3 | 7 | 31 | ~62 SP | 4–6 tuần |
| 🟣 Phase 3 — Add-on | 6 | 10 | 43 | ~80 SP | 4–5 tuần |
| **Tổng** | **14** | **29** | **130** | **~247 SP** | **13–18 tuần** |

## Dependency Map (Thứ tự phụ thuộc)

```
EPIC-01 (Foundation) ──┬──→ EPIC-02 (Queue & Cron)
                       │          │
                       │          ├──→ EPIC-03 (DNS Editor Client)
                       │          │
                       │          └──→ EPIC-04 (Admin Dashboard)
                       │
                       └──→ EPIC-05 (Provisioning)
                       
Phase 1 stable ──┬──→ EPIC-06 (Dashboard Metrics)
                 ├──→ EPIC-07 (URL Forwarding + SSL)
                 └──→ EPIC-08 (Conflict + Webhook)

Phase 2 stable ──┬──→ EPIC-09 (DDNS API)
                 ├──→ EPIC-10 (DNSSEC)
                 ├──→ EPIC-11 (Drift + Rollback)
                 ├──→ EPIC-12 (Quota + Template)
                 ├──→ EPIC-13 (Audit Trail + Email)
                 └──→ EPIC-14 (Bulk Ops + REST API)
```

## Milestone chính

| Milestone | Thời điểm | Tiêu chí đạt được |
|-----------|-----------|-------------------|
| **M1 — Alpha** | Tuần 3 | Queue hoạt động, Cron đẩy được record lên 1 DA Node |
| **M2 — Beta Internal** | Tuần 6 | Client DNS Editor + Admin cơ bản hoạt động end-to-end |
| **M3 — MVP Release** | Tuần 7 | Phase 1 hoàn chỉnh, deploy production cho 10 khách thử nghiệm |
| **M4 — Enterprise Release** | Tuần 13 | Phase 2 hoàn chỉnh, multi-server + dashboard + webhook |
| **M5 — Full Release** | Tuần 18 | Toàn bộ tính năng, documentation, training team support |

---

> **Ghi chú**: Tài liệu này là phiên bản sống (living document), được cập nhật liên tục theo tiến độ Sprint. Mọi thay đổi scope cần được thảo luận trong Sprint Planning và ghi nhận vào Changelog bên dưới.

## Changelog
| Ngày | Thay đổi | Người thực hiện |
|------|----------|-----------------|
| 25/02/2026 | Khởi tạo tài liệu v1.0 | — |
