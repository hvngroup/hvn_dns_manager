<div class="hvn-dns-client">
    <div class="card mb-4">
        <div class="card-body">
            <h3 class="card-title">DNS Management &mdash; Gói {$plan_name|default:'DNS Basic'}</h3>
            <p class="card-text">
                Trạng thái: 
                {if $service_status == 'Active'}
                    <span class="badge bg-success">Active</span>
                {else}
                    <span class="badge bg-danger">{$service_status}</span>
                {/if}
                &nbsp;&nbsp;&nbsp; Hết hạn: {$expiry_date}
            </p>
        </div>
    </div>

    <h4>Domain của bạn</h4>
    <div class="row row-cols-1 row-cols-md-2 row-cols-lg-3 g-4 mb-4">
        {foreach from=$domains item=domain}
            <div class="col">
                <div class="card h-100 {if $domain.status == 'suspended' || $domain.status == 'expired' || $domain.status == 'terminated'}opacity-50{/if}">
                    <div class="card-body">
                        <h5 class="card-title d-flex justify-content-between align-items-center">
                            <span><i class="bi bi-globe"></i> {$domain.domain}</span>
                            {if $domain.status == 'active'}
                                {if $domain.sync_status == 'syncing'}
                                    <span class="badge bg-warning text-dark"><i class="bi bi-arrow-repeat spin"></i> Syncing</span>
                                {elseif $domain.sync_status == 'pending'}
                                    <span class="badge bg-warning text-dark">Pending</span>
                                {else}
                                    <span class="badge bg-success">Active</span>
                                {/if}
                            {else}
                                <span class="badge bg-danger">{$domain.status|capitalize}</span>
                            {/if}
                        </h5>
                        <p class="card-text text-muted mb-2">{$domain.records_count} records</p>
                        <p class="card-text small mb-3">NS: {$default_ns|default:'dns1.hvn.vn, dns2.hvn.vn'}</p>
                    </div>
                    <div class="card-footer bg-transparent border-top-0 text-end">
                        <a href="index.php?m=hvn_dns_manager&domain_id={$domain.id}" class="btn btn-primary btn-sm">Quản lý DNS &rarr;</a>
                    </div>
                </div>
            </div>
        {foreachelse}
            <div class="col-12">
                <div class="alert alert-info">Bạn chưa có domain nào được cấp phát cho dịch vụ này.</div>
            </div>
        {/foreach}
    </div>

    <div class="card bg-light">
        <div class="card-body d-flex justify-content-between align-items-center">
            <div>
                <h5 class="card-title"><i class="bi bi-info-circle text-primary"></i> Nameserver cần trỏ về:</h5>
                <p class="card-text mb-0 font-monospace" id="ns-list">
                    {$default_ns1|default:'dns1.hvn.vn'} &nbsp;&nbsp; 
                    {$default_ns2|default:'dns2.hvn.vn'} &nbsp;&nbsp; 
                    {if $default_ns3}{$default_ns3}{/if}
                </p>
            </div>
            <button class="btn btn-outline-secondary btn-sm" onclick="copyToClipboard('#ns-list', this)">
                <i class="bi bi-clipboard"></i> Copy tất cả
            </button>
        </div>
    </div>
</div>

<script>
function copyToClipboard(selector, btn) {
    const text = document.querySelector(selector).innerText.replace(/\s+/g, ' ').trim();
    navigator.clipboard.writeText(text).then(() => {
        const originalText = btn.innerHTML;
        btn.innerHTML = '<i class="bi bi-check2"></i> Đã copy';
        btn.classList.replace('btn-outline-secondary', 'btn-success');
        setTimeout(() => {
            btn.innerHTML = originalText;
            btn.classList.replace('btn-success', 'btn-outline-secondary');
        }, 2000);
    });
}
</script>

<style>
.spin { animation: spin 2s linear infinite; }
@keyframes spin { 100% { transform: rotate(360deg); } }
</style>
