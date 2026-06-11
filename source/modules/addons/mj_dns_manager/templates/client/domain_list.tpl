<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css">
<div class="mj-dns mj-dns-client">
    <h3 style="font-size:18px;font-weight:700;color:#1e293b;margin-bottom:20px;">
        <i class="bi bi-hdd-network" style="color:#ea4544;"></i> DNS Management &mdash; Chọn domain cần quản lý
    </h3>
    <div style="display:grid;grid-template-columns:repeat(auto-fill,minmax(280px,1fr));gap:16px;margin-bottom:20px;">
        {foreach from=$domains item=domain}
            <div class="cl-domain-list-card {if $domain.status == 'suspended' || $domain.status == 'expired' || $domain.status == 'terminated'}" style="opacity:0.5;{/if}">
                <div class="cl-card-body">
                    <div style="display:flex;justify-content:space-between;align-items:flex-start;margin-bottom:8px;">
                        <div style="font-size:15px;font-weight:700;color:#1e293b;display:flex;align-items:center;gap:7px;">
                            <i class="bi bi-globe" style="color:#ea4544;"></i>
                            {$domain.domain|escape:'htmlall'}
                        </div>
                        {if $domain.status == 'active'}
                            {if $domain.sync_status == 'syncing'}
                                <span class="cl-badge cl-badge-warning"><span class="cl-status-dot cl-status-syncing"></span>Syncing</span>
                            {elseif $domain.sync_status == 'pending'}
                                <span class="cl-badge cl-badge-warning">Pending</span>
                            {else}
                                <span class="cl-badge cl-badge-success"><span class="cl-status-dot cl-status-live"></span>Active</span>
                            {/if}
                        {else}
                            <span class="cl-badge cl-badge-danger">{$domain.status|capitalize|escape:'htmlall'}</span>
                        {/if}
                    </div>
                    <div style="font-size:12px;color:#64748b;margin-bottom:4px;">
                        <i class="bi bi-files"></i> {$domain.records_count} records
                    </div>
                    <div style="font-size:11px;color:#94a3b8;font-family:'JetBrains Mono',monospace;">
                        NS: {$default_ns1|default:'dns1.hvn.vn'}, {$default_ns2|default:'dns2.hvn.vn'}
                    </div>
                </div>
                <div class="cl-card-footer" style="text-align:right;">
                    <a href="index.php?m=mj_dns_manager&domain_id={$domain.id}" class="cl-btn cl-btn-primary" style="height:44px;font-size:13px;padding:0 16px;">
                        Quản lý DNS <i class="bi bi-arrow-right"></i>
                    </a>
                </div>
            </div>
        {foreachelse}
            <div style="grid-column:1/-1;">
                <div class="cl-alert cl-alert-info">
                    <i class="bi bi-info-circle cl-alert-icon"></i>
                    <span>Bạn chưa có domain nào được cấp phát cho dịch vụ này.</span>
                </div>
            </div>
        {/foreach}
    </div>

    <div class="cl-ns-card">
        <div>
            <div class="cl-ns-label"><i class="bi bi-info-circle"></i> Nameserver cần trỏ về:</div>
            <div class="cl-ns-value" id="ns-list">
                {$default_ns1|default:'dns1.hvn.vn'} &nbsp;&nbsp;
                {$default_ns2|default:'dns2.hvn.vn'} &nbsp;&nbsp;
                {if $default_ns3}{$default_ns3|escape:'htmlall'}{/if}
            </div>
        </div>
        <button class="cl-btn cl-btn-secondary" style="height:44px;font-size:13px;padding:0 16px;" data-mj-copy-ns="#ns-list">
            <i class="bi bi-clipboard"></i> Copy
        </button>
    </div>
</div>

{* JS logic moved to assets/js/mj-dns.js (MJ standard §8) *}

<style>
{literal}
.spin { animation: cl-spin 1.2s linear infinite; }
@keyframes cl-spin { to { transform: rotate(360deg); } }
{/literal}
</style>
