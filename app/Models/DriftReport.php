<?php

namespace MJ\DnsManager\Models;

defined("WHMCS") or die("Access Denied");

use Illuminate\Database\Eloquent\Model;

class DriftReport extends Model
{
    protected $table = 'tbl_mj_dns_drift_reports';
    
    protected $fillable = [
        'domain_id', 
        'drift_type', 
        'record_type', 
        'record_name', 
        'local_value', 
        'remote_value', 
        'status', 
        'resolved_at'
    ];

    const UPDATED_AT = null;

    protected $casts = [
        'domain_id' => 'integer',
        'local_value' => 'array',
        'remote_value' => 'array',
        'detected_at' => 'datetime',
        'resolved_at' => 'datetime',
    ];

    public function domain()
    {
        return $this->belongsTo(Domain::class, 'domain_id');
    }
}
