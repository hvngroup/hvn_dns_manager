<?php

namespace HvnGroup\DnsManager\Models;

use Illuminate\Database\Eloquent\Model;

class Redirect extends Model
{
    protected $table = 'mod_hvndns_redirects';
    
    protected $fillable = [
        'domain_id', 
        'source_path', 
        'destination_url', 
        'type', 
        'masked_title', 
        'masked_desc'
    ];

    protected $casts = [
        'domain_id' => 'integer',
    ];

    public function domain()
    {
        return $this->belongsTo(Domain::class, 'domain_id');
    }
}
