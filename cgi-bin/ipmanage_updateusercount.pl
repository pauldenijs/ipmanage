#! /usr/bin/perl
#
# ok, this script should not be called updateusercount.pl, since it does
# more, like looking for changes in configuration, and checking who
# logged into ipmanage, and who has not the ipmanage main screen up, (actually
# left for a while, or had the session expire)
# it also detects who joined and left

use CGI;
use CGI::Cookie;
use File::Basename;
$q = new CGI;
use Socket;
use Digest::MD5;


BEGIN {
	push (@INC,"../modules");
}

use ipmanage_config;
use ipmanage;
use ipmanage_commoncgi;
use ipmanage_checksum;
use sql;

$refreshrate=		$q->param('refreshrate');
$who=			$q->param('who');
$validlogin=		$q->param('validlogin');
$action=		$q->param('action');

my $status_text="";
my $w_peeker=350;
my $h_peeker=100;

#print STDERR "[$refreshrate,$who,$validlogin,$action,$client_ip,$client_hostname]\n" if ($debug);

print $q->header();
print "<html>\n";

$saw=$q->cookie(-name=>'screen_width');
$sah=$q->cookie(-name=>'screen_height');

print <<__SetCookie__and__BottomSizedNewWindow__;
<SCRIPT language=Javascript>
function DelCookie (cookiename) {
	var cookiedate = new Date();  // current date & time
	cookiedate.setTime (cookiedate.getTime() - 1000);
	document.cookie=cookiename += "=; expires=" + cookiedate.toGMTString();
}

function SetCookie(cookiename,cookievalue,cookiepath,mseconds) {
        var str = ""
        var expires = null
        now=new Date();
        if (mseconds > 0) {
                expires=new Date(now.getTime()+mseconds)
        }
        str += cookiename + "=" + cookievalue
        if (mseconds > 0) {
                str += ";expires=" + expires.toGMTString();
        }
        str += ";path=" + cookiepath;
        document.cookie=str;
}

function BottomSizedNewWindow(file,win,w,h) {
	var options="";
	options+="toolbar=0,";
	options+="location=0,";
	options+="directories=0,";
	options+="status=0,";
	options+="scrollbars=1,";
	options+="resizable=1,";
	var t=$sah-h;
	var l=$saw-w;
	var attr="";
	attr+="height=" + h + ",";
	attr+="width=" + w + ",";
	attr+="top=" + t + ",";
	attr+="left=" + l + "";
	options += attr;
	me=open(file,win,options);
	me.blur();
	self.focus();
	if (!me.opener) me.opener=self;
}

function get_local_address() {
	var w=window.location;
	var h=w.host;
	var p=w.port || 80;

	SetCookie('client_ip','NA','',0);
	SetCookie('client_hostname','NA','',0);
}
</SCRIPT>
__SetCookie__and__BottomSizedNewWindow__


if ($q->cookie(-name=>'ipmanageID')) {

	$client_ip=$q->cookie(-name=>'client_ip');
	$client_hostname=$q->cookie(-name=>'client_hostname');

	$client_ip='NA' if ($client_ip eq '');
	$client_hostname='NA' if ($client_hostname eq '');

	if ($client_ip eq $client_hostname and $client_hostname ne 'NA') {
		# try to find the client_hostname here...
		my ($l_name,$l_aliases,$l_addrtype,$l_length,@l_addrs)=gethostbyaddr(inet_aton($client_ip),AF_INET);
		$client_hostname=$l_name;
	}

	$update_warning=$q->cookie(-name=>'update_warning');
	$update_warning=$update_warning+0;
	my @old_users=split /\|/, $q->cookie(-name=>'ipmanage_users');

	$ipmanageid=$q->cookie(-name=>'ipmanageID');
	my $remote_address="";
	if ($ENV{'HTTP_CLIENT_IP'} eq "") {
		$remote_address=$ENV{'REMOTE_ADDR'};
	} else {
		$remote_address=$ENV{'HTTP_CLIENT_IP'};
	}
	my $cmd="";
	$cmd="DELETE FROM ipmanage_usercount WHERE ipmanageID='$ipmanageid'";
	$dbh->do($cmd);
	$cmd="INSERT INTO ipmanage_usercount (ipmanageID,login,remote_address,client_ip,client_hostname) " . 
		"VALUES('$ipmanageid','$who','$remote_address','$client_ip','$client_hostname')";
	$dbh->do($cmd);
	my $now=&select1("SELECT NOW() + 0");
	my $expired=&select1("SELECT DATE_SUB(NOW()+0, INTERVAL $refreshrate SECOND)+0");
	$cmd="DELETE FROM ipmanage_usercount WHERE timestamp <= $expired ";
	&do_row($cmd);
	$nr_of_users=&select1("SELECT COUNT(*) FROM ipmanage_usercount");

	$cmd="SELECT ipmanageID,login,remote_address,client_ip,client_hostname FROM ipmanage_usercount";	
	my $ipmanage_users="";
	my @users=&select_array($cmd);

	# compare  @old_users and @users (current users)
	# we are actually only interested in new users, 
	# who and where they come from
	# just report the number of users who left
	@new_users;
	$usertable="<TABLE BORDER=1 CELLPADDING=1 CELLSPACING=1>";
	# without the client info
	# $usertable.="<TR><TH nowrap>User</TH><TH nowrap>Remote Address</TH></TR>";
	$usertable.="<TR><TH nowrap>User</TH><TH nowrap>Remote Address</TH><TH nowrap>Real Remote Hostname</TH><TH nowrap>Real Remote Address</TH></TR>";
	foreach $i (@users) {
		my ($id,$l,$r,$cip,$chn)=@$i;
		my $found=0;
		for $j (0 .. $#old_users) {
			if ($id eq $old_users[$j]) {
				splice(@old_users,$j,1);
				$found++;
			}
		}
		if (! $found) {
			push @new_users, [$l,$r,$cip,$chn];
		}
		$ipmanage_users.="$id|";
		# $r.=" (this session)" if ($id eq $ipmanageid);
		# without the client info
		# $usertable.="<TR><TD nowrap>$l</TD><TD nowrap>$r</TD></TR>";
		if ($id eq $ipmanageid) {
			$usertable.="<TR><TD nowrap CLASS=this_user_session>$l</TD><TD nowrap CLASS=this_user_session>$r</TD><TD nowrap CLASS=this_user_session>$chn</TD><TD nowrap CLASS=this_user_session>$cip</TD></TR>";
		} else {
			$usertable.="<TR><TD nowrap CLASS=other_user_session>$l</TD><TD nowrap CLASS=other_user_session>$r</TD><TD nowrap CLASS=other_user_session>$chn</TD><TD nowrap CLASS=other_user_session>$cip</TD></TR>";
		}
	}
	$usertable.="</TABLE>";
	$ipmanage_users=~s/\|$//;

	$new_usertable;
	if ($#new_users > -1 or  $#old_users > -1) {
		if ($#new_users > -1) {
			$new_usertable="<TABLE BORDER=1 CELLPADDING=1>";
			$new_usertable.="<TR><TH COLSPAN=2>New User(s)</TH></TR>";
			$new_usertable.="<TR><TH nowrap>User</TH><TH nowrap>Remote Address</TH></TR>";
			# the new user must be scanned first, and that is done after this page has been loaded !
			# $new_usertable.="<TR><TH nowrap>User</TH><TH nowrap>Remote Address</TH><TH nowrap>Real Remote Hostname</TH><TH nowrap>Real Remote Address</TH></TR>";
			foreach $i (@new_users) {
				my ($l,$r,$cip,$chn)=@$i;
				$new_usertable.="<TR><TD nowrap>$l</TD><TD nowrap>$r</TD></TR>";
				# the new user must be scanned first, and that is done after this page has been loaded !
				# $new_usertable.="<TR><TD nowrap>$l</TD><TD nowrap>$r</TD><TD nowrap>$chn</TD><TD nowrap>$cip</TD></TR>";
			}
			$new_usertable.="</TABLE>";
		}
		if ($#old_users > -1) {
			$new_usertable.="<BR>"; 
			$new_usertable.=$#old_users+1 . " user(s) left";
			$new_usertable.="<BR>";
		}
	}

	print $q->start_form(-name=>"usercount"),"\n";
	if ($q->cookie(-name=>$validlogin) eq "") {
		# craps, login expired, force a reload so that it can detect it
		$nr_of_users=-1;
		$status_text="Login expired ..."; 
	}

	# see if any other user updated something ....
	# if so, force a reload
	my $newchecksum=&get_checksum;
	my $cookie_checksum=$q->cookie(-name=>'checksum');
	$csflag=0;
	$reloadmsg="";
	if ($cookie_checksum ne $newchecksum) {
		print STDERR "$cookie_checksum, $newchecksum\n" if ($debug>9);
		$csflag=1;
		$status_text="Reload required because of updates detected ..."; 
		$reloadmsg="Reload of ipmanage main screen <BR>" .
			"required !!! You opted for NO automatic " .
			"reload (Autorefresh)";
		my $ar=$q->cookie(-name=>'AutoRefreshOFF');
		if ($ar eq "0" or $ar eq "") {
			$reloadmsg="Reloading ipmanage main screen,<BR>" .
				"Updates detected !!!";
			&update_checksum($newchecksum);
		} else {
			print "<SCRIPT language=Javascript>\n";
			# max warnings =3 times, then stop bugging
			$update_warning++;
			print "SetCookie('update_warning','$update_warning','',7776000000);\n";
			print "</SCRIPT>\n";
		}
	}

	print "csflag:";
	print $q->textfield(
                -name=>'csflag',
                -value=>$csflag,
                -size=>8,
                ),"\n";
	print "<BR>";

	print "uc:";
	print $q->textfield(
                -name=>'uc',
                -value=>0,
                -size=>8,
                ),"\n";
	print "<BR>";

	print "usertable:";
	print $q->textarea(
                -name=>'usertable',
                -value=>"",
                ),"\n";
	print "<BR>";

	print "<SCRIPT language=Javascript>\n";
	print "document.usercount.uc.value=$nr_of_users;\n";
	print "document.usercount.csflag.value=$csflag;\n";
	print "document.usercount.usertable.value=\"$usertable\";\n";
	print "SetCookie('ipmanage_users','$ipmanage_users','',7776000000);\n";
	$param="";
	if ($csflag) {
		$param.="&reloadmsg=$reloadmsg";
	}
	if ($new_usertable ne "") {
		$param.="&userchange=$new_usertable";
	}
	my $nf=$q->cookie(-name=>'NotifierOn');
	if ($nf eq "1") {
	   if ($param ne "") {
		if ($update_warning < 4) {
			print "BottomSizedNewWindow('./peeker.pl?$param','peeker',$w_peeker,$h_peeker);\n";
		} else {
			if ($new_usertable ne "") {
				print "BottomSizedNewWindow('./peeker.pl?$param','peeker',$w_peeker,$h_peeker);\n";
			}
		}
	   }
	}
	print "</SCRIPT>\n";
	print "<BODY onload=\"window.status='$status_text';setTimeout('get_local_address()',1000);\">\n";
	print $q->end_form(),"\n";
} else {
	$status_text="ipmanageID expired, forcing a re-login ...";
	print "$status_text<BR>\n";
	print $q->start_form(-name=>"usercount"),"\n";
	print $q->hidden(-name=>'csflag', -value=>0),"\n";
	print $q->hidden(-name=>'usertable', -value=>''),"\n";
	print "uc:";
	print $q->textfield(
                -name=>'uc',
                -value=>0,
                -size=>8,
                ),"\n";
	print $q->end_form(),"\n";
	# oh geez, you actually have to relogin !!!
	# use -1 in usercount to force a refresh 
	print "<SCRIPT language=Javascript>\n";
	print "document.usercount.uc.value=-1;\n";
	print "</SCRIPT>\n";
	print "<BODY onload=\"window.status='$status_text';\">\n";
	print $q->end_form(),"\n";
}

#print STDERR "$status_text\n" if ($debug);
print "</html>\n";
