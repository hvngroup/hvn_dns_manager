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
        'is_catchall',
        'synced_at',
    ];

    protected $casts = [
        'domain_id'   => 'integer',
        'is_catchall' => 'boolean',
    ];

    protected $dates = ['synced_at', 'created_at', 'updated_at'];

    /**
     * Relationship: thuộc về Domain.
     */
    public function domain()
    {
        return $this->belongsTo(Domain::class, 'domain_id');
    }

    /**
     * Scope: lấy forwarders của một domain cụ thể.
     *
     * @param  \Illuminate\Database\Eloquent\Builder $query
     * @param  int $domainId
     * @return \Illuminate\Database\Eloquent\Builder
     */
    public function scopeForDomain($query, int $domainId)
    {
        return $query->where('domain_id', $domainId);
    }

    /**
     * Kiểm tra forwarder đã sync thành công hay chưa.
     *
     * @return bool
     */
    public function isSynced(): bool
    {
        return $this->synced_at !== null;
    }
}
