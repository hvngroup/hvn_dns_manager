# Kế hoạch Phát triển Module Quản lý DNS Bất đồng bộ

Dựa trên việc phân tích cấu trúc của WHMCS DNS Suite (phiên bản cũ) và tích hợp thêm yêu cầu **Kiến trúc Bất đồng bộ (Hàng đợi - Queue)**, dưới đây là tài liệu phác thảo tính năng cho một Module hoàn toàn mới. 

## 1. Tên Module Chính Thức

Tên module được thống nhất là: **HVN - DirectAdmin DNS Manager**.
(Nhấn mạnh vào thương hiệu HVN Group, tích hợp trình quản lý DNS đồng bộ/bất đồng bộ tốc độ cao với máy chủ DirectAdmin).

---

## 2. Kiến trúc Cốt lõi (Core Architecture)

Khác với module cũ gọi API trực tiếp, hệ thống mới được quy định phải tuân thủ chuẩn luồng dữ liệu 4 bước khép kín và an toàn:

*   **Tầng Khách (Client Controller)**: Tiếp nhận chỉnh sửa DNS $\rightarrow$ Validate bảo mật $\rightarrow$ **Lưu ngay lập tức** vào DataBase (Bảng `queue_jobs`). KHÔNG gọi CURL nào ở đây.
*   **Tầng Lưu trữ (Database)**: Một bảng đặc biệt đóng vai trò lưu lại "Lịch sử tác vụ" với các trạng thái: `PENDING` (Chờ xử lý), `SYNCING` (Đang chạy), `COMPLETE` (Xong), `FAILED` (Lỗi). Sử dụng Core DB của WHMCS.
*   **Tầng Load Balancer (Định tuyến Node DA)**: Hệ thống ghi nhận Domain A thuộc Node cấu hình nào (VD: `dns1.hvn.vn` hay `dns2.hvn.vn`) để chọn đúng IP/Mật khẩu API khi tiến hành chạy Cron.
*   **Tầng Xử lý nền (Background Worker / Cron)**: Một tiến trình Cronjob trên WHMCS Server (1-3 phút/lần) tự động lặp qua các queue `PENDING`, mở socket kết nối lên đích DirectAdmin đã được định tuyến, thực thi và tự động ghi log.
*   **Tầng Đích (Root Server)**: DirectAdmin Node tiếp nhận API, thay đổi Zone File, Restart dịch vụ Named/Bind trên máy chủ. Đưa website thực tế vào hoạt động.

---

## 3. Danh sách Tính năng cần thiết (Feature List)

### 3.1. Dành cho Khách hàng (Client Area)

1. **Giao diện Editor DNS (Tức thời - Zero Latency)**: 
   - Thêm / Sửa / Xóa các bản ghi tiêu chuẩn (A, AAAA, CNAME, MX, TXT, SRV, NS, CAA).
   - Phản hồi lưu thành công từ giao diện chỉ tốn < 0.2 giây (do chạy DB lưu queue thay vì chờ API DA).
2. **Theo dõi Tiến trình (Sync Tracker)**:
   - Các bản ghi đang xử lý nền sẽ có icon "Đang xoay" (Spinner) hoặc badge `Syncing...` trên giao diện.
   - Khi cronjob chạy xong, giao diện tự cập nhật thành biểu tượng "Tích xanh" `Live on Root`.
3. **Quản lý Hướng (Redirect / URL Forwarding) Cấp Cao**:
   - Hỗ trợ tạo chuyển hướng Standard (301, 302).
   - Hỗ trợ Masked Redirect (Ẩn URL) sử dụng Connector thông minh (Mã hóa Hash bảo mật cao) trên host đích.
   - **Tích hợp Tự động SSL (Let's Encrypt)**: Tận dụng tính năng của DirectAdmin để phát hành chứng chỉ Auto-SSL miễn phí cho các domain sử dụng dịch vụ NameServer. Nhờ đó, link chuyển hướng URL bằng HTTPS (`https://domain.com` chuyển sang nơi khác) sẽ không bị các trình duyệt hiện đại cảnh báo lỗi bảo mật rủi ro (Not Secure).
4. **Quản lý Email (Email Forwarding / Catch-all)**:
   - Tạo hộp thư chuyển tiếp và hộp thư dọn dẹp lỗi. Hệ thống cũng đẩy qua Hàng đợi Đồng bộ.
5. **Nạp Mẫu (Load Template)**:
   - Khách hàng có thể reset DNS về dạng gốc bằng 1 click dựa trên các Profile/Mẫu DNS mặc định cấu hình bởi Admin.
6. **Client API DDNS (Dành cho Camera/Router gia đình)**:
   - User được cấp một URL mật để cấu hình vào Router (VD Mikrotik/DrayTek). Khi IP IP tĩnh đổi, Router ném Get Request lên WHMCS $\rightarrow$ Cập nhật bản ghi A của DNS Queue $\rightarrow$ Đổi IP Server tự động.
   - Đi kèm thuật toán **Anti-Brute Force** chống gọi API rác và Block IP xấu tự động.
7. **Hỗ trợ Quản lý DNSSEC**:
   - DirectAdmin **hỗ trợ rất tốt DNSSEC** nguyên bản (nếu được Enable trên Server DirectAdmin qua file `directadmin.conf`).
   - Trong module **HVN - DirectAdmin DNS Manager**, tính năng này sẽ được đồng nhất luồng kiến trúc mạng Bất đồng bộ (Queue):
       * (1) **Nút Kích Hoạt/Vô Hiệu Hóa (Enable/Disable)**: Giao diện cho phép khách hàng chọn Bật/Tắt chế độ bảo mật DNSSEC trực tiếp từ trang quản lý WHMCS. Lệnh này được đẩy vào **Database Queue** (như tạo Record thông thường) để Cronjob xử lý sau nhằm tránh tải nghẽn thay vì gọi API trực tiếp.
       * (2) Khi Cronjob chạy nền và bắn lệnh Bật DNSSEC tới DirectAdmin thành công, tiến trình này tự động sinh `Generate Keys` tạo chuỗi thông số DS Records cho tên miền.
       * (3) Hiển thị thông số Key Tag, Algorithm, Digest Type, Digest cập nhật ở Giao diện Khách để mang đi cấu hình tại nhà đăng ký.
       * (4) Khóa Zone (Sign) tự động sau mỗi lần Record bị thay đổi. Việc này thực hiện ngầm bởi worker ở chặng cuối sau khi đồng bộ Bảng DNS xong.

### 3.2. Dành cho Quản trị viên (Admin Area)

8. **Bảng Điều khiển Tổng và Đo lường (Dashboard & Metrics)**:
   - Thống kê tỷ lệ Đồng bộ (Sync Pipeline): Số lượng tác vụ `PENDING`, `COMPLETE`, `FAILED` trong 24h qua.
   - Thống kê Tình trạng Dịch vụ (Service Health): Tỷ lệ % Uptime hoặc Connection Error rate tới API DirectAdmin.
   - Thống kê Tổng quan: Tổng số Domain đang quản lý, tổng số Bản ghi DNS hiện tại, Top 5 Domain có lượng bản ghi/thay đổi nhiều nhất.
   - Cảnh báo nhanh màu đỏ nếu tỷ lệ `FAILED` tăng cao quá ngưỡng, biểu thị máy chủ DirectAdmin đang mất kết nối.
9. **Quản lý Tên Miền Toàn Cục (Global Domain Management)**:
   - Admin có quyền xem trực tiếp toàn bộ danh sách `Domains` đang kích hoạt dịch vụ DNS Suite trên Server.
   - Khi nhấp vào 1 domain bất kỳ, Admin có quyền **truy cập vào giao diện Editor DNS (Giống như Client)** để có quyền Tạo / Sửa / Xóa bản ghi DNS, chuyển hướng, tắt/bật DNSSEC *thay cho* người dùng mà không cần Login As Client.
10. **Lịch sử Đồng bộ (Global Sync Logs)**:
   - Bảng DataTables cực nhạy để Admin dò tìm (Search/Filter) toàn bộ vết tích đổi DNS của mọi User trong mạng. 
   - Xem chi tiết: *Domain nào? Thêm record gì? Lúc mấy giờ? IP người thao tác thế nào? Tại sao rớt kết nối?*
11. **Công cụ Sửa Lỗi Tự động (One-Click Retry)**:
    - Nút "Thử lại tất cả Lỗi" (Retry All Failed) gài lại trạng thái về `PENDING` để Cronjob tự làm lại khi DirectAdmin hoạt động bình thường trở lại. Không cần truy cập thủ công DA.
12. **Zone Management**:
    - Quản lý DNS Template chung cho toàn hệ thống để áp dụng khi User mới vừa mua Domain xong là đẩy template vào Queue lấy cấu hình chuẩn.
13. **Tự động Gỡ Lỗi (Auto-healing Queue)**: 
    - Nếu Cronjob gặp lỗi `Timeout` (VD kết nối chậm), thuật toán tự động tăng thời gian chờ (Exponential Backoff) để không đẩy dồn dập vào API của DA, bảo vệ máy chủ rễ không bị sập (DDoS nội bộ).
14. **Tính toán Limit (Data Quota)**:
    - Giới hạn khách hàng A chỉ được tạo tối đa X Record, Y Subdomain, Z Forwarders (dựa trên gói dịch vụ Hosting/Domain họ đã mua ở WHMCS). Tái ứng dụng Data Validation rất tốt từ bản v1.25.

### 3.3. Các Tính năng Quản trị Cấp cao & Bảo mật (Enterprise Standards)

15. **Multi-Server Management (Kiến trúc Fan-out Đồng bộ 3 Node)**:
    - Module quản lý đồng thời cấu hình của 3 Server DirectAdmin (`dns1.hvn.vn`, `dns2.hvn.vn`, `dns3.hvn.vn`).
    - **Áp dụng Cách A (Module đẩy trực tiếp)**: Khi có 1 thay đổi bản ghi DNS, Queue sẽ tạo ra 3 sub-jobs độc lập (hoặc 1 Job nhưng lặp gọi 3 API). Module sẽ chủ động đẩy lệnh cập nhật trực tiếp tới cả Primary (`dns1`) lẫn Secondary (`dns2`, `dns3`). Ưu điểm: Hệ thống WHMCS kiểm soát hoàn toàn trạng thái thành công/thất bại của từng node, ghi log rõ ràng từng IP server và cho phép nút Retry chạy lại chính xác trên Server bị trượt.
16. **Hệ thống Webhook / Monitor Notifications**:
    - Khi tỷ lệ `FAILED` của Cronjob quét qua ngưỡng cảnh báo (VD: 5 lệnh fail liên tiếp), module tự động đẩy thông báo qua qua **Telegram Bot / Slack** hoặc **Email Admin** để SysAdmin ứng cứu ngay.
17. **Audit Trail (Nhật ký Thay đổi Chéo)**:
    - Hệ thống Log lưu chi tiết: Ai là người vừa thực hiện đổi IP trong Data (Khách hàng tự đổi / Admin A login as client để đổi / IP gọi API tự động).
    - Lưu giữ dấu vết kiểm toán (Audit Log) không thể chỉnh sửa để truy vết bảo mật khi có sự cố chiếm quyền tên miền.
18. **Cơ chế Rollback (Khôi phục Snapshot)**:
    - Mỗi khi luồng Queue thực hiện `UPDATE / DELETE` bản ghi, hệ thống giữ lại bản sao (Snapshot) Zone của phút trước đó. Admin cấp cao có nút "Undo - Hoàn tác" để lấy lại dữ liệu nếu khách cấu hình sai làm sập web.
19. **Conflict Resolution (Quy tắc đụng độ)**:
    - Giao thức xử lý xung đột: Nếu Client và Admin cùng lúc ấn "Sửa IP" của một Record trong vòng 3 phút khi Job còn đang ở `PENDING`. \
      $\Rightarrow$ Áp dụng quy tắc: **Admin-Priority** (Lệnh do phiên Admin tạo ra sẽ ghi đè và hủy lệnh chờ của Client).  
20. **Data Integrity Check (Chống Lệch Dữ liệu)**:
    - Cung cấp 1 Script định kỳ (mỗi đêm 1 lần) gọi API tải toàn bộ DB của DirectAdmin thực tế đối chiếu với CSDL Zone Local WHMCS. Nếu có sự sai lệch (Drift - Do ai đó vào hẳn DA sửa tay), hệ thống báo đỏ tại Dashboard yêu cầu Admin ra quyết định (Kéo DA về WHMCS hay Ghi đè WHMCS lên DA).

---

## 4. Công nghệ Khuyên Dùng (Tech Stack)

Để module hoạt động độc lập, nhẹ và bảo mật cao, không vướng vấn đề mã hóa (như bị block bởi IonCube):

*   **Backend Framework**: PHP 7.4 - 8.2 (Tương thích chuẩn WHMCS 8.x Capsule Database).
*   **Database Management (Tiền tố `mod_hvndns_`)**: Sử dụng WHMCS Hook `AfterModuleActivate` / `AfterModuleUpgrade` để thiết lập hệ thống tự tạo bảng CSDL chuyên nghiệp, quản lý các bản cập nhật qua `version_tracking` schema thay cho cách dump SQL chay. (Thống nhất tiền tố `mod_hvndns_` cho khớp với tên module HVN).
*   **Hệ thống Logging (WHMCS Monolog)**: Nghiêm cấm tạo file `.txt` tự ghi log. Tận dụng thư viện chuẩn **Monolog** đã có sẵn tích hợp trong lõi WHMCS (`Log\Log`) cho Queue Worker để ghi nhật ký `info`, `warning`, `error`, tiện cho việc xuất file Audit và debug.
*   **Frontend Template**: Smarty Engine kết hợp **Bootstrap 4/5** + Ajax. Sử dụng **Vue.js** hoặc **Alpine.js** dạng nhẹ (CDN) để làm các DataTables quản lý trạng thái Syncing/Complete real-time ở UI mà không cần tải lại trang.
*   **DA Gateway (Giao tiếp)**: Viết lại class `HTTPSocket` của DA bằng **GuzzleHTTP** hoặc **cURL OOP hiện đại** để bắt Timeout chuẩn xác hơn và không rò rỉ bộ nhớ khi chạy Cron hàng nghìn lệnh.

---

## 5. Chiến lược Triển khai (Phasing / Testing)

Dự án có quy mô phân luồng lớn, bắt buộc phải chia nhỏ quá trình triển khai thay vì làm dồn cục 100% tính năng.

### Phase 1: MVP (Tính năng Khả thi Tối thiểu)
* **Mục tiêu**: Thay thế được bản v1.25 cũ với tốc độ Bất đồng bộ.
* **Hoàn thiện**: Module kết nối 1 DA Node, Client thêm/sửa/xóa record A/MX/TXT. Lưu vào bảng `mod_hvndns_queue` và Cronjob đọc cập nhật thành công lên DirectAdmin. UI hiển thị Log đơn giản. Chưa làm SSL auto, DNSSEC hay Quota Limit.
* **Kế hoạch Test**: Unit Test các class Validator của Queue, thực chạy Load test Cronjob đẩy 200 job liên tục lên một Domain DA Sandbox để bắt Timeout.

### Phase 2: Enterprise Core (Quản trị tập trung)
* **Hoàn thiện**: Code cụm Multi-server DA (Quản lý dns1/dns2/dns3). Xây Admin Dashboard Metrics toàn diện. Click-to-login as Client. Ra mắt URL Forwarding 301, Tự xin Let's Encrypt cho Forwarding. Bật tính năng Conflict Admin-Priority. Hook Webhook bắn lỗi Telegram.
* **Kế hoạch Test**: Integration test gọi API HTTPS Let's Encrypt DA. Giả lập Admin / Client mở 2 tab sửa cùng lúc để soi Conflict Logic.

### Phase 3: Add-on Values (Ra mắt Hoàn chỉnh)
* **Hoàn thiện**: Tool đồng bộ chống Data Drift mỗi đêm, API Client DDNS bảo mật bằng token, sinh keys quản trị DNSSEC, Auto-Healing Cronjob Backoff, tính toán Quota chuẩn WHMCS. Trình bày UI Audit Trail bảo vệ cao cấp.
