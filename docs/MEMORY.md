# MEMORY.md — Nhật ký tài liệu hoá (`mj_dns_manager`)

> Theo SOP-HSW-WHMCS-001: cập nhật mỗi khi chạm tài liệu/quyết định kiến trúc.

## 2026-06-11 — Security & SOP compliance pass
- **Audit theo MJ WHMCS SOP** (sop + dev-standard + security + dev-skills). Verdict ban đầu: **Cổng ③ TRƯỢT**
  (1 CRITICAL credential trong Git + nhiều HIGH CSRF). Đã xử lý:
  - **CRITICAL:** gỡ `docs/CREDENTIALS.md` (chứa mật khẩu admin thật) khỏi Git, thêm `.gitignore`, thay bằng
    `docs/CREDENTIALS.example.md` (placeholder). ⚠ **Mật khẩu phải được đổi (rotate) + scrub git history** —
    hành động ngoài code, cần con người thực hiện.
  - **HIGH CSRF:** thêm `app/Security/Csrf.php`; enforce `hash_equals()` trên mọi mutation (admin `ajax.php`
    + `AdminController::handleAjax` + form server_edit; client `ajax.php`). Vá lỗi bỏ-qua-khi-token-rỗng.
    Bootstrap CSRF tập trung ở `wrapper.tpl` (auto-đính header cho mọi fetch admin).
  - **MEDIUM:** thay toàn bộ `$_REQUEST` → `$_GET`/`$_POST`.
  - **Metadata/brand:** brand red `#ea4544`→`#EA4445`, hover `#C93939`; thêm `logo.png` (128×128),
    `lang/vietnamese.php`, `CHANGELOG.md`, `LICENSE`.
  - **Docs↔source drift:** đồng bộ định danh trong `docs/` (`mod_hvndns_`→`tbl_mj_dns_`, `hvn_dns_manager`→
    `mj_dns_manager`, `HVN -`→`MJ -`, `HVNDNS_CONFIG`→`MJDNS_CONFIG`).
  - **SOP docs:** sinh `CLAUDE.md`, `MEMORY.md`, `SCHEMA.md` (artifact Cổng ②).
- **Deviations [MJ-INTERNAL] còn lại (ghi nhận, chưa refactor):** xem README §Deviations — JS inline trong
  template (chưa gom về 1 IIFE), Alpine.js qua CDN (chưa có local fallback), CSS chưa dùng canonical mj-design
  (tokens/components), file license ở `app/License/` thay vì `lib/`. Cần môi trường WHMCS staging để refactor an toàn.

## Trước đó (lịch sử)
- Tài liệu gốc (`SPEC`, `EPICS`, `PLAN`, `DB_SCHEMA`, `WIREFRAME`, `API_REFERENCE`, `SETTINGS`, `LICENSING`,
  `PROTOTYPE`, `TEST_PLAN`, `AGENT`) viết dưới định danh cũ `hvn`/`mod_hvndns_`; đã chuẩn hoá về `mj_dns` ngày 2026-06-11.
- Đóng gói vào `source/` theo cây `public_html` (commit `8cdad47`).
