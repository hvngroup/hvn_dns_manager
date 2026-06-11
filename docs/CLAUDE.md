# CLAUDE.md — Bản đồ điều phối build (`mj_dns_manager`)

> Tệp Claude Code đọc khi build (SOP-HSW-WHMCS-001, Cổng ②). Đặc tả trước, triển khai sau.
> Khi chạm tài liệu → cập nhật `MEMORY.md`. Khi đổi DB → cập nhật `SCHEMA.md`.

## 1. Định danh sản phẩm
- **Tên:** MJ - DirectAdmin DNS Manager · **Module:** `mj_dns_manager` · **Loại:** Addon (WHMCS).
- **Abbr:** `dns` · **Prefix:** code `mj_dns_` · bảng `tbl_mj_dns_` · CSS `mj-` · JS `MJDNS_CONFIG`.
- **License key:** `MJ-DNS-{STD|PRO}-…` · Thương mại (ionCube + LicenseChecker).
- **Nền tảng mục tiêu:** WHMCS 8.x (test trên 8.13.x), PHP 8.1+ (đã lint 8.4).

## 2. Kiến trúc (async-first)
Mọi thao tác DNS đi qua **Queue + Cron Worker** (không gọi DirectAdmin trong request người dùng).
Fan-out đa server DA. Hooks: `AcceptOrder` (provisioning zone), `AfterCronJob` (queue worker +
SSL checker + drift checker + force-run flags), `ClientAreaPrimaryNavbar`.

## 3. Cây mã nguồn (`source/modules/addons/mj_dns_manager/`)
| Đường dẫn | Vai trò |
|---|---|
| `mj_dns_manager.php` | config / activate (migration + seed settings) / deactivate / output |
| `hooks.php` | đăng ký hook (AcceptOrder, AfterCronJob, navbar) |
| `ajax.php` | endpoint AJAX client + admin (CSRF qua `app/Security/Csrf.php`) |
| `ddns.php` | endpoint DDNS công khai (auth bằng token SHA-256, giao thức No-IP) |
| `cron/queue_worker.php` | worker hàng đợi (chạy mỗi phút qua crontab) |
| `app/Controllers/{Admin,Client}/` | điều hướng request → service |
| `app/Services/` | nghiệp vụ (Queue, Zone, Record, Dnssec, Ddns, EmailForward, Report, Settings…) |
| `app/Gateway/DAGateway.php` | client HTTP tới DirectAdmin API |
| `app/Models/` | Eloquent models (18 bảng `tbl_mj_dns_*`) |
| `app/Security/` | `InputSanitizer`, `Csrf` |
| `app/License/` | `LicenseChecker` + `license-config.php` (⚠ deviation: chuẩn đặt ở `lib/` — xem README §Deviations) |
| `templates/{admin,client}/` | Smarty `.tpl` — CHỈ markup + config block; logic JS ở `assets/js/mj-dns.js` |
| `app/Helpers/AssetInliner.php` | Bơm asset inline từ disk (config→CSS→JS→Alpine, hooks.md §7.2/§7.3) |
| `assets/css/` | `tokens.css` (canonical mj-design) → `components.css` (scoped `.mj-dns`) → `mj-dns.css` (bridge + shell + module rules) |
| `assets/js/` | `mj-dns.js` (single IIFE: Utils/CSRF/toast/confirm + page components) · `vendor/` (Alpine local — xem README trong đó) |
| `lang/` | `english.php`, `vietnamese.php` |

## 4. Bảo mật (bắt buộc — Cổng ③)
- **CSRF:** `app/Security/Csrf.php` — admin self-token (`$_SESSION['mj_dns_admin_csrf']`), client dùng
  `$_SESSION['tkval']`; **luôn** so sánh bằng `hash_equals()`. Mọi mutation (admin & client) phải verify.
  Token admin đính tự động vào fetch qua bootstrap trong `wrapper.tpl`.
- `defined("WHMCS") or die()` đầu mọi file `app/`. `ajax.php`/`ddns.php` là entry công khai → bootstrap `init.php`.
- Capsule binding (không ghép chuỗi SQL). Credential server DA mã hoá bằng `\WHMCS\Security\Encryption`.
- KHÔNG `$_REQUEST` (dùng `$_GET` routing / `$_POST` mutation). KHÔNG sửa core WHMCS.
- Secret KHÔNG vào repo: `docs/CREDENTIALS.md` (gitignore) ↔ `docs/CREDENTIALS.example.md` (template).

## 5. Tài liệu liên quan (trong `docs/`)
`SPEC.md` (đặc tả) · `EPICS.md` · `PLAN.md` · `API_REFERENCE.md` · `DB_SCHEMA.md` (từ điển cột) ·
`SETTINGS.md` · `LICENSING.md` · `WIREFRAME.md` · `PROTOTYPE.md` · `TEST_PLAN.md` · `AGENT.md`.
Tổng quan DB: `SCHEMA.md`. Nhật ký tài liệu: `MEMORY.md`.
