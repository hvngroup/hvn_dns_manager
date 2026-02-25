---
description: Sinh test cho file/issue
---

# Generate Tests

Sinh test cases cho 1 file hoặc 1 issue.

## Steps

1. **Xác định scope**:
   - User chỉ định file cụ thể HOẶC Issue ID
   - Nếu Issue ID → tìm test cases trong `docs/TEST_PLAN.md`

2. **Phân tích code** cần test:
   - Liệt kê tất cả public methods
   - Xác định: input types, output types, side effects, exceptions

3. **Sinh test file**:
   - Đặt đúng vị trí: `tests/Unit/` hoặc `tests/Integration/`
   - Naming: `{ClassName}Test.php`
   - Method naming: `test_{what}_{scenario}_{expected}`
   - Dùng TestData fixtures từ `tests/Fixtures/TestData.php`
   - Pattern: Arrange → Act → Assert

4. **Test categories** phải bao gồm:
   - Happy path (input hợp lệ → output đúng)
   - Validation errors (input sai → exception/error)
   - Edge cases (null, empty, max length, boundary values)
   - Error handling (DA timeout, DB fail)
   - Security (injection attempts, unauthorized access)

5. **Verify test chạy được**:
   - Suggest: `phpunit --filter {TestClassName}`
   - Check mock setup đúng