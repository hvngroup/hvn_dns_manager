<?php

namespace MJ\DnsManager\Models;

defined("WHMCS") or die("Access Denied");

use Illuminate\Database\Eloquent\Model;

class NotificationCooldown extends Model
{
    protected $table = 'tbl_mj_dns_notification_cooldowns';
    
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
