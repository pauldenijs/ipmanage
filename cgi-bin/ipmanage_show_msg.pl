#! /usr/bin/perl

use CGI();
use CGI::Cookie;
use File::Basename;
$q = new CGI;

BEGIN {
        push (@INC,"../modules");
}

use ipmanage_config;
use ipmanage_commoncgi;

$this_hostname=         `/bin/hostname`;
chomp $this_hostname;

$messagefile=   $q->param('messagefile');
$ok_to_remove=   $q->param('ok_to_remove');


print $q->header(),"\n";
&js_include('../javascript/ipmanage_common.js');
&css_include('../stylesheets/ipmanage.css');

print "<DIV id=dialog>\n";
print "<TITLE>Dialog</TITLE>\n";
print "<CENTER>\n";

print "<SCRIPT LANGUAGE=JavaScript>\n";
print "setTimeout('window.close()', 30000);";
print "</SCRIPT>\n";

$mseconds=14400000;
$hour=$mseconds/3600/1000;

print $q->p;
open(MSG,"$messagefile");
print <MSG>;
close MSG;
print $q->p;

print $q->button(
		-name=>'OK',
		-value=>'OK',
		-class=>button,
		-onclick=>"window.close();",
		),"\n";

print "</CENTER>\n";
print "</DIV>\n";

if ($ok_to_remove) {
	#oh, I'm allowed to delete the messagefile now!
	print STDERR "DELETING $messagefile\n";
	unlink $messagefile;
}

print "<BODY onload='resizeWin(\"dialog\");'>\n";

