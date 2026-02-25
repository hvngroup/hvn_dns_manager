---
trigger: always_on
---

# HVN DNS Manager — Project Context

## Thông tin dự án
- **Tên module**: HVN - DirectAdmin DNS Manager
- **Nền tảng**: WHMCS 8.x Addon Module
- **Ngôn ngữ**: PHP 7.4+ (target PHP 8.1)
- **Database**: MySQL/MariaDB qua WHMCS Eloquent ORM (Capsule)
- **Frontend**: Smarty Template + Bootstrap 5 + Alpine.js 3.x
- **Namespace gốc**: `HvnGroup\DnsManager`
- **Tiền tố DB**: `mod_hvndns_`

## Tài liệu tham chiếu (theo thứ tự ưu tiên)
Khi cần thông tin chi tiết, đọc các file trong `docs/`:
1. `docs/AGENT.md` — Quy tắc điều phối tối thượng
2. `docs/DB_SCHEMA.md` — Database schema, định nghĩa cột, indexes
3. `docs/API_REFERENCE.md` — DA API + Internal Ajax API + Error Codes
4. `docs/SETTINGS.md` — 96 Admin settings, validation, permission logic
5. `docs/SPEC.md` — Kiến trúc hệ thống, flow diagrams
6. `docs/EPICS.md` — User stories, acceptance criteria, issue list
7. `docs/TEST_PLAN.md` — Test cases, fixtures, checklists
8. `docs/WIREFRAME.md` — Phác thảo giao diện
9. `docs/PLAN.md` — Kế hoạch phát triển tổng thể

## Quy tắc tham chiếu theo ngữ cảnh
- Code database (Model, migration, query) → đọc `docs/DB_SCHEMA.md`
- Code gọi DA API (Gateway, parser) → đọc `docs/API_REFERENCE.md` Phần A
- Code Ajax endpoint (Controller, response) → đọc `docs/API_REFERENCE.md` Phần B
- Code settings/config (SettingsHelper, admin settings page) → đọc `docs/SETTINGS.md`
- Code permission check (record type enable/disable, NS check) → đọc `docs/SETTINGS.md` Section 5-6
- Code limits enforcement (per-type limits, 3-layer priority) → đọc `docs/SETTINGS.md` Section 7
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