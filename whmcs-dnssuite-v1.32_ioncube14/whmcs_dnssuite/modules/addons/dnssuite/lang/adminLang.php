<?php
$ADMINLANG_domainstatus = "Domain Status";
$ADMINLANG_currentns = "Current Nameservers";
$ADMINLANG_load = 'Load';
$ADMINLANG_totallocal = 'Total Local Active Domains:';
$ADMINLANG_totalremote = 'Total Remote Domains:';
$ADMINLANG_synctoremote = 'Sync Domains to Remote';
$ADMINLANG_finishsyncing = 'Finished syncing to DirectAdmin server';
$ADMINLANG_systemdns = 'System DNS Templates';
$ADMINLANG_clientdns = 'Client DNS Templates';
$ADMINLANG_nosystemdns = 'No system DNS Templates';
$ADMINLANG_noclientdns = 'No client DNS Templates';
$ADMINLANG_templatename = 'Template Name';
$ADMINLANG_finddomain = 'Find Domain';
$ADMINLANG_status = 'Status';
$ADMINLANG_edit = 'Edit';
$ADMINLANG_enabled = 'Enabled';
$ADMINLANG_disabled = 'Disabled';
$ADMINLANG_createnew = 'Create New Template';
$ADMINLANG_alphaonly = 'Alpha-numeric only, no spaces';
$ADMINLANG_error = 'Error';
$ADMINLANG_error_invalidname = 'Unable to add new template. Name must be Alpha-numeric without space.';
$ADMINLANG_error_duplicatename = 'Unable to add new template. There is a duplicate name in the system';
$ADMINLANG_success_addtemplate = 'Successfully added new template to the system';
$ADMINLANG_host = 'Host';
$ADMINLANG_value = 'Value';
$ADMINLANG_priority = 'Priority';
$ADMINLANG_weight = 'Weight';
$ADMINLANG_port = 'Port';
$ADMINLANG_redirect = 'Redirect';
$ADMINLANG_forwarder = 'Email Forwarding';
$ADMINLANG_catchall = 'Email Catch-All';
$ADMINLANG_deleteconfirm = 'Do you want to delete?';
$ADMINLANG_resetconfirm = "Do you want to reset the domain?";
$ADMINLANG_dnstemplateupdated = 'Template updated';
$ADMINLANG_dnstemplateupdatefailed = 'Unable to update DNS template';
$ADMINLANG_dnstemplatestatusupdated = 'DNS Template status updated';
$ADMINLANG_dnstemplateupdatestatusfailed = 'Unable to update DNS template status';
$ADMINLANG_dnstemplatedeleted = 'DNS Template deleted';
$ADMINLANG_dnstemplatedeletefailed = 'Failed to delete DNS Template';
$ADMINLANG_noresult = 'No result found, make sure the domain is in Active state .Please try again';
$ADMINLANG_restoreconfirm = "Do you want to restore the template onto your domain?";

//Version 1.1
$ADMINLANG_recorddeleted_success = "Record successfully deleted";
$ADMINLANG_recorddeleted_failed = "Unable to delete record, please contact support";

//Version 1.2
$ADMINLANG_subdomain = "Sub-Domain";
$ADMINLANG_nosubdomain = "No Sub-Domain";
$ADMINLANG_subdomainhostname = "Sub-Domain Hostname";
$ADMINLANG_subdomainmanage = "Manage";
$ADMINLANG_manage_js_deleteconfirmresubdomain = "Do you want to delete this Sub-Domain?";
$ADMINLANG_emaildestination = "Email Destination";
$ADMINLANG_dnsmgmtlink = "DNS Suite Management Link";


$ADMINLANGARRAY["dnssuitePage_manage_overview_nsfailed_explain"] = "The Nameservers set for the domain is currently not the ones required for the domain services to work. Press the Switch Nameservers button below to switch the domain's nameserver";
$ADMINLANGARRAY["dnssuitePage_manage_overview_switchns"] = "Switch Nameservers";
$ADMINLANGARRAY["dnssuitePage_manage_overview_switchns_success"] = "Successfully updated the nameservers for your domain. Please allow a few hours for DNS propagation";
$ADMINLANGARRAY["dnssuitePage_manage_overview_switchns_failed"] = "Failed to switch nameservers for your domain, please contact support";
$ADMINLANGARRAY["dnssuitePage_manage_overview_resetdomain_explain"] = "You can reset your domain's DNS, web redirect, email forwarding and catch-all back to the original status by using the button below";
$ADMINLANGARRAY["dnssuitePage_manage_overview_resetdomain"] = "Reset Domain";
$ADMINLANGARRAY["dnssuitePage_manage_overview_resetdomain_success"] = "Successfully reset the domain to default state.";
$ADMINLANGARRAY["dnssuitePage_manage_overview_resetdomain_failed"] = "Failed to reset the domain, please contact support";
$ADMINLANGARRAY["dnssuitePage_manage_overview_cleardns"] = "Clear DNS Records";
$ADMINLANGARRAY["dnssuitePage_manage_overview_cleardns_success"] = "Successfully cleared DNS records";
$ADMINLANGARRAY["dnssuitePage_manage_overview_cleardns_failed"] = "Failed to clear DNS, please contact support";
$ADMINLANGARRAY["dnssuitePage_manage_overview_removedomain"] = "Remove Domain from Database";
$ADMINLANGARRAY["dnssuitePage_manage_overview_removedomain_success"] = "Successfully remove the domain from database";
$ADMINLANGARRAY["dnssuitePage_manage_overview_removedomain_failed"] = "Failed to remove domain from database, please contact support";


$ADMINLANGARRAY["dnssuitePage_manage_js_error"] = "Error";
$ADMINLANGARRAY["dnssuitePage_manage_js_resetconfirm"] = "Do you want to reset the domain?";
$ADMINLANGARRAY["dnssuitePage_manage_js_deleteconfirm"] = "Do you want to delete the record?";
$ADMINLANGARRAY["dnssuitePage_manage_js_deleteusertemplateconfirm"] = "Do you want to delete the template?";
$ADMINLANGARRAY["dnssuitePage_manage_js_restorednstemplateconfirm"] = "Do you want to restore the template onto your domain?";
$ADMINLANGARRAY["dnssuitePage_manage_js_templateinvalid"] = "The template name you are trying to use is invalid. Please try again.";
$ADMINLANGARRAY["dnssuitePage_manage_js_a_ip_error"] = "The IP is not in valid format: ";
$ADMINLANGARRAY["dnssuitePage_manage_js_a_ipv4_error"] = "The IP is not in valid IPv4 format: ";
$ADMINLANGARRAY["dnssuitePage_manage_js_aaaa_ipv6_error"] = "The IP is not in valid IPv6 format: ";
$ADMINLANGARRAY["dnssuitePage_manage_js_invalidhostname"] = "The hostname is not valid: ";
$ADMINLANGARRAY["dnssuitePage_manage_js_invalidpriority"] = "The priority is not valid: ";
$ADMINLANGARRAY["dnssuitePage_manage_js_fieldempty"] = "The field cannot be empty! ";
$ADMINLANGARRAY["dnssuitePage_manage_js_hostfieldempty"] = "The host field cannot be empty! ";
$ADMINLANGARRAY["dnssuitePage_manage_js_valuefieldempty"] = "The value field cannot be empty! ";
$ADMINLANGARRAY["dnssuitePage_manage_js_nsnodomain"] = "Cannot add additional NS record to the main domain.";
$ADMINLANGARRAY["dnssuitePage_manage_js_txtfieldempty"] = "The TXT value cannot be empty! ";
$ADMINLANGARRAY["dnssuitePage_manage_js_txtfieldinvalid"] = "The TXT value is not valid. Make sure it does not contain any quotes, single or double";
$ADMINLANGARRAY["dnssuitePage_manage_js_priorityfieldempty"] = "The priority field cannot be empty! ";
$ADMINLANGARRAY["dnssuitePage_manage_js_portfieldempty"] = "The port field cannot be empty! ";
$ADMINLANGARRAY["dnssuitePage_manage_js_weightfieldempty"] = "The weight field cannot be empty! ";
$ADMINLANGARRAY["dnssuitePage_manage_js_priorityinvalid"] = "The priority field must be a integer! ";
$ADMINLANGARRAY["dnssuitePage_manage_js_portinvalid"] = "The port field must be a integer! ";
$ADMINLANGARRAY["dnssuitePage_manage_js_weightinvalid"] = "The weight field must be a integer! ";
$ADMINLANGARRAY["dnssuitePage_manage_js_invalidrange"] = "The priority, weight, port field must be a number between 0 and 65535 ";
$ADMINLANGARRAY["dnssuitePage_manage_js_valuefieldinvalid"] = "Value field invalid";
$ADMINLANGARRAY["dnssuitePage_manage_js_ttlinvalid"] = "The TTL must be integer ";
$ADMINLANGARRAY["dnssuitePage_manage_js_ttlrangeinvalid"] = "The TTL must be between: ";
$ADMINLANGARRAY["dnssuitePage_manage_addrecord"] = "Add Record";
$ADMINLANGARRAY["dnssuitePage_manage_dnszone"] = "DNS Zone Editor";
$ADMINLANGARRAY["dnssuitePage_manage_destination"] = "Destination";
$ADMINLANGARRAY["dnssuitePage_manage_on"] = "On";
$ADMINLANGARRAY["dnssuitePage_manage_off"] = "Off";
$ADMINLANGARRAY["dnssuitePage_manage_host"] = "Host";
$ADMINLANGARRAY["dnssuitePage_manage_delete"] = "Delete";
$ADMINLANGARRAY["dnssuitePage_manage_disable"] = "Disable";
$ADMINLANGARRAY["dnssuitePage_manage_destinationhost"] = "Destination Host";
$ADMINLANGARRAY["dnssuitePage_manage_ip"] = "IP Address";
$ADMINLANGARRAY["dnssuitePage_manage_protocol"] = "Protocol";
$ADMINLANGARRAY["dnssuitePage_manage_priority"] = "Priority";
$ADMINLANGARRAY["dnssuitePage_manage_port"] = "Port";
$ADMINLANGARRAY["dnssuitePage_manage_modify"] = "Save";
$ADMINLANGARRAY["dnssuitePage_manage_redirectfor"] = "Redirection for:";
$ADMINLANGARRAY["dnssuitePage_manage_service"] = "Service";
$ADMINLANGARRAY["dnssuitePage_manage_source"] = "Source";
$ADMINLANGARRAY["dnssuitePage_manage_ttl"] = "TTL";
$ADMINLANGARRAY["dnssuitePage_manage_txtvalue"] = "TXT Value (without quotes)";
$ADMINLANGARRAY["dnssuitePage_manage_weight"] = "Weight";
$ADMINLANGARRAY["dnssuitePage_manage_value"] = "Value";
$ADMINLANGARRAY["dnssuitePage_manage_update"] = "Update";
$ADMINLANGARRAY["dnssuitePage_manage_verify"] = "Verify";
$ADMINLANGARRAY["dnssuitePage_manage_unverify"] = "Unverified";
$ADMINLANGARRAY["dnssuitePage_manage_confirm"] = "Confirm";
$ADMINLANGARRAY["dnssuitePage_manage_type"] = "Redirection Type";
$ADMINLANGARRAY["dnssuitePage_manage_301"] = "301 - Permanent";
$ADMINLANGARRAY["dnssuitePage_manage_302"] = "302 - Temporary";
$ADMINLANGARRAY["dnssuitePage_manage_303"] = "303 - Replaced";
//Email forwarding
$ADMINLANGARRAY["dnssuitePage_manage_addemaildestination_success"] = "Successfully added the email for forwarding, before you can use this destination you must verify the destination with the Pin that has been send to the email address. Please go back to the Email forwarding tab and confirm with the verification pin";
$ADMINLANGARRAY["dnssuitePage_manage_addemail_failed"] = "Failed to add email to the database. Try again";
$ADMINLANGARRAY["dnssuitePage_manage_addemail_existed"] = "Failed to add email to the database. The same email has been used already.";
$ADMINLANGARRAY["dnssuitePage_manage_addemail_validation"] = "Failed to add email to the database. The email is not valid.";
$ADMINLANGARRAY["dnssuitePage_manage_addemail_success"] = "Successfully added the forwarder to the database, you can now assign emails to the forwarding";
$ADMINLANGARRAY["dnssuitePage_manage_addemail"] = "Add Email";
$ADMINLANGARRAY["dnssuitePage_manage_addalias_existed"] = "Failed to add forwarder to the database. The same forwarder has been used already.";
$ADMINLANGARRAY["dnssuitePage_manage_addalias_validation"] = "Failed to add forwarder to the database. The forwarder is not valid.";
$ADMINLANGARRAY["dnssuitePage_manage_addalias"] = "Add Alias";
$ADMINLANGARRAY["dnssuitePage_manage_addforwarding"] = "Add forwarding alias for:";
$ADMINLANGARRAY["dnssuitePage_manage_deleteemail_success"] = "Successfully deleted email from the database.";
$ADMINLANGARRAY["dnssuitePage_manage_deleteemail_failed"] = "Failed to delete email to the database. Please try again.";
$ADMINLANGARRAY["dnssuitePage_manage_deleteemail_failed_inuse"] = "Failed to delete email to the database. Email address currently in use";
$ADMINLANGARRAY["dnssuitePage_manage_verifypin_correctpin"] = "Pin validated, the email destination is now active";
$ADMINLANGARRAY["dnssuitePage_manage_verifypin_incorrectpin"] = "Incorrect pin entered, please try again";
$ADMINLANGARRAY["dnssuitePage_manage_verifypin_failed"] = "Unable to verify pin, please contact support";
$ADMINLANGARRAY["dnssuitePage_manage_confirmemail"] = "Email confirmed, it is now active";
$ADMINLANGARRAY["dnssuitePage_manage_confirmemail_failed"] = "Unable to confirm email, please try again";
$ADMINLANGARRAY["dnssuitePage_manage_existingforwarding"] = "Email Forwarding:";
$ADMINLANGARRAY["dnssuitePage_manage_existingcatchall"] = "Email Catch-all:";
$ADMINLANGARRAY["dnssuitePage_manage_addnewforwarding"] = "Add new email forwarding for:";
$ADMINLANGARRAY["dnssuitePage_manage_addemaildestination"] = "Add new email destination";

//Catchall
$ADMINLANGARRAY["dnssuitePage_manage_catchall_status"] = "Catch-all Status";
$ADMINLANGARRAY["dnssuitePage_manage_catchall_status_on"] = "On";
$ADMINLANGARRAY["dnssuitePage_manage_catchall_status_off"] = "Off";
$ADMINLANGARRAY["dnssuitePage_manage_catchall_success"] = "Catch-all successfully updated";
$ADMINLANGARRAY["dnssuitePage_manage_catchall_failed"] = "Unable to update Catch-all email, please contact support";
$ADMINLANGARRAY["dnssuitePage_manage_catchall_threshold"] = "You are updating your catch-all too often, please wait 5 minutes then try again";
$ADMINLANGARRAY["dnssuitePage_manage_catchall_status_unverified"] = "Unverified";
$ADMINLANGARRAY["dnssuitePage_manage_catchall_invalidemail"] = "Unable update catch-all, the email is in invalid format";
$ADMINLANGARRAY["dnssuitePage_manage_catchall_disable_success"] = "Catch-all successfully disabled";
$ADMINLANGARRAY["dnssuitePage_manage_catchall_disable_failed"] = "Unable to disable Catch-all email, please contact support";

//Redirect
$ADMINLANGARRAY["dnssuitePage_manage_addnewredirection"] = "Add new redirection for:";
$ADMINLANGARRAY["dnssuitePage_manage_setredirect"] = "Set redirect";
$ADMINLANGARRAY["dnssuitePage_manage_modifyredirect"] = "Modify redirect";
$ADMINLANGARRAY["dnssuitePage_manage_setforwarding"] = "Add forwarding";
$ADMINLANGARRAY["dnssuitePage_manage_modifyforwarding"] = "Modify forwarding";
$ADMINLANGARRAY["dnssuitePage_manage_emaildestination"] = "Email Destination";
$ADMINLANGARRAY["dnssuitePage_manage_updatecatchall"] = "Update Catch-All";
$ADMINLANGARRAY["dnssuitePage_manage_verifypin"] = "Verify Pin";
$ADMINLANGARRAY["dnssuitePage_manage_disablecatchall"] = "Disable Catch-All";

//DNSTemplate
$ADMINLANGARRAY["dnssuitePage_manage_loadtemplateplaceholder"] = 'Select your template';
$ADMINLANGARRAY["dnssuitePage_manage_savetemplate_preservedns"] = "Preserve current DNS records";
$ADMINLANGARRAY["dnssuitePage_manage_loadtemplate"] = "Load Template";

//Version 1.09
$ADMINLANG_domain_table_header = "Domain";
$ADMINLANG_domain_table_checkbox = "Keep Domain";
$ADMINLANG_remove_3m = "Remove 3 months expired domains from DA Server";
$ADMINLANG_remove_6m = "Remove 6 months expired domains from DA Server";
$ADMINLANG_remove_1y = "Remove 1 year expired domains from DA Server";
$ADMINLANG_deletedomain_button = "Delete Domains from DA Server";
$ADMINLANG_finishdelete = 'Finished deleting from DirectAdmin server';

//Version 1.099
$ADMINLANGARRAY["dnssuitePage_manage_dns_addrecord_success"] = "Successfully added the DNS record to the zone";
$ADMINLANGARRAY["dnssuitePage_manage_dns_addrecord_failed"] = "Unable to add DNS record to the zone, please contact support";
$ADMINLANGARRAY["dnssuitePage_manage_dns_updaterecord_success"] = "Successfully updated the DNS record";
$ADMINLANGARRAY["dnssuitePage_manage_dns_updaterecord_failed"] = "Unable to update the DNS record, please contact support";
$ADMINLANGARRAY["dnssuitePage_manage_dns_nssamedomain"] = "Cannot add additional NS record to the main domain.";
$ADMINLANGARRAY["dnssuitePage_manage_dns_invalidip"] = "Unable to update the DNS record, please check the IP";
$ADMINLANGARRAY["dnssuitePage_manage_dns_invalidhostname"] = "Invalid hostname, please check and try again";
$ADMINLANGARRAY["dnssuitePage_manage_dns_invalidhostvalue"] = "Unable to update the DNS record, please check the host and value";
$ADMINLANGARRAY["dnssuitePage_manage_dns_invalidmxvalue"] = "Invalid MX value, please check and try again";
$ADMINLANGARRAY["dnssuitePage_manage_dns_invalidmxpriority"] = "Invalid MX priority, please check and try again";
$ADMINLANGARRAY["dnssuitePage_manage_dns_invalidtxtvalue"] = "Invalid TXT value, please check and try again";
$ADMINLANGARRAY["dnssuitePage_manage_dns_invalidnsvalue"] = "Invalid NS value, please check and try again";
$ADMINLANGARRAY["dnssuitePage_manage_dns_duplicatecname"] = "There is a duplicate CNAME record of the same hostname, please delete it first";
$ADMINLANGARRAY["dnssuitePage_manage_dns_duplicatea"] = "There is a duplicate A record of the same hostname, please delete it first";
$ADMINLANGARRAY["dnssuitePage_manage_record_delete_success"] = "Record successfully deleted";
$ADMINLANGARRAY["dnssuitePage_manage_record_delete_failed"] = "Unable to delete record, please contact support";

//Version 1.1
$ADMINLANGARRAY["dnssuitePage_manage_redirect_success"] = "New web redirection successfully added";
$ADMINLANGARRAY["dnssuitePage_manage_redirectionblank"] = "The redirection destination cannot be blank.";
$ADMINLANGARRAY["dnssuitePage_manage_redirect_failed_url"] = "Unable add new web redirection, please check your URLs";
$ADMINLANGARRAY["dnssuitePage_manage_redirect_addfailed_duplicate"] = "Unable to add web redirection, please make sure there is not a duplicate redirect entry";
$ADMINLANGARRAY["dnssuitePage_manage_invalidredirectionurl"] = "The redirection URL is invalid.";
$ADMINLANGARRAY["dnssuitePage_manage_invalidtype"] = "The redirection type is incorrect.";
$ADMINLANGARRAY["dnssuitePage_manage_js_deleteconfirmredirect"] = "Do you want to delete the redirect?";
$ADMINLANGARRAY["dnssuitePage_manage_redirect_modifyfailed_support"] = "Unable modify web redirection, contact support";
$ADMINLANGARRAY["dnssuitePage_manage_emailempty"] = "The email field is empty.";
$ADMINLANGARRAY["dnssuitePage_manage_emailinvalid"] = "The email you entered is invalid. Please try again.";
$ADMINLANGARRAY["dnssuitePage_manage_forwarder_modify_success"] = "Email forwarder successfully updated";
$ADMINLANGARRAY["dnssuitePage_manage_forwarder_modify_success"] = "Email forwarder successfully updated";
$ADMINLANGARRAY["dnssuitePage_manage_forwarder_modify_invalidemail"] = "Unable to update forwarder, please check if the email addresses are in correct format";
$ADMINLANGARRAY["dnssuitePage_manage_forwarder_modify_failed"] = "Unable to update forwarder, please contact support";
$ADMINLANGARRAY["dnssuitePage_manage_forwarder_delete_success"] = "Email forwarder successfully deleted";
$ADMINLANGARRAY["dnssuitePage_manage_forwarder_delete_failed"] = "Email forwarder deletion failed, please contact support";

//Version 1.11
$ADMINLANGARRAY["dnssuitePage_manage_newalias"] = "newalias";
$ADMINLANGARRAY["dnssuitePage_manage_newalias_empty"] = "The alias field is empty.";
$ADMINLANGARRAY["dnssuitePage_manage_forwarder_modify_null"] = "If you are trying to clear the destination, you will need to remove the alias.";

//Version 1.2
$ADMINLANGARRAY["dnssuitePage_manage_overview_resetsubdomain_explain"] = "Reset sub-domain's web redirect, email forwarding and catch-all back to the original status by using the button below";
$ADMINLANGARRAY["dnssuitePage_manage_overview_resetsubdomain"] = "Reset Sub-Domain";

$ADMINLANGARRAY["dnssuitePage_manage_999"] = "Masked";
$ADMINLANGARRAY["dnssuitePage_manage_invalidredirectionurlmasked"] = "The source URL is invalid for masked redirect. It can only include alphanumeric, period, hypen and underscore characters.";
$ADMINLANGARRAY["dnssuitePage_manage_redirectatroot"] = "Unable to add a new masked redirect due to an existing redirect rule on the root of your domain. Please remove that first then try again.";
$ADMINLANGARRAY["dnssuitePage_manage_pagetitle"] = "Page title";
$ADMINLANGARRAY["dnssuitePage_manage_meta"] = "Meta tags";
$ADMINLANGARRAY["dnssuitePage_manage_keywords"] = "Keywords";
$ADMINLANGARRAY["dnssuitePage_manage_redirect_delete_failed"] = "Unable to delete the Web Redirection";
$ADMINLANGARRAY["dnssuitePage_manage_redirect_delete_success"] = "Web redirection successfully deleted";

$ADMINLANGARRAY["dnssuitePage_manage_subdomain"] = "Sub-domain";
$ADMINLANGARRAY["dnssuitePage_manage_subdomain_hostname"] = "Hostname";
$ADMINLANGARRAY["dnssuitePage_manage_subdomain_add_success"] = "Sub-domain added successfully";
$ADMINLANGARRAY["dnssuitePage_manage_subdomain_add_failed"] = "Failed to add Sub-domain, please contact support";
$ADMINLANGARRAY["dnssuitePage_manage_subdomainintro"] = "Add email forwarding, catch-all and URL redirect under a sub-domain.";
$ADMINLANGARRAY["dnssuitePage_manage_existingsubdomain"] = "Existing Sub-domains for:";
$ADMINLANGARRAY["dnssuitePage_manage_subdomainempty"] = "The hostname field is empty.";
$ADMINLANGARRAY["dnssuitePage_manage_subdomaininvalidhostname"] = "The hostname is invalid, please make sure it is in the valid format";
$ADMINLANGARRAY["dnssuitePage_manage_subdomain_hostnameexist"] = "There is an existing hostname in your DNS entry. Please remove it first and then add the subdomain again";
$ADMINLANGARRAY["dnssuitePage_manage_subdomain_overlimit"] = "You are over your sub-domain limit, please upgrade to another package.";
$ADMINLANGARRAY["dnssuitePage_manage_subdomain_delete_success"] = "Successfully deleted sub-domain";
$ADMINLANGARRAY["dnssuitePage_manage_subdomain_delete_failed"] = "Failed to delete sub-domain, please contact support";
$ADMINLANGARRAY["dnssuitePage_manage_subdomain_notowned"] = "You do not own that sub-domain. Please try again.";
$ADMINLANGARRAY["dnssuitePage_manage_js_deleteconfirmresubdomain"] = "Do you want to delete this Sub-Domain?";
$ADMINLANGARRAY["dnssuitePage_manage_subdomain_return"] = "Return to domain root";

//v1.26
$ADMINLANGARRAY["dnssuitePage_manage_overview_removedomainremote"] = "Remove Domain from DA server";
$ADMINLANG_requestLE = "Request LetsEncrypt SSL";
$ADMINLANG_requestssl_failed = "Request LetsEncrypt SSL failed";
$ADMINLANG_requestssl_success = "Request LetsEncrypt SSL success";

//v1.3
$ADMINLANGARRAY["dnssuitePage_manage_dnssec"] = "DNSSEC";
$ADMINLANGARRAY["dnssuitePage_manage_overview_dnssec"] = "The DNSSEC status for the domain is:";
$ADMINLANGARRAY["dnssuitePage_manage_dnssec_on"] = "Enabled";
$ADMINLANGARRAY["dnssuitePage_manage_dnssec_off"] = "Disabled";
$ADMINLANGARRAY["dnssuitePage_manage_dnssec_enable"] = "Enable DNSSEC on DNS Zone";
$ADMINLANGARRAY["dnssuitePage_manage_dnssec_disable"] = "Disable DNSSEC on DNS Zone";
$ADMINLANGARRAY["dnssuitePage_manage_overview_dnssec_tooltip"] = "Enabling this will turn DNSSEC on your DNS zone for the domain. Note that before DNSSEC will work on your domain, the DS record must be added to your domain at the registry level";
$ADMINLANGARRAY["dnssuitePage_manage_overview_dnssec_enable_success"] = "Successfully enabled DNSSEC on the zone. Make sure the DS record is enabled at the registry level for the domain! Otherwise, the domain will fail to propagte.";
$ADMINLANGARRAY["dnssuitePage_manage_overview_dnssec_enable_warning"] = "IMPORTANT!! Make sure the DS record is enabled at the registry level for the domain! Otherwise, the domain will fail to propagte.";
$ADMINLANGARRAY["dnssuitePage_manage_overview_dnssec_enable_failed"] = "Failed to enable DNSSEC on the zone. Please contact support if this persists";
$ADMINLANGARRAY["dnssuitePage_manage_overview_dnssec_disable_success"] = "Successfully disabled DNSSEC on the zone. Make sure the DS record is erased at the registry level for the domain! Otherwise, the domain will fail to propagte.";
$ADMINLANGARRAY["dnssuitePage_manage_overview_dnssec_disable_failed"] = "Failed to disable DNSSEC on the zone. Please contact support if this persists";
$ADMINLANGARRAY["dnssuitePage_manage_overview_dnssec_disable_warning"] = "IMPORTANT!! Make sure there is no DS record at the registry level for the domain! Otherwise, the domain will fail to propagte.";
$ADMINLANG_dnssuitePage_manage_js_endablednssecconfirm = "Do you want to enable DNSSEC for the domain?";
$ADMINLANG_dnssuitePage_manage_js_disablednssecconfirm = "Do you want to disable DNSSEC for the domain?";
$ADMINLANGARRAY["dnssuitePage_manage_dnssec_ds"] = "DS Record (DS)";
$ADMINLANGARRAY["dnssuitePage_manage_dnssec_zsk"] = "Zone Signing Key (ZSK)";
$ADMINLANGARRAY["dnssuitePage_manage_dnssec_ksk"] = "Key Signing Key (KSK)";
$ADMINLANGARRAY["dnssuitePage_manage_dnssec_keytag"] = "Keytag";
$ADMINLANGARRAY["dnssuitePage_manage_dnssec_algorithm"] = "Algorithm";
$ADMINLANGARRAY["dnssuitePage_manage_dnssec_type"] = "Digest Type";
$ADMINLANGARRAY["dnssuitePage_manage_dnssec_digest"] = "Digest";

?>