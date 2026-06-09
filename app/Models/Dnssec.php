<?php

namespace HvnGroup\DnsManager\Models;

use Illuminate\Database\Eloquent\Model;

class Dnssec extends Model
{
    protected $table = 'mod_hvndns_dnssec';
    
    protected $fillable = [
        'domain_id', 
        'is_enabled', 
        'key_tag', 
        'algorithm', 
        'digest_type', 
        'digest', 
        'ds_record_raw', 
        'public_key', 
        'last_signed_at'
    ];

    protected $casts = [
        'domain_id' => 'integer',
        'is_enabled' => 'boolean',
        'key_tag' => 'integer',
        'algorithm' => 'integer',
        'digest_type' => 'integer',
        'last_signed_at' => 'datetime',
    ];

    public function domain()
    {
        return $this->belongsTo(Domain::class, 'domain_id');
    }
}
