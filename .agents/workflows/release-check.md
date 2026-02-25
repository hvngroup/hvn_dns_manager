---
description: 
---

# Pre-Release Checklist

Kiểm tra đầy đủ trước khi deploy (từ TEST_PLAN.md Section 14).

## Steps

1. **Code Quality**:
   - [ ] Tất cả Unit Tests pass
   - [ ] Tất cả Integration Tests pass
   - [ ] Code coverage ≥ 80% cho Services/ và Validators/
   - [ ] Không có TODO/FIXME trong code production
   - [ ] PHPDoc đầy đủ

2. **Security**:
   - [ ] Security Tests pass
   - [ ] DA password encrypted trong DB
   - [ ] Client responses không chứa server credentials
   - [ ] CSRF enforced trên POST endpoints
   - [ ] Audit trail ghi đúng

3. **Performance**:
   - [ ] Client add record < 200ms
   - [ ] Admin Dashboard < 2s
   - [ ] DDNS endpoint < 100ms
   - [ ] DB queries dùng đúng indexes

4. **Database**:
   - [ ] Migration chạy OK (fresh + upgrade)
   - [ ] Migration idempotent
   - [ ] Backup trước deploy

5. **Regression Suite**: 20 critical tests PHẢI pass 100%

6. **Output**: Checklist với ✅/❌ cho từng item