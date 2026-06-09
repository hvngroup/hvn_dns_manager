<?php

namespace HvnGroup\DnsManager\Models;

use Illuminate\Database\Eloquent\Model;

class Domain extends Model
{
    protected $table = 'mod_hvndns_domains';

    protected $fillable = [
        'domain',
        'whmcs_domain_id',
        'whmcs_user_id',
        'status',
        'ssl_status',
        'ssl_expires_at',
        'default_ip',
        'notes',
        'provisioned_at',
        'suspended_at',
        'terminated_at'
    ];

    protected $casts = [
        'whmcs_domain_id' => 'integer',
        'whmcs_user_id' => 'integer',
        'ssl_expires_at' => 'datetime',
        'provisioned_at' => 'datetime',
        'suspended_at' => 'datetime',
        'terminated_at' => 'datetime',
    ];

    public function records()
    {
        return $this->hasMany(Record::class, 'domain_id');
    }

    public function dnssec()
    {
        return $this->hasOne(Dnssec::class, 'domain_id');
    }
}
