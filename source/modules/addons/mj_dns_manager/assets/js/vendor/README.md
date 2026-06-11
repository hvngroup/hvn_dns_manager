# Vendor JS — Alpine.js local fallback

Theo chuẩn MJ (no CDN dependency risk), thả file **`alpine.min.js`** phiên bản
**3.14.8** vào thư mục này:

```
curl -o alpine.min.js https://cdn.jsdelivr.net/npm/alpinejs@3.14.8/dist/cdn.min.js
```

Cơ chế (xem `app/Helpers/AssetInliner::alpineLoader()`):
- **Có** `alpine.min.js` tại đây → Alpine được bơm **inline từ disk** (zero CDN).
- **Chưa có** → tự fallback tải CDN jsDelivr (chỉ chấp nhận cho dev/staging).

> Bắt buộc vendor file này trước khi đóng gói bản thương mại (Phase 10 —
> ionCube). Môi trường build hiện tại chặn outbound network nên chưa kèm sẵn.

## Chart.js — ĐÃ LOẠI BỎ

Dashboard admin **không còn phụ thuộc Chart.js**. Biểu đồ Sync Pipeline được vẽ
bằng **SVG inline** (xem `dashboardManager().renderChart()` trong
`assets/js/mj-dns.js`) — zero CDN, không cần vendor thêm file nào.
