<?php

namespace HvnGroup\DnsManager\Security;

class InputSanitizer
{
    /**
     * Làm sạch dữ liệu đầu vào chung
     */
    public static function clean(string $input): string
    {
        $input = trim($input);
        return htmlspecialchars($input, ENT_QUOTES, 'UTF-8');
    }

    /**
     * Làm sạch giá trị của DNS record tùy theo loại bản ghi
     */
    public static function cleanRecordValue(string $type, string $value): string
    {
        $value = trim($value);
        $type = strtoupper($type);

        switch ($type) {
            case 'A':
            case 'AAAA':
                // Giữ lại số và dấu chấm/hai chấm
                return preg_replace('/[^a-fA-F0-9\.:]/', '', $value);

            case 'CNAME':
            case 'MX':
            case 'NS':
            case 'SRV':
            case 'PTR':
                $value = preg_replace('/[^a-zA-Z0-9._\-]/', '', $value);
                return $value;

            case 'TXT':
                return strip_tags($value);

            case 'CAA':
                return strip_tags($value);

            default:
                return self::clean($value);
        }
    }

    /**
     * Làm sạch tên bản ghi (name)
     */
    public static function cleanRecordName(string $name): string
    {
        $name = trim($name);

        if ($name === '@' || $name === '*') {
            return $name;
        }

        // Kí tự chuẩn cho subdomain: a-z, 0-9, dấu trừ, dấu gạch dưới (VD: _dmarc)
        return preg_replace('/[^a-zA-Z0-9\.-_]/', '', $name);
    }
}
