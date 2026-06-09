{* toast.tpl — Toast notification component (Alpine) — Pure CSS, no Bootstrap *}
{literal}
<style>
.hvn-toast-wrap {
    position: fixed;
    bottom: 24px;
    right: 24px;
    z-index: 9999;
    display: flex;
    flex-direction: column;
    gap: 10px;
    pointer-events: none;
}
.hvn-toast {
    display: flex;
    align-items: flex-start;
    gap: 12px;
    min-width: 280px;
    max-width: 380px;
    padding: 14px 16px;
    border-radius: 10px;
    box-shadow: 0 4px 20px rgba(0,0,0,0.18);
    color: #fff;
    font-size: 14px;
    line-height: 1.4;
    pointer-events: all;
    transition: opacity 0.3s ease, transform 0.3s ease;
}
.hvn-toast[x-show] { transition: opacity 0.3s ease, transform 0.3s ease; }
.hvn-toast-icon { font-size: 18px; flex-shrink: 0; margin-top: 1px; }
.hvn-toast-body { flex: 1; }
.hvn-toast-title { font-weight: 700; margin-bottom: 2px; }
.hvn-toast-msg  { opacity: 0.92; }
.hvn-toast-close {
    background: none;
    border: none;
    color: rgba(255,255,255,0.8);
    cursor: pointer;
    font-size: 18px;
    line-height: 1;
    padding: 0;
    flex-shrink: 0;
    transition: color 0.15s;
}
.hvn-toast-close:hover { color: #fff; }
/* Type colors */
.hvn-toast-success { background: linear-gradient(135deg, #16a34a, #15803d); }
.hvn-toast-danger  { background: linear-gradient(135deg, #dc2626, #b91c1c); }
.hvn-toast-warning { background: linear-gradient(135deg, #d97706, #b45309); }
.hvn-toast-info    { background: linear-gradient(135deg, #0284c7, #0369a1); }
</style>

<div class="hvn-toast-wrap" x-data="{
    show: false,
    title: '',
    msg: '',
    type: 'success',
    timeout: null,
    showToastHandler(e) {
        this.title = e.detail.title || '';
        this.msg   = e.detail.msg   || '';
        this.type  = e.detail.type  || 'success';
        this.show  = true;
        if (this.timeout) clearTimeout(this.timeout);
        this.timeout = setTimeout(() => { this.show = false; }, 4000);
    }
}" @show-toast.window="showToastHandler($event)">
    <div class="hvn-toast"
         :class="'hvn-toast-' + type"
         x-show="show"
         x-transition:enter="transition"
         x-transition:enter-start="opacity-0"
         x-transition:enter-end="opacity-100"
         x-transition:leave="transition"
         x-transition:leave-start="opacity-100"
         x-transition:leave-end="opacity-0"
         style="display:none">
        <div class="hvn-toast-icon" x-text="type === 'danger' ? '✕' : (type === 'warning' ? '⚠' : (type === 'info' ? 'ℹ' : '✓'))"></div>
        <div class="hvn-toast-body">
            <div class="hvn-toast-title" x-text="title"></div>
            <div class="hvn-toast-msg" x-html="msg"></div>
        </div>
        <button class="hvn-toast-close" @click="show = false; clearTimeout(timeout);" aria-label="Đóng">×</button>
    </div>
</div>

<script>
    function showToast(title, msg, type) {
        type = type || 'success';
        window.dispatchEvent(new CustomEvent('show-toast', { detail: { title: title, msg: msg, type: type } }));
    }
</script>
{/literal}
