#! /usr/bin/perl
#

$|=1;  #flushing output directly

use DBI();
use CGI();
use CGI::Cookie;
use File::Basename;
use Data::Dumper;

$q = new CGI;

BEGIN {
        push (@INC,"../modules");
}

use ipmanage_config;
use ipmanage;
use ipmanage_commoncgi;
use sql;

$ENV{PATH}="/usr/sbin:/usr/bin:";
$ENV{ENV}="";

$ip=			$q->param('ip');
$action=		$q->param('action');   # keyword: add/deleted

if ($debug) {
	print STDERR "================= PARAMETERS ($my_own_url)====================\n";
	foreach my $key ($q->param()) {
		print STDERR "key:" , $key , ",value:" ,$q->param($key),"\n";
	}
	print STDERR "================= END PARAMETERS ====================\n";
}

&header($VERSION . " on " . $this_hostname . " - " . $prog_title);

if ($q->cookie(-name=>$cookie_id2) eq not_valid) {
        $remote_user="";
} else {
        $remote_user=$q->cookie(-name=>$cookie_id1);
}

if(&check_cookies($remote_user) == 0) {
	my $login_wheretogo="./ipmanage_login.pl?&caller=./$my_own_url";
	print "<SCRIPT language=Javascript>";
	print "gotoSite('$login_wheretogo')";
	print "</SCRIPT>";
	exit;
}

if ($remote_user eq "") {
	print "<SCRIPT language=javascript>";
	print "gotoSite('./ipmanage_login.pl?&caller=./$my_own_url');";
	print "</SCRIPT>";
	exit;
}

my $sql_cmd="";

if ($action eq "add") {
	$ip_dotted=&convert_dec2ip($ip);
	$sql_cmd="
		INSERT INTO ip_hosts_restricted (ip,modified,modifier)
		VALUES ($ip,NOW(),'$remote_user')
	; ";
	print $sql_cmd,"\n";
	&do_row($sql_cmd);
	print "<SCRIPT language=javascript>";
	print "alert('added ip address $ip_dotted to the restricted list');\n";
	print "</SCRIPT>";
}
if ($action eq "delete") {
	$network_dotted=&convert_dec2ip($network);
	$sql_cmd="DELETE FROM ip_hosts_restricted WHERE ip=$ip;";
	print "<pre>\n";
	print $sql_cmd,"\n";
	print "</pre>\n";
	&do_row($sql_cmd);
	print "<SCRIPT language=javascript>";
	print "alert('deleted ip address $ip_dotted from the restricted list');\n";
	print "</SCRIPT>";
}
