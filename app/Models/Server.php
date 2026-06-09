<?php

namespace MJ\DnsManager\Models;

use Illuminate\Database\Eloquent\Model;


class Server extends Model
{
    protected $table = 'tbl_mj_dns_servers';

    protected $fillable = [
        'hostname',
        'ip_address',
        'port',
        'username',
        'use_ssl',
        'role',
        'is_active',
        'max_concurrent',
        'nameservers',
        'backoff_until',
        'backoff_count',
        'last_success_at',
        'last_error_at',
        'last_error_msg',
        'sort_order',
        'notes'
    ];

    protected $hidden = [
        'password_enc',
        'username',
        'ip_address'
    ];

    protected $casts = [
        'port' => 'integer',
        'use_ssl' => 'boolean',
        'is_active' => 'boolean',
        'max_concurrent' => 'integer',
        'backoff_count' => 'integer',
        'sort_order' => 'integer',
        'nameservers' => 'array', // TEXT column storing JSON array of NS hostnames
        // backoff_until, last_success_at, last_error_at: kept as strings
        // AdminController uses date()/strtotime() to format these safely
    ];

    public function setPasswordAttribute($value)
    {
        $this->attributes['password_enc'] = class_exists('\WHMCS\Security\Encryption')
            ? \WHMCS\Security\Encryption::encode($value)
            : base64_encode($value);
    }

    public function getPasswordAttribute()
    {
        if (!isset($this->attributes['password_enc'])) {
            return null;
        }
        return class_exists('\WHMCS\Security\Encryption')
            ? \WHMCS\Security\Encryption::decode($this->attributes['password_enc'])
            : base64_decode($this->attributes['password_enc']);
    }
}
