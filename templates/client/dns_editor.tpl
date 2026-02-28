<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css">

{* ── Smarty variables → JS config ── *}
<script>
    var HVNDNS_CONFIG = {ldelim}
        domainId: {$domain.id|intval},
        domainName: '{$domain.domain|escape:'javascript'}',
        records: {$recordsJson nofilter},
        redirects: {$redirectsJson|default:'[]' nofilter},
        emails: {$emailsJson|default:'[]' nofilter},
        ddnsTokens: {$ddnsJson|default:'[]' nofilter},
        templates: {$templatesJson|default:'[]' nofilter}
    {rdelim};
</script>

{* ── Alpine component ── *}
{literal}
<script>
    document.addEventListener('alpine:init', function() {
        Alpine.data('dnsEditor', function() {
            return {
                domainId: HVNDNS_CONFIG.domainId,
                records: HVNDNS_CONFIG.records,
                redirects: HVNDNS_CONFIG.redirects || [],
                emails: HVNDNS_CONFIG.emails || [],
                ddnsTokens: HVNDNS_CONFIG.ddnsTokens || [],
                templates: HVNDNS_CONFIG.templates || [],
                filterType: 'all',
                searchQuery: '',
                activeTab: 'records',

                // ── Inline editing state (DNS) ──
                editingId: null,       // id record đang sửa (null = không edit)
                addingNew: false,      // đang thêm row mới?
                editForm: { type: 'A', name: '', value: '', ttl: 3600, priority: 10, weight: 0, port: 443 },
                saving: false,

                // ── Inline editing state (Redirects) ──
                editingRedirectId: null,
                addingNewRedirect: false,
                editRedirectForm: { source: '/', destination: 'https://', type: '301', title: '' },
                savingRedirect: false,

                // ── Inline editing state (Email) ──
                editingEmailId: null,
                addingNewEmail: false,
                editEmailForm: { source: '', destination: '' },
                savingEmail: false,

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

                retryRedirect: function(id) {
                    for (var i = 0; i < this.redirects.length; i++) {
                        if (this.redirects[i].id === id) {
                            this.redirects[i].sync_status = 'syncing';
                            break;
                        }
                    }
                    window.dispatchEvent(new CustomEvent('show-toast', {
                        detail: { title: 'Đang thử lại', msg: 'Hệ thống đang đồng bộ lại chuyển hướng...', type: 'warning' }
                    }));
                },

                getTypeRedirectBadgeClass: function(type) {
                    var classes = { '301': 'bg-primary', '302': 'bg-info text-dark', 'masked': 'bg-dark' };
                    return classes[type] || 'bg-secondary';
                },

                getTypeRedirectLabel: function(type) {
                    var labels = { '301': 'Vĩnh viễn', '302': 'Tạm thời', 'masked': 'Trang ảo' };
                    return labels[type] || '';
                },

                // ── Bắt đầu thêm chuyển hướng mới ──
                startAddRedirect: function() {
                    this.cancelEditRedirect();
                    this.addingNewRedirect = true;
                    this.editRedirectForm = { source: '/', destination: 'https://', type: '301', title: '' };
                },

                // ── Bắt đầu sửa 1 chuyển hướng ──
                startEditRedirect: function(redirect) {
                    this.addingNewRedirect = false;
                    this.editingRedirectId = redirect.id;
                    this.editRedirectForm = {
                        source: redirect.source,
                        destination: redirect.destination,
                        type: redirect.type,
                        title: redirect.title || ''
                    };
                },

                // ── Hủy (Redirects) ──
                cancelEditRedirect: function() {
                    this.editingRedirectId = null;
                    this.addingNewRedirect = false;
                    this.savingRedirect = false;
                },

                // ── Lưu (thêm hoặc sửa chuyển hướng) ──
                saveEditRedirect: function() {
                    if (!this.editRedirectForm.source.trim() || !this.editRedirectForm.destination.trim()) {
                        alert('Vui lòng nhập nguồn và đích chuyển hướng');
                        return;
                    }

                    this.savingRedirect = true;
                    var self = this;

                    // Mock API delay
                    setTimeout(function() {
                        if (self.addingNewRedirect) {
                            var newRedirect = {
                                id: Date.now(),
                                source: self.editRedirectForm.source,
                                destination: self.editRedirectForm.destination,
                                type: self.editRedirectForm.type,
                                title: self.editRedirectForm.title,
                                sync_status: 'syncing',
                                pending_delete: false
                            };
                            self.redirects.unshift(newRedirect);
                            window.dispatchEvent(new CustomEvent('show-toast', {
                                detail: { title: 'Đã thêm', msg: 'Chuyển hướng từ ' + self.editRedirectForm.source + ' đang đồng bộ...', type: 'success' }
                            }));
                        } else {
                            var idx = -1;
                            for (var i = 0; i < self.redirects.length; i++) {
                                if (self.redirects[i].id === self.editingRedirectId) { idx = i; break; }
                            }
                            if (idx >= 0) {
                                self.redirects[idx].source = self.editRedirectForm.source;
                                self.redirects[idx].destination = self.editRedirectForm.destination;
                                self.redirects[idx].type = self.editRedirectForm.type;
                                self.redirects[idx].title = self.editRedirectForm.title;
                                self.redirects[idx].sync_status = 'syncing';
                            }
                            window.dispatchEvent(new CustomEvent('show-toast', {
                                detail: { title: 'Đã cập nhật', msg: 'Chuyển hướng từ ' + self.editRedirectForm.source + ' đang đồng bộ...', type: 'success' }
                            }));
                        }
                        self.cancelEditRedirect();
                    }, 500);
                },

                // ── Xóa chuyển hướng ──
                deleteRedirect: function(redirect) {
                    if (confirm('Bạn có chắc muốn xóa chuyển hướng: ' + redirect.source + ' -> ' + redirect.destination + '?')) {
                        redirect.pending_delete = true;
                        redirect.sync_status = 'syncing';
                        window.dispatchEvent(new CustomEvent('show-toast', {
                            detail: { title: 'Đang xóa', msg: 'Chuyển hướng ' + redirect.source + ' đang được xóa...', type: 'danger' }
                        }));
                    }
                },

                // ── Helper: Cần title? ──
                needsTitle: function(type) {
                    return type === 'masked';
                },

                // ── Xử lý Email Forwards ──
                retryEmail: function(id) {
                    for (var i = 0; i < this.emails.length; i++) {
                        if (this.emails[i].id === id) {
                            this.emails[i].sync_status = 'syncing';
                            break;
                        }
                    }
                    window.dispatchEvent(new CustomEvent('show-toast', {
                        detail: { title: 'Đang thử lại', msg: 'Hệ thống đang đồng bộ lại chuyển tiếp...', type: 'warning' }
                    }));
                },

                startAddEmail: function() {
                    this.cancelEditEmail();
                    this.addingNewEmail = true;
                    this.editEmailForm = { source: '', destination: '' };
                },

                startEditEmail: function(email) {
                    this.addingNewEmail = false;
                    this.editingEmailId = email.id;
                    this.editEmailForm = {
                        source: email.source.replace('@' + this.domainName, ''),
                        destination: email.destination
                    };
                },

                cancelEditEmail: function() {
                    this.editingEmailId = null;
                    this.addingNewEmail = false;
                    this.savingEmail = false;
                },

                saveEditEmail: function() {
                    if (!this.editEmailForm.source.trim() || !this.editEmailForm.destination.trim()) {
                        alert('Vui lòng nhập tên người dùng và địa chỉ đích');
                        return;
                    }

                    this.savingEmail = true;
                    var self = this;
                    var fullSource = self.editEmailForm.source + '@' + self.domainName;

                    setTimeout(function() {
                        if (self.addingNewEmail) {
                            var newEmail = {
                                id: Date.now(),
                                source: fullSource,
                                destination: self.editEmailForm.destination,
                                sync_status: 'syncing',
                                pending_delete: false
                            };
                            self.emails.unshift(newEmail);
                            window.dispatchEvent(new CustomEvent('show-toast', {
                                detail: { title: 'Đã thêm', msg: 'Chuyển tiếp cho ' + fullSource + ' đang đồng bộ...', type: 'success' }
                            }));
                        } else {
                            var idx = -1;
                            for (var i = 0; i < self.emails.length; i++) {
                                if (self.emails[i].id === self.editingEmailId) { idx = i; break; }
                            }
                            if (idx >= 0) {
                                self.emails[idx].source = fullSource;
                                self.emails[idx].destination = self.editEmailForm.destination;
                                self.emails[idx].sync_status = 'syncing';
                            }
                            window.dispatchEvent(new CustomEvent('show-toast', {
                                detail: { title: 'Đã cập nhật', msg: 'Chuyển tiếp cho ' + fullSource + ' đang đồng bộ...', type: 'success' }
                            }));
                        }
                        self.cancelEditEmail();
                    }, 500);
                },

                deleteEmail: function(email) {
                    if (confirm('Bạn có chắc muốn xóa chuyển tiếp: ' + email.source + '?')) {
                        email.pending_delete = true;
                        email.sync_status = 'syncing';
                        window.dispatchEvent(new CustomEvent('show-toast', {
                            detail: { title: 'Đang xóa', msg: 'Chuyển tiếp ' + email.source + ' đang được xóa...', type: 'danger' }
                        }));
                    }
                },

                // ── Helper: Cần title? ──
                needsTitle: function(type) {
                    return type === 'masked';
                },

                // ── DDNS Handlers ──
                showCreateDdnsForm: false,
                newDdnsToken: { subdomain: '', label: '' },

                toggleDdnsDetail: function(id) {
                    for (var i = 0; i < this.ddnsTokens.length; i++) {
                        if (this.ddnsTokens[i].id === id) {
                            this.ddnsTokens[i].showDetail = !this.ddnsTokens[i].showDetail;
                            break;
                        }
                    }
                },

                toggleDdnsActive: function(id) {
                    var token = null;
                    for (var i = 0; i < this.ddnsTokens.length; i++) {
                        if (this.ddnsTokens[i].id === id) {
                            this.ddnsTokens[i].active = !this.ddnsTokens[i].active;
                            token = this.ddnsTokens[i];
                            break;
                        }
                    }
                    if (token) {
                        window.dispatchEvent(new CustomEvent('show-toast', {
                            detail: { title: token.active ? 'Đã bật' : 'Đã tắt', msg: 'Token ' + token.subdomain + ' đã ' + (token.active ? 'kích hoạt' : 'vô hiệu hóa'), type: token.active ? 'success' : 'warning' }
                        }));
                    }
                },

                deleteDdnsToken: function(id) {
                    var token = null;
                    for (var i = 0; i < this.ddnsTokens.length; i++) {
                        if (this.ddnsTokens[i].id === id) {
                            token = this.ddnsTokens[i];
                            break;
                        }
                    }
                    if (token && confirm('Xóa DDNS token cho ' + token.subdomain + '? Thiết bị sẽ không thể cập nhật IP nữa.')) {
                        this.ddnsTokens = this.ddnsTokens.filter(function(t) { return t.id !== id; });
                        window.dispatchEvent(new CustomEvent('show-toast', {
                            detail: { title: 'Đã xóa', msg: 'Token ' + token.subdomain + ' đã bị xóa', type: 'danger' }
                        }));
                    }
                },

                createDdnsToken: function() {
                    if (!this.newDdnsToken.subdomain.trim()) {
                        alert('Vui lòng nhập subdomain');
                        return;
                    }
                    var newId = Date.now();
                    this.ddnsTokens.push({
                        id: newId,
                        subdomain: this.newDdnsToken.subdomain,
                        label: this.newDdnsToken.label || 'Token mới',
                        ip: 'Chưa cập nhật',
                        updated: 'Vừa tạo',
                        requests: 0,
                        active: true,
                        showDetail: true,
                        token_url: 'https://whmcs.hvn.vn/modules/addons/hvn_dns_manager/ddns.php?token=' + Math.random().toString(36).substring(2, 18)
                    });
                    this.newDdnsToken = { subdomain: '', label: '' };
                    this.showCreateDdnsForm = false;
                    window.dispatchEvent(new CustomEvent('show-toast', {
                        detail: { title: 'Thành công', msg: 'DDNS Token đã được tạo', type: 'success' }
                    }));
                },

                copyDdnsUrl: function(tokenId) {
                    var token = null;
                    for (var i = 0; i < this.ddnsTokens.length; i++) {
                        if (this.ddnsTokens[i].id === tokenId) {
                            token = this.ddnsTokens[i];
                            break;
                        }
                    }
                    if (token) {
                        navigator.clipboard.writeText(token.token_url).then(function() {
                            window.dispatchEvent(new CustomEvent('show-toast', {
                                detail: { title: 'Đã copy', msg: 'URL đã được lưu vào khay nhớ tạm', type: 'success' }
                            }));
                        });
                    }
                },

                copyDdnsMikrotik: function(tokenId) {
                    var token = null;
                    for (var i = 0; i < this.ddnsTokens.length; i++) {
                        if (this.ddnsTokens[i].id === tokenId) {
                            token = this.ddnsTokens[i];
                            break;
                        }
                    }
                    if (token) {
                        var script = '/tool fetch url="' + token.token_url + '" mode=http';
                        navigator.clipboard.writeText(script).then(function() {
                            window.dispatchEvent(new CustomEvent('show-toast', {
                                detail: { title: 'Đã copy', msg: 'Script Mikrotik đã được lưu', type: 'success' }
                            }));
                        });
                    }
                },

                // ── Templates Preview ──
                showTemplatePreview: false,
                previewTemplateId: null,
                previewTemplateRecords: [],

                openTemplatePreview: function(templateId) {
                    var template = this.templates.find(function(t) { return t.id === templateId; });
                    if (template) {
                        this.previewTemplateId = template.id;
                        this.previewTemplateRecords = template.records || [];
                        this.showTemplatePreview = true;
                    }
                },

                closeTemplatePreview: function() {
                    this.showTemplatePreview = false;
                    this.previewTemplateId = null;
                    this.previewTemplateRecords = [];
                },

                applyTemplate: function() {
                    if (confirm('CẢNH BÁO: Thao tác này sẽ XÓA TOÀN BỘ bản ghi hiện tại và áp dụng mẫu mới. Hệ thống sẽ tự động tạo bản backup. Bạn chắc chắn muốn tiếp tục?')) {
                        this.showTemplatePreview = false;
                        window.dispatchEvent(new CustomEvent('show-toast', {
                            detail: { title: 'Đang áp dụng mẫu', msg: 'Hệ thống đang tiến hành nạp mẫu DNS...', type: 'warning' }
                        }));
                    }
                },

                // ── Khác ──
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
