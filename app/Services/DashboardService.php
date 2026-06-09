<?php

namespace HvnGroup\DnsManager\Services;

use HvnGroup\DnsManager\Models\Domain;
use HvnGroup\DnsManager\Models\Record;
use HvnGroup\DnsManager\Models\QueueJob;
use HvnGroup\DnsManager\Models\Server;
use HvnGroup\DnsManager\Models\SyncLog;

class DashboardService
{
    // ─────────────────────────────────────────────────────────────────────────
    // Page data — dùng cho actionDashboard() (render lần đầu, không AJAX)
    // ─────────────────────────────────────────────────────────────────────────

    public function getPageData(): array
    {
        $queueStats = QueueJob::selectRaw('status, count(*) as cnt')->groupBy('status')->pluck('cnt', 'status')->toArray();
        $statsComplete = $queueStats['COMPLETE'] ?? 0;
        $statsPending = ($queueStats['PENDING'] ?? 0) + ($queueStats['SYNCING'] ?? 0);
        $statsFailed = ($queueStats['FAILED'] ?? 0) + ($queueStats['PERMANENTLY_FAILED'] ?? 0);

        $servers = $this->buildServerHealth();

        $hasCriticalAlert = array_reduce($servers, function ($carry, $s) {
            return $carry || ($s['failed'] > 0 && $s['status'] === 'offline');
        }, false);

        $statusMap = $this->statusMap();
        $sevenDaysAgo = date('Y-m-d H:i:s', strtotime('-7 days'));

        $recentJobs = QueueJob::with(['domain', 'server'])->orderByDesc('id')->limit(20)->get()
            ->map(function (QueueJob $job) use ($statusMap) {
                $status = $statusMap[$job->status] ?? 'pending';
                return [
                    'time' => $job->created_at ? date('H:i', strtotime((string) $job->created_at)) : '',
                    'action' => $job->action,
                    'domain' => $job->domain ? $job->domain->domain : '—',
                    'server' => $job->server ? $job->server->hostname : '—',
                    'status' => $status,
                    'status_text' => $status === 'complete' ? 'Complete' : ($status === 'failed' ? 'Failed' : 'Pending'),
                ];
            })->toArray();

        $topDomains = QueueJob::selectRaw('domain_id, count(*) as changes_count')
            ->where('created_at', '>=', $sevenDaysAgo)
            ->groupBy('domain_id')->orderByDesc('changes_count')->limit(5)->with('domain')
            ->get()->map(function ($row) {
                return ['domain' => $row->domain ? $row->domain->domain : '—', 'changes_count' => $row->changes_count];
            })->toArray();

        return [
            'hasCriticalAlert' => $hasCriticalAlert,
            'stats' => [
                'complete' => number_format($statsComplete),
                'pending' => number_format($statsPending),
                'failed' => number_format($statsFailed),
                'domains' => number_format(Domain::where('status', 'active')->count()),
                'records' => number_format(Record::count()),
            ],
            'servers' => $servers,
            'recentActivity' => $recentJobs,
            'topDomains' => $topDomains,
        ];
    }

    // ─────────────────────────────────────────────────────────────────────────
    // AJAX stats — dùng cho ajaxGetDashboardStats()
    // ─────────────────────────────────────────────────────────────────────────

    public function getStats(int $days): array
    {
        try {
            $nowTs = time();
            $queueStats = QueueJob::selectRaw('status, count(*) as cnt')->groupBy('status')->pluck('cnt', 'status')->toArray();

            $stats = [
                'complete' => number_format($queueStats['COMPLETE'] ?? 0),
                'pending' => number_format(($queueStats['PENDING'] ?? 0) + ($queueStats['SYNCING'] ?? 0)),
                'failed' => number_format(($queueStats['FAILED'] ?? 0) + ($queueStats['PERMANENTLY_FAILED'] ?? 0)),
                'domains' => number_format(Domain::where('status', 'active')->count()),
                'records' => number_format(Record::count()),
            ];

            $startDate = date('Y-m-d', strtotime("-{$days} days"));
            $dailyRaw = QueueJob::selectRaw(
                "DATE(created_at) as day,
                 SUM(status = 'COMPLETE') as complete,
                 SUM(status IN ('FAILED','PERMANENTLY_FAILED')) as failed,
                 SUM(status IN ('PENDING','SYNCING')) as pending"
            )->where('created_at', '>=', $startDate . ' 00:00:00')
                ->groupBy('day')->orderBy('day')->get()->keyBy('day')->toArray();

            $chartLabels = $chartComplete = $chartFailed = $chartPending = [];
            for ($i = $days - 1; $i >= 0; $i--) {
                $date = date('Y-m-d', strtotime("-{$i} days"));
                $row = $dailyRaw[$date] ?? null;
                $chartLabels[] = date('d/m', strtotime($date));
                $chartComplete[] = $row ? (int) $row['complete'] : 0;
                $chartFailed[] = $row ? (int) $row['failed'] : 0;
                $chartPending[] = $row ? (int) $row['pending'] : 0;
            }

            $servers = $this->buildServerHealth(true);
            $hasCriticalAlert = false;
            $alertMessages = [];
            foreach ($servers as $srv) {
                if ($srv['status'] === 'offline' && $srv['failed'] > 0) {
                    $hasCriticalAlert = true;
                    $alertMessages[] = "{$srv['hostname']} mất kết nối — {$srv['failed']} job FAILED.";
                }
                if ($srv['status'] === 'warning' && $srv['failed'] > 5) {
                    $hasCriticalAlert = true;
                    $alertMessages[] = "{$srv['hostname']} đang không ổn định — {$srv['failed']} job FAILED.";
                }
            }

            $statusMap = $this->statusMap();
            $sevenDaysAgo = date('Y-m-d H:i:s', strtotime('-7 days'));

            $recentActivity = QueueJob::with(['domain', 'server'])->orderByDesc('id')->limit(20)->get()
                ->map(function (QueueJob $job) use ($statusMap) {
                    $status = $statusMap[$job->status] ?? 'pending';
                    return [
                        'id' => $job->id,
                        'time' => $job->created_at ? date('H:i', strtotime((string) $job->created_at)) : '',
                        'action' => $job->action,
                        'domain' => $job->domain ? $job->domain->domain : '—',
                        'server' => $job->server ? $job->server->hostname : '—',
                        'status' => $status,
                        'status_text' => $status === 'complete' ? 'Complete' : ($status === 'failed' ? 'Failed' : 'Pending'),
                        'error_brief' => $job->error_message ? mb_substr($job->error_message, 0, 80) : null,
                    ];
                })->toArray();

            $topDomains = QueueJob::selectRaw('domain_id, count(*) as changes_count')
                ->where('created_at', '>=', $sevenDaysAgo)
                ->groupBy('domain_id')->orderByDesc('changes_count')->limit(5)->with('domain')
                ->get()->map(function ($r) {
                    return ['domain' => $r->domain ? $r->domain->domain : '—', 'changes_count' => $r->changes_count];
                })->toArray();

            return [
                'success' => true,
                'stats' => $stats,
                'chartData' => ['labels' => $chartLabels, 'complete' => $chartComplete, 'failed' => $chartFailed, 'pending' => $chartPending],
                'servers' => $servers,
                'recentActivity' => $recentActivity,
                'topDomains' => $topDomains,
                'hasCriticalAlert' => $hasCriticalAlert,
                'alertMessages' => $alertMessages,
                'generatedAt' => date('H:i:s'),
            ];
        } catch (\Throwable $e) {
            return ['success' => false, 'error' => $e->getMessage()];
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Helpers
    // ─────────────────────────────────────────────────────────────────────────

    private function buildServerHealth(bool $withUptime = false): array
    {
        $nowTs = time();
        return Server::where('is_active', true)->orderBy('sort_order')->get()
            ->map(function (Server $srv) use ($nowTs, $withUptime) {
                $backoffActive = $srv->backoff_until && strtotime((string) $srv->backoff_until) > $nowTs;
                $status = $backoffActive ? 'offline' : ($srv->backoff_count > 2 ? 'warning' : 'online');
                $pending = QueueJob::where('server_id', $srv->id)->whereIn('status', ['PENDING', 'SYNCING'])->count();
                $failed = QueueJob::where('server_id', $srv->id)->whereIn('status', ['FAILED', 'PERMANENTLY_FAILED'])->count();
                $avgMs = SyncLog::where('server_id', $srv->id)->where('success', 1)->whereNotNull('duration_ms')->orderByDesc('id')->limit(100)->avg('duration_ms');

                $row = [
                    'id' => $srv->id,
                    'hostname' => $srv->hostname,
                    'is_primary' => $srv->role === 'primary',
                    'status' => $status,
                    'pending' => $pending,
                    'failed' => $failed,
                    'latency' => $avgMs ? round($avgMs) : null,
                    'last_error' => $srv->last_error_msg,
                ];

                if ($withUptime) {
                    $total = SyncLog::where('server_id', $srv->id)->orderByDesc('id')->limit(100)->count();
                    $success = SyncLog::where('server_id', $srv->id)->where('success', 1)->orderByDesc('id')->limit(100)->count();
                    $row['uptime'] = $total > 0 ? round(($success / $total) * 100, 1) : null;
                }

                return $row;
            })->toArray();
    }

    private function statusMap(): array
    {
        return [
            'COMPLETE' => 'complete',
            'FAILED' => 'failed',
            'PERMANENTLY_FAILED' => 'failed',
            'PENDING' => 'pending',
            'SYNCING' => 'pending',
            'CANCELLED' => 'pending',
        ];
    }
}