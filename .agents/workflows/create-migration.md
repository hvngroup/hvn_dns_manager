---
description: 
---

# Create Database Migration

Tạo migration file cho phiên bản mới.

## Input
User chỉ định version (VD: v1_0_0) và mô tả thay đổi

## Steps

1. **Tạo file** tại `app/Migration/versions/{version}.php`

2. **Đọc DB_SCHEMA.md** cho bảng cần tạo/sửa

3. **Sinh migration code**:
   - Dùng `Illuminate\Database\Capsule\Manager as Capsule`
   - Kiểm tra `hasTable()` trước khi `create()` (idempotent)
   - Tạo indexes theo DB_SCHEMA.md
   - Foreign keys cho referential integrity
   - KHÔNG dùng `DROP TABLE` (chỉ add columns, add tables)

4. **Cập nhật** `schema_version` entry

5. **Verify** migration có thể chạy 2 lần không lỗi