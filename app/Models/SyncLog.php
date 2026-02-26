<?php

namespace HvnGroup\DnsManager\Models;

use Illuminate\Database\Eloquent\Model;

class SyncLog extends Model
{
    protected $table = 'mod_hvndns_sync_logs';
    
    protected $fillable = [
        'queue_id', 
        'server_id', 
        'http_method', 
        'http_url', 
        'http_status', 
        'request_body', 
        'response_body', 
        'duration_ms', 
        'success', 
        'error_type'
    ];

    public $timestamps = false; // Only uses created_at by default mapping usually it's handled by Model if UPDATED_AT is null but let's see. DB_SCHEMA only has created_at.

    const UPDATED_AT = null;
    
    protected $casts = [
        'queue_id' => 'integer',
        'server_id' => 'integer',
        'http_status' => 'integer',
        'duration_ms' => 'integer',
        'success' => 'boolean',
    ];

    public function queueJob()
    {
        return $this->belongsTo(QueueJob::class, 'queue_id');
    }

    public function server()
    {
        return $this->belongsTo(Server::class, 'server_id');
    }
}
