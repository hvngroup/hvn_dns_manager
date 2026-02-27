<div class="d-flex justify-content-between align-items-center mb-3">
    <h5 class="mb-0">Chuyển hướng URL</h5>
    <button class="btn btn-primary btn-sm" onclick="alert('Đang mở Modal thêm Redirect (Mock)')">
        <i class="bi bi-plus-lg"></i> Thêm chuyển hướng
    </button>
</div>

<div class="table-responsive mb-3">
    <table class="table table-hover align-middle">
        <thead class="table-light">
            <tr>
                <th>Nguồn</th>
                <th>Đích</th>
                <th>Loại</th>
                <th>Trạng thái</th>
                <th class="text-end">Hành động</th>
            </tr>
        </thead>
        <tbody>
            <tr>
                <td class="font-monospace">/</td>
                <td class="font-monospace">https://newsite.com</td>
                <td>
                    <span class="badge bg-primary">301</span>
                    <span class="d-block small text-muted">Vĩnh viễn</span>
                </td>
                <td><span class="text-success"><i class="bi bi-check-circle-fill"></i> Live</span></td>
                <td class="text-end">
                    <div class="btn-group btn-group-sm">
                        <button class="btn btn-outline-secondary"><i class="bi bi-pencil"></i></button>
                        <button class="btn btn-outline-danger"><i class="bi bi-trash"></i></button>
                    </div>
                </td>
            </tr>
            <tr>
                <td class="font-monospace">/promo</td>
                <td class="font-monospace">https://sale.example.com</td>
                <td>
                    <span class="badge bg-info text-dark">302</span>
                    <span class="d-block small text-muted">Tạm thời</span>
                </td>
                <td><span class="text-success"><i class="bi bi-check-circle-fill"></i> Live</span></td>
                <td class="text-end">
                    <div class="btn-group btn-group-sm">
                        <button class="btn btn-outline-secondary"><i class="bi bi-pencil"></i></button>
                        <button class="btn btn-outline-danger"><i class="bi bi-trash"></i></button>
                    </div>
                </td>
            </tr>
            <tr>
                <td class="font-monospace">/app</td>
                <td class="font-monospace text-break">https://app.other.io</td>
                <td>
                    <span class="badge bg-dark">Masked</span>
                    <span class="d-block small text-muted">Title: "My App"</span>
                </td>
                <td><span class="text-warning"><i class="bi bi-clock"></i> Pending</span></td>
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

<div class="alert alert-secondary py-2">
    <i class="bi bi-bar-chart-fill"></i> Đang dùng: <strong>3/5</strong> chuyển hướng
</div>
