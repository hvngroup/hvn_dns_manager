---
trigger: glob
globs: **/*.tpl, **/*.js, **/assets/**
---

# Frontend Rules

## Tech Stack
- Template Engine: Smarty (WHMCS built-in)
- CSS: Bootstrap 5.3.x (CDN)
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