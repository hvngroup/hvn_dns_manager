<?php

namespace HvnGroup\DnsManager\Models;

use Illuminate\Database\Eloquent\Model;

class DdnsToken extends Model
{
    protected $table = 'mod_hvndns_ddns_tokens';
    
    protected $fillable = [
        'domain_id', 
        'subdomain', 
        'token_hash', 
        'label', 
        'last_ip', 
        'last_update_at', 
        'last_request_at', 
        'is_active', 
        'request_count'
    ];

    protected $hidden = [
        'token_hash'
    ];

    const UPDATED_AT = null;

    protected $casts = [
        'domain_id' => 'integer',
        'last_update_at' => 'datetime',
        'last_request_at' => 'datetime',
        'is_active' => 'boolean',
        'request_count' => 'integer',
    ];

    public function setTokenAttribute($value)
    {
        $this->attributes['token_hash'] = hash('sha256', $value);
    }

    public function verifyToken($token)
    {
        return hash('sha256', $token) === $this->token_hash;
    }

    public function domain()
    {
        return $this->belongsTo(Domain::class, 'domain_id');
    }
}
