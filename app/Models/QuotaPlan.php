<?php

namespace HvnGroup\DnsManager\Models;

use Illuminate\Database\Eloquent\Model;

class QuotaPlan extends Model
{
    protected $table = 'mod_hvndns_quota_plans';
    
    protected $fillable = [
        'plan_name', 
        'max_records', 
        'max_subdomains', 
        'max_redirects', 
        'max_email_fwd', 
        'max_ddns_tokens', 
        'ddns_enabled', 
        'dnssec_enabled', 
        'ssl_enabled'
    ];

    protected $casts = [
        'max_records' => 'integer',
        'max_subdomains' => 'integer',
        'max_redirects' => 'integer',
        'max_email_fwd' => 'integer',
        'max_ddns_tokens' => 'integer',
        'ddns_enabled' => 'boolean',
        'dnssec_enabled' => 'boolean',
        'ssl_enabled' => 'boolean',
    ];

    public function domains()
    {
        return $this->hasMany(Domain::class, 'quota_plan_id');
    }
}
