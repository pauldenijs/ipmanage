#! /usr/bin/perl

use CGI;
use CGI::Carp qw(fatalsToBrowser);
use CGI::Cookie;
use File::Basename;
$q = new CGI;

BEGIN {
	push (@INC,"../modules");
}

use ipmanage_config;
use sql;

$form=$q->param('form');

print $q->header(),"\n";
my $modified_network=&select1("SELECT DATE_FORMAT(modified,'%Y%m%d%H%i%S') FROM ip_nets ORDER BY modified DESC limit 1;");
my $modified_ip=&select1("SELECT DATE_FORMAT(modified,'%Y%m%d%H%i%S') FROM ip_hosts ORDER BY modified DESC limit 1;");
my $modified=$modified_ip;
if ($modified_network > $modified_ip) {
	$modified=$modified_network;
}

print $q->start_form(-name=>check)."\n";
print $q->textfield(
	-name=>'modified',
	-value=>$modified,
	),"\n";
print $q->end_form(),"\n";

print <<___JS___;
<script language=javascript>
function check_parent() {
	if (window.parent.document.$form.now.value < document.check.modified.value) {
		window.parent.document.$form.hidden_refresh.click();
	}
}
</script>
___JS___

print "<BODY onload='check_parent();'>\n";

