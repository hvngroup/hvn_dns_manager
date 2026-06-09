<?php

defined("WHMCS") or die("Access Denied");

/**
 * Cấu hình License — endpoint + secret.
 *
 * Theo chuẩn MJ: KHÔNG hardcode secret trong class LicenseChecker; tách ra file
 * cấu hình riêng (file này KHÔNG được ionCube-encode khi đóng gói). Có thể ghi
 * đè qua Admin Settings (license_server_url / license_secret_key) — Settings ưu
 * tiên cao hơn giá trị mặc định ở đây.
 *
 * @return array{server_url:string, secret:string, check_interval:int, grace_days:int}
 */
return [
    // URL license server của ModuleJET / HVN GROUP.
    'server_url'     => 'https://billing.hvngroup.vn/modules/servers/licensing/verify.php',

    // Secret dùng để giải mã local key. ĐỂ TRỐNG trong repo — cấu hình thực tế
    // nạp qua Admin Settings (license_secret_key) hoặc khi đóng gói riêng cho khách.
    'secret'         => '',

    // Khoảng cách giữa các lần remote check (giây). Mặc định 24 giờ.
    'check_interval' => 86400,

    // Số ngày grace sau khi local key hết hạn mà vẫn cho module chạy.
    'grace_days'     => 15,
];
