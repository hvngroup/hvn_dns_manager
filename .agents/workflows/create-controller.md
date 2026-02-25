---
description: Tạo Controller + Ajax endpoint
---

# Create Controller + Ajax Endpoint

Tạo Controller mới với Ajax endpoints.

## Steps

1. **Đọc API_REFERENCE.md Phần B** cho endpoints cần tạo

2. **Tạo Controller** tại `app/Controllers/{Name}Controller.php`:
   - Controller KHÔNG chứa business logic (chỉ gọi Service)
   - Mỗi action method: nhận params → gọi Service → trả ResponseHelper

3. **Tạo/cập nhật route** trong entry point

4. **Response format**: tuân thủ chuẩn JSON (success/error)

5. **Security**:
   - CSRF check cho POST
   - Permission check (client chỉ truy cập domain của mình)
   - Rate limit check nếu cần
   - Input sanitization

6. **Đọc WIREFRAME.md** nếu endpoint phục vụ UI cụ thể