Hướng dẫn cài đặt và Tài liệu hướng dẫn có thể được tìm thấy tại https://docs.codebox.ca

# Phân tích WHMCS DNS Suite

## Tổng quan
**WHMCS DNS Suite** là một module addon được thiết kế để tích hợp WHMCS với DirectAdmin để quản lý DNS. Nó cho phép quản trị viên và khách hàng quản lý các bản ghi DNS, chuyển tiếp email (email forwarders) và chuyển hướng (redirects) trực tiếp từ WHMCS.

## Cấu trúc Thư mục
- **`whmcs_dnssuite/modules/addons/dnssuite/`**: Thư mục module cốt lõi.
    - **`dnssuite.php`**: Cấu hình module chính và các hook WHMCS.
    - **`hooks.php`**: Các hook tích hợp (ví dụ: `ClientAreaNavbars`).
    - **`class/`**:
        - **`class.dnssuite.php`**: Chứa phần lớn logic. Định nghĩa các lớp cho DNS, Email, Redirects, và tương tác API.
        - **`class.daapi.php`**: Chứa lớp `HTTPSocket` cho giao tiếp HTTP cấp thấp.
    - **`lib/`**:
        - **`Admin/Controller.php`**: Xử lý logic Khu vực Quản trị (Admin Area). Điều phối đến `Suite_AdminArea`.
        - **`Client/Controller.php`**: Xử lý logic Khu vực Khách hàng (Client Area). Điều phối đến `Suite_ClientArea`.
    - **`templates/`**: Các template Smarty cho giao diện người dùng (UI).
    - **`lang/`**: Các tập tin ngôn ngữ.
- **`remoteconnector/`**:
    - **`connector.php`**: Một script độc lập có khả năng được tải lên máy chủ DirectAdmin để hỗ trợ các hoạt động tệp cụ thể hoặc xác minh.

## Các Lớp Chính & Kiến Trúc
Tất cả logic cốt lõi nằm trong `class.dnssuite.php`.

### 1. `DNSSUITE\Suite_AdminArea`
- **Vị trí**: `class.dnssuite.php` (Dòng ~2096)
- **Vai trò**: Controller cho các hành động trong Khu vực Quản trị.
- **Phụ thuộc**: `DNSFunctions`, `RedirectFunctions`, `EmailFunctions`.
- **Các phương thức chính**: `addRecord`, `deleteRecord`, `syncDomainsToRemote`, `saveDNSTemplate`.

### 2. `DNSSUITE\Suite_ClientArea`
- **Vị trí**: `class.dnssuite.php` (Dòng ~2686)
- **Vai trò**: Controller cho các hành động trong Khu vực Khách hàng.
- **Phụ thuộc**: `DNSFunctions`, `RedirectFunctions`, `EmailFunctions`.
- **Xác thực**: Kiểm tra các phiên bản giấy phép "Free" (Miễn phí) so với "Premium" (Cao cấp).
- **Các phương thức chính**: `addRecord`, `addForwarder`, `manageSubdomains`.

### 3. `DNSSUITE\DNSFunctions` (mở rộng `BaseFunctions`)
- **Vị trí**: `class.dnssuite.php` (Dòng ~22)
- **Vai trò**: Quản lý các bản ghi DNS (A, MX, CNAME, TXT, v.v.).
- **Tích hợp**: Gọi `DAFunctions` để đẩy các thay đổi lên DirectAdmin.

### 4. `DNSSUITE\EmailFunctions` (mở rộng `BaseFunctions`)
- **Vị trí**: `class.dnssuite.php` (Dòng ~903)
- **Vai trò**: Quản lý chuyển tiếp email và địa chỉ catch-all.
- **Tích hợp**: Lưu trữ cơ sở dữ liệu (`mod_dnssuite_emailforwarders`) và đồng bộ hóa DirectAdmin.

### 5. `DNSSUITE\RedirectFunctions`
- **Vị trí**: `class.dnssuite.php` (Dòng ~489)
- **Vai trò**: Quản lý chuyển hướng tên miền (301, 302, masked).
- **Tích hợp**: Sử dụng `DAFunctions` để thiết lập chuyển hướng trong DirectAdmin.

### 6. `DNSSUITE\DDNSFunctions`
- **Vị trí**: `class.dnssuite.php` (Dòng ~3159)
- **Vai trò**: Xử lý cập nhật Dynamic DNS (DNS động).
- **Tính năng**: Quản lý cấm IP (`mod_dnssuite_ddns_bans`), giới hạn tốc độ API.

### 7. `DNSSUITE\DAFunctions`
- **Vị trí**: `class.dnssuite.php` (Dòng ~4157)
- **Vai trò**: Trình bao bọc cấp cao (high-level wrapper) cho các cuộc gọi API DirectAdmin.
- **Các phương thức**: `AddRecord`, `DeleteRow`, `GetZone`, `RequestSSL`.
- **Nền tảng**: Sử dụng `DAAPI\HTTPSocket` để truyền tải.

### 8. `DNSSUITE\BaseFunctions`
- **Vị trí**: `class.dnssuite.php` (Dòng ~3199)
- **Vai trò**: Các phương thức tiện ích được chia sẻ (tải cấu hình, kiểm tra giấy phép).
- **Dữ liệu chính**: `$configs` (cài đặt module), `$daconfigs` (thông tin xác thực máy chủ DirectAdmin).

## Tích hợp DirectAdmin
- **Kết nối**: Sử dụng `HTTPSocket` để kết nối với DirectAdmin trên cổng 2222 (mặc định) qua HTTP/HTTPS.
- **Xác thực**: Sử dụng User/Password API được định nghĩa trong cài đặt module.
- **Lệnh**: Gửi các lệnh API DirectAdmin gốc (ví dụ: `/CMD_API_DNS_CONTROL`, `/CMD_API_EMAIL_FORWARDERS`).
- **Trình kết nối từ xa**: `connector.php` cung cấp một kênh phụ trợ cho các hoạt động có thể bị hạn chế hoặc yêu cầu truy cập tệp cục bộ trên máy chủ từ xa (sử dụng xác minh hàm băm bảo mật).

## Lược đồ Cơ sở dữ liệu (Suy luận)
- `mod_dnssuite_emailforwarders`: Lưu trữ ánh xạ chuyển tiếp email.
- `mod_dnssuite_emailcatchalls`: Lưu trữ cấu hình catch-all.
- `mod_dnssuite_subdomains`: Theo dõi các subdomain.
- `mod_dnssuite_ddns_bans`: Cấm IP cho DDNS.
- `mod_dnssuite_api`: Khóa API cho DDNS.

## Quan sát về Bảo mật
- **Làm sạch đầu vào**: Sử dụng `idn_to_ascii` cho tên miền.
- **Kiểm soát truy cập**: Kiểm tra `subaccountrestriction` trong `Suite_ClientArea`.
- **Kiểm tra bản quyền**: Thực hiện hệ thống kiểm tra giấy phép từ xa (`checkLicenseNow` với `licensechef.com`).