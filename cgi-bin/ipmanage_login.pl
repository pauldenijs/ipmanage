#! /usr/bin/perl

$|=1;  #flushing output directly


use CGI;
use CGI::Cookie;
use File::Basename;
$q = new CGI;

BEGIN {
	push (@INC,"../modules");
}

use ipmanage_config;
use ipmanage;
use ipmanage_commoncgi;
use sql;

$this_hostname=         `/bin/hostname`;
chomp $this_hostname;

$passwd_input=		$q->param('passwd_input');
$login_input=		$q->param('login_input');
$action= 		$q->param('action');
$caller=		$q->param('caller');
$oldparams=		$q->param('oldparams');

# MAIN PROGRAM STARTS HERE ...
if ($q->cookie(-name=>$cookie_id2) eq not_valid) {
	$username="";
} else {
	$username=$q->cookie(-name=>$cookie_id1);
}

if ($action =~ /LOGIN/i) {
	&check_passwd; 
        print "<SCRIPT LANGUAGE=JavaScript>\n";
        my $popupmsg="This application requires popups to be enabled\\n";
        $popupmsg.="You cannot continue until you allow popups for this site";
        print "if(PopupBlocked()) {
		alert('$popupmsg');
		history.back();
	}\n";
        print "</SCRIPT>\n";
	#### &create_backdrop;
} elsif ($action =~ /LOGOUT/i) {
	&logout; 
} elsif ($action =~ /Return/i) {
	&goback_main;
} else {
	&check_passwd; 
}

sub goback_main {
        &header("");
        print "<SCRIPT language=javascript>\n";
        print "load('$caller?$allparams',opener);";
        print "window.close()";
        print "</SCRIPT>";
}

