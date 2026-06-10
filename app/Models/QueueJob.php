<?php

namespace MJ\DnsManager\Models;

defined("WHMCS") or die("Access Denied");

use Illuminate\Database\Eloquent\Model;

class QueueJob extends Model
{
    protected $table = 'tbl_mj_dns_queue';
    public $timestamps = false;

    protected $fillable = [
        'batch_id',
        'domain_id',
        'server_id',
        'action',
        'payload',
        'status',
        'priority',
        'attempts',
        'max_attempts',
        'next_retry_at',
        'locked_by',
        'locked_at',
        'error_message',
        'error_type',
        'actor_type',
        'actor_id',
        'scheduled_at',
        'started_at',
        'completed_at'
    ];

    protected $casts = [
        'domain_id' => 'integer',
        'server_id' => 'integer',
        'payload' => 'array',
        'priority' => 'integer',
        'attempts' => 'integer',
        'max_attempts' => 'integer',
        'next_retry_at' => 'datetime',
        'locked_at' => 'datetime',
        'actor_id' => 'integer',
        'scheduled_at' => 'datetime',
        'started_at' => 'datetime',
        'completed_at' => 'datetime',
    ];

    public function domain()
    {
        return $this->belongsTo(Domain::class, 'domain_id');
    }

    public function server()
    {
        return $this->belongsTo(Server::class, 'server_id');
    }
}
