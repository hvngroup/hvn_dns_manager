<?php

namespace MJ\DnsManager\Models;

use Illuminate\Database\Eloquent\Model;

class Record extends Model
{
    protected $table = 'tbl_mj_dns_records';
    
    protected $fillable = [
        'domain_id', 
        'type', 
        'name', 
        'value', 
        'ttl', 
        'priority', 
        'weight', 
        'port', 
        'is_system', 
        'is_locked', 
        'pending_delete'
    ];

    protected $casts = [
        'domain_id' => 'integer',
        'ttl' => 'integer',
        'priority' => 'integer',
        'weight' => 'integer',
        'port' => 'integer',
        'is_system' => 'boolean',
        'is_locked' => 'boolean',
        'pending_delete' => 'boolean',
    ];

    public function domain()
    {
        return $this->belongsTo(Domain::class, 'domain_id');
    }
}
