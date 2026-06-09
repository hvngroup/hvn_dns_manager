<?php
/*
 * @ https://EasyToYou.eu - IonCube v11 Decoder Online
 * @ PHP 7.4
 * @ Decoder version: 1.0.2
 * @ Release: 10/08/2022
 */

// Decoded file for php version 74.
namespace DNSSUITE;

class DNSFunctions extends BaseFunctions
{
    public $pdo;
    public $da;
    public $daconfig;
    public $zonedata;
    public $lastupdate;
    public $connection = false;
    public $debuginfo;
    public function __construct($pdo, $da)
    {
        $this->pdo = $pdo;
        $this->daconfig = $da;
    }
    // @Protected ioncube.dk encoding key.
    private function checkDAConnection()
    {
    }
    public function addDefaultNameservers($did, $vars)
    {
    }
    // @Protected ioncube.dk encoding key.
    public function addRecord()
    {
    }
    // @Protected ioncube.dk encoding key.
    public function getDomains()
    {
    }
    // @Protected ioncube.dk encoding key.
    public function changeTTL()
    {
    }
    // @Protected ioncube.dk encoding key.
    public function changeTTLSubdomain()
    {
    }
    // @Protected ioncube.dk encoding key.
    public function clearZone()
    {
    }
    // @Protected ioncube.dk encoding key.
    public function copyZonetoTemplate()
    {
    }
    // @Protected ioncube.dk encoding key.
    public function deleteDomainDirect()
    {
    }
    // @Protected ioncube.dk encoding key.
    public function deleteDomain()
    {
    }
    public function deleteSubDomain($domain)
    {
        $this->checkDAConnection();
        if($this->da->deleteDomain($domain)) {
            return true;
        }
        return false;
    }
    public function deleteSubDomainLocal($var)
    {
        try {
            $query = $this->pdo->prepare("DELETE FROM mod_dnssuite_subdomains WHERE id = :sdid");
            $query->execute([":sdid" => $var]);
            if(!$this->pdo->inTransaction()) {
                $this->pdo->beginTransaction();
            }
            $this->pdo->commit();
            $query = $this->pdo->prepare("DELETE FROM mod_dnssuite_sd_emailcatchalls WHERE id = :id");
            $query->execute([":id" => $var]);
            if(!$this->pdo->inTransaction()) {
                $this->pdo->beginTransaction();
            }
            $this->pdo->commit();
            $query = $this->pdo->prepare("DELETE FROM mod_dnssuite_sd_emailforwarders WHERE id = :id");
            $query->execute([":id" => $var]);
            if(!$this->pdo->inTransaction()) {
                $this->pdo->beginTransaction();
            }
            $this->pdo->commit();
            $query = $this->pdo->prepare("DELETE FROM mod_dnssuite_sd_redirects WHERE id = :id");
            $query->execute([":id" => $var]);
            if(!$this->pdo->inTransaction()) {
                $this->pdo->beginTransaction();
            }
            $this->pdo->commit();
            return true;
        } catch (PDOException $e) {
            echo $e->getMessage();
            $this->pdo->rollBack();
            echo "Unable delete subdomain from database, please report to technical support";
            return false;
        }
    }
    // @Protected ioncube.dk encoding key.
    public function deleteRecord()
    {
    }
    // @Protected ioncube.dk encoding key.
    public function deleteRecordAdmin()
    {
    }
    // @Protected ioncube.dk encoding key.
    public function fetchDNSTemplate()
    {
    }
    // @Protected ioncube.dk encoding key.
    public function fetchUserDNSTemplate()
    {
    }
    // @Protected ioncube.dk encoding key.
    public function fetchZoneLocal()
    {
    }
    // @Protected ioncube.dk encoding key.
    public function fetchZoneRemote()
    {
    }
    public function isRecordDuplicate($did, $vars)
    {
        $this->fetchZoneLocal($did);
        $zonedata = $this->parseZoneLocal();
        if($vars["mode"] == "A") {
            for ($i = 0; $i < count($zonedata["a"]); $i++) {
                if($vars["host"] == $zonedata["a"][$i][0]) {
                    return true;
                }
            }
        } elseif($vars["mode"] == "CNAME") {
            for ($i = 0; $i < count($zonedata["cname"]); $i++) {
                if($vars["host"] == $zonedata["cname"][$i][0]) {
                    return true;
                }
            }
        } elseif($vars["mode"] == "TXT") {
            for ($i = 0; $i < count($zonedata["txt"]); $i++) {
                if($vars["host"] == $zonedata["txt"][$i][0]) {
                    return true;
                }
            }
        }
        return false;
    }
    public function isRecordOverlimit($did, $vars)
    {
        $this->fetchZoneLocal($did);
        $zonedata = $this->parseZoneLocal();
        if($vars["mode"] == "A" && !empty($zonedata["a"])) {
            if($vars["config"] == 0 || count($zonedata["a"]) < $vars["config"]) {
                return false;
            }
            return true;
        }
        if($vars["mode"] == "MX" && !empty($zonedata["mx"])) {
            if($vars["config"] == 0 || count($zonedata["mx"]) < $vars["config"]) {
                return false;
            }
            return true;
        }
        if($vars["mode"] == "NS" && !empty($zonedata["ns"])) {
            if($vars["config"] == 0 || count($zonedata["ns"]) < $vars["config"]) {
                return false;
            }
            return true;
        }
        if($vars["mode"] == "TXT" && !empty($zonedata["txt"])) {
            if($vars["config"] == 0 || count($zonedata["txt"]) < $vars["config"]) {
                return false;
            }
            return true;
        }
        if($vars["mode"] == "CNAME" && !empty($zonedata["cname"])) {
            if($vars["config"] == 0 || count($zonedata["cname"]) < $vars["config"]) {
                return false;
            }
            return true;
        }
        if($vars["mode"] == "SRV" && !empty($zonedata["srv"])) {
            if($vars["config"] == 0 || count($zonedata["srv"]) < $vars["config"]) {
                return false;
            }
            return true;
        }
        if($vars["mode"] == "AAAA" && !empty($zonedata["aaaa"])) {
            if($vars["config"] == 0 || count($zonedata["aaaa"]) < $vars["config"]) {
                return false;
            }
            return true;
        }
    }
    public function newDomainCreate($did)
    {
        $this->checkDAConnection();
        if($this->da->AddDomain(parent::getDomainfromDID($did))) {
            $this->da->DeleteTemplate(parent::getDomainfromDID($did));
            if($this->daconfig["template"] != "") {
                $this->da->ExtractTemplate(parent::getDomainfromDID($did));
            }
            return true;
        }
        return false;
    }
    public function newSubDomainCreate($did, $host)
    {
        $this->checkDAConnection();
        if($this->da->AddDomain($host . "." . parent::getDomainfromDID($did))) {
            $this->da->DeleteTemplate($host . "." . parent::getDomainfromDID($did));
            if($this->daconfig["template"] != "") {
                $this->da->ExtractTemplate($host . "." . parent::getDomainfromDID($did));
            }
            return true;
        }
        return false;
    }
    public function parseTemplate($vars)
    {
        $zonedata = $vars["templatedata"];
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
        return $zonedata;
    }
    public function parseZoneLocal()
    {
        $zonedata = $this->zonedata;
        if(!empty($zonedata["a"])) {
            for ($i = 0; $i < count($zonedata["a"]); $i++) {
                $zonedata["a"][$i] = explode(" ", $zonedata["a"][$i]);
                $zonedata["a"][$i][] = $i;
            }
        }
        if(!empty($zonedata["aaaa"])) {
            for ($i = 0; $i < count($zonedata["aaaa"]); $i++) {
                $zonedata["aaaa"][$i] = explode(" ", $zonedata["aaaa"][$i]);
                $zonedata["aaaa"][$i][] = $i;
            }
        }
        if(!empty($zonedata["mx"])) {
            for ($i = 0; $i < count($zonedata["mx"]); $i++) {
                $zonedata["mx"][$i] = explode(" ", $zonedata["mx"][$i]);
                $zonedata["mx"][$i][] = $i;
            }
        }
        if(!empty($zonedata["ns"])) {
            for ($i = 0; $i < count($zonedata["ns"]); $i++) {
                $zonedata["ns"][$i] = explode(" ", $zonedata["ns"][$i]);
                $zonedata["ns"][$i][] = $i;
            }
        }
        if(!empty($zonedata["cname"])) {
            for ($i = 0; $i < count($zonedata["cname"]); $i++) {
                $zonedata["cname"][$i] = explode(" ", $zonedata["cname"][$i]);
                $zonedata["cname"][$i][] = $i;
            }
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
        }
        if(!empty($zonedata["srv"])) {
            for ($i = 0; $i < count($zonedata["srv"]); $i++) {
                $zonedata["srv"][$i] = explode(" ", $zonedata["srv"][$i]);
                $zonedata["srv"][$i][] = $i;
            }
        }
        if(!empty($zonedata["soa"])) {
            for ($i = 0; $i < count($zonedata["soa"]); $i++) {
                $zonedata["soa"][$i] = explode(" ", $zonedata["soa"][$i]);
                $zonedata["soa"][$i][] = $i;
            }
        }
        return $zonedata;
    }
    public function removeDefaultNameservers($did)
    {
        $this->checkDAConnection();
        $vars["domain"] = parent::getDomainfromDID($did);
        $vars["zone"] = $zonedata;
        if($this->da->DeleteDefaultNameservers($vars)) {
            return true;
        }
    }
    public function requestSSL($did)
    {
        $this->checkDAConnection();
        if($this->da->RequestSSL(["domain" => parent::getDomainfromDID($did)])) {
            return true;
        }
        return false;
    }
    public function requestSubdomainSSL($vars)
    {
        $sdid = $vars["sdid"];
        $did = $vars["did"];
        $this->checkDAConnection();
        if($this->da->RequestSSL(["domain" => parent::getSubDomainHostnameFromSDID($sdid) . "." . parent::getDomainfromDID($did)])) {
            return true;
        }
        return false;
    }
    public function replaceDomainwithAt($domain)
    {
        $zonedata = $this->zonedata;
        if(!empty($zonedata["a"])) {
            for ($i = 0; $i < count($zonedata["a"]); $i++) {
                $zonedata["a"][$i] = explode(" ", $zonedata["a"][$i]);
                if($zonedata["a"][$i][0] == $domain . ".") {
                    $this->zonedata["a"][$i] = "@ " . $zonedata["a"][$i][1] . " " . $zonedata["a"][$i][2] . " " . $zonedata["a"][$i][3] . " " . $zonedata["a"][$i][4];
                }
            }
        }
        if(!empty($zonedata["aaaa"])) {
            for ($i = 0; $i < count($zonedata["aaaa"]); $i++) {
                $zonedata["aaaa"][$i] = explode(" ", $zonedata["aaaa"][$i]);
                if($zonedata["aaaa"][$i][0] == $domain . ".") {
                    $this->zonedata["aaaa"][$i] = "@ " . $zonedata["aaaa"][$i][1] . " " . $zonedata["aaaa"][$i][2] . " " . $zonedata["aaaa"][$i][3] . " " . $zonedata["aaaa"][$i][4];
                }
            }
        }
        if(!empty($zonedata["mx"])) {
            for ($i = 0; $i < count($zonedata["mx"]); $i++) {
                $zonedata["mx"][$i] = explode(" ", $zonedata["mx"][$i]);
                if($zonedata["mx"][$i][0] == $domain . ".") {
                    $this->zonedata["mx"][$i] = "@ " . $zonedata["mx"][$i][1] . " " . $zonedata["mx"][$i][2] . " " . $zonedata["mx"][$i][3] . " " . $zonedata["mx"][$i][4] . " " . $zonedata["mx"][$i][5];
                }
            }
        }
        if(!empty($zonedata["cname"])) {
            for ($i = 0; $i < count($zonedata["cname"]); $i++) {
                $zonedata["cname"][$i] = explode(" ", $zonedata["cname"][$i]);
                if($zonedata["cname"][$i][0] == $domain . ".") {
                    $this->zonedata["cname"][$i] = "@ " . $zonedata["cname"][$i][1] . " " . $zonedata["cname"][$i][2] . " " . $zonedata["cname"][$i][3] . " " . $zonedata["cname"][$i][4];
                }
            }
        }
        if(!empty($zonedata["txt"])) {
            for ($i = 0; $i < count($zonedata["txt"]); $i++) {
                $zonedata["txt"][$i] = explode(" ", $zonedata["txt"][$i]);
                if($zonedata["txt"][$i][0] == $domain . ".") {
                    $this->zonedata["txt"][$i] = "@ " . $zonedata["txt"][$i][1] . " " . $zonedata["txt"][$i][2] . " " . $zonedata["txt"][$i][3] . " " . $zonedata["txt"][$i][4];
                }
            }
        }
        if(!empty($zonedata["srv"])) {
            for ($i = 0; $i < count($zonedata["srv"]); $i++) {
                $zonedata["srv"][$i] = explode(" ", $zonedata["srv"][$i]);
                if($zonedata["srv"][$i][0] == $domain . ".") {
                    $this->zonedata["srv"][$i] = "@ " . $zonedata["srv"][$i][1] . " " . $zonedata["srv"][$i][2] . " " . $zonedata["srv"][$i][3] . " " . $zonedata["srv"][$i][4];
                }
            }
        }
    }
    public function zonetoDB($zone, $did)
    {
        $domain = parent::getDomainfromDID($did);
        $query = $this->pdo->prepare("SELECT count(*) FROM mod_dnssuite_zones WHERE domain = :domain");
        $query->execute([":domain" => $domain]);
        $query = $query->fetch(\PDO::FETCH_ASSOC);
        if($query["count(*)"] < 1) {
            try {
                $query = $this->pdo->prepare("INSERT INTO mod_dnssuite_zones (relid, domain, records, lastupdate) VALUES (:relid,:domain,:records,:lastupdate)");
                $query->execute([":relid" => $did, ":domain" => idn_to_ascii(strtolower($domain)), ":records" => serialize($zone), ":lastupdate" => time()]);
                if(!$this->pdo->inTransaction()) {
                    $this->pdo->beginTransaction();
                }
                $this->pdo->commit();
            } catch (PDOException $e) {
                echo $e->getMessage();
                $this->pdo->rollBack();
                echo "Unable to add to database, please report to technical support";
            }
        } else {
            try {
                $query = $this->pdo->prepare("UPDATE mod_dnssuite_zones SET records = :records, lastupdate = :lastupdate WHERE domain = :domain ");
                $query->execute([":domain" => $domain, ":records" => serialize($zone), ":lastupdate" => time()]);
                if(!$this->pdo->inTransaction()) {
                    $this->pdo->beginTransaction();
                }
                $this->pdo->commit();
            } catch (PDOException $e) {
                echo $e->getMessage();
                $this->pdo->rollBack();
                echo "Unable to update zone to database, please report to technical support";
            }
        }
    }
    private function emptyZone($did)
    {
        try {
            $query = $this->pdo->prepare("UPDATE mod_dnssuite_zones SET records = \"\" WHERE relid = :did ");
            $query->execute([":did" => $did]);
            if(!$this->pdo->inTransaction()) {
                $this->pdo->beginTransaction();
            }
            $this->pdo->commit();
            unset($this->zonedata);
        } catch (PDOException $e) {
            echo $e->getMessage();
            $this->pdo->rollBack();
            echo "Unable to delete zone from database, please report to technical support";
        }
    }
}
class RedirectFunctions extends BaseFunctions
{
    public $pdo;
    public $da;
    public $daconfig;
    public $redirectdata;
    public $lastupdate;
    public $debuginfo;
    public function __construct($pdo, $da)
    {
        $this->pdo = $pdo;
        $this->daconfig = $da;
        $this->da = new DAFunctions($this->daconfig);
    }
    // @Protected ioncube.dk encoding key.
    private function checkDAConnection()
    {
    }
    public function addRedirectLocal($vars, $data)
    {
        $this->checkDAConnection();
        $this->redirectdata = $data;
        $this->redirecttoDB($vars, $data);
        return true;
    }
    public function addSubDomainRedirectLocal($vars, $data)
    {
        $this->checkDAConnection();
        $this->redirectdata = $data;
        $this->subdomainredirecttoDB($vars, $data);
        return true;
    }
    public function addRedirectRemote($vars)
    {
        $vars["domain"] = parent::getDomainfromDID($vars["did"]);
        if($vars["from"] == "") {
            $vars["from"] = "/";
        }
        if($vars["from"][0] != "/") {
            $vars["from"] = "/" . $vars["from"];
        }
        if($vars["type"] != "301" && $vars["type"] != "302" && $vars["type"] != "303") {
            $vars["type"] = "301";
        }
        if($this->da->AddRedirect($vars)) {
            return true;
        }
        $this->debuginfo = $this->da->debuginfo;
        return false;
    }
    public function addSubDomainRedirectRemote($vars)
    {
        $this->checkDAConnection();
        $vars["domain"] = $vars["host"] . "." . parent::getDomainfromDID($vars["did"]);
        if($vars["from"] == "") {
            $vars["from"] = "/";
        }
        if($vars["from"][0] != "/") {
            $vars["from"] = "/" . $vars["from"];
        }
        if($this->da->AddRedirect($vars)) {
            return true;
        }
        $this->debuginfo = $this->da->debuginfo;
        return false;
    }
    public function addRedirectMaskedRemote($vars)
    {
        $vars["domain"] = parent::getDomainfromDID($vars["did"]);
        if($vars["from"] == "") {
            $vars["from"] = "/";
        }
        if($this->hitServerConnector(["from" => htmlentities($vars["from"]), "to" => htmlentities($vars["to"]), "hash" => $vars["hash"], "domain" => $vars["domain"], "maskedtitle" => $vars["maskedtitle"], "maskedmeta" => $vars["maskedmeta"], "maskedkeywords" => $vars["maskedkeywords"]])) {
            return true;
        }
        return false;
    }
    public function addSubDomainRedirectMaskedRemote($vars)
    {
        $vars["domain"] = $vars["host"] . "." . parent::getDomainfromDID($vars["did"]);
        if($vars["from"] == "") {
            $vars["from"] = "/";
        }
        if($this->hitServerConnector(["from" => htmlentities($vars["from"]), "to" => htmlentities($vars["to"]), "hash" => $vars["hash"], "domain" => $vars["domain"], "maskedtitle" => $vars["maskedtitle"], "maskedmeta" => $vars["maskedmeta"], "maskedkeywords" => $vars["maskedkeywords"]])) {
            return true;
        }
        return false;
    }
    public function checkReplicateRedirect($did, $from)
    {
        if($from == "/") {
            $from = "%2F";
        }
        $query = $this->pdo->prepare("SELECT count(*) FROM mod_dnssuite_redirects WHERE domain = :from AND relid = :did");
        $query->execute([":did" => $did, ":from" => $from]);
        $query = $query->fetch(\PDO::FETCH_ASSOC);
        if(0 < $query["count(*)"]) {
            return true;
        }
        return false;
    }
    public function checkSubDomainReplicateRedirect($sdid, $from)
    {
        if($from == "/") {
            $from = "%2F";
        }
        $query = $this->pdo->prepare("SELECT count(*) FROM mod_dnssuite_sd_redirects WHERE domain = :from AND id = :sdid");
        $query->execute([":sdid" => $sdid, ":from" => $from]);
        $query = $query->fetch(\PDO::FETCH_ASSOC);
        if(0 < $query["count(*)"]) {
            return true;
        }
        return false;
    }
    public function clearRedirectDB($did)
    {
        $query = $this->pdo->prepare("DELETE FROM mod_dnssuite_redirects WHERE relid = :relid");
        $query->execute([":relid" => $did]);
        if(!$this->pdo->inTransaction()) {
            $this->pdo->beginTransaction();
        }
        $this->pdo->commit();
    }
    public function clearSubDomainRedirectDB($sdid)
    {
        $query = $this->pdo->prepare("DELETE FROM mod_dnssuite_sd_redirects WHERE relid = :relid AND type != 999");
        $query->execute([":relid" => $sdid]);
        if(!$this->pdo->inTransaction()) {
            $this->pdo->beginTransaction();
        }
        $this->pdo->commit();
    }
    public function deleteRedirectLocal($rid)
    {
        try {
            $query = $this->pdo->prepare("DELETE from mod_dnssuite_redirects WHERE id = :rid");
            $query->execute([":rid" => $rid]);
            if(!$this->pdo->inTransaction()) {
                $this->pdo->beginTransaction();
            }
            $this->pdo->commit();
        } catch (PDOException $e) {
            echo $e->getMessage();
            $this->pdo->rollBack();
            echo "Unable to remote redirect from database, please report to technical support";
        }
    }
    public function deleteSubDomainRedirectLocal($rid)
    {
        try {
            $query = $this->pdo->prepare("DELETE from mod_dnssuite_sd_redirects WHERE id = :rid");
            $query->execute([":rid" => $rid]);
            if(!$this->pdo->inTransaction()) {
                $this->pdo->beginTransaction();
            }
            $this->pdo->commit();
        } catch (PDOException $e) {
            echo $e->getMessage();
            $this->pdo->rollBack();
            echo "Unable to remote redirect from database, please report to technical support";
        }
    }
    public function deleteRedirectMasked($vars)
    {
        $vars["domain"] = parent::getDomainfromDID($vars["did"]);
        if($vars["from"] == "") {
            $vars["from"] = "/";
        }
        if($vars["from"][0] != "/") {
            $vars["from"] = "/" . $vars["from"];
        }
        if($this->hitServerConnectorDelete(["from" => htmlentities($vars["from"]), "hash" => $vars["hash"], "domain" => $vars["domain"]])) {
            return true;
        }
        return false;
    }
    public function deleteSubDomainRedirectMasked($vars)
    {
        $vars["domain"] = $vars["host"] . "." . parent::getDomainfromDID($vars["did"]);
        if($vars["from"] == "") {
            $vars["from"] = "/";
        }
        if($vars["from"][0] != "/") {
            $vars["from"] = "/" . $vars["from"];
        }
        if($this->hitServerConnectorDelete(["from" => htmlentities($vars["from"]), "hash" => $vars["hash"], "domain" => $vars["domain"]])) {
            return true;
        }
        return false;
    }
    public function deleteRedirectRemote($vars)
    {
        if($vars["from"] != "/") {
            $vars["from"] = "/" . $vars["from"];
        }
        $this->da->DeleteRedirect($vars);
    }
    public function deleteSubDomainRedirectRemote($vars)
    {
        $this->checkDAConnection();
        if($vars["from"] != "/") {
            $vars["from"] = "/" . $vars["from"];
        }
        $this->da->DeleteRedirect($vars);
    }
    public function fetchRedirectLocal($did)
    {
        unset($this->redirectdata);
        $query = $this->pdo->prepare("SELECT count(*) FROM mod_dnssuite_redirects WHERE relid = :did");
        $query->execute([":did" => $did]);
        $query = $query->fetch(\PDO::FETCH_ASSOC);
        if(0 < $query["count(*)"]) {
            $query = $this->pdo->prepare("SELECT * FROM mod_dnssuite_redirects WHERE relid = :did ORDER BY domain");
            $query->execute([":did" => $did]);
            $query = $query->fetchAll(\PDO::FETCH_ASSOC);
            for ($i = 0; $i < count($query); $i++) {
                $this->lastupdate = $query[$i]["lastupdate"];
                $query[$i]["redirect"] = urldecode($query[$i]["redirect"]);
                $query[$i]["domain"] = urldecode($query[$i]["domain"]);
            }
            $this->redirectdata = $query;
        } else {
            $this->fetchRedirectRemote($did);
        }
    }
    public function fetchSubDomainRedirectLocal($vars)
    {
        $sdid = $vars["sdid"];
        $did = $vars["did"];
        $this->checkDAConnection();
        unset($this->redirectdata);
        $query = $this->pdo->prepare("SELECT count(*) FROM mod_dnssuite_sd_redirects WHERE relid = :relid");
        $query->execute([":relid" => $sdid]);
        $query = $query->fetch(\PDO::FETCH_ASSOC);
        if(0 < $query["count(*)"]) {
            $query = $this->pdo->prepare("SELECT * FROM mod_dnssuite_sd_redirects WHERE relid = :relid ORDER BY domain");
            $query->execute([":relid" => $sdid]);
            $query = $query->fetchAll(\PDO::FETCH_ASSOC);
            for ($i = 0; $i < count($query); $i++) {
                $this->lastupdate = $query[$i]["lastupdate"];
                $query[$i]["redirect"] = urldecode($query[$i]["redirect"]);
                $query[$i]["domain"] = urldecode($query[$i]["domain"]);
            }
            $this->redirectdata = $query;
        } else {
            $this->fetchSubDomainRedirectRemote($vars);
        }
    }
    public function fetchRedirectMasked($did)
    {
        $query = $this->pdo->prepare("SELECT * FROM mod_dnssuite_redirects WHERE relid = :did AND type = 999 ORDER BY domain");
        $query->execute([":did" => $did]);
        $query = $query->fetchAll(\PDO::FETCH_ASSOC);
        for ($i = 0; $i < count($query); $i++) {
            $this->lastupdate = $query[$i]["lastupdate"];
            $query[$i]["redirect"] = urldecode($query[$i]["redirect"]);
            $query[$i]["domain"] = urldecode($query[$i]["domain"]);
        }
        $this->redirectdata = array_merge($this->redirectdata, $query);
    }
    public function fetchSubDomainRedirectMasked($sdid)
    {
        $query = $this->pdo->prepare("SELECT * FROM mod_dnssuite_sd_redirects WHERE relid = :relid AND type = 999 ORDER BY domain");
        $query->execute([":relid" => $sdid]);
        $query = $query->fetchAll(\PDO::FETCH_ASSOC);
        for ($i = 0; $i < count($query); $i++) {
            $this->lastupdate = $query[$i]["lastupdate"];
            $query[$i]["redirect"] = urldecode($query[$i]["redirect"]);
            $query[$i]["domain"] = urldecode($query[$i]["domain"]);
        }
        $this->redirectdata = array_merge($this->redirectdata, $query);
    }
    public function fetchRedirectRemote($did)
    {
        $this->checkDAConnection();
        unset($this->redirectdata);
        if($this->redirectdata = $this->da->GetRedirect(parent::getDomainfromDID($did))) {
            $this->redirecttoDB(["did" => $did], $this->redirectdata);
        }
    }
    public function fetchSubDomainRedirectRemote($vars)
    {
        $this->checkDAConnection();
        unset($this->redirectdata);
        if($this->redirectdata = $this->da->GetRedirect($vars["host"] . "." . parent::getDomainfromDID($vars["did"]))) {
            $this->subdomainredirecttoDB($vars, $this->redirectdata);
        }
    }
    public function isRedirectOverlimit($did, $var)
    {
        $this->fetchRedirectLocal($did);
        if(count($this->redirectdata) < $var) {
            return false;
        }
        return true;
    }
    public function isSubDomainRedirectOverlimit($vars, $var)
    {
        $this->fetchSubDomainRedirectLocal($vars);
        if(count($this->redirectdata) < $var) {
            return false;
        }
        return true;
    }
    public function modifyRedirectMasked($vars)
    {
        $vars["domain"] = parent::getDomainfromDID($vars["did"]);
        if($vars["from"] == "") {
            $vars["from"] = "/";
        }
        if($this->hitServerConnectorModify(["from" => htmlentities($vars["from"]), "to" => htmlentities($vars["to"]), "hash" => $vars["hash"], "domain" => $vars["domain"]])) {
            return true;
        }
        return false;
    }
    public function modifySubDomainRedirectMasked($vars)
    {
        $vars["domain"] = $vars["host"] . "." . parent::getDomainfromDID($vars["did"]);
        if($vars["from"] == "") {
            $vars["from"] = "/";
        }
        if($this->hitServerConnectorModify(["from" => htmlentities($vars["from"]), "to" => htmlentities($vars["to"]), "hash" => $vars["hash"], "domain" => $vars["domain"]])) {
            return true;
        }
        return false;
    }
    public function returnRedirectFrom($rid)
    {
        $query = $this->pdo->prepare("SELECT domain FROM mod_dnssuite_redirects WHERE id = :rid");
        $query->execute([":rid" => $rid]);
        $query = $query->fetch(\PDO::FETCH_ASSOC);
        return urldecode($query["domain"]);
    }
    public function returnSubDomainRedirectFrom($rid)
    {
        $query = $this->pdo->prepare("SELECT domain FROM mod_dnssuite_sd_redirects WHERE id = :rid");
        $query->execute([":rid" => $rid]);
        $query = $query->fetch(\PDO::FETCH_ASSOC);
        return urldecode($query["domain"]);
    }
    public function returnRedirectTotal($did)
    {
        $query = $this->pdo->prepare("SELECT count(*) FROM mod_dnssuite_redirects WHERE relid = :id");
        $query->execute([":id" => $did]);
        $query = $query->fetch(\PDO::FETCH_ASSOC);
        return $query["count(*)"];
    }
    public function returnSubDomainRedirectTotal($sdid)
    {
        $query = $this->pdo->prepare("SELECT count(*) FROM mod_dnssuite_sd_redirects WHERE id = :id");
        $query->execute([":id" => $sdid]);
        $query = $query->fetch(\PDO::FETCH_ASSOC);
        return $query["count(*)"];
    }
    public function redirecttoDB($vars, $redirects)
    {
        $did = $vars["did"];
        $domain = parent::getDomainfromDID($did);
        if(!empty($redirects)) {
            for ($i = 0; $i < count($redirects); $i++) {
                if($redirects[$i][0] != "" && $redirects[$i][2] != "") {
                    $query = $this->pdo->prepare("SELECT count(*) FROM mod_dnssuite_redirects WHERE domain = :domain AND relid = :relid");
                    $query->execute([":domain" => urlencode($redirects[$i][0]), ":relid" => $did]);
                    $query = $query->fetch(\PDO::FETCH_ASSOC);
                    if($query["count(*)"] < 1) {
                        try {
                            if($redirects[$i][3] != "301" && $redirects[$i][3] != "302" && $redirects[$i][3] != "303" && $redirects[$i][3] != "999") {
                                $redirects[$i][3] = "301";
                            }
                            if($redirects[$i][0] == "") {
                                $redirects[$i][0] = "/";
                            }
                            if($redirects[$i][3] == "999") {
                                $query = $this->pdo->prepare("INSERT INTO mod_dnssuite_redirects (relid, `type`, domain, redirect, lastupdate, maskeddata) VALUES (:relid,:type,:domain,:redirect,:lastupdate,:maskeddata)");
                                $query->execute([":relid" => $did, ":type" => $redirects[$i][3], ":domain" => urlencode($redirects[$i][0]), ":redirect" => urlencode($redirects[$i][2]), ":lastupdate" => time(), ":maskeddata" => serialize($vars["maskeddata"])]);
                            } else {
                                $query = $this->pdo->prepare("INSERT INTO mod_dnssuite_redirects (relid, `type`, domain, redirect, lastupdate) VALUES (:relid,:type,:domain,:redirect,:lastupdate)");
                                $query->execute([":relid" => $did, ":type" => $redirects[$i][3], ":domain" => urlencode($redirects[$i][0]), ":redirect" => urlencode($redirects[$i][2]), ":lastupdate" => time()]);
                            }
                            if(!$this->pdo->inTransaction()) {
                                $this->pdo->beginTransaction();
                            }
                            $this->pdo->commit();
                            unset($type);
                        } catch (PDOException $e) {
                            echo $e->getMessage();
                            $this->pdo->rollBack();
                            echo "Unable to add to database, please report to technical support";
                        }
                    } else {
                        try {
                            $query = $this->pdo->prepare("UPDATE mod_dnssuite_redirects SET domain = :domain, type = :type, redirect = :redirect, lastupdate = :lastupdate WHERE relid = :relid AND domain = :domain2");
                            $query->execute([":relid" => $did, "type" => $redirects[$i][3], ":domain2" => urlencode($redirects[$i][0]), ":domain" => urlencode($redirects[$i][0]), ":redirect" => urlencode($redirects[$i][2]), ":lastupdate" => time()]);
                            if(!$this->pdo->inTransaction()) {
                                $this->pdo->beginTransaction();
                            }
                            $this->pdo->commit();
                        } catch (PDOException $e) {
                            echo $e->getMessage();
                            $this->pdo->rollBack();
                            echo "Unable to update zone to database, please report to technical support";
                        }
                    }
                }
            }
        }
    }
    public function subdomainredirecttoDB($vars, $redirects)
    {
        $did = $vars["sdid"];
        for ($i = 0; $i < count($redirects); $i++) {
            if($redirects[$i][0] != "" && $redirects[$i][2] != "") {
                $query = $this->pdo->prepare("SELECT count(*) FROM mod_dnssuite_sd_redirects WHERE domain = :domain AND relid = :relid");
                $query->execute([":domain" => urlencode($redirects[$i][0]), ":relid" => $did]);
                $query = $query->fetch(\PDO::FETCH_ASSOC);
                if($query["count(*)"] < 1) {
                    try {
                        if($redirects[$i][3] != "301" && $redirects[$i][3] != "302" && $redirects[$i][3] != "303" && $redirects[$i][3] != "999") {
                            $redirects[$i][3] = "301";
                        }
                        if($redirects[$i][0] == "") {
                            $redirects[$i][0] = "/";
                        }
                        if($redirects[$i][3] == "999") {
                            $query = $this->pdo->prepare("INSERT INTO mod_dnssuite_sd_redirects (relid, `type`, domain, redirect, lastupdate, maskeddata) VALUES (:relid,:type,:domain,:redirect,:lastupdate,:maskeddata)");
                            $query->execute([":relid" => $did, ":type" => $redirects[$i][3], ":domain" => urlencode($redirects[$i][0]), ":redirect" => urlencode($redirects[$i][2]), ":lastupdate" => time(), ":maskeddata" => serialize($vars["maskeddata"])]);
                        } else {
                            $query = $this->pdo->prepare("INSERT INTO mod_dnssuite_sd_redirects (relid, `type`, domain, redirect, lastupdate) VALUES (:relid,:type,:domain,:redirect,:lastupdate)");
                            $query->execute([":relid" => $did, ":type" => $redirects[$i][3], ":domain" => urlencode($redirects[$i][0]), ":redirect" => urlencode($redirects[$i][2]), ":lastupdate" => time()]);
                        }
                        if(!$this->pdo->inTransaction()) {
                            $this->pdo->beginTransaction();
                        }
                        $this->pdo->commit();
                        unset($type);
                    } catch (PDOException $e) {
                        echo $e->getMessage();
                        $this->pdo->rollBack();
                        echo "Unable to add to database, please report to technical support";
                    }
                } else {
                    try {
                        $query = $this->pdo->prepare("UPDATE mod_dnssuite_sd_redirects SET domain = :domain, type = :type, redirect = :redirect, lastupdate = :lastupdate WHERE relid = :relid AND domain = :domain2");
                        $query->execute([":relid" => $did, "type" => $redirects[$i][3], ":domain2" => urlencode($redirects[$i][0]), ":domain" => urlencode($redirects[$i][0]), ":redirect" => urlencode($redirects[$i][2]), ":lastupdate" => time()]);
                        if(!$this->pdo->inTransaction()) {
                            $this->pdo->beginTransaction();
                        }
                        $this->pdo->commit();
                    } catch (PDOException $e) {
                        echo $e->getMessage();
                        $this->pdo->rollBack();
                        echo "Unable to update zone to database, please report to technical support";
                    }
                }
            }
        }
    }
    public function returnRedirectTypefromRID($rid)
    {
        $query = $this->pdo->prepare("SELECT type FROM mod_dnssuite_redirects WHERE id = :rid");
        $query->execute([":rid" => $rid]);
        $query = $query->fetch(\PDO::FETCH_ASSOC);
        return $query["type"];
    }
    public function returnSubDomainRedirectTypefromRID($rid)
    {
        $query = $this->pdo->prepare("SELECT type FROM mod_dnssuite_sd_redirects WHERE id = :rid");
        $query->execute([":rid" => $rid]);
        $query = $query->fetch(\PDO::FETCH_ASSOC);
        return $query["type"];
    }
    public function updateRedirectsLastupdate($did)
    {
        $query = $this->pdo->prepare("UPDATE mod_dnssuite_redirects SET lastupdate = :lastupdate WHERE relid = :relid");
        $query->execute([":relid" => $did, ":lastupdate" => time()]);
        if(!$this->pdo->inTransaction()) {
            $this->pdo->beginTransaction();
        }
        $this->pdo->commit();
    }
    public function updateSubDomainRedirectsLastupdate($sdid)
    {
        $query = $this->pdo->prepare("UPDATE mod_dnssuite_sd_redirects SET lastupdate = :lastupdate WHERE relid = :relid");
        $query->execute([":relid" => $sdid, ":lastupdate" => time()]);
        if(!$this->pdo->inTransaction()) {
            $this->pdo->beginTransaction();
        }
        $this->pdo->commit();
    }
    public function verifyRedirectOwner($did, $rid)
    {
        $query = $this->pdo->prepare("SELECT count(*) FROM mod_dnssuite_redirects WHERE relid = :did AND id = :rid");
        $query->execute([":did" => $did, ":rid" => $rid]);
        $query = $query->fetch(\PDO::FETCH_ASSOC);
        if($query["count(*)"] == 1) {
            return true;
        }
        return false;
    }
    public function verifySubDomainRedirectOwner($sdid, $rid)
    {
        $query = $this->pdo->prepare("SELECT count(*) FROM mod_dnssuite_sd_redirects WHERE relid = :sdid AND id = :rid");
        $query->execute([":sdid" => $sdid, ":rid" => $rid]);
        $query = $query->fetch(\PDO::FETCH_ASSOC);
        if($query["count(*)"] == 1) {
            return true;
        }
        return false;
    }
    private function hitServerConnector($vars)
    {
        $url = $vars["domain"] . "/connector.php";
        $time = time();
        $hash = hash("sha512", $vars["hash"] . $time);
        $postvar = ["domain" => $vars["domain"], "from" => htmlentities($vars["from"]), "to" => htmlentities($vars["to"]), "time" => $time, "hash" => $hash, "title" => htmlentities(strip_tags($vars["maskedtitle"])), "meta" => htmlentities(strip_tags($vars["maskedmeta"])), "keywords" => htmlentities(strip_tags($vars["maskedkeywords"]))];
        $handle = curl_init();
        curl_setopt($handle, CURLOPT_USERAGENT, "WHMCS DNS Suite 1.2");
        curl_setopt($handle, CURLOPT_URL, "http://" . $url);
        curl_setopt($handle, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($handle, CURLOPT_POSTFIELDS, $postvar);
        curl_setopt($handle, CURLOPT_FRESH_CONNECT, true);
        $output = curl_exec($handle);
        curl_close($handle);
        $return = json_decode($output);
        $return = (array) $return;
        if($return["status"] == 1) {
            return true;
        }
        return false;
    }
    private function hitServerConnectorDelete($vars)
    {
        $url = $vars["domain"] . "/connector.php";
        $time = time();
        $hash = hash("sha512", $vars["hash"] . $time);
        $postvar = ["domain" => $vars["domain"], "from" => htmlentities($vars["from"]), "time" => $time, "hash" => $hash, "action" => "delete"];
        $handle = curl_init();
        curl_setopt($handle, CURLOPT_USERAGENT, "WHMCS DNS Provider 1.0");
        curl_setopt($handle, CURLOPT_URL, "http://" . $url);
        curl_setopt($handle, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($handle, CURLOPT_POSTFIELDS, $postvar);
        curl_setopt($handle, CURLOPT_FRESH_CONNECT, true);
        $output = curl_exec($handle);
        curl_close($handle);
        $return = json_decode($output);
        $return = (array) $return;
        if($return["status"] == 1) {
            return true;
        }
        return false;
    }
    private function hitServerConnectorModify($vars)
    {
        $url = $vars["domain"] . "/connector.php";
        $time = time();
        $hash = hash("sha512", $vars["hash"] . $time);
        $postvar = ["domain" => $vars["domain"], "from" => htmlentities($vars["from"]), "to" => htmlentities($vars["to"]), "time" => $time, "hash" => $hash, "action" => "modify"];
        $handle = curl_init();
        curl_setopt($handle, CURLOPT_USERAGENT, "WHMCS DNS Suite 1.2");
        curl_setopt($handle, CURLOPT_URL, "http://" . $url);
        curl_setopt($handle, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($handle, CURLOPT_POSTFIELDS, $postvar);
        curl_setopt($handle, CURLOPT_FRESH_CONNECT, true);
        $output = curl_exec($handle);
        curl_close($handle);
        $return = json_decode($output);
        $return = (array) $return;
        if($return["status"] == 1) {
            return true;
        }
        return false;
    }
}
class EmailFunctions extends BaseFunctions
{
    public $pdo;
    public $da;
    public $daconfig;
    public $catchalldata;
    public $forwarderdata;
    public $emaildestinationdata;
    public $forwarderlimit;
    public $slottotal;
    public $lastupdate;
    public $catchalllastupdate;
    public $debuginfo;
    public function __construct($pdo, $da)
    {
        $this->pdo = $pdo;
        $this->daconfig = $da;
        $this->da = new DAFunctions($this->daconfig);
    }
    // @Protected ioncube.dk encoding key.
    private function checkDAConnection()
    {
    }
    public function addCatchallLocal($did, $mailto)
    {
        $query = $this->pdo->prepare("SELECT count(*) FROM mod_dnssuite_emailcatchalls WHERE relid = :relid");
        $query->execute([":relid" => $did]);
        $query = $query->fetch(\PDO::FETCH_ASSOC);
        if($query["count(*)"] < 1) {
            try {
                $query = $this->pdo->prepare("INSERT INTO mod_dnssuite_emailcatchalls (relid, domain, mailto, status, lastupdate) VALUES (:relid,:domain,:mailto,:status,:lastupdate)");
                $query->execute([":relid" => $did, ":domain" => parent::getDomainfromDID($did), ":mailto" => $mailto, ":status" => 1, ":lastupdate" => time()]);
                if(!$this->pdo->inTransaction()) {
                    $this->pdo->beginTransaction();
                }
                $this->pdo->commit();
                return true;
            } catch (PDOException $e) {
                echo $e->getMessage();
                echo "Unable to add catchall to database, please report to support";
                return false;
            }
        } else {
            try {
                $query = $this->pdo->prepare("UPDATE mod_dnssuite_emailcatchalls set domain = :domain, mailto = :mailto, status = :status, lastupdate = :lastupdate WHERE relid = :relid");
                $query->execute([":relid" => $did, ":domain" => parent::getDomainfromDID($did), ":mailto" => $mailto, ":status" => 1, ":lastupdate" => time()]);
                if(!$this->pdo->inTransaction()) {
                    $this->pdo->beginTransaction();
                }
                $this->pdo->commit();
                return true;
            } catch (PDOException $e) {
                echo $e->getMessage();
                echo "Unable update catchall email, please report to support";
                return false;
            }
        }
    }
    public function addSubDomainCatchallLocal($vars, $mailto)
    {
        $did = $vars["did"];
        $sdid = $vars["sdid"];
        $query = $this->pdo->prepare("SELECT count(*) FROM mod_dnssuite_sd_emailcatchalls WHERE relid = :relid");
        $query->execute([":relid" => $sdid]);
        $query = $query->fetch(\PDO::FETCH_ASSOC);
        if($query["count(*)"] < 1) {
            try {
                $query = $this->pdo->prepare("INSERT INTO mod_dnssuite_sd_emailcatchalls (relid, domain, mailto, status, lastupdate) VALUES (:relid,:domain,:mailto,:status,:lastupdate)");
                $query->execute([":relid" => $sdid, ":domain" => $vars["host"] . "." . parent::getDomainfromDID($did), ":mailto" => $mailto, ":status" => 1, ":lastupdate" => time()]);
                if(!$this->pdo->inTransaction()) {
                    $this->pdo->beginTransaction();
                }
                $this->pdo->commit();
                return true;
            } catch (PDOException $e) {
                echo $e->getMessage();
                echo "Unable to add catchall to database, please report to  support";
                return false;
            }
        } else {
            try {
                $query = $this->pdo->prepare("UPDATE mod_dnssuite_sd_emailcatchalls set domain = :domain, mailto = :mailto, status = :status, lastupdate = :lastupdate WHERE relid = :relid");
                $query->execute([":relid" => $sdid, ":domain" => $vars["host"] . "." . parent::getDomainfromDID($did), ":mailto" => $mailto, ":status" => 1, ":lastupdate" => time()]);
                if(!$this->pdo->inTransaction()) {
                    $this->pdo->beginTransaction();
                }
                $this->pdo->commit();
                return true;
            } catch (PDOException $e) {
                echo $e->getMessage();
                echo "Unable update catchall email, please report to  support";
                return false;
            }
        }
    }
    public function addAliastoDB($did, $alias)
    {
        try {
            $query = $this->pdo->prepare("INSERT INTO mod_dnssuite_emailforwarders (relid, email, lastupdate) VALUES (:relid,:alias,:lastupdate)");
            $query->execute([":relid" => $did, ":alias" => $alias, ":lastupdate" => time()]);
            if(!$this->pdo->inTransaction()) {
                $this->pdo->beginTransaction();
            }
            $this->pdo->commit();
            return true;
        } catch (PDOException $e) {
            echo $e->getMessage();
            $this->pdo->rollBack();
            echo "Unable to add alias to database, please report to technical support";
            return false;
        }
    }
    public function addSubDomainAliastoDB($sdid, $alias)
    {
        try {
            $query = $this->pdo->prepare("INSERT INTO mod_dnssuite_sd_emailforwarders (relid, email, lastupdate) VALUES (:relid,:alias,:lastupdate)");
            $query->execute([":relid" => $sdid, ":alias" => $alias, ":lastupdate" => time()]);
            if(!$this->pdo->inTransaction()) {
                $this->pdo->beginTransaction();
            }
            $this->pdo->commit();
            return true;
        } catch (PDOException $e) {
            echo $e->getMessage();
            $this->pdo->rollBack();
            echo "Unable to add alias to database, please report to technical support";
            return false;
        }
    }
    public function addCatchallRemote($did, $mailto)
    {
        if($this->da->AddCatchall(["domain" => parent::getDomainfromDID($did), "mailto" => $mailto])) {
            return true;
        }
        $this->debuginfo = $this->da->debuginfo;
        return false;
    }
    public function addSubDomainCatchallRemote($vars, $mailto)
    {
        $did = $vars["did"];
        $this->checkDAConnection();
        if($this->da->AddCatchall(["domain" => $vars["host"] . "." . parent::getDomainfromDID($did), "mailto" => $mailto])) {
            return true;
        }
        $this->debuginfo = $this->da->debuginfo;
        return false;
    }
    public function addEmailtoDB($did, $email, $status)
    {
        if($email != "") {
            try {
                $query = $this->pdo->prepare("INSERT INTO mod_dnssuite_emailaddresses (relid, email, status, lastupdate) VALUES (:relid,:email,:status,:lastupdate)");
                $query->execute([":relid" => $did, ":email" => strtolower($email), ":status" => $status, ":lastupdate" => time()]);
                if(!$this->pdo->inTransaction()) {
                    $this->pdo->beginTransaction();
                }
                $this->pdo->commit();
                if($this->sendEmailProcess($did, $email)) {
                    return true;
                }
                return false;
            } catch (PDOException $e) {
                echo $e->getMessage();
                $this->pdo->rollBack();
                echo "Unable to add destination email to database, please report to technical support";
            }
        }
        return false;
    }
    public function addForwarderLocal($did, $vars)
    {
        if($this->forwardertoDB($did, $vars)) {
            return true;
        }
        return false;
    }
    public function addSubDomainForwarderLocal($sdid, $vars)
    {
        $this->checkDAConnection();
        if($this->SubDomainforwardertoDB($sdid, $vars)) {
            return true;
        }
        return false;
    }
    public function addForwarderRemote($vars)
    {
        if($this->da->AddForwarder($vars)) {
            return true;
        }
        $this->debuginfo = $this->da->debuginfo;
        return false;
    }
    public function addSubDomainForwarderRemote($vars)
    {
        $this->checkDAConnection();
        if($this->da->AddForwarder($vars)) {
            return true;
        }
        $this->debuginfo = $this->da->debuginfo;
        return false;
    }
    public function assignForwarder($did, $vars)
    {
        if($this->addForwarderRemote($vars)) {
            if($this->addForwarderLocal($did, $vars)) {
                return true;
            }
            return false;
        }
        return false;
    }
    public function assignSubDomainForwarder($vars)
    {
        $did = $vars["did"];
        $sdid = $vars["sdid"];
        $this->checkDAConnection();
        if($this->addSubDomainForwarderRemote($vars)) {
            if($this->addSubDomainForwarderLocal($sdid, $vars)) {
                return true;
            }
            return false;
        }
        return false;
    }
    public function checkDestinationEmailExist($vars)
    {
        $query = $this->pdo->prepare("SELECT count(*) FROM mod_dnssuite_emailaddresses WHERE relid = :relid AND email = :email");
        $query->execute([":relid" => $vars["did"], ":email" => strtolower($vars["newemail"])]);
        $query = $query->fetch(\PDO::FETCH_ASSOC);
        if($query["count(*)"] < 1) {
            return false;
        }
        return true;
    }
    public function checkEmailInUse($did, $eid)
    {
        $query = $this->pdo->prepare("SELECT email FROM mod_dnssuite_emailaddresses WHERE relid = :relid AND id = :id");
        $query->execute([":relid" => $did, ":id" => $eid]);
        $query = $query->fetch(\PDO::FETCH_ASSOC);
        $email = $query["email"];
        $email = str_replace("+", "\\+", $email);
        $query = $this->pdo->prepare("SELECT mailto FROM mod_dnssuite_emailforwarders WHERE relid = :relid");
        $query->execute([":relid" => $did]);
        $query = $query->fetchAll(\PDO::FETCH_ASSOC);
        for ($i = 0; $i < count($query); $i++) {
            if(preg_match("/" . $email . "/", $query[$i]["mailto"])) {
                return true;
            }
        }
        $query = $this->pdo->prepare("SELECT mailto FROM mod_dnssuite_emailcatchalls WHERE relid = :relid");
        $query->execute([":relid" => $did]);
        $query = $query->fetchAll(\PDO::FETCH_ASSOC);
        for ($i = 0; $i < count($query); $i++) {
            if(preg_match("/" . $email . "/", $query[$i]["mailto"])) {
                return true;
            }
        }
        return false;
    }
    public function cleanEmailVariables($vars)
    {
        if(!empty($vars)) {
            for ($i = 0; $i < count($vars); $i++) {
                unset($vars[$i]["pin"]);
                unset($vars[$i]["lastupdate"]);
            }
        }
        return $vars;
    }
    public function clearEmailDestDB($did)
    {
        $query = $this->pdo->prepare("DELETE FROM mod_dnssuite_emailaddresses WHERE relid = :relid");
        $query->execute([":relid" => $did]);
        if(!$this->pdo->inTransaction()) {
            $this->pdo->beginTransaction();
        }
        $this->pdo->commit();
    }
    public function clearForwarderDB($did)
    {
        $query = $this->pdo->prepare("DELETE FROM mod_dnssuite_emailforwarders WHERE relid = :relid");
        $query->execute([":relid" => $did]);
        if(!$this->pdo->inTransaction()) {
            $this->pdo->beginTransaction();
        }
        $this->pdo->commit();
    }
    public function clearSubDomainForwarderDB($sdid)
    {
        $query = $this->pdo->prepare("DELETE FROM mod_dnssuite_sd_emailforwarders WHERE relid = :relid");
        $query->execute([":relid" => $sdid]);
        if(!$this->pdo->inTransaction()) {
            $this->pdo->beginTransaction();
        }
        $this->pdo->commit();
    }
    public function checkForwarderExist($did, $alias)
    {
        $query = $this->pdo->prepare("SELECT count(*) FROM mod_dnssuite_emailforwarders WHERE relid = :relid AND email = :alias");
        $query->execute([":relid" => $did, ":alias" => $alias]);
        $query = $query->fetch(\PDO::FETCH_ASSOC);
        if($query["count(*)"] < 1) {
            return false;
        }
        return true;
    }
    public function checkSubDomainForwarderExist($sdid, $alias)
    {
        $query = $this->pdo->prepare("SELECT count(*) FROM mod_dnssuite_sd_emailforwarders WHERE relid = :relid AND email = :alias");
        $query->execute([":relid" => $sdid, ":alias" => $alias]);
        $query = $query->fetch(\PDO::FETCH_ASSOC);
        if($query["count(*)"] < 1) {
            return false;
        }
        return true;
    }
    public function convertEmailIDtoAddress($did, $id)
    {
        $query = $this->pdo->prepare("SELECT count(*) FROM mod_dnssuite_emailaddresses WHERE relid = :relid AND id = :id AND status = 1");
        $query->execute([":relid" => $did, ":id" => $id]);
        $query = $query->fetch(\PDO::FETCH_ASSOC);
        if($query["count(*)"] < 1) {
            return false;
        }
        $query = $this->pdo->prepare("SELECT email FROM mod_dnssuite_emailaddresses WHERE relid = :relid AND id = :id AND status = 1");
        $query->execute([":relid" => $did, ":id" => $id]);
        $query = $query->fetch(\PDO::FETCH_ASSOC);
        return $query["email"];
    }
    public function deleteEmailfromDB($did, $id)
    {
        try {
            $query = $this->pdo->prepare("DELETE from mod_dnssuite_emailaddresses WHERE relid = :did AND id = :id");
            $query->execute([":did" => $did, ":id" => $id]);
            if(!$this->pdo->inTransaction()) {
                $this->pdo->beginTransaction();
            }
            $this->pdo->commit();
            return true;
        } catch (PDOException $e) {
            echo $e->getMessage();
            $this->pdo->rollBack();
            echo "Unable to remove email from database, please report to technical support";
        }
    }
    public function deleteCatchallLocal($did)
    {
        try {
            $query = $this->pdo->prepare("UPDATE mod_dnssuite_emailcatchalls SET mailto = :mailto, status = 0 WHERE relid = :did");
            $query->execute([":did" => $did, ":mailto" => ":fail:"]);
            if(!$this->pdo->inTransaction()) {
                $this->pdo->beginTransaction();
            }
            $this->pdo->commit();
            return true;
        } catch (PDOException $e) {
            echo $e->getMessage();
            $this->pdo->rollBack();
            echo "Unable to remove catchall from database, please report to technical support";
        }
    }
    public function deleteSubDomainCatchallLocal($sdid)
    {
        try {
            $query = $this->pdo->prepare("UPDATE mod_dnssuite_sd_emailcatchalls SET mailto = :mailto, status = 0 WHERE relid = :relid");
            $query->execute([":relid" => $sdid, ":mailto" => ":fail:"]);
            if(!$this->pdo->inTransaction()) {
                $this->pdo->beginTransaction();
            }
            $this->pdo->commit();
            return true;
        } catch (PDOException $e) {
            echo $e->getMessage();
            $this->pdo->rollBack();
            echo "Unable to remove catchall from database, please report to technical support";
        }
    }
    public function deleteCatchallRemote($did)
    {
        if($this->da->DisableCatchall(["domain" => parent::getDomainfromDID($did)])) {
            return true;
        }
        $this->debuginfo = $this->da->debuginfo;
        return false;
    }
    public function deleteSubDomainCatchallRemote($vars)
    {
        $did = $vars["did"];
        $this->checkDAConnection();
        if($this->da->DisableCatchall(["domain" => $vars["host"] . "." . parent::getDomainfromDID($did)])) {
            return true;
        }
        $this->debuginfo = $this->da->debuginfo;
        return false;
    }
    public function deleteForwarderLocal($fid)
    {
        try {
            $query = $this->pdo->prepare("DELETE from mod_dnssuite_emailforwarders WHERE id = :fid");
            $query->execute([":fid" => $fid]);
            if(!$this->pdo->inTransaction()) {
                $this->pdo->beginTransaction();
            }
            $this->pdo->commit();
            return true;
        } catch (PDOException $e) {
            echo $e->getMessage();
            $this->pdo->rollBack();
            echo "Unable to forwarder from database, please report to technical support";
        }
    }
    public function deleteSubDomainForwarderLocal($fid)
    {
        try {
            $query = $this->pdo->prepare("DELETE from mod_dnssuite_sd_emailforwarders WHERE id = :fid");
            $query->execute([":fid" => $fid]);
            if(!$this->pdo->inTransaction()) {
                $this->pdo->beginTransaction();
            }
            $this->pdo->commit();
            return true;
        } catch (PDOException $e) {
            echo $e->getMessage();
            $this->pdo->rollBack();
            echo "Unable to forwarder from database, please report to technical support";
        }
    }
    public function deleteForwarderRemote($did, $alias)
    {
        if($this->da->DeleteForwarder(["domain" => parent::getDomainfromDID($did), "alias" => $alias])) {
            return true;
        }
        $this->debuginfo = $this->da->debuginfo;
        return false;
    }
    public function deleteSubDomainForwarderRemote($vars, $alias)
    {
        $did = $vars["did"];
        $this->checkDAConnection();
        if($this->da->DeleteForwarder(["domain" => $vars["host"] . "." . parent::getDomainfromDID($did), "alias" => $alias])) {
            return true;
        }
        $this->debuginfo = $this->da->debuginfo;
        return false;
    }
    public function fetchCatchallLocal($did)
    {
        $query = $this->pdo->prepare("SELECT * FROM mod_dnssuite_emailcatchalls WHERE relid = :relid");
        $query->execute([":relid" => $did]);
        $query = $query->fetch(\PDO::FETCH_ASSOC);
        $this->catchalllastupdate = $query["lastupdate"];
        return $query;
    }
    public function fetchSubDomainCatchallLocal($vars)
    {
        $sdid = $vars["sdid"];
        $query = $this->pdo->prepare("SELECT * FROM mod_dnssuite_sd_emailcatchalls WHERE relid = :relid");
        $query->execute([":relid" => $sdid]);
        $query = $query->fetch(\PDO::FETCH_ASSOC);
        $this->catchalllastupdate = $query["lastupdate"];
        return $query;
    }
    public function fetchCatchallRemote($did)
    {
        if($this->catchalldata = $this->da->GetCatchAll(parent::getDomainfromDID($did))) {
            $this->addCatchallLocal($did, $this->catchalldata);
        }
    }
    public function fetchSubDomainCatchallRemote($vars)
    {
        $did = $vars["did"];
        $this->checkDAConnection();
        if($this->catchalldata = $this->da->GetCatchAll($vars["host"] . "." . parent::getDomainfromDID($did))) {
            $this->addSubDomainCatchallLocal($vars, $this->catchalldata);
        }
    }
    public function fetchForwarderLocal($did)
    {
        unset($this->forwarderdata);
        $query = $this->pdo->prepare("SELECT count(*) FROM mod_dnssuite_emailforwarders WHERE relid = :did");
        $query->execute([":did" => $did]);
        $query = $query->fetch(\PDO::FETCH_ASSOC);
        $this->getEmailDB($did);
        if(0 < $query["count(*)"]) {
            $query = $this->pdo->prepare("SELECT * FROM mod_dnssuite_emailforwarders WHERE relid = :did ORDER BY email");
            $query->execute([":did" => $did]);
            $query = $query->fetchAll(\PDO::FETCH_ASSOC);
            for ($i = 0; $i < count($query); $i++) {
                $this->lastupdate = $query[$i]["lastupdate"];
                $mailto = explode(",", $query[$i]["mailto"]);
                for ($z = 0; $z < count($mailto); $z++) {
                    if($mailto[$z] == "") {
                        unset($mailto[$z]);
                    }
                }
                $options = $this->generateSelectOptions($mailto);
                $row[] = ["alias" => $query[$i]["email"], "id" => $query[$i]["id"], "options" => $options];
            }
            $this->forwarderdata = $row;
            return true;
        }
        return false;
    }
    public function fetchSubDomainForwarderLocal($vars)
    {
        $did = $vars["did"];
        $sdid = $vars["sdid"];
        $this->checkDAConnection();
        unset($this->forwarderdata);
        $query = $this->pdo->prepare("SELECT count(*) FROM mod_dnssuite_sd_emailforwarders WHERE relid = :sdid");
        $query->execute([":sdid" => $sdid]);
        $query = $query->fetch(\PDO::FETCH_ASSOC);
        $this->getEmailDB($did);
        if(0 < $query["count(*)"]) {
            $query = $this->pdo->prepare("SELECT * FROM mod_dnssuite_sd_emailforwarders WHERE relid = :sdid ORDER BY email");
            $query->execute([":sdid" => $sdid]);
            $query = $query->fetchAll(\PDO::FETCH_ASSOC);
            for ($i = 0; $i < count($query); $i++) {
                $this->lastupdate = $query[$i]["lastupdate"];
                $mailto = explode(",", $query[$i]["mailto"]);
                for ($z = 0; $z < count($mailto); $z++) {
                    if($mailto[$z] == "") {
                        unset($mailto[$z]);
                    }
                }
                $options = $this->generateSelectOptions($mailto);
                $row[] = ["alias" => $query[$i]["email"], "id" => $query[$i]["id"], "options" => $options];
            }
            $this->forwarderdata = $row;
            return true;
        }
        return false;
    }
    public function fetchForwarderRemote($did)
    {
        if($this->forwarderdata = $this->da->GetForwarders(parent::getDomainfromDID($did))) {
            $this->forwarderRemotetoDB($did, $this->forwarderdata, 1);
            if(!empty($this->forwarderdata)) {
                for ($i = 0; $i < count($this->forwarderdata); $i++) {
                    $emails = explode(",", $this->forwarderdata[$i]["forwardemail"]);
                    if(!empty($emails)) {
                        for ($z = 0; $z < count($emails); $z++) {
                            if(!$this->checkDestinationEmailExist(["did" => $did, "newemail" => $emails[$z]])) {
                                $this->addEmailtoDB($did, $emails[$z], 1);
                            }
                        }
                    }
                }
            }
        }
    }
    public function fetchSubDomainForwarderRemote($vars)
    {
        $did = $vars["did"];
        $this->checkDAConnection();
        if($this->forwarderdata = $this->da->GetForwarders($vars["host"] . "." . parent::getDomainfromDID($did))) {
            $this->forwarderSubDomainRemotetoDB($vars["sdid"], $this->forwarderdata);
            if(!empty($this->forwarderdata)) {
                for ($i = 0; $i < count($this->forwarderdata); $i++) {
                    $emails = explode(",", $this->forwarderdata[$i]["forwardemail"]);
                    if(!empty($emails)) {
                        for ($z = 0; $z < count($emails); $z++) {
                            if(!$this->checkDestinationEmailExist(["did" => $did, "newemail" => $emails[$z]])) {
                                $this->addEmailtoDB($did, $emails[$z], 1);
                            }
                        }
                    }
                }
            }
        }
    }
    public function generateSelectOptions($mailto)
    {
        if(!empty($this->emaildestinationdata["confirmedemail"])) {
            for ($i = 0; $i < count($this->emaildestinationdata["confirmedemail"]); $i++) {
                unset($skip);
                unset($found);
                if(!empty($mailto)) {
                    for ($z = 0; $z < count($mailto); $z++) {
                        if($this->emaildestinationdata["confirmedemail"][$i]["email"] == $mailto[$z]) {
                            $found = true;
                        }
                    }
                }
                if(!$found) {
                    $options .= "<option value=\"" . $this->emaildestinationdata["confirmedemail"][$i]["id"] . "\">" . $this->emaildestinationdata["confirmedemail"][$i]["email"] . "</option>";
                } else {
                    $options .= "<option value=\"" . $this->emaildestinationdata["confirmedemail"][$i]["id"] . "\" selected=\"selected\">" . $this->emaildestinationdata["confirmedemail"][$i]["email"] . "</option>";
                }
            }
        }
        return $options;
    }
    public function generateSelectOptionsAny($vars)
    {
        if(!empty($vars)) {
            for ($i = 0; $i < count($vars); $i++) {
                $returnemails .= "<option value=\"" . $vars[$i]["id"] . "\">" . $vars[$i]["email"] . "</option>";
            }
        }
        return $returnemails;
    }
    public function getEmailDB($did)
    {
        unset($this->slottotal);
        unset($this->emaildestinationdata);
        $this->slottotal = 0;
        $query = $this->pdo->prepare("SELECT * FROM mod_dnssuite_emailaddresses WHERE relid = :relid ORDER BY email");
        $query->execute([":relid" => $did]);
        $query = $query->fetchALL(\PDO::FETCH_ASSOC);
        for ($i = 0; $i < count($query); $i++) {
            $this->slottotal++;
            if($query[$i]["status"] == 0) {
                $this->emaildestinationdata["pendingemail"][] = $query[$i];
            }
            if($query[$i]["status"] == 1) {
                $this->emaildestinationdata["confirmedemail"][] = $query[$i];
            }
        }
    }
    public function returnCatchallStatus($did)
    {
    }
    public function returnTotalForwarders($did)
    {
        $query = $this->pdo->prepare("SELECT count(*) FROM mod_dnssuite_emailforwarders WHERE relid = :relid");
        $query->execute([":relid" => $did]);
        $query = $query->fetch(\PDO::FETCH_ASSOC);
        return $query["count(*)"];
    }
    public function returnForwarderAlias($fid)
    {
        $query = $this->pdo->prepare("SELECT email FROM mod_dnssuite_emailforwarders WHERE id = :fid");
        $query->execute([":fid" => $fid]);
        $query = $query->fetch(\PDO::FETCH_ASSOC);
        return $query["email"];
    }
    public function returnSubDomainForwarderAlias($fid)
    {
        $query = $this->pdo->prepare("SELECT email FROM mod_dnssuite_sd_emailforwarders WHERE id = :fid");
        $query->execute([":fid" => $fid]);
        $query = $query->fetch(\PDO::FETCH_ASSOC);
        return $query["email"];
    }
    public function returnSubDomainTotalForwarders($sdid)
    {
        $query = $this->pdo->prepare("SELECT count(*) FROM mod_dnssuite_sd_emailforwarders WHERE relid = :relid");
        $query->execute([":relid" => $sdid]);
        $query = $query->fetch(\PDO::FETCH_ASSOC);
        return $query["count(*)"];
    }
    public function sendEmailProcess($did, $email)
    {
        $profileid = $this->checkEmailExist($email);
        if(!$profileid) {
            $tempvar = ["email" => $email];
            $oldsession = $_SESSION;
            $newid = $this->createNewProfile($tempvar);
            $pin = $this->generatePin();
            $result = $this->sendEmail($newid, ["pin" => $pin, "did" => $did]);
            $this->deleteProfile($newid);
            $_SESSION = $oldsession;
        } else {
            $pin = $this->generatePin();
            $result = $this->sendEmail($profileid, ["pin" => $pin, "did" => $did]);
        }
        if($result) {
            $query = $this->pdo->prepare("UPDATE mod_dnssuite_emailaddresses SET pin = :pin WHERE relid = :relid AND email = :email");
            $query->execute([":relid" => $did, ":pin" => $pin, ":email" => $email]);
            if(!$this->pdo->inTransaction()) {
                $this->pdo->beginTransaction();
            }
            $this->pdo->commit();
            return true;
        }
        return false;
    }
    public function updateEmailStatus($id, $status)
    {
        try {
            $query = $this->pdo->prepare("UPDATE mod_dnssuite_emailaddresses SET status = :status, lastupdate = :lastupdate WHERE id = :id ");
            $query->execute([":status" => $status, ":id" => $id, ":lastupdate" => time()]);
            if(!$this->pdo->inTransaction()) {
                $this->pdo->beginTransaction();
            }
            $this->pdo->commit();
            return true;
        } catch (PDOException $e) {
            echo $e->getMessage();
            $this->pdo->rollBack();
            echo "Unable to update email status, please report to technical support";
            return false;
        }
    }
    public function verifyForwarderOwner($did, $id)
    {
        $query = $this->pdo->prepare("SELECT count(*) FROM mod_dnssuite_emailforwarders WHERE relid = :did AND id = :id");
        $query->execute([":did" => $did, ":id" => $id]);
        $query = $query->fetch(\PDO::FETCH_ASSOC);
        if($query["count(*)"] == 1) {
            return true;
        }
        return false;
    }
    public function verifyEmailOwner($did, $id)
    {
        $query = $this->pdo->prepare("SELECT count(*) FROM mod_dnssuite_emailaddresses WHERE relid = :did AND id = :id");
        $query->execute([":did" => $did, ":id" => $id]);
        $query = $query->fetch(\PDO::FETCH_ASSOC);
        if($query["count(*)"] == 1) {
            return true;
        }
        return false;
    }
    public function verifySubDomainForwarderOwner($sdid, $id)
    {
        $query = $this->pdo->prepare("SELECT count(*) FROM mod_dnssuite_sd_emailforwarders WHERE relid = :sdid AND id = :id");
        $query->execute([":sdid" => $sdid, ":id" => $id]);
        $query = $query->fetch(\PDO::FETCH_ASSOC);
        if($query["count(*)"] == 1) {
            return true;
        }
        return false;
    }
    public function updateForwardersLastupdate($did)
    {
        $query = $this->pdo->prepare("UPDATE mod_dnssuite_emailforwarders SET lastupdate = :lastupdate WHERE relid = :relid");
        $query->execute([":relid" => $did, ":lastupdate" => time()]);
        if(!$this->pdo->inTransaction()) {
            $this->pdo->beginTransaction();
        }
        $this->pdo->commit();
    }
    public function updateSubDomainForwardersLastupdate($sdid)
    {
        $query = $this->pdo->prepare("UPDATE mod_dnssuite_sd_emailforwarders SET lastupdate = :lastupdate WHERE relid = :relid");
        $query->execute([":relid" => $sdid, ":lastupdate" => time()]);
        if(!$this->pdo->inTransaction()) {
            $this->pdo->beginTransaction();
        }
        $this->pdo->commit();
    }
    public function updateCatchallemail($did, $mailto)
    {
        $var = $this->returnCatchallStatus($did);
        if($var["relid"] == $did) {
            try {
                $query = $this->pdo->prepare("UPDATE mod_dnssuite_emailcatchalls set domain = :domain, mailto = :mailto, status = :status, lastupdate = :lastupdate WHERE relid = :relid");
                $query->execute([":relid" => $did, ":domain" => parent::getDomainfromDID($did), ":mailto" => $mailto, ":status" => 1, ":lastupdate" => time()]);
                if(!$this->pdo->inTransaction()) {
                    $this->pdo->beginTransaction();
                }
                $this->pdo->commit();
                return true;
            } catch (PDOException $e) {
                echo $e->getMessage();
                echo "Unable update catchall email, please report to technical support";
                return false;
            }
        } else {
            try {
                $query = $this->pdo->prepare("INSERT INTO mod_dnssuite_emailcatchalls (relid, domain, mailto, status, lastupdate) VALUES (:relid,:domain,:to,:status,:lastupdate)");
                $query->execute([":relid" => $did, ":domain" => parent::getDomainfromDID($did), ":to" => $mailto, ":status" => 1, ":lastupdate" => time()]);
                if(!$this->pdo->inTransaction()) {
                    $this->pdo->beginTransaction();
                }
                $this->pdo->commit();
                return true;
            } catch (PDOException $e) {
                echo $e->getMessage();
                echo "Unable to add catchall to database, please report to technical support";
                return false;
            }
        }
    }
    private function forwarderRemotetoDB($did, $vars)
    {
        for ($i = 0; $i < count($vars); $i++) {
            $query = $this->pdo->prepare("SELECT count(*) FROM mod_dnssuite_emailforwarders WHERE relid = :relid AND email = :alias");
            $query->execute([":relid" => $did, ":alias" => $vars[$i]["alias"]]);
            $query = $query->fetch(\PDO::FETCH_ASSOC);
            if($vars[$i]["forwardemail"] != "") {
                if($query["count(*)"] < 1) {
                    try {
                        $query = $this->pdo->prepare("INSERT INTO mod_dnssuite_emailforwarders (relid, email, mailto, lastupdate) VALUES (:relid,:alias, :mailto ,:lastupdate)");
                        $query->execute([":relid" => $did, ":alias" => $vars[$i]["alias"], ":mailto" => $vars[$i]["forwardemail"], ":lastupdate" => time()]);
                        if(!$this->pdo->inTransaction()) {
                            $this->pdo->beginTransaction();
                        }
                        $this->pdo->commit();
                    } catch (PDOException $e) {
                        echo $e->getMessage();
                        $this->pdo->rollBack();
                        echo "Unable to add forwarder to database via Remote, please report to technical support";
                    }
                } else {
                    try {
                        $query = $this->pdo->prepare("UPDATE mod_dnssuite_emailforwarders SET mailto = :mailto, lastupdate = :lastupdate WHERE relid = :relid AND email = :alias");
                        $query->execute([":relid" => $did, ":alias" => $vars[$i]["alias"], ":mailto" => $vars[$i]["forwardemail"], ":lastupdate" => time()]);
                        if(!$this->pdo->inTransaction()) {
                            $this->pdo->beginTransaction();
                        }
                        $this->pdo->commit();
                    } catch (PDOException $e) {
                        echo $e->getMessage();
                        $this->pdo->rollBack();
                        echo "Unable to update forwarder to database via Remote, please report to technical support";
                    }
                }
            }
        }
    }
    private function forwarderSubDomainRemotetoDB($sdid, $vars)
    {
        $did = $sdid;
        for ($i = 0; $i < count($vars); $i++) {
            $query = $this->pdo->prepare("SELECT count(*) FROM mod_dnssuite_sd_emailforwarders WHERE relid = :relid AND email = :alias");
            $query->execute([":relid" => $did, ":alias" => $vars[$i]["alias"]]);
            $query = $query->fetch(\PDO::FETCH_ASSOC);
            if($vars[$i]["forwardemail"] != "") {
                if($query["count(*)"] < 1) {
                    try {
                        $query = $this->pdo->prepare("INSERT INTO mod_dnssuite_sd_emailforwarders (relid, email, mailto, lastupdate) VALUES (:relid,:alias, :mailto ,:lastupdate)");
                        $query->execute([":relid" => $did, ":alias" => $vars[$i]["alias"], ":mailto" => $vars[$i]["forwardemail"], ":lastupdate" => time()]);
                        if(!$this->pdo->inTransaction()) {
                            $this->pdo->beginTransaction();
                        }
                        $this->pdo->commit();
                    } catch (PDOException $e) {
                        echo $e->getMessage();
                        $this->pdo->rollBack();
                        echo "Unable to add forwarder to database via Remote, please report to technical support";
                    }
                } else {
                    try {
                        $query = $this->pdo->prepare("UPDATE mod_dnssuite_sd_emailforwarders SET mailto = :mailto, lastupdate = :lastupdate WHERE relid = :relid AND email = :alias");
                        $query->execute([":relid" => $did, ":alias" => $vars[$i]["alias"], ":mailto" => $vars[$i]["forwardemail"], ":lastupdate" => time()]);
                        if(!$this->pdo->inTransaction()) {
                            $this->pdo->beginTransaction();
                        }
                        $this->pdo->commit();
                    } catch (PDOException $e) {
                        echo $e->getMessage();
                        $this->pdo->rollBack();
                        echo "Unable to update forwarder to database via Remote, please report to technical support";
                    }
                }
            }
        }
    }
    private function forwardertoDB($did, $vars)
    {
        $query = $this->pdo->prepare("SELECT count(*) FROM mod_dnssuite_emailforwarders WHERE relid = :relid AND email = :alias");
        $query->execute([":relid" => $did, ":alias" => $vars["alias"]]);
        $query = $query->fetch(\PDO::FETCH_ASSOC);
        if($vars["mailto"] != "") {
            if($query["count(*)"] < 1) {
                try {
                    $query = $this->pdo->prepare("INSERT INTO mod_dnssuite_emailforwarders (relid, email, mailto, lastupdate) VALUES (:relid,:alias,:mailto,:lastupdate)");
                    $query->execute([":relid" => $did, ":alias" => $vars["alias"], ":mailto" => $vars["mailto"], ":lastupdate" => time()]);
                    if(!$this->pdo->inTransaction()) {
                        $this->pdo->beginTransaction();
                    }
                    $this->pdo->commit();
                    return true;
                } catch (PDOException $e) {
                    echo $e->getMessage();
                    $this->pdo->rollBack();
                    echo "Unable to add forwarder to database, please report to technical support";
                    return false;
                }
            } else {
                try {
                    $query = $this->pdo->prepare("UPDATE mod_dnssuite_emailforwarders SET mailto = :mailto, lastupdate = :lastupdate WHERE relid = :relid AND email = :alias");
                    $query->execute([":relid" => $did, ":alias" => $vars[$i]["alias"], ":mailto" => $vars["mailto"], ":lastupdate" => time()]);
                    if(!$this->pdo->inTransaction()) {
                        $this->pdo->beginTransaction();
                    }
                    $this->pdo->commit();
                    return true;
                } catch (PDOException $e) {
                    echo $e->getMessage();
                    $this->pdo->rollBack();
                    echo "Unable to update forwarder to database, please report to technical support";
                    return false;
                }
            }
        }
    }
    private function SubDomainforwardertoDB($sdid, $vars)
    {
        $query = $this->pdo->prepare("SELECT count(*) FROM mod_dnssuite_sd_emailforwarders WHERE relid = :relid AND email = :alias");
        $query->execute([":relid" => $sdid, ":alias" => $vars["alias"]]);
        $query = $query->fetch(\PDO::FETCH_ASSOC);
        if($vars["mailto"] != "") {
            if($query["count(*)"] < 1) {
                try {
                    $query = $this->pdo->prepare("INSERT INTO mod_dnssuite_sd_emailforwarders (relid, email, mailto, lastupdate) VALUES (:relid,:alias,:mailto,:lastupdate)");
                    $query->execute([":relid" => $sdid, ":alias" => $vars["alias"], ":mailto" => $vars["mailto"], ":lastupdate" => time()]);
                    if(!$this->pdo->inTransaction()) {
                        $this->pdo->beginTransaction();
                    }
                    $this->pdo->commit();
                    return true;
                } catch (PDOException $e) {
                    echo $e->getMessage();
                    $this->pdo->rollBack();
                    echo "Unable to add forwarder to database, please report to technical support";
                    return false;
                }
            } else {
                try {
                    $query = $this->pdo->prepare("UPDATE mod_dnssuite_sd_emailforwarders SET mailto = :mailto, lastupdate = :lastupdate WHERE relid = :relid AND email = :alias");
                    $query->execute([":relid" => $sdid, ":alias" => $vars[$i]["alias"], ":mailto" => $vars["mailto"], ":lastupdate" => time()]);
                    if(!$this->pdo->inTransaction()) {
                        $this->pdo->beginTransaction();
                    }
                    $this->pdo->commit();
                    return true;
                } catch (PDOException $e) {
                    echo $e->getMessage();
                    $this->pdo->rollBack();
                    echo "Unable to update forwarder to database, please report to technical support";
                    return false;
                }
            }
        }
    }
    private function createNewProfile($vars)
    {
        $command = "AddClient";
        $postData = ["firstname" => "Email", "lastname" => "Verification", "email" => $vars["email"], "address1" => "PlaceHolder", "city" => "PlaceHolder", "state" => "ST", "postcode" => "12345", "country" => "US", "phonenumber" => "800-555-1234", "password2" => "password", "noemail" => true, "skipvalidation" => true];
        $adminUsername = $this->configs["apiuser"];
        $results = localAPI($command, $postData, $adminUsername);
        $tempuserid = $results["clientid"];
        return $tempuserid;
    }
    private function deleteProfile($uid)
    {
        $query = $this->pdo->prepare("SELECT email FROM tblclients WHERE id = :uid");
        $query->execute([":uid" => $uid]);
        $query = $query->fetch(\PDO::FETCH_ASSOC);
        $email = $query["email"];
        $command = "DeleteClient";
        $postData = ["clientid" => $uid, "deleteusers" => true];
        $results = localAPI($command, $postData);
        $query = $this->pdo->prepare("SELECT count(*) FROM tblusers WHERE email = :email");
        $query->execute([":email" => $email]);
        $query = $query->fetch(\PDO::FETCH_ASSOC);
        if(0 < $query["count(*)"]) {
            $query = $this->pdo->prepare("DELETE FROM tblusers WHERE email = :email");
            $query->execute([":email" => $email]);
            if(!$this->pdo->inTransaction()) {
                $this->pdo->beginTransaction();
            }
            $this->pdo->commit();
        }
    }
    private function checkEmailExist($email)
    {
        try {
            $query = $this->pdo->prepare("SELECT id FROM tblclients WHERE email = :email");
            $query->execute([":email" => strtolower($email)]);
            $query = $query->fetch(\PDO::FETCH_ASSOC);
            if($query["id"] == "") {
                return false;
            }
            return $query["id"];
        } catch (PDOException $e) {
            echo "Can't check if email account already exist";
        }
    }
    private function generatePin()
    {
        if($this->codeStyle == 0) {
            $chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";
            $len = 62;
        } elseif($this->codeStyle == 1) {
            $chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
            $len = 36;
        } elseif($this->codeStyle == 2) {
            $chars = "abcdefghijklmnopqrstuvwxyz0123456789";
            $len = 36;
        } elseif($this->codeStyle == 3) {
            $chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz";
            $len = 52;
        } elseif($this->codeStyle == 4) {
            $chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
            $len = 26;
        } elseif($this->codeStyle == 5) {
            $chars = "abcdefghijklmnopqrstuvwxyz";
            $len = 26;
        } elseif($this->codeStyle == 6) {
            $chars = "0123456789";
            $len = 10;
        } else {
            $chars = "0123456789";
            $len = 10;
        }
        srand((double) microtime() * 1000000);
        $i = 0;
        for ($pass = ""; $i < 11; $i++) {
            $num = rand() % $len;
            $tmp = substr($chars, $num, 1);
            $pass = $pass . $tmp;
        }
        return $pass;
    }
    private function sendEmail($clientid, $vars)
    {
        $query = $this->pdo->prepare("SELECT value FROM tbladdonmodules WHERE module = 'dnssuite' AND setting = :setting");
        $query->execute([":setting" => "apiuser"]);
        $query = $query->fetch(\PDO::FETCH_ASSOC);
        $apiuser = $query["value"];
        $query = $this->pdo->prepare("SELECT value FROM tbladdonmodules WHERE module = 'dnssuite' AND setting = :setting");
        $query->execute([":setting" => "templateemailverify"]);
        $query = $query->fetch(\PDO::FETCH_ASSOC);
        $templatename = $query["value"];
        $domain = $this->getDomainfromDID($vars["did"]);
        $command = "SendEmail";
        $postData = ["messagename" => $templatename, "id" => $clientid, "customvars" => ["pin" => $vars["pin"], "domain" => $domain]];
        if($apiuser != "") {
            $adminUsername = $apiuser;
        }
        $results = localAPI($command, $postData, $adminUsername);
        if($results["result"] == "success") {
            return true;
        }
        return false;
    }
    private function updatePin($did, $pin)
    {
    }
}
class Suite_AdminArea
{
    public $pdo;
    public $basic;
    public $dns;
    public $did;
    public $redirect;
    public $email;
    public $domain;
    public $dnstemplates;
    public $oldvalues;
    public $debuginfo;
    public function __construct($pdo)
    {
        $this->pdo = $pdo;
        $this->basic = new BaseFunctions($this->pdo);
        $this->dns = new DNSFunctions($this->pdo, $this->basic->daconfigs);
        $this->redirect = new RedirectFunctions($this->pdo, $this->basic->daconfigs);
        $this->email = new EmailFunctions($this->pdo, $this->basic->daconfigs);
        if($this->basic->configs["subaccountrestriction"] == "on" && isset($_SESSION[""]) && $this->checkSubAccountPermission()) {
            return false;
        }
    }
    // @Protected ioncube.dk encoding key.
    public function addAlias()
    {
    }
    // @Protected ioncube.dk encoding key.
    public function addSubDomainAlias()
    {
    }
    // @Protected ioncube.dk encoding key.
    public function addDNSTemplate()
    {
    }
    // @Protected ioncube.dk encoding key.
    public function addRecord()
    {
    }
    // @Protected ioncube.dk encoding key.
    public function addRedirect()
    {
    }
    public function addSubDomainRedirect($vars)
    {
        if($vars["from"] == "") {
            $vars["from"] = "/";
        }
        $vars["to"] = idn_to_ascii($vars["to"]);
        if(!$this->redirect->checkSubDomainReplicateRedirect($vars["sdid"], $vars["from"])) {
            if($vars["type"] == 999) {
                if($this->redirect->addSubDomainRedirectMaskedRemote(["did" => $vars["did"], "host" => $vars["host"], "from" => $vars["from"], "to" => $vars["to"], "hash" => $this->basic->configs["maskedhash"], "maskedtitle" => $vars["maskedtitle"], "maskedmeta" => $vars["maskedmeta"], "maskedkeywords" => $vars["maskedkeywords"]])) {
                    $newarray[] = [$vars["from"], 2 => $vars["to"], 3 => $vars["type"]];
                    $vars["maskeddata"] = ["maskedtitle" => htmlentities($vars["maskedtitle"]), "maskedmeta" => htmlentities($vars["maskedmeta"]), "maskedkeywords" => htmlentities($vars["maskedkeywords"])];
                    if($this->redirect->addSubDomainRedirectLocal($vars, $newarray)) {
                        $this->redirect->fetchSubDomainRedirectRemote($vars);
                        $this->redirect->fetchSubDomainRedirectMasked($vars["sdid"]);
                        return true;
                    }
                    $this->debuginfo = $this->redirect->debuginfo;
                    return false;
                }
                $this->debuginfo = $this->redirect->debuginfo;
                return false;
            }
            if($this->redirect->addSubDomainRedirectRemote(["did" => $vars["did"], "from" => $vars["from"], "to" => $vars["to"], "type" => $vars["type"], "host" => $vars["host"]])) {
                $newarray[] = [$vars["from"], 2 => $vars["to"], 3 => $vars["type"]];
                if($this->redirect->addSubDomainRedirectLocal($vars, $newarray)) {
                    $this->redirect->fetchSubDomainRedirectRemote($vars);
                    $this->redirect->fetchSubDomainRedirectMasked($vars["sdid"]);
                    return true;
                }
                $this->debuginfo = $this->redirect->debuginfo;
                return false;
            }
            $this->debuginfo = $this->redirect->debuginfo;
            return false;
        }
        $this->debuginfo = $this->redirect->debuginfo;
        return false;
    }
    // @Protected ioncube.dk encoding key.
    public function checkDomainExist()
    {
    }
    public function checkHostnameExist($vars)
    {
        $zonedata = $this->loadDomain($vars["did"]);
        if(!empty($zonedata["a"])) {
            for ($i = 0; $i < count($zonedata["a"]); $i++) {
                $zonedata["a"][$i] = explode(" ", $zonedata["a"][$i]);
                if($zonedata["a"][$i][0] == $vars["hostname"]) {
                    return true;
                }
            }
        }
        if(!empty($zonedata["cname"])) {
            for ($i = 0; $i < count($zonedata["cname"]); $i++) {
                $zonedata["cname"][$i] = explode(" ", $zonedata["cname"][$i]);
                if($zonedata["cname"][$i][0] == $vars["hostname"]) {
                    return true;
                }
            }
        }
        if(!empty($zonedata["aaaa"])) {
            for ($i = 0; $i < count($zonedata["aaaa"]); $i++) {
                $zonedata["aaaa"][$i] = explode(" ", $zonedata["aaaa"][$i]);
                if($zonedata["aaaa"][$i][0] == $vars["hostname"]) {
                    return true;
                }
            }
        }
        return false;
    }
    public function checkSubDomainExist($vars)
    {
        $did = $vars["did"];
        $host = $vars["host"];
        $domains = $this->dns->getDomains();
        $this->did = $did;
        $subdomain = $host . "." . $this->basic->getDomainfromDID($did);
        if(!in_array($subdomain, $domains)) {
            if($this->dns->newSubDomainCreate($did, $host)) {
                $this->dns->changeTTLSubdomain(["did" => $did, "host" => $host], $this->basic->configs["defaultttl"]);
            } else {
                return false;
            }
        }
        $query = $this->pdo->prepare("SELECT count(*) FROM mod_dnssuite_subdomains WHERE host = :hostname AND relid = :relid");
        $query->execute([":hostname" => $host, ":relid" => $did]);
        $query = $query->fetch(\PDO::FETCH_ASSOC);
        if(0 < $query["count(*)"]) {
            return true;
        }
        $query = $this->pdo->prepare("INSERT INTO mod_dnssuite_subdomains (relid, host) VALUES (:relid, :hostname)");
        $query->execute([":relid" => $did, ":hostname" => $host]);
        if(!$this->pdo->inTransaction()) {
            $this->pdo->beginTransaction();
        }
        $this->pdo->commit();
        return true;
    }
    // @Protected ioncube.dk encoding key.
    public function checkDuplicateTemplateName()
    {
    }
    // @Protected ioncube.dk encoding key.
    public function clearDNS()
    {
    }
    // @Protected ioncube.dk encoding key.
    public function deleteDomainDirect()
    {
    }
    public function deleteSubDomainDirect($vars)
    {
        $did = $vars["did"];
        $sdid = $vars["sdid"];
        $host = $vars["host"];
        $domain = $this->basic->getDomainfromDID($did);
        if($this->dns->deleteDomainDirect($host . "." . $domain)) {
            $this->subdomaindeleteProcess($sdid);
            logModuleCall("DNSSuite", "Delete subdomain from DA Server", "SubdomainDomain: " . $host . "." . idn_to_ascii($domain), $result, $processedData, $replaceVars);
            return true;
        }
        $this->debuginfo = $this->dns->debuginfo;
        return false;
    }
    // @Protected ioncube.dk encoding key.
    public function deleteEmail()
    {
    }
    // @Protected ioncube.dk encoding key.
    public function deleteForwarder()
    {
    }
    public function deleteSubDomainForwarder($vars, $fid)
    {
        $did = $vars["did"];
        $sdid = $vars["sdid"];
        if($this->email->verifySubDomainForwarderOwner($sdid, $fid)) {
            $query = $this->pdo->prepare("SELECT * FROM mod_dnssuite_sd_emailforwarders WHERE id = :fid");
            $query->execute([":fid" => $fid]);
            $query = $query->fetch(\PDO::FETCH_ASSOC);
            $alias = $query["email"];
            $this->oldvalues["oldmailto"] = $query["mailto"];
            $this->oldvalues["alias"] = $query["email"];
            if($this->email->deleteSubDomainForwarderRemote($vars, $alias)) {
                if(!$this->email->deleteSubDomainForwarderLocal($fid)) {
                    $this->debuginfo = $this->email->debuginfo;
                    return false;
                }
                $this->email->updateSubDomainForwardersLastupdate($sdid);
                return true;
            }
        } else {
            $this->debuginfo = $this->email->debuginfo;
            return false;
        }
    }
    // @Protected ioncube.dk encoding key.
    public function deleteRedirect()
    {
    }
    // @Protected ioncube.dk encoding key.
    public function deleteSubDomainRedirect()
    {
    }
    // @Protected ioncube.dk encoding key.
    public function deleteSubDomainRedirectMasked()
    {
    }
    // @Protected ioncube.dk encoding key.
    public function deleteRecord()
    {
    }
    public function deleteSubDomain($vars)
    {
        $subdomaindata = $this->basic->returnSubDomainFromSDID($vars["sdid"]);
        $subdomain = $subdomaindata["host"] . "." . $this->basic->getDomainfromDID($vars["did"]);
        if($this->dns->deleteSubDomain($subdomain)) {
            if($this->dns->deleteSubDomainLocal($vars["sdid"])) {
                return true;
            }
            $this->debuginfo = $this->dns->debuginfo;
            return false;
        }
        $this->debuginfo = $this->dns->debuginfo;
        return false;
    }
    // @Protected ioncube.dk encoding key.
    public function deleteSystemDNSTemplate()
    {
    }
    // @Protected ioncube.dk encoding key.
    public function disableCatchall()
    {
    }
    // @Protected ioncube.dk encoding key.
    public function disableSubDomainCatchall()
    {
    }
    // @Protected ioncube.dk encoding key.
    public function generateDomainsArray()
    {
    }
    // @Protected ioncube.dk encoding key.
    public function getSystemTemplate()
    {
    }
    // @Protected ioncube.dk encoding key.
    public function getUserTemplate()
    {
    }
    public function generateAJAXVARS($vars)
    {
        require ROOTDIR . "/modules/addons/dnssuite/lang/adminLang.php";
        $ajaxvars .= "var modulelink = '" . $vars["modulelink"] . "';\n";
        $ajaxvars .= "var modifyword = '" . $ADMINLANGARRAY["dnssuitePage_manage_modify"] . "';\n";
        $ajaxvars .= "var deleteword = '" . $ADMINLANGARRAY["dnssuitePage_manage_delete"] . "';\n";
        $ajaxvars .= "var addword = '" . $ADMINLANGARRAY["dnssuitePage_manage_addrecord"] . "';\n";
        $ajaxvars .= "var updateword = '" . $ADMINLANGARRAY["dnssuitePage_manage_update"] . "';\n";
        $ajaxvars .= "var hostword = '" . $ADMINLANGARRAY["dnssuitePage_manage_host"] . "';\n";
        $ajaxvars .= "var destinationword = '" . $ADMINLANGARRAY["dnssuitePage_manage_destinationhost"] . "';\n";
        $ajaxvars .= "var ipword = '" . $ADMINLANGARRAY["dnssuitePage_manage_ip"] . "';\n";
        $ajaxvars .= "var priorityword = '" . $ADMINLANGARRAY["dnssuitePage_manage_priority"] . "';\n";
        $ajaxvars .= "var weightword = '" . $ADMINLANGARRAY["dnssuitePage_manage_weight"] . "';\n";
        $ajaxvars .= "var portword = '" . $ADMINLANGARRAY["dnssuitePage_manage_port"] . "';\n";
        $ajaxvars .= "var word301 = '" . $ADMINLANGARRAY["dnssuitePage_manage_301"] . "';\n";
        $ajaxvars .= "var word302 = '" . $ADMINLANGARRAY["dnssuitePage_manage_302"] . "';\n";
        $ajaxvars .= "var word303 = '" . $ADMINLANGARRAY["dnssuitePage_manage_303"] . "';\n";
        $ajaxvars .= "var word999 = '" . $ADMINLANGARRAY["dnssuitePage_manage_999"] . "';\n";
        $ajaxvars .= "var wordpagetitle = '" . $ADMINLANGARRAY["dnssuitePage_manage_pagetitle"] . "';\n";
        $ajaxvars .= "var wordmeta = '" . $ADMINLANGARRAY["dnssuitePage_manage_meta"] . "';\n";
        $ajaxvars .= "var wordkeywords = '" . $ADMINLANGARRAY["dnssuitePage_manage_keywords"] . "';\n";
        $ajaxvars .= "var setredirectword = '" . $ADMINLANGARRAY["dnssuitePage_manage_setredirect"] . "';\n";
        $ajaxvars .= "var verifyword = '" . $ADMINLANGARRAY["dnssuitePage_manage_verify"] . "';\n";
        $ajaxvars .= "var destinationemailword = '" . $ADMINLANGARRAY["dnssuitePage_manage_destinationplaceholder"] . "';\n";
        $ajaxvars .= "var addemailword = '" . $ADMINLANGARRAY["dnssuitePage_manage_addemail"] . "';\n";
        $ajaxvars .= "var domainid = '" . $vars["domainid"] . "';\n";
        if(isset($vars["subdomain"])) {
            $ajaxvars .= "var domaindot = '" . $vars["subdomain"] . ".';\n";
            $ajaxvars .= "var domainname = '" . $vars["subdomain"] . "';\n";
        } else {
            $ajaxvars .= "var domaindot = '" . $vars["domain"] . ".';\n";
            $ajaxvars .= "var domainname = '" . $vars["domain"] . "';\n";
        }
        $ajaxvars .= "var addaliasword = '" . $ADMINLANGARRAY["dnssuitePage_manage_addalias"] . "';\n";
        $ajaxvars .= "var aliasplaceholder = '" . $ADMINLANGARRAY["dnssuitePage_manage_newalias"] . "';\n";
        $ajaxvars .= "var catchallstatusword = '" . $ADMINLANGARRAY["dnssuitePage_manage_catchall_status"] . "';\n";
        $ajaxvars .= "var catchalloffword = '" . $ADMINLANGARRAY["dnssuitePage_manage_catchall_status_off"] . "';\n";
        $ajaxvars .= "var catchallonword = '" . $ADMINLANGARRAY["dnssuitePage_manage_catchall_status_on"] . "';\n";
        $ajaxvars .= "var sid = '" . $vars["serviceid"] . "';\n";
        if(isset($vars["sdid"])) {
            $ajaxvars .= "var sdid = '" . $vars["sdid"] . "';\n";
        }
        return $ajaxvars;
    }
    // @Protected ioncube.dk encoding key.
    public function generateAHTML()
    {
    }
    // @Protected ioncube.dk encoding key.
    public function generateARecordHTML()
    {
    }
    // @Protected ioncube.dk encoding key.
    public function generateAAAAHTML()
    {
    }
    // @Protected ioncube.dk encoding key.
    public function generateAAAARecordHTML()
    {
    }
    // @Protected ioncube.dk encoding key.
    public function generateCatchAllHTML()
    {
    }
    // @Protected ioncube.dk encoding key.
    public function generateSubDomainCatchAllHTML()
    {
    }
    // @Protected ioncube.dk encoding key.
    public function generateCNAMEHTML()
    {
    }
    // @Protected ioncube.dk encoding key.
    public function generateCNAMERecordHTML()
    {
    }
    // @Protected ioncube.dk encoding key.
    public function generateDNSTemplateHTML()
    {
    }
    // @Protected ioncube.dk encoding key.
    public function generateDestinationHTML()
    {
    }
    // @Protected ioncube.dk encoding key.
    public function generateSubDomainForwarderHTML()
    {
    }
    // @Protected ioncube.dk encoding key.
    public function generateForwarderHTML()
    {
    }
    // @Protected ioncube.dk encoding key.
    public function generateMXHTML()
    {
    }
    // @Protected ioncube.dk encoding key.
    public function generateMXRecordHTML()
    {
    }
    // @Protected ioncube.dk encoding key.
    public function generateNSHTML()
    {
    }
    // @Protected ioncube.dk encoding key.
    public function generateNSRecordHTML()
    {
    }
    // @Protected ioncube.dk encoding key.
    public function generateSRVHTML()
    {
    }
    public function generateSubDomainHTML($vars)
    {
        require ROOTDIR . "/modules/addons/dnssuite/lang/adminLang.php";
        $domain = $this->basic->getDomainfromDID($vars["domainid"]);
        $modulelink = $vars["modulelink"];
        $subdomains = $this->returnSubdomains($vars["domainid"]);
        $html = "<script>";
        $html .= "\$(document).on('click', '.addSUBDOMAINbtn',function(e){\r\n                    e.preventDefault();\r\n                    var hostname = /^(([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\\-]*[a-zA-Z0-9])\\.)*([A-Za-z0-9]|[A-Za-z0-9][A-Za-z0-9\\-]*[A-Za-z0-9])\$/;\r\n                    if (document.getElementById('addSUBDOMAIN').value == ''){\r\n                        \$.notify({message: '" . $ADMINLANGARRAY["dnssuitePage_manage_subdomainempty"] . "'},{type: 'danger',delay: 5000,timer: 1000,newest_on_top: true,animate: {enter: 'animated fadeInDown',exit: 'animated fadeOutDown'},});\r\n                        document.getElementById('addSUBDOMAIN').focus();\r\n                        return false;\r\n                    }else if (!document.getElementById('addSUBDOMAIN').value.match(hostname)){\r\n                        \$.notify({message: '" . $ADMINLANGARRAY["dnssuitePage_manage_subdomaininvalidhostname"] . "'},{type: 'danger',delay: 5000,timer: 1000,newest_on_top: true,animate: {enter: 'animated fadeInDown',exit: 'animated fadeOutDown'},});\r\n                        document.getElementById('addSUBDOMAIN').focus();\r\n                        return false;\r\n                    }else{\r\n                        \$.ajax({\r\n                        type: 'POST',\r\n                        url: '../modules/addons/dnssuite/include/dnssuite_admin_ajax.php',\r\n                        data: { domainid: domainid, hostname: document.getElementById('addSUBDOMAIN').value, action: 'addSUBDOMAIN'},\r\n                        success:function(result){\r\n                            var result = JSON.parse(result);\r\n                            if (result.status == 2){\r\n                                \$.notify({message: '" . $ADMINLANGARRAY["dnssuitePage_manage_subdomain_hostnameexist"] . "'},{type: 'danger',delay: 5000,timer: 1000,newest_on_top: true,animate: {enter: 'animated fadeInDown',exit: 'animated fadeOutDown'},});\r\n                                return false;\r\n                            }else if (result.status == 3){\r\n                                \$.notify({message: '" . $ADMINLANGARRAY["dnssuitePage_manage_subdomain_add_failed"] . "'},{type: 'danger',delay: 5000,timer: 1000,newest_on_top: true,animate: {enter: 'animated fadeInDown',exit: 'animated fadeOutDown'},});\r\n                                return false;\r\n                            }else if (result.status == 1){\r\n                                \$.notify({message: '" . $ADMINLANGARRAY["dnssuitePage_manage_subdomain_add_success"] . "'},{type: 'success',delay: 5000,timer: 1000,newest_on_top: true,animate: {enter: 'animated fadeInDown',exit: 'animated fadeOutDown'},});\r\n                                var data = result.data;\r\n                                var write = true;\r\n                                \$('#SUBDOMAINtable').find('tr:gt(0)').remove();\r\n                                BuildTableSubDomainAdmin(data, write);\r\n                            }\r\n                        }});\r\n                    }\r\n                });";
        $html .= "\r\n            \$(document).on('click', '.deleteSUBDOMAINbtn',function(e) {\r\n                    e.preventDefault();\r\n                    var id = \$(this).val();\r\n\r\n                    \$('#deletemodalSUBDOMAIN').modal({\r\n                    backdrop: 'static',\r\n                    keyboard: true\r\n                    }).one('click', '#deletebutton', function(e) {\r\n                        \$.ajax({\r\n                            type: 'POST',\r\n                            url: '../modules/addons/dnssuite/include/dnssuite_admin_ajax.php',\r\n                            data: {  domainid: domainid, sdid: id, action: 'deleteSUBDOMAIN'},\r\n                            success:function(result){\r\n                                var result = JSON.parse(result);\r\n                                if (result.status == 2){\r\n                                    \$.notify({message: '" . $ADMINLANGARRAY["dnssuitePage_manage_subdomain_notowned"] . "'},{type: 'danger',delay: 5000,timer: 1000,newest_on_top: true,animate: {enter: 'animated fadeInDown',exit: 'animated fadeOutDown'},});\r\n                                    return false;\r\n                                }else if (result.status == 0){\r\n                                    \$.notify({message: '" . $ADMINLANGARRAY["dnssuitePage_manage_subdomain_delete_failed"] . "'},{type: 'danger',delay: 5000,timer: 1000,newest_on_top: true,animate: {enter: 'animated fadeInDown',exit: 'animated fadeOutDown'},});\r\n                                    return false;\r\n                                }else if (result.status == 1){\r\n                                    \$.notify({message: '" . $ADMINLANGARRAY["dnssuitePage_manage_subdomain_delete_success"] . "'},{type: 'success',delay: 5000,timer: 1000,newest_on_top: true,animate: {enter: 'animated fadeInDown',exit: 'animated fadeOutDown'},});\r\n                                    var data = result.data;\r\n                                    var write = true;\r\n                                    \$('#SUBDOMAINtable').find('tr:gt(0)').remove();\r\n                                    BuildTableSubDomainAdmin(data, write);\r\n                                }\r\n                        }});\r\n                    });\r\n                });\r\n\r\n        ";
        $html .= "</script>";
        $html .= "<div class=\"modal fade\" tabindex=\"-1\" role=\"dialog\" aria-labelledby=\"exampleModalLabel\" aria-hidden=\"true\" id=\"deletemodalSUBDOMAIN\">\r\n                        <div class=\"modal-dialog\" role=\"document\" >\r\n                            <div class=\"modal-content\" style=\"padding:0px\">\r\n                                <div class=\"modal-header-warning\">\r\n                                    <h5 class=\"modal-title\" id=\"exampleModalLabel\">" . $ADMINLANGARRAY["dnssuitePage_manage_js_deleteconfirmresubdomain"] . "</h5>\r\n                                </div>\r\n                                <div class=\"modal-body\" id=\"validateresp\">\r\n                \r\n                                </div>\r\n                                <div class=\"modal-footer\">\r\n                                    <button type=\"button\" class=\"btn btn-secondary\" data-dismiss=\"modal\" id=\"deletebutton\"><i class=\"fa fa-trash\"></i></button>\r\n                                    <button type=\"button\" class=\"btn btn-secondary\" data-dismiss=\"modal\"><i class=\"fa fa-ban\"></i></button>\r\n                                </div>\r\n                            </div>\r\n                        </div>\r\n                    </div>";
        $html .= "<p>";
        $html .= "<table id=\"SUBDOMAINtable\" class=\"table table-striped\">";
        $html .= "<tr>";
        $html .= "<th>" . $ADMINLANG_subdomainhostname . "</th>";
        $html .= "<th>&nbsp;</th>";
        $html .= "</tr>";
        if(!empty($subdomains)) {
            if(count($subdomains) == 0) {
            } else {
                for ($i = 0; $i < count($subdomains); $i++) {
                    $html .= "<tr>";
                    $html .= "<td>" . $subdomains[$i]["host"] . "." . $domain . "</td>";
                    $html .= "<td><div class=\"col-xs-4\"><a href=\"" . $modulelink . "&action=loadsubdomain&did=" . $vars["domainid"] . "&sdid=" . $subdomains[$i]["id"] . "\" target=\"_new\"><i class=\"fa fa-sign-in\"></i></a></div><div class=\"col-xs-4\"><button type=\"submit\" class=\"btn btn-danger btn-xs deleteSUBDOMAINbtn\" value=\"" . $subdomains[$i]["id"] . "\"><i class=\"fa fa-trash\"></i> </button></div></td>";
                    $html .= "</tr>";
                }
            }
        }
        $html .= "\r\n                 <tr>\r\n                    <td><input type=\"text\" id=\"addSUBDOMAIN\"/></td>\r\n                    <td>\r\n                        <input type=\"hidden\" id=\"addSUBDOMAIN-domainid\" value=\"" . $vars["domainid"] . "\">\r\n                        <div class=\"col-sm-4\"><button type=\"submit\" class=\"btn btn-primary btn-xs addSUBDOMAINbtn\"><i class=\"fa fa-plus\"></i> </button></div>\r\n                    </td>\r\n                </tr>\r\n            ";
        $html .= "</table></p>";
        return $html;
    }
    // @Protected ioncube.dk encoding key.
    public function generateSRVRecordHTML()
    {
    }
    // @Protected ioncube.dk encoding key.
    public function generateRedirectHTML()
    {
    }
    // @Protected ioncube.dk encoding key.
    public function generateSubDomainRedirectHTML()
    {
    }
    // @Protected ioncube.dk encoding key.
    public function generateTXTHTML()
    {
    }
    // @Protected ioncube.dk encoding key.
    public function generateTXTRecordHTML()
    {
    }
    // @Protected ioncube.dk encoding key.
    public function generateStatusHTML()
    {
    }
    // @Protected ioncube.dk encoding key.
    public function initOverview()
    {
    }
    // @Protected ioncube.dk encoding key.
    public function loadCatchall()
    {
    }
    // @Protected ioncube.dk encoding key.
    public function loadSubdomainCatchall()
    {
    }
    // @Protected ioncube.dk encoding key.
    public function loadDomain()
    {
    }
    // @Protected ioncube.dk encoding key.
    public function loadDNSTemplates()
    {
    }
    // @Protected ioncube.dk encoding key.
    public function loadForwarder()
    {
    }
    // @Protected ioncube.dk encoding key.
    public function loadSubDomainForwarder()
    {
    }
    // @Protected ioncube.dk encoding key.
    public function loadRedirect()
    {
    }
    // @Protected ioncube.dk encoding key.
    public function loadSubDomainRedirect()
    {
    }
    // @Protected ioncube.dk encoding key.
    public function modifyForwarder()
    {
    }
    // @Protected ioncube.dk encoding key.
    public function modifySubdomainForwarder()
    {
    }
    // @Protected ioncube.dk encoding key.
    public function modifyRedirect()
    {
    }
    // @Protected ioncube.dk encoding key.
    public function modifySubDomainRedirect()
    {
    }
    // @Protected ioncube.dk encoding key.
    public function parseZone()
    {
    }
    // @Protected ioncube.dk encoding key.
    public function removeDomain()
    {
    }
    // @Protected ioncube.dk encoding key.
    public function requestSSL()
    {
    }
    // @Protected ioncube.dk encoding key.
    public function requestSubDomainSSL()
    {
    }
    // @Protected ioncube.dk encoding key.
    public function resetDomain()
    {
    }
    // @Protected ioncube.dk encoding key.
    public function resetSubDomain()
    {
    }
    // @Protected ioncube.dk encoding key.
    public function returnDomainsLocal()
    {
    }
    // @Protected ioncube.dk encoding key.
    public function returnDomainsLocalExpired()
    {
    }
    // @Protected ioncube.dk encoding key.
    public function returnDomainsRemote()
    {
    }
    public function returnSubdomains($did)
    {
        $query = $this->pdo->prepare("SELECT * FROM mod_dnssuite_subdomains WHERE relid = :relid order by host");
        $query->execute([":relid" => $did]);
        $query = $query->fetchAll(\PDO::FETCH_ASSOC);
        return $query;
    }
    // @Protected ioncube.dk encoding key.
    public function returnUserDNSTemplates()
    {
    }
    // @Protected ioncube.dk encoding key.
    public function returnUserDNSTemplateName()
    {
    }
    // @Protected ioncube.dk encoding key.
    public function returnSystemDNSTemplates()
    {
    }
    // @Protected ioncube.dk encoding key.
    public function returnSystemDNSTemplateName()
    {
    }
    // @Protected ioncube.dk encoding key.
    public function searchforDomainID()
    {
    }
    // @Protected ioncube.dk encoding key.
    public function switchNS()
    {
    }
    // @Protected ioncube.dk encoding key.
    public function syncDomainsToRemote()
    {
    }
    // @Protected ioncube.dk encoding key.
    public function restoreDNSTemplatetoDomain()
    {
    }
    // @Protected ioncube.dk encoding key.
    public function updateCatchall()
    {
    }
    // @Protected ioncube.dk encoding key.
    public function updateSubDomainCatchall()
    {
    }
    // @Protected ioncube.dk encoding key.
    public function updateDNSRecord()
    {
    }
    // @Protected ioncube.dk encoding key.
    public function updateDNSTemplate()
    {
    }
    // @Protected ioncube.dk encoding key.
    public function updateDNSTemplateStatus()
    {
    }
    // @Protected ioncube.dk encoding key.
    private function saveDNSTemplate()
    {
    }
    // @Protected ioncube.dk encoding key.
    private function restoreProcess()
    {
    }
    // @Protected ioncube.dk encoding key.
    private function domaindeleteProcess()
    {
    }
    // @Protected ioncube.dk encoding key.
    private function subdomaindeleteProcess()
    {
    }
    // @Protected ioncube.dk encoding key.
    private function prepareforDelete()
    {
    }
}
class Suite_ClientArea
{
    public $pdo;
    public $basic;
    public $dns;
    public $did;
    public $redirect;
    public $email;
    public $domain;
    public $dnstemplates;
    public $oldvalues;
    public $debuginfo;
    public function __construct($pdo, $did)
    {
        $this->pdo = $pdo;
        $this->did = $did;
        $this->basic = new BaseFunctions($this->pdo);
        $this->dns = new DNSFunctions($this->pdo, $this->basic->daconfigs);
        $this->redirect = new RedirectFunctions($this->pdo, $this->basic->daconfigs);
        $this->email = new EmailFunctions($this->pdo, $this->basic->daconfigs);
        if($this->basic->edition == 0) {
            echo "Please upgrade to Premium or Pro. Free version will not run v1.1 and above";
            exit;
        }
        if($this->basic->configs["subaccountrestriction"] == "on" && isset($_SESSION[""]) && $this->checkSubAccountPermission()) {
            return false;
        }
    }
    // @Protected ioncube.dk encoding key.
    public function addAlias()
    {
    }
    // @Protected ioncube.dk encoding key.
    public function addSubDomainAlias()
    {
    }
    // @Protected ioncube.dk encoding key.
    public function addCatchall()
    {
    }
    // @Protected ioncube.dk encoding key.
    public function addRecord()
    {
    }
    // @Protected ioncube.dk encoding key.
    public function addRedirect()
    {
    }
    public function addSubDomainRedirect($vars)
    {
        if(!$this->basic->checkDomainOwnership_byid($vars["did"])) {
            return NULL;
        }
        if($vars["from"] == "") {
            $vars["from"] = "/";
        }
        $vars["to"] = idn_to_ascii($vars["to"]);
        if(!$this->redirect->checkSubDomainReplicateRedirect($vars["sdid"], $vars["from"])) {
            if($vars["type"] == 999) {
                if($this->redirect->addSubDomainRedirectMaskedRemote(["did" => $vars["did"], "host" => $vars["host"], "from" => $vars["from"], "to" => $vars["to"], "hash" => $this->basic->configs["maskedhash"], "maskedtitle" => $vars["maskedtitle"], "maskedmeta" => $vars["maskedmeta"], "maskedkeywords" => $vars["maskedkeywords"]])) {
                    $newarray[] = [$vars["from"], 2 => $vars["to"], 3 => $vars["type"]];
                    if(!$this->redirect->isSubDomainRedirectOverlimit($vars, $this->basic->urlforward["limit"])) {
                        $vars["maskeddata"] = ["maskedtitle" => htmlentities($vars["maskedtitle"]), "maskedmeta" => htmlentities($vars["maskedmeta"]), "maskedkeywords" => htmlentities($vars["maskedkeywords"])];
                        if($this->redirect->addSubDomainRedirectLocal($vars, $newarray)) {
                            $this->redirect->fetchSubDomainRedirectRemote($vars);
                            $this->redirect->fetchSubDomainRedirectMasked($vars["sdid"]);
                            return true;
                        }
                        return false;
                    }
                    return false;
                }
                return false;
            }
            if($this->redirect->addSubDomainRedirectRemote(["did" => $vars["did"], "from" => $vars["from"], "to" => $vars["to"], "type" => $vars["type"], "host" => $vars["host"]])) {
                $newarray[] = [$vars["from"], 2 => $vars["to"], 3 => $vars["type"]];
                if(!$this->redirect->isSubDomainRedirectOverlimit($vars, $this->basic->urlforward["limit"])) {
                    if($this->redirect->addSubDomainRedirectLocal($vars, $newarray)) {
                        $this->redirect->fetchSubDomainRedirectRemote($vars);
                        $this->redirect->fetchSubDomainRedirectMasked($vars["sdid"]);
                        return true;
                    }
                    return false;
                }
                return false;
            }
            return false;
        }
        return false;
    }
    // @Protected ioncube.dk encoding key.
    public function checkDomainExist()
    {
    }
    // @Protected ioncube.dk encoding key.
    public function checkDuplicateUserTemplateName()
    {
    }
    // @Protected ioncube.dk encoding key.
    public function checkHaveForwarding()
    {
    }
    // @Protected ioncube.dk encoding key.
    public function checkHaveWebRedirect()
    {
    }
    public function checkHostnameExist($vars)
    {
        $zonedata = $this->loadDomain($vars["did"], NULL);
        if(!empty($zonedata["a"])) {
            for ($i = 0; $i < count($zonedata["a"]); $i++) {
                $zonedata["a"][$i] = explode(" ", $zonedata["a"][$i]);
                if($zonedata["a"][$i][0] == $vars["hostname"]) {
                    return true;
                }
            }
        }
        if(!empty($zonedata["cname"])) {
            for ($i = 0; $i < count($zonedata["cname"]); $i++) {
                $zonedata["cname"][$i] = explode(" ", $zonedata["cname"][$i]);
                if($zonedata["cname"][$i][0] == $vars["hostname"]) {
                    return true;
                }
            }
        }
        if(!empty($zonedata["aaaa"])) {
            for ($i = 0; $i < count($zonedata["aaaa"]); $i++) {
                $zonedata["aaaa"][$i] = explode(" ", $zonedata["aaaa"][$i]);
                if($zonedata["aaaa"][$i][0] == $vars["hostname"]) {
                    return true;
                }
            }
        }
        return false;
    }
    // @Protected ioncube.dk encoding key.
    public function checkNotification()
    {
    }
    public function checkSubDomainExist($vars)
    {
        $did = $vars["did"];
        $host = $vars["host"];
        $domains = $this->dns->getDomains();
        $this->did = $did;
        $subdomain = $host . "." . $this->basic->getDomainfromDID($did);
        if(!in_array($subdomain, $domains)) {
            if($this->dns->newSubDomainCreate($did, $host)) {
                $this->dns->changeTTLSubdomain(["did" => $did, "host" => $host], $this->basic->configs["defaultttl"]);
            } else {
                return false;
            }
        }
        $query = $this->pdo->prepare("SELECT count(*) FROM mod_dnssuite_subdomains WHERE host = :hostname AND relid = :relid");
        $query->execute([":hostname" => $host, ":relid" => $did]);
        $query = $query->fetch(\PDO::FETCH_ASSOC);
        if(0 < $query["count(*)"]) {
            return true;
        }
        $query = $this->pdo->prepare("INSERT INTO mod_dnssuite_subdomains (relid, host) VALUES (:relid, :hostname)");
        $query->execute([":relid" => $did, ":hostname" => $host]);
        if(!$this->pdo->inTransaction()) {
            $this->pdo->beginTransaction();
        }
        $this->pdo->commit();
        return true;
    }
    // @Protected ioncube.dk encoding key.
    public function clearDNS()
    {
    }
    // @Protected ioncube.dk encoding key.
    public function createNotificationEntry()
    {
    }
    // @Protected ioncube.dk encoding key.
    public function createUserDNSTemplate()
    {
    }
    // @Protected ioncube.dk encoding key.
    public function checkUserTemplateOwnership()
    {
    }
    // @Protected ioncube.dk encoding key.
    public function disableCatchall()
    {
    }
    // @Protected ioncube.dk encoding key.
    public function disableSubDomainCatchall()
    {
    }
    // @Protected ioncube.dk encoding key.
    public function deleteEmail()
    {
    }
    // @Protected ioncube.dk encoding key.
    public function deleteUserDNSTemplate()
    {
    }
    // @Protected ioncube.dk encoding key.
    public function deleteForwarder()
    {
    }
    public function deleteSubDomainForwarder($vars, $fid)
    {
        $did = $vars["did"];
        $sdid = $vars["sdid"];
        if(!$this->basic->checkDomainOwnership_byid($did)) {
            return NULL;
        }
        if($this->email->verifySubDomainForwarderOwner($sdid, $fid)) {
            $query = $this->pdo->prepare("SELECT * FROM mod_dnssuite_sd_emailforwarders WHERE id = :fid");
            $query->execute([":fid" => $fid]);
            $query = $query->fetch(\PDO::FETCH_ASSOC);
            $alias = $query["email"];
            $this->oldvalues["oldmailto"] = $query["mailto"];
            $this->oldvalues["alias"] = $query["email"];
            if($this->email->deleteSubDomainForwarderRemote($vars, $alias)) {
                if(!$this->email->deleteSubDomainForwarderLocal($fid)) {
                    return false;
                }
                $this->email->updateSubDomainForwardersLastupdate($sdid);
                return true;
            }
        } else {
            return false;
        }
    }
    // @Protected ioncube.dk encoding key.
    public function deleteRecord()
    {
    }
    // @Protected ioncube.dk encoding key.
    public function deleteRedirect()
    {
    }
    // @Protected ioncube.dk encoding key.
    public function deleteSubDomainRedirect()
    {
    }
    // @Protected ioncube.dk encoding key.
    public function deleteRedirectMasked()
    {
    }
    // @Protected ioncube.dk encoding key.
    public function deleteSubDomainRedirectMasked()
    {
    }
    public function deleteSubDomain($vars)
    {
        $subdomaindata = $this->basic->returnSubDomainFromSDID($vars["sdid"]);
        $subdomain = $subdomaindata["host"] . "." . $this->basic->getDomainfromDID($vars["did"]);
        if($this->dns->deleteSubDomain($subdomain)) {
            if($this->dns->deleteSubDomainLocal($vars["sdid"])) {
                return true;
            }
            return false;
        }
        return false;
    }
    public function isOverSubDomainLimit($vars)
    {
        $subdomains = $this->basic->getSubdomainsFromDID($vars["did"]);
        if($this->basic->subdomain["limit"] == "0") {
            return false;
        }
        if($this->basic->subdomain["limit"] <= count($subdomains) && $this->basic->subdomain["limit"] != "0") {
            return true;
        }
        return false;
    }
    // @Protected ioncube.dk encoding key.
    public function isSubAccount()
    {
    }
    // @Protected ioncube.dk encoding key.
    public function isSubDomainOwned()
    {
    }
    // @Protected ioncube.dk encoding key.
    public function initOverview()
    {
    }
    public function initOverviewSubDomain($vars)
    {
        $sdid = $vars["sdid"];
        $did = $vars["did"];
        if(!$this->basic->checkSubdomainOwnershipFromSDID($sdid)) {
            return NULL;
        }
        if($this->basic->configs["enablenotification"] == "on") {
            $this->checkNotification($did);
            $notification = $this->returnNotification($did);
        }
        return ["notificationconfigs" => $notification];
    }
    // @Protected ioncube.dk encoding key.
    public function loadCatchall()
    {
    }
    // @Protected ioncube.dk encoding key.
    public function loadSubdomainCatchall()
    {
    }
    // @Protected ioncube.dk encoding key.
    public function loadDomain()
    {
    }
    // @Protected ioncube.dk encoding key.
    public function loadForwarder()
    {
    }
    // @Protected ioncube.dk encoding key.
    public function loadSubDomainForwarder()
    {
    }
    // @Protected ioncube.dk encoding key.
    public function loadRedirect()
    {
    }
    // @Protected ioncube.dk encoding key.
    public function loadSubDomainRedirect()
    {
    }
    // @Protected ioncube.dk encoding key.
    public function loadDNSTemplates()
    {
    }
    // @Protected ioncube.dk encoding key.
    public function loadUserDNSTemplates()
    {
    }
    // @Protected ioncube.dk encoding key.
    public function modifyForwarder()
    {
    }
    // @Protected ioncube.dk encoding key.
    public function modifySubdomainForwarder()
    {
    }
    // @Protected ioncube.dk encoding key.
    public function modifyRedirect()
    {
    }
    // @Protected ioncube.dk encoding key.
    public function modifySubDomainRedirect()
    {
    }
    // @Protected ioncube.dk encoding key.
    public function refreshAPI()
    {
    }
    // @Protected ioncube.dk encoding key.
    public function requestSSL()
    {
    }
    // @Protected ioncube.dk encoding key.
    public function requestSubDomainSSL()
    {
    }
    // @Protected ioncube.dk encoding key.
    public function resetDomain()
    {
    }
    // @Protected ioncube.dk encoding key.
    public function resetSubDomain()
    {
    }
    // @Protected ioncube.dk encoding key.
    public function restoreDNSTemplatetoDomain()
    {
    }
    // @Protected ioncube.dk encoding key.
    public function returnCatchallState()
    {
    }
    // @Protected ioncube.dk encoding key.
    public function returnDomain()
    {
    }
    // @Protected ioncube.dk encoding key.
    public function returnEmailForwarderState()
    {
    }
    // @Protected ioncube.dk encoding key.
    public function returnEmailForwarderSlotState()
    {
    }
    // @Protected ioncube.dk encoding key.
    public function returnEmailSlotState()
    {
    }
    // @Protected ioncube.dk encoding key.
    public function returnNotification()
    {
    }
    // @Protected ioncube.dk encoding key.
    public function returnRedirectState()
    {
    }
    // @Protected ioncube.dk encoding key.
    public function returnRedirectSlotState()
    {
    }
    // @Protected ioncube.dk encoding key.
    public function returnSubDomainEmailForwarderSlotState()
    {
    }
    // @Protected ioncube.dk encoding key.
    public function returnSubDomainRedirectSlotState()
    {
    }
    // @Protected ioncube.dk encoding key.
    public function returnSubDomainsLocal()
    {
    }
    // @Protected ioncube.dk encoding key.
    public function returnDNSTemplateName()
    {
    }
    // @Protected ioncube.dk encoding key.
    public function setAPIStatus()
    {
    }
    // @Protected ioncube.dk encoding key.
    public function switchNS()
    {
    }
    // @Protected ioncube.dk encoding key.
    public function updateCatchall()
    {
    }
    // @Protected ioncube.dk encoding key.
    public function updateSubDomainCatchall()
    {
    }
    // @Protected ioncube.dk encoding key.
    public function updateDNSRecord()
    {
    }
    // @Protected ioncube.dk encoding key.
    public function updateNotification()
    {
    }
    // @Protected ioncube.dk encoding key.
    public function verifyCatchall()
    {
    }
    // @Protected ioncube.dk encoding key.
    public function verifyEmail()
    {
    }
    // @Protected ioncube.dk encoding key.
    public function verifyForwarder()
    {
    }
    // @Protected ioncube.dk encoding key.
    private function isOverDNSTemplateLimit()
    {
    }
    // @Protected ioncube.dk encoding key.
    private function checkSubAccountPermission()
    {
    }
    // @Protected ioncube.dk encoding key.
    private function restoreProcess()
    {
    }
    // @Protected ioncube.dk encoding key.
    private function prepareforDelete()
    {
    }
}
class DDNSFunctions
{
    public $pdo;
    public function __construct($pdo)
    {
        $this->pdo = $pdo;
    }
    // @Protected ioncube.dk encoding key.
    public function addBruteForceBan()
    {
    }
    // @Protected ioncube.dk encoding key.
    public function addBruteForceLog()
    {
    }
    // @Protected ioncube.dk encoding key.
    public function isBanned()
    {
    }
    // @Protected ioncube.dk encoding key.
    public function isOverBruteForceLimit()
    {
    }
    // @Protected ioncube.dk encoding key.
    public function isOverAPILimit()
    {
    }
    // @Protected ioncube.dk encoding key.
    public function addLog()
    {
    }
    // @Protected ioncube.dk encoding key.
    public function returnRelid()
    {
    }
    // @Protected ioncube.dk encoding key.
    public function verifyKeys()
    {
    }
}
class BaseFunctions
{
    public $pdo;
    public $edition;
    public $style;
    public $configs;
    public $modon;
    public $daconfigs;
    public $ownership;
    public $urlforward;
    public $subdomainforward;
    public $emailforward;
    public $catchall;
    public $subdomain;
    public $records_a;
    public $records_ns;
    public $records_cname;
    public $records_mx;
    public $records_aaaa;
    public $records_srv;
    public $records_txt;
    public function __construct($pdo)
    {
        $this->pdo = $pdo;
        $this->getSettings();
        if($this->modon != "on") {
            echo "Module is disabled";
            exit;
        }
        if(!$this->checkLicense()) {
            echo "Warning code: DNSSUITE-11";
            $this->disable = true;
            exit;
        }
        if($this->edition < 2) {
            $this->daconfigs["template"] = "";
        }
    }
    public function isTTLValid($ttl, $mode)
    {
        if($mode == "A") {
            if($this->records_a["modifyttl"] != "on") {
                return true;
            }
            if($ttl < $this->records_a["maxttl"] & $this->records_a["minttl"] < $ttl) {
                return true;
            }
            return false;
        }
        if($mode == "NS") {
            if($this->records_ns["modifyttl"] != "on") {
                return true;
            }
            if($ttl < $this->records_ns["maxttl"] & $this->records_ns["minttl"] < $ttl) {
                return true;
            }
            return false;
        }
        if($mode == "MX") {
            if($this->records_mx["modifyttl"] != "on") {
                return true;
            }
            if($ttl < $this->records_mx["maxttl"] & $this->records_mx["minttl"] < $ttl) {
                return true;
            }
            return false;
        }
        if($mode == "CNAME") {
            if($this->records_cname["modifyttl"] != "on") {
                return true;
            }
            if($ttl < $this->records_cname["maxttl"] & $this->records_cname["minttl"] < $ttl) {
                return true;
            }
            return false;
        }
        if($mode == "TXT") {
            if($this->records_txt["modifyttl"] != "on") {
                return true;
            }
            if($ttl < $this->records_txt["maxttl"] & $this->records_txt["minttl"] < $ttl) {
                return true;
            }
            return false;
        }
        if($mode == "SRV") {
            if($this->records_srv["modifyttl"] != "on") {
                return true;
            }
            if($ttl < $this->records_srv["maxttl"] & $this->records_srv["minttl"] < $ttl) {
                return true;
            }
            return false;
        }
    }
    public function isRefreshtimeExpired($vars)
    {
        $refreshtime = $vars["refreshtime"] + $vars["zonetime"];
        if(time() < $refreshtime) {
            return false;
        }
        return true;
    }
    // @Protected ioncube.dk encoding key.
    public function checkDomainOwnership()
    {
    }
    // @Protected ioncube.dk encoding key.
    public function checkDomainOwnership_byid()
    {
    }
    public function checkSubdomainOwnershipFromSDID($sdid)
    {
        $query = $this->pdo->prepare("SELECT relid FROM mod_dnssuite_subdomains WHERE id = :sdid");
        $query->execute([":sdid" => $sdid]);
        $query = $query->fetch(\PDO::FETCH_ASSOC);
        $did = $query["relid"];
        if($this->checkDomainOwnership_byid($did)) {
            return true;
        }
        return false;
    }
    public function checkRedirectRoot($did)
    {
        $query = $this->pdo->prepare("SELECT count(*) FROM mod_dnssuite_redirects WHERE relid = :relid AND domain = :from AND type != 999");
        $query->execute([":relid" => $did, ":from" => "%2F"]);
        $query = $query->fetch(\PDO::FETCH_ASSOC);
        if(0 < $query["count(*)"]) {
            return true;
        }
        return false;
    }
    public function checkSubDomainRedirectRoot($sdid)
    {
        $query = $this->pdo->prepare("SELECT count(*) FROM mod_dnssuite_sd_redirects WHERE id = :sdid AND domain = :from AND type != 999");
        $query->execute([":sdid" => $sdid, ":from" => "%2F"]);
        $query = $query->fetch(\PDO::FETCH_ASSOC);
        if(0 < $query["count(*)"]) {
            return true;
        }
        return false;
    }
    // @Protected ioncube.dk encoding key.
    public function getAPI()
    {
    }
    public function generateAPI($did)
    {
        $query = $this->pdo->prepare("UPDATE mod_dnssuite_api SET keyphrase = :key, pass = :pass WHERE relid = :did");
        $key = hash("sha512", uniqid() . time());
        $pass = hash("sha512", uniqid() . date("Ymd"));
        $key = substr($key, 0, 20);
        $pass = substr($pass, 0, 20);
        $query->execute([":did" => $did, ":key" => $key, ":pass" => $pass]);
        if(!$this->pdo->inTransaction()) {
            $this->pdo->beginTransaction();
        }
        $this->pdo->commit();
    }
    public function getDomainfromDID($did)
    {
        $query = $this->pdo->prepare("SELECT domain FROM tbldomains WHERE id = :did");
        $query->execute([":did" => $did]);
        $query = $query->fetch(\PDO::FETCH_ASSOC);
        return idn_to_ascii(strtolower($query["domain"]));
    }
    public function getDIDFromSDID($sdid)
    {
        $query = $this->pdo->prepare("SELECT relid FROM mod_dnssuite_subdomains WHERE id = :sdid");
        $query->execute([":sdid" => $sdid]);
        $query = $query->fetch(\PDO::FETCH_ASSOC);
        return $query["relid"];
    }
    public function getSDIDFromSubDomainHostname($did, $host)
    {
        $query = $this->pdo->prepare("SELECT id FROM mod_dnssuite_subdomains WHERE relid = :relid AND host = :host");
        $query->execute([":relid" => $did, ":host" => $host]);
        $query = $query->fetch(\PDO::FETCH_ASSOC);
        return $query["id"];
    }
    public function getSubDomainsFromDID($did)
    {
        $query = $this->pdo->prepare("SELECT * FROM mod_dnssuite_subdomains WHERE relid = :relid");
        $query->execute([":relid" => $did]);
        $query = $query->fetchAll(\PDO::FETCH_ASSOC);
        return $query;
    }
    public function getSubDomainHostnameFromSDID($sdid)
    {
        $query = $this->pdo->prepare("SELECT host FROM mod_dnssuite_subdomains WHERE id = :sdid");
        $query->execute([":sdid" => $sdid]);
        $query = $query->fetch(\PDO::FETCH_ASSOC);
        return $query["host"];
    }
    public function isSDIDValid($sdid)
    {
        $query = $this->pdo->prepare("SELECT count(*) FROM mod_dnssuite_subdomains WHERE id = :sdid");
        $query->execute([":sdid" => $sdid]);
        $query = $query->fetch(\PDO::FETCH_ASSOC);
        if(0 < $query["count(*)"]) {
            return true;
        }
        return false;
    }
    public function isSubDomainOwnedByDID($vars)
    {
        $sdid = $vars["sdid"];
        $did = $vars["did"];
        $query = $this->pdo->prepare("SELECT count(*) FROM mod_dnssuite_subdomains WHERE id = :sdid AND relid = :did");
        $query->execute([":sdid" => $sdid, ":did" => $did]);
        $query = $query->fetch(\PDO::FETCH_ASSOC);
        if(0 < $query["count(*)"]) {
            return true;
        }
        return false;
    }
    public function returnSubDomainFromSDID($sdid)
    {
        $query = $this->pdo->prepare("SELECT * FROM mod_dnssuite_subdomains WHERE id = :sdid");
        $query->execute([":sdid" => $sdid]);
        $query = $query->fetch(\PDO::FETCH_ASSOC);
        return $query;
    }
    public function sendNotificationEmail($vars)
    {
        $query = $this->pdo->prepare("SELECT value FROM tbladdonmodules WHERE module = 'dnssuite' AND setting = :setting");
        $query->execute([":setting" => "templatenotificationemail"]);
        $query = $query->fetch(\PDO::FETCH_ASSOC);
        $templatename = $query["value"];
        $domain = $this->getDomainfromDID($vars["did"]);
        if($_SESSION["uid"] == "") {
            $query = $this->pdo->prepare("SELECT userid FROM tbldomains WHERE id = :did");
            $query->execute([":did" => $vars["did"]]);
            $query = $query->fetch(\PDO::FETCH_ASSOC);
            $userid = $query["userid"];
        } else {
            $userid = $_SESSION["uid"];
        }
        $command = "SendEmail";
        $postData = ["messagename" => $templatename, "id" => $userid, "customvars" => ["type" => $vars["type"], "domain" => $domain, "old" => $vars["old"], "new" => $vars["new"]]];
        if($this->configs["apiuser"] != "") {
            $adminUsername = $this->basic->configs["apiuser"];
        }
        $results = localAPI($command, $postData, $adminUsername);
        if($results["result"] == "success") {
            return true;
        }
        return false;
    }
    public function sendSubDomainNotificationEmail($vars)
    {
        $query = $this->pdo->prepare("SELECT value FROM tbladdonmodules WHERE module = 'dnssuite' AND setting = :setting");
        $query->execute([":setting" => "templatenotificationemail"]);
        $query = $query->fetch(\PDO::FETCH_ASSOC);
        $templatename = $query["value"];
        $domain = $vars["host"] . "." . $this->getDomainfromDID($vars["did"]);
        if($_SESSION["uid"] == "") {
            $query = $this->pdo->prepare("SELECT userid FROM tbldomains WHERE id = :did");
            $query->execute([":did" => $vars["did"]]);
            $query = $query->fetch(\PDO::FETCH_ASSOC);
            $userid = $query["userid"];
        } else {
            $userid = $_SESSION["uid"];
        }
        $command = "SendEmail";
        $postData = ["messagename" => $templatename, "id" => $userid, "customvars" => ["type" => $vars["type"], "domain" => $domain, "old" => $vars["old"], "new" => $vars["new"]]];
        if($this->configs["apiuser"] != "") {
            $adminUsername = $this->basic->configs["apiuser"];
        }
        $results = localAPI($command, $postData, $adminUsername);
        if($results["result"] == "success") {
            return true;
        }
        return false;
    }
    public function setAPIStatus($did, $mode)
    {
        if($mode == 0) {
            $query = $this->pdo->prepare("UPDATE mod_dnssuite_api SET status = :status WHERE relid = :did");
            $query->execute([":did" => $did, ":status" => 0]);
            if(!$this->pdo->inTransaction()) {
                $this->pdo->beginTransaction();
            }
            $this->pdo->commit();
        } else {
            $query = $this->pdo->prepare("UPDATE mod_dnssuite_api SET status = :status WHERE relid = :did");
            $query->execute([":did" => $did, ":status" => 1]);
            if(!$this->pdo->inTransaction()) {
                $this->pdo->beginTransaction();
            }
            $this->pdo->commit();
        }
    }
    // @Protected ioncube.dk encoding key.
    public function validateCNAMEHostname()
    {
    }
    // @Protected ioncube.dk encoding key.
    public function validateHostname()
    {
    }
    // @Protected ioncube.dk encoding key.
    public function validateHostnameNoWildCard()
    {
    }
    // @Protected ioncube.dk encoding key.
    public function validateHostnameDot()
    {
    }
    // @Protected ioncube.dk encoding key.
    public function validateHostnameUnderScore()
    {
    }
    // @Protected ioncube.dk encoding key.
    public function validateIntRange()
    {
    }
    // @Protected ioncube.dk encoding key.
    public function validateMXPriority()
    {
    }
    // @Protected ioncube.dk encoding key.
    public function validateTXTValue()
    {
    }
    // @Protected ioncube.dk encoding key.
    public function verifyHostasDomain()
    {
    }
    private function getSettings()
    {
        $query = $this->pdo->prepare("SELECT * FROM tbladdonmodules WHERE module = 'dnssuite'");
        $query->execute();
        $query = $query->fetchAll(\PDO::FETCH_ASSOC);
        for ($i = 0; $i < count($query); $i++) {
            if($query[$i]["setting"] == "license") {
                $this->configs["license"] = $query[$i]["value"];
            }
            if($query[$i]["setting"] == "modon") {
                $this->modon = $query[$i]["value"];
            }
            if($query[$i]["setting"] == "templatestyle") {
                $this->style = $query[$i]["value"];
            }
            if($query[$i]["setting"] == "respectwhmcsdns") {
                $this->configs["respectwhmcsdns"] = $query[$i]["value"];
            }
            if($query[$i]["setting"] == "disablemanage") {
                $this->configs["disablemanage"] = $query[$i]["value"];
            }
            if($query[$i]["setting"] == "templateverify") {
                $this->configs["templateverify"] = $query[$i]["value"];
            }
            if($query[$i]["setting"] == "subaccountrestriction") {
                $this->configs["subaccountrestriction"] = $query[$i]["value"];
            }
            if($query[$i]["setting"] == "refreshtime") {
                if(is_numeric($query[$i]["value"])) {
                    $this->configs["refreshtime"] = $query[$i]["value"];
                } else {
                    $this->configs["refreshtime"] = 7200;
                }
            }
            if($query[$i]["setting"] == "maskedhash") {
                if($query[$i]["value"] == "") {
                    $this->configs["maskedhash"] = "abc123def456";
                } else {
                    $this->configs["maskedhash"] = $query[$i]["value"];
                }
            }
            if($query[$i]["setting"] == "largedbexclusion") {
                $this->configs["largedbexclusion"] = $query[$i]["value"];
            }
            if($query[$i]["setting"] == "fetchonload") {
                $this->configs["fetchonload"] = $query[$i]["value"];
            }
            if($query[$i]["setting"] == "fetchonloadadmin") {
                $this->configs["fetchonloadadmin"] = $query[$i]["value"];
            }
            if($query[$i]["setting"] == "serialpriority") {
                $this->configs["serialpriority"] = $query[$i]["value"];
            }
            if($query[$i]["setting"] == "defaultnameserver1") {
                $this->configs["defaultnameserver1"] = $query[$i]["value"];
            }
            if($query[$i]["setting"] == "defaultnameserver2") {
                $this->configs["defaultnameserver2"] = $query[$i]["value"];
            }
            if($query[$i]["setting"] == "defaultnameserver3") {
                $this->configs["defaultnameserver3"] = $query[$i]["value"];
            }
            if($query[$i]["setting"] == "defaultnameserver4") {
                $this->configs["defaultnameserver4"] = $query[$i]["value"];
            }
            if($query[$i]["setting"] == "defaultnameserver5") {
                $this->configs["defaultnameserver5"] = $query[$i]["value"];
            }
            if($query[$i]["setting"] == "defaultttl") {
                if(!is_numeric($query[$i]["value"])) {
                    $this->configs["defaultttl"] = "360";
                } elseif($query[$i]["value"] < 30) {
                    $this->configs["defaultttl"] = "360";
                } elseif(2147483647 < $query[$i]["value"]) {
                    $this->configs["defaultttl"] = "360";
                } else {
                    $this->configs["defaultttl"] = $query[$i]["value"];
                }
            }
            if($query[$i]["setting"] == "showunderdomainmenu") {
                $this->configs["showunderdomainmenu"] = $query[$i]["value"];
            }
            if($query[$i]["setting"] == "letsencrypt") {
                $this->configs["letsencrypt"] = $query[$i]["value"];
            }
            if($query[$i]["setting"] == "clientletsencrypt") {
                $this->configs["clientletsencrypt"] = $query[$i]["value"];
            }
            if($query[$i]["setting"] == "createonpreregistrar") {
                $this->configs["createonpreregistrar"] = $query[$i]["value"];
            }
            if($query[$i]["setting"] == "createonregistration") {
                $this->configs["createonregistration"] = $query[$i]["value"];
            }
            if($query[$i]["setting"] == "createontransfer") {
                $this->configs["createontransfer"] = $query[$i]["value"];
            }
            if($query[$i]["setting"] == "enablednseditor") {
                $this->configs["enablednseditor"] = $query[$i]["value"];
            }
            if($query[$i]["setting"] == "disablearecordonforward") {
                $this->configs["disablearecordonforward"] = $query[$i]["value"];
            }
            if($query[$i]["setting"] == "disableemailonforward") {
                $this->configs["disableemailonforward"] = $query[$i]["value"];
            }
            if($query[$i]["setting"] == "enablednstemplate") {
                $this->configs["enablednstemplate"] = $query[$i]["value"];
            }
            if($query[$i]["setting"] == "enableuserdnstemplate") {
                $this->configs["enableuserdnstemplate"] = $query[$i]["value"];
            }
            if($query[$i]["setting"] == "userdnstemplatelimit") {
                if(is_numeric($query[$i]["value"])) {
                    $this->configs["userdnstemplatelimit"] = $query[$i]["value"];
                } else {
                    $this->configs["userdnstemplatelimit"] = 10;
                }
            }
            if($query[$i]["setting"] == "enabledyndns") {
                $this->configs["enabledyndns"] = $query[$i]["value"];
            }
            if($query[$i]["setting"] == "dyndnslimit") {
                if(is_numeric($query[$i]["value"])) {
                    $this->configs["dyndnslimit"] = $query[$i]["value"];
                } else {
                    $this->configs["dyndnslimit"] = 5;
                }
            }
            if($query[$i]["setting"] == "bruteforcetime") {
                if(is_numeric($query[$i]["value"])) {
                    $this->configs["bruteforcetime"] = $query[$i]["value"];
                } else {
                    $this->configs["bruteforcetime"] = 3600;
                }
            }
            if($query[$i]["setting"] == "bruteforcebantime") {
                if(is_numeric($query[$i]["value"])) {
                    $this->configs["bruteforcebantime"] = $query[$i]["value"];
                } else {
                    $this->configs["bruteforcebantime"] = 3600;
                }
            }
            if($query[$i]["setting"] == "dyndnsbruteforcelimit") {
                if(is_numeric($query[$i]["value"])) {
                    $this->configs["dyndnsbruteforcelimit"] = $query[$i]["value"];
                } else {
                    $this->configs["dyndnsbruteforcelimit"] = 10;
                }
            }
            if($query[$i]["setting"] == "enabledyndnsbruteforce") {
                $this->configs["enabledyndnsbruteforce"] = $query[$i]["value"];
            }
            if($query[$i]["setting"] == "daserver") {
                $this->daconfigs["server"] = $query[$i]["value"];
            }
            if($query[$i]["setting"] == "daport") {
                $this->daconfigs["port"] = $query[$i]["value"];
            }
            if($query[$i]["setting"] == "dalogin") {
                $this->daconfigs["login"] = $query[$i]["value"];
            }
            if($query[$i]["setting"] == "dapassword") {
                $this->daconfigs["password"] = $query[$i]["value"];
            }
            if($query[$i]["setting"] == "dassl") {
                $this->daconfigs["usessl"] = $query[$i]["value"];
            }
            if($query[$i]["setting"] == "daplaceholder") {
                $this->daconfigs["placeholder"] = $query[$i]["value"];
            }
            if($query[$i]["setting"] == "dawebtemplate") {
                $this->daconfigs["template"] = $query[$i]["value"];
            }
            if($query[$i]["setting"] == "daphp") {
                $this->daconfigs["php"] = $query[$i]["value"];
            }
            if($query[$i]["setting"] == "dawebssl") {
                $this->daconfigs["webssl"] = $query[$i]["value"];
            }
            if($query[$i]["setting"] == "enablenotification") {
                $this->configs["enablenotification"] = $query[$i]["value"];
            }
            if($query[$i]["setting"] == "templatenotificationemail") {
                $this->configs["templatenotificationemail"] = $query[$i]["value"];
            }
            if($query[$i]["setting"] == "subdomainlimit") {
                if(is_numeric($query[$i]["value"])) {
                    $this->subdomain["limit"] = $query[$i]["value"];
                    $this->subdomain["enable"] = "on";
                } elseif($query[$i]["value"] == "-1") {
                    $this->subdomain["enable"] = "off";
                } else {
                    $this->subdomain["limit"] = 5;
                    $this->subdomain["enable"] = "on";
                }
            }
            if($query[$i]["setting"] == "enableurlforwarder") {
                $this->urlforward["enable"] = $query[$i]["value"];
            }
            if($query[$i]["setting"] == "enablemaskedurlforwarder") {
                $this->urlforward["masked"] = $query[$i]["value"];
            }
            if($query[$i]["setting"] == "urlforwarderlimit") {
                if(is_numeric($query[$i]["value"])) {
                    $this->urlforward["limit"] = $query[$i]["value"];
                } else {
                    $this->urlforward["limit"] = 5;
                }
            }
            if($query[$i]["setting"] == "enableemailforwarder") {
                $this->emailforward["enable"] = $query[$i]["value"];
            }
            if($query[$i]["setting"] == "emailforwarderslotlimit") {
                $this->emailforward["limit"] = $query[$i]["value"];
            }
            if($query[$i]["setting"] == "emailslotlimit") {
                if(is_numeric($query[$i]["value"])) {
                    $this->emailforward["slotlimit"] = $query[$i]["value"];
                } else {
                    $this->emailforward["slotlimit"] = 5;
                }
            }
            if($query[$i]["setting"] == "enableemailcatchall") {
                $this->catchall["enable"] = $query[$i]["value"];
            }
            if($query[$i]["setting"] == "modifyarecord") {
                $this->records_a["modify"] = $query[$i]["value"];
            }
            if($query[$i]["setting"] == "arecordlimit") {
                if(is_numeric($query[$i]["value"])) {
                    $this->records_a["limit"] = $query[$i]["value"];
                } else {
                    $this->records_a["limit"] = 10;
                }
            }
            if($query[$i]["setting"] == "a_modifyttl") {
                $this->records_a["modifyttl"] = $query[$i]["value"];
            }
            if($query[$i]["setting"] == "a_defaultttl") {
                $this->records_a["defaulttt"] = $query[$i]["value"];
            }
            if($query[$i]["setting"] == "a_minttl") {
                $this->records_a["minttl"] = $query[$i]["value"];
            }
            if($query[$i]["setting"] == "a_maxttl") {
                $this->records_a["maxttl"] = $query[$i]["value"];
            }
            if($query[$i]["setting"] == "modifycnamerecord") {
                $this->records_cname["modify"] = $query[$i]["value"];
            }
            if($query[$i]["setting"] == "cnamerecordlimit") {
                if(is_numeric($query[$i]["value"])) {
                    $this->records_cname["limit"] = $query[$i]["value"];
                } else {
                    $this->records_cname["limit"] = 10;
                }
            }
            if($query[$i]["setting"] == "cname_modifyttl") {
                $this->records_cname["modifyttl"] = $query[$i]["value"];
            }
            if($query[$i]["setting"] == "cname_defaultttl") {
                $this->records_cname["defaulttt"] = $query[$i]["value"];
            }
            if($query[$i]["setting"] == "cname_minttl") {
                $this->records_cname["minttl"] = $query[$i]["value"];
            }
            if($query[$i]["setting"] == "cname_maxttl") {
                $this->records_cname["maxttl"] = $query[$i]["value"];
            }
            if($query[$i]["setting"] == "modifymxrecord") {
                $this->records_mx["modify"] = $query[$i]["value"];
            }
            if($query[$i]["setting"] == "mxrecordlimit") {
                if(is_numeric($query[$i]["value"])) {
                    $this->records_mx["limit"] = $query[$i]["value"];
                } else {
                    $this->records_mx["limit"] = 10;
                }
            }
            if($query[$i]["setting"] == "mx_modifyttl") {
                $this->records_mx["modifyttl"] = $query[$i]["value"];
            }
            if($query[$i]["setting"] == "mx_defaultttl") {
                $this->records_mx["defaulttt"] = $query[$i]["value"];
            }
            if($query[$i]["setting"] == "mx_minttl") {
                $this->records_mx["minttl"] = $query[$i]["value"];
            }
            if($query[$i]["setting"] == "mx_maxttl") {
                $this->records_mx["maxttl"] = $query[$i]["value"];
            }
            if($query[$i]["setting"] == "modifytxtrecord") {
                $this->records_txt["modify"] = $query[$i]["value"];
            }
            if($query[$i]["setting"] == "txtrecordlimit") {
                if(is_numeric($query[$i]["value"])) {
                    $this->records_txt["limit"] = $query[$i]["value"];
                } else {
                    $this->records_txt["limit"] = 10;
                }
            }
            if($query[$i]["setting"] == "txt_modifyttl") {
                $this->records_txt["modifyttl"] = $query[$i]["value"];
            }
            if($query[$i]["setting"] == "txt_defaultttl") {
                $this->records_txt["defaulttt"] = $query[$i]["value"];
            }
            if($query[$i]["setting"] == "txt_minttl") {
                $this->records_txt["minttl"] = $query[$i]["value"];
            }
            if($query[$i]["setting"] == "txt_maxttl") {
                $this->records_txt["maxttl"] = $query[$i]["value"];
            }
            if($query[$i]["setting"] == "modifysrvrecord") {
                $this->records_srv["modify"] = $query[$i]["value"];
            }
            if($query[$i]["setting"] == "srvrecordlimit") {
                if(is_numeric($query[$i]["value"])) {
                    $this->records_srv["limit"] = $query[$i]["value"];
                } else {
                    $this->records_srv["limit"] = 10;
                }
            }
            if($query[$i]["setting"] == "srv_modifyttl") {
                $this->records_srv["modifyttl"] = $query[$i]["value"];
            }
            if($query[$i]["setting"] == "srv_defaultttl") {
                $this->records_srv["defaulttt"] = $query[$i]["value"];
            }
            if($query[$i]["setting"] == "srv_minttl") {
                $this->records_srv["minttl"] = $query[$i]["value"];
            }
            if($query[$i]["setting"] == "srv_maxttl") {
                $this->records_srv["maxttl"] = $query[$i]["value"];
            }
            if($query[$i]["setting"] == "modifyaaaarecord") {
                $this->records_aaaa["modify"] = $query[$i]["value"];
            }
            if($query[$i]["setting"] == "aaaarecordlimit") {
                if(is_numeric($query[$i]["value"])) {
                    $this->records_aaaa["limit"] = $query[$i]["value"];
                } else {
                    $this->records_aaaa["limit"] = 10;
                }
            }
            if($query[$i]["setting"] == "aaaa_modifyttl") {
                $this->records_aaaa["modifyttl"] = $query[$i]["value"];
            }
            if($query[$i]["setting"] == "aaaa_defaultttl") {
                $this->records_aaaa["defaulttt"] = $query[$i]["value"];
            }
            if($query[$i]["setting"] == "aaaa_minttl") {
                $this->records_aaaa["minttl"] = $query[$i]["value"];
            }
            if($query[$i]["setting"] == "aaaa_maxttl") {
                $this->records_aaaa["maxttl"] = $query[$i]["value"];
            }
            if($query[$i]["setting"] == "modifynsrecord") {
                $this->records_ns["modify"] = $query[$i]["value"];
            }
            if($query[$i]["setting"] == "nsrecordlimit") {
                if(is_numeric($query[$i]["value"])) {
                    $this->records_ns["limit"] = $query[$i]["value"];
                } else {
                    $this->records_ns["limit"] = 10;
                }
            }
            if($query[$i]["setting"] == "ns_modifyttl") {
                $this->records_ns["modifyttl"] = $query[$i]["value"];
            }
            if($query[$i]["setting"] == "ns_defaultttl") {
                $this->records_ns["defaulttt"] = $query[$i]["value"];
            }
            if($query[$i]["setting"] == "ns_minttl") {
                $this->records_ns["minttl"] = $query[$i]["value"];
            }
            if($query[$i]["setting"] == "ns_maxttl") {
                $this->records_ns["maxttl"] = $query[$i]["value"];
            }
        }
    }
    public function getLatestVersion()
    {
        if(file_exists(ROOTDIR . "/modules/addons/dnssuite/dnssuiteLatest.php")) {
            $mdate = filemtime(ROOTDIR . "/modules/addons/dnssuite/dnssuiteLatest.php");
            if(date("Y-m-d", $mdate) == date("Y-m-d", time()) && 0 < filesize(ROOTDIR . "/modules/addons/dnssuite/dnssuiteLatest.php")) {
                $fh = fopen(ROOTDIR . "/modules/addons/dnssuite/dnssuiteLatest.php", "r+");
                $version = fread($fh, filesize(ROOTDIR . "/modules/addons/dnssuite/dnssuiteLatest.php"));
                fclose($fh);
                return $version;
            }
            $ch = curl_init();
            $url = "https://version.licensechef.com/?m=versions&id=27";
            curl_setopt($ch, CURLOPT_URL, $url);
            curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
            $version = curl_exec($ch);
            curl_close($ch);
            $fh = fopen(ROOTDIR . "/modules/addons/dnssuite/dnssuiteLatest.php", "w");
            fwrite($fh, $version);
            fclose($fh);
            return $version;
        }
        $ch = curl_init();
        $url = "https://version.licensechef.com/?m=versions&id=36";
        curl_setopt($ch, CURLOPT_URL, $url);
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
        $version = curl_exec($ch);
        curl_close($ch);
        $fh = fopen(ROOTDIR . "/modules/addons/dnssuite/dnssuiteLatest.php", "w");
        fwrite($fh, $version);
        fclose($fh);
        return $version;
    }
    private function checkLicense()
    {
        $localLic = $this->readLocalLicense();
        $liveLic = $this->configs["license"];
        $licreturn = $this->checkLicenseNow($liveLic, $localLic);
        if(preg_match("/Edition=Premium/", $licreturn["configoptions"])) {
            $this->edition = 1;
        } elseif(preg_match("/Edition=Professional/", $licreturn["configoptions"])) {
            $this->edition = 2;
        } else {
            $this->edition = 0;
        }
        if($licreturn["status"] == "Active") {
            if($licreturn["productname"] == "DNS Suite Module Premium") {
                $this->rewriteLocalLicense($licreturn["localkey"]);
                global $deepkey;
                $deepkey = "m48asdhn83he98qja";
                return true;
            }
        } else {
            return false;
        }
    }
    private function readLocalLicense()
    {
        if(file_exists(ROOTDIR . "/modules/addons/dnssuite/dnssLocal.php")) {
            if(0 < filesize(ROOTDIR . "/modules/addons/dnssuite/dnssLocal.php")) {
                $fh = fopen(ROOTDIR . "/modules/addons/dnssuite/dnssLocal.php", "r+");
                $csfLocal = fread($fh, filesize(ROOTDIR . "/modules/addons/dnssuite/dnssLocal.php"));
                fclose($fh);
                return $csfLocal;
            }
            return false;
        }
        touch(ROOTDIR . "/modules/addons/dnssuite/dnssLocal.php");
        return false;
    }
    private function rewriteLocalLicense($license)
    {
        $fh = fopen(ROOTDIR . "/modules/addons/dnssuite/dnssLocal.php", "w+");
        fwrite($fh, $license);
        fclose($fh);
    }
    private function validateVersion($version)
    {
        if(self::$version <= $version) {
            $this->validVersion = true;
        } else {
            $this->validVersion = false;
        }
    }
    private function checkLicenseNow($licensekey, $localkey = "")
    {
        $whmcsurl = "http://dashboard.licensechef.com/";
        $licensing_secret_key = "2j4fh98fhdn4m2je0";
        $localkeydays = 5;
        $allowcheckfaildays = 2;
        $check_token = time() . md5(mt_rand(1000000000, 0) . $licensekey);
        $checkdate = date("Ymd");
        $domain = $_SERVER["SERVER_NAME"];
        $usersip = isset($_SERVER["SERVER_ADDR"]) ? $_SERVER["SERVER_ADDR"] : $_SERVER["LOCAL_ADDR"];
        $dirpath = dirname(__FILE__);
        $verifyfilepath = "modules/servers/licensing/verify.php";
        $localkeyvalid = false;
        if($localkey) {
            $localkey = str_replace("\n", "", $localkey);
            $localdata = substr($localkey, 0, strlen($localkey) - 32);
            $md5hash = substr($localkey, strlen($localkey) - 32);
            if($md5hash == md5($localdata . $licensing_secret_key)) {
                $localdata = strrev($localdata);
                $md5hash = substr($localdata, 0, 32);
                $localdata = substr($localdata, 32);
                $localdata = base64_decode($localdata);
                $localkeyresults = unserialize($localdata);
                $originalcheckdate = $localkeyresults["checkdate"];
                if($md5hash == md5($originalcheckdate . $licensing_secret_key)) {
                    $localexpiry = date("Ymd", mktime(0, 0, 0, date("m"), date("d") - $localkeydays, date("Y")));
                    if($localexpiry < $originalcheckdate) {
                        $localkeyvalid = true;
                        $results = $localkeyresults;
                        $validdomains = explode(",", $results["validdomain"]);
                        if(!in_array($_SERVER["SERVER_NAME"], $validdomains)) {
                            $localkeyvalid = false;
                            $localkeyresults["status"] = "Invalid";
                            $results = [];
                        }
                        $validips = explode(",", $results["validip"]);
                        if(!in_array($usersip, $validips)) {
                            $localkeyvalid = false;
                            $localkeyresults["status"] = "Invalid";
                            $results = [];
                        }
                        $validdirs = explode(",", $results["validdirectory"]);
                        if(!in_array($dirpath, $validdirs)) {
                            $localkeyvalid = false;
                            $localkeyresults["status"] = "Invalid";
                            $results = [];
                        }
                    }
                }
            }
        }
        if(!$localkeyvalid) {
            $responseCode = 0;
            $postfields = ["licensekey" => $licensekey, "domain" => $domain, "ip" => $usersip, "dir" => $dirpath];
            if($check_token) {
                $postfields["check_token"] = $check_token;
            }
            $query_string = "";
            foreach ($postfields as $k => $v) {
                $query_string .= $k . "=" . urlencode($v) . "&";
            }
            if(function_exists("curl_exec")) {
                $ch = curl_init();
                curl_setopt($ch, CURLOPT_URL, $whmcsurl . $verifyfilepath);
                curl_setopt($ch, CURLOPT_POST, 1);
                curl_setopt($ch, CURLOPT_POSTFIELDS, $query_string);
                curl_setopt($ch, CURLOPT_TIMEOUT, 30);
                curl_setopt($ch, CURLOPT_RETURNTRANSFER, 1);
                $data = curl_exec($ch);
                $responseCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
                curl_close($ch);
            } else {
                $responseCodePattern = "/^HTTP\\/\\d+\\.\\d+\\s+(\\d+)/";
                $fp = @fsockopen($whmcsurl, 80, $errno, $errstr, 5);
                if($fp) {
                    $newlinefeed = "\r\n";
                    $header = "POST " . $whmcsurl . $verifyfilepath . " HTTP/1.0" . $newlinefeed;
                    $header .= "Host: " . $whmcsurl . $newlinefeed;
                    $header .= "Content-type: application/x-www-form-urlencoded" . $newlinefeed;
                    $header .= "Content-length: " . @strlen($query_string) . $newlinefeed;
                    $header .= "Connection: close" . $newlinefeed . $newlinefeed;
                    $header .= $query_string;
                    $data = $line = "";
                    @stream_set_timeout($fp, 20);
                    @fputs($fp, $header);
                    $status = @socket_get_status($fp);
                    while (!@feof($fp) && $status) {
                        $line = @fgets($fp, 1024);
                        $patternMatches = [];
                        if(!$responseCode && preg_match($responseCodePattern, trim($line), $patternMatches)) {
                            $responseCode = empty($patternMatches[1]) ? 0 : $patternMatches[1];
                        }
                        $data .= $line;
                        $status = @socket_get_status($fp);
                    }
                    @fclose($fp);
                }
            }
            if($responseCode != 200) {
                $localexpiry = date("Ymd", mktime(0, 0, 0, date("m"), date("d") - ($localkeydays + $allowcheckfaildays), date("Y")));
                if($localexpiry < $originalcheckdate) {
                    $results = $localkeyresults;
                } else {
                    $results = [];
                    $results["status"] = "Invalid";
                    $results["description"] = "Remote Check Failed";
                    return $results;
                }
            } else {
                preg_match_all("/<(.*?)>([^<]+)<\\/\\1>/i", $data, $matches);
                $results = [];
                foreach ($matches[1] as $k => $v) {
                    $results[$v] = $matches[2][$k];
                }
            }
            if(!is_array($results)) {
                exit("Invalid License Server Response");
            }
            if($results["md5hash"] && $results["md5hash"] != md5($licensing_secret_key . $check_token)) {
                $results["status"] = "Invalid";
                $results["description"] = "MD5 Checksum Verification Failed";
                return $results;
            }
            if($results["status"] == "Active") {
                $results["checkdate"] = $checkdate;
                $data_encoded = serialize($results);
                $data_encoded = base64_encode($data_encoded);
                $data_encoded = md5($checkdate . $licensing_secret_key) . $data_encoded;
                $data_encoded = strrev($data_encoded);
                $data_encoded = $data_encoded . md5($data_encoded . $licensing_secret_key);
                $data_encoded = wordwrap($data_encoded, 80, "\n", true);
                $results["localkey"] = $data_encoded;
            }
            $results["remotecheck"] = true;
        }
        unset($postfields);
        unset($data);
        unset($matches);
        unset($whmcsurl);
        unset($licensing_secret_key);
        unset($checkdate);
        unset($usersip);
        unset($localkeydays);
        unset($allowcheckfaildays);
        unset($md5hash);
        $this->status = $results["status"];
        $this->product = $results["productname"];
        if($results["remotecheck"]) {
            $this->rewriteLocalLicense($results["localkey"]);
        }
        $pattern = "/Owned/";
        if(preg_match($pattern, $results["productname"])) {
            $pattern2 = "/valid_version=+([0-9\\.]+)/";
            preg_match_all($pattern2, $results[customfields], $matches);
            $valid = implode($matches[1]);
            $this->validateVersion($valid);
        }
        $pattern = "/Leased/";
        if(preg_match($pattern, $results["productname"])) {
            $this->validVersion = true;
        }
        return $results;
    }
}
class DAFunctions
{
    public $socket;
    public $da;
    public $zoneinfo;
    public $debuginfo;
    public function __construct($da)
    {
        require_once ROOTDIR . "/modules/addons/dnssuite/class/class.daapi.php";
        $this->socket = new \DAAPI\HTTPSocket();
        $this->da = $da;
        if($this->da["usessl"] == "on") {
            $newhost = "ssl://" . $this->da["server"];
        } else {
            $newhost = "http://" . $this->da["server"];
        }
        $this->ConnectDAServer($newhost);
    }
    public function ActivateLE($vars)
    {
        $this->socket->query("/CMD_API_SSL", ["domain" => idn_to_ascii($vars["domain"]), "action" => "save", "type" => "create", "request" => "letsencrypt", "name" => idn_to_ascii($vars["domain"]), "keysize" => "secp384r1", "encryption" => "SHA256", "le_select0" => idn_to_ascii($vars["domain"]), "le_select1" => "www." . idn_to_ascii($vars["domain"]), "submit" => "save"]);
        $result = $this->socket->fetch_body();
    }
    public function AddCatchall($vars)
    {
        $this->socket->query("/CMD_API_EMAIL_CATCH_ALL", ["domain" => idn_to_ascii($vars["domain"]), "action" => "CMD_CHANGE_INFO", "value" => $vars["mailto"], "catch" => "address", "update" => "Update"]);
        $result = $this->socket->fetch_body();
        if(preg_match("/error=0/", $result)) {
            return true;
        }
        $this->debuginfo = $result;
        return false;
    }
    public function AddDomain($domain)
    {
        $params = ["action" => "create", "ubandwidth" => "unlimited", "uquota" => "unlimited", "domain" => idn_to_ascii($domain), "cgi" => "OFF"];
        if($this->da["php"] == "on") {
            $params["php"] = "on";
        }
        if($this->da["webssl"] == "on") {
            $params["ssl"] = "on";
        }
        $this->socket->query("/CMD_API_DOMAIN", $params);
        $result = $this->socket->fetch_body();
        logModuleCall("DNSSuite", "Created Domain", "Domain: " . idn_to_ascii($domain), $result, $processedData, $replaceVars);
        if(preg_match("/error=0/", $result)) {
            if($this->da["php"] == "on") {
                $this->socket->query("/CMD_API_DOMAIN", ["action" => "modify", "php" => "ON", "domain" => idn_to_ascii($domain)]);
            }
            if($this->da["webssl"] == "on") {
                $this->socket->query("/CMD_API_DOMAIN?json=yes", ["action" => "modify", "ubandwidth" => "unlimited", "uquota" => "unlimited", "ssl" => "ON", "domain" => idn_to_ascii($domain)]);
                $result = $this->socket->fetch_body();
                $result = (array) json_decode($result);
                if($result["success"] == "The domain has been modified") {
                    $this->socket->query("/CMD_API_DOMAIN?json=yes", ["action" => "private_html", "name" => "symlink", "domain" => idn_to_ascii($domain)]);
                    $result = $this->socket->fetch_body();
                    $result = (array) json_decode($result);
                    if($result["success"] == "Setting changed") {
                        $this->socket->query("/CMD_API_SSL?json=yes", ["action" => "save", "type" => "create", "submit" => "save", "request" => "letsencrypt", "name" => idn_to_ascii($domain), "keysize" => 4096, "encryption" => "sha256", "le_select0" => idn_to_ascii($domain), "domain" => idn_to_ascii($domain)]);
                        $result = $this->socket->fetch_body();
                        $result = (array) json_decode($result);
                        if($result["success"] == "Certificate and Key Saved.") {
                            logModuleCall("DNSSuite", "Request SSL: Success requesting LE during domain creation", "Domain: " . idn_to_ascii($domain), $result, $processedData, $replaceVars);
                        } else {
                            logModuleCall("DNSSuite", "Request SSL: Failed requesting LE during domain creation", "Domain: " . idn_to_ascii($domain), $result, $processedData, $replaceVars);
                        }
                    } else {
                        logModuleCall("DNSSuite", "Request SSL: Failed symlink during domain creation", "Domain: " . idn_to_ascii($domain), $result, $processedData, $replaceVars);
                    }
                } else {
                    logModuleCall("DNSSuite", "Request SSL: Failed enabling SSL during domain creation", "Domain: " . idn_to_ascii($domain), $result, $processedData, $replaceVars);
                }
            }
            return true;
        }
        $this->debuginfo = $result;
        return false;
    }
    public function AddForwarder($vars)
    {
        $this->socket->query("/CMD_API_EMAIL_FORWARDERS", ["domain" => idn_to_ascii($vars["domain"]), "action" => "create", "user" => $vars["alias"], "email" => $vars["mailto"]]);
        $result = $this->socket->fetch_body();
        logModuleCall("DNSSuite", "Add Forwarder", "Domain: " . idn_to_ascii($vars["domain"]) . "\nAlias: " . $vars["alias"] . "\nTo: " . $vars["mailto"], $result, $processedData, $replaceVars);
        if(preg_match("/error=0/", $result)) {
            return true;
        }
        $this->debuginfo = $result;
        return false;
    }
    public function AddRow($vars)
    {
        unset($this->zoneinfo);
        if($vars["mode"] == "A") {
            $this->socket->query("/CMD_API_DNS_CONTROL", ["domain" => idn_to_ascii($vars["domain"]), "action" => "add", "type" => $vars["mode"], "name" => $vars["host"], "value" => $vars["value"]]);
        } elseif($vars["mode"] == "AAAA") {
            $this->socket->query("/CMD_API_DNS_CONTROL", ["domain" => idn_to_ascii($vars["domain"]), "action" => "add", "type" => $vars["mode"], "name" => $vars["host"], "value" => $vars["value"]]);
        } elseif($vars["mode"] == "CNAME") {
            if(preg_match("/\\./", $vars["value"]) && substr($vars["value"], -1) != ".") {
                $vars["value"] = $vars["value"] . ".";
            }
            $this->socket->query("/CMD_API_DNS_CONTROL", ["domain" => idn_to_ascii($vars["domain"]), "action" => "add", "type" => "CNAME", "name" => $vars["host"], "value" => $vars["value"]]);
        } elseif($vars["mode"] == "TXT") {
            $vars["value"] = str_replace("'", "", $vars["value"]);
            $vars["value"] = str_replace("\"", "", $vars["value"]);
            $vars["value"] = "\"" . $vars["value"] . "\"";
            $this->socket->query("/CMD_API_DNS_CONTROL", ["domain" => idn_to_ascii($vars["domain"]), "action" => "add", "type" => "TXT", "name" => $vars["host"], "value" => $vars["value"]]);
        } elseif($vars["mode"] == "MX") {
            $this->socket->query("/CMD_API_DNS_CONTROL", ["domain" => idn_to_ascii($vars["domain"]), "action" => "add", "type" => "MX", "name" => $vars["host"], "value" => $vars["priority"], "mx_value" => $vars["value"]]);
        } elseif($vars["mode"] == "NS") {
            if(substr($vars["value"], -1) != ".") {
                $vars["value"] = $vars["value"] . ".";
            }
            $this->socket->query("/CMD_API_DNS_CONTROL", ["domain" => idn_to_ascii($vars["domain"]), "action" => "add", "type" => "NS", "value" => $vars["host"], "name" => $vars["value"]]);
        } elseif($vars["mode"] == "SRV") {
            if(substr($vars["value"], -1) != ".") {
                $vars["value"] = $vars["value"] . ".";
            }
            $value = $vars["priority"] . " " . $vars["weight"] . " " . $vars["port"] . " " . $vars["value"];
            $this->socket->query("/CMD_API_DNS_CONTROL", ["domain" => idn_to_ascii($vars["domain"]), "action" => "add", "type" => "SRV", "name" => $vars["host"], "value" => $value]);
        }
        $result = $this->socket->fetch_body();
        logModuleCall("DNSSuite", "Add Record", "Domain: " . idn_to_ascii($vars["domain"]) . "\nType: " . $vars["mode"] . "\nHost: " . $vars["host"] . "\nValue: " . $vars["value"] . "\nExtended Value: " . $value, $result, $processedData, $replaceVars);
        if(preg_match("/error=0/", $result)) {
            return true;
        }
        $this->debuginfo = $result;
        return false;
    }
    public function AddRedirect($vars)
    {
        $this->socket->query("/CMD_API_REDIRECT", ["domain" => idn_to_ascii($vars["domain"]), "action" => "add", "from" => $vars["from"], "to" => $vars["to"], "type" => $vars["type"]]);
        logModuleCall("DNSSuite", "Add Redirection", "Domain: " . idn_to_ascii($vars["domain"]) . "\nFrom: " . $vars["from"] . "\nTo: " . $vars["to"] . "\nType: " . $vars["type"], $result, $processedData, $replaceVars);
        $result = $this->socket->fetch_body();
        if(preg_match("/error=0/", $result)) {
            return true;
        }
        $this->debuginfo = $result;
        return false;
    }
    public function ChangeTTL($vars)
    {
        $this->socket->query("/CMD_API_DNS_CONTROL", ["domain" => idn_to_ascii($vars["domain"]), "action" => "ttl", "ttl_select" => "custom", "ttl" => $vars["defaultttl"]]);
        $result = $this->socket->fetch_body();
        if(preg_match("/error=0/", $result)) {
            return true;
        }
        $this->debuginfo = $result;
        return false;
    }
    public function DeleteDomain($domain)
    {
        $this->socket->query("/CMD_API_DOMAIN", ["delete" => "yes", "confirmed" => "Confirm", "delete_data" => "yes", "select0" => idn_to_ascii($domain)]);
        $result = $this->socket->fetch_body();
        logModuleCall("DNSSuite", "Delete Domain", "Domain: " . idn_to_ascii($vars["domain"]), $result, $processedData, $replaceVars);
        if(preg_match("/error=0/", $result)) {
            return true;
        }
        $this->debuginfo = $result;
        return false;
    }
    public function DeleteForwarder($vars)
    {
        $this->socket->query("/CMD_API_EMAIL_FORWARDERS", ["domain" => idn_to_ascii($vars["domain"]), "action" => "delete", "select0" => $vars["alias"]]);
        $result = $this->socket->fetch_body();
        logModuleCall("DNSSuite", "Delete Forwarder", "Domain: " . idn_to_ascii($vars["domain"]) . "\nAlias: " . $vars["alias"], $result, $processedData, $replaceVars);
        if(preg_match("/error=0/", $result)) {
            return true;
        }
    }
    public function DeleteTemplate($domain)
    {
        $path = "/domains/" . $domain . "/public_html";
        $this->socket->query("/CMD_API_FILE_MANAGER", ["action" => "multiple", "button" => "delete", "path" => $path, "select0" => $path . "/400.shtml", "select1" => $path . "/401.shtml", "select2" => $path . "/403.shtml", "select3" => $path . "/404.shtml", "select4" => $path . "/500.shtml", "select5" => $path . "/index.html", "select6" => $path . "/logo.png", "select7" => $path . "/cgi-bin"]);
        $result = $this->socket->fetch_body();
        if(preg_match("/error=0/", $result)) {
            return true;
        }
        $this->debuginfo = $result;
        return false;
    }
    public function DeleteDefaultNameservers($vars)
    {
        $deletearray = [];
        $deletearray["domain"] = idn_to_ascii($vars["domain"]);
        $deletearray["action"] = "select";
        for ($i = 0; $i < count($vars["zone"]["ns"]); $i++) {
            $deletearray["nsrecs" . $vars["zone"]["ns"][$i][5]] = "name=" . $vars["zone"]["ns"][$i][0] . "&value=" . $vars["zone"]["ns"][$i][4];
        }
        $this->socket->query("/CMD_API_DNS_CONTROL", $deletearray);
        $result = $this->socket->fetch_body();
        if(preg_match("/error=0/", $result)) {
            return true;
        }
        $this->debuginfo = $result;
        return false;
    }
    public function DeleteRow($vars)
    {
        if($vars["mode"] == "A") {
            $row = "arecs" . $vars["row"];
        } elseif($vars["mode"] == "NS") {
            $row = "nsrecs" . $vars["row"];
        } elseif($vars["mode"] == "MX") {
            $row = "mxrecs" . $vars["row"];
        } elseif($vars["mode"] == "CNAME") {
            $row = "cnamerecs" . $vars["row"];
        } elseif($vars["mode"] == "TXT") {
            $row = "txtrecs" . $vars["row"];
        } elseif($vars["mode"] == "AAAA") {
            $row = "aaaarecs" . $vars["row"];
        } elseif($vars["mode"] == "SRV") {
            $row = "srvrecs" . $vars["row"];
        }
        if($vars["mode"] == "TXT") {
            $vars["value"] = str_replace("'", "", $vars["value"]);
            $vars["value"] = str_replace("\"", "", $vars["value"]);
            $vars["record"] = "name=" . $vars["host"] . "&value=\"" . $vars["value"] . "\"";
        } elseif($vars["mode"] == "MX") {
            $vars["record"] = "name=" . $vars["host"] . "&value=" . $vars["priority"] . " " . $vars["value"];
        } else {
            $vars["record"] = "name=" . $vars["host"] . "&value=" . $vars["value"];
        }
        $this->socket->query("/CMD_API_DNS_CONTROL", ["domain" => idn_to_ascii($vars["domain"]), "action" => "select", (string) $row => $vars["record"]]);
        $result = $this->socket->fetch_body();
        logModuleCall("DNSSuite", "Delete Record", "Domain: " . idn_to_ascii($vars["domain"]) . "\nType: " . $vars["mode"] . "\nHost: " . $vars["host"] . "\nValue: " . $vars["value"] . "\nExtended Value: " . $value, $result, $processedData, $replaceVars);
        if(preg_match("/error=0/", $result)) {
            return true;
        }
        $this->debuginfo = $result;
        return false;
    }
    public function DeleteAllRows($vars)
    {
        $deletearray = [];
        $deletearray["domain"] = idn_to_ascii($vars["domain"]);
        $deletearray["action"] = "select";
        if(!empty($vars["zone"]["a"])) {
            for ($i = 0; $i < count($vars["zone"]["a"]); $i++) {
                $deletearray["arecs" . $vars["zone"]["a"][$i][5]] = "name=" . $vars["zone"]["a"][$i][0] . "&value=" . $vars["zone"]["a"][$i][4];
            }
        }
        if(!empty($vars["zone"]["aaaa"])) {
            for ($i = 0; $i < count($vars["zone"]["aaaa"]); $i++) {
                $deletearray["aaaarecs" . $vars["zone"]["aaaa"][$i][5]] = "name=" . $vars["zone"]["aaaa"][$i][0] . "&value=" . $vars["zone"]["aaaa"][$i][4];
            }
        }
        if(!empty($vars["zone"]["cname"])) {
            for ($i = 0; $i < count($vars["zone"]["cname"]); $i++) {
                $deletearray["cnamerecs" . $vars["zone"]["cname"][$i][5]] = "name=" . $vars["zone"]["cname"][$i][0] . "&value=" . $vars["zone"]["cname"][$i][4];
            }
        }
        if(!empty($vars["zone"]["mx"])) {
            for ($i = 0; $i < count($vars["zone"]["mx"]); $i++) {
                $deletearray["mxrecs" . $vars["zone"]["mx"][$i][6]] = "name=" . $vars["zone"]["mx"][$i][0] . "&value=" . $vars["zone"]["mx"][$i][4] . " " . $vars["zone"]["mx"][$i][5];
            }
        }
        if(!empty($vars["zone"]["txt"])) {
            for ($i = 0; $i < count($vars["zone"]["txt"]); $i++) {
                $vars["zone"]["txt"][$i][4] = str_replace("'", "", $vars["zone"]["txt"][$i][4]);
                $vars["zone"]["txt"][$i][4] = str_replace("\"", "", $vars["zone"]["txt"][$i][4]);
                $deletearray["txtrecs" . $vars["zone"]["txt"][$i][5]] = "name=" . $vars["zone"]["txt"][$i][0] . "&value=\"" . $vars["zone"]["txt"][$i][4] . "\"";
            }
        }
        if(!empty($vars["zone"]["srv"])) {
            for ($i = 0; $i < count($vars["zone"]["srv"]); $i++) {
                $deletearray["srvrecs" . $vars["zone"]["srv"][$i][8]] = "name=" . $vars["zone"]["srv"][$i][0] . "&value=" . $vars["zone"]["srv"][$i][4] . " " . $vars["zone"]["srv"][$i][5] . " " . $vars["zone"]["srv"][$i][6] . " " . $vars["zone"]["srv"][$i][7];
            }
        }
        $this->socket->query("/CMD_API_DNS_CONTROL", $deletearray);
        $result = $this->socket->fetch_body();
        if(preg_match("/error=0/", $result)) {
            return true;
        }
        $this->debuginfo = $result;
        return false;
    }
    public function DeleteRedirect($vars)
    {
        $this->socket->query("/CMD_API_REDIRECT", ["domain" => idn_to_ascii($vars["domain"]), "action" => "delete", "select0" => $vars["from"]]);
        $result = $this->socket->fetch_body();
        logModuleCall("DNSSuite", "Delete Redirection", "Domain: " . idn_to_ascii($vars["domain"]) . "\nFrom: " . $vars["from"], $result, $processedData, $replaceVars);
        if(preg_match("/error=0/", $result)) {
            return true;
        }
        $this->debuginfo = $result;
        return false;
    }
    public function DisableCatchall($vars)
    {
        $this->socket->query("/CMD_API_EMAIL_CATCH_ALL", ["domain" => idn_to_ascii($vars["domain"]), "action" => "CMD_CHANGE_INFO", "catch" => ":fail:", "update" => "Update"]);
        $result = $this->socket->fetch_body();
        logModuleCall("DNSSuite", "Disable Catchall", "Domain: " . idn_to_ascii($vars["domain"]), $result, $processedData, $replaceVars);
        if(preg_match("/error=0/", $result)) {
            return true;
        }
        $this->debuginfo = $result;
        return false;
    }
    public function ExtractTemplate($domain)
    {
        $path = "/domains/" . $domain . "/public_html";
        $this->socket->query("/CMD_API_FILE_MANAGER", ["action" => "extract", "path" => "/" . $this->da["template"], "page" => "2", "type" => "zip", "directory" => $path . "/"]);
        $result = $this->socket->fetch_body();
        if(!preg_match("/error=0/", $result)) {
            return true;
        }
        $this->debuginfo = $result;
    }
    public function GetCatchAll($domain)
    {
        $this->socket->query("/CMD_API_EMAIL_CATCH_ALL", ["domain" => idn_to_ascii($domain)]);
        $result = $this->socket->fetch_body();
        $result = urldecode($result);
        if($result) {
            $result = explode("&", $result);
            for ($i = 0; $i < count($result); $i++) {
                $row = explode("=", $result[$i]);
                $newrow[] = $row[1];
            }
            return $newrow[0];
        }
        $this->debuginfo = $result;
    }
    public function GetDomains()
    {
        $this->socket->query("/CMD_API_SHOW_DOMAINS?json=yes", []);
        $result = $this->socket->fetch_body();
        $domainsarray = json_decode($result);
        if(!empty($domainsarray)) {
            for ($i = 0; $i < count($domainsarray); $i++) {
                $domains[] = idn_to_utf8($domainsarray[$i]);
            }
        }
        return $domains;
    }
    public function GetForwarders($domain)
    {
        $this->socket->query("/CMD_API_EMAIL_FORWARDERS", ["domain" => idn_to_ascii($domain)]);
        $result = $this->socket->fetch_body();
        $result = urldecode($result);
        if($result) {
            $result = explode("&", $result);
            for ($i = 0; $i < count($result); $i++) {
                $row = explode("=", $result[$i]);
                $newrow[] = ["alias" => $row[0], "forwardemail" => $row[1]];
            }
            return $newrow;
        }
        $this->debuginfo = $result;
    }
    public function GetRedirect($domain)
    {
        $this->socket->query("/CMD_API_REDIRECT?domain=" . idn_to_ascii($domain) . "&apitype=yes");
        $result = $this->socket->fetch_body();
        if($result) {
            $result = urldecode($result);
            $result = explode("&/", $result);
            for ($i = 0; $i < count($result); $i++) {
                $rows = explode("=", $result[$i]);
                $type = explode("&", $rows[2]);
                $rows[2] = $type[0];
                $newrow[] = $rows;
            }
            $rows = $newrow;
            for ($i = 0; $i < count($rows); $i++) {
                if($rows[$i][0] != "/") {
                    $rows[$i][0] = str_replace("/", "", $rows[$i][0]);
                }
                if(1 < count($rows[$i])) {
                    for ($z = 2; $z < count($rows[$i]); $z++) {
                        $newrow[$i] = $newrow[$i] . "=" . $rows[$i][$z];
                    }
                }
                $rows[$i][1] = $rows[$i][1] . $newrow[$i];
            }
            return $rows;
        }
        $this->debuginfo = $result;
    }
    public function GetZone($domain)
    {
        unset($this->zoneinfo);
        $this->socket->query("/CMD_API_DNS_CONTROL", ["domain" => idn_to_ascii($domain)]);
        $result = $this->socket->fetch_body();
        $zone = explode("\n", $result);
        if(!empty($zone)) {
            for ($i = 0; $i < count($zone); $i++) {
                if($zone[$i] != "" && !preg_match("/TTL \\d+/", $zone[$i])) {
                    $newzone[] = $zone[$i];
                }
            }
        }
        if(!empty($newzone)) {
            for ($i = 0; $i < count($newzone); $i++) {
                if(preg_match("/\\(/", $newzone[$i])) {
                    $begin = true;
                }
                if(preg_match("/SOA/", $newzone[$i])) {
                    $isSOA = true;
                }
                if(preg_match("/\\)/", $newzone[$i])) {
                    $end = true;
                }
                if($begin && !$end) {
                    $serialine = $serialine . trim(preg_replace("/\\t+/", " ", $newzone[$i]));
                } elseif($begin && $end) {
                    unset($begin);
                    unset($end);
                    unset($isSOA);
                    if(!$isSOA) {
                        $serialine = $serialine . trim(preg_replace("/\\t+/", " ", $newzone[$i]));
                        $newzone2[] = $serialine;
                        unset($serialine);
                    }
                } else {
                    $newzone2[] = trim(preg_replace("/\\t+/", " ", $newzone[$i]));
                }
            }
        }
        if(!empty($newzone2)) {
            for ($i = 0; $i < count($newzone2); $i++) {
                if(!preg_match("/@\t  IN\t  SOA/", $newzone2[$i])) {
                    $newzone3[] = $newzone2[$i];
                }
            }
        }
        if(!empty($newzone3)) {
            for ($i = 0; $i < count($newzone3); $i++) {
                $newzone3[$i] = str_replace("( ", "", $newzone3[$i]);
                $newzone3[$i] = str_replace("\"\"", "", $newzone3[$i]);
                $newzone3[$i] = str_replace(" )", "", $newzone3[$i]);
            }
        }
        return $newzone3;
    }
    public function ParseZone($zone)
    {
        if(!empty($zone)) {
            for ($i = 0; $i < count($zone); $i++) {
                if(preg_match("/SOA/", $zone[$i])) {
                    $this->zoneinfo["soa"][] = $zone[$i];
                }
                if(preg_match("/IN A/", $zone[$i])) {
                    $this->zoneinfo["a"][] = $zone[$i];
                }
                if(preg_match("/IN NS/", $zone[$i])) {
                    $this->zoneinfo["ns"][] = $zone[$i];
                }
                if(preg_match("/IN CNAME/", $zone[$i])) {
                    $this->zoneinfo["cname"][] = $zone[$i];
                }
                if(preg_match("/IN MX/", $zone[$i])) {
                    $this->zoneinfo["mx"][] = $zone[$i];
                }
                if(preg_match("/IN TXT/", $zone[$i])) {
                    $this->zoneinfo["txt"][] = $zone[$i];
                }
                if(preg_match("/IN AAAA/", $zone[$i])) {
                    $this->zoneinfo["aaaa"][] = $zone[$i];
                }
                if(preg_match("/IN PTR/", $zone[$i])) {
                    $this->zoneinfo["ptr"][] = $zone[$i];
                }
                if(preg_match("/IN SRV/", $zone[$i])) {
                    $this->zoneinfo["srv"][] = $zone[$i];
                }
            }
        }
        if(!empty($this->zoneinfo["a"])) {
            for ($i = 0; $i < count($this->zoneinfo["a"]); $i++) {
                $tmprow = explode(" ", $this->zoneinfo["a"][$i]);
                if($tmprow[3] == "A") {
                    $rowarray[] = $this->zoneinfo["a"][$i];
                }
            }
            $this->zoneinfo["a"] = $rowarray;
        }
        return $this->zoneinfo;
    }
    public function RequestSSL($vars)
    {
        $domain = $vars["domain"];
        $this->socket->query("/CMD_API_DOMAIN?json=yes", ["action" => "modify", "ubandwidth" => "unlimited", "uquota" => "unlimited", "ssl" => "ON", "domain" => idn_to_ascii($domain)]);
        $result = $this->socket->fetch_body();
        $result = (array) json_decode($result);
        if($result["success"] == "The domain has been modified") {
            $this->socket->query("/CMD_API_DOMAIN?json=yes", ["action" => "private_html", "name" => "symlink", "domain" => idn_to_ascii($domain)]);
            $result = $this->socket->fetch_body();
            $result = (array) json_decode($result);
            if($result["success"] == "Setting changed") {
                $this->socket->query("/CMD_API_SSL?json=yes", ["action" => "save", "type" => "create", "submit" => "save", "request" => "letsencrypt", "name" => idn_to_ascii($domain), "keysize" => 4096, "encryption" => "sha256", "le_select0" => idn_to_ascii($domain), "domain" => idn_to_ascii($domain)]);
                $result = $this->socket->fetch_body();
                $result = (array) json_decode($result);
                if($result["success"] == "Certificate and Key Saved.") {
                    logModuleCall("DNSSuite", "Request SSL: Success requesting LE", "Domain: " . idn_to_ascii($domain), $result, $processedData, $replaceVars);
                    return true;
                }
                logModuleCall("DNSSuite", "Request SSL: Failed requesting LE", "Domain: " . idn_to_ascii($domain), $result, $processedData, $replaceVars);
                return false;
            }
            logModuleCall("DNSSuite", "Request SSL: Failed symlink", "Domain: " . idn_to_ascii($domain), $result, $processedData, $replaceVars);
            return false;
        }
        logModuleCall("DNSSuite", "Request SSL: Failed enabling SSL", "Domain: " . idn_to_ascii($domain), $result, $processedData, $replaceVars);
        return false;
    }
    private function ConnectDAServer($host)
    {
        if(preg_match("/\\d+/", $this->da["port"])) {
            $this->socket->connect($host, $this->da["port"]);
        } else {
            $this->socket->connect($host, 2222);
        }
        $this->socket->set_login($this->da["login"], $this->da["password"]);
        $this->socket->set_method("POST");
    }
}

?>