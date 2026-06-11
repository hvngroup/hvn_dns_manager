# CHANGELOG — MJ - DirectAdmin DNS Manager (`mj_dns_manager`)

> Theo [Keep a Changelog](https://keepachangelog.com/) + **semver**. Mỗi release (Phase 9) tag `vX.Y.Z` trên `main`.

## [Unreleased]
### Security
- **CSRF [WHMCS-REQUIRED]:** thêm `app/Security/Csrf.php` (admin self-token + token client-area
  WHMCS), so sánh bằng `hash_equals()`. Bắt buộc CSRF trên **mọi** mutation ở cả hai đường AJAX
  admin (`ajax.php` và `AdminController::handleAjax`) lẫn client, và form lưu server. Vá lỗi cũ:
  CSRF admin bị bỏ qua khi token session rỗng; so sánh token bằng `!==`/`===`.
- **Credential:** gỡ `docs/CREDENTIALS.md` khỏi Git, thêm vào `.gitignore`, thay bằng
  `docs/CREDENTIALS.example.md` chỉ chứa biến giả (tuân thủ ATTT 01-01/11/2024).

### Changed
- Thay toàn bộ `$_REQUEST` bằng `$_GET` (routing/query) / `$_POST` (mutation) theo chuẩn MJ.
- Đính CSRF token tập trung cho mọi `fetch()` admin tại `templates/admin/wrapper.tpl`.

### Fixed
- Brand red về đúng `#EA4445` (trước đó `#ea4544` do đảo số); hover `#C93939`.

### Added
- `lang/vietnamese.php`, `logo.png` (128×128), `CHANGELOG.md`, `LICENSE`.
- Tài liệu điều phối SOP: `docs/CLAUDE.md`, `docs/MEMORY.md`, `docs/SCHEMA.md`.

## [1.5.0]
### Added
- Bản nội bộ: DNS Editor (client), đồng bộ async qua Queue + Cron Worker, fan-out đa server
  DirectAdmin, DNSSEC / DDNS / URL Redirect / Email Forwarding, drift detection, audit trail.
