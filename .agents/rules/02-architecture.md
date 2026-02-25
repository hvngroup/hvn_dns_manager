---
trigger: always_on
---

# Kiến trúc Bất đồng bộ — Quy tắc Tuyệt đối

## Nguyên tắc Async-First
Mọi thao tác thay đổi DNS PHẢI đi qua hàng đợi (Queue). KHÔNG BAO GIỜ gọi API DirectAdmin trong request lifecycle của Client hoặc Admin.

### TUYỆT ĐỐI CẤM
- Gọi API DirectAdmin trong Controller hoặc Service khi xử lý HTTP request
- Sử dụng `curl_init()`, `file_get_contents()`, `HTTPSocket` tới DA server trong bất kỳ file nào ngoài `cron/` và `Gateway/`
- Chờ đợi response từ DA trước khi trả kết quả cho user
- Import hoặc sử dụng class `DAGateway` trong Controller

### BẮT BUỘC
- Mọi thay đổi DNS → `QueueManager::dispatch()` → Lưu DB → Trả JSON success cho user
- Chỉ các file trong `cron/` mới được gọi `DAGateway`
- Response cho user phải hoàn thành trong < 200ms (chỉ write DB)

### Ngoại lệ duy nhất
`DAGateway::testConnection()` được gọi từ Admin Controller khi bấm nút "Test Connection" — đây là hành động diagnostic có chủ đích.

## Fan-out Multi-Server
- `QueueManager::dispatch()` LUÔN query `ServerRegistry::getActiveServers()`
- Tạo N sub-jobs độc lập (1 job/server) với cùng `batch_id` (UUID v4)
- Mỗi sub-job có `server_id` riêng, `status` riêng, retry riêng
- KHÔNG hardcode số lượng server, KHÔNG giả định số server cố định

## WHMCS là Source of Truth
- Database WHMCS (`mod_hvndns_records`) là nguồn dữ liệu chính thức
- DirectAdmin là target execution layer, KHÔNG phải source of truth
- Khi có xung đột, dữ liệu WHMCS được ưu tiên