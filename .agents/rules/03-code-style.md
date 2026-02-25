---
trigger: always_on
---

# PHP Coding Conventions

## Naming
- Class: `PascalCase` (VD: `QueueManager`, `DnsRecordValidator`)
- Method/Function: `camelCase` (VD: `dispatch()`, `getActiveServers()`)
- Variable: `camelCase` (VD: `$batchId`, `$domainId`)
- Constant: `UPPER_SNAKE_CASE` (VD: `MAX_RETRY`, `STATUS_PENDING`)
- DB table: `mod_hvndns_` + `snake_case` (VD: `mod_hvndns_queue`)
- DB column: `snake_case` (VD: `domain_id`, `created_at`)

## Cấu trúc code
- Mọi class trong `app/` PHẢI có namespace `HvnGroup\DnsManager\{SubDir}`
- Mọi public method PHẢI có PHPDoc với `@param`, `@return`, `@throws`
- Mọi method PHẢI có type declarations cho parameters và return types
- Visibility LUÔN explicit (`public`, `private`, `protected`)

## Controller Pattern
- Controller KHÔNG chứa business logic
- Controller chỉ: nhận request → gọi Service → trả response
- Business logic đặt trong `Services/`
- Validation đặt trong `Validators/`

## Response Format (cho mọi Ajax endpoint)
```json
// Success
{"success": true, "data": {...}, "message": "..."}

// Error
{"success": false, "error": {"code": "ERROR_CODE", "message": "...", "field": "..."}}
```

## Logging
- Sử dụng Monolog qua WHMCS (KHÔNG tự tạo file .txt)
- `info` — sự kiện bình thường (dispatch, complete)
- `warning` — có vấn đề nhưng tiếp tục được (retry, backoff)
- `error` — lỗi cần chú ý (connection fail, auth fail)
- KHÔNG BAO GIỜ log: passwords, tokens, credentials, stack traces chứa credentials