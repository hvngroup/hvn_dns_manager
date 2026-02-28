<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css">

{* ── Smarty variables → JS config ── *}
<script>
    var HVNDNS_CONFIG = {ldelim}
        domainId: {$domain.id|intval},
        domainName: '{$domain.domain|escape:'javascript'}',
        records: {$recordsJson nofilter}
    {rdelim};
</script>

{* ── Alpine component ── *}
{literal}
<script>
    document.addEventListener('alpine:init', function() {
        Alpine.data('dnsEditor', function() {
            return {
                domainId: HVNDNS_CONFIG.domainId,
                domainName: HVNDNS_CONFIG.domainName,
                records: HVNDNS_CONFIG.records,
                filterType: 'all',
                searchQuery: '',
                activeTab: 'records',

                // ── Inline editing state ──
                editingId: null,       // id record đang sửa (null = không edit)
                addingNew: false,      // đang thêm row mới?
                editForm: { type: 'A', name: '', value: '', ttl: 3600, priority: 10, weight: 0, port: 443 },
                saving: false,

                get filteredRecords() {
                    var self = this;
                    return this.records.filter(function(record) {
                        var typeMatch = self.filterType === 'all' || record.type === self.filterType;
                        var searchMatch = self.searchQuery === '' 
                            || record.name.toLowerCase().includes(self.searchQuery.toLowerCase())
                            || record.value.toLowerCase().includes(self.searchQuery.toLowerCase());
                        return typeMatch && searchMatch;
                    });
                },

                getTypeBadgeClass: function(type) {
                    var classes = {
                        'A': 'bg-primary', 'AAAA': 'bg-info text-dark', 'CNAME': 'bg-purple',
                        'MX': 'bg-warning text-dark', 'TXT': 'bg-success', 'SRV': 'bg-danger',
                        'NS': 'bg-secondary', 'CAA': 'bg-dark'
                    };
                    return classes[type] || 'bg-secondary';
                },

                formatTTL: function(ttl) {
                    var map = { 60:'1m', 300:'5m', 1800:'30m', 3600:'1h', 14400:'4h', 43200:'12h', 86400:'24h' };
                    return map[ttl] || ttl + 's';
                },

                // ── Bắt đầu thêm mới ──
                startAdd: function() {
                    this.cancelEdit();
                    this.addingNew = true;
                    this.editForm = { type: 'A', name: '', value: '', ttl: 3600, priority: 10, weight: 0, port: 443 };
                },

                // ── Bắt đầu sửa 1 record ──
                startEdit: function(record) {
                    this.addingNew = false;
                    this.editingId = record.id;
                    this.editForm = {
                        type: record.type,
                        name: record.name,
                        value: record.value,
                        ttl: record.ttl,
                        priority: record.priority || 10,
                        weight: record.weight || 0,
                        port: record.port || 443
                    };
                },

                // ── Hủy ──
                cancelEdit: function() {
                    this.editingId = null;
                    this.addingNew = false;
                    this.saving = false;
                },

                // ── Lưu (thêm hoặc sửa) ──
                saveEdit: function() {
                    if (!this.editForm.value.trim()) {
                        alert('Vui lòng nhập giá trị bản ghi');
                        return;
                    }
                    if (!this.editForm.name.trim()) {
                        this.editForm.name = '@';
                    }

                    this.saving = true;
                    var self = this;

                    // Mock API delay
                    setTimeout(function() {
                        if (self.addingNew) {
                            // Thêm record mới vào danh sách
                            var newRecord = {
                                id: Date.now(),
                                type: self.editForm.type,
                                name: self.editForm.name,
                                value: self.editForm.value,
                                ttl: parseInt(self.editForm.ttl),
                                priority: parseInt(self.editForm.priority) || 0,
                                weight: parseInt(self.editForm.weight) || 0,
                                port: parseInt(self.editForm.port) || 0,
                                is_system: false,
                                is_locked: false,
                                sync_status: 'syncing',
                                pending_delete: false
                            };
                            self.records.unshift(newRecord);
                            window.dispatchEvent(new CustomEvent('show-toast', {
                                detail: { title: 'Đã thêm', msg: self.editForm.type + ' ' + self.editForm.name + ' đang đồng bộ...', type: 'success' }
                            }));
                        } else {
                            // Cập nhật record hiện tại
                            var idx = -1;
                            for (var i = 0; i < self.records.length; i++) {
                                if (self.records[i].id === self.editingId) { idx = i; break; }
                            }
                            if (idx >= 0) {
                                self.records[idx].name = self.editForm.name;
                                self.records[idx].value = self.editForm.value;
                                self.records[idx].ttl = parseInt(self.editForm.ttl);
                                self.records[idx].priority = parseInt(self.editForm.priority) || 0;
                                self.records[idx].weight = parseInt(self.editForm.weight) || 0;
                                self.records[idx].port = parseInt(self.editForm.port) || 0;
                                self.records[idx].sync_status = 'syncing';
                            }
                            window.dispatchEvent(new CustomEvent('show-toast', {
                                detail: { title: 'Đã cập nhật', msg: self.editForm.type + ' ' + self.editForm.name + ' đang đồng bộ...', type: 'success' }
                            }));
                        }
                        self.cancelEdit();
                    }, 500);
                },

                // ── Xóa ──
                deleteRecord: function(record) {
                    if (confirm('Bạn có chắc muốn xóa bản ghi: ' + record.name + ' ' + record.type + '?')) {
                        record.pending_delete = true;
                        record.sync_status = 'syncing';
                        window.dispatchEvent(new CustomEvent('show-toast', {
                            detail: { title: 'Đang xóa', msg: 'Bản ghi ' + record.name + ' đang được xóa...', type: 'danger' }
                        }));
                    }
                },

                retryRecord: function(id) {
                    for (var i = 0; i < this.records.length; i++) {
                        if (this.records[i].id === id) {
                            this.records[i].sync_status = 'syncing';
                            break;
                        }
                    }
                    window.dispatchEvent(new CustomEvent('show-toast', {
                        detail: { title: 'Đang thử lại', msg: 'Hệ thống đang đồng bộ lại...', type: 'warning' }
                    }));
                },

                // ── Helper: cần hiện priority? ──
                needsPriority: function(type) {
                    return type === 'MX' || type === 'SRV';
                },
                needsSrv: function(type) {
                    return type === 'SRV';
                }
            };
        });
    });
</script>
{/literal}

{* ══════════════════════════ HTML ══════════════════════════ *}

<div class="hvn-dns-client" x-data="dnsEditor()">

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
                        <span>Đang dùng: <strong x-text="records.length + '/{$quota.max_records} records'"></strong></span>
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

    {* ── Tabs ── *}
    <ul class="nav nav-tabs mb-4" role="tablist">
        <li class="nav-item">
            <button class="nav-link fw-bold" x-bind:class="activeTab === 'records' && 'active'" x-on:click="activeTab = 'records'" type="button">DNS Records</button>
        </li>
        <li class="nav-item">
            <button class="nav-link fw-bold" x-bind:class="activeTab === 'redirects' && 'active'" x-on:click="activeTab = 'redirects'" type="button">
                Redirects {if $domain.redirects_count > 0}<span class="badge bg-secondary rounded-pill">{$domain.redirects_count}</span>{/if}
            </button>
        </li>
        <li class="nav-item">
            <button class="nav-link fw-bold" x-bind:class="activeTab === 'email' && 'active'" x-on:click="activeTab = 'email'" type="button">
                Email {if $domain.email_fwds_count > 0}<span class="badge bg-secondary rounded-pill">{$domain.email_fwds_count}</span>{/if}
            </button>
        </li>
        {if $quota.dnssec_enabled}
        <li class="nav-item">
            <button class="nav-link fw-bold" x-bind:class="activeTab === 'dnssec' && 'active'" x-on:click="activeTab = 'dnssec'" type="button">DNSSEC</button>
        </li>
        {/if}
        {if $quota.ddns_enabled}
        <li class="nav-item">
            <button class="nav-link fw-bold" x-bind:class="activeTab === 'ddns' && 'active'" x-on:click="activeTab = 'ddns'" type="button">DDNS</button>
        </li>
        {/if}
        <li class="nav-item">
            <button class="nav-link fw-bold" x-bind:class="activeTab === 'templates' && 'active'" x-on:click="activeTab = 'templates'" type="button">Templates</button>
        </li>
    </ul>

    {* ── Tab Content ── *}
    <div>
        {assign var="partials_dir" value="{$module_dir}templates/client/partials"}

        <div x-show="activeTab === 'records'" x-cloak>
            {include file="$partials_dir/record_table.tpl"}
        </div>
        <div x-show="activeTab === 'redirects'" x-cloak>
            {include file="$partials_dir/tab_redirects.tpl"}
        </div>
        <div x-show="activeTab === 'email'" x-cloak>
            {include file="$partials_dir/tab_email.tpl"}
        </div>
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
        <div x-show="activeTab === 'templates'" x-cloak>
            {include file="$partials_dir/tab_templates.tpl"}
        </div>
    </div>

    {include file="$partials_dir/toast.tpl"}
</div>

<script src="https://cdn.jsdelivr.net/npm/alpinejs@3.x.x/dist/cdn.min.js" defer></script>

{literal}
<style>
[x-cloak] { display: none !important; }
.bg-purple { background-color: #6f42c1; color: white; }
.nav-tabs .nav-link { color: #495057; cursor: pointer; }
.nav-tabs .nav-link.active { border-bottom-color: transparent !important; color: #ea4544 !important; font-weight: 700 !important; }
.nav-tabs .nav-link:hover:not(.active) { border-color: transparent; color: #ea4544; }
.spin { animation: spin 2s linear infinite; }
@keyframes spin { 100% { transform: rotate(360deg); } }

/* Inline edit row */
.hvn-inline-edit td { background-color: #fff8e1 !important; }
.hvn-inline-edit .form-control,
.hvn-inline-edit .form-select { font-size: 12px; padding: 3px 6px; height: auto; }
.hvn-inline-add td { background-color: #e8f5e9 !important; }
.hvn-inline-add .form-control,
.hvn-inline-add .form-select { font-size: 12px; padding: 3px 6px; height: auto; }
</style>
{/literal}
