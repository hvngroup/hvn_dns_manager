<?php

namespace MJ\DnsManager\Models;

use Illuminate\Database\Eloquent\Model;

class Setting extends Model
{
    protected $table = 'tbl_mj_dns_settings';
    protected $fillable = ['setting_key', 'setting_val'];
}
