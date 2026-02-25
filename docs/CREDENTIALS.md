# Credentials & Môi trường Thử nghiệm

> **Lưu ý bảo mật:** File này chứa thông tin template mẫu. **TUYỆT ĐỐI KHÔNG** commit các mật khẩu thực tế, API Keys hay Tokens thật lên hệ thống quản lý mã nguồn (Git hoặc public repos). Hãy dùng các biến giả (`[Username WHMCS]`, v.v.) khi chia sẻ cho đối tác, hoặc chắc chắn file này đã bị tống vào `.gitignore` trước khi điền thông tin thật.

## 1. Môi trường WHMCS (Development)
- **URL Admin**: `https://id.hvn.group/admin`
- **URL Client Area**: `https://id.hvn.group/`
- **Tài khoản Admin**: 
  - Username: `admin`
  - Password: `Vuongnm@0502`
- **Tài khoản Test Client**:
  - Email: `[Email client thử nghiệm]`
  - Password: `[Mật khẩu client thử nghiệm]`
- **Đường dẫn thư mục module test**: `/path/to/whmcs/modules/addons/hvn_dns_manager/`

## 2. Thông tin DirectAdmin Servers (Nodes)

### Node 1 (Primary Server)
- **Hostname**: `dns1.hvn.vn`
- **IP Address**: `160.187.146.54`
- **Port**: `2222` (Mặc định)
- **Username DA**: `admin`
- **Password DA**: `[Mật khẩu admin DA 1]` -> Liên hệ gửi pass riêng
- **SSL**: `Enabled`

### Node 2 (Secondary Server)

### Node 3 (Secondary Server)

## 3. Tên miền & Dữ liệu Thử nghiệm

Để test các trường hợp CRUD/Syncing, Conflict Resolution (Lỗi Cùng Thao Tác), Auto-provisioning... hãy chuẩn bị ít nhất 2 tên miền đã thêm vào WHMCS:

- **Tên miền thử nghiệm 1** (Dành cho chức năng Add/Edit/Delete Records cơ bản): `tkw.com]`
  - Map với WHMCS Service ID: `[Service ID 1]`
  - Trạng thái bắt buộc: `Active`
- **Tên miền thử nghiệm 2** (Dành cho chức năng Test Chống Xung Đột/Rollback/Quota): `tkw.com]`
  - Map với WHMCS Service ID: `[Service ID 2]`
  - Trạng thái bắt buộc: `Active`

## 4. Cấu hình Nameservers Kiểm thử
Khi khách hàng mua tên miền thử nghiệm (Test domain), cần trỏ domain về các nameservers sau để test phân giải (DNS Propagation):
- **NS1**: `[dns1.hvn.vn]` (Tương ứng trỏ A record về `IP Server 1`)
- **NS2**: `[dns2.hvn.vn]` (Tương ứng trỏ A record về `IP Server 2`)
- **NS3**: `[dns3.hvn.vn]` (Tương ứng trỏ A record về `IP Server 3`)

## 5. Các thông tin cấu hình khác (Tùy chọn)
- **Telegram Bot Token** (Cảnh báo Notification System): `[Token bot telegram]`
- **Telegram Chat ID**: `[Chat ID hoặc ID Group nhận tin nhắn]`
- **Thông tin Database MySQL/MariaDB của WHMCS** (Dành cho dev test migration SQL query bằng tay):
  - Manager: `https://id.hvn.group/phpmyadmin` (Hoặc IP remote)
  - Host: `localhost` (Hoặc IP remote)
  - DB Name: `[Tên DB WHMCS, mặc định thường là *whmcs*]`
  - User: `vuongnm`
  - Pass: `1234`
