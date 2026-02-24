<div class="alert alert-info">
    <h3>{$ADDONLANG.dnssuitePage_index_intro}</h3>
</div>

<hr>

{if $havelist == true}

<div class="row">
	<div class="col-sm-12">
        <link href="modules/addons/dnssuite/templates/css/select2.custom.css" rel="stylesheet" />
        <link href="https://cdnjs.cloudflare.com/ajax/libs/select2/4.0.1/css/select2.min.css" rel="stylesheet" />
        <script src="https://cdnjs.cloudflare.com/ajax/libs/select2/4.0.1/js/select2.min.js"></script>

        <center>
    	<form method="POST" action="{$modulelink}&action=manage">
            {literal}
                <script type="text/javascript">
                $(document).ready(function() {
                	$("#domains").select2({
                        placeholder: "{/literal}{$ADDONLANG.dnssuitePage_index_searchplaceholder}{literal}",
                        allowClear: true,
                        data:[{/literal}{$dataarray}{literal}],
                	});
                    $("#domains").select2("val","");
                 });
                </script>
            {/literal}
            <select name="domainid" id="domains" style="width:75%;line-height:40px">
        		<!-- Dropdown List Option -->
        	</select>

        </center>
	</div>
</div>

<div class="row" style="padding-top:30px">
	<div class="col-sm-12">
        <center>
		<button type="submit" id="btnCompleteOrder" onclick="" class="btn btn-primary btn-lg" ><i class="fa fa-gear"></i> {$ADDONLANG.dnssuitePage_index_edit}
        </form>
        </center>
	</div>
</div>

<div class="row">
	<div class="col-sm-6">

	</div>
    <div class="col-sm-6">

	</div>
</div>

{else}
<div class="row">
	<div class="col-sm-12">
		{$ADDONLANG.dnssuitePage_index_nodomain}
	</div>
</div>

{/if}
