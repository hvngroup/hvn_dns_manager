<link type="text/css" rel="stylesheet" href="modules/addons/dnssuite/templates/css/bootstrap.vertical-tabs.min.css" />
<link type="text/css" rel="stylesheet" href="modules/addons/dnssuite/templates/css/tabs.css" />
<link type="text/css" rel="stylesheet" href="modules/addons/dnssuite/templates/css/modal.css" />
<script src="modules/addons/dnssuite/templates/js/bootstrap-notify.min.js"></script>
<link type="text/css" rel="stylesheet" href="modules/addons/dnssuite/templates/css/animate.css" />
<link href="https://cdnjs.cloudflare.com/ajax/libs/select2/4.0.6-rc.0/css/select2.min.css" rel="stylesheet" />
<script src="https://cdnjs.cloudflare.com/ajax/libs/select2/4.0.6-rc.0/js/select2.min.js"></script>
<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/jquery-confirm/3.3.0/jquery-confirm.min.css">
<script src="https://cdnjs.cloudflare.com/ajax/libs/jquery-confirm/3.3.0/jquery-confirm.min.js"></script>
<script src="modules/addons/dnssuite/templates/js/functions.js"></script>
{literal}
<script>
        var modulelink = '{/literal}{$modulelink}{literal}';
        var modifyword = '{/literal}{$ADDONLANG.dnssuitePage_manage_modify}{literal}';
        var deleteword = '{/literal}{$ADDONLANG.dnssuitePage_manage_delete}{literal}';
        var updateword = '{/literal}{$ADDONLANG.dnssuitePage_manage_update}{literal}';
        var addword = '{/literal}{$ADDONLANG.dnssuitePage_manage_addrecord}{literal}';
        var hostword = '{/literal}{$ADDONLANG.dnssuitePage_manage_host}{literal}';
        var destinationword = '{/literal}{$ADDONLANG.dnssuitePage_manage_destinationhost}{literal}';
        var ipword = '{/literal}{$ADDONLANG.dnssuitePage_manage_ip}{literal}';
        var priorityword = '{/literal}{$ADDONLANG.dnssuitePage_manage_priority}{literal}';
        var weightword = '{/literal}{$ADDONLANG.dnssuitePage_manage_weight}{literal}';
        var portword = '{/literal}{$ADDONLANG.dnssuitePage_manage_port}{literal}';
        var word301 = '{/literal}{$ADDONLANG.dnssuitePage_manage_301}{literal}';
        var word302 = '{/literal}{$ADDONLANG.dnssuitePage_manage_302}{literal}';
        var word303 = '{/literal}{$ADDONLANG.dnssuitePage_manage_303}{literal}';
        var word999 = '{/literal}{$ADDONLANG.dnssuitePage_manage_999}{literal}';
        var setredirectword = '{/literal}{$ADDONLANG.dnssuitePage_manage_setredirect}{literal}';
        var verifyword = '{/literal}{$ADDONLANG.dnssuitePage_manage_verify}{literal}';
        var destinationemailword = '{/literal}{$ADDONLANG.dnssuitePage_manage_destinationplaceholder}{literal}';
        var addemailword = '{/literal}{$ADDONLANG.dnssuitePage_manage_addemail}{literal}';
        var addaliasword = '{/literal}{$ADDONLANG.dnssuitePage_manage_addalias}{literal}';
        var aliasplaceholder = '{/literal}{$ADDONLANG.dnssuitePage_manage_newalias}{literal}';
        var catchallstatusword = '{/literal}{$ADDONLANG.dnssuitePage_manage_catchall_status}{literal}';
        var catchalloffword = '{/literal}{$ADDONLANG.dnssuitePage_manage_catchall_status_off}{literal}';
        var catchallonword = '{/literal}{$ADDONLANG.dnssuitePage_manage_catchall_status_on}{literal}';
        var domainid = '{/literal}{$domainid}{literal}';
        var domaindot = '{/literal}{$domaindot}{literal}';
        var domainname = '{/literal}{$domain}{literal}';
        {/literal}
        {if $urlconfig["masked"] == "on"}
            var havemasked = true;
            var wordpagetitle = '{$ADDONLANG.dnssuitePage_manage_pagetitle}';
            var wordmeta = '{$ADDONLANG.dnssuitePage_manage_meta}';
            var wordkeywords = '{$ADDONLANG.dnssuitePage_manage_keywords}';
        {else}
            var havemasked = false;
        {/if}
        {if $records_a.modify == "on"}
            {if $records_a.limit == 0}
                var limits_a = 0;
            {else}
                var limits_a = {$records_a.limit};
            {/if}
        {/if}
        {if $records_aaaa.modify == "on"}
            {if $records_aaaa.limit == 0}
                var limits_aaaa = 0;
            {else}
                var limits_aaaa = {$records_aaaa.limit};
            {/if}
        {/if}
        {if $records_mx.modify == "on"}
            {if $records_mx.limit == 0}
                var limits_mx = 0;
            {else}
                var limits_mx = {$records_mx.limit};
            {/if}
        {/if}
        {if $records_cname.modify == "on"}
            {if $records_cname.limit == 0}
                var limits_cname = 0;
            {else}
                var limits_cname = {$records_cname.limit};
            {/if}
        {/if}
        {if $records_txt.modify == "on"}
            {if $records_txt.limit == 0}
                var limits_txt = 0;
            {else}
                var limits_txt = {$records_txt.limit};
            {/if}
        {/if}
        {if $records_srv.modify == "on"}
            {if $records_srv.limit == 0}
                var limits_srv = 0;
            {else}
                var limits_srv = {$records_srv.limit};
            {/if}
        {/if}
        {if $records_ns.modify == "on"}
            {if $records_ns.limit == 0}
                var limits_ns = 0;
            {else}
                var limits_ns = {$records_ns.limit};
            {/if}
        {/if}
        {if $urlconfig["enable"] == "on" && $edition != "free"}
            {if $urlconfig["limit"] == 0}
                var limits_redirect = 0;
            {else}
                var limits_redirect = {$urlconfig["limit"]};
            {/if}
        {/if}

        {if $emailconfig["enable"] == "on" && $edition != "free"}
            {if $emailconfig["slotlimit"] == 0}
                var limits_emailslots = 0;
            {else}
                var limits_emailslots = {$emailconfig.slotlimit};
            {/if}
            {if $emailconfig["limit"] == 0}
                var limits_alias = 0;
            {else}
                var limits_alias = {$emailconfig.limit};
            {/if}
        {/if}

        {if $subdomain.enable == "on"}
            {if $subdomain.limit == 0}
                var limits_subdomains = 0;
            {else}
                var limits_subdomains = {$subdomain.limit};
            {/if}
        {/if}

        {literal}
            $(function() {
                $("#switchNSbtn").tooltip();
                $("#resetDOMAINbtn").tooltip();
                $("#clearDNSbtn").tooltip();
                $("#restoreDNSTEMPLATEbtn").tooltip();
                $("#createUSERDNSTEMPLATEbtn").tooltip();
                $("#APIbtn").tooltip();
                $("#redirectbtn").tooltip();
                $("#forwarderbtn").tooltip();
                $("#catchallbtn").tooltip();
            });
        {/literal}

        {if $clientletsencrypt == "on"}
            {literal}
                $(document).on("click", '.clientLETSENCRYPTbtn',function(e){
                    e.preventDefault();
                    $.ajax({
                        type: "POST",
                        url: "modules/addons/dnssuite/include/dnssuite_ajax.php",
                        data: { domainid: domainid, action: "requestSSL"},
                        success:function(result){
                            var result = JSON.parse(result);
                            if (result.status == 0){
                                $.notify({message: '{/literal}{$ADDONLANG.dnssuitePage_manage_overview_requestssl_failed}{literal}'},{type: 'danger',delay: 5000,timer: 1000,newest_on_top: true,animate: {enter: 'animated fadeInDown',exit: 'animated fadeOutDown'},});
                                return false;
                            }else if (result.status == 1){
                                $.notify({message: '{/literal}{$ADDONLANG.dnssuitePage_manage_overview_requestssl_success}{literal}'},{type: 'success',delay: 5000,timer: 1000,newest_on_top: true,animate: {enter: 'animated fadeInDown',exit: 'animated fadeOutDown'},});
                                var arraydata = result.data;
                                
                                return false;
                            }
                        }});
                });

                $(function() {
                    $("#requestSSL-tip").tooltip();
                });
            {/literal}
        {/if}

        {if $configs.enablednseditor == "on"}
        {literal}
        $(document).ready(function(){
            $(document).on("click", '.deletebtn',function(e){
                e.preventDefault();
                var row = $(this).val();
                var mode = $(this).attr('id');
                $('#deletemodal').modal({
                backdrop: 'static',
                keyboard: true
                }).one('click', '#deletebutton', function(e) {
                    $.ajax({
                        type: "POST",
                        url: "modules/addons/dnssuite/include/dnssuite_ajax.php",
                        data: { domainid: domainid, mode: mode, row: row, action: "deleteRecord"},
                        success:function(result){
                            var result = JSON.parse(result);
                            if (result.status == 0){
                                $.notify({message: '{/literal}{$ADDONLANG.dnssuitePage_manage_dns_updaterecord_failed}{literal}'},{type: 'danger',delay: 5000,timer: 1000,newest_on_top: true,animate: {enter: 'animated fadeInDown',exit: 'animated fadeOutDown'},});
                                return false;
                            }else if (result.status == 1){
                                $.notify({message: '{/literal}{$ADDONLANG.dnssuitePage_manage_dns_updaterecord_success}{literal}'},{type: 'success',delay: 5000,timer: 1000,newest_on_top: true,animate: {enter: 'animated fadeInDown',exit: 'animated fadeOutDown'},});
                                var arraydata = result.data;
                                if (mode == "A"){
                                    if (result.count < limits_a || limits_a == 0) var write = true;
                                    else var write = false;
                                    $("#Atable").find("tr:gt(0)").remove();
                                    BuildTable(arraydata, mode, write);
                                    document.getElementById("Acount").innerHTML = result.count;
                                }else if (mode == "AAAA"){
                                    if (result.count < limits_aaaa || limits_aaaa == 0) var write = true;
                                    else var write = false;
                                    $("#AAAAtable").find("tr:gt(0)").remove();
                                    BuildTable(arraydata, mode, write);
                                    document.getElementById("AAAAcount").innerHTML = result.count;
                                }else if (mode == "CNAME"){
                                    if (result.count < limits_cname || limits_cname == 0) var write = true;
                                    else var write = false;
                                    $("#CNAMEtable").find("tr:gt(0)").remove();
                                    BuildTable(arraydata, mode, write);
                                    document.getElementById("CNAMEcount").innerHTML = result.count;
                                }else if (mode == "NS"){
                                    if (result.count < limits_ns || limits_ns == 0) var write = true;
                                    else var write = false;
                                    $("#NStable").find("tr:gt(0)").remove();
                                    BuildTable(arraydata, mode, write);
                                    document.getElementById("NScount").innerHTML = result.count;
                                }else if (mode == "TXT"){
                                    if (result.count < limits_txt || limits_txt == 0) var write = true;
                                    else var write = false;
                                    $("#TXTtable").find("tr:gt(0)").remove();
                                    BuildTable(arraydata, mode, write);
                                    document.getElementById("TXTcount").innerHTML = result.count;
                                }else if (mode == "MX"){
                                    if (result.count < limits_mx || limits_mx == 0) var write = true;
                                    else var write = false;
                                    $("#MXtable").find("tr:gt(0)").remove();
                                    BuildTable(arraydata, mode, write);
                                    document.getElementById("MXcount").innerHTML = result.count;
                                }else if (mode == "SRV"){
                                    if (result.count < limits_srv || limits_srv == 0) var write = true;
                                    else var write = false;
                                    $("#SRVtable").find("tr:gt(0)").remove();
                                    BuildTable(arraydata, mode, write);
                                    document.getElementById("SRVcount").innerHTML = result.count;
                                }
                                return false;
                            }
                    }});
                });
            });

            $(document).on("click", '.addAbtn',function(e){
                e.preventDefault();
                var ipformat = /^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$/;
                var ipformat = /^(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])$/;
                var hostname = /^((([a-zA-Z0-9]|[\*])|[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z0-9])\.)*([A-Za-z0-9]|[A-Za-z0-9][A-Za-z0-9\-]*[A-Za-z0-9])$/;

                if (document.getElementById("addA-host").value == ""){
                    $('#validateaddresp').html('invalid hostname');
                    document.getElementById("addA-host").focus();
                    document.getElementById("validateresp").innerHTML = {/literal}"{$ADDONLANG.dnssuitePage_manage_js_hostfieldempty}"{literal}+" "+document.getElementById("addA-host").value;
                    $('#myModal').modal('show');
                    return false;
                }
                if (document.getElementById("addA-value").value == ""){
                    $('#validateaddresp').html('invalid value');
                    document.getElementById("addA-value").focus();
                    document.getElementById("validateresp").innerHTML = {/literal}"{$ADDONLANG.dnssuitePage_manage_js_valuefieldempty}"{literal}+" "+document.getElementById("addA-value").value;
                    $('#myModal').modal('show');
                    return false;
                }
                if (document.getElementById("addA-value").value.match(ipformat)){
                    if (document.getElementById("addA-host").value.match(hostname) || document.getElementById("addA-host").value == "{/literal}{$domain}.{literal}" || document.getElementById("addA-host").value == "*"){
                        $.ajax({
                            type: "POST",
                            url: "modules/addons/dnssuite/include/dnssuite_ajax.php",
                            data: { domainid: domainid, host: document.getElementById("addA-host").value, value: document.getElementById("addA-value").value, action: "addA"},
                            success:function(result){
                                var result = JSON.parse(result);
                                if (result.status == 0){
                                    $.notify({message: '{/literal}{$ADDONLANG.dnssuitePage_manage_dns_addrecord_failed}{literal}'},{type: 'danger',delay: 5000,timer: 1000,newest_on_top: true,animate: {enter: 'animated fadeInDown',exit: 'animated fadeOutDown'},});
                                    return false;
                                }else if (result.status == 1){
                                    $.notify({message: '{/literal}{$ADDONLANG.dnssuitePage_manage_dns_addrecord_success}{literal}'},{type: 'success',delay: 5000,timer: 1000,newest_on_top: true,animate: {enter: 'animated fadeInDown',exit: 'animated fadeOutDown'},});
                                    var arraydata = result.data;
                                    if (result.count < limits_a || limits_a == 0) var write = true;
                                    else var write = false;
                                    $("#Atable").find("tr:gt(0)").remove();
                                    BuildTable(arraydata, "A", write);
                                    document.getElementById("Acount").innerHTML = result.count;
                                    return false;
                                }
                        }});
                    } else{
                        document.getElementById("addA-host").focus();
                        document.getElementById("validateresp").innerHTML = {/literal}"{$ADDONLANG.dnssuitePage_manage_js_invalidhostname}"{literal}+" "+document.getElementById("addA-host").value;
                        $('#myModal').modal('show');
                        return false;
                    }
                } else{
                    document.getElementById("addA-value").focus();
                    document.getElementById("validateresp").innerHTML = {/literal}"{$ADDONLANG.dnssuitePage_manage_js_a_ipv4_error}"{literal}+" "+document.getElementById("addA-value").value;
                    $('#myModal').modal('show');
                    return false;
                }

            });
            $(document).on("click", '.modifyAbtn',function(e){
                e.preventDefault();
                var row = $(this).val();
                var ipformat = /^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$/;
                var intrange = /^(\d+)$/;
                var ipformat = /^(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])$/;

                if(document.getElementById("A-"+row+"-value").value.match(ipformat)){
                    $.ajax({
                        type: "POST",
                        url: "modules/addons/dnssuite/include/dnssuite_ajax.php",
                        data: { domainid: domainid, value: document.getElementById("A-"+row+"-value").value, row: row, action: "modifyA"},
                        success:function(result){
                            var result = JSON.parse(result);
                            if (result.status == 0){
                                $.notify({message: '{/literal}{$ADDONLANG.dnssuitePage_manage_dns_updaterecord_failed}{literal}'},{type: 'danger',delay: 5000,timer: 1000,newest_on_top: true,animate: {enter: 'animated fadeInDown',exit: 'animated fadeOutDown'},});
                                return false;
                            }else if (result.status == 2){
                                $.notify({message: '{/literal}{$ADDONLANG.dnssuitePage_manage_dns_invalidhostvalue}{literal}'},{type: 'danger',delay: 5000,timer: 1000,newest_on_top: true,animate: {enter: 'animated fadeInDown',exit: 'animated fadeOutDown'},});
                                return false;
                            }else if (result.status == 1){
                                $.notify({message: '{/literal}{$ADDONLANG.dnssuitePage_manage_dns_updaterecord_success}{literal}'},{type: 'success',delay: 5000,timer: 1000,newest_on_top: true,animate: {enter: 'animated fadeInDown',exit: 'animated fadeOutDown'},});
                                var arraydata = result.data;
                                if (result.count < limits_a || limits_a == 0) var write = true;
                                else var write = false;
                                $("#Atable").find("tr:gt(0)").remove();
                                BuildTable(arraydata, "A", write);
                                document.getElementById("Acount").innerHTML = result.count;
                                return false;
                            }
                    }});
                } else{
                    document.getElementById("A-"+row+"-value").focus();
                    document.getElementById("validateresp").innerHTML = {/literal}"{$ADDONLANG.dnssuitePage_manage_js_a_ip_error}"{literal}+" "+document.getElementById("A-"+row+"-value").value;
                    $('#myModal').modal('show');
                    return false;
                }
            });

            $(document).on("click", '.addAAAAbtn',function(e){
                e.preventDefault();
                var ipformat = /^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$/;
                var ipformat = /^((([0-9A-Fa-f]{1,4}:){7}[0-9A-Fa-f]{1,4})|(([0-9A-Fa-f]{1,4}:){6}:[0-9A-Fa-f]{1,4})|(([0-9A-Fa-f]{1,4}:){5}:([0-9A-Fa-f]{1,4}:)?[0-9A-Fa-f]{1,4})|(([0-9A-Fa-f]{1,4}:){4}:([0-9A-Fa-f]{1,4}:){0,2}[0-9A-Fa-f]{1,4})|(([0-9A-Fa-f]{1,4}:){3}:([0-9A-Fa-f]{1,4}:){0,3}[0-9A-Fa-f]{1,4})|(([0-9A-Fa-f]{1,4}:){2}:([0-9A-Fa-f]{1,4}:){0,4}[0-9A-Fa-f]{1,4})|(([0-9A-Fa-f]{1,4}:){6}((\b((25[0-5])|(1\d{2})|(2[0-4]\d)|(\d{1,2}))\b)\.){3}(\b((25[0-5])|(1\d{2})|(2[0-4]\d)|(\d{1,2}))\b))|(([0-9A-Fa-f]{1,4}:){0,5}:((\b((25[0-5])|(1\d{2})|(2[0-4]\d)|(\d{1,2}))\b)\.){3}(\b((25[0-5])|(1\d{2})|(2[0-4]\d)|(\d{1,2}))\b))|(::([0-9A-Fa-f]{1,4}:){0,5}((\b((25[0-5])|(1\d{2})|(2[0-4]\d)|(\d{1,2}))\b)\.){3}(\b((25[0-5])|(1\d{2})|(2[0-4]\d)|(\d{1,2}))\b))|([0-9A-Fa-f]{1,4}::([0-9A-Fa-f]{1,4}:){0,5}[0-9A-Fa-f]{1,4})|(::([0-9A-Fa-f]{1,4}:){0,6}[0-9A-Fa-f]{1,4})|(([0-9A-Fa-f]{1,4}:){1,7}:))$/;
                hostname = /^((([a-zA-Z0-9]|[\*])|[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z0-9])\.)*([A-Za-z0-9]|[A-Za-z0-9][A-Za-z0-9\-]*[A-Za-z0-9])$/;

                if (document.getElementById("addAAAA-host").value == ""){
                    $('#validateaddresp').html('invalid hostname');
                    document.getElementById("addAAAA-host").focus();
                    document.getElementById("validateresp").innerHTML = {/literal}"{$ADDONLANG.dnssuitePage_manage_js_hostfieldempty}"{literal}+" "+document.getElementById("addAAAA-host").value;
                    $('#myModal').modal('show');
                    return false;
                }
                if (document.getElementById("addAAAA-value").value == ""){
                    $('#validateaddresp').html('invalid value');
                    document.getElementById("addAAAA-value").focus();
                    document.getElementById("validateresp").innerHTML = {/literal}"{$ADDONLANG.dnssuitePage_manage_js_valuefieldempty}"{literal}+" "+document.getElementById("addAAAA-value").value;
                    $('#myModal').modal('show');
                    return false;
                }
                if(document.getElementById("addAAAA-value").value.match(ipformat)){
                    if(document.getElementById("addAAAA-host").value.match(hostname) || document.getElementById("addAAAA-host").value == "{/literal}{$domain}.{literal}" || document.getElementById("addAAAA-host").value == "*"){
                        $.ajax({
                        type: "POST",
                        url: "modules/addons/dnssuite/include/dnssuite_ajax.php",
                        data: { domainid: domainid, host: document.getElementById("addAAAA-host").value, value: document.getElementById("addAAAA-value").value, action: "addAAAA"},
                        success:function(result){
                            var result = JSON.parse(result);
                            if (result.status == 0){
                                $.notify({message: '{/literal}{$ADDONLANG.dnssuitePage_manage_dns_addrecord_failed}{literal}'},{type: 'danger',delay: 5000,timer: 1000,newest_on_top: true,animate: {enter: 'animated fadeInDown',exit: 'animated fadeOutDown'},});
                                return false;
                            }else if (result.status == 2){
                                $.notify({message: '{/literal}{$ADDONLANG.dnssuitePage_manage_dns_invalidhostvalue}{literal}'},{type: 'danger',delay: 5000,timer: 1000,newest_on_top: true,animate: {enter: 'animated fadeInDown',exit: 'animated fadeOutDown'},});
                                return false;
                            }else if (result.status == 1){
                                var arraydata = result.data;
                                if (result.count < limits_aaaa || limits_aaaa == 0) var write = true;
                                else var write = false;
                                $("#AAAAtable").find("tr:gt(0)").remove();
                                BuildTable(arraydata, "AAAA", write);
                                $.notify({message: '{/literal}{$ADDONLANG.dnssuitePage_manage_dns_addrecord_success}{literal}'},{type: 'success',delay: 5000,timer: 1000,newest_on_top: true,animate: {enter: 'animated fadeInDown',exit: 'animated fadeOutDown'},});
                                document.getElementById("AAAAcount").innerHTML = result.count;
                                return false;
                            }
                        }});
                        return false;
                    }else{
                        document.getElementById("addAAAA-host").focus();
                        document.getElementById("validateresp").innerHTML = {/literal}"{$ADDONLANG.dnssuitePage_manage_js_invalidhostname}"{literal}+" "+document.getElementById("addAAAA-host").value;
                        $('#myModal').modal('show');
                        return false;
                    }
                }else{
                    document.getElementById("addAAAA-value").focus();
                    document.getElementById("validateresp").innerHTML = {/literal}"{$ADDONLANG.dnssuitePage_manage_js_aaaa_ipv6_error}"{literal}+" "+document.getElementById("addAAAA-value").value;
                    $('#myModal').modal('show');
                    return false;
                }
            });
            $(document).on("click", '.modifyAAAAbtn',function(e) {
                e.preventDefault();
                var row = $(this).val();
                var ipformat = /^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$/;
                var ipformat = /^((([0-9A-Fa-f]{1,4}:){7}[0-9A-Fa-f]{1,4})|(([0-9A-Fa-f]{1,4}:){6}:[0-9A-Fa-f]{1,4})|(([0-9A-Fa-f]{1,4}:){5}:([0-9A-Fa-f]{1,4}:)?[0-9A-Fa-f]{1,4})|(([0-9A-Fa-f]{1,4}:){4}:([0-9A-Fa-f]{1,4}:){0,2}[0-9A-Fa-f]{1,4})|(([0-9A-Fa-f]{1,4}:){3}:([0-9A-Fa-f]{1,4}:){0,3}[0-9A-Fa-f]{1,4})|(([0-9A-Fa-f]{1,4}:){2}:([0-9A-Fa-f]{1,4}:){0,4}[0-9A-Fa-f]{1,4})|(([0-9A-Fa-f]{1,4}:){6}((\b((25[0-5])|(1\d{2})|(2[0-4]\d)|(\d{1,2}))\b)\.){3}(\b((25[0-5])|(1\d{2})|(2[0-4]\d)|(\d{1,2}))\b))|(([0-9A-Fa-f]{1,4}:){0,5}:((\b((25[0-5])|(1\d{2})|(2[0-4]\d)|(\d{1,2}))\b)\.){3}(\b((25[0-5])|(1\d{2})|(2[0-4]\d)|(\d{1,2}))\b))|(::([0-9A-Fa-f]{1,4}:){0,5}((\b((25[0-5])|(1\d{2})|(2[0-4]\d)|(\d{1,2}))\b)\.){3}(\b((25[0-5])|(1\d{2})|(2[0-4]\d)|(\d{1,2}))\b))|([0-9A-Fa-f]{1,4}::([0-9A-Fa-f]{1,4}:){0,5}[0-9A-Fa-f]{1,4})|(::([0-9A-Fa-f]{1,4}:){0,6}[0-9A-Fa-f]{1,4})|(([0-9A-Fa-f]{1,4}:){1,7}:))$/;
                if(document.getElementById("AAAA-"+row+"-value").value.match(ipformat)){
                    $.ajax({
                        type: "POST",
                        url: "modules/addons/dnssuite/include/dnssuite_ajax.php",
                        data: { domainid: domainid, value: document.getElementById("AAAA-"+row+"-value").value, row: row, action: "modifyAAAA"},
                        success:function(result){
                            var result = JSON.parse(result);
                            if (result.status == 0){
                                $.notify({message: '{/literal}{$ADDONLANG.dnssuitePage_manage_dns_updaterecord_failed}{literal}'},{type: 'danger',delay: 5000,timer: 1000,newest_on_top: true,animate: {enter: 'animated fadeInDown',exit: 'animated fadeOutDown'},});
                                return false;
                            }else if (result.status == 3){
                                $.notify({message: '{/literal}{$ADDONLANG.dnssuitePage_manage_dns_invalidip}{literal}'},{type: 'danger',delay: 5000,timer: 1000,newest_on_top: true,animate: {enter: 'animated fadeInDown',exit: 'animated fadeOutDown'},});
                                return false;
                            }else if (result.status == 1){
                                $.notify({message: '{/literal}{$ADDONLANG.dnssuitePage_manage_dns_updaterecord_success}{literal}'},{type: 'success',delay: 5000,timer: 1000,newest_on_top: true,animate: {enter: 'animated fadeInDown',exit: 'animated fadeOutDown'},});
                                var arraydata = result.data;
                                if (result.count < limits_aaaa || limits_aaaa == 0) var write = true;
                                else var write = false;
                                $("#AAAAtable").find("tr:gt(0)").remove();
                                BuildTable(arraydata, "AAAA", write);
                                document.getElementById("AAAAcount").innerHTML = result.count;
                                return false;
                            }
                    }});
                    return false;
                }else{
                    document.getElementById("AAAA-"+row+"-value").focus();
                    document.getElementById("validateresp").innerHTML = {/literal}"{$ADDONLANG.dnssuitePage_manage_js_a_ip_error}"{literal}+" "+document.getElementById("AAAA-"+row+"-value").value;
                    $('#myModal').modal('show');
                    return false;
                }
            });

            $(document).on("click", '.addCNAMEbtn',function(e){
                e.preventDefault();
                var hostname = /^((([a-zA-Z0-9]|[\*])|[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z0-9])\.)*([A-Za-z0-9]|[A-Za-z0-9][A-Za-z0-9\-]*[A-Za-z0-9])$/;
                var hostnamedot = /^(([\_a-zA-Z0-9]|[a-zA-Z0-9][\_a-zA-Z0-9\-]*[a-zA-Z0-9])[\.|w])*([A-Za-z0-9]|[A-Za-z0-9][A-Za-z0-9\-\_]*[A-Za-z0-9]|[A-Za-z0-9\_][A-Za-z0-9\-\_]*[\_A-Za-z0-9][\.|\w])$/;
                if (document.getElementById("addCNAME-host").value == ""){
                    $('#validateaddresp').html('invalid hostname');
                    document.getElementById("addCNAME-host").focus();
                    document.getElementById("validateresp").innerHTML = {/literal}"{$ADDONLANG.dnssuitePage_manage_js_hostfieldempty}"{literal}+" "+document.getElementById("addCNAME-host").value;
                    $('#myModal').modal('show');
                    return false;
                }
                if (document.getElementById("addCNAME-value").value == ""){
                    $('#validateaddresp').html('invalid value');
                    document.getElementById("addCNAME-value").focus();
                    document.getElementById("validateresp").innerHTML = {/literal}"{$ADDONLANG.dnssuitePage_manage_js_valuefieldempty}"{literal}+" "+document.getElementById("addCNAME-value").value;
                    $('#myModal').modal('show');
                    return false;
                }
                if(document.getElementById("addCNAME-host").value.match(hostname) || document.getElementById("addCNAME-host").value.match(hostnamedot) || document.getElementById("addCNAME-host").value == "*"){
                    if(document.getElementById("addCNAME-host").value.match(hostnamedot)){
                        $.ajax({
                        type: "POST",
                        url: "modules/addons/dnssuite/include/dnssuite_ajax.php",
                        data: { domainid: document.getElementById("addCNAME-domainid").value, host: document.getElementById("addCNAME-host").value, value: document.getElementById("addCNAME-value").value, action: "addCNAME"},
                        success:function(result){
                            var result = JSON.parse(result);
                            if (result.status == 0){
                                $.notify({message: '{/literal}{$ADDONLANG.dnssuitePage_manage_dns_addrecord_failed}{literal}'},{type: 'danger',delay: 5000,timer: 1000,newest_on_top: true,animate: {enter: 'animated fadeInDown',exit: 'animated fadeOutDown'},});
                                return false;
                            }else if (result.status == 2){
                                $.notify({message: '{/literal}{$ADDONLANG.dnssuitePage_manage_dns_invalidhostname}{literal}'},{type: 'danger',delay: 5000,timer: 1000,newest_on_top: true,animate: {enter: 'animated fadeInDown',exit: 'animated fadeOutDown'},});
                                return false;
                            }else if (result.status == 3){
                                $.notify({message: '{/literal}{$ADDONLANG.dnssuitePage_manage_dns_invaliddestinationvalue}{literal}'},{type: 'danger',delay: 5000,timer: 1000,newest_on_top: true,animate: {enter: 'animated fadeInDown',exit: 'animated fadeOutDown'},});
                                return false;
                            }else if (result.status == 1){
                                var arraydata = result.data;
                                if (result.count < limits_cname || limits_cname == 0) var write = true;
                                else var write = false;
                                $("#CNAMEtable").find("tr:gt(0)").remove();
                                BuildTable(arraydata, "CNAME", write);
                                $.notify({message: '{/literal}{$ADDONLANG.dnssuitePage_manage_dns_addrecord_success}{literal}'},{type: 'success',delay: 5000,timer: 1000,newest_on_top: true,animate: {enter: 'animated fadeInDown',exit: 'animated fadeOutDown'},});
                                document.getElementById("CNAMEcount").innerHTML = result.count;
                                return false;
                            }
                        }});
                    }else{
                        document.getElementById("addCNAME-value").focus();
                        document.getElementById("validateresp").innerHTML = {/literal}"{$ADDONLANG.dnssuitePage_manage_js_invalidhostname}"{literal}+" "+document.getElementById("addCNAME-value").value;
                        $('#myModal').modal('show');
                        return false;
                    }
                }else{
                    document.getElementById("addCNAME-host").focus();
                    document.getElementById("validateresp").innerHTML = {/literal}"{$ADDONLANG.dnssuitePage_manage_js_invalidhostname}"{literal}+" "+document.getElementById("addCNAME-host").value;
                    $('#myModal').modal('show');
                    return false;
                }
            });
            $(document).on("click", '.modifyCNAMEbtn',function(e){
                var row = $(this).val();
                var hostname = /^(([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z0-9])\.)*([A-Za-z0-9]|[A-Za-z0-9][A-Za-z0-9\-]*[A-Za-z0-9])$/;
                var hostnamedot = /^(([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z0-9])\.)*([A-Za-z0-9]|[A-Za-z0-9][A-Za-z0-9\-]*[A-Za-z0-9]|[A-Za-z0-9][A-Za-z0-9\-]*[A-Za-z0-9]\.)$/;
                if(document.getElementById("CNAME-"+row+"-value").value.match(hostnamedot) || document.getElementById("CNAME-"+row+"-value").value.match(hostname)){
                    $.ajax({
                        type: "POST",
                        url: "modules/addons/dnssuite/include/dnssuite_ajax.php",
                        data: { domainid: domainid, value: document.getElementById("CNAME-"+row+"-value").value, row: row, action: "modifyCNAME"},
                        success:function(result){
                            var result = JSON.parse(result);
                            if (result.status == 0){
                                $.notify({message: '{/literal}{$ADDONLANG.dnssuitePage_manage_dns_updaterecord_failed}{literal}'},{type: 'danger',delay: 5000,timer: 1000,newest_on_top: true,animate: {enter: 'animated fadeInDown',exit: 'animated fadeOutDown'},});
                                return false;
                            }else if (result.status == 3){
                                $.notify({message: '{/literal}{$ADDONLANG.dnssuitePage_manage_dns_invaliddestinationvalue}{literal}'},{type: 'danger',delay: 5000,timer: 1000,newest_on_top: true,animate: {enter: 'animated fadeInDown',exit: 'animated fadeOutDown'},});
                                return false;
                            }else if (result.status == 1){
                                $.notify({message: '{/literal}{$ADDONLANG.dnssuitePage_manage_dns_updaterecord_success}{literal}'},{type: 'success',delay: 5000,timer: 1000,newest_on_top: true,animate: {enter: 'animated fadeInDown',exit: 'animated fadeOutDown'},});
                                var arraydata = result.data;
                                if (result.count < limits_cname || limits_cname == 0) var write = true;
                                else var write = false;
                                $("#CNAMEtable").find("tr:gt(0)").remove();
                                BuildTable(arraydata, "CNAME", write);
                                document.getElementById("CNAMEcount").innerHTML = result.count;
                                return false;
                            }
                    }});
                    return false;
                }else{
                    document.getElementById("CNAME"+row+"-host").focus();
                    document.getElementById("validateresp").innerHTML = {/literal}"{$ADDONLANG.dnssuitePage_manage_js_invalidhostname}"{literal}+" "+document.getElementById("CNAME-"+row+"-host").value;
                    $('#myModal').modal('show');
                    return false;
                }
            });

            $(document).on("click", '.addNSbtn',function(e){
                e.preventDefault();
                var hostname = /^(([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z0-9])\.)*([A-Za-z0-9]|[A-Za-z0-9][A-Za-z0-9\-]*[A-Za-z0-9])$/;
                var hostnamedot = /^(([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z0-9])\.)*([A-Za-z0-9]|[A-Za-z0-9][A-Za-z0-9\-]*[A-Za-z0-9]|[A-Za-z0-9][A-Za-z0-9\-]*[A-Za-z0-9]\.)$/;
                if (document.getElementById("addNS-host").value == ""){
                    $('#validateaddresp').html('invalid hostname');
                    document.getElementById("addNS-host").focus();
                    document.getElementById("validateresp").innerHTML = {/literal}"{$ADDONLANG.dnssuitePage_manage_js_hostfieldempty}"{literal}+" "+document.getElementById("addNS-host").value;
                    $('#myModal').modal('show');
                    return false;
                }
                if (document.getElementById("addNS-value").value == ""){
                    $('#validateaddresp').html('invalid value');
                    document.getElementById("addNS-value").focus();
                    document.getElementById("validateresp").innerHTML = {/literal}"{$ADDONLANG.dnssuitePage_manage_js_valuefieldempty}"{literal}+" "+document.getElementById("addNS-value").value;
                    $('#myModal').modal('show');
                    return false;
                }
                if (document.getElementById("addNS-host").value == "{/literal}{$domain}{literal}."){
                    document.getElementById("addNS-host").focus();
                    document.getElementById("validateresp").innerHTML = {/literal}"{$ADDONLANG.dnssuitePage_manage_js_nsnodomain}"{literal}+" "+document.getElementById("addNS-host").value;
                    $('#myModal').modal('show');
                    return false
                }
                if(document.getElementById("addNS-host").value.match(hostname) || document.getElementById("addNS-host").value.match(hostnamedot)){
                    if(document.getElementById("addNS-value").value.match(hostnamedot)){
                        $.ajax({
                        type: "POST",
                        url: "modules/addons/dnssuite/include/dnssuite_ajax.php",
                        data: { domainid: document.getElementById("addNS-domainid").value, host: document.getElementById("addNS-host").value, value: document.getElementById("addNS-value").value, action: "addNS"},
                        success:function(result){
                            var result = JSON.parse(result);
                            if (result.status == 0){
                                $.notify({message: '{/literal}{$ADDONLANG.dnssuitePage_manage_dns_addrecord_failed}{literal}'},{type: 'danger',delay: 5000,timer: 1000,newest_on_top: true,animate: {enter: 'animated fadeInDown',exit: 'animated fadeOutDown'},});
                                return false;
                            }else if (result.status == 2){
                                $.notify({message: '{/literal}{$ADDONLANG.dnssuitePage_manage_dns_invalidhostname}{literal}'},{type: 'danger',delay: 5000,timer: 1000,newest_on_top: true,animate: {enter: 'animated fadeInDown',exit: 'animated fadeOutDown'},});
                                return false;
                            }else if (result.status == 3){
                                $.notify({message: '{/literal}{$ADDONLANG.dnssuitePage_manage_dns_invaliddestinationvalue}{literal}'},{type: 'danger',delay: 5000,timer: 1000,newest_on_top: true,animate: {enter: 'animated fadeInDown',exit: 'animated fadeOutDown'},});
                                return false;
                            }else if (result.status == 1){
                                var arraydata = result.data;
                                if (result.count < limits_ns || limits_ns == 0) var write = true;
                                else var write = false;
                                $("#NStable").find("tr:gt(0)").remove();
                                BuildTable(arraydata, "NS", write);
                                $.notify({message: '{/literal}{$ADDONLANG.dnssuitePage_manage_dns_addrecord_success}{literal}'},{type: 'success',delay: 5000,timer: 1000,newest_on_top: true,animate: {enter: 'animated fadeInDown',exit: 'animated fadeOutDown'},});
                                document.getElementById("NScount").innerHTML = result.count;
                                return false;
                            }
                        }});
                    }else{
                        document.getElementById("addNS-value").focus();
                        document.getElementById("validateresp").innerHTML = {/literal}"{$ADDONLANG.dnssuitePage_manage_js_invalidhostname}"{literal}+" "+document.getElementById("addNS-value").value;
                        $('#myModal').modal('show');
                        return false;
                    }
                }else{
                    document.getElementById("addNS-host").focus();
                    document.getElementById("validateresp").innerHTML = {/literal}"{$ADDONLANG.dnssuitePage_manage_js_invalidhostname}{literal}"+" "+document.getElementById("addNS-host").value;
                    $('#myModal').modal('show');
                    return false;
                }
            });
            $(document).on("click", '.modifyNSbtn',function(e){
                var row = $(this).val();
                var hostname = /^(([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z0-9])\.)*([A-Za-z0-9]|[A-Za-z0-9][A-Za-z0-9\-]*[A-Za-z0-9])$/;
                var hostnamedot = /^(([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z0-9])\.)*([A-Za-z0-9]|[A-Za-z0-9][A-Za-z0-9\-]*[A-Za-z0-9]|[A-Za-z0-9][A-Za-z0-9\-]*[A-Za-z0-9]\.)$/;
                if(document.getElementById("NS-"+row+"-value").value.match(hostnamedot) || document.getElementById("NS-"+row+"-value").value.match(hostname)){
                   $.ajax({
                        type: "POST",
                        url: "modules/addons/dnssuite/include/dnssuite_ajax.php",
                        data: { domainid: domainid, value: document.getElementById("NS-"+row+"-value").value, row: row, action: "modifyNS"},
                        success:function(result){
                            var result = JSON.parse(result);
                            if (result.status == 0){
                                $.notify({message: '{/literal}{$ADDONLANG.dnssuitePage_manage_dns_updaterecord_failed}{literal}'},{type: 'danger',delay: 5000,timer: 1000,newest_on_top: true,animate: {enter: 'animated fadeInDown',exit: 'animated fadeOutDown'},});
                                return false;
                            }else if (result.status == 3){
                                $.notify({message: '{/literal}{$ADDONLANG.dnssuitePage_manage_dns_invaliddestinationvalue}{literal}'},{type: 'danger',delay: 5000,timer: 1000,newest_on_top: true,animate: {enter: 'animated fadeInDown',exit: 'animated fadeOutDown'},});
                                return false;
                            }else if (result.status == 1){
                                $.notify({message: '{/literal}{$ADDONLANG.dnssuitePage_manage_dns_updaterecord_success}{literal}'},{type: 'success',delay: 5000,timer: 1000,newest_on_top: true,animate: {enter: 'animated fadeInDown',exit: 'animated fadeOutDown'},});
                                var arraydata = result.data;
                                if (result.count < limits_ns || limits_ns == 0) var write = true;
                                else var write = false;
                                $("#NStable").find("tr:gt(0)").remove();
                                BuildTable(arraydata, "NS", write);
                                document.getElementById("NScount").innerHTML = result.count;
                                return false;
                            }
                    }});
                    return false;
                }else{
                    document.getElementById("NS-"+row+"-value").focus();
                    document.getElementById("validateresp").innerHTML = {/literal}"{$ADDONLANG.dnssuitePage_manage_js_invalidhostname}"{literal}+" "+document.getElementById("NS-"+row+"-value").value;
                    $('#myModal').modal('show');
                    return false;
                }
            });

            $(document).on("click", '.addTXTbtn',function(e) {
                e.preventDefault();
                var hostname = /^(([a-zA-Z0-9]|[a-zA-Z0-9\_][a-zA-Z0-9\-]*[a-zA-Z0-9])\.)*([A-Za-z0-9]|[A-Za-z0-9\_][A-Za-z0-9\-\_]*[A-Za-z0-9\_\.]*)$/;
                var hostnamedot = /^(([a-zA-Z0-9_]|[a-zA-Z0-9_][a-zA-Z0-9\-_]*[a-zA-Z0-9_])\.)*([A-Za-z0-9]|[A-Za-z0-9_][A-Za-z0-9\-_]*[A-Za-z0-9_]|[A-Za-z0-9_][A-Za-z0-9\-_]*[A-Za-z0-9_]\.)$/;
                var txtvalue = /^[a-zA-Z0-9!#$%&()\\\*+,.\/:;<=>?@\[\] ^_`{|}~-]*$/;

                if (document.getElementById("addTXT-host").value == ""){
                    $('#validateaddresp').html('invalid hostname');
                    document.getElementById("addTXT-host").focus();
                    document.getElementById("validateresp").innerHTML = {/literal}"{$ADDONLANG.dnssuitePage_manage_js_hostfieldempty}"{literal}+" "+document.getElementById("addTXT-host").value;
                    $('#myModal').modal('show');
                    return false;
                }
                if (document.getElementById("addTXT-value").value == ""){
                    $('#validateaddresp').html('invalid value');
                    document.getElementById("addTXT-value").focus();
                    document.getElementById("validateresp").innerHTML = {/literal}"{$ADDONLANG.dnssuitePage_manage_js_valuefieldempty}"{literal}+" "+document.getElementById("addTXT-value").value;
                    $('#myModal').modal('show');
                    return false;
                }
                if(document.getElementById("addTXT-value").value.match(txtvalue)){
                    if(document.getElementById("addTXT-host").value.match(hostname) || document.getElementById("addTXT-host").value == "{/literal}{$domain}.{literal}" || document.getElementById("addTXT-host").value == "*"){
                        if(document.getElementById("addTXT-host").value.match(hostnamedot) || document.getElementById("addTXT-host").value == "*"){
                            $.ajax({
                                type: "POST",
                                url: "modules/addons/dnssuite/include/dnssuite_ajax.php",
                                data: { domainid: document.getElementById("addTXT-domainid").value, host: document.getElementById("addTXT-host").value, value: document.getElementById("addTXT-value").value, action: "addTXT"},
                                success:function(result){
                                    var result = JSON.parse(result);
                                    if (result.status == 0){
                                        $.notify({message: '{/literal}{$ADDONLANG.dnssuitePage_manage_dns_addrecord_failed}{literal}'},{type: 'danger',delay: 5000,timer: 1000,newest_on_top: true,animate: {enter: 'animated fadeInDown',exit: 'animated fadeOutDown'},});
                                        return false;
                                    }else if (result.status == 2){
                                        $.notify({message: '{/literal}{$ADDONLANG.dnssuitePage_manage_dns_invalidhostname}{literal}'},{type: 'danger',delay: 5000,timer: 1000,newest_on_top: true,animate: {enter: 'animated fadeInDown',exit: 'animated fadeOutDown'},});
                                        return false;
                                    }else if (result.status == 3){
                                        $.notify({message: '{/literal}{$ADDONLANG.dnssuitePage_manage_dns_invalidtxtvalue}{literal}'},{type: 'danger',delay: 5000,timer: 1000,newest_on_top: true,animate: {enter: 'animated fadeInDown',exit: 'animated fadeOutDown'},});
                                        return false;
                                    }else if (result.status == 1){
                                        var arraydata = result.data;
                                        if (result.count < limits_txt || limits_txt == 0) var write = true;
                                        else var write = false;
                                        $("#TXTtable").find("tr:gt(0)").remove();
                                        BuildTable(arraydata, "TXT", write);
                                        $.notify({message: '{/literal}{$ADDONLANG.dnssuitePage_manage_dns_addrecord_success}{literal}'},{type: 'success',delay: 5000,timer: 1000,newest_on_top: true,animate: {enter: 'animated fadeInDown',exit: 'animated fadeOutDown'},});
                                        document.getElementById("TXTcount").innerHTML = result.count;
                                        return false;
                                }
                            }});
                        }else{
                            document.getElementById("addTXT-host").focus();
                            document.getElementById("validateresp").innerHTML = {/literal}"{$ADDONLANG.dnssuitePage_manage_js_invalidhostname}"{literal}+" "+document.getElementById("addTXT-host").value;
                            $('#myModal').modal('show');
                            return false;
                        }
                    }else{
                        document.getElementById("addTXT-host").focus();
                        document.getElementById("validateresp").innerHTML = {/literal}"{$ADDONLANG.dnssuitePage_manage_js_invalidhostname}"{literal}+" "+document.getElementById("addTXT-host").value;
                        $('#myModal').modal('show');
                        return false;
                    }
                }else{
                    $('#validateaddresp').html('invalid value');
                    document.getElementById("addTXT-host").focus();
                    document.getElementById("validateresp").innerHTML = {/literal}"{$ADDONLANG.dnssuitePage_manage_js_txtfieldinvalid}"{literal};
                    $('#myModal').modal('show');
                    return false;
                }
            });
            $(document).on("click", '.modifyTXTbtn',function(e) {
                e.preventDefault();
                var row = $(this).val();
                var hostnamedot = /^(([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z0-9])\.)*([A-Za-z0-9]|[A-Za-z0-9][A-Za-z0-9\-]*[A-Za-z0-9]|[A-Za-z0-9][A-Za-z0-9\-]*[A-Za-z0-9]\.)$/;
                var txtvalue = /^[a-zA-Z0-9!#$%&()*+,\\\.\/:;<=>?@\[\] ^_`{|}~-]*$/;

                if(document.getElementById("TXT-"+row+"-value").value.match(txtvalue)){
                    if (document.getElementById("TXT-"+row+"-value").value == ""){
                        $('#validateaddresp').html('invalid hostname');
                        document.getElementById("TXT-"+row+"-value").focus();
                        document.getElementById("validateresp").innerHTML = {/literal}"{$ADDONLANG.dnssuitePage_manage_js_txtfieldempty}"{literal};
                        $('#myModal').modal('show');
                        return false;
                    }else{
                        $.ajax({
                        type: "POST",
                        url: "modules/addons/dnssuite/include/dnssuite_ajax.php",
                        data: { domainid: domainid, value: document.getElementById("TXT-"+row+"-value").value, row: row, action: "modifyTXT"},
                        success:function(result){
                            var result = JSON.parse(result);
                            if (result.status == 0){
                                $.notify({message: '{/literal}{$ADDONLANG.dnssuitePage_manage_dns_updaterecord_failed}{literal}'},{type: 'danger',delay: 5000,timer: 1000,newest_on_top: true,animate: {enter: 'animated fadeInDown',exit: 'animated fadeOutDown'},});
                                return false;
                            }else if (result.status == 3){
                                $.notify({message: '{/literal}{$ADDONLANG.dnssuitePage_manage_dns_invalidtxtvalue}{literal}'},{type: 'danger',delay: 5000,timer: 1000,newest_on_top: true,animate: {enter: 'animated fadeInDown',exit: 'animated fadeOutDown'},});
                                return false;
                            }else if (result.status == 1){
                                $.notify({message: '{/literal}{$ADDONLANG.dnssuitePage_manage_dns_updaterecord_success}{literal}'},{type: 'success',delay: 5000,timer: 1000,newest_on_top: true,animate: {enter: 'animated fadeInDown',exit: 'animated fadeOutDown'},});
                                var arraydata = result.data;
                                if (result.count < limits_txt || limits_txt == 0) var write = true;
                                else var write = false;
                                $("#TXTtable").find("tr:gt(0)").remove();
                                BuildTable(arraydata, "TXT", write);
                                document.getElementById("TXTcount").innerHTML = result.count;
                                return false;
                            }
                        }});
                    }
                }else{
                    $('#validateaddresp').html('invalid value');
                    document.getElementById("TXT-"+row+"-value").focus();
                    document.getElementById("validateresp").innerHTML = {/literal}"{$ADDONLANG.dnssuitePage_manage_js_txtfieldinvalid}"{literal};
                    $('#myModal').modal('show');
                    return false;
                }
            });

            $(document).on("click", '.addMXbtn',function(e){
                e.preventDefault();
                var hostname = /^(([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z0-9])\.)*([A-Za-z0-9]|[A-Za-z0-9][A-Za-z0-9\-]*[A-Za-z0-9])$/;
                var hostnamedot = /^(([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z0-9])\.)*([A-Za-z0-9]|[A-Za-z0-9][A-Za-z0-9\-]*[A-Za-z0-9]|[A-Za-z0-9][A-Za-z0-9\-]*[A-Za-z0-9]\.)$/;
                if (document.getElementById("addMX-host").value == ""){
                    $('#validateaddresp').html('invalid hostname');
                    document.getElementById("addMX-host").focus();
                    document.getElementById("validateresp").innerHTML = {/literal}"{$ADDONLANG.dnssuitePage_manage_js_hostfieldempty}"{literal}+" "+document.getElementById("addMX-host").value;
                    $('#myModal').modal('show');
                    return false;
                }
                if (document.getElementById("addMX-value").value == ""){
                    $('#validateaddresp').html('invalid value');
                    document.getElementById("addMX-value").focus();
                    document.getElementById("validateresp").innerHTML = {/literal}"{$ADDONLANG.dnssuitePage_manage_js_valuefieldempty}"{literal}+" "+document.getElementById("addMX-value").value;
                    $('#myModal').modal('show');
                    return false;
                }
                if (document.getElementById("addMX-priority").value == ""){
                    $('#validateaddresp').html('invalid value');
                    document.getElementById("addMX-priority").focus();
                    document.getElementById("validateresp").innerHTML = {/literal}"{$ADDONLANG.dnssuitePage_manage_js_priorityfieldempty}"{literal}+" "+document.getElementById("addMX-priority").value;
                    $('#myModal').modal('show');
                    return false;
                }
                if(document.getElementById("addMX-host").value.match(hostname) || document.getElementById("addMX-host").value == "{/literal}{$domain}.{literal}" ){
                    if(document.getElementById("addMX-host").value.match(hostnamedot) || document.getElementById("addMX-host").value == "*"){
                        if(document.getElementById("addMX-value").value.match(hostname) || document.getElementById("addMX-value").value.match(hostnamedot)){
                            if(document.getElementById("addMX-priority").value == 0 || document.getElementById("addMX-priority").value == 10 || document.getElementById("addMX-priority").value == 20 || document.getElementById("addMX-priority").value == 30 || document.getElementById("addMX-priority").value == 40 || document.getElementById("addMX-priority").value == 50 || document.getElementById("addMX-priority").value == 60 || document.getElementById("addMX-priority").value == 70 || document.getElementById("addMX-priority").value == 80 || document.getElementById("addMX-priority").value == 90 ){
                                     $.ajax({
                                    type: "POST",
                                    url: "modules/addons/dnssuite/include/dnssuite_ajax.php",
                                    data: { domainid: document.getElementById("addMX-domainid").value, host: document.getElementById("addMX-host").value, value: document.getElementById("addMX-value").value, priority: document.getElementById("addMX-priority").value, action: "addMX"},
                                    success:function(result){
                                        var result = JSON.parse(result);
                                        if (result.status == 0){
                                            $.notify({message: '{/literal}{$ADDONLANG.dnssuitePage_manage_dns_addrecord_failed}{literal}'},{type: 'danger',delay: 5000,timer: 1000,newest_on_top: true,animate: {enter: 'animated fadeInDown',exit: 'animated fadeOutDown'},});
                                            return false;
                                        }else if (result.status == 2){
                                            $.notify({message: '{/literal}{$ADDONLANG.dnssuitePage_manage_dns_invalidhostname}{literal}'},{type: 'danger',delay: 5000,timer: 1000,newest_on_top: true,animate: {enter: 'animated fadeInDown',exit: 'animated fadeOutDown'},});
                                            return false;
                                        }else if (result.status == 3){
                                            $.notify({message: '{/literal}{$ADDONLANG.dnssuitePage_manage_dns_invalidmxvalue}{literal}'},{type: 'danger',delay: 5000,timer: 1000,newest_on_top: true,animate: {enter: 'animated fadeInDown',exit: 'animated fadeOutDown'},});
                                            return false;
                                        }else if (result.status == 4){
                                            $.notify({message: '{/literal}{$ADDONLANG.dnssuitePage_manage_dns_invalidmxpriority}{literal}'},{type: 'danger',delay: 5000,timer: 1000,newest_on_top: true,animate: {enter: 'animated fadeInDown',exit: 'animated fadeOutDown'},});
                                            return false;
                                        }else if (result.status == 1){
                                            var arraydata = result.data;
                                            if (result.count < limits_mx || limits_mx == 0) var write = true;
                                            else var write = false;
                                            $("#MXtable").find("tr:gt(0)").remove();
                                            BuildTable(arraydata, "MX", write);
                                            $.notify({message: '{/literal}{$ADDONLANG.dnssuitePage_manage_dns_addrecord_success}{literal}'},{type: 'success',delay: 5000,timer: 1000,newest_on_top: true,animate: {enter: 'animated fadeInDown',exit: 'animated fadeOutDown'},});
                                            document.getElementById("MXcount").innerHTML = result.count;
                                            return false;
                                        }
                                    }});
                            }else{
                                document.getElementById("addMX-priority").focus();
                                document.getElementById("validateresp").innerHTML = {/literal}"{$ADDONLANG.dnssuitePage_manage_js_invalidpriority}"{literal}+" "+document.getElementById("addMX-priority").value;
                                $('#myModal').modal('show');
                                return false;
                            }
                        }else{
                            document.getElementById("addMX-priority").focus();
                            document.getElementById("validateresp").innerHTML = {/literal}"{$ADDONLANG.dnssuitePage_manage_js_valuefieldinvalid}"{literal}+" "+document.getElementById("addMX-value").value;
                            $('#myModal').modal('show');
                            return false;
                        }
                    }else{
                        document.getElementById("addMX-host").focus();
                        document.getElementById("validateresp").innerHTML = {/literal}"{$ADDONLANG.dnssuitePage_manage_js_invalidhostname}"{literal}+" "+document.getElementById("addMX-host").value;
                        $('#myModal').modal('show');
                        return false;
                    }
                }else{
                    document.getElementById("addMX-host").focus();
                    document.getElementById("validateresp").innerHTML = {/literal}"{$ADDONLANG.dnssuitePage_manage_js_invalidhostname}"{literal}+" "+document.getElementById("addMX-host").value;
                    $('#myModal').modal('show');
                    return false;
                }
            });
            $(document).on("click", '.modifyMXbtn',function(e) {
                e.preventDefault();
                var row = $(this).val();
                var hostname = /^(([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z0-9])\.)*([A-Za-z0-9]|[A-Za-z0-9][A-Za-z0-9\-]*[A-Za-z0-9])$/;
                var hostnamedot = /^(([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z0-9])\.)*([A-Za-z0-9]|[A-Za-z0-9][A-Za-z0-9\-]*[A-Za-z0-9]|[A-Za-z0-9][A-Za-z0-9\-]*[A-Za-z0-9]\.)$/;
                if (document.getElementById("MX-"+row+"-value").value == ""){
                    $('#validateaddresp').html('invalid value');
                    document.getElementById("MX-"+row+"-value").focus();
                    document.getElementById("validateresp").innerHTML = {/literal}"{$ADDONLANG.dnssuitePage_manage_js_valuefieldempty}"{literal}+" "+document.getElementById("MX-"+row+"-value").value;
                    $('#myModal').modal('show');
                    return false;
                }
                if (document.getElementById("MX-"+row+"-priority").value == ""){
                    $('#validateaddresp').html('invalid value');
                    document.getElementById("MX-"+row+"-priority").focus();
                    document.getElementById("validateresp").innerHTML = {/literal}"{$ADDONLANG.dnssuitePage_manage_js_priorityfieldempty}"{literal}+" "+document.getElementById("MX-"+row+"-priority").value;
                    $('#myModal').modal('show');
                    return false;
                }
                if(document.getElementById("MX-"+row+"-value").value.match(hostnamedot) || document.getElementById("MX-"+row+"-value").value.match(hostname)){
                    if(document.getElementById("MX-"+row+"-priority").value == 0 || document.getElementById("MX-"+row+"-priority").value == 10 || document.getElementById("MX-"+row+"-priority").value == 20 || document.getElementById("MX-"+row+"-priority").value == 30 || document.getElementById("MX-"+row+"-priority").value == 40 || document.getElementById("MX-"+row+"-priority").value == 50 || document.getElementById("MX-"+row+"-priority").value == 60 || document.getElementById("MX-"+row+"-priority").value == 70 || document.getElementById("MX-"+row+"-priority").value == 80 || document.getElementById("MX-"+row+"-priority").value == 90 ){
                        $.ajax({
                        type: "POST",
                        url: "modules/addons/dnssuite/include/dnssuite_ajax.php",
                        data: { domainid: domainid, value: document.getElementById("MX-"+row+"-value").value, row: row, priority: document.getElementById("MX-"+row+"-priority").value, action: "modifyMX"},
                        success:function(result){
                            var result = JSON.parse(result);
                            if (result.status == 0){
                                $.notify({message: '{/literal}{$ADDONLANG.dnssuitePage_manage_dns_updaterecord_failed}{literal}'},{type: 'danger',delay: 5000,timer: 1000,newest_on_top: true,animate: {enter: 'animated fadeInDown',exit: 'animated fadeOutDown'},});
                                return false;
                            }else if (result.status == 3){
                                $.notify({message: '{/literal}{$ADDONLANG.dnssuitePage_manage_dns_invalidmxvalue}{literal}'},{type: 'danger',delay: 5000,timer: 1000,newest_on_top: true,animate: {enter: 'animated fadeInDown',exit: 'animated fadeOutDown'},});
                                return false;
                            }else if (result.status == 4){
                                $.notify({message: '{/literal}{$ADDONLANG.dnssuitePage_manage_dns_invalidmxpriority}{literal}'},{type: 'danger',delay: 5000,timer: 1000,newest_on_top: true,animate: {enter: 'animated fadeInDown',exit: 'animated fadeOutDown'},});
                                return false;
                            }else if (result.status == 1){
                                $.notify({message: '{/literal}{$ADDONLANG.dnssuitePage_manage_dns_updaterecord_success}{literal}'},{type: 'success',delay: 5000,timer: 1000,newest_on_top: true,animate: {enter: 'animated fadeInDown',exit: 'animated fadeOutDown'},});
                                var arraydata = result.data;
                                if (result.count < limits_mx || limits_a == mx) var write = true;
                                else var write = false;
                                $("#MXtable").find("tr:gt(0)").remove();
                                BuildTable(arraydata, "MX", write);
                                document.getElementById("MXcount").innerHTML = result.count;
                                return false;
                            }
                        }});
                    }else{
                        document.getElementById("MX-"+row+"-priority").focus();
                        document.getElementById("validateresp").innerHTML = {/literal}"{$ADDONLANG.dnssuitePage_manage_js_invalidpriority}"{literal}+" "+document.getElementById("MX-"+row+"-priority").value;
                        $('#myModal').modal('show');
                        return false;
                    }
                }else{
                    document.getElementById("MX-"+row+"-value").focus();
                    document.getElementById("validateresp").innerHTML = {/literal}"{$ADDONLANG.dnssuitePage_manage_js_invalidhostname}"{literal}+" "+document.getElementById("MX-"+row+"-value").value;
                    $('#myModal').modal('show');
                    return false;
                }
            });

            $(document).on("click", '.addSRVbtn',function(e) {
                e.preventDefault();
                var hostnameunderscore = /^(([a-zA-Z0-9\_]|[a-zA-Z0-9\_][a-zA-Z0-9\-\_]*[a-zA-Z0-9\_])\.)*([A-Za-z0-9\_]|[A-Za-z0-9\_][A-Za-z0-9\-\_]*[A-Za-z0-9\_])$/;
                var hostnamedotunderscore = /^(([a-zA-Z0-9\_]|[a-zA-Z0-9\_][a-zA-Z0-9\-\_]*[a-zA-Z0-9\_])\.)*([A-Za-z0-9\_]|[A-Za-z0-9\_][A-Za-z0-9\-\_]*[A-Za-z0-9\_]|[A-Za-z0-9\_][A-Za-z0-9\-\_]*[A-Za-z0-9\_]\.)$/;
                var hostname = /^((([a-zA-Z0-9]|[\*])|[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z0-9])\.)*([A-Za-z0-9]|[A-Za-z0-9][A-Za-z0-9\-]*[A-Za-z0-9])$/;
                var hostnamedot = /^(([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z0-9])\.)*([A-Za-z0-9]|[A-Za-z0-9][A-Za-z0-9\-]*[A-Za-z0-9]|[A-Za-z0-9][A-Za-z0-9\-]*[A-Za-z0-9]\.)$/;
                var digits = /^\d+$/;

                if (document.getElementById("addSRV-host").value == ""){
                    $('#validateaddresp').html('invalid hostname');
                    document.getElementById("addSRV-host").focus();
                    document.getElementById("validateresp").innerHTML = {/literal}"{$ADDONLANG.dnssuitePage_manage_js_hostfieldempty}"{literal}+" "+document.getElementById("addSRV-host").value;
                    $('#myModal').modal('show');
                    return false;
                }
                if (document.getElementById("addSRV-priority").value == ""){
                    $('#validateaddresp').html('invalid hostname');
                    document.getElementById("addSRV-priority").focus();
                    document.getElementById("validateresp").innerHTML = {/literal}"{$ADDONLANG.dnssuitePage_manage_js_priorityfieldempty}"{literal}+" "+document.getElementById("addSRV-priority").value;
                    $('#myModal').modal('show');
                    return false;
                }
                if (document.getElementById("addSRV-weight").value == ""){
                    $('#validateaddresp').html('invalid hostname');
                    document.getElementById("addSRV-weight").focus();
                    document.getElementById("validateresp").innerHTML = {/literal}"{$ADDONLANG.dnssuitePage_manage_js_weightfieldempty}"{literal}+" "+document.getElementById("addSRV-weight").value;
                    $('#myModal').modal('show');
                    return false;
                }
                if (document.getElementById("addSRV-port").value == ""){
                    $('#validateaddresp').html('invalid hostname');
                    document.getElementById("addSRV-port").focus();
                    document.getElementById("validateresp").innerHTML = {/literal}"{$ADDONLANG.dnssuitePage_manage_js_portfieldempty}"{literal}+" "+document.getElementById("addSRV-port").value;
                    $('#myModal').modal('show');
                    return false;
                }
                if (document.getElementById("addSRV-value").value == ""){
                    $('#validateaddresp').html('invalid value');
                    document.getElementById("addSRV-value").focus();
                    document.getElementById("validateresp").innerHTML = {/literal}"{$ADDONLANG.dnssuitePage_manage_js_valuefieldempty}"{literal}+" "+document.getElementById("addSRV-value").value;
                    $('#myModal').modal('show');
                    return false;
                }
                if(!document.getElementById("addSRV-priority").value.match(digits)){
                    $('#validateaddresp').html('invalid value');
                    document.getElementById("addSRV-priority").focus();
                    document.getElementById("validateresp").innerHTML = {/literal}"{$ADDONLANG.dnssuitePage_manage_js_priorityinvalid}"{literal}+" "+document.getElementById("addSRV-priority").value;
                    $('#myModal').modal('show');
                    return false;
                }
                if(!document.getElementById("addSRV-weight").value.match(digits)){
                    $('#validateaddresp').html('invalid value');
                    document.getElementById("addSRV-weight").focus();
                    document.getElementById("validateresp").innerHTML = {/literal}"{$ADDONLANG.dnssuitePage_manage_js_weightinvalid}"{literal}+" "+document.getElementById("addSRV-weight").value;
                    $('#myModal').modal('show');
                    return false;
                }
                if(!document.getElementById("addSRV-port").value.match(digits)){
                    $('#validateaddresp').html('invalid value');
                    document.getElementById("addSRV-port").focus();
                    document.getElementById("validateresp").innerHTML = {/literal}"{$ADDONLANG.dnssuitePage_manage_js_portinvalid}"{literal}+" "+document.getElementById("addSRV-port").value;
                    $('#myModal').modal('show');
                    return false;
                }
                if (document.getElementById("addSRV-priority").value < 0 || document.getElementById("addSRV-priority").value > 65535){
                    $('#validateaddresp').html('invalid value');
                    document.getElementById("addSRV-priority").focus();
                    document.getElementById("validateresp").innerHTML = {/literal}"{$ADDONLANG.dnssuitePage_manage_js_invalidrange}"{literal}+" "+document.getElementById("addSRV-priority").value;
                    $('#myModal').modal('show');
                    return false;
                }
                if (document.getElementById("addSRV-weight").value < 0 || document.getElementById("addSRV-weight").value > 65535){
                    $('#validateaddresp').html('invalid value');
                    document.getElementById("addSRV-weight").focus();
                    document.getElementById("validateresp").innerHTML = {/literal}"{$ADDONLANG.dnssuitePage_manage_js_invalidrange}"{literal}+" "+document.getElementById("addSRV-weight").value;
                    $('#myModal').modal('show');
                    return false;
                }
                if (document.getElementById("addSRV-port").value < 0 || document.getElementById("addSRV-port").value > 65535){
                    $('#validateaddresp').html('invalid value');
                    document.getElementById("addSRV-port").focus();
                    document.getElementById("validateresp").innerHTML = {/literal}"{$ADDONLANG.dnssuitePage_manage_js_invalidrange}"{literal}+" "+document.getElementById("addSRV-port").value;
                    $('#myModal').modal('show');
                    return false;
                }
                if(document.getElementById("addSRV-value").value.match(hostname) || document.getElementById("addSRV-value").value.match(hostnamedot)){
                    if(document.getElementById("addSRV-host").value.match(hostnamedotunderscore) || document.getElementById("addSRV-host").value == "*"){
                        $.ajax({
                            type: "POST",
                            url: "modules/addons/dnssuite/include/dnssuite_ajax.php",
                            data: { domainid: document.getElementById("addSRV-domainid").value, host: document.getElementById("addSRV-host").value, value: document.getElementById("addSRV-value").value, priority: document.getElementById("addSRV-priority").value, weight: document.getElementById("addSRV-weight").value, port: document.getElementById("addSRV-port").value, action: "addSRV"},
                            success:function(result){
                                var result = JSON.parse(result);
                                if (result.status == 0){
                                    $.notify({message: '{/literal}{$ADDONLANG.dnssuitePage_manage_dns_addrecord_failed}{literal}'},{type: 'danger',delay: 5000,timer: 1000,newest_on_top: true,animate: {enter: 'animated fadeInDown',exit: 'animated fadeOutDown'},});
                                    return false;
                                }else if (result.status == 2){
                                    $.notify({message: '{/literal}{$ADDONLANG.dnssuitePage_manage_dns_invalidhostname}{literal}'},{type: 'danger',delay: 5000,timer: 1000,newest_on_top: true,animate: {enter: 'animated fadeInDown',exit: 'animated fadeOutDown'},});
                                    return false;
                                }else if (result.status == 3){
                                    $.notify({message: '{/literal}{$ADDONLANG.dnssuitePage_manage_js_valuefieldinvalid}{literal}'},{type: 'danger',delay: 5000,timer: 1000,newest_on_top: true,animate: {enter: 'animated fadeInDown',exit: 'animated fadeOutDown'},});
                                    return false;
                                }else if (result.status == 4){
                                    $.notify({message: '{/literal}{$ADDONLANG.dnssuitePage_manage_dns_invaliddestinationvalue}{literal}'},{type: 'danger',delay: 5000,timer: 1000,newest_on_top: true,animate: {enter: 'animated fadeInDown',exit: 'animated fadeOutDown'},});
                                    return false;
                                }else if (result.status == 1){
                                    var arraydata = result.data;
                                    if (result.count < limits_srv || limits_srv == 0) var write = true;
                                    else var write = false;
                                    $("#SRVtable").find("tr:gt(0)").remove();
                                    BuildTable(arraydata, "SRV", write);
                                    $.notify({message: '{/literal}{$ADDONLANG.dnssuitePage_manage_dns_addrecord_success}{literal}'},{type: 'success',delay: 5000,timer: 1000,newest_on_top: true,animate: {enter: 'animated fadeInDown',exit: 'animated fadeOutDown'},});
                                    document.getElementById("SRVcount").innerHTML = result.count;
                                    return false;
                                }
                        }});
                    }else{
                        document.getElementById("addSRV-host").focus();
                        document.getElementById("validateresp").innerHTML = {/literal}"{$ADDONLANG.dnssuitePage_manage_js_invalidhostname}"{literal}+" "+document.getElementById("addSRV-host").value;
                        $('#myModal').modal('show');
                        return false;
                    }
                }else{
                    $('#validateaddresp').html('invalid value');
                    document.getElementById("addSRV-value").focus();
                    document.getElementById("validateresp").innerHTML = {/literal}"{$ADDONLANG.dnssuitePage_manage_js_valuefieldinvalid}"{literal};
                    $('#myModal').modal('show');
                    return false;
                }
            });
            $(document).on("click", '.modifySRVbtn',function(e) {
                e.preventDefault();
                var row = $(this).val();
                var hostnameunderscore = /^(([a-zA-Z0-9\_]|[a-zA-Z0-9\_][a-zA-Z0-9\-\_]*[a-zA-Z0-9\_])\.)*([A-Za-z0-9\_]|[A-Za-z0-9\_][A-Za-z0-9\-\_]*[A-Za-z0-9\_])$/;
                var hostnamedotunderscore = /^(([a-zA-Z0-9\_]|[a-zA-Z0-9\_][a-zA-Z0-9\-\_]*[a-zA-Z0-9\_])\.)*([A-Za-z0-9\_]|[A-Za-z0-9\_][A-Za-z0-9\-\_]*[A-Za-z0-9\_]|[A-Za-z0-9\_][A-Za-z0-9\-\_]*[A-Za-z0-9\_]\.)$/;
                var hostname = /^(([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z0-9])\.)*([A-Za-z0-9]|[A-Za-z0-9][A-Za-z0-9\-]*[A-Za-z0-9])$/;
                var hostnamedot = /^(([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z0-9])\.)*([A-Za-z0-9]|[A-Za-z0-9][A-Za-z0-9\-]*[A-Za-z0-9]|[A-Za-z0-9][A-Za-z0-9\-]*[A-Za-z0-9]\.)$/;
                var digits = /^\d+$/;
                if (document.getElementById("SRV-"+row+"-priority").value == ""){
                    $('#validateaddresp').html('invalid hostname');
                    document.getElementById("SRV-"+row+"-priority").focus();
                    document.getElementById("validateresp").innerHTML = {/literal}"{$ADDONLANG.dnssuitePage_manage_js_priorityfieldempty}"{literal}+" "+document.getElementById("SRV-"+row+"-priority").value;
                    $('#myModal').modal('show');
                    return false;
                }
                if (document.getElementById("SRV-"+row+"-weight").value == ""){
                    $('#validateaddresp').html('invalid hostname');
                    document.getElementById("SRV-"+row+"-weight").focus();
                    document.getElementById("validateresp").innerHTML = {/literal}"{$ADDONLANG.dnssuitePage_manage_js_weightfieldempty}"{literal}+" "+document.getElementById("SRV-"+row+"-weight").value;
                    $('#myModal').modal('show');
                    return false;
                }
                if (document.getElementById("SRV-"+row+"-port").value == ""){
                    $('#validateaddresp').html('invalid hostname');
                    document.getElementById("SRV-"+row+"-port").focus();
                    document.getElementById("validateresp").innerHTML = {/literal}"{$ADDONLANG.dnssuitePage_manage_js_portfieldempty}"{literal}+" "+document.getElementById("SRV-"+row+"-port").value;
                    $('#myModal').modal('show');
                    return false;
                }
                if (document.getElementById("SRV-"+row+"-value").value == ""){
                    $('#validateaddresp').html('invalid value');
                    document.getElementById("SRV-"+row+"-value").focus();
                    document.getElementById("validateresp").innerHTML = {/literal}"{$ADDONLANG.dnssuitePage_manage_js_valuefieldempty}"{literal}+" "+document.getElementById("SRV-"+row+"-value").value;
                    $('#myModal').modal('show');
                    return false;
                }
                if(!document.getElementById("SRV-"+row+"-priority").value.match(digits)){
                    $('#validateaddresp').html('invalid value');
                    document.getElementById("SRV-"+row+"-priority").focus();
                    document.getElementById("validateresp").innerHTML = {/literal}"{$ADDONLANG.dnssuitePage_manage_js_priorityinvalid}"{literal}+" "+document.getElementById("SRV-"+row+"-priority").value;
                    $('#myModal').modal('show');
                    return false;
                }
                if(!document.getElementById("SRV-"+row+"-weight").value.match(digits)){
                    $('#validateaddresp').html('invalid value');
                    document.getElementById("SRV-"+row+"-weight").focus();
                    document.getElementById("validateresp").innerHTML = {/literal}"{$ADDONLANG.dnssuitePage_manage_js_weightinvalid}"{literal}+" "+document.getElementById("SRV-"+row+"-weight").value;
                    $('#myModal').modal('show');
                    return false;
                }
                if(!document.getElementById("SRV-"+row+"-port").value.match(digits)){
                    $('#validateaddresp').html('invalid value');
                    document.getElementById("SRV-"+row+"-port").focus();
                    document.getElementById("validateresp").innerHTML = {/literal}"{$ADDONLANG.dnssuitePage_manage_js_portinvalid}"{literal}+" "+document.getElementById("SRV-"+row+"-port").value;
                    $('#myModal').modal('show');
                    return false;
                }
                if (document.getElementById("SRV-"+row+"-priority").value < 0 || document.getElementById("SRV-"+row+"-priority").value > 65535){
                    $('#validateaddresp').html('invalid value');
                    document.getElementById("SRV-"+row+"-priority").focus();
                    document.getElementById("validateresp").innerHTML = {/literal}"{$ADDONLANG.dnssuitePage_manage_js_invalidrange}"{literal}+" "+document.getElementById("SRV-"+row+"-priority").value;
                    $('#myModal').modal('show');
                    return false;
                }
                if (document.getElementById("SRV-"+row+"-weight").value < 0 || document.getElementById("SRV-"+row+"-weight").value > 65535){
                    $('#validateaddresp').html('invalid value');
                    document.getElementById("SRV-"+row+"-weight").focus();
                    document.getElementById("validateresp").innerHTML = {/literal}"{$ADDONLANG.dnssuitePage_manage_js_invalidrange}"{literal}+" "+document.getElementById("SRV-"+row+"-weight").value;
                    $('#myModal').modal('show');
                    return false;
                }
                if (document.getElementById("SRV-"+row+"-port").value < 0 || document.getElementById("SRV-"+row+"-port").value > 65535){
                    $('#validateaddresp').html('invalid value');
                    document.getElementById("SRV-"+row+"-port").focus();
                    document.getElementById("validateresp").innerHTML = {/literal}"{$ADDONLANG.dnssuitePage_manage_js_invalidrange}"{literal}+" "+document.getElementById("SRV-"+row+"-port").value;
                    $('#myModal').modal('show');
                    return false;
                }
                if(document.getElementById("SRV-"+row+"-value").value.match(hostname) || document.getElementById("SRV-"+row+"-value").value.match(hostnamedot)){
                    $.ajax({
                        type: "POST",
                        url: "modules/addons/dnssuite/include/dnssuite_ajax.php",
                        data: { domainid: domainid, row: row, value: document.getElementById("SRV-"+row+"-value").value, priority: document.getElementById("SRV-"+row+"-priority").value, weight: document.getElementById("SRV-"+row+"-weight").value, port: document.getElementById("SRV-"+row+"-port").value, action: "modifySRV"},
                        success:function(result){
                            var result = JSON.parse(result);
                            if (result.status == 0){
                                $.notify({message: '{/literal}{$ADDONLANG.dnssuitePage_manage_dns_addrecord_failed}{literal}'},{type: 'danger',delay: 5000,timer: 1000,newest_on_top: true,animate: {enter: 'animated fadeInDown',exit: 'animated fadeOutDown'},});
                                return false;
                            }else if (result.status == 3){
                                $.notify({message: '{/literal}{$ADDONLANG.dnssuitePage_manage_js_valuefieldinvalid}{literal}'},{type: 'danger',delay: 5000,timer: 1000,newest_on_top: true,animate: {enter: 'animated fadeInDown',exit: 'animated fadeOutDown'},});
                                return false;
                            }else if (result.status == 4){
                                $.notify({message: '{/literal}{$ADDONLANG.dnssuitePage_manage_dns_invaliddestinationvalue}{literal}'},{type: 'danger',delay: 5000,timer: 1000,newest_on_top: true,animate: {enter: 'animated fadeInDown',exit: 'animated fadeOutDown'},});
                                return false;
                            }else if (result.status == 1){
                                var arraydata = result.data;
                                if (result.count < limits_srv || limits_srv == 0) var write = true;
                                else var write = false;
                                $("#SRVtable").find("tr:gt(0)").remove();
                                BuildTable(arraydata, "SRV", write);
                                $.notify({message: '{/literal}{$ADDONLANG.dnssuitePage_manage_dns_addrecord_success}{literal}'},{type: 'success',delay: 5000,timer: 1000,newest_on_top: true,animate: {enter: 'animated fadeInDown',exit: 'animated fadeOutDown'},});
                                document.getElementById("SRVcount").innerHTML = result.count;
                                return false;
                            }
                    }});
                }else{
                    $('#validateaddresp').html('invalid value');
                    document.getElementById("SRV-"+row+"-value").focus();
                    document.getElementById("validateresp").innerHTML = {/literal}"{$ADDONLANG.dnssuitePage_manage_js_valuefieldinvalid}"{literal};
                    $('#myModal').modal('show');
                    return false;
                }
            });
        });
        {/literal}
        {/if}
        {literal}
        function loadscreen(){
            document.getElementById("modal-loading").style.display = "block";
        }
        function resetConfirm(form){
            $('#resetmodal').modal({
                backdrop: 'static',
                keyboard: true
            })
                .one('click', '#deletebutton', function(e) {
                    form.submit();
                    return true;
                });
        }
        function deleteConfirm(form){
            $('#deletemodal').modal({
                backdrop: 'static',
                keyboard: true
            })
            .one('click', '#deletebutton', function(e) {
                $.ajax({
                    type: "POST",
                    url: "modules/addons/dnssuite/include/dnssuite_ajax.php",
                    data: { domainid: form["domainid"].value, mode: form["mode"].value, row: form["row"].value, action: "deleteRecord"},

                    success:function(result){
                        var result = JSON.parse(result);
                        if (result.status == 0){
                            $.notify({message: '{/literal}{$ADDONLANG.dnssuitePage_manage_dns_updaterecord_failed}{literal}'},{type: 'danger',delay: 5000,timer: 1000,newest_on_top: true,animate: {enter: 'animated fadeInDown',exit: 'animated fadeOutDown'},});
                            return false;
                        }else if (result.status == 1){
                            $.notify({message: '{/literal}{$ADDONLANG.dnssuitePage_manage_dns_updaterecord_success}{literal}'},{type: 'success',delay: 5000,timer: 1000,newest_on_top: true,animate: {enter: 'animated fadeInDown',exit: 'animated fadeOutDown'},});
                            var arraydata = result.data;
                            $("#Atable").find("tr:gt(0)").remove();
                            BuildTable(arraydata, "A");
                            return false;
                        }
                }});
            });
        }
        {/literal}
        
        {if $subdomain.enable == "on"}
            {literal}
                $(document).on("click", '.addSUBDOMAINbtn',function(e){
                    e.preventDefault();
                    var hostname = /^(([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z0-9])\.)*([A-Za-z0-9]|[A-Za-z0-9][A-Za-z0-9\-]*[A-Za-z0-9])$/;
                    if (document.getElementById("addSUBDOMAIN").value == ""){
                        $.notify({message: '{/literal}{$ADDONLANG.dnssuitePage_manage_subdomainempty}{literal}'},{type: 'danger',delay: 5000,timer: 1000,newest_on_top: true,animate: {enter: 'animated fadeInDown',exit: 'animated fadeOutDown'},});
                        document.getElementById("addSUBDOMAIN").focus();
                        return false;
                    }else if (!document.getElementById("addSUBDOMAIN").value.match(hostname)){
                        $.notify({message: '{/literal}{$ADDONLANG.dnssuitePage_manage_subdomaininvalidhostname}{literal}'},{type: 'danger',delay: 5000,timer: 1000,newest_on_top: true,animate: {enter: 'animated fadeInDown',exit: 'animated fadeOutDown'},});
                        document.getElementById("addSUBDOMAIN").focus();
                        return false;
                    }else{
                        $.ajax({
                        type: "POST",
                        url: "modules/addons/dnssuite/include/dnssuite_ajax.php",
                        data: { domainid: domainid, hostname: document.getElementById("addSUBDOMAIN").value, action: "addSUBDOMAIN"},
                        success:function(result){
                            console.log(result);
                            var result = JSON.parse(result);
                            if (result.status == 2){
                                $.notify({message: '{/literal}{$ADDONLANG.dnssuitePage_manage_subdomain_hostnameexist}{literal}'},{type: 'danger',delay: 5000,timer: 1000,newest_on_top: true,animate: {enter: 'animated fadeInDown',exit: 'animated fadeOutDown'},});
                                return false;
                            }else if (result.status == 3){
                                $.notify({message: '{/literal}{$ADDONLANG.dnssuitePage_manage_subdomain_add_failed}{literal}'},{type: 'danger',delay: 5000,timer: 1000,newest_on_top: true,animate: {enter: 'animated fadeInDown',exit: 'animated fadeOutDown'},});
                                return false;
                            }else if (result.status == 0){
                                $.notify({message: '{/literal}{$ADDONLANG.dnssuitePage_manage_subdomain_overlimit}{literal}'},{type: 'danger',delay: 5000,timer: 1000,newest_on_top: true,animate: {enter: 'animated fadeInDown',exit: 'animated fadeOutDown'},});
                                return false;
                            }else if (result.status == 1){
                                $.notify({message: '{/literal}{$ADDONLANG.dnssuitePage_manage_subdomain_add_success}{literal}'},{type: 'success',delay: 5000,timer: 1000,newest_on_top: true,animate: {enter: 'animated fadeInDown',exit: 'animated fadeOutDown'},});
                                var data = result.data;
                                if (result.count < limits_subdomains || limits_subdomains == 0) var write = true;
                                else var write = false;
                                $("#SUBDOMAINtable").find("tr:gt(0)").remove();
                                BuildTableSubDomain(data, write);
                                if (limits_subdomains != 0) {
                                    document.getElementById("SUBDOMAINcount").innerHTML = result.count;
                                }
                            }
                        }});
                    }
                });
                $(document).on("click", '.deleteSUBDOMAINbtn',function(e) {
                    e.preventDefault();
                    var id = $(this).val();

                    $('#deletemodalSUBDOMAIN').modal({
                    backdrop: 'static',
                    keyboard: true
                    }).one('click', '#deletebutton', function(e) {
                        $.ajax({
                            type: "POST",
                            url: "modules/addons/dnssuite/include/dnssuite_ajax.php",
                            data: {  domainid: domainid, sdid: id, action: "deleteSUBDOMAIN"},
                            success:function(result){
                                var result = JSON.parse(result);
                                if (result.status == 2){
                                    $.notify({message: '{/literal}{$ADDONLANG.dnssuitePage_manage_subdomain_notowned}{literal}'},{type: 'danger',delay: 5000,timer: 1000,newest_on_top: true,animate: {enter: 'animated fadeInDown',exit: 'animated fadeOutDown'},});
                                    return false;
                                }else if (result.status == 0){
                                    $.notify({message: '{/literal}{$ADDONLANG.dnssuitePage_manage_subdomain_delete_failed}{literal}'},{type: 'danger',delay: 5000,timer: 1000,newest_on_top: true,animate: {enter: 'animated fadeInDown',exit: 'animated fadeOutDown'},});
                                    return false;
                                }else if (result.status == 1){
                                    $.notify({message: '{/literal}{$ADDONLANG.dnssuitePage_manage_subdomain_delete_success}{literal}'},{type: 'success',delay: 5000,timer: 1000,newest_on_top: true,animate: {enter: 'animated fadeInDown',exit: 'animated fadeOutDown'},});
                                    var data = result.data;
                                    if (result.count < limits_subdomains || limits_subdomains == 0) var write = true;
                                    else var write = false;
                                    $("#SUBDOMAINtable").find("tr:gt(0)").remove();
                                    BuildTableSubDomain(data, write);
                                    if (limits_subdomains != 0) {
                                        document.getElementById("SUBDOMAINcount").innerHTML = result.count;
                                    }
                                }
                        }});
                    });
                });

            {/literal}
        {/if}        

        {if $urlconfig["enable"] == "on" && $edition != "free"}
            {if $urlconfig["masked"] == "on"}
                {literal}
                    $(document).ready(function(){
                         $("#addREDIRECT-type").change(function () {
                            if (this.value == 999){
                                $("#maskedattr").show("slow");
                            }
                            if (this.value != 999){
                                $("#maskedattr").hide("slow");
                            }
                         });
                     });
                    $('body').on('change', '#addREDIRECT-type', function() {
                        if (document.getElementById("addREDIRECT-type").value == 999){
                            $("#maskedattr").show("slow");
                        }
                        if (document.getElementById("addREDIRECT-type").value != 999){
                            $("#maskedattr").hide("slow");
                        }
                    });

                {/literal}
            {/if}
            {literal}
            $(function() {
                $("#redirect-tip").tooltip();
            });


            $(document).on("click", '.addREDIRECTbtn',function(e) {
                e.preventDefault();
                var exp = /^(?:http(s)?:\/\/)?[\w.-]+(?:\.[\w\.-]+)+[\w\-\._~:/?#[\]@!\$&'\(\)\*\+,;=.]+$/g;
                var exp2 = /^([\w\.\-\_\/]+)$/g;

                if (document.getElementById("addREDIRECT-type").value != 301 && document.getElementById("addREDIRECT-type").value != 302 && document.getElementById("addREDIRECT-type").value != 303 && document.getElementById("addREDIRECT-type").value != 999){
                    $('#validateaddresp').html('invalid value');
                    document.getElementById("addREDIRECT-redirecturl").focus();
                    document.getElementById("validateresp").innerHTML = {/literal}"{$ADDONLANG.dnssuitePage_manage_invalidtype}"{literal}+" "+document.getElementById("addREDIRECT-type").value;
                    $('#myModal').modal('show');
                    return false;
                }
                if (document.getElementById("addREDIRECT-redirecturl").value == ""){
                    $('#validateaddresp').html('invalid value');
                    document.getElementById("addREDIRECT-redirecturl").focus();
                    document.getElementById("validateresp").innerHTML = {/literal}"{$ADDONLANG.dnssuitePage_manage_redirectionblank}"{literal}+" "+document.getElementById("addREDIRECT-redirecturl").value;
                    $('#myModal').modal('show');
                    return false;
                }else if (!document.getElementById("addREDIRECT-redirecturl").value.match(exp)){
                    $('#validateaddresp').html('invalid value');
                    document.getElementById("addREDIRECT-redirecturl").focus();
                    document.getElementById("validateresp").innerHTML = {/literal}"{$ADDONLANG.dnssuitePage_manage_invalidredirectionurl}"{literal}+" "+document.getElementById("addREDIRECT-redirecturl").value;
                    $('#myModal').modal('show');
                    return false;
                }else if (!document.getElementById("addREDIRECT-fromurl").value.match(exp2) && document.getElementById("addREDIRECT-fromurl").value != "" && document.getElementById("addREDIRECT-type").value == 999){
                    document.getElementById("addREDIRECT-fromurl").focus();
                    document.getElementById("validateresp").innerHTML = {/literal}"{$ADDONLANG.dnssuitePage_manage_invalidredirectionurlmasked}"{literal}+" "+document.getElementById("addREDIRECT-fromurl").value;
                    $('#myModal').modal('show');
                    return false;
                }else{
                    if (document.getElementById("addREDIRECT-type").value == 999){
                        $.ajax({
                            type: "POST",
                            url: "modules/addons/dnssuite/include/dnssuite_ajax.php",
                            data: { domainid: domainid, fromurl: document.getElementById("addREDIRECT-fromurl").value, redirecturl: document.getElementById("addREDIRECT-redirecturl").value, type: document.getElementById("addREDIRECT-type").value ,action: "addREDIRECT", maskedtitle: document.getElementById("maskedtitle").value.replace(/<\/?[^>]+(>|$)/g, ""), maskedmeta: document.getElementById("maskedmeta").value.replace(/<\/?[^>]+(>|$)/g, ""), maskedkeywords: document.getElementById("maskedkeywords").value.replace(/<\/?[^>]+(>|$)/g, "")},
                            success:function(result){
                                var result = JSON.parse(result);
                                if (result.status == 0){
                                    $.notify({message: '{/literal}{$ADDONLANG.dnssuitePage_manage_redirect_failed_url}{literal}'},{type: 'danger',delay: 5000,timer: 1000,newest_on_top: true,animate: {enter: 'animated fadeInDown',exit: 'animated fadeOutDown'},});
                                    return false;
                                }else if (result.status == 2){
                                    $.notify({message: '{/literal}{$ADDONLANG.dnssuitePage_manage_invalidredirectionurl}{literal}'},{type: 'danger',delay: 5000,timer: 1000,newest_on_top: true,animate: {enter: 'animated fadeInDown',exit: 'animated fadeOutDown'},});
                                }else if (result.status == 3){
                                    $.notify({message: '{/literal}{$ADDONLANG.dnssuitePage_manage_redirect_addfailed_duplicate}{literal}'},{type: 'danger',delay: 5000,timer: 1000,newest_on_top: true,animate: {enter: 'animated fadeInDown',exit: 'animated fadeOutDown'},});
                                }else if (result.status == 7){
                                    $.notify({message: '{/literal}{$ADDONLANG.dnssuitePage_manage_redirectatroot}{literal}'},{type: 'danger',delay: 5000,timer: 1000,newest_on_top: true,animate: {enter: 'animated fadeInDown',exit: 'animated fadeOutDown'},});
                                }else if (result.status == 8){
                                    $.notify({message: '{/literal}{$ADDONLANG.dnssuitePage_manage_invalidtype}{literal}'},{type: 'danger',delay: 5000,timer: 1000,newest_on_top: true,animate: {enter: 'animated fadeInDown',exit: 'animated fadeOutDown'},});
                                }else if (result.status == 1){
                                    var arraydata = result.data;
                                    if (result.count < limits_redirect || limits_redirect == 0) var write = true;
                                    else var write = false;
                                    $("#REDIRECTtable").find("tr:gt(0)").remove();
                                    BuildTable(arraydata, "REDIRECT", write);
                                    $.notify({message: '{/literal}{$ADDONLANG.dnssuitePage_manage_redirect_success}{literal}'},{type: 'success',delay: 5000,timer: 1000,newest_on_top: true,animate: {enter: 'animated fadeInDown',exit: 'animated fadeOutDown'},});
                                    if (limits_redirect != 0){
                                        document.getElementById("REDIRECTcount").innerHTML = result.count;
                                    }
                                    return false;
                                }
                        }});
                    }else{
                        $.ajax({
                            type: "POST",
                            url: "modules/addons/dnssuite/include/dnssuite_ajax.php",
                            data: { domainid: domainid, fromurl: document.getElementById("addREDIRECT-fromurl").value, redirecturl: document.getElementById("addREDIRECT-redirecturl").value, type: document.getElementById("addREDIRECT-type").value ,action: "addREDIRECT"},
                            success:function(result){
                                var result = JSON.parse(result);
                                if (result.status == 0){
                                    $.notify({message: '{/literal}{$ADDONLANG.dnssuitePage_manage_redirect_failed_url}{literal}'},{type: 'danger',delay: 5000,timer: 1000,newest_on_top: true,animate: {enter: 'animated fadeInDown',exit: 'animated fadeOutDown'},});
                                    return false;
                                }else if (result.status == 2){
                                    $.notify({message: '{/literal}{$ADDONLANG.dnssuitePage_manage_invalidredirectionurl}{literal}'},{type: 'danger',delay: 5000,timer: 1000,newest_on_top: true,animate: {enter: 'animated fadeInDown',exit: 'animated fadeOutDown'},});
                                }else if (result.status == 3){
                                    $.notify({message: '{/literal}{$ADDONLANG.dnssuitePage_manage_redirect_addfailed_duplicate}{literal}'},{type: 'danger',delay: 5000,timer: 1000,newest_on_top: true,animate: {enter: 'animated fadeInDown',exit: 'animated fadeOutDown'},});
                                }else if (result.status == 1){
                                    var arraydata = result.data;
                                    if (result.count < limits_redirect || limits_redirect == 0) var write = true;
                                    else var write = false;
                                    $("#REDIRECTtable").find("tr:gt(0)").remove();
                                    BuildTable(arraydata, "REDIRECT", write);
                                    $.notify({message: '{/literal}{$ADDONLANG.dnssuitePage_manage_redirect_success}{literal}'},{type: 'success',delay: 5000,timer: 1000,newest_on_top: true,animate: {enter: 'animated fadeInDown',exit: 'animated fadeOutDown'},});
                                    document.getElementById("REDIRECTcount").innerHTML = result.count;
                                    return false;
                                }
                        }});
                    }
                }
            });
            $(document).on("click", '.modifyREDIRECTbtn',function(e) {
                e.preventDefault();
                var row = $(this).val();
                var exp = /^(?:http(s)?:\/\/)?[\w.-]+(?:\.[\w\.-]+)+[\w\-\._~:/?#[\]@!\$&'\(\)\*\+,;=.]+$/g;

                if (document.getElementById("REDIRECT-"+row+"-type").value != 301 && document.getElementById("REDIRECT-"+row+"-type").value != 302 && document.getElementById("REDIRECT-"+row+"-type").value != 303 && document.getElementById("REDIRECT-"+row+"-type").value != 999){
                    $('#validateaddresp').html('invalid value');
                    document.getElementById("REDIRECT-"+row+"-type").focus();
                    document.getElementById("validateresp").innerHTML = {/literal}"{$ADDONLANG.dnssuitePage_manage_invalidtype}"{literal}+" "+document.getElementById("REDIRECT-"+row+"-type").value;
                    $('#myModal').modal('show');
                    return false;
                }
                if (document.getElementById("REDIRECT-"+row+"-redirecturl").value == ""){
                    $('#validateaddresp').html('invalid value');
                    document.getElementById("REDIRECT-"+row+"-redirecturl").focus();
                    document.getElementById("validateresp").innerHTML = {/literal}"{$ADDONLANG.dnssuitePage_manage_redirectionblank}"{literal}+" "+document.getElementById("REDIRECT-"+row+"-redirecturl").value;
                    $('#myModal').modal('show');
                    return false;
                }else if (!document.getElementById("REDIRECT-"+row+"-redirecturl").value.match(exp)){
                    $('#validateaddresp').html('invalid value');
                    document.getElementById("REDIRECT-"+row+"-redirecturl").focus();
                    document.getElementById("validateresp").innerHTML = {/literal}"{$ADDONLANG.dnssuitePage_manage_invalidredirectionurl}"{literal}+" "+document.getElementById("REDIRECT-"+row+"-redirecturl").value;
                    $('#myModal').modal('show');
                    return false;
                }else{
                    $.ajax({
                        type: "POST",
                        url: "modules/addons/dnssuite/include/dnssuite_ajax.php",
                        data: { domainid: domainid, redirectid: row, redirecturl: document.getElementById("REDIRECT-"+row+"-redirecturl").value, type: document.getElementById("REDIRECT-"+row+"-type").value ,action: "modifyREDIRECT"},
                        success:function(result){
                            var result = JSON.parse(result);
                            if (result.status == 0){
                                $.notify({message: '{/literal}{$ADDONLANG.dnssuitePage_manage_redirect_modifyfailed_support}{literal}'},{type: 'danger',delay: 5000,timer: 1000,newest_on_top: true,animate: {enter: 'animated fadeInDown',exit: 'animated fadeOutDown'},});
                                return false;
                            }else if (result.status == 1){
                                var arraydata = result.data;
                                if (result.count < limits_redirect || limits_redirect == 0) var write = true;
                                else var write = false;
                                $("#REDIRECTtable").find("tr:gt(0)").remove();
                                BuildTable(arraydata, "REDIRECT", write);
                                $.notify({message: '{/literal}{$ADDONLANG.dnssuitePage_manage_redirect_modify_success}{literal}'},{type: 'success',delay: 5000,timer: 1000,newest_on_top: true,animate: {enter: 'animated fadeInDown',exit: 'animated fadeOutDown'},});
                                document.getElementById("REDIRECTcount").innerHTML = result.count;
                                return false;
                            }
                    }});
                }
            });
            $(document).on("click", '.deleteREDIRECTbtn',function(e) {
                e.preventDefault();
                var row = $(this).val();

                $('#deletemodalREDIRECT').modal({
                backdrop: 'static',
                keyboard: true
                }).one('click', '#deletebutton', function(e) {
                    $.ajax({
                        type: "POST",
                        url: "modules/addons/dnssuite/include/dnssuite_ajax.php",
                        data: { domainid: domainid, redirectid: row, action: "deleteREDIRECT"},
                        success:function(result){
                            var result = JSON.parse(result);
                            if (result.status == 0){
                                $.notify({message: '{/literal}{$ADDONLANG.dnssuitePage_manage_redirect_delete_failed}{literal}'},{type: 'danger',delay: 5000,timer: 1000,newest_on_top: true,animate: {enter: 'animated fadeInDown',exit: 'animated fadeOutDown'},});
                                return false;
                            }else if (result.status == 1){
                                $.notify({message: '{/literal}{$ADDONLANG.dnssuitePage_manage_redirect_delete_success}{literal}'},{type: 'success',delay: 5000,timer: 1000,newest_on_top: true,animate: {enter: 'animated fadeInDown',exit: 'animated fadeOutDown'},});
                                var arraydata = result.data;
                                if (result.count < limits_redirect || limits_redirect == 0) var write = true;
                                else var write = false;
                                $("#REDIRECTtable").find("tr:gt(0)").remove();
                                BuildTable(arraydata, "REDIRECT", write);
                                document.getElementById("REDIRECTcount").innerHTML = result.count;
                                return false;
                            }
                    }});
                });
            });
            {/literal}
        {/if}

        {if $emailconfig["enable"] == "on" && $edition != "free"}
            {literal}
                $(function() {
                    $("#forwarder-tip").tooltip();
                });
                $(document).on("click", '.modifyALIASbtn',function(e){
                    e.preventDefault();
                    var row = $(this).val();
                    var selvals = $('#'+row+"-emails").val();
                    if ( selvals == null ){
                        $.notify({message: '{/literal}{$ADDONLANG.dnssuitePage_manage_forwarder_modify_null}{literal}'},{type: 'danger',delay: 5000,timer: 1000,newest_on_top: true,animate: {enter: 'animated fadeInDown',exit: 'animated fadeOutDown'},});
                    }else{
                        $.ajax({
                            type: "POST",
                            url: "modules/addons/dnssuite/include/dnssuite_ajax.php",
                            data: { domainid: domainid, forwarderid: row, emails: selvals, action: "modifyALIAS"},
                            success:function(result){
                                var result = JSON.parse(result);
                                if (result.status == 0){
                                    $.notify({message: '{/literal}{$ADDONLANG.dnssuitePage_manage_forwarder_modify_failed}{literal}'},{type: 'danger',delay: 5000,timer: 1000,newest_on_top: true,animate: {enter: 'animated fadeInDown',exit: 'animated fadeOutDown'},});
                                    return false;
                                }else if (result.status == 1){
                                    $.notify({message: '{/literal}{$ADDONLANG.dnssuitePage_manage_forwarder_modify_success}{literal}'},{type: 'success',delay: 5000,timer: 1000,newest_on_top: true,animate: {enter: 'animated fadeInDown',exit: 'animated fadeOutDown'},});
                                    var data = result.data;
                                    if (result.count < limits_alias) var write = true;
                                    else var write = false;
                                    $("#ALIAStable").find("tr:gt(0)").remove();
                                    BuildTableAliases(data, write);
                                    document.getElementById("ALIAScount").innerHTML = result.count;
                                    $('.emails-multiple').select2();
                                }
                        }});
                    }
                });
                $(document).on("click", '.deleteALIASbtn',function(e){
                    e.preventDefault();
                    var row = $(this).val();
                    $.ajax({
                        type: "POST",
                        url: "modules/addons/dnssuite/include/dnssuite_ajax.php",
                        data: { domainid: domainid, forwarderid: row, action: "deleteALIAS"},
                        success:function(result){
                            var result = JSON.parse(result);
                            if (result.status == 0){
                                $.notify({message: '{/literal}{$ADDONLANG.dnssuitePage_manage_forwarder_delete_failed}{literal}'},{type: 'danger',delay: 5000,timer: 1000,newest_on_top: true,animate: {enter: 'animated fadeInDown',exit: 'animated fadeOutDown'},});
                                return false;
                            }else if (result.status == 1){
                                $.notify({message: '{/literal}{$ADDONLANG.dnssuitePage_manage_forwarder_delete_success}{literal}'},{type: 'success',delay: 5000,timer: 1000,newest_on_top: true,animate: {enter: 'animated fadeInDown',exit: 'animated fadeOutDown'},});
                                var data = result.data;
                                if (result.count < limits_alias) var write = true;
                                else var write = false;
                                $("#ALIAStable").find("tr:gt(0)").remove();
                                BuildTableAliases(data, write);
                                document.getElementById("ALIAScount").innerHTML = result.count;
                                $('.emails-multiple').select2();
                            }
                        }});
                });
                $(document).on("click", '.addALIASbtn',function(e){
                    e.preventDefault();
                    if (document.getElementById("addALIAS-alias").value == ""){
                        $.notify({message: '{/literal}{$ADDONLANG.dnssuitePage_manage_newalias_empty}{literal}'},{type: 'danger',delay: 5000,timer: 1000,newest_on_top: true,animate: {enter: 'animated fadeInDown',exit: 'animated fadeOutDown'},});
                        document.getElementById("addALIAS-alias").focus();
                        return false;
                    }else{
                        $.ajax({
                        type: "POST",
                        url: "modules/addons/dnssuite/include/dnssuite_ajax.php",
                        data: { domainid: domainid, newalias: document.getElementById("addALIAS-alias").value, action: "addALIAS"},
                        success:function(result){
                            var result = JSON.parse(result);
                            if (result.status == 0){
                                $.notify({message: '{/literal}{$ADDONLANG.dnssuitePage_manage_addalias_existed}{literal}'},{type: 'danger',delay: 5000,timer: 1000,newest_on_top: true,animate: {enter: 'animated fadeInDown',exit: 'animated fadeOutDown'},});
                                return false;
                            }else if (result.status == 2){
                                $.notify({message: '{/literal}{$ADDONLANG.dnssuitePage_manage_addalias_validation}{literal}'},{type: 'danger',delay: 5000,timer: 1000,newest_on_top: true,animate: {enter: 'animated fadeInDown',exit: 'animated fadeOutDown'},});
                                return false;
                            }else if (result.status == 1){
                                $.notify({message: '{/literal}{$ADDONLANG.dnssuitePage_manage_addemail_success}{literal}'},{type: 'success',delay: 5000,timer: 1000,newest_on_top: true,animate: {enter: 'animated fadeInDown',exit: 'animated fadeOutDown'},});
                                var data = result.data;
                                if (result.count < limits_alias) var write = true;
                                else var write = false;
                                $("#ALIAStable").find("tr:gt(0)").remove();
                                BuildTableAliases(data, write);
                                document.getElementById("ALIAScount").innerHTML = result.count;
                                $('.emails-multiple').select2();
                            }
                        }});
                    }
                });
                $(document).on("click", '.addFORWARDERbtn',function(e){
                    e.preventDefault();
                    var exp = /^(([^<>()\[\]\.,;:\s@\"]+(\.[^<>()\[\]\.,;:\s@\"]+)*)|(\".+\"))@(([^<>()[\]\.,;:\s@\"]+\.)+[^<>()[\]\.,;:\s@\"]{2,})$/i;
                    if (document.getElementById("addFORWARDER-email").value == ""){
                        document.getElementById("addFORWARDER-email").focus();

                        $.notify({message: '{/literal}{$ADDONLANG.dnssuitePage_manage_emailempty}{literal}'},{type: 'danger',delay: 5000,timer: 1000,newest_on_top: true,animate: {enter: 'animated fadeInDown',exit: 'animated fadeOutDown'},});
                        return false;
                    }else if (!document.getElementById("addFORWARDER-email").value.match(exp)){
                        document.getElementById("addFORWARDER-email").focus();

                        $.notify({message: '{/literal}{$ADDONLANG.dnssuitePage_manage_emailinvalid}{literal}'},{type: 'danger',delay: 5000,timer: 1000,newest_on_top: true,animate: {enter: 'animated fadeInDown',exit: 'animated fadeOutDown'},});
                        return false;
                    }else{
                        $.ajax({
                        type: "POST",
                        url: "modules/addons/dnssuite/include/dnssuite_ajax.php",
                        data: { domainid: domainid, newemail: document.getElementById("addFORWARDER-email").value, action: "addEMAIL"},
                        success:function(result){
                            var result = JSON.parse(result);
                            if (result.status == 0){
                                $.notify({message: '{/literal}{$ADDONLANG.dnssuitePage_manage_addemail_failed}{literal}'},{type: 'danger',delay: 5000,timer: 1000,newest_on_top: true,animate: {enter: 'animated fadeInDown',exit: 'animated fadeOutDown'},});
                                return false;
                            }else if (result.status == 2){
                                $.notify({message: '{/literal}{$ADDONLANG.dnssuitePage_manage_addemail_validation}{literal}'},{type: 'danger',delay: 5000,timer: 1000,newest_on_top: true,animate: {enter: 'animated fadeInDown',exit: 'animated fadeOutDown'},});
                                return false;
                            }else if (result.status == 3){
                                $.notify({message: '{/literal}{$ADDONLANG.dnssuitePage_manage_addemail_existed}{literal}'},{type: 'danger',delay: 5000,timer: 1000,newest_on_top: true,animate: {enter: 'animated fadeInDown',exit: 'animated fadeOutDown'},});
                                return false;
                            }else if (result.status == 4){
                                $.notify({message: '{/literal}{$ADDONLANG.dnssuitePage_manage_addemail_slotfull}{literal}'},{type: 'danger',delay: 5000,timer: 1000,newest_on_top: true,animate: {enter: 'animated fadeInDown',exit: 'animated fadeOutDown'},});
                                return false;
                            }else if (result.status == 1){
                                $.notify({message: '{/literal}{$ADDONLANG.dnssuitePage_manage_addemaildestination_success}{literal}'},{type: 'success',delay: 5000,timer: 1000,newest_on_top: true,animate: {enter: 'animated fadeInDown',exit: 'animated fadeOutDown'},});
                                var datapending = result.datapending;
                                var dataconfirmed = result.dataconfirmed;
                                if (result.count < limits_emailslots) var write = true;
                                else var write = false;
                                $("#FORWARDERtable").find("tr:gt(0)").remove();
                                BuildTableEmails(datapending, dataconfirmed, write);
                                document.getElementById("EMAILSLOTcount").innerHTML = result.count;
                                return false;
                            }
                        }});
                    }
                });

                $(document).on("click", '.deleteFORWARDERbtn',function(e) {
                    e.preventDefault();
                    var row = $(this).val();

                    $.ajax({
                        type: "POST",
                        url: "modules/addons/dnssuite/include/dnssuite_ajax.php",
                        data: { domainid: domainid, emailid: row, action: "deleteEMAIL"},
                        success:function(result){
                            var result = JSON.parse(result);
                            if (result.status == 0){
                                $.notify({message: '{/literal}{$ADDONLANG.dnssuitePage_manage_deleteemail_failed}{literal}'},{type: 'danger',delay: 5000,timer: 1000,newest_on_top: true,animate: {enter: 'animated fadeInDown',exit: 'animated fadeOutDown'},});
                                return false;
                            }else if (result.status == 2){
                                $.notify({message: '{/literal}{$ADDONLANG.dnssuitePage_manage_deleteemail_failed_inuse}{literal}'},{type: 'danger',delay: 5000,timer: 1000,newest_on_top: true,animate: {enter: 'animated fadeInDown',exit: 'animated fadeOutDown'},});
                                return false;
                            }else if (result.status == 3){
                                $.notify({message: '{/literal}{$ADDONLANG.dnssuitePage_manage_deleteemail_failed_id}{literal}'},{type: 'danger',delay: 5000,timer: 1000,newest_on_top: true,animate: {enter: 'animated fadeInDown',exit: 'animated fadeOutDown'},});
                                return false;
                            }else if (result.status == 1){
                                $.notify({message: '{/literal}{$ADDONLANG.dnssuitePage_manage_deleteemail_success}{literal}'},{type: 'success',delay: 5000,timer: 1000,newest_on_top: true,animate: {enter: 'animated fadeInDown',exit: 'animated fadeOutDown'},});
                                var datapending = result.datapending;
                                var dataconfirmed = result.dataconfirmed;
                                var forwarderdata = result.forwarderdata;
                                if (result.count < limits_emailslots) var write = true;
                                else var write = false;
                                $("#FORWARDERtable").find("tr:gt(0)").remove();
                                BuildTableEmails(datapending, dataconfirmed, write);
                                document.getElementById("EMAILSLOTcount").innerHTML = result.count;
                                if (result.forwardercount < limits_alias) var write = true;
                                else var write = false;
                                $("#ALIAStable").find("tr:gt(0)").remove();
                                BuildTableAliases(forwarderdata, write);
                                document.getElementById("ALIAScount").innerHTML = result.forwardercount;
                                {/literal}
                                {if $catchallconfig["enable"] == "on" && $edition != "free"}
                                    {literal}
                                        var catchalloptions = result.catchalloptions;
                                        var mailto = result.catchallmailto;
                                        var destinationemails = result.destinationemails;
                                        BuildTableCatchAll(destinationemails, catchalloptions, mailto);
                                    {/literal}
                                {/if}
                                {literal}
                                $('.emails-multiple').select2();
                                return false;
                            }
                    }});
                });

                $(document).on("click", '.verifyFORWARDERbtn',function(e) {
                    e.preventDefault();
                    var row = $(this).val();

                    if (document.getElementById("FORWARDER-"+row+"-pin").value == ""){
                        $('#validateaddresp').html('invalid value');
                        document.getElementById("FORWARDER-"+row+"-pin").focus();

                        document.getElementById("validateresp").innerHTML = {/literal}"{$ADDONLANG.dnssuitePage_manage_verifypin_empty}"{literal}+" ";
                        $('#myModal').modal('show');
                        return false;
                    }else{
                        $.ajax({
                        type: "POST",
                        url: "modules/addons/dnssuite/include/dnssuite_ajax.php",
                        data: { domainid: domainid, emailid: row, pin: document.getElementById("FORWARDER-"+row+"-pin").value, action: "verifyEMAIL"},
                        success:function(result){
                            var result = JSON.parse(result);
                            if (result.status == 0){
                                $.notify({message: '{/literal}{$ADDONLANG.dnssuitePage_manage_verifypin_failed}{literal}'},{type: 'danger',delay: 5000,timer: 1000,newest_on_top: true,animate: {enter: 'animated fadeInDown',exit: 'animated fadeOutDown'},});
                                return false;
                            }else if (result.status == 2){
                                $.notify({message: '{/literal}{$ADDONLANG.dnssuitePage_manage_verifypin_incorrectpin}{literal}'},{type: 'danger',delay: 5000,timer: 1000,newest_on_top: true,animate: {enter: 'animated fadeInDown',exit: 'animated fadeOutDown'},});
                            }else if (result.status == 1){
                                $.notify({message: '{/literal}{$ADDONLANG.dnssuitePage_manage_verifypin_correctpin}{literal}'},{type: 'success',delay: 5000,timer: 1000,newest_on_top: true,animate: {enter: 'animated fadeInDown',exit: 'animated fadeOutDown'},});
                                var datapending = result.datapending;
                                var dataconfirmed = result.dataconfirmed;
                                var forwarderdata = result.forwarderdata;
                                if (result.count < limits_emailslots || limits_emailslots == 0) var write = true;
                                else var write = false;
                                $("#FORWARDERtable").find("tr:gt(0)").remove();
                                BuildTableEmails(datapending, dataconfirmed, write);
                                document.getElementById("EMAILSLOTcount").innerHTML = result.count;
                                if (result.forwardercount < limits_alias) var write = true;
                                else var write = false;
                                $("#ALIAStable").find("tr:gt(0)").remove();
                                BuildTableAliases(forwarderdata, write);
                                document.getElementById("ALIAScount").innerHTML = result.forwardercount;
                                {/literal}
                                {if $catchallconfig["enable"] == "on" && $edition != "free"}
                                    {literal}
                                        var catchalloptions = result.catchalloptions;
                                        var mailto = result.catchallmailto;
                                        var destinationemails = result.destinationemails;
                                        BuildTableCatchAll(destinationemails, catchalloptions, mailto);
                                    {/literal}
                                {/if}
                                {literal}
                                $('.emails-multiple').select2();
                                return false;
                            }
                        }});
                    }
                });
            {/literal}
        {/if}

        {if $catchallconfig["enable"] == "on" && $edition != "free"}
            {literal}
                $(function() {
                    $("#catchall-tip").tooltip();
                });
                $(document).on("click", '.modifyCATCHALLbtn',function(e){
                    e.preventDefault();
                    var selvals = $('#emails-catchall').val();
                    $.ajax({
                        type: "POST",
                        url: "modules/addons/dnssuite/include/dnssuite_ajax.php",
                        data: { domainid: domainid, emails: selvals, action: "modifyCATCHALL"},
                        success:function(result){
                            var result = JSON.parse(result);
                            if (result.status == 0){
                                $.notify({message: '{/literal}{$ADDONLANG.dnssuitePage_manage_catchall_disable_failed}{literal}'},{type: 'danger',delay: 5000,timer: 1000,newest_on_top: true,animate: {enter: 'animated fadeInDown',exit: 'animated fadeOutDown'},});
                                return false;
                            }else if (result.status == 3){
                                $.notify({message: '{/literal}{$ADDONLANG.dnssuitePage_manage_catchall_invalidemail}{literal}'},{type: 'danger',delay: 5000,timer: 1000,newest_on_top: true,animate: {enter: 'animated fadeInDown',exit: 'animated fadeOutDown'},});
                                return false;
                            }
                            else if (result.status == 2){
                                $.notify({message: '{/literal}{$ADDONLANG.dnssuitePage_manage_catchall_disable_success}{literal}'},{type: 'success',delay: 5000,timer: 1000,newest_on_top: true,animate: {enter: 'animated fadeInDown',exit: 'animated fadeOutDown'},});
                                var destinationemails = result.destinationemails;
                                var catchalloptions = result.catchalloptions;
                                var mailto = result.catchallmailto;
                                BuildTableCatchAll(destinationemails, catchalloptions, mailto);
                                $('.emails-multiple').select2();
                                document.getElementById("catchallstatus").innerHTML = catchallstatusword+': <font color="red">'+catchalloffword+'</font>';
                                return false;
                            }else if (result.status == 1){
                                $.notify({message: '{/literal}{$ADDONLANG.dnssuitePage_manage_catchall_success}{literal}'},{type: 'success',delay: 5000,timer: 1000,newest_on_top: true,animate: {enter: 'animated fadeInDown',exit: 'animated fadeOutDown'},});
                                var destinationemails = result.destinationemails;
                                var catchalloptions = result.catchalloptions;
                                var mailto = result.catchallmailto;
                                BuildTableCatchAll(destinationemails, catchalloptions, mailto);
                                $('.emails-multiple').select2();
                                document.getElementById("catchallstatus").innerHTML = catchallstatusword+': <font color="green">'+catchallonword+'</font>';
                                return false;
                            }
                        }
                    });
                });
            {/literal}
        {/if}

        {if $configs.enabledyndns == "on" && $edition == "professional"}
        {literal}
             $(document).on("click", '.refreshAPIbtn',function(e){
                e.preventDefault();
                $.ajax({
                    type: "POST",
                    url: "modules/addons/dnssuite/include/dnssuite_ajax.php",
                    data: { domainid: domainid, action: "refreshapi"},
                    success:function(result){
                        var result = JSON.parse(result);
                        if (result.status == 0){
                            $.notify({message: '{/literal}{$ADDONLANG.dnssuitePage_manage_api_refresh_failed}{literal}'},{type: 'danger',delay: 5000,timer: 1000,newest_on_top: true,animate: {enter: 'animated fadeInDown',exit: 'animated fadeOutDown'},});
                            return false;
                        }else if (result.status == 1){
                            $.notify({message: '{/literal}{$ADDONLANG.dnssuitePage_manage_api_refresh_success}{literal}'},{type: 'success',delay: 5000,timer: 1000,newest_on_top: true,animate: {enter: 'animated fadeInDown',exit: 'animated fadeOutDown'},});
                            $("#APIkeyphrase").attr("value",result.keyphrase);
                            $("#APIpass").attr("value",result.pass);
                            return false;
                        }
                }});
             });
            $(document).on("click", '.enableAPIbtn',function(e){
                e.preventDefault();
                $.ajax({
                    type: "POST",
                    url: "modules/addons/dnssuite/include/dnssuite_ajax.php",
                    data: { domainid: domainid, action: "enableapi"},
                    success:function(result){
                        var result = JSON.parse(result);
                        if (result.status == 0){
                            $.notify({message: '{/literal}{$ADDONLANG.dnssuitePage_manage_api_enable_failed}{literal}'},{type: 'danger',delay: 5000,timer: 1000,newest_on_top: true,animate: {enter: 'animated fadeInDown',exit: 'animated fadeOutDown'},});
                            return false;
                        }else if (result.status == 1){
                            $.notify({message: '{/literal}{$ADDONLANG.dnssuitePage_manage_api_enable_success}{literal}'},{type: 'success',delay: 5000,timer: 1000,newest_on_top: true,animate: {enter: 'animated fadeInDown',exit: 'animated fadeOutDown'},});
                            $("#APIbtn").removeClass('btn-success');
                            $("#APIbtn").removeClass('enableAPIbtn');
                            $("#APIbtn").addClass('btn-danger');
                            $("#APIbtn").addClass('disableAPIbtn');
                            $("#APIbtn").html('<i class="fa fa-power-off"></i> {/literal}{$ADDONLANG.dnssuitePage_manage_api_disable}{literal}');
                            return false;
                        }
                    }
                });
            });
            $(document).on("click", '.disableAPIbtn',function(e){
                e.preventDefault();
                $.ajax({
                    type: "POST",
                    url: "modules/addons/dnssuite/include/dnssuite_ajax.php",
                    data: { domainid: domainid, action: "disableapi"},
                    success:function(result){
                        var result = JSON.parse(result);
                        if (result.status == 0){
                            $.notify({message: '{/literal}{$ADDONLANG.dnssuitePage_manage_api_disable_failed}{literal}'},{type: 'danger',delay: 5000,timer: 1000,newest_on_top: true,animate: {enter: 'animated fadeInDown',exit: 'animated fadeOutDown'},});
                            return false;
                        }else if (result.status == 1){
                            $.notify({message: '{/literal}{$ADDONLANG.dnssuitePage_manage_api_disable_success}{literal}'},{type: 'success',delay: 5000,timer: 1000,newest_on_top: true,animate: {enter: 'animated fadeInDown',exit: 'animated fadeOutDown'},});
                            $("#APIbtn").removeClass('btn-danger');
                            $("#APIbtn").removeClass('disableAPIbtn');
                            $("#APIbtn").addClass('btn-success');
                            $("#APIbtn").addClass('enableAPIbtn');
                            $("#APIbtn").html('<i class="fa fa-power-off"></i> {/literal}{$ADDONLANG.dnssuitePage_manage_api_enable}{literal}');
                            return false;
                        }
                    }
                });
            });
        {/literal}
        {/if}

        {if $configs["enablenotification"] == "on"}
        {literal}
            $(document).on("click", '.updateNOTIFYbtn',function(e){
                e.preventDefault();
                if ($("#notifydns").is(":checked")){
                    var dns = 1;
                } else {
                    var dns = 0;
                }
                if ($("#notifyemailforward").is(":checked")){
                    var emailforward = 1;
                } else {
                    var emailforward = 0;
                }
                if ($("#notifyemailcatchall").is(":checked")){
                    var emailcatchall = 1;
                } else {
                    var emailcatchall = 0;
                }
                if ($("#notifywebredirect").is(":checked")){
                    var webredirect = 1;
                } else {
                    var webredirect = 0;
                }
                if ($("#notifyddns").is(":checked")){
                    var ddns = 1;
                } else {
                    var ddns = 0;
                }

                $.ajax({
                    type: "POST",
                    url: "modules/addons/dnssuite/include/dnssuite_ajax.php",
                    data: { domainid: domainid, action: "updatenotification", dns: dns
, emailforward: emailforward, emailcatchall: emailcatchall, webredirect: webredirect, ddns: ddns},
                    success:function(result){
                        var result = JSON.parse(result);
                        if (result.status == 0){
                            $.notify({message: '{/literal}{$ADDONLANG.dnssuitePage_manage_notification_update_failed}{literal}'},{type: 'danger',delay: 5000,timer: 1000,newest_on_top: true,animate: {enter: 'animated fadeInDown',exit: 'animated fadeOutDown'},});
                            return false;
                        }else if (result.status == 1){
                            $.notify({message: '{/literal}{$ADDONLANG.dnssuitePage_manage_notification_update_success}{literal}'},{type: 'success',delay: 5000,timer: 1000,newest_on_top: true,animate: {enter: 'animated fadeInDown',exit: 'animated fadeOutDown'},});
                            return false;
                        }
                    }
                });
            });
        {/literal}
        {/if}

        {if $configs.enablednstemplate == "on"}
        {literal}
            function saveTemplate(form){
                var templateformat = /^(\w+)$/;

                if(form["name"].value.match(templateformat)){
                    document.getElementById("modal-loading").style.display = "block";
                    form.submit();
                    return true;
                }else{
                    form["name"].focus();
                    document.getElementById("validateresp").innerHTML = {/literal}"{$ADDONLANG.dnssuitePage_manage_js_templateinvalid}"{literal}+" "+form["name"].value;
                    $('#myModal').modal('show');
                    return false;
                }
            }

            function deleteUserDNSTemplateConfirm(form){
                $('#deleteuserdnstemplatemodal').modal({
                    backdrop: 'static',
                    keyboard: true
                })
                    .one('click', '#deletebutton', function(e) {
                        form.submit();
                        return true;
                    });
            }

            function restoreDNSTemplateConfirm(form){
                $('#restorednstemplatemodal').modal({
                    backdrop: 'static',
                    keyboard: true
                })
                    .one('click', '#deletebutton', function(e) {
                        form.submit();
                        return true;
                    });
            }
        {/literal}
        {/if}
        {literal}

</script>
{/literal}
<hr>

{if $notowned == true}

{else}
    {if $style == "Twentyone"}
        <div class="row">
            <div class="col-sm-12">
                <div class="col-xs-12"> <!-- required for floating -->
                    <!-- Nav tabs -->
                    <ul class="nav nav-pills">
                        <li class="nav-item">
                            <a href="#home-v" data-toggle="tab" class="nav-link active">{$ADDONLANG.dnssuitePage_manage_overview}</a>
                        </li>
                        {if ($disablemanage == "on" && $nsfail != true) || $disablemanage != "on" }
                            {if $subdomain.enable == "on"}<li class="nav-item"><a href="#subdomain-v" data-toggle="tab" class="nav-link">{$ADDONLANG.dnssuitePage_manage_subdomain}</a></li>{/if}
                            {if $configs.enablednseditor == "on"}
                                <li class="nav-item dropdown">
                                    <a data-toggle="dropdown" href="#" role="button" aria-haspopup="true" aria-expanded="false" class="nav-link dropdown-toggle">{$ADDONLANG.dnssuitePage_manage_dnszone}<span class="caret"></span></a>
                                    <div class="dropdown-menu">
                                        {if $records_a.modify == "on"}
                                            {if $records_a.limit == 0}
                                                <a href="#a-v" data-toggle="tab" class="dropdown-item">A</a>
                                            {else}
                                                <a href="#a-v" data-toggle="tab" class="dropdown-item">A (<span id="Acount">{$recordcount.a}</span>/{$records_a.limit})</a>
                                            {/if}
                                        {/if}
                                        {if $records_aaaa.modify == "on"}
                                            {if $records_aaaa.limit == 0}
                                                <a href="#aaaa-v" data-toggle="tab" class="dropdown-item">AAAA</a>
                                            {else}
                                                <a href="#aaaa-v" data-toggle="tab" class="dropdown-item">AAAA (<span id="AAAAcount">{$recordcount.aaaa}</span>/{$records_aaaa.limit})</a>
                                            {/if}
                                        {/if}
                                        {if $records_mx.modify == "on"}
                                            {if $records_mx.limit == 0}
                                                <a href="#mx-v" data-toggle="tab" class="dropdown-item">MX</a>
                                            {else}
                                                <a href="#mx-v" data-toggle="tab" class="dropdown-item">MX (<span id="MXcount">{$recordcount.mx}</span>/{$records_mx.limit})</a>
                                            {/if}
                                        {/if}
                                        {if $records_cname.modify == "on"}
                                            {if $records_cname.limit == 0}
                                                <a href="#cname-v" data-toggle="tab" class="dropdown-item">CNAME</a>
                                            {else}
                                                <a href="#cname-v" data-toggle="tab" class="dropdown-item">CNAME (<span id="CNAMEcount">{$recordcount.cname}</span>/{$records_cname.limit})</a>
                                            {/if}
                                        {/if}
                                        {if $records_txt.modify == "on"}
                                            {if $records_txt.limit == 0}
                                                <a href="#txt-v" data-toggle="tab" class="dropdown-item">TXT</a>
                                            {else}
                                                <a href="#txt-v" data-toggle="tab" class="dropdown-item">TXT (<span id="TXTcount">{$recordcount.txt}</span>/{$records_txt.limit})</a>
                                            {/if}
                                        {/if}
                                        {if $records_srv.modify == "on"}
                                            {if $records_srv.limit == 0}
                                                <a href="#srv-v" data-toggle="tab" class="dropdown-item">SRV</a>
                                            {else}
                                                <a href="#srv-v" data-toggle="tab" class="dropdown-item">SRV (<span id="SRVcount">{$recordcount.srv}</span>/{$records_srv.limit})</a>
                                            {/if}
                                        {/if}
                                        {if $records_ns.modify == "on"}
                                            {if $records_ns.limit == 0}
                                                <a href="#ns-v" data-toggle="tab" class="dropdown-item">NS</a>
                                            {else}
                                                <a href="#ns-v" data-toggle="tab" class="dropdown-item">NS (<span id="NScount">{$recordcount.ns}</span>/{$records_ns.limit})</a>
                                            {/if}
                                        {/if}

                                    </div>
                                </li>
                            {/if}
                            {if $urlconfig["enable"] == "on" && $edition != "free"}<li class="nav-item"><a href="#redirect-v" data-toggle="tab" class="nav-link">{$ADDONLANG.dnssuitePage_manage_redirect}</a></li>{/if}
                            {if $emailconfig["enable"] == "on" && $edition != "free"}<li class="nav-item"><a href="#email-v" data-toggle="tab" class="nav-link">{$ADDONLANG.dnssuitePage_manage_emailforward}</a></li>{/if}
                            {if $catchallconfig["enable"] == "on" && $edition != "free"}<li class="nav-item"><a href="#catchall-v" data-toggle="tab" class="nav-link">{$ADDONLANG.dnssuitePage_manage_catchall}</a></li>{/if}
                            {if $configs.enablenotification == "on"}<li class="nav-item"><a href="#notification-v" data-toggle="tab" class="nav-link">{$ADDONLANG.dnssuitePage_manage_notification}</a></li>{/if}
                        {/if}
                    </ul>
                </div>
            </div>
        </div>
    {else}
        <div class="row">
            <div class="col-sm-12">
                <div class="col-xs-12"> <!-- required for floating -->
                    <!-- Nav tabs -->
                    <ul class="nav nav-pills">
                        <li class="active"><a href="#home-v" data-toggle="tab">{$ADDONLANG.dnssuitePage_manage_overview}</a></li>
                        {if ($disablemanage == "on" && $nsfail != true) || $disablemanage != "on" }
                            {if $subdomain.enable == "on"}<li><a href="#subdomain-v" data-toggle="tab">{$ADDONLANG.dnssuitePage_manage_subdomain}</a></li>{/if}
                            {if $configs.enablednseditor == "on"}
                                <li class="dropdown">
                                    <a class="dropdown-toggle" data-toggle="dropdown" href="#">{$ADDONLANG.dnssuitePage_manage_dnszone}<span class="caret"></span></a>
                                    <ul class="dropdown-menu">
                                        {if $records_a.modify == "on"}
                                            {if $records_a.limit == 0}
                                                <li><a href="#a-v" data-toggle="tab">A</a></li>
                                            {else}
                                                <li><a href="#a-v" data-toggle="tab">A (<span id="Acount">{$recordcount.a}</span>/{$records_a.limit})</a></li>
                                            {/if}
                                        {/if}
                                        {if $records_aaaa.modify == "on"}
                                            {if $records_aaaa.limit == 0}
                                                <li><a href="#aaaa-v" data-toggle="tab">AAAA</a></li>
                                            {else}
                                                <li><a href="#aaaa-v" data-toggle="tab">AAAA (<span id="AAAAcount">{$recordcount.aaaa}</span>/{$records_aaaa.limit})</a></li>
                                            {/if}
                                        {/if}
                                        {if $records_mx.modify == "on"}
                                            {if $records_mx.limit == 0}
                                                <li><a href="#mx-v" data-toggle="tab">MX</a></li>
                                            {else}
                                                <li><a href="#mx-v" data-toggle="tab">MX (<span id="MXcount">{$recordcount.mx}</span>/{$records_mx.limit})</a></li>
                                            {/if}
                                        {/if}
                                        {if $records_cname.modify == "on"}
                                            {if $records_cname.limit == 0}
                                                <li><a href="#cname-v" data-toggle="tab">CNAME</a></li>
                                            {else}
                                                <li><a href="#cname-v" data-toggle="tab">CNAME (<span id="CNAMEcount">{$recordcount.cname}</span>/{$records_cname.limit})</a></li>
                                            {/if}
                                        {/if}
                                        {if $records_txt.modify == "on"}
                                            {if $records_txt.limit == 0}
                                                <li><a href="#txt-v" data-toggle="tab">TXT</a></li>
                                            {else}
                                                <li><a href="#txt-v" data-toggle="tab">TXT (<span id="TXTcount">{$recordcount.txt}</span>/{$records_txt.limit})</a></li>
                                            {/if}
                                        {/if}
                                        {if $records_srv.modify == "on"}
                                            {if $records_srv.limit == 0}
                                                <li><a href="#srv-v" data-toggle="tab">SRV</a></li>
                                            {else}
                                                <li><a href="#srv-v" data-toggle="tab">SRV (<span id="SRVcount">{$recordcount.srv}</span>/{$records_srv.limit})</a></li>
                                            {/if}
                                        {/if}
                                        {if $records_ns.modify == "on"}
                                            {if $records_ns.limit == 0}
                                                <li><a href="#ns-v" data-toggle="tab">NS</a></li>
                                            {else}
                                                <li><a href="#ns-v" data-toggle="tab">NS (<span id="NScount">{$recordcount.ns}</span>/{$records_ns.limit})</a></li>
                                            {/if}
                                        {/if}

                                    </ul>
                                </li>
                            {/if}
                            {if $urlconfig["enable"] == "on" && $edition != "free"}<li><a href="#redirect-v" data-toggle="tab">{$ADDONLANG.dnssuitePage_manage_redirect}</a></li>{/if}
                            {if $emailconfig["enable"] == "on" && $edition != "free"}<li><a href="#email-v" data-toggle="tab">{$ADDONLANG.dnssuitePage_manage_emailforward}</a></li>{/if}
                            {if $catchallconfig["enable"] == "on" && $edition != "free"}<li><a href="#catchall-v" data-toggle="tab">{$ADDONLANG.dnssuitePage_manage_catchall}</a></li>{/if}
                            {if $configs.enablenotification == "on"}<li><a href="#notification-v" data-toggle="tab">{$ADDONLANG.dnssuitePage_manage_notification}</a></li>{/if}
                        {/if}
                    </ul>
                </div>
            </div>
        </div>
    {/if}


    <!-- Modal -->
    <div class="modal fade" tabindex="-1" role="dialog" aria-labelledby="exampleModalLabel" aria-hidden="true" id="deletemodalSUBDOMAIN">
        <div class="modal-dialog" role="document" >
            <div class="modal-content" style="padding:0px">
                <div class="modal-header-warning">
                    <h5 class="modal-title" id="exampleModalLabel">{$ADDONLANG.dnssuitePage_manage_js_deleteconfirmresubdomain}</h5>
                </div>
                <div class="modal-body" id="validateresp">

                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-secondary" data-dismiss="modal" id="deletebutton"><i class="fa fa-trash"></i></button>
                    <button type="button" class="btn btn-secondary" data-dismiss="modal"><i class="fa fa-ban"></i></button>
                </div>
            </div>
        </div>
    </div>

    <div class="modal fade" id="myModal" tabindex="-1" role="dialog" aria-labelledby="exampleModalLabel" aria-hidden="true" id="validatemodal">
        <div class="modal-dialog" role="document" >
            <div class="modal-content" style="padding:0px">
                <div class="modal-header-warning">
                    <h5 class="modal-title" id="exampleModalLabel">{$ADDONLANG.dnssuitePage_manage_js_error}</h5>
                </div>
                <div class="modal-body" id="validateresp">

                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-secondary" data-dismiss="modal">X</button>
                </div>
            </div>
        </div>
    </div>

    <div class="modal fade" tabindex="-1" role="dialog" aria-labelledby="exampleModalLabel" aria-hidden="true" id="deletemodalREDIRECT">
        <div class="modal-dialog" role="document" >
            <div class="modal-content" style="padding:0px">
                <div class="modal-header-warning">
                    <h5 class="modal-title" id="exampleModalLabel">{$ADDONLANG.dnssuitePage_manage_js_deleteconfirmredirect}</h5>
                </div>
                <div class="modal-body" id="validateresp">

                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-secondary" data-dismiss="modal" id="deletebutton"><i class="fa fa-trash"></i></button>
                    <button type="button" class="btn btn-secondary" data-dismiss="modal"><i class="fa fa-ban"></i></button>
                </div>
            </div>
        </div>
    </div>

    <div class="modal fade" tabindex="-1" role="dialog" aria-labelledby="exampleModalLabel" aria-hidden="true" id="deletemodal">
        <div class="modal-dialog" role="document" >
            <div class="modal-content" style="padding:0px">
                <div class="modal-header-warning">
                    <h5 class="modal-title" id="exampleModalLabel">{$ADDONLANG.dnssuitePage_manage_js_deleteconfirm}</h5>
                </div>
                <div class="modal-body" id="validateresp">

                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-secondary" data-dismiss="modal" id="deletebutton"><i class="fa fa-trash"></i></button>
                    <button type="button" class="btn btn-secondary" data-dismiss="modal"><i class="fa fa-ban"></i></button>
                </div>
            </div>
        </div>
    </div>

    <div class="modal fade" tabindex="-1" role="dialog" aria-labelledby="exampleModalLabel" aria-hidden="true" id="deleteuserdnstemplatemodal">
        <div class="modal-dialog" role="document" >
            <div class="modal-content" style="padding:0px">
                <div class="modal-header-warning">
                    <h5 class="modal-title" id="exampleModalLabel">{$ADDONLANG.dnssuitePage_manage_js_deleteusertemplateconfirm}</h5>
                </div>
                <div class="modal-body" id="validateresp">

                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-secondary" data-dismiss="modal" id="deletebutton"><i class="fa fa-trash"></i></button>
                    <button type="button" class="btn btn-secondary" data-dismiss="modal"><i class="fa fa-ban"></i></button>
                </div>
            </div>
        </div>
    </div>

    <div class="modal fade" tabindex="-1" role="dialog" aria-labelledby="exampleModalLabel" aria-hidden="true" id="restorednstemplatemodal">
        <div class="modal-dialog" role="document" >
            <div class="modal-content" style="padding:0px">
                <div class="modal-header-warning">
                    <h5 class="modal-title" id="exampleModalLabel">{$ADDONLANG.dnssuitePage_manage_js_restorednstemplateconfirm}</h5>
                </div>
                <div class="modal-body" id="validateresp">

                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-secondary" data-dismiss="modal" id="deletebutton"><i class="fa fa-check"></i></button>
                    <button type="button" class="btn btn-secondary" data-dismiss="modal"><i class="fa fa-ban"></i></button>
                </div>
            </div>
        </div>
    </div>

    <div class="modal fade" tabindex="-1" role="dialog" aria-labelledby="exampleModalLabel" aria-hidden="true" id="resetmodal">
        <div class="modal-dialog" role="document" >
            <div class="modal-content" style="padding:0px">
                <div class="modal-header-warning">
                    <h5 class="modal-title" id="exampleModalLabel">{$ADDONLANG.dnssuitePage_manage_js_resetconfirm}</h5>
                </div>
                <div class="modal-body" id="validateresp">

                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-secondary" data-dismiss="modal" id="deletebutton"><i class="fa fa-check"></i></button>
                    <button type="button" class="btn btn-secondary" data-dismiss="modal"><i class="fa fa-ban"></i></button>
                </div>
            </div>
        </div>
    </div>

    <div class="modal-loading" id="modal-loading"><!-- Place at bottom of page --></div>
    <div class="row">
        <div class="col-sm-12">
            <div class="col-xs-12">
                <!-- Tab panes -->
                <div class="tab-content">
                    <div class="tab-pane active" id="home-v">
                        {if $switchns == true || $resetdomain == true || $createuserdnstemplate == true || $deleteuserdnstemplate == true || $restorednstemplate == true || $updatenotification == true || $cleardns == true }
                            <div class="alert alert-success">
                                {$noticemsg}
                            </div>
                        {/if}
                        {if $switchnsfailed == true || $resetdomainfailed || $createuserdnstemplatefailed == true || $deleteuserdnstemplatefailed == true || $restorednstemplatefailed == true ||$updatenotificationfailed == true || $cleardnsfailed == true }
                            <div class="alert alert-danger">
                                {$noticemsg}
                            </div>
                        {/if}
                        {if $apistatus == true}
                            <div class="alert alert-success">
                                {$noticemsg}
                            </div>
                        {/if}
                        <div class="row">
                            <div class="col-sm-12">
                                <div class="panel panel-primary panel-table">
                                    <div class="panel-heading">
                                        <div class="row">
                                            <div class="col col-xs-12">
                                                <h3 class="panel-title">{$ADDONLANG.dnssuitePage_manage_domainstatus} ({$domain}) 
                                                    {if $clientletsencrypt == "on" && $nsfail != true}
                                                        <button type="submit" class="btn btn-primary btn-m clientLETSENCRYPTbtn" id="requestSSL-tip" title="{$ADDONLANG.dnssuitePage_manage_overview_requestssl_tooltip}"><i class="fa fa-lock"></i> {$ADDONLANG.dnssuitePage_manage_overview_requestssl}</button>
                                                    {/if}</h3>
                                            </div>
                                        </div>
                                    </div>
                                </div>

                                <div class="panel-body">
                                    <div class="row">
                                        <div class="col-sm-12">
                                            {if $nsfail == true}
                                                <div class="alert alert-danger">
                                                    <p>{$ADDONLANG.dnssuitePage_manage_overview_nsfailed_explain}</p>
                                                    <p>{$ADDONLANG.dnssuitePage_manage_overview_nsfailed_explain2}</p>
                                                    <p><form method="post" action="{$modulelink}&action=manage">
                                                        <input type="hidden" name="domainid" value="{$domainid}"/>
                                                        <input type="hidden" name="switchns" value="yes"/>
                                                        <button type="submit" id="switchNSbtn" class="btn btn-success btn-sm" title="{$ADDONLANG.dnssuitePage_manage_overview_switchns_tooltip}"><i class="fa fa-pencil-square-o"></i> {$ADDONLANG.dnssuitePage_manage_overview_switchns}</button>
                                                    </form></p>
                                                </div>
                                            {/if}

                                            {if ($disablemanage == "on" && $nsfail != true) || $disablemanage != "on" }
                                                <div class="alert alert-warning">
                                                    <p>{$ADDONLANG.dnssuitePage_manage_overview_resetdomain_explain}</p>
                                                    <p><form method="post" action="{$modulelink}&action=manage">
                                                        <input type="hidden" name="domainid" value="{$domainid}"/>
                                                        <input type="hidden" name="resetdomain" value="yes"/>
                                                        <button type="submit" id="resetDOMAINbtn" class="btn btn-danger btn-sm" onClick="event.preventDefault(); resetConfirm(this.form)" title="{$ADDONLANG.dnssuitePage_manage_overview_resetdomain_tooltip}"><i class="fa fa-eraser"></i> {$ADDONLANG.dnssuitePage_manage_overview_resetdomain}</button>
                                                    </form></p>
                                                    <p>{$ADDONLANG.dnssuitePage_manage_overview_cleardns_explain}</p>
                                                    <p><form method="post" action="{$modulelink}&action=manage">
                                                        <input type="hidden" name="domainid" value="{$domainid}"/>
                                                        <input type="hidden" name="cleardns" value="yes"/>
                                                        <button type="submit" id="clearDNSbtn" class="btn btn-danger btn-sm" onClick="event.preventDefault(); resetConfirm(this.form)" title="{$ADDONLANG.dnssuitePage_manage_overview_cleardns_tooltip}"><i class="fa fa-eraser"></i> {$ADDONLANG.dnssuitePage_manage_overview_cleardns}</button>
                                                    </form></p>
                                                </div>
                                            {/if}
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>

                        {if ($disablemanage == "on" && $nsfail != true) || $disablemanage != "on" }
                            {if $configs.enablednstemplate == "on" && $edition == "professional"}
                                <div class="row">
                                    <div class="col-sm-12">
                                        <div class="panel panel-primary panel-table">
                                            <div class="panel-heading">
                                                <div class="row">
                                                    <div class="col col-xs-12">
                                                        <h3 class="panel-title">{$ADDONLANG.dnssuitePage_manage_dnstemplate}</h3>
                                                    </div>
                                                </div>
                                            </div>
                                        </div>
                                        <div class="panel-body">
                                            <div class="row">
                                                <div class="col-sm-12">
                                                    <div class="alert alert-info">
                                                        <p>{$ADDONLANG.dnssuitePage_manage_dnstemplate_explain}</p>
                                                        <p><form method="post" action="{$modulelink}&action=manage">
                                                            {literal}
                                                            <script type="text/javascript">
                                                                $(document).ready(function() {
                                                                    $("#dnstemplate").select2({
                                                                        placeholder: "{/literal}{$ADDONLANG.dnssuitePage_manage_loadtemplateplaceholder}{literal}",
                                                                        allowClear: true,
                                                                        data:[{/literal}{$dnstemplatearray}{literal}],
                                                                    });
                                                                    $("#dnstemplate").select2("val","");
                                                                });
                                                            </script>
                                                            {/literal}
                                                            <select name="dnstemplate" id="dnstemplate" style="width:75%;line-height:40px">
                                                                <!-- Dropdown List Option -->
                                                            </select>
                                                            <input type="hidden" name="domainid" value="{$domainid}"/>
                                                            <input type="hidden" name="restorednstemplate" value="yes"/>
                                                            <button type="submit" class="btn btn-success btn-sm" onClick="event.preventDefault(); restoreDNSTemplateConfirm(this.form)" id="restoreDNSTEMPLATEbtn" title="{$ADDONLANG.dnssuitePage_manage_overview_restorednstemplate_tooltip}"><i class="fa fa-upload"></i> {$ADDONLANG.dnssuitePage_manage_loadtemplate}</button>
                                                            <p><input type="checkbox" name="preserve" value="yes"> {$ADDONLANG.dnssuitePage_manage_savetemplate_preservedns}</p>
                                                        </form></p>
                                                    </div>
                                                </div>
                                                {if $configs.enableuserdnstemplate == "on"}
                                                    <div class="col-sm-12">
                                                        <div class="alert alert-info">
                                                            <p>{$ADDONLANG.dnssuitePage_manage_creatednstemplate_explain}</p>
                                                            <p><form method="post" action="{$modulelink}&action=manage">
                                                                <input type="text" name="name" placeholder="{$ADDONLANG.dnssuitePage_manage_dnstemplatename}">
                                                                <input type="hidden" name="domainid" value="{$domainid}"/>
                                                                <input type="hidden" name="createuserdnstemplate" value="yes"/>
                                                                <button type="submit" class="btn btn-success btn-sm" onClick="event.preventDefault(); saveTemplate(this.form)" id="createUSERDNSTEMPLATEbtn" title="{$ADDONLANG.dnssuitePage_manage_overview_createuserdnstemplate_tooltip}"><i class="fa fa-pencil"></i> {$ADDONLANG.dnssuitePage_manage_savetemplate}</button>
                                                            </form></p>
                                                            <p style="color: red;font-style: italic">{$ADDONLANG.dnssuitePage_manage_savetemplate_explain}</p>
                                                            <p><form method="post" action="{$modulelink}&action=manage">
                                                                {literal}
                                                                <script type="text/javascript">
                                                                    $(document).ready(function() {
                                                                        $("#userdnstemplates").select2({
                                                                            placeholder: "{/literal}{$ADDONLANG.dnssuitePage_manage_loadtemplateplaceholder}{literal}",
                                                                            allowClear: true,
                                                                            data:[{/literal}{$userdnstemplatearray}{literal}],
                                                                        });
                                                                        $("#userdnstemplates").select2("val","");
                                                                    });
                                                                </script>
                                                                {/literal}
                                                                <select name="userdnstemplates" id="userdnstemplates" style="width:75%;line-height:40px">
                                                                    <!-- Dropdown List Option -->
                                                                </select>
                                                                <input type="hidden" name="deleteuserdnstemplate" value="yes"/>
                                                                <input type="hidden" name="domainid" value="{$domainid}"/>
                                                                <button type="submit" class="btn btn-danger btn-sm" onClick="event.preventDefault(); deleteUserDNSTemplateConfirm(this.form)"><i class="fa fa-trash"></i> {$ADDONLANG.dnssuitePage_manage_deletetemplate}</button>
                                                            </form></p>
                                                        </div>
                                                    </div>
                                                {/if}
                                            </div>
                                        </div>

                                    </div>
                                </div>
                            {/if}

                            {if $configs.enabledyndns == "on" && $edition == "professional"}
                                <div class="row">
                                    <div class="col-sm-12">
                                        <div class="panel panel-primary panel-table">
                                            <div class="panel-heading">
                                                <div class="row">
                                                    <div class="col col-xs-12">
                                                        <h3 class="panel-title">{$ADDONLANG.dnssuitePage_manage_dynamicdns} API </h3>
                                                    </div>
                                                </div>
                                            </div>
                                        </div>
                                        <div class="panel-body">
                                            <table class="table table-striped table-bordered table-list">
                                                <tbody>
                                                <tr>
                                                    <td>{$ADDONLANG.dnssuitePage_manage_api_url}</td>
                                                    <td><input type="text" value="{$systemurl}{$modulelink}&action=ddns&keyphrase={$configs.keyphrase}&pass={$configs.pass}" size="50"></td>
                                                </tr>
                                                <tr>
                                                    <td>{$ADDONLANG.dnssuitePage_manage_api_keyphrase}</td>
                                                    <td><input type="text" id="APIkeyphrase" value="{$configs.keyphrase}" size="50"></td>
                                                </tr>
                                                <tr>
                                                    <td>{$ADDONLANG.dnssuitePage_manage_api_pass}</td>
                                                    <td><input type="text" id="APIpass" value="{$configs.pass}" size="50"></td>
                                                </tr>
                                                </tbody>
                                            </table>
                                            <div class="panel-body">
                                                <div class="col-sm-8">
                                                    <div class="col-sm-4">
                                                        <button type="submit" class="btn btn-success btn-sm refreshAPIbtn" ><i class="fa fa-retweet"></i> {$ADDONLANG.dnssuitePage_manage_api_refresh}</button>
                                                    </div>
                                                    <div class="col-sm-4">
                                                        {if $configs.apistatus == 1}
                                                            <button type="submit" class="btn btn-danger btn-sm disableAPIbtn" id="APIbtn"><i class="fa fa-power-off"></i> {$ADDONLANG.dnssuitePage_manage_api_disable}</button>
                                                        {else}
                                                            <button type="submit" class="btn btn-success btn-sm enableAPIbtn" id="APIbtn" title="{$ADDONLANG.dnssuitePage_manage_overview_enableapi_tooltip}"><i class="fa fa-power-off"></i> {$ADDONLANG.dnssuitePage_manage_api_enable}</button>
                                                        {/if}
                                                    </div>
                                                </div>
                                            </div>
                                            <div class="panel-body">
                                                <table class="table table-striped table-bordered table-list">
                                                    <thead>
                                                    <tr>
                                                        <th>{$ADDONLANG.dnssuitePage_manage_api_option}</th>
                                                        <th>{$ADDONLANG.dnssuitePage_manage_api_explanation}</th>
                                                    </tr>
                                                    </thead>
                                                    <tbody>
                                                    <tr>
                                                        <td>&host</td>
                                                        <td><p>{$ADDONLANG.dnssuitePage_manage_api_host_explain}</p>
                                                            <p>{$ADDONLANG.dnssuitePage_manage_api_example}: {$systemurl}{$modulelink}&action=ddns&keyphrase={$configs.keyphrase}&pass={$configs.pass}&host=ftp</p>
                                                        </td>
                                                    </tr>
                                                    <tr>
                                                        <td>&ip</td>
                                                        <td><p>{$ADDONLANG.dnssuitePage_manage_api_ip_explain}</p>
                                                            <p>{$ADDONLANG.dnssuitePage_manage_api_example}: {$systemurl}{$modulelink}&action=ddns&keyphrase={$configs.keyphrase}&pass={$configs.pass}&host=ftp&ip=1.2.3.4</p>
                                                        </td>
                                                    </tr>
                                                    <tr>
                                                        <td>&ipv6</td>
                                                        <td><p>{$ADDONLANG.dnssuitePage_manage_api_ipv6_explain}</p>
                                                            <p>{$ADDONLANG.dnssuitePage_manage_api_example}: {$systemurl}{$modulelink}&action=ddns&keyphrase={$configs.keyphrase}&pass={$configs.pass}&host=ftp&ip=2001:db8:a0b:12f0::1&ipv6=yes</p>
                                                        </td>
                                                    </tr>
                                                    <tr>
                                                        <td>&delete</td>
                                                        <td><p>{$ADDONLANG.dnssuitePage_manage_api_delete_explain}</p>
                                                            <p>{$ADDONLANG.dnssuitePage_manage_api_example}: {$systemurl}{$modulelink}&action=ddns&keyphrase={$configs.keyphrase}&pass={$configs.pass}&host=ftp&delete=1</p>
                                                        </td>
                                                    </tr>
                                                    </tbody>
                                                </table>
                                            </div>
                                        </div>

                                    </div>
                                </div>
                            {/if}
                        {/if}

                    </div>
                    {if $records_a.modify == "on" && $configs.enablednseditor == "on"}
                        <div class="tab-pane" id="a-v">
                            <div class="panel panel-primary">
                                <div class="panel-heading">
                                    <h3 class="panel-title">{$ADDONLANG.dnssuitePage_manage_a_record} </h3>
                                </div>
                                <div class="panel-body">
                                    <div class="row">
                                        <div class="col-sm-12">
                                            <table class="table table-striped" id="Atable">
                                                <tr>
                                                    <th>{$ADDONLANG.dnssuitePage_manage_host}</th>
                                                    <th>{$ADDONLANG.dnssuitePage_manage_value}</th>
                                                    <th></th>
                                                </tr>
                                                {foreach from=$zonedata.a item=record}
                                                    <tr id="A-{$record.5}">
                                                        <td>{$record.0}</td>
                                                        <td><input type="text" id="A-{$record.5}-value" value="{$record.4}" name="value" size="12"/></td>
                                                        <td>
                                                            <div class="col-sm-4">
                                                                <button type="submit" value="{$record.5}" class="btn btn-success btn-xs modifyAbtn" ><i class="fa fa-save"></i> </button>
                                                            </div>
                                                            <div class="col-sm-4">
                                                                <input type="hidden" id="A-{$record.5}-domainid" value="{$domainid}"/>
                                                                <button type="submit" value="{$record.5}" class="btn btn-danger btn-xs deletebtn" id="A"><i class="fa fa-trash"></i> </button>
                                                            </div>
                                                        </td>
                                                    </tr>
                                                {/foreach}
                                                {if $records_a.limit==0 || $records_a.limit > $recordcount.a}
                                                    <tr>
                                                        <td><input type="text" id="addA-host" placeholder="{$ADDONLANG.dnssuitePage_manage_host}"/></td>
                                                        <td>
                                                            <input type="text" id="addA-value" placeholder="{$ADDONLANG.dnssuitePage_manage_ip}" name="value" size="12"/>
                                                        </td>
                                                        <td>
                                                            <div class="col-sm-4">
                                                                <input type="hidden" id="addA-domainid" value="{$domainid}"/>
                                                                <button type="submit" class="btn btn-success btn-xs addAbtn" ><i class="fa fa-plus"></i> </button>
                                                            </div>
                                                        </td>
                                                    </tr>
                                                {/if}
                                            </table>
                                        </div>
                                        {if $havewebredirect == true}
                                            <div class="panel-body">
                                                <div class="row">
                                                    <div class="col-sm-12">
                                                        <div class="alert alert-danger">
                                                            <p>{$ADDONLANG.dnssuitePage_manage_dns_a_footer_haveredirect}</p>
                                                            <p>{$ADDONLANG.dnssuitePage_manage_dns_a_footer_haveredirect2} {$domaindot}</p>
                                                        </div>
                                                    </div>
                                                </div>
                                            </div>
                                        {/if}
                                        <div class="panel-body">
                                            <div class="row">
                                                <div class="col-sm-12">
                                                    <div class="alert alert-info">
                                                        <p>{$ADDONLANG.dnssuitePage_manage_dns_a_footer}</p>
                                                        <p>{$ADDONLANG.dnssuitePage_manage_dns_a_footer2}</p>
                                                    </div>
                                                </div>
                                            </div>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>
                    {/if}

            {if $records_aaaa.modify == "on" && $configs.enablednseditor == "on"}
            <div class="tab-pane" id="aaaa-v">
                <div class="panel panel-primary">
                    <div class="panel-heading">
                        <h3 class="panel-title">{$ADDONLANG.dnssuitePage_manage_aaaa_record} </h3>
                    </div>
                    <div class="panel-body">
                        <div class="row">
                            <div class="col-sm-12">
                                <table class="table table-striped" id="AAAAtable">
                                    <tr>
                                        <th>{$ADDONLANG.dnssuitePage_manage_host}</th>
                                        <th>{$ADDONLANG.dnssuitePage_manage_value}</th>
                                        <th></th>
                                    </tr>

                                    {foreach from=$zonedata.aaaa item=record}
                                        <tr>
                                            <td>{$record.0}</td>
                                            <td><input type="text" id="AAAA-{$record.5}-value" value="{$record.4}" size="12"/></td>
                                            <td>
                                                <div class="col-sm-4">
                                                    <button type="submit" value="{$record.5}" class="btn btn-success btn-xs modifyAAAAbtn" ><i class="fa fa-save"></i> </button>
                                                </div>
                                                <div class="col-sm-4">
                                                        <input type="hidden" id="AAAA-{$record.5}-domainid" name="domainid" value="{$domainid}"/>
                                                        <button type="submit" value="{$record.5}" class="btn btn-danger btn-xs deletebtn" id="AAAA"><i class="fa fa-trash"></i> </button>
                                                </div>
                                            </td>
                                        </tr>
                                    {/foreach}
                                    {if $records_aaaa.limit==0 || $records_aaaa.limit > $recordcount.aaaa}
                                        <tr>
                                            <td><input type="text" id="addAAAA-host" placeholder="{$ADDONLANG.dnssuitePage_manage_host}"/></td>
                                            <td><input type="text" id="addAAAA-value" placeholder="{$ADDONLANG.dnssuitePage_manage_ip}" name="value" size="12"/></td>
                                            <td>
                                                <div class="col-sm-4">
                                                    <input type="hidden" id="addAAAA-domainid" name="domainid" value="{$domainid}"/>
                                                    <button type="submit" class="btn btn-success btn-xs addAAAAbtn"><i class="fa fa-plus"></i> </button>
                                                </div>
                                            </td>
                                        </tr>
                                    {/if}
                                </table>
                            </div>
                            <div class="panel-body">
                                <div class="row">
                                    <div class="col-sm-12">
                                        <div class="alert alert-info">
                                            <p>{$ADDONLANG.dnssuitePage_manage_dns_a_footer}</p>
                                            <p>{$ADDONLANG.dnssuitePage_manage_dns_a_footer2}</p>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        {/if}

    {if $records_ns.modify == "on" && $configs.enablednseditor == "on"}
        <div class="tab-pane" id="ns-v">
            <div class="panel panel-primary">
                <div class="panel-heading">
                    <h3 class="panel-title">{$ADDONLANG.dnssuitePage_manage_ns_record} </h3>
                </div>
                <div class="panel-body">
                    <div class="row">
                        <div class="col-sm-12">
                            <table class="table table-striped" id="NStable">
                                <tr>
                                    <th>{$ADDONLANG.dnssuitePage_manage_host}</th>
                                    <th>{$ADDONLANG.dnssuitePage_manage_value}</th>
                                    <th></th>
                                </tr>
                                {foreach from=$zonedata.ns item=record}
                                    {if $record.0 != $domaindot}
                                        <tr>
                                            <td>{$record.0}</td>
                                            <td><input type="text" id="NS-{$record.5}-value" value="{$record.4}" size="20"/></td>
                                            <td>
                                                <div class="col-sm-4">
                                                    <button type="submit" value="{$record.5}" class="btn btn-success btn-xs modifyNSbtn" ><i class="fa fa-save"></i> </button>
                                                </div>
                                                <div class="col-sm-4">
                                                    <input type="hidden" id="NS-{$record.5}-domainid"/>
                                                    <button type="submit" value="{$record.5}" class="btn btn-danger btn-xs deletebtn" id="NS"><i class="fa fa-trash"></i> </button>
                                                </div>
                                            </td>
                                        </tr>
                                    {else}
                                        <tr>
                                            <td>{$record.0}</td>
                                            <td>{$record.4}</td>
                                            <td>&nbsp;</td>
                                        </tr>
                                    {/if}
                                {/foreach}
                                {if $records_ns.limit==0 || $records_ns.limit > $recordcount.ns}
                                    <tr>
                                        <td><input type="text" id="addNS-host" placeholder="{$ADDONLANG.dnssuitePage_manage_host}"/></td>
                                        <td><input type="text" id="addNS-value" placeholder="{$ADDONLANG.dnssuitePage_manage_destinationhost}" name="value" size="20"/></td>
                                        <td>
                                            <div class="col-sm-4">
                                                <input type="hidden" id="addNS-domainid" value="{$domainid}"/>
                                                <button type="submit" class="btn btn-success btn-xs addNSbtn"><i class="fa fa-plus"></i> </button>
                                            </div>
                                        </td>
                                    </tr>
                                {/if}
                            </table>
                        </div>
                        <div class="panel-body">
                            <div class="row">
                                <div class="col-sm-12">
                                    <div class="alert alert-info">
                                        <p>{$ADDONLANG.dnssuitePage_manage_dns_ns_footer}</p>
                                        <p>{$ADDONLANG.dnssuitePage_manage_dns_ns_footer2}</p>
                                        <p>{$ADDONLANG.dnssuitePage_manage_dns_ns_footer3}</p>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    {/if}
    {if $records_cname.modify == "on" && $configs.enablednseditor == "on"}
        <div class="tab-pane" id="cname-v">
            <div class="panel panel-primary">
                <div class="panel-heading">
                    <h3 class="panel-title">{$ADDONLANG.dnssuitePage_manage_cname_record} </h3>
                </div>
                <div class="panel-body">
                    <div class="row">
                        <div class="col-sm-12">
                            <table class="table table-striped" id="CNAMEtable">
                                <tr>
                                    <th>{$ADDONLANG.dnssuitePage_manage_host}</th>
                                    <th>{$ADDONLANG.dnssuitePage_manage_value}</th>
                                    <th></th>
                                </tr>
                                {foreach from=$zonedata.cname item=record}
                                    <tr>
                                        <td>{$record.0}</td>
                                        <td><input type="text" id="CNAME-{$record.5}-value" value="{$record.4}" name="value" size="30"/></td>
                                        <td>
                                            <div class="col-sm-4">
                                                <button type="submit" value="{$record.5}" class="btn btn-success btn-xs modifyCNAMEbtn"><i class="fa fa-save"></i> </button>
                                            </div>
                                            <div class="col-sm-4">
                                                <input type="hidden" id="CNAME-{$record.5}-domainid" value="{$domainid}"/>
                                                <button type="submit" value="{$record.5}" class="btn btn-danger btn-xs deletebtn" id="CNAME"><i class="fa fa-trash"></i> </button>
                                            </div>
                                        </td>
                                    </tr>
                                {/foreach}
                                {if $records_cname.limit==0 || $records_cname.limit > $recordcount.cname}
                                    <tr>
                                        <td><input type="text" id="addCNAME-host" placeholder="{$ADDONLANG.dnssuitePage_manage_host}"/></td>
                                        <td><input type="text" id="addCNAME-value" placeholder="{$ADDONLANG.dnssuitePage_manage_destinationhost}" size="30"/></td>
                                        <td>
                                            <div class="col-sm-4">
                                                <input type="hidden" id="addCNAME-domainid" value="{$domainid}"/>
                                                <button type="submit" class="btn btn-success btn-xs addCNAMEbtn" ><i class="fa fa-plus"></i> </button>
                                            </div>
                                        </td>
                                    </tr>
                                {/if}
                            </table>
                        </div>
                        <div class="panel-body">
                            <div class="row">
                                <div class="col-sm-12">
                                    <div class="alert alert-info">
                                        <p>{$ADDONLANG.dnssuitePage_manage_dns_cname_footer}</p>
                                        <p>{$ADDONLANG.dnssuitePage_manage_dns_cname_footer2}</p>
                                        <p>{$ADDONLANG.dnssuitePage_manage_dns_cname_footer3}</p>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    {/if}
    {if $records_txt.modify == "on" && $configs.enablednseditor == "on"}
        <div class="tab-pane" id="txt-v">
            <div class="panel panel-primary">
                <div class="panel-heading">
                    <h3 class="panel-title">{$ADDONLANG.dnssuitePage_manage_txt_record} </h3>
                </div>
                <div class="panel-body">
                    <div class="row">
                        <div class="col-sm-12">
                            <table id="TXTtable" class="table table-striped">
                                <tr>
                                    <th>{$ADDONLANG.dnssuitePage_manage_host}</th>
                                    <th>{$ADDONLANG.dnssuitePage_manage_value}</th>
                                    <th></th>
                                </tr>
                                {foreach from=$zonedata.txt item=record}
                                    <tr>
                                        <td>{$record.0}</td>
                                        <td><input type="text" id="TXT-{$record.5}-value" value="{$record.4}" size="30"/></td>
                                        <td>
                                            <div class="col-sm-4">
                                                <button type="submit" value="{$record.5}" class="btn btn-success btn-xs modifyTXTbtn" ><i class="fa fa-save"></i> </button>
                                            </div>
                                            <div class="col-sm-4">
                                                <input type="hidden" id="TXT-{$record.5}-domainid" value="{$domainid}"/>
                                                <button type="submit" value="{$record.5}" class="btn btn-danger btn-xs deletebtn" id="TXT"><i class="fa fa-trash"></i> </button>
                                            </div>
                                        </td>
                                    </tr>
                                {/foreach}
                                {if $records_txt.limit==0 || $records_txt.limit > $recordcount.txt}
                                    <tr>
                                        <td><input type="text" id="addTXT-host" placeholder="{$ADDONLANG.dnssuitePage_manage_host}"/></td>
                                        <td><input type="text" id="addTXT-value" placeholder="{$ADDONLANG.dnssuitePage_manage_txtvalue}" size="30"/></td>
                                        <td>
                                            <div class="col-sm-4">
                                                <input type="hidden" id="addTXT-domainid" value="{$domainid}"/>
                                                <button type="submit" class="btn btn-success btn-xs addTXTbtn" ><i class="fa fa-plus"></i> </button>
                                            </div>
                                        </td>
                                    </tr>
                                {/if}
                            </table>
                        </div>
                        <div class="panel-body">
                            <div class="row">
                                <div class="col-sm-12">
                                    <div class="alert alert-info">
                                        <p>{$ADDONLANG.dnssuitePage_manage_dns_txt_footer}</p>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    {/if}
    {if $records_mx.modify == "on" && $configs.enablednseditor == "on"}
        <div class="tab-pane" id="mx-v">
            <div class="panel panel-primary">
                <div class="panel-heading">
                    <h3 class="panel-title">{$ADDONLANG.dnssuitePage_manage_mx_record} </h3>
                </div>
                <div class="panel-body">
                    <div class="row">
                        <div class="col-sm-12">
                            <table id="MXtable" class="table table-striped">
                                <tr>
                                    <th>{$ADDONLANG.dnssuitePage_manage_host}</th>
                                    <th>{$ADDONLANG.dnssuitePage_manage_priority}</th>
                                    <th>{$ADDONLANG.dnssuitePage_manage_value}</th>
                                    <th></th>
                                </tr>

                                {foreach from=$zonedata.mx item=record}
                                    <tr>
                                        <td>{$record.0}</td>
                                        <td>
                                            <select id="MX-{$record.6}-priority">
                                                <option value="0" {if $record.4 == 0}selected="selected"{/if}>0</option><option value="10" {if $record.4 == 10}selected="selected"{/if}>10</option><option value="20" {if $record.4 == 20}selected="selected"{/if}>20</option><option value="30" {if $record.4 == 30}selected="selected"{/if}>30</option><option value="40" {if $record.4 == 40}selected="selected"{/if}>40</option><option value="50" {if $record.4 == 50}selected="selected"{/if}>50</option><option value="60" {if $record.4 == 60}selected="selected"{/if}>60</option><option value="70" {if $record.4 == 70}selected="selected"{/if}>70</option><option value="80" {if $record.4 == 80}selected="selected"{/if}>80</option><option value="90" {if $record.4 == 90}selected="selected"{/if}>90</option></select>
                                        </td>
                                        <td><input type="text" id="MX-{$record.6}-value" value="{$record.5}" size="20"/></td>
                                        <td>
                                            <div class="col-sm-4">
                                                <button type="submit"  value="{$record.6}" class="btn btn-success btn-xs modifyMXbtn" ><i class="fa fa-save"></i> </button>
                                            </div>
                                            <div class="col-sm-4">
                                                <input type="hidden" name="MX-{$record.6}-domainid" value="{$domainid}"/>
                                                <button type="submit" value="{$record.6}" class="btn btn-danger btn-xs deletebtn" id="MX"><i class="fa fa-trash"></i> </button>
                                            </div>
                                        </td>
                                    </tr>
                                {/foreach}
                                {if $records_mx.limit==0 || $records_mx.limit > $recordcount.mx}
                                    <tr>
                                        <td><input type="text" id="addMX-host" placeholder="{$ADDONLANG.dnssuitePage_manage_host}"/></td>
                                        <td>
                                            <select id="addMX-priority">
                                                <option value="0">0</option><option value="10">10</option><option value="20">20</option><option value="30">30</option><option value="40">40</option><option value="50">50</option><option value="60">60</option><option value="70">70</option><option value="80">80</option><option value="90">90</option>
                                            </select>
                                        </td>
                                        <td><input type="text" id="addMX-value" placeholder="{$ADDONLANG.dnssuitePage_manage_destinationhost}" size="20"/></td>
                                        <td>
                                            <div class="col-sm-4">
                                                <input type="hidden" id="addMX-domainid" value="{$domainid}"/>
                                                <button type="submit" class="btn btn-success btn-xs addMXbtn" ><i class="fa fa-plus"> </i></button>
                                            </div>
                                        </td>
                                    </tr>
                                {/if}
                            </table>
                        </div>
                        {if $haveforwarding == true}
                            <div class="panel-body">
                                <div class="row">
                                    <div class="col-sm-12">
                                        <div class="alert alert-danger">
                                            <p>{$ADDONLANG.dnssuitePage_manage_dns_mx_footer_haveforwarding}</p>
                                            <p>{$ADDONLANG.dnssuitePage_manage_dns_mx_footer_haveforwarding2} {$domaindot}</p>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        {/if}
                        <div class="panel-body">
                            <div class="row">
                                <div class="col-sm-12">
                                    <div class="alert alert-info">
                                        <p>{$ADDONLANG.dnssuitePage_manage_dns_mx_footer}</p>
                                        <p>{$ADDONLANG.dnssuitePage_manage_dns_mx_footer2}</p>
                                        <p>{$ADDONLANG.dnssuitePage_manage_dns_mx_footer3}</p>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    {/if}
    {if $records_srv.modify == "on" && $configs.enablednseditor == "on"}
        <div class="tab-pane" id="srv-v">
            <div class="panel panel-primary">
                <div class="panel-heading">
                    <h3 class="panel-title">{$ADDONLANG.dnssuitePage_manage_srv_record} </h3>
                </div>
                <div class="panel-body">
                    <div class="row">
                        <div class="col-sm-12">
                            <table id="SRVtable" class="table table-striped">
                                <tr>
                                    <th>{$ADDONLANG.dnssuitePage_manage_host}</th>
                                    <th>{$ADDONLANG.dnssuitePage_manage_priority}</th>
                                    <th>{$ADDONLANG.dnssuitePage_manage_weight}</th>
                                    <th>{$ADDONLANG.dnssuitePage_manage_port}</th>
                                    <th>{$ADDONLANG.dnssuitePage_manage_value}</th>
                                    <th></th>
                                </tr>
                                {foreach from=$zonedata.srv item=record}
                                    <tr>
                                        <td>{$record.0}</td>
                                        <td><input type="text" id="SRV-{$record.8}-priority" value="{$record.4}" size="6"/></td>
                                        <td><input type="text" id="SRV-{$record.8}-weight" value="{$record.5}" size="6"/></td>
                                        <td><input type="text" id="SRV-{$record.8}-port" value="{$record.6}" size="6"/></td>
                                        <td><input type="text" id="SRV-{$record.8}-value" value="{$record.7}" size="10"/></td>
                                        <td>
                                            <div class="col-sm-4">
                                                <button type="submit" value="{$record.8}" class="btn btn-success btn-xs modifySRVbtn" ><i class="fa fa-save"></i> </button>
                                            </div>
                                            <div class="col-sm-4">
                                                    <input type="hidden" id="SRV-{$record.8}-domainid" value="{$domainid}"/>
                                                    <button type="submit" value="{$record.8}" class="btn btn-danger btn-xs deletebtn" id="SRV"><i class="fa fa-trash"></i> </button>
                                            </div>
                                        </td>
                                    </tr>
                                {/foreach}
                                {if $records_srv.limit==0 || $records_srv.limit > $recordcount.srv}
                                    <tr>
                                        <td><input type="text" id="addSRV-host" placeholder="{$ADDONLANG.dnssuitePage_manage_host}" size="10"/></td>
                                        <td><input type="text" id="addSRV-priority" placeholder="{$ADDONLANG.dnssuitePage_manage_priority}" size="6"/></td>
                                        <td><input type="text" id="addSRV-weight" placeholder="{$ADDONLANG.dnssuitePage_manage_weight}" size="6"/></td>
                                        <td><input type="text" id="addSRV-port" placeholder="{$ADDONLANG.dnssuitePage_manage_port}" size="6"/></td>
                                        <td><input type="text" id="addSRV-value" placeholder="{$ADDONLANG.dnssuitePage_manage_value}" size="10"/></td>
                                        <td>
                                            <div class="col-sm-4">
                                                <input type="hidden" id="addSRV-domainid" value="{$domainid}"/>
                                                <button type="submit" class="btn btn-success btn-xs addSRVbtn" ><i class="fa fa-plus"> </i></button>
                                            </div>
                                        </td>
                                    </tr>
                                {/if}
                            </table>
                         </div>
                        <div class="panel-body">
                            <div class="row">
                                <div class="col-sm-12">
                                    <div class="alert alert-info">
                                        <p>{$ADDONLANG.dnssuitePage_manage_dns_srv_footer}</p>
                                        <p>{$ADDONLANG.dnssuitePage_manage_dns_srv_footer2}</p>
                                        <p>{$ADDONLANG.dnssuitePage_manage_dns_srv_footer3}</p>
                                        <p>{$ADDONLANG.dnssuitePage_manage_dns_srv_footer4}</p>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    {/if}
    {if $subdomain.enable == "on"}
        <div class="tab-pane" id="subdomain-v">
            <div class="row">
                <div class="col-sm-12">
                    <h2>{$ADDONLANG.dnssuitePage_manage_managesubdomain}</h2>
                </div>

                <div class="col-sm-12">
                    <h3>{$ADDONLANG.dnssuitePage_manage_subdomainintro}</h3>
                </div>
            </div>
            <hr/>
            <div class="row">
                <div class="col-sm-12">
                    <div class="panel panel-primary">
                        <div class="panel-heading">
                            <div class="row">
                                <div class="col col-xs-12">
                                    <h3 class="panel-title">{$ADDONLANG.dnssuitePage_manage_existingsubdomain} {$domain} {if $subdomain.limit != 0}(<span id="SUBDOMAINcount">{$subdomaincount}</span>/{$subdomain.limit}){/if}</h3>
                                </div>
                            </div>
                        </div>

                        <div class="panel-body">
                            <table id="SUBDOMAINtable" class="table table-striped">
                                <thead>
                                <tr>
                                    <th>{$ADDONLANG.dnssuitePage_manage_subdomain_hostname}</th>
                                    <th></th>
                                </tr>
                                </thead>
                                <tbody>
                                {if $subdomainfalse != true}
                                    {foreach from=$subdomainlist item=subdomain}
                                        <tr>
                                            <td>{$subdomain.host}</td>
                                            <td>
                                                <div class="col-sm-4"><a href="{$modulelink}&action=managesubdomain&sdid={$subdomain.id}" target="_blank"><i class="fa fa-sign-in"></i> </a></div>
                                                <div class="col-sm-4"><button type="submit" value="{$subdomain.id}" class="btn btn-danger btn-xs deleteSUBDOMAINbtn"><i class="fa fa-trash"></i> </button></div>
                                            </td>
                                        </tr>
                                    {/foreach}
                                {/if}
                                {if $subdomain.limit > $subdomaincount || $subdomain.limit == 0}
                                    <tr>
                                        <td><input type="text" id="addSUBDOMAIN"/></td>
                                        <td>
                                            <input type="hidden" id="addSUBDOMAIN-domainid" value="{$domainid}">
                                            <div class="col-sm-4"><button type="submit" class="btn btn-primary btn-xs addSUBDOMAINbtn"><i class="fa fa-plus"></i> </button></div>
                                        </td>
                                    </tr>
                                {/if}
                                </tbody>
                            </table>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    {/if}
    {if $urlconfig["enable"] == "on" && $edition != "free"}
        <div class="tab-pane" id="redirect-v">
            <div class="row">
                <div class="col-sm-12">
                    <h2>{$ADDONLANG.dnssuitePage_manage_setredirect} <button type="submit" class="btn btn-primary btn-m redirecttipbtn" id="redirectbtn" title="{$ADDONLANG.dnssuitePage_manage_redirect_tooltip}"><i class="fa fa-lightbulb"></i> </button></h2> 
                </div>

                <div class="col-sm-12">
                    <h3>{$ADDONLANG.dnssuitePage_manage_redirectionintro}</h3>
                </div>
            </div>
            <hr/>
            <div class="row">
                <div class="col-sm-12">
                    <div class="panel panel-primary">
                        <div class="panel-heading">
                            <div class="row">
                                <div class="col col-xs-12">
                                    <h3 class="panel-title">{$ADDONLANG.dnssuitePage_manage_redirectfor} {$domain} (<span id="REDIRECTcount">{$urlredirecttotal}</span>/{$urlconfig["limit"]})</h3>
                                </div>
                            </div>
                        </div>

                        <div class="panel-body">
                            <table id="REDIRECTtable" class="table table-striped">
                                <thead>
                                <tr>
                                    <th>{$ADDONLANG.dnssuitePage_manage_source}</th>
                                    <th>{$ADDONLANG.dnssuitePage_manage_destination}</th>
                                    <th>{$ADDONLANG.dnssuitePage_manage_type}</th>
                                    <th></th>
                                </tr>
                                </thead>
                                <tbody>
                                {foreach from=$redirectdata item=redirect}
                                    <tr>
                                        <td>{$domain}/{if $redirect.domain != "/"}{$redirect.domain}{/if}</td>
                                        <td><input type="text" id="REDIRECT-{$redirect.id}-redirecturl" value="{$redirect.redirect}"/></td>
                                        <td><select id="REDIRECT-{$redirect.id}-type">
                                        {if $redirect.type == 301}
                                            <option value="301" selected="selected">{$ADDONLANG.dnssuitePage_manage_301}</option>
                                            <option value="302">{$ADDONLANG.dnssuitePage_manage_302}</option>
                                            <option value="303">{$ADDONLANG.dnssuitePage_manage_303}</option>
                                            {if $urlconfig["masked"] == "on"}
                                                <option value="999">{$ADDONLANG.dnssuitePage_manage_999}</option>
                                            {/if}
                                        {elseif $redirect.type == 302}
                                            <option value="301">{$ADDONLANG.dnssuitePage_manage_301}</option>
                                            <option value="302" selected="selected">{$ADDONLANG.dnssuitePage_manage_302}</option>
                                            <option value="303">{$ADDONLANG.dnssuitePage_manage_303}</option>
                                            {if $urlconfig["masked"] == "on"}
                                                <option value="999">{$ADDONLANG.dnssuitePage_manage_999}</option>
                                            {/if}
                                        {elseif $redirect.type == 303}
                                            <option value="301">{$ADDONLANG.dnssuitePage_manage_301}</option>
                                            <option value="302">{$ADDONLANG.dnssuitePage_manage_302}</option>
                                            <option value="303" selected="selected">{$ADDONLANG.dnssuitePage_manage_303}</option>
                                            {if $urlconfig["masked"] == "on"}
                                                <option value="999">{$ADDONLANG.dnssuitePage_manage_999}</option>
                                            {/if}
                                        {elseif $redirect.type == 999}
                                            <option value="301">{$ADDONLANG.dnssuitePage_manage_301}</option>
                                            <option value="302">{$ADDONLANG.dnssuitePage_manage_302}</option>
                                            <option value="303">{$ADDONLANG.dnssuitePage_manage_303}</option>
                                            <option value="999" selected="selected">{$ADDONLANG.dnssuitePage_manage_999}</option>
                                        {else}
                                            <option value="301">{$ADDONLANG.dnssuitePage_manage_301}</option>
                                            <option value="302">{$ADDONLANG.dnssuitePage_manage_302}</option>
                                            <option value="303">{$ADDONLANG.dnssuitePage_manage_303}</option>
                                            {if $urlconfig["masked"] == "on"}
                                                <option value="999">{$ADDONLANG.dnssuitePage_manage_999}</option>
                                            {/if}
                                        {/if}
                                        </select></td>
                                        <td>
                                            <div class="col-sm-4"><button type="submit" value="{$redirect.id}" class="btn btn-success btn-xs modifyREDIRECTbtn"><i class="fa fa-save"></i> </button></div>
                                        <input type="hidden" name="REDIRECT-{$redirect.id}-domainid" value="{$domainid}"/>
                                            <div class="col-sm-4"><button type="submit" value="{$redirect.id}" class="btn btn-danger btn-xs deleteREDIRECTbtn"><i class="fa fa-trash"></i> </button></div>
                                        </td>
                                    </tr>
                                {/foreach}
                                {if $urlconfig["limit"] > $urlredirecttotal}
                                    <tr>
                                        <td>{$domain}/<input type="text" id="addREDIRECT-fromurl"/></td>
                                        <td><input type="text" id="addREDIRECT-redirecturl" placeholder="http://"/></td>
                                        <td>
                                            <select id="addREDIRECT-type">
                                                <option value="301">{$ADDONLANG.dnssuitePage_manage_301}</option>
                                                <option value="302">{$ADDONLANG.dnssuitePage_manage_302}</option>
                                                <option value="303">{$ADDONLANG.dnssuitePage_manage_303}</option>
                                                {if $urlconfig["masked"] == "on"}
                                                    <option value="999">{$ADDONLANG.dnssuitePage_manage_999}</option>
                                                {/if}
                                            </select>
                                        </td>
                                        <td>
                                            <input type="hidden" id="addREDIRECT-domainid" value="{$domainid}">
                                            <div class="col-sm-4"><button type="submit" class="btn btn-primary btn-xs addREDIRECTbtn"><i class="fa fa-plus"></i> </button></div>
                                        </td>
                                    </tr>
                                    {if $urlconfig["masked"] == "on"}
                                        <tr id="maskedattr" style="display: none;">
                                            <td colspan="4">
                                            <div class="form-group">
                                                <label>{$ADDONLANG.dnssuitePage_manage_pagetitle}</label>
                                                <input type="text" class="form-control" id="maskedtitle">
                                            </div>
                                            <div class="form-group">
                                                <label>{$ADDONLANG.dnssuitePage_manage_meta}</label>
                                                <input type="text" class="form-control" id="maskedmeta">
                                            </div>
                                            <div class="form-group">
                                                <label>{$ADDONLANG.dnssuitePage_manage_keywords}</label>
                                                <input type="text" class="form-control" id="maskedkeywords">
                                            </div>
                                            </td>
                                        </tr>
                                    {/if}
                                {/if}
                                </tbody>
                            </table>
                        </div>
                    </div>
                    {if $urlconfig["masked"] == "on"}
                        <div class="alert alert-warning">
                            <p>{$ADDONLANG.dnssuitePage_manage_redirectionmaskedexplain}</p>
                        </div>
                    {/if}
                </div>
            </div>
        </div>
    {/if}
    {if $emailconfig["enable"] == "on" && $edition != "free"}
        <div class="tab-pane" id="email-v">
            <div class="row">
                <div class="col-sm-12">
                    <h2>{$ADDONLANG.dnssuitePage_manage_emailforward} <button type="submit" class="btn btn-primary btn-m forwardertipbtn" id="forwarder-tip" title="{$ADDONLANG.dnssuitePage_manage_forwarder_tooltip}"><i class="fa fa-lightbulb"></i> </button></h2>
                </div>
                <div class="col-sm-12">
                    <h3>{$ADDONLANG.dnssuitePage_manage_emailintro}</h3>
                </div>
            </div>
            <hr/>
            <div class="row">
                <div class="col-sm-12">
                    {if $forwardfalse != true}
                    <div class="panel panel-primary panel-table">
                        <div class="panel-heading">
                            <div class="row">
                                <div class="col col-xs-12">
                                    <h3 class="panel-title">{$ADDONLANG.dnssuitePage_manage_existingforwarding} {$domain} (<span id="ALIAScount">{$forwardertotal}</span>/{$emailconfig.limit})</h3>
                                </div>
                            </div>
                        </div>

                        <div class="panel-body">
                            <table class="table table-striped" id="ALIAStable">
                                <thead>
                                <tr>
                                    <th>{$ADDONLANG.dnssuitePage_manage_source}</th>
                                    <th>{$ADDONLANG.dnssuitePage_manage_destination}</th>
                                    <th></th>
                                </tr>
                                </thead>
                                <tbody>
                                    {foreach from=$forwarddata item=forward}
                                    <tr>
                                        <td><p>{$forward.alias}@</p></td>
                                        <td>
                                            <p>
                                            <!--email_off-->
                                                <select class="emails-multiple" id="{$forward.id}-emails" multiple="multiple" style="width:100%">
                                                {$forward.options}
                                                </select>
                                            <!--/email_off-->
                                            </p>
                                        </td>
                                        <td>
                                            <div class="col-xs-6">
                                                <button type="submit" value="{$forward.id}" class="btn btn-success btn-xs modifyALIASbtn" ><i class="fa fa-save"></i> </button>
                                            </div>
                                            <div class="col-xs-6">
                                                <button type="submit" value="{$forward.id}" class="btn btn-danger btn-xs deleteALIASbtn" ><i class="fa fa-trash"></i> </button>
                                            </div>
                                        </td>
                                    </tr>
                                    {/foreach}
                                    {if $emailconfig.limit > $forwardertotal}
                                        <tr>
                                            <td colspan="2">
                                                <input type="text" id="addALIAS-alias" placeholder="{$ADDONLANG.dnssuitePage_manage_newalias}" size="30"/>@{$domain}
                                            </td>
                                            <td>
                                                <div class="col-xs-6">
                                                    <button type="submit" class="btn btn-primary btn-xs addALIASbtn" ><i class="fa fa-plus"></i> </button>
                                                </div>
                                            </td>
                                        </tr>
                                    {/if}
                                </tbody>
                            </table>
                        </div>
                    </div>
                {else}
                    <div class="panel panel-primary panel-table">
                        <div class="panel-heading">
                            <div class="row">
                                <div class="col col-xs-12">
                                    <h3 class="panel-title">{$ADDONLANG.dnssuitePage_manage_existingforwarding} {$domain} (<span id="ALIAScount">{$forwardertotal}</span>/{$emailconfig.limit})</h3>
                                </div>
                            </div>
                        </div>
                        <div class="panel-body">
                            <table class="table table-striped" id="ALIAStable">
                                <thead>
                                <tr>
                                    <th>{$ADDONLANG.dnssuitePage_manage_source}</th>
                                    <th>{$ADDONLANG.dnssuitePage_manage_destination}</th>
                                    <th></th>
                                </tr>
                                </thead>
                                <tbody>
                                    <tr>
                                        <td colspan="2">
                                            <input type="text" id="addALIAS-alias" placeholder="{$ADDONLANG.dnssuitePage_manage_newalias}" size="30"/>@{$domain}
                                        </td>
                                        <td>
                                            <div class="col-xs-6">
                                                <button type="submit" class="btn btn-primary btn-xs addALIASbtn" ><i class="fa fa-plus"></i> </button>
                                            </div>
                                        </td>
                                    </tr>
                                </tbody>
                            </table>
                        </div>
                    </div>

                {/if}

        <div class="panel panel-primary">
            <div class="panel-heading">
                <h3 class="panel-title">{$ADDONLANG.dnssuitePage_manage_emaildestination} {if $emailconfig.slotlimit != 0}(<span id="EMAILSLOTcount">{$slottotal}</span>/{$emailconfig.slotlimit}){/if}</h3>
            </div>
            <div class="panel-body">
                <div class="row">
                    <div class="col-sm-12">
                        <table class="table table-striped" id="FORWARDERtable">
                            <tr>
                                <th>{$ADDONLANG.dnssuitePage_manage_destination}</th>
                                <th>{$ADDONLANG.dnssuitePage_manage_verifypin}</th>
                                <th></th>
                            </tr>
                            {foreach from=$emaildestinationdata.pendingemail item=pendingemail}
                                <tr>
                                    <td>{$pendingemail.email}</td>
                                    <td><input type="text" id="FORWARDER-{$pendingemail.id}-pin"/></td>
                                    <td>
                                        <div class="col-sm-4">
                                            <input type="hidden" name="FORWARDER-{$pendingemail.id}-domainid" value="{$domainid}"/>
                                            <button type="submit" value="{$pendingemail.id}" class="btn btn-primary btn-xs verifyFORWARDERbtn" ><i class="fa fa-check"></i> </button>
                                        </div>
                                        <div class="col-sm-4">
                                            <input type="hidden" name="FORWARDER-{$pendingemail.id}-domainid" value="{$domainid}"/>
                                            <button type="submit" value="{$pendingemail.id}" class="btn btn-danger btn-xs deleteFORWARDERbtn" ><i class="fa fa-trash"></i> </button>
                                        </div>
                                    </td>
                                </tr>
                            {/foreach}
                            {foreach from=$emaildestinationdata.confirmedemail item=confirmedemail}
                                <tr>
                                    <td>{$confirmedemail.email}</td>
                                    <td>&nbsp;</td>
                                    <td>
                                        <div class="col-sm-4">
                                                <button type="submit" value="{$confirmedemail.id}" class="btn btn-danger btn-xs deleteFORWARDERbtn" ><i class="fa fa-trash"></i> </button>
                                        </div>
                                    </td>
                                </tr>
                            {/foreach}
                            {if $slottotal < $emailconfig.slotlimit}
                                <tr>
                                    <td>
                                        <input type="text" id="addFORWARDER-email" placeholder="{$ADDONLANG.dnssuitePage_manage_destinationplaceholder}" size="30"/>
                                    </td>
                                    <td>
                                        <input type="hidden" id="addFORWARDER-domainid" value="{$domainid}"/>
                                    </td>
                                    <td>
                                        <div class="col-sm-4">
                                            <button type="submit" class="btn btn-success btn-xs addFORWARDERbtn" ><i class="fa fa-plus"></i> </form>
                                        </div>
                                    </td>
                                </tr>
                            {/if}
                        </table>
                    </div>
                </div>
            </div>
        </div>
        <div class="alert alert-warning">
            <p>{$ADDONLANG.dnssuitePage_manage_forwarder_footer}</p>
        </div>
        </div>
        </div>
        </div>
    {/if}
    {if $catchallconfig["enable"] == "on" && $edition != "free"}
        <div class="tab-pane" id="catchall-v">
            <div class="row">
                <div class="col-sm-12">
                    <h2>{$ADDONLANG.dnssuitePage_manage_catchall} <button type="submit" class="btn btn-primary btn-m catchalltipbtn" id="catchall-tip" title="{$ADDONLANG.dnssuitePage_manage_catchall_tooltip}"><i class="fa fa-lightbulb"></i> </button></h2>
                </div>

                <div class="col-sm-12">
                    <h3>{$ADDONLANG.dnssuitePage_manage_catchallintro}</h3>
                </div>
            </div>
            <hr/>
            <div class="row">
                <div class="col-sm-12">
                    <div class="panel panel-primary panel-table">
                        <div class="panel-heading">
                            <h3 class="panel-title">{$ADDONLANG.dnssuitePage_manage_existingcatchall} {$domain}</h3>
                        </div>
                        <div class="panel-body">
                            <div class="row">
                                <div class="col-sm-4">
                                    <p id="catchallstatus">{$ADDONLANG.dnssuitePage_manage_catchall_status}:
                                        {if $catchallfalse == true}
                                            <font color="red">{$ADDONLANG.dnssuitePage_manage_catchall_status_off}</font>
                                        {elseif $catchalldata.status == 1 && $catchalldata.mailto != ":fail:"}
                                            <font color="green">{$ADDONLANG.dnssuitePage_manage_catchall_status_on}</font>
                                        {else}
                                            <font color="red">{$ADDONLANG.dnssuitePage_manage_catchall_status_off}</font>
                                        {/if}
                                    </p>
                                    <p>
                                        <span id="catchalldiv">
                                            {if $catchalldata.mailto == "" || $catchalldata.mailto == ":fail:"}
                                                <!--email_off-->
                                                <select class="emails-multiple" id="emails-catchall" multiple="multiple" style="width:100%">
                                                    {$destinationemails}
                                                </select>
                                            <!--/email_off-->
                                            {elseif $catchalldata.mailto != ""}
                                                <!--email_off-->
                                                <select class="emails-multiple" id="emails-catchall" multiple="multiple" style="width:100%">
                                                    {$catchalldata.options}
                                                </select>
                                                <!--/email_off-->
                                            {/if}
                                        </span>
                                    </p>
                                    <h2><button type="submit" class="btn btn-primary btn-xs modifyCATCHALLbtn" ><i class="fa fa-plus"></i> </button></h2>
                                    </p>
                                </div>
                                <div class="col-sm-1">
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
             </div>
        </div>
    {/if}
    {if $configs["enablenotification"] == "on"}
        <div class="tab-pane" id="notification-v">
            <div class="row">
                <div class="col-sm-12">
                    <h2>{$ADDONLANG.dnssuitePage_manage_notification_settings}</h2>
                </div>

                <div class="col-sm-12">
                    <h3>{$ADDONLANG.dnssuitePage_manage_notification_explain}</h3>
                </div>
            </div>
            <hr/>
            <div class="row">
                <div class="col-sm-12">
                    <div class="panel panel-default panel-table">
                        <div class="panel-body">
                            <div class="row">
                                <div class="col-sm-12">
                                    <div class="alert alert-info">
                                        <p>
                                            <p><input type="checkbox" id="notifydns" value="1" {if $notificationconfigs.dns == 1}checked{/if}> {$ADDONLANG.dnssuitePage_manage_notification_dns}</p>
                                            <p><input type="checkbox" id="notifyemailforward" value="1" {if $notificationconfigs.emailforward == 1}checked{/if}> {$ADDONLANG.dnssuitePage_manage_notification_emailforwarding}</p>
                                            <p><input type="checkbox" id="notifyemailcatchall" value="1" {if $notificationconfigs.emailcatchall == 1}checked{/if}> {$ADDONLANG.dnssuitePage_manage_notification_emailcatchall}</p>
                                            <p><input type="checkbox" id="notifywebredirect" value="1" {if $notificationconfigs.webredirect == 1}checked{/if}> {$ADDONLANG.dnssuitePage_manage_notification_webredirect}</p>
                                            <p><input type="checkbox" id="notifyddns" value="1" {if $notificationconfigs.ddns == 1}checked{/if}> {$ADDONLANG.dnssuitePage_manage_notification_ddns}</p>
                                            <button type="submit" class="btn btn-success btn-xs updateNOTIFYbtn"><i class="fa fa-pencil"></i> </button>
                                        </p>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    {/if}
    </div>
    </div>

    <div class="clearfix"></div>
    </div><!-- /col -->
    </div><!-- /row -->
{literal}
    <script>
        $(document).ready(function() {
            $('.emails-multiple').select2();
        });
    </script>

{/literal}
{/if}