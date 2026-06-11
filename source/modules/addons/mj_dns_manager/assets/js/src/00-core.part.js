/* ====================================================================
   CORE — config, Utils, CSRF fetch guard, toast + confirm components
   ==================================================================== */

// Config: admin pages inject window.mjDnsConfig (AssetInliner); client
// pages keep the legacy per-page window.MJDNS_CONFIG blob. Read both.
var CFG = window.mjDnsConfig || {};

function mjDnsCsrf() {
    if (CFG.csrfToken) { return CFG.csrfToken; }
    if (window.MJDNS_CONFIG && window.MJDNS_CONFIG.csrfToken) { return window.MJDNS_CONFIG.csrfToken; }
    return '';
}

/* ================================================================
   UTILITIES
   ================================================================ */
var Utils = {
    esc: function (s) {
        return String(s == null ? '' : s)
            .replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;')
            .replace(/"/g, '&quot;').replace(/'/g, '&#039;');
    },

    toast: function (msg, type, title) {
        if (typeof window._mjDnsToast === 'function') {
            window._mjDnsToast(type || 'info', title || msg, title ? msg : '');
        }
    },

    confirm: function (options) {
        if (typeof window._mjDnsConfirm === 'function') { return window._mjDnsConfirm(options); }
        return Promise.resolve(window.confirm(typeof options === 'string' ? options : (options && options.message) || ''));
    },

    /**
     * fetch() wrapper [WHMCS-REQUIRED]:
     *  - X-Requested-With là routing hint, KHÔNG phải auth;
     *  - tự đính CSRF token trên mọi method khác GET/HEAD;
     *  - tự refresh token client từ res._token (WHMCS xoay tkval);
     *  - lỗi mạng nổi lên thành toast, trả {success:false}.
     */
    fetchJson: async function (url, opts) {
        opts = opts || {};
        opts.headers = Object.assign({ 'X-Requested-With': 'XMLHttpRequest' }, opts.headers || {});

        var method = (opts.method || 'GET').toUpperCase();
        if (method !== 'GET' && method !== 'HEAD') {
            var token = mjDnsCsrf();
            if (!opts.headers['X-CSRF-Token']) { opts.headers['X-CSRF-Token'] = token; }
            if (opts.body instanceof URLSearchParams && !opts.body.has('token')) { opts.body.append('token', token); }
            if (opts.body instanceof FormData && !opts.body.has('token')) { opts.body.append('token', token); }
        }

        try {
            var res = await (await fetch(url, opts)).json();
            if (res && res._token && window.MJDNS_CONFIG) { window.MJDNS_CONFIG.csrfToken = res._token; }
            return res;
        } catch (e) {
            Utils.toast('Lỗi mạng: ' + e.message, 'error');
            return { success: false, error: { code: 'NETWORK', message: e.message } };
        }
    }
};

/* ================================================================
   CSRF FETCH GUARD (belt-and-braces)
   Đính X-CSRF-Token cho MỌI fetch() mutation tới URL của module —
   kể cả code cũ gọi fetch() trực tiếp. Backend vẫn chặn nếu thiếu.
   ================================================================ */
(function () {
    if (window.__mjDnsFetchPatched) { return; }
    window.__mjDnsFetchPatched = true;
    var origFetch = window.fetch;
    if (typeof origFetch !== 'function') { return; }
    window.fetch = function (input, init) {
        try {
            var url = (typeof input === 'string') ? input : (input && input.url) || '';
            var method = ((init && init.method) || (typeof input === 'object' && input && input.method) || 'GET').toUpperCase();
            if (url.indexOf('mj_dns_manager') !== -1 && method !== 'GET' && method !== 'HEAD') {
                init = init || {};
                var h = new Headers(init.headers || (typeof input === 'object' && input ? input.headers : undefined) || {});
                if (!h.has('X-CSRF-Token')) { h.set('X-CSRF-Token', mjDnsCsrf()); }
                init.headers = h;
            }
        } catch (e) { /* fail-open vào fetch gốc — backend vẫn chặn nếu thiếu token */ }
        return origFetch.call(this, input, init);
    };
})();

/* ================================================================
   ALPINE — GLOBAL TOAST SYSTEM (moved from templates/admin/wrapper.tpl)
   ================================================================ */
document.addEventListener('alpine:init', () => {
    Alpine.data('mjDnsToastSystem', () => ({
        toasts: [],
        _nextId: 1,

        add(type, title, message, duration) {
            duration = duration || 4000;
            var id = this._nextId++;
            // Inline stroke SVGs (24×24, currentColor) — không dùng unicode/emoji làm icon.
            var svg = function (path) {
                return '<svg viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">' + path + '</svg>';
            };
            var icons = {
                success: svg('<path d="M20 6L9 17l-5-5"/>'),
                error:   svg('<line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/>'),
                warning: svg('<path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"/><line x1="12" y1="9" x2="12" y2="13"/><line x1="12" y1="17" x2="12.01" y2="17"/>'),
                info:    svg('<circle cx="12" cy="12" r="10"/><line x1="12" y1="16" x2="12" y2="12"/><line x1="12" y1="8" x2="12.01" y2="8"/>'),
            };
            this.toasts.push({ id: id, type: type, title: title, message: message || '', icon: icons[type] || icons.info, leaving: false });

            setTimeout(() => { this.dismiss(id); }, duration);
        },

        dismiss(id) {
            var t = this.toasts.find(function(x) { return x.id === id; });
            if (!t || t.leaving) return;
            t.leaving = true;
            setTimeout(() => {
                this.toasts = this.toasts.filter(function(x) { return x.id !== id; });
            }, 270);
        },

        init() {
            var self = this;
            // Expose global API
            window._mjDnsToast = function(type, title, message, duration) {
                self.add(type, title, message, duration);
            };

            // Listen to custom event (for cross-Alpine-component usage)
            window.addEventListener('mjdns:toast', function(e) {
                var d = e.detail || {};
                self.add(d.type || 'info', d.title || d.message || '', d.message || '', d.duration);
            });
        }
    }));
});

/* ================================================================
   ALPINE — GLOBAL CONFIRM MODAL (moved from templates/admin/wrapper.tpl)
   ================================================================ */
document.addEventListener('alpine:init', () => {
    Alpine.data('mjDnsConfirmModal', () => ({
        open:         false,
        title:        'Xác nhận',
        message:      '',
        variant:      'warning',   // 'danger' | 'warning' | 'info' | 'success'
        confirmLabel: 'Xác nhận',
        cancelLabel:  'Hủy',
        _resolve:     null,

        init() {
            var self = this;
            window._mjDnsConfirm = function(options) {
                if (typeof options === 'string') {
                    options = { message: options };
                }
                return new Promise(function(resolve) {
                    self.title        = options.title        || 'Xác nhận';
                    self.message      = options.message      || '';
                    self.variant      = options.variant      || 'warning';
                    self.confirmLabel = options.confirmLabel || 'Xác nhận';
                    self.cancelLabel  = options.cancelLabel  || 'Hủy';
                    self._resolve     = resolve;
                    self.open         = true;
                    // Focus confirm button after paint
                    setTimeout(function() {
                        if (self.$refs && self.$refs.confirmBtn) {
                            self.$refs.confirmBtn.focus();
                        }
                    }, 50);
                });
            };
        },

        confirm() {
            this.open = false;
            if (this._resolve) { this._resolve(true); this._resolve = null; }
        },

        cancel() {
            this.open = false;
            if (this._resolve) { this._resolve(false); this._resolve = null; }
        }
    }));
});

/* ================================================================
   BOOT
   ================================================================ */
function boot() {
    // Body class scope cho CSS ẩn content-header — chỉ trang admin module.
    if (CFG.context === 'admin') {
        document.body.classList.add('mj-dns-app-page');
    }
}
if (document.readyState === 'loading') { document.addEventListener('DOMContentLoaded', boot); }
else { boot(); }

window.mjDns = { Utils: Utils, csrf: mjDnsCsrf, cfg: CFG };
