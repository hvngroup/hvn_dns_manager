<?php
/*
 * @ https://EasyToYou.eu - IonCube v11 Decoder Online
 * @ PHP 7.4
 * @ Decoder version: 1.0.2
 * @ Release: 10/08/2022
 */

// Decoded file for php version 74.
if(!defined("WHMCS")) {
    exit("This file cannot be accessed directly");
}
function dnssuite_config()
{
    $pdo = WHMCS\Database\Capsule::connection()->getPdo();
    $query = $pdo->prepare("SELECT * FROM tbladmins WHERE disabled = 0");
    $query->execute();
    $query = $query->fetchAll(PDO::FETCH_ASSOC);
    $admins = $query;
    if(!empty($admins)) {
        for ($i = 0; $i < count($admins); $i++) {
            $adminoption .= "," . $admins[$i]["username"];
        }
    }
    $query = $pdo->prepare("SELECT * FROM tblemailtemplates WHERE type = 'general' AND `disabled` = '0'");
    $query->execute();
    $query = $query->fetchAll(PDO::FETCH_ASSOC);
    $emails = $query;
    if(!empty($emails)) {
        for ($i = 0; $i < count($emails); $i++) {
            $emailoption .= "," . $emails[$i]["name"];
        }
    }
    return ["name" => "DNS Suite Management", "description" => "This module provides your customers the ability to setup URL forwarding, email forwarding, DNS management for their registered domains", "author" => "Codebox.ca", "language" => "english", "version" => "1.25", "fields" => ["license" => ["FriendlyName" => "License Key", "Type" => "text", "Size" => "23", "Description" => "License Key", "Default" => "Fill in your license key"], "modon" => ["FriendlyName" => "Mod Status", "Type" => "yesno", "Size" => "25", "Description" => "Enable Mod", "Default" => "on"], "templatestyle" => ["FriendlyName" => "Template Style", "Type" => "dropdown", "Options" => "Six,Twentyone", "Description" => "The style of your WHMCS template is using"], "respectwhmcsdns" => ["FriendlyName" => "Respect WHMCS DNS Setting", "Type" => "yesno", "Size" => "25", "Description" => "When enabled, the module will respect each domain's DNS Management setting"], "disablemanage" => ["FriendlyName" => "Disable Client Management without Correct Nameservers", "Type" => "yesno", "Size" => "25", "Description" => "When enabled, the client will not be able to modify DNS settings when the domain's nameserver isn't set", "Default" => "on"], "templateemailverify" => ["FriendlyName" => "Email Verify Template", "Type" => "dropdown", "Options" => $emailoption, "Description" => "The email template of (Email Desintation Verification)"], "subaccountrestriction" => ["FriendlyName" => "Restrict Sub-accounts", "Type" => "yesno", "Size" => "25", "Description" => "Restrict sub-accounts to use modules when account with domain manage permission"], "enablenotification" => ["FriendlyName" => "Enable email notification", "Type" => "yesno", "Size" => "25", "Description" => "Enabling this will allow client to receive email notification when changes made"], "templatenotificationemail" => ["FriendlyName" => "Notification Email Template", "Type" => "dropdown", "Options" => $emailoption, "Description" => "The email template to send for notification"], "daserver" => ["FriendlyName" => "DirectAdmin URL", "Type" => "text", "Size" => "40", "Description" => "The full hostname of your DirectAdmin DNS server"], "daport" => ["FriendlyName" => "DirectAdmin Custom Port", "Type" => "text", "Size" => "40", "Description" => "Use this field if you use custom port for your DirectAdmin. Otherwise leave it blank"], "dalogin" => ["FriendlyName" => "DirectAdmin Login", "Type" => "text", "Size" => "40", "Description" => "DirectAdmin Username", "Default" => ""], "dapassword" => ["FriendlyName" => "DirecrAdmin Password", "Type" => "password", "Size" => "40", "Description" => "DirectAdmin User password", "Default" => ""], "dassl" => ["FriendlyName" => "DirectAdmin SSL Connection", "Type" => "yesno", "Size" => "25", "Description" => "Use SSL connection to DA server"], "dawebtemplate" => ["FriendlyName" => "Web template file name", "Type" => "text", "Size" => "40", "Description" => "The zip file that contains your files that will be used to extract to new domain public_html.", "Default" => "webtemplate.zip"], "daphp" => ["FriendlyName" => "Enable PHP for domain", "Type" => "yesno", "Size" => "25", "Description" => "To allow to run PHP scripts (The DA account must have PHP previledge)", "Default" => "on"], "dawebssl" => ["FriendlyName" => "Enable SSL for domain", "Type" => "yesno", "Size" => "25", "Description" => "Turn HTTPS on the domain (Will use Letsencrypt)"], "clientletsencrypt" => ["FriendlyName" => "Clientarea Letsencrypt Trigger", "Type" => "yesno", "Size" => "25", "Description" => "Allow client to manually trigger Letsencrypt in the client area"], "largedbexclusion" => ["FriendlyName" => "Large DB exclusion", "Type" => "yesno", "Size" => "25", "Description" => "Enable this if you have a large database of domains. It will disable query of All active domains and only allow for name search"], "fetchonload" => ["FriendlyName" => "Fetch from NS on load", "Type" => "yesno", "Size" => "25", "Description" => "Fetch info from nameserver on every zone load, otherwise zone is load from local cache in database", "Default" => ""], "fetchonloadadmin" => ["FriendlyName" => "Fetch from NS on load (Admin)", "Type" => "yesno", "Size" => "25", "Description" => "Fetch info from nameserver on every zone load for admin backend, otherwise zone is load from local cache in database", "Default" => ""], "refreshtime" => ["FriendlyName" => "TTL on zone refresh", "Type" => "text", "Size" => "40", "Description" => "The TTL on the last updated time before fetching the record again on the NS server (in seconds)", "Default" => "720"], "defaultnameserver1" => ["FriendlyName" => "Default Nameserver 1", "Type" => "text", "Size" => "25", "Description" => "The default nameserver to use, cannot be left blank", "Default" => "ns1.yourdns.com"], "defaultnameserver2" => ["FriendlyName" => "Default Nameserver 2", "Type" => "text", "Size" => "25", "Description" => "The default nameserver to use, cannot be left blank", "Default" => "ns2.yourdns.com"], "defaultnameserver3" => ["FriendlyName" => "Default Nameserver 3", "Type" => "text", "Size" => "25", "Description" => "The default nameserver to use, can be left blank"], "defaultnameserver4" => ["FriendlyName" => "Default Nameserver 4", "Type" => "text", "Size" => "25", "Description" => "The default nameserver to use, can be left blank"], "defaultnameserver5" => ["FriendlyName" => "Default Nameserver 5", "Type" => "text", "Size" => "25", "Description" => "The default nameserver to use, can be left blank"], "defaultttl" => ["FriendlyName" => "Default TTL", "Type" => "text", "Size" => "25", "Description" => "Default TTL value for records in the DNS zone", "Default" => "360"], "showdomainservicelink" => ["FriendlyName" => "Display link under Domain Service Page (Admin)", "Type" => "yesno", "Size" => "25", "Description" => "Enabling this will display a direct link to the DNS Suite Management for a specific domain on the Admin Domain Service page", "Default" => "on"], "showunderdomainmenu" => ["FriendlyName" => "Display under Domain menu", "Type" => "yesno", "Size" => "25", "Description" => "Show management link under the Native WHMCS Domain menu", "Default" => "yes"], "navmenuorder" => ["FriendlyName" => "Menu Showing Order", "Type" => "text", "Size" => "25", "Description" => "The order for the menu item", "Default" => "20"], "showindomainpage" => ["FriendlyName" => "Display in Domain details side bar", "Type" => "yesno", "Size" => "25", "Description" => "Show management link on the domain's detail page", "Default" => "yes"], "createonpreregistrar" => ["FriendlyName" => "Create on Pre-Registrar", "Type" => "yesno", "Size" => "25", "Description" => "Create domain on DA server pre-registrar hook (Required for registry that need an active zone on the nameservers)", "Default" => "yes"], "createonregistration" => ["FriendlyName" => "Create on Registration", "Type" => "yesno", "Size" => "25", "Description" => "Create domain on DA server after domain registration hook", "Default" => "yes"], "createontransfer" => ["FriendlyName" => "Create on Transfer", "Type" => "yesno", "Size" => "25", "Description" => "Create domain on DA server after domain transfer hook", "Default" => "yes"], "enablednseditor" => ["FriendlyName" => "DNS Editor", "Type" => "yesno", "Size" => "25", "Description" => "Enable DNS Editor"], "enablednstemplate" => ["FriendlyName" => "DNS Templates", "Type" => "yesno", "Size" => "25", "Description" => "Enable DNS templates"], "enableuserdnstemplate" => ["FriendlyName" => "User Custom DNS Templates", "Type" => "yesno", "Size" => "25", "Description" => "Enable to allow user to create own DNS templates"], "userdnstemplatelimit" => ["FriendlyName" => "User Custom DNS Template Limit", "Type" => "text", "Size" => "3", "Description" => "Limit how many custom DNS template user can create", "Default" => "10"], "enabledyndns" => ["FriendlyName" => "Dynamic DNS Support", "Type" => "yesno", "Size" => "25", "Description" => "Enable Dynamic DNS API support"], "dyndnslimit" => ["FriendlyName" => "Dynamic DNS API Use limit", "Type" => "text", "Size" => "3", "Description" => "Limit how many API can be called per hour", "Default" => "5"], "enabledyndnsbruteforce" => ["FriendlyName" => "Enable Brute Force Detection", "Type" => "yesno", "Size" => "25", "Description" => "Enable brute force protection"], "bruteforcetime" => ["FriendlyName" => "Bruteforce Timer", "Type" => "text", "Size" => "3", "Description" => "The amount of seconds to check in the bruteforce log before denying", "Default" => "3600"], "bruteforcebantime" => ["FriendlyName" => "Bruteforce Ban Timer", "Type" => "text", "Size" => "3", "Description" => "The amount of seconds to ban the IP address from accessing the API", "Default" => "3600"], "dyndnsbruteforcelimit" => ["FriendlyName" => "Dynamic DNS API Brute Force limit", "Type" => "text", "Size" => "3", "Description" => "Limit how many unsuccessful API call each IP can call per hour", "Default" => "10"], "subdomainlimit" => ["FriendlyName" => "SubDomain Limit", "Type" => "text", "Size" => "3", "Description" => "Limit how many subdomain can set per domain (Set 0 for unlimited, -1 to disable)", "Default" => "5"], "enableurlforwarder" => ["FriendlyName" => "URL Redirect", "Type" => "yesno", "Size" => "25", "Description" => "Enable URL Forwarding", "Default" => "yes"], "enablemaskedurlforwarder" => ["FriendlyName" => "URL Masked Redirect", "Type" => "yesno", "Size" => "25", "Description" => "Enable Masked URL Forwarding", "Default" => "yes"], "maskedhash" => ["FriendlyName" => "Hash for Connector", "Type" => "text", "Size" => "23", "Description" => "The Hash key for use of Masked URL forwarding", "Default" => "abc123"], "urlforwarderlimit" => ["FriendlyName" => "URL Redirect Limit", "Type" => "text", "Size" => "3", "Description" => "Limit how many URL redirect can set per domain (0 for unlimited)", "Default" => "5"], "enableemailforwarder" => ["FriendlyName" => "Email Forwarder", "Type" => "yesno", "Size" => "25", "Description" => "Enable Email Forwarding", "Default" => "yes"], "emailforwarderslotlimit" => ["FriendlyName" => "Email Forwarder (Alias) Limit", "Type" => "text", "Size" => "3", "Description" => "Limit how many Email forwarder can set per domain (0 for unlimited)", "Default" => "5"], "emailslotlimit" => ["FriendlyName" => "Destination Email Slots Limit", "Type" => "text", "Size" => "3", "Description" => "The amount of email destination per domain (0 for unlimited)", "Default" => "10"], "enableemailcatchall" => ["FriendlyName" => "Email Catch-all", "Type" => "yesno", "Size" => "25", "Description" => "Enable Email Catch-all", "Default" => "yes"], "modifyarecord" => ["FriendlyName" => "Allow A record Modification", "Type" => "yesno", "Size" => "25", "Description" => "Enable A Record modification", "Default" => "yes"], "arecordlimit" => ["FriendlyName" => "A records Limit", "Type" => "text", "Size" => "3", "Description" => "The number of records allow for A (0 for unlimited)", "Default" => "100"], "modifyaaaarecord" => ["FriendlyName" => "Allow AAAA record Modification", "Type" => "yesno", "Size" => "25", "Description" => "Enable AAAA Record modification", "Default" => "yes"], "aaaarecordlimit" => ["FriendlyName" => "AAAA records Limit", "Type" => "text", "Size" => "3", "Description" => "The number of records allow for AAAA (0 for unlimited)", "Default" => "100"], "modifycnamerecord" => ["FriendlyName" => "Allow CNAME record Modification", "Type" => "yesno", "Size" => "25", "Description" => "Enable CNAME Record modification"], "cnamerecordlimit" => ["FriendlyName" => "CNAME records Limit", "Type" => "text", "Size" => "3", "Description" => "The number of records allow for CNAME (0 for unlimited)", "Default" => "100"], "modifytxtrecord" => ["FriendlyName" => "Allow TXT record Modification", "Type" => "yesno", "Size" => "25", "Description" => "Enable TXT Record modification"], "txtrecordlimit" => ["FriendlyName" => "TXT records Limit", "Type" => "text", "Size" => "3", "Description" => "The number of records allow for TXT (0 for unlimited)", "Default" => "100"], "modifynsrecord" => ["FriendlyName" => "Allow NS record Modification", "Type" => "yesno", "Size" => "25", "Description" => "Enable NS Record modification"], "nsrecordlimit" => ["FriendlyName" => "NS records Limit", "Type" => "text", "Size" => "3", "Description" => "The number of records allow for NS (0 for unlimited)", "Default" => "100"], "modifymxrecord" => ["FriendlyName" => "Allow MX record Modification", "Type" => "yesno", "Size" => "25", "Description" => "Enable MX Record modification", "Default" => "yes"], "mxrecordlimit" => ["FriendlyName" => "MX records Limit", "Type" => "text", "Size" => "3", "Description" => "The number of records allow for MX (0 for unlimited)", "Default" => "100"], "modifysrvrecord" => ["FriendlyName" => "Allow SRV record Modification", "Type" => "yesno", "Size" => "25", "Description" => "Enable SRV Record modification"], "srvrecordlimit" => ["FriendlyName" => "SRV records Limit", "Type" => "text", "Size" => "3", "Description" => "The number of records allow for SRV (0 for unlimited)", "Default" => "100"]]];
}
function dnssuite_activate()
{
    $pdo = WHMCS\Database\Capsule::connection()->getPdo();
    $query = $pdo->prepare("CREATE TABLE `mod_dnssuite_zones` (`id` INT NOT NULL AUTO_INCREMENT PRIMARY KEY, `relid` INT NOT NULL, `domain` VARCHAR (1000) NOT NULL ,`records` TEXT ( 65535  ) NULL, `lastupdate` INT (10) NOT NULL)");
    $query->execute();
    if(!$pdo->inTransaction()) {
        $pdo->beginTransaction();
    }
    $pdo->commit();
    $query = $pdo->prepare("CREATE TABLE `mod_dnssuite_redirects` (`id` INT NOT NULL AUTO_INCREMENT PRIMARY KEY, `relid` INT NOT NULL, `type` INT NOT NULL, `domain` VARCHAR (1000) NOT NULL ,`redirect` VARCHAR ( 1000 ) NOT NULL, `maskeddata` VARCHAR ( 1000 ) NULL, `lastupdate` INT (10) NOT NULL)");
    $query->execute();
    if(!$pdo->inTransaction()) {
        $pdo->beginTransaction();
    }
    $pdo->commit();
    $query = $pdo->prepare("CREATE TABLE `mod_dnssuite_emailforwarders` (`id` INT NOT NULL AUTO_INCREMENT PRIMARY KEY, `relid` INT NOT NULL, `email` VARCHAR ( 1000 ) NOT NULL, `mailto` VARCHAR(1000) NOT NULL, `lastupdate` INT (10) NOT NULL)");
    $query->execute();
    if(!$pdo->inTransaction()) {
        $pdo->beginTransaction();
    }
    $pdo->commit();
    $query = $pdo->prepare("CREATE TABLE `mod_dnssuite_emailaddresses` (`id` INT NOT NULL AUTO_INCREMENT PRIMARY KEY, `relid` INT NOT NULL, `email` VARCHAR ( 1000 ) NOT NULL, `pin` VARCHAR(1000) NOT NULL, `status` INT (1) NOT NULL, `lastupdate` INT (10) NOT NULL)");
    $query->execute();
    if(!$pdo->inTransaction()) {
        $pdo->beginTransaction();
    }
    $pdo->commit();
    $query = $pdo->prepare("CREATE TABLE `mod_dnssuite_emailcatchalls` (`id` INT NOT NULL AUTO_INCREMENT PRIMARY KEY, `relid` INT NOT NULL, `domain` VARCHAR (1000) NOT NULL ,`mailto` VARCHAR ( 1000 ) NOT NULL, `status` INT (1) NOT NULL, `lastupdate` INT (10) NOT NULL)");
    $query->execute();
    if(!$pdo->inTransaction()) {
        $pdo->beginTransaction();
    }
    $pdo->commit();
    $query = $pdo->prepare("CREATE TABLE `mod_dnssuite_api` (`id` INT NOT NULL AUTO_INCREMENT PRIMARY KEY, `relid` INT NOT NULL , `keyphrase` VARCHAR(20) NOT NULL, `pass` VARCHAR(20) NOT NULL,`status` INT NOT NULL)");
    $query->execute();
    if(!$pdo->inTransaction()) {
        $pdo->beginTransaction();
    }
    $pdo->commit();
    $query = $pdo->prepare("CREATE TABLE `mod_dnssuite_api_log` (`id` INT NOT NULL AUTO_INCREMENT PRIMARY KEY, `relid` INT NOT NULL , `timelog` VARCHAR(15) NOT NULL)");
    $query->execute();
    if(!$pdo->inTransaction()) {
        $pdo->beginTransaction();
    }
    $pdo->commit();
    $query = $pdo->prepare("CREATE TABLE `mod_dnssuite_api_bruteforce` (`id` INT NOT NULL AUTO_INCREMENT PRIMARY KEY, `ip` VARCHAR (100) NOT NULL, `timelog` VARCHAR(15) NOT NULL)");
    $query->execute();
    if(!$pdo->inTransaction()) {
        $pdo->beginTransaction();
    }
    $pdo->commit();
    $query = $pdo->prepare("CREATE TABLE `mod_dnssuite_bruteforce_ban` (`id` int(11) NOT NULL AUTO_INCREMENT PRIMARY KEY, `ip` varchar(100) NOT NULL, `expiretime` varchar(15) NOT NULL)");
    $query->execute();
    if(!$pdo->inTransaction()) {
        $pdo->beginTransaction();
    }
    $pdo->commit();
    $query = $pdo->prepare("CREATE TABLE `mod_dnssuite_dnstemplates` (`id` int(11) NOT NULL AUTO_INCREMENT PRIMARY KEY, `name` varchar(100) NOT NULL, `records` text(65535) NULL,`status` tinyint(1) NOT NULL)");
    $query->execute();
    if(!$pdo->inTransaction()) {
        $pdo->beginTransaction();
    }
    $pdo->commit();
    $query = $pdo->prepare("CREATE TABLE `mod_dnssuite_userdnstemplates` (`id` int(11) NOT NULL AUTO_INCREMENT PRIMARY KEY,`userid` int(11) NOT NULL, `name` varchar(100) NOT NULL, `records` text(65535) NULL,`status` tinyint(1) NOT NULL)");
    $query->execute();
    if(!$pdo->inTransaction()) {
        $pdo->beginTransaction();
    }
    $pdo->commit();
    $query = $pdo->prepare("CREATE TABLE `mod_dnssuite_notification` ( `id` int(11) NOT NULL AUTO_INCREMENT PRIMARY KEY, `relid` int(11) NOT NULL, `dns` tinyint(1) NOT NULL, `emailforward` tinyint(1) NOT NULL, `emailcatchall` tinyint(1) NOT NULL, `webredirect` tinyint(1) NOT NULL, `ddns` tinyint(1) NOT NULL)");
    $query->execute();
    if(!$pdo->inTransaction()) {
        $pdo->beginTransaction();
    }
    $pdo->commit();
    $query = $pdo->prepare("INSERT INTO tblemailtemplates (type, name, subject, disabled, custom, message) VALUE ('general','DNSSuite Email Verification','Please Verify Your Email', '0', '1', '<p>Hello,</p>\r\n    <p>&nbsp;</p>\r\n    <p>Your verification pin is \\{\$pin\\} for your Catch-all/Forwarding Email</p>\r\n    <p>\\{\$domain\\}</p>\r\n    <p>\\{\$signature\\}</p>')");
    $query->execute();
    if(!$pdo->inTransaction()) {
        $pdo->beginTransaction();
    }
    $pdo->commit();
    $query = $pdo->prepare("INSERT INTO tbladdonmodules (module, setting, value) VALUE (:module, :setting, :value)");
    $query->execute([":module" => "dnssuite", ":setting" => "templateemailverify", ":value" => "DNSSuite Email Verification"]);
    if(!$pdo->inTransaction()) {
        $pdo->beginTransaction();
    }
    $pdo->commit();
    $query = $pdo->prepare("INSERT INTO tblemailtemplates (type, name, subject, disabled, custom, message) VALUE ('general','DNSSuite Notification Email','Domain Settings Modification Notice - \\{\$domain\\}', '0', '1', '<p>Hello,</p>\r\n    <p>&nbsp;</p>\r\n    <p>This is notification for a modification that has been made to your domain. If you did not make this change, please contact support immediately.</p>\r\n    <p>Type: \\{\$type\\}</p>\r\n    <p>Old Value: \\{\$old\\}</p>\r\n    <p>New Value: \\{\$new\\}</p>\r\n    <p>\\{\$signature\\}</p>')");
    $query->execute();
    $verifyid = $pdo->lastInsertId();
    if(!$pdo->inTransaction()) {
        $pdo->beginTransaction();
    }
    $pdo->commit();
    $query = $pdo->prepare("INSERT INTO tbladdonmodules (module, setting, value) VALUE (:module, :setting, :value)");
    $query->execute([":module" => "dnssuite", ":setting" => "templatenotificationemail", ":value" => "DNSSuite Notification Email"]);
    if(!$pdo->inTransaction()) {
        $pdo->beginTransaction();
    }
    $pdo->commit();
    $query = $pdo->prepare("CREATE TABLE `mod_dnssuite_subdomains` (`id` int(11) NOT NULL AUTO_INCREMENT PRIMARY KEY, `relid` int(11) NOT NULL, `host` varchar(1000) NOT NULL)");
    $query->execute();
    if(!$pdo->inTransaction()) {
        $pdo->beginTransaction();
    }
    $pdo->commit();
    $query = $pdo->prepare("CREATE TABLE `mod_dnssuite_sd_redirects` (`id` INT NOT NULL AUTO_INCREMENT PRIMARY KEY, `relid` INT NOT NULL, `type` INT NOT NULL, `domain` VARCHAR (1000) NOT NULL ,`redirect` VARCHAR ( 1000 ) NOT NULL, `maskeddata` VARCHAR ( 1000 ) NULL, `lastupdate` INT (10) NOT NULL)");
    $query->execute();
    if(!$pdo->inTransaction()) {
        $pdo->beginTransaction();
    }
    $pdo->commit();
    $query = $pdo->prepare("CREATE TABLE `mod_dnssuite_sd_emailforwarders` (`id` INT NOT NULL AUTO_INCREMENT PRIMARY KEY, `relid` INT NOT NULL, `email` VARCHAR ( 1000 ) NOT NULL, `mailto` VARCHAR(1000) NOT NULL, `lastupdate` INT (10) NOT NULL)");
    $query->execute();
    if(!$pdo->inTransaction()) {
        $pdo->beginTransaction();
    }
    $pdo->commit();
    $query = $pdo->prepare("CREATE TABLE `mod_dnssuite_sd_emailcatchalls` (`id` INT NOT NULL AUTO_INCREMENT PRIMARY KEY, `relid` INT NOT NULL, `domain` VARCHAR (1000) NOT NULL ,`mailto` VARCHAR ( 1000 ) NOT NULL, `status` INT (1) NOT NULL, `lastupdate` INT (10) NOT NULL)");
    $query->execute();
    if(!$pdo->inTransaction()) {
        $pdo->beginTransaction();
    }
    $pdo->commit();
    return ["status" => "success", "description" => "Activation success! Please check instructions on http://whmcsdnsmodule.com/docs"];
}
function dnssuite_deactivate()
{
    WHMCS\Database\Capsule::schema()->dropIfExists("mod_dnssuite_zones");
    WHMCS\Database\Capsule::schema()->dropIfExists("mod_dnssuite_redirects");
    WHMCS\Database\Capsule::schema()->dropIfExists("mod_dnssuite_emailforwarders");
    WHMCS\Database\Capsule::schema()->dropIfExists("mod_dnssuite_emailaddresses");
    WHMCS\Database\Capsule::schema()->dropIfExists("mod_dnssuite_emailcatchalls");
    WHMCS\Database\Capsule::schema()->dropIfExists("mod_dnssuite_api");
    WHMCS\Database\Capsule::schema()->dropIfExists("mod_dnssuite_api_log");
    WHMCS\Database\Capsule::schema()->dropIfExists("mod_dnssuite_api_bruteforce");
    WHMCS\Database\Capsule::schema()->dropIfExists("mod_dnssuite_bruteforce_ban");
    WHMCS\Database\Capsule::schema()->dropIfExists("mod_dnssuite_dnstemplates");
    WHMCS\Database\Capsule::schema()->dropIfExists("mod_dnssuite_userdnstemplates");
    WHMCS\Database\Capsule::schema()->dropIfExists("mod_dnssuite_notification");
    WHMCS\Database\Capsule::schema()->dropIfExists("mod_dnssuite_subdomains");
    WHMCS\Database\Capsule::schema()->dropIfExists("mod_dnssuite_sd_redirects");
    WHMCS\Database\Capsule::schema()->dropIfExists("mod_dnssuite_sd_emailforwarders");
    WHMCS\Database\Capsule::schema()->dropIfExists("mod_dnssuite_sd_emailcatchalls");
    return ["status" => "success", "description" => "This is a demo module only. In a real module you might report an error/failure here."];
}
function dnssuite_upgrade($vars)
{
    $pdo = WHMCS\Database\Capsule::connection()->getPdo();
    $currentlyInstalledVersion = $vars["version"];
    if($currentlyInstalledVersion < 0) {
        $query = $pdo->prepare("CREATE TABLE `mod_dnssuite_subdomains` (`id` int(11) NOT NULL AUTO_INCREMENT PRIMARY KEY, `relid` int(11) NOT NULL, `host` varchar(1000) NOT NULL)");
        $query->execute();
        if(!$pdo->inTransaction()) {
            $pdo->beginTransaction();
        }
        $pdo->commit();
        $query = $pdo->prepare("CREATE TABLE `mod_dnssuite_sd_redirects` (`id` INT NOT NULL AUTO_INCREMENT PRIMARY KEY, `relid` INT NOT NULL, `type` INT NOT NULL, `domain` VARCHAR (1000) NOT NULL ,`redirect` VARCHAR ( 1000 ) NOT NULL, `maskeddata` VARCHAR ( 1000 ) NULL, `lastupdate` INT (10) NOT NULL)");
        $query->execute();
        if(!$pdo->inTransaction()) {
            $pdo->beginTransaction();
        }
        $pdo->commit();
        $query = $pdo->prepare("CREATE TABLE `mod_dnssuite_sd_emailforwarders` (`id` INT NOT NULL AUTO_INCREMENT PRIMARY KEY, `relid` INT NOT NULL, `email` VARCHAR ( 1000 ) NOT NULL, `mailto` VARCHAR(1000) NOT NULL, `lastupdate` INT (10) NOT NULL)");
        $query->execute();
        if(!$pdo->inTransaction()) {
            $pdo->beginTransaction();
        }
        $pdo->commit();
        $query = $pdo->prepare("CREATE TABLE `mod_dnssuite_sd_emailcatchalls` (`id` INT NOT NULL AUTO_INCREMENT PRIMARY KEY, `relid` INT NOT NULL, `domain` VARCHAR (1000) NOT NULL ,`mailto` VARCHAR ( 1000 ) NOT NULL, `status` INT (1) NOT NULL, `lastupdate` INT (10) NOT NULL)");
        $query->execute();
        if(!$pdo->inTransaction()) {
            $pdo->beginTransaction();
        }
        $pdo->commit();
        $query = $pdo->prepare("ALTER TABLE `mod_dnssuite_redirects` ADD `maskeddata` VARCHAR ( 1000 ) NULL AFTER `redirect`;");
        $query->execute();
        if(!$pdo->inTransaction()) {
            $pdo->beginTransaction();
        }
        $pdo->commit();
    }
}
function dnssuite_output($vars)
{
    require ROOTDIR . "/modules/addons/dnssuite/lib/Admin/AdminDispatcher.php";
    require ROOTDIR . "/modules/addons/dnssuite/lib/Admin/Controller.php";
    $modulelink = $vars["modulelink"];
    $version = $vars["version"];
    $_lang = $vars["_lang"];
    $configTextField = $vars["Text Field Name"];
    $configPasswordField = $vars["Password Field Name"];
    $configCheckboxField = $vars["Checkbox Field Name"];
    $configDropdownField = $vars["Dropdown Field Name"];
    $configRadioField = $vars["Radio Field Name"];
    $configTextareaField = $vars["Textarea Field Name"];
    $action = isset($_REQUEST["action"]) ? $_REQUEST["action"] : "";
    $dispatcher = new WHMCS\Module\Addon\AddonModule\Admin\AdminDispatcher();
    $response = $dispatcher->dispatch($action, $vars);
    echo $response;
}
function dnssuite_sidebar($vars)
{
    $modulelink = $vars["modulelink"];
    $version = $vars["version"];
    $_lang = $vars["_lang"];
    $configTextField = $vars["Text Field Name"];
    $configPasswordField = $vars["Password Field Name"];
    $configCheckboxField = $vars["Checkbox Field Name"];
    $configDropdownField = $vars["Dropdown Field Name"];
    $configRadioField = $vars["Radio Field Name"];
    $configTextareaField = $vars["Textarea Field Name"];
    $sidebar = "<p>Sidebar output HTML goes here</p>";
}
function dnssuite_clientarea($vars)
{
    require ROOTDIR . "/modules/addons/dnssuite/lib/Client/ClientDispatcher.php";
    require ROOTDIR . "/modules/addons/dnssuite/lib/Client/Controller.php";
    $modulelink = $vars["modulelink"];
    $version = $vars["version"];
    $_lang = $vars["_lang"];
    $configTextField = $vars["Text Field Name"];
    $configPasswordField = $vars["Password Field Name"];
    $configCheckboxField = $vars["Checkbox Field Name"];
    $configDropdownField = $vars["Dropdown Field Name"];
    $configRadioField = $vars["Radio Field Name"];
    $configTextareaField = $vars["Textarea Field Name"];
    $action = isset($_REQUEST["action"]) ? $_REQUEST["action"] : "";
    $dispatcher = new WHMCS\Module\Addon\AddonModule\Client\ClientDispatcher();
    return $dispatcher->dispatch($action, $vars);
}

?>