<?php

namespace MJ\DnsManager\Models;

use Illuminate\Database\Eloquent\Model;

class Template extends Model
{
    protected $table = 'tbl_mj_dns_templates';
    
    protected $fillable = [
        'name', 
        'description', 
        'is_default', 
        'records_data', 
        'is_visible_client', 
        'created_by_user_id'
    ];

    protected $casts = [
        'is_default' => 'boolean',
        'records_data' => 'array',
        'is_visible_client' => 'boolean',
        'created_by_user_id' => 'integer',
    ];
}
