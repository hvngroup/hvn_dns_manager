# Credentials & Môi trường Thử nghiệm — TEMPLATE

> **⚠️ BẢO MẬT (ATTT HVN 01-01/11/2024):** Đây là **template mẫu** — chỉ chứa biến giả.
> **TUYỆT ĐỐI KHÔNG** điền mật khẩu/API key/token thật vào file này hoặc bất kỳ file nào
> được Git theo dõi. Để dùng thực tế: copy file này thành `docs/CREDENTIALS.md`
> (đã nằm trong `.gitignore`, KHÔNG bao giờ được commit) rồi điền giá trị thật ở bản local.

## 1. Môi trường WHMCS (Development)
- **URL Admin**: `[URL admin WHMCS]`
- **URL Client Area**: `[URL client area WHMCS]`
- **Tài khoản Admin**:
  - Username: `[username admin]`
  - Password: `[mật khẩu admin — KHÔNG commit]`
- **Tài khoản Test Client**:
  - Email: `[email client thử nghiệm]`
  - Password: `[mật khẩu client thử nghiệm]`
- **Đường dẫn thư mục module test**: `/path/to/whmcs/modules/addons/mj_dns_manager/`

## 2. Thông tin DirectAdmin Servers (Nodes)

### Node 1 (Primary Server)
- **Hostname**: `[hostname node 1]`
- **IP Address**: `[IP node 1]`
- **Port**: `2222`
- **Username DA**: `[username DA]`
- **Password DA**: `[mật khẩu DA — KHÔNG commit]`
- **SSL**: `Enabled`

### Node 2 (Secondary Server)

### Node 3 (Secondary Server)

## 3. Tên miền & Dữ liệu Thử nghiệm

Chuẩn bị ít nhất 2 tên miền đã thêm vào WHMCS để test CRUD/Syncing/Conflict/Auto-provisioning:

- **Tên miền thử nghiệm 1** (Add/Edit/Delete Records cơ bản): `[domain test 1]`
  - Map với WHMCS Service ID: `[Service ID 1]`
  - Trạng thái bắt buộc: `Active`
- **Tên miền thử nghiệm 2** (Chống Xung Đột/Rollback/Quota): `[domain test 2]`
  - Map với WHMCS Service ID: `[Service ID 2]`
  - Trạng thái bắt buộc: `Active`

## 4. Cấu hình Nameservers Kiểm thử
- **NS1**: `[ns1 hostname]` (trỏ A record về `[IP Server 1]`)
- **NS2**: `[ns2 hostname]` (trỏ A record về `[IP Server 2]`)
- **NS3**: `[ns3 hostname]` (trỏ A record về `[IP Server 3]`)

## 5. Các thông tin cấu hình khác (Tùy chọn)
- **Telegram Bot Token** (Notification System): `[token bot telegram]`
- **Telegram Chat ID**: `[chat ID / group ID]`
- **Database MySQL/MariaDB của WHMCS** (test migration/SQL thủ công):
  - Manager: `[URL phpMyAdmin / IP remote]`
  - Host: `[localhost hoặc IP remote]`
  - DB Name: `[tên DB WHMCS]`
  - User: `[DB user]`
  - Pass: `[DB pass — KHÔNG commit]`
