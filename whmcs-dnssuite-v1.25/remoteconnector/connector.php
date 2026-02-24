<?php
require_once ("connector_settings.php");

//Verification
if ($_POST["hash"] == hash('sha512', $hash.$_POST["time"]) && (time() - $_POST["time"] < 900)){
    $title = html_entity_decode($_POST["title"]);
    $meta = html_entity_decode($_POST["meta"]);
    $keywords = html_entity_decode($_POST["keywords"]);
    $to = html_entity_decode($_POST["to"]);

    $template = '<html><head><title>'.$title.'</title><meta name="description" content="'.$meta.'"> <meta name="keywords" content="'.$keywords.'"> </head> <frameset rows="100%,0" border="0"> <frame src="'.$to.'" frameborder="0"> <frame frameborder="0"> </frameset> </html>';

    $path = html_entity_decode($_POST["from"]);
    //Clear / at beginning
    if (substr($path, 0, 1) == "/") $path = substr($path, 1);
    //Clear / at the end
    if (substr($path, -1) == "/") $path = rtrim($path, "/");


    if ($_POST["action"] == "modify"){
        if ($path == ""){
            if (file_exists("index.html")){
                $fh = fopen('index.html','r');
                while ($line = fgets($fh)) $newline[] = $line;
                fclose($fh);

                for ($i=0;$i<count($newline);$i++) $newline[$i] = preg_replace('/http:\/\/([\w\.\-\/\_\~]+)/', $to, $newline[$i] );
                $template = implode($newline);
                $myfile = fopen("index.html", "w");
                if (fwrite($myfile, $template)){
                    fclose($myfile);
                    echo json_encode(array("status"=>1));
                }else echo json_encode(array("status"=>0));
                die();
            }else echo json_encode(array("status"=>0));
            die();
        }else{
            if ((file_exists($path."/index.html"))){
                $fh = fopen($path.'/index.html','r');
                while ($line = fgets($fh)) $newline[] = $line;
                fclose($fh);

                for ($i=0;$i<count($newline);$i++) $newline[$i] = preg_replace('/http:\/\/([\w\.\-\/\_\~]+)/', $to, $newline[$i] );
                $template = implode($newline);

                $myfile = fopen($path."/index.html", "w");
                if (fwrite($myfile, $template)){
                    fclose($myfile);
                    echo json_encode(array("status"=>1));
                }else echo json_encode(array("status"=>0));
            }else echo json_encode(array("status"=>0));
        }
    }elseif ($_POST["action"] == "delete"){
        if ($path == "") {
            if (file_exists("index.html")) {
                if (unlink("index.html")) echo json_encode(array("status"=>1));
            }else echo json_encode(array("status"=>1));
        }else{
            if (file_exists($path."/index.html")){
                if (unlink($path."/index.html")) echo json_encode(array("status"=>1));
            }else echo json_encode(array("status"=>1));
        }
        die();
    }else{
        if ($path == ""){
            if (file_exists("index.html")) unlink("index.html");

            $myfile = fopen("index.html", "w");
            if (fwrite($myfile, $template)){
                fclose($myfile);
                echo json_encode(array("status"=>1));
            }else echo json_encode(array("status"=>0));
            die();
        }else{
            if (!file_exists($path)){
                if (mkdir($path, 0755, true)){
                    $myfile = fopen($path."/index.html", "w");
                    if (fwrite($myfile, $template)){
                        fclose($myfile);
                        echo json_encode(array("status"=>1));
                    }else echo json_encode(array("status"=>0));
                }
            }else{
                if (file_exists($path."/index.html")) unlink($path."/index.html");

                $myfile = fopen($path."/index.html", "w");
                if (fwrite($myfile, $template)){
                    fclose($myfile);
                    echo json_encode(array("status"=>1));
                }else echo json_encode(array("status"=>0));
            }
        }
    }
}else echo json_encode(array("status"=>0));
?>