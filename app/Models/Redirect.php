<?php

namespace MJ\DnsManager\Models;

use Illuminate\Database\Eloquent\Model;

class Redirect extends Model
{
    protected $table = 'tbl_mj_dns_redirects';

    protected $fillable = [
        'domain_id',
        'source_path',
        'destination_url',
        'type',         
        'masked_title',  
        'masked_desc',   
    ];

    protected $casts = [
        'domain_id' => 'integer',
    ];

    public function domain()
    {
        return $this->belongsTo(Domain::class, 'domain_id');
    }
}