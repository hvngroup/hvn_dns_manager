---
description: Debug và sửa bug
---

# Debug & Fix Bug

Quy trình tìm và sửa bug.

## Input
User mô tả bug (error message, behavior sai, screenshot)

## Steps

1. **Phân tích bug**:
   - Xác định component bị lỗi (Queue? Gateway? Validator? UI?)
   - Tìm file/function liên quan
   - Đọc error logs nếu có

2. **Tái hiện**:
   - Xác định input gây lỗi
   - Trace qua code flow (tham chiếu SPEC.md flow diagrams)

3. **Tìm root cause**:
   - Kiểm tra: input validation? logic error? DA API format? race condition?
   - Kiểm tra gotchas DA API (docs/API_REFERENCE.md A8)

4. **Fix**:
   - Sửa code tối thiểu (không refactor ngoài scope)
   - Giữ backward compatible
   - Thêm logging nếu bug khó detect

5. **Viết regression test**:
   - Test case tái hiện bug → pass sau khi fix
   - Thêm vào regression suite nếu critical

6. **Verify** fix không break tính năng khác