<?php

namespace MJ\DnsManager\Services;

defined("WHMCS") or die("Access Denied");

use MJ\DnsManager\Helpers\SettingsHelper;
use MJ\DnsManager\Models\QueueJob;
use MJ\DnsManager\Models\Server;
use Illuminate\Database\Capsule\Manager as Capsule;

/**
 * NotificationService — Gửi cảnh báo qua Telegram / Email khi hệ thống gặp sự cố.
 *
 * Trigger rules:
 *   RULE_01 — >= N job FAILED liên tiếp trên 1 server
 *   RULE_02 — Server unreachable >= N lần liên tiếp
 *   RULE_03 — Queue backlog > N jobs PENDING > 10 phút
 *
 * Gọi từ QueueWorker::failJob() sau mỗi lần job thất bại.
 */
class NotificationService
{
    const RULE_CONSECUTIVE_FAILS = 'RULE_01_fails';
    const RULE_SERVER_UNREACHABLE = 'RULE_02_unreachable';
    const RULE_QUEUE_BACKLOG = 'RULE_03_backlog';

    // Màu header email theo severity
    const COLOR_DANGER = '#dc3545'; // Đỏ — lỗi nghiêm trọng
    const COLOR_WARNING = '#ffc107'; // Vàng — cảnh báo
    const COLOR_SUCCESS = '#28a745'; // Xanh — thành công / test

    // ─────────────────────────────────────────────────────────────────────
    // Entry point
    // ─────────────────────────────────────────────────────────────────────

    public function triggerCheck($serverId)
    {
        $telegramOn = SettingsHelper::getBool('enable_telegram_alert', false);
        $emailOn = SettingsHelper::getBool('enable_email_alert', false);

        if (!$telegramOn && !$emailOn) {
            return;
        }

        $server = Server::find($serverId);
        if (!$server) {
            return;
        }

        $this->checkConsecutiveFails($server);
        $this->checkServerUnreachable($server);
        $this->checkQueueBacklog();
    }

    // ─────────────────────────────────────────────────────────────────────
    // RULE_01 — >= N job FAILED liên tiếp trên cùng 1 server
    // ─────────────────────────────────────────────────────────────────────

    private function checkConsecutiveFails(Server $server)
    {
        $threshold = SettingsHelper::getInt('alert_failed_threshold', 5);
        if ($threshold <= 0) {
            return;
        }

        $recentJobs = QueueJob::where('server_id', $server->id)
            ->whereIn('status', ['COMPLETE', 'FAILED', 'PERMANENTLY_FAILED'])
            ->orderBy('id', 'desc')
            ->limit($threshold + 5)
            ->pluck('status')
            ->toArray();

        $consecutiveFails = 0;
        foreach ($recentJobs as $status) {
            if ($status === 'COMPLETE') {
                break;
            }
            $consecutiveFails++;
        }

        if ($consecutiveFails < $threshold) {
            return;
        }

        $ruleId = self::RULE_CONSECUTIVE_FAILS;
        $target = 'server_' . $server->id;

        if (!$this->passCooldown($ruleId, $target)) {
            return;
        }

        $fields = array(
            'Rule'   => 'Consecutive Job Failures',
            'Server' => $server->hostname,
            'Failed' => $consecutiveFails . ' jobs in a row',
            'Action' => 'Check DA server connection or review Sync Logs',
        );

        $this->send(
            $this->buildTelegramMessage('🔴 DNS Sync Failure Alert', $fields),
            '[MJ DNS] DNS Sync Failure: ' . $server->hostname,
            'DNS Sync Failure Alert',
            self::COLOR_DANGER,
            $fields,
            $consecutiveFails . ' consecutive jobs have failed on this server. Immediate attention may be required.'
        );

        $this->recordCooldown($ruleId, $target);
    }

    // ─────────────────────────────────────────────────────────────────────
    // RULE_02 — Server unreachable >= N lần liên tiếp
    // ─────────────────────────────────────────────────────────────────────

    private function checkServerUnreachable(Server $server)
    {
        $threshold = SettingsHelper::getInt('alert_unreachable_threshold', 3);
        if ($threshold <= 0) {
            return;
        }

        if ($server->backoff_count < $threshold) {
            return;
        }

        $lastError = (string) ($server->last_error_msg ?? '');
        if (!$this->isConnectionError($lastError)) {
            return;
        }

        $ruleId = self::RULE_SERVER_UNREACHABLE;
        $target = 'server_' . $server->id;

        if (!$this->passCooldown($ruleId, $target)) {
            return;
        }

        $backoffUntil = $server->backoff_until
            ? date('H:i:s', strtotime((string) $server->backoff_until))
            : 'N/A';

        $fields = array(
            'Rule'          => 'Server Unreachable',
            'Server'        => $server->hostname . ' (' . $server->ip_address . ')',
            'Fail count'    => $server->backoff_count . ' consecutive failures',
            'Backoff until' => $backoffUntil,
            'Last error'    => mb_substr($lastError, 0, 100),
            'Action'        => 'Check server status and reset backoff in Admin',
        );

        $this->send(
            $this->buildTelegramMessage('🔴 Server Unreachable Alert', $fields),
            '[MJ DNS] Server Unreachable: ' . $server->hostname,
            'Server Unreachable Alert',
            self::COLOR_DANGER,
            $fields,
            'The following DirectAdmin server has been unreachable for ' . $server->backoff_count . ' consecutive attempts.'
        );

        $this->recordCooldown($ruleId, $target);
    }

    // ─────────────────────────────────────────────────────────────────────
    // RULE_03 — Queue backlog > N jobs PENDING > 10 phút
    // ─────────────────────────────────────────────────────────────────────

    /**
     * Public wrapper — gọi từ QueueWorker::run() sau mỗi chu kỳ cron.
     */
    public function checkBacklogAlert()
    {
        $telegramOn = SettingsHelper::getBool('enable_telegram_alert', false);
        $emailOn = SettingsHelper::getBool('enable_email_alert', false);
        if (!$telegramOn && !$emailOn) {
            return;
        }
        $this->checkQueueBacklog();
    }

    private function checkQueueBacklog()
    {
        $threshold = SettingsHelper::getInt('alert_queue_backlog_threshold', 100);
        if ($threshold <= 0) {
            return;
        }

        $tenMinutesAgo = date('Y-m-d H:i:s', strtotime('-10 minutes'));
        $backlogCount = QueueJob::where('status', 'PENDING')
            ->where('created_at', '<=', $tenMinutesAgo)
            ->count();

        if ($backlogCount <= $threshold) {
            return;
        }

        $ruleId = self::RULE_QUEUE_BACKLOG;
        $target = 'global';

        if (!$this->passCooldown($ruleId, $target)) {
            return;
        }

        $fields = array(
            'Rule'    => 'Queue Congestion',
            'Backlog' => $backlogCount . ' jobs PENDING for more than 10 minutes',
            'Action'  => 'Check whether the Cron Worker is running',
        );

        $this->send(
            $this->buildTelegramMessage('🟡 Queue Backlog Warning', $fields),
            '[MJ DNS] Queue Backlog: ' . $backlogCount . ' jobs',
            'Queue Backlog Warning',
            self::COLOR_WARNING,
            $fields,
            $backlogCount . ' DNS jobs have been pending for more than 10 minutes. The cron worker may not be running.'
        );

        $this->recordCooldown($ruleId, $target);
    }

    // ─────────────────────────────────────────────────────────────────────
    // Gửi alert qua tất cả kênh được bật
    // ─────────────────────────────────────────────────────────────────────

    /**
     * Gửi đồng thời Telegram + Email với nội dung riêng cho từng kênh.
     *
     * @param string $telegramMsg  Nội dung Telegram (Markdown plain text)
     * @param string $emailSubject Subject email
     * @param string $emailTitle   Tiêu đề hiển thị trong HTML email
     * @param string $emailColor   Màu header (#hex)
     * @param array  $emailFields  Dữ liệu dạng key => value cho bảng email
     */
    private function send($telegramMsg, $emailSubject, $emailTitle, $emailColor, array $emailFields, $intro = null, $outro = null)
    {
        if (SettingsHelper::getBool('enable_telegram_alert', false)) {
            $this->sendTelegram($telegramMsg);
        }

        if (SettingsHelper::getBool('enable_email_alert', false)) {
            $htmlBody = $this->buildAdminEmailBody($emailTitle, $emailColor, $emailFields, $intro, $outro);
            $this->sendEmail($emailSubject, $htmlBody);
        }
    }

    // ─────────────────────────────────────────────────────────────────────
    // Gửi email độc lập — dùng cho PERMANENTLY_FAILED, SSL failed
    // (những nơi gọi sendTelegram() trực tiếp, không qua send())
    // ─────────────────────────────────────────────────────────────────────

    public function sendEmailDirect($subject, $title, $color, array $fields, $intro = null, $outro = null)
    {
        if (!SettingsHelper::getBool('enable_email_alert', false)) {
            return false;
        }

        $htmlBody = $this->buildAdminEmailBody($title, $color, $fields, $intro, $outro);
        return $this->sendEmail($subject, $htmlBody);
    }

    // ─────────────────────────────────────────────────────────────────────
    // Telegram — gửi tin nhắn thật (dùng cho alert)
    // ─────────────────────────────────────────────────────────────────────

    public function sendTelegram($message)
    {
        try {
            $rawToken = SettingsHelper::get('telegram_bot_token', '');
            $chatId = SettingsHelper::get('telegram_chat_id', '');

            if (empty($rawToken) || empty($chatId)) {
                return false;
            }

            $token = $this->decryptToken($rawToken);
            $chatId = trim($chatId);

            if (empty($token)) {
                logActivity('MJ DNS Manager [NotificationService]: Telegram token rỗng sau decrypt.');
                return false;
            }

            $url = 'https://api.telegram.org/bot' . $token . '/sendMessage';
            $postData = http_build_query([
                'chat_id' => $chatId,
                'text' => $message,
            ]);

            $ch = curl_init();
            curl_setopt($ch, CURLOPT_URL, $url);
            curl_setopt($ch, CURLOPT_POST, true);
            curl_setopt($ch, CURLOPT_POSTFIELDS, $postData);
            curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
            curl_setopt($ch, CURLOPT_TIMEOUT, 10);
            curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);
            curl_setopt($ch, CURLOPT_IPRESOLVE, CURL_IPRESOLVE_V4);
            curl_setopt($ch, CURLOPT_HTTPHEADER, ['Content-Type: application/x-www-form-urlencoded']);

            $response = curl_exec($ch);
            $curlError = curl_error($ch);
            curl_close($ch);

            if ($response === false) {
                logActivity('MJ DNS Manager [NotificationService]: Telegram cURL error — ' . $curlError);
                return false;
            }

            $result = json_decode($response, true);
            if (!$result || empty($result['ok'])) {
                $desc = isset($result['description']) ? $result['description'] : 'Unknown error';
                logActivity('MJ DNS Manager [NotificationService]: Telegram API error — ' . $desc);
                return false;
            }

            return true;
        } catch (\Throwable $e) {
            logActivity('MJ DNS Manager [NotificationService]: Telegram exception — ' . $e->getMessage());
            return false;
        }
    }

    // ─────────────────────────────────────────────────────────────────────
    // Telegram — test token bằng /getMe, KHÔNG gửi tin nhắn
    // ─────────────────────────────────────────────────────────────────────

    private function testTelegramToken()
    {
        try {
            $rawToken = SettingsHelper::get('telegram_bot_token', '');

            if (empty($rawToken)) {
                return ['success' => false, 'error' => 'Chưa cấu hình Telegram Bot Token.'];
            }

            $token = $this->decryptToken($rawToken);
            if (empty($token)) {
                return ['success' => false, 'error' => 'Không đọc được token. Vui lòng lưu lại token trong Settings.'];
            }

            $ch = curl_init();
            curl_setopt($ch, CURLOPT_URL, 'https://api.telegram.org/bot' . $token . '/getMe');
            curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
            curl_setopt($ch, CURLOPT_TIMEOUT, 10);
            curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);
            curl_setopt($ch, CURLOPT_IPRESOLVE, CURL_IPRESOLVE_V4);

            $response = curl_exec($ch);
            $curlError = curl_error($ch);
            curl_close($ch);

            if ($response === false) {
                return ['success' => false, 'error' => 'Không kết nối được tới Telegram: ' . $curlError];
            }

            $result = json_decode($response, true);
            if (!$result || empty($result['ok'])) {
                $desc = isset($result['description']) ? $result['description'] : 'Unknown error';
                return ['success' => false, 'error' => 'Token không hợp lệ: ' . $desc];
            }

            $botInfo = $result['result'];
            return [
                'success' => true,
                'bot_name' => $botInfo['first_name'],
                'bot_username' => '@' . $botInfo['username'],
                'bot_id' => $botInfo['id'],
            ];
        } catch (\Throwable $e) {
            return ['success' => false, 'error' => $e->getMessage()];
        }
    }

    /**
     * Send HTML email to all addresses in alert_email_addresses.
     * Uses WHMCS SMTP config directly via PHPMailer.
     */
    public function sendEmail($subject, $htmlBody)
    {
        try {
            $recipients = SettingsHelper::get('alert_email_addresses', '');
            if (empty($recipients)) {
                logActivity('MJ DNS Manager [NotificationService]: sendEmail skipped — alert_email_addresses not configured.');
                return false;
            }

            $emails = array_filter(array_map('trim', explode(',', $recipients)));
            if (empty($emails)) {
                return false;
            }

            $sent = false;
            foreach ($emails as $email) {
                if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
                    logActivity('MJ DNS Manager [NotificationService]: Invalid email skipped — ' . $email);
                    continue;
                }
                if ($this->sendEmailViaWhmcsMailer($email, $subject, $htmlBody)) {
                    $sent = true;
                }
            }

            return $sent;
        } catch (\Throwable $e) {
            logActivity('MJ DNS Manager [NotificationService]: Email exception — ' . $e->getMessage());
            return false;
        }
    }

    /**
     * Send via PHPMailer using WHMCS SMTP config.
     * WHMCS 8+: config stored encrypted in tblconfiguration.setting='MailConfig' as JSON.
     * WHMCS 7:  config stored as separate keys SMTPHost, SMTPPort, etc.
     */
    private function sendEmailViaWhmcsMailer($to, $subject, $htmlBody)
    {
        try {
            // ── STEP 1: Đọc SMTP config ───────────────────────────────────
            $baseRows = \Illuminate\Database\Capsule\Manager::table('tblconfiguration')
                ->whereIn('setting', array('MailConfig', 'MailType', 'Email', 'CompanyName'))
                ->get();

            $base = array();
            foreach ($baseRows as $row) {
                $base[$row->setting] = $row->value;
            }

            $fromEmail = !empty($base['Email']) ? $base['Email'] : 'noreply@localhost';
            $fromName  = !empty($base['CompanyName']) ? $base['CompanyName'] : 'MJ DNS Manager';

            // WHMCS 8+: toàn bộ SMTP config encrypt trong MailConfig dạng JSON
            $config   = array();
            $mailType = 'mail';
            $isWhmcs8 = false;

            if (!empty($base['MailConfig']) && function_exists('decrypt')) {
                try {
                    $decrypted = decrypt($base['MailConfig']);
                    if (!empty($decrypted)) {
                        $parsed = json_decode($decrypted, true);
                        if (is_array($parsed) && !empty($parsed)) {
                            // WHMCS 8 format: { "module": "SmtpMail", "configuration": { "host": ..., ... } }
                            $module = isset($parsed['module']) ? strtolower($parsed['module']) : '';
                            $inner  = isset($parsed['configuration']) && is_array($parsed['configuration'])
                                ? $parsed['configuration']
                                : $parsed;

                            $config   = $inner;
                            $mailType = ($module === 'smtpmail' || $module === 'smtp') ? 'smtp' : 'mail';
                            $isWhmcs8 = true;
                        }
                    }
                } catch (\Exception $e) {
                }
            }

            // Fallback WHMCS 7: đọc key riêng lẻ
            if (!$isWhmcs8) {
                $oldRows = \Illuminate\Database\Capsule\Manager::table('tblconfiguration')
                    ->whereIn('setting', array(
                        'MailType',
                        'SMTPHost',
                        'SMTPPort',
                        'SMTPUsername',
                        'SMTPPassword',
                        'SMTPSecure',
                        'SMTPAutoTLS',
                    ))
                    ->get();
                foreach ($oldRows as $row) {
                    $config[$row->setting] = $row->value;
                }
                $mailType = isset($config['MailType']) ? strtolower($config['MailType']) : 'mail';
            }

            // Map key theo WHMCS version
            $smtpHost = $isWhmcs8
                ? (isset($config['host'])     ? $config['host']     : '')
                : (isset($config['SMTPHost']) ? $config['SMTPHost'] : '');
            $smtpPort = $isWhmcs8
                ? (isset($config['port'])     ? $config['port']     : 25)
                : (isset($config['SMTPPort']) ? $config['SMTPPort'] : 25);
            $smtpUser = $isWhmcs8
                ? (isset($config['username'])     ? $config['username']     : '')
                : (isset($config['SMTPUsername']) ? $config['SMTPUsername'] : '');
            $smtpPass = $isWhmcs8
                ? (isset($config['password'])     ? $config['password']     : '')
                : (isset($config['SMTPPassword']) ? $config['SMTPPassword'] : '');
            // WHMCS 8 dùng key 'secure', không phải 'security'
            $smtpSec  = $isWhmcs8
                ? (isset($config['secure'])    ? $config['secure']    : '')
                : (isset($config['SMTPSecure']) ? $config['SMTPSecure'] : '');

            // ── STEP 2: Tìm PHPMailer ─────────────────────────────────────
            $whmcsRoot = dirname(__DIR__, 5);
            $pmV6      = $whmcsRoot . '/vendor/phpmailer/phpmailer/src/PHPMailer.php';
            $pmV5      = $whmcsRoot . '/includes/mail/class.phpmailer.php';

            if (file_exists($pmV6)) {
                require_once $pmV6;
                require_once dirname($pmV6) . '/SMTP.php';
                require_once dirname($pmV6) . '/Exception.php';
                $mail = new \PHPMailer\PHPMailer\PHPMailer(true);
            } elseif (file_exists($pmV5)) {
                require_once $pmV5;
                require_once dirname($pmV5) . '/class.smtp.php';
                $mail = new \PHPMailer(true);
            } else {
                return $this->sendEmailViaPhpMail($to, $subject, $htmlBody, $fromEmail, $fromName);
            }

            // ── STEP 3: Decrypt password (chỉ WHMCS 7, WHMCS 8 đã decrypt qua MailConfig) ──
            if (!$isWhmcs8 && !empty($smtpPass)) {
                if (function_exists('decrypt')) {
                    try {
                        $dec = decrypt($smtpPass);
                        if (!empty($dec)) {
                            $smtpPass = $dec;
                        }
                    } catch (\Exception $e) {
                    }
                }
            }

            // ── STEP 4: Cấu hình PHPMailer ────────────────────────────────
            $mail->CharSet  = 'UTF-8';
            $mail->From     = $fromEmail;
            $mail->FromName = $fromName;

            if ($mailType === 'smtp' && !empty($smtpHost)) {
                $mail->isSMTP();
                $mail->Host        = $smtpHost;
                $mail->Port        = (int) $smtpPort;
                $mail->SMTPAutoTLS = false;

                if (!empty($smtpUser)) {
                    $mail->SMTPAuth = true;
                    $mail->Username = $smtpUser;
                    $mail->Password = $smtpPass;
                }

                $secure = strtolower($smtpSec);
                if ($secure === 'ssl') {
                    $mail->SMTPSecure = 'ssl';
                } elseif ($secure === 'tls' || $secure === 'starttls') {
                    $mail->SMTPSecure = 'tls';
                } else {
                    $mail->SMTPSecure = '';
                }

                $mail->SMTPOptions = array(
                    'ssl' => array(
                        'verify_peer'       => false,
                        'verify_peer_name'  => false,
                        'allow_self_signed' => true,
                    ),
                );
            } else {
                $mail->isMail();
            }

            // ── STEP 5: Gửi ──────────────────────────────────────────────
            $mail->addAddress($to);
            $mail->isHTML(true);
            $mail->Subject = $subject;
            $mail->Body    = $htmlBody;
            $mail->AltBody = strip_tags(str_replace(
                array('<br>', '<br/>', '<br />'),
                "\n",
                $htmlBody
            ));

            $mail->send();

            return true;
        } catch (\Throwable $e) {
            return false;
        }
    }

    /**
     * Last-resort fallback khi PHPMailer không tìm thấy.   
     */
    private function sendEmailViaPhpMail($to, $subject, $htmlBody, $fromEmail, $fromName)
    {
        $headers  = 'From: ' . $fromName . ' <' . $fromEmail . '>' . "\r\n";
        $headers .= 'To: ' . $to . "\r\n";
        $headers .= 'Content-Type: text/html; charset=UTF-8' . "\r\n";
        $headers .= 'MIME-Version: 1.0' . "\r\n";

        $result = @mail($to, $subject, $htmlBody, $headers);

        if ($result) {
            logActivity('MJ DNS Manager [NotificationService]: Email sent to ' . $to . ' via PHP mail().');
        } else {
            $err = error_get_last();
            logActivity('MJ DNS Manager [NotificationService]: PHP mail() failed for ' . $to
                . ' — ' . ($err ? $err['message'] : 'unknown error'));
        }

        return (bool) $result;
    }

    // ─────────────────────────────────────────────────────────────────────
    // Queue Worker Notifications — gọi từ QueueWorker
    // ─────────────────────────────────────────────────────────────────────

    /**
     * Notify admin when a job is permanently failed — via Telegram + HTML email.
     */
    public function notifyJobPermanentlyFailed(
        $jobId,
        $jobAction,
        $attempts,
        $maxAttempts,
        $errorMessage,
        $serverHostname,
        $domainName,
        $recordType,
        $recordName
    ) {
        // ── Telegram ──────────────────────────────────────────────────────
        if (SettingsHelper::getBool('enable_telegram_alert', false)) {
            $this->sendTelegram(
                "\xF0\x9F\x94\xB4 *Job Permanently Failed*\n" .
                    "*Job ID:* #" . $jobId . "\n" .
                    "*Action:* " . $jobAction . "\n" .
                    "*Domain:* " . $domainName . "\n" .
                    "*Server:* " . $serverHostname . "\n" .
                    "*Attempts:* " . $attempts . "/" . $maxAttempts . "\n" .
                    "*Error:* " . mb_substr($errorMessage, 0, 200) . "\n" .
                    "*Time:* " . date('Y-m-d H:i:s T') . "\n" .
                    "*Next step:* Admin > DNS Manager > Sync Logs"
            );
        }

        // ── Email ─────────────────────────────────────────────────────────
        if (!SettingsHelper::getBool('enable_email_alert', false)) {
            return;
        }

        $record  = trim($recordType . ' ' . $recordName);
        $subject = '[MJ DNS] Job #' . $jobId . ' permanently failed — ' . $jobAction . ' on ' . $domainName;

        $fields = array(
            'Job ID'   => '#' . $jobId,
            'Action'   => $jobAction,
            'Domain'   => $domainName,
            'Record'   => $record !== '' ? $record : 'N/A',
            'Server'   => $serverHostname,
            'Attempts' => $attempts . ' / ' . $maxAttempts,
            'Error'    => mb_substr($errorMessage, 0, 300),
            'Time'     => date('Y-m-d H:i:s T'),
        );

        $intro = 'A DNS queue job has permanently failed and requires your attention.';
        $outro = 'Please check Admin > DNS Manager > Sync Logs for full details.'
            . "\n" . 'If this error persists, verify the server connection and retry the job manually.';

        $htmlBody = $this->buildAdminEmailBody('Job Permanently Failed', self::COLOR_DANGER, $fields, $intro, $outro);
        $this->sendEmail($subject, $htmlBody);
    }

    /**
     * Notify client when their DNS record is successfully changed.
     * Called from QueueWorker::completeJob() after ADD/EDIT/DELETE_RECORD completes.
     */
    public function notifyClientRecordChanged(
        $clientId,
        $domain,
        $action,
        $recordType,
        $recordName,
        $recordValue
    ) {
        if (!function_exists('localAPI') || (int) $clientId <= 0) {
            return;
        }

        $actionLabel = array(
            'ADD_RECORD'    => 'created',
            'EDIT_RECORD'   => 'updated',
            'DELETE_RECORD' => 'deleted',
        );
        $label = isset($actionLabel[$action]) ? $actionLabel[$action] : 'changed';

        $color = self::COLOR_DANGER;

        $subject = '[DNS] ' . strtoupper($recordType) . ' record ' . $label . ' — ' . $domain;

        $fields = array(
            'Domain' => $domain,
            'Type'   => $recordType,
            'Name'   => $recordName,
            'Value'  => $recordValue,
            'Action' => ucfirst($label),
            'Time'   => date('Y-m-d H:i:s T'),
        );

        $intro = 'Your DNS record has been ' . $label . ' successfully.';
        $outro = 'If you did not perform this action, please contact our support team immediately.';

        $htmlBody = $this->buildEmailBody(
            'DNS Record ' . ucfirst($label),
            $color,
            $fields,
            $intro,
            $outro
        );

        try {
            $result = localAPI('SendEmail', array(
                'id'            => (int) $clientId,
                'customtype'    => 'general',
                'customsubject' => $subject,
                'custommessage' => $htmlBody,
            ));

            if (isset($result['result']) && $result['result'] === 'success') {
                logActivity('MJ DNS Manager [Email]: Sent to client #' . $clientId . ' — ' . $subject);
            } else {
                $err = isset($result['message']) ? $result['message'] : json_encode($result);
                logActivity('MJ DNS Manager [Email]: Failed for client #' . $clientId . ' — ' . $err);
            }
        } catch (\Exception $e) {
            logActivity('MJ DNS Manager [Email]: notifyClientRecordChanged exception — ' . $e->getMessage());
        }
    }

    /**
     * Notify client when their DNS zone is successfully created.
     * Called from QueueWorker::completeJob() after CREATE_ZONE completes.
     *
     * @param int    $clientId  WHMCS tblclients.id
     * @param string $domain    Domain name
     */
    public function notifyClientZoneCreated($clientId, $domain)
    {
        if (!function_exists('localAPI') || (int) $clientId <= 0) {
            return;
        }

        $subject = '[DNS] Zone created successfully — ' . $domain;

        $fields = array(
            'Domain'    => $domain,
            'Status'    => 'Active',
            'SSL'       => 'Pending issuance',
            'Time'      => date('Y-m-d H:i:s T'),
        );

        $intro = 'Your DNS zone for ' . $domain . ' has been successfully created on our nameservers.';
        $outro = 'Your DNS records are now active. SSL certificate issuance is in progress and will be ready shortly.'
            . "\n" . 'If you have any questions, please contact our support team.';

        $htmlBody = $this->buildEmailBody(
            'DNS Zone Created',
            self::COLOR_SUCCESS,
            $fields,
            $intro,
            $outro
        );

        try {
            $result = localAPI('SendEmail', array(
                'id'            => (int) $clientId,
                'customtype'    => 'general',
                'customsubject' => $subject,
                'custommessage' => $htmlBody,
            ));

            if (isset($result['result']) && $result['result'] === 'success') {
                logActivity('MJ DNS Manager [Email]: Zone created notification sent to client #' . $clientId . ' for ' . $domain);
            } else {
                $err = isset($result['message']) ? $result['message'] : json_encode($result);
                logActivity('MJ DNS Manager [Email]: Zone created notification failed for client #' . $clientId . ' — ' . $err);
            }
        } catch (\Exception $e) {
            logActivity('MJ DNS Manager [Email]: notifyClientZoneCreated exception — ' . $e->getMessage());
        }
    }

    /**
     * Notify client when a DDNS token is created.
     * Called from DdnsService::createToken() after token saved to DB.
     *
     * @param int    $clientId  WHMCS tblclients.id
     * @param string $domain    Domain name
     * @param string $subdomain Subdomain (e.g. "home", "office")
     * @param string $label     Optional label
     */
    public function notifyClientDdnsTokenCreated($clientId, $domain, $subdomain, $label = '')
    {
        if (!function_exists('localAPI') || (int) $clientId <= 0) {
            return;
        }

        $subject = '[DNS] DDNS token created — ' . $subdomain . '.' . $domain;

        $fields = array(
            'Domain'    => $domain,
            'Subdomain' => $subdomain . '.' . $domain,
            'Label'     => !empty($label) ? $label : '(none)',
            'Time'      => date('Y-m-d H:i:s T'),
        );

        $intro = 'A new Dynamic DNS (DDNS) token has been created for your domain.';
        $outro = 'If you did not perform this action, please contact our support team immediately.';

        $htmlBody = $this->buildEmailBody(
            'DDNS Token Created',
            self::COLOR_SUCCESS,
            $fields,
            $intro,
            $outro
        );

        try {
            $result = localAPI('SendEmail', array(
                'id'            => (int) $clientId,
                'customtype'    => 'general',
                'customsubject' => $subject,
                'custommessage' => $htmlBody,
            ));

            if (isset($result['result']) && $result['result'] === 'success') {
                logActivity('MJ DNS Manager [Email]: DDNS token notification sent to client #' . $clientId . ' for ' . $subdomain . '.' . $domain);
            } else {
                $err = isset($result['message']) ? $result['message'] : json_encode($result);
                logActivity('MJ DNS Manager [Email]: DDNS token notification failed for client #' . $clientId . ' — ' . $err);
            }
        } catch (\Exception $e) {
            logActivity('MJ DNS Manager [Email]: notifyClientDdnsTokenCreated exception — ' . $e->getMessage());
        }
    }

    /**
     * Notify the domain owner (client) when DNS drift is detected.
     * Called from DriftChecker::scanOneDomain().
     */
    public function notifyDriftDetected($clientId, $domain, array $drifts)
    {
        if (!function_exists('localAPI') || (int) $clientId <= 0 || empty($drifts)) {
            return;
        }

        $count   = count($drifts);
        $typeMap = array(
            'ADDED_ON_DA'   => 'Added directly on server',
            'REMOVED_ON_DA' => 'Removed from server',
            'VALUE_CHANGED' => 'Value mismatch',
        );

        $detailLines = array();
        foreach ($drifts as $i => $d) {
            $typeLabel     = isset($typeMap[$d['drift_type']]) ? $typeMap[$d['drift_type']] : $d['drift_type'];
            $detailLines[] = ($i + 1) . '. [' . $typeLabel . '] ' . $d['record_type'] . ' — ' . $d['record_name'];
        }

        $fields = array(
            'Domain'       => $domain,
            'Issues found' => $count . ' discrepancy(s)',
            'Details'      => implode("\n", $detailLines),
            'Detected at'  => date('Y-m-d H:i:s T'),
        );

        $intro = 'We detected ' . $count . ' DNS discrepancy(s) for your domain. No immediate action is required on your end.';
        $outro = 'Our technical team will review and resolve the discrepancies.'
            . "\n" . 'If you have any questions, please contact our support team.';

        $subject  = '[DNS] ' . $count . ' discrepancy(s) detected for ' . $domain;
        $htmlBody = $this->buildEmailBody('DNS Drift Detected', self::COLOR_WARNING, $fields, $intro, $outro);

        try {
            $result = localAPI('SendEmail', array(
                'id'            => (int) $clientId,
                'customtype'    => 'general',
                'customsubject' => $subject,
                'custommessage' => $htmlBody,
            ));

            if (isset($result['result']) && $result['result'] === 'success') {
                logActivity('MJ DNS Manager [Email]: Drift alert sent to client #' . $clientId . ' for \'' . $domain . '\'.');
            } else {
                $err = isset($result['message']) ? $result['message'] : json_encode($result);
                logActivity('MJ DNS Manager [Email]: Drift alert failed for \'' . $domain . '\' — ' . $err);
            }
        } catch (\Exception $e) {
            logActivity('MJ DNS Manager [Email]: notifyDriftDetected exception — ' . $e->getMessage());
        }
    }

    /**
     * Notify admin when an SSL certificate fails to issue.
     * Called from SslChecker::syncSslStatus().
     */
    public function notifySslFailed($domainName)
    {
        $telegramOn = SettingsHelper::getBool('enable_telegram_alert', false);
        $emailOn    = SettingsHelper::getBool('enable_email_alert', false);

        if (!$telegramOn && !$emailOn) {
            return;
        }

        if ($telegramOn) {
            $this->sendTelegram(
                "\xE2\x9A\xA0\xEF\xB8\x8F *SSL Certificate Failed*\n" .
                    "*Domain:* " . $domainName . "\n" .
                    "*Reason:* Certificate was not issued and is no longer in DA retry queue\n" .
                    "*Next step:* Check DNS propagation or SSL config on DA server\n" .
                    "*Time:* " . date('Y-m-d H:i:s T')
            );
        }

        if ($emailOn) {
            $fields = array(
                'Domain'    => $domainName,
                'Reason'    => 'Certificate was not issued and is no longer in the DA retry queue',
                'Next step' => 'Check DNS propagation or SSL configuration on the DA server',
                'Time'      => date('Y-m-d H:i:s T'),
            );

            $intro = 'The SSL certificate for the following domain has failed to issue.';
            $outro = 'Please review the domain\'s DNS propagation status and SSL configuration on the DirectAdmin server.';

            $htmlBody = $this->buildAdminEmailBody('SSL Certificate Failed', self::COLOR_DANGER, $fields, $intro, $outro);
            $this->sendEmail('[MJ DNS] SSL certificate failed — ' . $domainName, $htmlBody);
        }
    }

    // ─────────────────────────────────────────────────────────────────────
    // Test — gọi từ Admin UI nút "Test Connection"
    // Telegram: dùng /getMe — KHÔNG gửi tin nhắn
    // Email: gửi HTML test email
    // ─────────────────────────────────────────────────────────────────────

    public function sendTest()
    {
        $results = [];

        if (SettingsHelper::getBool('enable_telegram_alert', false)) {
            $res = $this->testTelegramToken();
            $results['telegram'] = $res['success'];
            if (!$res['success']) {
                $results['telegram_error'] = $res['error'];
            } else {
                $results['bot_name'] = $res['bot_name'];
                $results['bot_username'] = $res['bot_username'];
            }
        }

        if (SettingsHelper::getBool('enable_email_alert', false)) {
            $fields = array(
                'Status' => 'Connection successful!',
                'Module' => 'MJ DNS Manager',
                'Time'   => date('Y-m-d H:i:s T'),
            );
            $intro    = 'This is a test notification to confirm that email alerts are working correctly.';
            $htmlBody = $this->buildAdminEmailBody('Test Notification', self::COLOR_SUCCESS, $fields, $intro);
            $results['email'] = (bool) $this->sendEmail('[MJ DNS] Test notification', $htmlBody);
        }

        return $results;
    }

    // ─────────────────────────────────────────────────────────────────────
    // Helpers — Build messages
    // ─────────────────────────────────────────────────────────────────────

    /**
     * Build nội dung Telegram (plain text với Markdown).
     */
    private function buildTelegramMessage($title, array $fields)
    {
        $lines = [];
        $lines[] = '*' . $title . '*';
        $lines[] = '';
        foreach ($fields as $label => $value) {
            $lines[] = '*' . $label . ':* ' . $value;
        }
        $lines[] = '*Time:* ' . date('Y-m-d H:i:s');
        return implode("\n", $lines);
    }

    /**
     * Build HTML email body with colored header, key-value table, optional intro/outro.
     *
     * @param string      $title   Header title
     * @param string      $color   Header background color (#hex)
     * @param array       $fields  Key => value data rows
     * @param string|null $intro   Optional intro paragraph above the table
     * @param string|null $outro   Optional closing paragraph below the table
     * @return string HTML
     */
    private function buildEmailBody($title, $color, array $fields, $intro = null, $outro = null)
    {
        $rows = '';
        foreach ($fields as $label => $value) {
            $rows .= '<tr>'
                . '<td style="color:#555;width:36%;padding:9px 14px;border-bottom:1px solid #eee;vertical-align:top;font-size:13px;white-space:nowrap;font-weight:600;">'
                . htmlspecialchars((string) $label)
                . '</td>'
                . '<td style="color:#222;padding:9px 14px;border-bottom:1px solid #eee;vertical-align:top;font-size:13px;word-break:break-word;">'
                . nl2br(htmlspecialchars((string) $value))
                . '</td>'
                . '</tr>';
        }

        $introHtml = '';
        if (!empty($intro)) {
            $introHtml = '<p style="margin:0 0 16px;font-size:13px;color:#444;line-height:1.6;">'
                . nl2br(htmlspecialchars($intro))
                . '</p>';
        }

        $outroHtml = '';
        if (!empty($outro)) {
            $outroHtml = '<p style="margin:16px 0 0;font-size:13px;color:#444;line-height:1.6;">'
                . nl2br(htmlspecialchars($outro))
                . '</p>';
        }

        $time = date('d/m/Y H:i:s');

        return '<div style="font-family:Arial,Helvetica,sans-serif;max-width:600px;background:#fff;border:1px solid #ddd;border-radius:4px;overflow:hidden;">'
            . '<div style="background:' . $color . ';padding:18px 20px;">'
            . '<p style="margin:0;font-size:17px;font-weight:bold;color:#fff;">' . htmlspecialchars($title) . '</p>'
            . '<p style="margin:4px 0 0;font-size:11px;color:rgba(255,255,255,0.75);">MJ DNS Manager &mdash; Notification</p>'
            . '</div>'
            . '<div style="padding:18px 20px;">'
            . $introHtml
            . '<table width="100%" cellpadding="0" cellspacing="0" style="border-collapse:collapse;border:1px solid #e8e8e8;border-radius:3px;">'
            . $rows
            . '</table>'
            . $outroHtml
            . '</div>'
            . '<div style="background:#f7f7f7;padding:10px 20px;border-top:1px solid #eee;">'
            . '<p style="margin:0;font-size:11px;color:#999;">Sent at <strong>' . $time . '</strong> &mdash; MJ DNS Manager</p>'
            . '</div>'
            . '</div>';
    }

    /**
     * Build HTML email body cho admin alerts — wrap vào MJ email template.
     * Dùng cho: notifyJobPermanentlyFailed, notifySslFailed, RULE_01/02/03.
     * KHÔNG dùng cho client emails (notifyClientRecordChanged, notifyDriftDetected)
     * vì những email đó đã được WHMCS wrap template tự động qua localAPI.
     *
     * @param string      $title
     * @param string      $color
     * @param array       $fields
     * @param string|null $intro
     * @param string|null $outro
     * @return string Full HTML email với HVN template
     */
    private function buildAdminEmailBody($title, $color, array $fields, $intro = null, $outro = null)
    {
        $innerHtml = $this->buildEmailBody($title, $color, $fields, $intro, $outro);
        return \MJ\DnsManager\Mail\EmailTemplate::wrap($innerHtml, $title);
    }

    // ─────────────────────────────────────────────────────────────────────
    // Helpers — Cooldown
    // ─────────────────────────────────────────────────────────────────────

    private function passCooldown($ruleId, $target)
    {
        $cooldownSeconds = SettingsHelper::getInt('alert_cooldown', 900);

        try {
            $row = Capsule::table('tbl_mj_dns_notification_cooldowns')
                ->where('rule_id', $ruleId)
                ->where('target_id', $target)
                ->first();

            if (!$row) {
                return true;
            }

            return (time() - strtotime((string) $row->last_sent_at)) >= $cooldownSeconds;
        } catch (\Throwable $e) {
            return true;
        }
    }

    private function recordCooldown($ruleId, $target)
    {
        try {
            $now = date('Y-m-d H:i:s');
            $exists = Capsule::table('tbl_mj_dns_notification_cooldowns')
                ->where('rule_id', $ruleId)
                ->where('target_id', $target)
                ->exists();

            if ($exists) {
                Capsule::table('tbl_mj_dns_notification_cooldowns')
                    ->where('rule_id', $ruleId)
                    ->where('target_id', $target)
                    ->update(['last_sent_at' => $now]);
            } else {
                Capsule::table('tbl_mj_dns_notification_cooldowns')->insert([
                    'rule_id' => $ruleId,
                    'target_id' => $target,
                    'last_sent_at' => $now,
                ]);
            }
        } catch (\Throwable $e) {
            // Silent
        }
    }

    // ─────────────────────────────────────────────────────────────────────
    // Helpers — Decrypt / Connection check
    // ─────────────────────────────────────────────────────────────────────

    private function decryptToken($encoded)
    {
        if (empty($encoded)) {
            return '';
        }

        // Bước 1: WHMCS Encryption
        if (class_exists('\WHMCS\Security\Encryption')) {
            try {
                $decoded = \WHMCS\Security\Encryption::decode($encoded);
                if (!empty($decoded) && strpos($decoded, ':') !== false) {
                    return $decoded;
                }
            } catch (\Throwable $e) {
                // fallthrough
            }
        }

        // Bước 2: base64
        $b64 = base64_decode($encoded, true);
        if ($b64 !== false && strpos($b64, ':') !== false) {
            return $b64;
        }

        // Bước 3: plaintext
        if (strpos($encoded, ':') !== false) {
            return $encoded;
        }

        return '';
    }

    private function isConnectionError($errorMessage)
    {
        $patterns = [
            'cURL error 28',
            'cURL error 7',
            'cURL error 6',
            'connection_failed',
            'Cannot connect',
            'Failed to connect',
            'Connection timed out',
            'timed out',
            'unreachable',
        ];

        foreach ($patterns as $p) {
            if (stripos($errorMessage, $p) !== false) {
                return true;
            }
        }

        return false;
    }
}
