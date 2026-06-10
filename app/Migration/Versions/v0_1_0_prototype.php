<?php

namespace MJ\DnsManager\Migration\Versions;

defined("WHMCS") or die("Access Denied");

use Illuminate\Database\Capsule\Manager as Capsule;

class v0_1_0_prototype
{
    public function up()
    {
        $schema = Capsule::schema();

        // 1. tbl_mj_dns_schema_version
        if (!$schema->hasTable('tbl_mj_dns_schema_version')) {
            Capsule::statement("CREATE TABLE tbl_mj_dns_schema_version (
                id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
                version VARCHAR(20) NOT NULL,
                description VARCHAR(255) NULL,
                executed_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
                UNIQUE INDEX uniq_version (version)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;");
        }

        // 3B. tbl_mj_dns_settings
        if (!$schema->hasTable('tbl_mj_dns_settings')) {
            Capsule::statement("CREATE TABLE tbl_mj_dns_settings (
                id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
                setting_key VARCHAR(100) NOT NULL,
                setting_val TEXT NULL,
                created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
                updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                UNIQUE INDEX uniq_key (setting_key)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;");
        }

        // 4. tbl_mj_dns_servers
        if (!$schema->hasTable('tbl_mj_dns_servers')) {
            Capsule::statement("CREATE TABLE tbl_mj_dns_servers (
                id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
                hostname VARCHAR(255) NOT NULL,
                ip_address VARCHAR(45) NOT NULL,
                port SMALLINT UNSIGNED NOT NULL DEFAULT 2222,
                username VARCHAR(100) NOT NULL,
                password_enc TEXT NOT NULL,
                use_ssl TINYINT(1) NOT NULL DEFAULT 1,
                role ENUM('primary','secondary') NOT NULL DEFAULT 'secondary',
                is_active TINYINT(1) NOT NULL DEFAULT 1,
                max_concurrent SMALLINT UNSIGNED NOT NULL DEFAULT 50,
                backoff_until DATETIME NULL,
                backoff_count TINYINT UNSIGNED NOT NULL DEFAULT 0,
                last_success_at DATETIME NULL,
                last_error_at DATETIME NULL,
                last_error_msg TEXT NULL,
                sort_order TINYINT UNSIGNED NOT NULL DEFAULT 0,
                notes TEXT NULL,
                created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
                updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                UNIQUE INDEX uniq_hostname (hostname),
                INDEX idx_active (is_active),
                INDEX idx_backoff (backoff_until)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;");
        }

        // 5. tbl_mj_dns_domains
        if (!$schema->hasTable('tbl_mj_dns_domains')) {
            Capsule::statement("CREATE TABLE tbl_mj_dns_domains (
                id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
                domain VARCHAR(253) NOT NULL,
                whmcs_domain_id INT UNSIGNED NULL COMMENT 'tbldomains.id (domain registration)',
                whmcs_user_id INT UNSIGNED NOT NULL,
                status ENUM('active','suspended','terminated','pending_delete') NOT NULL DEFAULT 'active',
                ssl_status ENUM('none','pending','active','expired','failed') NOT NULL DEFAULT 'none',
                ssl_expires_at DATETIME NULL,
                default_ip VARCHAR(45) NULL,
                notes TEXT NULL,
                provisioned_at DATETIME NULL,
                suspended_at DATETIME NULL,
                terminated_at DATETIME NULL,
                created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
                updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                UNIQUE INDEX uniq_domain (domain),
                INDEX idx_whmcs_user (whmcs_user_id),
                INDEX idx_whmcs_domain (whmcs_domain_id),
                INDEX idx_status (status)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;");
        }

        // 6. tbl_mj_dns_records
        if (!$schema->hasTable('tbl_mj_dns_records')) {
            Capsule::statement("CREATE TABLE tbl_mj_dns_records (
                id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
                domain_id INT UNSIGNED NOT NULL,
                type ENUM('A','AAAA','CNAME','MX','TXT','SRV','NS','CAA','PTR') NOT NULL,
                name VARCHAR(255) NOT NULL,
                value TEXT NOT NULL,
                ttl INT UNSIGNED NOT NULL DEFAULT 3600,
                priority SMALLINT UNSIGNED NULL,
                weight SMALLINT UNSIGNED NULL,
                port SMALLINT UNSIGNED NULL,
                is_system TINYINT(1) NOT NULL DEFAULT 0,
                is_locked TINYINT(1) NOT NULL DEFAULT 0,
                pending_delete TINYINT(1) NOT NULL DEFAULT 0,
                created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
                updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                INDEX idx_domain_type (domain_id, type),
                INDEX idx_domain_name (domain_id, name),
                FOREIGN KEY (domain_id) REFERENCES tbl_mj_dns_domains(id) ON DELETE CASCADE
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;");
        }

        // 7. tbl_mj_dns_queue
        if (!$schema->hasTable('tbl_mj_dns_queue')) {
            Capsule::statement("CREATE TABLE tbl_mj_dns_queue (
                id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
                batch_id CHAR(36) NOT NULL,
                domain_id INT UNSIGNED NOT NULL,
                server_id INT UNSIGNED NOT NULL,
                action ENUM('ADD_RECORD','EDIT_RECORD','DELETE_RECORD','CREATE_ZONE','DELETE_ZONE','CREATE_REDIRECT','EDIT_REDIRECT','DELETE_REDIRECT','CREATE_EMAIL_FWD','DELETE_EMAIL_FWD','ENABLE_DNSSEC','DISABLE_DNSSEC','RESIGN_ZONE','REQUEST_SSL','RENEW_SSL','FETCH_DS_RECORDS','APPLY_TEMPLATE') NOT NULL,
                payload JSON NOT NULL,
                status ENUM('PENDING','SYNCING','COMPLETE','FAILED','CANCELLED','PERMANENTLY_FAILED') NOT NULL DEFAULT 'PENDING',
                priority TINYINT UNSIGNED NOT NULL DEFAULT 5,
                attempts TINYINT UNSIGNED NOT NULL DEFAULT 0,
                max_attempts TINYINT UNSIGNED NOT NULL DEFAULT 5,
                next_retry_at DATETIME NULL,
                locked_by VARCHAR(50) NULL,
                locked_at DATETIME NULL,
                error_message TEXT NULL,
                error_type VARCHAR(50) NULL,
                actor_type ENUM('client','admin','system','api') NOT NULL DEFAULT 'client',
                actor_id INT UNSIGNED NULL,
                scheduled_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
                started_at DATETIME NULL,
                completed_at DATETIME NULL,
                created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
                INDEX idx_worker_pickup (status, next_retry_at, priority, scheduled_at),
                INDEX idx_batch (batch_id),
                INDEX idx_domain_status (domain_id, status),
                INDEX idx_server_status (server_id, status),
                INDEX idx_locked (locked_by, locked_at),
                FOREIGN KEY (domain_id) REFERENCES tbl_mj_dns_domains(id),
                FOREIGN KEY (server_id) REFERENCES tbl_mj_dns_servers(id)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;");
        }

        // 8. tbl_mj_dns_sync_logs
        if (!$schema->hasTable('tbl_mj_dns_sync_logs')) {
            Capsule::statement("CREATE TABLE tbl_mj_dns_sync_logs (
                id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
                queue_id INT UNSIGNED NOT NULL,
                server_id INT UNSIGNED NOT NULL,
                http_method VARCHAR(10) NULL,
                http_url VARCHAR(500) NULL,
                http_status SMALLINT UNSIGNED NULL,
                request_body TEXT NULL,
                response_body TEXT NULL,
                duration_ms INT UNSIGNED NULL,
                success TINYINT(1) NOT NULL,
                error_type VARCHAR(50) NULL,
                created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
                INDEX idx_queue (queue_id),
                INDEX idx_server_time (server_id, created_at),
                INDEX idx_success_time (success, created_at),
                FOREIGN KEY (queue_id) REFERENCES tbl_mj_dns_queue(id),
                FOREIGN KEY (server_id) REFERENCES tbl_mj_dns_servers(id)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;");
        }

        // 9. tbl_mj_dns_audit_trail
        if (!$schema->hasTable('tbl_mj_dns_audit_trail')) {
            Capsule::statement("CREATE TABLE tbl_mj_dns_audit_trail (
                id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
                actor_type ENUM('client','admin','system','api') NOT NULL,
                actor_id INT UNSIGNED NULL,
                actor_name VARCHAR(255) NULL,
                domain VARCHAR(253) NOT NULL,
                domain_id INT UNSIGNED NULL,
                action VARCHAR(50) NOT NULL,
                target_type VARCHAR(50) NULL,
                target_id INT UNSIGNED NULL,
                old_value JSON NULL,
                new_value JSON NULL,
                context VARCHAR(100) NULL,
                ip_address VARCHAR(45) NOT NULL,
                user_agent VARCHAR(500) NULL,
                session_id VARCHAR(100) NULL,
                notes TEXT NULL,
                created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
                INDEX idx_domain_time (domain, created_at),
                INDEX idx_actor (actor_type, actor_id, created_at),
                INDEX idx_action_time (action, created_at),
                INDEX idx_ip_time (ip_address, created_at)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;");
        }

        // 10. tbl_mj_dns_record_history
        if (!$schema->hasTable('tbl_mj_dns_record_history')) {
            Capsule::statement("CREATE TABLE tbl_mj_dns_record_history (
                id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
                record_id INT UNSIGNED NOT NULL,
                domain_id INT UNSIGNED NOT NULL,
                change_type ENUM('created','updated','deleted') NOT NULL,
                old_type VARCHAR(10) NULL,
                old_name VARCHAR(255) NULL,
                old_value TEXT NULL,
                old_ttl INT UNSIGNED NULL,
                old_priority SMALLINT UNSIGNED NULL,
                new_type VARCHAR(10) NULL,
                new_name VARCHAR(255) NULL,
                new_value TEXT NULL,
                new_ttl INT UNSIGNED NULL,
                new_priority SMALLINT UNSIGNED NULL,
                changed_by_type ENUM('client','admin','system','api') NOT NULL,
                changed_by_id INT UNSIGNED NULL,
                created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
                INDEX idx_record_time (record_id, created_at),
                INDEX idx_domain_time (domain_id, created_at)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;");
        }

        // 11. tbl_mj_dns_snapshots
        if (!$schema->hasTable('tbl_mj_dns_snapshots')) {
            Capsule::statement("CREATE TABLE tbl_mj_dns_snapshots (
                id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
                domain_id INT UNSIGNED NOT NULL,
                snapshot_type ENUM('scheduled','pre_bulk','pre_template','manual') NOT NULL DEFAULT 'scheduled',
                records_data JSON NOT NULL,
                record_count SMALLINT UNSIGNED NOT NULL,
                trigger_info VARCHAR(255) NULL,
                created_by ENUM('system','admin') NOT NULL DEFAULT 'system',
                created_by_id INT UNSIGNED NULL,
                created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
                INDEX idx_domain_time (domain_id, created_at),
                FOREIGN KEY (domain_id) REFERENCES tbl_mj_dns_domains(id) ON DELETE CASCADE
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;");
        }

        // 12. tbl_mj_dns_templates
        if (!$schema->hasTable('tbl_mj_dns_templates')) {
            Capsule::statement("CREATE TABLE tbl_mj_dns_templates (
                id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
                name VARCHAR(100) NOT NULL,
                description TEXT NULL,
                is_default TINYINT(1) NOT NULL DEFAULT 0,
                records_data JSON NOT NULL,
                is_visible_client TINYINT(1) NOT NULL DEFAULT 1,
                created_by_user_id INT UNSIGNED NULL,
                created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
                updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                UNIQUE INDEX uniq_name (name)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;");
        }

        // 14. tbl_mj_dns_dnssec
        if (!$schema->hasTable('tbl_mj_dns_dnssec')) {
            Capsule::statement("CREATE TABLE tbl_mj_dns_dnssec (
                id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
                domain_id INT UNSIGNED NOT NULL,
                is_enabled TINYINT(1) NOT NULL DEFAULT 0,
                key_tag INT UNSIGNED NULL,
                algorithm SMALLINT UNSIGNED NULL,
                digest_type SMALLINT UNSIGNED NULL,
                digest VARCHAR(512) NULL,
                ds_record_raw TEXT NULL,
                public_key TEXT NULL,
                last_signed_at DATETIME NULL,
                created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
                updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                UNIQUE INDEX uniq_domain (domain_id),
                FOREIGN KEY (domain_id) REFERENCES tbl_mj_dns_domains(id) ON DELETE CASCADE
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;");
        }

        // 15. tbl_mj_dns_ddns_tokens
        if (!$schema->hasTable('tbl_mj_dns_ddns_tokens')) {
            Capsule::statement("CREATE TABLE tbl_mj_dns_ddns_tokens (
                id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
                domain_id INT UNSIGNED NOT NULL,
                subdomain VARCHAR(255) NOT NULL DEFAULT '@',
                token_hash CHAR(64) NOT NULL,
                label VARCHAR(100) NULL,
                last_ip VARCHAR(45) NULL,
                last_update_at DATETIME NULL,
                last_request_at DATETIME NULL,
                is_active TINYINT(1) NOT NULL DEFAULT 1,
                request_count INT UNSIGNED NOT NULL DEFAULT 0,
                created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
                UNIQUE INDEX uniq_token_hash (token_hash),
                INDEX idx_domain (domain_id),
                FOREIGN KEY (domain_id) REFERENCES tbl_mj_dns_domains(id) ON DELETE CASCADE
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;");
        }

        // 16. tbl_mj_dns_redirects
        if (!$schema->hasTable('tbl_mj_dns_redirects')) {
            Capsule::statement("CREATE TABLE tbl_mj_dns_redirects (
                id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
                domain_id INT UNSIGNED NOT NULL,
                source_path VARCHAR(255) NOT NULL DEFAULT '/',
                destination_url VARCHAR(2048) NOT NULL,
                type ENUM('301','302','masked') NOT NULL DEFAULT '301',
                masked_title VARCHAR(255) NULL,
                masked_desc TEXT NULL,
                created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
                updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                INDEX idx_domain (domain_id),
                FOREIGN KEY (domain_id) REFERENCES tbl_mj_dns_domains(id) ON DELETE CASCADE
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;");
        }

        // 17. tbl_mj_dns_email_forwards
        if (!$schema->hasTable('tbl_mj_dns_email_forwards')) {
            Capsule::statement("CREATE TABLE tbl_mj_dns_email_forwards (
                id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
                domain_id INT UNSIGNED NOT NULL,
                source_local VARCHAR(255) NOT NULL,
                destination_email VARCHAR(255) NOT NULL,
                is_catchall TINYINT(1) NOT NULL DEFAULT 0,
                created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
                updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                INDEX idx_domain (domain_id),
                FOREIGN KEY (domain_id) REFERENCES tbl_mj_dns_domains(id) ON DELETE CASCADE
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;");
        }

        // 18. tbl_mj_dns_drift_reports
        if (!$schema->hasTable('tbl_mj_dns_drift_reports')) {
            Capsule::statement("CREATE TABLE tbl_mj_dns_drift_reports (
                id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
                domain_id INT UNSIGNED NOT NULL,
                drift_type ENUM('missing_on_da','added_on_da','modified') NOT NULL,
                record_type VARCHAR(10) NULL,
                record_name VARCHAR(255) NULL,
                local_value JSON NULL,
                remote_value JSON NULL,
                status ENUM('pending','resolved','auto_fixed','ignored') NOT NULL DEFAULT 'pending',
                detected_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
                resolved_at DATETIME NULL,
                INDEX idx_domain (domain_id),
                INDEX idx_status (status),
                FOREIGN KEY (domain_id) REFERENCES tbl_mj_dns_domains(id) ON DELETE CASCADE
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;");
        }

        // 19. tbl_mj_dns_ip_blacklist
        if (!$schema->hasTable('tbl_mj_dns_ip_blacklist')) {
            Capsule::statement("CREATE TABLE tbl_mj_dns_ip_blacklist (
                id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
                ip_address VARCHAR(45) NOT NULL,
                reason VARCHAR(255) NOT NULL,
                blocked_until DATETIME NOT NULL,
                created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
                UNIQUE INDEX uniq_ip (ip_address),
                INDEX idx_expiry (blocked_until)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;");
        }

        // 20. tbl_mj_dns_notification_cooldowns
        if (!$schema->hasTable('tbl_mj_dns_notification_cooldowns')) {
            Capsule::statement("CREATE TABLE tbl_mj_dns_notification_cooldowns (
                id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
                rule_id VARCHAR(50) NOT NULL,
                target_id VARCHAR(50) NOT NULL DEFAULT 'global',
                last_sent_at DATETIME NOT NULL,
                UNIQUE INDEX uniq_rule_target (rule_id, target_id)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;");
        }

        // ── Patch: Add nameservers column to tbl_mj_dns_servers (idempotent) ──
        if ($schema->hasTable('tbl_mj_dns_servers')) {
            if (!$schema->hasColumn('tbl_mj_dns_servers', 'nameservers')) {
                Capsule::statement("ALTER TABLE tbl_mj_dns_servers ADD COLUMN nameservers TEXT NULL COMMENT 'JSON array of nameservers e.g. [\"ns1.hvn.vn\",\"ns2.hvn.vn\"]' AFTER notes");
            }
        }

        // ── Patch: Mở rộng ENUM action trong tbl_mj_dns_queue ─────────────────
        // Thêm FETCH_DS_RECORDS và APPLY_TEMPLATE vào ENUM
        // Idempotent: kiểm tra xem APPLY_TEMPLATE đã có trong ENUM chưa trước khi ALTER
        if ($schema->hasTable('tbl_mj_dns_queue')) {
            $enumDef = Capsule::selectOne(
                "SELECT COLUMN_TYPE FROM information_schema.COLUMNS
                  WHERE TABLE_SCHEMA = DATABASE()
                    AND TABLE_NAME = 'tbl_mj_dns_queue'
                    AND COLUMN_NAME = 'action'"
            );
            $currentEnum = $enumDef ? (string) $enumDef->COLUMN_TYPE : '';

            if (strpos($currentEnum, 'APPLY_TEMPLATE') === false) {
                Capsule::statement(
                    "ALTER TABLE tbl_mj_dns_queue
                     MODIFY COLUMN action
                     ENUM('ADD_RECORD','EDIT_RECORD','DELETE_RECORD','CREATE_ZONE','DELETE_ZONE',
                          'CREATE_REDIRECT','EDIT_REDIRECT','DELETE_REDIRECT',
                          'CREATE_EMAIL_FWD','DELETE_EMAIL_FWD',
                          'ENABLE_DNSSEC','DISABLE_DNSSEC','RESIGN_ZONE',
                          'REQUEST_SSL','RENEW_SSL',
                          'FETCH_DS_RECORDS','APPLY_TEMPLATE') NOT NULL"
                );
            }
        }

        // ── Patch: Add synced_at column to tbl_mj_dns_email_forwards (idempotent) ──
        // Đánh dấu thời điểm forwarder được đồng bộ thành công lên DA server.
        // NULL = chưa sync (pending), NOT NULL = đã sync thành công.
        if ($schema->hasTable('tbl_mj_dns_email_forwards')) {
            if (!$schema->hasColumn('tbl_mj_dns_email_forwards', 'synced_at')) {
                Capsule::statement("ALTER TABLE tbl_mj_dns_email_forwards ADD COLUMN synced_at DATETIME NULL DEFAULT NULL COMMENT 'Thời điểm sync thành công lên DA. NULL = chưa sync.' AFTER is_catchall");
            }
        }
    }

    public function down()
    {
        $schema = Capsule::schema();
        // Drop in reverse order of foreign key dependencies
        $schema->dropIfExists('tbl_mj_dns_notification_cooldowns');
        $schema->dropIfExists('tbl_mj_dns_ip_blacklist');
        $schema->dropIfExists('tbl_mj_dns_drift_reports');
        $schema->dropIfExists('tbl_mj_dns_email_forwards');
        $schema->dropIfExists('tbl_mj_dns_redirects');
        $schema->dropIfExists('tbl_mj_dns_ddns_tokens');
        $schema->dropIfExists('tbl_mj_dns_dnssec');
        $schema->dropIfExists('tbl_mj_dns_templates');
        $schema->dropIfExists('tbl_mj_dns_snapshots');
        $schema->dropIfExists('tbl_mj_dns_record_history');
        $schema->dropIfExists('tbl_mj_dns_audit_trail');
        $schema->dropIfExists('tbl_mj_dns_sync_logs');
        $schema->dropIfExists('tbl_mj_dns_queue');
        $schema->dropIfExists('tbl_mj_dns_records');
        $schema->dropIfExists('tbl_mj_dns_domains');
        $schema->dropIfExists('tbl_mj_dns_servers');
        $schema->dropIfExists('tbl_mj_dns_settings');
        $schema->dropIfExists('tbl_mj_dns_schema_version');
    }
}
