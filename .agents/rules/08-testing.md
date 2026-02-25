---
trigger: always_on
---

---
activation:
  glob: "**/tests/**"
---

# Testing Rules

## Cấu trúc Test
- `tests/Unit/` → Mock everything, test 1 class (target < 30s total)
- `tests/Integration/` → Real MySQL, mock DA API (target < 2 min)
- `tests/E2E/` → Real browser + DA Sandbox (target < 15 min)
- `tests/Security/` → Injection, XSS, auth bypass
- `tests/Performance/` → Response time, load test
- `tests/Fixtures/TestData.php` → Shared test data

## Naming Convention
- File: mirror cấu trúc `app/` — VD: `app/Services/QueueManager.php` → `tests/Unit/Services/QueueManagerTest.php`
- Method: `test_{what}_{scenario}_{expected}`
- VD: `test_valid_ipv4_accepted`, `test_dispatch_creates_jobs_for_all_active_servers`

## Pattern
- Arrange → Act → Assert (AAA)
- 1 assert per concept (có thể nhiều assert cùng 1 behavior)
- Luôn dùng `TestData` fixtures, KHÔNG hardcode giá trị trong test method

## Mock Rules
- Mock DA API: GuzzleHTTP MockHandler — KHÔNG gọi DA thật trong Unit/Integration
- Unit test: KHÔNG chạm database
- Integration test: dùng MySQL test database, cleanup after each test

## Coverage Target
- `Services/` ≥ 80%
- `Validators/` ≥ 90%
- `Gateway/` ≥ 80%
- `Controllers/` ≥ 60%

## Regression (PHẢI pass 100% trước deploy)
REG-001..005 Queue, REG-006..010 DNS, REG-011..015 Security,
REG-016..018 Provisioning, REG-019..020 Database