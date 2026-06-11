{* confirm_modal.tpl — Global confirm dialog component (Alpine) — Pure CSS, no Bootstrap *}
{literal}
<style>
/* ── Confirm Modal Overlay ── */
.mj-modal-overlay {
    position: fixed;
    inset: 0;
    background: rgba(15, 23, 42, 0.45);
    z-index: 10000;
    display: flex;
    align-items: center;
    justify-content: center;
    padding: 16px;
}
.mj-modal {
    background: #fff;
    border-radius: 8px;
    box-shadow: 0 8px 32px rgba(0,0,0,0.18);
    max-width: 460px;
    width: 100%;
    overflow: hidden;
    animation: mj-modal-in 0.18s ease;
    font-family: 'Inter', system-ui, -apple-system, sans-serif;
}
@keyframes mj-modal-in {
    from { opacity: 0; transform: translateY(-10px); }
    to   { opacity: 1; transform: translateY(0); }
}
.mj-modal-header {
    display: flex;
    align-items: center;
    justify-content: space-between;
    padding: 14px 16px;
    border-bottom: 1px solid #e9ecef;
    background: #fff;
    font-family: 'Inter', sans-serif;
}
.mj-modal-header-left {
    display: flex;
    align-items: center;
    gap: 10px;
}
.mj-modal-icon {
    width: 28px;
    height: 28px;
    border-radius: 6px;
    display: flex;
    align-items: center;
    justify-content: center;
    font-size: 15px;
    flex-shrink: 0;
}
.mj-modal-icon-danger  { background: #fee2e2; color: #dc2626; }
.mj-modal-icon-warning { background: #fef3c7; color: #d97706; }
.mj-modal-icon-info    { background: #dbeafe; color: #2563eb; }
.mj-modal-title {
    font-size: 16px;
    font-weight: 700;
    color: #202124;
    line-height: 1.3;
}
.mj-modal-close {
    width: 28px;
    height: 28px;
    border: none;
    background: transparent;
    border-radius: 6px;
    color: #94a3b8;
    cursor: pointer;
    display: flex;
    align-items: center;
    justify-content: center;
    font-size: 14px;
    transition: all 0.15s;
    flex-shrink: 0;
}
.mj-modal-close:hover { background: #f1f5f9; color: #475569; }
.mj-modal-body {
    padding: 18px 16px;
    color: #495057;
    font-size: 14px;
    line-height: 1.65;
    white-space: pre-line;
    border-bottom: 1px solid #e9ecef;
}
.mj-modal-footer {
    display: flex;
    justify-content: flex-end;
    align-items: center;
    gap: 8px;
    padding: 14px 16px;
    background: #fff;
}
.mj-modal-btn {
    height: 44px;
    padding: 8px 16px;
    border-radius: 6px;
    font-size: 13px;
    font-weight: 600;
    cursor: pointer;
    transition: all 0.15s ease;
    display: inline-flex;
    align-items: center;
    gap: 6px;
    font-family: 'Inter', sans-serif;
    line-height: 1;
    white-space: nowrap;
}
.mj-modal-btn-cancel {
    background: #fff;
    color: #495057;
    border: 1px solid #dee2e6;
}
.mj-modal-btn-cancel:hover { background: #f8f9fa; border-color: #adb5bd; }
.mj-modal-btn-ok-danger  { background: #dc2626; color: #fff; border: none; box-shadow: 0 2px 6px rgba(220,38,38,.25); }
.mj-modal-btn-ok-danger:hover  { background: #b91c1c; }
.mj-modal-btn-ok-warning { background: #d97706; color: #fff; border: none; box-shadow: 0 2px 6px rgba(217,119,6,.25); }
.mj-modal-btn-ok-warning:hover { background: #b45309; }
.mj-modal-btn-ok-info    { background: #2563eb; color: #fff; border: none; box-shadow: 0 2px 6px rgba(37,99,235,.25); }
.mj-modal-btn-ok-info:hover    { background: #1d4ed8; }
</style>

<div id="mj-confirm-modal-root" x-data="mjDnsConfirmModal()">
    <div class="mj-modal-overlay"
         x-show="show"
         x-transition:enter="transition"
         x-transition:enter-start="opacity-0"
         x-transition:enter-end="opacity-100"
         x-transition:leave="transition"
         x-transition:leave-start="opacity-100"
         x-transition:leave-end="opacity-0"
         style="display:none"
         @click.self="onCancel()">
        <div class="mj-modal" @click.stop>

            <!-- Header: icon + title + close button -->
            <div class="mj-modal-header">
                <div class="mj-modal-header-left">
                    <div class="mj-modal-icon" :class="'mj-modal-icon-' + variant">
                        <i class="bi"
                           :class="variant === 'danger' ? 'bi-trash3-fill' : (variant === 'warning' ? 'bi-exclamation-triangle-fill' : 'bi-info-circle-fill')"></i>
                    </div>
                    <h5 class="mj-modal-title" x-text="title"></h5>
                </div>
                <button class="mj-modal-close" @click="onCancel()" type="button" title="Đóng">
                    <i class="bi bi-x-lg"></i>
                </button>
            </div>

            <!-- Body -->
            <div class="mj-modal-body" x-text="msg"></div>

            <!-- Footer -->
            <div class="mj-modal-footer">
                <button class="mj-modal-btn mj-modal-btn-cancel"
                        @click="onCancel()"
                        x-text="cancelText"
                        type="button">
                </button>
                <button class="mj-modal-btn"
                        :class="'mj-modal-btn-ok-' + variant"
                        @click="onOk()"
                        x-text="okText"
                        type="button">
                </button>
            </div>

        </div>
    </div>
</div>

{* JS logic moved to assets/js/mj-dns.js (MJ standard §8) *}
{/literal}
