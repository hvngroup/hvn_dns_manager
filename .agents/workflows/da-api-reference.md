---
description: Tra cứu DA API nhanh
---

# DA API Quick Reference

Tra cứu nhanh DirectAdmin API command.

## Steps

1. **User hỏi** về DA API command hoặc action cụ thể

2. **Đọc `docs/API_REFERENCE.md` Phần A** và trả lời:
   - Request format (URL, method, parameters)
   - Response format (success + error examples)
   - Gotchas liên quan
   - Error handling (retryable hay không)
   - Code example sử dụng DAGateway

3. **Nếu liên quan đến format mapping** (WHMCS ↔ DA):
   - Hiển thị bảng format differences
   - Chỉ ra DAResponseParser method cần dùng

4. **Nếu liên quan đến error handling**:
   - Hiển thị error classification table
   - Chỉ ra Worker nên handle thế nào