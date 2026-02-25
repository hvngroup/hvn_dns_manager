---
trigger: always_on
---

---
activation: always
---

# Security Rules — Không Thỏa Hiệp

## Input Validation
- MỌI user input → `InputSanitizer::clean()` → `DnsRecordValidator::validate()`
- KHÔNG trust bất kỳ input nào từ user mà không validate
- CSRF protection qua WHMCS token system cho mọi POST request

## Data Protection
- Client Area KHÔNG BAO GIỜ thấy: server IP, port, password, raw error từ DA
- Client chỉ thấy: server hostname (dns1.hvn.vn), thông báo lỗi thân thiện
- Error message cho client: generic "Đồng bộ thất bại", KHÔNG leak technical details
- Admin Area: hiển thị đầy đủ nhưng password luôn masked (••••••)

## Forbidden Operations
- KHÔNG sử dụng: `eval()`, `exec()`, `shell_exec()`, `system()`
- KHÔNG lưu DDNS token plaintext (phải SHA-256 hash)
- KHÔNG expose raw DA error message, stack trace, SQL error cho client
- KHÔNG tạo endpoint nào cho phép UPDATE/DELETE bảng `audit_trail`

## Encryption
- DA Server password: `WHMCS\Security\Encryption::encode()` (AES-256)
- DDNS Token: SHA-256 hash (one-way) — plain token chỉ hiển thị 1 lần khi tạo
- Telegram Bot Token: `WHMCS\Security\Encryption::encode()`