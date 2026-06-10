<?php

namespace MJ\DnsManager\Models;

defined("WHMCS") or die("Access Denied");

use Illuminate\Database\Eloquent\Model;

class IpBlacklist extends Model
{
    protected $table = 'tbl_mj_dns_ip_blacklist';
    
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
