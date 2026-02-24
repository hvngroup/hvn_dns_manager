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
        var sdid = '{/literal}{$sdid}{literal}';
        var domaindot = '{/literal}{$domaindot}{literal}';
        var domainname = '{/literal}{$domain}{literal}';
        {/literal}

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

        {if $clientletsencrypt == "on"}
            {literal}
                $(document).on("click", '.clientLETSENCRYPTbtn',function(e){
                    e.preventDefault();
                    $.ajax({
                        type: "POST",
                        url: "modules/addons/dnssuite/include/dnssuite_ajax.php",
                        data: { domainid: domainid, sdid: sdid, action: "requestSSL-sub"},
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

        {if $urlconfig["masked"] == "on"}
            var havemasked = true;
            var wordpagetitle = '{$ADDONLANG.dnssuitePage_manage_pagetitle}';
            var wordmeta = '{$ADDONLANG.dnssuitePage_manage_meta}';
            var wordkeywords = '{$ADDONLANG.dnssuitePage_manage_keywords}';
        {else}
            var havemasked = false;
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
            $(document).ready(function(){
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
                                data: { domainid: domainid, sdid: sdid, fromurl: document.getElementById("addREDIRECT-fromurl").value, redirecturl: document.getElementById("addREDIRECT-redirecturl").value, type: document.getElementById("addREDIRECT-type").value ,action: "addREDIRECT-sub", maskedtitle: document.getElementById("maskedtitle").value.replace(/<\/?[^>]+(>|$)/g, ""), maskedmeta: document.getElementById("maskedmeta").value.replace(/<\/?[^>]+(>|$)/g, ""), maskedkeywords: document.getElementById("maskedkeywords").value.replace(/<\/?[^>]+(>|$)/g, "")},
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
                                data: { domainid: domainid, sdid: sdid, fromurl: document.getElementById("addREDIRECT-fromurl").value, redirecturl: document.getElementById("addREDIRECT-redirecturl").value, type: document.getElementById("addREDIRECT-type").value ,action: "addREDIRECT-sub"},
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
                            data: { domainid: domainid, sdid: sdid, redirectid: row, redirecturl: document.getElementById("REDIRECT-"+row+"-redirecturl").value, type: document.getElementById("REDIRECT-"+row+"-type").value ,action: "modifyREDIRECT-sub"},
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
                            data: { domainid: domainid, sdid: sdid, redirectid: row, action: "deleteREDIRECT-sub"},
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
                            data: { domainid: domainid, sdid: sdid, forwarderid: row, emails: selvals, action: "modifyALIAS-sub"},
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
                        data: { domainid: domainid, sdid: sdid, forwarderid: row, action: "deleteALIAS-sub"},
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
                        data: { domainid: domainid, sdid: sdid, newalias: document.getElementById("addALIAS-alias").value, action: "addALIAS-sub"},
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
                        data: { domainid: domainid, sdid: sdid, newemail: document.getElementById("addFORWARDER-email").value, action: "addEMAIL"},
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
                        data: { domainid: domainid, sdid: sdid, emailid: row, action: "deleteEMAIL"},
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
                        data: { domainid: domainid, sdid: sdid, emailid: row, pin: document.getElementById("FORWARDER-"+row+"-pin").value, action: "verifyEMAIL"},
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
                        data: { domainid: domainid, sdid: sdid, emails: selvals, action: "modifyCATCHALL-sub"},
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
        {literal}

</script>
{/literal}
<hr>

{if $notowned == true}

{else}
    {if $style == "Twentyone"}
        <div class="col-sm-12">
            <div class="col-xs-12"> <!-- required for floating -->
                <!-- Nav tabs -->
                <ul class="nav nav-pills">
                    <li class="nav-item">
                        <a href="#home-v" data-toggle="tab" class="nav-link active">{$ADDONLANG.dnssuitePage_manage_overview}</a>
                    </li>
                    {if ($disablemanage == "on" && $nsfail != true) || $disablemanage != "on" }
                        {if $urlconfig["enable"] == "on" && $edition != "free"}<li class="nav-item"><a href="#redirect-v" data-toggle="tab" class="nav-link">{$ADDONLANG.dnssuitePage_manage_redirect}</a></li>{/if}
                        {if $emailconfig["enable"] == "on" && $edition != "free"}<li class="nav-item"><a href="#email-v" data-toggle="tab" class="nav-link">{$ADDONLANG.dnssuitePage_manage_emailforward}</a></li>{/if}
                        {if $catchallconfig["enable"] == "on" && $edition != "free"}<li class="nav-item"><a href="#catchall-v" data-toggle="tab" class="nav-link">{$ADDONLANG.dnssuitePage_manage_catchall}</a></li>{/if}
                    {/if}
                </ul>
            </div>
        </div>
    {else}
        <div class="col-sm-12">
            <div class="col-xs-12"> <!-- required for floating -->
                <!-- Nav tabs -->
                <ul class="nav nav-pills">
                    <li class="active"><a href="#home-v" data-toggle="tab">{$ADDONLANG.dnssuitePage_manage_overview}</a></li>
                    {if ($disablemanage == "on" && $nsfail != true) || $disablemanage != "on" }
                        {if $urlconfig["enable"] == "on" && $edition != "free"}<li><a href="#redirect-v" data-toggle="tab">{$ADDONLANG.dnssuitePage_manage_redirect}</a></li>{/if}
                        {if $emailconfig["enable"] == "on" && $edition != "free"}<li><a href="#email-v" data-toggle="tab">{$ADDONLANG.dnssuitePage_manage_emailforward}</a></li>{/if}
                        {if $catchallconfig["enable"] == "on" && $edition != "free"}<li><a href="#catchall-v" data-toggle="tab">{$ADDONLANG.dnssuitePage_manage_catchall}</a></li>{/if}
                    {/if}
                </ul>
            </div>
        </div>
    {/if}
    <!-- Modal -->
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
                        {if $resetdomain == true }
                            <div class="alert alert-success">
                                {$ADDONLANG.dnssuitePage_manage_subdomain_reset_success}
                            </div>
                        {/if}
                        {if $resetdomainfailed }
                            <div class="alert alert-danger">
                                {$ADDONLANG.dnssuitePage_manage_subdomain_reset_failed}
                            </div>
                        {/if}

                        <div class="row">
                            <div class="col-sm-12">
                                <div class="panel panel-primary panel-table">
                                    <div class="panel-heading">
                                        <div class="row">
                                            <div class="col col-xs-12">
                                                <h3 class="panel-title">{$ADDONLANG.dnssuitePage_manage_domainstatus} ({$subdomain})
                                                {if $clientletsencrypt == "on" && $nsfail != true}
                                                    <button type="submit" class="btn btn-primary btn-m clientLETSENCRYPTbtn" id="requestSSL-tip" title="{$ADDONLANG.dnssuitePage_manage_overview_requestssl_tooltip}"><i class="fa fa-lock"></i> {$ADDONLANG.dnssuitePage_manage_overview_requestssl}</button>
                                                {/if}</h3>
                                                </h3>
                                            </div>
                                        </div>
                                    </div>
                                </div>

                                {if ($disablemanage == "on" && $nsfail != true) || $disablemanage != "on" }
                                    <div class="panel-body">
                                        <div class="row">
                                            <div class="col-sm-12">
                                                <div class="alert alert-warning">
                                                    <p>{$ADDONLANG.dnssuitePage_manage_overview_resetdomain_explain}</p>
                                                    <p><form method="post" action="{$modulelink}&action=managesubdomain&sdid={$sdid}">
                                                        <input type="hidden" name="resetdomain" value="yes"/>
                                                        <button type="submit" id="resetDOMAINbtn" class="btn btn-danger btn-sm" onClick="event.preventDefault(); resetConfirm(this.form)"><i class="fa fa-eraser"></i> {$ADDONLANG.dnssuitePage_manage_overview_resetdomain}</button>
                                                    </form></p>
                                                </div>
                                            </div>
                                        </div>
                                    </div>
                                {/if}
                            </div>
                        </div>
                    </div>

                    {if $urlconfig["enable"] == "on" && $edition != "free"}
                        <div class="tab-pane" id="redirect-v">
                            <div class="row">
                                <div class="col-sm-12">
                                    <h2>{$ADDONLANG.dnssuitePage_manage_setredirect} <button type="submit" class="btn btn-primary btn-m redirecttipbtn" id="redirect-tip" title="{$ADDONLANG.dnssuitePage_manage_redirect_tooltip}"><i class="fa fa-lightbulb"></i> </button></h2>
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
                                                    <h3 class="panel-title">{$ADDONLANG.dnssuitePage_manage_redirectfor} {$subdomain} (<span id="REDIRECTcount">{$urlredirecttotal}</span>/{$urlconfig["limit"]})</h3>
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
                                                        <td>{$subdomain}/{if $redirect.domain != "/"}{$redirect.domain}{/if}</td>
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
                                                        <td>{$subdomain}/<input type="text" id="addREDIRECT-fromurl"/></td>
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