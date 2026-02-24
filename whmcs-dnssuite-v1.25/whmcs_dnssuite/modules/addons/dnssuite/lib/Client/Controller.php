<?php
/*
 * @ https://EasyToYou.eu - IonCube v11 Decoder Online
 * @ PHP 7.4
 * @ Decoder version: 1.0.2
 * @ Release: 10/08/2022
 */

// Decoded file for php version 74.
namespace WHMCS\Module\Addon\AddonModule\Client;

class Controller
{
    public $obj;
    public $pdo;
    public $addonlang;
    public function __construct()
    {
        $this->pdo = \Illuminate\Database\Capsule\Manager::connection()->getPdo();
        $this->pdo->beginTransaction();
        require ROOTDIR . "/modules/addons/dnssuite/class/class.dnssuite.php";
        $this->obj = new \DNSSUITE\Suite_ClientArea($this->pdo, $_POST["domainid"]);
        $userLang = $_SESSION["Language"];
        if($userLang == "") {
            $query = $this->pdo->prepare("SELECT value FROM tblconfiguration WHERE setting = 'Language' ");
            $query->execute();
            $query = $query->fetch(\PDO::FETCH_ASSOC);
            $query = $query["value"];
            include ROOTDIR . "/modules/addons/dnssuite/lang/" . $query . ".php";
        } else {
            include ROOTDIR . "/modules/addons/dnssuite/lang/" . $userLang . ".php";
        }
        $this->addonlang = $_ADDONLANG;
    }
    public function index($vars)
    {
        $modulelink = $vars["modulelink"];
        $version = $vars["version"];
        if($this->obj->isSubAccount()) {
            $template = "nopermission";
            return ["pagetitle" => $this->addonlang["dnssuitePage_breadcrumb_dnssuite"], "breadcrumb" => ["index.php?m=dnssuite" => $this->addonlang["dnssuitePage_breadcrumb_dnssuite"]], "templatefile" => $template, "requirelogin" => true, "forcessl" => true, "vars" => ["ADDONLANG" => $this->addonlang, "modulelink" => $modulelink]];
        }
        if($this->obj->basic->configs["respectwhmcsdns"] == "on") {
            $query = $this->pdo->prepare("SELECT * FROM tbldomains WHERE userid = :uid AND status = 'Active' AND dnsmanagement = 1 ORDER BY domain");
        } else {
            $query = $this->pdo->prepare("SELECT * FROM tbldomains WHERE userid = :uid AND status = 'Active' ORDER BY domain");
        }
        $query->execute([":uid" => $_SESSION["uid"]]);
        $domains = $query->fetchAll(\PDO::FETCH_ASSOC);
        if(!empty($domains)) {
            for ($i = 0; $i < count($domains); $i++) {
                $dataarray .= "{id: '" . $domains[$i]["id"] . "',text:'" . $domains[$i]["domain"] . "'},";
                $var_havelist = true;
            }
        } else {
            $var_havelist = false;
        }
        $template = "index";
        return ["pagetitle" => $this->addonlang["dnssuitePage_breadcrumb_dnssuite"], "breadcrumb" => ["index.php?m=dnssuite" => $this->addonlangANG["dnssuitePage_breadcrumb_dnssuite"]], "templatefile" => $template, "requirelogin" => true, "forcessl" => true, "vars" => ["ADDONLANG" => $this->addonlang, "modulelink" => $modulelink, "dataarray" => $dataarray, "havelist" => $var_havelist]];
    }
    public function manage($vars)
    {
        if($this->obj->isSubAccount()) {
            $template = "nopermission";
            return ["pagetitle" => $this->addonlang["dnssuitePage_breadcrumb_dnssuite"], "breadcrumb" => ["index.php?m=dnssuite" => $this->addonlang["dnssuitePage_breadcrumb_dnssuite"]], "templatefile" => $template, "requirelogin" => true, "forcessl" => true, "vars" => ["ADDONLANG" => $this->addonlang, "modulelink" => $modulelink]];
        }
        if(preg_match("/\\d+/", $_GET["domainid"])) {
            $_POST = $_GET;
        }
        if(!preg_match("/\\d+/", $_POST["domainid"])) {
            header("Location: index.php?m=dnssuite");
            exit;
        }
        if($this->obj->basic->configs["respectwhmcsdns"] == "on") {
            $query = $this->pdo->prepare("SELECT dnsmanagement FROM tbldomains WHERE id = :did");
            $query->execute([":did" => $_POST["domainid"]]);
            $query = $query->fetch(\PDO::FETCH_ASSOC);
            $dnsmanagement = $query["dnsmanagement"];
            if($dnsmanagement != "1") {
                header("Location: index.php?m=dnssuite");
                exit;
            }
        }
        $modulelink = $vars["modulelink"];
        $version = $vars["version"];
        if(!$this->obj->checkDomainExist($_POST["domainid"], NULL)) {
            header("Location: index.php?m=dnssuite");
            exit;
        }
        $initreturn = $this->obj->initOverview($_POST["domainid"], 0);
        $domain = $this->obj->basic->getDomainfromDID($_POST["domainid"]);
        if($_POST["switchns"] == "yes") {
            $switchns = $this->obj->switchNS($_POST["domainid"]);
            if($switchns) {
                $switchns = true;
                $noticemsg = $this->addonlang["dnssuitePage_manage_overview_switchns_success"];
                if($this->obj->basic->configs["enablenotification"] == "on" && $initreturn["notificationconfigs"]["dns"] == 1) {
                    $this->obj->basic->sendNotificationEmail(["did" => $_POST["domainid"], "type" => $this->addonlang["dnssuitePage_email_type_switchnameserver"], "old" => $initreturn["nsarray"][0] . " " . $initreturn["nsarray"][1] . " " . $initreturn["nsarray"][2] . " " . $initreturn["nsarray"][3] . " " . $initreturn["nsarray"][4] . " ", "new" => $this->obj->basic->configs["defaultnameserver1"] . " " . $this->obj->basic->configs["defaultnameserver2"] . " " . $this->obj->basic->configs["defaultnameserver3"] . " " . $this->obj->basic->configs["defaultnameserver4"] . " " . $this->obj->basic->configs["defaultnameserver5"] . " "]);
                }
            } else {
                $switchnsfailed = true;
                $noticemsg = $this->addonlang["dnssuitePage_manage_overview_switchns_failed"];
            }
        }
        if($_POST["resetdomain"] == "yes") {
            $resetdomain = $this->obj->resetDomain($_POST["domainid"]);
            if($resetdomain) {
                $resetdomain = true;
                $noticemsg = $this->addonlang["dnssuitePage_manage_overview_resetdomain_success"];
                if($this->obj->basic->configs["enablenotification"] == "on" && ($initreturn["notificationconfigs"]["dns"] == 1 || $initreturn["notificationconfigs"]["emailforward"] == 1 || $initreturn["notificationconfigs"]["emailcatchall"] == 1 || $initreturn["notificationconfigs"]["webredirect"] == 1)) {
                    $emailtype = $this->addonlang["dnssuitePage_email_all"] . " - (" . $this->addonlang["dnssuitePage_email_reset"] . ")";
                    $emailoldval = $this->addonlang["dnssuitePage_email_na"];
                    $emailnewval = $this->addonlang["dnssuitePage_email_na"];
                    $this->obj->basic->sendNotificationEmail(["did" => $_POST["domainid"], "type" => $emailtype, "old" => $emailoldval, "new" => $emailnewval]);
                }
            } else {
                $resetdomainfailed = true;
                $noticemsg = $this->addonlang["dnssuitePage_manage_overview_resetdomain_failed"];
            }
        }
        if($_POST["cleardns"] == "yes") {
            $cleardns = $this->obj->clearDNS($_POST["domainid"]);
            if($cleardns) {
                $cleardns = true;
                $noticemsg = $this->addonlang["dnssuitePage_manage_overview_cleardns_success"];
                if($this->obj->basic->configs["enablenotification"] == "on" && $initreturn["notificationconfigs"]["dns"] == 1) {
                    $emailtype = $this->addonlang["dnssuitePage_email_cleardns"] . " - (" . $this->addonlang["dnssuitePage_email_clear"] . ")";
                    $emailoldval = $this->addonlang["dnssuitePage_email_na"];
                    $emailnewval = $this->addonlang["dnssuitePage_email_na"];
                    $this->obj->basic->sendNotificationEmail(["did" => $_POST["domainid"], "type" => $emailtype, "old" => $emailoldval, "new" => $emailnewval]);
                }
            } else {
                $cleardnsfailed = true;
                $noticemsg = $this->addonlang["dnssuitePage_manage_overview_resetdomain_failed"];
            }
        }
        if($_POST["restorednstemplate"] == "yes" && 1 < $this->obj->basic->edition) {
            if($this->obj->restoreDNSTemplatetoDomain($_POST["domainid"], $_POST)) {
                $restorednstemplate = true;
                $noticemsg = $this->addonlang["dnssuitePage_manage_restoretemplate_success"];
                if($this->obj->basic->configs["enablenotification"] == "on" && $initreturn["notificationconfigs"]["dns"] == 1) {
                    $this->obj->basic->sendNotificationEmail(["did" => $_POST["domainid"], "type" => $this->addonlang["dnssuitePage_email_type_dnstemplaterestore"], "old" => $this->addonlang["dnssuitePage_email_na"], "new" => $this->obj->returnDNSTemplateName(["dnstemplate" => $_POST["dnstemplate"]])]);
                }
            } else {
                $restorednstemplatefailed = true;
                $noticemsg = $this->addonlang["dnssuitePage_manage_restoretemplate_failed"];
            }
        }
        if($_POST["createuserdnstemplate"] == "yes" && 1 < $this->obj->basic->edition) {
            if(!$this->obj->checkDuplicateUserTemplateName($_POST["domainid"], ["name" => $_POST["name"]])) {
                if($this->obj->createUserDNSTemplate($_POST["domainid"], ["name" => $_POST["name"]])) {
                    $createuserdnstemplate = true;
                    $noticemsg = $this->addonlang["dnssuitePage_manage_savetemplate_success"];
                    $this->obj->loadDNSTemplates();
                    $initreturn["userdnstemplates"] = $this->obj->loadUserDNSTemplates();
                } else {
                    $createuserdnstemplatefailed = true;
                    $noticemsg = $this->addonlang["dnssuitePage_manage_savetemplate_failed"];
                }
            } else {
                $createuserdnstemplatefailed = true;
                $noticemsg = $this->addonlang["dnssuitePage_manage_savetemplate_duplicate"];
            }
        }
        if($_POST["deleteuserdnstemplate"] == "yes" && 1 < $this->obj->basic->edition) {
            if($this->obj->checkUserTemplateOwnership($_POST["userdnstemplates"])) {
                if($this->obj->deleteUserDNSTemplate($_POST["userdnstemplates"])) {
                    $deleteuserdnstemplate = true;
                    $noticemsg = $this->addonlang["dnssuitePage_manage_deletetemplate_success"];
                    $this->obj->loadDNSTemplates();
                    $initreturn["userdnstemplates"] = $this->obj->loadUserDNSTemplates();
                } else {
                    $deleteuserdnstemplatefailed = true;
                    $noticemsg = $this->addonlang["dnssuitePage_manage_deletetemplate_failed"];
                }
            } else {
                $deleteuserdnstemplatefailed = true;
                $noticemsg = $this->addonlang["dnssuitePage_manage_deletetemplate_notowned"];
            }
        }
        if(1 < $this->obj->basic->edition) {
            $this->obj->basic->getAPI($_POST["domainid"]);
        }
        if($this->obj->basic->subdomain["enable"] != "off") {
            $subdomains = $this->obj->returnSubDomainsLocal($_POST["domainid"]);
            if(count($subdomains) == 0) {
                $subdomainfalse = true;
            } else {
                for ($i = 0; $i < count($subdomains); $i++) {
                    $subdomains[$i]["host"] = $subdomains[$i]["host"] . "." . $this->obj->basic->getDomainfromDID($_POST["domainid"]);
                }
            }
        }
        if($zonedata = $this->obj->loadDomain($_POST["domainid"], false)) {
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
        } else {
            $zonefalse = true;
        }
        if($redirectdata = $this->obj->loadRedirect($_POST["domainid"])) {
        } else {
            $redirectfalse = true;
        }
        if($forwarddata = $this->obj->loadForwarder($_POST["domainid"])) {
        } else {
            $forwardfalse = true;
        }
        if($catchalldata = $this->obj->loadCatchall($_POST["domainid"])) {
        } else {
            $catchallfalse = true;
        }
        $destinationemails = $this->obj->email->generateSelectOptionsAny($this->obj->email->emaildestinationdata["confirmedemail"]);
        if($this->obj->basic->edition == 0) {
            $edition = "free";
        } elseif($this->obj->basic->edition == 1) {
            $edition = "premium";
        } elseif($this->obj->basic->edition == 2) {
            $edition = "professional";
        }
        $havewebredirect = $this->obj->checkHaveWebRedirect($_POST["domainid"]);
        $haveforwarding = $this->obj->checkHaveForwarding($_POST["domainid"]);
        if(!empty($zonedata["ns"])) {
            $counts["ns"] = count($zonedata["ns"]);
        } else {
            $counts["ns"] = 0;
        }
        return ["pagetitle" => $this->addonlang["dnssuitePage_dns_pagetitle"], "breadcrumb" => ["index.php?m=addonmodule" => $this->addonlang["dnssuitePage_breadcrumb_dnssuite"], "index.php?m=addonmodule&action=manage" => $this->addonlang["dnssuitePage_breadcrumb_dnsmanagement"]], "templatefile" => "manage", "requirelogin" => true, "forcessl" => true, "vars" => ["ADDONLANG" => $this->addonlang, "errormsg" => $errormsg, "noticemsg" => $noticemsg, "domaindot" => $domain . ".", "modulelink" => $modulelink, "edition" => $edition, "zonefalse" => $zonefalsefalse, "nsfail" => $initreturn["nsfail"], "havewebredirect" => $havewebredirect, "haveforwarding" => $haveforwarding, "disablemanage" => $this->obj->basic->configs["disablemanage"], "clientletsencrypt" => $this->obj->basic->configs["clientletsencrypt"], "switchns" => $switchns, "switchnsfailed" => $switchnsfailed, "resetdomain" => $resetdomain, "resetdomainfailed" => $resetdomainfailed, "cleardns" => $cleardns, "cleardnsfailed" => $cleardnsfailed, "createuserdnstemplate" => $createuserdnstemplate, "createuserdnstemplatefailed" => $createuserdnstemplatefailed, "dnstemplatearray" => $this->obj->dnstemplates["all"], "userdnstemplatearray" => $initreturn["userdnstemplates"], "deleteuserdnstemplate" => $deleteuserdnstemplate, "deleteuserdnstemplatefailed" => $deleteuserdnstemplatefailed, "restorednstemplate" => $restorednstemplate, "restorednstemplatefailed" => $restorednstemplatefailed, "notificationconfigs" => $initreturn["notificationconfigs"], "updatenotification" => $updatenotification, "updatenotificationfailed" => $updatenotificationfailed, "apistatus" => $apistatus, "recordcount" => $recordcount, "addrecord" => $addrecord, "addrecordfailed" => $addrecordfailed, "updaterecord" => $updaterecord, "updaterecordfailed" => $updaterecordfailed, "deleterecord" => $deleterecord, "deleterecordfailed" => $deleterecordfailed, "addemail" => $addemail, "addemailfailed" => $addemailfailed, "deleteemail" => $deleteemail, "deleteemailfailed" => $deleteemailfailed, "validateerror" => $validateerror, "forwardfalse" => $forwardfalse, "addalias" => $addalias, "aliasexist" => $aliasexist, "addforwarderfailed" => $addforwarderfailed, "modifyforwarder" => $modifyforwarder, "modifyforwarderfailed" => $modifyforwarderfailed, "deleteforwarder" => $deleteforwarder, "deleteforwarderfailed" => $deleteforwarderfailed, "emailexist" => $emailexist, "redirectfalse" => $redirectfalse, "addredirect" => $addredirect, "deleteredirect" => $deleteredirect, "deleteredirectfailed" => $deleteredirectfailed, "modifyredirectfailed" => $modifyredirectfailed, "modifyredirect" => $modifyredirect, "addredirectfailed" => $addredirectfailed, "updatecatchall" => $updatecatchall, "updatecatchallfailed" => $updatecatchallfailed, "verifypin" => $verifypin, "verifypinfailed" => $verifypinfailed, "catchallfalse" => $catchallfalse, "disablecatchall" => $disablecatchall, "disablecatchallfailed" => $disablecatchallfailed, "records_a" => $this->obj->basic->records_a, "records_mx" => $this->obj->basic->records_mx, "records_ns" => $this->obj->basic->records_ns, "records_cname" => $this->obj->basic->records_cname, "records_txt" => $this->obj->basic->records_txt, "records_srv" => $this->obj->basic->records_srv, "records_aaaa" => $this->obj->basic->records_aaaa, "configs" => $this->obj->basic->configs, "nstotal" => $counts["ns"], "zonedata" => $zonedata, "redirectdata" => $redirectdata, "destinationemails" => $destinationemails, "forwarddata" => $forwarddata, "emaildestinationdata" => $this->obj->email->emaildestinationdata, "catchalldata" => $catchalldata, "domainid" => $_POST["domainid"], "domain" => $this->obj->basic->getDomainfromDID($_POST["domainid"]), "forwardertotal" => $this->obj->email->returnTotalForwarders($_POST["domainid"]), "subdomain" => $this->obj->basic->subdomain, "subdomainfalse" => $subdomainfalse, "subdomainlist" => $subdomains, "subdomaincount" => count($subdomains), "slottotal" => $this->obj->email->slottotal, "emailconfig" => $this->obj->basic->emailforward, "catchallconfig" => $this->obj->basic->catchall, "urlconfig" => $this->obj->basic->urlforward, "urlredirecttotal" => $this->obj->redirect->returnRedirectTotal($_POST["domainid"]), "style" => $this->obj->basic->style]];
    }
    public function managesubdomain($vars)
    {
        $sdid = $_GET["sdid"];
        if($this->obj->isSubAccount()) {
            $template = "nopermission";
            return ["pagetitle" => $this->addonlang[dnssuitePage_breadcrumb_dnssuite], "breadcrumb" => ["index.php?m=dnssuite" => $this->addonlang[dnssuitePage_breadcrumb_dnssuite]], "templatefile" => $template, "requirelogin" => true, "forcessl" => true, "vars" => ["ADDONLANG" => $this->addonlang, "modulelink" => $modulelink]];
        }
        if($this->obj->isSubDomainOwned($sdid)) {
            $did = $this->obj->basic->getDIDFromSDID($sdid);
            if($this->obj->basic->configs["respectwhmcsdns"] == "on") {
                $query = $this->pdo->prepare("SELECT dnsmanagement FROM tbldomains WHERE id = :did");
                $query->execute([":did" => $_POST["domainid"]]);
                $query = $query->fetch(\PDO::FETCH_ASSOC);
                $dnsmanagement = $query["dnsmanagement"];
                if($dnsmanagement != "1") {
                    header("Location: index.php?m=dnssuite");
                    exit;
                }
            }
            $modulelink = $vars["modulelink"];
            $version = $vars["version"];
            $initreturndomain = $this->obj->initOverview($did, 0);
            $initreturn = $this->obj->initOverviewSubDomain(["did" => $did, "sdid" => $sdid]);
            $subdomaindata = $this->obj->basic->returnSubDomainFromSDID($sdid);
            $domain = $this->obj->basic->getDomainfromDID($did);
            $subdomain = $subdomaindata["host"] . "." . $domain;
            if($_POST["resetdomain"] == "yes") {
                $resetdomain = $this->obj->resetSubDomain(["did" => $did, "sdid" => $sdid, "host" => $subdomaindata["host"]]);
                if($resetdomain) {
                    $resetdomain = true;
                    if($obj->basic->configs["enablenotification"] == "on" && ($initreturn["notificationconfigs"]["dns"] == 1 || $initreturn["notificationconfigs"]["emailforward"] == 1 || $initreturn["notificationconfigs"]["emailcatchall"] == 1 || $initreturn["notificationconfigs"]["webredirect"] == 1)) {
                        $emailtype = $_ADDONLANG["dnssuitePage_email_all"] . " - (" . $_ADDONLANG["dnssuitePage_email_reset"] . ")";
                        $emailoldval = $_ADDONLANG["dnssuitePage_email_na"];
                        $emailnewval = $_ADDONLANG["dnssuitePage_email_na"];
                        $obj->basic->sendSubDomainNotificationEmail(["did" => $_POST["domainid"], "type" => $emailtype, "old" => $emailoldval, "new" => $emailnewval, "sid" => $sid]);
                    }
                } else {
                    $resetdomainfailed = true;
                }
            }
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
            $destinationemails = $this->obj->email->generateSelectOptionsAny($this->obj->email->emaildestinationdata["confirmedemail"]);
            if($this->obj->basic->edition == 0) {
                $edition = "free";
            } elseif($this->obj->basic->edition == 1) {
                $edition = "premium";
            } elseif($this->obj->basic->edition == 2) {
                $edition = "professional";
            }
            $havewebredirect = $this->obj->checkHaveWebRedirect($_POST["domainid"]);
            $haveforwarding = $this->obj->checkHaveForwarding($_POST["domainid"]);
            return ["pagetitle" => $this->addonlang["dnssuitePage_dns_pagetitle"], "breadcrumb" => ["index.php?m=addonmodule" => $this->addonlang["dnssuitePage_breadcrumb_dnssuite"], "index.php?m=addonmodule&action=manage" => $this->addonlang["dnssuitePage_breadcrumb_dnsmanagement"]], "templatefile" => "managesubdomain", "requirelogin" => true, "forcessl" => true, "vars" => ["ADDONLANG" => $this->addonlang, "errormsg" => $errormsg, "noticemsg" => $noticemsg, "domaindot" => $domain . ".", "modulelink" => $modulelink, "edition" => $edition, "zonefalse" => $zonefalsefalse, "nsfail" => $initreturndomain["nsfail"], "havewebredirect" => $havewebredirect, "haveforwarding" => $haveforwarding, "disablemanage" => $this->obj->basic->configs["disablemanage"], "resetdomain" => $resetdomain, "resetdomainfailed" => $resetdomainfailed, "clientletsencrypt" => $this->obj->basic->configs["clientletsencrypt"], "addemail" => $addemail, "addemailfailed" => $addemailfailed, "deleteemail" => $deleteemail, "deleteemailfailed" => $deleteemailfailed, "validateerror" => $validateerror, "forwardfalse" => $forwardfalse, "addalias" => $addalias, "aliasexist" => $aliasexist, "addforwarderfailed" => $addforwarderfailed, "modifyforwarder" => $modifyforwarder, "modifyforwarderfailed" => $modifyforwarderfailed, "deleteforwarder" => $deleteforwarder, "deleteforwarderfailed" => $deleteforwarderfailed, "emailexist" => $emailexist, "redirectfalse" => $redirectfalse, "addredirect" => $addredirect, "deleteredirect" => $deleteredirect, "deleteredirectfailed" => $deleteredirectfailed, "modifyredirectfailed" => $modifyredirectfailed, "modifyredirect" => $modifyredirect, "addredirectfailed" => $addredirectfailed, "updatecatchall" => $updatecatchall, "updatecatchallfailed" => $updatecatchallfailed, "verifypin" => $verifypin, "verifypinfailed" => $verifypinfailed, "catchallfalse" => $catchallfalse, "disablecatchall" => $disablecatchall, "disablecatchallfailed" => $disablecatchallfailed, "configs" => $this->obj->basic->configs, "redirectdata" => $redirectdata, "destinationemails" => $destinationemails, "forwarddata" => $forwarddata, "emaildestinationdata" => $this->obj->email->emaildestinationdata, "catchalldata" => $catchalldata, "domainid" => $did, "sdid" => $sdid, "domain" => $subdomain, "subdomain" => $subdomain, "forwardertotal" => $this->obj->email->returnTotalForwarders($_POST["domainid"]), "slottotal" => $this->obj->email->slottotal, "emailconfig" => $this->obj->basic->emailforward, "catchallconfig" => $this->obj->basic->catchall, "urlconfig" => $this->obj->basic->urlforward, "urlredirecttotal" => $this->obj->redirect->returnRedirectTotal($_POST["domainid"]), "style" => $this->obj->basic->style]];
        }
        if(!preg_match("/\\d+/", $_POST["domainid"])) {
            header("Location: index.php?m=dnssuite");
            exit;
        }
    }
    public function ddns($vars)
    {
        if($this->obj->basic->configs["enabledyndns"] == "on") {
            $ddnsobj = new \DNSSUITE\DDNSFunctions($this->pdo);
            if($ddnsobj->isBanned($_SERVER["REMOTE_ADDR"])) {
                exit;
            }
            if($this->obj->basic->configs["enabledyndnsbruteforce"] != "on" || $this->obj->basic->configs["enabledyndnsbruteforce"] == "on" && !$ddnsobj->isOverBruteForceLimit(["ip" => $_SERVER["REMOTE_ADDR"], "limit" => $this->obj->basic->configs["dyndnsbruteforcelimit"], "timecheck" => $this->obj->basic->configs["bruteforcetime"]])) {
                if($ddnsobj->verifyKeys(["keyphrase" => $_GET["keyphrase"], "pass" => $_GET["pass"]])) {
                    $relid = $ddnsobj->returnRelid(["keyphrase" => $_GET["keyphrase"], "pass" => $_GET["pass"]]);
                    $initreturn = $this->obj->initOverview($relid, []);
                    if($ddnsobj->isOverAPILimit(["relid" => $relid, "limit" => $this->obj->basic->configs["dyndnslimit"]])) {
                        echo json_encode(["status" => 0, "log" => "over the hourly api usage rate, please try again later"]);
                        exit;
                    }
                    if(isset($_GET["host"])) {
                        if($this->obj->basic->validateHostname($_GET["host"])) {
                            if($_GET["ipv6"] == "yes") {
                                $ip = $_GET["ip"];
                                if(filter_var($ip, FILTER_VALIDATE_IP, FILTER_FLAG_IPV6)) {
                                    if($zonedata = $this->obj->loadDomain($relid, true)) {
                                        for ($i = 0; $i < count($zonedata["aaaa"]); $i++) {
                                            $zonedata["aaaa"][$i] = explode(" ", $zonedata["aaaa"][$i]);
                                            $zonedata["aaaa"][$i][] = $i;
                                        }
                                        $recordcount["aaaa"] = count($zonedata["aaaa"]);
                                    }
                                    for ($i = 0; $i < count($zonedata["aaaa"]); $i++) {
                                        if($zonedata["aaaa"][$i][0] == $_GET["host"]) {
                                            if($this->obj->updateDNSRecord($relid, ["mode" => "AAAA", "value" => $ip, "row" => $zonedata["aaaa"][$i][5], "bypass" => true])) {
                                                if($this->obj->basic->configs["enablenotification"] == "on" && $initreturn["notificationconfigs"]["ddns"] == 1) {
                                                    $emailtype = $this->addonlang["dnssuitePage_email_type_ddns"] . " " . $this->obj->oldvalues["type"] . " - (" . $this->addonlang["dnssuitePage_email_update"] . ")";
                                                    $emailoldval = $this->obj->oldvalues["host"] . " " . $this->obj->oldvalues["value"];
                                                    $emailnewval = $ip;
                                                    $this->obj->basic->sendNotificationEmail(["did" => $relid, "type" => $emailtype, "old" => $emailoldval, "new" => $emailnewval]);
                                                }
                                                $ddnsobj->addLog($relid);
                                                echo json_encode(["status" => 1, "log" => "ip updated successfully"]);
                                                exit;
                                            }
                                            echo json_encode(["status" => 0, "log" => "ip update failed"]);
                                            exit;
                                        }
                                    }
                                    if($this->obj->addRecord($relid, ["host" => $_GET["host"], "value" => $ip, "mode" => "AAAA", "bypass" => true])) {
                                        $ddnsobj->addLog($relid);
                                        if($this->obj->basic->configs["enablenotification"] == "on" && $initreturn["notificationconfigs"]["ddns"] == 1) {
                                            $emailtype = $this->addonlang["dnssuitePage_email_type_ddns"] . " AAAA " . " - (" . $this->addonlang["dnssuitePage_email_add"] . ")";
                                            $emailnewval = $_GET["host"] . " " . $ip;
                                            $this->obj->basic->sendNotificationEmail(["did" => $relid, "type" => $emailtype, "old" => $this->addonlang["dnssuitePage_email_na"], "new" => $emailnewval]);
                                        }
                                        echo json_encode(["status" => 1, "log" => "new host added successfully"]);
                                        exit;
                                    }
                                    echo json_encode(["status" => 0, "log" => "unable to create new host"]);
                                    exit;
                                }
                                echo json_encode(["status" => 0, "log" => "invalid ip"]);
                            } else {
                                if(isset($_GET["ip"])) {
                                    $ip = $_GET["ip"];
                                } else {
                                    $ip = $_SERVER["REMOTE_ADDR"];
                                }
                                if(filter_var($ip, FILTER_VALIDATE_IP, FILTER_FLAG_IPV4)) {
                                    $relid = $ddnsobj->returnRelid(["keyphrase" => $_GET["keyphrase"], "pass" => $_GET["pass"]]);
                                    if($zonedata = $this->obj->loadDomain($relid, true)) {
                                        for ($i = 0; $i < count($zonedata["a"]); $i++) {
                                            $zonedata["a"][$i] = explode(" ", $zonedata["a"][$i]);
                                            $zonedata["a"][$i][] = $i;
                                        }
                                        $recordcount["a"] = count($zonedata["a"]);
                                    }
                                    for ($i = 0; $i < count($zonedata["a"]); $i++) {
                                        if($zonedata["a"][$i][0] == $_GET["host"]) {
                                            if($this->obj->updateDNSRecord($relid, ["mode" => "A", "value" => $ip, "row" => $zonedata["a"][$i][5], "bypass" => true])) {
                                                if($this->obj->basic->configs["enablenotification"] == "on" && $initreturn["notificationconfigs"]["ddns"] == 1) {
                                                    $emailtype = $this->addonlang["dnssuitePage_email_type_ddns"] . " " . $this->obj->oldvalues["type"] . " - (" . $this->addonlang["dnssuitePage_email_update"] . ")";
                                                    $emailoldval = $this->obj->oldvalues["host"] . " " . $this->obj->oldvalues["value"];
                                                    $emailnewval = $ip;
                                                    $this->obj->basic->sendNotificationEmail(["did" => $relid, "type" => $emailtype, "old" => $emailoldval, "new" => $emailnewval]);
                                                }
                                                $ddnsobj->addLog($relid);
                                                echo json_encode(["status" => 1, "log" => "ip updated successfully"]);
                                                exit;
                                            }
                                            echo json_encode(["status" => 0, "log" => "ip update failed"]);
                                            exit;
                                        }
                                    }
                                    if($this->obj->addRecord($relid, ["host" => $_GET["host"], "value" => $ip, "mode" => "A", "bypass" => true])) {
                                        $ddnsobj->addLog($relid);
                                        if($this->obj->basic->configs["enablenotification"] == "on" && $initreturn["notificationconfigs"]["ddns"] == 1) {
                                            $emailtype = $this->addonlang["dnssuitePage_email_type_ddns"] . " A " . " - (" . $this->addonlang["dnssuitePage_email_add"] . ")";
                                            $emailnewval = $_GET["host"] . " " . $ip;
                                            $this->obj->basic->sendNotificationEmail(["did" => $relid, "type" => $emailtype, "old" => $this->addonlang["dnssuitePage_email_na"], "new" => $emailnewval]);
                                        }
                                        echo json_encode(["status" => 1, "log" => "new host added successfully"]);
                                        exit;
                                    }
                                    echo json_encode(["status" => 0, "log" => "unable to create new host"]);
                                    exit;
                                }
                                echo json_encode(["status" => 0, "log" => "invalid ip"]);
                            }
                        } else {
                            echo json_encode(["status" => 0, "log" => "invalid host"]);
                        }
                    } else {
                        $domain = $this->obj->basic->getDomainfromDID($relid);
                        $domaindot = $domain . ".";
                        if($_GET["ipv6"] == "yes") {
                            $ip = $_GET["ip"];
                            if(filter_var($ip, FILTER_VALIDATE_IP, FILTER_FLAG_IPV6)) {
                                if($zonedata = $this->obj->loadDomain($relid, true)) {
                                    for ($i = 0; $i < count($zonedata["aaaa"]); $i++) {
                                        $zonedata["aaaa"][$i] = explode(" ", $zonedata["aaaa"][$i]);
                                        $zonedata["aaaa"][$i][] = $i;
                                    }
                                    $recordcount["aaaa"] = count($zonedata["aaaa"]);
                                }
                                for ($i = 0; $i < count($zonedata["aaaa"]); $i++) {
                                    if($zonedata["aaaa"][$i][0] == $domaindot) {
                                        if($this->obj->updateDNSRecord($relid, ["mode" => "AAAA", "value" => $ip, "row" => $zonedata["aaaa"][$i][5], "bypass" => true])) {
                                            $ddnsobj->addLog($relid);
                                            if($this->obj->basic->configs["enablenotification"] == "on" && $initreturn["notificationconfigs"]["ddns"] == 1) {
                                                $emailtype = $this->addonlang["dnssuitePage_email_type_ddns"] . " " . $this->obj->oldvalues["type"] . " - (" . $this->addonlang["dnssuitePage_email_update"] . ")";
                                                $emailoldval = $this->obj->oldvalues["host"] . " " . $this->obj->oldvalues["value"];
                                                $emailnewval = $ip;
                                                $this->obj->basic->sendNotificationEmail(["did" => $relid, "type" => $emailtype, "old" => $emailoldval, "new" => $emailnewval]);
                                            }
                                            echo json_encode(["status" => 1, "log" => "ip updated successfully"]);
                                            exit;
                                        }
                                        echo json_encode(["status" => 0, "log" => "ip update failed"]);
                                        exit;
                                    }
                                }
                                if($this->obj->addRecord($relid, ["host" => $domaindot, "value" => $ip, "mode" => "AAAA", "bypass" => true])) {
                                    $ddnsobj->addLog($relid);
                                    if($this->obj->basic->configs["enablenotification"] == "on" && $initreturn["notificationconfigs"]["ddns"] == 1) {
                                        $emailtype = $this->addonlang["dnssuitePage_email_type_ddns"] . " AAAA " . " - (" . $this->addonlang["dnssuitePage_email_update"] . ")";
                                        $emailnewval = $domaindot . " " . $ip;
                                        $this->obj->basic->sendNotificationEmail(["did" => $relid, "type" => $emailtype, "old" => $this->addonlang["dnssuitePage_email_na"], "new" => $emailnewval]);
                                    }
                                    echo json_encode(["status" => 1, "log" => "new host added successfully"]);
                                    exit;
                                }
                                echo json_encode(["status" => 0, "log" => "unable to create new host"]);
                                exit;
                            }
                            echo json_encode(["status" => 0, "log" => "invalid ip"]);
                        } else {
                            if(isset($_GET["ip"])) {
                                $ip = $_GET["ip"];
                            } else {
                                $ip = $_SERVER["REMOTE_ADDR"];
                            }
                            if(filter_var($ip, FILTER_VALIDATE_IP, FILTER_FLAG_IPV4)) {
                                if($zonedata = $this->obj->loadDomain($relid, true)) {
                                    for ($i = 0; $i < count($zonedata["a"]); $i++) {
                                        $zonedata["a"][$i] = explode(" ", $zonedata["a"][$i]);
                                        $zonedata["a"][$i][] = $i;
                                    }
                                    $recordcount["a"] = count($zonedata["a"]);
                                }
                                for ($i = 0; $i < count($zonedata["a"]); $i++) {
                                    if($zonedata["a"][$i][0] == $domaindot) {
                                        if($this->obj->updateDNSRecord($relid, ["mode" => "A", "value" => $ip, "row" => $zonedata["a"][$i][5], "bypass" => true])) {
                                            $ddnsobj->addLog($relid);
                                            if($this->obj->basic->configs["enablenotification"] == "on" && $initreturn["notificationconfigs"]["ddns"] == 1) {
                                                $emailtype = $this->addonlang["dnssuitePage_email_type_ddns"] . " " . $this->obj->oldvalues["type"] . " - (" . $this->addonlang["dnssuitePage_email_update"] . ")";
                                                $emailoldval = $this->obj->oldvalues["host"] . " " . $this->obj->oldvalues["value"];
                                                $emailnewval = $ip;
                                                $this->obj->basic->sendNotificationEmail(["did" => $relid, "type" => $emailtype, "old" => $emailoldval, "new" => $emailnewval]);
                                            }
                                            echo json_encode(["status" => 1, "log" => "ip updated successfully"]);
                                            exit;
                                        }
                                        echo json_encode(["status" => 0, "log" => "ip update failed"]);
                                        exit;
                                    }
                                }
                                if($this->obj->addRecord($relid, ["host" => $domaindot, "value" => $ip, "mode" => "A", "bypass" => true])) {
                                    $ddnsobj->addLog($relid);
                                    if($this->obj->basic->configs["enablenotification"] == "on" && $initreturn["notificationconfigs"]["ddns"] == 1) {
                                        $emailtype = $this->addonlang["dnssuitePage_email_type_ddns"] . " A " . " - (" . $this->addonlang["dnssuitePage_email_add"] . ")";
                                        $emailnewval = $domaindot . " " . $ip;
                                        $this->obj->basic->sendNotificationEmail(["did" => $relid, "type" => $emailtype, "old" => $this->addonlang["dnssuitePage_email_na"], "new" => $emailnewval]);
                                    }
                                    echo json_encode(["status" => 1, "log" => "new host added successfully"]);
                                    exit;
                                }
                                echo json_encode(["status" => 0, "log" => "unable to create new host"]);
                                exit;
                            }
                            echo json_encode(["status" => 0, "log" => "invalid ip"]);
                        }
                    }
                } else {
                    $ddnsobj->addBruteForceLog(["ip" => $_SERVER["REMOTE_ADDR"]]);
                    echo json_encode(["status" => 0, "log" => "incorrect login credentials"]);
                }
            } else {
                $ddnsobj->addBruteForceBan(["ip" => $_SERVER["REMOTE_ADDR"], "bantimer" => $this->obj->basic->configs["bruteforcebantime"]]);
            }
        }
        exit;
    }
}

?>