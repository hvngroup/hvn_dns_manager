{* ── Load Alpine.js + Bootstrap Icons (chỉ inject nếu chưa có) ── *}
<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css">

{* ── Alpine data + config PHẢI đặt TRƯỚC khi Alpine load ── *}
<script>
    var HVNDNS_CONFIG = {
        domainId: {$domain.id|intval},
        records: {$recordsJson nofilter}
    };

    document.addEventListener('alpine:init', function() {
        Alpine.data('dnsEditor', function() {
            return {
                domainId: HVNDNS_CONFIG.domainId,
                records: HVNDNS_CONFIG.records,
                filterType: 'all',
                searchQuery: '',
                activeTab: 'records',

                get filteredRecords() {
                    return this.records.filter(function(record) {
                        var typeMatch = this.filterType === 'all' || record.type === this.filterType;
                        var searchMatch = this.searchQuery === '' 
                            || record.name.toLowerCase().includes(this.searchQuery.toLowerCase())
                            || record.value.toLowerCase().includes(this.searchQuery.toLowerCase());
                        return typeMatch && searchMatch;
                    }.bind(this));
                },

                getTypeBadgeClass(type) {
                    var classes = {
                        'A': 'bg-primary', 'AAAA': 'bg-info text-dark', 'CNAME': 'bg-purple',
                        'MX': 'bg-warning text-dark', 'TXT': 'bg-success', 'SRV': 'bg-danger',
                        'NS': 'bg-secondary', 'CAA': 'bg-dark'
                    };
                    return classes[type] || 'bg-secondary';
                },

                formatTTL(ttl) {
                    var map = { 60:'1m', 300:'5m', 1800:'30m', 3600:'1h', 14400:'4h', 43200:'12h', 86400:'24h' };
                    return map[ttl] || ttl + 's';
                },

                deleteRecord(record) {
                    if (confirm('Bạn có chắc muốn xóa bản ghi: ' + record.name + ' ' + record.type + '?')) {
                        window.dispatchEvent(new CustomEvent('show-toast', {
                            detail: { title: 'Đã Xóa', msg: 'Bản ghi ' + record.name + ' đang được xóa...', type: 'danger' }
                        }));
                    }
                },

                retryRecord(id) {
                    window.dispatchEvent(new CustomEvent('show-toast', {
                        detail: { title: 'Đang thử lại', msg: 'Hệ thống đang đồng bộ lại...', type: 'warning' }
                    }));
                }
            };
        });
    });
</script>

<div class="hvn-dns-client" x-data="dnsEditor()">
    {* ── Header ── *}
    <div class="d-flex justify-content-between align-items-center mb-3">
        <a href="index.php?m=hvn_dns_manager" class="text-decoration-none">
            &larr; Quay lại danh sách domain
        </a>
    </div>

    {* ── Domain Info Card ── *}
    <div class="card mb-4 border-primary">
        <div class="card-body">
            <h2 class="card-title d-flex align-items-center gap-2 mb-3">
                <i class="bi bi-globe text-primary"></i> {$domain.domain}
            </h2>
            <hr>
            <div class="row align-items-center">
                <div class="col-md-6 mb-3 mb-md-0">
                    {assign var="safe_max" value=$quota.max_records|default:1}
                    {math assign="percent" equation="round((c/m)*100)" c=$domain.records_count m=$safe_max}
                    <div class="d-flex justify-content-between mb-1">
                        <span>Đang dùng: <strong>{$domain.records_count}/{$quota.max_records} records</strong></span>
                        <span>{$percent}%</span>
                    </div>
                    <div class="progress" style="height: 10px;">
                        <div class="progress-bar {if $percent > 90}bg-danger{elseif $percent > 75}bg-warning{else}bg-primary{/if}" 
                             role="progressbar" style="width: {$percent}%;" aria-valuenow="{$percent}" aria-valuemin="0" aria-valuemax="100"></div>
                    </div>
                </div>
                <div class="col-md-6 text-md-end">
                    <span class="badge {if $domain.dnssec_enabled}bg-success{else}bg-secondary{/if} me-2 p-2">
                        <i class="bi bi-shield-lock"></i> DNSSEC: {if $domain.dnssec_enabled}Bật{else}Tắt{/if}
                    </span>
                    <span class="badge {if $domain.ssl_status == 'active'}bg-success{elseif $domain.ssl_status == 'pending'}bg-warning{else}bg-secondary{/if} p-2">
                        <i class="bi bi-lock"></i> SSL: {$domain.ssl_status|capitalize|default:'None'}
                    </span>
                </div>
            </div>
        </div>
    </div>

    {* ── Navigation Tabs (Alpine-powered, không phụ thuộc BS JS) ── *}
    <ul class="nav nav-tabs mb-4" role="tablist">
        <li class="nav-item" role="presentation">
            <button class="nav-link fw-bold" :class="{ 'active': activeTab === 'records' }" @click="activeTab = 'records'" type="button">
                DNS Records
            </button>
        </li>
        <li class="nav-item" role="presentation">
            <button class="nav-link fw-bold" :class="{ 'active': activeTab === 'redirects' }" @click="activeTab = 'redirects'" type="button">
                Redirects {if $domain.redirects_count > 0}<span class="badge bg-secondary rounded-pill">{$domain.redirects_count}</span>{/if}
            </button>
        </li>
        <li class="nav-item" role="presentation">
            <button class="nav-link fw-bold" :class="{ 'active': activeTab === 'email' }" @click="activeTab = 'email'" type="button">
                Email {if $domain.email_fwds_count > 0}<span class="badge bg-secondary rounded-pill">{$domain.email_fwds_count}</span>{/if}
            </button>
        </li>
        {if $quota.dnssec_enabled}
        <li class="nav-item" role="presentation">
            <button class="nav-link fw-bold" :class="{ 'active': activeTab === 'dnssec' }" @click="activeTab = 'dnssec'" type="button">
                DNSSEC
            </button>
        </li>
        {/if}
        {if $quota.ddns_enabled}
        <li class="nav-item" role="presentation">
            <button class="nav-link fw-bold" :class="{ 'active': activeTab === 'ddns' }" @click="activeTab = 'ddns'" type="button">
                DDNS
            </button>
        </li>
        {/if}
        <li class="nav-item" role="presentation">
            <button class="nav-link fw-bold" :class="{ 'active': activeTab === 'templates' }" @click="activeTab = 'templates'" type="button">
                Templates
            </button>
        </li>
    </ul>

    {* ── Tab Content (Alpine x-show thay vì BS tab-pane) ── *}
    <div>
        <div x-show="activeTab === 'records'" x-cloak>
            {include file="./partials/record_table.tpl"}
        </div>
        
        <div x-show="activeTab === 'redirects'" x-cloak>
            {include file="./partials/tab_redirects.tpl"}
        </div>
        
        <div x-show="activeTab === 'email'" x-cloak>
            {include file="./partials/tab_email.tpl"}
        </div>
        
        {if $quota.dnssec_enabled}
        <div x-show="activeTab === 'dnssec'" x-cloak>
            {include file="./partials/tab_dnssec.tpl"}
        </div>
        {/if}

        {if $quota.ddns_enabled}
        <div x-show="activeTab === 'ddns'" x-cloak>
            {include file="./partials/tab_ddns.tpl"}
        </div>
        {/if}

        <div x-show="activeTab === 'templates'" x-cloak>
            {include file="./partials/tab_templates.tpl"}
        </div>
    </div>
    
    {* ── Toast ── *}
    {include file="./partials/toast.tpl"}
</div>

{* ── Load Alpine.js SAU khi đã register xong alpine:init listener ── *}
<script src="https://cdn.jsdelivr.net/npm/alpinejs@3.x.x/dist/cdn.min.js" defer></script>

<style>
{literal}
/* Alpine cloak: ẩn cho đến khi Alpine init xong */
[x-cloak] { display: none !important; }

.bg-purple { background-color: #6f42c1; color: white; }
.nav-tabs .nav-link { color: #495057; cursor: pointer; }
.nav-tabs .nav-link.active { 
    border-bottom-color: transparent !important; 
    color: #ea4544 !important; 
    font-weight: 700 !important;
}
.nav-tabs .nav-link:hover:not(.active) {
    border-color: transparent;
    color: #ea4544;
}
.spin { animation: spin 2s linear infinite; }
@keyframes spin { 100% { transform: rotate(360deg); } }
{/literal}
</style>
