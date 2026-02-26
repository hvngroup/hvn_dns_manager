<?php

namespace HvnGroup\DnsManager\Models;

use Illuminate\Database\Eloquent\Model;

class NotificationCooldown extends Model
{
    protected $table = 'mod_hvndns_notification_cooldowns';
    
    protected $fillable = [
        'rule_id', 
        'target_id', 
        'last_sent_at'
    ];

    public $timestamps = false; // No created_at or updated_at shown in schema for this, check schema mapping: only last_sent_at

    protected $casts = [
        'last_sent_at' => 'datetime',
    ];
}
