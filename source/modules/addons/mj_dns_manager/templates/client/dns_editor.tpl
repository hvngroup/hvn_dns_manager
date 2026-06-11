    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css">

    {* ── Smarty variables → JS config ── *}
    <script>
        var MJDNS_CONFIG = {ldelim}
            domainId:   {$domain.id|intval},
            domainName: '{$domain.domain|escape:'javascript'}',
            csrfToken:  '{$csrf_token|escape:'javascript'}',
            records:    {$recordsJson nofilter},
            redirects:  {$redirectsJson|default:'[]' nofilter},
            emails:     {$emailsJson|default:'[]' nofilter},
            ddnsTokens: {$ddnsJson|default:'[]' nofilter},
            templates:  {$templates|@json_encode nofilter}
        {rdelim};
    </script>

    {* JS logic moved to assets/js/mj-dns.js (MJ standard §8) *}

    {* ══════════════════════════ HTML ══════════════════════════ *}

    <div class="mj-dns mj-dns-client" x-data="dnsEditor()">

        <a href="index.php?m=mj_dns_manager" class="cl-back-link">
            <i class="bi bi-arrow-left"></i> Quay lại danh sách domain
        </a>

        {* ── Domain Info Card ── *}
        <div class="cl-domain-card">
            <div class="cl-domain-name">
                <i class="bi bi-globe2"></i>
                {$domain.domain|escape:'htmlall'}
            </div>
            <div style="display:flex;align-items:center;justify-content:space-between;gap:16px;flex-wrap:wrap;">
                <div style="flex:1;min-width:200px;">
                    {assign var="safe_max" value=$quota.max_records|default:1}
                    {math assign="percent" equation="round((c/m)*100)" c=$domain.records_count m=$safe_max}
                    <div class="cl-quota-row">
                        <span class="cl-quota-label">Bản ghi đang dùng</span>
                        <span class="cl-quota-value" x-text="records.length + ' / {$quota.max_records}'"></span>
                    </div>
                    <div class="cl-progress">
                        <div class="cl-progress-bar {if $percent > 90}cl-progress-danger{elseif $percent > 75}cl-progress-warning{/if}"
                            style="width:{$percent}%" role="progressbar"></div>
                    </div>
                </div>
                <div style="display:flex;gap:8px;flex-shrink:0;">
                    <span class="cl-chip {if $domain.dnssec_enabled}cl-chip-active{else}cl-chip-off{/if}">
                        <i class="bi bi-shield-lock"></i> DNSSEC: {if $domain.dnssec_enabled}Bật{else}Tắt{/if}
                    </span>
                    <span class="cl-chip {if $domain.ssl_status == 'active'}cl-chip-active{elseif $domain.ssl_status == 'pending'}cl-chip-pending{else}cl-chip-off{/if}">
                        <i class="bi bi-lock"></i> SSL: {$domain.ssl_status|capitalize|default:'None'}
                    </span>
                </div>
            </div>
        </div>

        {* ── Tabs ── *}
        <div class="cl-tab-bar">
            <button class="cl-tab-btn" x-bind:class="activeTab === 'records' ? 'cl-tab-active' : ''" x-on:click="activeTab = 'records'" type="button">
                <i class="bi bi-globe2"></i> DNS Records
            </button>
            {if $quota.redirects_enabled}
            <button class="cl-tab-btn" x-bind:class="activeTab === 'redirects' ? 'cl-tab-active' : ''" x-on:click="activeTab = 'redirects'" type="button">
                <i class="bi bi-link-45deg"></i> Redirects
                {if $domain.redirects_count > 0}<span class="cl-tab-count">{$domain.redirects_count}</span>{/if}
            </button>
            {/if}
            {if $quota.email_enabled}
            <button class="cl-tab-btn" x-bind:class="activeTab === 'email' ? 'cl-tab-active' : ''" x-on:click="activeTab = 'email'" type="button">
                <i class="bi bi-envelope"></i> Email
                {if $domain.email_fwds_count > 0}<span class="cl-tab-count">{$domain.email_fwds_count}</span>{/if}
            </button>
            {/if}
            {if $quota.dnssec_enabled}
            <button class="cl-tab-btn" x-bind:class="activeTab === 'dnssec' ? 'cl-tab-active' : ''" x-on:click="activeTab = 'dnssec'" type="button">
                <i class="bi bi-shield-lock"></i> DNSSEC
            </button>
            {/if}
            {if $quota.ddns_enabled}
            <button class="cl-tab-btn" x-bind:class="activeTab === 'ddns' ? 'cl-tab-active' : ''" x-on:click="activeTab = 'ddns'" type="button">
                <i class="bi bi-router"></i> DDNS
            </button>
            {/if}
            {if $quota.templates_enabled}
            <button class="cl-tab-btn" x-bind:class="activeTab === 'templates' ? 'cl-tab-active' : ''" x-on:click="activeTab = 'templates'" type="button">
                <i class="bi bi-files"></i> Templates
            </button>
            {/if}
        </div>

        {* ── Tab Content ── *}
        <div>
            {assign var="partials_dir" value="{$module_dir}templates/client/partials"}

            <div x-show="activeTab === 'records'" x-cloak>
                {include file="$partials_dir/record_table.tpl"}
            </div>
            {if $quota.redirects_enabled}
            <div x-show="activeTab === 'redirects'" x-cloak>
                {include file="$partials_dir/tab_redirects.tpl"}
            </div>
            {/if}
            {if $quota.email_enabled}
            <div x-show="activeTab === 'email'" x-cloak>
                {include file="$partials_dir/tab_email.tpl"}
            </div>
            {/if}
            {if $quota.dnssec_enabled}
            <div x-show="activeTab === 'dnssec'" x-cloak>
                {include file="$partials_dir/tab_dnssec.tpl"}
            </div>
            {/if}
            {if $quota.ddns_enabled}
            <div x-show="activeTab === 'ddns'" x-cloak>
                {include file="$partials_dir/tab_ddns.tpl"}
            </div>
            {/if}
            {if $quota.templates_enabled}
            <div x-show="activeTab === 'templates'" x-cloak>
                {include file="$partials_dir/tab_templates.tpl"}
            </div>
            {/if}
        </div>

    </div>

    {assign var="partials_dir_toast" value="{$module_dir}templates/client/partials"}
    {include file="$partials_dir_toast/toast.tpl"}
    {include file="$partials_dir_toast/confirm_modal.tpl"}

    {literal}
    <style>
    [x-cloak] { display: none !important; }
    </style>
    {/literal}