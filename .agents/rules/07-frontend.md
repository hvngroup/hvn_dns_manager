---
trigger: glob
globs: **/*.tpl, **/*.js, **/assets/**
---

# Frontend Rules

## Tech Stack
- Template Engine: Smarty (WHMCS built-in)
- CSS: Native CSS (WHMCS) + Pure CSS (KHÔNG DÙNG Bootstrap 5 hay CDN ngoài)
- JS Reactivity: Alpine.js 3.x (CDN + local fallback)
- DataTables: DataTables.net 1.13.x (CDN)
- Charts (Admin): Chart.js 4.x (CDN)
- KHÔNG dùng jQuery trừ khi WHMCS theme yêu cầu
- KHÔNG dùng Vue.js, React, hoặc bất kỳ framework nào cần build step

## Smarty Template Rules
- Escape MỌI dynamic data: `{$var|escape:'htmlall'}`
- Form PHẢI có CSRF token: `<input type="hidden" name="token" value="{$token}">`
- Tham chiếu WIREFRAME.md cho layout từng màn hình
- Client templates: `templates/client/` → WIREFRAME CL-01 đến CL-08
- Admin templates: `templates/admin/` → WIREFRAME AD-01 đến AD-12

### Quy tắc Delimiter — Tránh conflict Smarty vs JS/Alpine/CSS

Smarty engine parse TẤT CẢ `{ }` thành Smarty tags. Khi viết template có chứa JavaScript, Alpine.js, hoặc CSS inline → PHẢI bọc `{literal}...{/literal}`.

**NGUYÊN TẮC: Khi nào cần `{literal}`?**

| Context | Cần `{literal}`? | Ví dụ |
|---------|:---:|--------|
| Smarty variable | ❌ | `{$domain.name}` |
| `<script>` block | ✅ BẮT BUỘC | `<script>{literal}...{/literal}</script>` |
| `<style>` block | ✅ BẮT BUỘC | `<style>{literal}...{/literal}</style>` |
| Alpine.js `x-data` | ✅ BẮT BUỘC | `x-data="{literal}{ open: false }{/literal}"` |
| Alpine.js `:class` object | ✅ BẮT BUỘC | `:class="{literal}{ 'active': val }{/literal}"` |
| Alpine.js `x-on` / `@click` (no braces) | ❌ | `@click="count++"` |

**CẤM BIÊN DỊCH TRỰC TIẾP:**
```smarty
{* ❌ SAI — Smarty cố parse { open: false } thành Smarty tag → LỖI *}
<div x-data="{ open: false }"></div>
<script>
    const obj = { key: 'value' };
</script>

{* ✅ ĐÚNG — Bọc {literal} cho mọi JS/Alpine object/CSS block *}
<div x-data="{literal}{ open: false }{/literal}"></div>
<script>
{literal}
    const obj = { key: 'value' };
{/literal}
</script>
```

**Kỹ thuật kết hợp Smarty variable TRONG JS:**
Tuyệt đối KHÔNG ĐẶT biến `{$var}` bên trong `{literal}`.
```smarty
{* ── Cách ĐÚNG: Script variable trước {literal} block ── *}
<script>
    var HVNDNS_CONFIG = { domainId: {$domain.id} };
</script>
<script>
{literal}
    console.log(HVNDNS_CONFIG.domainId);
{/literal}
</script>
```

## Alpine.js Rules
- Mọi API call qua `fetch()` với JSON (KHÔNG dùng jQuery Ajax)
- Error handling cho MỌI fetch call (try-catch)
- Loading state cho mọi action (spinner/disabled button)
- Sync Status Polling: 5 giây interval, tự dừng khi complete/failed

## Bảo mật Frontend
- KHÔNG hiển thị server IP, port, credentials cho Client
- Client chỉ thấy hostname (dns1.hvn.vn)
- Error messages thân thiện tiếng Việt, không technical details
- CSP header: `script-src 'self' cdnjs.cloudflare.com`