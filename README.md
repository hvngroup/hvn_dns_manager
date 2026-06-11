# MJ — DirectAdmin DNS Manager (WHMCS Addon)

Addon WHMCS quản lý DNS trên cụm **DirectAdmin** theo kiến trúc **Queue bất đồng bộ (async-first)**:
DNS Editor cho client, đồng bộ đa server (fan-out), DNSSEC / DDNS / URL Redirect /
Email Forwarding, drift detection và audit trail.

## Cấu trúc repository

| Đường dẫn | Vai trò |
|---|---|
| **`source/`** | **Code chạy thật — sẵn sàng upload vào `public_html`.** Đây là toàn bộ những gì cần đưa lên server production. |
| `docs/` | Tài liệu kỹ thuật (SPEC, AGENT, DB_SCHEMA…). **Chỉ dùng khi phát triển — KHÔNG upload.** |
| `.agents/` | Rule/workflow cho công cụ phát triển. **KHÔNG upload.** |

`source/` được tổ chức **đúng theo cây thư mục của `public_html`**:

```
source/
└── modules/
    └── addons/
        └── mj_dns_manager/        ← module addon WHMCS
            ├── mj_dns_manager.php  (file chính: config/activate/output)
            ├── hooks.php           (hook tự động: provisioning, cron SSL/Drift)
            ├── ajax.php            (endpoint AJAX client)
            ├── ddns.php            (endpoint cập nhật Dynamic DNS)
            ├── whmcs.json          (metadata module)
            ├── app/                (mã nguồn: Controllers, Services, Models, Gateway…)
            ├── templates/          (giao diện admin + client)
            ├── assets/             (CSS)
            ├── cron/queue_worker.php (worker xử lý hàng đợi)
            └── lang/english.php    (ngôn ngữ)
```

## Yêu cầu

- WHMCS **≥ 8.0.0**
- PHP **≥ 7.4** (đã kiểm cú pháp tới PHP 8.4)

## Cài đặt (deploy lên production)

### 1. Upload
Đưa **toàn bộ nội dung bên trong `source/`** vào thư mục `public_html` của WHMCS
(hợp nhất thư mục `modules/` — không ghi đè module khác). Kết quả phải là:

```
public_html/modules/addons/mj_dns_manager/...
```

> ⚠️ Module dùng đường dẫn tương đối cố định (`../../../init.php`) nên **bắt buộc** nằm
> đúng tại `modules/addons/mj_dns_manager/`.

### 2. Kích hoạt addon
WHMCS Admin → **System Settings → Addon Modules** → tìm
**"ModuleJET — DirectAdmin DNS Manager"** → **Activate** → cấu hình **Access Control**
(nhóm admin được phép) và các tham số trong tab cấu hình. Bước này tự tạo bảng CSDL
`tbl_mj_dns_*`.

### 3. Thiết lập Cron (worker hàng đợi)
Mọi thao tác DNS chạy bất đồng bộ qua hàng đợi, cần worker chạy thường xuyên. Thêm vào crontab:

```cron
* * * * * php -q /ĐƯỜNG_DẪN/public_html/modules/addons/mj_dns_manager/cron/queue_worker.php >/dev/null 2>&1
```

> Các tác vụ định kỳ khác (kiểm tra SSL, drift) chạy qua **WHMCS System Cron** sẵn có
> (hook `AfterCronJob`) — không cần cron riêng.

### 4. License & DirectAdmin server
- Cấu hình **license** trong tab cấu hình addon (module có kiểm tra license 3 lớp).
- Thêm **DirectAdmin server** trong giao diện admin của addon (hostname, IP, cổng, tài khoản).

## Tuân thủ chuẩn MJ & WHMCS

Module bám SOP-HSW-WHMCS-001 (HVN WHMCS Suite). Các điểm `[WHMCS-REQUIRED]` đã đạt:
guard `defined("WHMCS")`, Capsule binding, **CSRF `hash_equals()` trên mọi mutation**
(`app/Security/Csrf.php`), không `$_REQUEST`, không sửa core, secret server DA mã hoá,
license fail-safe (không làm sập admin).

### Đã đồng bộ với mj-design + dev-standard (v1.6.0)

- **1 file JS IIFE** `assets/js/mj-dns.js` — toàn bộ logic JS rời khỏi template (template chỉ
  còn config block giá trị Smarty); `Utils.fetchJson` tự đính CSRF; toast/confirm dùng chung.
- **Design system canonical:** `tokens.css` (mj-design) + `components.css` (scoped `.mj-dns`)
  + `mj-dns.css` (bridge legacy→canonical); Inter + JetBrains Mono; brand red `#EA4445`.
- **Admin shell chuẩn MJ:** Header / Nav / Breadcrumb / Content / Footer, icon SVG stroke,
  ẩn WHMCS content-header (body-class scoped), reset va chạm Bootstrap.
- **Asset inline từ disk** (`AssetInliner`, hooks.md §7.2/§7.3) + `assets/.htaccess`;
  client inject qua `ClientAreaHeadOutput` page-scoped; navbar gate theo enabled+license.

### Deviations `[MJ-INTERNAL]` còn lại (ghi nhận có lý do)

| Deviation | Chuẩn mong đợi | Lý do |
|---|---|---|
| Icon page-body dùng Bootstrap-icons (CDN) | SVG stroke set `I.*` của mj-design, không icon font | Swap ~30 template là đợt riêng; shell mới đã dùng SVG stroke |
| Alpine.js chưa vendor sẵn (loader ưu tiên local, fallback CDN) | `assets/js/vendor/alpine.min.js` 3.14.8 | Môi trường build chặn network — thả file khi đóng gói (xem `assets/js/vendor/README.md`) |
| Admin template là Smarty `.tpl` | PHP include templates | Đổi engine render = rewrite toàn bộ admin UI; Smarty vẫn là chuẩn WHMCS cho client, giữ thống nhất |
| License ở `app/License/` (namespaced, autoload) | `lib/LicenseChecker.php` + `lib/license-config.php` | Di chuyển phá autoloader; giữ chỗ hiện tại có chủ đích |
| Markup page-body giữ class `.mj-*` bridge (chưa re-skin sang `.btn`/`.card`/`.kpi` canonical) | Class canonical components.css | Re-skin 30 template cần đối chiếu trực quan trên staging; token/màu/font đã canonical |

## Ghi chú

- **`logo.png`:** đã có (128×128, brand red) trong thư mục module, khớp khai báo `whmcs.json`.
- **Credential:** `docs/CREDENTIALS.md` đã được gỡ khỏi Git và đưa vào `.gitignore`; dùng
  `docs/CREDENTIALS.example.md` làm mẫu. **Tuyệt đối không** điền secret thật vào file được Git theo dõi.
- **Chưa kiểm thử end-to-end trên WHMCS thật:** code verify tới mức lint (PHP 8.4) + đối chiếu tĩnh.
  Bắt buộc chạy staging (Cổng ④ UAT) trước production.
