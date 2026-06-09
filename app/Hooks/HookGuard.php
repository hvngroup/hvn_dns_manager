<?php

namespace MJ\DnsManager\Hooks;

defined("WHMCS") or die("Access Denied");

use Illuminate\Database\Capsule\Manager as Capsule;

/**
 * HookGuard — Shared validation logic for domain registrar lifecycle hooks.
 *
 * Provides guard methods to filter out events that should not trigger DNS
 * provisioning. Used by AfterRegistrarRegistration, AfterRegistrarTransfer,
 * and other registrar-related hooks.
 *
 * Source of truth: tbldomains (domain registration), NOT tblhosting (hosting service).
 */
trait HookGuard
{
    /**
     * Run all validation guards. Returns true if DNS provisioning should proceed.
     *
     * Guard chain:
     *   1. userId > 0 and domainId > 0
     *   2. domain is a valid FQDN (RFC 1035 compliant)
     *   3. Domain exists in tbldomains with matching id
     *
     * @param  string $domainName  Domain from hook $params (e.g. "example.com").
     * @param  int    $userId      WHMCS client ID (tblclients.id).
     * @param  int    $domainId    tbldomains.id
     * @param  string $hookName    Hook name for logging (e.g. 'AfterRegistrarRegistration').
     * @return bool  True = proceed. False = skip silently.
     */
    protected static function passesGuards(
        string $domainName,
        int $userId,
        int $domainId,
        string $hookName
    ): bool {
        // Guard 1: Presence
        if (empty($domainName) || $userId === 0 || $domainId === 0) {
            return false;
        }

        // Guard 2: Valid FQDN
        if (!self::isValidFqdn($domainName)) {
            if (!empty($domainName)) {
                logActivity("MJ DNS Manager [{$hookName}]: Skipped '{$domainName}' — not a valid FQDN.");
            }
            return false;
        }

        // Guard 3: Domain exists in tbldomains
        $domainInfo = self::getDomainInfo($domainId, $hookName);
        if (!$domainInfo) {
            return false;
        }

        return true;
    }

    /**
     * Validate that a string is a plausible FQDN.
     *
     * Rules (RFC 1035):
     *   - Must contain at least one dot
     *   - Must NOT be an IP address
     *   - Must NOT contain spaces
     *   - Each label: 1–63 chars, alphanumeric + hyphens (no leading/trailing hyphen)
     *   - TLD (last label): minimum 2 chars
     *   - Total max 253 chars
     *
     * @param  string $domain
     * @return bool
     */
    protected static function isValidFqdn(string $domain): bool
    {
        if (empty($domain) || strpos($domain, ' ') !== false) {
            return false;
        }

        // Reject plain IP addresses
        if (filter_var($domain, FILTER_VALIDATE_IP)) {
            return false;
        }

        // Must have at least one dot
        if (strpos($domain, '.') === false) {
            return false;
        }

        // Total length (RFC 1035: max 253)
        if (strlen($domain) > 253) {
            return false;
        }

        // Validate each label
        $labels = explode('.', rtrim($domain, '.'));

        foreach ($labels as $label) {
            if (empty($label) || strlen($label) > 63) {
                return false;
            }
            // Alphanumeric + hyphens, no leading or trailing hyphen
            if (!preg_match('/^[a-zA-Z0-9]([a-zA-Z0-9\-]*[a-zA-Z0-9])?$/', $label)) {
                return false;
            }
        }

        // TLD must be at least 2 chars (catches ".vn", ".com", ".io")
        if (strlen(end($labels)) < 2) {
            return false;
        }

        return true;
    }

    /**
     * Query tbldomains to verify the domain record exists.
     *
     * Returns null if:
     *   - domainId not found in tbldomains
     *   - DB query throws exception
     *
     * @param  int    $domainId  tbldomains.id
     * @param  string $hookName  For logging.
     * @return array|null
     */
    protected static function getDomainInfo(int $domainId, string $hookName): ?array
    {
        try {
            $row = Capsule::table('tbldomains')
                ->where('id', $domainId)
                ->select([
                    'id       as domain_id',
                    'userid',
                    'domain',
                    'status',
                    'registrar',
                    'registrationperiod',
                    'expirydate',
                ])
                ->first();

            return $row ? (array) $row : null;
        } catch (\Exception $e) {
            logActivity("MJ DNS Manager [{$hookName}]: DB lookup failed for domain #{$domainId} — " . $e->getMessage());
            return null;
        }
    }
}
