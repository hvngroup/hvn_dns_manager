---
description: Tạo Smarty template
---

# Create Smarty Template

Tạo template mới cho Client hoặc Admin Area.

## Input
User chỉ định màn hình (VD: CL-02, AD-01)

## Steps

1. **Đọc WIREFRAME.md** cho màn hình tương ứng

2. **Tạo file .tpl** tại `templates/client/` hoặc `templates/admin/`

3. **Quy tắc cơ bản**:
   - Escape dynamic data: `{$var|escape:'htmlall'}`
   - CSRF token trong forms: `<input type="hidden" name="token" value="{$token}">`
   - Alpine.js cho reactivity (x-data, x-show, x-on)
   - Responsive: hoạt động trên mobile

4. **Quy tắc `{literal}` — BẮT BUỘC** (tham chiếu `docs/AGENT.md` Section 3.6):
   - MỌI `<script>` block phải bọc `{literal}...{/literal}`
   - MỌI `<style>` block phải bọc `{literal}...{/literal}`
   - Alpine `:class`, `x-data` object phải bọc `{literal}...{/literal}`

   ⚠️ **GOTCHA — Không bao giờ viết Smarty tag trong JS comment:**
   ```
   // SAI: // Bien Smarty khai bao NGOAI {literal} block  ← {literal} trong comment = LỖI
   // ĐÚNG: // Khai bao bien JS nguyen thuy ngoai literal block
   ```
   Smarty parse TẤT CẢ `{ }` kể cả trong `//` comment. Xem chi tiết: `docs/AGENT.md` CAUTION block Section 3.6.

5. **Kỹ thuật truyền Smarty var vào JS** (KHÔNG đặt `{$var}` bên trong `{literal}`):
   ```smarty
   <script>
       var PAGE_DATA = { domainId: {$domain.id}, token: '{$token}' };
   </script>
   <script>
   {literal}
       // Dùng PAGE_DATA.domainId ở đây
   {/literal}
   </script>
   ```

6. **Tích hợp Alpine.js** component nếu cần:
   - Polling, loading states, toast notifications

7. **KHÔNG hiển thị** server IP/credentials cho client templates

8. **Checklist trước khi hoàn thành**:
   - [ ] Không có `{$var}` nằm bên trong `{literal}...{/literal}`
   - [ ] Không có Smarty tag (`{literal}`, `{if}`, `{$var}`...) trong JS comment `//` hoặc `/* */`
   - [ ] Tất cả `<script>` và `<style>` block đã bọc `{literal}`
   - [ ] Dynamic data đã escape bằng `|escape:'htmlall'`