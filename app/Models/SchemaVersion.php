<?php

namespace HvnGroup\DnsManager\Models;

use Illuminate\Database\Eloquent\Model;

class SchemaVersion extends Model
{
    protected $table = 'mod_hvndns_schema_version';
    protected $fillable = ['version', 'description'];
    
    public $timestamps = false;
    
    protected $casts = [
        'executed_at' => 'datetime',
    ];
}
