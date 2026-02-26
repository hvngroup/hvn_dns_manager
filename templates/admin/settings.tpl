<div class="hvn-dns-admin hvn-settings" x-data="settingsManager()">
    <div class="hvn-d-flex hvn-justify-content-between hvn-align-items-center hvn-mb-4">
        <h2><i class="bi bi-gear-fill"></i> Cài đặt Module (Settings)</h2>
        <div x-show="savedMsg" x-transition class="hvn-alert hvn-alert-success hvn-py-2 hvn-px-3 hvn-mb-0">
            <i class="bi bi-check-circle-fill hvn-me-1"></i> Đã lưu cài đặt!
        </div>
    </div>

    <div class="hvn-row">
        <!-- ── Vertical Sidebar Tabs ── -->
        <div class="hvn-col-md-3 hvn-mb-4">
            <div class="hvn-card hvn-shadow-sm hvn-border-0">
                <div class="hvn-list-group hvn-list-group-flush hvn-rounded" id="settingsLayoutTabs" role="tablist">
                    <button class="hvn-list-group-item hvn-list-group-item-action hvn-d-flex hvn-align-items-center gap-2 active" data-bs-toggle="list" data-bs-target="#pane-general" @click="activeTab='general'">
                        <i class="bi bi-sliders fs-5 hvn-text-secondary"></i> <span class="hvn-fw-bold">Chung</span>
                    </button>
                    <button class="hvn-list-group-item hvn-list-group-item-action hvn-d-flex hvn-align-items-center gap-2" data-bs-toggle="list" data-bs-target="#pane-domain-policy" @click="activeTab='domain-policy'">
                        <i class="bi bi-globe fs-5 hvn-text-secondary"></i> <span class="hvn-fw-bold">Domain Policy</span>
                    </button>
                    <button class="hvn-list-group-item hvn-list-group-item-action hvn-d-flex hvn-align-items-center gap-2" data-bs-toggle="list" data-bs-target="#pane-dns-editor" @click="activeTab='dns-editor'">
                        <i class="bi bi-pencil-square fs-5 hvn-text-secondary"></i> <span class="hvn-fw-bold">DNS Editor</span>
                    </button>
                    <button class="hvn-list-group-item hvn-list-group-item-action hvn-d-flex hvn-align-items-center gap-2" data-bs-toggle="list" data-bs-target="#pane-limits" @click="activeTab='limits'">
                        <i class="bi bi-bar-chart-steps fs-5 hvn-text-secondary"></i> <span class="hvn-fw-bold">Limits</span>
                    </button>
                    <button class="hvn-list-group-item hvn-list-group-item-action hvn-d-flex hvn-align-items-center gap-2" data-bs-toggle="list" data-bs-target="#pane-redirect" @click="activeTab='redirect'">
                        <i class="bi bi-link-45deg fs-5 hvn-text-secondary"></i> <span class="hvn-fw-bold">URL Redirect</span>
                    </button>
                    <button class="hvn-list-group-item hvn-list-group-item-action hvn-d-flex hvn-align-items-center gap-2" data-bs-toggle="list" data-bs-target="#pane-email" @click="activeTab='email'">
                        <i class="bi bi-envelope fs-5 hvn-text-secondary"></i> <span class="hvn-fw-bold">Email Forwarding</span>
                    </button>
                    <button class="hvn-list-group-item hvn-list-group-item-action hvn-d-flex hvn-align-items-center gap-2" data-bs-toggle="list" data-bs-target="#pane-ddns" @click="activeTab='ddns'">
                        <i class="bi bi-router fs-5 hvn-text-primary"></i> <span class="hvn-fw-bold">DDNS</span>
                    </button>
                    <button class="hvn-list-group-item hvn-list-group-item-action hvn-d-flex hvn-align-items-center gap-2" data-bs-toggle="list" data-bs-target="#pane-dnssec" @click="activeTab='dnssec'">
                        <i class="bi bi-shield-check fs-5 hvn-text-success"></i> <span class="hvn-fw-bold">DNSSEC</span>
                    </button>
                    <button class="hvn-list-group-item hvn-list-group-item-action hvn-d-flex hvn-align-items-center gap-2" data-bs-toggle="list" data-bs-target="#pane-ssl" @click="activeTab='ssl'">
                        <i class="bi bi-lock fs-5 hvn-text-success"></i> <span class="hvn-fw-bold">SSL / Let's Encrypt</span>
                    </button>
                    <button class="hvn-list-group-item hvn-list-group-item-action hvn-d-flex hvn-align-items-center gap-2" data-bs-toggle="list" data-bs-target="#pane-templates" @click="activeTab='templates'">
                        <i class="bi bi-files fs-5 hvn-text-secondary"></i> <span class="hvn-fw-bold">DNS Templates</span>
                    </button>
                    <button class="hvn-list-group-item hvn-list-group-item-action hvn-d-flex hvn-align-items-center gap-2" data-bs-toggle="list" data-bs-target="#pane-notify" @click="activeTab='notify'">
                        <i class="bi bi-bell fs-5 hvn-text-warning"></i> <span class="hvn-fw-bold">Notifications</span>
                    </button>
                    <button class="hvn-list-group-item hvn-list-group-item-action hvn-d-flex hvn-align-items-center gap-2" data-bs-toggle="list" data-bs-target="#pane-ui" @click="activeTab='ui'">
                        <i class="bi bi-window fs-5 hvn-text-info"></i> <span class="hvn-fw-bold">UI / Navigation</span>
                    </button>
                    <button class="hvn-list-group-item hvn-list-group-item-action hvn-d-flex hvn-align-items-center gap-2" data-bs-toggle="list" data-bs-target="#pane-perf" @click="activeTab='perf'">
                        <i class="bi bi-speedometer2 fs-5 hvn-text-secondary"></i> <span class="hvn-fw-bold">Performance</span>
                    </button>
                    <button class="hvn-list-group-item hvn-list-group-item-action hvn-d-flex hvn-align-items-center gap-2" data-bs-toggle="list" data-bs-target="#pane-queue" @click="activeTab='queue'">
                        <i class="bi bi-stack fs-5 hvn-text-secondary"></i> <span class="hvn-fw-bold">Queue &amp; Cron</span>
                    </button>
                    <button class="hvn-list-group-item hvn-list-group-item-action hvn-d-flex hvn-align-items-center gap-2" data-bs-toggle="list" data-bs-target="#pane-webhook" @click="activeTab='webhook'">
                        <i class="bi bi-send fs-5 hvn-text-danger"></i> <span class="hvn-fw-bold">Webhook &amp; Alerts</span>
                    </button>
                    <button class="hvn-list-group-item hvn-list-group-item-action hvn-d-flex hvn-align-items-center gap-2" data-bs-toggle="list" data-bs-target="#pane-security" @click="activeTab='security'">
                        <i class="bi bi-incognito fs-5 hvn-text-danger"></i> <span class="hvn-fw-bold">Security</span>
                    </button>
                    <button class="hvn-list-group-item hvn-list-group-item-action hvn-d-flex hvn-align-items-center gap-2" data-bs-toggle="list" data-bs-target="#pane-license" @click="activeTab='license'">
                        <i class="bi bi-key-fill fs-5 hvn-text-warning"></i> <span class="hvn-fw-bold">License</span>
                    </button>
                    <button class="hvn-list-group-item hvn-list-group-item-action hvn-d-flex hvn-align-items-center gap-2" data-bs-toggle="list" data-bs-target="#pane-upsell" @click="activeTab='upsell'">
                        <i class="bi bi-cart-check fs-5 hvn-text-primary"></i> <span class="hvn-fw-bold">Upsell</span>
                    </button>
                </div>
            </div>
        </div>

        <!-- ── Tab Content ── -->
        <div class="hvn-col-md-9">
            <div class="hvn-card hvn-shadow-sm hvn-border-0">
                <div class="hvn-card-body hvn-p-0">
                    <form @submit.prevent="saveSettings()" id="settingsForm">
                        <input type="hidden" name="token" value="{$token}">
                        <div class="tab-content">

                            <!-- ════════════════════════════════
                                 TAB: CHUNG (Module Core)
                                 Settings #1-8
                            ════════════════════════════════ -->
                            <div class="tab-pane fade show active hvn-p-4" id="pane-general" role="tabpanel">
                                <h5 class="hvn-border-bottom hvn-pb-2 hvn-mb-4"><i class="bi bi-sliders hvn-text-secondary"></i> Cài đặt Chung (Module Core)</h5>

                                <!-- module_enabled -->
                                <div class="hvn-mb-4 hvn-p-3 hvn-bg-light hvn-rounded hvn-d-flex hvn-justify-content-between hvn-align-items-center">
                                    <div>
                                        <div class="hvn-fw-bold">Kích hoạt Module <code class="hvn-text-muted small">module_enabled</code></div>
                                        <div class="small hvn-text-muted">Khi tắt: Client Area ẩn, Cron Worker dừng. Admin vẫn truy cập được settings.</div>
                                    </div>
                                    <div class="form-check form-switch hvn-ms-3">
                                        <input class="form-check-input" type="checkbox" id="moduleEnabled" x-model="s.module_enabled">
                                    </div>
                                </div>

                                <!-- Nameservers -->
                                <div class="hvn-mb-4">
                                    <label class="form-label hvn-fw-bold">Nameservers mặc định <code class="hvn-text-muted small">default_nameserver_1..5</code></label>
                                    <div class="hvn-row g-2">
                                        <div class="hvn-col-md-6">
                                            <div class="hvn-input-group">
                                                <span class="hvn-input-group-text small">NS1 *</span>
                                                <input type="text" class="hvn-form-control font-monospace" x-model="s.default_nameserver_1" placeholder="dns1.hvn.vn" required>
                                            </div>
                                        </div>
                                        <div class="hvn-col-md-6">
                                            <div class="hvn-input-group">
                                                <span class="hvn-input-group-text small">NS2 *</span>
                                                <input type="text" class="hvn-form-control font-monospace" x-model="s.default_nameserver_2" placeholder="dns2.hvn.vn" required>
                                            </div>
                                        </div>
                                        <div class="hvn-col-md-6">
                                            <div class="hvn-input-group">
                                                <span class="hvn-input-group-text small">NS3</span>
                                                <input type="text" class="hvn-form-control font-monospace" x-model="s.default_nameserver_3" placeholder="dns3.hvn.vn">
                                            </div>
                                        </div>
                                        <div class="hvn-col-md-6">
                                            <div class="hvn-input-group">
                                                <span class="hvn-input-group-text small">NS4</span>
                                                <input type="text" class="hvn-form-control font-monospace" x-model="s.default_nameserver_4" placeholder="(tùy chọn)">
                                            </div>
                                        </div>
                                        <div class="hvn-col-md-6">
                                            <div class="hvn-input-group">
                                                <span class="hvn-input-group-text small">NS5</span>
                                                <input type="text" class="hvn-form-control font-monospace" x-model="s.default_nameserver_5" placeholder="(tùy chọn)">
                                            </div>
                                        </div>
                                    </div>
                                    <div class="form-text">NS1 và NS2 bắt buộc. Dùng khi tạo zone mới và hiển thị hướng dẫn cho client.</div>
                                </div>

                                <!-- default_ttl -->
                                <div class="hvn-mb-3">
                                    <label class="form-label hvn-fw-bold">TTL mặc định <code class="hvn-text-muted small">default_ttl</code></label>
                                    <div class="hvn-input-group" style="max-width: 260px;">
                                        <input type="number" class="hvn-form-control" x-model="s.default_ttl" min="60" max="86400">
                                        <span class="hvn-input-group-text">giây</span>
                                    </div>
                                    <div class="form-text">Mặc định: 3600. Range: 60–86400. Áp dụng khi tạo record mới.</div>
                                </div>
                            </div>

                            <!-- ════════════════════════════════
                                 TAB: DOMAIN POLICY
                                 Settings #9-15
                            ════════════════════════════════ -->
                            <div class="tab-pane fade hvn-p-4" id="pane-domain-policy" role="tabpanel">
                                <h5 class="hvn-border-bottom hvn-pb-2 hvn-mb-4"><i class="bi bi-globe hvn-text-secondary"></i> Domain Policy — Chính sách Tên miền</h5>

                                <!-- respect_whmcs_dns -->
                                <div class="hvn-mb-4 hvn-p-3 hvn-bg-light hvn-rounded hvn-d-flex hvn-justify-content-between hvn-align-items-center">
                                    <div>
                                        <div class="hvn-fw-bold">Tuân theo cài đặt DNS Management của WHMCS <code class="hvn-text-muted small">respect_whmcs_dns</code></div>
                                        <div class="small hvn-text-muted">Khi bật: chỉ quản lý domain có "DNS Management = Enabled" trong WHMCS.</div>
                                    </div>
                                    <div class="form-check form-switch hvn-ms-3">
                                        <input class="form-check-input" type="checkbox" id="respectWhmcsDns" x-model="s.respect_whmcs_dns">
                                    </div>
                                </div>

                                <!-- disable_manage_wrong_ns -->
                                <div class="hvn-mb-4 hvn-p-3 hvn-bg-light hvn-rounded hvn-d-flex hvn-justify-content-between hvn-align-items-center">
                                    <div>
                                        <div class="hvn-fw-bold">Chặn quản lý khi NS chưa đúng <code class="hvn-text-muted small">disable_manage_wrong_ns</code></div>
                                        <div class="small hvn-text-muted">Client không thể sửa DNS nếu domain chưa trỏ NS về nameserver đúng. <span class="hvn-text-info">Mặc định: Bật.</span></div>
                                    </div>
                                    <div class="form-check form-switch hvn-ms-3">
                                        <input class="form-check-input" type="checkbox" id="disableManageWrongNs" x-model="s.disable_manage_wrong_ns">
                                    </div>
                                </div>

                                <!-- ns_check_method -->
                                <div class="hvn-mb-4">
                                    <label class="form-label hvn-fw-bold">Phương thức kiểm tra NS <code class="hvn-text-muted small">ns_check_method</code></label>
                                    <select class="hvn-form-select" x-model="s.ns_check_method" style="max-width: 360px;">
                                        <option value="dns_lookup">dns_lookup — PHP dns_get_record() realtime</option>
                                        <option value="whois">whois — WHOIS lookup</option>
                                        <option value="skip">skip — Bỏ qua kiểm tra (luôn cho phép)</option>
                                    </select>
                                </div>

                                <h6 class="hvn-fw-bold hvn-text-muted hvn-mt-4 hvn-mb-3"><i class="bi bi-gear"></i> Auto-Provisioning Actions</h6>
                                <div class="hvn-mb-3 hvn-p-3 hvn-bg-light hvn-rounded hvn-d-flex hvn-justify-content-between hvn-align-items-center">
                                    <div>
                                        <div class="hvn-fw-bold">Tạo zone TRƯỚC khi đăng ký <code class="hvn-text-muted small">create_on_preregistrar</code></div>
                                        <div class="small hvn-text-muted">Cần thiết cho .vn (VNNIC yêu cầu zone sống trước khi accept EPP register).</div>
                                    </div>
                                    <div class="form-check form-switch hvn-ms-3">
                                        <input class="form-check-input" type="checkbox" x-model="s.create_on_preregistrar">
                                    </div>
                                </div>
                                <div class="hvn-mb-3 hvn-p-3 hvn-bg-light hvn-rounded hvn-d-flex hvn-justify-content-between hvn-align-items-center">
                                    <div>
                                        <div class="hvn-fw-bold">Tạo zone SAU khi đăng ký <code class="hvn-text-muted small">create_on_registration</code></div>
                                        <div class="small hvn-text-muted">Hook AfterRegistrarRegistration. Tự bỏ qua nếu create_on_preregistrar đã tạo rồi.</div>
                                    </div>
                                    <div class="form-check form-switch hvn-ms-3">
                                        <input class="form-check-input" type="checkbox" x-model="s.create_on_registration">
                                    </div>
                                </div>
                                <div class="hvn-mb-3 hvn-p-3 hvn-bg-light hvn-rounded hvn-d-flex hvn-justify-content-between hvn-align-items-center">
                                    <div>
                                        <div class="hvn-fw-bold">Tạo zone sau khi Transfer <code class="hvn-text-muted small">create_on_transfer</code></div>
                                    </div>
                                    <div class="form-check form-switch hvn-ms-3">
                                        <input class="form-check-input" type="checkbox" x-model="s.create_on_transfer">
                                    </div>
                                </div>

                                <!-- grace_period_days -->
                                <div class="hvn-mb-3">
                                    <label class="form-label hvn-fw-bold">Số ngày giữ zone sau khi hủy <code class="hvn-text-muted small">grace_period_days</code></label>
                                    <div class="hvn-input-group" style="max-width: 200px;">
                                        <input type="number" class="hvn-form-control" x-model="s.grace_period_days" min="0" max="365">
                                        <span class="hvn-input-group-text">ngày</span>
                                    </div>
                                    <div class="form-text">0 = xóa ngay khi terminate. Range 0–365.</div>
                                </div>
                            </div>

                            <!-- ════════════════════════════════
                                 TAB: DNS EDITOR
                                 Settings #16-25 (Editor + Permissions)
                            ════════════════════════════════ -->
                            <div class="tab-pane fade hvn-p-4" id="pane-dns-editor" role="tabpanel">
                                <h5 class="hvn-border-bottom hvn-pb-2 hvn-mb-4"><i class="bi bi-pencil-square hvn-text-secondary"></i> DNS Editor &amp; Record Permissions</h5>

                                <!-- enable_dns_editor -->
                                <div class="hvn-mb-4 hvn-p-3 hvn-bg-light hvn-rounded hvn-d-flex hvn-justify-content-between hvn-align-items-center">
                                    <div>
                                        <div class="hvn-fw-bold">Bật DNS Editor <code class="hvn-text-muted small">enable_dns_editor</code></div>
                                        <div class="small hvn-text-muted">Tắt = Client không thể xem/sửa. Admin vẫn truy cập được.</div>
                                    </div>
                                    <div class="form-check form-switch hvn-ms-3">
                                        <input class="form-check-input" type="checkbox" x-model="s.enable_dns_editor">
                                    </div>
                                </div>

                                <!-- subdomain_limit -->
                                <div class="hvn-mb-4">
                                    <label class="form-label hvn-fw-bold">Giới hạn Subdomain/domain <code class="hvn-text-muted small">subdomain_limit</code></label>
                                    <div class="hvn-input-group" style="max-width: 200px;">
                                        <input type="number" class="hvn-form-control" x-model="s.subdomain_limit" min="-1">
                                        <span class="hvn-input-group-text">subdomain</span>
                                    </div>
                                    <div class="form-text">0 = unlimited. -1 = tắt tính năng subdomain.</div>
                                </div>

                                <h6 class="hvn-fw-bold hvn-mt-4 hvn-mb-3"><i class="bi bi-toggle-on"></i> Quyền Client theo Loại Record <span class="small hvn-text-muted">(Admin luôn có quyền)</span></h6>
                                <div class="hvn-card hvn-border-0 hvn-bg-light">
                                    <div class="hvn-card-body">
                                        <div class="hvn-row g-3">
                                            <div class="hvn-col-md-6 hvn-col-lg-4" x-data>
                                                <div class="hvn-d-flex hvn-justify-content-between hvn-align-items-center hvn-p-2 hvn-bg-white hvn-rounded hvn-shadow-sm">
                                                    <label class="hvn-fw-bold hvn-mb-0">A</label>
                                                    <div class="form-check form-switch hvn-mb-0">
                                                        <input class="form-check-input" type="checkbox" x-model="s.allow_modify_a">
                                                    </div>
                                                </div>
                                            </div>
                                            <div class="hvn-col-md-6 hvn-col-lg-4">
                                                <div class="hvn-d-flex hvn-justify-content-between hvn-align-items-center hvn-p-2 hvn-bg-white hvn-rounded hvn-shadow-sm">
                                                    <label class="hvn-fw-bold hvn-mb-0">AAAA</label>
                                                    <div class="form-check form-switch hvn-mb-0">
                                                        <input class="form-check-input" type="checkbox" x-model="s.allow_modify_aaaa">
                                                    </div>
                                                </div>
                                            </div>
                                            <div class="hvn-col-md-6 hvn-col-lg-4">
                                                <div class="hvn-d-flex hvn-justify-content-between hvn-align-items-center hvn-p-2 hvn-bg-white hvn-rounded hvn-shadow-sm">
                                                    <label class="hvn-fw-bold hvn-mb-0">CNAME</label>
                                                    <div class="form-check form-switch hvn-mb-0">
                                                        <input class="form-check-input" type="checkbox" x-model="s.allow_modify_cname">
                                                    </div>
                                                </div>
                                            </div>
                                            <div class="hvn-col-md-6 hvn-col-lg-4">
                                                <div class="hvn-d-flex hvn-justify-content-between hvn-align-items-center hvn-p-2 hvn-bg-white hvn-rounded hvn-shadow-sm">
                                                    <label class="hvn-fw-bold hvn-mb-0">MX</label>
                                                    <div class="form-check form-switch hvn-mb-0">
                                                        <input class="form-check-input" type="checkbox" x-model="s.allow_modify_mx">
                                                    </div>
                                                </div>
                                            </div>
                                            <div class="hvn-col-md-6 hvn-col-lg-4">
                                                <div class="hvn-d-flex hvn-justify-content-between hvn-align-items-center hvn-p-2 hvn-bg-white hvn-rounded hvn-shadow-sm">
                                                    <label class="hvn-fw-bold hvn-mb-0">TXT</label>
                                                    <div class="form-check form-switch hvn-mb-0">
                                                        <input class="form-check-input" type="checkbox" x-model="s.allow_modify_txt">
                                                    </div>
                                                </div>
                                            </div>
                                            <div class="hvn-col-md-6 hvn-col-lg-4">
                                                <div class="hvn-d-flex hvn-justify-content-between hvn-align-items-center hvn-p-2 hvn-bg-white hvn-rounded hvn-shadow-sm">
                                                    <label class="hvn-fw-bold hvn-mb-0">SRV</label>
                                                    <div class="form-check form-switch hvn-mb-0">
                                                        <input class="form-check-input" type="checkbox" x-model="s.allow_modify_srv">
                                                    </div>
                                                </div>
                                            </div>
                                            <div class="hvn-col-md-6 hvn-col-lg-4">
                                                <div class="hvn-d-flex hvn-justify-content-between hvn-align-items-center hvn-p-2 hvn-bg-white hvn-rounded hvn-shadow-sm">
                                                    <label class="hvn-fw-bold hvn-mb-0">CAA</label>
                                                    <div class="form-check form-switch hvn-mb-0">
                                                        <input class="form-check-input" type="checkbox" x-model="s.allow_modify_caa">
                                                    </div>
                                                </div>
                                            </div>
                                            <div class="hvn-col-md-6 hvn-col-lg-4">
                                                <div class="hvn-d-flex hvn-justify-content-between hvn-align-items-center hvn-p-2 hvn-bg-white hvn-rounded hvn-shadow-sm">
                                                    <label class="hvn-fw-bold hvn-mb-0 hvn-text-danger">NS <small class="hvn-fw-normal">(nguy hiểm)</small></label>
                                                    <div class="form-check form-switch hvn-mb-0">
                                                        <input class="form-check-input" type="checkbox" x-model="s.allow_modify_ns">
                                                    </div>
                                                </div>
                                            </div>
                                        </div>
                                    </div>
                                </div>
                            </div>

                            <!-- ════════════════════════════════
                                 TAB: LIMITS (Record Limits)
                                 Settings #26-33
                            ════════════════════════════════ -->
                            <div class="tab-pane fade hvn-p-4" id="pane-limits" role="tabpanel">
                                <h5 class="hvn-border-bottom hvn-pb-2 hvn-mb-1"><i class="bi bi-bar-chart-steps hvn-text-secondary"></i> Record Limits — Giới hạn Số lượng</h5>
                                <div class="small hvn-text-muted hvn-mb-4">Ưu tiên: Admin Override &gt; Quota Plan &gt; Global Settings. <code>0</code> = unlimited.</div>

                                <!-- Static record limit inputs -->

                                <div class="hvn-row g-3 hvn-mt-1">
                                    <div class="hvn-col-md-6 hvn-col-lg-4">
                                        <label class="form-label hvn-fw-bold hvn-mb-1">A <code class="hvn-text-muted small">a_record_limit</code></label>
                                        <div class="hvn-input-group"><input type="number" class="hvn-form-control" x-model="s.a_record_limit" min="-1"><span class="hvn-input-group-text">records</span></div>
                                    </div>
                                    <div class="hvn-col-md-6 hvn-col-lg-4">
                                        <label class="form-label hvn-fw-bold hvn-mb-1">AAAA <code class="hvn-text-muted small">aaaa_record_limit</code></label>
                                        <div class="hvn-input-group"><input type="number" class="hvn-form-control" x-model="s.aaaa_record_limit" min="-1"><span class="hvn-input-group-text">records</span></div>
                                    </div>
                                    <div class="hvn-col-md-6 hvn-col-lg-4">
                                        <label class="form-label hvn-fw-bold hvn-mb-1">CNAME <code class="hvn-text-muted small">cname_record_limit</code></label>
                                        <div class="hvn-input-group"><input type="number" class="hvn-form-control" x-model="s.cname_record_limit" min="-1"><span class="hvn-input-group-text">records</span></div>
                                    </div>
                                    <div class="hvn-col-md-6 hvn-col-lg-4">
                                        <label class="form-label hvn-fw-bold hvn-mb-1">MX <code class="hvn-text-muted small">mx_record_limit</code></label>
                                        <div class="hvn-input-group"><input type="number" class="hvn-form-control" x-model="s.mx_record_limit" min="-1"><span class="hvn-input-group-text">records</span></div>
                                    </div>
                                    <div class="hvn-col-md-6 hvn-col-lg-4">
                                        <label class="form-label hvn-fw-bold hvn-mb-1">TXT <code class="hvn-text-muted small">txt_record_limit</code></label>
                                        <div class="hvn-input-group"><input type="number" class="hvn-form-control" x-model="s.txt_record_limit" min="-1"><span class="hvn-input-group-text">records</span></div>
                                    </div>
                                    <div class="hvn-col-md-6 hvn-col-lg-4">
                                        <label class="form-label hvn-fw-bold hvn-mb-1">SRV <code class="hvn-text-muted small">srv_record_limit</code></label>
                                        <div class="hvn-input-group"><input type="number" class="hvn-form-control" x-model="s.srv_record_limit" min="-1"><span class="hvn-input-group-text">records</span></div>
                                    </div>
                                    <div class="hvn-col-md-6 hvn-col-lg-4">
                                        <label class="form-label hvn-fw-bold hvn-mb-1">CAA <code class="hvn-text-muted small">caa_record_limit</code></label>
                                        <div class="hvn-input-group"><input type="number" class="hvn-form-control" x-model="s.caa_record_limit" min="-1"><span class="hvn-input-group-text">records</span></div>
                                    </div>
                                    <div class="hvn-col-md-6 hvn-col-lg-4">
                                        <label class="form-label hvn-fw-bold hvn-mb-1">NS <code class="hvn-text-muted small">ns_record_limit</code></label>
                                        <div class="hvn-input-group"><input type="number" class="hvn-form-control" x-model="s.ns_record_limit" min="-1"><span class="hvn-input-group-text">records</span></div>
                                    </div>
                                </div>
                            </div>

                            <!-- ════════ TAB: URL REDIRECT #34-37 ════════ -->
                            <div class="tab-pane fade hvn-p-4" id="pane-redirect" role="tabpanel">
                                <h5 class="hvn-border-bottom hvn-pb-2 hvn-mb-4"><i class="bi bi-link-45deg hvn-text-secondary"></i> URL Redirect — Chuyển hướng</h5>

                                <div class="hvn-mb-3 hvn-p-3 hvn-bg-light hvn-rounded hvn-d-flex hvn-justify-content-between hvn-align-items-center">
                                    <div>
                                        <div class="hvn-fw-bold">Bật URL Forwarding <code class="hvn-text-muted small">enable_url_redirect</code></div>
                                        <div class="small hvn-text-muted">Cho phép client tạo chuyển hướng 301/302.</div>
                                    </div>
                                    <div class="form-check form-switch hvn-ms-3">
                                        <input class="form-check-input" type="checkbox" x-model="s.enable_url_redirect">
                                    </div>
                                </div>

                                <div class="hvn-mb-3 hvn-p-3 hvn-bg-light hvn-rounded hvn-d-flex hvn-justify-content-between hvn-align-items-center" :class="{literal}{'opacity-50': !s.enable_url_redirect}{/literal}">
                                    <div>
                                        <div class="hvn-fw-bold">Bật Masked URL Forwarding <code class="hvn-text-muted small">enable_masked_redirect</code></div>
                                        <div class="small hvn-text-muted">Cần enable_url_redirect = true. Ẩn URL đích sau iframe.</div>
                                    </div>
                                    <div class="form-check form-switch hvn-ms-3">
                                        <input class="form-check-input" type="checkbox" x-model="s.enable_masked_redirect" :disabled="!s.enable_url_redirect">
                                    </div>
                                </div>

                                <div class="hvn-mb-3" x-show="s.enable_masked_redirect">
                                    <label class="form-label hvn-fw-bold">Hash Key cho Connector <code class="hvn-text-muted small">masked_hash_key</code> <span class="hvn-text-danger">*</span></label>
                                    <input type="password" class="hvn-form-control font-monospace" x-model="s.masked_hash_key" placeholder="Tối thiểu 8 ký tự bí mật...">
                                    <div class="form-text hvn-text-danger"><i class="bi bi-exclamation-triangle"></i> BẮT BUỘC thay đổi khỏi giá trị mặc định. Lưu encrypted trong DB.</div>
                                </div>

                                <div class="hvn-mb-3">
                                    <label class="form-label hvn-fw-bold">Giới hạn Redirect/domain <code class="hvn-text-muted small">url_redirect_limit</code></label>
                                    <div class="hvn-input-group" style="max-width:200px">
                                        <input type="number" class="hvn-form-control" x-model="s.url_redirect_limit" min="0">
                                        <span class="hvn-input-group-text">redirect</span>
                                    </div>
                                    <div class="form-text">0 = unlimited.</div>
                                </div>
                            </div>

                            <!-- ════════ TAB: EMAIL FORWARDING #38-42 ════════ -->
                            <div class="tab-pane fade hvn-p-4" id="pane-email" role="tabpanel">
                                <h5 class="hvn-border-bottom hvn-pb-2 hvn-mb-4"><i class="bi bi-envelope hvn-text-secondary"></i> Email Forwarding</h5>

                                <div class="hvn-mb-3 hvn-p-3 hvn-bg-light hvn-rounded hvn-d-flex hvn-justify-content-between hvn-align-items-center">
                                    <div>
                                        <div class="hvn-fw-bold">Bật Email Forwarding <code class="hvn-text-muted small">enable_email_forwarder</code></div>
                                    </div>
                                    <div class="form-check form-switch hvn-ms-3">
                                        <input class="form-check-input" type="checkbox" x-model="s.enable_email_forwarder">
                                    </div>
                                </div>
                                <div class="hvn-mb-3 hvn-p-3 hvn-bg-light hvn-rounded hvn-d-flex hvn-justify-content-between hvn-align-items-center">
                                    <div>
                                        <div class="hvn-fw-bold">Bật Email Catch-all <code class="hvn-text-muted small">enable_email_catchall</code></div>
                                        <div class="small hvn-text-muted">Nhận tất cả email không match forwarder.</div>
                                    </div>
                                    <div class="form-check form-switch hvn-ms-3">
                                        <input class="form-check-input" type="checkbox" x-model="s.enable_email_catchall">
                                    </div>
                                </div>

                                <div class="hvn-row g-3 hvn-mb-3">
                                    <div class="hvn-col-md-6">
                                        <label class="form-label hvn-fw-bold">Giới hạn Alias/domain <code class="hvn-text-muted small">email_forwarder_limit</code></label>
                                        <div class="hvn-input-group"><input type="number" class="hvn-form-control" x-model="s.email_forwarder_limit" min="0"><span class="hvn-input-group-text">alias</span></div>
                                    </div>
                                    <div class="hvn-col-md-6">
                                        <label class="form-label hvn-fw-bold">Giới hạn Destination/domain <code class="hvn-text-muted small">email_destination_limit</code></label>
                                        <div class="hvn-input-group"><input type="number" class="hvn-form-control" x-model="s.email_destination_limit" min="0"><span class="hvn-input-group-text">địa chỉ</span></div>
                                    </div>
                                </div>

                                <div class="hvn-mb-3">
                                    <label class="form-label hvn-fw-bold">Email Template Xác minh Destination <code class="hvn-text-muted small">email_verify_template</code></label>
                                    <select class="hvn-form-select" x-model="s.email_verify_template" style="max-width: 400px;">
                                        <option value="">(Để trống = không yêu cầu xác minh)</option>
                                        <option value="dns_email_verify">DNS Email Verification</option>
                                    </select>
                                    <div class="form-text">Template WHMCS gửi xác minh email đích khi thêm forwarder mới.</div>
                                </div>
                            </div>

                            <!-- ════════ TAB: DDNS #43-49 ════════ -->
                            <div class="tab-pane fade hvn-p-4" id="pane-ddns" role="tabpanel">
                                <h5 class="hvn-border-bottom hvn-pb-2 hvn-mb-4"><i class="bi bi-router hvn-text-primary"></i> Dynamic DNS (DDNS)</h5>

                                <div class="hvn-mb-4">
                                    <label class="form-label hvn-fw-bold">Chế độ hoạt động <code class="hvn-text-muted small">ddns_mode</code> <span class="hvn-text-danger">*</span></label>
                                    <div class="hvn-card hvn-border-0 hvn-bg-light">
                                        <div class="hvn-card-body">
                                            <div class="form-check hvn-mb-2">
                                                <input class="form-check-input" type="radio" name="ddnsMode" id="ddnsOff" value="off" x-model="s.ddns_mode">
                                                <label class="form-check-label hvn-fw-bold" for="ddnsOff">Off — Tắt hoàn toàn</label>
                                            </div>
                                            <div class="form-check hvn-mb-2">
                                                <input class="form-check-input" type="radio" name="ddnsMode" id="ddnsFree" value="free" x-model="s.ddns_mode">
                                                <label class="form-check-label hvn-fw-bold" for="ddnsFree">Free — Mở theo Quota Plan</label>
                                            </div>
                                            <div class="form-check">
                                                <input class="form-check-input" type="radio" name="ddnsMode" id="ddnsPaid" value="paid" x-model="s.ddns_mode">
                                                <label class="form-check-label hvn-fw-bold hvn-text-primary" for="ddnsPaid">Paid — Yêu cầu mua Addon WHMCS</label>
                                            </div>
                                        </div>
                                    </div>
                                </div>

                                <div class="hvn-row g-3 hvn-mb-4">
                                    <div class="hvn-col-md-6">
                                        <label class="form-label hvn-fw-bold">Rate Limit/giờ <code class="hvn-text-muted small">ddns_rate_limit</code></label>
                                        <div class="hvn-input-group"><input type="number" class="hvn-form-control" x-model="s.ddns_rate_limit" min="1"><span class="hvn-input-group-text">req/h</span></div>
                                    </div>
                                    <div class="hvn-col-md-6">
                                        <label class="form-label hvn-fw-bold">Giới hạn Token/domain <code class="hvn-text-muted small">ddns_token_limit</code></label>
                                        <div class="hvn-input-group"><input type="number" class="hvn-form-control" x-model="s.ddns_token_limit" min="1"><span class="hvn-input-group-text">token</span></div>
                                    </div>
                                </div>

                                <h6 class="hvn-fw-bold hvn-mb-3"><i class="bi bi-shield-exclamation hvn-text-danger"></i> Brute Force Protection</h6>
                                <div class="hvn-mb-3 hvn-p-3 hvn-bg-light hvn-rounded hvn-d-flex hvn-justify-content-between hvn-align-items-center">
                                    <div>
                                        <div class="hvn-fw-bold">Bật Brute Force Detection <code class="hvn-text-muted small">enable_ddns_bruteforce</code></div>
                                    </div>
                                    <div class="form-check form-switch hvn-ms-3">
                                        <input class="form-check-input" type="checkbox" x-model="s.enable_ddns_bruteforce">
                                    </div>
                                </div>
                                <div class="hvn-row g-3" x-show="s.enable_ddns_bruteforce">
                                    <div class="hvn-col-md-4">
                                        <label class="form-label hvn-fw-bold small">Ngưỡng fail <code class="hvn-text-muted small">ddns_bruteforce_threshold</code></label>
                                        <div class="hvn-input-group"><input type="number" class="hvn-form-control" x-model="s.ddns_bruteforce_threshold" min="1"><span class="hvn-input-group-text">lần</span></div>
                                    </div>
                                    <div class="hvn-col-md-4">
                                        <label class="form-label hvn-fw-bold small">Cửa sổ kiểm tra <code class="hvn-text-muted small">ddns_bruteforce_window</code></label>
                                        <div class="hvn-input-group"><input type="number" class="hvn-form-control" x-model="s.ddns_bruteforce_window" min="60"><span class="hvn-input-group-text">giây</span></div>
                                    </div>
                                    <div class="hvn-col-md-4">
                                        <label class="form-label hvn-fw-bold small">Thời gian Block IP <code class="hvn-text-muted small">ddns_bruteforce_ban_duration</code></label>
                                        <div class="hvn-input-group"><input type="number" class="hvn-form-control" x-model="s.ddns_bruteforce_ban_duration" min="60"><span class="hvn-input-group-text">giây</span></div>
                                    </div>
                                </div>
                            </div>

                            <!-- ════════ TAB: DNSSEC #50-51 ════════ -->
                            <div class="tab-pane fade hvn-p-4" id="pane-dnssec" role="tabpanel">
                                <h5 class="hvn-border-bottom hvn-pb-2 hvn-mb-4"><i class="bi bi-shield-check hvn-text-success"></i> DNSSEC — Bảo mật tên miền</h5>

                                <div class="hvn-mb-4">
                                    <label class="form-label hvn-fw-bold">Chế độ hoạt động <code class="hvn-text-muted small">dnssec_mode</code> <span class="hvn-text-danger">*</span></label>
                                    <div class="hvn-card hvn-border-0 hvn-bg-light">
                                        <div class="hvn-card-body">
                                            <div class="form-check hvn-mb-3">
                                                <input class="form-check-input" type="radio" name="dnssecMode" id="dnssecOff" value="off" x-model="s.dnssec_mode">
                                                <label class="form-check-label hvn-fw-bold" for="dnssecOff">Off — Tắt hoàn toàn</label>
                                                <div class="small hvn-text-muted">Ẩn tab DNSSEC với mọi client.</div>
                                            </div>
                                            <div class="form-check hvn-mb-3">
                                                <input class="form-check-input" type="radio" name="dnssecMode" id="dnssecFree" value="free" x-model="s.dnssec_mode">
                                                <label class="form-check-label hvn-fw-bold" for="dnssecFree">Free — Miễn phí theo Quota Plan</label>
                                            </div>
                                            <div class="form-check">
                                                <input class="form-check-input" type="radio" name="dnssecMode" id="dnssecPaid" value="paid" x-model="s.dnssec_mode">
                                                <label class="form-check-label hvn-fw-bold hvn-text-primary" for="dnssecPaid">Paid — Yêu cầu Addon WHMCS</label>
                                                <div class="small hvn-text-muted">Hiển thị Upsell Card nếu client chưa mua.</div>
                                            </div>
                                        </div>
                                    </div>
                                </div>

                                <div class="hvn-mb-4 hvn-p-3 hvn-bg-light hvn-rounded hvn-d-flex hvn-justify-content-between hvn-align-items-center">
                                    <div>
                                        <div class="hvn-fw-bold">Tự động Re-sign Zone <code class="hvn-text-muted small">dnssec_auto_resign</code></div>
                                        <div class="small hvn-text-muted">Tự dispatch RESIGN_ZONE sau mỗi batch thay đổi record khi DNSSEC đang bật.</div>
                                    </div>
                                    <div class="form-check form-switch hvn-ms-3">
                                        <input class="form-check-input" type="checkbox" x-model="s.dnssec_auto_resign">
                                    </div>
                                </div>

                                <div class="hvn-alert hvn-alert-warning" x-show="s.dnssec_mode !== 'off'">
                                    <i class="bi bi-exclamation-triangle-fill"></i> Yêu cầu DA Server đã bật <code>dnssec=1</code> trong cấu hình máy chủ.
                                </div>
                            </div>

                            <!-- ════════ TAB: SSL #52-55 ════════ -->
                            <div class="tab-pane fade hvn-p-4" id="pane-ssl" role="tabpanel">
                                <h5 class="hvn-border-bottom hvn-pb-2 hvn-mb-4"><i class="bi bi-lock hvn-text-success"></i> SSL / Let's Encrypt</h5>

                                <div class="hvn-mb-3 hvn-p-3 hvn-bg-light hvn-rounded hvn-d-flex hvn-justify-content-between hvn-align-items-center">
                                    <div>
                                        <div class="hvn-fw-bold">Bật Auto-SSL cho domain mới <code class="hvn-text-muted small">enable_auto_ssl</code></div>
                                        <div class="small hvn-text-muted">Tự request Let's Encrypt khi tạo zone mới trên DA.</div>
                                    </div>
                                    <div class="form-check form-switch hvn-ms-3">
                                        <input class="form-check-input" type="checkbox" x-model="s.enable_auto_ssl">
                                    </div>
                                </div>
                                <div class="hvn-mb-3 hvn-p-3 hvn-bg-light hvn-rounded hvn-d-flex hvn-justify-content-between hvn-align-items-center">
                                    <div>
                                        <div class="hvn-fw-bold">Cho phép Client trigger SSL <code class="hvn-text-muted small">enable_client_ssl_trigger</code></div>
                                        <div class="small hvn-text-muted">Client bấm "Yêu cầu SSL" trong Client Area để request/renew thủ công.</div>
                                    </div>
                                    <div class="form-check form-switch hvn-ms-3">
                                        <input class="form-check-input" type="checkbox" x-model="s.enable_client_ssl_trigger">
                                    </div>
                                </div>
                                <div class="hvn-mb-3 hvn-p-3 hvn-bg-light hvn-rounded hvn-d-flex hvn-justify-content-between hvn-align-items-center">
                                    <div>
                                        <div class="hvn-fw-bold">Bật PHP cho domain trên DA <code class="hvn-text-muted small">enable_php_for_domain</code></div>
                                        <div class="small hvn-text-muted">Cần cho URL Forwarding connector. DA account phải có PHP privilege.</div>
                                    </div>
                                    <div class="form-check form-switch hvn-ms-3">
                                        <input class="form-check-input" type="checkbox" x-model="s.enable_php_for_domain">
                                    </div>
                                </div>
                                <div class="hvn-mb-3">
                                    <label class="form-label hvn-fw-bold">Gia hạn SSL trước (ngày) <code class="hvn-text-muted small">ssl_auto_renew_days</code></label>
                                    <div class="hvn-input-group" style="max-width:200px">
                                        <input type="number" class="hvn-form-control" x-model="s.ssl_auto_renew_days" min="1" max="30">
                                        <span class="hvn-input-group-text">ngày</span>
                                    </div>
                                    <div class="form-text">Cron ssl_checker tự gia hạn cert khi còn ≤ N ngày trước hết hạn.</div>
                                </div>
                            </div>

                            <!-- ════════ TAB: DNS TEMPLATES #56-58 ════════ -->
                            <div class="tab-pane fade hvn-p-4" id="pane-templates" role="tabpanel">
                                <h5 class="hvn-border-bottom hvn-pb-2 hvn-mb-4"><i class="bi bi-files hvn-text-secondary"></i> DNS Templates</h5>

                                <div class="hvn-mb-3 hvn-p-3 hvn-bg-light hvn-rounded hvn-d-flex hvn-justify-content-between hvn-align-items-center">
                                    <div>
                                        <div class="hvn-fw-bold">Bật DNS Templates <code class="hvn-text-muted small">enable_dns_templates</code></div>
                                        <div class="small hvn-text-muted">Cho phép client load DNS template từ danh sách Admin tạo sẵn.</div>
                                    </div>
                                    <div class="form-check form-switch hvn-ms-3">
                                        <input class="form-check-input" type="checkbox" x-model="s.enable_dns_templates">
                                    </div>
                                </div>
                                <div class="hvn-mb-3 hvn-p-3 hvn-bg-light hvn-rounded hvn-d-flex hvn-justify-content-between hvn-align-items-center">
                                    <div>
                                        <div class="hvn-fw-bold">Cho phép User tự tạo Template <code class="hvn-text-muted small">enable_user_custom_templates</code></div>
                                        <div class="small hvn-text-muted">Client tự tạo template từ zone hiện tại để dùng lại. <strong>Mặc định: Tắt.</strong></div>
                                    </div>
                                    <div class="form-check form-switch hvn-ms-3">
                                        <input class="form-check-input" type="checkbox" x-model="s.enable_user_custom_templates">
                                    </div>
                                </div>
                                <div class="hvn-mb-3" x-show="s.enable_user_custom_templates">
                                    <label class="form-label hvn-fw-bold">Giới hạn Template/user <code class="hvn-text-muted small">user_template_limit</code></label>
                                    <div class="hvn-input-group" style="max-width:200px">
                                        <input type="number" class="hvn-form-control" x-model="s.user_template_limit" min="0">
                                        <span class="hvn-input-group-text">template</span>
                                    </div>
                                </div>
                            </div>

                            <!-- ════════ TAB: NOTIFICATIONS #59-63 + #81-89 ════════ -->
                            <div class="tab-pane fade hvn-p-4" id="pane-notify" role="tabpanel">
                                <h5 class="hvn-border-bottom hvn-pb-2 hvn-mb-4"><i class="bi bi-bell hvn-text-warning"></i> Notifications</h5>

                                <h6 class="hvn-fw-bold hvn-mb-3">📧 Client Email</h6>
                                <div class="hvn-mb-3 hvn-p-3 hvn-bg-light hvn-rounded hvn-d-flex hvn-justify-content-between hvn-align-items-center">
                                    <div>
                                        <div class="hvn-fw-bold">Bật Email thông báo cho Client <code class="hvn-text-muted small">enable_client_notification</code></div>
                                    </div>
                                    <div class="form-check form-switch hvn-ms-3">
                                        <input class="form-check-input" type="checkbox" x-model="s.enable_client_notification">
                                    </div>
                                </div>
                                <div x-show="s.enable_client_notification">
                                    <div class="hvn-mb-3">
                                        <label class="form-label hvn-fw-bold">Email Template Thông báo <code class="hvn-text-muted small">notification_email_template</code></label>
                                        <select class="hvn-form-select" x-model="s.notification_email_template" style="max-width:400px">
                                            <option value="">(Chọn WHMCS Email Template)</option>
                                            <option value="dns_change_notify">DNS Change Notification</option>
                                        </select>
                                    </div>
                                    <div class="hvn-row g-2 hvn-mb-3">
                                        <div class="hvn-col-md-4">
                                            <div class="form-check">
                                                <input class="form-check-input" type="checkbox" id="notifyZoneCreate" x-model="s.notify_on_zone_create">
                                                <label class="form-check-label" for="notifyZoneCreate">Tạo Zone mới</label>
                                            </div>
                                        </div>
                                        <div class="hvn-col-md-4">
                                            <div class="form-check">
                                                <input class="form-check-input" type="checkbox" id="notifyRecordChange" x-model="s.notify_on_record_change">
                                                <label class="form-check-label" for="notifyRecordChange">Thay đổi Record</label>
                                            </div>
                                        </div>
                                        <div class="hvn-col-md-4">
                                            <div class="form-check">
                                                <input class="form-check-input" type="checkbox" id="notifyZoneDelete" x-model="s.notify_on_zone_delete">
                                                <label class="form-check-label" for="notifyZoneDelete">Xóa Zone</label>
                                            </div>
                                        </div>
                                    </div>
                                </div>

                                <h6 class="hvn-fw-bold hvn-mt-4 hvn-mb-3">🚨 Admin Alerts (Webhook)</h6>
                                <div class="hvn-mb-3 hvn-p-3 hvn-bg-light hvn-rounded hvn-d-flex hvn-justify-content-between hvn-align-items-center">
                                    <div><div class="hvn-fw-bold">Bật Telegram Alert <code class="hvn-text-muted small">enable_telegram_alert</code></div></div>
                                    <div class="form-check form-switch hvn-ms-3">
                                        <input class="form-check-input" type="checkbox" x-model="s.enable_telegram_alert">
                                    </div>
                                </div>
                                <div x-show="s.enable_telegram_alert">
                                    <div class="hvn-row g-3 hvn-mb-3">
                                        <div class="hvn-col-md-8">
                                            <label class="form-label hvn-fw-bold small">Bot Token <code class="hvn-text-muted small">telegram_bot_token</code></label>
                                            <input type="password" class="hvn-form-control font-monospace" x-model="s.telegram_bot_token" placeholder="123456:ABC-DEF...">
                                        </div>
                                        <div class="hvn-col-md-4">
                                            <label class="form-label hvn-fw-bold small">Chat ID <code class="hvn-text-muted small">telegram_chat_id</code></label>
                                            <input type="text" class="hvn-form-control font-monospace" x-model="s.telegram_chat_id" placeholder="-100123...">
                                        </div>
                                    </div>
                                </div>
                                <div class="hvn-mb-3 hvn-p-3 hvn-bg-light hvn-rounded hvn-d-flex hvn-justify-content-between hvn-align-items-center">
                                    <div><div class="hvn-fw-bold">Bật Email Alert <code class="hvn-text-muted small">enable_email_alert</code></div></div>
                                    <div class="form-check form-switch hvn-ms-3">
                                        <input class="form-check-input" type="checkbox" x-model="s.enable_email_alert">
                                    </div>
                                </div>
                                <div x-show="s.enable_email_alert">
                                    <div class="hvn-mb-3">
                                        <label class="form-label hvn-fw-bold small">Email nhận Alert <code class="hvn-text-muted small">alert_email_addresses</code></label>
                                        <input type="text" class="hvn-form-control" x-model="s.alert_email_addresses" placeholder="admin@hvn.vn, devops@hvn.vn">
                                    </div>
                                </div>
                                <div class="hvn-row g-3">
                                    <div class="hvn-col-md-4">
                                        <label class="form-label hvn-fw-bold small">Cooldown Alert (giây) <code class="hvn-text-muted small">alert_cooldown</code></label>
                                        <input type="number" class="hvn-form-control" x-model="s.alert_cooldown" min="60">
                                    </div>
                                    <div class="hvn-col-md-4">
                                        <label class="form-label hvn-fw-bold small">Ngưỡng Job Failed <code class="hvn-text-muted small">alert_failed_threshold</code></label>
                                        <input type="number" class="hvn-form-control" x-model="s.alert_failed_threshold" min="1">
                                    </div>
                                    <div class="hvn-col-md-4">
                                        <label class="form-label hvn-fw-bold small">Ngưỡng Queue Tồn đọng <code class="hvn-text-muted small">alert_queue_backlog_threshold</code></label>
                                        <input type="number" class="hvn-form-control" x-model="s.alert_queue_backlog_threshold" min="1">
                                    </div>
                                </div>
                            </div>

                            <!-- ════════ TAB: UI / NAVIGATION #64-67 ════════ -->
                            <div class="tab-pane fade hvn-p-4" id="pane-ui" role="tabpanel">
                                <h5 class="hvn-border-bottom hvn-pb-2 hvn-mb-4"><i class="bi bi-window hvn-text-info"></i> UI / Navigation</h5>

                                <div class="hvn-mb-3 hvn-p-3 hvn-bg-light hvn-rounded hvn-d-flex hvn-justify-content-between hvn-align-items-center">
                                    <div>
                                        <div class="hvn-fw-bold">Hiện link trong Domain Admin <code class="hvn-text-muted small">show_domain_service_link</code></div>
                                        <div class="small hvn-text-muted">Hiển thị link "DNS Manager" trên trang Domain Service trong Admin Area.</div>
                                    </div>
                                    <div class="form-check form-switch hvn-ms-3">
                                        <input class="form-check-input" type="checkbox" x-model="s.show_domain_service_link">
                                    </div>
                                </div>
                                <div class="hvn-mb-3 hvn-p-3 hvn-bg-light hvn-rounded hvn-d-flex hvn-justify-content-between hvn-align-items-center">
                                    <div>
                                        <div class="hvn-fw-bold">Hiện trong menu Domain (Client) <code class="hvn-text-muted small">show_under_domain_menu</code></div>
                                    </div>
                                    <div class="form-check form-switch hvn-ms-3">
                                        <input class="form-check-input" type="checkbox" x-model="s.show_under_domain_menu">
                                    </div>
                                </div>
                                <div class="hvn-mb-3 hvn-p-3 hvn-bg-light hvn-rounded hvn-d-flex hvn-justify-content-between hvn-align-items-center">
                                    <div>
                                        <div class="hvn-fw-bold">Hiện trong Sidebar Domain Detail <code class="hvn-text-muted small">show_in_domain_sidebar</code></div>
                                    </div>
                                    <div class="form-check form-switch hvn-ms-3">
                                        <input class="form-check-input" type="checkbox" x-model="s.show_in_domain_sidebar">
                                    </div>
                                </div>
                                <div class="hvn-mb-3">
                                    <label class="form-label hvn-fw-bold">Thứ tự Menu <code class="hvn-text-muted small">nav_menu_order</code></label>
                                    <input type="number" class="hvn-form-control" x-model="s.nav_menu_order" min="0" style="max-width:120px">
                                    <div class="form-text">Số nhỏ = hiện trước trong Client Area navigation.</div>
                                </div>
                            </div>

                            <!-- ════════ TAB: PERFORMANCE & CACHE #68-72, #94-96 ════════ -->
                            <div class="tab-pane fade hvn-p-4" id="pane-perf" role="tabpanel">
                                <h5 class="hvn-border-bottom hvn-pb-2 hvn-mb-4"><i class="bi bi-speedometer2 hvn-text-secondary"></i> Performance &amp; Cache</h5>

                                <div class="hvn-mb-3 hvn-p-3 hvn-bg-light hvn-rounded hvn-d-flex hvn-justify-content-between hvn-align-items-center">
                                    <div>
                                        <div class="hvn-fw-bold">Fetch từ NS mỗi lần load (Client) <code class="hvn-text-muted small">fetch_from_ns_on_load</code></div>
                                        <div class="small hvn-text-muted">true: Gọi DA API mỗi lần client mở DNS Editor (~1s). false: Dùng DB local (&lt;50ms).</div>
                                    </div>
                                    <div class="form-check form-switch hvn-ms-3">
                                        <input class="form-check-input" type="checkbox" x-model="s.fetch_from_ns_on_load">
                                    </div>
                                </div>
                                <div class="hvn-mb-3 hvn-p-3 hvn-bg-light hvn-rounded hvn-d-flex hvn-justify-content-between hvn-align-items-center">
                                    <div>
                                        <div class="hvn-fw-bold">Fetch từ NS mỗi lần load (Admin) <code class="hvn-text-muted small">fetch_from_ns_on_load_admin</code></div>
                                    </div>
                                    <div class="form-check form-switch hvn-ms-3">
                                        <input class="form-check-input" type="checkbox" x-model="s.fetch_from_ns_on_load_admin">
                                    </div>
                                </div>
                                <div class="hvn-mb-3 hvn-p-3 hvn-bg-light hvn-rounded hvn-d-flex hvn-justify-content-between hvn-align-items-center">
                                    <div>
                                        <div class="hvn-fw-bold">Chế độ Database lớn <code class="hvn-text-muted small">large_db_mode</code></div>
                                        <div class="small hvn-text-muted">Bật khi có &gt; 2000 domains. Trang Global Domains chỉ cho phép tìm kiếm, không load toàn bộ.</div>
                                    </div>
                                    <div class="form-check form-switch hvn-ms-3">
                                        <input class="form-check-input" type="checkbox" x-model="s.large_db_mode">
                                    </div>
                                </div>
                                <div class="hvn-row g-3 hvn-mb-4">
                                    <div class="hvn-col-md-6">
                                        <label class="form-label hvn-fw-bold">TTL Cache Zone <code class="hvn-text-muted small">cache_refresh_ttl</code></label>
                                        <div class="hvn-input-group"><input type="number" class="hvn-form-control" x-model="s.cache_refresh_ttl" min="60"><span class="hvn-input-group-text">giây</span></div>
                                        <div class="form-text">Chỉ áp dụng khi fetch_from_ns_on_load = false. Mặc định: 720 (12 phút).</div>
                                    </div>
                                    <div class="hvn-col-md-6">
                                        <label class="form-label hvn-fw-bold">Rate Limit Client <code class="hvn-text-muted small">client_rate_limit</code></label>
                                        <div class="hvn-input-group"><input type="number" class="hvn-form-control" x-model="s.client_rate_limit" min="1"><span class="hvn-input-group-text">thay đổi/phút</span></div>
                                    </div>
                                </div>

                                <h6 class="hvn-fw-bold hvn-mt-3 hvn-mb-3">🗂 Data Retention</h6>
                                <div class="hvn-row g-3">
                                    <div class="hvn-col-md-4">
                                        <label class="form-label hvn-fw-bold small">Snapshot/domain <code class="hvn-text-muted small">snapshot_retention_count</code></label>
                                        <div class="hvn-input-group"><input type="number" class="hvn-form-control" x-model="s.snapshot_retention_count" min="1"><span class="hvn-input-group-text">snapshot</span></div>
                                    </div>
                                    <div class="hvn-col-md-4">
                                        <label class="form-label hvn-fw-bold small">Giữ Queue COMPLETE <code class="hvn-text-muted small">queue_completed_retention_days</code></label>
                                        <div class="hvn-input-group"><input type="number" class="hvn-form-control" x-model="s.queue_completed_retention_days" min="1"><span class="hvn-input-group-text">ngày</span></div>
                                    </div>
                                    <div class="hvn-col-md-4">
                                        <label class="form-label hvn-fw-bold small hvn-text-warning">Tự động sửa Drift <code class="hvn-text-muted small">drift_auto_fix</code></label>
                                        <div class="hvn-p-2 hvn-bg-light hvn-rounded hvn-d-flex hvn-justify-content-between hvn-align-items-center">
                                            <span class="small">Push WHMCS→DA tự động</span>
                                            <div class="form-check form-switch hvn-mb-0 hvn-ms-2">
                                                <input class="form-check-input" type="checkbox" x-model="s.drift_auto_fix">
                                            </div>
                                        </div>
                                    </div>
                                </div>
                            </div>

                            <!-- ════════ TAB: QUEUE & CRON #75-80 ════════ -->
                            <div class="tab-pane fade hvn-p-4" id="pane-queue" role="tabpanel">
                                <h5 class="hvn-border-bottom hvn-pb-2 hvn-mb-4"><i class="bi bi-stack hvn-text-secondary"></i> Queue &amp; Cron Worker</h5>

                                <div class="hvn-row g-3">
                                    <div class="hvn-col-md-6">
                                        <label class="form-label hvn-fw-bold">Tần suất Cron <code class="hvn-text-muted small">cron_interval</code></label>
                                        <div class="hvn-input-group"><input type="number" class="hvn-form-control" x-model="s.cron_interval" min="10"><span class="hvn-input-group-text">giây</span></div>
                                        <div class="form-text">Mặc định: 60 (1 phút). Giảm xuống 30 → sync nhanh hơn nhưng tốn CPU.</div>
                                    </div>
                                    <div class="hvn-col-md-6">
                                        <label class="form-label hvn-fw-bold">Timeout mỗi Job <code class="hvn-text-muted small">job_timeout</code></label>
                                        <div class="hvn-input-group"><input type="number" class="hvn-form-control" x-model="s.job_timeout" min="5"><span class="hvn-input-group-text">giây</span></div>
                                    </div>
                                    <div class="hvn-col-md-6">
                                        <label class="form-label hvn-fw-bold">Số lần Retry tối đa <code class="hvn-text-muted small">max_retry_attempts</code></label>
                                        <div class="hvn-input-group"><input type="number" class="hvn-form-control" x-model="s.max_retry_attempts" min="1" max="10"><span class="hvn-input-group-text">lần</span></div>
                                        <div class="form-text">Range 1–10. Sau N lần fail → PERMANENTLY_FAILED.</div>
                                    </div>
                                    <div class="hvn-col-md-6">
                                        <label class="form-label hvn-fw-bold">Timeout Stale Lock <code class="hvn-text-muted small">stale_lock_timeout</code></label>
                                        <div class="hvn-input-group"><input type="number" class="hvn-form-control" x-model="s.stale_lock_timeout" min="60"><span class="hvn-input-group-text">giây</span></div>
                                        <div class="form-text">Job SYNCING quá N giây → coi là stale (cron crash) → recover.</div>
                                    </div>
                                    <div class="hvn-col-md-6">
                                        <label class="form-label hvn-fw-bold">Thời gian chạy tối đa Worker <code class="hvn-text-muted small">worker_max_runtime</code></label>
                                        <div class="hvn-input-group"><input type="number" class="hvn-form-control" x-model="s.worker_max_runtime" min="10"><span class="hvn-input-group-text">giây</span></div>
                                        <div class="form-text">Worker tự thoát sau N giây. Nên &lt; cron_interval.</div>
                                    </div>
                                    <div class="hvn-col-md-6">
                                        <label class="form-label hvn-fw-bold">Cửa sổ Conflict <code class="hvn-text-muted small">conflict_window</code></label>
                                        <div class="hvn-input-group"><input type="number" class="hvn-form-control" x-model="s.conflict_window" min="30"><span class="hvn-input-group-text">giây</span></div>
                                        <div class="form-text">Khoảng thời gian kiểm tra xung đột khi tạo job mới cùng record.</div>
                                    </div>
                                </div>
                            </div>

                            <!-- ════════ TAB: SECURITY #90-93 ════════ -->
                            <div class="tab-pane fade hvn-p-4" id="pane-security" role="tabpanel">
                                <h5 class="hvn-border-bottom hvn-pb-2 hvn-mb-4"><i class="bi bi-incognito hvn-text-danger"></i> Security &amp; Access Control</h5>

                                <div class="hvn-mb-3 hvn-p-3 hvn-bg-light hvn-rounded hvn-d-flex hvn-justify-content-between hvn-align-items-center">
                                    <div>
                                        <div class="hvn-fw-bold">Giới hạn Sub-accounts <code class="hvn-text-muted small">restrict_subaccounts</code></div>
                                        <div class="small hvn-text-muted">Sub-accounts chỉ quản lý DNS nếu tài khoản chính có quyền "Domain Management".</div>
                                    </div>
                                    <div class="form-check form-switch hvn-ms-3">
                                        <input class="form-check-input" type="checkbox" x-model="s.restrict_subaccounts">
                                    </div>
                                </div>

                                <div class="hvn-row g-3 hvn-mt-2">
                                    <div class="hvn-col-md-4">
                                        <label class="form-label hvn-fw-bold">Lưu Audit Trail <code class="hvn-text-muted small">audit_trail_retention_days</code></label>
                                        <div class="hvn-input-group"><input type="number" class="hvn-form-control" x-model="s.audit_trail_retention_days" min="365"><span class="hvn-input-group-text">ngày</span></div>
                                        <div class="form-text">Tối thiểu 365 ngày.</div>
                                    </div>
                                    <div class="hvn-col-md-4">
                                        <label class="form-label hvn-fw-bold">Lưu Sync Logs <code class="hvn-text-muted small">sync_log_retention_days</code></label>
                                        <div class="hvn-input-group"><input type="number" class="hvn-form-control" x-model="s.sync_log_retention_days" min="1"><span class="hvn-input-group-text">ngày</span></div>
                                    </div>
                                    <div class="hvn-col-md-4">
                                        <label class="form-label hvn-fw-bold">Lưu Record History <code class="hvn-text-muted small">record_history_retention_days</code></label>
                                        <div class="hvn-input-group"><input type="number" class="hvn-form-control" x-model="s.record_history_retention_days" min="1"><span class="hvn-input-group-text">ngày</span></div>
                                    </div>
                                </div>
                            </div>

                            <!-- ════════ TAB: LICENSE #97-104 ════════ -->
                            <div class="tab-pane fade hvn-p-4" id="pane-license" role="tabpanel">
                                <h5 class="hvn-border-bottom hvn-pb-2 hvn-mb-4"><i class="bi bi-key-fill hvn-text-warning"></i> License &amp; Bản quyền</h5>

                                <!-- Status Card -->
                                <div class="hvn-alert hvn-d-flex hvn-align-items-center hvn-mb-4"
                                     :class="s.license_status === 'Active' ? 'hvn-alert-success' : 'hvn-alert-danger'">
                                    <i class="bi hvn-me-2 hvn-fs-4" :class="s.license_status === 'Active' ? 'bi-check-circle-fill' : 'bi-x-circle-fill'"></i>
                                    <div>
                                        <div class="hvn-fw-bold">Trạng thái: <span x-text="s.license_status || 'Chưa kích hoạt'"></span></div>
                                        <div class="small">Lần kiểm tra cuối: <span x-text="s.license_last_check || '—'"></span></div>
                                        <div class="small hvn-text-danger" x-show="s.license_error_message" x-text="s.license_error_message"></div>
                                    </div>
                                </div>

                                <div class="hvn-row g-3">
                                    <div class="hvn-col-md-12">
                                        <label class="form-label hvn-fw-bold">License Key <code class="hvn-text-muted small">license_key</code></label>
                                        <input type="text" class="hvn-form-control font-monospace" x-model="s.license_key" placeholder="hvndns-XXXXXXXX">
                                    </div>
                                    <div class="hvn-col-md-12">
                                        <label class="form-label hvn-fw-bold">License Server URL <code class="hvn-text-muted small">license_server_url</code></label>
                                        <input type="url" class="hvn-form-control font-monospace" x-model="s.license_server_url" placeholder="https://license.hvn.vn/api/v1/check">
                                    </div>
                                    <div class="hvn-col-md-6">
                                        <label class="form-label hvn-fw-bold">Grace Days <code class="hvn-text-muted small">license_grace_days</code></label>
                                        <div class="hvn-input-group"><input type="number" class="hvn-form-control" x-model="s.license_grace_days" min="0"><span class="hvn-input-group-text">ngày</span></div>
                                        <div class="form-text">Số ngày tiếp tục dùng khi hết hạn hoặc không kết nối được server.</div>
                                    </div>
                                    <div class="hvn-col-md-6">
                                        <label class="form-label hvn-fw-bold">Chu kỳ kiểm tra <code class="hvn-text-muted small">license_check_interval</code></label>
                                        <div class="hvn-input-group"><input type="number" class="hvn-form-control" x-model="s.license_check_interval" min="1"><span class="hvn-input-group-text">ngày</span></div>
                                    </div>
                                </div>
                                <div class="hvn-mt-3">
                                    <button type="button" class="hvn-btn hvn-btn-outline-primary" @click="checkLicense()">
                                        <i class="bi bi-arrow-repeat"></i> Kiểm tra License ngay
                                    </button>
                                </div>
                            </div>

                            <!-- ════════ TAB: UPSELL #105-111 ════════ -->
                            <div class="tab-pane fade hvn-p-4" id="pane-upsell" role="tabpanel">
                                <h5 class="hvn-border-bottom hvn-pb-2 hvn-mb-4"><i class="bi bi-cart-check hvn-text-primary"></i> Upsell &amp; Addon</h5>

                                <div class="hvn-mb-3 hvn-p-3 hvn-bg-light hvn-rounded hvn-d-flex hvn-justify-content-between hvn-align-items-center">
                                    <div>
                                        <div class="hvn-fw-bold">Bật module Upsell <code class="hvn-text-muted small">upsell_enable</code></div>
                                        <div class="small hvn-text-muted">Hiển thị gói nâng cấp/addon DNS trong Client Area.</div>
                                    </div>
                                    <div class="form-check form-switch hvn-ms-3">
                                        <input class="form-check-input" type="checkbox" x-model="s.upsell_enable">
                                    </div>
                                </div>

                                <div x-show="s.upsell_enable">
                                    <div class="hvn-row g-3 hvn-mb-3">
                                        <div class="hvn-col-md-6">
                                            <label class="form-label hvn-fw-bold">ID Addon DNSSEC <code class="hvn-text-muted small">upsell_dnssec_addon_id</code></label>
                                            <input type="number" class="hvn-form-control" x-model="s.upsell_dnssec_addon_id" min="0" placeholder="0 = chưa cài đặt">
                                        </div>
                                        <div class="hvn-col-md-6">
                                            <label class="form-label hvn-fw-bold">ID Addon DDNS <code class="hvn-text-muted small">upsell_ddns_addon_id</code></label>
                                            <input type="number" class="hvn-form-control" x-model="s.upsell_ddns_addon_id" min="0" placeholder="0 = chưa cài đặt">
                                        </div>
                                        <div class="hvn-col-md-12">
                                            <label class="form-label hvn-fw-bold">IDs Addon Quota/Limits <code class="hvn-text-muted small">upsell_quota_addon_ids</code></label>
                                            <input type="text" class="hvn-form-control" x-model="s.upsell_quota_addon_ids" placeholder="12, 15, 22 (phân cách bằng dấu phẩy)">
                                        </div>
                                        <div class="hvn-col-md-12">
                                            <label class="form-label hvn-fw-bold">URL tùy chỉnh <code class="hvn-text-muted small">upsell_custom_url</code></label>
                                            <input type="url" class="hvn-form-control" x-model="s.upsell_custom_url" placeholder="https://... (để trống = dùng link mặc định)">
                                        </div>
                                        <div class="hvn-col-md-12">
                                            <label class="form-label hvn-fw-bold">Mô tả Upsell <code class="hvn-text-muted small">upsell_description</code></label>
                                            <textarea class="hvn-form-control" rows="3" x-model="s.upsell_description" placeholder="Nội dung tiếp thị nâng cấp..."></textarea>
                                        </div>
                                        <div class="hvn-col-md-6">
                                            <div class="hvn-p-3 hvn-bg-light hvn-rounded hvn-d-flex hvn-justify-content-between hvn-align-items-center">
                                                <div class="hvn-fw-bold small">Hiển thị giá Upsell <code class="hvn-text-muted small">upsell_display_price</code></div>
                                                <div class="form-check form-switch hvn-mb-0 hvn-ms-2">
                                                    <input class="form-check-input" type="checkbox" x-model="s.upsell_display_price">
                                                </div>
                                            </div>
                                        </div>
                                    </div>
                                </div>
                            </div>

                        </div><!-- end tab-content -->

                        <!-- ── Footer Save Button ── -->
                        <div class="hvn-p-4 hvn-bg-light hvn-border-top hvn-text-end hvn-rounded-bottom">
                            <button type="submit" class="hvn-btn hvn-btn-primary px-5" :disabled="isSaving">
                                <span x-show="!isSaving"><i class="bi bi-save"></i> Lưu tất cả cài đặt</span>
                                <span x-show="isSaving"><span class="hvn-spinner-border hvn-spinner-border-sm"></span> Đang lưu...</span>
                            </button>
                        </div>
                    </form>
                </div>
            </div>
        </div><!-- end col-md-9 -->
    </div><!-- end row -->
</div><!-- end hvn-dns-admin -->

<script>
{literal}
document.addEventListener('alpine:init', () => {
    Alpine.data('settingsManager', () => ({
        activeTab: 'general',
        isSaving: false,
        savedMsg: false,

        s: {
            // Module Core
            module_enabled: true,
            default_nameserver_1: 'dns1.hvn.vn',
            default_nameserver_2: 'dns2.hvn.vn',
            default_nameserver_3: 'dns3.hvn.vn',
            default_nameserver_4: '',
            default_nameserver_5: '',
            default_ttl: 3600,

            // Domain Policy
            respect_whmcs_dns: false,
            disable_manage_wrong_ns: true,
            ns_check_method: 'dns_lookup',
            create_on_preregistrar: true,
            create_on_registration: true,
            create_on_transfer: true,
            grace_period_days: 30,

            // DNS Editor
            enable_dns_editor: true,
            subdomain_limit: 0,
            allow_modify_a: true,
            allow_modify_aaaa: true,
            allow_modify_cname: true,
            allow_modify_mx: true,
            allow_modify_txt: true,
            allow_modify_srv: true,
            allow_modify_caa: true,
            allow_modify_ns: false,

            // Record Limits
            a_record_limit: 100,
            aaaa_record_limit: 100,
            cname_record_limit: 100,
            mx_record_limit: 100,
            txt_record_limit: 100,
            srv_record_limit: 100,
            caa_record_limit: 20,
            ns_record_limit: 10,

            // URL Redirect
            enable_url_redirect: true,
            enable_masked_redirect: true,
            masked_hash_key: '',
            url_redirect_limit: 5,

            // Email Forwarding
            enable_email_forwarder: true,
            enable_email_catchall: true,
            email_forwarder_limit: 5,
            email_destination_limit: 10,
            email_verify_template: '',

            // DDNS
            ddns_mode: 'off',
            ddns_rate_limit: 60,
            ddns_token_limit: 5,
            enable_ddns_bruteforce: true,
            ddns_bruteforce_threshold: 10,
            ddns_bruteforce_window: 3600,
            ddns_bruteforce_ban_duration: 3600,

            // DNSSEC
            dnssec_mode: 'off',
            dnssec_auto_resign: true,

            // SSL
            enable_auto_ssl: true,
            enable_client_ssl_trigger: true,
            ssl_auto_renew_days: 7,
            enable_php_for_domain: true,

            // DNS Templates
            enable_dns_templates: true,
            enable_user_custom_templates: false,
            user_template_limit: 10,

            // Client Notification
            enable_client_notification: false,
            notification_email_template: '',
            notify_on_zone_create: true,
            notify_on_record_change: true,
            notify_on_zone_delete: true,

            // Admin Alert / Webhook
            enable_telegram_alert: false,
            telegram_bot_token: '',
            telegram_chat_id: '',
            enable_email_alert: false,
            alert_email_addresses: '',
            alert_cooldown: 900,
            alert_failed_threshold: 5,
            alert_unreachable_threshold: 3,
            alert_queue_backlog_threshold: 100,

            // UI
            show_domain_service_link: true,
            show_under_domain_menu: true,
            nav_menu_order: 20,
            show_in_domain_sidebar: true,

            // Performance
            fetch_from_ns_on_load: false,
            fetch_from_ns_on_load_admin: false,
            cache_refresh_ttl: 720,
            large_db_mode: false,
            client_rate_limit: 30,

            // Data Retention
            snapshot_retention_count: 30,
            queue_completed_retention_days: 30,
            drift_auto_fix: false,

            // Queue
            cron_interval: 60,
            job_timeout: 30,
            max_retry_attempts: 5,
            stale_lock_timeout: 300,
            worker_max_runtime: 55,
            conflict_window: 180,

            // Security
            restrict_subaccounts: true,
            audit_trail_retention_days: 365,
            sync_log_retention_days: 90,
            record_history_retention_days: 90,

            // License
            license_key: '',
            license_server_url: 'https://license.hvn.vn/api/v1/check',
            license_grace_days: 3,
            license_check_interval: 7,
            license_last_check: '26/02/2026 02:00',
            license_status: 'Active',
            license_error_message: '',

            // Upsell
            upsell_enable: false,
            upsell_dnssec_addon_id: 0,
            upsell_ddns_addon_id: 0,
            upsell_quota_addon_ids: '',
            upsell_display_price: true,
            upsell_custom_url: '',
            upsell_description: '',
        },

        saveSettings() {
            this.isSaving = true;
            setTimeout(() => {
                this.isSaving = false;
                this.savedMsg = true;
                setTimeout(() => { this.savedMsg = false; }, 3000);
            }, 800);
        },

        checkLicense() {
            const btn = event.currentTarget;
            const icon = btn.querySelector('i');
            icon.classList.add('hvn-spin');
            setTimeout(() => {
                icon.classList.remove('hvn-spin');
                this.s.license_status = 'Active';
                this.s.license_last_check = new Date().toLocaleString('vi-VN');
                alert('License hợp lệ! Trạng thái: Active');
            }, 1200);
        }
    }));
});
{/literal}
</script>

<style>
{literal}
#settingsLayoutTabs .hvn-list-group-item {
    border: none;
    border-bottom: 1px solid #f1f3f5;
    padding: 0.85rem 1.25rem;
    transition: background 0.15s;
}
#settingsLayoutTabs .hvn-list-group-item.active {
    background-color: #f0f4ff;
    color: #0d6efd;
    border-left: 4px solid #0d6efd;
    font-weight: 600;
}
.hvn-spin {
    animation: hvn-spin-kf 1s linear infinite;
    display: inline-block;
}
@keyframes hvn-spin-kf { 100% { transform: rotate(360deg); } }
{/literal}
</style>
