# CHANGELOG — MJ - DirectAdmin DNS Manager (`mj_dns_manager`)

> Theo [Keep a Changelog](https://keepachangelog.com/) + **semver**. Mỗi release (Phase 9) tag `vX.Y.Z` trên `main`.

## [Unreleased]

## [1.6.0] — Security pass + đồng bộ mj-design / mj-whmcs-dev-standard
### Security
- **CSRF [WHMCS-REQUIRED]:** thêm `app/Security/Csrf.php` (admin self-token + token client-area
  WHMCS), so sánh bằng `hash_equals()`. Bắt buộc CSRF trên **mọi** mutation ở cả hai đường AJAX
  admin (`ajax.php` và `AdminController::handleAjax`) lẫn client, và form lưu server. Vá lỗi cũ:
  CSRF admin bị bỏ qua khi token session rỗng; so sánh token bằng `!==`/`===`.
- **Credential:** gỡ `docs/CREDENTIALS.md` khỏi Git, thêm vào `.gitignore`, thay bằng
  `docs/CREDENTIALS.example.md` chỉ chứa biến giả (tuân thủ ATTT 01-01/11/2024).

### Changed
- **Design system:** vendor `assets/css/tokens.css` (canonical mj-design) +
  `assets/css/components.css` (scope-transform dưới `.mj-dns` để không ảnh hưởng UI WHMCS
  host — [WHMCS-REQUIRED]); hợp nhất 2 file CSS cũ thành `assets/css/mj-dns.css` với bridge
  alias biến legacy → token canonical (`--mj-*`), bổ sung Inter + JetBrains Mono.
- **Admin shell:** wrapper.tpl chuyển từ sidebar Bootstrap-clone sang layout chuẩn MJ
  (Header / Nav / Breadcrumb / Content / Footer, templates-layout.md) với icon SVG stroke;
  ẩn `content-header` WHMCS theo body-class scoped; reset va chạm Bootstrap `.modal`/`.row`.
- **JavaScript:** toàn bộ logic JS inline (~3.400 dòng / 22 template) chuyển về MỘT file IIFE
  `assets/js/mj-dns.js` (Utils.fetchJson tự đính CSRF + X-Requested-With, toast/confirm,
  page components); template chỉ còn config block (giá trị Smarty).
- **Asset delivery:** bơm INLINE từ disk qua `app/Helpers/AssetInliner` (hooks.md §7.2/§7.3)
  thay cho `<link>/<script src>` vào modules/addons/* (tránh 403 Nginx/cPanel);
  thêm `assets/.htaccess` (Apache safeguard); Alpine.js ưu tiên vendor local
  `assets/js/vendor/alpine.min.js`, fallback CDN khi chưa vendor.
- **Hooks:** thêm `ClientAreaHeadOutput` page-scoped (chỉ `m=mj_dns_manager`) bơm asset
  client; gate `ClientAreaPrimaryNavbar` theo `module_enabled` + license (fail-open).
- Thay toàn bộ `$_REQUEST` bằng `$_GET` (routing/query) / `$_POST` (mutation) theo chuẩn MJ.
- Version module → **1.6.0** (semver).

### Fixed
- Brand red về đúng `#EA4445` (trước đó `#ea4544` do đảo số); hover `#C93939`.

### Added
- `lang/vietnamese.php`, `logo.png` (128×128), `CHANGELOG.md`, `LICENSE`.
- Tài liệu điều phối SOP: `docs/CLAUDE.md`, `docs/MEMORY.md`, `docs/SCHEMA.md`.

## [1.5.0]
### Added
- Bản nội bộ: DNS Editor (client), đồng bộ async qua Queue + Cron Worker, fan-out đa server
  DirectAdmin, DNSSEC / DDNS / URL Redirect / Email Forwarding, drift detection, audit trail.
