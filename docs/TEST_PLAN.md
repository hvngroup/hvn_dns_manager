# HVN - DirectAdmin DNS Manager
## TEST_PLAN.md — Kế hoạch Kiểm thử

> **Phiên bản**: 1.0  
> **Ngày tạo**: 25/02/2026  
> **Dành cho**: QA Engineer, Developer, AI Agent  
> **Tham chiếu**: SPEC.md, EPICS.md (Acceptance Criteria), API_REFERENCE.md, DB_SCHEMA.md  

---

## Mục lục

1. [Chiến lược Kiểm thử Tổng quan](#1-chiến-lược-kiểm-thử-tổng-quan)
2. [Môi trường Kiểm thử](#2-môi-trường-kiểm-thử)
3. [Unit Tests](#3-unit-tests)
4. [Integration Tests](#4-integration-tests)
5. [End-to-End Tests (E2E)](#5-end-to-end-tests)
6. [Security Tests](#6-security-tests)
7. [Performance & Load Tests](#7-performance--load-tests)
8. [Regression Tests](#8-regression-tests)
9. [User Acceptance Tests (UAT)](#9-user-acceptance-tests)
10. [Test Case Matrix — Phase 1](#10-test-case-matrix--phase-1)
11. [Test Case Matrix — Phase 2](#11-test-case-matrix--phase-2)
12. [Test Case Matrix — Phase 3](#12-test-case-matrix--phase-3)
13. [Bug Severity Classification](#13-bug-severity-classification)
14. [Checklist Trước Release](#14-checklist-trước-release)

---

## 1. Chiến lược Kiểm thử Tổng quan

### 1.1. Kim tự tháp Testing

```
                    ╱╲
                   ╱  ╲
                  ╱ E2E ╲            Ít nhất, chậm nhất, đắt nhất
                 ╱  Tests ╲          ~10% tổng test cases
                ╱──────────╲         Trình duyệt thật, DA server thật
               ╱ Integration╲        ~30% tổng test cases
              ╱    Tests      ╲      Mock DA API, real DB
             ╱────────────────╲
            ╱   Unit Tests      ╲    ~60% tổng test cases
           ╱                      ╲  Nhanh nhất, nhiều nhất
          ╱────────────────────────╲
```

### 1.2. Nguyên tắc Testing

| Nguyên tắc | Mô tả |
|-------------|-------|
| **Async-First Testing** | Mọi test liên quan DNS change PHẢI verify qua queue, KHÔNG verify trực tiếp trên DA |
| **Isolation** | Unit test không phụ thuộc DB, network, hoặc DA server |
| **Idempotent** | Chạy test nhiều lần cho cùng kết quả. Test tự cleanup sau khi chạy |
| **Deterministic** | Không dùng `sleep()` chờ cron. Mock time hoặc trigger worker trực tiếp |
| **Coverage Target** | Unit: ≥ 80% line coverage cho `Services/`, `Validators/`, `Gateway/` |

### 1.3. Phân bổ Testing theo Phase

| Phase | Focus | Khi nào chạy |
|-------|-------|-------------|
| Phase 1 (MVP) | Unit + Integration cho Queue, Validator, Gateway | Mỗi commit |
| Phase 2 (Enterprise) | + Integration cho Conflict, Webhook, SSL | Mỗi sprint |
| Phase 3 (Add-on) | + E2E, Security, Performance | Trước release |
| Mọi Phase | Regression test suite | Trước mỗi deploy |

---

## 2. Môi trường Kiểm thử

### 2.1. Environments

| Env | Mục đích | DA Server | Database |
|-----|----------|-----------|----------|
| **Local Dev** | Developer chạy unit test | Mock (không cần DA) | SQLite in-memory |
| **CI/CD** | Automated test pipeline | Mock DA API | MySQL container |
| **Staging** | Integration & E2E test | DA Sandbox (`da-test.hvn.vn`) | MySQL clone từ production |
| **Pre-Production** | UAT, Performance test | DA Staging cluster (3 nodes) | MySQL clone |

### 2.2. DA Sandbox Server

```
Hostname:  da-test.hvn.vn
IP:        10.0.0.50 (nội bộ)
Port:      2222
Username:  admin
Password:  (encrypted trong .env.testing)
DNSSEC:    Enabled
SSL:       Self-signed (verify=false cho test)

Quy tắc:
- Chỉ dùng domain dạng: test-*.hvndns.local
- Xóa sạch test zones mỗi đêm (cron cleanup)
- KHÔNG dùng domain thật
```

### 2.3. Test Data Fixtures

```php
// File: tests/Fixtures/TestData.php

class TestData
{
    // Domain fixtures
    const DOMAIN_ACTIVE     = 'test-active.hvndns.local';
    const DOMAIN_SUSPENDED  = 'test-suspended.hvndns.local';
    const DOMAIN_TERMINATED = 'test-terminated.hvndns.local';
    const DOMAIN_BULK       = 'test-bulk-{n}.hvndns.local'; // n = 1..100
    
    // Record fixtures
    const RECORD_A     = ['type' => 'A',     'name' => 'www',   'value' => '10.0.0.100', 'ttl' => 3600];
    const RECORD_AAAA  = ['type' => 'AAAA',  'name' => 'ipv6',  'value' => '2001:db8::1', 'ttl' => 3600];
    const RECORD_CNAME = ['type' => 'CNAME', 'name' => 'ftp',   'value' => 'test-active.hvndns.local', 'ttl' => 3600];
    const RECORD_MX    = ['type' => 'MX',    'name' => '@',     'value' => 'mail.test-active.hvndns.local', 'ttl' => 3600, 'priority' => 10];
    const RECORD_TXT   = ['type' => 'TXT',   'name' => '@',     'value' => 'v=spf1 include:_spf.google.com ~all', 'ttl' => 3600];
    const RECORD_SRV   = ['type' => 'SRV',   'name' => '_sip._tcp', 'value' => 'sip.test.local', 'ttl' => 3600, 'priority' => 10, 'weight' => 0, 'port' => 5060];
    const RECORD_CAA   = ['type' => 'CAA',   'name' => '@',     'value' => '0 issue "letsencrypt.org"', 'ttl' => 3600];
    
    // Invalid data fixtures
    const INVALID_IP       = '999.999.999.999';
    const INVALID_IPV6     = 'not:an:ipv6';
    const INVALID_FQDN     = '-invalid-.domain';
    const INVALID_TTL_LOW  = 10;    // < 60
    const INVALID_TTL_HIGH = 100000; // > 86400
    
    // Server fixtures
    const SERVER_PRIMARY   = ['hostname' => 'dns-test1.hvn.vn', 'ip' => '10.0.0.51', 'port' => 2222, 'role' => 'primary'];
    const SERVER_SECONDARY = ['hostname' => 'dns-test2.hvn.vn', 'ip' => '10.0.0.52', 'port' => 2222, 'role' => 'secondary'];
}
```

---

## 3. Unit Tests

> **Scope**: Test 1 class/method riêng lẻ, mock tất cả dependencies.  
> **Tool**: PHPUnit 9.x  
> **Vị trí**: `tests/Unit/`  
> **Chạy**: `phpunit --testsuite unit` — Target: < 30 giây toàn bộ

### 3.1. DnsRecordValidator Tests

```
tests/Unit/Validators/DnsRecordValidatorTest.php

TEST GROUP: A Record Validation
├── test_valid_ipv4_accepted                          "103.45.67.89" → pass
├── test_ipv4_each_octet_max_255                      "256.1.1.1" → fail
├── test_ipv4_reject_letters                          "abc.def.ghi.jkl" → fail
├── test_private_ip_warning_not_block                 "192.168.1.1" → pass + warning
├── test_loopback_warning                             "127.0.0.1" → pass + warning
└── test_empty_value_rejected                         "" → fail

TEST GROUP: AAAA Record Validation
├── test_valid_ipv6_full_accepted                     "2001:0db8:85a3:0000:0000:8a2e:0370:7334" → pass
├── test_valid_ipv6_compressed_accepted               "2001:db8::1" → pass
├── test_ipv4_rejected_for_aaaa                       "103.45.67.89" → fail
└── test_invalid_ipv6_rejected                        "not:an:ipv6" → fail

TEST GROUP: CNAME Record Validation
├── test_valid_fqdn_accepted                          "target.example.com" → pass
├── test_ip_rejected_for_cname                        "103.1.2.3" → fail (must be FQDN)
├── test_cname_conflict_with_existing_a_record        name="www" + existing A "www" → fail
├── test_cname_at_root_with_mx_rejected               name="@" + existing MX → fail
├── test_cname_at_root_without_mx_accepted            name="@" + no MX → pass
└── test_trailing_dot_auto_handled                    "target.com" → stored as "target.com"

TEST GROUP: MX Record Validation
├── test_valid_mx_accepted                            value="mail.example.com", priority=10 → pass
├── test_ip_rejected_for_mx                           value="103.1.2.3" → fail (RFC 2181)
├── test_missing_priority_rejected                    priority=null → fail
├── test_priority_zero_accepted                       priority=0 → pass
├── test_priority_max_65535_accepted                  priority=65535 → pass
├── test_priority_negative_rejected                   priority=-1 → fail
└── test_duplicate_priority_warning                   priority=10 + existing MX priority=10 → pass + warning

TEST GROUP: TXT Record Validation
├── test_valid_spf_accepted                           "v=spf1 include:..." → pass
├── test_long_txt_accepted_max_4096                   4096 chars → pass
├── test_txt_over_4096_rejected                       4097 chars → fail
├── test_spf_syntax_warning_on_invalid                "v=spf1 invalid" → pass + warning
└── test_dkim_format_warning_on_invalid               name="_domainkey" + bad format → pass + warning

TEST GROUP: SRV Record Validation
├── test_valid_srv_accepted                           name="_sip._tcp", priority=10, weight=0, port=5060 → pass
├── test_missing_port_rejected                        port=null → fail
├── test_port_range_1_to_65535                        port=0 → fail, port=65536 → fail
├── test_name_format_must_start_underscore            name="sip.tcp" → fail (need _sip._tcp)
└── test_target_must_be_fqdn                          value="103.1.2.3" → fail

TEST GROUP: CAA Record Validation
├── test_valid_caa_issue_accepted                     "0 issue \"letsencrypt.org\"" → pass
├── test_valid_caa_issuewild_accepted                 "0 issuewild \"letsencrypt.org\"" → pass
├── test_invalid_tag_rejected                         "0 invalid \"ca.org\"" → fail
└── test_flag_only_0_or_128                           flag=1 → fail, flag=128 → pass

TEST GROUP: Name (Subdomain) Validation
├── test_at_sign_accepted_as_root                     "@" → pass
├── test_wildcard_accepted                            "*" → pass
├── test_valid_subdomain_accepted                     "mail" → pass
├── test_multi_level_subdomain_accepted               "sub.mail" → pass
├── test_hyphen_middle_accepted                       "my-site" → pass
├── test_hyphen_start_rejected                        "-invalid" → fail
├── test_hyphen_end_rejected                          "invalid-" → fail
├── test_label_max_63_chars                           64 chars → fail
├── test_total_max_253_chars                          254 chars → fail
└── test_special_chars_rejected                       "ma!l" → fail

TEST GROUP: TTL Validation
├── test_valid_ttl_3600_accepted                      3600 → pass
├── test_min_ttl_60_accepted                          60 → pass
├── test_max_ttl_86400_accepted                       86400 → pass
├── test_ttl_below_60_rejected                        59 → fail
├── test_ttl_above_86400_rejected                     86401 → fail
├── test_default_ttl_3600_when_null                   null → default 3600
└── test_ttl_non_numeric_rejected                     "abc" → fail
```

**Tổng**: ~50 test cases cho Validator

---

### 3.2. QueueManager Tests

```
tests/Unit/Services/QueueManagerTest.php

TEST GROUP: Dispatch
├── test_dispatch_creates_jobs_for_all_active_servers
│   Setup: 3 servers (2 active, 1 disabled)
│   Assert: 2 jobs created (not 3)
│   Assert: all jobs have same batch_id
│   Assert: all jobs status = PENDING
│
├── test_dispatch_returns_uuid_batch_id
│   Assert: batch_id matches UUID v4 format
│
├── test_dispatch_sets_correct_priority
│   actor_type='admin' → priority=1
│   actor_type='client' → priority=5
│   actor_type='system' → varies by action
│
├── test_dispatch_stores_payload_as_json
│   Assert: payload column contains valid JSON
│   Assert: JSON contains record_id, type, name, value
│
├── test_dispatch_completes_under_50ms
│   Assert: execution time < 50ms (only DB writes)
│
└── test_dispatch_with_no_active_servers_throws_exception
    Setup: all servers disabled
    Assert: throws NoActiveServersException

TEST GROUP: Deduplication
├── test_dedup_replaces_pending_job_same_actor
│   Setup: existing PENDING job for record #456 by client
│   Action: dispatch same record #456 by client with new value
│   Assert: old job payload updated, no new job created
│   Assert: returns original batch_id
│
├── test_dedup_does_not_affect_syncing_jobs
│   Setup: existing SYNCING job for record #456
│   Action: dispatch same record #456
│   Assert: new job created (does not touch SYNCING)
│
└── test_dedup_triggers_conflict_resolver_if_different_actor
    Setup: existing PENDING job by client
    Action: dispatch same record by admin
    Assert: ConflictResolver::resolve() called

TEST GROUP: Batch Status
├── test_batch_status_all_complete
│   Setup: 3 jobs, all COMPLETE
│   Assert: getBatchStatus() returns 'complete'
│
├── test_batch_status_partial
│   Setup: 2 COMPLETE, 1 FAILED
│   Assert: returns 'partial'
│
├── test_batch_status_all_pending
│   Assert: returns 'pending'
│
├── test_batch_status_mixed_syncing
│   Setup: 1 COMPLETE, 1 SYNCING, 1 PENDING
│   Assert: returns 'syncing'
│
└── test_batch_status_all_failed
    Assert: returns 'failed'

TEST GROUP: Cancel & Retry
├── test_cancel_batch_sets_pending_to_cancelled
│   Assert: PENDING → CANCELLED, SYNCING untouched
│
├── test_retry_failed_resets_status_and_attempts
│   Assert: status → PENDING, attempts → 0, next_retry_at → NULL
│
└── test_retry_all_failed_returns_count
    Setup: 12 FAILED jobs
    Assert: retryFailed() returns 12
```

**Tổng**: ~20 test cases

---

### 3.3. DAGateway Tests (Mock HTTP)

```
tests/Unit/Gateway/DAGatewayTest.php

Sử dụng: GuzzleHTTP MockHandler để giả lập DA response

TEST GROUP: Connection
├── test_test_connection_success
│   Mock: HTTP 200 + valid DA response
│   Assert: DAResponse.success = true, version populated
│
├── test_test_connection_auth_fail
│   Mock: HTTP 403
│   Assert: DAResponse.errorType = 'auth_fail'
│
├── test_test_connection_timeout
│   Mock: ConnectException (timeout)
│   Assert: DAResponse.errorType = 'timeout'
│
└── test_test_connection_unreachable
    Mock: ConnectException (connection refused)
    Assert: DAResponse.errorType = 'network_error'

TEST GROUP: Record Operations
├── test_add_record_success
│   Mock: HTTP 200 {"success": "Record added successfully"}
│   Assert: DAResponse.success = true
│
├── test_add_record_conflict
│   Mock: HTTP 200 {"error": "1", "text": "Record already exists"}
│   Assert: DAResponse.errorType = 'dns_conflict'
│   Assert: DAResponse.isRetryable() = false
│
├── test_edit_record_builds_correct_arression
│   Assert: arression param = "{old_name}={old_value}"
│   Assert: root domain arression starts with "="
│
├── test_edit_record_not_found
│   Mock: HTTP 200 {"error": "1", "text": "Cannot modify record"}
│   Assert: DAResponse.errorType = 'dns_conflict'
│
├── test_delete_record_success
│   Mock: success response
│   Assert: success = true
│
├── test_delete_record_not_found_treated_as_success
│   Mock: {"error": "1", "text": "Record not found"}
│   Assert: Worker should treat as idempotent success
│
└── test_server_error_500_is_retryable
    Mock: HTTP 500
    Assert: DAResponse.isRetryable() = true

TEST GROUP: Zone Operations
├── test_create_zone_success
├── test_create_zone_already_exists_treated_as_success
├── test_delete_zone_success
└── test_delete_zone_not_found_treated_as_success

TEST GROUP: Response Parser
├── test_parse_root_domain_empty_string_to_at
│   DA name="" → WHMCS name="@"
│
├── test_parse_trailing_dot_stripped
│   DA value="mail.example.com." → WHMCS value="mail.example.com"
│
├── test_parse_txt_quotes_stripped
│   DA value="\"v=spf1...\"" → WHMCS value="v=spf1..."
│
├── test_parse_srv_value_split
│   DA value="0 5060 sip.example.com." → weight=0, port=5060, value="sip.example.com"
│
├── test_build_params_adds_trailing_dot_for_cname
│   WHMCS value="target.com" → DA value="target.com."
│
├── test_build_params_quotes_txt
│   WHMCS value="v=spf1..." → DA value="\"v=spf1...\""
│
└── test_build_params_srv_combines_weight_port_target
    WHMCS weight=0, port=5060, value="sip.com" → DA value="0 5060 sip.com."
```

**Tổng**: ~25 test cases

---

### 3.4. ConflictResolver Tests

```
tests/Unit/Services/ConflictResolverTest.php

├── test_no_conflict_when_no_pending_job
├── test_client_vs_client_same_record_deduplicates
├── test_admin_vs_client_cancels_client_job
│   Assert: client job → CANCELLED
│   Assert: audit trail notes "Overridden by Admin"
│
├── test_client_vs_admin_does_not_cancel_admin_job
│   Assert: client job rejected, admin job untouched
│
├── test_admin_vs_admin_allows_with_warning
│   Assert: both jobs kept, warning returned
│
├── test_conflict_window_3_minutes
│   Setup: job created 4 minutes ago
│   Assert: no conflict detected (outside window)
│
├── test_conflict_only_checks_pending_status
│   Setup: SYNCING job for same record
│   Assert: no conflict (SYNCING not affected)
│
└── test_conflict_resolution_writes_audit_trail
    Assert: AuditTrail entry with action='override_conflict'
```

**Tổng**: ~8 test cases

---

### 3.5. Các Unit Test khác

```
tests/Unit/Services/QuotaEnforcerTest.php
├── test_under_limit_passes                           15/50 → pass
├── test_at_limit_fails                               50/50 → QuotaExceededException
├── test_unlimited_plan_always_passes                  max_records=0 → pass
├── test_no_plan_assigned_unlimited                    quota_plan_id=NULL → pass
├── test_admin_override_bypasses_quota                 admin context → pass regardless
└── test_counts_only_active_records_not_pending_delete pending_delete excluded from count

tests/Unit/Services/SnapshotServiceTest.php
├── test_create_snapshot_saves_all_records_as_json
├── test_snapshot_rolling_deletes_oldest_beyond_30
├── test_restore_creates_pre_rollback_snapshot_first
└── test_restore_dispatches_correct_add_delete_jobs

tests/Unit/Helpers/CryptoHelperTest.php
├── test_encrypt_decrypt_roundtrip
├── test_different_plaintext_different_ciphertext
└── test_decrypt_wrong_key_fails

tests/Unit/Helpers/DnsFormatHelperTest.php
├── test_ttl_to_human_readable                        3600 → "1h", 300 → "5m"
├── test_full_record_name                             name="mail", domain="example.com" → "mail.example.com"
└── test_full_record_name_root                        name="@", domain="example.com" → "example.com"

tests/Unit/Helpers/SettingsHelperTest.php
├── test_get_returns_default_when_key_not_found         get('missing', 'default') → 'default'
├── test_get_bool_casts_correctly                        '1' → true, '0' → false, '' → false
├── test_get_int_casts_correctly                         '3600' → 3600
├── test_set_creates_new_setting                         set('new_key', 'value') → row created
├── test_set_updates_existing_setting                    set('existing', 'new') → value updated
└── test_encrypted_settings_roundtrip                    telegram_bot_token encrypt → decrypt OK

tests/Unit/Services/RecordPermissionTest.php
├── test_allowed_type_passes                             allow_modify_a=1 + type A → pass
├── test_disallowed_type_blocked                         allow_modify_ns=0 + type NS → RECORD_TYPE_DISABLED
├── test_admin_bypasses_permission                       allow_modify_ns=0 + actor=admin → pass
└── test_allowed_types_list_excludes_disabled             Dropdown chỉ chứa types được bật

tests/Unit/Services/NsCheckTest.php
├── test_ns_match_passes                                 domain NS = dns1.hvn.vn → pass
├── test_ns_mismatch_blocks                              domain NS = ns1.other.com → NS_NOT_CONFIGURED
├── test_ns_check_disabled_always_passes                  disable_manage_wrong_ns=0 → pass regardless
├── test_ns_check_skip_method                             ns_check_method='skip' → pass
└── test_partial_ns_match_passes                          domain có dns1 nhưng thiếu dns3 → pass (partial OK)

tests/Integration/SettingsIntegrationTest.php
├── test_per_type_limit_enforcement                      a_record_limit=5 + 5 A records → 6th blocked
├── test_global_limit_vs_quota_plan_priority              Quota Plan limit < global → quota plan wins
├── test_admin_override_beats_quota_plan                  Admin exception override → pass
├── test_client_notification_sent_after_sync_complete     enable_client_notification=1 → email sent
├── test_client_notification_not_sent_on_queue_only       Job pending → NO email yet
├── test_fetch_from_ns_updates_db_on_drift                fetch_on_load=1 + DA has extra record → DB updated
└── test_cache_refresh_ttl_triggers_background_fetch       cache expired → background DA fetch triggered
```

**Tổng Unit Tests: ~120 test cases**

---

## 4. Integration Tests

> **Scope**: Test nhiều component phối hợp, sử dụng real DB (MySQL test), mock DA API.  
> **Tool**: PHPUnit + MySQL test database  
> **Vị trí**: `tests/Integration/`  
> **Chạy**: `phpunit --testsuite integration` — Target: < 2 phút

### 4.1. Queue → Worker → SyncLog Pipeline

```
tests/Integration/QueueWorkerPipelineTest.php

TEST: test_full_pipeline_add_record
    1. Tạo domain, server (2 active) trong DB
    2. Gọi QueueManager::dispatch(ADD_RECORD)
    3. Assert: 2 jobs created, status=PENDING
    4. Chạy CronWorker::processOneCycle() (mock DA → success)
    5. Assert: 2 jobs status=COMPLETE
    6. Assert: 2 sync_logs created, success=true
    7. Assert: server.last_success_at updated

TEST: test_pipeline_partial_failure
    1. Dispatch ADD_RECORD → 2 jobs
    2. Mock: server1 → success, server2 → timeout
    3. Run worker
    4. Assert: job1=COMPLETE, job2=FAILED
    5. Assert: job2.attempts=1, job2.next_retry_at set
    6. Assert: getBatchStatus() = 'partial'

TEST: test_pipeline_retry_with_backoff
    1. Create FAILED job with attempts=2
    2. Set next_retry_at = NOW() - 1 minute (ready to retry)
    3. Run worker (mock DA → success this time)
    4. Assert: job status=COMPLETE
    5. Assert: server.backoff_count reset to 0

TEST: test_pipeline_permanently_failed_after_max_attempts
    1. Create FAILED job with attempts=4 (max=5)
    2. Run worker (mock DA → fail again)
    3. Assert: job status=PERMANENTLY_FAILED
    4. Assert: job.attempts=5

TEST: test_stale_job_recovery
    1. Create SYNCING job with locked_at = 10 minutes ago
    2. Run worker
    3. Assert: job status=FAILED, error_message contains "Stale job"
    4. Assert: lock released (locked_by=NULL)

TEST: test_worker_respects_max_concurrent_per_server
    1. Create 100 PENDING jobs for server with max_concurrent=10
    2. Run worker
    3. Assert: only 10 jobs processed (90 still PENDING)

TEST: test_worker_skips_server_in_backoff
    1. Set server.backoff_until = NOW() + 10 minutes
    2. Create PENDING jobs for that server
    3. Run worker
    4. Assert: 0 jobs processed

TEST: test_worker_exits_before_55_seconds
    1. Create 1000 PENDING jobs
    2. Mock DA with 1-second delay per call
    3. Run worker
    4. Assert: worker exited, remaining jobs still PENDING
    5. Assert: total runtime < 56 seconds
```

---

### 4.2. DnsRecordService Full Flow

```
tests/Integration/DnsRecordServiceTest.php

TEST: test_create_record_full_flow
    1. Gọi DnsRecordService::createRecord(A, mail, 1.2.3.4)
    2. Assert: record in mod_hvndns_records
    3. Assert: queue jobs created (fan-out)
    4. Assert: audit_trail entry exists
    5. Assert: record_history entry with change_type='created'

TEST: test_edit_record_stores_old_value_in_history
    1. Create record → edit with new value
    2. Assert: record_history has old_value and new_value

TEST: test_delete_record_sets_pending_delete
    1. Delete record
    2. Assert: record.pending_delete = true (not deleted from DB yet)
    3. Assert: queue job action = DELETE_RECORD

TEST: test_quota_enforcement_blocks_over_limit
    1. Set quota plan max_records = 3
    2. Create 3 records → success
    3. Create 4th record → QuotaExceededException
    4. Assert: 4th record NOT in DB, NO queue job created

TEST: test_rate_limit_enforcement
    1. Create 30 records rapidly (within 1 minute)
    2. Create 31st record → RateLimitException
```

---

### 4.3. Provisioning Integration

```
tests/Integration/ProvisioningTest.php

TEST: test_provision_creates_zone_and_applies_template
    1. Simulate WHMCS hook AfterModuleCreate
    2. Assert: domain created in mod_hvndns_domains
    3. Assert: NS records (3x) + default A record created
    4. Assert: CREATE_ZONE jobs dispatched for all servers
    5. Assert: audit_trail "Zone created via auto-provision"

TEST: test_terminate_soft_deletes_domain
    1. Simulate AfterModuleTerminate
    2. Assert: domain.status = 'pending_delete'
    3. Assert: domain.terminated_at = now
    4. Assert: DELETE_ZONE jobs dispatched

TEST: test_suspend_makes_domain_readonly
    1. Simulate AfterModuleSuspend
    2. Assert: domain.status = 'suspended'
    3. Try create record → fail with DOMAIN_SUSPENDED
```

---

### 4.4. Database Migration Integration

```
tests/Integration/MigrationTest.php

TEST: test_fresh_install_creates_all_18_tables
    1. Run MigrationRunner on empty database
    2. Assert: all 18 tables exist
    3. Assert: schema_version has entry for v1.0.0

TEST: test_migration_is_idempotent
    1. Run migration twice
    2. Assert: no errors, tables unchanged
    3. Assert: schema_version still has 1 entry

TEST: test_upgrade_migration_adds_new_columns
    1. Install v1.0.0
    2. Run v1.1.0 migration
    3. Assert: new columns/tables exist
    4. Assert: old data preserved

TEST: test_deactivate_does_not_drop_tables
    1. Install module, add some data
    2. Deactivate module
    3. Assert: tables still exist with data
```

---

## 5. End-to-End Tests

> **Scope**: Test từ browser tới DA server thật, verify DNS thực sự thay đổi.  
> **Tool**: PHPUnit + cURL (hoặc Selenium cho UI tests)  
> **Env**: Staging với DA Sandbox  
> **Chạy**: Manual trigger hoặc nightly CI — Target: < 15 phút

### 5.1. E2E — Core DNS Flow

```
tests/E2E/CoreDnsFlowTest.php

TEST: test_e2e_add_record_appears_on_da_server
    1. Login WHMCS Client Area
    2. POST add A record "e2e-test" → "10.0.0.200"
    3. Assert: HTTP 200, success response
    4. Wait for cron (trigger manually hoặc chờ 60s)
    5. Query DA API getZone() trực tiếp
    6. Assert: record "e2e-test" = "10.0.0.200" exists on DA
    7. Cleanup: delete record

TEST: test_e2e_edit_record_updates_on_da_server
    1. Create record on WHMCS → wait sync complete
    2. Edit record value → wait sync complete
    3. Query DA → assert new value present, old value gone

TEST: test_e2e_delete_record_removes_from_da_server
    1. Create record → wait sync
    2. Delete record → wait sync
    3. Query DA → assert record not present

TEST: test_e2e_multi_server_fanout
    1. Ensure 3 test servers active
    2. Add record
    3. Wait sync complete
    4. Query ALL 3 DA servers
    5. Assert: record present on all 3
```

### 5.2. E2E — DDNS

```
tests/E2E/DdnsFlowTest.php

TEST: test_e2e_ddns_update_changes_ip
    1. Create DDNS token for subdomain "cam"
    2. GET ddns.php?token=xxx (simulating router)
    3. Assert response: "good {ip}"
    4. Wait sync
    5. Query DA → A record "cam" = request IP

TEST: test_e2e_ddns_nochg_when_same_ip
    1. Call DDNS with same IP twice
    2. Assert 2nd response: "nochg {ip}"
    3. Assert: only 1 queue job created (not 2)

TEST: test_e2e_ddns_brute_force_blocks_ip
    1. Send 10 requests with invalid token from same IP
    2. Assert: IP blocked (HTTP 403)
    3. Send valid token from same IP
    4. Assert: still blocked (IP-level block)
```

---

## 6. Security Tests

> **Focus**: Bảo mật input, authorization, data leakage, injection  
> **Chạy**: Mỗi sprint + trước release

### 6.1. Input Security

```
tests/Security/InputSecurityTest.php

TEST GROUP: SQL Injection Attempts
├── test_sqli_in_record_name                          name="'; DROP TABLE--" → sanitized, no SQL error
├── test_sqli_in_record_value                         value="1 OR 1=1" → treated as literal value
├── test_sqli_in_domain_search                        search="' UNION SELECT--" → sanitized
└── test_sqli_in_ajax_parameters                      domain_id="1; DELETE" → rejected

TEST GROUP: XSS Attempts
├── test_xss_in_record_value_escaped_in_template      value="<script>alert(1)</script>" → HTML escaped
├── test_xss_in_domain_notes                          notes contain JS → escaped in admin view
├── test_xss_in_ddns_token_label                      label="<img onerror=...>" → escaped
└── test_xss_in_audit_trail_display                   old_value contains XSS → escaped in view

TEST GROUP: Path Traversal
├── test_template_file_path_traversal                 filename="../../etc/passwd" → rejected
└── test_export_filename_sanitized                    filename="log;rm -rf" → sanitized
```

### 6.2. Authorization Security

```
tests/Security/AuthorizationTest.php

TEST GROUP: Client Isolation
├── test_client_cannot_access_other_clients_domain
│   Client A tries to access domain belonging to Client B
│   Assert: HTTP 403 UNAUTHORIZED
│
├── test_client_cannot_see_server_ip_or_credentials
│   Assert: sync_status response contains only hostname, no IP/port/password
│
├── test_client_cannot_modify_system_records
│   Try delete NS record (is_system=true) → HTTP 403 RECORD_PROTECTED
│
├── test_client_cannot_modify_locked_records
│   Try edit locked record → HTTP 403 RECORD_LOCKED
│
├── test_client_cannot_access_admin_endpoints
│   Client calls admin-only endpoint → HTTP 403 ADMIN_REQUIRED
│
└── test_suspended_domain_readonly
    Client tries to add record on suspended domain → HTTP 403 DOMAIN_SUSPENDED

TEST GROUP: CSRF Protection
├── test_post_without_csrf_token_rejected             Missing token → 403
├── test_post_with_invalid_csrf_token_rejected        Wrong token → 403
└── test_get_requests_do_not_require_csrf             GET endpoints work without token
```

### 6.3. Data Leakage

```
tests/Security/DataLeakageTest.php

├── test_error_response_does_not_contain_stack_trace
│   Trigger internal error → assert response has no file paths, class names, SQL
│
├── test_sync_log_does_not_contain_da_password
│   After worker processes job → check sync_log.http_url has no password
│
├── test_audit_trail_does_not_contain_sensitive_data
│   Assert: no server passwords, tokens in audit trail
│
├── test_client_api_response_no_server_details
│   All client endpoints → assert no ip_address, port, password_enc fields
│
├── test_ddns_token_only_shown_once
│   Create token → plain_token in response
│   Get token details → NO plain_token, only masked info
│
└── test_da_password_encrypted_in_database
    Check raw DB value → assert password_enc is not plaintext
```

---

## 7. Performance & Load Tests

> **Tool**: Custom PHP script hoặc Apache Bench (ab)  
> **Env**: Pre-Production  
> **Chạy**: Trước release lớn, khi thay đổi DB schema hoặc queue logic

### 7.1. Response Time Tests

| Test Case | Target | Max | Method |
|-----------|--------|-----|--------|
| Client add record (Ajax) | < 200ms | 500ms | Measure dispatch time (DB write only) |
| Client DNS Editor page load (50 records) | < 1s | 2s | Page load time |
| Admin Dashboard load | < 2s | 3s | Page load + stats queries |
| Admin Sync Logs (10K rows, server-side DataTable) | < 1s | 2s | Ajax with pagination |
| DDNS endpoint response | < 100ms | 200ms | cURL benchmark |
| Sync status poll (Ajax) | < 100ms | 200ms | Simple DB query |
| Queue dispatch (fan-out 3 servers) | < 50ms | 100ms | 3 DB inserts |

### 7.2. Load Tests

```
TEST: test_load_queue_200_jobs_sequential
    Dispatch 200 jobs liên tục (simulating 200 record changes)
    Run worker 1 cycle
    Measure: thời gian xử lý, memory usage, jobs/second
    Target: 150 jobs/minute minimum

TEST: test_load_concurrent_clients_50
    50 clients đồng thời add record (simulating peak traffic)
    Assert: no race condition, no duplicate records
    Assert: all 50 requests complete < 500ms

TEST: test_load_ddns_100_requests_per_minute
    100 DDNS requests trong 1 phút (from different IPs)
    Assert: all valid tokens processed, rate limits enforced correctly
    Assert: average response time < 100ms

TEST: test_load_admin_dashboard_with_500k_sync_logs
    Seed 500,000 sync_log rows
    Load dashboard
    Assert: page loads < 3 seconds
    Assert: queries use indexes (EXPLAIN shows no full table scan)

TEST: test_load_drift_detection_500_domains
    Seed 500 active domains (20 records each = 10,000 records)
    Run DriftDetector
    Measure: total runtime, DA API calls, throttle effectiveness
    Target: complete within 30 minutes
    Assert: 1 request/second throttle maintained
```

### 7.3. Database Performance

```
TEST: test_query_performance_worker_pickup
    Seed: 100,000 queue rows (mixed statuses)
    Run EXPLAIN on worker pickup query:
      SELECT * FROM mod_hvndns_queue
      WHERE status='PENDING' AND (next_retry_at IS NULL OR next_retry_at<=NOW())
      ORDER BY priority ASC, scheduled_at ASC
      LIMIT 150
    Assert: uses idx_worker_pickup index
    Assert: query time < 50ms

TEST: test_query_performance_batch_status
    Seed: 10,000 batches (3 jobs each)
    Query getBatchStatus() for random batch
    Assert: query time < 10ms

TEST: test_query_performance_audit_trail_search
    Seed: 1,000,000 audit_trail rows
    Search by domain + date range
    Assert: query time < 100ms
    Assert: uses idx_domain_time index
```

---

## 8. Regression Tests

> **Mục đích**: Chạy lại mỗi khi deploy để đảm bảo không break tính năng cũ.  
> **Scope**: Subset quan trọng nhất từ Unit + Integration tests.  
> **Chạy**: Tự động trên CI/CD trước mỗi deploy — Target: < 5 phút

### 8.1. Regression Suite — Critical Path

```
Mỗi regression run PHẢI pass 100% các test sau:

CORE QUEUE:
[REG-001] Queue dispatch tạo đúng số jobs theo active servers
[REG-002] Worker process jobs thành công (mock DA success)
[REG-003] Worker handle timeout → FAILED + retry scheduled
[REG-004] Stale job recovery hoạt động
[REG-005] Exponential backoff formula đúng

CORE DNS:
[REG-006] A record validation (valid IP accepted, invalid rejected)
[REG-007] CNAME conflict detection (CNAME + existing A → fail)
[REG-008] Create record → queue dispatched → audit trail written
[REG-009] Edit record → old value saved in history
[REG-010] Delete record → pending_delete flag set

CORE SECURITY:
[REG-011] Client cannot access other client's domain
[REG-012] DA password encrypted in DB
[REG-013] Server IP not exposed to client
[REG-014] CSRF token required for POST requests
[REG-015] SQL injection attempts sanitized

CORE PROVISIONING:
[REG-016] AfterModuleCreate → domain + zone created
[REG-017] AfterModuleTerminate → soft delete + DELETE_ZONE queued
[REG-018] AfterModuleSuspend → domain readonly

DATABASE:
[REG-019] Migration idempotent (run twice no error)
[REG-020] Audit trail append-only (UPDATE/DELETE throws exception)
```

---

## 9. User Acceptance Tests (UAT)

> **Thực hiện bởi**: Product Owner, Support Team, Beta Customers  
> **Env**: Staging  
> **Format**: Checklist thủ công

### 9.1. UAT — Client Area

```
SCENARIO: Khách hàng mới mua dịch vụ DNS
□ Đăng nhập WHMCS Client Area
□ Mở dịch vụ DNS vừa mua
□ Thấy danh sách domain với nameserver cần trỏ
□ Click "Quản lý DNS" → thấy DNS Editor
□ Thấy NS records mặc định (dns1, dns2, dns3) với badge 🟢 Live
□ Thêm record A "test" → 1.2.3.4
□ Thấy record xuất hiện ngay với badge 🟡 Pending
□ Chờ ~1-2 phút → badge chuyển sang 🟢 Live
□ Sửa record: đổi IP thành 5.6.7.8
□ Badge hiện 🔄 Syncing → rồi 🟢 Live
□ Xóa record → confirm dialog → record mờ đi → biến mất sau khi sync
□ Thử thêm record với IP sai (999.999.999.999) → thấy thông báo lỗi rõ ràng
□ Thử xóa NS record → bị chặn "Không thể xóa bản ghi hệ thống"

SCENARIO: Khách hàng sử dụng DDNS
□ Mở tab DDNS → tạo token cho subdomain "cam"
□ Thấy URL endpoint + hướng dẫn Mikrotik/DrayTek
□ Copy URL → gọi bằng trình duyệt → thấy "good {ip}"
□ Gọi lại → thấy "nochg {ip}" (IP không đổi)
□ Kiểm tra bảng DNS → A record "cam" đã được tạo/cập nhật

SCENARIO: Khách hàng bật DNSSEC
□ Mở tab DNSSEC → bấm "Bật DNSSEC"
□ Thấy trạng thái "Đang xử lý..."
□ Chờ sync → thấy bảng DS Record hiện ra
□ Nút Copy hoạt động → paste thấy đúng thông số
□ Hướng dẫn cấu hình nhà đăng ký rõ ràng
```

### 9.2. UAT — Admin Area

```
SCENARIO: Admin quản lý hệ thống
□ Mở module → thấy Dashboard
□ Widget Sync Pipeline hiện số đúng
□ Server Health hiện 3 server, uptime %, response time
□ Activity feed cập nhật real-time

SCENARIO: Admin xử lý sự cố server
□ Disable 1 server → thấy badge thay đổi
□ Job mới chỉ fan-out ra 2 server (không phải 3)
□ Enable lại server → fan-out trở về 3
□ Retry All Failed → jobs quay lại PENDING

SCENARIO: Admin sửa DNS thay client
□ Mở Global Domains → tìm domain khách
□ Click vào → mở DNS Editor với quyền Admin
□ Sửa record → badge hiện "Admin Mode"
□ Kiểm tra Audit Trail → thấy ghi actor=admin

SCENARIO: Admin rollback zone
□ Mở DNS Editor admin → click Rollback
□ Chọn snapshot → thấy preview diff rõ ràng
□ Xác nhận → hệ thống tạo snapshot trước khi rollback
□ Records khôi phục đúng theo snapshot
```

---

## 10. Test Case Matrix — Phase 1

> Mapping test cases ↔ EPICS.md Issues

| EPIC | Issue ID | Test Type | Test Case | Priority |
|------|----------|-----------|-----------|----------|
| 01 | FOUND-001..005 | Integration | Migration tạo đúng bảng + idempotent | P0 |
| 01 | FOUND-006..013 | Unit | Eloquent Models: relationships, scopes, casts | P0 |
| 01 | FOUND-014..018 | Unit | DAGateway: mock HTTP 5 scenarios | P0 |
| 02 | QUEUE-001..005 | Unit | QueueManager: dispatch, fanout, dedup, cancel | P0 |
| 02 | QUEUE-006..011 | Integration | Worker pipeline: PENDING→SYNCING→COMPLETE/FAILED | P0 |
| 02 | QUEUE-012..015 | Unit | Exponential Backoff formula + per-server | P1 |
| 03 | CLIENT-001..005 | E2E/UAT | DNS Editor page load, responsive, Alpine.js reactive | P0 |
| 03 | CLIENT-006..012 | Unit + Integration | Validator (50 cases) + CRUD flow + rate limit | P0 |
| 03 | CLIENT-013..016 | Integration | Sync Tracker polling + status aggregate | P1 |
| 04 | ADMIN-001..005 | Integration + UAT | Server CRUD + Test Connection | P0 |
| 04 | ADMIN-006..009 | Integration + UAT | Global Domains + Admin DNS Editor | P1 |
| 04 | ADMIN-010..014 | Integration | Sync Logs DataTable + Retry + Export | P1 |
| 05 | PROV-001..004 | Integration | Provision/Terminate/Suspend hooks | P0 |

**Phase 1 Total**: ~120 Unit + ~30 Integration + ~5 E2E + 20 UAT checklist items

---

## 11. Test Case Matrix — Phase 2

| EPIC | Feature | Test Type | Key Test Cases | Priority |
|------|---------|-----------|---------------|----------|
| 06 | Dashboard Metrics | Integration + Performance | Stats queries < 2s on 500K rows | P1 |
| 07 | URL Redirect 301/302 | Integration | Create/Edit/Delete redirect → queue → DA | P1 |
| 07 | Masked Redirect | Integration + E2E | Reverse proxy setup, URL hiding | P2 |
| 07 | Auto-SSL | Integration + E2E | Let's Encrypt request → cert installed | P1 |
| 08 | Conflict Resolution | Unit (8 cases) | Admin-Priority, Optimistic Locking | P0 |
| 08 | Webhook Telegram | Integration | Alert trigger → Telegram API called → cooldown | P1 |
| 08 | Webhook Email | Integration | Alert trigger → WHMCS mail sent | P1 |

**Phase 2 Total**: ~8 Unit + ~15 Integration + ~5 E2E + 15 UAT items

---

## 12. Test Case Matrix — Phase 3

| EPIC | Feature | Test Type | Key Test Cases | Priority |
|------|---------|-----------|---------------|----------|
| 09 | DDNS Endpoint | Unit + Integration + E2E | Token auth, IP compare, rate limit, brute force block | P0 |
| 10 | DNSSEC | Integration + E2E | Enable → Get DS → Display → Re-sign after change | P1 |
| 11 | Drift Detection | Integration + Performance | Diff algorithm, 500 domains scan < 30 min | P1 |
| 11 | Zone Rollback | Integration + E2E | Snapshot → Preview diff → Restore → Verify on DA | P1 |
| 12 | Quota Enforcement | Unit (6 cases) | Under/at/over limit, unlimited, admin override | P0 |
| 12 | DNS Templates | Integration | Create template, apply to domain, placeholder replace | P1 |
| 13 | Audit Trail UI | Integration + Security | Append-only, export checksum, filter performance | P1 |
| 13 | Email Forwarding | Integration + E2E | Create forwarder → DA API → verify working | P2 |
| 14 | Bulk Operations | Integration + E2E | Preview → Snapshot → Execute → Progress tracking | P1 |
| 14 | REST API | Integration + Security | Auth, rate limit, CRUD endpoints, same queue path | P1 |

**Phase 3 Total**: ~15 Unit + ~25 Integration + ~10 E2E + 20 UAT items

---

## 13. Bug Severity Classification

| Severity | Định nghĩa | Ví dụ | SLA Fix |
|----------|-----------|-------|---------|
| 🔴 **Critical (S1)** | Hệ thống không hoạt động, mất dữ liệu, hoặc lỗ hổng bảo mật nghiêm trọng | Queue Worker crash loop; SQL injection found; DA password leak; DNS zone bị xóa nhầm | Hotfix trong 4 giờ |
| 🟠 **Major (S2)** | Tính năng chính bị hỏng nhưng có workaround | Client không thể thêm record (nhưng Admin vẫn thêm được thay); Sync status không cập nhật (nhưng DNS thực tế vẫn sync); Webhook không gửi (nhưng Dashboard vẫn hiện alert) | Fix trong 24 giờ |
| 🟡 **Minor (S3)** | Tính năng phụ bị lỗi hoặc UI hiển thị sai | Badge status sai màu; TTL hiện "3600" thay vì "1h"; Pagination sai số trang; Export CSV thiếu 1 cột | Fix trong sprint hiện tại |
| ⚪ **Cosmetic (S4)** | Lỗi giao diện nhỏ, không ảnh hưởng chức năng | Khoảng cách padding không đều; Typo trong label; Icon không align đẹp | Backlog, fix khi rảnh |

### Quy tắc Auto-Escalate

| Điều kiện | Escalate lên |
|-----------|-------------|
| Bug liên quan đến mất dữ liệu DNS | Luôn S1 |
| Bug liên quan đến hiển thị server credentials cho client | Luôn S1 |
| Bug ảnh hưởng > 50% users | Tối thiểu S2 |
| Bug chỉ xảy ra trên 1 browser/device | Tối đa S3 |
| Bug trong Phase 3 features (chưa release) | Tối đa S3 |

---

## 14. Checklist Trước Release

### 14.1. Pre-Release Checklist — Mỗi Phase

```
CODE QUALITY:
□ Tất cả Unit Tests pass (0 failures)
□ Tất cả Integration Tests pass
□ Code coverage ≥ 80% cho Services/ và Validators/
□ Không có TODO/FIXME trong code production
□ PHPDoc đầy đủ cho mọi public method

SECURITY:
□ Security Tests pass (injection, XSS, auth, data leakage)
□ DA password encrypted trong DB (verify manually)
□ Client API responses không chứa server IP/credentials
□ CSRF token enforced trên tất cả POST endpoints
□ Audit Trail ghi đúng cho mọi thao tác thay đổi data

PERFORMANCE:
□ Client add record < 200ms (measure trên staging)
□ Admin Dashboard load < 2s
□ DDNS endpoint < 100ms
□ Worker xử lý ≥ 100 jobs/phút
□ DB queries sử dụng đúng indexes (EXPLAIN verify)

DATABASE:
□ Migration chạy thành công trên staging (fresh install)
□ Migration chạy thành công trên staging (upgrade từ version trước)
□ Migration idempotent (chạy lại không lỗi)
□ Backup database production trước khi deploy

FUNCTIONALITY:
□ Regression Suite pass 100% (20 critical test cases)
□ UAT checklist hoàn thành bởi Product Owner
□ E2E tests pass trên staging (DA sandbox)
□ Cron Worker chạy ổn định trên staging ≥ 24 giờ không crash

DEPLOYMENT:
□ CHANGELOG.md cập nhật
□ Version number bumped trong module config
□ Schema migration version file tạo (nếu có DB changes)
□ Rollback plan documented (biết cách revert nếu deploy fail)
□ Notification settings configured (Telegram/Email cho monitoring)
```

### 14.2. Post-Deploy Verification — Chạy ngay sau deploy

```
□ Module activate thành công trên production
□ DB migration chạy tự động (kiểm tra schema_version)
□ Cron Worker chạy được chu kỳ đầu tiên (kiểm tra Activity Log)
□ Thêm 1 record test trên domain test → verify sync thành công trên tất cả DA nodes
□ Dashboard hiển thị đúng số liệu
□ Telegram notification test gửi thành công (nếu configured)
□ Xóa record test vừa tạo
□ Kiểm tra production error logs — không có exception mới
```

---

> **Tài liệu này là phiên bản sống (living document)**. Cập nhật test cases khi thêm tính năng mới hoặc phát hiện regression.

## Changelog
| Ngày | Thay đổi | Người thực hiện |
|------|----------|-----------------|
| 25/02/2026 | Khởi tạo v1.0 — Full test plan 3 phases | — |
