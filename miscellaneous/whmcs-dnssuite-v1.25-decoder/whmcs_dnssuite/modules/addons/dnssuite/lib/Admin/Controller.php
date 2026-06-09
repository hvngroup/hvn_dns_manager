<?php
/*
 * @ https://EasyToYou.eu - IonCube v11 Decoder Online
 * @ PHP 7.4
 * @ Decoder version: 1.0.2
 * @ Release: 10/08/2022
 */

// Decoded file for php version 74.
namespace WHMCS\Module\Addon\AddonModule\Admin;

class Controller
{
    public $obj;
    public $pdo;
    public function __construct()
    {
        $this->pdo = \Illuminate\Database\Capsule\Manager::connection()->getPdo();
        $this->pdo->beginTransaction();
        require ROOTDIR . "/modules/addons/dnssuite/class/class.dnssuite.php";
        $this->obj = new \DNSSUITE\Suite_AdminArea($this->pdo);
    }
    public function index($vars)
    {
        require ROOTDIR . "/modules/addons/dnssuite/lang/adminLang.php";
        if($this->obj->basic->edition < 1) {
            return "        Please subscribe to the Premium or Professional edition to use this function";
        }
        $modulelink = $vars["modulelink"];
        $version = $vars["version"];
        $LANG = $vars["_lang"];
        $latestversion = $this->obj->basic->getLatestVersion();
        if($version < $latestversion) {
            $newversion = "\r\n            <div class=\"alert alert-info\">\r\n                New version " . $latestversion . " available for download! \r\n            </div>\r\n            ";
        }
        $_SESSION["dnssuiteadmin"] = true;
        $configTextField = $vars["Text Field Name"];
        $configPasswordField = $vars["Password Field Name"];
        $configCheckboxField = $vars["Checkbox Field Name"];
        $configDropdownField = $vars["Dropdown Field Name"];
        $configRadioField = $vars["Radio Field Name"];
        $configTextareaField = $vars["Textarea Field Name"];
        if($this->obj->basic->configs["largedbexclusion"] != "on") {
            if(10 < $_SESSION["arrayhitcount"] || !isset($_SESSION["arrayhitcount"])) {
                $localdomains = 0;
                $localexpireddomains = 0;
                $remotedomains = 0;
                $expired3m = [];
                $expired6m = [];
                $expired1y = [];
                $dataarray = $this->obj->generateDomainsArray();
                $localdomains = $this->obj->returnDomainsLocal();
                $localexpireddomains = $this->obj->returnDomainsLocalExpired();
                $remotedomains = $this->obj->returnDomainsRemote();
                $_SESSION["domainarray"] = $dataarray;
                $_SESSION["localdomains"] = $localdomains;
                $_SESSION["remotedomains"] = $remotedomains;
                $today = time();
                for ($i = 0; $i < count($localexpireddomains); $i++) {
                    $expiretime = strtotime($localexpireddomains[$i]["expirydate"]);
                    $datediff = $today - $expiretime;
                    $diff = round($datediff / 86400);
                    if(90 <= $diff) {
                        $expired3m[] = $localexpireddomains[$i]["domain"];
                    }
                    if(180 <= $diff) {
                        $expired6m[] = $localexpireddomains[$i]["domain"];
                    }
                    if(365 <= $diff) {
                        $expired1y[] = $localexpireddomains[$i]["domain"];
                    }
                }
                $_SESSION["expired_3m"] = [];
                $_SESSION["expired_6m"] = [];
                $_SESSION["expired_1y"] = [];
                for ($i = 0; $i < count($expired3m); $i++) {
                    if(in_array($expired3m[$i], $remotedomains) && !in_array($expired3m[$i], $localdomains)) {
                        $_SESSION["expired_3m"][] = $expired3m[$i];
                    }
                }
                for ($i = 0; $i < count($expired6m); $i++) {
                    if(in_array($expired6m[$i], $remotedomains) && !in_array($expired6m[$i], $localdomains)) {
                        $_SESSION["expired_6m"][] = $expired6m[$i];
                    }
                }
                for ($i = 0; $i < count($expired1y); $i++) {
                    if(in_array($expired1y[$i], $remotedomains) && !in_array($expired1y[$i], $localdomains)) {
                        $_SESSION["expired_1y"][] = $expired1y[$i];
                    }
                }
                if(empty($_SESSION["localdomains"])) {
                    $localdomainscount = 0;
                } else {
                    $localdomainscount = count($_SESSION["localdomains"]);
                }
                if(empty($_SESSION["localdomains"])) {
                    $localdomainscount = 0;
                } else {
                    $remotedomainscount = count($_SESSION["remotedomains"]);
                }
                if(!empty($_SESSION["expired_3m"])) {
                    $localexpireddomainscount_3m = count($_SESSION["expired_3m"]);
                } else {
                    $localexpireddomainscount_3m = 0;
                }
                if(!empty($_SESSION["expired_6m"])) {
                    $localexpireddomainscount_6m = count($_SESSION["expired_6m"]);
                } else {
                    $localexpireddomainscount_6m = 0;
                }
                if(!empty($_SESSION["expired_1y"])) {
                    $localexpireddomainscount_1y = count($_SESSION["expired_1y"]);
                } else {
                    $localexpireddomainscount_1y = 0;
                }
                $_SESSION["arrayhitcount"] = 0;
            } else {
                $dataarray = $_SESSION["domainarray"];
                if(empty($_SESSION["localdomains"])) {
                    $localdomainscount = 0;
                } else {
                    $localdomainscount = count($_SESSION["localdomains"]);
                }
                if(empty($_SESSION["localdomains"])) {
                    $localdomainscount = 0;
                } else {
                    $remotedomainscount = count($_SESSION["remotedomains"]);
                }
                if(!empty($_SESSION["expired_3m"])) {
                    $localexpireddomainscount_3m = count($_SESSION["expired_3m"]);
                } else {
                    $localexpireddomainscount_3m = 0;
                }
                if(!empty($_SESSION["expired_6m"])) {
                    $localexpireddomainscount_6m = count($_SESSION["expired_6m"]);
                } else {
                    $localexpireddomainscount_6m = 0;
                }
                if(!empty($_SESSION["expired_1y"])) {
                    $localexpireddomainscount_1y = count($_SESSION["expired_1y"]);
                } else {
                    $localexpireddomainscount_1y = 0;
                }
                $_SESSION["arrayhitcount"]++;
            }
            $searchbox = "\r\n                <script type=\"text/javascript\">\r\n                    \$(document).ready(function() {\r\n                        \$(\"#domains\").select2({\r\n                            placeholder: \"" . $ADMINLANG_finddomain . "\",\r\n                            allowClear: true,\r\n                            data:[" . $dataarray . "],\r\n                        });\r\n                        \$(\"#domains\").select2(\"val\",\"\");\r\n                     });\r\n                    </script>\r\n                    <select name=\"domainid\" id=\"domains\" style=\"width:250px;line-height:40px\">\r\n        \t\t    <!-- Dropdown List Option -->\r\n        \t\t        <option></option>\r\n        \t        </select>\r\n            ";
        } else {
            $searchbox .= "<input type=\"text\" name=\"domainname\"/>";
            $localdomainscount = "NA";
            $remotedomainscount = "NA";
        }
        if($remotedomainscount < $localdomainscount) {
            $syncbutton = " <p><a href=\"" . $modulelink . "&action=syncremote\" class=\"btn btn-success\">\r\n                            <i class=\"fa fa-sync\"></i>\r\n                            " . $ADMINLANG_synctoremote . "\r\n                            </a></p>";
        }
        if(0 < $localexpireddomainscount_3m) {
            $button3m = " <p><a href=\"" . $modulelink . "&action=listdomains&expire=0\" class=\"btn btn-danger\">\r\n                            <i class=\"fa fa-trash\"></i>\r\n                            " . $ADMINLANG_remove_3m . "\r\n                            </a></p>";
        }
        if(0 < $localexpireddomainscount_6m) {
            $button6m = " <p><a href=\"" . $modulelink . "&action=listdomains&expire=1\" class=\"btn btn-danger\">\r\n                            <i class=\"fa fa-trash\"></i>\r\n                            " . $ADMINLANG_remove_6m . "\r\n                            </a></p>";
        }
        if(0 < $localexpireddomainscount_1y) {
            $button1y = " <p><a href=\"" . $modulelink . "&action=listdomains&expire=2\" class=\"btn btn-danger\">\r\n                            <i class=\"fa fa-trash\"></i>\r\n                            " . $ADMINLANG_remove_1y . "\r\n                            </a></p>";
        }
        if(1 < $this->obj->basic->edition) {
            $menu .= "<li><a href=\"" . $modulelink . "&action=systemdns\">" . $ADMINLANG_systemdns . "</a></li>\r\n            <li><a href=\"" . $modulelink . "&action=clientdns\">" . $ADMINLANG_clientdns . "</a></li>";
        }
        return "        <link href=\"../modules/addons/dnssuite/templates/css/select2.custom.css\" rel=\"stylesheet\" />\r\n        <link href=\"https://cdnjs.cloudflare.com/ajax/libs/select2/4.0.1/css/select2.min.css\" rel=\"stylesheet\" />\r\n        <script src=\"https://cdnjs.cloudflare.com/ajax/libs/select2/4.0.1/js/select2.min.js\"></script>\r\n      \r\n<nav class=\"navbar navbar-inverse\">\r\n  <div class=\"container-fluid\">\r\n    <div class=\"navbar-header\">\r\n      <button type=\"button\" class=\"navbar-toggle\" data-toggle=\"collapse\" data-target=\"#myNavbar\">\r\n        <span class=\"icon-bar\"></span>\r\n        <span class=\"icon-bar\"></span>\r\n        <span class=\"icon-bar\"></span>                        \r\n      </button>\r\n    </div>\r\n    <div class=\"collapse navbar-collapse\" id=\"myNavbar\">\r\n      <ul class=\"nav navbar-nav\">\r\n        <li class=\"active\"><a href=\"" . $modulelink . "\">Home</a></li>\r\n        " . $menu . "\r\n        <li><a href=\"http://whmcsdnsmodule.com/docs\" target=\"_blank\"> Documentation</a></li>\r\n        <li><a href=\"https://codebox.ca/\" target=\"_blank\"> CodeBox.ca</a></li>\r\n      </ul>\r\n      <ul class=\"nav navbar-nav navbar-right\">\r\n        <li>\r\n            <form method=\"POST\" action=\"" . $modulelink . "&action=loaddomain\">\r\n            " . $searchbox . "                \r\n        \t<button type=\"submit\" id=\"btnCompleteOrder\" onclick=\"\" class=\"btn btn-primary btn-md\" ><i class=\"fa fa-gear\"></i> " . $ADMINLANG_load . "        \t\r\n        \t</form>\r\n        </li>\r\n      </ul>\r\n    </div>\r\n  </div>\r\n</nav>\r\n\r\n<p>" . $ADMINLANG_totallocal . " " . $localdomainscount . "</p>\r\n\r\n<p>" . $ADMINLANG_totalremote . " " . $remotedomainscount . "</p>\r\n\r\n<p>" . $syncbutton . "</p>\r\n\r\n<p>" . $button3m . " " . $button6m . " " . $button1y . "</p>\r\n\r\n<p>" . $newversion . "</p>\r\n";
    }
    public function listDomains($vars)
    {
        require ROOTDIR . "/modules/addons/dnssuite/lang/adminLang.php";
        $modulelink = $vars["modulelink"];
        if($this->obj->basic->edition < 1) {
            return "    Please subscribe to the Premium or Professional edition to use this function";
        }
        $_SESSION["dnssuiteadmin"] = true;
        if($_GET["expire"] == 0) {
            for ($i = 0; $i < count($_SESSION["expired_3m"]); $i++) {
                $ret .= "<tr>";
                $ret .= "<th>" . $_SESSION["expired_3m"][$i] . "</th>";
                $ret .= "<th scope=\"row\"><div class=\"custom-control custom-checkbox\">";
                $ret .= "<input type=\"checkbox\" class=\"custom-control-input\" id=\"tableDefaultCheck1\" name=\"domainarray[]\" value=\"" . $i . "\">";
                $ret .= "</div></th>";
                $ret .= "</tr>";
                $ret .= "<input type=\"hidden\" name=\"expired\" value=\"0\"/>";
            }
        } elseif($_GET["expire"] == 1) {
            for ($i = 0; $i < count($_SESSION["expired_6m"]); $i++) {
                $ret .= "<tr>";
                $ret .= "<th>" . $_SESSION["expired_6m"][$i] . "</th>";
                $ret .= "<th scope=\"row\"><div class=\"custom-control custom-checkbox\">";
                $ret .= "<input type=\"checkbox\" class=\"custom-control-input\" id=\"tableDefaultCheck1\" name=\"domainarray[]\" value=\"" . $i . "\">";
                $ret .= "</div></th>";
                $ret .= "</tr>";
                $ret .= "<input type=\"hidden\" name=\"expired\" value=\"1\"/>";
            }
        } elseif($_GET["expire"] == 2) {
            for ($i = 0; $i < count($_SESSION["expired_1y"]); $i++) {
                $ret .= "<tr>";
                $ret .= "<th>" . $_SESSION["expired_1y"][$i] . "</th>";
                $ret .= "<th scope=\"row\"><div class=\"custom-control custom-checkbox\">";
                $ret .= "<input type=\"checkbox\" class=\"custom-control-input\" id=\"tableDefaultCheck1\" name=\"domainarray[]\" value=\"" . $i . "\">";
                $ret .= "</div></th>";
                $ret .= "</tr>";
                $ret .= "<input type=\"hidden\" name=\"expired\" value=\"2\"/>";
            }
        }
        return "            <form method=\"POST\" action=\"" . $modulelink . "&action=deletedomain\">\r\n            <table class=\"table table-bordered\">\r\n                  <thead>\r\n                    <tr>\r\n                      <th>" . $ADMINLANG_domain_table_header . "</th>\r\n                      <th> \r\n                        <div class=\"custom-control custom-checkbox\">\r\n                          <label class=\"custom-control-label\" for=\"tableDefaultCheck1\">" . $ADMINLANG_domain_table_checkbox . "</label>\r\n                        </div>\r\n                      </th>\r\n                    </tr>\r\n                  </thead>\r\n                  <tbody>\r\n                    " . $ret . "\r\n                  </tbody>\r\n                </table>\r\n                <button type=\"submit\" class=\"btn btn-secondary\" data-dismiss=\"modal\">" . $ADMINLANG_deletedomain_button . "</button>\r\n            </form>";
    }
    public function deletedomain($vars)
    {
        require ROOTDIR . "/modules/addons/dnssuite/lang/adminLang.php";
        $modulelink = $vars["modulelink"];
        if($this->obj->basic->edition < 1) {
            return "    Please subscribe to the Premium or Professional edition to use this function";
        }
        $_SESSION["dnssuiteadmin"] = true;
        unset($_SESSION["arrayhitcount"]);
        if($_POST["expired"] == 0) {
            $domains = $_SESSION["expired_3m"];
        } elseif($_POST["expired"] == 1) {
            $domains = $_SESSION["expired_6m"];
        } elseif($_POST["expired"] == 2) {
            $domains = $_SESSION["expired_1y"];
        }
        if(!empty($domains)) {
            for ($i = 0; $i < count($domains); $i++) {
                if(!in_array($i, $_POST["domainarray"])) {
                    $this->obj->deleteDomainDirect($domains[$i]);
                }
            }
        }
        return "        <p>" . $ADMINLANG_finishdelete . "</p>\r\n        <p><a href=\"" . $modulelink . "\" class=\"btn btn-success\">\r\n            <i class=\"fa fa-backward\"></i>\r\n            </a></p>";
    }
    public function syncremote($vars)
    {
        require ROOTDIR . "/modules/addons/dnssuite/lang/adminLang.php";
        $modulelink = $vars["modulelink"];
        if($this->obj->basic->edition < 1) {
            return "    Please subscribe to the Premium or Professional edition to use this function";
        }
        $_SESSION["dnssuiteadmin"] = true;
        unset($_SESSION["arrayhitcount"]);
        $this->obj->syncDomainsToRemote();
        return "        <p>" . $ADMINLANG_finishsyncing . "</p>\r\n        <p><a href=\"" . $modulelink . "\" class=\"btn btn-success\">\r\n            <i class=\"fa fa-backward\"></i>\r\n            </a></p>";
    }
    public function systemdns($vars)
    {
        require ROOTDIR . "/modules/addons/dnssuite/lang/adminLang.php";
        $modulelink = $vars["modulelink"];
        if($this->obj->basic->edition < 2) {
            return "    Please subscribe to the Professional edition to use this function";
        }
        $_SESSION["dnssuiteadmin"] = true;
        if($_POST["addsystemdnstemplate"] == "yes") {
            if(!preg_match("/^(\\w+)\$/", $_POST["name"])) {
                $notice .= "<div class=\"alert alert-danger\">\r\n                        " . $ADMINLANG_error_invalidname . "        \r\n                        </div>";
            } elseif(!$this->obj->checkDuplicateTemplateName(["name" => $_POST["name"]])) {
                $this->obj->addDNSTemplate(["name" => $_POST["name"]]);
                $notice .= "<div class=\"alert alert-success\">\r\n                        " . $ADMINLANG_success_addtemplate . "        \r\n                        </div>";
            } else {
                $notice .= "<div class=\"alert alert-danger\">\r\n                        " . $ADMINLANG_error_duplicatename . "        \r\n                        </div>";
            }
        }
        if($_POST["deletesystemdnstemplate"] == "yes") {
            if(is_numeric($_POST["templateid"])) {
                $this->obj->deleteSystemDNSTemplate(["id" => $_POST["templateid"]]);
                $notice = "<div class=\"alert alert-success\">" . $ADMINLANG_dnstemplatedeleted . "</div>";
            } else {
                $notice = "<div class=\"alert alert-danger\">" . $ADMINLANG_dnstemplatedeletefailed . "</div>";
            }
        }
        $templates = $this->obj->returnSystemDNSTemplates();
        $js = "\r\n            <script>\r\n            function saveTemplate(form){\r\n                var templateformat = /^(\\w+)\$/;\r\n                if(form[\"name\"].value.match(templateformat)){\r\n                    document.getElementById(\"myModal\").style.display = \"block\";\r\n                    form.submit();\r\n                    return true;\r\n                }else{\r\n                    form[\"name\"].focus();\r\n                    document.getElementById(\"validateresp\").innerHTML = \"" . $ADMINLANG_alphaonly . "\"+\" \"+form[\"name\"].value;\r\n                    \$('#myModal').modal('show');\r\n                    return false;\r\n                }\r\n            }\r\n            </script>";
        $modal = "<div class=\"modal fade\" id=\"myModal\" tabindex=\"-1\" role=\"dialog\" aria-labelledby=\"exampleModalLabel\" aria-hidden=\"true\" id=\"validatemodal\">\r\n        <div class=\"modal-dialog\" role=\"document\" >\r\n            <div class=\"modal-content\" style=\"padding:0px\">\r\n                <div class=\"modal-header\">\r\n                    <h5 class=\"modal-title\" id=\"exampleModalLabel\">" . $ADMINLANG_error . "</h5>\r\n                </div>\r\n                <div class=\"modal-body\" id=\"validateresp\">\r\n\r\n                </div>\r\n                <div class=\"modal-footer\">\r\n                    <button type=\"button\" class=\"btn btn-secondary\" data-dismiss=\"modal\">X</button>\r\n                </div>\r\n            </div>\r\n        </div>\r\n    </div>";
        if(count($templates) == 0) {
            $output = "<p>" . $ADMINLANG_nosystemdns . "</p>";
        } else {
            $output .= "<p>";
            $output .= "<table class=\"table table-striped\">";
            $output .= "<tr>";
            $output .= "<th>" . $ADMINLANG_templatename . "</th>";
            $output .= "<th>&nbsp;</th>";
            $output .= "<th>&nbsp;</th>";
            $output .= "</tr>";
            for ($i = 0; $i < count($templates); $i++) {
                $output .= "<tr>";
                $output .= "<td>";
                $output .= $templates[$i]["name"];
                $output .= "</td>";
                $output .= "<td>";
                if($templates[$i]["status"] == 0) {
                    $output .= $ADMINLANG_disabled;
                } else {
                    $output .= $ADMINLANG_enabled;
                }
                $output .= "</td>";
                $output .= "<td>";
                $output .= "<a href=\"" . $modulelink . "&action=editdnstemplate&id=" . $templates[$i]["id"] . "\">" . $ADMINLANG_edit . "</a>";
                $output .= "</td>";
                $output .= "</tr>";
            }
            $output .= "</table>";
            $output .= "</p>";
        }
        $output .= "<p>";
        $output .= "<div class=\"panel panel-primary\">\r\n                    <div class=\"panel-heading\">\r\n                        <h3 class=\"panel-title\">" . $ADMINLANG_createnew . "</h3>\r\n                    </div>\r\n                    <div class=\"panel-body\">\r\n                    <table>\r\n                    <form method=\"POST\" action=\"" . $modulelink . "&action=systemdns\">\r\n                    <td>\r\n                        <input type=\"text\" name=\"name\">\r\n                        <input type=\"hidden\" name=\"addsystemdnstemplate\" value=\"yes\">\r\n                    </td>\r\n                    <td>\r\n                        <button type=\"submit\" id=\"btnCompleteOrder\" onClick=\"event.preventDefault(); saveTemplate(this.form)\" class=\"btn btn-success btn-sm\" ><i class=\"fa fa-plus\"></i></button>\r\n                    </td>\r\n                    </form>\r\n                    </table>\r\n                    </div>\r\n        </div>";
        $output .= "</p>";
        return "        \r\n        " . $js . "\r\n        " . $modal . "\r\n        <p><div id=\"resp\" style=\"color:red\">" . $notice . "</div></p>\r\n\r\n        " . $output . "\r\n        \r\n";
    }
    public function deletedomainremote($vars)
    {
        require ROOTDIR . "/modules/addons/dnssuite/lang/adminLang.php";
        $modulelink = $vars["modulelink"];
        $domain = $this->obj->basic->getDomainfromDID($_POST["domainid"]);
        $LANG = $vars["_lang"];
        if($this->obj->basic->edition < 1) {
            return "    Please subscribe to the Premium or Professional edition to use this function";
        }
        $_SESSION["dnssuiteadmin"] = true;
        if(1 < $this->obj->basic->edition) {
            $menu .= "<li><a href=\"" . $modulelink . "&action=systemdns\">" . $ADMINLANG_systemdns . "</a></li>\r\n            <li><a href=\"" . $modulelink . "&action=clientdns\">" . $ADMINLANG_clientdns . "</a></li>";
        }
        if(preg_match("/\\d+/", $_POST["domainid"])) {
            $this->obj->checkDomainExist($_POST["domainid"], true);
            $subdomains = $this->obj->returnSubdomains($_POST["domainid"]);
            if(!empty($subdomains)) {
                for ($i = 0; $i < count($subdomains); $i++) {
                    $this->obj->deleteSubDomainDirect(["did" => $_POST["domainid"], "sdid" => $subdomains[$i]["id"], "host" => $subdomains[$i]["host"]]);
                }
            }
            $domain = $this->obj->basic->getDomainfromDID($_POST["domainid"]);
            if($this->obj->deleteDomainDirect(["id" => $_POST["domainid"], "domain" => $domain])) {
                $notice = $ADMINLANGARRAY["dnssuitePage_manage_overview_removedomain_success"];
            } else {
                $notice = $ADMINLANGARRAY["dnssuitePage_manage_overview_removedomain_failed"];
            }
            if($this->obj->basic->configs["largedbexclusion"] != "on") {
                $localdomains = 0;
                $localexpireddomains = 0;
                $remotedomains = 0;
                $dataarray = $this->obj->generateDomainsArray();
                $localdomains = $this->obj->returnDomainsLocal();
                $remotedomains = $this->obj->returnDomainsRemote();
                $_SESSION["domainarray"] = $dataarray;
                $_SESSION["localdomains"] = $localdomains;
                $_SESSION["remotedomains"] = $remotedomains;
                if(empty($_SESSION["localdomains"])) {
                    $localdomainscount = 0;
                } else {
                    $localdomainscount = count($_SESSION["localdomains"]);
                }
                if(empty($_SESSION["localdomains"])) {
                    $localdomainscount = 0;
                } else {
                    $remotedomainscount = count($_SESSION["remotedomains"]);
                }
                $_SESSION["arrayhitcount"] = 0;
                $searchbox = "\r\n                <script type=\"text/javascript\">\r\n                    \$(document).ready(function() {\r\n                        \$(\"#domains\").select2({\r\n                            placeholder: \"" . ${$ADMINLANG_finddomain} . "\",\r\n                            allowClear: true,\r\n                            data:[" . $dataarray . "],\r\n                        });\r\n                        \$(\"#domains\").select2(\"val\",\"\");\r\n                     });\r\n                    </script>\r\n                    <select name=\"domainid\" id=\"domains\" style=\"width:250px;line-height:40px\">\r\n        \t\t    <!-- Dropdown List Option -->\r\n        \t        </select>\r\n            ";
            } else {
                $searchbox .= "<input type=\"text\" name=\"domainname\"/>";
            }
            return "        <link href=\"../modules/addons/dnssuite/templates/css/select2.custom.css\" rel=\"stylesheet\" />\r\n        <link href=\"https://cdnjs.cloudflare.com/ajax/libs/select2/4.0.1/css/select2.min.css\" rel=\"stylesheet\" />\r\n        <script src=\"https://cdnjs.cloudflare.com/ajax/libs/select2/4.0.1/js/select2.min.js\"></script>\r\n      \r\n<nav class=\"navbar navbar-inverse\">\r\n  <div class=\"container-fluid\">\r\n    <div class=\"navbar-header\">\r\n      <button type=\"button\" class=\"navbar-toggle\" data-toggle=\"collapse\" data-target=\"#myNavbar\">\r\n        <span class=\"icon-bar\"></span>\r\n        <span class=\"icon-bar\"></span>\r\n        <span class=\"icon-bar\"></span>                        \r\n      </button>\r\n    </div>\r\n    <div class=\"collapse navbar-collapse\" id=\"myNavbar\">\r\n      <ul class=\"nav navbar-nav\">\r\n        <li class=\"active\"><a href=\"" . $modulelink . "\">Home</a></li>\r\n        " . $menu . "\r\n        <li><a href=\"http://whmcsdnsmodule.com/docs\" target=\"_blank\"> Documentation</a></li>\r\n        <li><a href=\"https://codebox.ca/\" target=\"_blank\"> CodeBox.ca</a></li>\r\n      </ul>\r\n      <ul class=\"nav navbar-nav navbar-right\">\r\n        <li>\r\n            <form method=\"POST\" action=\"" . $modulelink . "&action=loaddomain\">\r\n            " . $searchbox . "                \r\n        \t<button type=\"submit\" id=\"btnCompleteOrder\" onclick=\"\" class=\"btn btn-primary btn-md\" ><i class=\"fa fa-gear\"></i> " . $ADMINLANG_load . "        \t\r\n        \t</form>\r\n        </li>\r\n      </ul>\r\n    </div>\r\n  </div>\r\n</nav>\r\n\r\n<p><div id=\"resp\" style=\"color:red\">" . $notice . "</div></p>\r\n\r\n<p>" . $ADMINLANG_totallocal . " " . $localdomainscount . "</p>\r\n\r\n<p>" . $ADMINLANG_totalremote . " " . $remotedomainscount . "</p>\r\n\r\n<p>" . $syncbutton . "</p>\r\n\r\n<p>" . $button3m . " " . $button6m . " " . $button1y . "</p>\r\n\r\n<p>" . $newversion . "</p>\r\n";
        }
    }
    public function editdnstemplate($vars)
    {
        require ROOTDIR . "/modules/addons/dnssuite/lang/adminLang.php";
        $modulelink = $vars["modulelink"];
        if($this->obj->basic->edition < 2) {
            return "    Please subscribe to the Professional edition to use this function";
        }
        $_SESSION["dnssuiteadmin"] = true;
        if($_POST["templateid"] != "") {
            $_GET["id"] = $_POST["templateid"];
        }
        if($_POST["client"] != "") {
            $_GET["client"] = 1;
        }
        if($_POST["updateStatus"] == "yes") {
            if($_POST["status"] == 0 || $_POST["status"] == 1) {
                $this->obj->updateDNSTemplateStatus(["id" => $_POST["templateid"], "status" => $_POST["status"], "client" => $_POST["client"]]);
                $notice = "<div class=\"alert alert-success\">" . $ADMINLANG_dnstemplatestatusupdated . "</div>";
            } else {
                $notice = "<div class=\"alert alert-danger\">" . $ADMINLANG_dnstemplateupdatestatusfailed . "</div>";
            }
        }
        if($_POST["deleterecord"] == "yes") {
            if(is_numeric($_POST["row"]) && is_numeric($_POST["templateid"])) {
                $this->obj->updateDNSTemplate(["mode" => $_POST["mode"], "id" => $_POST["templateid"], "type" => "delete", "row" => $_POST["row"], "client" => $_POST["client"]]);
                $notice = "<div class=\"alert alert-success\">" . $ADMINLANG_dnstemplateupdated . "</div>";
            } else {
                $notice = "<div class=\"alert alert-danger\">" . $ADMINLANG_dnstemplateupdatefailed . "</div>";
            }
        }
        if($_POST["updateA"] == "yes") {
            if(filter_var($_POST["value"], FILTER_VALIDATE_IP, FILTER_FLAG_IPV4)) {
                $this->obj->updateDNSTemplate(["mode" => "A", "id" => $_POST["templateid"], "value" => $_POST["value"], "row" => $_POST["row"], "type" => "update", "client" => $_POST["client"]]);
                $notice = "<div class=\"alert alert-success\">" . $ADMINLANG_dnstemplateupdated . "</div>";
            } else {
                $notice = "<div class=\"alert alert-danger\">" . $ADMINLANG_dnstemplateupdatefailed . "</div>";
            }
        }
        if($_POST["addA"] == "yes") {
            if(($this->obj->basic->validateHostname($_POST["host"]) || $_POST["host"] == "@") && filter_var($_POST["value"], FILTER_VALIDATE_IP, FILTER_FLAG_IPV4)) {
                $this->obj->updateDNSTemplate(["mode" => "A", "id" => $_POST["templateid"], "host" => $_POST["host"], "value" => $_POST["value"], "type" => "add", "client" => $_POST["client"]]);
                $notice = "<div class=\"alert alert-success\">" . $ADMINLANG_dnstemplateupdated . "</div>";
            } else {
                $notice = "<div class=\"alert alert-danger\">" . $ADMINLANG_dnstemplateupdatefailed . "</div>";
            }
        }
        if($_POST["updateAAAA"] == "yes") {
            if(filter_var($_POST["value"], FILTER_VALIDATE_IP, FILTER_FLAG_IPV6)) {
                $this->obj->updateDNSTemplate(["mode" => "AAAA", "id" => $_POST["templateid"], "value" => $_POST["value"], "row" => $_POST["row"], "type" => "update", "client" => $_POST["client"]]);
                $notice = "<div class=\"alert alert-success\">" . $ADMINLANG_dnstemplateupdated . "</div>";
            } else {
                $notice = "<div class=\"alert alert-danger\">" . $ADMINLANG_dnstemplateupdatefailed . "</div>";
            }
        }
        if($_POST["addAAAA"] == "yes") {
            if(($this->obj->basic->validateHostname($_POST["host"]) || $_POST["host"] == "@") && filter_var($_POST["value"], FILTER_VALIDATE_IP, FILTER_FLAG_IPV6)) {
                $this->obj->updateDNSTemplate(["mode" => "AAAA", "id" => $_POST["templateid"], "host" => $_POST["host"], "value" => $_POST["value"], "type" => "add", "client" => $_POST["client"]]);
                $notice = "<div class=\"alert alert-success\">" . $ADMINLANG_dnstemplateupdated . "</div>";
            } else {
                $notice = "<div class=\"alert alert-danger\">" . $ADMINLANG_dnstemplateupdatefailed . "</div>";
            }
        }
        if($_POST["updateCNAME"] == "yes") {
            if($this->obj->basic->validateHostname($_POST["value"]) || $this->obj->basic->validateHostnameDot($_POST["value"]) || $_POST["value"] == "@") {
                $this->obj->updateDNSTemplate(["mode" => "CNAME", "id" => $_POST["templateid"], "value" => $_POST["value"], "row" => $_POST["row"], "type" => "update", "client" => $_POST["client"]]);
                $notice = "<div class=\"alert alert-success\">" . $ADMINLANG_dnstemplateupdated . "</div>";
            } else {
                $notice = "<div class=\"alert alert-danger\">" . $ADMINLANG_dnstemplateupdatefailed . "</div>";
            }
        }
        if($_POST["addCNAME"] == "yes") {
            if(($this->obj->basic->validateHostname($_POST["host"]) || $_POST["host"] == "@") && ($this->obj->basic->validateHostname($_POST["value"]) || $this->obj->basic->validateHostnameDot($_POST["value"]) || $_POST["value"] == "@")) {
                $this->obj->updateDNSTemplate(["mode" => "CNAME", "id" => $_POST["templateid"], "host" => $_POST["host"], "value" => $_POST["value"], "type" => "add", "client" => $_POST["client"]]);
                $notice = "<div class=\"alert alert-success\">" . $ADMINLANG_dnstemplateupdated . "</div>";
            } else {
                $notice = "<div class=\"alert alert-danger\">" . $ADMINLANG_dnstemplateupdatefailed . "</div>";
            }
        }
        if($_POST["updateMX"] == "yes") {
            if(($this->obj->basic->validateHostname($_POST["value"]) || $this->obj->basic->validateHostnameDot($_POST["value"])) && $this->obj->basic->validateMXPriority($_POST["priority"])) {
                $this->obj->updateDNSTemplate(["mode" => "MX", "id" => $_POST["templateid"], "value" => $_POST["value"], "priority" => $_POST["priority"], "row" => $_POST["row"], "type" => "update", "client" => $_POST["client"]]);
                $notice = "<div class=\"alert alert-success\">" . $ADMINLANG_dnstemplateupdated . "</div>";
            } else {
                $notice = "<div class=\"alert alert-danger\">" . $ADMINLANG_dnstemplateupdatefailed . "</div>";
            }
        }
        if($_POST["addMX"] == "yes") {
            if(($this->obj->basic->validateHostname($_POST["host"]) || $_POST["host"] == "@") && ($this->obj->basic->validateHostname($_POST["value"]) || $this->obj->basic->validateHostnameDot($_POST["value"])) && $this->obj->basic->validateMXPriority($_POST["priority"])) {
                $this->obj->updateDNSTemplate(["mode" => "MX", "id" => $_POST["templateid"], "host" => $_POST["host"], "value" => $_POST["value"], "priority" => $_POST["priority"], "type" => "add", "client" => $_POST["client"]]);
                $notice = "<div class=\"alert alert-success\">" . $ADMINLANG_dnstemplateupdated . "</div>";
            } else {
                $notice = "<div class=\"alert alert-danger\">" . $ADMINLANG_dnstemplateupdatefailed . "</div>";
            }
        }
        if($_POST["updateTXT"] == "yes") {
            if($this->obj->basic->validateTXTValue($_POST["value"])) {
                $this->obj->updateDNSTemplate(["mode" => "TXT", "id" => $_POST["templateid"], "value" => $_POST["value"], "row" => $_POST["row"], "type" => "update", "client" => $_POST["client"]]);
                $notice = "<div class=\"alert alert-success\">" . $ADMINLANG_dnstemplateupdated . "</div>";
            } else {
                $notice = "<div class=\"alert alert-danger\">" . $ADMINLANG_dnstemplateupdatefailed . "</div>";
            }
        }
        if($_POST["addTXT"] == "yes") {
            if(($this->obj->basic->validateHostnameUnderScore($_POST["host"]) || $_POST["host"] == "@") && $this->obj->basic->validateTXTValue($_POST["value"])) {
                $this->obj->updateDNSTemplate(["mode" => "TXT", "id" => $_POST["templateid"], "host" => $_POST["host"], "value" => $_POST["value"], "type" => "add", "client" => $_POST["client"]]);
                $notice = "<div class=\"alert alert-success\">" . $ADMINLANG_dnstemplateupdated . "</div>";
            } else {
                $notice = "<div class=\"alert alert-danger\">" . $ADMINLANG_dnstemplateupdatefailed . "</div>";
            }
        }
        if($_POST["updateSRV"] == "yes") {
            if($this->obj->basic->validateIntRange($_POST["priority"]) && $this->obj->basic->validateIntRange($_POST["weight"]) && $this->obj->basic->validateIntRange($_POST["port"]) && ($this->obj->basic->validateHostname($_POST["value"]) || $this->obj->basic->validateHostnameDot($_POST["value"]))) {
                $this->obj->updateDNSTemplate(["mode" => "SRV", "id" => $_POST["templateid"], "value" => $_POST["value"], "row" => $_POST["row"], "priority" => $_POST["priority"], "weight" => $_POST["weight"], "port" => $_POST["port"], "type" => "update", "client" => $_POST["client"]]);
                $notice = "<div class=\"alert alert-success\">" . $ADMINLANG_dnstemplateupdated . "</div>";
            } else {
                $notice = "<div class=\"alert alert-danger\">" . $ADMINLANG_dnstemplateupdatefailed . "</div>";
            }
        }
        if($_POST["addSRV"] == "yes") {
            if(($this->obj->basic->validateHostname($_POST["host"]) || $_POST["host"] == "@") && $this->obj->basic->validateIntRange($_POST["priority"]) && $this->obj->basic->validateIntRange($_POST["weight"]) && $this->obj->basic->validateIntRange($_POST["port"]) && ($this->obj->basic->validateHostname($_POST["value"]) || $this->obj->basic->validateHostnameDot($_POST["value"]))) {
                $this->obj->updateDNSTemplate(["mode" => "SRV", "id" => $_POST["templateid"], "host" => $_POST["host"], "value" => $_POST["value"], "priority" => $_POST["priority"], "weight" => $_POST["weight"], "port" => $_POST["port"], "type" => "add", "client" => $_POST["client"]]);
                $notice = "<div class=\"alert alert-success\">" . $ADMINLANG_dnstemplateupdated . "</div>";
            } else {
                $notice = "<div class=\"alert alert-danger\">" . $ADMINLANG_dnstemplateupdatefailed . "</div>";
            }
        }
        if($_POST["updateNS"] == "yes") {
            if($this->obj->basic->validateHostname($_POST["value"]) || $this->obj->basic->validateHostnameDot($_POST["value"])) {
                $this->obj->updateDNSTemplate(["mode" => "NS", "id" => $_POST["templateid"], "value" => $_POST["value"], "row" => $_POST["row"], "type" => "update", "client" => $_POST["client"]]);
                $notice = "<div class=\"alert alert-success\">" . $ADMINLANG_dnstemplateupdated . "</div>";
            } else {
                $notice = "<div class=\"alert alert-danger\">" . $ADMINLANG_dnstemplateupdatefailed . "</div>";
            }
        }
        if($_POST["addNS"] == "yes") {
            if($this->obj->basic->validateHostname($_POST["host"]) && ($this->obj->basic->validateHostname($_POST["value"]) || $this->obj->basic->validateHostnameDot($_POST["value"]))) {
                $this->obj->updateDNSTemplate(["mode" => "NS", "id" => $_POST["templateid"], "host" => $_POST["host"], "value" => $_POST["value"], "type" => "add", "client" => $_POST["client"]]);
                $notice = "<div class=\"alert alert-success\">" . $ADMINLANG_dnstemplateupdated . "</div>";
            } else {
                $notice = "<div class=\"alert alert-danger\">" . $ADMINLANG_dnstemplateupdatefailed . "</div>";
            }
        }
        if(preg_match("/\\d+/", $_GET["id"])) {
            if($_GET["client"] == 1) {
                $data = $this->obj->getUserTemplate(["id" => $_GET["id"]]);
            } else {
                $data = $this->obj->getSystemTemplate(["id" => $_GET["id"]]);
            }
        }
        $zonedata = $data["zonedata"];
        $parsed = $this->obj->parseZone(["zonedata" => $zonedata]);
        $statusHTML = $this->obj->generateStatusHTML(["modulelink" => $modulelink, "status" => $data["status"], "templateid" => $_GET["id"], "client" => $_GET["client"]]);
        $AHTML = $this->obj->generateAHTML(["zonedata" => $parsed["a"], "templateid" => $_GET["id"], "modulelink" => $modulelink, "client" => $_GET["client"]]);
        $AAAAHTML = $this->obj->generateAAAAHTML(["zonedata" => $parsed["aaaa"], "templateid" => $_GET["id"], "modulelink" => $modulelink, "client" => $_GET["client"]]);
        $MXHTML = $this->obj->generateMXHTML(["zonedata" => $parsed["mx"], "templateid" => $_GET["id"], "modulelink" => $modulelink, "client" => $_GET["client"]]);
        $CNAMEHTML = $this->obj->generateCNAMEHTML(["zonedata" => $parsed["cname"], "templateid" => $_GET["id"], "modulelink" => $modulelink, "client" => $_GET["client"]]);
        $TXTHTML = $this->obj->generateTXTHTML(["zonedata" => $parsed["txt"], "templateid" => $_GET["id"], "modulelink" => $modulelink, "client" => $_GET["client"]]);
        $SRVHTML = $this->obj->generateSRVHTML(["zonedata" => $parsed["srv"], "templateid" => $_GET["id"], "modulelink" => $modulelink, "client" => $_GET["client"]]);
        $NSHTML = $this->obj->generateNSHTML(["zonedata" => $parsed["ns"], "templateid" => $_GET["id"], "modulelink" => $modulelink, "client" => $_GET["client"]]);
        return "        <script>\r\n            function deleteConfirm(form){\r\n            \$('#deletemodal').modal({\r\n                backdrop: 'static',\r\n                keyboard: false\r\n            })\r\n                .one('click', '#deletebutton', function(e) {\r\n                    form.submit();\r\n                    return true;\r\n                });\r\n        }\r\n        </script>\r\n        \r\n        <div class=\"modal fade\" tabindex=\"-1\" role=\"dialog\" aria-labelledby=\"ModalLabel\" aria-hidden=\"true\" id=\"deletemodal\">\r\n        <div class=\"modal-dialog\" role=\"document\" >\r\n            <div class=\"modal-content\" style=\"padding:0px\">\r\n                <div class=\"modal-header\">\r\n                    <h5 class=\"modal-title\" id=\"ModalLabel\">" . $ADMINLANG_deleteconfirm . "</h5>\r\n                </div>\r\n                <div class=\"modal-footer\">\r\n                    <button type=\"button\" class=\"btn btn-secondary\" data-dismiss=\"modal\" id=\"deletebutton\"><i class=\"fa fa-trash\"></i></button>\r\n                    <button type=\"button\" class=\"btn btn-secondary\" data-dismiss=\"modal\"><i class=\"fa fa-ban\"></i></button>\r\n                </div>\r\n            </div>\r\n        </div>\r\n    </div>\r\n        \r\n            <p><div id=\"resp\" style=\"color:red\">" . $notice . "</div></p>\r\n            " . $statusHTML . "\r\n            " . $AHTML . "\r\n            " . $AAAAHTML . "\r\n            " . $MXHTML . "\r\n            " . $CNAMEHTML . "\r\n            " . $TXTHTML . "\r\n            " . $SRVHTML . "\r\n            " . $NSHTML . "\r\n";
    }
    public function clientdns($vars)
    {
        require ROOTDIR . "/modules/addons/dnssuite/lang/adminLang.php";
        $modulelink = $vars["modulelink"];
        if($this->obj->basic->edition < 2) {
            return "    Please subscribe to the Professional edition to use this function";
        }
        $_SESSION["dnssuiteadmin"] = true;
        if($_POST["deleteuserdnstemplate"] == "yes") {
            if(is_numeric($_POST["templateid"])) {
                $this->obj->deleteUserDNSTemplate(["id" => $_POST["templateid"]]);
                $notice = "<div class=\"alert alert-success\">" . $ADMINLANG_dnstemplatedeleted . "</div>";
            } else {
                $notice = "<div class=\"alert alert-danger\">" . $ADMINLANG_dnstemplatedeletefailed . "</div>";
            }
        }
        $templates = $this->obj->returnUserDNSTemplates();
        $js = "\r\n            <script>\r\n            function saveTemplate(form){\r\n                var templateformat = /^(\\w+)\$/;\r\n                if(form[\"name\"].value.match(templateformat)){\r\n                    document.getElementById(\"myModal\").style.display = \"block\";\r\n                    form.submit();\r\n                    return true;\r\n                }else{\r\n                    form[\"name\"].focus();\r\n                    document.getElementById(\"validateresp\").innerHTML = \"" . $ADMINLANG_alphaonly . "\"+\" \"+form[\"name\"].value;\r\n                    \$('#myModal').modal('show');\r\n                    return false;\r\n                }\r\n            }\r\n            </script>";
        $modal = "<div class=\"modal fade\" id=\"myModal\" tabindex=\"-1\" role=\"dialog\" aria-labelledby=\"exampleModalLabel\" aria-hidden=\"true\" id=\"validatemodal\">\r\n        <div class=\"modal-dialog\" role=\"document\" >\r\n            <div class=\"modal-content\" style=\"padding:0px\">\r\n                <div class=\"modal-header\">\r\n                    <h5 class=\"modal-title\" id=\"exampleModalLabel\">" . $ADMINLANG_error . "</h5>\r\n                </div>\r\n                <div class=\"modal-body\" id=\"validateresp\">\r\n\r\n                </div>\r\n                <div class=\"modal-footer\">\r\n                    <button type=\"button\" class=\"btn btn-secondary\" data-dismiss=\"modal\">X</button>\r\n                </div>\r\n            </div>\r\n        </div>\r\n    </div>";
        if(count($templates) == 0) {
            $output = "<p>" . $ADMINLANG_nosystemdns . "</p>";
        } else {
            $output .= "<p>";
            $output .= "<table class=\"table table-striped\">";
            $output .= "<tr>";
            $output .= "<th>" . $ADMINLANG_templatename . "</th>";
            $output .= "<th>&nbsp;</th>";
            $output .= "<th>&nbsp;</th>";
            $output .= "</tr>";
            for ($i = 0; $i < count($templates); $i++) {
                $output .= "<tr>";
                $output .= "<td>";
                $output .= "<a href=\"clientssummary.php?userid=" . $templates[$i]["userid"] . "\" target=\"_new\">" . $templates[$i]["userid"] . "</a> - " . $templates[$i]["name"];
                $output .= "</td>";
                $output .= "<td>";
                if($templates[$i]["status"] == 0) {
                    $output .= $ADMINLANG_disabled;
                } else {
                    $output .= $ADMINLANG_enabled;
                }
                $output .= "</td>";
                $output .= "<td>";
                $output .= "<a href=\"" . $modulelink . "&action=editdnstemplate&client=1&id=" . $templates[$i]["id"] . "\">" . $ADMINLANG_edit . "</a>";
                $output .= "</td>";
                $output .= "</tr>";
            }
            $output .= "</table>";
            $output .= "</p>";
        }
        return "        \r\n        " . $js . "\r\n        " . $modal . "\r\n        <p><div id=\"resp\" style=\"color:red\">" . $notice . "</div></p>\r\n\r\n        " . $output . "\r\n        \r\n";
    }
    public function removedomain($vars)
    {
        require ROOTDIR . "/modules/addons/dnssuite/lang/adminLang.php";
        $modulelink = $vars["modulelink"];
        $domain = $this->obj->basic->getDomainfromDID($_POST["domainid"]);
        $LANG = $vars["_lang"];
        if($this->obj->basic->edition < 1) {
            return "    Please subscribe to the Premium or Professional edition to use this function";
        }
        $_SESSION["dnssuiteadmin"] = true;
        if(1 < $this->obj->basic->edition) {
            $menu .= "<li><a href=\"" . $modulelink . "&action=systemdns\">" . $ADMINLANG_systemdns . "</a></li>\r\n            <li><a href=\"" . $modulelink . "&action=clientdns\">" . $ADMINLANG_clientdns . "</a></li>";
        }
        if(preg_match("/\\d+/", $_POST["domainid"])) {
            $this->obj->checkDomainExist($_POST["domainid"], true);
            if($_POST["removedomain"] == "yes") {
                if($this->obj->removeDomain($_POST["domainid"])) {
                    $notice = $ADMINLANGARRAY["dnssuitePage_manage_overview_removedomain_success"];
                } else {
                    $notice = $ADMINLANGARRAY["dnssuitePage_manage_overview_removedomain_failed"];
                }
            }
            if($this->obj->basic->configs["largedbexclusion"] != "on") {
                $localdomains = 0;
                $localexpireddomains = 0;
                $remotedomains = 0;
                $dataarray = $this->obj->generateDomainsArray();
                $localdomains = $this->obj->returnDomainsLocal();
                $remotedomains = $this->obj->returnDomainsRemote();
                $_SESSION["domainarray"] = $dataarray;
                $_SESSION["localdomains"] = $localdomains;
                $_SESSION["remotedomains"] = $remotedomains;
                if(empty($_SESSION["localdomains"])) {
                    $localdomainscount = 0;
                } else {
                    $localdomainscount = count($_SESSION["localdomains"]);
                }
                if(empty($_SESSION["localdomains"])) {
                    $localdomainscount = 0;
                } else {
                    $remotedomainscount = count($_SESSION["remotedomains"]);
                }
                $_SESSION["arrayhitcount"] = 0;
                $searchbox = "\r\n                <script type=\"text/javascript\">\r\n                    \$(document).ready(function() {\r\n                        \$(\"#domains\").select2({\r\n                            placeholder: \"" . ${$ADMINLANG_finddomain} . "\",\r\n                            allowClear: true,\r\n                            data:[" . $dataarray . "],\r\n                        });\r\n                        \$(\"#domains\").select2(\"val\",\"\");\r\n                     });\r\n                    </script>\r\n                    <select name=\"domainid\" id=\"domains\" style=\"width:250px;line-height:40px\">\r\n        \t\t    <!-- Dropdown List Option -->\r\n        \t        </select>\r\n            ";
            } else {
                $searchbox .= "<input type=\"text\" name=\"domainname\"/>";
            }
            return "                    <script>\r\n            \r\n        </script>\r\n                \r\n \r\n        <link type=\"text/css\" rel=\"stylesheet\" href=\"../modules/addons/dnssuite/templates/css/tabs.css\" />\r\n        <link type=\"text/css\" rel=\"stylesheet\" href=\"../modules/addons/dnssuite/templates/css/modal.css\" />\r\n        <link href=\"https://cdnjs.cloudflare.com/ajax/libs/select2/4.0.1/css/select2.min.css\" rel=\"stylesheet\" />\r\n        <script src=\"https://cdnjs.cloudflare.com/ajax/libs/select2/4.0.1/js/select2.min.js\"></script>\r\n      \r\n<nav class=\"navbar navbar-inverse\">\r\n  <div class=\"container-fluid\">\r\n    <div class=\"navbar-header\">\r\n      <button type=\"button\" class=\"navbar-toggle\" data-toggle=\"collapse\" data-target=\"#myNavbar\">\r\n        <span class=\"icon-bar\"></span>\r\n        <span class=\"icon-bar\"></span>\r\n        <span class=\"icon-bar\"></span>                        \r\n      </button>\r\n    </div>\r\n    <div class=\"collapse navbar-collapse\" id=\"myNavbar\">\r\n      <ul class=\"nav navbar-nav\">\r\n        <li class=\"active\"><a href=\"" . $modulelink . "\">Home</a></li>\r\n        " . $menu . "\r\n      </ul>\r\n      <ul class=\"nav navbar-nav navbar-right\">\r\n        <li>\r\n            <form method=\"POST\" action=\"" . $modulelink . "&action=loaddomain\">\r\n            " . $searchbox . "                \r\n        \t<button type=\"submit\" id=\"loadDOMAINbtn\" onclick=\"\" class=\"btn btn-primary btn-md\" ><i class=\"fa fa-gear\"></i> " . $ADMINLANG_load . "        \t\r\n        \t</form>\r\n        </li>\r\n      </ul>\r\n    </div>\r\n  </div>\r\n</nav>\r\n            \r\n            \r\n<p><div class=\"alert alert-success\">" . $notice . "</div></p>";
        }
    }
    public function loaddomain($vars)
    {
        require ROOTDIR . "/modules/addons/dnssuite/lang/adminLang.php";
        $modulelink = $vars["modulelink"];
        if(isset($_GET["domainid"])) {
            $_POST["domainid"] = $_GET["domainid"];
        }
        $domain = $this->obj->basic->getDomainfromDID($_POST["domainid"]);
        $LANG = $vars["_lang"];
        if($this->obj->basic->edition < 1) {
            $_SESSION["dnssuiteadmin"] = false;
            return "    Please subscribe to the Premium or Professional edition to use this function";
        }
        $_SESSION["dnssuiteadmin"] = true;
        if(1 < $this->obj->basic->edition) {
            $menu .= "<li><a href=\"" . $modulelink . "&action=systemdns\">" . $ADMINLANG_systemdns . "</a></li>\r\n            <li><a href=\"" . $modulelink . "&action=clientdns\">" . $ADMINLANG_clientdns . "</a></li>";
        }
        if($this->obj->basic->configs["largedbexclusion"] != "on") {
            if(10 < $_SESSION["arrayhitcount"] || !isset($_SESSION["arrayhitcount"])) {
                $localdomains = 0;
                $localexpireddomains = 0;
                $remotedomains = 0;
                $expired3m = [];
                $expired6m = [];
                $expired1y = [];
                $dataarray = $this->obj->generateDomainsArray();
                $localdomains = $this->obj->returnDomainsLocal();
                $localexpireddomains = $this->obj->returnDomainsLocalExpired();
                $remotedomains = $this->obj->returnDomainsRemote();
                $_SESSION["domainarray"] = $dataarray;
                $_SESSION["localdomains"] = $localdomains;
                $_SESSION["remotedomains"] = $remotedomains;
                if(empty($_SESSION["localdomains"])) {
                    $localdomainscount = 0;
                } else {
                    $localdomainscount = count($_SESSION["localdomains"]);
                }
                if(empty($_SESSION["localdomains"])) {
                    $localdomainscount = 0;
                } else {
                    $remotedomainscount = count($_SESSION["remotedomains"]);
                }
                $_SESSION["arrayhitcount"] = 0;
            } else {
                $dataarray = $_SESSION["domainarray"];
                if(empty($_SESSION["localdomains"])) {
                    $localdomainscount = 0;
                } else {
                    $localdomainscount = count($_SESSION["localdomains"]);
                }
                if(empty($_SESSION["localdomains"])) {
                    $localdomainscount = 0;
                } else {
                    $remotedomainscount = count($_SESSION["remotedomains"]);
                }
                $_SESSION["arrayhitcount"]++;
            }
            $searchbox = "\r\n                <script type=\"text/javascript\">\r\n                    \$(document).ready(function() {\r\n                        \$(\"#domains\").select2({\r\n                            placeholder: \"" . ${$ADMINLANG_finddomain} . "\",\r\n                            allowClear: true,\r\n                            data:[" . $dataarray . "],\r\n                        });\r\n                        \$(\"#domains\").select2(\"val\",\"\");\r\n                     });\r\n                    </script>\r\n                    <select name=\"domainid\" id=\"domains\" style=\"width:250px;line-height:40px\">\r\n        \t\t    <!-- Dropdown List Option -->\r\n        \t        </select>\r\n            ";
        } else {
            $searchbox .= "<input type=\"text\" name=\"domainname\"/>";
        }
        if($this->obj->basic->configs["largedbexclusion"] == "on" && !isset($_POST["domainid"])) {
            if($domainid = $this->obj->searchforDomainID(["domain" => $_POST["domainname"]])) {
                $_POST["domainid"] = $domainid;
                $domain = $this->obj->basic->getDomainfromDID($_POST["domainid"]);
            } else {
                return "    " . $ADMINLANG_noresult . "\r\n    <p><a href=\"" . $modulelink . "\" class=\"btn btn-success\">\r\n<i class=\"fa fa-backward\"></i>\r\n</a></p>";
            }
        }
        if(preg_match("/\\d+/", $_POST["domainid"])) {
            $this->obj->checkDomainExist($_POST["domainid"], true);
            if($_POST["deleterecord"] == "yes") {
                if($this->obj->deleteRecord($_POST["domainid"], ["mode" => $_POST["mode"], "row" => $_POST["row"]])) {
                    $notice = $ADMINLANGARRAY["dnssuitePage_manage_record_delete_success"];
                } else {
                    $notice = $ADMINLANGARRAY["dnssuitePage_manage_record_delete_failed"];
                }
            }
            if($_POST["resetdomain"] == "yes") {
                if($this->obj->resetDomain($_POST["domainid"])) {
                    $notice = $ADMINLANGARRAY["dnssuitePage_manage_overview_resetdomain_success"];
                } else {
                    $notice = $ADMINLANGARRAY["dnssuitePage_manage_overview_resetdomain_failed"];
                }
            }
            if($_POST["cleardns"] == "yes") {
                if($this->obj->clearDNS($_POST["domainid"])) {
                    $notice = $ADMINLANGARRAY["dnssuitePage_manage_overview_cleardns_success"];
                } else {
                    $notice = $ADMINLANGARRAY["dnssuitePage_manage_overview_cleardns_failed"];
                }
            }
            if($_POST["switchns"] == "yes") {
                if($this->obj->switchNS($_POST["domainid"])) {
                    $notice = $ADMINLANGARRAY["dnssuitePage_manage_overview_switchns_success"];
                } else {
                    $notice = $ADMINLANGARRAY["dnssuitePage_manage_overview_switchns_failed"];
                }
            }
            if($_POST["restorednstemplate"] == "yes" && 1 < $this->obj->basic->edition) {
                if($this->obj->restoreDNSTemplatetoDomain($_POST["domainid"], $_POST)) {
                    $notice = $ADMINLANGARRAY["dnssuitePage_manage_restoretemplate_success"];
                } else {
                    $notice = $ADMINLANGARRAY["dnssuitePage_manage_restoretemplate_failed"];
                }
            }
            if($_POST["addA"] == "yes") {
                if($this->obj->basic->validateHostname($_POST["host"]) && filter_var($_POST["value"], FILTER_VALIDATE_IP, FILTER_FLAG_IPV4) || $this->obj->basic->verifyHostasDomain($_POST["domainid"], $_POST["host"]) && filter_var($_POST["value"], FILTER_VALIDATE_IP, FILTER_FLAG_IPV4)) {
                    if($this->obj->addRecord($_POST["domainid"], ["host" => $_POST["host"], "value" => $_POST["value"], "mode" => "A"])) {
                        $notice = $ADMINLANGARRAY["dnssuitePage_manage_dns_addrecord_success"];
                    } else {
                        $notice = $ADMINLANGARRAY["dnssuitePage_manage_dns_addrecord_failed"];
                    }
                } else {
                    $notice = $ADMINLANGARRAY["dnssuitePage_manage_dns_invalidhostvalue"];
                }
            } elseif($_POST["updateA"] == "yes") {
                if(filter_var($_POST["value"], FILTER_VALIDATE_IP, FILTER_FLAG_IPV4)) {
                    if($this->obj->updateDNSRecord($_POST["domainid"], ["mode" => "A", "value" => $_POST["value"], "row" => $_POST["row"]])) {
                        $notice = $ADMINLANGARRAY["dnssuitePage_manage_dns_updaterecord_success"];
                    } else {
                        $notice = $ADMINLANGARRAY["dnssuitePage_manage_dns_updaterecord_failed"];
                    }
                } else {
                    $notice = $ADMINLANGARRAY["dnssuitePage_manage_dns_invalidip"];
                }
            }
            if($_POST["addAAAA"] == "yes") {
                if($this->obj->basic->validateHostname($_POST["host"]) && filter_var($_POST["value"], FILTER_VALIDATE_IP, FILTER_FLAG_IPV6) || $this->obj->basic->verifyHostasDomain($_POST["domainid"], $_POST["host"]) && filter_var($_POST["value"], FILTER_VALIDATE_IP, FILTER_FLAG_IPV6)) {
                    if($this->obj->addRecord($_POST["domainid"], ["host" => $_POST["host"], "value" => $_POST["value"], "mode" => "AAAA"])) {
                        $notice = $ADMINLANGARRAY["dnssuitePage_manage_dns_addrecord_success"];
                    } else {
                        $notice = $ADMINLANGARRAY["dnssuitePage_manage_dns_addrecord_failed"];
                    }
                } else {
                    $notice = $ADMINLANGARRAY["dnssuitePage_manage_dns_invalidhostvalue"];
                }
            } elseif($_POST["updateAAAA"] == "yes") {
                if(filter_var($_POST["value"], FILTER_VALIDATE_IP, FILTER_FLAG_IPV6)) {
                    if($this->obj->updateDNSRecord($_POST["domainid"], ["mode" => "AAAA", "value" => $_POST["value"], "row" => $_POST["row"]])) {
                        $notice = $ADMINLANGARRAY["dnssuitePage_manage_dns_updaterecord_success"];
                    } else {
                        $notice = $ADMINLANGARRAY["dnssuitePage_manage_dns_updaterecord_failed"];
                    }
                } else {
                    $notice = $ADMINLANGARRAY["dnssuitePage_manage_dns_invalidip"];
                }
            }
            if($_POST["addCNAME"] == "yes") {
                if($this->obj->basic->validateHostname($_POST["host"])) {
                    if($this->obj->basic->validateHostname($_POST["value"]) || $this->obj->basic->validateHostnameDot($_POST["value"])) {
                        if($this->obj->addRecord($_POST["domainid"], ["mode" => "CNAME", "host" => $_POST["host"], "value" => $_POST["value"]])) {
                            $notice = $ADMINLANGARRAY["dnssuitePage_manage_dns_addrecord_success"];
                        } else {
                            $notice = $ADMINLANGARRAY["dnssuitePage_manage_dns_addrecord_failed"];
                        }
                    } else {
                        $notice = $ADMINLANGARRAY["dnssuitePage_manage_dns_addrecord_failed"];
                    }
                } else {
                    $notice = $ADMINLANGARRAY["dnssuitePage_manage_dns_invalidhostname"];
                }
            } elseif($_POST["updateCNAME"] == "yes") {
                if($this->obj->basic->validateHostname($_POST["value"]) || $this->obj->basic->validateHostnameDot($_POST["value"])) {
                    if($this->obj->updateDNSRecord($_POST["domainid"], ["mode" => "CNAME", "value" => $_POST["value"], "row" => $_POST["row"]])) {
                        $notice = $ADMINLANGARRAY["dnssuitePage_manage_dns_updaterecord_success"];
                    } else {
                        $notice = $ADMINLANGARRAY["dnssuitePage_manage_dns_updaterecord_failed"];
                    }
                } else {
                    $notice = $ADMINLANGARRAY["dnssuitePage_manage_dns_invalidhostname"];
                }
            }
            if($_POST["addTXT"] == "yes") {
                if($this->obj->basic->validateHostname($_POST["host"]) || $this->obj->basic->validateHostnameDot($_POST["host"])) {
                    if($this->obj->basic->validateTXTValue($_POST["value"])) {
                        if($this->obj->addRecord($_POST["domainid"], ["mode" => "TXT", "host" => $_POST["host"], "value" => $_POST["value"]])) {
                            $notice = $ADMINLANGARRAY["dnssuitePage_manage_dns_addrecord_success"];
                        } else {
                            $notice = $ADMINLANGARRAY["dnssuitePage_manage_dns_addrecord_failed"];
                        }
                    } else {
                        $notice = $ADMINLANGARRAY["dnssuitePage_manage_dns_invalidtxtvalue"];
                    }
                } else {
                    $notice = $ADMINLANGARRAY["dnssuitePage_manage_dns_invalidhostname"];
                }
            } elseif($_POST["updateTXT"] == "yes") {
                if($this->obj->basic->validateTXTValue($_POST["value"])) {
                    if($this->obj->updateDNSRecord($_POST["domainid"], ["mode" => "TXT", "value" => $_POST["value"], "row" => $_POST["row"]])) {
                        $notice = $ADMINLANGARRAY["dnssuitePage_manage_dns_updaterecord_success"];
                    } else {
                        $notice = $ADMINLANGARRAY["dnssuitePage_manage_dns_updaterecord_failed"];
                    }
                } else {
                    $notice = $ADMINLANGARRAY["dnssuitePage_manage_dns_invalidtxtvalue"];
                }
            }
            if($_POST["addMX"] == "yes") {
                if($this->obj->basic->validateHostname($_POST["host"]) || $this->obj->basic->validateHostnameDot($_POST["host"])) {
                    if($this->obj->basic->validateMXPriority($_POST["priority"])) {
                        if($this->obj->basic->validateHostname($_POST["value"]) || $this->obj->basic->validateHostnameDot($_POST["value"])) {
                            if($this->obj->addRecord($_POST["domainid"], ["mode" => "MX", "host" => $_POST["host"], "value" => $_POST["value"], "priority" => $_POST["priority"]])) {
                                $notice = $ADMINLANGARRAY["dnssuitePage_manage_dns_addrecord_success"];
                            } else {
                                $notice = $ADMINLANGARRAY["dnssuitePage_manage_dns_addrecord_failed"];
                            }
                        } else {
                            $notice = $ADMINLANGARRAY["dnssuitePage_manage_dns_invalidmxvalue"];
                        }
                    } else {
                        $notice = $ADMINLANGARRAY["dnssuitePage_manage_dns_invalidmxpriority"];
                    }
                } else {
                    $notice = $ADMINLANGARRAY["dnssuitePage_manage_dns_invalidhostname"];
                }
            } elseif($_POST["updateMX"] == "yes") {
                if($this->obj->basic->validateHostname($_POST["value"]) || $this->obj->basic->validateHostnameDot($_POST["value"])) {
                    if($this->obj->basic->validateMXPriority($_POST["priority"])) {
                        if($this->obj->updateDNSRecord($_POST["domainid"], ["mode" => "MX", "value" => $_POST["value"], "row" => $_POST["row"], "priority" => $_POST["priority"]])) {
                            $notice = $ADMINLANGARRAY["dnssuitePage_manage_dns_updaterecord_success"];
                        } else {
                            $notice = $ADMINLANGARRAY["dnssuitePage_manage_dns_updaterecord_failed"];
                        }
                    } else {
                        $notice = $ADMINLANGARRAY["dnssuitePage_manage_dns_invalidmxpriority"];
                    }
                } else {
                    $notice = $ADMINLANGARRAY["dnssuitePage_manage_dns_invalidmxvalue"];
                }
            }
            if($_POST["addNS"] == "yes") {
                if($this->obj->basic->validateHostname($_POST["host"]) || $this->obj->basic->validateHostnameDot($_POST["host"])) {
                    if($this->obj->basic->validateHostname($_POST["value"]) || $this->obj->basic->validateHostnameDot($_POST["value"])) {
                        if($this->obj->addRecord($_POST["domainid"], ["mode" => "NS", "host" => $_POST["host"], "value" => $_POST["value"]])) {
                            $notice = $ADMINLANGARRAY["dnssuitePage_manage_dns_addrecord_success"];
                        } else {
                            $notice = $ADMINLANGARRAY["dnssuitePage_manage_dns_addrecord_failed"];
                        }
                    } else {
                        $notice = $ADMINLANGARRAY["dnssuitePage_manage_dns_addrecord_failed"];
                    }
                } else {
                    $notice = $ADMINLANGARRAY["dnssuitePage_manage_dns_invalidhostname"];
                }
            } elseif($_POST["updateNS"] == "yes") {
                if($this->obj->basic->validateHostname($_POST["value"]) || $this->obj->basic->validateHostnameDot($_POST["value"])) {
                    if($this->obj->updateDNSRecord($_POST["domainid"], ["mode" => "NS", "value" => $_POST["value"], "row" => $_POST["row"]])) {
                        $notice = $ADMINLANGARRAY["dnssuitePage_manage_dns_updaterecord_success"];
                    } else {
                        $notice = $ADMINLANGARRAY["dnssuitePage_manage_dns_updaterecord_failed"];
                    }
                } else {
                    $notice = $ADMINLANGARRAY["dnssuitePage_manage_dns_invalidnsvalue"];
                }
            }
            if($_POST["addSRV"] == "yes") {
                if($this->obj->basic->validateHostname($_POST["host"]) || $this->obj->basic->validateHostnameDot($_POST["host"]) || $this->obj->basic->validateHostnameUnderScore($_POST["host"])) {
                    if($this->obj->basic->validateIntRange($_POST["priority"]) && $this->obj->basic->validateIntRange($_POST["weight"]) && $this->obj->basic->validateIntRange($_POST["port"]) && ($this->obj->basic->validateHostname($_POST["value"]) || $this->obj->basic->validateHostnameDot($_POST["value"]))) {
                        if($this->obj->addRecord($_POST["domainid"], ["mode" => "SRV", "host" => $_POST["host"], "value" => $_POST["value"], "priority" => $_POST["priority"], "weight" => $_POST["weight"], "port" => $_POST["port"]])) {
                            $notice = $ADMINLANGARRAY["dnssuitePage_manage_dns_addrecord_success"];
                        } else {
                            $notice = $ADMINLANGARRAY["dnssuitePage_manage_dns_addrecord_failed"];
                        }
                    } else {
                        $notice = $ADMINLANGARRAY["dnssuitePage_manage_dns_addrecord_failed"];
                    }
                } else {
                    $notice = $ADMINLANGARRAY["dnssuitePage_manage_dns_invalidhostname"];
                }
            } elseif($_POST["updateSRV"] == "yes") {
                if($this->obj->basic->validateIntRange($_POST["priority"]) && $this->obj->basic->validateIntRange($_POST["weight"]) && $this->obj->basic->validateIntRange($_POST["port"]) && ($this->obj->basic->validateHostname($_POST["value"]) || $this->obj->basic->validateHostnameDot($_POST["value"]))) {
                    if($this->obj->updateDNSRecord($_POST["domainid"], ["mode" => "SRV", "value" => $_POST["value"], "priority" => $_POST["priority"], "weight" => $_POST["weight"], "port" => $_POST["port"], "row" => $_POST["row"]])) {
                        $notice = $ADMINLANGARRAY["dnssuitePage_manage_dns_updaterecord_success"];
                    } else {
                        $notice = $ADMINLANGARRAY["dnssuitePage_manage_dns_updaterecord_failed"];
                    }
                } else {
                    $notice = $ADMINLANGARRAY["dnssuitePage_manage_dns_updaterecord_failed"];
                }
            }
            if($_POST["addredirect"] == "yes") {
                $url = parse_url($_POST["redirecturl"]);
                if(!$url["scheme"]) {
                    $_POST["redirecturl"] = "http://" . $_POST["redirecturl"];
                }
                if(filter_var($_POST["redirecturl"], FILTER_VALIDATE_URL, FILTER_FLAG_SCHEME_REQUIRED | FILTER_FLAG_HOST_REQUIRED)) {
                    if($this->obj->addRedirect(["did" => $_POST["domainid"], "from" => $_POST["fromurl"], "to" => $_POST["redirecturl"], "type" => $_POST["type"]])) {
                        $notice = $ADMINLANGARRAY["dnssuitePage_manage_redirect_success"];
                    } else {
                        $notice = $ADMINLANGARRAY["dnssuitePage_manage_redirect_failed_support"];
                    }
                } else {
                    $notice = $ADMINLANGARRAY["dnssuitePage_manage_redirect_failed_url"];
                }
            } elseif($_POST["modifyredirect"] == "yes" && 0 < $this->obj->basic->edition) {
                $url = parse_url($_POST["redirecturl"]);
                if(!$url["scheme"]) {
                    $_POST["redirecturl"] = "http://" . $_POST["redirecturl"];
                }
                if(filter_var($_POST["redirecturl"], FILTER_VALIDATE_URL, FILTER_FLAG_SCHEME_REQUIRED | FILTER_FLAG_HOST_REQUIRED)) {
                    if($this->obj->modifyRedirect($_POST["domainid"], ["to" => $_POST["redirecturl"], "type" => $_POST["type"], "rid" => $_POST["redirectid"]])) {
                        $notice = $ADMINLANGARRAY["dnssuitePage_manage_redirect_modify_success"];
                    } else {
                        $notice = $ADMINLANGARRAY["dnssuitePage_manage_redirect_modifyfailed_support"];
                    }
                } else {
                    $notice = $ADMINLANGARRAY["dnssuitePage_manage_redirect_modifyfailed_url"];
                }
            } elseif($_POST["deleteredirect"] == "yes" && 0 < $this->obj->basic->edition) {
                if($this->obj->deleteRedirect($_POST["domainid"], $_POST["redirectid"])) {
                    $notice = $ADMINLANGARRAY["dnssuitePage_manage_redirect_delete_success"];
                } else {
                    $notice = $ADMINLANGARRAY["dnssuitePage_manage_redirect_delete_failed"];
                }
            }
            if($_POST["addemail"] == "yes" && 0 < $this->obj->basic->edition) {
                if(!filter_var($_POST["newemail"], FILTER_VALIDATE_EMAIL)) {
                    $notice = $ADMINLANGARRAY["dnssuitePage_manage_addemail_existed"];
                } elseif($this->obj->email->checkDestinationEmailExist(["did" => $_POST["domainid"], "newemail" => $_POST["newemail"]])) {
                    $notice = $ADMINLANGARRAY["dnssuitePage_manage_addemail_existed"];
                } elseif($this->obj->email->addEmailtoDB($_POST["domainid"], $_POST["newemail"], 0)) {
                    $notice = $ADMINLANGARRAY["dnssuitePage_manage_addemaildestination_success"];
                } else {
                    $notice = $ADMINLANGARRAY["dnssuitePage_manage_addemail_failed"];
                }
            }
            if($_POST["confirmemail"] == "yes" && 0 < $this->obj->basic->edition) {
                if($this->obj->email->updateEmailStatus($_POST["emailid"], 1)) {
                    $notice = $ADMINLANGARRAY["dnssuitePage_manage_confirmemail"];
                } else {
                    $notice = $ADMINLANGARRAY["dnssuitePage_manage_confirmemail_failed"];
                }
            }
            if($_POST["deleteemail"] == "yes" && 0 < $this->obj->basic->edition) {
                if(!is_numeric($_POST["emailid"])) {
                    $ADMINLANGARRAY = $ADMINLANGARRAY["dnssuitePage_manage_deleteemail_failed"];
                } elseif($this->obj->email->checkEmailInUse($_POST["domainid"], $_POST["emailid"])) {
                    $notice = $ADMINLANGARRAY["dnssuitePage_manage_deleteemail_failed_inuse"];
                } elseif($this->obj->deleteEmail($_POST["domainid"], $_POST["emailid"])) {
                    $notice = $ADMINLANGARRAY["dnssuitePage_manage_deleteemail_success"];
                } else {
                    $notice = $ADMINLANGARRAY["dnssuitePage_manage_deleteemail_failed"];
                }
            }
            if($_POST["addalias"] == "yes" && 0 < $this->obj->basic->edition) {
                if(!filter_var($_POST["newalias"] . "@" . $domain, FILTER_VALIDATE_EMAIL)) {
                    $notice = $ADMINLANGARRAY["dnssuitePage_manage_addalias_validation"];
                } elseif(!$this->obj->addAlias($_POST["domainid"], $_POST["newalias"])) {
                    $notice = $ADMINLANGARRAY["dnssuitePage_manage_addalias_existed"];
                } else {
                    $notice = $ADMINLANGARRAY["dnssuitePage_manage_addemail_success"];
                }
            }
            if($_POST["modifyforwarder"] == "yes" && 0 < $this->obj->basic->edition) {
                if($this->obj->modifyForwarder($_POST["domainid"], ["fid" => $_POST["forwarderid"], "mailto" => $_POST["emails"]])) {
                    $notice = $ADMINLANGARRAY["dnssuitePage_manage_forwarder_modify_success"];
                } else {
                    $notice = $ADMINLANGARRAY["dnssuitePage_manage_forwarder_modify_failed"];
                }
            }
            if($_POST["deleteforwarder"] == "yes" && 0 < $this->obj->basic->edition) {
                if($this->obj->deleteForwarder($_POST["domainid"], $_POST["forwarderid"])) {
                    $notice = $ADMINLANGARRAY["dnssuitePage_manage_forwarder_delete_success"];
                } else {
                    $notice = $ADMINLANGARRAY["dnssuitePage_manage_forwarder_delete_failed"];
                }
            }
            if($_POST["updatecatchall"] == "yes" && 0 < $this->obj->basic->edition) {
                if($this->obj->updateCatchall($_POST["domainid"], $_POST["emails"])) {
                    $notice = $ADMINLANGARRAY["dnssuitePage_manage_catchall_success"];
                } elseif($_POST["emails"] == NULL) {
                    if($this->obj->disableCatchall($_POST["domainid"])) {
                        $notice = $ADMINLANGARRAY["dnssuitePage_manage_catchall_disable_success"];
                    } else {
                        $notice = $ADMINLANGARRAY["dnssuitePage_manage_catchall_disable_failed"];
                    }
                } else {
                    $notice = $ADMINLANGARRAY["dnssuitePage_manage_catchall_invalidemail"];
                }
            } elseif($_POST["disablecatchall"] == "yes" && 0 < $this->obj->basic->edition) {
                if($this->obj->disableCatchall($_POST["domainid"])) {
                    $notice = $ADMINLANGARRAY["dnssuitePage_manage_catchall_disable_success"];
                } else {
                    $notice = $ADMINLANGARRAY["dnssuitePage_manage_catchall_disable_failed"];
                }
            }
            if($zonedata = $this->obj->loaddomain($_POST["domainid"])) {
                if(!empty($zonedata["a"])) {
                    for ($i = 0; $i < count($zonedata["a"]); $i++) {
                        $zonedata["a"][$i] = explode(" ", $zonedata["a"][$i]);
                        $zonedata["a"][$i][] = $i;
                    }
                    $recordcount["a"] = count($zonedata["a"]);
                } else {
                    $recordcount["a"] = 0;
                }
                if(!empty($zonedata["mx"])) {
                    for ($i = 0; $i < count($zonedata["mx"]); $i++) {
                        $zonedata["mx"][$i] = explode(" ", $zonedata["mx"][$i]);
                        $zonedata["mx"][$i][] = $i;
                    }
                    $recordcount["mx"] = count($zonedata["mx"]);
                } else {
                    $recordcount["mx"] = 0;
                }
                if(!empty($zonedata["ns"])) {
                    for ($i = 0; $i < count($zonedata["ns"]); $i++) {
                        $zonedata["ns"][$i] = explode(" ", $zonedata["ns"][$i]);
                        $zonedata["ns"][$i][] = $i;
                    }
                    $recordcount["ns"] = count($zonedata["ns"]);
                } else {
                    $recordcount["ns"] = 0;
                }
                if(!empty($zonedata["cname"])) {
                    for ($i = 0; $i < count($zonedata["cname"]); $i++) {
                        $zonedata["cname"][$i] = explode(" ", $zonedata["cname"][$i]);
                        $zonedata["cname"][$i][] = $i;
                    }
                    $recordcount["cname"] = count($zonedata["cname"]);
                } else {
                    $recordcount["cname"] = 0;
                }
                if(!empty($zonedata["txt"])) {
                    for ($i = 0; $i < count($zonedata["txt"]); $i++) {
                        $zonedata["txt"][$i] = explode(" ", $zonedata["txt"][$i]);
                        $zonedata["txt"][$i][4] = str_replace("\"", "", $zonedata["txt"][$i][4]);
                        for ($z = 5; $z < count($zonedata["txt"][$i]); $z++) {
                            $zonedata["txt"][$i][4] = $zonedata["txt"][$i][4] . " " . $zonedata["txt"][$i][$z];
                            $zonedata["txt"][$i][4] = str_replace("\"", "", $zonedata["txt"][$i][4]);
                        }
                        $zonedata["txt"][$i][5] = $i;
                    }
                    $recordcount["txt"] = count($zonedata["txt"]);
                } else {
                    $recordcount["txt"] = 0;
                }
                if(!empty($zonedata["aaaa"])) {
                    for ($i = 0; $i < count($zonedata["aaaa"]); $i++) {
                        $zonedata["aaaa"][$i] = explode(" ", $zonedata["aaaa"][$i]);
                        $zonedata["aaaa"][$i][] = $i;
                    }
                    $recordcount["aaaa"] = count($zonedata["aaaa"]);
                } else {
                    $recordcount["aaaa"] = 0;
                }
                if(!empty($zonedata["srv"])) {
                    for ($i = 0; $i < count($zonedata["srv"]); $i++) {
                        $zonedata["srv"][$i] = explode(" ", $zonedata["srv"][$i]);
                        $zonedata["srv"][$i][] = $i;
                    }
                    $recordcount["srv"] = count($zonedata["srv"]);
                } else {
                    $recordcount["srv"] = 0;
                }
                if(!empty($zonedata["soa"])) {
                    for ($i = 0; $i < count($zonedata["soa"]); $i++) {
                        $zonedata["soa"][$i] = explode(" ", $zonedata["soa"][$i]);
                        $zonedata["soa"][$i][] = $i;
                    }
                }
                if($redirectdata = $this->obj->loadRedirect($_POST["domainid"])) {
                } else {
                    $redirectfalse = true;
                }
                if($forwarddata = $this->obj->loadForwarder($_POST["domainid"])) {
                } else {
                    $forwarderfalse = true;
                }
                if($catchalldata = $this->obj->loadCatchall($_POST["domainid"])) {
                } else {
                    $catchallfalse = true;
                }
            }
            if(!empty($this->obj->email->emaildestinationdata["confirmedemail"])) {
                for ($i = 0; $i < count($this->obj->email->emaildestinationdata["confirmedemail"]); $i++) {
                    $destinationemails .= "<option value=\"" . $this->obj->email->emaildestinationdata["confirmedemail"][$i]["id"] . "\">" . $this->obj->email->emaildestinationdata["confirmedemail"][$i]["email"] . "</option>";
                }
            }
            $overviewreturn = $this->obj->initOverview($_POST["domainid"]);
            if(!empty($overviewreturn["nsarray"])) {
                for ($z = 0; $z < count($overviewreturn["nsarray"]); $z++) {
                    $nslist .= $overviewreturn["nsarray"][$z] . " | ";
                }
            }
            $overview .= "\r\n                <div class=\"alert alert-info\">\r\n                        <p>" . $ADMINLANG_currentns . ": " . $nslist . "</p>\r\n                        \r\n                </div>\r\n            ";
            if($overviewreturn["nsfail"]) {
                $overview .= "\r\n                    <div class=\"alert alert-danger\">\r\n                        <p>" . $ADMINLANGARRAY["dnssuitePage_manage_overview_nsfailed_explain"] . "</p>\r\n                        <p><form method=\"post\" action=\"" . $modulelink . "&action=loaddomain\">\r\n                            <input type=\"hidden\" name=\"domainid\" value=\"" . $_POST["domainid"] . "\"/>\r\n                            <input type=\"hidden\" name=\"switchns\" value=\"yes\"/>\r\n                            <button type=\"submit\" class=\"btn btn-success btn-sm\" >" . $ADMINLANGARRAY["dnssuitePage_manage_overview_switchns"] . " <i class=\"fa fa-pencil-square-o\"></i></button>\r\n                        </form></p>\r\n                    </div>\r\n                ";
            }
            $overview .= "\r\n                <div class=\"alert alert-warning\">\r\n                    <p>" . $ADMINLANGARRAY["dnssuitePage_manage_overview_resetdomain_explain"] . "</p>\r\n                    <p><form method=\"post\" action=\"" . $modulelink . "&action=loaddomain\">\r\n                        <input type=\"hidden\" name=\"domainid\" value=\"" . $_POST["domainid"] . "\"/>\r\n                        <input type=\"hidden\" name=\"resetdomain\" value=\"yes\"/>\r\n                        <button type=\"submit\" id=\"resetDOMAINbtn\" class=\"btn btn-danger btn-sm\" onClick=\"event.preventDefault(); resetConfirm(this.form)\"><i class=\"fa fa-eraser\"></i> " . $ADMINLANGARRAY["dnssuitePage_manage_overview_resetdomain"] . "</button>\r\n                        </form></p>\r\n                    <p><form method=\"post\" action=\"" . $modulelink . "&action=loaddomain\">\r\n                    <input type=\"hidden\" name=\"domainid\" value=\"" . $_POST["domainid"] . "\"/>\r\n                    <input type=\"hidden\" name=\"cleardns\" value=\"yes\"/>\r\n                    <button type=\"submit\" id=\"clearDNSbtn\" class=\"btn btn-danger btn-sm\" onClick=\"event.preventDefault(); resetConfirm(this.form)\"><i class=\"fa fa-eraser\"></i> " . $ADMINLANGARRAY["dnssuitePage_manage_overview_cleardns"] . "</button>\r\n                    </form></p>\r\n                    <p><form method=\"post\" action=\"" . $modulelink . "&action=removedomain\">\r\n                    <input type=\"hidden\" name=\"domainid\" value=\"" . $_POST["domainid"] . "\"/>\r\n                    <input type=\"hidden\" name=\"removedomain\" value=\"yes\"/>\r\n                    <button type=\"submit\" id=\"removedomainBTN\" class=\"btn btn-danger btn-sm\" onClick=\"event.preventDefault(); removeConfirm(this.form)\"><i class=\"fa fa-trash\"></i> " . $ADMINLANGARRAY["dnssuitePage_manage_overview_removedomain"] . "</button>\r\n                    </form></p>\r\n                    <p><form method=\"post\" action=\"" . $modulelink . "&action=deletedomainremote\">\r\n                    <input type=\"hidden\" name=\"domainid\" value=\"" . $_POST["domainid"] . "\"/>\r\n                    <input type=\"hidden\" name=\"deletedomainremote\" value=\"yes\"/>\r\n                    <button type=\"submit\" id=\"deletedomainremoteBTN\" class=\"btn btn-danger btn-sm\" onClick=\"event.preventDefault(); removeConfirm(this.form)\"><i class=\"fa fa-trash\"></i> " . $ADMINLANGARRAY["dnssuitePage_manage_overview_removedomainremote"] . "</button>\r\n                    </form></p>\r\n            ";
            $domainstatus = $ADMINLANGARRAY[""] . " " . $domain;
            $AHTML = $this->obj->generateARecordHTML(["zonedata" => $zonedata["a"], "domainid" => $_POST["domainid"], "modulelink" => $modulelink]);
            $AAAAHTML = $this->obj->generateAAAARecordHTML(["zonedata" => $zonedata["aaaa"], "domainid" => $_POST["domainid"], "modulelink" => $modulelink]);
            $CNAMEHTML = $this->obj->generateCNAMERecordHTML(["zonedata" => $zonedata["cname"], "domainid" => $_POST["domainid"], "modulelink" => $modulelink]);
            $MXHTML = $this->obj->generateMXRecordHTML(["zonedata" => $zonedata["mx"], "domainid" => $_POST["domainid"], "modulelink" => $modulelink]);
            $NSHTML = $this->obj->generateNSRecordHTML(["zonedata" => $zonedata["ns"], "domainid" => $_POST["domainid"], "modulelink" => $modulelink]);
            $TXTHTML = $this->obj->generateTXTRecordHTML(["zonedata" => $zonedata["txt"], "domainid" => $_POST["domainid"], "modulelink" => $modulelink]);
            $SRVHTML = $this->obj->generateSRVRecordHTML(["zonedata" => $zonedata["srv"], "domainid" => $_POST["domainid"], "modulelink" => $modulelink]);
            $SUBDOMAINHTML = $this->obj->generateSubDomainHTML(["domainid" => $_POST["domainid"], "modulelink" => $modulelink]);
            $REDIRECTHTML = $this->obj->generateRedirectHTML(["items" => $redirectdata, "domainid" => $_POST["domainid"], "modulelink" => $modulelink]);
            $FORWARDERHTML = $this->obj->generateForwarderHTML(["items" => $forwarddata, "domainid" => $_POST["domainid"], "emaildestinationdata" => $this->obj->email->emaildestinationdata, "modulelink" => $modulelink]);
            $CATCHALLHTML = $this->obj->generateCatchAllHTML(["items" => $catchalldata, "domainid" => $_POST["domainid"], "emaildestinationdata" => $this->obj->email->emaildestinationdata, "destinationemails" => $destinationemails, "modulelink" => $modulelink]);
            $DESTINATIONHTML = $this->obj->generateDestinationHTML(["emaildestinationdata" => $this->obj->email->emaildestinationdata, "destinationemails" => $destinationemails]);
            if(1 < $this->obj->basic->edition) {
                $DNSTEMPLATEHTML = $this->obj->generateDNSTemplateHTML(["domainid" => $_POST["domainid"], "modulelink" => $modulelink]);
            }
            $ajaxvars = $this->obj->generateAJAXVARS(["domainid" => $_POST["domainid"], "modulelink" => $modulelink, "domain" => $domain, "serviceid" => $vars["serviceid"]]);
        }
        return "        <script> \r\n            " . $ajaxvars . "\r\n            \r\n            \$(document).on(\"click\", '.deletebtn',function(e){\r\n                e.preventDefault();\r\n                var row = \$(this).val();\r\n                var mode = \$(this).attr('id');\r\n                \$('#deletemodal').modal({\r\n                backdrop: 'static',\r\n                keyboard: true\r\n                }).one('click', '#deletebutton', function(e) {\r\n                    \$.ajax({\r\n                        type: \"POST\",\r\n                        url: \"../modules/addons/dnssuite/include/dnssuite_admin_ajax.php\",\r\n                        data: { domainid: domainid, mode: mode, row: row, action: \"deleteRecord\"},\r\n                        success:function(result){\r\n                            var result = JSON.parse(result);\r\n                            if (result.status == 0){\r\n                                \$.notify({message: '" . $ADMINLANG_recorddeleted_failed . "'},{type: 'danger',delay: 5000,timer: 1000,newest_on_top: true,animate: {enter: 'animated fadeInDown',exit: 'animated fadeOutDown'},});\r\n                                return false;\r\n                            }else if (result.status == 1){\r\n                                \$.notify({message: '" . $ADMINLANG_recorddeleted_success . "'},{type: 'success',delay: 5000,timer: 1000,newest_on_top: true,animate: {enter: 'animated fadeInDown',exit: 'animated fadeOutDown'},});\r\n                                var arraydata = result.data;\r\n                                if (mode == \"A\"){\r\n                                    var write = true;\r\n                                    \$(\"#Atable\").find(\"tr:gt(0)\").remove();\r\n                                    BuildTable(arraydata, mode, write);\r\n                                }else if (mode == \"AAAA\"){\r\n                                    var write = true;\r\n                                    \$(\"#AAAAtable\").find(\"tr:gt(0)\").remove();\r\n                                    BuildTable(arraydata, mode, write);\r\n                                }else if (mode == \"CNAME\"){\r\n                                    var write = true;\r\n                                    \$(\"#CNAMEtable\").find(\"tr:gt(0)\").remove();\r\n                                    BuildTable(arraydata, mode, write);\r\n                                }else if (mode == \"NS\"){\r\n                                    var write = true;\r\n                                    \$(\"#NStable\").find(\"tr:gt(0)\").remove();\r\n                                    BuildTableAdmin(arraydata, mode, write);\r\n                                }else if (mode == \"TXT\"){\r\n                                    var write = true;\r\n                                    \$(\"#TXTtable\").find(\"tr:gt(0)\").remove();\r\n                                    BuildTable(arraydata, mode, write);\r\n                                }else if (mode == \"MX\"){\r\n                                    var write = true;\r\n                                    \$(\"#MXtable\").find(\"tr:gt(0)\").remove();\r\n                                    BuildTable(arraydata, mode, write);\r\n                                }else if (mode == \"SRV\"){\r\n                                    var write = true;\r\n                                    \$(\"#SRVtable\").find(\"tr:gt(0)\").remove();\r\n                                    BuildTable(arraydata, mode, write);\r\n                                }\r\n                                return false;\r\n                            }\r\n                    }});\r\n                });\r\n            });\r\n            \r\n            function deleteConfirm(form){\r\n            \$('#deletemodal').modal({\r\n                backdrop: 'static',\r\n                keyboard: true\r\n            })\r\n                .one('click', '#deletebutton', function(e) {\r\n                    form.submit();\r\n                    return true;\r\n            });\r\n        }\r\n\r\n            function resetConfirm(form){\r\n                \$('#resetmodal').modal({\r\n                    backdrop: 'static',\r\n                    keyboard: true\r\n                })\r\n                    .one('click', '#deletebutton', function(e) {\r\n                        form.submit();\r\n                        return true;\r\n                });\r\n            }\r\n            \r\n            function removeConfirm(form){\r\n                \$('#resetmodal').modal({\r\n                    backdrop: 'static',\r\n                    keyboard: true\r\n                })\r\n                    .one('click', '#deletebutton', function(e) {\r\n                        form.submit();\r\n                        return true;\r\n                });\r\n            }\r\n            \r\n            \$(document).on(\"click\", '.adminLETSENCRYPTbtn',function(e){\r\n                e.preventDefault();\r\n                \$.ajax({\r\n                    type: \"POST\",\r\n                    url: \"../modules/addons/dnssuite/include/dnssuite_admin_ajax.php\",\r\n                    data: { domainid: domainid, action: \"requestSSL\"},\r\n                    success:function(result){\r\n                        var result = JSON.parse(result);\r\n                        if (result.status == 0){\r\n                            \$.notify({message: '" . $ADMINLANG_requestssl_failed . "'},{type: 'danger',delay: 5000,timer: 1000,newest_on_top: true,animate: {enter: 'animated fadeInDown',exit: 'animated fadeOutDown'},});\r\n                            return false;\r\n                        }else if (result.status == 1){\r\n                            \$.notify({message: '" . $ADMINLANG_requestssl_success . "'},{type: 'success',delay: 5000,timer: 1000,newest_on_top: true,animate: {enter: 'animated fadeInDown',exit: 'animated fadeOutDown'},});\r\n                            var arraydata = result.data;\r\n                            \r\n                            return false;\r\n                        }\r\n                    }});\r\n            });\r\n\r\n            function restoreDNSTemplateConfirm(form){\r\n            \$('#restorednstemplatemodal').modal({\r\n                backdrop: 'static',\r\n                keyboard: true\r\n            })\r\n                .one('click', '#deletebutton', function(e) {\r\n                    form.submit();\r\n                    return true;\r\n                });\r\n        }\r\n        </script>\r\n                \r\n        <script src=\"../modules/addons/dnssuite/templates/js/bootstrap-notify.min.js\"></script>\r\n        <script src=\"../modules/addons/dnssuite/templates/js/functions.js\"></script>\r\n        <link type=\"text/css\" rel=\"stylesheet\" href=\"../modules/addons/dnssuite/templates/css/animate.css\" />\r\n        <link type=\"text/css\" rel=\"stylesheet\" href=\"../modules/addons/dnssuite/templates/css/tabs.css\" />\r\n        <link type=\"text/css\" rel=\"stylesheet\" href=\"../modules/addons/dnssuite/templates/css/modal.css\" />\r\n        <link href=\"https://cdnjs.cloudflare.com/ajax/libs/select2/4.0.1/css/select2.min.css\" rel=\"stylesheet\" />\r\n        <script src=\"https://cdnjs.cloudflare.com/ajax/libs/select2/4.0.1/js/select2.min.js\"></script>\r\n      \r\n<nav class=\"navbar navbar-inverse\">\r\n  <div class=\"container-fluid\">\r\n    <div class=\"navbar-header\">\r\n      <button type=\"button\" class=\"navbar-toggle\" data-toggle=\"collapse\" data-target=\"#myNavbar\">\r\n        <span class=\"icon-bar\"></span>\r\n        <span class=\"icon-bar\"></span>\r\n        <span class=\"icon-bar\"></span>                        \r\n      </button>\r\n    </div>\r\n    <div class=\"collapse navbar-collapse\" id=\"myNavbar\">\r\n      <ul class=\"nav navbar-nav\">\r\n        <li class=\"active\"><a href=\"" . $modulelink . "\">Home</a></li>\r\n        " . $menu . "\r\n        <li><a href=\"http://whmcsdnsmodule.com/docs\" target=\"_blank\"> Documentation</a></li>\r\n        <li><a href=\"https://codebox.ca/\" target=\"_blank\"> CodeBox.ca</a></li>\r\n      </ul>\r\n      <ul class=\"nav navbar-nav navbar-right\">\r\n        <li>\r\n            <form method=\"POST\" action=\"" . $modulelink . "&action=loaddomain\">\r\n            " . $searchbox . "                \r\n        \t<button type=\"submit\" onclick=\"\" class=\"btn btn-primary btn-md\" ><i class=\"fa fa-gear\"></i> " . $ADMINLANG_load . "        \t\r\n        \t</form>\r\n        </li>\r\n      </ul>\r\n    </div>\r\n  </div>\r\n</nav>\r\n<div class=\"modal fade\" id=\"myModal\" tabindex=\"-1\" role=\"dialog\" aria-labelledby=\"exampleModalLabel\" aria-hidden=\"true\" id=\"validatemodal\">\r\n    <div class=\"modal-dialog\" role=\"document\" >\r\n        <div class=\"modal-content\" style=\"padding:0px\">\r\n            <div class=\"modal-header-warning\">\r\n                <h5 class=\"modal-title\" id=\"exampleModalLabel\">" . $ADMINLANG_dnssuitePage_manage_js_error . "</h5>\r\n            </div>\r\n            <div class=\"modal-body\" id=\"validateresp\">\r\n\r\n            </div>\r\n            <div class=\"modal-footer\">\r\n                <button type=\"button\" class=\"btn btn-secondary\" data-dismiss=\"modal\">X</button>\r\n            </div>\r\n        </div>\r\n    </div>\r\n</div>\r\n\r\n<div class=\"modal fade\" tabindex=\"-1\" role=\"dialog\" aria-labelledby=\"exampleModalLabel\" aria-hidden=\"true\" id=\"deletemodalREDIRECT\">\r\n    <div class=\"modal-dialog\" role=\"document\" >\r\n        <div class=\"modal-content\" style=\"padding:0px\">\r\n            <div class=\"modal-header-warning\">\r\n                <h5 class=\"modal-title\" id=\"exampleModalLabel\">" . $ADMINLANG_deleteconfirm . "</h5>\r\n            </div>\r\n            <div class=\"modal-body\" id=\"validateresp\">\r\n\r\n            </div>\r\n            <div class=\"modal-footer\">\r\n                <button type=\"button\" class=\"btn btn-secondary\" data-dismiss=\"modal\" id=\"deletebutton\"><i class=\"fa fa-trash\"></i></button>\r\n                <button type=\"button\" class=\"btn btn-secondary\" data-dismiss=\"modal\"><i class=\"fa fa-ban\"></i></button>\r\n            </div>\r\n        </div>\r\n    </div>\r\n</div>\r\n\r\n<div class=\"modal fade\" tabindex=\"-1\" role=\"dialog\" aria-labelledby=\"exampleModalLabel\" aria-hidden=\"true\" id=\"deletemodal\">\r\n    <div class=\"modal-dialog\" role=\"document\" >\r\n        <div class=\"modal-content\" style=\"padding:0px\">\r\n            <div class=\"modal-header-warning\">\r\n                <h5 class=\"modal-title\" id=\"exampleModalLabel\">" . $ADMINLANG_deleteconfirm . "</h5>\r\n            </div>\r\n            <div class=\"modal-body\" id=\"validateresp\">\r\n\r\n            </div>\r\n            <div class=\"modal-footer\">\r\n                <button type=\"button\" class=\"btn btn-secondary\" data-dismiss=\"modal\" id=\"deletebutton\"><i class=\"fa fa-trash\"></i></button>\r\n                <button type=\"button\" class=\"btn btn-secondary\" data-dismiss=\"modal\"><i class=\"fa fa-ban\"></i></button>\r\n            </div>\r\n        </div>\r\n    </div>\r\n</div>\r\n\r\n<div class=\"modal fade\" tabindex=\"-1\" role=\"dialog\" aria-labelledby=\"ModalLabel\" aria-hidden=\"true\" id=\"deletemodal\">\r\n    <div class=\"modal-dialog\" role=\"document\" >\r\n        <div class=\"modal-content\" style=\"padding:0px\">\r\n            <div class=\"modal-header\">\r\n                <h5 class=\"modal-title\" id=\"ModalLabel\">" . $ADMINLANG_deleteconfirm . "</h5>\r\n            </div>\r\n            <div class=\"modal-footer\">\r\n                <button type=\"button\" class=\"btn btn-secondary\" data-dismiss=\"modal\" id=\"deletebutton\"><i class=\"fa fa-trash\"></i></button>\r\n                <button type=\"button\" class=\"btn btn-secondary\" data-dismiss=\"modal\"><i class=\"fa fa-ban\"></i></button>\r\n            </div>\r\n        </div>\r\n    </div>\r\n</div>\r\n\r\n<div class=\"modal fade\" tabindex=\"-1\" role=\"dialog\" aria-labelledby=\"exampleModalLabel\" aria-hidden=\"true\" id=\"resetmodal\">\r\n    <div class=\"modal-dialog\" role=\"document\" >\r\n        <div class=\"modal-content\" style=\"padding:0px\">\r\n            <div class=\"modal-header-warning\">\r\n                <h5 class=\"modal-title\" id=\"exampleModalLabel\">" . $ADMINLANG_deleteconfirm . "</h5>\r\n            </div>\r\n            <div class=\"modal-body\" id=\"validateresp\">\r\n\r\n            </div>\r\n            <div class=\"modal-footer\">\r\n                <button type=\"button\" class=\"btn btn-secondary\" data-dismiss=\"modal\" id=\"deletebutton\"><i class=\"fa fa-check\"></i></button>\r\n                <button type=\"button\" class=\"btn btn-secondary\" data-dismiss=\"modal\"><i class=\"fa fa-ban\"></i></button>\r\n            </div>\r\n        </div>\r\n    </div>\r\n</div>\r\n\r\n<div class=\"modal fade\" tabindex=\"-1\" role=\"dialog\" aria-labelledby=\"exampleModalLabel\" aria-hidden=\"true\" id=\"restorednstemplatemodal\">\r\n    <div class=\"modal-dialog\" role=\"document\" >\r\n        <div class=\"modal-content\" style=\"padding:0px\">\r\n            <div class=\"modal-header-warning\">\r\n                <h5 class=\"modal-title\" id=\"exampleModalLabel\">" . $ADMINLANG_restoreconfirm . "</h5>\r\n            </div>\r\n            <div class=\"modal-body\" id=\"validateresp\">\r\n\r\n            </div>\r\n            <div class=\"modal-footer\">\r\n                <button type=\"button\" class=\"btn btn-secondary\" data-dismiss=\"modal\" id=\"deletebutton\"><i class=\"fa fa-check\"></i></button>\r\n                <button type=\"button\" class=\"btn btn-secondary\" data-dismiss=\"modal\"><i class=\"fa fa-ban\"></i></button>\r\n            </div>  \r\n        </div>\r\n    </div>\r\n</div>\r\n\r\n<p><div id=\"resp\" style=\"color:red\">" . $notice . "</div></p>\r\n\r\n<div class=\"row\">\r\n    <div class=\"col-sm-12\">\r\n        <div class=\"panel panel-primary panel-table\">\r\n            <div class=\"panel-heading\">\r\n                <div class=\"row\">\r\n                    <div class=\"col col-xs-12\">\r\n                        <h3 class=\"panel-title\">" . $ADMINLANG_domainstatus . " (" . $domain . ")</h3>\r\n                    </div>\r\n                </div>\r\n            </div>\r\n        </div>\r\n\r\n        <div class=\"panel-body\">\r\n            <div class=\"row\">\r\n                <div class=\"col-sm-12\">\r\n                     " . $overview . "\r\n                </div>\r\n             \r\n                <div class=\"col-sm-12\">\r\n                    " . $DNSTEMPLATEHTML . "   \r\n                </div>\r\n                \r\n                <div class=\"col-sm-12\">\r\n                    <button data-toggle=\"collapse\" data-target=\"#A\" class=\"btn btn-primary\">A</button>\r\n                    <button data-toggle=\"collapse\" data-target=\"#AAAA\" class=\"btn btn-primary\">AAAA</button>\r\n                    <button data-toggle=\"collapse\" data-target=\"#CNAME\" class=\"btn btn-primary\">CNAME</button>\r\n                    <button data-toggle=\"collapse\" data-target=\"#MX\" class=\"btn btn-primary\">MX</button>\r\n                    <button data-toggle=\"collapse\" data-target=\"#TXT\" class=\"btn btn-primary\">TXT</button>\r\n                    <button data-toggle=\"collapse\" data-target=\"#SRV\" class=\"btn btn-primary\">SRV</button>\r\n                    <button data-toggle=\"collapse\" data-target=\"#NS\" class=\"btn btn-primary\">NS</button>\r\n                    <button data-toggle=\"collapse\" data-target=\"#SUBDOMAIN\" class=\"btn btn-info\">" . $ADMINLANG_subdomain . "</button>\r\n                    <button data-toggle=\"collapse\" data-target=\"#REDIRECT\" class=\"btn btn-warning\">" . $ADMINLANG_redirect . "</button>\r\n                    <button data-toggle=\"collapse\" data-target=\"#FORWARDER\" class=\"btn btn-danger\">" . $ADMINLANG_forwarder . "</button>\r\n                    <button data-toggle=\"collapse\" data-target=\"#CATCHALL\" class=\"btn btn-danger\">" . $ADMINLANG_catchall . "</button>\r\n                    <button data-toggle=\"collapse\" data-target=\"#DESTINATION\" class=\"btn btn-danger\">" . $ADMINLANG_emaildestination . "</button>\r\n                    <button type=\"submit\" class=\"btn btn-primary adminLETSENCRYPTbtn\"><i class=\"fa fa-lock\"></i> " . $ADMINLANG_requestLE . "</button>\r\n                    \r\n                    <div id=\"A\" class=\"collapse\">\r\n                        <p>" . $AHTML . "</p>\r\n                    </div>\r\n                    <div id=\"AAAA\" class=\"collapse\">\r\n                        <p>" . $AAAAHTML . "</p>\r\n                    </div>\r\n                    <div id=\"CNAME\" class=\"collapse\">\r\n                        <p>" . $CNAMEHTML . "</p>\r\n                    </div>\r\n                    <div id=\"MX\" class=\"collapse\">\r\n                        <p>" . $MXHTML . "</p>\r\n                    </div>\r\n                    <div id=\"TXT\" class=\"collapse\">\r\n                        <p>" . $TXTHTML . "</p>\r\n                    </div>\r\n                    <div id=\"SRV\" class=\"collapse\">\r\n                        <p>" . $SRVHTML . "</p>\r\n                    </div>\r\n                    <div id=\"NS\" class=\"collapse\">\r\n                        <p>" . $NSHTML . "</p>\r\n                    </div>\r\n                    <div id=\"SUBDOMAIN\" class=\"collapse\">\r\n                        <p>" . $SUBDOMAINHTML . "</p>\r\n                    </div>      \r\n                    <div id=\"REDIRECT\" class=\"collapse\">\r\n                        <p>" . $REDIRECTHTML . "</p>\r\n                    </div>\r\n                    <div id=\"FORWARDER\" class=\"collapse\">\r\n                        <p>" . $FORWARDERHTML . "</p>\r\n                    </div>\r\n                    <div id=\"CATCHALL\" class=\"collapse\">\r\n                        <p>" . $CATCHALLHTML . "</p>\r\n                    </div>\r\n                    <div id=\"DESTINATION\" class=\"collapse\">\r\n                        <p>" . $DESTINATIONHTML . "</p>\r\n                    </div>\r\n                </div>   \r\n            </div>\r\n        </div>\r\n    </div>\r\n</div>\r\n";
    }
    public function loadsubdomain($vars)
    {
        require ROOTDIR . "/modules/addons/dnssuite/lang/adminLang.php";
        $modulelink = $vars["modulelink"];
        if($this->obj->basic->edition < 1) {
            $_SESSION["dnssuiteadmin"] = false;
            return "    Please subscribe to the Premium or Professional edition to use this function";
        }
        $_SESSION["dnssuiteadmin"] = true;
        $sdid = $_GET["sdid"];
        $did = $this->obj->basic->getDIDFromSDID($sdid);
        if(isset($did)) {
            $_POST["domainid"] = $did;
        }
        $domain = $this->obj->basic->getDomainfromDID($_POST["domainid"]);
        $host = $this->obj->basic->getSubDomainHostnameFromSDID($sdid);
        $subdomain = $host . "." . $domain;
        $LANG = $vars["_lang"];
        $subdomaindata = $this->obj->basic->returnSubDomainFromSDID($sdid);
        if(1 < $this->obj->basic->edition) {
            $menu .= "<li><a href=\"" . $modulelink . "&action=systemdns\">" . $ADMINLANG_systemdns . "</a></li>\r\n            <li><a href=\"" . $modulelink . "&action=clientdns\">" . $ADMINLANG_clientdns . "</a></li>";
        }
        if($this->obj->basic->configs["largedbexclusion"] != "on") {
            if(10 < $_SESSION["arrayhitcount"] || !isset($_SESSION["arrayhitcount"])) {
                $localdomains = 0;
                $localexpireddomains = 0;
                $remotedomains = 0;
                $expired3m = [];
                $expired6m = [];
                $expired1y = [];
                $dataarray = $this->obj->generateDomainsArray();
                $localdomains = $this->obj->returnDomainsLocal();
                $remotedomains = $this->obj->returnDomainsRemote();
                $_SESSION["arrayhitcount"] = $dataarray;
                $_SESSION["localdomains"] = $localdomains;
                $_SESSION["remotedomains"] = $remotedomains;
                if(empty($_SESSION["localdomains"])) {
                    $localdomainscount = 0;
                } else {
                    $localdomainscount = count($_SESSION["localdomains"]);
                }
                if(empty($_SESSION["localdomains"])) {
                    $localdomainscount = 0;
                } else {
                    $remotedomainscount = count($_SESSION["remotedomains"]);
                }
                $_SESSION["arrayhitcount"] = 0;
            } else {
                $dataarray = $_SESSION["domainarray"];
                if(empty($_SESSION["localdomains"])) {
                    $localdomainscount = 0;
                } else {
                    $localdomainscount = count($_SESSION["localdomains"]);
                }
                if(empty($_SESSION["localdomains"])) {
                    $localdomainscount = 0;
                } else {
                    $remotedomainscount = count($_SESSION["remotedomains"]);
                }
                $_SESSION["arrayhitcount"]++;
            }
            $searchbox = "\r\n                <script type=\"text/javascript\">\r\n                    \$(document).ready(function() {\r\n                        \$(\"#domains\").select2({\r\n                            placeholder: \"" . $ADMINLANG_finddomain . "\",\r\n                            allowClear: true,\r\n                            data:[" . $dataarray . "],\r\n                        });\r\n                        \$(\"#domains\").select2(\"val\",\"\");\r\n                     });\r\n                    \$(\"#domains\").select2(\"val\",\"\");\r\n                    </script>\r\n                    <select name=\"domainid\" id=\"domains\" style=\"width:250px;line-height:40px\">\r\n                        <option></option>\r\n        \t        </select>\r\n            ";
        } else {
            $searchbox .= "<input type=\"text\" name=\"domainname\"/>";
        }
        if($this->obj->basic->configs["largedbexclusion"] == "on" && !isset($_POST["domainid"])) {
            if($domainid = $this->obj->searchforDomainID(["domain" => $_POST["domainname"]])) {
                $_POST["domainid"] = $domainid;
                $domain = $this->obj->basic->getDomainfromDID($_POST["domainid"]);
            } else {
                return "    " . $ADMINLANG_noresult . "\r\n    <p><a href=\"" . $modulelink . "\" class=\"btn btn-success\">\r\n<i class=\"fa fa-backward\"></i>\r\n</a></p>";
            }
        }
        if($this->obj->basic->isSDIDValid($sdid)) {
            if(preg_match("/\\d+/", $_POST["domainid"])) {
                if($this->obj->basic->isSubDomainOwnedByDID(["did" => $did, "sdid" => $sdid])) {
                    $this->obj->checkDomainExist($_POST["domainid"], true);
                    if($_POST["resetdomain"] == "yes") {
                        if($this->obj->resetSubDomain(["did" => $did, "sdid" => $sdid, "host" => $subdomaindata["host"]])) {
                            $notice = $ADMINLANGARRAY["dnssuitePage_manage_overview_resetdomain_success"];
                        } else {
                            $notice = $ADMINLANGARRAY["dnssuitePage_manage_overview_resetdomain_failed"];
                        }
                    }
                    $domainstatus = $ADMINLANGARRAY[""] . " " . $domain;
                    $overviewreturn = $this->obj->initOverview($_POST["domainid"]);
                    $overview .= "\r\n                        <div class=\"alert alert-warning\">\r\n                            <p>" . $ADMINLANGARRAY["dnssuitePage_manage_overview_resetsubdomain_explain"] . "</p>\r\n                            <p><form method=\"post\" action=\"" . $modulelink . "&action=loadsubdomain&did=" . $did . "&sdid=" . $sdid . "\">\r\n                                <input type=\"hidden\" name=\"domainid\" value=\"" . $did . "\"/>\r\n                                <input type=\"hidden\" name=\"resetdomain\" value=\"yes\"/>\r\n                                <button type=\"submit\" id=\"resetDOMAINbtn\" class=\"btn btn-danger btn-sm\" onClick=\"event.preventDefault(); resetConfirm(this.form)\"><i class=\"fa fa-eraser\"></i> " . $ADMINLANGARRAY["dnssuitePage_manage_overview_resetsubdomain"] . "</button>\r\n                                </form></p>\r\n                    ";
                    if($zonedata = $this->obj->loaddomain($_POST["domainid"])) {
                        if($redirectdata = $this->obj->loadSubDomainRedirect(["did" => $did, "sdid" => $sdid, "host" => $subdomaindata["host"]])) {
                        } else {
                            $redirectfalse = true;
                        }
                        if($forwarddata = $this->obj->loadSubDomainForwarder(["did" => $did, "sdid" => $sdid, "host" => $subdomaindata["host"]])) {
                        } else {
                            $forwardfalse = true;
                        }
                        if($catchalldata = $this->obj->loadSubdomainCatchall(["did" => $did, "sdid" => $sdid, "host" => $subdomaindata["host"]])) {
                        } else {
                            $catchallfalse = true;
                        }
                        if(!empty($this->obj->email->emaildestinationdata["confirmedemail"])) {
                            for ($i = 0; $i < count($this->obj->email->emaildestinationdata["confirmedemail"]); $i++) {
                                $destinationemails .= "<option value=\"" . $this->obj->email->emaildestinationdata["confirmedemail"][$i]["id"] . "\">" . $this->obj->email->emaildestinationdata["confirmedemail"][$i]["email"] . "</option>";
                            }
                        }
                        $REDIRECTHTML = $this->obj->generateSubDomainRedirectHTML(["items" => $redirectdata, "domainid" => $_POST["domainid"], "sdid" => $sdid, "modulelink" => $modulelink, "subdomain" => $subdomain]);
                        $FORWARDERHTML = $this->obj->generateSubDomainForwarderHTML(["items" => $forwarddata, "domainid" => $_POST["domainid"], "sdid" => $sdid, "emaildestinationdata" => $this->obj->email->emaildestinationdata, "modulelink" => $modulelink, "subdomain" => $subdomain]);
                        $CATCHALLHTML = $this->obj->generateSubDomainCatchAllHTML(["items" => $catchalldata, "domainid" => $_POST["domainid"], "sdid" => $sdid, "emaildestinationdata" => $this->obj->email->emaildestinationdata, "destinationemails" => $destinationemails, "modulelink" => $modulelink, "subdomain" => $subdomain]);
                        $DESTINATIONHTML = $this->obj->generateDestinationHTML(["emaildestinationdata" => $this->obj->email->emaildestinationdata, "destinationemails" => $destinationemails]);
                    }
                    $ajaxvars = $this->obj->generateAJAXVARS(["domainid" => $_POST["domainid"], "modulelink" => $modulelink, "domain" => $domain, "serviceid" => $vars["serviceid"], "sdid" => $sdid, "subdomain" => $subdomain]);
                    $servicelink = "<a href=\"clientsservices.php?productselect=" . $overviewreturn["sid"] . "\" target=\"_new\">" . $ADMINLANG_servicelink . "</a>";
                    $DNSHTML = "<div class=\"container\">\r\n                                    <button data-toggle=\"collapse\" data-target=\"#REDIRECT\" class=\"btn btn-warning\">" . $ADMINLANG_redirect . "</button>\r\n                                    <button data-toggle=\"collapse\" data-target=\"#FORWARDER\" class=\"btn btn-danger\">" . $ADMINLANG_forwarder . "</button>\r\n                                    <button data-toggle=\"collapse\" data-target=\"#CATCHALL\" class=\"btn btn-danger\">" . $ADMINLANG_catchall . "</button>\r\n                                    <button data-toggle=\"collapse\" data-target=\"#DESTINATION\" class=\"btn btn-danger\">" . $ADMINLANG_emaildestination . "</button>\r\n                                    <button type=\"submit\" class=\"btn btn-primary adminLETSENCRYPTbtn\"><i class=\"fa fa-lock\"></i> " . $ADMINLANG_requestLE . "</button>\r\n                                    \r\n                                    <div id=\"REDIRECT\" class=\"collapse\">\r\n                                    <p>" . $REDIRECTHTML . "</p>\r\n                                    </div>\r\n                                    <div id=\"FORWARDER\" class=\"collapse\">\r\n                                    <p>" . $FORWARDERHTML . "</p>\r\n                                    </div>\r\n                                    <div id=\"CATCHALL\" class=\"collapse\">\r\n                                    <p>" . $CATCHALLHTML . "</p>\r\n                                    </div>\r\n                                    <div id=\"DESTINATION\" class=\"collapse\">\r\n                                    <p>" . $DESTINATIONHTML . "</p>\r\n                                    </div>\r\n                                    \r\n                                </div>";
                }
                return "                <script> \r\n                    " . $ajaxvars . "\r\n                    \r\n                    \$(document).on(\"click\", '.loadbtn',function(e){\r\n                        var f = document.getElementById(\"domains\");\r\n                        var did = f.options[f.selectedIndex].value;\r\n                        if (did == \"\"){\r\n                            e.preventDefault();\r\n                            \$.notify({message: '" . $ADMINLANG_nodomain . "'},{type: 'danger',delay: 5000,timer: 1000,newest_on_top: true,animate: {enter: 'animated fadeInDown',exit: 'animated fadeOutDown'},});\r\n                        }\r\n                    });\r\n                    \r\n                    \r\n                    function deleteConfirm(form){\r\n                    \$('#deletemodal').modal({\r\n                        backdrop: 'static',\r\n                        keyboard: true\r\n                    })\r\n                        .one('click', '#deletebutton', function(e) {\r\n                            form.submit();\r\n                            return true;\r\n                    });\r\n                }\r\n        \r\n                    function resetConfirm(form){\r\n                        \$('#resetmodal').modal({\r\n                            backdrop: 'static',\r\n                            keyboard: true\r\n                        })\r\n                            .one('click', '#deletebutton', function(e) {\r\n                                form.submit();\r\n                                return true;\r\n                        });\r\n                    }\r\n                    \r\n                    function removeConfirm(form){\r\n                        \$('#resetmodal').modal({\r\n                            backdrop: 'static',\r\n                            keyboard: true\r\n                        })\r\n                            .one('click', '#deletebutton', function(e) {\r\n                                form.submit();\r\n                                return true;\r\n                        });\r\n                    }\r\n\r\n                    \$(document).on(\"click\", '.adminLETSENCRYPTbtn',function(e){\r\n                        e.preventDefault();\r\n                        \$.ajax({\r\n                            type: \"POST\",\r\n                            url: \"../modules/addons/dnssuite/include/dnssuite_admin_ajax.php\",\r\n                            data: { domainid: domainid, sdid: sdid, action: \"requestSSL-sub\"},\r\n                            success:function(result){\r\n                                var result = JSON.parse(result);\r\n                                if (result.status == 0){\r\n                                    \$.notify({message: '" . $ADMINLANG_requestssl_failed . "'},{type: 'danger',delay: 5000,timer: 1000,newest_on_top: true,animate: {enter: 'animated fadeInDown',exit: 'animated fadeOutDown'},});\r\n                                    return false;\r\n                                }else if (result.status == 1){\r\n                                    \$.notify({message: '" . $ADMINLANG_requestssl_success . "'},{type: 'success',delay: 5000,timer: 1000,newest_on_top: true,animate: {enter: 'animated fadeInDown',exit: 'animated fadeOutDown'},});\r\n                                    var arraydata = result.data;\r\n                                    \r\n                                    return false;\r\n                                }\r\n                            }});\r\n                    });\r\n                    \r\n                </script>\r\n                 \r\n                <script src=\"../modules/addons/dnssuite/templates/js/bootstrap-notify.min.js\"></script>\r\n                <script src=\"../modules/addons/dnssuite/templates/js/functions.js\"></script>\r\n                <link type=\"text/css\" rel=\"stylesheet\" href=\"../modules/addons/dnssuite/templates/css/animate.css\" />\r\n                <link type=\"text/css\" rel=\"stylesheet\" href=\"../modules/addons/dnssuite/templates/css/tabs.css\" />\r\n                <link type=\"text/css\" rel=\"stylesheet\" href=\"../modules/addons/dnssuite/templates/css/modal.css\" />\r\n                <link href=\"https://cdnjs.cloudflare.com/ajax/libs/select2/4.0.1/css/select2.min.css\" rel=\"stylesheet\" />\r\n                <script src=\"https://cdnjs.cloudflare.com/ajax/libs/select2/4.0.1/js/select2.min.js\"></script>\r\n               \r\n        <nav class=\"navbar navbar-inverse\">\r\n          <div class=\"container-fluid\">\r\n            <div class=\"navbar-header\">\r\n              <button type=\"button\" class=\"navbar-toggle\" data-toggle=\"collapse\" data-target=\"#myNavbar\">\r\n                <span class=\"icon-bar\"></span>\r\n                <span class=\"icon-bar\"></span>\r\n                <span class=\"icon-bar\"></span>                        \r\n              </button>\r\n            </div>\r\n            <div class=\"collapse navbar-collapse\" id=\"myNavbar\">\r\n              <ul class=\"nav navbar-nav\">\r\n                <li class=\"active\"><a href=\"" . $modulelink . "\">Home</a></li>\r\n                " . $menu . "\r\n                <li><a href=\"http://whmcsdnsmodule.com/docs\" target=\"_blank\"> Documentation</a></li>\r\n                <li><a href=\"https://codebox.ca/\" target=\"_blank\"> CodeBox.ca</a></li>\r\n              </ul>\r\n              <ul class=\"nav navbar-nav navbar-right\">\r\n                <li>\r\n                    <form method=\"POST\" action=\"" . $modulelink . "&action=loaddomain\">\r\n                    " . $searchbox . "                \r\n                    <button type=\"submit\" onclick=\"\" class=\"btn btn-primary btn-md loadbtn\" ><i class=\"fa fa-gear\"></i> " . $ADMINLANG_load . "        \t\r\n                    </form>\r\n                </li>\r\n              </ul>\r\n            </div>\r\n          </div>\r\n        </nav>\r\n        <div class=\"modal fade\" id=\"myModal\" tabindex=\"-1\" role=\"dialog\" aria-labelledby=\"exampleModalLabel\" aria-hidden=\"true\" id=\"validatemodal\">\r\n                <div class=\"modal-dialog\" role=\"document\" >\r\n                    <div class=\"modal-content\" style=\"padding:0px\">\r\n                        <div class=\"modal-header-warning\">\r\n                            <h5 class=\"modal-title\" id=\"exampleModalLabel\">" . $ADMINLANG_dnssuitePage_manage_js_error . "</h5>\r\n                        </div>\r\n                        <div class=\"modal-body\" id=\"validateresp\">\r\n        \r\n                        </div>\r\n                        <div class=\"modal-footer\">\r\n                            <button type=\"button\" class=\"btn btn-secondary\" data-dismiss=\"modal\">X</button>\r\n                        </div>\r\n                    </div>\r\n                </div>\r\n            </div>\r\n        \r\n            <div class=\"modal fade\" tabindex=\"-1\" role=\"dialog\" aria-labelledby=\"exampleModalLabel\" aria-hidden=\"true\" id=\"deletemodalREDIRECT\">\r\n                <div class=\"modal-dialog\" role=\"document\" >\r\n                    <div class=\"modal-content\" style=\"padding:0px\">\r\n                        <div class=\"modal-header-warning\">\r\n                            <h5 class=\"modal-title\" id=\"exampleModalLabel\">" . $ADMINLANG_deleteconfirm . "</h5>\r\n                        </div>\r\n                        <div class=\"modal-body\" id=\"validateresp\">\r\n        \r\n                        </div>\r\n                        <div class=\"modal-footer\">\r\n                            <button type=\"button\" class=\"btn btn-secondary\" data-dismiss=\"modal\" id=\"deletebutton\"><i class=\"fa fa-trash\"></i></button>\r\n                            <button type=\"button\" class=\"btn btn-secondary\" data-dismiss=\"modal\"><i class=\"fa fa-ban\"></i></button>\r\n                        </div>\r\n                    </div>\r\n                </div>\r\n            </div>\r\n        \r\n            <div class=\"modal fade\" tabindex=\"-1\" role=\"dialog\" aria-labelledby=\"exampleModalLabel\" aria-hidden=\"true\" id=\"deletemodal\">\r\n                <div class=\"modal-dialog\" role=\"document\" >\r\n                    <div class=\"modal-content\" style=\"padding:0px\">\r\n                        <div class=\"modal-header-warning\">\r\n                            <h5 class=\"modal-title\" id=\"exampleModalLabel\">" . $ADMINLANG_deleteconfirm . "</h5>\r\n                        </div>\r\n                        <div class=\"modal-body\" id=\"validateresp\">\r\n        \r\n                        </div>\r\n                        <div class=\"modal-footer\">\r\n                            <button type=\"button\" class=\"btn btn-secondary\" data-dismiss=\"modal\" id=\"deletebutton\"><i class=\"fa fa-trash\"></i></button>\r\n                            <button type=\"button\" class=\"btn btn-secondary\" data-dismiss=\"modal\"><i class=\"fa fa-ban\"></i></button>\r\n                        </div>\r\n                    </div>\r\n                </div>\r\n            </div>\r\n        \r\n        <div class=\"modal fade\" tabindex=\"-1\" role=\"dialog\" aria-labelledby=\"ModalLabel\" aria-hidden=\"true\" id=\"deletemodal\">\r\n            <div class=\"modal-dialog\" role=\"document\" >\r\n                <div class=\"modal-content\" style=\"padding:0px\">\r\n                    <div class=\"modal-header\">\r\n                        <h5 class=\"modal-title\" id=\"ModalLabel\">" . $ADMINLANG_deleteconfirm . "</h5>\r\n                    </div>\r\n                    <div class=\"modal-footer\">\r\n                        <button type=\"button\" class=\"btn btn-secondary\" data-dismiss=\"modal\" id=\"deletebutton\"><i class=\"fa fa-trash\"></i></button>\r\n                        <button type=\"button\" class=\"btn btn-secondary\" data-dismiss=\"modal\"><i class=\"fa fa-ban\"></i></button>\r\n                    </div>\r\n                </div>\r\n            </div>\r\n        </div>\r\n        \r\n        <div class=\"modal fade\" tabindex=\"-1\" role=\"dialog\" aria-labelledby=\"exampleModalLabel\" aria-hidden=\"true\" id=\"resetmodal\">\r\n            <div class=\"modal-dialog\" role=\"document\" >\r\n                <div class=\"modal-content\" style=\"padding:0px\">\r\n                    <div class=\"modal-header-warning\">\r\n                        <h5 class=\"modal-title\" id=\"exampleModalLabel\">" . $ADMINLANG_manage_js_deleteconfirmresubdomain . "</h5>\r\n                    </div>\r\n                    <div class=\"modal-body\" id=\"validateresp\">\r\n        \r\n                    </div>\r\n                    <div class=\"modal-footer\">\r\n                        <button type=\"button\" class=\"btn btn-secondary\" data-dismiss=\"modal\" id=\"deletebutton\"><i class=\"fa fa-check\"></i></button>\r\n                        <button type=\"button\" class=\"btn btn-secondary\" data-dismiss=\"modal\"><i class=\"fa fa-ban\"></i></button>\r\n                    </div>\r\n                </div>\r\n            </div>\r\n        </div>\r\n        \r\n        <p><div id=\"resp\" style=\"color:red\">" . $notice . "</div></p>\r\n        \r\n        <div class=\"row\">\r\n            <div class=\"col-sm-12\">\r\n                <div class=\"panel panel-primary panel-table\">\r\n                    <div class=\"panel-heading\">\r\n                        <div class=\"row\">\r\n                            <div class=\"col col-xs-12\">\r\n                                <h3 class=\"panel-title\">" . $ADMINLANG_domainstatus . " (" . $subdomain . ")</h3>\r\n                            </div>\r\n                        </div>\r\n                    </div>\r\n                </div>\r\n            </div>  \r\n        \r\n            <div class=\"col-sm-12\">\r\n                <div class=\"panel-body\">\r\n                    <div class=\"row\">\r\n                        <div class=\"col-sm-12\">\r\n                             " . $overview . "\r\n                        </div>\r\n                        <div class=\"col-sm-12\">\r\n                            " . $statusreturn . "\r\n                        </div>\r\n                        <div class=\"col-sm-12\">\r\n                            " . $DNSHTML . "               \r\n                        </div>\r\n                    </div>\r\n                </div>\r\n                                \r\n                </div>\r\n            </div>\r\n        </div>\r\n</div>";
            }
        }
    }
}

?>