# Implementation Plan: Asynchronous Queue System cho WHMCS DNS Suite

Mục tiêu: Xây dựng hệ thống hàng đợi (queue) trung gian để ghi nhận các thay đổi bản ghi DNS vào cơ sở dữ liệu và đồng bộ ngầm thông qua cronjob, thay vì phải chờ phản hồi trực tiếp từ DirectAdmin API. Điều này giúp cải thiện đáng kể tốc độ phản hồi cho người dùng (UX) khi thao tác với module WHMCS DNS Suite.

## Trả lời các câu hỏi của bạn (Q&A)

**Q: Hãy kiểm tra lại mã nguồn tệp [class.dnssuite.php](file:///Users/nguyenvuong/Desktop/Project/Ph%C3%A1t%20tri%E1%BB%83n%20module%20qu%E1%BA%A3n%20l%C3%BD%20DNS/whmcs-dnssuite-v1.25/whmcs_dnssuite/modules/addons/dnssuite/class/class.dnssuite.php), tôi thấy đã được decoder bằng ionCube**
> **A:** Vâng, đúng là file này đã được chạy qua bộ giải mã (`EasyToYou`). Tuy nhiên, bản thân công cụ giải mã không thể phục hồi lại 100% mã nguồn đối với một số hàm mấu chốt (những hàm chứa key bảo vệ `Protected ioncube.dk encoding key`). Ví dụ, các hàm thực thi cốt lõi như [addRecord()](file:///Users/nguyenvuong/Desktop/Project/Ph%C3%A1t%20tri%E1%BB%83n%20module%20qu%E1%BA%A3n%20l%C3%BD%20DNS/whmcs-dnssuite-v1.25/whmcs_dnssuite/modules/addons/dnssuite/class/class.dnssuite.php#2726-2730), [deleteRecord()](file:///Users/nguyenvuong/Desktop/Project/Ph%C3%A1t%20tri%E1%BB%83n%20module%20qu%E1%BA%A3n%20l%C3%BD%20DNS/whmcs-dnssuite-v1.25/whmcs_dnssuite/modules/addons/dnssuite/class/class.dnssuite.php#108-112), [checkDAConnection()](file:///Users/nguyenvuong/Desktop/Project/Ph%C3%A1t%20tri%E1%BB%83n%20module%20qu%E1%BA%A3n%20l%C3%BD%20DNS/whmcs-dnssuite-v1.25/whmcs_dnssuite/modules/addons/dnssuite/class/class.dnssuite.php#1081-1085) bên trong file này hiện đang **rỗng tuếch (trống trơn nội dung)**. Do đó, PHP vẫn chạy dựa trên file mã hóa gốc `.so` ở tầng server, còn nội dung ta nhìn thấy bằng mắt thường trong file đã giải mã không có giá trị để chỉnh sửa (nếu bạn sửa, phần mềm giải mã cũng không thể biên dịch lại thành file mã hóa ban đầu).

**Q: Việc này có cần can thiệp vào mã gốc của ứng dụng không?**
> **A:** **Có, chúng ta BẮT BUỘC phải can thiệp (chỉnh sửa) mã gốc của ứng dụng (Core App Files)**. Cụ thể ở đây là các file [lib/Client/Controller.php](file:///Users/nguyenvuong/Desktop/Project/Ph%C3%A1t%20tri%E1%BB%83n%20module%20qu%E1%BA%A3n%20l%C3%BD%20DNS/whmcs-dnssuite-v1.25/whmcs_dnssuite/modules/addons/dnssuite/lib/Client/Controller.php) (nơi hứng yêu cầu submit form từ giao diện) và các file liên quan đến cấu hình hệ thống ban đầu ([dnssuite.php](file:///Users/nguyenvuong/Desktop/Project/Ph%C3%A1t%20tri%E1%BB%83n%20module%20qu%E1%BA%A3n%20l%C3%BD%20DNS/whmcs-dnssuite-v1.25/whmcs_dnssuite/modules/addons/dnssuite/dnssuite.php) để lúc active tạo bảng database). 
> 
> *Best Practice (Phương pháp hay nhất)*: Do chúng ta không thể sửa vào thư viện lớp nội bộ ([class.dnssuite.php](file:///Users/nguyenvuong/Desktop/Project/Ph%C3%A1t%20tri%E1%BB%83n%20module%20qu%E1%BA%A3n%20l%C3%BD%20DNS/whmcs-dnssuite-v1.25/whmcs_dnssuite/modules/addons/dnssuite/class/class.dnssuite.php)), cách duy nhất và an toàn nhất là **chặn đứng (intercept)** yêu cầu của người dùng ngay tại tầng Route/Controller. Thay vì để Controller gọi lệnh [addRecord()](file:///Users/nguyenvuong/Desktop/Project/Ph%C3%A1t%20tri%E1%BB%83n%20module%20qu%E1%BA%A3n%20l%C3%BD%20DNS/whmcs-dnssuite-v1.25/whmcs_dnssuite/modules/addons/dnssuite/class/class.dnssuite.php#2726-2730) của class nội bộ, chúng ta sẽ bắt nó gọi lệnh `insert_into_db_queue()` của chúng ta. Việc này đòi hỏi phải chỉnh sửa mã nguồn gốc của module.

## Proposed Changes

### Database Schema
Cần tạo thêm một bảng mới để lưu trữ hàng đợi công việc. Sẽ được thực thi khi kích hoạt module hoặc thông qua một file update riêng.

#### [NEW] `mod_dnssuite_sync_queue`
Bảng lưu trữ thông tin về các tác vụ cần đồng bộ.
*   [id](file:///Users/nguyenvuong/Desktop/Project/Ph%C3%A1t%20tri%E1%BB%83n%20module%20qu%E1%BA%A3n%20l%C3%BD%20DNS/whmcs-dnssuite-v1.25/whmcs_dnssuite/modules/addons/dnssuite/class/class.dnssuite.php#3237-3294) (INT, AUTO_INCREMENT, PRIMARY KEY)
*   `domainid` (INT): ID của domain trong WHMCS (`tbldomains`).
*   `action` (VARCHAR): Loại tác vụ (ví dụ: [addRecord](file:///Users/nguyenvuong/Desktop/Project/Ph%C3%A1t%20tri%E1%BB%83n%20module%20qu%E1%BA%A3n%20l%C3%BD%20DNS/whmcs-dnssuite-v1.25/whmcs_dnssuite/modules/addons/dnssuite/class/class.dnssuite.php#2726-2730), `updateRecord`, [deleteRecord](file:///Users/nguyenvuong/Desktop/Project/Ph%C3%A1t%20tri%E1%BB%83n%20module%20qu%E1%BA%A3n%20l%C3%BD%20DNS/whmcs-dnssuite-v1.25/whmcs_dnssuite/modules/addons/dnssuite/class/class.dnssuite.php#108-112)).
*   `record_type` (VARCHAR): Loại bản ghi DNS (A, AAAA, MX, CNAME, TXT, SRV, NS).
*   `old_data` (TEXT): Dữ liệu cũ định dạng JSON (dùng khi update hoặc delete).
*   `new_data` (TEXT): Dữ liệu mới định dạng JSON (dùng khi add hoặc update).
*   [status](file:///Users/nguyenvuong/Desktop/Project/Ph%C3%A1t%20tri%E1%BB%83n%20module%20qu%E1%BA%A3n%20l%C3%BD%20DNS/whmcs-dnssuite-v1.25/whmcs_dnssuite/modules/addons/dnssuite/class/class.daapi.php#180-184) (VARCHAR): Trạng thái (`pending`, `syncing`, `complete`, `failed`).
*   `fail_reason` (TEXT): Ghi nhận lý do lỗi nếu quá trình đồng bộ thất bại.
*   `created_at` (DATETIME): Thời gian tạo.
*   `updated_at` (DATETIME): Thời gian cập nhật cuối cùng.

---
### Database Setup

#### [MODIFY] [dnssuite.php](file:///Users/nguyenvuong/Desktop/Project/Ph%C3%A1t%20tri%E1%BB%83n%20module%20qu%E1%BA%A3n%20l%C3%BD%20DNS/whmcs-dnssuite-v1.25/whmcs_dnssuite/modules/addons/dnssuite/dnssuite.php)
*   **Mô tả**: Trong hàm [dnssuite_activate()](file:///Users/nguyenvuong/Desktop/Project/Ph%C3%A1t%20tri%E1%BB%83n%20module%20qu%E1%BA%A3n%20l%C3%BD%20DNS/whmcs-dnssuite-v1.25/whmcs_dnssuite/modules/addons/dnssuite/dnssuite.php#36-162), thêm câu lệnh SQL PDO tạo bảng `mod_dnssuite_sync_queue`. Trong hàm [dnssuite_deactivate()](file:///Users/nguyenvuong/Desktop/Project/Ph%C3%A1t%20tri%E1%BB%83n%20module%20qu%E1%BA%A3n%20l%C3%BD%20DNS/whmcs-dnssuite-v1.25/whmcs_dnssuite/modules/addons/dnssuite/dnssuite.php#162-182), thêm lệnh DROP bảng này. Đối với các hệ thống đang chạy, cần thêm logic tạo bảng ở [dnssuite_upgrade()](file:///Users/nguyenvuong/Desktop/Project/Ph%C3%A1t%20tri%E1%BB%83n%20module%20qu%E1%BA%A3n%20l%C3%BD%20DNS/whmcs-dnssuite-v1.25/whmcs_dnssuite/modules/addons/dnssuite/dnssuite.php#182-219) hoặc có một cơ chế tự động tạo nếu bảng chưa tồn tại.

---
### Cronjob / Background Worker

#### [NEW] [cron.php](file:///Users/nguyenvuong/Desktop/Project/Ph%C3%A1t%20tri%E1%BB%83n%20module%20qu%E1%BA%A3n%20l%C3%BD%20DNS/whmcs-dnssuite-v1.25/whmcs_dnssuite/modules/addons/dnssuite/cron.php)
*   **Mô tả**: Đây sẽ là file cronjob chạy nền định kỳ (ví dụ: mỗi 5 phút `*/5 * * * *`).
*   **Hoạt động**:
    1.  Mở kết nối CSDL WHMCS, truy vấn bảng `mod_dnssuite_sync_queue` tìm các record có [status](file:///Users/nguyenvuong/Desktop/Project/Ph%C3%A1t%20tri%E1%BB%83n%20module%20qu%E1%BA%A3n%20l%C3%BD%20DNS/whmcs-dnssuite-v1.25/whmcs_dnssuite/modules/addons/dnssuite/class/class.daapi.php#180-184) là `pending`. Gắn cờ (update) các record này thành `syncing` để tránh bị cron tiến trình khác xử lý trùng.
    2.  Khởi tạo các Controller của WHMCS DNS Suite (giống như cách web đang làm) để lấy các tham số kết nối API.
    3.  Thực hiện loop qua các record và gọi hàm update thực tế lên DirectAdmin (thông qua lớp gốc của hệ thống nếu có thể triệu gọi các hàm public, hoặc tái tạo các lời gọi API dựa trên cấu hình DirectAdmin đã lưu).
    4.  Cập nhật trạng thái trong CSDL thành `complete` nếu phản hồi thành công, hoặc `failed` kèm `fail_reason` nếu thất bại.

---
### Giao diện và Interception

#### [MODIFY] [lib/Client/Controller.php](file:///Users/nguyenvuong/Desktop/Project/Ph%C3%A1t%20tri%E1%BB%83n%20module%20qu%E1%BA%A3n%20l%C3%BD%20DNS/whmcs-dnssuite-v1.25/whmcs_dnssuite/modules/addons/dnssuite/lib/Client/Controller.php) (và các script Submit Ajax nếu có)
*   **Mô tả**: Thay vì khi client/admin bấm nút Add/Edit/Delete Record, hệ thống chặn việc gọi trực tiếp các lệnh đồng bộ lên [class.dnssuite.php](file:///Users/nguyenvuong/Desktop/Project/Ph%C3%A1t%20tri%E1%BB%83n%20module%20qu%E1%BA%A3n%20l%C3%BD%20DNS/whmcs-dnssuite-v1.25/whmcs_dnssuite/modules/addons/dnssuite/class/class.dnssuite.php) và thay bằng lệnh đẩy dữ liệu vào `mod_dnssuite_sync_queue`.
*   *Thách thức*: Phải phân tích cách hệ thống nhận POST request ở thời điểm hiện tại và điều chỉnh logic trả về "Đã đưa vào hàng đợi" (Added to Queue) xuống View của người dùng thay vì kết quả ngay lập tức.

#### [NEW] Giao diện "Sync Logs" (Log đồng bộ)
*   Cần tạo một View/Template (bằng Smarty / HTML) để hiển thị bảng `mod_dnssuite_sync_queue`.
*   **Client Area**: Thêm một Tab "Sync Logs" vào giao diện Quản lý DNS của người dùng, giới hạn chỉ hiển thị các bản ghi có `domainid` thuộc về họ.
*   **Admin Area**: Thêm trang "System Sync Logs" liệt kê tất cả mọi hoạt động đồng bộ của toàn bộ người dùng.

## Verification Plan

Trong quá trình này, các bước xác thực sẽ được thực hiện bằng cách:
1.  **Thiết lập Test:** Chạy trực tiếp một file PHP thử nghiệm để đảm bảo cấu trúc bảng được tạo chính xác khi Upgrade/Activate.
2.  **Khả năng Override API:** Kiểm tra việc "bọc lót" phương thức POST hiện tại khi một record mới được tạo, đảm bảo nó lưu vào CSDL thay vì gọi API thực của [class.dnssuite.php](file:///Users/nguyenvuong/Desktop/Project/Ph%C3%A1t%20tri%E1%BB%83n%20module%20qu%E1%BA%A3n%20l%C3%BD%20DNS/whmcs-dnssuite-v1.25/whmcs_dnssuite/modules/addons/dnssuite/class/class.dnssuite.php).
3.  **Cronjob Trigger:** Chạy file `cron.php` từ Terminal (ví dụ: `php cron.php`) và mô phỏng môi trường bị delay/timeout để xác minh tiến trình `pending` $\rightarrow$ `syncing` $\rightarrow$ `failed`/`complete` hoạt động đáng tin cậy. Dùng các URL API giả (mocked endpoints) nếu cần thiết để giả lập trạng thái API lagging.
4.  **Kiểm tra giao diện:** Mở WHMCS Admin & Client UI để xem dữ liệu có nạp chính xác vào UI log hay không.
