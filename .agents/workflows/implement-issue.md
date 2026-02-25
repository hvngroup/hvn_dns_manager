---
description: Implement 1 issue
---

# Implement Issue

Quy trình implement 1 issue cụ thể từ EPICS.md.

## Input
User cung cấp Issue ID (VD: QUEUE-001, CLIENT-006, ADMIN-010)

## Steps

1. **Tìm Issue** trong `docs/EPICS.md`:
   - Đọc mô tả issue, Story Point
   - Đọc Acceptance Criteria (AC) của Story chứa issue đó
   - Xác định issue thuộc Phase nào — nếu không phải Phase hiện tại, CẢNH BÁO

2. **Tham chiếu tài liệu phù hợp**:
   - Database → đọc `docs/DB_SCHEMA.md` cho bảng liên quan
   - DA API → đọc `docs/API_REFERENCE.md` Phần A
   - Ajax endpoint → đọc `docs/API_REFERENCE.md` Phần B
   - UI/Template → đọc `docs/WIREFRAME.md`
   - Flow logic → đọc `docs/SPEC.md`

3. **Kiểm tra dependencies**:
   - Issue phụ thuộc issue nào khác?
   - Class/table/service cần thiết đã tồn tại chưa?
   - Nếu thiếu → liệt kê và hỏi có tạo dependency trước không

4. **Kiểm tra test plan**:
   - Tìm test cases liên quan trong `docs/TEST_PLAN.md`
   - Nếu có → viết test TRƯỚC code (TDD)

5. **Sinh code**:
   - Tuân thủ tất cả Rules đã định nghĩa
   - Code hoàn chỉnh, chạy được — KHÔNG sinh stub/placeholder
   - Bao gồm PHPDoc, type hints, error handling, logging

6. **Sinh test**:
   - Viết Unit Test cho logic mới
   - Dùng TestData fixtures, mock dependencies

7. **Xác nhận AC**:
   - Liệt kê từng AC của Story
   - Đánh dấu AC nào đã đáp ứng, AC nào chưa
   - Đề xuất bước tiếp theo nếu cần