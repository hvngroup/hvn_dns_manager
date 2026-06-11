<?php

namespace MJ\DnsManager\Gateway;

defined("WHMCS") or die("Access Denied");

/**
 * Standardized response object for all DirectAdmin API calls.
 * Wraps raw DA responses into a consistent interface.
 */
class DAResponse
{
    public $success;
    public $errorCode;
    public $errorMessage;
    public $data;
    public $httpStatus;
    public $durationMs;

    public function __construct(
        bool $success,
        array $data = [],
        ?string $errorCode = null,
        ?string $errorMessage = null,
        ?int $httpStatus = null,
        int $durationMs = 0
    ) {
        $this->success = $success;
        $this->data = $data;
        $this->errorCode = $errorCode;
        $this->errorMessage = $errorMessage;
        $this->httpStatus = $httpStatus;
        $this->durationMs = $durationMs;
    }

    /**
     * @return bool True if the DA operation was successful.
     */
    public function isSuccess(): bool
    {
        return $this->success;
    }

    /**
     * Build a successful response.
     *
     * @param  array $data       Parsed response body.
     * @param  int   $httpStatus HTTP status code.
     * @param  int   $duration   Duration in ms.
     * @return self
     */
    public static function ok(array $data = [], int $httpStatus = 200, int $duration = 0): self
    {
        return new self(true, $data, null, null, $httpStatus, $duration);
    }

    /**
     * Build a failed response.
     *
     * @param  string      $errorCode    Machine-readable error code.
     * @param  string      $errorMessage Human-readable error message.
     * @param  array       $data         Raw DA response data (for logging).
     * @param  int|null    $httpStatus   HTTP status code.
     * @param  int         $duration     Duration in ms.
     * @return self
     */
    public static function fail(
        string $errorCode,
        string $errorMessage,
        array $data = [],
        ?int $httpStatus = null,
        int $duration = 0
    ): self {
        return new self(false, $data, $errorCode, $errorMessage, $httpStatus, $duration);
    }
}
