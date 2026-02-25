---
trigger: glob
globs: **/*.php
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