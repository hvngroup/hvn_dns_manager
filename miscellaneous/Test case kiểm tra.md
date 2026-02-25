# Tài liệu Test Cases: Hệ thống Asynchronous DNS Queue

Tài liệu này cung cấp các kịch bản kiểm thử (Test Cases) để đảm bảo hệ thống Queue hoạt động ổn định, chính xác và xử lý lỗi trơn tru. Quá trình kiểm tra bắt đầu từ môi trường chuẩn bị cho đến các thao tác của người dùng cuối.

---

## Phần 1: Các bước Chuẩn bị Môi trường (Pre-requisites)

| Bước | Hành động | Kết quả mong đợi | Xác nhận |
| :--- | :--- | :--- | :--- |
| **PRE-01** | Cấp quyền API trên DirectAdmin | Tạo một tài khoản Reseller/Admin trên DA Test. Đảm bảo Login Keys/Mật khẩu API có đủ quyền thao tác DNS (`CMD_API_DNS_CONTROL`). | Kết nối API hợp lệ, trả về list domain qua API. |
| **PRE-02** | Cấu hình Module tại WHMCS | Vào WHMCS Admin $\rightarrow$ Setup $\rightarrow$ Addon Modules $\rightarrow$ Điền thông tin kết nối API DA (IP, User, Pass/Key) vào cấu hình DNS Suite. | Form cấu hình lưu thành công không báo lỗi Access Denied. |
| **PRE-03** | Gắn Domain vào DNS Zone (DA) | Đăng nhập DirectAdmin Test, vào phần **DNS Management**, trỏ tạo thủ công một Zone cho tên miền `testdomain.com`. | Domain tồn tại trong danh sách Zone trên bảng điều khiển DA. |
| **PRE-04** | Đồng bộ Domain ở WHMCS | Vào WHMCS $\rightarrow$ Clients $\rightarrow$ Domains. Thêm/import `testdomain.com` gán cho một khách hàng Test. | Domain hiển thị trạng thái Active ở máy khách WHMCS. |
| **PRE-05** | Chạy Cronjob ảo giả lập | Mở terminal server WHMCS chạy tay lệnh: `php -q /path/to/modules/addons/dnssuite/cron.php`. | File cron chạy không bị dừng lỗi cú pháp (Cột mốc số 1). |

---

## Phần 2: Kiểm thử Chức năng (Functional Test Cases)

### 1. Luồng Ghi nhận (Queue Insertion)

| ID | Kịch bản kiểm tra (Test Case) | Các bước thực hiện (Steps) | Kết quả mong đợi (Expected Results) | Trạng thái |
| :--- | :--- | :--- | :--- | :--- |
| **TC-1.1** | Tạo mới bản ghi DNS hợp lệ (Add Record) | 1. Đăng nhập WHMCS Client/Admin.<br>2. Chọn domain `testdomain.com`.<br>3. Thêm bản ghi loại `A`, Name: `www`, IP: `1.1.1.1`.<br>4. Nhấn **Save**. | Giao diện không bị treo. Báo "Bản ghi đã lưu vào Queue". DB `mod_dnssuite_sync_queue` có dòng mới với status = `pending`. | `[  ]` |
| **TC-1.2** | Kiểm tra XSS/Injection | 1. Thêm bản ghi chứa Payload mạo danh: `<script>alert(1)</script>`.<br>2. Bấm Save. | Controller Client chặn và báo lỗi Validation (Record không hợp lệ), KHÔNG ghi vào bảng Queue. | `[  ]` |
| **TC-1.3** | Cập nhật bản ghi DNS (Edit Record) | 1. Chọn nút Sửa bản ghi tại `www` thành `2.2.2.2`.<br>2. Nhấn Save. | DB Queue nhận thêm dòng có trường `action = updateRecord`, `old_data` chứa IP cũ 1.1.1.1, `new_data` là 2.2.2.2. Status: `pending`. | `[  ]` |
| **TC-1.4** | Xóa bản ghi DNS (Delete Record) | 1. Bấm nút Thùng rác (Xóa) dòng `www`.<br>2. Nhấn Xác nhận. | Bảng Queue nhận lệnh `action = deleteRecord`. Giao diện cập nhật tức thì (Ẩn record khỏi UI dù chưa lên DA). | `[  ]` |

### 2. Luồng Xử lý Đồng bộ (Cronjob Worker)

| ID | Kịch bản kiểm tra (Test Case) | Các bước thực hiện (Steps) | Kết quả mong đợi (Expected Results) | Trạng thái |
| :--- | :--- | :--- | :--- | :--- |
| **TC-2.1** | Cronjob lấy cờ Pending thành công | 1. Đảm bảo có 3 record `pending` trong DB.<br>2. Chạy tay `cron.php`.<br>3. Kiểm tra log/CSDL trong 1 giây đầu. | Cron đổi 3 record đó từ `pending` sang `syncing` để khóa không cho worker khác xử lý đè. | `[  ]` |
| **TC-2.2** | Cronjob kết nối thành công và Đồng bộ DA | 1. Đợi tiến trình Cronjob ở TC-2.1 chạy xong.<br>2. Kiểm tra CSDL DirectAdmin thực tế. | Bản ghi `www` với IP đã nhập được xuất hiện/chuyển đổi trên Zone của `testdomain.com` ở DirectAdmin. Status về `complete`. | `[  ]` |
| **TC-2.3** | Lỗi Network Timeout & Sinh Log Lỗi | 1. Cố ý sửa sai thông số Mật khẩu API / Tắt mạng kết nối đến server DA.<br>2. Submit DNS $\rightarrow$ `pending`.<br>3. Chạy `cron.php`. | Cronjob mất 1 khoảng thời gian (timeout) nhưng không chết vòng loop. Update record thành `failed`. Cột `fail_reason` ghi nhận "Connection Timeout" hoặc "Auth Failed". | `[  ]` |
| **TC-2.4** | Xử lý đa luồng (Concurrency - Nâng cao) | 1. Set 50 bản ghi `pending`.<br>2. Chạy cùng lúc 2 cửa sổ terminal chạy `cron.php`. | Các cronjob không bị giẫm chân lên nhau tạo ra duplicate. Tổng số `complete`/`failed` đúng bằng 50. | `[  ]` |

### 3. Giao diện Giám sát (UI/UX)

| ID | Kịch bản kiểm tra (Test Case) | Các bước thực hiện (Steps) | Kết quả mong đợi (Expected Results) | Trạng thái |
| :--- | :--- | :--- | :--- | :--- |
| **TC-3.1** | Khách hàng giám sát Log cá nhân | 1. Đăng nhập Client có `testdomain.com`.<br>2. Bấm vào Tab **Sync Logs**.<br>3. Chuyển sang client khác không sở hữu domain đó. | Client xem được toàn bộ tiến trình báo lỗi hay success của tên miền mình. Client khác không xem được chéo hệ thống. Badge màu xanh (Success) đỏ (Failed) hiển thị mượt. | `[  ]` |
| **TC-3.2** | Admin Retry Failed Job | 1. Đăng nhập Admin $\rightarrow$ System Sync Logs.<br>2. Tìm 1 queue trạng thái `failed` (do TC-2.3 tạo).<br>3. Sửa lại mật khẩu API cho đúng trên DA.<br>4. Nhấn Icon **Retry**. | Tác vụ chạy lại Ajax, queue đổi từ `failed` $\rightarrow$ `pending`. Vài phút sau Cronjob dọn dẹp biến thành `complete`. | `[  ]` |

---
**Ghi chú:** Đánh dấu kiểm (x) vào cột Trạng thái sau khi hoàn thành chạy thực tế trong giai đoạn Verification.
