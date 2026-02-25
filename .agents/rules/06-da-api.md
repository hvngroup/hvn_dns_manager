---
trigger: glob
globs: **/Gateway/**
---

# DirectAdmin API — Quy tắc khi code Gateway

## LUÔN dùng DAResponseParser
KHÔNG BAO GIỜ build DA API parameters thủ công. Luôn dùng:
- `DAResponseParser::buildDAParams()` để chuyển WHMCS format → DA format
- `DAResponseParser::parseRecord()` để chuyển DA format → WHMCS format
- `DAResponseParser::buildAressionParam()` để build tham số edit record

## 10 Gotchas bắt buộc (chi tiết: docs/API_REFERENCE.md Section A8)
1. Root domain name: WHMCS `"@"` ↔ DA `""` (empty string)
2. CNAME/MX/NS value: cần trailing dot `.` khi gửi lên DA
3. TXT value: cần escaped quotes khi gửi, strip quotes khi parse
4. SRV value: gộp `"weight port target."` vào 1 string
5. Edit record: tham số tên `arression` (KHÔNG phải `aression`)
6. DA error field: string `"1"` — kiểm tra `isset()` không phải `=== true`
7. CREATE_ZONE: chỉ ns1 + ns2, ns3 phải thêm bằng ADD_RECORD riêng
8. DELETE record not found → coi như success (idempotent)
9. CREATE_ZONE zone exists → coi như success (idempotent)
10. Let's Encrypt: response trả trước khi cert ready, cần đợi + verify

## Error Classification
- `timeout`, `rate_limit`, `server_error`, `network_error` → Retryable
- `auth_fail` → PERMANENTLY_FAILED + alert Admin
- `dns_conflict`, `zone_not_found` → FAILED non-retryable
- `zone_exists` (khi CREATE) → coi như success

## GuzzleHTTP Config
- Connect timeout: 15 giây
- Request timeout: 30 giây
- Luôn gửi `json=yes` để nhận JSON response
- Content-Type: `application/x-www-form-urlencoded` (DA không hỗ trợ JSON body)
- HTTP errors: `false` (không throw exception cho 4xx/5xx, tự handle)