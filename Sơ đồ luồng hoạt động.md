# Sơ đồ Luồng Hoạt Động (Architecture Flow)

Tài liệu này mô tả chi tiết luồng dữ liệu (Data Flow) và trình tự thời gian (Sequence) của hệ thống **Asynchronous DNS Queue** cho WHMCS DNS Suite.

Mô hình này chuyển đổi cấu trúc đồng bộ (chờ phản hồi trực tiếp) thành bất đồng bộ (giải phóng trình duyệt ngay lập tức và xử lý nền).

## Biểu đồ Sequence (Trình tự)

```mermaid
sequenceDiagram
    participant C as Khách hàng (Trình duyệt)
    participant W as WHMCS (DNS Suite Controller)
    participant DB as Tiện ích Cơ sở dữ liệu (mod_dnssuite_sync_queue)
    participant Cron as Cronjob (Background Worker)
    participant DA as Máy chủ DirectAdmin (API)
    participant Root as Root Server (Name Server Zone)
    
    %% Luồng 1: Ghi nhận (Asynchronous Save) - Phân tách với API
    Note over C, DB: Luồng 1: Xử lý Tức thời (Trực tiếp với UX)
    C->>+W: Gửi yêu cầu thay đổi DNS (Thêm/Sửa/Xóa cấu hình)
    W->>W: Validate dữ liệu đầu vào (IP, định dạng Record)
    W->>+DB: Lưu cầu trúc vào hàng đợi
    Note right of DB: Status: PENDING<br>Data: old_json, new_json
    DB-->>-W: Xác nhận Insert thành công
    W-->>-C: Phản hồi "Thành công - Đã đưa vào Hàng đợi"
    
    %% Luồng 2: Xử lý đồng bộ (Background Sync) - Chạy nền
    Note over Cron, Root: Luồng 2: Đồng bộ ngầm (Chạy nền mỗi 1-5 phút)
    loop Mỗi chu kỳ 5 phút
        Cron->>+DB: Quét (Fetch) danh sách các bản ghi pending
        DB-->>-Cron: Trả về một mảng Mảng công việc (Queue Jobs)
        Cron->>+DB: Khóa tiến trình bằng cách Cập nhật
        Note right of DB: Status: SYNCING<br>(Đảm bảo an toàn đa luồng)
        DB-->>-Cron: Lock success
        
        loop Từng công việc trong hàng đợi (Foreach Queue Job)
            Cron->>+DA: Cấu hình cURL & Bắn lệnh API cập nhật
            DA->>+Root: Phân giải Command thành lệnh thay đổi Zone
            Root-->>-DA: Viết file config & Restart bind/named
            
            alt Phản hồi Thành công
                DA-->>Cron: HTTP 200 OK (Thành công)
                Cron->>DB: Đánh dấu cập nhật
                Note right of DB: Status: COMPLETE
            else Phản hồi Thất bại (Auth sai, Mất mạng, Lỗi Zone)
                DA-->>-Cron: HTTP Error (hoặc cURL timeout 100s)
                Cron->>DB: Đánh dấu lỗi
                Note right of DB: Status: FAILED<br>Lý do (Fail Reason Text)
            end
        end
    end
    
    %% Luồng 3: Giám sát Log
    Note over C, DB: Luồng 3: Xem Lịch sử (Giám sát Đồng bộ)
    C->>+W: Truy cập Tab "Nhật ký Lịch sử Đồng bộ"
    W->>+DB: Thực thi truy vấn lấy trạng thái các Queue thuộc về Domain này
    DB-->>-W: Trả mảng kết quả (Chứa các badge Complete / Failed)
    W-->>-C: Render ra UI hiển thị Bảng theo dõi
```

## Chú giải (Legend)

*   **Luồng 1 (Xử lý Tức thời)**: Điểm nghẽn ở hệ thống cũ nằm ở chỗ máy Khách hàng (`C`) phải mở kết nối thẳng đến `DA`. Với lược đồ mới, mọi thứ kết thúc ở Database (`DB`), do đó, độ trễ web chỉ tính bằng **< 10ms**.
*   **Luồng 2 (Đồng bộ Ngầm)**: Cronjob hoạt động độc lập với tương tác của người dùng. Trạng thái `SYNCING` được đưa vào để ngăn chặn hiện tượng hai luồng cronjob chạy gần nhau cùng lấy một lệnh và đẩy lên DA hai lần (Duplicate Data / Race condition).
*   **Root Server**: Bản chất DirectAdmin API sẽ chỉnh sửa file `.db` zone ở thư mục hệ thống (thường nằm tại `/var/named/testdomain.com.db`) và reload lại dịch vụ `named`/`bind`, tức thì phản ánh thay đổi cấu hình hạ tầng mạng trên Internet thực tế.
