<?php

namespace HvnGroup\DnsManager\Models;

use Illuminate\Database\Eloquent\Model;

class EmailForward extends Model
{
    protected $table = 'mod_hvndns_email_forwards';
    
    protected $fillable = [
        'domain_id', 
        'source_local', 
        'destination_email', 
        'is_catchall'
    ];

    protected $casts = [
        'domain_id' => 'integer',
        'is_catchall' => 'boolean',
    ];

    public function domain()
    {
        return $this->belongsTo(Domain::class, 'domain_id');
    }
}
