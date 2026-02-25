<?php
/*
 * @ https://EasyToYou.eu - IonCube v11 Decoder Online
 * @ PHP 7.4
 * @ Decoder version: 1.0.2
 * @ Release: 10/08/2022
 */

// Decoded file for php version 74.
add_hook("ClientAreaNavbars", 1, function ($vars) {
    $pdo = Illuminate\Database\Capsule\Manager::connection()->getPdo();
    $userLang = $_SESSION["Language"];
    if(!isset($userLang)) {
        $pdo = Illuminate\Database\Capsule\Manager::connection()->getPdo();
        $query = $pdo->prepare("SELECT value FROM tblconfiguration WHERE setting = 'Language' ");
        $query->execute();
        $query = $query->fetch(PDO::FETCH_ASSOC);
        $query = $query["value"];
        include ROOTDIR . "/modules/addons/dnssuite/lang/" . $query . ".php";
    } else {
        include ROOTDIR . "/modules/addons/dnssuite/lang/" . $userLang . ".php";
    }
    $query = $pdo->prepare("SELECT value FROM tbladdonmodules WHERE module = 'dnssuite' AND setting = 'showunderdomainmenu'");
    $query->execute();
    $query = $query->fetch(PDO::FETCH_ASSOC);
    $showclientareanavmenu = $query["value"];
    $query = $pdo->prepare("SELECT value FROM tbladdonmodules WHERE module = 'dnssuite' AND setting = 'navmenuorder'");
    $query->execute();
    $query = $query->fetch(PDO::FETCH_ASSOC);
    $menuorder = $query["value"];
    if(!preg_match("/\\d+/", $menuorder)) {
        $menuorder = 90;
    }
    if($showclientareanavmenu == "on") {
        $primaryNavbar = Menu::primaryNavbar();
        $secondaryNavbar = Menu::secondaryNavbar();
        if(!is_null($primaryNavbar->getChild("Domains"))) {
            $primaryNavbar->getChild("Domains")->addChild("DNSSuite", ["label" => $_ADDONLANG["dnssuite_menuitem_name"], "uri" => "index.php?m=dnssuite", "order" => $menuorder]);
        }
    }
});
add_hook("ClientAreaPageDomainDetails", 1, function ($vars) {
    $pdo = Illuminate\Database\Capsule\Manager::connection()->getPdo();
    $userLang = $_SESSION["Language"];
    if(!isset($userLang)) {
        $pdo = Illuminate\Database\Capsule\Manager::connection()->getPdo();
        $query = $pdo->prepare("SELECT value FROM tblconfiguration WHERE setting = 'Language' ");
        $query->execute();
        $query = $query->fetch(PDO::FETCH_ASSOC);
        $query = $query["value"];
        include ROOTDIR . "/modules/addons/dnssuite/lang/" . $query . ".php";
    } else {
        include ROOTDIR . "/modules/addons/dnssuite/lang/" . $userLang . ".php";
    }
    $query = $pdo->prepare("SELECT count(*) FROM tbldomains WHERE id = :id AND status = :status");
    $query->execute([":id" => $vars["domainid"], ":status" => "Active"]);
    $query = $query->fetch(PDO::FETCH_ASSOC);
    if(0 < $query["count(*)"]) {
        $query = $pdo->prepare("SELECT value FROM tbladdonmodules WHERE module = 'dnssuite' AND setting = 'respectwhmcsdns'");
        $query->execute();
        $query = $query->fetch(PDO::FETCH_ASSOC);
        $respectwhmcsdns = $query["value"];
        if($respectwhmcsdns == "on") {
            $query = $pdo->prepare("SELECT dnsmanagement FROM tbldomains WHERE id = :did");
            $query->execute([":did" => $vars["domainid"]]);
            $query = $query->fetch(PDO::FETCH_ASSOC);
            $dnsmanagement = $query["dnsmanagement"];
            if($dnsmanagement != "1") {
                return NULL;
            }
        }
        $query = $pdo->prepare("SELECT value FROM tbladdonmodules WHERE module = 'dnssuite' AND setting = 'showindomainpage'");
        $query->execute();
        $query = $query->fetch(PDO::FETCH_ASSOC);
        $showindomainpage = $query["value"];
        $query = $pdo->prepare("SELECT value FROM tbladdonmodules WHERE module = 'dnssuite' AND setting = 'sidemenuorder'");
        $query->execute();
        $query = $query->fetch(PDO::FETCH_ASSOC);
        $sidemenuorder = $query["value"];
        if(!preg_match("/\\d+/", $sidemenuorder)) {
            $sidemenuorder = 90;
        }
        if($showindomainpage == "on") {
            $primarySidebar = Menu::primarySideBar();
            if(!is_null($primarySidebar->getChild("Domain Details Management"))) {
                $primarySidebar->getChild("Domain Details Management")->addChild("DNSSuite Manage Link")->setLabel($_ADDONLANG["dnssuite_sidemenuitem_name"])->setUri("index.php?m=dnssuite&action=manage&domainid=" . $vars["domainid"])->setOrder($sidemenuorder);
            }
        }
    }
});
add_hook("PreRegistrarRegisterDomain", 1, function ($vars) {
    $pdo = Illuminate\Database\Capsule\Manager::connection()->getPdo();
    $query = $pdo->prepare("SELECT value FROM tbladdonmodules WHERE module = 'dnssuite' AND setting = 'createonpreregistrar'");
    $query->execute();
    $query = $query->fetch(PDO::FETCH_ASSOC);
    $create = $query["value"];
    if($create == "on") {
        require_once ROOTDIR . "/modules/addons/dnssuite/class/class.dnssuite.php";
        $obj = new DNSSUITE\Suite_AdminArea($pdo);
        logModuleCall("WHMCS DNS SUITE", "PreRegistrarRegisterDomain", "First step", $responseData, $vars["params"], $replaceVars);
        if(isset($vars["params"]["domainid"])) {
            logModuleCall("WHMCS DNS SUITE", "PreRegistrarRegisterDomain", "Second step - isset", $responseData, $vars["params"]["domainid"], $replaceVars);
            $obj->checkDomainExist($vars["params"]["domainid"]);
        } else {
            $domain = $vars["params"]["sld"] . "." . $vars["params"]["tld"];
            $query = $pdo->prepare("SELECT id FROM tbldomains WHERE domain = :domain AND userid = :userid AND status = :status");
            $query->execute([":domain" => $domain, ":userid" => $vars["params"]["userid"], ":status" => "Pending"]);
            $query = $query->fetch(PDO::FETCH_ASSOC);
            $did = $query["id"];
            logModuleCall("WHMCS DNS SUITE", "PreRegistrarRegisterDomain", "Second step - Manual If", $responseData, $did, $replaceVars);
            if($did != "") {
                $obj->checkDomainExist($did);
            }
        }
    }
});
add_hook("PreDomainRegister", 1, function ($vars) {
    $pdo = Illuminate\Database\Capsule\Manager::connection()->getPdo();
    $query = $pdo->prepare("SELECT value FROM tbladdonmodules WHERE module = 'dnssuite' AND setting = 'createonregistration'");
    $query->execute();
    $query = $query->fetch(PDO::FETCH_ASSOC);
    $create = $query["value"];
    if($create == "on") {
        require_once ROOTDIR . "/modules/addons/dnssuite/class/class.dnssuite.php";
        $obj = new DNSSUITE\Suite_AdminArea($pdo);
        logModuleCall("WHMCS DNS SUITE", "PreDomainRegister", "First step", $responseData, $vars["params"], $replaceVars);
        if(isset($vars["params"]["domainid"])) {
            logModuleCall("WHMCS DNS SUITE", "PreDomainRegister", "Second step - isset", $responseData, $vars["params"]["domainid"], $replaceVars);
            $obj->checkDomainExist($vars["params"]["domainid"]);
        } else {
            $domain = $vars["params"]["sld"] . "." . $vars["params"]["tld"];
            $query = $pdo->prepare("SELECT id FROM tbldomains WHERE domain = :domain AND userid = :userid AND status = :status");
            $query->execute([":domain" => $domain, ":userid" => $vars["params"]["userid"], ":status" => "Pending"]);
            $query = $query->fetch(PDO::FETCH_ASSOC);
            $did = $query["id"];
            logModuleCall("WHMCS DNS SUITE", "PreDomainRegister", "Second step - Manual If", $responseData, $did, $replaceVars);
            if($did != "") {
                $obj->checkDomainExist($did);
            }
        }
    }
});
add_hook("PreRegistrarTransferDomain", 1, function ($vars) {
    $pdo = Illuminate\Database\Capsule\Manager::connection()->getPdo();
    $query = $pdo->prepare("SELECT value FROM tbladdonmodules WHERE module = 'dnssuite' AND setting = 'createontransfer'");
    $query->execute();
    $query = $query->fetch(PDO::FETCH_ASSOC);
    $create = $query["value"];
    if($create == "on") {
        require_once ROOTDIR . "/modules/addons/dnssuite/class/class.dnssuite.php";
        $obj = new DNSSUITE\Suite_AdminArea($pdo);
        logModuleCall("WHMCS DNS SUITE", "PreRegistrarTransferDomain", "First step", $responseData, $vars["params"], $replaceVars);
        if(isset($vars["params"]["domainid"])) {
            logModuleCall("WHMCS DNS SUITE", "PreRegistrarTransferDomain", "Second step - isset", $responseData, $vars["params"]["domainid"], $replaceVars);
            $obj->checkDomainExist($vars["params"]["domainid"]);
        } else {
            $domain = $vars["params"]["sld"] . "." . $vars["params"]["tld"];
            $query = $pdo->prepare("SELECT id FROM tbldomains WHERE domain = :domain AND userid = :userid AND status = :status");
            $query->execute([":domain" => $domain, ":userid" => $vars["params"]["userid"], ":status" => "Pending"]);
            $query = $query->fetch(PDO::FETCH_ASSOC);
            $did = $query["id"];
            logModuleCall("WHMCS DNS SUITE", "PreRegistrarTransferDomain", "Second step - Manual If", $responseData, $did, $replaceVars);
            if($did != "") {
                $obj->checkDomainExist($did);
            }
        }
    }
});
add_hook("AdminAreaFooterOutput", 1, function ($vars) {
    $pdo = Illuminate\Database\Capsule\Manager::connection()->getPdo();
    $query = $pdo->prepare("SELECT value FROM tbladdonmodules WHERE module = 'dnssuite' AND setting = 'showdomainservicelink'");
    $query->execute();
    $query = $query->fetch(PDO::FETCH_ASSOC);
    global $id;
    if($query["value"] == "on" && $vars["filename"] == "clientsdomains") {
        include ROOTDIR . "/modules/addons/dnssuite/lang/adminLang.php";
        $query = $pdo->prepare("SELECT count(*) FROM tbldomains WHERE id = :id AND status = 'Active'");
        $query->execute([":id" => $id]);
        $query = $query->fetch(PDO::FETCH_ASSOC);
        if(0 < $query["count(*)"]) {
            $a = "<a href='addonmodules.php?module=dnssuite&action=loaddomain&domainid=" . $id . "' target='_new'>" . $ADMINLANG_dnsmgmtlink . "</a>";
            $script = "<script type=\"text/javascript\">";
            $script .= "jQuery( document ).ready(function(){";
            $script .= "\$( \"div#profileContent\" ).before(\"<div class=\\\"alert alert-info\\\"><strong>" . $a . "</strong></div>\")";
            $script .= "});";
            $script .= "</script>";
            return $script;
        }
    }
});

?>