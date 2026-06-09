<?php
/*
 * @ https://EasyToYou.eu - IonCube v11 Decoder Online
 * @ PHP 7.4
 * @ Decoder version: 1.0.2
 * @ Release: 10/08/2022
 */

// Decoded file for php version 74.
namespace WHMCS\Module\Addon\AddonModule\Admin;

class AdminDispatcher
{
    public function dispatch($action, $parameters)
    {
        if(!$action) {
            $action = "index";
        }
        $controller = new Controller();
        if(is_callable([$controller, $action])) {
            return $controller->{$action}($parameters);
        }
        return "<p>Invalid action requested. Please go back and try again.</p>";
    }
}

?>