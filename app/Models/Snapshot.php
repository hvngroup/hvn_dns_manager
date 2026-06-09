<?php

namespace MJ\DnsManager\Models;

use Illuminate\Database\Eloquent\Model;

class Snapshot extends Model
{
    protected $table = 'tbl_mj_dns_snapshots';
    
    protected $fillable = [
        'domain_id', 
        'snapshot_type', 
        'records_data', 
        'record_count', 
        'trigger_info', 
        'created_by', 
        'created_by_id'
    ];

    const UPDATED_AT = null;

    protected $casts = [
        'domain_id' => 'integer',
        'records_data' => 'array',
        'record_count' => 'integer',
        'created_by_id' => 'integer',
    ];

    public function domain()
    {
        return $this->belongsTo(Domain::class, 'domain_id');
    }
}
