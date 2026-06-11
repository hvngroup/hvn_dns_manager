# SCHEMA.md — Lược đồ DB tổng quan (`mj_dns_manager`)

> Tổng quan; chi tiết cột/khóa/index xem `DB_SCHEMA.md`. Tiền tố: **`tbl_mj_dns_`** ·
> `utf8mb4_unicode_ci` · ORM Illuminate Capsule (Eloquent). Tạo/xoá trong migration
> `app/Migration/Versions/v0_1_0_prototype.php` (bọc try/catch).

## 18 bảng

| Bảng | Vai trò |
|---|---|
| `tbl_mj_dns_schema_version` | Phiên bản schema (migration) |
| `tbl_mj_dns_settings` | Cấu hình module (key/value) — nguồn sự thật cho settings |
| `tbl_mj_dns_servers` | Node DirectAdmin (hostname/IP/port/cred mã hoá, role, trạng thái) |
| `tbl_mj_dns_domains` | Tên miền khách (map `whmcs_user_id`, service id, trạng thái zone) |
| `tbl_mj_dns_records` | Bản ghi DNS — **source of truth** (A/AAAA/CNAME/MX/TXT/SRV/CAA/NS) |
| `tbl_mj_dns_queue` | Hàng đợi tác vụ bất đồng bộ (ADD/EDIT/DELETE record, CREATE/DELETE zone…) |
| `tbl_mj_dns_sync_logs` | Nhật ký đồng bộ tới từng server (fan-out) |
| `tbl_mj_dns_audit_trail` | Nhật ký kiểm toán hành động (ai/khi/gì) |
| `tbl_mj_dns_record_history` | Lịch sử thay đổi từng record |
| `tbl_mj_dns_snapshots` | Bản sao zone (rollback) |
| `tbl_mj_dns_templates` | Mẫu DNS (áp nhanh bộ record) |
| `tbl_mj_dns_dnssec` | Thông số DNSSEC theo domain |
| `tbl_mj_dns_ddns_tokens` | Token DDNS (lưu **SHA-256 hash**, không lưu token thô) |
| `tbl_mj_dns_redirects` | Chuyển hướng URL (thường/masked) |
| `tbl_mj_dns_email_forwards` | Chuyển tiếp email / catch-all |
| `tbl_mj_dns_drift_reports` | Báo cáo lệch dữ liệu (DB ↔ server thật) |
| `tbl_mj_dns_ip_blacklist` | IP bị chặn (rate-limit/brute-force DDNS) |
| `tbl_mj_dns_notification_cooldowns` | Kiểm soát tần suất cảnh báo admin |

## Quan hệ chính
- `domains.whmcs_user_id` → client WHMCS; `domains.id` ← `records`, `ddns_tokens`, `dnssec`,
  `redirects`, `email_forwards`, `snapshots`, `drift_reports` (domain_id).
- `queue.domain_id` → `domains`; `sync_logs` tham chiếu queue job + server.
- `records` là nguồn sự thật; worker đẩy ra các `servers` (role primary/secondary) → ghi `sync_logs`.

## Quy ước
- Index: khoá ngoại (`domain_id`, `whmcs_user_id`, `server_id`) đều index; `settings.setting_key` unique;
  `ddns_tokens.token_hash` index.
- Retention: cấu hình qua settings (`audit_trail_retention_days`, `sync_log_retention_days`,
  `record_history_retention_days`, `snapshot_retention_count`, `queue_completed_retention_days`).
