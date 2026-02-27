<div class="d-flex justify-content-between align-items-center mb-3">
    <h5 class="mb-0">Chuyển tiếp Email</h5>
    <button class="btn btn-primary btn-sm" onclick="alert('Đang mở Modal thêm Email Forward (Mock)')">
        <i class="bi bi-plus-lg"></i> Thêm chuyển tiếp
    </button>
</div>

<div class="table-responsive mb-4">
    <table class="table table-hover align-middle">
        <thead class="table-light">
            <tr>
                <th>Từ</th>
                <th>Chuyển đến</th>
                <th>Trạng thái</th>
                <th class="text-end">Hành động</th>
            </tr>
        </thead>
        <tbody>
            <tr>
                <td class="font-monospace">info@{$domain.domain}</td>
                <td class="font-monospace">personal@gmail.com</td>
                <td><span class="text-success"><i class="bi bi-check-circle-fill"></i> Live</span></td>
                <td class="text-end">
                    <div class="btn-group btn-group-sm">
                        <button class="btn btn-outline-secondary"><i class="bi bi-pencil"></i></button>
                        <button class="btn btn-outline-danger"><i class="bi bi-trash"></i></button>
                    </div>
                </td>
            </tr>
            <tr>
                <td class="font-monospace">support@{$domain.domain}</td>
                <td class="font-monospace">team@company.com</td>
                <td><span class="text-success"><i class="bi bi-check-circle-fill"></i> Live</span></td>
                <td class="text-end">
                    <div class="btn-group btn-group-sm">
                        <button class="btn btn-outline-secondary"><i class="bi bi-pencil"></i></button>
                        <button class="btn btn-outline-danger"><i class="bi bi-trash"></i></button>
                    </div>
                </td>
            </tr>
        </tbody>
    </table>
</div>

<div class="card mb-3 border-secondary">
    <div class="card-header bg-light">
        <h6 class="mb-0">Catch-all (Nhận mọi email)</h6>
    </div>
    <div class="card-body">
        <div class="form-check form-switch mb-2">
            <input class="form-check-input" type="checkbox" id="catchallToggle">
            <label class="form-check-label" for="catchallToggle">
                Chuyển mọi email gửi tới sai địa chỉ về email này:
            </label>
        </div>
        <div class="input-group input-group-sm w-50 mb-2">
            <span class="input-group-text">*@{$domain.domain} &rarr;</span>
            <input type="email" class="form-control" placeholder="backup@gmail.com" disabled>
            <button class="btn btn-outline-secondary" disabled>Lưu</button>
        </div>
        <div class="text-warning small">
            <i class="bi bi-exclamation-triangle-fill"></i> <strong>Cảnh báo:</strong> Bật catch-all đồng nghĩa với việc bạn sẽ nhận tất cả thư rác (spam) gửi tới tên miền của mình.
        </div>
    </div>
</div>

<div class="alert alert-secondary py-2">
    <i class="bi bi-bar-chart-fill"></i> Đang dùng: <strong>2/10</strong> chuyển tiếp
</div>

{literal}
<script>
    document.getElementById('catchallToggle').addEventListener('change', function() {
        var inputs = this.closest('.card-body').querySelectorAll('input[type="email"], button');
        inputs.forEach(function(el) { el.disabled = !this.checked; }.bind(this));
    });
</script>
{/literal}
