<?php

namespace MJ\DnsManager\Contracts;

defined("WHMCS") or die("Access Denied");

interface JobInterface
{
    const ACTION_ADD_RECORD        = 'ADD_RECORD';
    const ACTION_EDIT_RECORD       = 'EDIT_RECORD';
    const ACTION_DELETE_RECORD     = 'DELETE_RECORD';
    const ACTION_CREATE_ZONE       = 'CREATE_ZONE';
    const ACTION_DELETE_ZONE       = 'DELETE_ZONE';
    const ACTION_CREATE_REDIRECT   = 'CREATE_REDIRECT';
    const ACTION_EDIT_REDIRECT     = 'EDIT_REDIRECT';
    const ACTION_DELETE_REDIRECT   = 'DELETE_REDIRECT';
    const ACTION_CREATE_EMAIL_FWD  = 'CREATE_EMAIL_FWD';
    const ACTION_DELETE_EMAIL_FWD  = 'DELETE_EMAIL_FWD';
    const ACTION_ENABLE_DNSSEC     = 'ENABLE_DNSSEC';
    const ACTION_DISABLE_DNSSEC    = 'DISABLE_DNSSEC';
    const ACTION_RESIGN_ZONE       = 'RESIGN_ZONE';
    const ACTION_REQUEST_SSL       = 'REQUEST_SSL';
    const ACTION_RENEW_SSL         = 'RENEW_SSL';
    const ACTION_APPLY_TEMPLATE    = 'APPLY_TEMPLATE';
    const ACTION_SYNC_ZONE         = 'SYNC_ZONE';

    const STATUS_PENDING            = 'PENDING';
    const STATUS_SYNCING            = 'SYNCING';
    const STATUS_COMPLETE           = 'COMPLETE';
    const STATUS_FAILED             = 'FAILED';
    const STATUS_CANCELLED          = 'CANCELLED';
    const STATUS_PERMANENTLY_FAILED = 'PERMANENTLY_FAILED';

    const ACTOR_CLIENT = 'client';
    const ACTOR_ADMIN  = 'admin';
    const ACTOR_SYSTEM = 'system';
    const ACTOR_API    = 'api';

    const PRIORITY_ADMIN     = 1;
    const PRIORITY_PROVISION = 2;
    const PRIORITY_CLIENT    = 5;
    const PRIORITY_RESIGN    = 7;
    const PRIORITY_SSL       = 8;
    const PRIORITY_DRIFT     = 9;

    const VALID_ACTIONS = [
        self::ACTION_ADD_RECORD,
        self::ACTION_EDIT_RECORD,
        self::ACTION_DELETE_RECORD,
        self::ACTION_CREATE_ZONE,
        self::ACTION_DELETE_ZONE,
        self::ACTION_CREATE_REDIRECT,
        self::ACTION_EDIT_REDIRECT,
        self::ACTION_DELETE_REDIRECT,
        self::ACTION_CREATE_EMAIL_FWD,
        self::ACTION_DELETE_EMAIL_FWD,
        self::ACTION_ENABLE_DNSSEC,
        self::ACTION_DISABLE_DNSSEC,
        self::ACTION_RESIGN_ZONE,
        self::ACTION_REQUEST_SSL,
        self::ACTION_RENEW_SSL,
        self::ACTION_APPLY_TEMPLATE,
        self::ACTION_SYNC_ZONE,
    ];

    const VALID_ACTOR_TYPES = [
        self::ACTOR_CLIENT,
        self::ACTOR_ADMIN,
        self::ACTOR_SYSTEM,
        self::ACTOR_API,
    ];

    const PAYLOAD_REQUIRED_KEYS = [
        self::ACTION_ADD_RECORD        => ['record_id', 'type', 'name', 'value', 'ttl'],
        self::ACTION_EDIT_RECORD       => ['record_id', 'old_record', 'new_record'],
        self::ACTION_DELETE_RECORD     => ['record_id', 'type', 'name', 'value'],
        self::ACTION_CREATE_ZONE       => [],
        self::ACTION_DELETE_ZONE       => [],
        self::ACTION_ENABLE_DNSSEC     => [],
        self::ACTION_DISABLE_DNSSEC    => [],
        self::ACTION_RESIGN_ZONE       => [],
        self::ACTION_REQUEST_SSL       => [],
        self::ACTION_RENEW_SSL         => [],
        self::ACTION_CREATE_EMAIL_FWD  => ['user', 'email'],
        self::ACTION_DELETE_EMAIL_FWD  => ['user'],
        self::ACTION_CREATE_REDIRECT   => ['source_path', 'destination_url', 'redirect_type'],
        self::ACTION_EDIT_REDIRECT     => ['redirect_id', 'source_path', 'destination_url'],
        self::ACTION_DELETE_REDIRECT   => ['redirect_id'],
        self::ACTION_APPLY_TEMPLATE    => ['template_id', 'template_name', 'records'],
        self::ACTION_SYNC_ZONE         => [],
    ];
}
