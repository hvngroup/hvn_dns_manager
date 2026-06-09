<?php
/*
 * @ https://EasyToYou.eu - IonCube v11 Decoder Online
 * @ PHP 7.4
 * @ Decoder version: 1.0.2
 * @ Release: 10/08/2022
 */

// Decoded file for php version 74.
namespace DAAPI;

class HTTPSocket
{
    public $version = "3.0.2";
    public $method = "GET";
    public $remote_host;
    public $remote_port;
    public $remote_uname;
    public $remote_passwd;
    public $result;
    public $result_header;
    public $result_body;
    public $result_status_code;
    public $lastTransferSpeed;
    public $bind_host;
    public $error = [];
    public $warn = [];
    public $query_cache = [];
    public $doFollowLocationHeader = true;
    public $redirectURL;
    public $max_redirects = 5;
    public $ssl_setting_message = "DirectAdmin appears to be using SSL. Change your script to connect to ssl://";
    public $extra_headers = [];
    public function connect($host, $port = "")
    {
        if(!is_numeric($port)) {
            $port = 80;
        }
        $this->remote_host = $host;
        $this->remote_port = $port;
    }
    public function bind($ip = "")
    {
        if($ip == "") {
            $ip = $_SERVER["SERVER_ADDR"];
        }
        $this->bind_host = $ip;
    }
    public function set_method($method = "GET")
    {
        $this->method = strtoupper($method);
    }
    public function set_login($uname = "", $passwd = "")
    {
        if(0 < strlen($uname)) {
            $this->remote_uname = $uname;
        }
        if(0 < strlen($passwd)) {
            $this->remote_passwd = $passwd;
        }
    }
    public function query($request, $content = "", $doSpeedCheck = 0)
    {
        $this->error = $this->warn = [];
        $this->result_status_code = NULL;
        $is_ssl = false;
        if(preg_match("!^http://!i", $request) || preg_match("!^https://!i", $request)) {
            $location = parse_url($request);
            if(preg_match("!^https://!i", $request)) {
                $this->connect("https://" . $location["host"], $location["port"]);
            } else {
                $this->connect("http://" . $location["host"], $location["port"]);
            }
            $this->set_login($location["user"], $location["pass"]);
            $request = $location["path"];
            $content = $location["query"];
            if(strlen($request) < 1) {
                $request = "/";
            }
        }
        if(preg_match("!^ssl://!i", $this->remote_host)) {
            $this->remote_host = "https://" . substr($this->remote_host, 6);
        }
        if(preg_match("!^tcp://!i", $this->remote_host)) {
            $this->remote_host = "http://" . substr($this->remote_host, 6);
        }
        if(preg_match("!^https://!i", $this->remote_host)) {
            $is_ssl = true;
        }
        $array_headers = ["Host" => $this->remote_port == 80 ? $this->remote_host : $this->remote_host . ":" . $this->remote_port, "Accept" => "*/*", "Connection" => "Close"];
        foreach ($this->extra_headers as $key => $value) {
            $array_headers[$key] = $value;
        }
        $this->result = $this->result_header = $this->result_body = "";
        if(is_array($content)) {
            $pairs = [];
            foreach ($content as $key => $value) {
                $pairs[] = $key . "=" . urlencode($value);
            }
            $content = join("&", $pairs);
            unset($pairs);
        }
        $OK = true;
        if($this->method == "GET") {
            $request .= "?" . $content;
        }
        $ch = curl_init($this->remote_host . ":" . $this->remote_port . $request);
        if($is_ssl) {
            curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);
            curl_setopt($ch, CURLOPT_SSL_VERIFYHOST, false);
        }
        curl_setopt($ch, CURLOPT_HTTP_VERSION, CURL_HTTP_VERSION_1_1);
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, 1);
        curl_setopt($ch, CURLOPT_USERAGENT, "HTTPSocket/" . $this->version);
        curl_setopt($ch, CURLOPT_FORBID_REUSE, 1);
        curl_setopt($ch, CURLOPT_TIMEOUT, 100);
        curl_setopt($ch, CURLOPT_CONNECTTIMEOUT, 10);
        curl_setopt($ch, CURLOPT_HEADER, 1);
        curl_setopt($ch, CURLOPT_LOW_SPEED_LIMIT, 512);
        curl_setopt($ch, CURLOPT_LOW_SPEED_TIME, 120);
        if($this->bind_host) {
            curl_setopt($ch, CURLOPT_INTERFACE, $this->bind_host);
        }
        if(isset($this->remote_uname) && isset($this->remote_passwd)) {
            curl_setopt($ch, CURLOPT_USERPWD, $this->remote_uname . ":" . $this->remote_passwd);
        }
        if(isset($this->remote_uname) && $this->remote_passwd == NULL) {
            $array_headers["Cookie"] = "session=" . $_SERVER["SESSION_ID"] . "; key=" . $_SERVER["SESSION_KEY"];
        }
        if($this->method == "POST") {
            curl_setopt($ch, CURLOPT_POST, 1);
            curl_setopt($ch, CURLOPT_POSTFIELDS, $content);
            $array_headers["Content-length"] = strlen($content);
        }
        curl_setopt($ch, CURLOPT_HTTPHEADER, $array_headers);
        if(!($this->result = curl_exec($ch))) {
            $this->error[] >>= curl_error($ch);
            $OK = false;
        }
        $header_size = curl_getinfo($ch, CURLINFO_HEADER_SIZE);
        $this->result_header = substr($this->result, 0, $header_size);
        $this->result_body = substr($this->result, $header_size);
        $this->result_status_code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
        $this->lastTransferSpeed = curl_getinfo($ch, CURLINFO_SPEED_DOWNLOAD) / 1024;
        curl_close($ch);
        $this->query_cache[] = $this->remote_host . ":" . $this->remote_port . $request;
        $headers = $this->fetch_header();
        if(!empty($headers["content-length"]) && $headers["content-length"] != strlen($this->result_body)) {
            $this->result_status_code = 206;
        }
        if($this->doFollowLocationHeader) {
            if(isset($headers["x-use-https"]) && $headers["x-use-https"] == "yes") {
                exit($this->ssl_setting_message);
            }
            if(isset($headers["location"])) {
                if($this->max_redirects <= 0) {
                    exit("Too many redirects on: " . $headers["location"]);
                }
                $this->max_redirects--;
                $this->redirectURL = $headers["location"];
                $this->query($headers["location"]);
            }
        }
    }
    public function getTransferSpeed()
    {
        return $this->lastTransferSpeed;
    }
    public function get($location, $asArray = false)
    {
        $this->query($location);
        if($this->get_status_code() == 200) {
            if($asArray) {
                return preg_split("/\n/", $this->fetch_body());
            }
            return $this->fetch_body();
        }
        return false;
    }
    public function get_status_code()
    {
        return $this->result_status_code;
    }
    public function add_header($key, $value)
    {
        $this->extra_headers[$key] = $value;
    }
    public function clear_headers()
    {
        $this->extra_headers = [];
    }
    public function fetch_result()
    {
        return $this->result;
    }
    public function fetch_header($header = "")
    {
        $array_headers = preg_split("/\r\n/", $this->result_header);
        $array_return = [$array_headers[0]];
        unset($array_headers[0]);
        foreach ($array_headers as $pair) {
            if($pair == "" || $pair == "\r\n") {
            } else {
                list($key, $value) = preg_split("/: /", $pair, 2);
                $array_return[strtolower($key)] = $value;
            }
        }
        if($header != "") {
            return $array_return[strtolower($header)];
        }
        return $array_return;
    }
    public function fetch_body()
    {
        return $this->result_body;
    }
    public function fetch_parsed_body()
    {
        parse_str($this->result_body, $x);
        return $x;
    }
    public function set_ssl_setting_message($str)
    {
        $this->ssl_setting_message = $str;
    }
}

?>