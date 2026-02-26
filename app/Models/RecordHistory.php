<?php

namespace HvnGroup\DnsManager\Models;

use Illuminate\Database\Eloquent\Model;

class RecordHistory extends Model
{
    protected $table = 'mod_hvndns_record_history';
    
    protected $fillable = [
        'record_id', 
        'domain_id', 
        'change_type', 
        'old_type', 
        'old_name', 
        'old_value', 
        'old_ttl', 
        'old_priority', 
        'new_type', 
        'new_name', 
        'new_value', 
        'new_ttl', 
        'new_priority', 
        'changed_by_type', 
        'changed_by_id'
    ];

    const UPDATED_AT = null;

    protected $casts = [
        'record_id' => 'integer',
        'domain_id' => 'integer',
        'old_ttl' => 'integer',
        'old_priority' => 'integer',
        'new_ttl' => 'integer',
        'new_priority' => 'integer',
        'changed_by_id' => 'integer',
    ];

    public function domain()
    {
        return $this->belongsTo(Domain::class, 'domain_id');
    }
}
