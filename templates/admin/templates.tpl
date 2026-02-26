<div class="hvn-dns-admin hvn-templates" x-data="templateManager()">
    <div class="hvn-d-flex hvn-justify-content-between hvn-align-items-center hvn-mb-4">
        <h2><i class="bi bi-file-text"></i> Quản lý DNS Template</h2>
        <a href="{$modulelink}&action=template_edit" class="hvn-btn hvn-btn-primary"><i class="bi bi-plus-lg"></i> Tạo Template</a>
    </div>

    <div class="hvn-row">
        <!-- Loop Template Items -->
        <template x-for="tpl in templates" :key="tpl.id">
            <div class="hvn-col-md-6 col-lhvn-g-4 hvn-mb-4">
                <div class="hvn-card hvn-shadow-sm h-100 hvn-border-0" :class="{ 'hvn-border-primary hvn-border-start': tpl.is_default, 'hvn-bg-light': !tpl.is_visible}">
                    <div class="hvn-card-body position-relative">
                        <template x-if="tpl.is_default">
                            <span class="position-absolute tohvn-p-0 end-0 badge hvn-bg-primary hvn-m-2" style="font-size: 0.7rem;"><i class="bi bi-star-fill hvn-text-warning"></i> DEFAULT</span>
                        </template>
                        
                        <h5 class="card-title hvn-text-primary hvn-fw-bold" x-text="tpl.name"></h5>
                        <p class="card-text hvn-text-muted small hvn-mb-3" style="min-height: 40px;" x-text="tpl.description"></p>
                        
                        <div class="hvn-d-flex hvn-justify-content-between hvn-align-items-center hvn-mb-3">
                            <span class="hvn-badge hvn-bg-secondary"><span x-text="tpl.records_count"></span> bản ghi</span>
                            <span class="small" :class="tpl.is_visible ? 'hvn-text-success' : 'hvn-text-danger'">
                                <i class="bi" :class="tpl.is_visible ? 'bi-eye-fill' : 'bi-eye-slash-fill'"></i>
                                <span x-text="tpl.is_visible ? 'Hiển thị Client' : 'Ẩn với Client'"></span>
                            </span>
                        </div>
                        
                        <div class="btn-group w-100">
                            <a :href="'{$modulelink}&action=template_edit&id=' + tpl.id" class="hvn-btn btn-sm hvn-btn-outline-primary"><i class="bi bi-pencil"></i> Sửa</a>
                            <button class="hvn-btn btn-sm btn-outline-secondary" @click="cloneTemplate(tpl)"><i class="bi bi-stickies"></i> Clone</button>
                            <template x-if="!tpl.is_default">
                                <button class="hvn-btn btn-sm btn-outline-success" @click="setDefault(tpl)"><i class="bi bi-star"></i> Set Default</button>
                            </template>
                            <template x-if="!tpl.is_default">
                                <button class="hvn-btn btn-sm btn-outline-danger" @click="deleteTemplate(tpl)"><i class="bi bi-trash"></i></button>
                            </template>
                        </div>
                    </div>
                </div>
            </div>
        </template>
    </div>


</div>

<script>
{literal}
document.addEventListener('alpine:init', () => {
    Alpine.data('templateManager', () => ({
        templates: [
            {
                id: 1, name: 'Basic DNS', description: 'NS + A record mặc định cho hosting', is_default: true,
                is_visible: true, records_count: 6,
                records: [
                    { type: 'NS', name: '@', value: '{literal}{{ns1}}{/literal}', ttl: 86400, prio: 0 },
                    { type: 'NS', name: '@', value: '{literal}{{ns2}}{/literal}', ttl: 86400, prio: 0 },
                    { type: 'A', name: '@', value: '{literal}{{ip}}{/literal}', ttl: 3600, prio: 0 },
                    { type: 'A', name: 'www', value: '{literal}{{ip}}{/literal}', ttl: 3600, prio: 0 },
                    { type: 'A', name: 'mail', value: '{literal}{{ip}}{/literal}', ttl: 3600, prio: 0 },
                    { type: 'MX', name: '@', value: 'mail.{literal}{{domain}}{/literal}.', ttl: 3600, prio: 10 }
                ]
            },
            {
                id: 2, name: 'Email Optimized', description: 'Bao gồm MX, SPF, DKIM, DMARC chống vào Spam', is_default: false,
                is_visible: true, records_count: 12, records: []
            },
            {
                id: 3, name: 'Internal Only', description: 'Template nội bộ cho DEV', is_default: false,
                is_visible: false, records_count: 4, records: []
            }
        ],
        cloneTemplate(tpl) {
            let clone = JSON.parse(JSON.stringify(tpl));
            clone.id = Date.now();
            clone.name = clone.name + ' (Copy)';
            clone.is_default = false;
            this.templates.push(clone);
        },

        setDefault(tpl) {
            if(confirm(`Đặt "${tpl.name}" làm mặc định cho tên miền mới?`)) {
                this.templates.forEach(t => t.is_default = false);
                tpl.is_default = true;
            }
        },

        deleteTemplate(tpl) {
            if(confirm(`Xóa vĩnh viễn template "${tpl.name}"?`)) {
                this.templates = this.templates.filter(t => t.id !== tpl.id);
            }
        }
    }));
});
{/literal}
</script>
