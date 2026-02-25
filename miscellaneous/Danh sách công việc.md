# Task Documentation: Asynchronous Queue System

Tài liệu này định nghĩa chi tiết các hạng mục công việc cần thực hiện để phát triển hệ thống hàng đợi bất đồng bộ (Asynchronous Queue System) cho WHMCS DNS Suite, kèm theo thời gian ước tính (Duration) và công cụ hỗ trợ công nghệ (Tech Stack / AI Tools) để tăng tốc phát triển.

## 1. Back-end Tasks (CSDL & Xử lý Logic)

| Mã | Tên công việc | Mô tả / Cách thực hiện | Kết quả cần đạt | Thời gian | Tech Stack / AI Assist |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **BE-01** | Tạo bảng DB `mod_dnssuite_sync_queue` | Can thiệp hàm `dnssuite_activate()` (`dnssuite.php`) thêm schema SQL tạo 1 bảng lưu: domainid, action, record, times, status. | Bảng được tạo tự động khi kích hoạt / nâng cấp. | 30 phút | **Tech:** PHP, WHMCS DB Capsule.<br>**AI:** Dùng Gemini/Copilot/Cursor sinh code Schema DB WHMCS cho nhanh gọn và chuẩn syntax. |
| **BE-02** | Xử lý DB khi Hủy kích hoạt | Thêm câu lệnh SQL `DROP TABLE` vào hàm `dnssuite_deactivate()`. | Bảng queue được xóa khi gỡ module. | 10 phút | **Tech:** PHP.<br>**AI:** Github Copilot (Autocompletion). |
| **BE-03** | Khởi tạo bảng cho User Cũ (Upgrade) | Viết script kiểm tra sự tồn tại của bảng trong hàm `dnssuite_upgrade()`. | User cũ nâng cấp lên bản này không lo lỗi thiếu bảng CSDL. | 30 phút | **Tech:** PHP, PDO.<br>**AI:** Prompt AI viết logic check table exists (MySQL). |
| **BE-04** | Viết `cron.php` (Background Worker) | Script lập lịch định kỳ query các record `pending` $\rightarrow$ đổi trạng thái `syncing` $\rightarrow$ Khởi tạo Controller gốc $\rightarrow$ Bắn API cURL lên Server DA. | Tự động quá trình đồng bộ nền, user không cần treo trình duyệt. | ~4 giờ | **Tech:** PHP CLI, WHMCS local API, Cron.<br>**AI:** Sử dụng AI IDE (Windsurf / Cursor) yêu cầu tạo khung template cho 1 Queue Worker Class (try catch an toàn, logging chi tiết). |
| **BE-05** | Xử lý kết quả trả về từ Cronjob | Parse nội dung response từ API. Cập nhật record trong DB thành `complete` hoặc `failed` (lưu fail_reason). | System tracking chính xác nguyên nhân lỗi đồng bộ. | 1.5 giờ | **Tech:** JSON Parsing, PHP Regex.<br>**AI:** Ném mẫu Object Response JSON cho LLM và bảo nó parse tự động ra Regex/Class lấy lỗi chuẩn nhất. |
| **BE-06** | Override Lệnh Lưu DNS ở Client | Mổ xẻ `lib/Client/Controller.php` (hoặc submit ajax). Thay vì gọi trực tiếp class bị IonCube, lấy post data nhét vào bảng DB Queue. | Trải nghiệm lưu thông số nhanh tức thời (phản hồi < 1s). | 2 - 3 giờ | **Tech:** PHP, OOP Polymorphism.<br>**AI:** Đưa code form handler cũ vào ChatGPT/Claude để nó phân tích và bóc tách input POST thay thế lưu xuống DB an toàn (chống SQL Injection). |
| **BE-07** | Override Lệnh Lưu DNS ở Admin | Tương tự BE-06 nhưng áp dụng đối với luồng file `lib/Admin/Controller.php`. | Tốc độ Admin thao tác như chớp mắt. | 2 giờ | **Tech:** PHP.<br>**AI:** Copy code từ BE-06 sang nhờ AI Refactor cho context của Admin Panel. |
| **BE-08** | Tính năng "Retry" Failed Jobs | Điểm cuối Controller, nhận id request, update lại thành `pending`. | Tự phục hồi dữ liệu kẹt mạng. | 1 giờ | **Tech:** SQL Update.<br>**AI:** Nhờ AI viết route action và Controller nhỏ. |

## 2. Front-end Tasks (Giao diện người dùng)

| Mã | Tên công việc | Mô tả / Cách thực hiện | Kết quả cần đạt | Thời gian | Tech Stack / AI Assist |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **FE-01** | Sửa thông báo UI ("Loading/Save") | Sửa text/alert cũ thành dòng mới: _"Bản ghi đã lưu vào Queue... Vui lòng chờ 1-5 phút"_ | User nắm hành vi hệ thống. | 30 phút | **Tech:** Smarty, JS (Ajax).<br>**AI:** Phân tích logic Alert hộp thoại Javascript để override. |
| **FE-02** | Xây dựng Tab "Sync Logs" (Client Area) | Giao diện cho Client (sửa Smarty TPL template), render UI bảng chứa record Queue từ BE_DB. | Khách xem log rõ ràng. | 2 - 3 giờ | **Tech:** HTML, CSS, WHMCS Smarty, Bootstrap 3/4.<br>**AI:** Yêu cầu AI Generate code bảng Data Table HTML/Smarty chuyên nghiệp dựa trên array dữ liệu BE trả về. Rút ngắn 80% time làm markup HTML. |
| **FE-03** | Menu "System Sync Logs" (Admin Area) | Tại trang hệ thống Admin, list 1 bảng DataTables toàn bộ các bản ghi của mọi user. Kèm phân trang. | Admin giám sát toàn hệ thống. | 2 - 3 giờ | **Tech:** jQuery DataTables, PHP, HTML.<br>**AI:** Nhờ AI viết script jQuery Ajax DataTables có Server-side processing để nạp hàng triệu dòng log không bị đơ. |
| **FE-04** | Style Màu Sắc & Badge Trạng thái | Thêm thẻ CSS, Bootstrap Classes (`label-warning`, `label-success`, `label-danger`) vào bảng Logs... | UX hiện đại, minh bạch trực quan. | 1 giờ | **Tech:** SCSS / CSS.<br>**AI:** Dùng AI tạo các mảng màu theo UI Kit của WHMCS. |
| **FE-05** | Nút Retry UI cho Admin | Gắn icon "vòng lặp" gọi Ajax kích hoạt tính năng Retry BE-08 ở mỗi dòng failed. | 1 Click phục hồi lỗi. | 1 giờ | **Tech:** jQuery, SweetAlert.<br>**AI:** Tự động gen Ajax Script kèm Confirmation Popup (Bạn có chắc muốn chạy lại Sync?). |

---
**Tổng thời gian dự kiến (Estimations):** 
Khoảng **~18 đến 22 giờ làm việc** (Khoảng 2.5 - 3 ngày làm việc tập trung). 
Nếu sử dụng 100% công sức tự gõ, dự án có thể kéo dài >4 ngày do rất nhiều Boilerplate. Nhưng với sự kết nối của **Generative AI Tools** (như Cursor, GitHub Copilot, ChatGPT/Claude để dịch ngược form submission, DataTables Boilerplates...), thời lượng dự án có thể **rút ngắn ~30-40%**.
