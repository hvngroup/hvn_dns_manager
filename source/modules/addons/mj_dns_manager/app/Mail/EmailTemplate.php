<?php

namespace MJ\DnsManager\Mail;

defined("WHMCS") or die("Access Denied");

/**
 * EmailTemplate — HTML wrapper cho tất cả email gửi từ MJ DNS Manager.
 *
 * Áp dụng đúng template HVN Group: header ảnh, content, footer social + địa chỉ.
 * Dùng cho cả admin alert (failed job, SSL, unreachable) và client notification.
 */
class EmailTemplate
{
    /**
     * Wrap nội dung HTML vào full email template của HVN Group.
     *
     * @param string $contentHtml  Nội dung chính (output từ buildEmailBody())
     * @param string $preheader    Text ẩn hiển thị trong preview email (tùy chọn)
     * @return string              Full HTML email
     */
    public static function wrap($contentHtml, $preheader = '')
    {
        if (empty($preheader)) {
            $preheader = 'Notification from MJ DNS Manager';
        }

        $preheaderEscaped = htmlspecialchars($preheader);

        return '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" lang="en" xml:lang="en" style="background:#f6f7f8!important">
<head>
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8">
    <meta name="viewport" content="width=device-width">
    <style type="text/css">
        @media (prefers-color-scheme: dark) {
            body { background-color: white; color: black; }
        }
        @media only screen and (max-width: 628px) {
            .container-radius {
                border-spacing: 0 !important;
                padding-left: 16px !important;
                padding-right: 16px !important;
                padding-top: 16px !important;
            }
        }
    </style>
</head>
<body style="-moz-box-sizing:border-box;-ms-text-size-adjust:100%;-webkit-box-sizing:border-box;-webkit-text-size-adjust:100%;Margin:0;box-sizing:border-box;color:#0a0a0a;font-family:Roboto,sans-serif;font-size:16px;font-weight:400;line-height:1.3;margin:0;min-width:100%;padding:0;text-align:left;width:100%!important">

    <span class="preheader" style="color:#fff;display:none!important;font-size:1px;line-height:1px;max-height:0;max-width:0;mso-hide:all!important;opacity:0;overflow:hidden;visibility:hidden">'
            . $preheaderEscaped
            . '</span>

    <table width="100%" style="background-color:#f7f7f7" bgcolor="#f7f7f7">
        <tbody>
            <tr>
                <td></td>
                <td width="600">
                    <table class="body" style="Margin:0;background-color:#f6f7f8;border-collapse:collapse;border-color:transparent;border-spacing:0;color:#0a0a0a;font-family:Roboto,sans-serif;font-size:16px;font-weight:400;height:100%;line-height:1.3;margin:0;padding:0;text-align:left;vertical-align:top;width:100%">
                        <tr style="padding:0;text-align:left;vertical-align:top">
                            <td class="center" align="center" valign="top" style="-moz-hyphens:auto;-webkit-hyphens:auto;Margin:0;border-collapse:collapse!important;color:#0a0a0a;font-family:Roboto,sans-serif;font-size:16px;font-weight:400;hyphens:auto;line-height:1.3;margin:0;padding:0;text-align:left;vertical-align:top;word-wrap:break-word">
                                <center data-parsed="" style="min-width:600px;width:600px;margin:0 auto;">

                                    <!-- Top spacer -->
                                    <table class="spacer float-center" style="Margin:0 auto;border-collapse:collapse;border-color:transparent;border-spacing:0;float:none;margin:0 auto;padding:0;text-align:center;vertical-align:top;width:100%">
                                        <tbody>
                                            <tr style="padding:0;text-align:left;vertical-align:top">
                                                <td height="0" style="-moz-hyphens:auto;-webkit-hyphens:auto;Margin:0;border-collapse:collapse!important;color:#0a0a0a;font-family:Roboto,sans-serif;font-size:40px;font-weight:400;hyphens:auto;line-height:40px;margin:0;mso-line-height-rule:exactly;padding:0;text-align:left;vertical-align:top;word-wrap:break-word">
                                                    &#xA0;
                                                </td>
                                            </tr>
                                        </tbody>
                                    </table>

                                    <!-- Header logo -->
                                    <table align="center" width="600" class="container header" bgcolor="#ffffff"
                                        style="border-collapse:collapse;width:600px;max-width:100%;text-align:center;background-color:#ffffff;border-left:1px solid #e6e6e6;border-right:1px solid #e6e6e6;border-top:5px solid #ea4544;">
                                        <tbody>
                                            <tr>
                                                <td style="font-family:Roboto,sans-serif;font-size:16px;line-height:1.3;color:#0a0a0a;padding:0;">
                                                    <table width="100%" cellpadding="0" cellspacing="0" border="0" bgcolor="#ffffff" style="border-collapse:collapse;width:100%;max-width:100%;background-color:#ffffff;">
                                                        <thead>
                                                            <tr>
                                                                <th style="padding:0;">
                                                                    <a href="https://hvn.vn" style="display:block;">
                                                                        <img src="https://id.hvn.vn/assets/img/email_template/email_header.jpg"
                                                                            alt="Thu gui tu tap doan HVN"
                                                                            style="width:100%;display:block;border:none;"
                                                                            width="600">
                                                                    </a>
                                                                </th>
                                                            </tr>
                                                        </thead>
                                                    </table>
                                                </td>
                                            </tr>
                                        </tbody>
                                    </table>

                                    <!-- Main content -->
                                    <table border="0" cellpadding="0" cellspacing="0" width="600"
                                        style="padding:25px;background-color:#ffffff;border-left:1px solid #e6e6e6;border-right:1px solid #e6e6e6;" bgcolor="#fff">
                                        <tbody>
                                            <tr>
                                                <td valign="top">'
            . $contentHtml
            . '</td>
                                            </tr>
                                        </tbody>
                                    </table>

                                    <!-- Social footer -->
                                    <table cellpadding="0" cellspacing="0" border="0" align="center"
                                        style="Margin:0 auto;border-bottom-left-radius:0px;border-bottom-right-radius:0px;border-collapse:collapse;border-color:transparent;border-spacing:0;float:none;margin:0 auto;padding:0;text-align:center;vertical-align:top;width:600px;max-width:600px">
                                        <tbody>
                                            <tr style="padding:0;text-align:left;vertical-align:top">
                                                <td style="-moz-hyphens:auto;-webkit-hyphens:auto;Margin:0;border-collapse:collapse!important;color:#0a0a0a;font-family:Roboto,sans-serif;font-size:16px;font-weight:400;hyphens:auto;line-height:1.3;margin:0;padding:0px;text-align:left;vertical-align:top;word-wrap:break-word;width:600px;max-width:600px;">

                                                    <!-- Social icons bar -->
                                                    <table style="border-collapse:collapse;border-color:transparent;border-spacing:0;padding:0;text-align:left;vertical-align:top;width:100%;border-left:1px solid #e6e6e6;border-right:1px solid #e6e6e6;" width="600">
                                                        <tbody>
                                                            <tr>
                                                                <td>
                                                                    <table border="0" cellpadding="0" cellspacing="0" width="596" bgcolor="#EA4544" style="padding:20px;">
                                                                        <tr>
                                                                            <td style="font-size:16px;color:#FFFFFF !important;">
                                                                                <p style="color:#FFFFFF !important;">Theo d&#245;i ch&#250;ng t&#244;i t&#7841;i</p>
                                                                            </td>
                                                                            <td>
                                                                                <table border="0" cellspacing="0" cellpadding="0" style="margin-left:auto;">
                                                                                    <tr>
                                                                                        <td valign="top" style="padding:0px 0px 0px 20px">
                                                                                            <a href="https://www.facebook.com/hvngroup/" target="_blank">
                                                                                                <img width="24" height="24" src="https://id.hvn.vn/assets/img/email_template/facebook.png" alt="Facebook">
                                                                                            </a>
                                                                                        </td>
                                                                                        <td valign="top" style="padding:0px 0px 0px 20px">
                                                                                            <a href="https://www.linkedin.com/showcase/hvngroup/" target="_blank">
                                                                                                <img width="24" height="24" src="https://id.hvn.vn/assets/img/email_template/linkedin-in.png" alt="Linkedin">
                                                                                            </a>
                                                                                        </td>
                                                                                        <td valign="top" style="padding:0px 0px 0px 20px">
                                                                                            <a href="https://zalo.me/4361145264790109815/" target="_blank">
                                                                                                <img width="24" height="24" src="https://id.hvn.vn/assets/img/email_template/Zalo.png" alt="Zalo">
                                                                                            </a>
                                                                                        </td>
                                                                                        <td valign="top" style="padding:0px 0px 0px 20px">
                                                                                            <a href="https://www.youtube.com/@hvngroup" target="_blank">
                                                                                                <img width="24" height="24" src="https://id.hvn.vn/assets/img/email_template/youtube.png" alt="Youtube">
                                                                                            </a>
                                                                                        </td>
                                                                                    </tr>
                                                                                </table>
                                                                            </td>
                                                                        </tr>
                                                                    </table>
                                                                </td>
                                                            </tr>
                                                        </tbody>
                                                    </table>

                                                    <!-- Spacer -->
                                                    <table style="Margin:0 auto;border-collapse:collapse;border-color:transparent;border-spacing:0;float:none;margin:0 auto;padding:0;text-align:center;vertical-align:top;width:100%;border-left:1px solid #e6e6e6;border-right:1px solid #e6e6e6;" bgcolor="#ffffff" width="600">
                                                        <tbody>
                                                            <tr>
                                                                <td height="20px" style="Margin:0;border-collapse:collapse!important;color:#0a0a0a;font-family:Roboto,sans-serif;font-size:20px;font-weight:400;line-height:20px;margin:0;padding:0;text-align:left;vertical-align:top;word-wrap:break-word">&nbsp;</td>
                                                            </tr>
                                                        </tbody>
                                                    </table>

                                                    <!-- Sub-brand logos -->
                                                    <table style="border-collapse:collapse;border-color:transparent;border-spacing:0;padding:0;text-align:left;vertical-align:top;width:100%;border-left:1px solid #e6e6e6;border-right:1px solid #e6e6e6;" bgcolor="#ffffff" width="600">
                                                        <tbody>
                                                            <tr>
                                                                <th style="Margin:0 auto;color:#0a0a0a;width:10px;display:inline-block;font-family:Roboto,sans-serif;font-size:38px;font-weight:400;line-height:1.3;margin:0;padding:0!important" width="25px"></th>
                                                                <th style="Margin:0 auto;color:#0a0a0a;float:none;font-family:Roboto,sans-serif;font-size:14px;font-weight:400;line-height:1.3;margin:0 auto;padding:4px 0!important;text-align:center">
                                                                    <a href="https://hvn.plus/" style="Margin:0;color:#0057ff;font-family:Roboto,sans-serif;font-weight:400;line-height:1.3;margin:0;padding:0;text-align:left;text-decoration:none" target="_blank">
                                                                        <img width="119" src="https://id.hvn.vn/assets/img/email_template/HVN_Plus.jpg" alt="HVN Plus" style="clear:both;display:inline-block;width:119px;height:auto;outline:0;text-decoration:none;max-height:49px;vertical-align:middle;">
                                                                    </a>
                                                                </th>
                                                                <th style="Margin:0 auto;color:#0a0a0a;width:24px;display:inline-block;font-size:38px;font-weight:400;line-height:1.3;margin:0;padding:0!important" width="24px"></th>
                                                                <th style="Margin:0 auto;color:#0a0a0a;float:none;font-family:Roboto,sans-serif;font-size:14px;font-weight:400;line-height:1.3;margin:0 auto;padding:4px 0!important;text-align:center">
                                                                    <a href="https://hvn.ac/" style="Margin:0;color:#0057ff;font-family:Roboto,sans-serif;font-weight:400;line-height:1.3;margin:0;padding:0;text-align:left;text-decoration:none" target="_blank">
                                                                        <img width="119" src="https://id.hvn.vn/assets/img/email_template/HVN_Affiliate.jpg" alt="HVN Affiliate" style="clear:both;display:inline-block;width:119px;height:auto;outline:0;text-decoration:none;max-height:49px;vertical-align:middle;">
                                                                    </a>
                                                                </th>
                                                                <th style="Margin:0 auto;color:#0a0a0a;width:24px;display:inline-block;font-size:38px;font-weight:400;line-height:1.3;margin:0;padding:0!important" width="24px"></th>
                                                                <th style="Margin:0 auto;color:#0a0a0a;float:none;font-family:Roboto,sans-serif;font-size:14px;font-weight:400;line-height:1.3;margin:0 auto;padding:4px 0!important;text-align:center">
                                                                    <a href="https://hvn.biz/" style="Margin:0;color:#0057ff;font-family:Roboto,sans-serif;font-weight:400;line-height:1.3;margin:0;padding:0;text-align:left;text-decoration:none" target="_blank">
                                                                        <img width="119" src="https://id.hvn.vn/assets/img/email_template/HVN_Reseller.jpg" alt="HVN Reseller" style="clear:both;display:inline-block;width:119px;height:auto;outline:0;text-decoration:none;max-height:49px;vertical-align:middle;">
                                                                    </a>
                                                                </th>
                                                                <th style="Margin:0 auto;color:#0a0a0a;width:24px;display:inline-block;font-size:38px;font-weight:400;line-height:1.3;margin:0;padding:0!important" width="24px"></th>
                                                                <th style="Margin:0 auto;color:#0a0a0a;float:none;font-family:Roboto,sans-serif;font-size:14px;font-weight:400;line-height:1.3;margin:0 auto;padding:4px 0!important;text-align:center">
                                                                    <a href="https://hvn.foundation/" style="Margin:0;color:#0057ff;font-family:Roboto,sans-serif;font-weight:400;line-height:1.3;margin:0;padding:0;text-align:left;text-decoration:none" target="_blank">
                                                                        <img width="119" src="https://id.hvn.vn/assets/img/email_template/HVN_Foundation.jpg" alt="HVN Foundation" style="clear:both;display:inline-block;width:119px;height:auto;outline:0;text-decoration:none;max-height:49px;vertical-align:middle;">
                                                                    </a>
                                                                </th>
                                                                <th style="Margin:0 auto;color:#0a0a0a;width:10px;display:inline-block;font-size:38px;font-weight:400;line-height:1.3;margin:0;padding:0!important" width="25px"></th>
                                                            </tr>
                                                        </tbody>
                                                    </table>

                                                    <!-- Spacer -->
                                                    <table style="border-collapse:collapse;border-color:transparent;border-spacing:0;padding:0;text-align:left;vertical-align:top;width:600px;max-width:600px;border-left:1px solid #e6e6e6;border-right:1px solid #e6e6e6;" bgcolor="#ffffff">
                                                        <tbody>
                                                            <tr>
                                                                <td height="20px" style="Margin:0;border-collapse:collapse!important;color:#0a0a0a;font-family:Roboto,sans-serif;font-size:20px;font-weight:400;line-height:20px;margin:0;padding:0;text-align:left;vertical-align:top;word-wrap:break-word">&nbsp;</td>
                                                            </tr>
                                                        </tbody>
                                                    </table>

                                                    <!-- Company info -->
                                                    <table border="0" cellpadding="0" cellspacing="0" width="600" align="center" bgcolor="#ffffff"
                                                        style="border-collapse:collapse;border-color:transparent;border-spacing:0;margin:0 auto;padding:0;text-align:center;vertical-align:top;width:600px;border-left:1px solid #e6e6e6;border-right:1px solid #e6e6e6;">
                                                        <tbody>
                                                            <tr>
                                                                <td><strong style="font-size:14px;line-height:22px;color:#333333">C&#212;NG TY C&#7892; PH&#7846;N T&#7852;P &#272;O&#192;N HVN</strong></td>
                                                            </tr>
                                                            <tr>
                                                                <td><span style="font-size:12px;line-height:18px;color:#575757">&#272;&#7883;a ch&#7881;: L&#244; TT02-15, K&#272;T Mon City, Nam T&#7915; Li&#234;m, H&#224; N&#7897;i</span></td>
                                                            </tr>
                                                            <tr>
                                                                <td>
                                                                    <table border="0" cellpadding="0" cellspacing="0" width="100%" align="center" style="padding:5px 0px 0px 0px;">
                                                                        <tbody valign="middle" align="center">
                                                                            <tr valign="middle">
                                                                                <td style="text-align:center;">
                                                                                    <img width="14" src="https://id.hvn.vn/assets/img/email_template/call.png" alt="" style="clear:both;display:inline-block;max-width:14px;width:auto;height:auto;outline:0;text-decoration:none;max-height:49px;vertical-align:middle;">
                                                                                    <a href="tel:02499997777" style="font-size:12px;line-height:14px;color:#575757;text-decoration:none"><strong>Hotline:</strong> 024.9999.7777</a>
                                                                                </td>
                                                                                <td style="text-align:center;">
                                                                                    <img width="14" src="https://id.hvn.vn/assets/img/email_template/mail.png" alt="" style="clear:both;display:inline-block;max-width:14px;width:auto;height:auto;outline:0;text-decoration:none;max-height:49px;vertical-align:middle;">
                                                                                    <a href="mailto:hi@hvn.vn" style="font-size:12px;line-height:14px;color:#575757;text-decoration:none"><strong>Email:</strong> hi@hvn.vn</a>
                                                                                </td>
                                                                                <td style="text-align:center;">
                                                                                    <img width="14" src="https://id.hvn.vn/assets/img/email_template/world.png" alt="" style="clear:both;display:inline-block;max-width:14px;width:auto;height:auto;outline:0;text-decoration:none;max-height:49px;vertical-align:middle;">
                                                                                    <a href="https://hvn.vn/" style="font-size:12px;line-height:14px;color:#575757;text-decoration:none"><strong>Website:</strong> https://hvn.vn</a>
                                                                                </td>
                                                                            </tr>
                                                                        </tbody>
                                                                    </table>
                                                                </td>
                                                            </tr>
                                                            <tr>
                                                                <td style="text-align:center;">
                                                                    <table border="0" cellpadding="0" cellspacing="0" width="100%" style="padding:20px;">
                                                                        <tbody valign="middle" align="center">
                                                                            <tr>
                                                                                <td style="text-align:center;">
                                                                                    <span style="font-size:12px;line-height:18px;color:#575757;display:block;max-width:516px;margin-left:auto;margin-right:auto;text-align:center;">Qu&#253; kh&#225;ch nh&#7853;n &#273;&#432;&#7907;c th&#432; &#273;i&#7879;n t&#7917; n&#224;y b&#7903;i v&#236; Qu&#253; kh&#225;ch &#273;&#227; ch&#7845;p thu&#7853;n cho C&#244;ng ty c&#7893; ph&#7847;n T&#7853;p &#273;o&#224;n HVN g&#7917;i &#273;&#7871;n cho Qu&#253; kh&#225;ch th&#244;ng tin v&#224; ch&#432;&#417;ng tr&#236;nh khuy&#7871;n m&#227;i li&#234;n quan &#273;&#7871;n s&#7843;n ph&#7849;m v&#224; d&#7883;ch v&#7909; c&#7911;a HVN. Qu&#253; kh&#225;ch c&#243; th&#7875; l&#7921;a ch&#7885;n <a style="color:#0057ff" href="https://id.hvn.vn/index.php?rp=/account/contacts">C&#7853;p nh&#7853;t th&#244;ng tin t&#7841;i &#273;&#226;y</a></span>
                                                                                </td>
                                                                            </tr>
                                                                        </tbody>
                                                                    </table>
                                                                </td>
                                                            </tr>
                                                        </tbody>
                                                    </table>

                                                    <!-- Divider -->
                                                    <table width="600" bgcolor="#ffffff" style="Margin:0 auto;border-collapse:collapse;border-color:transparent;border-spacing:0;float:none;margin:0 auto;padding:0;text-align:center;vertical-align:top;width:100%;border-left:1px solid #e6e6e6;border-right:1px solid #e6e6e6;">
                                                        <tbody>
                                                            <tr>
                                                                <td height="5px" style="Margin:0;border-collapse:collapse!important;color:#cacaca;font-family:Roboto,sans-serif;font-size:20px;font-weight:400;line-height:5px;margin:0;padding:0;text-align:left;vertical-align:top;word-wrap:break-word">
                                                                    <hr style="background-color:#e0cccc;height:1px;border:0;">&nbsp;
                                                                </td>
                                                            </tr>
                                                        </tbody>
                                                    </table>

                                                    <!-- Footer image -->
                                                    <table width="600" align="center" style="Margin:0 auto;background:#ffffff;border-collapse:collapse;border-color:transparent;border-spacing:0;float:none;margin:0 auto;padding:0;text-align:center;vertical-align:top;width:600px;max-width:600px;border-left:1px solid #e6e6e6;border-right:1px solid #e6e6e6;">
                                                        <tbody>
                                                            <tr>
                                                                <td style="-moz-hyphens:auto;-webkit-hyphens:auto;Margin:0;border-collapse:collapse!important;color:#0a0a0a;font-family:Roboto,sans-serif;font-size:16px;font-weight:400;hyphens:auto;line-height:1.3;margin:0;padding:0;text-align:left;vertical-align:top;word-wrap:break-word;">
                                                                    <table width="100%" cellpadding="0" cellspacing="0" border="0" style="margin:0;padding:0;border-collapse:collapse;border-spacing:0;text-align:left;max-width:100%;">
                                                                        <thead>
                                                                            <tr>
                                                                                <th style="text-align:left;margin:0;padding:0;width:100%;max-width:100%;">
                                                                                    <a href="https://hvn.vn">
                                                                                        <img src="https://id.hvn.vn/assets/img/email_template/footer-email.gif" alt="Thu gui tu tap doan HVN" style="width:598px;" width="598">
                                                                                    </a>
                                                                                </th>
                                                                            </tr>
                                                                        </thead>
                                                                    </table>
                                                                </td>
                                                            </tr>
                                                        </tbody>
                                                    </table>

                                                    <!-- Bottom spacer -->
                                                    <table width="600" bgcolor="#ffffff" style="Margin:0 auto;border-collapse:collapse;border-color:transparent;border-spacing:0;float:none;margin:0 auto;padding:0;text-align:center;vertical-align:top;width:100%;border-left:1px solid #e6e6e6;border-right:1px solid #e6e6e6;">
                                                        <tbody>
                                                            <tr>
                                                                <td height="20px" style="Margin:0;border-collapse:collapse!important;color:#0a0a0a;font-family:Roboto,sans-serif;font-size:20px;font-weight:400;line-height:20px;margin:0;padding:0;text-align:left;vertical-align:top;word-wrap:break-word">&nbsp;</td>
                                                            </tr>
                                                        </tbody>
                                                    </table>

                                                    <!-- Final spacer -->
                                                    <table class="spacer float-center" style="Margin:0 auto;border-collapse:collapse;border-color:transparent;border-spacing:0;float:none;margin:0 auto;padding:0;text-align:center;vertical-align:top;width:100%;">
                                                        <tbody>
                                                            <tr>
                                                                <td height="0" style="-moz-hyphens:auto;-webkit-hyphens:auto;Margin:0;border-collapse:collapse!important;color:#0a0a0a;font-family:Roboto,sans-serif;font-size:40px;font-weight:400;hyphens:auto;line-height:40px;margin:0;mso-line-height-rule:exactly;padding:0;text-align:left;vertical-align:top;word-wrap:break-word">&#xA0;</td>
                                                            </tr>
                                                        </tbody>
                                                    </table>

                                                </td>
                                            </tr>
                                        </tbody>
                                    </table>

                                </center>
                            </td>
                        </tr>
                    </table>
                </td>
                <td></td>
            </tr>
        </tbody>
    </table>
</body>
</html>';
    }
}
