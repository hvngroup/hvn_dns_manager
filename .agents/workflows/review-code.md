---
description: Review code file
---

# Review Code

Review 1 file hoặc tập file, kiểm tra tuân thủ convention và phát hiện bug.

## Steps

1. **Đọc file** cần review

2. **Kiểm tra conventions** (theo Rules):
   - [ ] Namespace đúng cấu trúc thư mục?
   - [ ] PHPDoc đầy đủ cho public methods?
   - [ ] Type declarations cho params và return?
   - [ ] Naming convention (PascalCase class, camelCase method)?
   - [ ] Không có raw SQL?
   - [ ] Không gọi DA API trong Controller?
   - [ ] User input qua Sanitizer + Validator?
   - [ ] Response format đúng chuẩn JSON?
   - [ ] Logging đúng level, không log sensitive data?
   - [ ] CSRF token trong forms?
   - [ ] Smarty escape dynamic data?

3. **Kiểm tra bảo mật**:
   - [ ] Không leak server IP/credentials cho client?
   - [ ] Password encrypted?
   - [ ] Audit trail ghi đúng?
   - [ ] Không có eval/exec/shell_exec?

4. **Kiểm tra logic**:
   - [ ] Có xử lý error cases?
   - [ ] Có edge cases chưa handle?
   - [ ] Có race condition tiềm ẩn?
   - [ ] Performance OK? (N+1 query? missing index?)

5. **Output**:
   - Danh sách vấn đề tìm thấy (severity: Critical/Major/Minor/Cosmetic)
   - Đề xuất fix cho mỗi vấn đề
   - Điểm đánh giá tổng: ✅ Pass / ⚠️ Pass with notes / ❌ Fail