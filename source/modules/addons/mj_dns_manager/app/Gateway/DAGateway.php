<?php

namespace MJ\DnsManager\Gateway;

defined("WHMCS") or die("Access Denied");

use GuzzleHttp\Client;
use GuzzleHttp\Exception\ConnectException;
use GuzzleHttp\Exception\RequestException;
use MJ\DnsManager\Models\Server;

/**
 * DAGateway — GuzzleHTTP wrapper for DirectAdmin API.
 *
 * IMPORTANT: This class MUST ONLY be called from:
 *   - app/Cron/* files (queue worker)
 *   - Admin "Test Connection" action (diagnostic only)
 *
 * NEVER instantiate this class from Controllers or during HTTP request lifecycle.
 */
class DAGateway
{
    /** @var Client */
    private $http;

    /** @var Server */
    private $server;

    /**
     * @param Server $server The DA server to connect to.
     */
    public function __construct(Server $server)
    {
        $this->server = $server;
        $this->http = $this->buildClient($server->use_ssl);
    }

    /**
     * Build a GuzzleHTTP client for this server.
     * @param bool $useSsl Whether to use HTTPS.
     */

    private function buildClient(bool $useSsl): Client
    {
        $protocol = $useSsl ? 'https' : 'http';
        $baseUri = "{$protocol}://{$this->server->ip_address}:{$this->server->port}";

        // Đọc từ settings nếu có, fallback về 5s
        $timeout = 5;
        try {
            $fromSettings = \MJ\DnsManager\Helpers\SettingsHelper::getInt('job_timeout', 5);
            if ($fromSettings > 0) {
                $timeout = $fromSettings;
            }
        } catch (\Throwable $e) {
            // Silent — dùng default 5s
        }

        return new Client([
            'base_uri'        => $baseUri,
            'auth'            => [$this->server->username, $this->server->password],
            'timeout'         => $timeout,          // Total response timeout (default 30s)
            'connect_timeout' => min($timeout, 8),  // BẮT BUỘC <= 8s. Nếu để 30s sẽ làm sập PHP max_execution_time khi chạy qua giao diện Web
            'verify'          => false,
            'http_errors'     => false,
            'headers'         => [
                'User-Agent' => 'MJ-DNS-Manager/1.0',
            ],
        ]);
    }

    /**
     * Parse DirectAdmin response gracefully supporting JSON and URL-encoded strings,
     * as well as catching HTML redirect pages from plain HTTP to HTTPS.
     * 
     * @return array Parsed response, or error array with 'error' => '1' and '_https_redirect' flag.
     */
    private function parseResponse(string $rawBody, int $status): array
    {
        if ($status >= 400 && empty(trim($rawBody))) {
            return ['error' => '1', 'text' => "HTTP Error {$status} / Connection refused"];
        }

        // Detect DA's HTTPS redirect page: <html>use https<script>location.protocol = "https:"</script>
        if (stripos($rawBody, 'use https') !== false && stripos($rawBody, '<html>') !== false) {
            return [
                'error' => '1',
                'text' => 'DirectAdmin yêu cầu HTTPS. Đang thử lại với SSL...',
                '_https_redirect' => true,
                '_raw' => substr($rawBody, 0, 200)
            ];
        }

        // Try JSON first
        $json = json_decode($rawBody, true);
        if (json_last_error() === JSON_ERROR_NONE && is_array($json)) {
            return $json;
        }

        // Try parsing as URL encoded (legacy DA API format)
        $parsed = [];
        parse_str($rawBody, $parsed);
        if (isset($parsed['error']) || isset($parsed['text']) || isset($parsed['details'])) {
            return $parsed;
        }

        // Unknown / HTML error response
        return [
            'error' => '1',
            'text' => 'Invalid API Response — Check IP Whitelist or Credentials.',
            '_raw' => substr($rawBody, 0, 500)
        ];
    }

    /**
     * Auto-upgrade to HTTPS and retry if DA returned a redirect response.
     * Mutates $this->http if upgrade is needed.
     *
     * @param  string $method  'get' or 'post'
     * @param  string $path    URL path
     * @param  array  $options GuzzleHTTP options
     * @return \Psr\Http\Message\ResponseInterface
     */
    private function requestWithHttpsFallback(string $method, string $path, array $options)
    {
        $response = $this->http->{$method}($path, $options);
        $rawBody = (string) $response->getBody();
        $status = $response->getStatusCode();

        // If DA responds with redirect to HTTPS, upgrade client and retry once
        if (!$this->server->use_ssl && stripos($rawBody, 'use https') !== false) {
            $this->http = $this->buildClient(true); // auto-upgrade to HTTPS
            $response = $this->http->{$method}($path, $options);
        }

        return $response;
    }

    // ─────────────────────────────────────────────────────────
    // A3 — DNS Zone Management
    // ─────────────────────────────────────────────────────────

    /**
     * Tạo domain account trên DirectAdmin via CMD_API_DOMAIN.
     * DA tự động tạo zone DNS kèm theo khi tạo domain.
     *
     * Confirmed params từ Postman:
     *   POST /CMD_API_DOMAIN
     *   action=create, domain=example.com, php=ON, cgi=OFF, ssl=ON
     *
     * @param  string $domain  Tên miền cần tạo
     * @param  array  $payload Job payload (có thể chứa php, cgi, ssl, bandwidth, quota)
     * @return DAResponse
     */
    public function createDomain(string $domain, array $payload = []): DAResponse
    {
        $start = microtime(true);

        try {
            $response = $this->requestWithHttpsFallback('post', '/CMD_API_DOMAIN', [
                'form_params' => [
                    'action' => 'create',
                    'domain' => $domain,
                    'php' => $payload['php'] ?? 'ON',
                    'cgi' => $payload['cgi'] ?? 'OFF',
                    'ssl' => $payload['ssl'] ?? 'ON',
                    'json' => 'yes',
                ],
            ]);

            $duration = (int) ((microtime(true) - $start) * 1000);
            $status = $response->getStatusCode();
            $body = $this->parseResponse((string) $response->getBody(), $status);
            $isError = isset($body['error']) && (string) $body['error'] !== '0';

            if ($isError || $status >= 400) {
                // Domain đã tồn tại — idempotent
                $errText = strtolower($body['details'] ?? $body['text'] ?? '');
                if (strpos($errText, 'already exists') !== false || strpos($errText, 'already set up') !== false) {
                    logActivity("DAGateway: Domain '{$domain}' already exists on DA — treating as success.");
                    return DAResponse::ok($body, $status, $duration);
                }

                return DAResponse::fail(
                    'domain_create_failed',
                    $body['text'] ?? 'Unable to create domain',
                    $body,
                    $status,
                    $duration
                );
            }

            return DAResponse::ok($body, $status, $duration);

        } catch (ConnectException $e) {
            $duration = (int) ((microtime(true) - $start) * 1000);
            return DAResponse::fail('connection_failed', 'Cannot connect to DirectAdmin server: ' . $e->getMessage(), [], null, $duration);
        } catch (RequestException $e) {
            $duration = (int) ((microtime(true) - $start) * 1000);
            return DAResponse::fail('request_failed', 'Request failed: ' . $e->getMessage(), [], null, $duration);
        }
    }

    /**
     * Delete a DNS zone on DirectAdmin.
     *
     * Uses CMD_API_DNS_ADMIN action=delete.
     * Zone not found is treated as success (idempotent).
     *
     * @param  string $domain Domain name.
     * @return DAResponse
     */
    public function deleteZone(string $domain): DAResponse
    {
        $start = microtime(true);

        try {
            $response = $this->requestWithHttpsFallback('post', '/CMD_API_DNS_ADMIN', [
                'form_params' => [
                    'domain' => $domain,
                    'action' => 'delete',
                    'json' => 'yes',
                ],
            ]);

            $duration = (int) ((microtime(true) - $start) * 1000);
            $status = $response->getStatusCode();
            $body = $this->parseResponse((string) $response->getBody(), $status);

            $isError = isset($body['error']) && (string) $body['error'] !== '0';

            if ($isError || $status >= 400) {
                // Zone does not exist — treat as success (idempotent)
                if (stripos($body['details'] ?? $body['text'] ?? '', 'does not exist') !== false) {
                    return DAResponse::ok($body, $status, $duration);
                }

                return DAResponse::fail(
                    'zone_delete_failed',
                    $body['text'] ?? 'Unable to delete zone',
                    $body,
                    $status,
                    $duration
                );
            }

            return DAResponse::ok($body, $status, $duration);
        } catch (ConnectException $e) {
            $duration = (int) ((microtime(true) - $start) * 1000);
            return DAResponse::fail('connection_failed', 'Cannot connect to DirectAdmin server: ' . $e->getMessage(), [], null, $duration);
        } catch (RequestException $e) {
            $duration = (int) ((microtime(true) - $start) * 1000);
            return DAResponse::fail('request_failed', 'Request failed: ' . $e->getMessage(), [], null, $duration);
        }
    }

    /**
     * Get all DNS records for a zone on DirectAdmin.
     *
     * Uses CMD_API_DNS_CONTROL action=dns.
     *
     * @param  string $domain Domain name.
     * @return DAResponse
     */
    public function getZone(string $domain): DAResponse
    {
        $start = microtime(true);

        try {
            // Note: If domain is not owned by the DA admin account itself, CMD_API_DNS_CONTROL will fail.
            // But WHMCS uses Admin credentials to fetch any zone, so CMD_API_DNS_ADMIN is required.
            $response = $this->requestWithHttpsFallback('get', '/CMD_API_DNS_ADMIN', [
                'query' => [
                    'domain' => $domain,
                    'action' => 'dns', // Required when using CMD_API_DNS_ADMIN to get records
                    'json' => 'yes',
                ],
            ]);

            $duration = (int) ((microtime(true) - $start) * 1000);
            $status = $response->getStatusCode();
            $body = $this->parseResponse((string) $response->getBody(), $status);

            $isError = isset($body['error']) && (string) $body['error'] !== '0';

            if ($isError || $status >= 400 || !isset($body['records'])) {
                return DAResponse::fail(
                    'zone_get_failed',
                    $body['text'] ?? 'Unable to get zone records',
                    $body,
                    $status,
                    $duration
                );
            }

            return DAResponse::ok($body, $status, $duration);
        } catch (ConnectException $e) {
            $duration = (int) ((microtime(true) - $start) * 1000);
            return DAResponse::fail('connection_failed', 'Cannot connect to DirectAdmin server: ' . $e->getMessage(), [], null, $duration);
        } catch (RequestException $e) {
            $duration = (int) ((microtime(true) - $start) * 1000);
            return DAResponse::fail('request_failed', 'Request failed: ' . $e->getMessage(), [], null, $duration);
        }
    }

    // ─────────────────────────────────────────────────────────
    // A4 — DNS Record Management
    // Tất cả dùng CMD_API_DNS_ADMIN (admin-level)
    // Params đã xác nhận qua F12 Network trên DA admin panel
    // ─────────────────────────────────────────────────────────

    /**
     * Add a DNS record.
     *
     * Endpoint (confirmed via F12 on DA UI):
     *   - AAAA → /CMD_DNS_ADMIN (web endpoint, CMD_API_DNS_ADMIN rejects AAAA)
     *   - Others → /CMD_API_DNS_ADMIN
     *
     * MX format: value = priority (number), mx_value = hostname (no trailing dot)
     * SRV format: value = "{priority} {weight} {port} {target.}" via buildDaValue()
     *
     * @param  string $domain
     * @param  array  $record  ['type','name','value','ttl','priority','weight','port']
     * @return DAResponse
     */
    public function addRecord(string $domain, array $record): DAResponse
    {
        $start = microtime(true);

        $name = ($record['name'] ?? '') === '@' ? '' : ($record['name'] ?? '');
        $type = strtoupper($record['type'] ?? '');

        // Pre-validate: AAAA phải là IPv6 — catch bad queue jobs từ trước khi có validator
        if ($type === 'AAAA') {
            $rawValue = trim($record['value'] ?? '');
            if (filter_var($rawValue, FILTER_VALIDATE_IP, FILTER_FLAG_IPV4)) {
                return DAResponse::fail('invalid_payload', "AAAA record yêu cầu địa chỉ IPv6, không phải IPv4: '{$rawValue}'.", [], null, 0);
            }
            if (!filter_var($rawValue, FILTER_VALIDATE_IP, FILTER_FLAG_IPV6)) {
                return DAResponse::fail('invalid_payload', "Địa chỉ IPv6 không hợp lệ: '{$rawValue}'. Ví dụ đúng: 2001:db8::1", [], null, 0);
            }
        }

        $params = [
            'domain'          => $domain,
            'action'          => 'add',
            'affect_pointers' => 'no',
            'type'            => $type,
            'name'            => $name,
            'ttl'             => $record['ttl'] ?? 3600,
            'json'            => 'yes',
        ];

        if ($type === 'MX') {
            $params['value']    = (string) (int) ($record['priority'] ?? 10);
            $params['mx_value'] = rtrim($record['value'] ?? '', '.');
        } else {
            $params['value'] = $this->buildDaValue($type, [
                'value'    => $record['value'] ?? '',
                'priority' => $record['priority'] ?? 10,
                'weight'   => $record['weight'] ?? 0,
                'port'     => $record['port'] ?? 0,
            ]);
        }

        $endpoint = ($type === 'AAAA') ? '/CMD_DNS_ADMIN' : '/CMD_API_DNS_ADMIN';

        try {
            $response = $this->requestWithHttpsFallback('post', $endpoint, [
                'form_params' => $params,
            ]);

            $duration = (int) ((microtime(true) - $start) * 1000);
            $status   = $response->getStatusCode();
            $body     = $this->parseResponse((string) $response->getBody(), $status);
            $isError  = isset($body['error']) && (string) $body['error'] !== '0';

            if ($isError || $status >= 400) {
                return DAResponse::fail('record_add_failed', $body['text'] ?? 'Unable to add record', $body, $status, $duration);
            }

            return DAResponse::ok($body, $status, $duration);
        } catch (ConnectException $e) {
            return DAResponse::fail('connection_failed', $e->getMessage(), [], null, (int) ((microtime(true) - $start) * 1000));
        } catch (RequestException $e) {
            return DAResponse::fail('request_failed', $e->getMessage(), [], null, (int) ((microtime(true) - $start) * 1000));
        }
    }

    /**
     * Edit a DNS record via CMD_API_DNS_ADMIN.
     *
     * arecs0 identifies the OLD record by zone RDATA format.
     * New value for MX uses separate value/mx_value fields (same as addRecord).
     */
    public function editRecord(string $domain, array $payload): DAResponse
    {
        $start = microtime(true);

        $old = $payload['old_record'] ?? [];
        $new = $payload['new_record'] ?? [];

        if (empty($old) || empty($new)) {
            return DAResponse::fail('invalid_payload', 'editRecord payload thiếu old_record hoặc new_record.', [], null, 0);
        }

        $type    = strtoupper($new['type'] ?? $old['type'] ?? '');
        // arecs0 dùng FQDN cho root record để DA tìm đúng record cần edit
        $oldRawName = $old['name'] ?? '';
        $oldName = ($oldRawName === '@') ? ($domain . '.') : $oldRawName;
        // newName: DA UI gửi FQDN cho root record (confirmed F12)
        $newRawName = $new['name'] ?? '';
        $newName = ($newRawName === '@') ? ($domain . '.') : $newRawName;

        // arecs0: identify OLD record using zone RDATA format
        // MX zone RDATA = "{priority} {exchange.}" (e.g. "10 mail.example.com.")
        $oldValue = $this->buildDaValue($type, [
            'value'    => $old['value'] ?? '',
            'priority' => $old['priority'] ?? 10,
            'weight'   => $old['weight'] ?? 0,
            'port'     => $old['port'] ?? 0,
        ]);

        $arecs0 = 'name=' . $oldName . '&value=' . $oldValue;

        $params = [
            'domain' => $domain,
            'action' => 'edit',
            'arecs0' => $arecs0,
            'type'   => $type,
            'name'   => $newName,
            'ttl'    => $new['ttl'] ?? 3600,
            'json'   => 'yes',
        ];

        if ($type === 'MX') {
            // New value: same 2-field format as addRecord (confirmed F12)
            $params['value']    = (string) (int) ($new['priority'] ?? 10);
            $params['mx_value'] = rtrim($new['value'] ?? '', '.');
        } else {
            $params['value'] = $this->buildDaValue($type, [
                'value'    => $new['value'] ?? '',
                'priority' => $new['priority'] ?? 10,
                'weight'   => $new['weight'] ?? 0,
                'port'     => $new['port'] ?? 0,
            ]);
        }

        try {
            $response = $this->requestWithHttpsFallback('post', '/CMD_API_DNS_ADMIN', [
                'form_params' => $params,
            ]);

            $duration = (int) ((microtime(true) - $start) * 1000);
            $status = $response->getStatusCode();
            $body = $this->parseResponse((string) $response->getBody(), $status);
            $isError = isset($body['error']) && (string) $body['error'] !== '0';

            if ($isError || $status >= 400) {
                return DAResponse::fail('record_edit_failed', $body['text'] ?? 'Unable to edit record', $body, $status, $duration);
            }

            return DAResponse::ok($body, $status, $duration);
        } catch (ConnectException $e) {
            return DAResponse::fail('connection_failed', $e->getMessage(), [], null, (int) ((microtime(true) - $start) * 1000));
        } catch (RequestException $e) {
            return DAResponse::fail('request_failed', $e->getMessage(), [], null, (int) ((microtime(true) - $start) * 1000));
        }
    }


    /**
     * Delete a DNS record.
     * Confirmed params qua F12: action=select, delete=yes, arecs0=name={name}&value={value}
     */
    public function deleteRecord(string $domain, array $payload): DAResponse
    {
        $start = microtime(true);

        $type = strtoupper($payload['type'] ?? '');
        $name = ($payload['name'] ?? '') === '@' ? '' : ($payload['name'] ?? '');

        if ($type === '' || ($payload['value'] ?? '') === '') {
            return DAResponse::fail('invalid_payload', 'deleteRecord payload thiếu type hoặc value.', [], null, 0);
        }

        // Build value in DA zone format (same as addRecord) for arecs0 matching
        $value = $this->buildDaValue($type, [
            'value'    => $payload['value'] ?? '',
            'priority' => $payload['priority'] ?? 10,
            'weight'   => $payload['weight'] ?? 0,
            'port'     => $payload['port'] ?? 0,
        ]);

        $arecs0 = 'name=' . $name . '&value=' . $value;

        try {
            $response = $this->requestWithHttpsFallback('post', '/CMD_API_DNS_ADMIN', [
                'form_params' => [
                    'domain' => $domain,
                    'action' => 'select',
                    'delete' => 'yes',
                    'arecs0' => $arecs0,
                    'json'   => 'yes',
                ],
            ]);

            $duration = (int) ((microtime(true) - $start) * 1000);
            $status = $response->getStatusCode();
            $body = $this->parseResponse((string) $response->getBody(), $status);
            $isError = isset($body['error']) && (string) $body['error'] !== '0';

            if ($isError || $status >= 400) {
                $errorText = strtolower($body['details'] ?? $body['text'] ?? '');
                if (strpos($errorText, 'not found') !== false || strpos($errorText, 'does not exist') !== false) {
                    return DAResponse::ok($body, $status, $duration); // idempotent
                }
                return DAResponse::fail('record_delete_failed', $body['text'] ?? 'Unable to delete record', $body, $status, $duration);
            }

            return DAResponse::ok($body, $status, $duration);
        } catch (ConnectException $e) {
            return DAResponse::fail('connection_failed', $e->getMessage(), [], null, (int) ((microtime(true) - $start) * 1000));
        } catch (RequestException $e) {
            return DAResponse::fail('request_failed', $e->getMessage(), [], null, (int) ((microtime(true) - $start) * 1000));
        }
    }

    /**
     * Build DA zone RDATA value string từ record fields.
     *
     * Dùng cho arecs0 (định danh record trong edit/delete) theo zone format:
     *   - MX:       "{priority} {exchange.}"             e.g. "10 mail.example.com."
     *   - SRV:      "{priority} {weight} {port} {target.}"
     *   - CNAME/NS: "{target.}"  (có trailing dot)
     *   - TXT:      '"content"'  (có dấu ngoặc kép)
     *   - A/AAAA/CAA/PTR: as-is
     *
     * @param  string $type   Record type (uppercase)
     * @param  array  $fields ['value', 'priority', 'weight', 'port']
     * @return string
     */
    private function buildDaValue(string $type, array $fields): string
    {
        $value    = $fields['value']    ?? '';
        $priority = (int) ($fields['priority'] ?? 10);
        $weight   = (int) ($fields['weight']   ?? 0);
        $port     = (int) ($fields['port']     ?? 0);

        switch ($type) {
            case 'MX':
                return $priority . ' ' . rtrim($value, '.') . '.';

            case 'SRV':
                return $priority . ' ' . $weight . ' ' . $port . ' ' . rtrim($value, '.') . '.';

            case 'CNAME':
            case 'NS':
                return rtrim($value, '.') . '.';

            case 'TXT':
                return '"' . addslashes($value) . '"';

            default:
                return $value;
        }
    }


    // ─────────────────────────────────────────────────────────

    // A5 — Site Redirect Management (CMD_REDIRECT)
    // Confirmed via F12: POST /CMD_REDIRECT?json=yes
    // Body: JSON với các field action, domain, from, to, type
    // ─────────────────────────────────────────────────────────

    /**
     * Lấy danh sách redirects của domain.
     *
     * @param  string $domain
     * @return DAResponse  data['redirects'] = array of {from, to, type}
     */
    public function listRedirects(string $domain): DAResponse
    {
        $start = microtime(true);

        try {
            $response = $this->requestWithHttpsFallback('get', '/CMD_REDIRECT', [
                'query' => [
                    'domain' => $domain,
                    'json' => 'yes',
                ],
            ]);

            $duration = (int) ((microtime(true) - $start) * 1000);
            $status = $response->getStatusCode();
            $body = $this->parseResponse((string) $response->getBody(), $status);
            $isError = isset($body['error']) && (string) $body['error'] !== '0';

            if ($isError || $status >= 400) {
                return DAResponse::fail('redirect_list_failed', $body['text'] ?? 'Unable to list redirects', $body, $status, $duration);
            }

            // DA trả về array các redirect objects hoặc object có key 'list'
            // Chuẩn hoá thành array dưới key 'redirects'
            $redirects = [];
            if (isset($body['list']) && is_array($body['list'])) {
                $redirects = $body['list'];
            } elseif (is_array($body) && !isset($body['error'])) {
                // Một số DA version trả thẳng array
                $redirects = array_values($body);
            }

            return DAResponse::ok(['redirects' => $redirects], $status, $duration);

        } catch (ConnectException $e) {
            $duration = (int) ((microtime(true) - $start) * 1000);
            return DAResponse::fail('connection_failed', 'Cannot connect to DirectAdmin server: ' . $e->getMessage(), [], null, $duration);
        } catch (RequestException $e) {
            $duration = (int) ((microtime(true) - $start) * 1000);
            return DAResponse::fail('request_failed', 'Request failed: ' . $e->getMessage(), [], null, $duration);
        }
    }

    /**
     * Tạo redirect mới trên DA.
     * Confirmed params từ F12: action=add, domain, from, to, type (301|302)
     *
     * @param  string $domain
     * @param  string $from   Path nguồn, VD: "/old-page" hoặc "/"
     * @param  string $to     URL đích đầy đủ, VD: "https://google.com"
     * @param  string $type   "301" hoặc "302"
     * @return DAResponse
     */
    public function createRedirect(string $domain, string $from, string $to, string $type = '301'): DAResponse
    {
        $start = microtime(true);

        try {
            $response = $this->requestWithHttpsFallback('post', '/CMD_REDIRECT', [
                'query' => ['json' => 'yes'],
                'json' => [
                    'action' => 'add',
                    'domain' => $domain,
                    'from' => $from,
                    'to' => $to,
                    'type' => $type,
                ],
            ]);

            $duration = (int) ((microtime(true) - $start) * 1000);
            $status = $response->getStatusCode();
            $body = $this->parseResponse((string) $response->getBody(), $status);
            $isError = isset($body['error']) && (string) $body['error'] !== '0';

            if ($isError || $status >= 400) {
                // Redirect đã tồn tại — idempotent
                $errText = strtolower($body['text'] ?? $body['details'] ?? '');
                if (strpos($errText, 'already exists') !== false || strpos($errText, 'duplicate') !== false) {
                    return DAResponse::ok($body, $status, $duration);
                }
                return DAResponse::fail('redirect_create_failed', $body['text'] ?? 'Unable to create redirect', $body, $status, $duration);
            }

            return DAResponse::ok($body, $status, $duration);

        } catch (ConnectException $e) {
            $duration = (int) ((microtime(true) - $start) * 1000);
            return DAResponse::fail('connection_failed', 'Cannot connect to DirectAdmin server: ' . $e->getMessage(), [], null, $duration);
        } catch (RequestException $e) {
            $duration = (int) ((microtime(true) - $start) * 1000);
            return DAResponse::fail('request_failed', 'Request failed: ' . $e->getMessage(), [], null, $duration);
        }
    }

    /**
     * Xóa redirect trên DA.
     * Confirmed via F12: action=delete, select0={source_path}
     * DA dùng 'select0' để identify redirect cần xóa, không phải 'from'.
     *
     * @param  string $domain
     * @param  string $from  Path nguồn của redirect cần xóa (VD: "/test")
     * @return DAResponse
     */
    public function deleteRedirect(string $domain, string $from): DAResponse
    {
        $start = microtime(true);

        try {
            $response = $this->requestWithHttpsFallback('post', '/CMD_REDIRECT', [
                'query' => ['json' => 'yes'],
                'json' => [
                    'action' => 'delete',
                    'domain' => $domain,
                    'select0' => $from,   // ← DA dùng select0, không phải from
                ],
            ]);

            $duration = (int) ((microtime(true) - $start) * 1000);
            $status = $response->getStatusCode();
            $body = $this->parseResponse((string) $response->getBody(), $status);
            $isError = isset($body['error']) && (string) $body['error'] !== '0';

            if ($isError || $status >= 400) {
                $errText = strtolower($body['text'] ?? $body['details'] ?? '');
                if (strpos($errText, 'not found') !== false || strpos($errText, 'does not exist') !== false) {
                    return DAResponse::ok($body, $status, $duration);
                }
                return DAResponse::fail('redirect_delete_failed', $body['text'] ?? 'Unable to delete redirect', $body, $status, $duration);
            }

            return DAResponse::ok($body, $status, $duration);

        } catch (ConnectException $e) {
            $duration = (int) ((microtime(true) - $start) * 1000);
            return DAResponse::fail('connection_failed', 'Cannot connect to DirectAdmin server: ' . $e->getMessage(), [], null, $duration);
        } catch (RequestException $e) {
            $duration = (int) ((microtime(true) - $start) * 1000);
            return DAResponse::fail('request_failed', 'Request failed: ' . $e->getMessage(), [], null, $duration);
        }
    }

    // ─────────────────────────────────────────────────────────
    // A6 — SSL Certificate Management (CMD_API_SSL)
    // Confirmed via Postman: GET /CMD_API_SSL?domain=x&json=yes
    // ─────────────────────────────────────────────────────────

    /**
     * Lấy thông tin SSL cert hiện tại của domain.
     *
     * Các field quan trọng từ response thực tế:
     *   - ssl_on        : "yes" | "no"
     *   - signed        : "yes" | "no"     — cert đã được CA ký chưa
     *   - end           : Unix timestamp   — ngày hết hạn
     *   - start         : Unix timestamp   — ngày bắt đầu
     *   - issuer_simple : "letsencrypt"
     *   - next_retries  : array            — domain đang chờ ACME issue (chưa có cert)
     *
     * @param  string $domain
     * @return DAResponse
     */
    public function getSslInfo(string $domain): DAResponse
    {
        $start = microtime(true);

        try {
            $response = $this->requestWithHttpsFallback('get', '/CMD_API_SSL', [
                'query' => [
                    'domain' => $domain,
                    'json' => 'yes',
                ],
            ]);

            $duration = (int) ((microtime(true) - $start) * 1000);
            $status = $response->getStatusCode();
            $body = $this->parseResponse((string) $response->getBody(), $status);
            $isError = isset($body['error']) && (string) $body['error'] !== '0';

            if ($isError || $status >= 400) {
                return DAResponse::fail(
                    'ssl_info_failed',
                    $body['text'] ?? 'Unable to get SSL info',
                    $body,
                    $status,
                    $duration
                );
            }

            return DAResponse::ok($body, $status, $duration);

        } catch (ConnectException $e) {
            $duration = (int) ((microtime(true) - $start) * 1000);
            return DAResponse::fail('connection_failed', 'Cannot connect to DirectAdmin server: ' . $e->getMessage(), [], null, $duration);
        } catch (RequestException $e) {
            $duration = (int) ((microtime(true) - $start) * 1000);
            return DAResponse::fail('request_failed', 'Request failed: ' . $e->getMessage(), [], null, $duration);
        }
    }

    /**
     * Trigger gia hạn Let's Encrypt cert cho domain.
     *
     * DA sẽ queue ACME renewal request nội bộ.
     * Sau khi job này COMPLETE, SslChecker sẽ gọi getSslInfo()
     * để lấy ngày hết hạn mới và update ssl_status = 'active'.
     *
     * @param  string $domain
     * @return DAResponse
     */
    public function renewSsl(string $domain): DAResponse
    {
        $start = microtime(true);

        try {
            $response = $this->requestWithHttpsFallback('post', '/CMD_API_SSL', [
                'form_params' => [
                    'action' => 'save',
                    'domain' => $domain,
                    'request' => 'letsencrypt',
                    'type' => 'create',
                    'wildcard' => 'yes',
                    'background' => 'auto',
                    'json' => 'yes',
                ],
            ]);

            $duration = (int) ((microtime(true) - $start) * 1000);
            $status = $response->getStatusCode();
            $body = $this->parseResponse((string) $response->getBody(), $status);
            $isError = isset($body['error']) && (string) $body['error'] !== '0';

            if ($isError || $status >= 400) {
                return DAResponse::fail(
                    'ssl_renew_failed',
                    $body['text'] ?? 'Unable to renew SSL certificate',
                    $body,
                    $status,
                    $duration
                );
            }

            return DAResponse::ok($body, $status, $duration);

        } catch (ConnectException $e) {
            $duration = (int) ((microtime(true) - $start) * 1000);
            return DAResponse::fail('connection_failed', 'Cannot connect to DirectAdmin server: ' . $e->getMessage(), [], null, $duration);
        } catch (RequestException $e) {
            $duration = (int) ((microtime(true) - $start) * 1000);
            return DAResponse::fail('request_failed', 'Request failed: ' . $e->getMessage(), [], null, $duration);
        }
    }
    
     /**
     * Bật DNSSEC cho domain trên DirectAdmin.
     *
     * DA sẽ tự generate cặp khóa KSK/ZSK và ký toàn bộ zone.
     * Sau khi job này COMPLETE, gọi getDsRecords() để lấy DS Record.
     *
     * @param  string $domain
     * @return DAResponse
     */
    public function enableDnssec(string $domain): DAResponse
    {
        $start = microtime(true);

        try {
            $response = $this->requestWithHttpsFallback('post', '/CMD_API_DNS_ADMIN', [
                'form_params' => array(
                    'domain' => $domain,
                    'action' => 'dnssec',
                    'dnssec' => 'enable',
                    'json'   => 'yes',
                ),
            ]);

            $duration = (int) ((microtime(true) - $start) * 1000);
            $status   = $response->getStatusCode();
            $body     = $this->parseResponse((string) $response->getBody(), $status);
            $isError  = isset($body['error']) && (string) $body['error'] !== '0';

            if ($isError || $status >= 400) {
                // Đã bật trước đó — idempotent
                $errText = strtolower($body['text'] ?? $body['details'] ?? '');
                if (strpos($errText, 'already enabled') !== false || strpos($errText, 'already active') !== false) {
                    return DAResponse::ok($body, $status, $duration);
                }
                return DAResponse::fail('dnssec_enable_failed', $body['text'] ?? 'Unable to enable DNSSEC', $body, $status, $duration);
            }

            return DAResponse::ok($body, $status, $duration);

        } catch (ConnectException $e) {
            $duration = (int) ((microtime(true) - $start) * 1000);
            return DAResponse::fail('connection_failed', 'Cannot connect to DirectAdmin server: ' . $e->getMessage(), [], null, $duration);
        } catch (RequestException $e) {
            $duration = (int) ((microtime(true) - $start) * 1000);
            return DAResponse::fail('request_failed', 'Request failed: ' . $e->getMessage(), [], null, $duration);
        }
    }

    /**
     * Tắt DNSSEC cho domain trên DirectAdmin.
     *
     * CẢNH BÁO: Phải xóa DS Record tại Registrar trước khi gọi method này.
     * Nếu làm ngược lại sẽ gây SERVFAIL — domain không phân giải được.
     *
     * @param  string $domain
     * @return DAResponse
     */
    public function disableDnssec(string $domain): DAResponse
    {
        $start = microtime(true);

        try {
            $response = $this->requestWithHttpsFallback('post', '/CMD_API_DNS_ADMIN', [
                'form_params' => array(
                    'domain' => $domain,
                    'action' => 'dnssec',
                    'dnssec' => 'disable',
                    'json'   => 'yes',
                ),
            ]);

            $duration = (int) ((microtime(true) - $start) * 1000);
            $status   = $response->getStatusCode();
            $body     = $this->parseResponse((string) $response->getBody(), $status);
            $isError  = isset($body['error']) && (string) $body['error'] !== '0';

            if ($isError || $status >= 400) {
                // Đã tắt trước đó — idempotent
                $errText = strtolower($body['text'] ?? $body['details'] ?? '');
                if (strpos($errText, 'not enabled') !== false || strpos($errText, 'already disabled') !== false) {
                    return DAResponse::ok($body, $status, $duration);
                }
                return DAResponse::fail('dnssec_disable_failed', $body['text'] ?? 'Unable to disable DNSSEC', $body, $status, $duration);
            }

            return DAResponse::ok($body, $status, $duration);

        } catch (ConnectException $e) {
            $duration = (int) ((microtime(true) - $start) * 1000);
            return DAResponse::fail('connection_failed', 'Cannot connect to DirectAdmin server: ' . $e->getMessage(), [], null, $duration);
        } catch (RequestException $e) {
            $duration = (int) ((microtime(true) - $start) * 1000);
            return DAResponse::fail('request_failed', 'Request failed: ' . $e->getMessage(), [], null, $duration);
        }
    }

    /**
     * Lấy DS Records của domain từ DirectAdmin.
     *
     * Gọi sau khi enableDnssec() thành công để lấy thông số
     * Key Tag, Algorithm, Digest Type, Digest cho client mang
     * đến Registrar cấu hình.
     *
     * Response data mong đợi từ DA:
     * {
     *   "key_tag":     12345,
     *   "algorithm":   13,
     *   "digest_type": 2,
     *   "digest":      "49FD46E6...",
     *   "ds_record":   "dnsproject.io.vn. IN DS 12345 13 2 49FD46E6..."
     * }
     *
     * @param  string $domain
     * @return DAResponse  data chứa key_tag, algorithm, digest_type, digest, ds_record
     */
    public function getDsRecords(string $domain): DAResponse
    {
        $start = microtime(true);

        try {
            $response = $this->requestWithHttpsFallback('get', '/CMD_API_DNS_ADMIN', [
                'query' => array(
                    'domain' => $domain,
                    'action' => 'dnssec',
                    'json'   => 'yes',
                ),
            ]);

            $duration = (int) ((microtime(true) - $start) * 1000);
            $status   = $response->getStatusCode();
            $body     = $this->parseResponse((string) $response->getBody(), $status);
            $isError  = isset($body['error']) && (string) $body['error'] !== '0';

            if ($isError || $status >= 400) {
                return DAResponse::fail(
                    'dnssec_ds_fetch_failed',
                    $body['text'] ?? 'Unable to fetch DS Records',
                    $body,
                    $status,
                    $duration
                );
            }

            // Validate response có đủ field cần thiết
            if (empty($body['key_tag']) && empty($body['digest'])) {
                return DAResponse::fail(
                    'dnssec_not_ready',
                    'DNSSEC chưa sẵn sàng hoặc DA chưa generate xong keys.',
                    $body,
                    $status,
                    $duration
                );
            }

            return DAResponse::ok($body, $status, $duration);

        } catch (ConnectException $e) {
            $duration = (int) ((microtime(true) - $start) * 1000);
            return DAResponse::fail('connection_failed', 'Cannot connect to DirectAdmin server: ' . $e->getMessage(), [], null, $duration);
        } catch (RequestException $e) {
            $duration = (int) ((microtime(true) - $start) * 1000);
            return DAResponse::fail('request_failed', 'Request failed: ' . $e->getMessage(), [], null, $duration);
        }
    }


    // ─────────────────────────────────────────────────────────
    // A7 — Email Forwarding (CMD_API_EMAIL_FORWARDERS)
    // ─────────────────────────────────────────────────────────

    /**
     * Lấy danh sách email forwarders của domain từ DirectAdmin.
     *
     * @param  string $domain  Tên miền
     * @return DAResponse  data['forwarders'] = array of {user, email}
     */
    public function listEmailForwarders(string $domain): DAResponse
    {
        $start = microtime(true);

        try {
            $response = $this->requestWithHttpsFallback('get', '/CMD_API_EMAIL_FORWARDERS', [
                'query' => [
                    'domain' => $domain,
                    'json'   => 'yes',
                ],
            ]);

            $duration = (int) ((microtime(true) - $start) * 1000);
            $status   = $response->getStatusCode();
            $body     = $this->parseResponse((string) $response->getBody(), $status);
            $isError  = isset($body['error']) && (string) $body['error'] !== '0';

            if ($isError || $status >= 400) {
                return DAResponse::fail(
                    'email_fwd_list_failed',
                    $body['text'] ?? 'Unable to list email forwarders',
                    $body,
                    $status,
                    $duration
                );
            }

            // DA trả về array của forwarder objects, hoặc object có key 'list'
            $forwarders = [];
            if (isset($body['list']) && is_array($body['list'])) {
                $forwarders = $body['list'];
            } elseif (is_array($body) && !isset($body['error'])) {
                $forwarders = array_values(array_filter($body, 'is_array'));
            }

            return DAResponse::ok(['forwarders' => $forwarders], $status, $duration);

        } catch (ConnectException $e) {
            $duration = (int) ((microtime(true) - $start) * 1000);
            return DAResponse::fail('connection_failed', 'Cannot connect to DirectAdmin server: ' . $e->getMessage(), [], null, $duration);
        } catch (RequestException $e) {
            $duration = (int) ((microtime(true) - $start) * 1000);
            return DAResponse::fail('request_failed', 'Request failed: ' . $e->getMessage(), [], null, $duration);
        }
    }

    /**
     * Tạo email forwarder trên DirectAdmin.
     *
     * DA API: POST /CMD_API_EMAIL_FORWARDERS
     *   action=create, domain=example.com, user=info, email=dest@gmail.com
     *
     * ⚠️ GOTCHA: `user` là local part (VD: "info"), không phải full email.
     * Forwarder đã tồn tại → idempotent (treat as success).
     *
     * @param  string $domain      Tên miền
     * @param  string $sourceLocal Local part (VD: "info" cho info@example.com)
     * @param  string $destEmail   Email đích nhận forward
     * @return DAResponse
     */
    public function createEmailForwarder(string $domain, string $sourceLocal, string $destEmail): DAResponse
    {
        $start = microtime(true);

        try {
            $response = $this->requestWithHttpsFallback('post', '/CMD_API_EMAIL_FORWARDERS', [
                'form_params' => [
                    'domain' => $domain,
                    'action' => 'create',
                    'user'   => $sourceLocal,
                    'email'  => $destEmail,
                    'json'   => 'yes',
                ],
            ]);

            $duration = (int) ((microtime(true) - $start) * 1000);
            $status   = $response->getStatusCode();
            $body     = $this->parseResponse((string) $response->getBody(), $status);
            $isError  = isset($body['error']) && (string) $body['error'] !== '0';

            if ($isError || $status >= 400) {
                // Forwarder đã tồn tại — idempotent
                $errText = strtolower($body['text'] ?? $body['details'] ?? '');
                if (strpos($errText, 'already exists') !== false || strpos($errText, 'already set up') !== false) {
                    logActivity("DAGateway: Email forwarder '{$sourceLocal}@{$domain}' already exists — treating as success.");
                    return DAResponse::ok($body, $status, $duration);
                }

                return DAResponse::fail(
                    'email_fwd_create_failed',
                    $body['text'] ?? 'Unable to create email forwarder',
                    $body,
                    $status,
                    $duration
                );
            }

            return DAResponse::ok($body, $status, $duration);

        } catch (ConnectException $e) {
            $duration = (int) ((microtime(true) - $start) * 1000);
            return DAResponse::fail('connection_failed', 'Cannot connect to DirectAdmin server: ' . $e->getMessage(), [], null, $duration);
        } catch (RequestException $e) {
            $duration = (int) ((microtime(true) - $start) * 1000);
            return DAResponse::fail('request_failed', 'Request failed: ' . $e->getMessage(), [], null, $duration);
        }
    }

    /**
     * Xóa email forwarder trên DirectAdmin.
     *
     * DA API: POST /CMD_API_EMAIL_FORWARDERS
     *   action=delete, domain=example.com, select0=info
     *
     * ⚠️ GOTCHA: Xóa dùng `select0` (local part), không phải `user` hay full email.
     * Forwarder không tồn tại → idempotent (treat as success).
     *
     * @param  string $domain      Tên miền
     * @param  string $sourceLocal Local part của forwarder cần xóa
     * @return DAResponse
     */
    public function deleteEmailForwarder(string $domain, string $sourceLocal): DAResponse
    {
        $start = microtime(true);

        try {
            $response = $this->requestWithHttpsFallback('post', '/CMD_API_EMAIL_FORWARDERS', [
                'form_params' => [
                    'domain'  => $domain,
                    'action'  => 'delete',
                    'select0' => $sourceLocal,  // ← DA dùng select0, không phải user
                    'json'    => 'yes',
                ],
            ]);

            $duration = (int) ((microtime(true) - $start) * 1000);
            $status   = $response->getStatusCode();
            $body     = $this->parseResponse((string) $response->getBody(), $status);
            $isError  = isset($body['error']) && (string) $body['error'] !== '0';

            if ($isError || $status >= 400) {
                // Forwarder không tồn tại — idempotent
                $errText = strtolower($body['text'] ?? $body['details'] ?? '');
                if (strpos($errText, 'not found') !== false || strpos($errText, 'does not exist') !== false) {
                    return DAResponse::ok($body, $status, $duration);
                }

                return DAResponse::fail(
                    'email_fwd_delete_failed',
                    $body['text'] ?? 'Unable to delete email forwarder',
                    $body,
                    $status,
                    $duration
                );
            }

            return DAResponse::ok($body, $status, $duration);

        } catch (ConnectException $e) {
            $duration = (int) ((microtime(true) - $start) * 1000);
            return DAResponse::fail('connection_failed', 'Cannot connect to DirectAdmin server: ' . $e->getMessage(), [], null, $duration);
        } catch (RequestException $e) {
            $duration = (int) ((microtime(true) - $start) * 1000);
            return DAResponse::fail('request_failed', 'Request failed: ' . $e->getMessage(), [], null, $duration);
        }
    }

    // ─────────────────────────────────────────────────────────
    // Diagnostic — Test Connection (Admin only)
    // ─────────────────────────────────────────────────────────

    /**
     * Test connectivity to this DA server.
     *
     * This is the ONLY method allowed to be called from Admin Controller
     * during HTTP request lifecycle (diagnostic purpose only).
     *
     * @return DAResponse
     */
    public function testConnection(): DAResponse
    {
        $start = microtime(true);

        try {
            $response = $this->requestWithHttpsFallback('get', '/CMD_API_SHOW_DOMAINS', [
                'query' => ['json' => 'yes'],
            ]);

            $duration = (int) ((microtime(true) - $start) * 1000);
            $status = $response->getStatusCode();

            // ── Check auth TRƯỚC khi parse body ──────────────────────────────
            // 401/403: body thường là HTML rỗng, parseResponse() sẽ báo lỗi sai
            if ($status === 401 || $status === 403) {
                return DAResponse::fail('auth_failed', 'Authentication failed — check username/password.', [], $status, $duration);
            }

            $body = $this->parseResponse((string) $response->getBody(), $status);
            $isError = isset($body['error']) && (string) $body['error'] !== '0';

            if ($isError || $status >= 400) {
                return DAResponse::fail('test_failed', $body['text'] ?? 'Test connection failed', $body, $status, $duration);
            }

            // ── Success: body có thể là [] (admin không có domain) — vẫn OK ──
            return DAResponse::ok($body, $status, $duration);

        } catch (ConnectException $e) {
            $duration = (int) ((microtime(true) - $start) * 1000);
            return DAResponse::fail('connection_failed', 'Cannot reach server: ' . $e->getMessage(), [], null, $duration);
        } catch (RequestException $e) {
            $duration = (int) ((microtime(true) - $start) * 1000);
            return DAResponse::fail('request_failed', $e->getMessage(), [], null, $duration);
        }
    }
}
