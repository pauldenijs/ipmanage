# This is the common module
#

BEGIN {
	if ($ENV{HTTP_HOST} ne "") {
	   if ($ipmanage_stderr ne "") {
       	 	use CGI::Carp qw(carpout);
       	 	open(ERR_LOG,">> $ipmanage_stderr") or 
		die ("Unable to open log file: $ipmanage_stderr");
        	carpout(ERR_LOG);
	   } else {
		use CGI::Carp qw(fatalsToBrowser);
	   }
	}
}

$VERSION=		"IPmanage 1.0";
$NOSELECTION=		"---none---";

$pathinfo=		dirname($ENV{'SCRIPT_NAME'}) if ($ENV{HTTP_HOST} ne "");
$my_own_url=		basename($0);
$my_own_url=~		 /(.*)/; $my_own_url=$1;
%cookies= 		fetch CGI::Cookie;

$cookie_id1=		${VERSION}. '_login';
$cookie_id1=~		s/\s+/_/g;
$cookie_value1=		'';
$cookie_expiration1=	2419200000; # 4 weeks = 4*7*24*3600*1000 ms

$cookie_id2=		${VERSION} . '_validlogin';
$cookie_id2=~		s/\s+/_/g;
$cookie_value2=		'';
$cookie_expiration2=	57600000; # 16 hours = 16*3600*1000 ms

$passwd_file=		"$INSTALLDIR/files/passwords";
$update_refreshrate=	30;	#check for updates every 30 seconds
				#like config changes, #of users etc

$saw=			0;
$sah=			0;
$max_screen_width=	300;
$max_screen_height=	300;

sub mysqldate_to_readable {
	my ($date)=@_;
	# converts YYYYMMDDHHMMSS to DD-MMM-YYYY HH:MM:SS 
	my @month_array= ('dummy','Jan','Feb','Mar','Apr','May','Jun',
		'Jul','Aug','Sep','Oct','Nov','Dec');
	my $year=substr($date,0,4);
	my $month=substr($date,4,2);
	my $day=substr($date,6,2);
	my $hour=substr($date,8,2);
	my $min=substr($date,10,2);
	my $sec=substr($date,12,2);
	return($day . "-" . $month_array[$month] . "-" . $year  .
		" " . $hour . ":" . $min . ":" . $sec);
}

sub show_head {
	my ($title)=@_;
	# the top row (left)
	print $q->start_center(),"\n";
	print "<TABLE BORDER=0 CELLPADDING=0 CELLSPACING=0 WIDTH=100%>\n";
	print "<TR>\n";
	print "<TD CLASS=TOPBAR ALIGN=left NOWRAP=nowrap>";
	print $VERSION," on ",$this_hostname;
	print "</TD>\n";
	if ($my_own_url =~ /ipmanage_main.pl/) {
		print "<TD CLASS=TOPBAR>\n";
		print "</TD>\n";

		print "<TD CLASS=TOPBAR ALIGN=center NOWRAP=nowrap>\n";
		print "logged in as: <FONT COLOR=#ff0000>";
		print $remote_user,"@",$this_hostname;
		print "</FONT>";
		print "&nbsp;&nbsp;&nbsp;";
		print "<A HREF=\"./ipmanage_login.pl?&caller=./$my_own_url\">login</A>";
		print "&nbsp;|&nbsp;";
		print "<A HREF=\"./ipmanage_login.pl?&caller=./$my_own_url?&action=LOGOUT\">logout</A>";
		print "</TD>\n";
		
		print "<TD CLASS=TOPBAR ALIGN=center NOWRAP=nowrap >";
		print "<A STYLE=\"color:#0000ff;cursor:pointer;\" onmouseover=\"balloon_popLayer(this,document.main.usertable.value)\" onmouseout=\"balloon_hideLayer();\">";
		print "Current Users: ";
		print "</A>";
		print $q->textfield(
			-name=>usercount,
			-value=>0,
			-size=>5,
			-class=>usercount,
			);
		print "</TD>\n";
	} else {
		print "<TD CLASS=TOPBAR ALIGN=center NOWRAP=nowrap>&nbsp;</TD>\n";
	}

	print "<TD CLASS=TOPBAR VALIGN=middle ALIGN=right NOWRAP=nowrap>";
	print "&nbsp;";
	print "</TR>\n";

	&logo_stuff;

	print "</TABLE>\n";
	print $q->end_center();
	print "\n";

	sub logo_stuff {
		print "<TR>\n";
		print "<TD CLASS=BODYt COLSPAN=5>\n";
		print "<div class=a2 id=a2>\n";
		if ($title ne "") {
			print "<div id=title class=title>$title</div>\n";
		}
		print "<div class=cornerTL>\n";
		print "<div class=cornerTR>\n";
		print "<div class=cornerBL>\n";
		print "<div class=cornerBR>\n";
		print "</div>\n";
		print "</div>\n";
		print "</div>\n";
		print "</div>\n";
		print "</div>\n";
		print "</TD>\n";
		print "</TR>\n";
	}
}

sub header {
	my ($title,$header_printed,$refreshrate)=@_;
	print $q->header() if (! $header_printed);
	print "<HEAD>\n";
	if ($refreshrate>0) {
		print "<META HTTP-EQUIV=refresh CONTENT=$refreshrate>\n";
	}
	print "<TITLE>";
	print "$title";
	print "</TITLE>\n";

	&css_include('../stylesheets/ipmanage.css');
	&js_include('../javascript/ipmanage_common.js');

	print "<SCRIPT LANGUAGE=javascript>";
	print "set_image_dir('../images');";
	print "</SCRIPT>\n";

	print "</HEAD>\n";

	&body;

	print "<div id=\"object1\" ",
		"style=\"position:absolute; ",
		"background-color:FFFFDD;",
		"color:black;border-color:black;border-width:20; ",
		"left:25px; top:-100px; z-index:2;\" ",
		"onmouseover=\"overdiv=1;\" ",
		"onmouseout=\"overdiv=0;setTimeout('hideLayer()',1000)\">",
		"pop up description layer",
		"</div>\n";
	print "<div id=\"object2\" ",
		"style=\"filter:alpha(opacity=5);-moz-opacity:0.05;",
		"position:absolute;background-color:FFFFDD;",
		"color:black;border-color:black;border-width:1;",
		"left:0px;top:0px;z-index:2;\">",
		"</div>\n";
	print "<CENTER>\n";
	print "<NOSCRIPT>\n";
	print "<BLINK>\n";
	print "<HR>\n";
	print "<B>\n";
	print "This application requires a browser with JavaScript enabled\n";
	print "<BR>\n";
	print "Please enable Javascript, and try again\n";
	print "</B>\n";
	print "<BR>\n";
	print "<HR>\n";
	print "</BLINK>\n";
	print "<A HREF=about:blank>\n";
	print "<IMG SRC=${a_image_dir}/empty.gif HEIGHT=1000 ";
	print "WIDTH=1000 BORDER=0 ALT=\"Oops\"></A>\n";
	print "</NOSCRIPT>\n\n\n";
	print "</CENTER>\n";
	print "\n\n";
	
	print "<SCRIPT LANGUAGE=JavaScript>\n";
	print "SetCookie('screen_width',screen.availWidth,'',7776000000);\n";
	print "SetCookie('screen_height',screen.availHeight,'',7776000000);\n";
	print "</SCRIPT>\n";

        $saw=$q->cookie(-name=>'screen_width');
        $sah=$q->cookie(-name=>'screen_height');

	$try_saw=$q->cookie(-name=>'max_screen_width');
	if ($try_saw ne "") {
		$saw=$try_saw;
	}
	$try_sah=$q->cookie(-name=>'max_screen_height');
	if ($try_sah ne "") {
		$sah=$try_sah;
	}

	print "<SCRIPT LANGUAGE=JavaScript>\n";
	if ($saw eq '') {
		print "var saw=screen.availWidth;";
	} else {
		print "var saw=$saw;";
	}
	if ($sah eq '') {
		print "var sah=screen.availHeight;";
	} else {
		print "var sah=$sah;";
	}
	print "</SCRIPT>\n";
}

sub body {
	print "<BODY LINK=#3300FF ALINK=#3300FF VLINK=#3300FF ";
	print "BACKGROUND=../images/backdrop.png ";
	print "BGCOLOR=#f2f2f2 ";
	print ">\n";
}

sub footer {
	print $q->p;
	print "\n";
	print "<TABLE CELLPADDING=0>\n";
	print "<TR>\n";
	print "<TD CLASS=BODY><FONT SIZE=2>Written in Perl and Javascript by: ";
	print "<A HREF=\"mailto:paul_de_nijs\@yahoo.com\">Paul de Nijs</A> ";
	print "&nbsp;&nbsp;&nbsp;Powered by:";
	print "</FONT></TD>\n";
	print "<TD CLASS=BODY>";
	print "<IMG SRC='../images/mysql-logo.png' WIDTH=40>";

	print "</TD>\n";
	print "</TR>\n";
	print "</TABLE>\n";
}


sub check_admin {
	#check if user is a admin user, if not, deny access here ...
	if ($username ne "admin") {
		&header("Permission Check");
		print "
		<SCRIPT language=javascript>
		var msg = \"\\n\";
		msg += \"This function is restricted to \";
		msg += \"administrative users.\\n\";
		msg += \"Access denied !\\n\";
		msg += \"Please login as: admin\";
		alert(msg);
		gotoSite(\"./$my_own_url\");
		</SCRIPT>
		";
		exit;
	}
}

sub get_passwd {
	my $prog_title="Login";
	&header($VERSION . " on " . $this_hostname . " - " . $prog_title);
	&show_head($prog_title);
	print "<BR>\n";

	# delete cookie 'ipmanageID' and 'totd' (tip of the day);
	print "<SCRIPT language=javascript>\n";
	print "DelCookie('ipmanageID');";
	print "DelCookie('totd');";
	print "</SCRIPT>\n";

	$login_expired=$_[0];
	$login_input=$username;
	$try_cookie=$q->cookie(-name=>scramble);
	if ($try_cookie ne "") {
		if (crypt("1",$try_cookie) eq $try_cookie) {
			$last_try=1;
		} elsif (crypt("2",$try_cookie) eq $try_cookie) {
			$last_try=2;
		} elsif (crypt("3",$try_cookie) eq $try_cookie) {
			$last_try=3;
		} else {
			$last_try=4;
		}
	}
	$last_try=$last_try+0;
	if ($last_try > 2) {
		print "<SCRIPT language=javascript>\n";
		print "var msg=\"Too many failed login attempts, \\n\";";
		print "msg+=\"Try Again later!\";";
		print "alert(msg);";
		print "window.close();\n";
		print "</SCRIPT\n";
	}

	print $q->start_form(-name=>'LoginForm');
	print $q->start_html(-title=>'Authentication Request');
	print $q->start_center();
	print $q->p;
	if ($login_expired == 1) {
		print "Your login validation has expired,";
		print " please login again<BR>";
	}
	print "<FONT FACE=\"Arial, Helvetica, sans-serif\" SIZE=2>";
	print "<FONT COLOR=#003366 SIZE=5>";
	print "<B>Welcome to ${VERSION}";
	print "</B></FONT>";
	print $q->p;

	print $q->start_table({-border=>0,-cellpadding=>5,-align=>center,-class=>BODYt}),"\n";
	print "<TR>\n";
	if (open (TXT,"$INSTALLDIR/files/logintext")) {
		my @text=<TXT>;
		close TXT;
		print @text;
	}
	print "</TR>\n";
	print "<TR>\n";
	print "<TD COLSPAN=4 ALIGN=CENTER CLASS=BODYt>\n";
	print "&nbsp";
	print "</TD>\n";
	print "</TR>\n";

	print "<TR>\n";
	print "<TD CLASS=BODYt>&nbsp;&nbsp;&nbsp;</TD>";
	print "<TD CLASS=BODYt ALIGN=RIGHT>Username: </TD>\n";
	print "<TD CLASS=BODYt>\n";
	print $q->textfield(
		-name=>'login_input', 
		-value=>$login_input,
		-size=>'10', 
		-maxlength=>'10',
		),"\n";
	print "</TD>\n";
	print "<TD CLASS=BODYt>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</TD>";
	print "</TR>\n";

	print "<TR>\n";
	print "<TD CLASS=BODYt>&nbsp;&nbsp;&nbsp;</TD>";
	print "<TD ALIGN=RIGHT CLASS=BODYt>Password: </TD>\n";
	print "<TD CLASS=BODYt>\n";
	print $q->password_field(
		-name=>'passwd_input', 
		-value=>$passwd_input,
		-size=>'10', 
		-maxlength=>'10',
		-onBlur=>"document.LoginForm.action.value='LOGIN';
			document.LoginForm.submit();",
		),"\n";

	print "</TD>\n";
	print "<TD CLASS=BODYt>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</TD>";
	print "</TR>\n";
	print "</FONT></FONT>\n";

	print "<TR>\n";
	print "<TD COLSPAN=4 ALIGN=CENTER CLASS=BODYt>\n";
	print $q->hidden('passwd_input',$passwd_input);
	print $q->hidden('caller',$caller);
	print $q->submit(
		-name=>'action', 
		-value=>'LOGIN',
		-class=>button,
		),"\n";
	print $q->button(
		-name=>'action', 
		-value=>'Cancel', 
		-onClick=>"history.back()",
		-class=>button,
		),"\n";
	print "</TD>\n";
	print "</TR>\n";

	print "<TR>\n";
	print "<TD COLSPAN=4 ALIGN=CENTER CLASS=BODYt>\n";
	print "&nbsp";
	print "</TD>\n";
	print "</TR>\n";

	print $q->end_table(),"\n";;

	print $q->p;
	if ($Message_text ne "") {
		print "$Message_text";
	}
	print $q->p;
}

sub logout {
	my $prog_title="Logout";
	&header($VERSION . " on " . $this_hostname . " - " . $prog_title);
	&show_head($prog_title);
	print "<BR>\n";

	# cookie name=$cookie_id2
	# cookie value='not_valid'
	# cookie path=$pathinfo
	# cookie expires=$cookie_expiration2 (ms)

	print "<SCRIPT language=javascript>\n";
	print "SetCookie('$cookie_id2','not_valid',
		'$pathinfo',$cookie_expiration2);";
	print "</SCRIPT>";

	print $q->start_center();
	print "Thank you for using $VERSION<BR>";
	print "Logged out as: ",$username,"<BR>";
	print $q->start_form();
	print $q->hidden('username','');
	print $q->hidden('caller',$caller);
	print $q->hidden('oldparams',$oldparams);
	print $q->p;
	print $q->button(
		-name=>'action', 
		-value=>'Log in as a different user', 
		-onClick=>"gotoSite('$caller');",
		-class=>button,
		),"\n";
	print $q->end_form();
}


sub check_passwd {
	my $pwd="RuBbIsH";
	my $supwd="RuBbIsH";
	my $registrarpwd="RuBbIsH";
	my $user_found=0;
	my $ts_deny_found=0;
	my $su_user_found=0;
	my $registrar_found=0;

	open(SESAME, $passwd_file) or die "Can't open \"$passwd_file\": $!\n";
	my @passwd_data= <SESAME>;
	close(SESAME);

	my @users_file;
	foreach my $fp (@passwd_data) {
		chomp $fp;
		next if ($fp =~ /^#/);
		my ($login, $passwd, $name)=split(/:/,$fp);
		push @users_file, [$login, $passwd];
	}
	# now open the users database
	my $cmd="SELECT login,passwd FROM ipmanage_users ORDER BY login";
	my @users_database=&select_array($cmd);

	# get passwd from whatever password services as well.
	# note that if the user is in the LOCAL password file, it can't read the password, 
	# since it's in the /etc/shadow file, and the password will be "x"
	# this is just a backup if the password in the database is outdated !!!!
	$pwd2="x";

	######## All users who can log in have access! ###############
	# let's say that everybody has access ...
	my ($al_name,$al_passwd,$al_uid,$al_gid,$al_quota,$al_comment,$al_gcos,$al_dir,$al_shell)=getpwnam($login_input);
	if ($al_name ne '') {
		$pwd2=$al_passwd;
		$user_found=1;
	}
	######## END All users who can log in have access! ###############

	foreach my $i (@users_database,@users_file) {
		my ($login, $passwd)=@$i;
		if ($login eq $login_input) {
			$pwd=$passwd;
			my ($l_name,$l_passwd,$l_uid,$l_gid,$l_quota,$l_comment,$l_gcos,$l_dir,$l_shell)=getpwnam($login_input);
			$pwd2=$l_passwd;
			$user_found=1;
		}
		# get the super user (admin) password, if you have that,
		# you are allowed to login as any person
		if ($login eq "admin") {
			$supwd=$passwd;
			$su_user_found=1;
		}
		if ($user_found && $su_user_found) {last;}
	}

	if ($login_input eq "") {
		&get_passwd(0);
		exit;
	}	
	if ($passwd_input eq "") {
		&get_passwd(0);
		exit;
	}

	my $encrypted_passwd=crypt($passwd_input, substr($pwd,0,11));
	my $encrypted_passwd2=crypt($passwd_input, substr($pwd2,0,11));
	my $su_encrypted_passwd=crypt($passwd_input, substr($supwd,0,11));
	print STDERR "[\$encrypted_passwd=$$encrypted_passwd, \$encrypted_passwd2=$encrypted_passwd2, \$su_encrypted_passwd=$su_encrypted_passwd\n";

	if (!$user_found) {
		$pwd="";
		$pwd2="";
	}

	$ok_2_continue=0;

	# print STDERR "[$encrypted_passwd]", length($encrypted_passwd),"\n";
	# print STDERR "[$pwd]", length($pwd),"\n";
	# print STDERR "[$encrypted_passwd2]", length($encrypted_passwd2),"\n";
	# print STDERR "[$pwd2]", length($pwd2),"\n";
	# print STDERR "[$su_encrypted_passwd]", length($su_encrypted_passwd),"\n";
	# print STDERR "[$supwd]", length($supwd),"\n";

	if ($su_encrypted_passwd eq $supwd) {
		$ok_2_continue=1;
	} else {
		if ($encrypted_passwd eq $pwd and $pwd ne "") {
			$ok_2_continue=1;
		}
		if ( $encrypted_passwd2 eq $pwd2 and $pwd2 ne "") {
			$ok_2_continue=2;
		}
	}

	if ($ok_2_continue) {
		my $crypt_value=crypt($login_input,rand 99);
		my $prog_title="Permission Granted";
		my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime(time);
		$mon=$mon+1;
		$year=$year+1900;
		my $date=sprintf("%04d-%02d-%02d %02d:%02d",$year,$mon,$mday,$hour,$min);
		print STDERR "Permission granted for $login_input at: $date from $ENV{'REMOTE_ADDR'}\n";
		if ($encrypted_passwd eq $pwd and $pwd ne "") {
			print STDERR "NOTE: used password from database for user: $login_input\n"; 
		}
		if ($encrypted_passwd2 eq $pwd2 and $pwd2 ne "") {
			print STDERR "NOTE: used password from network password services for user: $login_input\n"; 
		}
		if ($su_encrypted_passwd eq $supwd and $login_input ne "admin") {
			print STDERR "NOTE: used admin password for user: $login_input\n"; 
		}
		&header($VERSION . " on " . $this_hostname . " - " . $prog_title);
		&show_head($prog_title);
		print "<BR>\n";

		# create an ipmanageid
		my $ipmanageid=&myrandom;
		# now delete all users that actually do not exist anymore
		# that are the users that are in th etable "users" with a 
		# timestamp <= NOW() - update_refreshrate in seconds
		if ($ENV{'HTTP_CLIENT_IP'} eq "") {
			$remote_address=$ENV{'REMOTE_ADDR'};
		} else {
			$remote_address=$ENV{'HTTP_CLIENT_IP'};
		}
		my $cmd="";
		$cmd="INSERT INTO ipmanage_usercount (ipmanageID,login,remote_address) " .
			"VALUES('$ipmanageid','$login_input','$remote_address')";
		$dbh->do($cmd);
		my $now=&select1("SELECT NOW() + 0");
		my $expired=&select1("SELECT DATE_SUB(NOW()+0, INTERVAL $update_refreshrate SECOND)+0");
		$cmd="DELETE FROM ipmanage_usercount WHERE timestamp <= $expired ";
		&do_row($cmd);

		# now get all users (including "me") and store them in a 
		# variable $ipmanage_users, "|" seperated
		my $ipmanage_users="";
		$cmd="SELECT ipmanageID FROM ipmanage_usercount";
		foreach my $user (&select_array($cmd)) {
			my ($id)=@$user;
			$ipmanage_users.="$id|";
		}
		$ipmanage_users=~s/\|$//;
		
		print "<SCRIPT language=javascript>\n";
		print "SetCookie('$cookie_id1','$login_input', '$pathinfo',$cookie_expiration1);";
		print "SetCookie('$cookie_id2','$crypt_value', '$pathinfo',$cookie_expiration2);";
		print "SetCookie('scramble','$try_cookie', '$pathinfo',-1);";
		print "SetCookie('ipmanageID','$ipmanageid', '',$cookie_expiration1);";
		print "SetCookie('ipmanage_users','$ipmanage_users', '',$cookie_expiration1);";
		print "</SCRIPT>";

		print $q->start_center();
		print "<BR>";
		print "Permission granted!<BR>";
		print "Logged in as: $login_input<BR>";
		print $q->start_form(-name=>'ok');

		print "<BR><BR>";
		print $q->hidden('caller',$caller);
		print $q->button(
			-name=>'action', 
			-value=>'Continue',
			-onclick=>"gotoSite('$caller');",
			-class=>button,
		),"\n";

		if ($login_input eq "admin" and ! $ipmanage_auto_updates) {
			print "<BR><BR>Note: ",
				"Automatic Updates are disabled<BR>";
		}

		if ($login_input eq "admin" and $ipmanage_auto_updates) {
			#check for updates if username = admin
			&wait_start('update_check',
				'Checking for ipmanage updates, please wait');
			$update_check_result=&check_updates_today;
			if ($update_check_result==-1) {
				# skipping update
				&wait_end('update_check');
			} elsif ($update_check_result==0) {
				# update check failed
				&wait_end('update_check');
				print "<BR><BR>";
				print "<BLINK><FONT COLOR=#ff0000>";
				print "Update check failed (Cannot contact the update server)!<BR>";
				print "Please contact your system \nadministrator to check the log files.<BR>\n"; 
				print "</FONT></BLINK>";
			} elsif ($update_check_result==1) {
				# update available
				&wait_end('update_check');
				print "<BR><BR><BR><BR>";
				print "<BLINK>";
				print "<SPAN id=updates_available></SPAN>";
				print "</BLINK>";
				print "<SCRIPT language=javascript>\n";
				print "var txt='New Updates are Available! ';";
				print "txt+='(' + document.ok.update_file_timestamp.value + ')';";
				print "change_text_in_id('updates_available', txt,1);";
				print "document.ok.action.value='Continue (without updates)';";
				print "</SCRIPT>";
				print "<BR><BR>";
				print "<div id=install_update_button style=\"display: block;\">";
				print $q->button(
					-name=>'install_update', 
					-value=>'',
					-onclick=>"
						var url='./install_updates.pl';
						var prms='?';
						prms+='&url_update_file=';
						prms+=document.ok.update_file.value;
						prms+='&webuser=';
						prms+=document.ok.webuser.value;
						prms+='&webgroup=';
						prms+=document.ok.webgroup.value;
						prms+='&timestamp=';
						prms+=document.ok.update_file_timestamp.value;
						url+=prms;
						url+='#BOTTOM';

						SizedNewWindow(url,'install_updates',800,950);
						install_update_button.style.display='none';
						updates_available.style.display='none';
						document.ok.action.value='Continue';
						
					",
					-class=>button,
				),"\n";
				print "<div>";
				print "<SCRIPT language=javascript>\n";
				print "var btxt='Install Update ';";
				print "btxt+=document.ok.update_file_timestamp.value;";
				print "document.ok.install_update.value=btxt;";
				
				print "</SCRIPT>";
				print "<BR>";
			} elsif ($update_check_result==2) {
				# no new updates
				&wait_end('update_check');
				print "<BR><BR>";
				print "Note: No new updates available<BR>";
			} elsif ($update_check_result==1000) {
				&wait_end('update_check');
				print "<BR><BR>";
				print "<BLINK><FONT COLOR=#ff0000>";
				print "Update check failed ",
					"(undefined failure)!<BR>";
				print "Please contact your system \n", 
					"administrator to check ",
					"the log files.<BR>\n"; 
				print "</FONT></BLINK>";
			} else {
				&wait_end('update_check');
			}
		}
		# submit form when return key is pressed (netscape7)
		print "<SCRIPT LANGUAGE=javascript>";
		print "document.ok.action.focus();";
		print "</SCRIPT>";
		print $q->end_form();
	} else {
		my $prog_title="Authentication Failed";
		&header($VERSION . " on " . $this_hostname . " - " . 
				$prog_title);
		&show_head($prog_title);
		print "<BR>\n";
		my $last_try_c=$q->cookie(-name=>scramble);
		if ($last_try_c eq "") {
			$last_try=0;
		} else {
			if (crypt(1,$last_try_c) eq $last_try_c) {
				$last_try=1;
			} elsif (crypt(2,$last_try_c) eq $last_try_c) {
				$last_try=2;
			} elsif (crypt(3,$last_try_c) eq $last_try_c) {
				$last_try=3;
			} else {
				$last_try=3;
			}
		}
		$last_try=$last_try+0;
		$last_try++;

		$try_cookie=crypt($last_try,rand 99);
		print "<SCRIPT language=javascript>\n";
		print "SetCookie('scramble','$try_cookie','$pathinfo',36000000);";
		print "</SCRIPT>";
		
		print $q->start_center();
		if ($restricted_access) {
			print "<H2>Wrong Password</H2><BR>",
				"OR<BR>you do not have access ",
				"to this application<BR>";
			print $q->p,"\n";
			### print "<IMG SRC='../images/asterix_avec_glaive.jpg' BORDER=0>";
			### print $q->p,"\n";
		} else {
			print "<H2>Wrong Password</H2><BR>";
			print $q->p,"\n";
			### print "<IMG SRC='../images/asterix_avec_glaive.jpg' BORDER=0>";
			### print $q->p,"\n";
		}
		print $q->p;
		print $q->start_form();
		print $q->hidden('caller',$caller);
		print $q->hidden('oldparams',$oldparams);
		print $q->submit(-name=>'action', 
			-class=>button,
			-value=>'Try Again');
		print $q->button(
			-name=>'action', 
			-value=>'Cancel', 
			-class=>button,
			-onClick=>"window.close()",
			),"\n";
		print $q->end_form();
	}
}

sub check_cookies {
	my ($username)=@_;
	if (%cookies) {
		my $cookie=$q->cookie(-name=>$cookie_id2);
		if (crypt($username,$cookie) eq $cookie and $cookie ne "") {
			return(1);
		} else { 
			return(0);
		}
	} else {
		return(0);
	}
}


sub userpass_crypt {
	my ($str)=@_;

	my $chstr="";
	my $strinhex="";

	# random shift number 32-64
        my $s=int(rand(32))+32;
	my $shiftinhex=sprintf("%02x",$s);
	
	# length of the string in hex + the random shift nr
	my $lengthinhex=sprintf("%02x",length($str)+$s);

	for ($i=0;$i<length($str);$i++) {
		my $c=substr($str,$i,1);
		# add random shift number to the character
		my $d=unpack(c,$c)+$s;
		my $h=sprintf("%02x",$d);
		$strinhex.=$h;
		# reverse the string
		$chstr=$h . $chstr;
	}
	# now add bogus hex numbers to the end of the string to make it
	# 64 characters 
	my $fillstr="";
	for ($i=length($str);$i<30;$i++) {
		my $r=int(rand(96))+32+$s;
		my $rh=sprintf("%02x",$r);
		$fillstr.=$rh;
	}
	# add the length of the original string in hex to the beginning
	$chstr=$lengthinhex . $chstr . $fillstr;

	# now get the whole string and swap all the nibbles
	my $saved=$shiftinhex;
	for ($i=0;$i<length($chstr);$i++) {
		$saved.=substr($chstr,$i+1,1);
		$saved.=substr($chstr,$i,1);
		$i++;
	}
	return ($saved);
}

sub userpass_decrypt {
	my ($str)=@_;
	my @crypt_array;
	
	# retrieve the shiftnr from the string and convert to a integer
	my $s=hex(substr($str,0,2));
	# retrieve the length of the original string, and convert to a
	# integer
	my $linhex=substr($str,3,1);
	$linhex.=substr($str,2,1);
	my $l=hex($linhex)-$s;

	my $j=0;
	my $crypted_string=substr($str,4,length($str)-4);
	for ($i=0;$i<length($crypted_string);$i++) {
		if ($i%2==0) {
			my $hn=substr($crypted_string,$i+1,1);
			my $ln=substr($crypted_string,$i,1);
			my $chinhex=$hn . $ln;
			$ascii_int=hex($chinhex)-$s;
			$crypt_array[$j++]=chr($ascii_int);
		}
	}

	my $uncrypted_string="";
	for ($i=$l-1;$i>-1;$i--) {
		$uncrypted_string.=$crypt_array[$i];
	}
	return($uncrypted_string);
}

sub show_hostname_in_background {
	return if ($this_hostname eq "");
	# fill the background with the hostname of this server ....
	# we have to know the size of the screen, and we do!
	# the font size is fixed (40pt) so we calculate with that.
	my $cs=40;
	my $tl=length($this_hostname)+3;
	my $px=0;my $py=0;
	my $mpy=600;
	my $mpx=800;
	for (my $y=0,$py=0;$py<$mpy;$y++) {
		if ($y%2==1) {
			for (my $x=0,$px=0;$px<$mpx;$x++) {
			$px=$x*$tl*$cs+int(rand(5)*10);
			print "<div style=\"top:${py}px;left:${px}px; position: fixed; font-size: ${cs}pt; color: #e8e8e8; z-index:+0;\">$this_hostname</div>\n";
			}
		} else {
			for (my $x=0,$px=0;$px<$mpx;$x++) {
			$px=$x*$tl*$cs-($cs*$tl)/2+int(rand(5)*10);
			print "<div style=\"top:${py}px;left:${px}px; position: fixed; font-size: ${cs}pt; color: #e8e8e8; z-index:+0;\">$this_hostname</div>\n";
			}
		}
		$py+=70;
	}

}


sub string_to_urlstring {
	# converts a string with weird characters to a string with the hex value for a url
	# like "--Perl[--" -> "%2D%2DPerl%5B%2D%2D"
	# reversed function of urlstring_to_string
	my ($str)=@_;
	$str=~ s/\W/'%' . uc(unpack(H2,$&))/eg;
	return $str;
}

sub urlstring_to_string {
	# converts a string with weird characters to a string with the hex value for a url
	# like "%2D%2DPerl%5B%2D%2D" -> "--Perl[--"
	# reversed function of string_to_urlstring
	my ($str)=@_;
	$str =~ s/(%)(..)/pack(H2,$2)/eg;
	return $str;
}

sub js_include {
	my ($js)=@_;

	# this routine does something like :
	# print "<SCRIPT LANGUAGE=JavaScript SRC=$js?v=20130101120000></SCRIPT>\n";
	# It will look at the timestamp of the javascript first, and give it a version. 
	# This means that the browser cache will not load 'old' files, and the newest javascript will be used!

	# Make sure that the file is always relative to the calling program, in HTML and in the OS!
	# something like '&js_include('../javascript/common.js')

	my $version=&file_mtime($js);
	print "<SCRIPT LANGUAGE=JavaScript SRC='", $js, "?v=", $version, "' ></SCRIPT>\n";
}

sub css_include {
	my ($css)=@_;

	# this routine does something like :
	# print "<LINK REL=stylesheet HREF='$css?v=20130101120000' TYPE=text/css />\n";
	# It will look at the timestamp of the javascript first, and give it a version. 
	# This means that the browser cache will not load 'old' files, and the newest javascript will be used!

	my $version=&file_mtime($js);
	print "<LINK REL=stylesheet TYPE=text/css HREF='$css?v=20130101120000' />\n";
}


sub file_mtime {
	# returns the last modify time of a file
	# in the form: YYYYMMDDHHmmss (year month dat hour minute seconds)
	my ($file)=@_;

	# get all status from the file
	my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks)=stat($file);

	# nov convert $mtime to YYYYMMDDHHmmss
	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime($mtime);
        $mon=$mon+1;
        $year=$year+1900;
        $s=sprintf("%04d%02d%02d%02d%02d%02d",$year,$mon,$mday,$hour,$min,$sec);
        return ($s);
}

sub date_and_time_stamp_int {
	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime(time);
	$mon=$mon+1;
	$year=$year+1900;
	my $date=sprintf("%04d%02d%02d%02d%02d%02d",$year,$mon,$mday,$hour,$min,$sec);
	return $date;
}


sub simple_page_refresh {
	# call this function AFTER the $q->start_form(-name=>'bla') 
	# also ANY call to ./ipmanage_check_db_updates.pl should have the parameter 
	# &form=bla 
	# as well, like:

	# function js_check_updates() {
	# 	// alert('loading page');
	#	document.getElementById('refresh_frame').src='./ipmanage_check_db_updates.pl?&form=bla';
	# }
	
	print "<DIV STYLE='display:none'>\n";
	print $q->submit(
		-name=>hidden_refresh,
		-value=>'Hidden_Refresh',
	),"\n";
	my $now=&date_and_time_stamp_int;
	print $q->textfield(-name=>now, value=>$now, -override=>1, -size=>14),"\n";
	print "<IFRAME ID=refresh_frame NAME=check_refresh SRC=''></IFRAME>\n";
	print "</DIV>\n";
}
	

sub iso {
	# converts strange characters to be displayed in HTML
	# a " will be converted to &#34;
	# a ' will be converted to &#39; ...
	my ($str)=@_;
	my (@s)=split "", $str;
	my $ret_str="";
	foreach my $i (@s) {
		if ($i !~ /[0-9A-Za-z]/) {
			# replace strange character for HTML
			my $num_entry=unpack "c", $i;
			$ret_str.="\&#" . $num_entry . ";";
		} else {
			$ret_str.=$i;
		}
	}
	return $ret_str;
}

1;
