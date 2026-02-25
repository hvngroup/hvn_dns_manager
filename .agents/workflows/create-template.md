---
description: 
---

# Create Smarty Template

Tạo template mới cho Client hoặc Admin Area.

## Input
User chỉ định màn hình (VD: CL-02, AD-01)

## Steps

1. **Đọc WIREFRAME.md** cho màn hình tương ứng

2. **Tạo file .tpl** tại `templates/client/` hoặc `templates/admin/`

3. **Quy tắc**:
   - Bootstrap 5 grid system
   - Escape dynamic data: `{$var|escape:'htmlall'}`
   - CSRF token trong forms
   - Alpine.js cho reactivity (x-data, x-show, x-on)
   - KHÔNG dùng inline JavaScript (tách ra file .js riêng)
   - Responsive: hoạt động trên mobile

4. **Tích hợp Alpine.js** component nếu cần:
   - Tạo file JS tại `assets/js/`
   - Polling, loading states, toast notifications

5. **KHÔNG hiển thị** server IP/credentials cho client templates