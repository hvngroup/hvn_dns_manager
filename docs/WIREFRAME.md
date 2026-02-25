# HVN - DirectAdmin DNS Manager
## WIREFRAME.md — Phác thảo Giao diện

> **Phiên bản**: 1.0  
> **Ngày tạo**: 25/02/2026  
> **Dành cho**: Frontend Developer, UI/UX Designer, AI Agent  
> **Framework**: Smarty Template + Bootstrap 5 + Alpine.js 3.x  
> **Theme tương thích**: WHMCS Six / Twenty-One  

---

## Mục lục

**Client Area (Khách hàng)**
1. [CL-01: Danh sách Domain](#cl-01-danh-sách-domain)
2. [CL-02: DNS Editor — Màn hình chính](#cl-02-dns-editor--màn-hình-chính)
3. [CL-03: Modal Thêm/Sửa Record](#cl-03-modal-thêmsửa-record)
4. [CL-04: Tab Redirects](#cl-04-tab-redirects)
5. [CL-05: Tab Email Forwarding](#cl-05-tab-email-forwarding)
6. [CL-06: Tab DNSSEC](#cl-06-tab-dnssec)
7. [CL-07: Tab DDNS](#cl-07-tab-ddns)
8. [CL-08: Load Template Dialog](#cl-08-load-template-dialog)

**Admin Area (Quản trị viên)**
9. [AD-01: Dashboard](#ad-01-dashboard)
10. [AD-02: Server Management](#ad-02-server-management)
11. [AD-03: Modal Thêm/Sửa Server](#ad-03-modal-thêmsửa-server)
12. [AD-04: Global Domain List](#ad-04-global-domain-list)
13. [AD-05: Admin DNS Editor](#ad-05-admin-dns-editor)
14. [AD-06: Sync Logs](#ad-06-sync-logs)
15. [AD-07: Audit Trail](#ad-07-audit-trail)
16. [AD-08: Template Manager](#ad-08-template-manager)
17. [AD-09: Quota Plans](#ad-09-quota-plans)
18. [AD-10: Drift Reports](#ad-10-drift-reports)
19. [AD-11: Bulk Operations](#ad-11-bulk-operations)
20. [AD-12: Notification Settings](#ad-12-notification-settings)

---

## Quy ước Wireframe

```
Ký hiệu:
╔══════╗     Khung trang / Section
║      ║
╚══════╝

┌──────┐     Thành phần UI (card, form, table)
│      │
└──────┘

[Button]      Nút bấm
(●) / ( )    Radio button (selected / unselected)
[✓] / [ ]    Checkbox (checked / unchecked)
[___________] Input field
[▼ Dropdown ] Select / Dropdown
«link»        Clickable link
🟢🟡🔴       Status indicators
⟳             Loading spinner
→             Navigation / flow direction

Ghi chú:
{variable}    Dữ liệu động từ backend
$alpine       Alpine.js reactive data
```

---

# CLIENT AREA — Giao diện Khách hàng

---

## CL-01: Danh sách Domain

> **URL**: `/clientarea.php?action=productdetails&id={service_id}`  
> **Khi nào hiện**: Client truy cập dịch vụ DNS đã mua trên WHMCS  
> **Mục đích**: Hiển thị tất cả domain thuộc dịch vụ, entry point vào DNS Editor

```
╔══════════════════════════════════════════════════════════════════════╗
║  WHMCS Client Area Header / Navigation                              ║
╠══════════════════════════════════════════════════════════════════════╣
║                                                                      ║
║  ◄ Quay lại Dịch vụ của tôi                                        ║
║                                                                      ║
║  ┌────────────────────────────────────────────────────────────────┐  ║
║  │  DNS Management — Gói {plan_name}                              │  ║
║  │  Trạng thái: 🟢 Active    Hết hạn: {expiry_date}             │  ║
║  └────────────────────────────────────────────────────────────────┘  ║
║                                                                      ║
║  ┌────────────────────────────────────────────────────────────────┐  ║
║  │  Domain của bạn                                                │  ║
║  │                                                                │  ║
║  │  ┌──────────────────────────────────────────────────────────┐ │  ║
║  │  │ 🌐 example.com              15 records    🟢 Active     │ │  ║
║  │  │    NS: dns1.hvn.vn, dns2.hvn.vn, dns3.hvn.vn           │ │  ║
║  │  │                                    [Quản lý DNS →]      │ │  ║
║  │  ├──────────────────────────────────────────────────────────┤ │  ║
║  │  │ 🌐 shop.vn                   8 records    🟢 Active     │ │  ║
║  │  │    NS: dns1.hvn.vn, dns2.hvn.vn, dns3.hvn.vn           │ │  ║
║  │  │                                    [Quản lý DNS →]      │ │  ║
║  │  ├──────────────────────────────────────────────────────────┤ │  ║
║  │  │ 🌐 myblog.net                3 records    🟡 Syncing    │ │  ║
║  │  │    NS: dns1.hvn.vn, dns2.hvn.vn, dns3.hvn.vn           │ │  ║
║  │  │    ⟳ 2 bản ghi đang đồng bộ...    [Quản lý DNS →]      │ │  ║
║  │  └──────────────────────────────────────────────────────────┘ │  ║
║  └────────────────────────────────────────────────────────────────┘  ║
║                                                                      ║
║  ┌────────────────────────────────────────────────────────────────┐  ║
║  │  ℹ️ Nameserver cần trỏ về:                                    │  ║
║  │     dns1.hvn.vn    dns2.hvn.vn    dns3.hvn.vn                │  ║
║  │     [Copy tất cả]                                              │  ║
║  └────────────────────────────────────────────────────────────────┘  ║
╚══════════════════════════════════════════════════════════════════════╝
```

**Hành vi**:
- Click `[Quản lý DNS →]` → chuyển tới CL-02 (DNS Editor)
- Badge trạng thái lấy từ aggregate sync status (nếu có job PENDING/SYNCING → 🟡)
- Nút `[Copy tất cả]` copy 3 nameserver vào clipboard

---

## CL-02: DNS Editor — Màn hình chính

> **URL**: `/clientarea.php?action=productdetails&id={service_id}&domain_id={id}`  
> **Mục đích**: Màn hình quản lý DNS chính — hiển thị tất cả records, tabs cho các tính năng phụ  
> **Đây là màn hình quan trọng nhất của Client Area**

```
╔══════════════════════════════════════════════════════════════════════════╗
║  WHMCS Client Area Header / Navigation                                  ║
╠══════════════════════════════════════════════════════════════════════════╣
║                                                                          ║
║  ◄ Quay lại danh sách domain                                           ║
║                                                                          ║
║  ┌──────────────────────────────────────────────────────────────────┐   ║
║  │  🌐 example.com                                                  │   ║
║  │  ──────────────────────────────────────────────────────────────  │   ║
║  │  Đang dùng: 15/50 records    │   🔒 DNSSEC: Bật    │  🔐 SSL: Active │
║  │  ████████████░░░░░░░░ 30%    │                      │                 │
║  └──────────────────────────────────────────────────────────────────┘   ║
║                                                                          ║
║  ┌──────────────────────────────────────────────────────────────────┐   ║
║  │ [DNS Records] [Redirects] [Email] [DNSSEC] [DDNS] [Templates]   │   ║
║  │  ═══════════                                                      │   ║
║  │                                                                    │   ║
║  │  ┌───────────────────────────────────────────────────────┐       │   ║
║  │  │ Lọc: [▼ Tất cả loại] [________Tìm kiếm________] 🔍  │       │   ║
║  │  │                                    [+ Thêm bản ghi]   │       │   ║
║  │  └───────────────────────────────────────────────────────┘       │   ║
║  │                                                                    │   ║
║  │  ┌─────┬──────────┬────────────────────┬───────┬────────┬──────┐ │   ║
║  │  │Loại │ Tên      │ Giá trị            │ TTL   │Tr.thái │      │ │   ║
║  │  ├─────┼──────────┼────────────────────┼───────┼────────┼──────┤ │   ║
║  │  │     │          │                    │       │        │      │ │   ║
║  │  │ NS  │ @        │ dns1.hvn.vn.       │ 86400 │ 🟢Live │  🔒 │ │   ║
║  │  │ 🔧  │          │                    │       │        │      │ │   ║
║  │  ├─────┼──────────┼────────────────────┼───────┼────────┼──────┤ │   ║
║  │  │ NS  │ @        │ dns2.hvn.vn.       │ 86400 │ 🟢Live │  🔒 │ │   ║
║  │  │ 🔧  │          │                    │       │        │      │ │   ║
║  │  ├─────┼──────────┼────────────────────┼───────┼────────┼──────┤ │   ║
║  │  │ NS  │ @        │ dns3.hvn.vn.       │ 86400 │ 🟢Live │  🔒 │ │   ║
║  │  │ 🔧  │          │                    │       │        │      │ │   ║
║  │  ├─────┼──────────┼────────────────────┼───────┼────────┼──────┤ │   ║
║  │  │ A   │ @        │ 103.45.67.89       │ 3600  │ 🟢Live │ [✏️] │ │   ║
║  │  │     │          │                    │       │        │ [🗑️] │ │   ║
║  │  ├─────┼──────────┼────────────────────┼───────┼────────┼──────┤ │   ║
║  │  │ A   │ mail     │ 103.45.67.90       │ 3600  │🔄2/3   │ [✏️] │ │   ║
║  │  │     │          │                    │       │Syncing │ [🗑️] │ │   ║
║  │  ├─────┼──────────┼────────────────────┼───────┼────────┼──────┤ │   ║
║  │  │ A   │ www      │ 103.45.67.89       │ 3600  │ 🟡     │ [✏️] │ │   ║
║  │  │     │          │                    │       │Pending │ [🗑️] │ │   ║
║  │  ├─────┼──────────┼────────────────────┼───────┼────────┼──────┤ │   ║
║  │  │CNAME│ ftp      │ example.com.       │ 3600  │ 🟢Live │ [✏️] │ │   ║
║  │  │     │          │                    │       │        │ [🗑️] │ │   ║
║  │  ├─────┼──────────┼────────────────────┼───────┼────────┼──────┤ │   ║
║  │  │ MX  │ @        │ mail.example.com.  │ 3600  │ 🟢Live │ [✏️] │ │   ║
║  │  │     │          │ Priority: 10       │       │        │ [🗑️] │ │   ║
║  │  ├─────┼──────────┼────────────────────┼───────┼────────┼──────┤ │   ║
║  │  │ TXT │ @        │ v=spf1 include:    │ 3600  │ 🔴     │ [✏️] │ │   ║
║  │  │     │          │ _spf.google.com ~a │       │Failed  │ [🗑️] │ │   ║
║  │  │     │          │                    │       │[Retry] │      │ │   ║
║  │  └─────┴──────────┴────────────────────┴───────┴────────┴──────┘ │   ║
║  │                                                                    │   ║
║  │  Hiển thị 1-8 / 15 bản ghi      ◄ 1  2 ►                        │   ║
║  └──────────────────────────────────────────────────────────────────┘   ║
╚══════════════════════════════════════════════════════════════════════════╝
```

**Chi tiết thành phần**:

**Header Domain Info**:
- Tên domain lớn, nổi bật
- Thanh Quota: progress bar `{current}/{limit} records` — đổi màu khi gần limit (>80% vàng, >95% đỏ)
- Badge DNSSEC: hiện Bật/Tắt
- Badge SSL: None / Active / Expired

**Tab Navigation**:
- Tab active có underline đậm, tab khác màu nhạt
- Số lượng hiện trên tab nếu có: `Redirects (3)`, `Email (2)`
- Tab DDNS và DNSSEC chỉ hiện nếu quota plan cho phép (`ddns_enabled`, `dnssec_enabled`)

**Bộ lọc & Tìm kiếm**:
- Dropdown filter theo type (Tất cả / A / AAAA / CNAME / MX / TXT / SRV / NS / CAA)
- Ô search: tìm theo name hoặc value — filter real-time (Alpine.js client-side)
- Nút `[+ Thêm bản ghi]` mở Modal CL-03

**Bảng Records**:
- Cột **Loại**: Badge màu theo type (A=xanh dương, CNAME=tím, MX=cam, TXT=xanh lá, NS=xám)
- Cột **Tên**: Hiện subdomain part. `@` hiển thị là `example.com` (full domain)
- Cột **Giá trị**: Nội dung record. TXT dài thì cắt + tooltip hover xem full. MX/SRV hiện thêm Priority
- Cột **TTL**: Hiện dạng thân thiện: `1h` (3600), `5m` (300), `24h` (86400)
- Cột **Trạng thái** (Alpine.js reactive):
  - 🟢 `Live` — Đã đồng bộ tất cả server
  - 🔄 `Syncing (2/3)` — Đang đồng bộ, hiện số server đã xong
  - 🟡 `Pending` — Chờ xử lý
  - 🔴 `Failed` + nút `[Retry]` nhỏ — Client có thể retry 1 lần
  - ⟳ Spinner animation khi Syncing
- Cột **Actions**:
  - `[✏️]` Sửa — mở Modal CL-03 (pre-fill dữ liệu)
  - `[🗑️]` Xóa — confirm dialog
  - `🔒` Icon khóa cho records is_system hoặc is_locked — không có nút sửa/xóa

**Pagination**: Server-side, 10 records/page mặc định

---

## CL-03: Modal Thêm/Sửa Record

> **Trigger**: Click `[+ Thêm bản ghi]` hoặc `[✏️]` trên bảng  
> **Kiểu**: Bootstrap Modal (overlay, không chuyển trang)

```
┌──────────────────────────────────────────────────────┐
│                                                ╳ Đóng │
│  Thêm bản ghi DNS                                    │
│  ─────────────────                                    │
│                                                       │
│  Loại bản ghi *                                       │
│  [▼ A                                           ]     │
│     ┌─────────────────────────────────────┐           │
│     │ A        — Trỏ tới địa chỉ IPv4    │           │
│     │ AAAA     — Trỏ tới địa chỉ IPv6    │           │
│     │ CNAME    — Bí danh (Alias)          │           │
│     │ MX       — Máy chủ nhận email       │           │
│     │ TXT      — Văn bản (SPF, DKIM, ...) │           │
│     │ SRV      — Dịch vụ (SIP, XMPP,...) │           │
│     │ CAA      — Ủy quyền chứng chỉ SSL  │           │
│     └─────────────────────────────────────┘           │
│                                                       │
│  Tên (Subdomain) *                                    │
│  [____________@___________]  .example.com             │
│  ℹ️ Nhập @ cho domain gốc, * cho wildcard             │
│                                                       │
│  Giá trị *                                            │
│  [__________103.45.67.89__________]                   │
│  ℹ️ Địa chỉ IPv4 (VD: 103.45.67.89)                  │
│  ⚠️ Validation message hiện ở đây nếu sai format      │
│                                                       │
│  ┌─── Hiện khi type = MX hoặc SRV ───────────────┐   │
│  │                                                 │   │
│  │  Priority *        (MX, SRV)                    │   │
│  │  [______10______]                               │   │
│  │  ℹ️ Số nhỏ = ưu tiên cao (VD: 10, 20, 30)      │   │
│  │                                                 │   │
│  │  Weight            (chỉ SRV)                    │   │
│  │  [______0_______]                               │   │
│  │                                                 │   │
│  │  Port *            (chỉ SRV)                    │   │
│  │  [______443_____]                               │   │
│  │                                                 │   │
│  └─────────────────────────────────────────────────┘   │
│                                                       │
│  TTL (Thời gian cache)                                │
│  [▼ 1 giờ (3600)                                ]     │
│     ┌─────────────────────────────────────┐           │
│     │ 1 phút   (60)    — Thay đổi liên tục│           │
│     │ 5 phút   (300)   — DDNS             │           │
│     │ 30 phút  (1800)  — Thường dùng      │           │
│     │ 1 giờ    (3600)  — Mặc định ✓       │           │
│     │ 12 giờ   (43200) — Ít thay đổi      │           │
│     │ 24 giờ   (86400) — Rất ổn định      │           │
│     │ Tùy chỉnh...                         │           │
│     └─────────────────────────────────────┘           │
│                                                       │
│                        [Hủy]  [💾 Lưu bản ghi]       │
│                                                       │
│  ┌─── Toast sau khi lưu thành công ──────────────┐   │
│  │ ✅ Đã lưu! Bản ghi đang được đồng bộ...       │   │
│  └────────────────────────────────────────────────┘   │
└───────────────────────────────────────────────────────┘
```

**Hành vi theo Type**:
- Chọn type → helper text thay đổi (VD: A → "Địa chỉ IPv4", CNAME → "Tên miền đích (FQDN)")
- Trường Priority/Weight/Port chỉ hiện khi MX hoặc SRV
- Validation real-time (Alpine.js): kiểm tra format ngay khi user rời khỏi field
- Khi submit: nút `[💾 Lưu]` chuyển thành spinner → success toast → modal tự đóng → record xuất hiện trong bảng với badge 🟡 Pending

**Khi Sửa (Edit Mode)**:
- Title đổi thành: "Sửa bản ghi DNS"
- Dropdown Type bị disabled (không cho đổi type)
- Trường Name bị disabled (không cho đổi subdomain)
- Chỉ cho sửa Value, TTL, Priority

---

## CL-04: Tab Redirects

> **Vị trí**: Tab thứ 2 trong DNS Editor (CL-02)

```
┌──────────────────────────────────────────────────────────────────┐
│ [DNS Records] [Redirects ③] [Email] [DNSSEC] [DDNS] [Templates] │
│                ═══════════                                        │
│                                                                   │
│  Chuyển hướng URL                          [+ Thêm chuyển hướng] │
│                                                                   │
│  ┌────────┬──────────────────────┬────────┬────────┬───────────┐ │
│  │ Nguồn  │ Đích                 │ Loại   │Tr.thái │           │ │
│  ├────────┼──────────────────────┼────────┼────────┼───────────┤ │
│  │ /      │ https://newsite.com  │ 301    │ 🟢Live │ [✏️] [🗑️] │ │
│  │        │                      │Vĩnh viễn│       │           │ │
│  ├────────┼──────────────────────┼────────┼────────┼───────────┤ │
│  │ /promo │ https://sale.com/vn  │ 302    │ 🟢Live │ [✏️] [🗑️] │ │
│  │        │                      │Tạm thời│        │           │ │
│  ├────────┼──────────────────────┼────────┼────────┼───────────┤ │
│  │ /app   │ https://app.other.io │ Masked │ 🟡     │ [✏️] [🗑️] │ │
│  │        │ Title: "My App"      │Ẩn URL  │Pending │           │ │
│  └────────┴──────────────────────┴────────┴────────┴───────────┘ │
│                                                                   │
│  Đang dùng: 3/5 chuyển hướng                                    │
└──────────────────────────────────────────────────────────────────┘
```

**Modal Thêm/Sửa Redirect**:
```
┌──────────────────────────────────────────────┐
│  Thêm chuyển hướng URL                 ╳ Đóng│
│  ──────────────────                           │
│                                               │
│  Đường dẫn nguồn *                            │
│  example.com [________/________]              │
│  ℹ️ Nhập / cho trang chủ                      │
│                                               │
│  URL đích *                                   │
│  [__https://newsite.com/page__]               │
│                                               │
│  Loại chuyển hướng *                          │
│  (●) 301 — Vĩnh viễn (SEO tốt)              │
│  ( ) 302 — Tạm thời                          │
│  ( ) Masked — Ẩn URL đích                    │
│                                               │
│  ┌─── Hiện khi chọn Masked ──────────────┐   │
│  │  Tiêu đề trang                         │   │
│  │  [__________My Website__________]      │   │
│  │                                         │   │
│  │  Mô tả SEO                             │   │
│  │  [__________Mô tả ngắn__________]     │   │
│  └─────────────────────────────────────────┘   │
│                                               │
│                    [Hủy]  [💾 Lưu]            │
└───────────────────────────────────────────────┘
```

---

## CL-05: Tab Email Forwarding

> **Vị trí**: Tab thứ 3 trong DNS Editor

```
┌──────────────────────────────────────────────────────────────────┐
│ [DNS Records] [Redirects] [Email ②] [DNSSEC] [DDNS] [Templates] │
│                            ═══════                                │
│                                                                   │
│  Chuyển tiếp Email                      [+ Thêm chuyển tiếp]    │
│                                                                   │
│  ┌───────────────────────┬───────────────────────┬──────┬──────┐ │
│  │ Từ                    │ Chuyển đến             │Tr.thái│     │ │
│  ├───────────────────────┼───────────────────────┼──────┼──────┤ │
│  │ info@example.com      │ personal@gmail.com    │🟢Live│[✏️][🗑️]│ │
│  ├───────────────────────┼───────────────────────┼──────┼──────┤ │
│  │ support@example.com   │ team@company.com      │🟢Live│[✏️][🗑️]│ │
│  └───────────────────────┴───────────────────────┴──────┴──────┘ │
│                                                                   │
│  ── Catch-all ──────────────────────────────────────────────────  │
│  [ ] Bật Catch-all: Mọi email khác gửi tới → [_backup@gmail.com_]│
│  ⚠️ Cảnh báo: Bật catch-all sẽ nhận tất cả spam gửi tới domain  │
│                                                                   │
│  Đang dùng: 2/10 chuyển tiếp                                    │
└──────────────────────────────────────────────────────────────────┘
```

---

## CL-06: Tab DNSSEC

> **Vị trí**: Tab DNSSEC trong DNS Editor  
> **Điều kiện hiện**: `quota_plan.dnssec_enabled = true`

```
┌──────────────────────────────────────────────────────────────────┐
│ [DNS Records] [Redirects] [Email] [DNSSEC] [DDNS] [Templates]   │
│                                    ══════                         │
│                                                                   │
│  DNSSEC — Bảo mật phân giải tên miền                            │
│                                                                   │
│  ┌────────────────────────────────────────────────────────────┐  │
│  │  Trạng thái: 🟢 Đã bật                                    │  │
│  │  Ký Zone lần cuối: 25/02/2026 14:30                        │  │
│  │                                                            │  │
│  │                              [🔴 Tắt DNSSEC]              │  │
│  └────────────────────────────────────────────────────────────┘  │
│                                                                   │
│  ── Thông số DS Record ─────────────────────────────────────────  │
│  ℹ️ Sao chép thông tin bên dưới và nhập vào trang quản lý tên    │
│     miền tại nhà đăng ký (VD: VNNIC, GoDaddy, Namecheap)        │
│                                                                   │
│  ┌────────────────┬─────────────────────────────────────────┐    │
│  │ Key Tag        │ 12345                            [Copy] │    │
│  ├────────────────┼─────────────────────────────────────────┤    │
│  │ Algorithm      │ 13 (ECDSA P-256)                 [Copy] │    │
│  ├────────────────┼─────────────────────────────────────────┤    │
│  │ Digest Type    │ 2 (SHA-256)                      [Copy] │    │
│  ├────────────────┼─────────────────────────────────────────┤    │
│  │ Digest         │ 49FD46E6C4B45C55D4AC...          [Copy] │    │
│  ├────────────────┼─────────────────────────────────────────┤    │
│  │ DS Record      │ 12345 13 2 49FD46E6C4B4...       [Copy] │    │
│  │ (đầy đủ)       │                                         │    │
│  └────────────────┴─────────────────────────────────────────┘    │
│                                                                   │
│  [📋 Copy tất cả]                                                │
│                                                                   │
│  ── Hướng dẫn ──────────────────────────────────────────────────  │
│  ┌────────────────────────────────────────────────────────────┐  │
│  │ 📖 Cách cấu hình DNSSEC tại nhà đăng ký:                  │  │
│  │                                                            │  │
│  │ 1. Đăng nhập vào trang quản lý tên miền tại nhà đăng ký  │  │
│  │ 2. Tìm mục DNSSEC / DS Record                             │  │
│  │ 3. Nhập các thông số Key Tag, Algorithm, Digest Type,     │  │
│  │    và Digest ở trên                                        │  │
│  │ 4. Lưu thay đổi — quá trình xác thực có thể mất 24-48h  │  │
│  │                                                            │  │
│  │ ⚠️ LƯU Ý QUAN TRỌNG:                                     │  │
│  │ Nếu muốn TẮT DNSSEC, hãy xóa DS Record tại nhà đăng ký  │  │
│  │ TRƯỚC, chờ 24h, rồi mới tắt tại đây. Nếu tắt ở đây      │  │
│  │ trước khi xóa DS Record → domain sẽ bị lỗi phân giải!    │  │
│  └────────────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────────┘

── Khi DNSSEC chưa bật ──

┌────────────────────────────────────────────────────────────────┐
│  Trạng thái: ⚪ Chưa bật                                      │
│                                                                │
│  DNSSEC bảo vệ domain khỏi tấn công DNS Spoofing bằng cách   │
│  ký số (digital sign) các bản ghi DNS.                         │
│                                                                │
│                         [🟢 Bật DNSSEC]                       │
│                                                                │
│  ℹ️ Sau khi bật, hệ thống sẽ tạo khóa bảo mật trong vài phút.│
│     Bạn cần mang thông số DS Record đến nhà đăng ký để hoàn   │
│     tất quá trình.                                              │
└────────────────────────────────────────────────────────────────┘
```

---

## CL-07: Tab DDNS

> **Vị trí**: Tab DDNS trong DNS Editor  
> **Điều kiện hiện**: `quota_plan.ddns_enabled = true`

```
┌──────────────────────────────────────────────────────────────────┐
│ [DNS Records] [Redirects] [Email] [DNSSEC] [DDNS] [Templates]   │
│                                             ════                  │
│                                                                   │
│  Dynamic DNS — Tự động cập nhật IP                               │
│  ℹ️ Dành cho kết nối Internet IP động (Camera, NAS, VPN Router)   │
│                                                                   │
│  ┌────────────────────────────────────────────────────────────┐  │
│  │                                         [+ Tạo DDNS Token] │  │
│  │                                                            │  │
│  │ ┌──────────┬───────────────┬──────────┬────────┬────────┐ │  │
│  │ │Subdomain │ Nhãn          │ IP hiện tại│Cập nhật│       │ │  │
│  │ ├──────────┼───────────────┼──────────┼────────┼────────┤ │  │
│  │ │cam       │Camera VP HN   │118.70.5.6│ 2 giờ  │[⚙️][🗑️]│ │  │
│  │ │          │               │          │ trước  │        │ │  │
│  │ ├──────────┼───────────────┼──────────┼────────┼────────┤ │  │
│  │ │vpn       │Router Mikrotik│113.22.1.3│ 15 phút│[⚙️][🗑️]│ │  │
│  │ │          │               │          │ trước  │        │ │  │
│  │ └──────────┴───────────────┴──────────┴────────┴────────┘ │  │
│  │                                                            │  │
│  │  Đang dùng: 2/2 token DDNS                                │  │
│  └────────────────────────────────────────────────────────────┘  │
│                                                                   │
│  ── Khi click [⚙️] → Chi tiết Token ────────────────────────────  │
│                                                                   │
│  ┌────────────────────────────────────────────────────────────┐  │
│  │  DDNS Token cho: cam.example.com                           │  │
│  │                                                            │  │
│  │  URL cập nhật:                                             │  │
│  │  ┌──────────────────────────────────────────────────────┐ │  │
│  │  │ https://whmcs.hvn.vn/modules/addons/hvn_dns_manager/ │ │  │
│  │  │ ddns.php?token=a1b2c3d4e5f6...                       │ │  │
│  │  └──────────────────────────────────────────────────────┘ │  │
│  │  [📋 Copy URL]                                             │  │
│  │                                                            │  │
│  │  ── Hướng dẫn cấu hình ───────────────────────────────── │  │
│  │                                                            │  │
│  │  📖 Mikrotik RouterOS:                                     │  │
│  │  ┌──────────────────────────────────────────────────────┐ │  │
│  │  │ /tool fetch url="https://whmcs.hvn.vn/modules/...    │ │  │
│  │  │   /ddns.php?token=a1b2c3d4e5f6" mode=http            │ │  │
│  │  │                                                       │ │  │
│  │  │ # Đặt vào Scheduler chạy mỗi 5 phút                 │ │  │
│  │  └──────────────────────────────────────────────────────┘ │  │
│  │  [📋 Copy lệnh Mikrotik]                                  │  │
│  │                                                            │  │
│  │  📖 DrayTek Vigor:                                         │  │
│  │  ┌──────────────────────────────────────────────────────┐ │  │
│  │  │ Dynamic DNS > Custom Provider                         │ │  │
│  │  │ Server: whmcs.hvn.vn                                  │ │  │
│  │  │ Path: /modules/addons/hvn_dns_manager/ddns.php       │ │  │
│  │  │ Token: a1b2c3d4e5f6...                               │ │  │
│  │  └──────────────────────────────────────────────────────┘ │  │
│  │                                                            │  │
│  │  [🔄 Tạo lại Token]  [🗑️ Xóa Token]                      │  │
│  │  ⚠️ Tạo lại token sẽ vô hiệu hóa token cũ. Bạn cần cấu  │  │
│  │     hình lại trên thiết bị.                                │  │
│  └────────────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────────┘
```

---

## CL-08: Load Template Dialog

> **Trigger**: Click tab `[Templates]` hoặc nút "Nạp mẫu DNS" trong DNS Editor

```
┌──────────────────────────────────────────────────────┐
│  Nạp mẫu DNS                                  ╳ Đóng│
│  ─────────────                                       │
│                                                      │
│  Chọn mẫu DNS để áp dụng cho example.com:           │
│                                                      │
│  (●) Basic DNS                                       │
│      NS + A record mặc định                         │
│      (6 bản ghi)                                     │
│                                                      │
│  ( ) Email Optimized                                 │
│      Bao gồm MX, SPF, DKIM, DMARC                  │
│      (12 bản ghi)                                    │
│                                                      │
│  ( ) Google Workspace                                │
│      MX + SPF + DKIM cho Google                      │
│      (10 bản ghi)                                    │
│                                                      │
│  ┌────────────────────────────────────────────────┐  │
│  │ ⚠️ CẢNH BÁO                                    │  │
│  │                                                │  │
│  │ Thao tác này sẽ XÓA TOÀN BỘ bản ghi DNS      │  │
│  │ hiện tại và thay bằng mẫu đã chọn.            │  │
│  │                                                │  │
│  │ Hệ thống sẽ tự động tạo bản sao lưu trước    │  │
│  │ khi thay đổi. Liên hệ Support nếu cần khôi   │  │
│  │ phục.                                          │  │
│  │                                                │  │
│  │ [✓] Tôi hiểu và muốn tiếp tục                │  │
│  └────────────────────────────────────────────────┘  │
│                                                      │
│              [Hủy]  [⚡ Áp dụng mẫu]                │
│                      (disabled nếu chưa tick)        │
└──────────────────────────────────────────────────────┘
```

---

# ADMIN AREA — Giao diện Quản trị viên

---

## AD-01: Dashboard

> **URL**: `/admin/addonmodules.php?module=hvn_dns_manager`  
> **Mục đích**: Tổng quan sức khỏe hệ thống, metrics real-time, cảnh báo nhanh  
> **Đây là trang đầu tiên Admin thấy khi mở module**

```
╔══════════════════════════════════════════════════════════════════════════════╗
║  WHMCS Admin Sidebar    │  HVN - DirectAdmin DNS Manager                    ║
║  ─────────────────      │  ═══════════════════════════════                   ║
║                         │                                                    ║
║  📊 Dashboard          │  ┌─── Alert Banner (chỉ hiện khi có sự cố) ────┐ ║
║  🖥️ Servers            │  │ 🔴 CẢNH BÁO: dns3.hvn.vn mất kết nối từ   │ ║
║  🌐 Domains            │  │    14:30 — 7 job FAILED liên tiếp.           │ ║
║  📋 Sync Logs          │  │    [Xem chi tiết] [Retry All] [Dismiss]      │ ║
║  🔍 Audit Trail        │  └──────────────────────────────────────────────┘ ║
║  📝 Templates          │                                                    ║
║  📦 Quota Plans        │  ┌─────────────────────────────────────────────┐  ║
║  🔄 Drift Reports      │  │          Sync Pipeline — 24 giờ qua         │  ║
║  ⚡ Bulk Operations    │  │                                              │  ║
║  ⚙️ Settings           │  │  ┌──────────┐ ┌──────────┐ ┌──────────┐   │  ║
║                         │  │  │  ✅ 1,247  │ │  ⏳  23   │ │  ❌  12   │   │  ║
║                         │  │  │ Complete  │ │ Pending  │ │  Failed  │   │  ║
║                         │  │  └──────────┘ └──────────┘ └──────────┘   │  ║
║                         │  │                                              │  ║
║                         │  │  ▁▂▃▄▅▆▇█▇▆▅▄▃▂▁▂▃▅▆▇  (sparkline chart) │  ║
║                         │  └─────────────────────────────────────────────┘  ║
║                         │                                                    ║
║                         │  ┌──────────────────────┐ ┌─────────────────────┐ ║
║                         │  │  Server Health        │ │  Tổng quan          │ ║
║                         │  │                       │ │                     │ ║
║                         │  │ 🟢 dns1.hvn.vn       │ │ 🌐 Domains:   342  │ ║
║                         │  │    99.8% ∙ 45ms avg  │ │ 📝 Records: 6,840  │ ║
║                         │  │    12 pending         │ │                     │ ║
║                         │  │                       │ │ Top thay đổi 7 ngày│ ║
║                         │  │ 🟢 dns2.hvn.vn       │ │ 1. example.com  45 │ ║
║                         │  │    99.5% ∙ 52ms avg  │ │ 2. shop.vn      38 │ ║
║                         │  │    12 pending         │ │ 3. myblog.net   22 │ ║
║                         │  │                       │ │ 4. test.org     15 │ ║
║                         │  │ 🔴 dns3.hvn.vn       │ │ 5. demo.io      12 │ ║
║                         │  │    97.1% ∙ timeout    │ │                     │ ║
║                         │  │    7 failed ⚠️        │ │                     │ ║
║                         │  │    [Test] [Disable]   │ │                     │ ║
║                         │  └──────────────────────┘ └─────────────────────┘ ║
║                         │                                                    ║
║                         │  ┌────────────────────────────────────────────┐   ║
║                         │  │  Hoạt động gần đây                         │   ║
║                         │  │                                             │   ║
║                         │  │  14:32  ❌ DELETE_RECORD  myblog.net        │   ║
║                         │  │         → dns3.hvn.vn  timeout              │   ║
║                         │  │  14:31  ✅ ADD_RECORD     shop.vn           │   ║
║                         │  │         → dns1,dns2,dns3  complete          │   ║
║                         │  │  14:30  ✅ EDIT_RECORD    example.com       │   ║
║                         │  │         → dns1,dns2,dns3  complete          │   ║
║                         │  │  14:28  ⚠️ ENABLE_DNSSEC test.org          │   ║
║                         │  │         → dns3.hvn.vn  retrying...          │   ║
║                         │  │                                             │   ║
║                         │  │  «Xem tất cả Sync Logs →»                  │   ║
║                         │  └────────────────────────────────────────────┘   ║
╚══════════════════════════════════════════════════════════════════════════════╝
```

**Chi tiết**:
- **Alert Banner**: chỉ hiện khi có FAILED rate > 20% hoặc server unreachable. Persistent trên mọi trang admin của module cho đến khi Dismiss hoặc resolved
- **Sync Pipeline**: 3 widget số lớn + sparkline chart (Chart.js) hiện lưu lượng job theo giờ
- **Server Health**: card cho mỗi server với uptime %, average response time, số pending jobs. Server có vấn đề highlight đỏ + nút action nhanh
- **Hoạt động gần đây**: 10 dòng mới nhất từ sync_logs, auto-refresh mỗi 30 giây
- **Sidebar**: navigation cố định cho tất cả trang admin của module

---

## AD-02: Server Management

> **URL**: `?module=hvn_dns_manager&action=servers`

```
╔═══════════════════════════════════════════════════════════════════════╗
║  Sidebar │  Quản lý Server DirectAdmin              [+ Thêm Server] ║
║          │  ═══════════════════════════                               ║
║          │                                                            ║
║          │  ┌─────────────────────────────────────────────────────┐  ║
║          │  │ 🟢 dns1.hvn.vn                          Primary    │  ║
║          │  │    IP: 103.xx.xx.10  │  Port: 2222  │  SSL: ✅     │  ║
║          │  │    Max concurrent: 50                               │  ║
║          │  │    ──────────────────────────────────────           │  ║
║          │  │    Uptime: 99.8%  │  Avg: 45ms  │  Last OK: 2 min │  ║
║          │  │    Pending: 12    │  Today: 425 complete            │  ║
║          │  │                                                     │  ║
║          │  │    [🔌 Test Connection]  [✏️ Sửa]  [⏸️ Disable]    │  ║
║          │  ├─────────────────────────────────────────────────────┤  ║
║          │  │ 🟢 dns2.hvn.vn                          Secondary  │  ║
║          │  │    IP: 103.xx.xx.11  │  Port: 2222  │  SSL: ✅     │  ║
║          │  │    Max concurrent: 50                               │  ║
║          │  │    ──────────────────────────────────────           │  ║
║          │  │    Uptime: 99.5%  │  Avg: 52ms  │  Last OK: 2 min │  ║
║          │  │    Pending: 12    │  Today: 423 complete            │  ║
║          │  │                                                     │  ║
║          │  │    [🔌 Test Connection]  [✏️ Sửa]  [⏸️ Disable]    │  ║
║          │  ├─────────────────────────────────────────────────────┤  ║
║          │  │ 🔴 dns3.hvn.vn                          Secondary  │  ║
║          │  │    IP: 103.xx.xx.12  │  Port: 2222  │  SSL: ✅     │  ║
║          │  │    Max concurrent: 50                               │  ║
║          │  │    ──────────────────────────────────────           │  ║
║          │  │    ⚠️ BACKOFF: retry lúc 14:48 (4 phút nữa)       │  ║
║          │  │    Failed: 7 liên tiếp  │  Last error: timeout     │  ║
║          │  │    Error: Connection timed out after 15000ms        │  ║
║          │  │                                                     │  ║
║          │  │    [🔌 Test Connection]  [✏️ Sửa]  [⏸️ Disable]    │  ║
║          │  │    [🔄 Reset Backoff]                               │  ║
║          │  └─────────────────────────────────────────────────────┘  ║
║          │                                                            ║
║          │  Ghi chú: Disable server sẽ dừng fan-out job mới tới      ║
║          │  server đó. Job PENDING hiện tại sẽ chuyển CANCELLED.     ║
╚═══════════════════════════════════════════════════════════════════════╝
```

---

## AD-03: Modal Thêm/Sửa Server

```
┌────────────────────────────────────────────────────────┐
│  Thêm Server DirectAdmin                         ╳ Đóng│
│  ─────────────────────                                  │
│                                                         │
│  Hostname *                                             │
│  [__________dns4.hvn.vn__________]                      │
│  ℹ️ Tên hiển thị cho khách hàng (không hiện IP)         │
│                                                         │
│  Địa chỉ IP *                                          │
│  [__________103.xx.xx.13__________]                     │
│                                                         │
│  Port *                     Sử dụng SSL                 │
│  [____2222____]             [✓] HTTPS                   │
│                                                         │
│  ── Thông tin đăng nhập DA ──                           │
│                                                         │
│  Username *                                             │
│  [__________admin__________]                            │
│                                                         │
│  Password *                                             │
│  [__________••••••••__________]  👁️                     │
│  🔒 Mật khẩu được mã hóa AES-256 trước khi lưu        │
│                                                         │
│  ── Cấu hình ──                                         │
│                                                         │
│  Vai trò *                                              │
│  (●) Secondary    ( ) Primary                           │
│  ℹ️ Primary dùng cho Drift Detection. Chỉ nên có 1     │
│                                                         │
│  Max Concurrent Jobs *                                  │
│  [____50____]                                           │
│  ℹ️ Số job tối đa xử lý mỗi chu kỳ cron cho server này│
│                                                         │
│  Ghi chú                                                │
│  [__________________________________________]           │
│  [__________________________________________]           │
│                                                         │
│  ┌────────────────────────────────────────────────────┐ │
│  │ 🔌 Kết quả Test Connection:                        │ │
│  │                                                    │ │
│  │ ✅ Kết nối thành công!                             │ │
│  │    DirectAdmin v1.65.0                             │ │
│  │    Latency: 42ms                                   │ │
│  │    DNS Zones: 156                                  │ │
│  │    DNSSEC: Enabled                                 │ │
│  └────────────────────────────────────────────────────┘ │
│                                                         │
│          [🔌 Test Connection]  [Hủy]  [💾 Lưu Server]  │
└─────────────────────────────────────────────────────────┘
```

---

## AD-04: Global Domain List

> **URL**: `?module=hvn_dns_manager&action=domains`

```
╔══════════════════════════════════════════════════════════════════════════════╗
║  Sidebar │  Quản lý Domain                                                  ║
║          │  ═══════════════                                                  ║
║          │                                                                   ║
║          │  ┌──────────────────────────────────────────────────────────┐    ║
║          │  │ Tìm kiếm: [________________🔍________________]          │    ║
║          │  │                                                          │    ║
║          │  │ Bộ lọc:                                                  │    ║
║          │  │ [▼ Tất cả trạng thái]  [▼ Tất cả server]               │    ║
║          │  │ [▼ Tất cả gói quota]   [ ] Chỉ domain có lỗi          │    ║
║          │  └──────────────────────────────────────────────────────────┘    ║
║          │                                                                   ║
║          │  ┌───────────────┬───────────┬──────┬────────┬──────┬──────┐    ║
║          │  │Domain         │Khách hàng │Record│Sync    │Trạng │      │    ║
║          │  │               │           │      │gần nhất│thái  │      │    ║
║          │  ├───────────────┼───────────┼──────┼────────┼──────┼──────┤    ║
║          │  │«example.com»  │Nguyễn A   │ 15   │ 2 phút │🟢    │[DNS] │    ║
║          │  │               │#1234      │      │        │      │      │    ║
║          │  ├───────────────┼───────────┼──────┼────────┼──────┼──────┤    ║
║          │  │«shop.vn»      │Trần B     │ 8    │ 5 phút │🟢    │[DNS] │    ║
║          │  │               │#1235      │      │        │      │      │    ║
║          │  ├───────────────┼───────────┼──────┼────────┼──────┼──────┤    ║
║          │  │«myblog.net»   │Lê C       │ 3    │ 1 giờ  │🟡    │[DNS] │    ║
║          │  │               │#1236      │      │ ⚠️2 fail│Sync  │      │    ║
║          │  ├───────────────┼───────────┼──────┼────────┼──────┼──────┤    ║
║          │  │«old-site.org» │Phạm D     │ 22   │ 3 ngày │🔴    │[DNS] │    ║
║          │  │               │#1237      │      │ Susp.  │Susp. │      │    ║
║          │  └───────────────┴───────────┴──────┴────────┴──────┴──────┘    ║
║          │                                                                   ║
║          │  Hiển thị 1-4 / 342 domain     10 ▼    ◄ 1 2 3 ... 35 ►        ║
╚══════════════════════════════════════════════════════════════════════════════╝
```

**Hành vi**:
- Click `«domain»` hoặc `[DNS]` → mở AD-05 (Admin DNS Editor)
- Click tên khách hàng → mở profile client WHMCS
- Server-side pagination + search cho 5000+ domains
- Cột "Sync gần nhất" highlight đỏ nếu có job FAILED

---

## AD-05: Admin DNS Editor

> **Giống CL-02** nhưng có thêm quyền Admin:

```
┌──────────────────────────────────────────────────────────────────┐
│  🔧 ADMIN MODE — Đang quản lý thay cho: Nguyễn A (#1234)       │
│  ──────────────────────────────────────────────────────────────  │
│                                                                   │
│  (Giống layout CL-02 nhưng thêm các quyền sau)                  │
│                                                                   │
│  Khác biệt so với Client:                                        │
│  ┌────────────────────────────────────────────────────────────┐  │
│  │ ✅ Không bị rate limit (30 changes/min)                    │  │
│  │ ✅ Có thể sửa/xóa record is_system (NS, SOA)             │  │
│  │ ✅ Có thể lock/unlock record cho Client                   │  │
│  │ ✅ Conflict Resolution: Admin-Priority (override Client)  │  │
│  │ ✅ Nút [📸 Tạo Snapshot] tạo bản sao zone thủ công       │  │
│  │ ✅ Nút [⏪ Rollback Zone] khôi phục từ snapshot           │  │
│  │ ✅ Xem và quản lý tất cả tabs (kể cả khi quota disabled) │  │
│  └────────────────────────────────────────────────────────────┘  │
│                                                                   │
│  ── Toolbar Admin (phía trên bảng records) ──                    │
│                                                                   │
│  [+ Thêm bản ghi] [📸 Snapshot] [⏪ Rollback] [📋 Xem History]  │
│                                                                   │
│  ── Cột Actions mở rộng ──                                       │
│                                                                   │
│  │ ... │ 🟢Live │ [✏️] [🗑️] [🔒Lock] │    (thêm nút Lock)     │
│  │ ... │ 🟢Live │ [✏️] [🗑️] [🔓Unlock]│   (record đang locked) │
│                                                                   │
└──────────────────────────────────────────────────────────────────┘

── Rollback Dialog ──

┌────────────────────────────────────────────────────────┐
│  Khôi phục Zone DNS — example.com                ╳ Đóng│
│  ─────────────────────────────                          │
│                                                         │
│  Chọn bản sao để khôi phục:                            │
│                                                         │
│  (●) 25/02/2026 02:00 — Nightly backup (15 records)   │
│  ( ) 24/02/2026 02:00 — Nightly backup (14 records)   │
│  ( ) 23/02/2026 15:30 — Before template load (12 rec) │
│  ( ) 23/02/2026 02:00 — Nightly backup (12 records)   │
│                                                         │
│  ── Preview thay đổi ──                                 │
│                                                         │
│  So sánh: Hiện tại (15 records) → Snapshot (15 records)│
│                                                         │
│  🟢 Giữ nguyên: 13 records                             │
│  🔴 Sẽ xóa:     2 records                              │
│     - A  test  →  1.2.3.4                               │
│     - TXT  _verify  →  google-site-verif...             │
│  🟡 Sẽ sửa:     0 records                              │
│  🔵 Sẽ thêm:    0 records                              │
│                                                         │
│  ⚠️ Thao tác này không thể hoàn tác. Snapshot hiện     │
│     tại sẽ được tạo trước khi rollback.                 │
│                                                         │
│               [Hủy]  [⏪ Xác nhận Rollback]            │
└─────────────────────────────────────────────────────────┘
```

---

## AD-06: Sync Logs

> **URL**: `?module=hvn_dns_manager&action=sync_logs`

```
╔══════════════════════════════════════════════════════════════════════════════╗
║  Sidebar │  Lịch sử Đồng bộ                        [📥 Export CSV/Excel]  ║
║          │  ════════════════                                                ║
║          │                                                                   ║
║          │  ┌──────────────────────────────────────────────────────────┐    ║
║          │  │ Bộ lọc nâng cao:                                         │    ║
║          │  │                                                          │    ║
║          │  │ [▼ Tất cả status]  [▼ Tất cả server]  [▼ Tất cả action]│    ║
║          │  │ Domain: [____________]                                    │    ║
║          │  │ Từ: [📅 25/02/2026] Đến: [📅 25/02/2026]               │    ║
║          │  │                                        [🔍 Lọc] [↺ Reset]│    ║
║          │  └──────────────────────────────────────────────────────────┘    ║
║          │                                                                   ║
║          │  [🔄 Retry All Failed (12 jobs)]                                 ║
║          │                                                                   ║
║          │  ┌──────┬──────────┬───────────┬──────────┬──────┬────┬──────┐  ║
║          │  │Thời  │Domain    │Action     │Server    │Status│ ms │      │  ║
║          │  │gian  │          │           │          │      │    │      │  ║
║          │  ├──────┼──────────┼───────────┼──────────┼──────┼────┼──────┤  ║
║          │  │14:32 │myblog.net│DELETE_REC │dns3.hvn  │ ❌   │ -- │[Retry│  ║
║          │  │      │          │A @ 1.2.3.4│.vn       │tmout │    │ 🔍]  │  ║
║          │  ├──────┼──────────┼───────────┼──────────┼──────┼────┼──────┤  ║
║          │  │14:31 │shop.vn   │ADD_RECORD │dns1.hvn  │ ✅   │ 89 │[ 🔍]│  ║
║          │  │      │          │A mail     │.vn       │      │    │      │  ║
║          │  ├──────┼──────────┼───────────┼──────────┼──────┼────┼──────┤  ║
║          │  │14:31 │shop.vn   │ADD_RECORD │dns2.hvn  │ ✅   │ 92 │[ 🔍]│  ║
║          │  │      │          │A mail     │.vn       │      │    │      │  ║
║          │  ├──────┼──────────┼───────────┼──────────┼──────┼────┼──────┤  ║
║          │  │14:31 │shop.vn   │ADD_RECORD │dns3.hvn  │ ❌   │ -- │[Retry│  ║
║          │  │      │          │A mail     │.vn       │tmout │    │ 🔍]  │  ║
║          │  └──────┴──────────┴───────────┴──────────┴──────┴────┴──────┘  ║
║          │                                                                   ║
║          │  ── Click 🔍 → Detail Panel ──                                   ║
║          │                                                                   ║
║          │  ┌────────────────────────────────────────────────────────────┐  ║
║          │  │  Job #4521 — Chi tiết                                      │  ║
║          │  │                                                            │  ║
║          │  │  Domain:      myblog.net                                   │  ║
║          │  │  Action:      DELETE_RECORD                                │  ║
║          │  │  Payload:     {"type":"A","name":"@","value":"1.2.3.4"}   │  ║
║          │  │  Server:      dns3.hvn.vn (103.xx.xx.12:2222)            │  ║
║          │  │  Status:      FAILED (attempt 3/5)                        │  ║
║          │  │  Error:       Connection timed out after 15000ms          │  ║
║          │  │  Next retry:  14:48 (16 phút)                            │  ║
║          │  │  Batch:       abc-123-def (2/3 complete)                  │  ║
║          │  │  Actor:       Client #1236 (Lê C) from 118.70.xx.xx     │  ║
║          │  │  Created:     25/02/2026 14:30:15                        │  ║
║          │  │                                                            │  ║
║          │  │  DA Response: (empty — timeout before response)           │  ║
║          │  │                                                            │  ║
║          │  │  [🔄 Retry Now]  [❌ Cancel Job]  [📋 Copy Debug Info]   │  ║
║          │  └────────────────────────────────────────────────────────────┘  ║
╚══════════════════════════════════════════════════════════════════════════════╝
```

---

## AD-07: Audit Trail

> **URL**: `?module=hvn_dns_manager&action=audit_trail`

```
╔══════════════════════════════════════════════════════════════════════════════╗
║  Sidebar │  Nhật ký Kiểm toán                   [📥 Export CSV] [📥 PDF]  ║
║          │  ═══════════════════                                              ║
║          │                                                                   ║
║          │  ┌──────────────────────────────────────────────────────────┐    ║
║          │  │ Bộ lọc:                                                  │    ║
║          │  │ [▼ Tất cả actor]  [▼ Tất cả action]  Domain:[________] │    ║
║          │  │ IP: [____________]                                        │    ║
║          │  │ Từ: [📅 ________] Đến: [📅 ________]                    │    ║
║          │  └──────────────────────────────────────────────────────────┘    ║
║          │                                                                   ║
║          │  ┌──────┬────────┬──────────┬───────────┬──────────┬──────┐     ║
║          │  │Thời  │Ai      │Domain    │Hành động  │Chi tiết  │  IP  │     ║
║          │  │gian  │        │          │           │          │      │     ║
║          │  ├──────┼────────┼──────────┼───────────┼──────────┼──────┤     ║
║          │  │14:32 │👤Client│myblog.net│delete_    │A @ →     │118.70│     ║
║          │  │      │Lê C    │          │record     │1.2.3.4   │.xx.xx│     ║
║          │  ├──────┼────────┼──────────┼───────────┼──────────┼──────┤     ║
║          │  │14:30 │🔧Admin │example   │edit_      │A mail:   │10.0. │     ║
║          │  │      │Vuong   │.com      │record     │.3→.4    │0.1   │     ║
║          │  │      │        │          │           │Overridden│      │     ║
║          │  ├──────┼────────┼──────────┼───────────┼──────────┼──────┤     ║
║          │  │14:28 │⚙️Sys  │test.org  │enable_    │DNSSEC on │WHMCS │     ║
║          │  │      │Cron    │          │dnssec     │          │server│     ║
║          │  ├──────┼────────┼──────────┼───────────┼──────────┼──────┤     ║
║          │  │14:25 │🔌API  │cam       │ddns_      │IP:       │118.70│     ║
║          │  │      │DDNS    │.shop.vn  │update     │.5→.6    │.5.6  │     ║
║          │  └──────┴────────┴──────────┴───────────┴──────────┴──────┘     ║
║          │                                                                   ║
║          │  ── Click dòng → Popup chi tiết ──                               ║
║          │                                                                   ║
║          │  ┌────────────────────────────────────────────────────────────┐  ║
║          │  │  Audit Entry #89201                                        │  ║
║          │  │                                                            │  ║
║          │  │  Actor:       Admin Vuong (#2)                             │  ║
║          │  │  Context:     admin_editor                                 │  ║
║          │  │  Domain:      example.com                                  │  ║
║          │  │  Action:      edit_record                                  │  ║
║          │  │  Target:      Record #456 (A mail)                         │  ║
║          │  │                                                            │  ║
║          │  │  Giá trị cũ:  {"value": "103.45.67.90", "ttl": 3600}     │  ║
║          │  │  Giá trị mới: {"value": "103.45.67.91", "ttl": 3600}     │  ║
║          │  │                                                            │  ║
║          │  │  IP:          10.0.0.1                                     │  ║
║          │  │  User Agent:  Mozilla/5.0 (Windows NT 10.0...)            │  ║
║          │  │  Session:     whmcs_sess_abc123                            │  ║
║          │  │  Notes:       Overridden by Admin — cancelled client job  │  ║
║          │  │  Thời gian:   25/02/2026 14:30:22                        │  ║
║          │  └────────────────────────────────────────────────────────────┘  ║
╚══════════════════════════════════════════════════════════════════════════════╝
```

---

## AD-08: Template Manager

> **URL**: `?module=hvn_dns_manager&action=templates`

```
╔═══════════════════════════════════════════════════════════════════════╗
║  Sidebar │  Quản lý DNS Template                    [+ Tạo Template] ║
║          │  ════════════════════                                      ║
║          │                                                            ║
║          │  ┌─────────────────────────────────────────────────────┐  ║
║          │  │  ⭐ Basic DNS                           [DEFAULT]   │  ║
║          │  │  NS + A record mặc định                             │  ║
║          │  │  6 bản ghi  │  Hiển thị Client: ✅                  │  ║
║          │  │                         [✏️ Sửa] [📋 Clone] [🗑️]   │  ║
║          │  ├─────────────────────────────────────────────────────┤  ║
║          │  │  📧 Email Optimized                                 │  ║
║          │  │  MX + SPF + DKIM + DMARC                            │  ║
║          │  │  12 bản ghi  │  Hiển thị Client: ✅                 │  ║
║          │  │                  [⭐ Set Default] [✏️] [📋] [🗑️]   │  ║
║          │  ├─────────────────────────────────────────────────────┤  ║
║          │  │  🔧 Internal Only                                    │  ║
║          │  │  Template nội bộ cho test                            │  ║
║          │  │  4 bản ghi  │  Hiển thị Client: ❌                  │  ║
║          │  │                  [⭐ Set Default] [✏️] [📋] [🗑️]   │  ║
║          │  └─────────────────────────────────────────────────────┘  ║
║          │                                                            ║
║          │  ── Template Editor (khi click ✏️) ──                     ║
║          │                                                            ║
║          │  ┌─────────────────────────────────────────────────────┐  ║
║          │  │  Sửa Template: Basic DNS                            │  ║
║          │  │                                                     │  ║
║          │  │  Tên: [______Basic DNS______]                       │  ║
║          │  │  Mô tả: [______NS + A record mặc định______]      │  ║
║          │  │  [✓] Hiển thị cho Client                            │  ║
║          │  │                                                     │  ║
║          │  │  Bản ghi trong template:                            │  ║
║          │  │  ┌─────┬──────┬────────────────────┬───────┐       │  ║
║          │  │  │Type │Name  │Value               │TTL    │       │  ║
║          │  │  ├─────┼──────┼────────────────────┼───────┤       │  ║
║          │  │  │ NS  │ @    │ dns1.hvn.vn.       │ 86400 │ [🗑️] │  ║
║          │  │  │ NS  │ @    │ dns2.hvn.vn.       │ 86400 │ [🗑️] │  ║
║          │  │  │ NS  │ @    │ dns3.hvn.vn.       │ 86400 │ [🗑️] │  ║
║          │  │  │ A   │ @    │ {{ip}}             │ 3600  │ [🗑️] │  ║
║          │  │  │ A   │ www  │ {{ip}}             │ 3600  │ [🗑️] │  ║
║          │  │  │ MX  │ @    │ mail.{{domain}}.   │ 3600  │ [🗑️] │  ║
║          │  │  └─────┴──────┴────────────────────┴───────┘       │  ║
║          │  │                                                     │  ║
║          │  │  [+ Thêm record]                                    │  ║
║          │  │                                                     │  ║
║          │  │  Placeholders có thể dùng:                          │  ║
║          │  │  {{domain}} = tên miền thực                         │  ║
║          │  │  {{ip}}     = IP mặc định của domain                │  ║
║          │  │  {{ns1}}    = dns1.hvn.vn                           │  ║
║          │  │  {{ns2}}    = dns2.hvn.vn                           │  ║
║          │  │  {{ns3}}    = dns3.hvn.vn                           │  ║
║          │  │                                                     │  ║
║          │  │              [Hủy]  [💾 Lưu Template]               │  ║
║          │  └─────────────────────────────────────────────────────┘  ║
╚═══════════════════════════════════════════════════════════════════════╝
```

---

## AD-09: Quota Plans

> **URL**: `?module=hvn_dns_manager&action=quota_plans`

```
╔═══════════════════════════════════════════════════════════════════════════╗
║  Sidebar │  Quản lý Gói Quota                            [+ Tạo Gói]   ║
║          │  ═════════════════                                            ║
║          │                                                                ║
║          │  ┌─────────┬────────┬──────┬──────┬──────┬──────┬──────┬───┐ ║
║          │  │Tên gói  │Records │Subdom│Redir │Email │DDNS  │DNSSEC│SSL│ ║
║          │  ├─────────┼────────┼──────┼──────┼──────┼──────┼──────┼───┤ ║
║          │  │Basic    │   20   │  10  │  2   │  5   │  ❌  │  ❌  │ ❌│ ║
║          │  │         │        │      │      │      │      │      │[✏️]│ ║
║          │  ├─────────┼────────┼──────┼──────┼──────┼──────┼──────┼───┤ ║
║          │  │Pro      │   50   │  20  │  5   │  10  │  ✅  │  ❌  │ ✅│ ║
║          │  │         │        │      │      │  2tk │      │      │[✏️]│ ║
║          │  ├─────────┼────────┼──────┼──────┼──────┼──────┼──────┼───┤ ║
║          │  │Enterpr. │   ∞    │  ∞   │  ∞   │  ∞   │  ✅  │  ✅  │ ✅│ ║
║          │  │         │        │      │      │  5tk │      │      │[✏️]│ ║
║          │  └─────────┴────────┴──────┴──────┴──────┴──────┴──────┴───┘ ║
║          │                                                                ║
║          │  ℹ️ ∞ = Không giới hạn (giá trị 0 trong DB)                   ║
║          │  ℹ️ Map Quota Plan vào WHMCS Product trong cấu hình Product   ║
╚═══════════════════════════════════════════════════════════════════════════╝
```

---

## AD-10: Drift Reports

> **URL**: `?module=hvn_dns_manager&action=drift_reports`

```
╔═══════════════════════════════════════════════════════════════════════════╗
║  Sidebar │  Báo cáo Lệch Dữ liệu                                       ║
║          │  ══════════════════════                                        ║
║          │                                                                ║
║          │  Lần scan gần nhất: 25/02/2026 02:15  │  Kế tiếp: 26/02 02:00║
║          │  [▼ Tất cả]  [▼ Chỉ Pending]                                 ║
║          │                                                                ║
║          │  ⚠️ 3 domain có dữ liệu lệch cần xử lý                      ║
║          │                                                                ║
║          │  ┌─── example.com (2 bản ghi lệch) ───────────────────────┐  ║
║          │  │                                                         │  ║
║          │  │  ❓ added_on_da — A test2 → 5.6.7.8                    │  ║
║          │  │     Có trên DA, không có trong WHMCS                    │  ║
║          │  │     [Pull DA→WHMCS]  [Xóa trên DA]  [Bỏ qua]          │  ║
║          │  │                                                         │  ║
║          │  │  ❓ modified — TXT @ SPF record                         │  ║
║          │  │     WHMCS: v=spf1 include:_spf.google.com ~all         │  ║
║          │  │     DA:    v=spf1 include:_spf.zoho.com ~all           │  ║
║          │  │     [Pull DA→WHMCS]  [Push WHMCS→DA]  [Bỏ qua]        │  ║
║          │  │                                                         │  ║
║          │  └─────────────────────────────────────────────────────────┘  ║
║          │                                                                ║
║          │  ┌─── shop.vn (1 bản ghi lệch) ───────────────────────────┐  ║
║          │  │                                                         │  ║
║          │  │  ❓ missing_on_da — CNAME ftp → shop.vn.                │  ║
║          │  │     Có trong WHMCS, không có trên DA                    │  ║
║          │  │     [Push WHMCS→DA]  [Xóa trong WHMCS]  [Bỏ qua]      │  ║
║          │  │                                                         │  ║
║          │  └─────────────────────────────────────────────────────────┘  ║
║          │                                                                ║
║          │  ── Cài đặt Auto-fix ──                                       ║
║          │  [ ] Tự động đẩy WHMCS → DA khi phát hiện drift              ║
║          │      (WHMCS là Source of Truth, ghi đè DA mỗi đêm)           ║
╚═══════════════════════════════════════════════════════════════════════════╝
```

---

## AD-11: Bulk Operations

> **URL**: `?module=hvn_dns_manager&action=bulk`

```
╔═══════════════════════════════════════════════════════════════════════════╗
║  Sidebar │  Thao tác Hàng loạt                                           ║
║          │  ══════════════════                                            ║
║          │                                                                ║
║          │  Chọn thao tác:                                               ║
║          │  (●) Thay đổi IP hàng loạt                                    ║
║          │  ( ) Áp dụng Template hàng loạt                                ║
║          │                                                                ║
║          │  ── Thay đổi IP hàng loạt ──                                  ║
║          │                                                                ║
║          │  IP cũ: [______103.45.67.89______]                            ║
║          │  IP mới: [______103.45.67.100______]                          ║
║          │                                                                ║
║          │  Phạm vi:                                                      ║
║          │  (●) Tất cả domain         ( ) Chọn thủ công                  ║
║          │  ( ) Domain trên server: [▼ dns1.hvn.vn]                      ║
║          │                                                                ║
║          │  [🔍 Quét & Preview]                                          ║
║          │                                                                ║
║          │  ── Preview kết quả ──                                        ║
║          │                                                                ║
║          │  Tìm thấy 23 bản ghi A chứa IP 103.45.67.89 trên 15 domain: ║
║          │                                                                ║
║          │  [✓] example.com     — 3 records (A @, A www, A mail)        ║
║          │  [✓] shop.vn         — 2 records (A @, A www)                ║
║          │  [✓] myblog.net      — 1 record  (A @)                       ║
║          │  [✓] ... (12 domain nữa)                                      ║
║          │                                                                ║
║          │  Tổng: 23 bản ghi trên 15 domain sẽ được thay đổi            ║
║          │  ⚠️ Hệ thống sẽ tự tạo Snapshot cho tất cả domain trước     ║
║          │     khi thực hiện.                                             ║
║          │                                                                ║
║          │  [Hủy]  [⚡ Thực hiện thay đổi]                              ║
║          │                                                                ║
║          │  ── Sau khi thực hiện ──                                      ║
║          │                                                                ║
║          │  ┌────────────────────────────────────────────────┐           ║
║          │  │  Tiến trình: ████████████░░░░░░ 12/15 domain   │           ║
║          │  │  ✅ 10 thành công  ⟳ 2 đang xử lý  ❌ 0 lỗi  │           ║
║          │  │                                     [Dừng lại]  │           ║
║          │  └────────────────────────────────────────────────┘           ║
╚═══════════════════════════════════════════════════════════════════════════╝
```

---

## AD-12: Notification Settings

> **URL**: `?module=hvn_dns_manager&action=settings` (tab Notifications)

```
╔═══════════════════════════════════════════════════════════════════════╗
║  Sidebar │  Cài đặt Module                                          ║
║          │  ══════════════                                           ║
║          │                                                            ║
║          │  [Chung] [Thông báo] [Cron] [Bảo trì]                    ║
║          │           ═════════                                        ║
║          │                                                            ║
║          │  ── Telegram ──                                            ║
║          │                                                            ║
║          │  [✓] Bật thông báo Telegram                               ║
║          │                                                            ║
║          │  Bot Token *                                               ║
║          │  [____________••••••••••____________]                       ║
║          │                                                            ║
║          │  Chat ID *                                                 ║
║          │  [____________-1001234567890____________]                   ║
║          │  ℹ️ Nhóm Telegram hoặc cá nhân                            ║
║          │                                                            ║
║          │  [📬 Gửi tin nhắn test]                                    ║
║          │  ✅ Đã gửi thành công lúc 14:35!                          ║
║          │                                                            ║
║          │  ── Email ──                                               ║
║          │                                                            ║
║          │  [✓] Bật thông báo Email                                  ║
║          │                                                            ║
║          │  Danh sách email nhận:                                     ║
║          │  [_admin@hvn.vn, devops@hvn.vn_]                          ║
║          │  ℹ️ Nhiều email phân tách bằng dấu phẩy                   ║
║          │                                                            ║
║          │  ── Quy tắc cảnh báo ──                                   ║
║          │                                                            ║
║          │  [✓] Server fail ≥ [_5_] job liên tiếp   Cooldown: [_15_] phút ║
║          │  [✓] Server mất kết nối ≥ [_3_] lần      Cooldown: [_15_] phút ║
║          │  [✓] Queue tồn đọng > [_100_] jobs        Cooldown: [_30_] phút ║
║          │  [✓] Job PERMANENTLY_FAILED               Cooldown: mỗi job    ║
║          │  [✓] Drift detected                       Cooldown: [_24_] giờ ║
║          │  [✓] SSL sắp hết hạn < [_7_] ngày        Cooldown: [_24_] giờ ║
║          │                                                            ║
║          │                              [💾 Lưu cài đặt]             ║
╚═══════════════════════════════════════════════════════════════════════╝
```

---

# PHỤ LỤC

## A. Bảng màu Status Badge

| Trạng thái | Badge | Màu Bootstrap | CSS Class |
|------------|-------|---------------|-----------|
| Live / Complete | 🟢 | `success` | `badge bg-success` |
| Pending | 🟡 | `warning` | `badge bg-warning text-dark` |
| Syncing | 🔄 | `info` + spinner | `badge bg-info` + `spinner-border-sm` |
| Failed | 🔴 | `danger` | `badge bg-danger` |
| Cancelled | ⚪ | `secondary` | `badge bg-secondary` |
| Suspended | 🟠 | `warning` | `badge bg-warning` |
| Locked | 🔒 | `dark` | `badge bg-dark` |
| System | 🔧 | `secondary` | `badge bg-secondary` |

## B. Breakpoints Responsive

| Thiết bị | Breakpoint | Layout |
|----------|-----------|--------|
| Desktop | ≥ 1200px | Full layout, sidebar + content |
| Tablet | 768-1199px | Collapse sidebar, full-width content |
| Mobile | < 768px | Stacked cards, table scroll horizontal |

Bảng records trên mobile: cột TTL và Actions ẩn, swipe để xem. Hoặc chuyển sang card-based layout.

## C. Accessibility Checklist

| Yêu cầu | Cách thực hiện |
|---------|---------------|
| Contrast ratio ≥ 4.5:1 | Dùng Bootstrap 5 default colors |
| Keyboard navigation | Tab order đúng, focus visible |
| Screen reader | `aria-label` cho icon buttons, `sr-only` cho badge text |
| Form labels | Mọi input có `<label>` tường minh |
| Error messages | Liên kết `aria-describedby` với field |
| Loading states | `aria-live="polite"` cho sync status updates |

---

> **Ghi chú**: Wireframe này là phác thảo chức năng (functional wireframe), không phải visual design. Màu sắc, font chữ, spacing cụ thể tuân theo theme WHMCS đang sử dụng.

## Changelog
| Ngày | Thay đổi | Người thực hiện |
|------|----------|-----------------|
| 25/02/2026 | Khởi tạo v1.0 — 20 màn hình Client + Admin | — |
