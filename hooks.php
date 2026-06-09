<?php

/**
 * HVN DNS Manager - WHMCS Hooks
 */

if (!defined("WHMCS")) {
    die("This file cannot be accessed directly");
}

// DB migration chạy trong hvn_dns_manager_activate() (xem hvn_dns_manager.php).
// KHÔNG dùng hook 'AddonActivation' cho việc này: hook đó kích hoạt khi một
// product-addon của khách được active (vars: id/userid/clientid/serviceid/addonid),
// không có vars['module'] và không liên quan tới việc kích hoạt addon module.

/**
 * Register "Domain Manager" Menu in Client Area
 */
add_hook('ClientAreaPrimaryNavbar', 1, function($primaryNavbar) {
    // Add a new menu item under the main navbar
    $primaryNavbar->addChild('HVN Domain Manager', [
        'label' => 'Domain Manager',
        'uri'   => 'index.php?m=hvn_dns_manager',
        'order' => 20,
    ]);
});
