<?php

namespace MJ\DnsManager\Hooks;

defined("WHMCS") or die("Access Denied");

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

}
