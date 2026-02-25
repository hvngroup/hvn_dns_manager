---
description: Tạo Eloquent Model
---

# Create Eloquent Model

Tạo 1 Eloquent Model mới theo chuẩn DB_SCHEMA.md.

## Input
User chỉ định tên bảng (VD: `mod_hvndns_servers`, hoặc tên ngắn `servers`)

## Steps

1. **Đọc schema** từ `docs/DB_SCHEMA.md`:
   - Tìm bảng tương ứng
   - Liệt kê tất cả cột, data types, constraints

2. **Tạo Model file** tại `app/Models/{ModelName}.php`:
   - `$table` = tên bảng đầy đủ
   - `$fillable` = TẤT CẢ cột có thể mass assign (trừ id, timestamps, encrypted fields)
   - `$casts` = mapping type (boolean, integer, array)
   - `$hidden` = fields nhạy cảm
   - Relationships dựa trên ERD
   - Scopes thường dùng

3. **Áp dụng quy tắc đặc biệt** (nếu có):
   - AuditTrail → Block update/delete
   - Server → Encrypt/decrypt password mutator
   - DdnsToken → Hash token methods
   - IpBlacklist → Active/expired scopes

4. **Output**: File Model hoàn chỉnh, sẵn sàng sử dụng