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

## Ghi chú

- **Thiếu `logo.png`:** `whmcs.json` khai báo `logo.png` nhưng file chưa có. Không chặn
  hoạt động — chỉ là module hiển thị không có logo. Thêm `logo.png` vào thư mục module nếu cần.
- **Chưa kiểm thử end-to-end trên WHMCS thật:** code mới verify tới mức lint (PHP 8.4) +
  đối chiếu tĩnh. Nên chạy thử trên môi trường staging trước khi đưa lên production.
