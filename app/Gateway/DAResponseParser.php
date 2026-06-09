<?php

namespace MJ\DnsManager\Gateway;

/**
 * DAResponseParser — Helper class to normalize DirectAdmin API responses 
 * (specifically DNS records) into standard WHMCS format mapping.
 */
class DAResponseParser
{
    /**
     * Parse DA record format → WHMCS record format
     *
     * @param array $daRecord A single record array from DA's API response
     * @return array Standardized array matching tbl_mj_dns_records structure
     */
    public static function parseRecord(array $daRecord): array
    {
        $name = isset($daRecord['name']) && $daRecord['name'] === '' ? '@' : ($daRecord['name'] ?? '@');
        $value = $daRecord['value'] ?? '';
        $type = strtoupper($daRecord['type'] ?? '');

        // DA root name representation varies depending on endpoint context, but is typically empty or the dot-appended domain name.
        if (substr($name, -1) === '.') {
            $name = '@'; // Fallback root domain
        }

        // Strip TXT outer quotes if present
        if ($type === 'TXT' && substr($value, 0, 1) === '"' && substr($value, -1) === '"') {
            $value = substr($value, 1, -1);
            $value = stripslashes($value);
        }

        // Trim FQDN trailing dot (CNAME, MX, NS) because DA API returns trailing dots
        if (in_array($type, ['CNAME', 'MX', 'NS', 'SRV']) && substr($value, -1) === '.') {
            $value = rtrim($value, '.');
        }

        // Base mapping
        $result = [
            'type' => $type,
            'name' => $name,
            'value' => $value,
            'ttl' => (int) ($daRecord['ttl'] ?? 3600),
            'priority' => isset($daRecord['priority']) ? (int) $daRecord['priority'] : null,
        ];

        // Parse SRV: value = "{weight} {port} {target}" (Format in DA response vs what we need)
        if ($type === 'SRV') {
            $parts = explode(' ', $daRecord['value'], 3);
            if (count($parts) === 3) {
                $result['weight'] = (int) $parts[0];
                $result['port'] = (int) $parts[1];
                $result['value'] = rtrim($parts[2], '.'); // strip trailing dot for SRV target
            }
        }

        return $result;
    }

    /**
     * Build DA record format ← WHMCS record format
     * Used for preparing parameters to send back to DA API (add/edit/delete)
     *
     * @param array $record The local WHMCS record mapped format
     * @return array The param array to send to DA
     */
    public static function buildDAParams(array $record): array
    {
        $name = $record['name'] === '@' ? '' : $record['name'];
        $value = $record['value'];
        $type = strtoupper($record['type']);

        // CNAME, MX, NS require trailing dot for DA API parameters
        if (in_array($type, ['CNAME', 'MX', 'NS']) && substr($value, -1) !== '.') {
            $value .= '.';
        }

        // TXT requires quotes for DA API parameters
        if ($type === 'TXT') {
            $value = '"' . addslashes($value) . '"';
        }

        // SRV format construction: "weight port target."
        if ($type === 'SRV') {
            $target = $record['value'];
            if (substr($target, -1) !== '.') {
                $target .= '.';
            }
            $value = ($record['weight'] ?? 0) . ' ' . ($record['port'] ?? 0) . ' ' . $target;
        }

        $params = [
            'type' => $type,
            'name' => $name,
            'value' => $value,
        ];

        if (isset($record['priority']) && in_array($type, ['MX', 'SRV'])) {
            $params['priority'] = (string) $record['priority'];
        }

        return $params;
    }
}
