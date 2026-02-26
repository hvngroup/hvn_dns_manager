# AGENT.md — HVN DirectAdmin DNS Manager

> **Mục đích**: Tệp này là bộ quy tắc điều phối cho AI Agent (Claude, Cursor, Copilot, hoặc bất kỳ AI coding assistant nào) khi hỗ trợ xây dựng module **HVN - DirectAdmin DNS Manager**. Mọi code được sinh ra PHẢI tuân thủ tài liệu này.

---

## 1. THÔNG TIN DỰ ÁN

### 1.1. Tổng quan

- **Tên module**: HVN - DirectAdmin DNS Manager
- **Nền tảng**: WHMCS 8.x Addon Module
- **Ngôn ngữ**: PHP 7.4+ (target PHP 8.1)
- **Database**: MySQL/MariaDB qua WHMCS Eloquent ORM (Capsule)
- **Frontend**: Smarty Template + Bootstrap 5 + Alpine.js 3.x
- **Kiến trúc cốt lõi**: Queue-based Async (Bất đồng bộ qua hàng đợi)
- **Tiền tố DB**: `mod_hvndns_`
- **Namespace gốc**: `HvnGroup\DnsManager`

### 1.2. Tài liệu tham chiếu

Khi nhận bất kỳ yêu cầu nào liên quan đến module này, Agent PHẢI tham chiếu các tài liệu sau theo thứ tự ưu tiên:

1. **AGENT.md** (tệp này) — Quy tắc tối thượng, điều phối toàn bộ AI Agent
2. **DB_SCHEMA.md** — Database schema chi tiết, định nghĩa cột, index strategy, retention policy
3. **API_REFERENCE.md** — Tham chiếu API: DirectAdmin API, Internal Ajax API, REST API, Error Codes
4. **SETTINGS.md** — 111 Admin settings, validation rules, logic
5. **LICENSING.md** — Các quy tắc cấp phép, Feature Gate cho DNSSEC/DDNS (tham chiếu Section 6-7 khi code features này)
6. **SPEC.md** — Thông số kỹ thuật, flow diagrams, kiến trúc hệ thống
7. **EPICS.md** — User stories, acceptance criteria, issue list
8. **TEST_PLAN.md** — Kế hoạch kiểm thử, test cases, fixtures, checklists
9. **WIREFRAME.md** — Phác thảo giao diện Client Area & Admin Area
10. **PLAN.md** — Kế hoạch phát triển tổng thể, phân phase

Nếu có mâu thuẫn giữa các tài liệu, thứ tự ưu tiên là: AGENT.md > DB_SCHEMA.md > API_REFERENCE.md > SPEC.md > EPICS.md > PLAN.md.

**Quy tắc tham chiếu theo ngữ cảnh**:
- Khi code **database** (Model, migration, query) → tham chiếu **DB_SCHEMA.md** trước
- Khi code **gọi API DirectAdmin** (DAGateway, parser) → tham chiếu **API_REFERENCE.md Phần A**
- Khi code **Ajax endpoint** (Controller, response format) → tham chiếu **API_REFERENCE.md Phần B**
- Khi code **settings/config** (SettingsHelper, validation, admin settings page) → tham chiếu **SETTINGS.md**
- Khi code **permission check** (record type enable/disable, NS check) → tham chiếu **SETTINGS.md** Section 5-6
- Khi code **limits enforcement** (per-type limits, 3-layer priority) → tham chiếu **SETTINGS.md** Section 7
- Khi code **giao diện** (Smarty template, Alpine.js) → tham chiếu **WIREFRAME.md**
- Khi code **luồng xử lý** (Service, Queue, Cron) → tham chiếu **SPEC.md**
- Khi **viết test** → tham chiếu **TEST_PLAN.md** cho test cases, fixtures, naming convention
- Khi **implement issue cụ thể** → tham chiếu **EPICS.md** cho acceptance criteria

### 1.3. Cấu trúc thư mục bắt buộc

```
modules/addons/hvn_dns_manager/
├── hvn_dns_manager.php          # WHMCS entry point
├── hooks.php                     # Hook registrations
├── cron/
│   ├── queue_worker.php
│   ├── drift_detector.php
│   ├── snapshot_creator.php
│   ├── ssl_checker.php
│   └── cleanup.php
├── app/
│   ├── Controllers/
│   ├── Services/
│   │   ├── ClientFeatureResolver.php   # (Mới) Phân giải tính năng theo gói
│   │   ├── UpsellHelper.php            # (Mới) Logic hiển thị upsell/addon
│   ├── Models/
│   ├── Gateway/
│   ├── Validators/
│   ├── Migration/
│   │   └── versions/
│   └── Helpers/
├── templates/
│   ├── client/
│   └── admin/
├── assets/
│   ├── css/
│   ├── js/
│   └── img/
└── docs/
```

Agent KHÔNG ĐƯỢC tạo file hoặc thư mục ngoài cấu trúc trên trừ khi được yêu cầu rõ ràng.

### 1.4. Danh sách 19 bảng Database (Quick Reference)

Tham chiếu chi tiết tại DB_SCHEMA.md. Dưới đây là danh sách nhanh:

| # | Bảng | Model | Mục đích | Đặc biệt |
|---|------|-------|----------|-----------|
| 1 | `mod_hvndns_schema_version` | SchemaVersion | Migration tracking | — |
| 2 | `mod_hvndns_servers` | Server | DA Node configs | `password_enc` 🔒 |
| 3 | `mod_hvndns_domains` | Domain | Domain registry | Bảng pivot trung tâm |
| 4 | `mod_hvndns_records` | DnsRecord | DNS records (Source of Truth) | `is_system`, `is_locked` |
| 5 | `mod_hvndns_queue` | QueueJob | Job queue bất đồng bộ | Bảng critical nhất |
| 6 | `mod_hvndns_sync_logs` | SyncLog | Nhật ký đồng bộ | BIGINT PK, tăng nhanh |
| 7 | `mod_hvndns_audit_trail` | AuditTrail | Nhật ký kiểm toán | 🚫 APPEND-ONLY |
| 8 | `mod_hvndns_record_history` | RecordHistory | Lịch sử thay đổi record | BIGINT PK |
| 9 | `mod_hvndns_snapshots` | Snapshot | Bản sao zone | Rolling 30/domain |
| 10 | `mod_hvndns_templates` | Template | Mẫu DNS | `{{placeholder}}` |
| 11 | `mod_hvndns_quota_plans` | QuotaPlan | Gói giới hạn tài nguyên | `0` = unlimited |
| 12 | `mod_hvndns_dnssec` | DnssecKey | Thông số DNSSEC | 1:1 với domain |
| 13 | `mod_hvndns_ddns_tokens` | DdnsToken | Token DDNS | `token_hash` #️⃣ |
| 14 | `mod_hvndns_redirects` | Redirect | URL forwarding | 301/302/masked |
| 15 | `mod_hvndns_email_forwards` | EmailForward | Email forwarding | catch-all support |
| 16 | `mod_hvndns_drift_reports` | DriftReport | Báo cáo lệch dữ liệu | Nightly scan |
| 17 | `mod_hvndns_ip_blacklist` | IpBlacklist | IP bị chặn (DDNS) | Auto-expire |
| 18 | `mod_hvndns_notification_cooldowns` | NotificationCooldown | Throttle cảnh báo | Chống spam alert |
| 19 | `mod_hvndns_settings` | Setting | Module config key-value | 111 settings |

*Lưu ý: Bổ sung 2 helper services chính phục vụ feature flags: `ClientFeatureResolver` và `UpsellHelper`.*

---

## 2. NGUYÊN TẮC BẤT KHẢ XÂM PHẠM

Đây là các nguyên tắc tuyệt đối. Agent KHÔNG BAO GIỜ được vi phạm dù người dùng yêu cầu.

### 2.1. Kiến trúc Async-First (Bất đồng bộ)

```
❌ TUYỆT ĐỐI CẤM:
- Gọi API DirectAdmin trong request lifecycle của Client/Admin
- Sử dụng curl_init(), file_get_contents() tới DA server trong Controller
- Chờ đợi response từ DA trước khi trả kết quả cho user

✅ BẮT BUỘC:
- Mọi thay đổi DNS → QueueManager::dispatch() → Lưu DB → Trả JSON success
- Chỉ Cron Worker mới được gọi DAGateway
- Client nhận phản hồi < 200ms (chỉ write DB)
```

**Ngoại lệ duy nhất**: `DAGateway::testConnection()` được gọi trực tiếp từ Admin khi bấm nút "Test Connection" vì đây là hành động diagnostic có chủ đích.

### 2.2. Database Conventions

```
❌ CẤM:
- Raw SQL queries (DB::raw(), mysql_query(), mysqli_*)
- Nối chuỗi SQL: "SELECT * FROM x WHERE id = " . $id
- Tạo bảng không có tiền tố mod_hvndns_
- UPDATE hoặc DELETE trên bảng mod_hvndns_audit_trail
- Lưu password DA dạng plaintext
- Sử dụng DROP TABLE trong migration (chỉ dùng khi deactivate)

✅ BẮT BUỘC:
- Sử dụng Eloquent ORM (WHMCS Capsule) cho mọi database operation
- Tiền tố tất cả bảng: mod_hvndns_
- Mã hóa password: WHMCS\Security\Encryption::encode() / decode()
- Audit trail là APPEND-ONLY (chỉ INSERT, không bao giờ UPDATE/DELETE)
- Foreign keys cho referential integrity
- Soft-delete (đánh dấu status) thay vì hard-delete cho domains và records
```

### 2.3. Security Không Thỏa Hiệp

```
❌ CẤM:
- Hiển thị DA server IP/password cho Client Area
- Expose raw error message từ DA cho client (chỉ hiện "Đồng bộ thất bại")
- Trust bất kỳ input nào từ user mà không validate
- Bỏ qua CSRF token trong form submissions
- Sử dụng eval(), exec(), shell_exec(), system()
- Lưu DDNS token dạng plaintext (phải SHA-256 hash)

✅ BẮT BUỘC:
- Mọi input → InputSanitizer::clean() → DnsRecordValidator::validate()
- CSRF protection qua WHMCS token system
- Client Area chỉ thấy: hostname server (dns1.hvn.vn), KHÔNG thấy IP/port/credentials
- Error messages cho client phải thân thiện, không leak technical details
- Admin Area kiểm tra WHMCS admin permission trước mọi action

### 2.4. Feature Gating & License Checking

```
❌ CẤM:
- Kiểm tra tính năng bằng boolean đơn giản trước đây (VD: enable_dnssec == 1)
- Cho phép xử lý API liên quan đến DDNS/DNSSEC mà không qua feature gate

✅ BẮT BUỘC:
- Mọi logic/UI liên quan đến DNSSEC và DDNS PHẢI wrap trong FeatureGate (VD: FeatureGate::canClientUseDnssec($serviceId))
- Kiểm tra giá trị mode mới (off/free/paid) qua SettingsHelper để có luồng xử lý tương ứng
```

### 2.5. Primary-only Push

```
❌ CẤM:
- Dispatch job chỉ tới 1 server khi có nhiều server active
- Hardcode danh sách server trong code
- Giả định số lượng server cố định

✅ BẮT BUỘC:
- QueueManager::dispatch() LUÔN query ServerRegistry::getActiveServers()
- Từ N server active → Mỗi lần dispatch tạo 1 job cho Primary Server
- Status tính từ sub-job duy nhất của Primary Server
```

---

## 3. CODING CONVENTIONS

### 3.1. PHP Coding Standards

```php
<?php
/**
 * [Mô tả class/function]
 * 
 * @package HvnGroup\DnsManager
 * @since   1.0.0
 */

// Namespace bắt buộc cho mọi class trong app/
namespace HvnGroup\DnsManager\Controllers;
namespace HvnGroup\DnsManager\Services;
namespace HvnGroup\DnsManager\Models;
namespace HvnGroup\DnsManager\Gateway;
namespace HvnGroup\DnsManager\Validators;
namespace HvnGroup\DnsManager\Helpers;

// Type declarations bắt buộc cho parameters và return types
public function dispatch(
    int $domainId,
    string $action,
    array $payload,
    string $actorType = 'client',
    ?int $actorId = null,
    int $priority = 5
): string  // return batch_id

// Naming conventions
class QueueManager {}          // PascalCase cho class
public function dispatch() {}  // camelCase cho methods
$batchId = '';                 // camelCase cho variables
CONST MAX_RETRY = 5;          // UPPER_SNAKE cho constants
mod_hvndns_queue               // snake_case cho DB tables/columns

// Visibility luôn phải explicit
public function doSomething(): void {}
private function helperMethod(): array {}
protected string $tableName = '';

// KHÔNG sử dụng
var $oldStyle;          // ❌ Dùng public/private/protected
function noVisibility() // ❌ Thiếu visibility modifier
```

### 3.2. Eloquent Model Template

Mọi Model mới PHẢI tuân theo template sau. **Tham chiếu DB_SCHEMA.md** để lấy đúng `$fillable`, `$casts`, và relationships.

```php
<?php

namespace HvnGroup\DnsManager\Models;

use Illuminate\Database\Eloquent\Model;

class DnsRecord extends Model
{
    /** @var string */
    protected $table = 'mod_hvndns_records';

    /** @var bool */
    public $timestamps = true;

    const CREATED_AT = 'created_at';
    const UPDATED_AT = 'updated_at';

    /** 
     * @var array Cho phép mass assignment
     * LẤY CHÍNH XÁC từ DB_SCHEMA.md — không tự thêm/bớt cột
     */
    protected $fillable = [
        'domain_id',
        'type',
        'name',
        'value',
        'ttl',
        'priority',
        'weight',
        'port',
        'is_system',
        'is_locked',
        'pending_delete',
    ];

    /** 
     * @var array Casting types
     * Quy tắc: TINYINT(1) → 'boolean', INT UNSIGNED → 'integer', JSON → 'array'
     */
    protected $casts = [
        'domain_id'      => 'integer',
        'ttl'            => 'integer',
        'priority'       => 'integer',
        'weight'         => 'integer',
        'port'           => 'integer',
        'is_system'      => 'boolean',
        'is_locked'      => 'boolean',
        'pending_delete' => 'boolean',
    ];

    /** @var array KHÔNG BAO GIỜ xuất ra JSON/array (bảo mật) */
    protected $hidden = [];

    // ── Relationships (tham chiếu ERD trong DB_SCHEMA.md Section 1) ──

    public function domain()
    {
        return $this->belongsTo(Domain::class, 'domain_id');
    }

    public function history()
    {
        return $this->hasMany(RecordHistory::class, 'record_id')
                    ->orderBy('created_at', 'desc');
    }

    // ── Scopes ──

    public function scopeOfType($query, string $type)
    {
        return $query->where('type', $type);
    }

    public function scopeActive($query)
    {
        return $query->where('pending_delete', false);
    }

    // ── Accessors ──

    public function getFullNameAttribute(): string
    {
        if ($this->name === '@') {
            return $this->domain->domain;
        }
        return $this->name . '.' . $this->domain->domain;
    }
}
```

#### 3.2.1. Quy tắc đặc biệt theo loại Model

**Model có dữ liệu mã hóa** (`Server`):
```php
// password_enc KHÔNG nằm trong $fillable — set qua mutator
// KHÔNG BAO GIỜ đưa vào $visible hoặc toArray()
protected $hidden = ['password_enc', 'username', 'ip_address'];

public function setPasswordAttribute(string $plaintext): void
{
    $this->attributes['password_enc'] = \WHMCS\Security\Encryption::encode($plaintext);
}

public function getDecryptedPassword(): string
{
    return \WHMCS\Security\Encryption::decode($this->password_enc);
}
```

**Model APPEND-ONLY** (`AuditTrail`):
```php
// KHÔNG định nghĩa update(), delete(), save()
// KHÔNG có $fillable cho updated_at
// CHỈ có static method create()

public $timestamps = false; // Chỉ có created_at, không có updated_at

public static function log(array $data): self
{
    return static::create($data);
}

// Block mọi attempt update/delete
public function update(array $attributes = [], array $options = []): bool
{
    throw new \RuntimeException('AuditTrail is append-only. UPDATE not allowed.');
}

public function delete(): bool
{
    throw new \RuntimeException('AuditTrail is append-only. DELETE not allowed.');
}
```

**Model có hash một chiều** (`DdnsToken`):
```php
// token_hash lưu SHA-256, KHÔNG lưu plaintext
protected $hidden = ['token_hash'];

public static function generateToken(): array
{
    $plainToken = bin2hex(random_bytes(32)); // 64 chars
    $hash = hash('sha256', $plainToken);
    return ['plain' => $plainToken, 'hash' => $hash];
    // plain chỉ hiển thị 1 lần cho user, sau đó chỉ lưu hash
}

public static function findByToken(string $plainToken): ?self
{
    return static::where('token_hash', hash('sha256', $plainToken))
                  ->where('is_active', true)
                  ->first();
}
```

**Model có JSON column** (`QueueJob`, `Snapshot`, `Template`):
```php
protected $casts = [
    'payload'      => 'array',  // JSON → PHP array tự động
    'records_data' => 'array',
];
```

**Model có auto-expire** (`IpBlacklist`):
```php
public function scopeActive($query)
{
    return $query->where('blocked_until', '>', now());
}

public function scopeExpired($query)
{
    return $query->where('blocked_until', '<=', now());
}

public function getIsExpiredAttribute(): bool
{
    return $this->blocked_until <= now();
}
```

### 3.3. Controller Pattern

```php
<?php

namespace HvnGroup\DnsManager\Controllers;

/**
 * Controller KHÔNG chứa business logic.
 * Controller chỉ:
 * 1. Nhận request
 * 2. Gọi Service (business logic ở đây)
 * 3. Trả response
 */
class ClientDnsController
{
    private DnsRecordService $recordService;
    private QueueManager $queueManager;

    public function __construct()
    {
        $this->recordService = new DnsRecordService();
        $this->queueManager = new QueueManager();
    }

    /**
     * Thêm bản ghi DNS
     * Route: POST ?action=add_record
     */
    public function addRecord(array $params): array
    {
        // 1. Validate & sanitize (KHÔNG chứa logic validate ở đây)
        $validated = $this->recordService->validateAndSanitize($params);

        // 2. Business logic qua Service
        $result = $this->recordService->createRecord(
            domainId: (int) $validated['domain_id'],
            type:     $validated['type'],
            name:     $validated['name'],
            value:    $validated['value'],
            ttl:      (int) ($validated['ttl'] ?? 3600),
            priority: isset($validated['priority']) ? (int) $validated['priority'] : null,
            actorType: 'client',
            actorId:   $this->getCurrentUserId()
        );

        // 3. Return (Controller KHÔNG format HTML, chỉ trả data)
        return ResponseHelper::success([
            'record_id' => $result['record_id'],
            'batch_id'  => $result['batch_id'],
            'message'   => 'Bản ghi DNS đã được lưu và đang đồng bộ.',
        ]);
    }
}
```

### 3.4. Service Pattern (Business Logic)

```php
<?php

namespace HvnGroup\DnsManager\Services;

/**
 * Service chứa TOÀN BỘ business logic.
 * Service KHÔNG biết về HTTP request/response.
 * Service có thể được gọi từ Controller, Cron, Hook, hoặc API.
 */
class DnsRecordService
{
    private QueueManager $queue;
    private QuotaEnforcer $quota;
    private ConflictResolver $conflict;
    private AuditTrailService $audit;

    /**
     * Tạo bản ghi DNS mới
     * 
     * Flow: Validate → Quota check → Conflict check → Save record 
     *       → Dispatch queue → Write audit → Return
     * 
     * @throws ValidationException
     * @throws QuotaExceededException
     */
    public function createRecord(
        int $domainId,
        string $type,
        string $name,
        string $value,
        int $ttl = 3600,
        ?int $priority = null,
        string $actorType = 'client',
        ?int $actorId = null
    ): array {
        // 1. Validate DNS record format
        DnsRecordValidator::validate($type, $name, $value, $ttl, $priority);

        // 2. Validate conflicts (CNAME vs A, duplicate MX priority, etc.)
        ConflictValidator::checkRecordConflict($domainId, $type, $name);

        // 3. Check quota
        $this->quota->enforceRecordLimit($domainId);

        // 4. Check queue conflict (same record PENDING?)
        $this->conflict->checkAndResolve($domainId, $type, $name, $actorType);

        // 5. Save to local DB (Source of Truth)
        $record = DnsRecord::create([
            'domain_id' => $domainId,
            'type'      => $type,
            'name'      => $name,
            'value'     => $value,
            'ttl'       => $ttl,
            'priority'  => $priority,
        ]);

        // 6. Dispatch to queue (Primary-only Push)
        $batchId = $this->queue->dispatch(
            domainId:  $domainId,
            action:    'ADD_RECORD',
            payload:   [
                'record_id' => $record->id,
                'type'      => $type,
                'name'      => $name,
                'value'     => $value,
                'ttl'       => $ttl,
                'priority'  => $priority,
            ],
            actorType: $actorType,
            actorId:   $actorId,
            priority:  $actorType === 'admin' ? 1 : 5
        );

        // 7. Write audit trail
        $this->audit->log(
            actorType:  $actorType,
            actorId:    $actorId,
            domainId:   $domainId,
            action:     'add_record',
            targetType: 'record',
            targetId:   $record->id,
            newValue:   $record->toArray()
        );

        return [
            'record_id' => $record->id,
            'batch_id'  => $batchId,
        ];
    }
}
```

### 3.5. Response Format chuẩn

Mọi Ajax response PHẢI tuân theo format sau:

```php
// Success
{
    "success": true,
    "data": {
        "record_id": 456,
        "batch_id": "abc-123-def"
    },
    "message": "Bản ghi DNS đã được lưu và đang đồng bộ."
}

// Error (validation)
{
    "success": false,
    "error": {
        "code": "VALIDATION_ERROR",
        "message": "Địa chỉ IP không hợp lệ.",
        "field": "value"
    }
}

// Error (quota)
{
    "success": false,
    "error": {
        "code": "QUOTA_EXCEEDED",
        "message": "Bạn đã đạt giới hạn 50 bản ghi. Vui lòng nâng cấp gói dịch vụ.",
        "current": 50,
        "limit": 50,
        "upgrade_url": "/cart.php?a=add&pid=12"
    }
}

// Error (server - KHÔNG leak technical details cho client)
{
    "success": false,
    "error": {
        "code": "INTERNAL_ERROR",
        "message": "Đã xảy ra lỗi. Vui lòng thử lại sau."
    }
}
```

### 3.6. Smarty Template Conventions

#### Quy tắc Delimiter — Tránh conflict Smarty vs JS/Alpine/CSS

Smarty engine parse TẤT CẢ `{ }` thành Smarty tags. Khi viết template có chứa JavaScript, Alpine.js, hoặc CSS inline → PHẢI bọc `{literal}...{/literal}`.

**NGUYÊN TẮC: Khi nào cần `{literal}`?**

| Context | Cần `{literal}`? | Ví dụ |
|---------|:---:|--------|
| Smarty variable | ❌ | `{$domain.name}` |
| Smarty function | ❌ | `{include file="..."}` |
| Smarty modifier | ❌ | `{$var\|escape:'htmlall'}` |
| `<script>` block | ✅ BẮT BUỘC | `<script>{literal}...{/literal}</script>` |
| `<style>` block | ✅ BẮT BUỘC | `<style>{literal}...{/literal}</style>` |
| Alpine.js `x-data` | ✅ BẮT BUỘC | `x-data="{literal}{ open: false }{/literal}"` |
| Alpine.js `:class` object | ✅ BẮT BUỘC | `:class="{literal}{ 'active': val }{/literal}"` |
| Alpine.js `x-on` simple | ❌ (no curly) | `x-on:click="open = true"` |
| Alpine.js `@click` simple | ❌ (no curly) | `@click="count++"` |
| CSS inline `style="..."` | ❌ (no curly) | `style="color: red"` |
| HTML attribute no braces | ❌ | `class="btn btn-primary"` |

**CẤM tuyệt đối:**
```smarty
{* ❌ SAI — Smarty parse { open: false } thành Smarty tag → LỖI *}
<div x-data="{ open: false }"></div>
<script>
    const obj = { key: 'value' };
</script>
<style>
    .card { padding: 10px; }
</style>

{* ✅ ĐÚNG — Bọc {literal} cho mọi JS/Alpine object/CSS block *}
<div x-data="{literal}{ open: false }{/literal}"></div>
<script>
{literal}
    const obj = { key: 'value' };
{/literal}
</script>
<style>
{literal}
    .card { padding: 10px; }
{/literal}
</style>
```

**Kỹ thuật kết hợp Smarty variable TRONG block `{literal}`:**

Khi cần truyền Smarty variable vào JavaScript, KHÔNG đặt Smarty variable bên trong `{literal}` (sẽ không được parse). Thay vào đó:

```smarty
{* ── Cách 1: Data attribute — RECOMMEND ── *}
<div id="dns-editor" data-domain-id="{$domain.id}" data-domain-name="{$domain.name|escape:'htmlall'}" data-base-url="{$moduleUrl}"></div>
<script>
{literal}
    // Đọc data từ HTML attribute
    const el = document.getElementById('dns-editor');
    const domainId = el.dataset.domainId;
    const domainName = el.dataset.domainName;
    const baseUrl = el.dataset.baseUrl;
{/literal}
</script>

{* ── Cách 2: Script variable trước {literal} block ── *}
<script>
    var HVNDNS_CONFIG = {
        domainId: {$domain.id},
        domainName: '{$domain.name|escape:'javascript'}',
        baseUrl: '{$moduleUrl}',
        csrfToken: '{$token}'
    };
</script>
<script>
{literal}
    // Sử dụng HVNDNS_CONFIG.domainId trong code
    console.log(HVNDNS_CONFIG.domainId);
{/literal}
</script>

{* ── Cách 3: Alpine.js x-data đọc từ attribute ── *}
<div x-data="dnsEditor()" data-config="{$configJson|escape:'htmlall'}"></div>
<script>
{literal}
    function dnsEditor() {
        return {
            config: JSON.parse(this.$el.dataset.config),
            init() {
                console.log(this.config.domainId);
            }
        };
    }
{/literal}
</script>
```

**Quy tắc Smarty modifiers & escaping:**
```smarty
{* ── HTML context (mặc định) ── *}
{$record.value|escape:'htmlall'}

{* ── JavaScript context ── *}
var name = '{$domain.name|escape:'javascript'}';

{* ── URL context ── *}
<a href="?action=edit&id={$record.id|escape:'url'}">Sửa</a>

{* ── Không escape (trusted data, đã sanitize server-side) ── *}
{$trustedHtml nofilter}
{* ⚠️ CHỈ dùng khi data đã sanitize 100% ở Controller *}
```

**Cấu trúc template file chuẩn:**
```smarty
{* 
 * File: templates/client/dns_editor.tpl
 * Màn hình: CL-02 DNS Editor
 * Variables từ Controller:
 *   $domain      - Object domain
 *   $records     - Array of records
 *   $quota       - {current: int, limit: int}
 *   $moduleUrl   - Base URL module assets
 *   $token       - CSRF token
 *}

{* ── 1. Include CSS module (không cần {literal} vì file external) ── *}
<link rel="stylesheet" href="{$moduleUrl}/assets/css/hvndns.css">

{* ── 2. HTML markup với Smarty variables ── *}
<div x-data="dnsEditor()">
    <h2>{$domain.domain|escape:'htmlall'}</h2>
    
    {* Include partial *}
    {include file="client/partials/quota_bar.tpl" current=$quota.current limit=$quota.limit}
    
    {* Loop records *}
    {foreach from=$records item=record}
        <div class="record-row">
            <span>{$record.type|escape:'htmlall'}</span>
            <span>{$record.name|escape:'htmlall'}</span>
            <span>{$record.value|escape:'htmlall'}</span>
        </div>
    {/foreach}
</div>

{* ── 3. Truyền data cho JS qua config object ── *}
<script>
    var HVNDNS = {
        domainId: {$domain.id|intval},
        baseUrl: '{$moduleUrl|escape:'javascript'}',
        token: '{$token|escape:'javascript'}',
        records: {$recordsJson nofilter}
    };
</script>

{* ── 4. Alpine.js / JS code bọc {literal} ── *}
<script>
{literal}
    function dnsEditor() {
        return {
            records: HVNDNS.records,
            loading: false,
            
            async addRecord(formData) {
                this.loading = true;
                const res = await fetch(HVNDNS.baseUrl + '&action=add_record', {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json',
                        'X-CSRF-Token': HVNDNS.token
                    },
                    body: JSON.stringify(formData)
                });
                const data = await res.json();
                this.loading = false;
            }
        };
    }
{/literal}
</script>
```

**Include & Partials:**
```smarty
{* ── Include partial với params ── *}
{include file="client/partials/sync_badge.tpl" status=$record.sync_status}

{* ── Partial file: partials/sync_badge.tpl ── *}
{if $status == 'complete'}
    <span class="badge bg-success">Live</span>
{elseif $status == 'syncing'}
    <span class="badge bg-warning">
         <i class="bi bi-arrow-repeat spin"></i> Syncing
    </span>
{elseif $status == 'pending'}
    <span class="badge bg-secondary">Pending</span>
{elseif $status == 'failed'}
    <span class="badge bg-danger">Failed</span>
{/if}

{* ── Conditional include ── *}
{if $tabs.dnssec}
    {include file="client/partials/tab_dnssec.tpl"}
{/if}
```

**Smarty functions thường dùng:**
```smarty
{* Biến *}
{$variable}
{$array.key}
{$object->property}

{* Gán biến *}
{assign var="fullName" value="{$record.name}.{$domain.domain}"}

{* Điều kiện *}
{if $record.is_system}...{elseif $record.is_locked}...{else}...{/if}

{* Vòng lặp *}
{foreach from=$records item=record key=index}
    {$record.name} — Index: {$index}
    {if $record@first}Đầu tiên{/if}
    {if $record@last}Cuối cùng{/if}
{foreachelse}
    Không có bản ghi nào.
{/foreach}

{* Modifiers *}
{$var|escape:'htmlall'}          — HTML escape
{$var|escape:'javascript'}       — JS string escape  
{$var|escape:'url'}              — URL encode
{$var|truncate:50:'...'}         — Cắt chuỗi
{$var|date_format:'%d/%m/%Y'}    — Format ngày
{$var|default:'N/A'}             — Giá trị mặc định
{$var|intval}                    — Cast integer
{$var|count}                     — Đếm array
{$var|upper}                     — Uppercase
{$var|lower}                     — Lowercase
{$var|nl2br}                     — Newline → <br>
{$var|strip_tags}                — Xóa HTML tags
```

### 3.7. Logging Convention

```php
// SỬ DỤNG Monolog qua WHMCS
use WHMCS\Log\Activity as ActivityLog;

// Log levels và khi nào dùng:

// INFO — Sự kiện quan trọng bình thường
$this->logger->info('Queue dispatched', [
    'batch_id'  => $batchId,
    'domain'    => $domain,
    'action'    => $action,
    'servers'   => count($activeServers),
]);

// WARNING — Có vấn đề nhưng hệ thống vẫn hoạt động
$this->logger->warning('Job retry scheduled', [
    'job_id'    => $job->id,
    'attempt'   => $job->attempts,
    'next_retry'=> $job->next_retry_at,
    'error'     => $errorMessage,
]);

// ERROR — Lỗi cần chú ý
$this->logger->error('DA connection failed', [
    'server'    => $server->hostname,
    'error'     => $exception->getMessage(),
    'duration'  => $durationMs,
]);

// ❌ KHÔNG BAO GIỜ log:
// - DA server passwords (dù đã mã hóa)
// - Full request body chứa credentials
// - User session tokens
// - DDNS tokens (chỉ log hash prefix: "token:abc1**")
```

---

## 4. QUY TẮC SINH CODE

### 4.1. Khi nhận yêu cầu tạo file mới

Agent PHẢI tuân thủ checklist sau trước khi sinh code:

```
□ File thuộc đúng thư mục trong cấu trúc đã định nghĩa (Section 1.3)?
□ Namespace đúng theo cây thư mục?
□ Có tham chiếu đúng tài liệu cho phần đang code?
   - Database → DB_SCHEMA.md
   - DA API call → API_REFERENCE.md Phần A
   - Ajax endpoint → API_REFERENCE.md Phần B
   - Template/UI → WIREFRAME.md
   - Business logic → SPEC.md
□ Class/function có PHPDoc đầy đủ?
□ Type declarations cho parameters và return types?
□ Không vi phạm bất kỳ nguyên tắc nào trong Section 2?
□ Error handling đầy đủ (try-catch, validation)?
□ Logging ở đúng level?
□ Nếu có DB operation → dùng Eloquent, không raw SQL?
□ Nếu có user input → qua Sanitizer + Validator?
□ Nếu có thay đổi DNS → đi qua QueueManager::dispatch()?
□ Nếu hiển thị cho Client → không leak server details?
□ Nếu gọi DA API → tuân thủ format trong API_REFERENCE.md (arression, trailing dot, TXT quoting)?
□ Nếu trả JSON response → tuân thủ format chuẩn (API_REFERENCE.md B5)?
□ Nếu code có thể test → test case tương ứng đã có trong TEST_PLAN.md?
```

### 4.2. Khi nhận yêu cầu sửa code

```
□ Đọc code hiện tại và hiểu context trước khi sửa
□ Giữ nguyên code conventions đã có trong file
□ Không refactor ngoài phạm vi yêu cầu (trừ khi được hỏi)
□ Nếu phát hiện bug/vi phạm convention → CẢNH BÁO người dùng trước khi sửa
□ Mọi thay đổi phải backward compatible (không break existing data)
□ Cập nhật migration version nếu thay đổi DB schema
```

### 4.3. Khi tạo Database Migration

```php
<?php
// File: app/Migration/versions/v1_0_0.php

namespace HvnGroup\DnsManager\Migration;

use Illuminate\Database\Capsule\Manager as Capsule;

class v1_0_0
{
    /** @var string Mô tả migration */
    public static string $description = 'Initial schema - core tables';

    /**
     * LUÔN kiểm tra table exists trước khi tạo (idempotent)
     */
    public static function up(): void
    {
        $schema = Capsule::schema();

        if (!$schema->hasTable('mod_hvndns_servers')) {
            $schema->create('mod_hvndns_servers', function ($table) {
                $table->increments('id');
                $table->string('hostname', 255);
                $table->string('ip_address', 45);
                // ... (theo SPEC.md Section 4.2)
                $table->timestamps();
                
                $table->index('is_active', 'idx_active');
            });
        }

        // Tiếp tục cho các bảng khác...
    }

    /**
     * KHÔNG DROP TABLE trong down() cho production
     * Chỉ disable/flag, không xóa data
     */
    public static function down(): void
    {
        // Cân nhắc kỹ trước khi implement
        // Thường chỉ cần cho development
    }
}
```

### 4.4. Khi tạo Smarty Template

```smarty
{* 
 * File: templates/client/dns_editor.tpl
 * Mô tả: Giao diện DNS Editor cho Client Area
 * 
 * Variables từ Controller:
 *   $domain      - Domain object
 *   $records     - Array of DnsRecord
 *   $syncStatus  - Sync status của Primary Server
 *   $quota       - {current: int, limit: int}
 *}

{* ── LUÔN include module CSS/JS ── *}
<link rel="stylesheet" href="{$moduleUrl}/assets/css/hvndns.css">

{* ── Alpine.js cho reactivity ── *}
<div x-data="dnsEditor()" x-init="init()">
    
    {* ── KHÔNG BAO GIỜ hiển thị server IP/credentials ── *}
    {* ── Chỉ hiện hostname: dns1.hvn.vn ── *}
    
    {* ── Escape mọi dynamic data ── *}
    <h3>{$domain.domain|escape:'htmlall'}</h3>
    
    {* ── Form PHẢI có CSRF token ── *}
    <input type="hidden" name="token" value="{$token}">
    
</div>

<script src="{$moduleUrl}/assets/js/dns-editor.js"></script>
```

### 4.5. Khi tạo Alpine.js Component

```javascript
/**
 * DNS Editor Alpine.js Component
 * File: assets/js/dns-editor.js
 * 
 * Conventions:
 * - Tất cả API calls qua fetch() với JSON
 * - Error handling cho mọi fetch call
 * - Loading states cho mọi action
 * - Không dùng jQuery (chỉ vanilla JS + Alpine)
 */
function dnsEditor() {
    return {
        records: [],
        loading: false,
        saving: false,
        error: null,
        pollInterval: null,
        
        // ── Khởi tạo ──
        async init() {
            await this.loadRecords();
        },
        
        // ── Load records ──
        async loadRecords() {
            this.loading = true;
            try {
                const res = await fetch(`${moduleBaseUrl}&action=get_records&domain_id=${domainId}`);
                const data = await res.json();
                if (data.success) {
                    this.records = data.data.records;
                } else {
                    this.error = data.error.message;
                }
            } catch (e) {
                this.error = 'Không thể tải dữ liệu. Vui lòng thử lại.';
            } finally {
                this.loading = false;
            }
        },
        
        // ── Thêm record ──
        async addRecord(formData) {
            this.saving = true;
            this.error = null;
            try {
                const res = await fetch(`${moduleBaseUrl}&action=add_record`, {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify(formData),
                });
                const data = await res.json();
                
                if (data.success) {
                    // Thêm record vào list với status Pending
                    this.records.push({
                        ...formData,
                        id: data.data.record_id,
                        batch_id: data.data.batch_id,
                        sync_status: 'pending',
                    });
                    // Bắt đầu poll sync status
                    this.startPolling(data.data.batch_id);
                    this.showToast('success', data.message);
                } else {
                    this.error = data.error.message;
                }
            } catch (e) {
                this.error = 'Đã xảy ra lỗi. Vui lòng thử lại.';
            } finally {
                this.saving = false;
            }
        },
        
        // ── Sync Status Polling ──
        startPolling(batchId) {
            if (this.pollInterval) return; // Đã có polling
            
            this.pollInterval = setInterval(async () => {
                const res = await fetch(
                    `${moduleBaseUrl}&action=sync_status&batch_id=${batchId}`
                );
                const data = await res.json();
                
                if (data.success) {
                    this.updateSyncBadges(data.data);
                    
                    // Dừng khi hoàn thành
                    if (data.data.status === 'complete' || data.data.status === 'failed') {
                        this.stopPolling();
                    }
                }
            }, 5000); // 5 giây
        },
        
        stopPolling() {
            if (this.pollInterval) {
                clearInterval(this.pollInterval);
                this.pollInterval = null;
            }
        },
    };
}
```

---

## 5. WORKFLOW AGENT PHẢI TUÂN THỦ

### 5.1. Khi được yêu cầu implement 1 Issue

```
Bước 1: XÁC ĐỊNH ISSUE
  → Tìm Issue ID trong EPICS.md (VD: QUEUE-001)
  → Đọc mô tả, Story Point, và Acceptance Criteria của Story chứa issue đó

Bước 2: THAM CHIẾU TÀI LIỆU PHÙ HỢP
  → Database work? → DB_SCHEMA.md
  → DA API call? → API_REFERENCE.md Phần A
  → Ajax endpoint? → API_REFERENCE.md Phần B
  → UI/Template? → WIREFRAME.md
  → Business logic/flow? → SPEC.md
  → Xác định: bảng DB nào? class nào? flow nào? endpoint nào?

Bước 3: KIỂM TRA DEPENDENCIES
  → Issue này phụ thuộc vào issue nào khác?
  → Các class/table cần thiết đã tồn tại chưa?
  → Nếu chưa → CẢNH BÁO và hỏi có muốn tạo dependency trước không

Bước 4: KIỂM TRA TEST PLAN
  → Tìm test cases liên quan trong TEST_PLAN.md
  → Nếu có test cases → viết test TRƯỚC (TDD approach)
  → Nếu chưa có → đề xuất bổ sung test cases

Bước 5: SINH CODE
  → Tuân thủ conventions trong Section 3 & 4
  → Bao gồm PHPDoc, type hints, error handling
  → Nếu code DA API → dùng DAResponseParser (Section 4.6)
  → Nếu code Ajax response → tuân thủ format chuẩn (API_REFERENCE.md B5)
  → KHÔNG sinh code stub/placeholder — luôn sinh code hoàn chỉnh chạy được

Bước 6: SINH TEST
  → Viết Unit Test cho logic mới (Section 4.7)
  → Dùng TestData fixtures, mock dependencies
  → Naming: test_{what}_{scenario}_{expected}

Bước 7: XÁC NHẬN AC
  → Liệt kê từng Acceptance Criteria từ EPICS.md
  → Giải thích code đáp ứng AC nào
  → Liệt kê test nào cover AC nào
  → Nếu có AC chưa đáp ứng → nêu rõ và đề xuất bước tiếp theo
```

### 5.2. Khi được yêu cầu implement 1 Story

```
Bước 1: Liệt kê tất cả Issues trong Story
Bước 2: Đề xuất thứ tự implement (dựa trên dependency)
Bước 3: Implement từng Issue theo workflow 5.1
Bước 4: Sau khi hoàn thành tất cả Issues → tổng kết AC của Story
```

### 5.3. Khi được yêu cầu implement 1 Epic

```
Bước 1: Tóm tắt Epic scope và liệt kê Stories
Bước 2: Đề xuất thứ tự Stories
Bước 3: Hỏi người dùng muốn implement Story nào trước
Bước 4: KHÔNG tự ý implement toàn bộ Epic cùng lúc
         (quá nhiều code, dễ sai, khó review)
```

### 5.4. Khi phát hiện vấn đề

```
Nếu Agent phát hiện:
- Code hiện tại vi phạm convention → CẢNH BÁO trước, đề xuất sửa
- Yêu cầu mâu thuẫn với SPEC → CHỈ RA mâu thuẫn, hỏi ý kiến
- Thiếu dependency → LIỆT KÊ dependencies cần tạo trước
- Bug tiềm ẩn → GIẢI THÍCH bug và đề xuất fix
- Security vulnerability → CẢNH BÁO NGAY LẬP TỨC, không chờ hỏi
```

---

## 6. QUY TẮC THEO PHASE

### 6.1. Phase 1 (MVP) — Quy tắc đặc biệt

```
- Chỉ support 1 loại DNS action: ADD_RECORD, EDIT_RECORD, DELETE_RECORD, CREATE_ZONE, DELETE_ZONE
- Chưa cần DNSSEC, SSL, Email Forward, Redirect actions trong Queue
- Chưa cần Drift Detection, Snapshot, Bulk Operations
- Frontend có thể đơn giản (DataTable cơ bản), chưa cần Chart.js
- Webhook notification chưa cần implement (chỉ log)
- Quota check có thể skip (hardcode limit cao)
- Conflict Resolution chưa cần (deduplication cơ bản đủ)
```

### 6.2. Phase 2 (Enterprise) — Mở rộng

```
- Thêm actions: CREATE_REDIRECT, EDIT_REDIRECT, DELETE_REDIRECT, REQUEST_SSL, RENEW_SSL
- Implement ConflictResolver đầy đủ (Admin-Priority)
- Implement NotificationService (Telegram + Email)
- Dashboard với Chart.js metrics
- Let's Encrypt integration qua DA API
```

### 6.3. Phase 3 (Add-on) — Hoàn thiện

```
- Thêm actions: ENABLE_DNSSEC, DISABLE_DNSSEC, RESIGN_ZONE, CREATE_EMAIL_FWD, DELETE_EMAIL_FWD
- Implement DriftDetector + SnapshotService
- Implement DDNS endpoint + Anti-Brute Force
- Implement QuotaEnforcer đầy đủ
- Implement Audit Trail UI + Export
- Implement Bulk Operations
- REST API cho external integration
```

---

## 7. COMMAND SHORTCUTS

Người dùng có thể sử dụng các lệnh tắt sau khi làm việc với Agent:

| Lệnh | Ý nghĩa |
|-------|---------|
| `@implement ISSUE-ID` | Implement issue cụ thể (VD: `@implement QUEUE-001`) |
| `@implement STORY X.Y` | Implement toàn bộ story (VD: `@implement STORY 2.1`) |
| `@review FILE` | Review code file, kiểm tra convention compliance |
| `@checklist EPIC-XX` | Hiển thị checklist AC cho Epic |
| `@schema TABLE` | Hiển thị schema chi tiết từ DB_SCHEMA.md cho bảng cụ thể |
| `@flow FLOW-XX` | Hiển thị flow diagram từ SPEC.md |
| `@api DA-COMMAND` | Hiển thị DA API reference (VD: `@api CMD_API_DNS_CONTROL`) |
| `@api ENDPOINT` | Hiển thị Internal API reference (VD: `@api add_record`) |
| `@wireframe SCREEN` | Hiển thị wireframe màn hình (VD: `@wireframe CL-02`, `@wireframe AD-01`) |
| `@status` | Tổng kết tiến độ: issues nào đã implement, issues nào còn |
| `@deps ISSUE-ID` | Liệt kê dependencies của issue |
| `@fix BUG-DESCRIPTION` | Tìm và sửa bug dựa trên mô tả |
| `@test ISSUE-ID` | Sinh test cases cho issue (tham chiếu TEST_PLAN.md) |
| `@test run SUITE` | Liệt kê test cases cần chạy cho suite (VD: `@test run unit`, `@test run regression`) |
| `@test coverage` | Kiểm tra test coverage — issue nào chưa có test |
| `@migration VERSION` | Tạo migration file cho version mới |
| `@refactor FILE` | Refactor file theo đúng convention |
| `@gotcha` | Hiển thị danh sách 10 DA API gotchas từ API_REFERENCE.md |
| `@release-check` | Hiển thị Pre-Release Checklist từ TEST_PLAN.md Section 14 |

---

## 8. ERROR RESPONSE PATTERNS

Khi Agent không thể thực hiện yêu cầu, PHẢI trả lời theo pattern:

```
⚠️ KHÔNG THỂ THỰC HIỆN

Lý do: [Giải thích cụ thể]
Vi phạm: [Section nào trong AGENT.md]

Đề xuất thay thế:
1. [Phương án A]
2. [Phương án B]

Cần quyết định từ bạn trước khi tiếp tục.
```

---

## 9. KNOWLEDGE BASE NHANH

### 9.1. WHMCS API/Hook Reference

```php
// Hooks thường dùng trong module này
add_hook('AfterModuleCreate', 1, 'hvndns_provision_zone');
add_hook('AfterModuleTerminate', 1, 'hvndns_terminate_zone');
add_hook('AfterModuleSuspend', 1, 'hvndns_suspend_domain');
add_hook('AfterModuleUnsuspend', 1, 'hvndns_unsuspend_domain');
add_hook('DailyCronJob', 1, 'hvndns_daily_maintenance');
add_hook('AdminAreaPage', 1, 'hvndns_admin_page_hook');
add_hook('ClientAreaPage', 1, 'hvndns_client_page_hook');
```

### 9.2. DirectAdmin API Quick Reference (Chi tiết tại API_REFERENCE.md)

```
Base URL:  https://{ip}:{port}
Auth:      HTTP Basic (username:password)
Format:    POST with application/x-www-form-urlencoded + json=yes

Command Mapping (chi tiết tại API_REFERENCE.md Phụ lục D1):
  ADD_RECORD       → CMD_API_DNS_CONTROL  action=add
  EDIT_RECORD      → CMD_API_DNS_CONTROL  action=edit  (CẦN arression param!)
  DELETE_RECORD    → CMD_API_DNS_CONTROL  action=delete (CẦN value chính xác!)
  CREATE_ZONE      → CMD_API_DNS_ADMIN    action=create (chỉ ns1+ns2)
  DELETE_ZONE      → CMD_API_DNS_ADMIN    action=delete
  ENABLE_DNSSEC    → CMD_API_DNS_DNSSEC   action=sign
  DISABLE_DNSSEC   → CMD_API_DNS_DNSSEC   action=unsign
  REQUEST_SSL      → CMD_API_SSL          action=save type=create request=letsencrypt
  CREATE_EMAIL_FWD → CMD_API_EMAIL_FORWARDERS action=create
  DELETE_EMAIL_FWD → CMD_API_EMAIL_FORWARDERS action=delete (dùng select0, KHÔNG dùng user)

Critical Format Rules (PHẢI dùng DAResponseParser):
  Root domain:  WHMCS "@" ↔ DA "" (empty string)
  CNAME/MX/NS:  WHMCS "target.com" → DA "target.com." (trailing dot)
  TXT:          WHMCS "v=spf1..." → DA "\"v=spf1...\"" (quoted)
  SRV:          WHMCS weight=0,port=5060,value="sip.com" → DA "0 5060 sip.com."
  Edit:         Cần arression={old_name}={old_value}

Error Handling:
  error field = string "1" → kiểm tra isset(), không phải boolean
  "Record not found" khi DELETE → coi như success (idempotent)
  "Zone already exists" khi CREATE → coi như success (idempotent)
  HTTP 403 → PERMANENTLY_FAILED + alert Admin
  Timeout → Retryable + Exponential Backoff
```

### 9.3. Internal Ajax API Quick Reference (Chi tiết tại API_REFERENCE.md Phần B)

```
Client Base:  /modules/addons/hvn_dns_manager/ajax.php?action={action}
Admin Base:   /admin/addonmodules.php?module=hvn_dns_manager&ajax=1&action={action}
DDNS:         /modules/addons/hvn_dns_manager/ddns.php?token={token}

Client Endpoints:
  GET  get_records         → Danh sách records + sync status + quota
  POST add_record          → Thêm record → returns batch_id
  POST edit_record         → Sửa record → returns batch_id
  POST delete_record       → Xóa record → returns batch_id
  GET  sync_status         → Poll sync status by batch_id
  GET  sync_status_all     → Poll tất cả records of domain
  POST create_ddns_token   → Tạo DDNS token (plain_token chỉ trả 1 lần!)
  POST toggle_dnssec       → Bật/tắt DNSSEC
  GET  get_dnssec          → Lấy DS Record info

Admin Endpoints:
  GET  dashboard_stats     → Metrics: pipeline, server health, overview
  POST test_server         → Test connection tới DA Node
  POST toggle_server       → Enable/Disable server
  POST retry_job           → Retry 1 job FAILED
  POST retry_all_failed    → Retry tất cả FAILED
  POST resolve_drift       → Xử lý drift (pull_da/push_whmcs/ignore)
  POST bulk_preview        → Preview bulk operation
  POST bulk_execute        → Execute bulk operation
  POST create_snapshot     → Tạo snapshot thủ công
  GET  list_snapshots      → Danh sách snapshots
  POST rollback_preview    → Preview rollback diff
  POST rollback_execute    → Execute rollback

Response Format (BẮT BUỘC cho mọi Ajax response):
  Success: {"success": true, "data": {...}, "message": "..."}
  Error:   {"success": false, "error": {"code": "...", "message": "...", "field": "..."}}

DDNS Response (plain text, tương thích DynDNS):
  "good {ip}"      → IP đã thay đổi thành công
  "nochg {ip}"     → IP không đổi
  "badauth"        → Token sai
  "abuse"          → Rate limit
  "blocked"        → IP bị block

Error Codes (đầy đủ tại API_REFERENCE.md B6):
  VALIDATION_ERROR    422  → Input format sai
  CNAME_CONFLICT      422  → CNAME trùng A record
  UNAUTHORIZED        403  → Không có quyền
  DOMAIN_SUSPENDED    403  → Domain bị suspend
  RECORD_PROTECTED    403  → Record hệ thống (NS/SOA)
  RECORD_LOCKED       403  → Admin đã lock
  QUOTA_EXCEEDED      429  → Vượt giới hạn gói dịch vụ
  RATE_LIMITED        429  → Quá nhiều thay đổi
  RECORD_MODIFIED     409  → Optimistic Locking fail
  INTERNAL_ERROR      500  → Lỗi server (KHÔNG leak chi tiết cho Client)
```

### 9.4. Test Quick Reference (Chi tiết tại TEST_PLAN.md)

```
Test Structure:
  tests/Unit/           → Mock everything, test 1 class (< 30s total)
  tests/Integration/    → Real DB, mock DA API (< 2 min total)
  tests/E2E/            → Real browser + DA Sandbox (< 15 min total)
  tests/Security/       → Injection, XSS, auth bypass
  tests/Performance/    → Response time, load, DB query plans
  tests/Fixtures/       → TestData.php shared fixtures

Run Commands:
  phpunit --testsuite unit          → Unit tests only
  phpunit --testsuite integration   → Integration tests only
  phpunit --testsuite regression    → Critical 20 test cases
  phpunit                           → All tests

Naming: test_{what}_{scenario}_{expected}
  VD: test_valid_ipv4_accepted
  VD: test_cname_conflict_with_existing_a_record
  VD: test_dispatch_creates_jobs_for_all_active_servers

Pattern: Arrange → Act → Assert (AAA)
Fixtures: Luôn dùng TestData::RECORD_A, TestData::INVALID_IP, v.v.
Mock DA: GuzzleHTTP MockHandler — KHÔNG gọi DA thật trong Unit/Integration

Coverage Targets:
  Services/    ≥ 80% line coverage
  Validators/  ≥ 90% line coverage
  Gateway/     ≥ 80% line coverage
  Controllers/ ≥ 60% line coverage (nhiều logic ở Service)

Regression Suite (PHẢI pass 100% trước deploy):
  REG-001..005  Queue core (dispatch, worker, retry, stale, backoff)
  REG-006..010  DNS core (validate, CRUD, audit, history)
  REG-011..015  Security (isolation, encrypt, leak, CSRF, SQLi)
  REG-016..018  Provisioning (create, terminate, suspend)
  REG-019..020  Database (migration idempotent, audit append-only)
```

### 9.3. Bảng Status Reference (Đồng bộ với DB_SCHEMA.md)

```
Queue Job Status (mod_hvndns_queue.status):
  PENDING            → Chờ xử lý (Worker sẽ pick up)
  SYNCING            → Đang được Worker xử lý (row locked)
  COMPLETE           → DA đã confirm thành công
  FAILED             → Lỗi, sẽ retry (nếu còn attempts)
  CANCELLED          → Bị hủy (conflict resolution hoặc server disabled)
  PERMANENTLY_FAILED → Hết retry hoặc lỗi non-retryable (auth_fail, zone_not_found)

Queue Job Error Types (mod_hvndns_queue.error_type):
  timeout            → DA không phản hồi trong thời gian cho phép → Retryable
  auth_fail          → Sai username/password DA → Non-retryable, alert Admin
  dns_conflict       → Record đã tồn tại hoặc xung đột → Non-retryable
  zone_not_found     → Zone không tồn tại trên DA → Non-retryable
  zone_exists        → Zone đã có (khi CREATE_ZONE) → Conditional (coi như success)
  rate_limit         → DA API rate limit → Retryable, backoff 60s
  server_error       → DA trả HTTP 5xx → Retryable
  network_error      → Không kết nối được → Retryable
  unknown            → Lỗi không xác định → Retryable 1 lần, sau đó non-retryable

Domain Status (mod_hvndns_domains.status):
  active         → Đang hoạt động, Client có thể CRUD
  suspended      → Tạm ngưng (nợ phí), Client readonly, zone vẫn live trên DA
  terminated     → Đã hủy, chuyển sang pending_delete
  pending_delete → Đang trong grace period 30 ngày trước khi xóa zone khỏi DA

SSL Status (mod_hvndns_domains.ssl_status):
  none     → Chưa yêu cầu SSL
  pending  → Đang chờ Let's Encrypt cấp phát
  active   → Đang hoạt động (auto-renew khi < 7 ngày)
  expired  → Đã hết hạn
  failed   → Cấp phát thất bại

Drift Resolution (mod_hvndns_drift_reports.resolution):
  pending    → Chờ Admin quyết định
  pull_da    → Lấy giá trị từ DA ghi đè WHMCS DB
  push_whmcs → Đẩy giá trị WHMCS DB ghi đè lên DA
  ignored    → Admin chọn bỏ qua
  auto_fixed → Module tự sửa (khi drift_auto_fix = true)

Redirect Types (mod_hvndns_redirects.redirect_type):
  301        → Permanent redirect (SEO-friendly, browser cache vĩnh viễn)
  302        → Temporary redirect (browser không cache)
  masked     → URL masking (ẩn URL đích, hiển thị domain nguồn)

Snapshot Types (mod_hvndns_snapshots.snapshot_type):
  scheduled     → Nightly cron tự tạo (2:00 AM)
  pre_bulk      → Tự động trước bulk operation
  pre_template  → Tự động trước load template
  manual        → Admin bấm nút tạo thủ công

Server Roles (mod_hvndns_servers.role):
  primary    → Server chính (dùng cho Drift Detection query)
  secondary  → Bản sao, được đồng bộ tự động, không nhận job trực tiếp từ WHMCS

Actor Types (dùng chung cho queue, audit_trail, record_history):
  client  → Khách hàng từ Client Area
  admin   → Quản trị viên từ Admin Area
  system  → Tự động (cron, provisioning, auto-resign, auto-renew)
  api     → DDNS endpoint hoặc REST API

Notification Rules (mod_hvndns_notification_cooldowns.rule_id):
  RULE_01  → ≥5 FAILED liên tiếp trên 1 server     → Cooldown 15 phút
  RULE_02  → Server unreachable ≥3 lần liên tiếp    → Cooldown 15 phút
  RULE_03  → Queue backlog >100 pending >10 phút     → Cooldown 30 phút
  RULE_04  → Server vào backoff mode                  → Cooldown 30 phút
  RULE_05  → PERMANENTLY_FAILED job detected          → Mỗi job
  RULE_06  → Drift detected (nightly scan)            → Cooldown 24 giờ
  RULE_07  → SSL certificate expiring <7 ngày         → Cooldown 24 giờ
```

---

## 10. CHECKLIST TRƯỚC KHI COMMIT

Agent nên nhắc người dùng kiểm tra trước khi deploy:

```
□ Code không vi phạm bất kỳ nguyên tắc nào trong Section 2
□ Không có TODO, FIXME, hoặc placeholder trong code production
□ Mọi function có PHPDoc và type declarations
□ Mọi user input đã qua sanitize + validate
□ Mọi DB operation dùng Eloquent (không raw SQL)
□ Mọi thay đổi DNS đi qua QueueManager::dispatch()
□ Mọi response tuân theo JSON format chuẩn (Section 3.5)
□ Logging đúng level, không log sensitive data
□ Client Area không hiển thị server credentials
□ Audit trail được ghi cho mọi thay đổi data
□ Error handling đầy đủ (try-catch, graceful fallback)
□ Migration là idempotent (chạy lại không lỗi)
□ Template escape mọi dynamic data
□ CSRF token trong mọi form
```

---

> **Ngày tạo**: 25/02/2026  
> **Phiên bản**: 1.2  
> **Cập nhật lần cuối**: 25/02/2026 — Tích hợp API_REFERENCE.md + TEST_PLAN.md  
> **Cập nhật bởi**: HVN Group Development Team  
> **Lưu ý**: Tệp này phải được đặt tại root của project repository và được include vào context của mọi AI Agent session.
