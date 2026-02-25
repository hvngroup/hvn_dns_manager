---
description: Implement toàn bộ story
---

# Implement Story

Quy trình implement toàn bộ 1 Story (nhiều Issues).

## Input
User cung cấp Story ID (VD: Story 1.1, Story 2.1, Story 3.2)

## Steps

1. **Đọc Story** trong `docs/EPICS.md`:
   - Liệt kê TẤT CẢ Issues trong Story
   - Đọc Acceptance Criteria tổng thể

2. **Phân tích dependency**:
   - Sắp xếp Issues theo thứ tự phụ thuộc
   - Đề xuất thứ tự implement

3. **Implement từng Issue** theo thứ tự:
   - Dùng quy trình `/implement` cho mỗi issue
   - Sau mỗi issue, confirm với user trước khi tiếp

4. **Tổng kết Story**:
   - Liệt kê tất cả AC
   - Đánh dấu pass/fail cho từng AC
   - Liệt kê files đã tạo/sửa
   - Đề xuất test cần chạy