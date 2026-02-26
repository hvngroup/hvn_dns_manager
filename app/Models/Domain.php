<?php

namespace HvnGroup\DnsManager\Models;

use Illuminate\Database\Eloquent\Model;

class Domain extends Model
{
    protected $table = 'mod_hvndns_domains';
    
    protected $fillable = [
        'domain', 
        'whmcs_service_id', 
        'whmcs_user_id', 
        'status', 
        'ssl_status', 
        'ssl_expires_at', 
        'quota_plan_id', 
        'default_ip', 
        'notes', 
        'provisioned_at', 
        'suspended_at', 
        'terminated_at'
    ];

    protected $casts = [
        'whmcs_service_id' => 'integer',
        'whmcs_user_id' => 'integer',
        'ssl_expires_at' => 'datetime',
        'quota_plan_id' => 'integer',
        'provisioned_at' => 'datetime',
        'suspended_at' => 'datetime',
        'terminated_at' => 'datetime',
    ];

    public function quotaPlan()
    {
        return $this->belongsTo(QuotaPlan::class, 'quota_plan_id');
    }

    public function records()
    {
        return $this->hasMany(Record::class, 'domain_id');
    }

    public function dnssec()
    {
        return $this->hasOne(Dnssec::class, 'domain_id');
    }
}
