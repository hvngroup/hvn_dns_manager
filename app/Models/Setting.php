<?php

namespace HvnGroup\DnsManager\Models;

use Illuminate\Database\Eloquent\Model;

class Setting extends Model
{
    protected $table = 'mod_hvndns_settings';
    protected $fillable = ['setting_key', 'setting_val'];
}
