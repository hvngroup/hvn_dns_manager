<?php

namespace MJ\DnsManager\Validators;

defined("WHMCS") or die("Access Denied");

/**
 * DnsRecordValidator — Validate DNS record data trước khi lưu vào DB và Queue.
 *
 * Tuân thủ SPEC.md Section 9.3 và AGENT.md Section 2.3.
 * Mọi input từ Client/Admin PHẢI đi qua validator này trước khi dispatch.
 *
 * @package MJ\DnsManager\Validators
 * @since   1.0.0
 */
class DnsRecordValidator
{
    /**
     * @var array Lưu trữ các lỗi validation (field => message)
     */
    protected $errors = [];

    /**
     * Danh sách loại record hợp lệ.
     */
    const ALLOWED_TYPES = ['A', 'AAAA', 'CNAME', 'MX', 'TXT', 'SRV', 'NS', 'CAA', 'PTR'];

    /**
     * Giới hạn TTL hợp lệ.
     */
    const TTL_MIN = 60;
    const TTL_MAX = 86400;

    /**
     * Giới hạn độ dài tối đa của TXT record.
     */
    const TXT_MAX_LENGTH = 4096;

    // ─────────────────────────────────────────────────────────────────────────
    // Public API
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * Validate toàn bộ data của 1 DNS record.
     *
     * @param  array $data     Input data cần validate.
     *                         Required keys: type, name, value, ttl
     *                         Optional keys: priority, weight, port
     * @param  bool  $isUpdate True khi đang update (bỏ qua validate type change).
     * @return bool  True nếu hợp lệ, False nếu có lỗi.
     */
    public function validate(array $data, $isUpdate = false)
    {
        $this->errors = [];

        $type = isset($data['type']) ? strtoupper(trim($data['type'])) : '';

        $this->validateType($type);
        $this->validateName($data['name'] ?? '');
        $this->validateTtl($data['ttl'] ?? 3600);

        // Chỉ validate value/priority/weight/port nếu type hợp lệ
        if (in_array($type, self::ALLOWED_TYPES)) {
            $this->validateValueByType($type, $data['value'] ?? '');
            $this->validatePriorityFields($type, $data);
        }

        return empty($this->errors);
    }


    /**
     * Lấy tất cả lỗi validation.
     *
     * @return array Array dạng [field => message].
     */
    public function getErrors()
    {
        return $this->errors;
    }

    /**
     * Lấy lỗi đầu tiên (dùng cho response trả về client).
     *
     * @return array|null ['field' => string, 'message' => string] hoặc null nếu không có lỗi.
     */
    public function getFirstError()
    {
        if (empty($this->errors)) {
            return null;
        }
        
        reset($this->errors);
        $field = key($this->errors);
        return [
            'field' => $field,
            'message' => $this->errors[$field],
        ];
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Private validate methods
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * Validate loại record.
     */
    private function validateType($type)
    {
        if ($type === '') {
            $this->addError('type', 'Loại bản ghi không được để trống.');
            return;
        }
        if (!in_array($type, self::ALLOWED_TYPES)) {
            $this->addError('type', "Loại bản ghi '{$type}' không hợp lệ. Chỉ chấp nhận: " . implode(', ', self::ALLOWED_TYPES) . '.');
        }
    }

    /**
     * Validate tên bản ghi (subdomain / host).
     * Cho phép: @, *, a-z, 0-9, dấu gạch nối, dấu chấm, dấu gạch dưới.
     * Theo RFC 1035: mỗi label ≤ 63 ký tự, tổng ≤ 253 ký tự.
     */
    private function validateName($name)
    {
        $name = trim((string) $name);

        if ($name === '') {
            $this->addError('name', 'Tên bản ghi không được để trống. Dùng "@" cho root domain.');
            return;
        }

        // @ và * là giá trị đặc biệt hợp lệ
        if ($name === '@' || $name === '*') {
            return;
        }

        // Wildcard chỉ được ở đầu: *.sub hoặc *
        if (strpos($name, '*') !== false && substr($name, 0, 2) !== '*.') {
            $this->addError('name', 'Wildcard chỉ được đặt ở đầu (VD: *.sub.domain).');
            return;
        }

        // Tổng độ dài
        if (strlen($name) > 253) {
            $this->addError('name', 'Tên bản ghi quá dài (tối đa 253 ký tự).');
            return;
        }

        // Cho phép: chữ, số, dấu gạch nối, dấu chấm, dấu gạch dưới (cho _dmarc, _sip._tcp)
        if (!preg_match('/^[a-zA-Z0-9_\.\-\*]+$/', $name)) {
            $this->addError('name', 'Tên bản ghi chứa ký tự không hợp lệ. Chỉ được dùng chữ cái, số, dấu (-), dấu (_), dấu (.).');
            return;
        }

        // Kiểm tra từng label ≤ 63 ký tự
        $labels = explode('.', ltrim($name, '*.'));
        foreach ($labels as $label) {
            if (strlen($label) > 63) {
                $this->addError('name', "Label '{$label}' trong tên bản ghi quá dài (tối đa 63 ký tự).");
                return;
            }
        }
    }

    /**
     * Validate TTL.
     * Range hợp lệ: TTL_MIN (60) đến TTL_MAX (86400).
     */
    private function validateTtl($ttl)
    {
        $ttl = (int) $ttl;
        if ($ttl < self::TTL_MIN || $ttl > self::TTL_MAX) {
            $this->addError('ttl', 'TTL phải nằm trong khoảng ' . self::TTL_MIN . '–' . self::TTL_MAX . ' giây (1 phút đến 24 giờ).');
        }
    }

    /**
     * Validate priority, weight, port theo loại record.
     */
    private function validatePriorityFields($type, array $data)
    {
        if (in_array($type, ['MX', 'SRV'])) {
            $priority = $data['priority'] ?? null;
            if ($priority === null || $priority === '') {
                $this->addError('priority', "Bản ghi {$type} yêu cầu Priority.");
            } elseif (!is_numeric($priority) || (int) $priority < 0 || (int) $priority > 65535) {
                $this->addError('priority', 'Priority phải là số nguyên từ 0 đến 65535.');
            }
        }

        if ($type === 'SRV') {
            $weight = $data['weight'] ?? null;
            if ($weight === null || $weight === '') {
                $this->addError('weight', 'Bản ghi SRV yêu cầu Weight.');
            } elseif (!is_numeric($weight) || (int) $weight < 0 || (int) $weight > 65535) {
                $this->addError('weight', 'Weight phải là số nguyên từ 0 đến 65535.');
            }

            $port = $data['port'] ?? null;
            if ($port === null || $port === '') {
                $this->addError('port', 'Bản ghi SRV yêu cầu Port.');
            } elseif (!is_numeric($port) || (int) $port < 1 || (int) $port > 65535) {
                $this->addError('port', 'Port phải là số nguyên từ 1 đến 65535.');
            }
        }
    }

    /**
     * Validate giá trị (value) tùy theo loại bản ghi.
     * Áp dụng RFC-specific rules cho từng type.
     */
    private function validateValueByType($type, $value)
    {
        $value = trim((string) $value);

        if ($value === '') {
            $this->addError('value', 'Giá trị bản ghi không được để trống.');
            return;
        }

        switch ($type) {
            case 'A':
                $this->validateIPv4($value);
                break;

            case 'AAAA':
                $this->validateIPv6($value);
                break;

            case 'CNAME':
                $this->validateFqdn($value, 'CNAME');
                // CNAME không được trỏ về chính root domain
                if ($value === '@') {
                    $this->addError('value', 'CNAME không thể trỏ về root domain (@). Dùng A record thay thế.');
                }
                break;

            case 'MX':
                // RFC 2181: MX target KHÔNG được là IP address
                if (filter_var($value, FILTER_VALIDATE_IP)) {
                    $this->addError('value', 'MX record phải trỏ về hostname, không được dùng địa chỉ IP trực tiếp (RFC 2181).');
                } else {
                    $this->validateFqdn($value, 'MX');
                }
                break;

            case 'NS':
                $this->validateFqdn($value, 'NS');
                break;

            case 'PTR':
                $this->validateFqdn($value, 'PTR');
                break;

            case 'SRV':
                $this->validateFqdn($value, 'SRV');
                break;

            case 'TXT':
                $this->validateTxt($value);
                break;

            case 'CAA':
                $this->validateCaa($value);
                break;
        }
    }

    /**
     * Validate địa chỉ IPv4.
     */
    private function validateIPv4($value)
    {
        if (!filter_var($value, FILTER_VALIDATE_IP, FILTER_FLAG_IPV4)) {
            $this->addError('value', "Địa chỉ IPv4 không hợp lệ: '{$value}'. Đúng format: 103.45.67.89");
        }
    }

    /**
     * Validate địa chỉ IPv6.
     */
    private function validateIPv6($value)
    {
        if (!filter_var($value, FILTER_VALIDATE_IP, FILTER_FLAG_IPV6)) {
            $this->addError('value', "Địa chỉ IPv6 không hợp lệ: '{$value}'.");
        }
    }

    /**
     * Validate FQDN / hostname.
     * Cho phép trailing dot (DA format).
     * Theo RFC 1035: label 1–63 ký tự, tổng ≤ 253 ký tự.
     */
    private function validateFqdn($value, $context = '')
    {
        // Bỏ trailing dot nếu có để validate
        $check = rtrim($value, '.');

        if ($check === '') {
            $this->addError('value', "Giá trị {$context} không hợp lệ.");
            return;
        }

        if (strlen($check) > 253) {
            $this->addError('value', "Hostname {$context} quá dài (tối đa 253 ký tự).");
            return;
        }

        // Kiểm tra format: a-z, 0-9, dấu gạch nối, dấu chấm
        if (!preg_match('/^[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?)*$/', $check)) {
            $this->addError('value', "Hostname '{$value}' không hợp lệ cho {$context} record. Chỉ được chứa chữ, số và dấu gạch nối, phân tách bởi dấu chấm.");
        }
    }

    /**
     * Validate TXT record.
     * Chỉ kiểm tra độ dài — KHÔNG validate SPF syntax vì quá phức tạp.
     * SPF hỗ trợ nhiều mechanism: ip4, ip6, include, exists, redirect, ptr, a, mx
     * với modifiers qualifier (+/-/~/?). Không thể validate đúng bằng regex đơn.
     */
    private function validateTxt($value)
    {
        if (strlen($value) > self::TXT_MAX_LENGTH) {
            $this->addError('value', 'Nội dung TXT record quá dài (tối đa ' . self::TXT_MAX_LENGTH . ' ký tự).');
            return;
        }
        // SPF và các TXT record khác được chấp nhận mà không validate thêm
    }

    /**
     * Validate CAA record.
     * Format: <flag> <tag> "<value>"
     * flag: 0 hoặc 128
     * tag: issue | issuewild | iodef
     */
    private function validateCaa($value)
    {
        // Bỏ qua dấu nháy bao ngoài nếu có
        $check = trim($value, '"');

        // Format: "0 issue "letsencrypt.org"" hoặc "0 iodef "mailto:admin@example.com""
        if (!preg_match('/^(0|128)\s+(issue|issuewild|iodef)\s+".+"$/', $value)) {
            $this->addError('value', 'CAA record không đúng format. Đúng format: <0|128> <issue|issuewild|iodef> "value". VD: 0 issue "letsencrypt.org"');
        }
    }

    /**
     * Helper: Thêm lỗi vào danh sách (chỉ lưu lỗi đầu tiên cho mỗi field).
     */
    private function addError($field, $message)
    {
        if (!isset($this->errors[$field])) {
            $this->errors[$field] = $message;
        }
    }
}
