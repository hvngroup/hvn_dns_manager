<?php

namespace HvnGroup\DnsManager\Models;

use Illuminate\Database\Eloquent\Model;

class AuditTrail extends Model
{
    protected $table = 'mod_hvndns_audit_trail';
    
    protected $fillable = [
        'actor_type', 
        'actor_id', 
        'actor_name', 
        'domain', 
        'domain_id', 
        'action', 
        'target_type', 
        'target_id', 
        'old_value', 
        'new_value', 
        'context', 
        'ip_address', 
        'user_agent', 
        'session_id', 
        'notes'
    ];

    const UPDATED_AT = null;

    protected $casts = [
        'actor_id' => 'integer',
        'domain_id' => 'integer',
        'target_id' => 'integer',
        'old_value' => 'array',
        'new_value' => 'array',
    ];

    public function update(array $attributes = [], array $options = [])
    {
        throw new \RuntimeException('AuditTrail records cannot be updated. They are append-only.');
    }

    public function delete()
    {
        throw new \RuntimeException('AuditTrail records cannot be deleted. They are append-only.');
    }
}
