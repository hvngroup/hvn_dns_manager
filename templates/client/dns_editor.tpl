<div class="hvn-dns-client" x-data="dnsEditor()">
    <!-- Header -->
    <div class="d-flex justify-content-between align-items-center mb-3">
        <a href="clientarea.php?action=productdetails&id={$serviceid}" class="text-decoration-none">
            &larr; Quay lại danh sách domain
        </a>
    </div>

    <div class="card mb-4 border-primary">
        <div class="card-body">
            <h2 class="card-title d-flex align-items-center gap-2 mb-3">
                <i class="bi bi-globe text-primary"></i> {$domain.domain}
            </h2>
            <hr>
            <div class="row align-items-center">
                <div class="col-md-6 mb-3 mb-md-0">
                    <div class="d-flex justify-content-between mb-1">
                        <span>Đang dùng: <strong>{$domain.records_count}/{$quota.max_records} records</strong></span>
                        <span>{math equation="round((c/m)*100)" c=$domain.records_count m=$quota.max_records}%</span>
                    </div>
                    <div class="progress" style="height: 10px;">
                        {math assign="percent" equation="round((c/m)*100)" c=$domain.records_count m=$quota.max_records}
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

    <!-- Navigation Tabs -->
    <ul class="nav nav-tabs mb-4" id="dnsTabs" role="tablist">
        <li class="nav-item" role="presentation">
            <button class="nav-link active fw-bold" id="records-tab" data-bs-toggle="tab" data-bs-target="#records" type="button" role="tab" aria-controls="records" aria-selected="true">
                DNS Records
            </button>
        </li>
        <li class="nav-item" role="presentation">
            <button class="nav-link fw-bold text-dark" id="redirects-tab" data-bs-toggle="tab" data-bs-target="#redirects" type="button" role="tab" aria-controls="redirects" aria-selected="false">
                Redirects {if $domain.redirects_count > 0}<span class="badge bg-secondary rounded-pill">{$domain.redirects_count}</span>{/if}
            </button>
        </li>
        <li class="nav-item" role="presentation">
            <button class="nav-link fw-bold text-dark" id="email-tab" data-bs-toggle="tab" data-bs-target="#email" type="button" role="tab" aria-controls="email" aria-selected="false">
                Email {if $domain.email_fwds_count > 0}<span class="badge bg-secondary rounded-pill">{$domain.email_fwds_count}</span>{/if}
            </button>
        </li>
        {if $quota.dnssec_enabled}
        <li class="nav-item" role="presentation">
            <button class="nav-link fw-bold text-dark" id="dnssec-tab" data-bs-toggle="tab" data-bs-target="#dnssec" type="button" role="tab" aria-controls="dnssec" aria-selected="false">
                DNSSEC
            </button>
        </li>
        {/if}
        {if $quota.ddns_enabled}
        <li class="nav-item" role="presentation">
            <button class="nav-link fw-bold text-dark" id="ddns-tab" data-bs-toggle="tab" data-bs-target="#ddns" type="button" role="tab" aria-controls="ddns" aria-selected="false">
                DDNS
            </button>
        </li>
        {/if}
        <li class="nav-item" role="presentation">
            <button class="nav-link fw-bold text-dark" id="templates-tab" data-bs-toggle="tab" data-bs-target="#templates" type="button" role="tab" aria-controls="templates" aria-selected="false">
                Templates
            </button>
        </li>
    </ul>

    <!-- Tab Content -->
    <div class="tab-content" id="dnsTabsContent">
        <!-- Records Tab -->
        <div class="tab-pane fade show active" id="records" role="tabpanel" aria-labelledby="records-tab">
            {include file="./partials/record_table.tpl"}
        </div>
        
        <!-- Redirects Tab -->
        <div class="tab-pane fade" id="redirects" role="tabpanel" aria-labelledby="redirects-tab">
            {include file="./partials/tab_redirects.tpl"}
        </div>
        
        <!-- Email Tab -->
        <div class="tab-pane fade" id="email" role="tabpanel" aria-labelledby="email-tab">
            {include file="./partials/tab_email.tpl"}
        </div>
        
        <!-- DNSSEC Tab -->
        {if $quota.dnssec_enabled}
        <div class="tab-pane fade" id="dnssec" role="tabpanel" aria-labelledby="dnssec-tab">
            {include file="./partials/tab_dnssec.tpl"}
        </div>
        {/if}

        <!-- DDNS Tab -->
        {if $quota.ddns_enabled}
        <div class="tab-pane fade" id="ddns" role="tabpanel" aria-labelledby="ddns-tab">
            {include file="./partials/tab_ddns.tpl"}
        </div>
        {/if}

        <!-- Templates Tab -->
        <div class="tab-pane fade" id="templates" role="tabpanel" aria-labelledby="templates-tab">
            {include file="./partials/tab_templates.tpl"}
        </div>
    </div>
    
    <!-- Modals -->
    {include file="./partials/toast.tpl"}
    
    <!-- Alpine JS logic initialization -->
    <script>
        document.addEventListener('alpine:init', () => {
            Alpine.data('dnsEditor', () => ({
                domainId: {$domain.id},
                records: {$recordsJson|default:'[]'},
                filterType: 'all',
                searchQuery: '',
                
                get filteredRecords() {
                    return this.records.filter(record => {
                        const typeMatch = this.filterType === 'all' || record.type === this.filterType;
                        const searchMatch = this.searchQuery === '' 
                            || record.name.toLowerCase().includes(this.searchQuery.toLowerCase())
                            || record.value.toLowerCase().includes(this.searchQuery.toLowerCase());
                        return typeMatch && searchMatch;
                    });
                },
                
                getTypeBadgeClass(type) {
                    const classes = {
                        'A': 'bg-primary',
                        'AAAA': 'bg-info text-dark',
                        'CNAME': 'bg-purple',
                        'MX': 'bg-warning text-dark',
                        'TXT': 'bg-success',
                        'SRV': 'bg-danger',
                        'NS': 'bg-secondary',
                        'CAA': 'bg-dark'
                    };
                    return classes[type] || 'bg-secondary';
                },
                // Additional methods for add/edit/delete will go here in JS file
            }));
        document.addEventListener('alpine:initialized', () => {
            if (Alpine.$data(document.querySelector('.hvn-dns-client'))) {
                const data = Alpine.$data(document.querySelector('.hvn-dns-client'));
                data.deleteRecord = function(record) {
                    if(confirm(`Bạn có chắc muốn xóa bản ghi: ${record.name} ${record.type}?`)) {
                        window.dispatchEvent(new CustomEvent('show-toast', { detail: { title: 'Đã Xóa', msg: `Bản ghi ${record.name} đang được xóa...`, type: 'danger' } }));
                    }
                };
                data.retryRecord = function(id) {
                    window.dispatchEvent(new CustomEvent('show-toast', { detail: { title: 'Đang thử lại', msg: 'Hệ thống đang đồng bộ lại...', type: 'warning' } }));
                }
            }
        });
    </script>
</div>
<style>
.bg-purple { background-color: #6f42c1; color: white; }
.nav-tabs .nav-link.active { border-bottom-color: transparent !important; color: #ea4544 !important; }
</style>
