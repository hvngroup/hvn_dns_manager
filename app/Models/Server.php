<?php

namespace HvnGroup\DnsManager\Models;

use Illuminate\Database\Eloquent\Model;
use WHMCS\Security\Encryption;

class Server extends Model
{
    protected $table = 'mod_hvndns_servers';
    
    protected $fillable = [
        'hostname', 
        'ip_address', 
        'port', 
        'username', 
        'use_ssl', 
        'role', 
        'is_active', 
        'max_concurrent', 
        'backoff_until', 
        'backoff_count', 
        'last_success_at', 
        'last_error_at', 
        'last_error_msg', 
        'sort_order', 
        'notes'
    ];

    protected $hidden = [
        'password_enc'
    ];

    protected $casts = [
        'port' => 'integer',
        'use_ssl' => 'boolean',
        'is_active' => 'boolean',
        'max_concurrent' => 'integer',
        'backoff_until' => 'datetime',
        'backoff_count' => 'integer',
        'last_success_at' => 'datetime',
        'last_error_at' => 'datetime',
        'sort_order' => 'integer',
    ];

    public function setPasswordAttribute($value)
    {
        $this->attributes['password_enc'] = Encryption::encode($value);
    }

    public function getPasswordAttribute()
    {
        return isset($this->attributes['password_enc']) 
            ? Encryption::decode($this->attributes['password_enc']) 
            : null;
    }
}
