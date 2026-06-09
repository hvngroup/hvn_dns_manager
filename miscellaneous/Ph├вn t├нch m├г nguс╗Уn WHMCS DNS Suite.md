# Báo cáo Phân tích Mã nguồn WHMCS DNS Suite v1.25

Dựa trên quá trình phân tích mã nguồn của module **WHMCS DNS Suite v1.25**, dưới đây là tài liệu tổng hợp về cấu trúc, nguyên lý hoạt động và các thành phần cốt lõi của plugin này:

## 1. Cấu trúc tổng quan

Module được thiết kế theo mô hình **MVC (Model-View-Controller)** cơ bản, tích hợp chặt chẽ với hệ thống hook và module addon của WHMCS. 
Mã nguồn đã được giải mã từ `IonCube v11` (bởi bộ giải mã EasyToYou), tuy nhiên một số function cốt lõi trong file `class.dnssuite.php` chứa logic độc quyền vẫn giữ lại các chú thích `// @Protected ioncube.dk encoding key` và bị làm rỗng nội dung trong bản phục hồi (như `addRecord`, `checkDAConnection`, `deleteDomainDirect`, v.v.).

## 2. Hoạt động cốt lõi và Định tuyến (Routing)

*   **`dnssuite.php`**: File cấu hình chính của WHMCS addon. Chứa các hàm bắt buộc:
    *   `dnssuite_config()`: Khai báo metadata và một danh sách rất dài các cấu hình setting cho WHMCS Admin (Cấu hình DirectAdmin server, kết nối SSL, các limit tạo record, limit API v.v.).
    *   `dnssuite_activate()`: Chạy khi kích hoạt module, tạo toàn bộ các bảng CSDL cần thiết: zone DNS, redirects, email forwarders, email catch-alls, cấu hình API, bảng log chống brute-force cho DDNS, DNS templates, v.v.
    *   `dnssuite_output()` và `dnssuite_clientarea()`: Đóng vai trò làm Router ban đầu, triệu gọi `AdminDispatcher` và `ClientDispatcher`.

*   **`lib/Admin/Controller.php` & `lib/Client/Controller.php`**: 
    Hứng request từ Dispatcher, thực thi các `$action` (ví dụ `index`, `manage`, `loaddomain`). Controller sẽ khởi tạo một instance của DB class (từ phần tử cốt lõi `DNSSUITE\Suite_AdminArea` hoặc `DNSSUITE\Suite_ClientArea`), nạp dữ liệu từ CSDL WHMCS và API, sau đó trả về mảng dữ liệu để render lên các Smarty template của WHMCS.

## 3. Lõi xử lý Logic (`class.dnssuite.php`)

Đây là "trái tim" của hệ thống với gần **4700 dòng lệnh**. Do dung lượng lớn, nhà phát triển (Codebox.ca) đã chia thành nhiều class kế thừa (extends) lẫn nhau theo tính năng:

*   **`BaseFunctions`**: Các tác vụ chung (Load Config WHMCS, kiểm tra License từ xa, validation các record DNS, định dạng domain, v.v.).
*   **`DNSFunctions`**: Xử lý việc fetch, add, delete, update các bản ghi DNS (A, AAAA, MX, CNAME, TXT, SRV) trên DirectAdmin. Lưu trữ "local cache" của các zone vào bảng `mod_dnssuite_zones` để giảm tải cho API.
*   **`RedirectFunctions``: Quản lý web redirections (301, 302 chuyển hướng URL). 
*   **`EmailFunctions`**: Quản lý Email Forwarders và Catch-all.
*   **`DDNSFunctions`**: Cung cấp API cập nhật Dynamic DNS cho end-user, tích hợp sẵn cơ chế chống Brute Force (khóa IP tự động lưu vào `mod_dnssuite_api_bruteforce` & `mod_dnssuite_bruteforce_ban`).
*   **`DAFunctions`**: Lớp wrap (trình bao bọc) trực tiếp gọi các API của DirectAdmin (bằng các Endpoint lệnh như `/CMD_API_DNS_CONTROL`, `/CMD_API_EMAIL_FORWARDERS`).

## 4. Giao tiếp API với DirectAdmin (`class.daapi.php`)

Module tự định nghĩa một `HTTPSocket` class (version 3.0.2) chuyên dùng để kết nối với Web Console của DirectAdmin qua cURL.
*   Hỗ trợ cả HTTP/HTTPS.
*   Authenticates thông qua phương thức HTTP Basic Login (truyền username/password API config từ hệ thống).
*   Thực hiện gọi API GET/POST linh hoạt, tối ưu timeout và bắt dính header trả về để đọc JSON/Plain-text.

## 5. Script điều khiển từ xa (`remoteconnector/connector.php`)

Đây là một đoạn script độc lập rất thú vị trong giải pháp này. `connector.php` phải được người quản trị tải lên môi trường lưu trữ (thư mục gốc hosting) của tài khoản cụm DirectAdmin. Nó giải quyết bài toán **Masked URL Forwarding** (Chuyển hướng ẩn URL - giữ nguyên tên miền trên thanh địa chỉ):
*   Khi WHMCS gọi thực thi tạo một masked redirect, nó sẽ giao tiếp HTTP POST tới file `connector.php` ở máy chủ đích.
*   **Bảo mật**: Dùng `hash('sha512', $hash.$_POST["time"])` để xác thực chữ ký (ngăn tình trạng ai cũng gọi được file này). Giới hạn thời gian chữ ký sống trong tối đa 900 giây (15 phút).
*   **Thực thi**: Script sẽ tự động *tạo / sửa / xóa đổi* file `index.html` (hoặc tạo thư mục đường dẫn tùy chỉnh) trên hosting DirectAdmin đó. Nội dung file sinh ra bản chất là một trang HTML có thẻ `<frameset><frame src="Đích_đến_URL"></frameset>` ôm toàn màn hình. Từ đó giả lập tính năng Masked Redirecting cho DNS.

## 6. Sự can thiệp Tự động (`hooks.php`)

Để chạy ngầm trơn tru trong hệ sinh thái WHMCS, module dùng WHMCS Hooks để can thiệp:
*   `ClientAreaNavbars` & `ClientAreaPageDomainDetails`: Chèn thêm Menu item `DNSSuite` ở thanh điều hướng khách hàng và Sidebar của WHMCS.
*   `PreRegistrarRegisterDomain`, `PreDomainRegister`, `PreRegistrarTransferDomain`: Ngay sau khi một Domain được đăng ký hoặc transfer thành công thông qua WHMCS, hook này sẽ bắt ID và tự động "tạo Zone DNS" (hoặc Domain template) ngầm trên phần mềm DirectAdmin ở máy chủ name server đích, dọn sẵn hạ tầng ngay lập tức cho khách hàng sử dụng dịch vụ.

> [!NOTE] 
> Nhìn chung, đây là một DNS Manager Component được viết khá tốt, tối ưu cho DirectAdmin. Đóng gói đầy đủ tính năng DNS Editor, Email Forwarding, URL Masking (bằng thủ thuật xuất file HTML), Dynamic DNS cho client với cả chế độ admin local cache để thao tác giao diện được nhanh hơn.
