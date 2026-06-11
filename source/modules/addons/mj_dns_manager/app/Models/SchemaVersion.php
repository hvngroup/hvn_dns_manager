<?php

namespace MJ\DnsManager\Models;

defined("WHMCS") or die("Access Denied");

use Illuminate\Database\Eloquent\Model;

class SchemaVersion extends Model
{
    protected $table = 'tbl_mj_dns_schema_version';
    protected $fillable = ['version', 'description'];
    
    public $timestamps = false;
    
    protected $casts = [
        'executed_at' => 'datetime',
    ];
}
