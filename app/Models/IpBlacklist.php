<?php

namespace HvnGroup\DnsManager\Models;

use Illuminate\Database\Eloquent\Model;

class IpBlacklist extends Model
{
    protected $table = 'mod_hvndns_ip_blacklist';
    
    protected $fillable = [
        'ip_address', 
        'reason', 
        'blocked_until'
    ];

    const UPDATED_AT = null;

    protected $casts = [
        'blocked_until' => 'datetime',
    ];

    public function scopeActive($query)
    {
        return $query->where('blocked_until', '>', \Carbon\Carbon::now());
    }
}
