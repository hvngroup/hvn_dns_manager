<?php
/*
 * @ https://EasyToYou.eu - IonCube v11 Decoder Online
 * @ PHP 7.4
 * @ Decoder version: 1.0.2
 * @ Release: 10/08/2022
 */

// Decoded file for php version 74.
require "../../../../init.php";
$pdo = Illuminate\Database\Capsule\Manager::connection()->getPdo();
$pdo->beginTransaction();
require ROOTDIR . "/modules/addons/dnssuite/class/class.dnssuite.php";
if($_SESSION["uid"]) {
    if(!preg_match("/\\d+/", $_POST["domainid"])) {
        echo json_encode(["status" => 9]);
        exit;
    }
    $did = $_POST["domainid"];
    $userLang = $_SESSION["Language"];
    if(!isset($userLang)) {
        $query = $pdo->prepare("SELECT value FROM tblconfiguration WHERE setting = 'Language' ");
        $query->execute();
        $query = $query->fetch(PDO::FETCH_ASSOC);
        $query = $query["value"];
        include ROOTDIR . "/modules/addons/dnssuite/lang/" . $query . ".php";
    } else {
        include ROOTDIR . "/modules/addons/dnssuite/lang/" . $userLang . ".php";
    }
    $LANG = $_ADDONLANG;
    $query = $pdo->prepare("SELECT count(*) FROM tbldomains WHERE id = :did AND userid = :uid AND status = :status ");
    $query->execute([":did" => $did, ":uid" => $_SESSION["uid"], ":status" => "Active"]);
    $query = $query->fetch(PDO::FETCH_ASSOC);
    if($query["count(*)"] == 1) {
        $obj = new DNSSUITE\Suite_ClientArea($pdo, $did);
        $domain = $obj->basic->getDomainfromDID($did);
        $initreturn = $obj->initOverview($_POST["domainid"], 0);
        if($_POST["action"] == "updatenotification") {
            if($obj->updateNotification($did, $_POST)) {
                echo json_encode(["status" => 1]);
            } else {
                echo json_encode(["status" => 0]);
            }
        }
        if($_POST["action"] == "refreshapi") {
            if(1 < $obj->basic->edition) {
                if($obj->refreshAPI($did)) {
                    $obj->basic->getAPI($did);
                    echo json_encode(["status" => 1, "keyphrase" => $obj->basic->configs["keyphrase"], "pass" => $obj->basic->configs["pass"]]);
                } else {
                    echo json_encode(["status" => 0]);
                }
            } else {
                echo json_encode(["status" => 9]);
            }
        }
        if($_POST["action"] == "enableapi" && 1 < $obj->basic->edition) {
            if($obj->setAPIStatus($did, 1)) {
                echo json_encode(["status" => 1]);
            } else {
                echo json_encode(["status" => 0]);
            }
        }
        if($_POST["action"] == "disableapi" && 1 < $obj->basic->edition) {
            if($obj->setAPIStatus($did, 0)) {
                echo json_encode(["status" => 1]);
            } else {
                echo json_encode(["status" => 0]);
            }
        }
        if($_POST["action"] == "requestSSL") {
            if($obj->basic->configs["clientletsencrypt"] == 1) {
                if($obj->requestSSL($did)) {
                    echo json_encode(["status" => 1]);
                } else {
                    echo json_encode(["status" => 0]);
                }
            } else {
                echo json_encode(["status" => 0]);
            }
        }
        if($_POST["action"] == "requestSSL-sub") {
            if($obj->basic->configs["clientletsencrypt"] == 1) {
                if($obj->requestSubDomainSSL(["did" => $did, "sdid" => $sdid])) {
                    echo json_encode(["status" => 1]);
                } else {
                    echo json_encode(["status" => 0]);
                }
            } else {
                echo json_encode(["status" => 0]);
            }
        }
        if($_POST["action"] == "deleteRecord" && $obj->basic->configs["enablednseditor"] == "on") {
            if(!preg_match("/\\d+/", $_POST["row"])) {
                echo json_encode(["status" => 8]);
                exit;
            }
            if(!in_array($_POST["mode"], ["A", "AAAA", "CNAME", "TXT", "NS", "MX", "SRV"], true)) {
                echo json_encode(["status" => 7]);
                exit;
            }
            if($obj->deleteRecord($_POST["domainid"], ["mode" => $_POST["mode"], "row" => $_POST["row"]])) {
                $deleterecord = true;
                $noticemsg = $LANG["dnssuitePage_manage_record_delete_success"];
                if($obj->basic->configs["enablenotification"] == "on" && $initreturn["notificationconfigs"]["dns"] == 1) {
                    if($_POST["mode"] == "A" || $_POST["mode"] == "AAAA" || $_POST["mode"] == "CNAME" || $_POST["mode"] == "TXT" || $_POST["mode"] == "NS") {
                        $emailtype = $LANG["dnssuitePage_email_type_dns"] . " " . $obj->oldvalues["type"] . " " . " - (" . $LANG["dnssuitePage_email_delete"] . ")";
                        $emailoldval = "(" . $obj->oldvalues["type"] . ") - " . $obj->oldvalues["host"] . " " . $obj->oldvalues["value"];
                    }
                    if($_POST["mode"] == "MX") {
                        $emailtype = $LANG["dnssuitePage_email_type_dns"] . " " . $obj->oldvalues["type"] . " " . " - (" . $LANG["dnssuitePage_email_delete"] . ")";
                        $emailoldval = $obj->oldvalues["host"] . " " . $obj->oldvalues["priority"] . " " . $obj->oldvalues["value"];
                    }
                    if($_POST["mode"] == "SRV") {
                        $emailtype = $LANG["dnssuitePage_email_type_dns"] . " " . $obj->oldvalues["type"] . " " . " - (" . $LANG["dnssuitePage_email_delete"] . ")";
                        $emailoldval = $obj->oldvalues["host"] . " " . $obj->oldvalues["priority"] . " " . $obj->oldvalues["weight"] . " " . $obj->oldvalues["port"] . " " . $obj->oldvalues["value"];
                    }
                    $obj->basic->sendNotificationEmail(["did" => $_POST["domainid"], "type" => $emailtype, "old" => $emailoldval, "new" => $LANG["dnssuitePage_email_na"]]);
                }
                if($mode == "A") {
                    $obj->basic->configs["fetchonload"] = "on";
                    if($zonedata = $obj->loadDomain($_POST["domainid"], false)) {
                        if(!empty($zonedata["a"])) {
                            for ($i = 0; $i < count($zonedata["a"]); $i++) {
                                $zonedata["a"][$i] = explode(" ", $zonedata["a"][$i]);
                                $zonedata["a"][$i][] = $i;
                            }
                            $recordcount["a"] = count($zonedata["a"]);
                        } else {
                            $recordcount["a"] = 0;
                        }
                    }
                    $returndata = $zonedata["a"];
                    $returncount = $recordcount["a"];
                } elseif($mode == "AAAA") {
                    $obj->basic->configs["fetchonload"] = "on";
                    if($zonedata = $obj->loadDomain($_POST["domainid"], false)) {
                        if(!empty($zonedata["aaaa"])) {
                            for ($i = 0; $i < count($zonedata["aaaa"]); $i++) {
                                $zonedata["aaaa"][$i] = explode(" ", $zonedata["aaaa"][$i]);
                                $zonedata["aaaa"][$i][] = $i;
                            }
                            $recordcount["aaaa"] = count($zonedata["aaaa"]);
                        } else {
                            $recordcount["aaaa"] = 0;
                        }
                    }
                    $returndata = $zonedata["aaaa"];
                    $returncount = $recordcount["aaaa"];
                } elseif($mode == "CNAME") {
                    $obj->basic->configs["fetchonload"] = "on";
                    if($zonedata = $obj->loadDomain($_POST["domainid"], false)) {
                        if(!empty($zonedata["cname"])) {
                            for ($i = 0; $i < count($zonedata["cname"]); $i++) {
                                $zonedata["cname"][$i] = explode(" ", $zonedata["cname"][$i]);
                                $zonedata["cname"][$i][] = $i;
                            }
                            $recordcount["cname"] = count($zonedata["cname"]);
                        } else {
                            $recordcount["cname"] = 0;
                        }
                    }
                    $returndata = $zonedata["cname"];
                    $returncount = $recordcount["cname"];
                } elseif($mode == "NS") {
                    $obj->basic->configs["fetchonload"] = "on";
                    if($zonedata = $obj->loadDomain($_POST["domainid"], false)) {
                        if(!empty($zonedata["ns"])) {
                            for ($i = 0; $i < count($zonedata["ns"]); $i++) {
                                $zonedata["ns"][$i] = explode(" ", $zonedata["ns"][$i]);
                                $zonedata["ns"][$i][] = $i;
                            }
                            $recordcount["ns"] = count($zonedata["ns"]);
                        } else {
                            $recordcount["ns"] = 0;
                        }
                    }
                    $returndata = $zonedata["ns"];
                    $returncount = $recordcount["ns"];
                } elseif($mode == "TXT") {
                    $obj->basic->configs["fetchonload"] = "on";
                    if($zonedata = $obj->loadDomain($_POST["domainid"], false)) {
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
                            $recordcount["Txt"] = 0;
                        }
                    }
                    $returndata = $zonedata["txt"];
                    $returncount = $recordcount["txt"];
                } elseif($mode == "MX") {
                    $obj->basic->configs["fetchonload"] = "on";
                    if($zonedata = $obj->loadDomain($_POST["domainid"], false)) {
                        if(!empty($zonedata["mx"])) {
                            for ($i = 0; $i < count($zonedata["mx"]); $i++) {
                                $zonedata["mx"][$i] = explode(" ", $zonedata["mx"][$i]);
                                $zonedata["mx"][$i][] = $i;
                            }
                            $recordcount["mx"] = count($zonedata["mx"]);
                        } else {
                            $recordcount["mx"] = 0;
                        }
                    }
                    $returndata = $zonedata["mx"];
                    $returncount = $recordcount["mx"];
                } elseif($mode == "SRV") {
                    $obj->basic->configs["fetchonload"] = "on";
                    if($zonedata = $obj->loadDomain($_POST["domainid"], false)) {
                        if(!empty($zonedata["srv"])) {
                            for ($i = 0; $i < count($zonedata["srv"]); $i++) {
                                $zonedata["srv"][$i] = explode(" ", $zonedata["srv"][$i]);
                                $zonedata["srv"][$i][] = $i;
                            }
                            $recordcount["srv"] = count($zonedata["srv"]);
                        } else {
                            $recordcount["srv"] = 0;
                        }
                    }
                    $returndata = $zonedata["srv"];
                    $returncount = $recordcount["srv"];
                }
                echo json_encode(["status" => 1, "data" => $returndata, "count" => $returncount]);
            } else {
                echo json_encode(["status" => 0]);
            }
            exit;
        }
        if($_POST["action"] == "addA" && $obj->basic->configs["enablednseditor"] == "on" && $obj->basic->records_a["modify"] == "on") {
            $_POST["host"] = strtolower($_POST["host"]);
            if($obj->basic->validateHostname($_POST["host"]) && filter_var($_POST["value"], FILTER_VALIDATE_IP, FILTER_FLAG_IPV4) || $obj->basic->verifyHostasDomain($_POST["domainid"], $_POST["host"]) && filter_var($_POST["value"], FILTER_VALIDATE_IP, FILTER_FLAG_IPV4)) {
                if($obj->addRecord($_POST["domainid"], ["host" => $_POST["host"], "value" => $_POST["value"], "mode" => "A"])) {
                    $addrecord = true;
                    $noticemsg = $LANG["dnssuitePage_manage_dns_addrecord_success"];
                    if($obj->basic->configs["enablenotification"] == "on" && $initreturn["notificationconfigs"]["dns"] == 1) {
                        $emailtype = $LANG["dnssuitePage_email_type_dns"] . " A " . " - (" . $LANG["dnssuitePage_email_add"] . ")";
                        $emailnewval = $_POST["host"] . " " . $_POST["value"];
                        $obj->basic->sendNotificationEmail(["did" => $_POST["domainid"], "type" => $emailtype, "old" => $LANG["dnssuitePage_email_na"], "new" => $emailnewval]);
                    }
                    $obj->basic->configs["fetchonload"] = "on";
                    if($zonedata = $obj->loadDomain($_POST["domainid"], false)) {
                        for ($i = 0; $i < count($zonedata["a"]); $i++) {
                            $zonedata["a"][$i] = explode(" ", $zonedata["a"][$i]);
                            $zonedata["a"][$i][] = $i;
                        }
                        $recordcount = count($zonedata["a"]);
                    }
                    echo json_encode(["status" => 1, "data" => $zonedata["a"], "count" => $recordcount]);
                } else {
                    echo json_encode(["status" => 0]);
                }
            } else {
                echo json_encode(["status" => 2]);
            }
            exit;
        }
        if($_POST["action"] == "modifyA" && $obj->basic->configs["enablednseditor"] == "on" && $obj->basic->records_a["modify"] == "on") {
            if(!preg_match("/\\d+/", $_POST["row"])) {
                echo json_encode(["status" => 8]);
                exit;
            }
            if(filter_var($_POST["value"], FILTER_VALIDATE_IP, FILTER_FLAG_IPV4)) {
                if($obj->updateDNSRecord($_POST["domainid"], ["mode" => "A", "value" => $_POST["value"], "row" => $_POST["row"]])) {
                    $updaterecord = true;
                    $noticemsg = $LANG["dnssuitePage_manage_dns_updaterecord_success"];
                    if($obj->basic->configs["enablenotification"] == "on" && $initreturn["notificationconfigs"]["dns"] == 1) {
                        $emailtype = $LANG["dnssuitePage_email_type_dns"] . " " . $obj->oldvalues["type"] . " - (" . $LANG["dnssuitePage_email_update"] . ")";
                        $emailoldval = $obj->oldvalues["host"] . " " . $obj->oldvalues["value"];
                        $emailnewval = $_POST["value"];
                        $obj->basic->sendNotificationEmail(["did" => $_POST["domainid"], "type" => $emailtype, "old" => $emailoldval, "new" => $emailnewval]);
                    }
                    $obj->basic->configs["fetchonload"] = "on";
                    if($zonedata = $obj->loadDomain($_POST["domainid"], false)) {
                        for ($i = 0; $i < count($zonedata["a"]); $i++) {
                            $zonedata["a"][$i] = explode(" ", $zonedata["a"][$i]);
                            $zonedata["a"][$i][] = $i;
                        }
                        $recordcount = count($zonedata["a"]);
                    }
                    echo json_encode(["status" => 1, "data" => $zonedata["a"], "count" => $recordcount]);
                } else {
                    echo json_encode(["status" => 0]);
                }
            } else {
                echo json_encode(["status" => 3]);
            }
            exit;
        }
        if($_POST["action"] == "addAAAA" && $obj->basic->configs["enablednseditor"] == "on" && $obj->basic->records_aaaa["modify"] == "on") {
            $_POST["host"] = strtolower($_POST["host"]);
            if($obj->basic->validateHostname($_POST["host"]) && filter_var($_POST["value"], FILTER_VALIDATE_IP, FILTER_FLAG_IPV6) || $obj->basic->verifyHostasDomain($_POST["domainid"], $_POST["host"]) && filter_var($_POST["value"], FILTER_VALIDATE_IP, FILTER_FLAG_IPV6)) {
                if($obj->addRecord($_POST["domainid"], ["host" => $_POST["host"], "value" => $_POST["value"], "mode" => "AAAA"])) {
                    $addrecord = true;
                    $noticemsg = $LANG["dnssuitePage_manage_dns_addrecord_success"];
                    if($obj->basic->configs["enablenotification"] == "on" && $initreturn["notificationconfigs"]["dns"] == 1) {
                        $emailtype = $LANG["dnssuitePage_email_type_dns"] . " AAAA " . " - (" . $LANG["dnssuitePage_email_add"] . ")";
                        $emailnewval = $_POST["host"] . " " . $_POST["value"];
                        $obj->basic->sendNotificationEmail(["did" => $_POST["domainid"], "type" => $emailtype, "old" => $LANG["dnssuitePage_email_na"], "new" => $emailnewval]);
                    }
                    $obj->basic->configs["fetchonload"] = "on";
                    if($zonedata = $obj->loadDomain($_POST["domainid"], false)) {
                        if(!empty($zonedata["aaaa"])) {
                            for ($i = 0; $i < count($zonedata["aaaa"]); $i++) {
                                $zonedata["aaaa"][$i] = explode(" ", $zonedata["aaaa"][$i]);
                                $zonedata["aaaa"][$i][] = $i;
                            }
                            $recordcount = count($zonedata["aaaa"]);
                        } else {
                            $recordcount = 0;
                        }
                    }
                    echo json_encode(["status" => 1, "data" => $zonedata["aaaa"], "count" => $recordcount]);
                } else {
                    echo json_encode(["status" => 0]);
                }
            } else {
                echo json_encode(["status" => 2]);
            }
            exit;
        }
        if($_POST["action"] == "modifyAAAA" && $obj->basic->configs["enablednseditor"] == "on" && $obj->basic->records_aaaa["modify"] == "on") {
            if(!preg_match("/\\d+/", $_POST["row"])) {
                echo json_encode(["status" => 8]);
                exit;
            }
            if(filter_var($_POST["value"], FILTER_VALIDATE_IP, FILTER_FLAG_IPV6)) {
                if($obj->updateDNSRecord($_POST["domainid"], ["mode" => "AAAA", "value" => $_POST["value"], "row" => $_POST["row"]])) {
                    $updaterecord = true;
                    $noticemsg = $LANG["dnssuitePage_manage_dns_updaterecord_success"];
                    if($obj->basic->configs["enablenotification"] == "on" && $initreturn["notificationconfigs"]["dns"] == 1) {
                        $emailtype = $LANG["dnssuitePage_email_type_dns"] . " " . $obj->oldvalues["type"] . " - (" . $LANG["dnssuitePage_email_update"] . ")";
                        $emailoldval = $obj->oldvalues["host"] . " " . $obj->oldvalues["value"];
                        $emailnewval = $_POST["value"];
                        $obj->basic->sendNotificationEmail(["did" => $_POST["domainid"], "type" => $emailtype, "old" => $emailoldval, "new" => $emailnewval]);
                    }
                    $obj->basic->configs["fetchonload"] = "on";
                    if($zonedata = $obj->loadDomain($_POST["domainid"], false)) {
                        if(!empty($zonedata["aaaa"])) {
                            for ($i = 0; $i < count($zonedata["aaaa"]); $i++) {
                                $zonedata["aaaa"][$i] = explode(" ", $zonedata["aaaa"][$i]);
                                $zonedata["aaaa"][$i][] = $i;
                            }
                            $recordcount = count($zonedata["aaaa"]);
                        } else {
                            $recordcount = 0;
                        }
                    }
                    echo json_encode(["status" => 1, "data" => $zonedata["aaaa"], "count" => $recordcount]);
                } else {
                    echo json_encode(["status" => 0]);
                }
            } else {
                echo json_encode(["status" => 0]);
            }
            exit;
        }
        if($_POST["action"] == "addCNAME" && $obj->basic->configs["enablednseditor"] == "on" && $obj->basic->records_cname["modify"] == "on") {
            $_POST["host"] = strtolower($_POST["host"]);
            if($obj->basic->validateCNAMEHostname($_POST["host"])) {
                if($obj->basic->validateHostname($_POST["value"]) || $obj->basic->validateHostnameDot($_POST["value"])) {
                    if($obj->addRecord($_POST["domainid"], ["mode" => "CNAME", "host" => $_POST["host"], "value" => $_POST["value"]])) {
                        $addrecord = true;
                        $noticemsg = $LANG["dnssuitePage_manage_dns_addrecord_success"];
                        if($obj->basic->configs["enablenotification"] == "on" && $initreturn["notificationconfigs"]["dns"] == 1) {
                            $emailtype = $LANG["dnssuitePage_email_type_dns"] . " CNAME " . " - (" . $LANG["dnssuitePage_email_add"] . ")";
                            $emailnewval = $_POST["host"] . " " . $_POST["value"];
                            $obj->basic->sendNotificationEmail(["did" => $_POST["domainid"], "type" => $emailtype, "old" => $LANG["dnssuitePage_email_na"], "new" => $emailnewval]);
                        }
                        $obj->basic->configs["fetchonload"] = "on";
                        if($zonedata = $obj->loadDomain($_POST["domainid"], false)) {
                            if(!empty($zonedata["cname"])) {
                                for ($i = 0; $i < count($zonedata["cname"]); $i++) {
                                    $zonedata["cname"][$i] = explode(" ", $zonedata["cname"][$i]);
                                    $zonedata["cname"][$i][] = $i;
                                }
                                $recordcount = count($zonedata["cname"]);
                            } else {
                                $recordcount = 0;
                            }
                        }
                        echo json_encode(["status" => 1, "data" => $zonedata["cname"], "count" => $recordcount]);
                    } else {
                        echo json_encode(["status" => 0]);
                    }
                } else {
                    echo json_encode(["status" => 3]);
                }
            } else {
                echo json_encode(["status" => 2]);
            }
            exit;
        }
        if($_POST["action"] == "modifyCNAME" && $obj->basic->configs["enablednseditor"] == "on" && $obj->basic->records_cname["modify"] == "on") {
            if(!preg_match("/\\d+/", $_POST["row"])) {
                echo json_encode(["status" => 8]);
                exit;
            }
            if($obj->basic->validateHostname($_POST["value"]) || $obj->basic->validateHostnameDot($_POST["value"])) {
                if($obj->updateDNSRecord($_POST["domainid"], ["mode" => "CNAME", "value" => $_POST["value"], "row" => $_POST["row"]])) {
                    $updaterecord = true;
                    $noticemsg = $LANG["dnssuitePage_manage_dns_updaterecord_success"];
                    if($obj->basic->configs["enablenotification"] == "on" && $initreturn["notificationconfigs"]["dns"] == 1) {
                        $emailtype = $LANG["dnssuitePage_email_type_dns"] . " " . $obj->oldvalues["type"] . " - (" . $LANG["dnssuitePage_email_update"] . ")";
                        $emailoldval = $obj->oldvalues["host"] . " " . $obj->oldvalues["value"];
                        $emailnewval = $_POST["value"];
                        $obj->basic->sendNotificationEmail(["did" => $_POST["domainid"], "type" => $emailtype, "old" => $emailoldval, "new" => $emailnewval]);
                    }
                    $obj->basic->configs["fetchonload"] = "on";
                    if($zonedata = $obj->loadDomain($_POST["domainid"], false)) {
                        if(!empty($zonedata["cname"])) {
                            for ($i = 0; $i < count($zonedata["cname"]); $i++) {
                                $zonedata["cname"][$i] = explode(" ", $zonedata["cname"][$i]);
                                $zonedata["cname"][$i][] = $i;
                            }
                            $recordcount = count($zonedata["cname"]);
                        } else {
                            $recordcount = 0;
                        }
                    }
                    echo json_encode(["status" => 1, "data" => $zonedata["cname"], "count" => $recordcount]);
                } else {
                    echo json_encode(["status" => 0]);
                }
            } else {
                echo json_encode(["status" => 3]);
            }
            exit;
        }
        if($_POST["action"] == "addNS" && $obj->basic->configs["enablednseditor"] == "on" && $obj->basic->records_ns["modify"] == "on") {
            $_POST["host"] = strtolower($_POST["host"]);
            if($_POST["host"] != $domain . ".") {
                if($obj->basic->validateHostname($_POST["host"])) {
                    if($obj->basic->validateHostname($_POST["value"]) || $obj->basic->validateHostnameDot($_POST["value"])) {
                        if($obj->addRecord($_POST["domainid"], ["mode" => "NS", "host" => $_POST["host"], "value" => $_POST["value"]])) {
                            $addrecord = true;
                            $noticemsg = $LANG["dnssuitePage_manage_dns_addrecord_success"];
                            if($obj->basic->configs["enablenotification"] == "on" && $initreturn["notificationconfigs"]["dns"] == 1) {
                                $emailtype = $LANG["dnssuitePage_email_type_dns"] . " NS " . " - (" . $LANG["dnssuitePage_email_add"] . ")";
                                $emailnewval = $_POST["host"] . " " . $_POST["value"];
                                $obj->basic->sendNotificationEmail(["did" => $_POST["domainid"], "type" => $emailtype, "old" => $LANG["dnssuitePage_email_na"], "new" => $emailnewval]);
                            }
                            $obj->basic->configs["fetchonload"] = "on";
                            if($zonedata = $obj->loadDomain($_POST["domainid"], false)) {
                                if(!empty($zonedata["ns"])) {
                                    for ($i = 0; $i < count($zonedata["ns"]); $i++) {
                                        $zonedata["ns"][$i] = explode(" ", $zonedata["ns"][$i]);
                                        $zonedata["ns"][$i][] = $i;
                                    }
                                    $recordcount = count($zonedata["ns"]);
                                } else {
                                    $recordcount = 0;
                                }
                            }
                            echo json_encode(["status" => 1, "data" => $zonedata["ns"], "count" => $recordcount]);
                        } else {
                            echo json_encode(["status" => 0]);
                        }
                    } else {
                        echo json_encode(["status" => 3]);
                    }
                } else {
                    echo json_encode(["status" => 2]);
                }
            } else {
                echo json_encode(["status" => 2]);
            }
            exit;
        }
        if($_POST["action"] == "modifyNS" && $obj->basic->configs["enablednseditor"] == "on" && $obj->basic->records_ns["modify"] == "on") {
            if($obj->basic->validateHostname($_POST["value"]) || $obj->basic->validateHostnameDot($_POST["value"])) {
                if($obj->updateDNSRecord($_POST["domainid"], ["mode" => "NS", "value" => $_POST["value"], "row" => $_POST["row"]])) {
                    $updaterecord = true;
                    $noticemsg = $LANG["dnssuitePage_manage_dns_updaterecord_success"];
                    if($obj->basic->configs["enablenotification"] == "on" && $initreturn["notificationconfigs"]["dns"] == 1) {
                        $emailtype = $LANG["dnssuitePage_email_type_dns"] . " " . $obj->oldvalues["type"] . " - (" . $LANG["dnssuitePage_email_update"] . ")";
                        $emailoldval = $obj->oldvalues["host"] . " " . $obj->oldvalues["value"];
                        $emailnewval = $_POST["value"];
                        $obj->basic->sendNotificationEmail(["did" => $_POST["domainid"], "type" => $emailtype, "old" => $emailoldval, "new" => $emailnewval]);
                    }
                    $obj->basic->configs["fetchonload"] = "on";
                    if($zonedata = $obj->loadDomain($_POST["domainid"], false)) {
                        if(!empty($zonedata["ns"])) {
                            for ($i = 0; $i < count($zonedata["ns"]); $i++) {
                                $zonedata["ns"][$i] = explode(" ", $zonedata["ns"][$i]);
                                $zonedata["ns"][$i][] = $i;
                            }
                            $recordcount = count($zonedata["ns"]);
                        } else {
                            $recordcount = 0;
                        }
                    }
                    echo json_encode(["status" => 1, "data" => $zonedata["ns"], "count" => $recordcount]);
                } else {
                    echo json_encode(["status" => 0]);
                }
            } else {
                echo json_encode(["status" => 3]);
            }
            exit;
        }
        if($_POST["action"] == "addTXT" && $obj->basic->configs["enablednseditor"] == "on" && $obj->basic->records_txt["modify"] == "on") {
            $_POST["host"] = strtolower($_POST["host"]);
            if($obj->basic->validateHostname($_POST["host"]) || $obj->basic->validateHostnameDot($_POST["host"] || $obj->basic->validateHostnameUnderScore($_POST["host"]))) {
                if($obj->basic->validateTXTValue($_POST["value"])) {
                    if($obj->addRecord($_POST["domainid"], ["mode" => "TXT", "host" => $_POST["host"], "value" => $_POST["value"]])) {
                        $addrecord = true;
                        $noticemsg = $LANG["dnssuitePage_manage_dns_addrecord_success"];
                        if($obj->basic->configs["enablenotification"] == "on" && $initreturn["notificationconfigs"]["dns"] == 1) {
                            $emailtype = $LANG["dnssuitePage_email_type_dns"] . " TXT " . " - (" . $LANG["dnssuitePage_email_add"] . ")";
                            $emailnewval = $_POST["host"] . " " . $_POST["value"];
                            $obj->basic->sendNotificationEmail(["did" => $_POST["domainid"], "type" => $emailtype, "old" => $LANG["dnssuitePage_email_na"], "new" => $emailnewval]);
                        }
                        $obj->basic->configs["fetchonload"] = "on";
                        if($zonedata = $obj->loadDomain($_POST["domainid"], false)) {
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
                                $recordcount = count($zonedata["txt"]);
                            } else {
                                $recordcount = 0;
                            }
                        }
                        echo json_encode(["status" => 1, "data" => $zonedata["txt"], "count" => $recordcount]);
                    } else {
                        echo json_encode(["status" => 0]);
                    }
                } else {
                    echo json_encode(["status" => 3]);
                }
            } else {
                echo json_encode(["status" => 2]);
            }
            exit;
        }
        if($_POST["action"] == "modifyTXT" && $obj->basic->configs["enablednseditor"] == "on" && $obj->basic->records_txt["modify"] == "on") {
            if($obj->basic->validateTXTValue($_POST["value"])) {
                if($obj->updateDNSRecord($_POST["domainid"], ["mode" => "TXT", "value" => $_POST["value"], "row" => $_POST["row"]])) {
                    $updaterecord = true;
                    $noticemsg = $LANG["dnssuitePage_manage_dns_updaterecord_success"];
                    if($obj->basic->configs["enablenotification"] == "on" && $initreturn["notificationconfigs"]["dns"] == 1) {
                        $emailtype = $LANG["dnssuitePage_email_type_dns"] . " " . $obj->oldvalues["type"] . " - (" . $LANG["dnssuitePage_email_update"] . ")";
                        $emailoldval = $obj->oldvalues["host"] . " " . $obj->oldvalues["value"];
                        $emailnewval = $_POST["value"];
                        $obj->basic->sendNotificationEmail(["did" => $_POST["domainid"], "type" => $emailtype, "old" => $emailoldval, "new" => $emailnewval]);
                    }
                    $obj->basic->configs["fetchonload"] = "on";
                    if($zonedata = $obj->loadDomain($_POST["domainid"], false)) {
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
                            $recordcount = count($zonedata["txt"]);
                        } else {
                            $recordcount = 0;
                        }
                    }
                    echo json_encode(["status" => 1, "data" => $zonedata["txt"], "count" => $recordcount]);
                } else {
                    echo json_encode(["status" => 0]);
                }
            } else {
                echo json_encode(["status" => 3]);
            }
            exit;
        }
        if($_POST["action"] == "addMX" && $obj->basic->configs["enablednseditor"] == "on" && $obj->basic->records_mx["modify"] == "on") {
            $_POST["host"] = strtolower($_POST["host"]);
            if($obj->basic->validateHostnameNoWildCard($_POST["host"]) || $obj->basic->validateHostnameDot($_POST["host"])) {
                if($obj->basic->validateMXPriority($_POST["priority"])) {
                    if($obj->basic->validateHostname($_POST["value"]) || $obj->basic->validateHostnameDot($_POST["value"])) {
                        if($obj->addRecord($_POST["domainid"], ["mode" => "MX", "host" => $_POST["host"], "value" => $_POST["value"], "priority" => $_POST["priority"]])) {
                            $addrecord = true;
                            $noticemsg = $LANG["dnssuitePage_manage_dns_addrecord_success"];
                            if($obj->basic->configs["enablenotification"] == "on" && $initreturn["notificationconfigs"]["dns"] == 1) {
                                $emailtype = $LANG["dnssuitePage_email_type_dns"] . " MX " . " - (" . $LANG["dnssuitePage_email_add"] . ")";
                                $emailnewval = $_POST["host"] . " " . $_POST["priority"] . " " . $_POST["value"];
                                $obj->basic->sendNotificationEmail(["did" => $_POST["domainid"], "type" => $emailtype, "old" => $LANG["dnssuitePage_email_na"], "new" => $emailnewval]);
                            }
                            $obj->basic->configs["fetchonload"] = "on";
                            if($zonedata = $obj->loadDomain($_POST["domainid"], false)) {
                                if(!empty($zonedata["txt"])) {
                                    for ($i = 0; $i < count($zonedata["mx"]); $i++) {
                                        $zonedata["mx"][$i] = explode(" ", $zonedata["mx"][$i]);
                                        $zonedata["mx"][$i][] = $i;
                                    }
                                    $recordcount = count($zonedata["mx"]);
                                } else {
                                    $recordcount = 0;
                                }
                            }
                            echo json_encode(["status" => 1, "data" => $zonedata["mx"], "count" => $recordcount]);
                        } else {
                            echo json_encode(["status" => 0]);
                        }
                    } else {
                        echo json_encode(["status" => 3]);
                    }
                } else {
                    echo json_encode(["status" => 4]);
                }
            } else {
                echo json_encode(["status" => 2]);
            }
            exit;
        }
        if($_POST["action"] == "modifyMX" && $obj->basic->configs["enablednseditor"] == "on" && $obj->basic->records_mx["modify"] == "on") {
            if($obj->basic->validateHostname($_POST["value"]) || $obj->basic->validateHostnameDot($_POST["value"])) {
                if($obj->basic->validateMXPriority($_POST["priority"])) {
                    if($obj->updateDNSRecord($_POST["domainid"], ["mode" => "MX", "value" => $_POST["value"], "row" => $_POST["row"], "priority" => $_POST["priority"]])) {
                        $updaterecord = true;
                        $noticemsg = $LANG["dnssuitePage_manage_dns_updaterecord_success"];
                        if($obj->basic->configs["enablenotification"] == "on" && $initreturn["notificationconfigs"]["dns"] == 1) {
                            $emailtype = $LANG["dnssuitePage_email_type_dns"] . " " . $obj->oldvalues["type"] . " - (" . $LANG["dnssuitePage_email_update"] . ")";
                            $emailoldval = $obj->oldvalues["host"] . " " . $obj->oldvalues["priority"] . " " . $obj->oldvalues["value"];
                            $emailnewval = $obj->oldvalues["priority"] . " " . $_POST["value"];
                            $obj->basic->sendNotificationEmail(["did" => $_POST["domainid"], "type" => $emailtype, "old" => $emailoldval, "new" => $emailnewval]);
                        }
                        $obj->basic->configs["fetchonload"] = "on";
                        if($zonedata = $obj->loadDomain($_POST["domainid"], false)) {
                            if(!empty($zonedata["mx"])) {
                                for ($i = 0; $i < count($zonedata["mx"]); $i++) {
                                    $zonedata["mx"][$i] = explode(" ", $zonedata["mx"][$i]);
                                    $zonedata["mx"][$i][] = $i;
                                }
                                $recordcount = count($zonedata["mx"]);
                            } else {
                                $recordcount = 0;
                            }
                        }
                        echo json_encode(["status" => 1, "data" => $zonedata["mx"], "count" => $recordcount]);
                    } else {
                        echo json_encode(["status" => 0]);
                    }
                } else {
                    echo json_encode(["status" => 4]);
                }
            } else {
                echo json_encode(["status" => 3]);
            }
            exit;
        }
        if($_POST["action"] == "addSRV" && $obj->basic->configs["enablednseditor"] == "on" && $obj->basic->records_srv["modify"] == "on") {
            $_POST["host"] = strtolower($_POST["host"]);
            if($obj->basic->validateHostname($_POST["host"]) || $obj->basic->validateHostnameDot($_POST["host"]) || $obj->basic->validateHostnameUnderScore($_POST["host"])) {
                if($obj->basic->validateIntRange($_POST["priority"]) && $obj->basic->validateIntRange($_POST["weight"]) && $obj->basic->validateIntRange($_POST["port"])) {
                    if($obj->basic->validateHostname($_POST["value"]) || $obj->basic->validateHostnameDot($_POST["value"])) {
                        if($obj->addRecord($_POST["domainid"], ["mode" => "SRV", "host" => $_POST["host"], "value" => $_POST["value"], "priority" => $_POST["priority"], "weight" => $_POST["weight"], "port" => $_POST["port"]])) {
                            $addrecord = true;
                            $noticemsg = $LANG["dnssuitePage_manage_dns_addrecord_success"];
                            if($obj->basic->configs["enablenotification"] == "on" && $initreturn["notificationconfigs"]["dns"] == 1) {
                                $emailtype = $LANG["dnssuitePage_email_type_dns"] . " SRV " . " - (" . $LANG["dnssuitePage_email_add"] . ")";
                                $emailnewval = $_POST["priority"] . " " . $_POST["weight"] . " " . $_POST["port"] . " " . $_POST["value"];
                                $obj->basic->sendNotificationEmail(["did" => $_POST["domainid"], "type" => $emailtype, "old" => $LANG["dnssuitePage_email_na"], "new" => $emailnewval]);
                            }
                            $obj->basic->configs["fetchonload"] = "on";
                            if($zonedata = $obj->loadDomain($_POST["domainid"], false)) {
                                if(!empty($zonedata["srv"])) {
                                    for ($i = 0; $i < count($zonedata["srv"]); $i++) {
                                        $zonedata["srv"][$i] = explode(" ", $zonedata["srv"][$i]);
                                        $zonedata["srv"][$i][] = $i;
                                    }
                                    $recordcount = count($zonedata["srv"]);
                                } else {
                                    $recordcount = 0;
                                }
                            }
                            echo json_encode(["status" => 1, "data" => $zonedata["srv"], "count" => $recordcount]);
                        } else {
                            echo json_encode(["status" => 0]);
                        }
                    } else {
                        echo json_encode(["status" => 3]);
                    }
                } else {
                    echo json_encode(["status" => 4]);
                }
            } else {
                echo json_encode(["status" => 2]);
            }
            exit;
        }
        if($_POST["action"] == "modifySRV" && $obj->basic->configs["enablednseditor"] == "on" && $obj->basic->records_srv["modify"] == "on") {
            if($obj->basic->validateIntRange($_POST["priority"]) && $obj->basic->validateIntRange($_POST["weight"]) && $obj->basic->validateIntRange($_POST["port"])) {
                if($obj->basic->validateHostname($_POST["value"]) || $obj->basic->validateHostnameDot($_POST["value"])) {
                    if($obj->updateDNSRecord($_POST["domainid"], ["mode" => "SRV", "value" => $_POST["value"], "priority" => $_POST["priority"], "weight" => $_POST["weight"], "port" => $_POST["port"], "row" => $_POST["row"]])) {
                        $updaterecord = true;
                        $noticemsg = $LANG["dnssuitePage_manage_dns_updaterecord_success"];
                        if($obj->basic->configs["enablenotification"] == "on" && $initreturn["notificationconfigs"]["dns"] == 1) {
                            $emailtype = $LANG["dnssuitePage_email_type_dns"] . " " . $obj->oldvalues["type"] . " - (" . $LANG["dnssuitePage_email_update"] . ")";
                            $emailoldval = $obj->oldvalues["host"] . " " . $obj->oldvalues["priority"] . " " . $obj->oldvalues["weight"] . " " . $obj->oldvalues["port"] . " " . $obj->oldvalues["value"];
                            $emailnewval = $obj->oldvalues["priority"] . " " . $obj->oldvalues["weight"] . " " . $obj->oldvalues["port"] . " " . $_POST["value"];
                            $obj->basic->sendNotificationEmail(["did" => $_POST["domainid"], "type" => $emailtype, "old" => $emailoldval, "new" => $emailnewval]);
                        }
                        $obj->basic->configs["fetchonload"] = "on";
                        if($zonedata = $obj->loadDomain($_POST["domainid"], false)) {
                            if(!empty($zonedata["srv"])) {
                                for ($i = 0; $i < count($zonedata["srv"]); $i++) {
                                    $zonedata["srv"][$i] = explode(" ", $zonedata["srv"][$i]);
                                    $zonedata["srv"][$i][] = $i;
                                }
                                $recordcount = count($zonedata["srv"]);
                            } else {
                                $recordcount = 0;
                            }
                        }
                        echo json_encode(["status" => 1, "data" => $zonedata["srv"], "count" => $recordcount]);
                    } else {
                        echo json_encode(["status" => 0]);
                    }
                } else {
                    echo json_encode(["status" => 3]);
                }
            } else {
                echo json_encode(["status" => 4]);
            }
            exit;
        }
        if($_POST["action"] == "addREDIRECT") {
            $_POST["redirecturl"] = strtolower($_POST["redirecturl"]);
            $_POST["fromurl"] = strtolower($_POST["fromurl"]);
            if($obj->returnRedirectState() && $obj->returnRedirectSlotState($_POST["domainid"]) && 0 < $obj->basic->edition) {
                if($obj->basic->urlforward["masked"] != "on") {
                    if($_POST["type"] != 301 && $_POST["type"] != 302 && $_POST["type"] != 303) {
                        echo json_encode(["status" => 8]);
                        exit;
                    }
                } elseif($_POST["type"] != 301 && $_POST["type"] != 302 && $_POST["type"] != 303 && $_POST["type"] != 999) {
                    echo json_encode(["status" => 8]);
                    exit;
                }
                if($obj->basic->checkRedirectRoot($_POST["domainid"]) && $_POST["type"] == 999) {
                    echo json_encode(["status" => 7]);
                    exit;
                }
                $url = parse_url($_POST["redirecturl"]);
                if(!$url["scheme"]) {
                    $_POST["redirecturl"] = "http://" . $_POST["redirecturl"];
                }
                if(filter_var($_POST["redirecturl"], FILTER_VALIDATE_URL)) {
                    if($obj->addRedirect(["did" => $_POST["domainid"], "from" => $_POST["fromurl"], "to" => $_POST["redirecturl"], "type" => $_POST["type"], "maskedtitle" => strip_tags($_POST["maskedtitle"]), "maskedmeta" => strip_tags($_POST["maskedmeta"]), "maskedkeywords" => strip_tags($_POST["maskedkeywords"])])) {
                        $addredirect = true;
                        $noticemsg = $LANG["dnssuitePage_manage_redirect_success"];
                        $obj->redirect->fetchRedirectRemote($_POST["domainid"]);
                        if($obj->basic->configs["enablenotification"] == "on" && $initreturn["notificationconfigs"]["webredirect"] == 1) {
                            $emailtype = $LANG["dnssuitePage_email_type_webredirect"] . " - (" . $LANG["dnssuitePage_email_add"] . ")";
                            $emailnewval = $_POST["fromurl"] . " -> " . $_POST["redirecturl"] . " (" . $_POST["type"] . ")";
                            $obj->basic->sendNotificationEmail(["did" => $_POST["domainid"], "type" => $emailtype, "old" => $LANG["dnssuitePage_email_na"], "new" => $emailnewval]);
                        }
                        $redirectdata = $obj->loadRedirect($_POST["domainid"]);
                        $redirectcount = count($redirectdata);
                        echo json_encode(["status" => 1, "data" => $redirectdata, "count" => $redirectcount]);
                    } else {
                        echo json_encode(["status" => 3]);
                    }
                } else {
                    echo json_encode(["status" => 2]);
                }
            } else {
                echo json_encode(["status" => 0]);
            }
            exit;
        }
        if($_POST["action"] == "modifyREDIRECT" && $obj->returnRedirectState() && 0 < $obj->basic->edition) {
            if(!preg_match("/\\d+/", $_POST["redirectid"])) {
                echo json_encode(["status" => 8]);
                exit;
            }
            if($obj->basic->urlforward["masked"] != "on") {
                if($_POST["type"] != 301 && $_POST["type"] != 302 && $_POST["type"] != 303) {
                    echo json_encode(["status" => 8]);
                    exit;
                }
            } elseif($_POST["type"] != 301 && $_POST["type"] != 302 && $_POST["type"] != 303 && $_POST["type"] != 999) {
                echo json_encode(["status" => 8]);
                exit;
            }
            $url = parse_url($_POST["redirecturl"]);
            if(!$url["scheme"]) {
                $_POST["redirecturl"] = "http://" . $_POST["redirecturl"];
            }
            if(filter_var($_POST["redirecturl"], FILTER_VALIDATE_URL)) {
                if($obj->modifyRedirect($_POST["domainid"], ["to" => $_POST["redirecturl"], "type" => $_POST["type"], "rid" => $_POST["redirectid"]])) {
                    $modifyredirect = true;
                    $noticemsg = $LANG["dnssuitePage_manage_redirect_modify_success"];
                    if($obj->basic->configs["enablenotification"] == "on" && $initreturn["notificationconfigs"]["webredirect"] == 1) {
                        $emailtype = $LANG["dnssuitePage_email_type_webredirect"] . " - (" . $LANG["dnssuitePage_email_update"] . ")";
                        $emailoldval = $obj->oldvalues["fromurl"] . " -> " . $obj->oldvalues["redirecturl"] . " (" . $obj->oldvalues["type"] . ")";
                        $emailnewval = $_POST["redirecturl"] . " (" . $_POST["type"] . ")";
                        $obj->basic->sendNotificationEmail(["did" => $_POST["domainid"], "type" => $emailtype, "old" => $emailoldval, "new" => $emailnewval]);
                    }
                    $redirectdata = $obj->loadRedirect($_POST["domainid"]);
                    if(!empty($redirectdata)) {
                        $redirectcount = count($redirectdata);
                    } else {
                        $redirectcount = 0;
                    }
                    echo json_encode(["status" => 1, "data" => $redirectdata, "count" => $redirectcount]);
                } else {
                    echo json_encode(["status" => 0]);
                }
            } else {
                echo json_encode(["status" => 2]);
            }
        }
        if($_POST["action"] == "deleteREDIRECT" && $obj->returnRedirectState() && 0 < $obj->basic->edition) {
            if(!preg_match("/\\d+/", $_POST["redirectid"])) {
                echo json_encode(["status" => 8]);
                exit;
            }
            $type = $obj->redirect->returnRedirectTypefromRID($_POST["redirectid"]);
            if($type == 999) {
                if($obj->deleteRedirectMasked($_POST["domainid"], $_POST["redirectid"])) {
                    $noticemsg = $LANG["dnsproviderPage_manage_redirect_delete_success"];
                    if($obj->basic->configs["enablenotification"] == "on" && $initreturn["notificationconfigs"]["webredirect"] == 1) {
                        $emailtype = $LANG["dnsproviderPage_email_type_webredirect"] . " - (" . $LANG["dnsproviderPage_email_delete"] . ")";
                        $emailoldval = $obj->oldvalues["fromurl"] . " -> " . $obj->oldvalues["redirecturl"] . " (" . $obj->oldvalues["type"] . ")";
                        $emailnewval = $LANG["dnsproviderPage_email_na"];
                        $obj->basic->sendNotificationEmail(["did" => $_POST["domainid"], "type" => $emailtype, "old" => $emailoldval, "new" => $emailnewval, "sid" => $sid]);
                    }
                    $redirectdata = $obj->loadRedirect($_POST["domainid"]);
                    if(!empty($redirectdata)) {
                        $redirectcount = count($redirectdata);
                    } else {
                        $redirectcount = 0;
                    }
                    echo json_encode(["status" => 1, "data" => $redirectdata, "count" => $redirectcount]);
                } else {
                    json_encode(["status" => 0]);
                }
            } elseif($obj->deleteRedirect($_POST["domainid"], $_POST["redirectid"])) {
                $deleteredirect = true;
                $noticemsg = $LANG["dnssuitePage_manage_redirect_delete_success"];
                if($obj->basic->configs["enablenotification"] == "on" && $initreturn["notificationconfigs"]["webredirect"] == 1) {
                    $emailtype = $LANG["dnssuitePage_email_type_webredirect"] . " - (" . $LANG["dnssuitePage_email_delete"] . ")";
                    $emailoldval = $obj->oldvalues["fromurl"] . " -> " . $obj->oldvalues["redirecturl"] . " (" . $obj->oldvalues["type"] . ")";
                    $emailnewval = $LANG["dnssuitePage_email_na"];
                    $obj->basic->sendNotificationEmail(["did" => $_POST["domainid"], "type" => $emailtype, "old" => $emailoldval, "new" => $emailnewval]);
                }
                $redirectdata = $obj->loadRedirect($_POST["domainid"]);
                if(!empty($redirectdata)) {
                    $redirectcount = count($redirectdata);
                } else {
                    $redirectcount = 0;
                }
                echo json_encode(["status" => 1, "data" => $redirectdata, "count" => $redirectcount]);
            } else {
                json_encode(["status" => 0]);
            }
        }
        if($_POST["action"] == "addALIAS") {
            $_POST["newalias"] = strtolower($_POST["newalias"]);
            if($obj->returnEmailForwarderState() && $obj->returnEmailForwarderSlotState($_POST["domainid"]) && 0 < $obj->basic->edition) {
                if(!filter_var($_POST["newalias"] . "@" . $domain, FILTER_VALIDATE_EMAIL)) {
                    echo json_encode(["status" => 2]);
                } elseif(!$obj->addAlias($_POST["domainid"], $_POST["newalias"])) {
                    echo json_encode(["status" => 0]);
                } else {
                    $forwarddata = $obj->loadForwarder($_POST["domainid"]);
                    if(!empty($forwarddata)) {
                        $count = count($forwarddata);
                    } else {
                        $count = 0;
                    }
                    echo json_encode(["status" => 1, "data" => $forwarddata, "count" => $count]);
                }
            }
        }
        if($_POST["action"] == "modifyALIAS" && $obj->returnEmailForwarderState() && 0 < $obj->basic->edition) {
            if($obj->modifyForwarder($_POST["domainid"], ["fid" => $_POST["forwarderid"], "mailto" => $_POST["emails"]])) {
                if($obj->basic->configs["enablenotification"] == "on" && $initreturn["notificationconfigs"]["emailforward"] == 1) {
                    $emailtype = $LANG["dnssuitePage_email_type_emailforward"] . " - (" . $LANG["dnssuitePage_email_update"] . ")";
                    $emailoldval = $obj->oldvalues["alias"] . " -> " . $obj->oldvalues["oldmailto"];
                    $emailnewval = $obj->oldvalues["newmailto"];
                    $obj->basic->sendNotificationEmail(["did" => $_POST["domainid"], "type" => $emailtype, "old" => $emailoldval, "new" => $emailnewval]);
                }
                $forwarddata = $obj->loadForwarder($_POST["domainid"]);
                if(!empty($forwarddata)) {
                    $count = count($forwarddata);
                } else {
                    $count = 0;
                }
                echo json_encode(["status" => 1, "data" => $forwarddata, "count" => $count]);
            } else {
                echo json_encode(["status" => 0]);
            }
        }
        if($_POST["action"] == "deleteALIAS" && $obj->returnEmailForwarderState() && 0 < $obj->basic->edition) {
            if($obj->deleteForwarder($_POST["domainid"], $_POST["forwarderid"])) {
                if($obj->basic->configs["enablenotification"] == "on" && $initreturn["notificationconfigs"]["emailforward"] == 1) {
                    $emailtype = $LANG["dnssuitePage_email_type_emailforward"] . " - (" . $LANG["dnssuitePage_email_delete"] . ")";
                    $emailoldval = $obj->oldvalues["alias"] . " -> " . $obj->oldvalues["oldmailto"];
                    $emailnewval = $LANG["dnssuitePage_email_na"];
                    $obj->basic->sendNotificationEmail(["did" => $_POST["domainid"], "type" => $emailtype, "old" => $emailoldval, "new" => $emailnewval]);
                }
                $forwarddata = $obj->loadForwarder($_POST["domainid"]);
                if(!empty($forwarddata)) {
                    $count = count($forwarddata);
                } else {
                    $count = 0;
                }
                echo json_encode(["status" => 1, "data" => $forwarddata, "count" => $count]);
            } else {
                echo json_encode(["status" => 0]);
            }
        }
        if($_POST["action"] == "addEMAIL") {
            $_POST["newemail"] = strtolower($_POST["newemail"]);
            if(($obj->returnEmailForwarderState() || $obj->returnCatchallState()) && $obj->returnEmailSlotState($_POST["domainid"]) && 0 < $obj->basic->edition) {
                if(filter_var($_POST["newemail"], FILTER_VALIDATE_EMAIL)) {
                    if(!$obj->email->checkDestinationEmailExist(["did" => $_POST["domainid"], "newemail" => $_POST["newemail"]])) {
                        if($obj->email->addEmailtoDB($_POST["domainid"], $_POST["newemail"], 0)) {
                            if(isset($_POST["sdid"]) && $obj->basic->checkSubdomainOwnershipFromSDID($_POST["sdid"])) {
                                $subdomain = $obj->basic->returnSubDomainFromSDID($_POST["sdid"]);
                                $forwarddata = $obj->loadSubDomainForwarder(["did" => $_POST["domainid"], "sdid" => $_POST["sdid"], "host" => $subdomain["host"]]);
                            } else {
                                $forwarddata = $obj->loadForwarder($_POST["domainid"]);
                            }
                            if(!empty($obj->email->emaildestinationdata["pendingemail"])) {
                                $pendingemailcount = count($obj->email->emaildestinationdata["pendingemail"]);
                            } else {
                                $pendingemailcount = 0;
                            }
                            if(!empty($obj->email->emaildestinationdata["confirmedemail"])) {
                                $confirmedemailcount = count($obj->email->emaildestinationdata["confirmedemail"]);
                            } else {
                                $confirmedemailcount = 0;
                            }
                            $count = $pendingemailcount + $confirmedemailcount;
                            echo json_encode(["status" => 1, "datapending" => $obj->email->cleanEmailVariables($obj->email->emaildestinationdata["pendingemail"]), "dataconfirmed" => $obj->email->cleanEmailVariables($obj->email->emaildestinationdata["confirmedemail"]), "count" => $count]);
                        } else {
                            echo json_encode(["status" => 0]);
                        }
                    } else {
                        echo json_encode(["status" => 3]);
                    }
                } else {
                    echo json_encode(["status" => 2]);
                }
            } else {
                echo json_encode(["status" => 4]);
            }
        }
        if($_POST["action"] == "verifyEMAIL" && ($obj->returnEmailForwarderState() || $obj->returnCatchallState()) && 0 < $obj->basic->edition) {
            if($obj->verifyEmail($_POST["domainid"], $_POST["emailid"], $_POST["pin"])) {
                if($obj->email->updateEmailStatus($_POST["emailid"], 1)) {
                    if(isset($_POST["sdid"]) && $obj->basic->checkSubdomainOwnershipFromSDID($_POST["sdid"])) {
                        $subdomain = $obj->basic->returnSubDomainFromSDID($_POST["sdid"]);
                        $forwarddata = $obj->loadSubDomainForwarder(["did" => $_POST["domainid"], "sdid" => $_POST["sdid"], "host" => $subdomain["host"]]);
                    } else {
                        $forwarddata = $obj->loadForwarder($_POST["domainid"]);
                    }
                    if(!empty($obj->email->emaildestinationdata["pendingemail"])) {
                        $pendingemailcount = count($obj->email->emaildestinationdata["pendingemail"]);
                    } else {
                        $pendingemailcount = 0;
                    }
                    if(!empty($obj->email->emaildestinationdata["confirmedemail"])) {
                        $confirmedemailcount = count($obj->email->emaildestinationdata["confirmedemail"]);
                    } else {
                        $confirmedemailcount = 0;
                    }
                    $count = $pendingemailcount + $confirmedemailcount;
                    if(!empty($forwarddata)) {
                        $forwardercount = count($forwarddata);
                    } else {
                        $forwardercount = 0;
                    }
                    $catchalldata = $obj->loadCatchall($_POST["domainid"]);
                    $destinationemails = $obj->email->generateSelectOptionsAny($obj->email->emaildestinationdata["confirmedemail"]);
                    echo json_encode(["status" => 1, "datapending" => $obj->email->cleanEmailVariables($obj->email->emaildestinationdata["pendingemail"]), "dataconfirmed" => $obj->email->cleanEmailVariables($obj->email->emaildestinationdata["confirmedemail"]), "count" => $count, "destinationemails" => $destinationemails, "forwarderdata" => $forwarddata, "forwardercount" => $forwardercount, "catchalloptions" => $catchalldata["options"], "catchallmailto" => $catchalldata["mailto"]]);
                } else {
                    echo json_encode(["status" => 0]);
                }
            } else {
                echo json_encode(["status" => 2]);
            }
        }
        if($_POST["action"] == "deleteEMAIL" && ($obj->returnEmailForwarderState() || $obj->returnCatchallState()) && 0 < $obj->basic->edition) {
            if(!is_numeric($_POST["emailid"])) {
                echo json_encode(["status" => 3]);
                exit;
            }
            if(!$obj->email->checkEmailInUse($_POST["domainid"], $_POST["emailid"])) {
                if($obj->deleteEmail($_POST["domainid"], $_POST["emailid"])) {
                    if(isset($_POST["sdid"]) && $obj->basic->checkSubdomainOwnershipFromSDID($_POST["sdid"])) {
                        $subdomain = $obj->basic->returnSubDomainFromSDID($_POST["sdid"]);
                        $forwarddata = $obj->loadSubDomainForwarder(["did" => $_POST["domainid"], "sdid" => $_POST["sdid"], "host" => $subdomain["host"]]);
                    } else {
                        $forwarddata = $obj->loadForwarder($_POST["domainid"]);
                    }
                    if(!empty($obj->email->emaildestinationdata["pendingemail"])) {
                        $pendingemailcount = count($obj->email->emaildestinationdata["pendingemail"]);
                    } else {
                        $pendingemailcount = 0;
                    }
                    if(!empty($obj->email->emaildestinationdata["confirmedemail"])) {
                        $confirmedemailcount = count($obj->email->emaildestinationdata["confirmedemail"]);
                    } else {
                        $confirmedemailcount = 0;
                    }
                    $count = $pendingemailcount + $confirmedemailcount;
                    if(!empty($forwarddata)) {
                        $forwardercount = count($forwarddata);
                    } else {
                        $forwardercount = 0;
                    }
                    $catchalldata = $obj->loadCatchall($_POST["domainid"]);
                    $destinationemails = $obj->email->generateSelectOptionsAny($obj->email->emaildestinationdata["confirmedemail"]);
                    echo json_encode(["status" => 1, "datapending" => $obj->email->cleanEmailVariables($obj->email->emaildestinationdata["pendingemail"]), "dataconfirmed" => $obj->email->cleanEmailVariables($obj->email->emaildestinationdata["confirmedemail"]), "count" => $count, "destinationemails" => $destinationemails, "forwarderdata" => $forwarddata, "forwardercount" => $forwardercount, "catchalloptions" => $catchalldata["options"], "catchallmailto" => $catchalldata["mailto"]]);
                } else {
                    echo json_encode(["status" => 0]);
                }
            } else {
                echo json_encode(["status" => 2]);
            }
        }
        if($_POST["action"] == "modifyCATCHALL" && $obj->returnCatchallState() && 0 < $obj->basic->edition) {
            if($_POST["emails"] == NULL) {
                if($obj->disableCatchall($_POST["domainid"])) {
                    if($obj->basic->configs["enablenotification"] == "on" && $initreturn["notificationconfigs"]["emailcatchall"] == 1) {
                        $emailtype = $LANG["dnssuitePage_email_type_emailcatchall"] . " - (" . $LANG["dnssuitePage_email_disable"] . ")";
                        $emailoldval = "-> " . $obj->oldvalues["oldmailto"];
                        $emailnewval = $LANG["dnssuitePage_email_na"];
                        $obj->basic->sendNotificationEmail(["did" => $_POST["domainid"], "type" => $emailtype, "old" => $emailoldval, "new" => $emailnewval]);
                    }
                    $forwarddata = $obj->loadForwarder($_POST["domainid"]);
                    $catchalldata = $obj->loadCatchall($_POST["domainid"]);
                    $destinationemails = $obj->email->generateSelectOptionsAny($obj->email->emaildestinationdata["confirmedemail"]);
                    echo json_encode(["status" => 2, "destinationemails" => $destinationemails, "catchalloptions" => $catchalldata["options"], "catchallmailto" => $catchalldata["mailto"]]);
                } else {
                    echo json_encode(["status" => 0]);
                }
            } elseif($obj->updateCatchall($_POST["domainid"], $_POST["emails"])) {
                if($obj->basic->configs["enablenotification"] == "on" && $initreturn["notificationconfigs"]["emailcatchall"] == 1) {
                    $emailtype = $LANG["dnssuitePage_email_type_emailcatchall"] . " - (" . $LANG["dnssuitePage_email_update"] . ")";
                    $emailoldval = "-> " . $obj->oldvalues["oldmailto"];
                    $emailnewval = $obj->oldvalues["newmailto"];
                    $obj->basic->sendNotificationEmail(["did" => $_POST["domainid"], "type" => $emailtype, "old" => $emailoldval, "new" => $emailnewval]);
                }
                $forwarddata = $obj->loadForwarder($_POST["domainid"]);
                $catchalldata = $obj->loadCatchall($_POST["domainid"]);
                $destinationemails = $obj->email->generateSelectOptionsAny($obj->email->emaildestinationdata["confirmedemail"]);
                echo json_encode(["status" => 1, "destinationemails" => $destinationemails, "catchalloptions" => $catchalldata["options"], "catchallmailto" => $catchalldata["mailto"]]);
            } else {
                echo json_encode(["status" => 3]);
            }
        }
        if($_POST["action"] == "addSUBDOMAIN") {
            $_POST["hostname"] = strtolower($_POST["hostname"]);
            if(!$obj->isOverSubDomainLimit(["did" => $_POST["domainid"], "sid" => $sid])) {
                if(!$obj->checkHostnameExist(["did" => $_POST["domainid"], "hostname" => $_POST["hostname"]])) {
                    if($obj->checkSubDomainExist(["did" => $_POST["domainid"], "host" => $_POST["hostname"]])) {
                        $sdid = $obj->basic->getSDIDFromSubDomainHostname($_POST["domainid"], $_POST["hostname"]);
                        $subdomains = $obj->basic->getSubDomainsFromDID($_POST["domainid"]);
                        if(!empty($subdomains)) {
                            for ($i = 0; $i < count($subdomains); $i++) {
                                $subdomains[$i]["host"] = $subdomains[$i]["host"] . "." . $obj->basic->getDomainfromDID($_POST["domainid"]);
                            }
                            $subdomaincount = count($subdomains);
                        } else {
                            $subdomaincount = 0;
                        }
                        echo json_encode(["status" => 1, "id" => $sdid, "count" => $subdomaincount, "data" => $subdomains]);
                    } else {
                        echo json_encode(["status" => 3]);
                    }
                } else {
                    echo json_encode(["status" => 2]);
                }
            } else {
                echo json_encode(["status" => 0]);
            }
        }
        if($_POST["action"] == "deleteSUBDOMAIN") {
            if(!is_numeric($_POST["sdid"])) {
                echo json_encode(["status" => 3]);
                exit;
            }
            if($obj->basic->checkSubdomainOwnershipFromSDID($_POST["id"])) {
                if($obj->deleteSubDomain(["did" => $_POST["domainid"], "sdid" => $_POST["sdid"]])) {
                    $subdomains = $obj->basic->getSubDomainsFromDID($_POST["domainid"]);
                    if(!empty($subdomains)) {
                        for ($i = 0; $i < count($subdomains); $i++) {
                            $subdomains[$i]["host"] = $subdomains[$i]["host"] . "." . $obj->basic->getDomainfromDID($_POST["domainid"]);
                        }
                        $subdomaincount = count($subdomains);
                    } else {
                        $subdomaincount = 0;
                    }
                    echo json_encode(["status" => 1, "id" => $sdid, "count" => $subdomaincount, "data" => $subdomains]);
                } else {
                    echo json_encode(["status" => 0]);
                }
            } else {
                echo json_encode(["status" => 2]);
            }
        }
        if($_POST["action"] == "addREDIRECT-sub") {
            if($obj->basic->checkSubdomainOwnershipFromSDID($_POST["sdid"])) {
                if($obj->returnRedirectState() && 0 < $obj->basic->edition) {
                    $subdomain = $obj->basic->returnSubDomainFromSDID($_POST["sdid"]);
                    $_POST["redirecturl"] = strtolower($_POST["redirecturl"]);
                    $_POST["fromurl"] = strtolower($_POST["fromurl"]);
                    if($obj->returnRedirectState() && $obj->returnSubDomainRedirectSlotState($_POST["sdid"]) && 0 < $obj->basic->edition) {
                        if($obj->basic->urlforward["masked"] != "on") {
                            if($_POST["type"] != 301 && $_POST["type"] != 302 && $_POST["type"] != 303) {
                                echo json_encode(["status" => 8]);
                                exit;
                            }
                        } elseif($_POST["type"] != 301 && $_POST["type"] != 302 && $_POST["type"] != 303 && $_POST["type"] != 999) {
                            echo json_encode(["status" => 8]);
                            exit;
                        }
                        if($obj->basic->checkSubDomainRedirectRoot($_POST["sdid"]) && $_POST["type"] == 999) {
                            echo json_encode(["status" => 7]);
                            exit;
                        }
                        $url = parse_url($_POST["redirecturl"]);
                        if(!$url["scheme"]) {
                            $_POST["redirecturl"] = "http://" . $_POST["redirecturl"];
                        }
                        if(filter_var($_POST["redirecturl"], FILTER_VALIDATE_URL)) {
                            if($obj->addSubDomainRedirect(["did" => $_POST["domainid"], "from" => $_POST["fromurl"], "host" => $subdomain["host"], "sdid" => $_POST["sdid"], "to" => $_POST["redirecturl"], "type" => $_POST["type"], "maskedtitle" => strip_tags($_POST["maskedtitle"]), "maskedmeta" => strip_tags($_POST["maskedmeta"]), "maskedkeywords" => strip_tags($_POST["maskedkeywords"])])) {
                                $addredirect = true;
                                $noticemsg = $LANG["dnsproviderPage_manage_redirect_success"];
                                $obj->redirect->fetchSubDomainRedirectRemote(["did" => $_POST["domainid"], "host" => $subdomain["host"], "sdid" => $_POST["sdid"]]);
                                if($obj->basic->configs["enablenotification"] == "on" && $initreturn["notificationconfigs"]["webredirect"] == 1) {
                                    $emailtype = $LANG["dnsproviderPage_email_type_webredirect"] . " - (" . $LANG["dnsproviderPage_email_add"] . ")";
                                    $emailnewval = $_POST["fromurl"] . " -> " . $_POST["redirecturl"] . " (" . $_POST["type"] . ")";
                                    $obj->basic->sendSubDomainNotificationEmail(["did" => $_POST["domainid"], "type" => $emailtype, "old" => $LANG["dnsproviderPage_email_na"], "new" => $emailnewval, "sid" => $sid]);
                                }
                                $redirectdata = $obj->loadSubDomainRedirect(["did" => $_POST["domainid"], "host" => $subdomain["host"], "sdid" => $_POST["sdid"]]);
                                if(!empty($redirectdata)) {
                                    $redirectcount = count($redirectdata);
                                } else {
                                    $redirectcount = 0;
                                }
                                echo json_encode(["status" => 1, "data" => $redirectdata, "count" => $redirectcount]);
                            } else {
                                echo json_encode(["status" => 3]);
                            }
                        } else {
                            echo json_encode(["status" => 2]);
                        }
                    } else {
                        echo json_encode(["status" => 0]);
                    }
                    exit;
                }
            } else {
                echo json_encode(["status" => 9]);
            }
        }
        if($_POST["action"] == "modifyREDIRECT-sub") {
            if($obj->basic->checkSubdomainOwnershipFromSDID($_POST["sdid"])) {
                if($obj->returnRedirectState() && 0 < $obj->basic->edition) {
                    $subdomain = $obj->basic->returnSubDomainFromSDID($_POST["sdid"]);
                    if(!preg_match("/\\d+/", $_POST["redirectid"])) {
                        echo json_encode(["status" => 8]);
                        exit;
                    }
                    if($obj->basic->urlforward["masked"] != "on") {
                        if($_POST["type"] != 301 && $_POST["type"] != 302 && $_POST["type"] != 303) {
                            echo json_encode(["status" => 8]);
                            exit;
                        }
                    } elseif($_POST["type"] != 301 && $_POST["type"] != 302 && $_POST["type"] != 303 && $_POST["type"] != 999) {
                        echo json_encode(["status" => 8]);
                        exit;
                    }
                    $url = parse_url($_POST["redirecturl"]);
                    if(!$url["scheme"]) {
                        $_POST["redirecturl"] = "http://" . $_POST["redirecturl"];
                    }
                    if(filter_var($_POST["redirecturl"], FILTER_VALIDATE_URL)) {
                        if($obj->modifySubDomainRedirect(["did" => $_POST["domainid"], "sdid" => $_POST["sdid"], "host" => $subdomain["host"]], ["to" => $_POST["redirecturl"], "type" => $_POST["type"], "rid" => $_POST["redirectid"]])) {
                            $noticemsg = $LANG["dnsproviderPage_manage_redirect_modify_success"];
                            if($obj->basic->configs["enablenotification"] == "on" && $initreturn["notificationconfigs"]["webredirect"] == 1) {
                                $emailtype = $LANG["dnsproviderPage_email_type_webredirect"] . " - (" . $LANG["dnsproviderPage_email_update"] . ")";
                                $emailoldval = $obj->oldvalues["fromurl"] . " -> " . $obj->oldvalues["redirecturl"] . " (" . $obj->oldvalues["type"] . ")";
                                $emailnewval = $_POST["redirecturl"] . " (" . $_POST["type"] . ")";
                                $obj->basic->sendSubDomainNotificationEmail(["did" => $_POST["domainid"], "type" => $emailtype, "old" => $emailoldval, "new" => $emailnewval, "sid" => $sid]);
                            }
                            $redirectdata = $obj->loadSubDomainRedirect(["did" => $_POST["domainid"], "host" => $subdomain["host"], "sdid" => $_POST["sdid"]]);
                            if(!empty($redirectdata)) {
                                $redirectcount = count($redirectdata);
                            }
                            $redirectcount = 0;
                            echo json_encode(["status" => 1, "data" => $redirectdata, "count" => $redirectcount]);
                        } else {
                            echo json_encode(["status" => 0]);
                        }
                    } else {
                        echo json_encode(["status" => 2]);
                    }
                }
            } else {
                echo json_encode(["status" => 9]);
            }
        }
        if($_POST["action"] == "deleteREDIRECT-sub") {
            if($obj->basic->checkSubdomainOwnershipFromSDID($_POST["sdid"])) {
                if($obj->returnRedirectState() && 0 < $obj->basic->edition) {
                    $subdomain = $obj->basic->returnSubDomainFromSDID($_POST["sdid"]);
                    if(!preg_match("/\\d+/", $_POST["redirectid"])) {
                        echo json_encode(["status" => 8]);
                        exit;
                    }
                    $type = $obj->redirect->returnSubDomainRedirectTypefromRID($_POST["redirectid"]);
                    if($type == 999) {
                        if($obj->deleteSubDomainRedirectMasked(["did" => $_POST["domainid"], "sdid" => $_POST["sdid"], "host" => $subdomain["host"]], $_POST["redirectid"])) {
                            $noticemsg = $LANG["dnsproviderPage_manage_redirect_delete_success"];
                            if($obj->basic->configs["enablenotification"] == "on" && $initreturn["notificationconfigs"]["webredirect"] == 1) {
                                $emailtype = $LANG["dnsproviderPage_email_type_webredirect"] . " - (" . $LANG["dnsproviderPage_email_delete"] . ")";
                                $emailoldval = $obj->oldvalues["fromurl"] . " -> " . $obj->oldvalues["redirecturl"] . " (" . $obj->oldvalues["type"] . ")";
                                $emailnewval = $LANG["dnsproviderPage_email_na"];
                                $obj->basic->sendSubDomainNotificationEmail(["did" => $_POST["domainid"], "type" => $emailtype, "old" => $emailoldval, "new" => $emailnewval, "sid" => $sid]);
                            }
                            $redirectdata = $obj->loadSubDomainRedirect(["did" => $_POST["domainid"], "host" => $subdomain["host"], "sdid" => $_POST["sdid"]]);
                            $redirectcount = count($redirectdata);
                            echo json_encode(["status" => 1, "data" => $redirectdata, "count" => $redirectcount]);
                        } else {
                            json_encode(["status" => 0]);
                        }
                    } elseif($obj->deleteSubDomainRedirect(["did" => $_POST["domainid"], "sdid" => $_POST["sdid"], "host" => $subdomain["host"]], $_POST["redirectid"])) {
                        $noticemsg = $LANG["dnsproviderPage_manage_redirect_delete_success"];
                        if($obj->basic->configs["enablenotification"] == "on" && $initreturn["notificationconfigs"]["webredirect"] == 1) {
                            $emailtype = $LANG["dnsproviderPage_email_type_webredirect"] . " - (" . $LANG["dnsproviderPage_email_delete"] . ")";
                            $emailoldval = $obj->oldvalues["fromurl"] . " -> " . $obj->oldvalues["redirecturl"] . " (" . $obj->oldvalues["type"] . ")";
                            $emailnewval = $LANG["dnsproviderPage_email_na"];
                            $obj->basic->sendSubDomainNotificationEmail(["did" => $_POST["domainid"], "type" => $emailtype, "old" => $emailoldval, "new" => $emailnewval, "sid" => $sid]);
                        }
                        $redirectdata = $obj->loadSubDomainRedirect(["did" => $_POST["domainid"], "host" => $subdomain["host"], "sdid" => $_POST["sdid"]]);
                        if(!empty($redirectdata)) {
                            $redirectcount = count($redirectdata);
                        } else {
                            $redirectcount = 0;
                        }
                        echo json_encode(["status" => 1, "data" => $redirectdata, "count" => $redirectcount]);
                    } else {
                        json_encode(["status" => 0]);
                    }
                }
            } else {
                echo json_encode(["status" => 9]);
            }
        }
        if($_POST["action"] == "addALIAS-sub") {
            if($obj->basic->checkSubdomainOwnershipFromSDID($_POST["sdid"])) {
                $_POST["newalias"] = strtolower($_POST["newalias"]);
                if($obj->returnEmailForwarderState() && $obj->returnSubDomainEmailForwarderSlotState($_POST["sdid"]) && 0 < $obj->basic->edition) {
                    $subdomain = $obj->basic->returnSubDomainFromSDID($_POST["sdid"]);
                    $_POST["newalias"] = strtolower($_POST["newalias"]);
                    if(!filter_var($_POST["newalias"] . "@" . $subdomain["host"] . "." . $domain, FILTER_VALIDATE_EMAIL)) {
                        echo json_encode(["status" => 2]);
                    } elseif(!$obj->addSubDomainAlias(["did" => $_POST["domainid"], "sdid" => $_POST["sdid"]], $_POST["newalias"])) {
                        echo json_encode(["status" => 0]);
                    } else {
                        $forwarddata = $obj->loadSubDomainForwarder(["did" => $_POST["domainid"], "sdid" => $_POST["sdid"], "host" => $subdomain["host"]]);
                        if(!empty($forwarddata)) {
                            $count = count($forwarddata);
                        } else {
                            $count = 0;
                        }
                        echo json_encode(["status" => 1, "data" => $forwarddata, "count" => $count]);
                    }
                }
            } else {
                echo json_encode(["status" => 9]);
            }
        }
        if($_POST["action"] == "modifyALIAS-sub") {
            if($obj->basic->checkSubdomainOwnershipFromSDID($_POST["sdid"])) {
                if($obj->returnEmailForwarderState() && 0 < $obj->basic->edition) {
                    $subdomain = $obj->basic->returnSubDomainFromSDID($_POST["sdid"]);
                    if($obj->modifySubDomainForwarder(["did" => $_POST["domainid"], "sdid" => $_POST["sdid"], "host" => $subdomain["host"]], ["fid" => $_POST["forwarderid"], "mailto" => $_POST["emails"]])) {
                        if($obj->basic->configs["enablenotification"] == "on" && $initreturn["notificationconfigs"]["emailforward"] == 1) {
                            $emailtype = $LANG["dnsproviderPage_email_type_emailforward"] . " - (" . $LANG["dnsproviderPage_email_update"] . ")";
                            $emailoldval = $obj->oldvalues["alias"] . " -> " . $obj->oldvalues["oldmailto"];
                            $emailnewval = $obj->oldvalues["newmailto"];
                            $obj->basic->sendSubDomainNotificationEmail(["did" => $_POST["domainid"], "type" => $emailtype, "old" => $emailoldval, "new" => $emailnewval, "sid" => $sid]);
                        }
                        $forwarddata = $obj->loadSubDomainForwarder(["did" => $_POST["domainid"], "sdid" => $_POST["sdid"], "host" => $subdomain["host"]]);
                        if(!empty($forwarddata)) {
                            $count = count($forwarddata);
                        } else {
                            $count = 0;
                        }
                        echo json_encode(["status" => 1, "data" => $forwarddata, "count" => $count]);
                    } else {
                        echo json_encode(["status" => 0]);
                    }
                }
            } else {
                echo json_encode(["status" => 9]);
            }
        }
        if($_POST["action"] == "deleteALIAS-sub") {
            if($obj->basic->checkSubdomainOwnershipFromSDID($_POST["sdid"])) {
                if($obj->returnEmailForwarderState() && 0 < $obj->basic->edition) {
                    $subdomain = $obj->basic->returnSubDomainFromSDID($_POST["sdid"]);
                    if($obj->deleteSubDomainForwarder(["did" => $_POST["domainid"], "sdid" => $_POST["sdid"], "host" => $subdomain["host"]], $_POST["forwarderid"])) {
                        if($obj->basic->configs["enablenotification"] == "on" && $initreturn["notificationconfigs"]["emailforward"] == 1) {
                            $emailtype = $LANG["dnsproviderPage_email_type_emailforward"] . " - (" . $LANG["dnsproviderPage_email_delete"] . ")";
                            $emailoldval = $obj->oldvalues["alias"] . " -> " . $obj->oldvalues["oldmailto"];
                            $emailnewval = $LANG["dnsproviderPage_email_na"];
                            $obj->basic->sendSubDomainNotificationEmail(["did" => $_POST["domainid"], "type" => $emailtype, "old" => $emailoldval, "new" => $emailnewval, "sid" => $sid]);
                        }
                        $forwarddata = $obj->loadSubDomainForwarder(["did" => $_POST["domainid"], "sdid" => $_POST["sdid"], "host" => $subdomain["host"]]);
                        if(!empty($forwarddata)) {
                            $count = count($forwarddata);
                        } else {
                            $count = 0;
                        }
                        echo json_encode(["status" => 1, "data" => $forwarddata, "count" => $count]);
                    } else {
                        echo json_encode(["status" => 0]);
                    }
                }
            } else {
                echo json_encode(["status" => 9]);
            }
        }
        if($_POST["action"] == "modifyCATCHALL-sub") {
            if($obj->basic->checkSubdomainOwnershipFromSDID($_POST["sdid"])) {
                if($obj->returnCatchallState() && 0 < $obj->basic->edition) {
                    $subdomain = $obj->basic->returnSubDomainFromSDID($_POST["sdid"]);
                    if($_POST["emails"] == NULL) {
                        if($obj->disableSubDomainCatchall(["did" => $_POST["domainid"], "sdid" => $_POST["sdid"], "host" => $subdomain["host"]])) {
                            if($obj->basic->configs["enablenotification"] == "on" && $initreturn["notificationconfigs"]["emailcatchall"] == 1) {
                                $emailtype = $LANG["dnsproviderPage_email_type_emailcatchall"] . " - (" . $LANG["dnsproviderPage_email_disable"] . ")";
                                $emailoldval = "-> " . $obj->oldvalues["oldmailto"];
                                $emailnewval = $LANG["dnsproviderPage_email_na"];
                                $obj->basic->sendSubDomainNotificationEmail(["did" => $_POST["domainid"], "type" => $emailtype, "old" => $emailoldval, "new" => $emailnewval, "sid" => $sid]);
                            }
                            $forwarddata = $obj->loadSubDomainForwarder(["did" => $_POST["domainid"], "sdid" => $_POST["sdid"], "host" => $subdomain["host"]]);
                            $catchalldata = $obj->loadSubdomainCatchall(["did" => $_POST["domainid"], "sdid" => $_POST["sdid"], "host" => $subdomain["host"]]);
                            $destinationemails = $obj->email->generateSelectOptionsAny($obj->email->emaildestinationdata["confirmedemail"]);
                            echo json_encode(["status" => 2, "destinationemails" => $destinationemails, "catchalloptions" => $catchalldata["options"], "catchallmailto" => $catchalldata["mailto"]]);
                        } else {
                            echo json_encode(["status" => 0]);
                        }
                    } elseif($obj->updateSubDomainCatchall(["did" => $_POST["domainid"], "sdid" => $_POST["sdid"], "host" => $subdomain["host"]], $_POST["emails"])) {
                        if($obj->basic->configs["enablenotification"] == "on" && $initreturn["notificationconfigs"]["emailcatchall"] == 1) {
                            $emailtype = $LANG["dnsproviderPage_email_type_emailcatchall"] . " - (" . $LANG["dnsproviderPage_email_update"] . ")";
                            $emailoldval = "-> " . $obj->oldvalues["oldmailto"];
                            $emailnewval = $obj->oldvalues["newmailto"];
                            $obj->basic->sendSubDomainNotificationEmail(["did" => $_POST["domainid"], "type" => $emailtype, "old" => $emailoldval, "new" => $emailnewval, "sid" => $sid]);
                        }
                        $forwarddata = $obj->loadSubDomainForwarder(["did" => $_POST["domainid"], "sdid" => $_POST["sdid"], "host" => $subdomain["host"]]);
                        $catchalldata = $obj->loadSubdomainCatchall(["did" => $_POST["domainid"], "sdid" => $_POST["sdid"], "host" => $subdomain["host"]]);
                        $destinationemails = $obj->email->generateSelectOptionsAny($obj->email->emaildestinationdata["confirmedemail"]);
                        echo json_encode(["status" => 1, "destinationemails" => $destinationemails, "catchalloptions" => $catchalldata["options"], "catchallmailto" => $catchalldata["mailto"]]);
                    } else {
                        echo json_encode(["status" => 3]);
                    }
                }
            } else {
                echo json_encode(["status" => 9]);
            }
        }
    } else {
        echo json_encode(["status" => 9]);
    }
} else {
    echo json_encode(["status" => 0]);
}

?>