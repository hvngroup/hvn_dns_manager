<?php
//DNS Suite - Generic
$_ADDONLANG["dnssuitePage_dns_pagetitle"] = 'DNS Management Console';
$_ADDONLANG["dnssuitePage_breadcrumb_dnssuite"] = 'DNS Suite';
$_ADDONLANG["dnssuitePage_breadcrumb_dnsmanagement"] = 'Domain Functions Management';
$_ADDONLANG["dnssuitePage_breadcrumb_urlforwarding"] = 'URL Forwarding';
$_ADDONLANG["dnssuitePage_breadcrumb_subdomainforwarding"] = 'Subdomain Forwarding';
$_ADDONLANG["dnssuitePage_breadcrumb_emailforwarding"] = 'Email Forwarding';
$_ADDONLANG["dnssuitePage_breadcrumb_catchallforwarding"] = 'Catch-all Forwarding';

$_ADDONLANG["dnssuite_menuitem_name"] = "DNS Manager";
$_ADDONLANG["dnssuite_sidemenuitem_name"] = "Manage DNS Record, Forwarding & Redirect";

//Index page
$_ADDONLANG["dnssuitePage_index_nodomain"] = "Sorry, you don't have any domains with us!";
$_ADDONLANG["dnssuitePage_index_searchplaceholder"] = 'Select your domain';
$_ADDONLANG["dnssuitePage_index_edit"] = 'Modify Domain';
$_ADDONLANG["dnssuitePage_index_intro"] = 'Please note that you will only be able to manage a domain that is in Active state. Expired or cancelled domain(s) will not show up on this list.';

//No Access Page
$_ADDONLANG["dnssuitePage_noaccess_title"] = "Access Denied";
$_ADDONLANG["dnssuitePage_noaccess_explain"] = "Unfortunately, your account do not have permission to Manage Domains. Please contact the account holder to grant you Manage Domain permission for your sub-account";

//DNS Suite - Manage Page
$_ADDONLANG["dnssuitePage_manage_pagetitle"] = 'Domain DNS Management';
$_ADDONLANG["dnssuitePage_manage_title"] = "Management for:";
$_ADDONLANG["dnssuitePage_manage_overview"] = "Overview";
$_ADDONLANG["dnssuitePage_manage_domainstatus"] = "Domain Status";
$_ADDONLANG["dnssuitePage_manage_redirect"] = "Web Redirect";
$_ADDONLANG["dnssuitePage_manage_emailforward"] = "Email Forwarding";
$_ADDONLANG["dnssuitePage_manage_catchall"] = "Email Catch-all";
$_ADDONLANG["dnssuitePage_manage_notification"] = "Notification";
$_ADDONLANG["dnssuitePage_manage_notification_settings"] = "Notification Settings";

$_ADDONLANG["dnssuitePage_manage_overview_nsfailed_explain"] = "The Nameservers set for the domain is currently not the ones required for the domain services to work. Press the Switch Nameservers button below to switch your nameserver";
$_ADDONLANG["dnssuitePage_manage_overview_nsfailed_explain2"] = "By switching away from your current nameservers, you may lose web and email functions for your domain. If you are unsure please contact support.";
$_ADDONLANG["dnssuitePage_manage_overview_switchns"] = "Switch Nameservers";
$_ADDONLANG["dnssuitePage_manage_overview_switchns_success"] = "Successfully updated the nameservers for your domain. Please allow a few hours for DNS propagation";
$_ADDONLANG["dnssuitePage_manage_overview_switchns_failed"] = "Failed to switch nameservers for your domain, please contact support";
$_ADDONLANG["dnssuitePage_manage_overview_resetdomain_explain"] = "You can reset your domain's DNS, web redirect, email forwarding and catch-all back to the original status by using the button below";
$_ADDONLANG["dnssuitePage_manage_overview_resetdomain"] = "Reset Domain";
$_ADDONLANG["dnssuitePage_manage_overview_resetdomain_success"] = "Successfully reset your domain to default state.";
$_ADDONLANG["dnssuitePage_manage_overview_resetdomain_failed"] = "Failed to reset your domain, please contact support";
$_ADDONLANG["dnssuitePage_manage_overview_cleardns_explain"] = "You can clear your domain's DNS records using the button below";
$_ADDONLANG["dnssuitePage_manage_overview_cleardns"] = "Clear DNS";
$_ADDONLANG["dnssuitePage_manage_overview_cleardns_success"] = "Successfully cleared your domain's DNS records.";
$_ADDONLANG["dnssuitePage_manage_overview_cleardns_failed"] = "Failed to clear your domain's DNS records, please contact support";

$_ADDONLANG["dnssuitePage_manage_notification_explain"] = "Enable email notification upon changes of the following of this domain";
$_ADDONLANG["dnssuitePage_manage_notification_dns"] = "DNS Update";
$_ADDONLANG["dnssuitePage_manage_notification_emailforwarding"] = "Email Forwarding Update";
$_ADDONLANG["dnssuitePage_manage_notification_emailcatchall"] = "Email Catchall Update";
$_ADDONLANG["dnssuitePage_manage_notification_webredirect"] = "Web Redirect";
$_ADDONLANG["dnssuitePage_manage_notification_ddns"] = "DDNS Update";
$_ADDONLANG["dnssuitePage_manage_notification_update"] = "Update Notification";
$_ADDONLANG["dnssuitePage_manage_notification_update_success"] = "Successfully updated notification settings";
$_ADDONLANG["dnssuitePage_manage_notification_update_failed"] = "Failed to update Notification settings, please contact support";

$_ADDONLANG["dnssuitePage_manage_dnstemplate"] = "DNS Templates";
$_ADDONLANG["dnssuitePage_manage_dnstemplatename"] = "DNS Template Name";
$_ADDONLANG["dnssuitePage_manage_loadtemplate"] = "Load Template";
$_ADDONLANG["dnssuitePage_manage_savetemplate"] = "Save Template";
$_ADDONLANG["dnssuitePage_manage_deletetemplate"] = "Delete Template";
$_ADDONLANG["dnssuitePage_manage_savetemplate_explain"] = "The template name must be alpha-numeric. Space is not allowed";
$_ADDONLANG["dnssuitePage_manage_savetemplate_preservedns"] = "Preserve my current DNS records";
$_ADDONLANG["dnssuitePage_manage_savetemplate_failed"] = "Saving of DNS template failed.";
$_ADDONLANG["dnssuitePage_manage_savetemplate_duplicate"] = "Duplicate DNS Template name. Please try another name";
$_ADDONLANG["dnssuitePage_manage_savetemplate_success"] = "New template successfully added";
$_ADDONLANG["dnssuitePage_manage_deletetemplate_notowned"] = "Not able to delete the template because you don't own it";
$_ADDONLANG["dnssuitePage_manage_deletetemplate_failed"] = "Not able to delete the template, please contact support";
$_ADDONLANG["dnssuitePage_manage_deletetemplate_success"] = "Your DNS template successfully deleted.";
$_ADDONLANG["dnssuitePage_manage_loadtemplateplaceholder"] = 'Select your template';
$_ADDONLANG["dnssuitePage_manage_dnstemplate_explain"] = "Using the templates below you can easily load up some of the common 3rd party settings onto your domain such as Gmail, Outlook, etc...";
$_ADDONLANG["dnssuitePage_manage_creatednstemplate_explain"] = "You can create a template of your current DNS record and use it among your domains";
$_ADDONLANG["dnssuitePage_manage_restoretemplate_success"] = "Successfully loaded the template onto your Domain.";
$_ADDONLANG["dnssuitePage_manage_restoretemplate_failed"] = "Unable to restore the DNS template, please contact support";


$_ADDONLANG["dnssuitePage_manage_dynamicdns"] = "Dynamic DNS";
$_ADDONLANG["dnssuitePage_manage_api_url"] = "API URL";
$_ADDONLANG["dnssuitePage_manage_api_keyphrase"] = "Keyphrase";
$_ADDONLANG["dnssuitePage_manage_api_pass"] = "Pass";
$_ADDONLANG["dnssuitePage_manage_api_option"] = "Options";
$_ADDONLANG["dnssuitePage_manage_api_explanation"] = "Explanation";
$_ADDONLANG["dnssuitePage_manage_api_example"] = "Example";
$_ADDONLANG["dnssuitePage_manage_api_host_explain"] = "The hostname you want to update. If you want to update a sub-domain called ftp, then set this variable as ftp. Omit this variable if you want to update the main domain";
$_ADDONLANG["dnssuitePage_manage_api_ip_explain"] = "The IP address you want to update the host to. Omit this variable if you want the API to grab the IP from the API call";
$_ADDONLANG["dnssuitePage_manage_api_ipv6_explain"] = "Set this to yes if you want to modify a AAAA record. If this is enabled, you must set the &ip variable";
$_ADDONLANG["dnssuitePage_manage_api_delete_explain"] = "Set this to 1 if you want to delete the host's record";
$_ADDONLANG["dnssuitePage_manage_api_disable"] = "Disable API";
$_ADDONLANG["dnssuitePage_manage_api_enable"] = "Enable API";
$_ADDONLANG["dnssuitePage_manage_api_refresh"] = "Refresh API Keys";
$_ADDONLANG["dnssuitePage_manage_api_refresh_success"] = "API Keys successfully refreshed";
$_ADDONLANG["dnssuitePage_manage_api_enable_success"] = "API enabled successfully";
$_ADDONLANG["dnssuitePage_manage_api_disable_success"] = "API is now disabled";

$_ADDONLANG["dnssuitePage_manage_redirectionintro"] = "Redirect your domain to either a remote domain or remote URL. Great to use with affiliate links.";
$_ADDONLANG["dnssuitePage_manage_emailintro"] = "Forward your domain email to an external email address. Save yourself time from checking multiple email accounts";
$_ADDONLANG["dnssuitePage_manage_catchallintro"] = "Catch-all allows you to capture all mis-addressed email and forward it to one destination. Catch-all can also attract lots of spam into your inbox, use it carefully.";
$_ADDONLANG["dnssuitePage_manage_addrecord"] = "Add Record";
$_ADDONLANG["dnssuitePage_manage_dnszone"] = "DNS Zone Editor";
$_ADDONLANG["dnssuitePage_manage_destination"] = "Destination";
$_ADDONLANG["dnssuitePage_manage_on"] = "On";
$_ADDONLANG["dnssuitePage_manage_off"] = "Off";
$_ADDONLANG["dnssuitePage_manage_host"] = "Host";
$_ADDONLANG["dnssuitePage_manage_delete"] = "Delete";
$_ADDONLANG["dnssuitePage_manage_disable"] = "Disable";
$_ADDONLANG["dnssuitePage_manage_destinationhost"] = "Destination Host";
$_ADDONLANG["dnssuitePage_manage_ip"] = "IP Address";
$_ADDONLANG["dnssuitePage_manage_protocol"] = "Protocol";
$_ADDONLANG["dnssuitePage_manage_priority"] = "Priority";
$_ADDONLANG["dnssuitePage_manage_port"] = "Port";
$_ADDONLANG["dnssuitePage_manage_modify"] = "Save";
$_ADDONLANG["dnssuitePage_manage_redirectfor"] = "Redirection for:";
$_ADDONLANG["dnssuitePage_manage_service"] = "Service";
$_ADDONLANG["dnssuitePage_manage_source"] = "Source";
$_ADDONLANG["dnssuitePage_manage_ttl"] = "TTL";
$_ADDONLANG["dnssuitePage_manage_txtvalue"] = "TXT Value (without quotes)";
$_ADDONLANG["dnssuitePage_manage_weight"] = "Weight";
$_ADDONLANG["dnssuitePage_manage_value"] = "Value";
$_ADDONLANG["dnssuitePage_manage_update"] = "Update";
$_ADDONLANG["dnssuitePage_manage_verify"] = "Verify";


//DNS
$_ADDONLANG["dnssuitePage_manage_dns_a_footer"] = "To add a record for you domain, make sure a dot (.) is added at the end of the hostname. Eg: domain.com would be domain.com.";
$_ADDONLANG["dnssuitePage_manage_dns_a_footer2"] = "To add a record for a sub-domain, simply add the hostname. Eg: ftp.domain.com would just be ftp";
$_ADDONLANG["dnssuitePage_manage_dns_a_footer_haveredirect"] = "You currently have web direct enabled for your domain. The web redirection will not work properly if you modify the existing main domain's A record or add additional records for the main domain. It is safe for you to add sub-domain records, it will not affect the web redirection.";
$_ADDONLANG["dnssuitePage_manage_dns_a_footer_haveredirect2"] = "Your main domain's hostname is:";
$_ADDONLANG["dnssuitePage_manage_dns_cname_footer"] = "Only sub-domains can be used with CNAME records.";
$_ADDONLANG["dnssuitePage_manage_dns_cname_footer2"] = "To add a record for a sub-domain, simply add the hostname. Eg: ftp.domain.com would just be ftp";
$_ADDONLANG["dnssuitePage_manage_dns_cname_footer3"] = "The destination host can be end with or without (dot) at the end of the hostname. If you want to point the CNAME record to a external domain, you must add a (dot) to the end of the hostname. Eg, google.com. Otherwise, if you want to point to an internal subdomain, add the hostname without (dot), Eg, smtp";
$_ADDONLANG["dnssuitePage_manage_dns_txt_footer"] = "SPF and DKIM are used with TXT records. Check with your email provider for the proper syntax.";
$_ADDONLANG["dnssuitePage_manage_dns_mx_footer"] = "MX record with lowest priority will be used first";
$_ADDONLANG["dnssuitePage_manage_dns_mx_footer2"] = "0 = Highest priority";
$_ADDONLANG["dnssuitePage_manage_dns_mx_footer3"] = "The destination host can be end with or without (dot) at the end of the hostname. If you want to point the CNAME record to a external domain, you must add a (dot) to the end of the hostname. Eg, google.com. Otherwise, if you want to point to an internal subdomain, add the hostname without (dot), Eg, smtp";
$_ADDONLANG["dnssuitePage_manage_dns_mx_footer_haveforwarding"] = "You currently have email forwarding and/or catch-all for your domain setup. The email forwarding/catch-all will not work properly if you modify the existing main domain's MX record or add additional MX records for the main domain. It is safe for you to add sub-domain MX records, it will not affect the email forwarding or email catch-all";
$_ADDONLANG["dnssuitePage_manage_dns_mx_footer_haveforwarding2"] = "Your main domain's hostname is:";

$_ADDONLANG["dnssuitePage_manage_dns_srv_footer"] = "The SRV record host is in the following format. _service.protocol.host.";
$_ADDONLANG["dnssuitePage_manage_dns_srv_footer2"] = "For example to create a record for SIP service with the UDP protocol. Use the following format for the host: _sip._udp";
$_ADDONLANG["dnssuitePage_manage_dns_srv_footer3"] = "To create a SRV record for your primary domain, simply end the Host without a dot (.). For example, _sip._udp";
$_ADDONLANG["dnssuitePage_manage_dns_srv_footer4"] = "To create a SRV record for your sub domain, append the subdomain host at the end of the _service._protocol. string. For example, _sip._udp.subdomain";
$_ADDONLANG["dnssuitePage_manage_dns_ns_footer"] = "NS records are used to delegate which server is the authoirtative nameserver for your domain and it's sub domains.";
$_ADDONLANG["dnssuitePage_manage_dns_ns_footer2"] = "To delegate a record for a sub-domain, simply add the hostname. Eg: ftp.domain.com would just be ftp";
$_ADDONLANG["dnssuitePage_manage_dns_ns_footer3"] = "Don't forget to add a dot (.) at the end of the destination hostname, so it becomes ns.nameserver.com.";

$_ADDONLANG["dnssuitePage_manage_dns_addrecord_success"] = "Successfully added the DNS record to the zone";
$_ADDONLANG["dnssuitePage_manage_dns_addrecord_failed"] = "Unable to add DNS record to the zone, please contact support";
$_ADDONLANG["dnssuitePage_manage_dns_updaterecord_success"] = "Successfully updated the DNS record";
$_ADDONLANG["dnssuitePage_manage_dns_updaterecord_failed"] = "Unable to update the DNS record, please contact support";
$_ADDONLANG["dnssuitePage_manage_dns_nssamedomain"] = "Cannot add additional NS record to the main domain.";
$_ADDONLANG["dnssuitePage_manage_dns_invalidip"] = "Unable to update the DNS record, please check the IP";
$_ADDONLANG["dnssuitePage_manage_dns_invalidhostname"] = "Invalid hostname, please check and try again";
$_ADDONLANG["dnssuitePage_manage_dns_invalidhostvalue"] = "Unable to update the DNS record, please check the host and value";
$_ADDONLANG["dnssuitePage_manage_dns_invalidmxvalue"] = "Invalid MX value, please check and try again";
$_ADDONLANG["dnssuitePage_manage_dns_invalidmxpriority"] = "Invalid MX priority, please check and try again";
$_ADDONLANG["dnssuitePage_manage_dns_invalidtxtvalue"] = "Invalid TXT value, please check and try again";
$_ADDONLANG["dnssuitePage_manage_dns_invalidnsvalue"] = "Invalid NS value, please check and try again";
$_ADDONLANG["dnssuitePage_manage_dns_duplicatecname"] = "There is a duplicate CNAME record of the same hostname, please delete it first";
$_ADDONLANG["dnssuitePage_manage_dns_duplicatea"] = "There is a duplicate A record of the same hostname, please delete it first";
$_ADDONLANG["dnssuitePage_manage_a_record"] = "A Records";
$_ADDONLANG["dnssuitePage_manage_host"] = "Host";
$_ADDONLANG["dnssuitePage_manage_mx_record"] = "MX Records";
$_ADDONLANG["dnssuitePage_manage_cname_record"] = "CNAME Records";
$_ADDONLANG["dnssuitePage_manage_ns_record"] = "NS Records";
$_ADDONLANG["dnssuitePage_manage_txt_record"] = "TXT Records";
$_ADDONLANG["dnssuitePage_manage_srv_record"] = "SRV Records";
$_ADDONLANG["dnssuitePage_manage_aaaa_record"] = "AAAA Records";
$_ADDONLANG["dnssuitePage_manage_record_delete_success"] = "Record successfully deleted";
$_ADDONLANG["dnssuitePage_manage_record_delete_failed"] = "Unable to delete record, please contact support";


//Email forwarding
$_ADDONLANG["dnssuitePage_manage_addemaildestination_success"] = "Successfully added the email for forwarding, before you can use this destination you must verify the destination with the Pin that has been send to the email address. Please go back to the Email forwarding tab and confirm with the verification pin";
$_ADDONLANG["dnssuitePage_manage_addemail_failed"] = "Failed to add email to the database. Try again";
$_ADDONLANG["dnssuitePage_manage_addemail_existed"] = "Failed to add email to the database. The same email has been used already.";
$_ADDONLANG["dnssuitePage_manage_addemail_validation"] = "Failed to add email to the database. The email is not valid.";
$_ADDONLANG["dnssuitePage_manage_addemail_success"] = "Successfully added the forwarder to the database, you can now assign emails to the forwarding";
$_ADDONLANG["dnssuitePage_manage_addemail"] = "Add Email";
$_ADDONLANG["dnssuitePage_manage_addalias_existed"] = "Failed to add alias to the database. The same alias has been used already.";
$_ADDONLANG["dnssuitePage_manage_addalias_validation"] = "Failed to add alias to the database. The alias is not valid.";
$_ADDONLANG["dnssuitePage_manage_addalias"] = "Add Alias";
$_ADDONLANG["dnssuitePage_manage_addforwarding"] = "Add forwarding alias for:";
$_ADDONLANG["dnssuitePage_manage_deleteemail_success"] = "Successfully deleted email from the database.";
$_ADDONLANG["dnssuitePage_manage_deleteemail_failed"] = "Failed to delete email from the database. Please try again.";
$_ADDONLANG["dnssuitePage_manage_deleteemail_failed_inuse"] = "Failed to delete email from the database. Email address currently in use";
$_ADDONLANG["dnssuitePage_manage_verifypin_correctpin"] = "Pin validated, the email destination is now active";
$_ADDONLANG["dnssuitePage_manage_verifypin_incorrectpin"] = "Incorrect pin entered, please try again";
$_ADDONLANG["dnssuitePage_manage_verifypin_failed"] = "Unable to verify pin, please contact support";
$_ADDONLANG["dnssuitePage_manage_existingforwarding"] = "Email Forwarding:";
$_ADDONLANG["dnssuitePage_manage_existingcatchall"] = "Email Catch-all:";
$_ADDONLANG["dnssuitePage_manage_addnewforwarding"] = "Add new email forwarding for:";
$_ADDONLANG["dnssuitePage_manage_addemaildestination"] = "Add new email destination";
$_ADDONLANG["dnssuitePage_manage_forwarder_success"] = "New email forwarder successfully added";
$_ADDONLANG["dnssuitePage_manage_forwarder_failed"] = "Unable to add new forwarder, please contact support";
$_ADDONLANG["dnssuitePage_manage_forwarder_invalidemail"] = "Unable to add new forwarder, please check if the email addresses are in correct format";
$_ADDONLANG["dnssuitePage_manage_forwarder_modify_success"] = "Email forwarder successfully updated";
$_ADDONLANG["dnssuitePage_manage_forwarder_modify_invalidemail"] = "Unable to update forwarder, please check if the email addresses are in correct format";
$_ADDONLANG["dnssuitePage_manage_forwarder_modify_failed"] = "Unable to update forwarder, please contact support";
$_ADDONLANG["dnssuitePage_manage_forwarder_delete_success"] = "Email forwarder successfully deleted";
$_ADDONLANG["dnssuitePage_manage_forwarder_delete_failed"] = "Email forwarder deletion failed, please contact support";

//Redirect
$_ADDONLANG["dnssuitePage_manage_addnewredirection"] = "Add new redirection for:";
$_ADDONLANG["dnssuitePage_manage_setredirect"] = "Set redirect";
$_ADDONLANG["dnssuitePage_manage_modifyredirect"] = "Modify redirect";
$_ADDONLANG["dnssuitePage_manage_setforwarding"] = "Add forwarding";
$_ADDONLANG["dnssuitePage_manage_modifyforwarding"] = "Modify forwarding";
$_ADDONLANG["dnssuitePage_manage_emaildestination"] = "Email Destination";
$_ADDONLANG["dnssuitePage_manage_updatecatchall"] = "Update Catch-All";
$_ADDONLANG["dnssuitePage_manage_verifypin"] = "Verify Pin";
$_ADDONLANG["dnssuitePage_manage_disablecatchall"] = "Disable Catch-All";
$_ADDONLANG["dnssuitePage_manage_type"] = "Redirection Type";
$_ADDONLANG["dnssuitePage_manage_301"] = "301 - Permanent";
$_ADDONLANG["dnssuitePage_manage_302"] = "302 - Temporary";
$_ADDONLANG["dnssuitePage_manage_303"] = "303 - Replaced";
$_ADDONLANG["dnssuitePage_manage_redirect_success"] = "New web redirection successfully added";
$_ADDONLANG["dnssuitePage_manage_redirect_failed_support"] = "Unable add new web redirection, please contact support";
$_ADDONLANG["dnssuitePage_manage_redirect_failed_url"] = "Unable add new web redirection, please check your URLs";
$_ADDONLANG["dnssuitePage_manage_redirect_modify_success"] = "Web redirection successfully updated";
$_ADDONLANG["dnssuitePage_manage_redirect_modifyfailed_support"] = "Unable modify web redirection, contact support";
$_ADDONLANG["dnssuitePage_manage_redirect_modifyfailed_duplicate"] = "Unable modify web redirection, please make sure there isn't a duplicate redirect";
$_ADDONLANG["dnssuitePage_manage_redirect_modifyfailed_url"] = "Unable modify web redirection, please check your URLs";
$_ADDONLANG["dnssuitePage_manage_redirect_delete_success"] = "Web redirect successfully deleted";
$_ADDONLANG["dnssuitePage_manage_redirect_delete_failed"] = "Web redirect deletion failed, please contact support";

$_ADDONLANG["dnssuitePage_manage_catchall_status"] = "Catch-all Status";
$_ADDONLANG["dnssuitePage_manage_catchall_status_on"] = "On";
$_ADDONLANG["dnssuitePage_manage_catchall_status_off"] = "Off";
$_ADDONLANG["dnssuitePage_manage_catchall_success"] = "Catch-all successfully updated";
$_ADDONLANG["dnssuitePage_manage_catchall_failed"] = "Unable to update Catch-all email, please contact support";
$_ADDONLANG["dnssuitePage_manage_catchall_threshold"] = "You are updating your catch-all too often, please wait 5 minutes then try again";
$_ADDONLANG["dnssuitePage_manage_catchall_status_unverified"] = "Unverified";
$_ADDONLANG["dnssuitePage_manage_catchall_invalidemail"] = "Unable update catch-all, the email is in invalid format";
$_ADDONLANG["dnssuitePage_manage_catchall_disable_success"] = "Catch-all successfully disabled";
$_ADDONLANG["dnssuitePage_manage_catchall_disable_failed"] = "Unable to disable Catch-all email, please contact support";

//Javascript response
$_ADDONLANG["dnssuitePage_manage_js_error"] = "Error";
$_ADDONLANG["dnssuitePage_manage_js_resetconfirm"] = "Do you want to reset the domain?";
$_ADDONLANG["dnssuitePage_manage_js_deleteconfirm"] = "Do you want to delete the record?";
$_ADDONLANG["dnssuitePage_manage_js_deleteusertemplateconfirm"] = "Do you want to delete the template?";
$_ADDONLANG["dnssuitePage_manage_js_restorednstemplateconfirm"] = "Do you want to restore the template onto your domain?";
$_ADDONLANG["dnssuitePage_manage_js_templateinvalid"] = "The template name you are trying to use is invalid. Please try again.";
$_ADDONLANG["dnssuitePage_manage_js_a_ip_error"] = "The IP is not in valid format: ";
$_ADDONLANG["dnssuitePage_manage_js_a_ipv4_error"] = "The IP is not in valid IPv4 format: ";
$_ADDONLANG["dnssuitePage_manage_js_aaaa_ipv6_error"] = "The IP is not in valid IPv6 format: ";
$_ADDONLANG["dnssuitePage_manage_js_invalidhostname"] = "The hostname is not valid: ";
$_ADDONLANG["dnssuitePage_manage_js_invalidpriority"] = "The priority is not valid: ";
$_ADDONLANG["dnssuitePage_manage_js_fieldempty"] = "The field cannot be empty! ";
$_ADDONLANG["dnssuitePage_manage_js_hostfieldempty"] = "The host field cannot be empty! ";
$_ADDONLANG["dnssuitePage_manage_js_valuefieldempty"] = "The value field cannot be empty! ";
$_ADDONLANG["dnssuitePage_manage_js_nsnodomain"] = "Cannot add additional NS record to the main domain.";
$_ADDONLANG["dnssuitePage_manage_js_txtfieldempty"] = "The TXT value cannot be empty! ";
$_ADDONLANG["dnssuitePage_manage_js_txtfieldinvalid"] = "The TXT value is not valid. Make sure it does not contain any quotes, single or double";
$_ADDONLANG["dnssuitePage_manage_js_priorityfieldempty"] = "The priority field cannot be empty! ";
$_ADDONLANG["dnssuitePage_manage_js_portfieldempty"] = "The port field cannot be empty! ";
$_ADDONLANG["dnssuitePage_manage_js_weightfieldempty"] = "The weight field cannot be empty! ";
$_ADDONLANG["dnssuitePage_manage_js_priorityinvalid"] = "The priority field must be a integer! ";
$_ADDONLANG["dnssuitePage_manage_js_portinvalid"] = "The port field must be a integer! ";
$_ADDONLANG["dnssuitePage_manage_js_weightinvalid"] = "The weight field must be a integer! ";
$_ADDONLANG["dnssuitePage_manage_js_invalidrange"] = "The priority, weight, port field must be a number between 0 and 65535 ";
$_ADDONLANG["dnssuitePage_manage_js_valuefieldinvalid"] = "Value field invalid";
$_ADDONLANG["dnssuitePage_manage_js_ttlinvalid"] = "The TTL must be integer ";
$_ADDONLANG["dnssuitePage_manage_js_ttlrangeinvalid"] = "The TTL must be between: ";

//Notification Email
$_ADDONLANG["dnssuitePage_email_type_dns"] = "DNS";
$_ADDONLANG["dnssuitePage_email_type_emailforward"] = "Email Forwarding";
$_ADDONLANG["dnssuitePage_email_type_emailcatchall"] = "Email Catchall";
$_ADDONLANG["dnssuitePage_email_type_webredirect"] = "Web Redirect";
$_ADDONLANG["dnssuitePage_email_type_ddns"] = "DDNS";
$_ADDONLANG["dnssuitePage_email_type_dnstemplaterestore"] = "DNS Template Restore";
$_ADDONLANG["dnssuitePage_email_type_switchnameserver"] = "Switching Nameserver";
$_ADDONLANG["dnssuitePage_email_all"] = "All Domain Settings";
$_ADDONLANG["dnssuitePage_email_cleardns"] = "Clear DNS Records";
$_ADDONLANG["dnssuitePage_email_na"] = "Not Applicable";
$_ADDONLANG["dnssuitePage_email_add"] = "Add";
$_ADDONLANG["dnssuitePage_email_delete"] = "Delete";
$_ADDONLANG["dnssuitePage_email_update"] = "Update";
$_ADDONLANG["dnssuitePage_email_disable"] = "Disable";
$_ADDONLANG["dnssuitePage_email_reset"] = "Reset";
$_ADDONLANG["dnssuitePage_email_clear"] = "Clear";

//v1.1
//DNS
$_ADDONLANG["dnssuitePage_manage_dns_invaliddestinationvalue"] = "Unable to update the DNS record, please check the destination value";

//Redirect
$_ADDONLANG["dnssuitePage_manage_redirectionblank"] = "The redirection destination cannot be blank.";
$_ADDONLANG["dnssuitePage_manage_redirect_addfailed_duplicate"] = "Unable to add web redirection, please make sure there is not a duplicate redirect entry";
$_ADDONLANG["dnssuitePage_manage_invalidredirectionurl"] = "The redirection URL is invalid.";
$_ADDONLANG["dnssuitePage_manage_invalidtype"] = "The redirection type is incorrect.";
$_ADDONLANG["dnssuitePage_manage_js_deleteconfirmredirect"] = "Do you want to delete the redirect?";

//Email forwarding
$_ADDONLANG["dnssuitePage_manage_verifypin"] = "Verify Pin";
$_ADDONLANG["dnssuitePage_manage_destinationplaceholder"] = "newDestination@domain.com";
$_ADDONLANG["dnssuitePage_manage_addemail_slotfull"] = "You have reached the maximum destination email you can add. Please contact support.";
$_ADDONLANG["dnssuitePage_manage_deleteemail_failed_id"] = "Invalid email address being delete, please contact support.";
$_ADDONLANG["dnssuitePage_manage_emailempty"] = "The email field is empty.";
$_ADDONLANG["dnssuitePage_manage_emailinvalid"] = "The email you entered is invalid. Please try again.";
$_ADDONLANG["dnssuitePage_manage_verifypin_empty"] = "The pin is blank";
$_ADDONLANG["dnssuitePage_manage_forwarder_footer"] = "To setup a Email Forwarding. You must first add a new Email Destination. A verification code will be send to that email destination to confirm the forwarding. Once you have received the verification code, enter it to the Verify Pin above. Once the destination is confirmed, you can proceed to create a new Forwarding Alias and be able to assign the previous email destination to that email alias for forwarding.";

//v1.11
$_ADDONLANG["dnssuitePage_manage_newalias"] = "newalias";
$_ADDONLANG["dnssuitePage_manage_newalias_empty"] = "The alias field is empty.";
$_ADDONLANG["dnssuitePage_manage_forwarder_modify_null"] = "If you are trying to clear the destination, you will need to remove the alias.";

//v1.12
$_ADDONLANG["dnssuitePage_manage_api_refresh_failed"] = "Failed to refresh API keys";
$_ADDONLANG["dnssuitePage_manage_api_enable_failed"] = "Failed to enable the API";
$_ADDONLANG["dnssuitePage_manage_api_disable_failed"] = "Failed to disable the API";

//v1.2
$_ADDONLANG['clientarea_ov_subdomainlimit'] = "Sub-Domain Limit";
$_ADDONLANG['clientarea_ov_maskedredirect'] = "Masked Web Redirection Support";
$_ADDONLANG["dnssuitePage_manage_999"] = "Masked";
$_ADDONLANG["dnssuitePage_manage_invalidredirectionurlmasked"] = "The source URL is invalid for masked redirect. It can only include alphanumeric, period, hypen and underscore characters.";
$_ADDONLANG["dnssuitePage_manage_redirectionmaskedexplain"] = "A Masked redirection allow you to show an externally sourced page and display it under your domain in the browser's URL. Due to browser security settings, it is recommended to use regular http instead of https for a Masked Redirection.";
$_ADDONLANG["dnssuitePage_manage_redirectatroot"] = "Unable to add a new masked redirect due to an existing redirect rule on the root of your domain. Please remove that first then try again.";
$_ADDONLANG["dnssuitePage_manage_pagetitle"] = "Page title";
$_ADDONLANG["dnssuitePage_manage_meta"] = "Meta tags";
$_ADDONLANG["dnssuitePage_manage_keywords"] = "Keywords";
$_ADDONLANG["dnssuitePage_manage_redirect_delete_failed"] = "Unable to delete the Web Redirection";
$_ADDONLANG["dnssuitePage_manage_redirect_delete_success"] = "Web redirection successfully deleted";

$_ADDONLANG["dnssuitePage_manage_subdomain"] = "Sub-domain";
$_ADDONLANG["dnssuitePage_manage_subdomain_hostname"] = "Hostname";
$_ADDONLANG["dnssuitePage_manage_subdomain_add_success"] = "Sub-domain added successfully";
$_ADDONLANG["dnssuitePage_manage_subdomain_add_failed"] = "Failed to add Sub-domain, please contact support";
$_ADDONLANG["dnssuitePage_manage_managesubdomain"] = "Manage Sub-Domains";
$_ADDONLANG["dnssuitePage_manage_subdomain_reset_success"] = "Sub-domain reset successfully";
$_ADDONLANG["dnssuitePage_manage_subdomain_reset_failed"] = "Failed to reset Sub-domain, please try again";
$_ADDONLANG["dnssuitePage_manage_subdomainintro"] = "Add email forwarding, catch-all and URL redirect under a sub-domain.";
$_ADDONLANG["dnssuitePage_manage_existingsubdomain"] = "Existing Sub-domains for:";
$_ADDONLANG["dnssuitePage_manage_subdomainempty"] = "The hostname field is empty.";
$_ADDONLANG["dnssuitePage_manage_subdomaininvalidhostname"] = "The hostname is invalid, please make sure it is in the valid format";
$_ADDONLANG["dnssuitePage_manage_subdomain_hostnameexist"] = "There is an existing hostname in your DNS entry. Please remove it first and then add the subdomain again";
$_ADDONLANG["dnssuitePage_manage_subdomain_overlimit"] = "You are over your sub-domain limit, please upgrade to another package.";
$_ADDONLANG["dnssuitePage_manage_subdomain_delete_success"] = "Successfully deleted sub-domain";
$_ADDONLANG["dnssuitePage_manage_subdomain_delete_failed"] = "Failed to delete sub-domain, please contact support";
$_ADDONLANG["dnssuitePage_manage_subdomain_notowned"] = "You do not own that sub-domain. Please try again.";
$_ADDONLANG["dnssuitePage_manage_js_deleteconfirmresubdomain"] = "Do you want to delete this Sub-Domain?";
$_ADDONLANG["dnssuitePage_manage_subdomain_return"] = "Return to domain root";

//v1.26
$_ADDONLANG["dnssuitePage_manage_overview_requestssl"] = "Request SSL";
$_ADDONLANG["dnssuitePage_manage_overview_requestssl_success"] = "SSL successfully generated. You may need to clear your browser cache to see the updated SSL";
$_ADDONLANG["dnssuitePage_manage_overview_requestssl_failed"] = "Failed to request SSL. Your domain must be properly propagated and pointed to our server. It will not work if it is pointed else where.";
$_ADDONLANG["dnssuitePage_manage_overview_requestssl_tooltip"] = "In order for SSL to generate, your domain must be pointed to our server";

$_ADDONLANG["dnssuitePage_manage_overview_switchns_tooltip"] = "!!! Do not switch the Nameservers if you are using an existing web hosting service's nameserver. It will stop your domain from functioning !!!";
$_ADDONLANG["dnssuitePage_manage_overview_resetdomain_tooltip"] = "This will reset all settings. Proceed with caution!";
$_ADDONLANG["dnssuitePage_manage_overview_cleardns_tooltip"] = "This will wipe all DNS records for your domain";

$_ADDONLANG["dnssuitePage_manage_overview_restorednstemplate_tooltip"] = "Replace your existing DNS records with the template. It will replace clear your existing DNS records unless Preserve my current DNS records is checked";
$_ADDONLANG["dnssuitePage_manage_overview_createuserdnstemplate_tooltip"] = "Save your current DNS settings to be used with another domain";

$_ADDONLANG["dnssuitePage_manage_overview_enableapi_tooltip"] = "Enable the API will allow you to update DNS records automatically via an external device (Router, cronjob, etc...)";

$_ADDONLANG["dnssuitePage_manage_redirect_tooltip"] = "Redirection will not work if your domain A record is pointed to an external server";
$_ADDONLANG["dnssuitePage_manage_forwarder_tooltip"] = "Email Forwarding will not work if your MX record is pointed to an external server";
$_ADDONLANG["dnssuitePage_manage_catchall_tooltip"] = "Catch-all will not work if your MX record is pointed to an external server";

//v1.3
$_ADDONLANG["dnssuitePage_manage_dnssec"] = "DNSSEC";
$_ADDONLANG["dnssuitePage_manage_overview_dnssec"] = "The DNSSEC status for the domain is:";
$_ADDONLANG["dnssuitePage_manage_dnssec_on"] = "Enabled";
$_ADDONLANG["dnssuitePage_manage_dnssec_off"] = "Disabled";
$_ADDONLANG["dnssuitePage_manage_dnssec_enable"] = "Enable DNSSEC on DNS Zone";
$_ADDONLANG["dnssuitePage_manage_dnssec_disable"] = "Disable DNSSEC on DNS Zone";
$_ADDONLANG["dnssuitePage_manage_overview_dnssec_tooltip"] = "Enabling this will turn DNSSEC on your DNS zone for the domain. Note that before DNSSEC will work on your domain, the DS record must be added to your domain at the registry level";
$_ADDONLANG["dnssuitePage_manage_overview_dnssec_enable_success"] = "Successfully enabled DNSSEC on the zone. Make sure the DS record is enabled at the registry level for the domain! Otherwise, the domain will fail to propagte.";
$_ADDONLANG["dnssuitePage_manage_overview_dnssec_enable_failed"] = "Failed to enable DNSSEC on the zone. Please contact support if this persists";
$_ADDONLANG["dnssuitePage_manage_overview_dnssec_enable_warning"] = "The DS record must be entered at the registry for the domain before DNSSEC will operate on the domain. Please contact support for this.";
$_ADDONLANG["dnssuitePage_manage_overview_dnssec_disable_success"] = "Successfully disabled DNSSEC on the zone. Make sure the DS record is erased at the registry level for the domain! Otherwise, the domain will fail to propagte.";
$_ADDONLANG["dnssuitePage_manage_overview_dnssec_disable_failed"] = "Failed to disable DNSSEC on the zone. Please contact support if this persists";
$_ADDONLANG["dnssuitePage_manage_overview_dnssec_disable_warning"] = "!!STOP!! If you have an existing DS record entered on the registry level. DO NOT PROCEED! Disabling DNSSEC while leaving the DS record at the registry will leave your domain non-functional. Contact support if you are unsure!";
$_ADDONLANG["dnssuitePage_manage_js_endablednssecconfirm"] = "Do you want to enable DNSSEC for the domain?";
$_ADDONLANG["dnssuitePage_manage_js_disablednssecconfirm"] = "Do you want to disable DNSSEC for the domain?";
$_ADDONLANG["dnssuitePage_manage_dnssec_ds"] = "DS Record (DS)";
$_ADDONLANG["dnssuitePage_manage_dnssec_zsk"] = "Zone Signing Key (ZSK)";
$_ADDONLANG["dnssuitePage_manage_dnssec_ksk"] = "Key Signing Key (KSK)";
$_ADDONLANG["dnssuitePage_manage_dnssec_keytag"] = "Keytag";
$_ADDONLANG["dnssuitePage_manage_dnssec_algorithm"] = "Algorithm";
$_ADDONLANG["dnssuitePage_manage_dnssec_type"] = "Digest Type";
$_ADDONLANG["dnssuitePage_manage_dnssec_digest"] = "Digest";