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
use ipmanage_iphosts_search;
use sql;

$ENV{PATH}="/usr/sbin:/usr/bin:";
$ENV{ENV}="";

$action=		$q->param('action');
$network=		$q->param('network');		# make sure this is a hidden field 
$bitmask=		$q->param('bitmask');		# make sure this is a hidden field
$page=			$q->param('page');		# Pages are in multiple of 256 otherwise they take too long to load     
$anchor=		$q->param('anchor');		# checkboxes will set the anchor, so after a edit, go back to the first last selected item

$page=0 if ($page eq '');
$anchor=0 if ($anchor eq '');

#edits, deletes etc
$ips_selected=		$q->param('ips_selected');		# just a list of networks (comma seperated) that were selected with the checkbox;
# edits only
@ip=			$q->param('ip');
@hostname=		$q->param('hostname');
@confirm_duplicate=	$q->param('confirm_duplicate');
@aliases=		$q->param('aliases');
@comment=		$q->param('comment');

# we will use this for the textfield sizes...
$max_hostname_length=0;
$max_aliases_length=0;
$max_comment_length=0;

# simple search
$search_flag=		$q->param('search_flag');
$searchstring=		$q->param('searchstring');
$advancedsearchflag=	$q->param('advancedsearchflag');

# advanced search ...
$action2=     		$q->param('action2');
@field=			$q->param('field');
@selection=		$q->param('selection');
@fieldvalue=		$q->param('fieldvalue');
@andor=			$q->param('andor');
@bracketopen=		$q->param('bracketopen');
@bracketclose=		$q->param('bracketclose');
$nrfields=		$q->param('nrfields');
$whereclause=		$q->param('whereclause');

# extra actions
$order_by=		$q->param('order_by');

if ($debug) {
	print STDERR "================= PARAMETERS ($my_own_url)====================\n";
	foreach my $key ($q->param()) {
		print STDERR "key:" , $key , ",value:" ,$q->param($key),"\n";
	}
	print STDERR "================= END PARAMETERS ====================\n";
}


$this_hostname=         `/bin/hostname`;
chomp $this_hostname;

$network_dotted=&convert_dec2ip($network);

my $prog_title="Network: " . $network_dotted . "/" . $bitmask;
&header($VERSION . " on " . $this_hostname . " - " . $prog_title);
&js_include('../javascript/StickyTableHeaders.js');

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

# make sure we can reference this as an array with length, if we have only 1 network entry
# show all the networks. Since we don't know what the heck we are going to need, just stuff them in a hash ...
$network_hash=&create_network_hash; 		### network hash has ALL the network information from the database!!!
# see if we are allowed to change this record!
$user_allowed=0;
foreach my $o ('admin','root',(split /\s+/,$network_hash->{$network}->{owners}),$network_hash->{$network}->{modifier}) {
	if ($o eq $remote_user) {
		$user_allowed++;
		last;
	}
}

$FORMNAME="network";
print $q->start_form(-name=>$FORMNAME),"\n";
### make sure we know which network/bitmask are working with when we submit or refresh etc ... 
print $q->hidden(-name=>'network',-value=>$network,-override=>1),"\n";	
print $q->hidden(-name=>'bitmask',-value=>$bitmask,-override=>1),"\n";	
print $q->hidden(-name=>'anchor',-value=>$anchor,-override=>1),"\n";	
print $q->hidden(-name=>'search_flag',-value=>$search_flag,-override=>1),"\n";	

# search stuff
if ($advancedsearchflag eq "yes") {
	print $q->hidden(-name=>'action2', -value=>'submitadvancedsearch', -override=>1),"\n";
} else {
	# print $q->hidden(-name=>'action2', -value=>'', -override=>1),"\n";
	### changed because the sort should remember what it was (reg or simple search)
	print $q->hidden(-name=>'action2', -value=>$action2, -override=>1),"\n";
}
print $q->hidden(-name=>'advancedsearchflag',-value=>$advancedsearchflag, -override=>1),"\n";
print $q->hidden(-name=>nrfields,-value=>$nrfields,-override=>1),"\n";
# end search stuff

$duplicate_oops=0;

&simple_page_refresh();

sub normal_sort {
	my ($field,$FORM)=@_;
	print "<IMG SRC=../images/down.gif name=dummy ";
	if ($order_by eq $field) {
		print "style='border:1px solid #0000ff;' ";
	}
	print "ONCLICK='document.$FORM.order_by.value=\"$field\"; document.$FORM.submit();' ";
	print "ONMOUSEOVER=\"balloon_popLayer(this,'Sort column');\" ";
	print "ONMOUSEOUT=\"balloon_hideLayer();\" ";
	print ">&nbsp;";
}
		
sub reversed_sort {
	my ($field,$FORM)=@_;
	print "&nbsp";
	print "<IMG SRC=../images/up.gif name=dummy ";
	if ($order_by eq $field) {
		print "style='border:1px solid #0000ff;' ";
	}
	print "ONCLICK='document.$FORM.order_by.value=\"$field\"; document.$FORM.submit();' ";
	print "ONMOUSEOVER=\"balloon_popLayer(this,'Sort column in REVERSED order');\" ";
	print "ONMOUSEOUT=\"balloon_hideLayer();\" ";
	print ">";
}

sub ip_hash_sort {
	# since we can't sort with that database, because we use a hash
	# this will sort the hash on the existing fields
        my ($hash,$orderby)=@_;
        my ($field,$direction)=split /\s+/,lc($orderby);

	if ($field eq '') {
		$field='ip';
		$direction='';
	} 

        if ($field eq 'hostname' or $field eq 'aliases' or $field eq 'comment') {
                if ($direction eq 'desc') {
                        return sort {$hash->{$b}->{$field} cmp $hash->{$a}->{$field}} keys %{$hash};
                } else {
                        return sort {$hash->{$a}->{$field} cmp $hash->{$b}->{$field}} keys %{$hash};
                }
        } else {
                if ($direction eq 'desc') {
                        return sort {lc($hash->{$b}->{$field}) <=> lc($hash->{$a}->{$field})} keys %{$hash};
                } else {
                        return sort {lc($hash->{$a}->{$field}) <=> lc($hash->{$b}->{$field})} keys %{$hash};
                }
        }
}

sub check_network_modify_permissions {
	# this checks if the current user is allowed to modify this ip address entry by checking the network modify permissions.
	# returns 1 (true) if allowed, 0 by default ..
	my ($ip2check)=@_;
	foreach my $nw (keys %{$network_hash}) {
		if ($ip2check >= $network_hash->{$nw}->{network} and $ip2check <= $network_hash->{$nw}->{broadcast}) {
			# ah, the ip address is in this network!!!
			foreach my $o ('admin','root',(split /\s+/,$network_hash->{$nw}->{owners}),$network_hash->{$nw}->{modifier}) {
				if ($o eq $remote_user) {
					return(1);
				}
			}
			return(0);
		}
	}
	return(0);
}
		

sub save_changes {
	print STDERR "Saving changes for ip addresses: $ips_selected\n";
	my $err_file=&tmpfile_pre_post("duplicate_check_",".err");
	my @ips=split /,/,$ips_selected;
	for my $i (0 .. $#ips) {
		next if ($hostname[$i] eq '');
		my $force='';
		if ($confirm_duplicate[$i] eq 'on') {
			$force="-f"; 
		}
		my $cmd="../bin/ipmanage_ip.pl $force -Z $remote_user -n \"$hostname[$i]\" -A \"$aliases[$i]\" -c \"$comment[$i]\" $ip[$i] >>$err_file";
		print STDERR "$cmd\n";
		my $status=system($cmd);
		$status&=0xffff;
		$duplicate_oops++ if($status != 0);
	}
	if ($duplicate_oops) {
		open(ERR,"$err_file");
		my @data=<ERR>;
		close ERR;
		my $str=join('',@data);
		$str=~s/\n/\\n/g;
		unlink $err_file;
		print "<SCRIPT LANGUAGE=javascript>";
		print "alert(\"",  $str, "\");";
		print "</SCRIPT>";
		return(1);
	}
	return(0);
}

sub delete_selected_ips {
	print STDERR "Deleting ips: $ips_selected\n";
	foreach my $e (split /,/,$ips_selected) {
		my $ip_dotted=&convert_dec2ip($e);
		my $cmd="../bin/ipmanage_ip.pl -Z $remote_user -d $ip_dotted";
		print STDERR "$cmd\n";
		system($cmd);
	}
}

sub ping_selected_ips {
	print STDERR "Ping networks: $ps_selected\n";
	my $cmd="../bin/ipmanage_ping.pl -i $ips_selected &"; 
	$dbh->disconnect();

	my $total_time_to_run=0;
	$total_time_to_run+=$ping_timeout + 1;
	my $msg="Program will take at least $total_time_to_run seconds to run.\\n";
	$msg.="It will run in the background. Your screen will refresh when done.\\n";

	if ($pid = fork) {
		print "<SCRIPT language=javascript>\n";
		print "alert('$msg')\n";
		print "</SCRIPT>\n";
	} else {
		close (STDOUT);
		system($cmd);
		exit 0;
	}
	$dbh=DBI->connect($dsn,$dbuser,$dbpasswd);
}

sub show_ips {
	$sql_cmd='';
	my $this_start=0;
	my $this_end=0;
	my @pagevalues=();
	my %pagelabels=();

	my @restricted_ip=();

	# create an IFRAME to run a cgi script in (it could be anything)
	print "<IFRAME STYLE='display:none' ID='hidden_cgi' NAME='hidden_cgi' SRC=''></IFRAME>\n";

	my ($duplicates_byname_hash,$duplicates_byip_hash)=&create_duplicate_hashes();

	$select_multi_checkboxes_help="To select multiple boxes, click the first selection (checked or unchecked).<BR> " .
		"Hold the Shift-Key and click the last box. The range will follow the red (last) bordered checkbox selection";

	if ($search_flag) {
		### in search mode, different query to start with ...
		&build_whereclause_var;
		$sql_cmd=&build_show_query;
		my $restricted_sql="
			SELECT ip 
			FROM ip_hosts_restricted 
		 	ORDER BY ip
		 	;";
		@restricted_ip=&select_1dim_array($restricted_sql);
	} else {
		my $broadcast=$network_hash->{$network}->{broadcast};
		# Show only 256 ip-addresses in one page. If the network is bigger, then divide it .
		if ($network_hash->{$network}->{nr_ips} > 256) { 			# and really, then it's a multiple of 256 ;-)
			for ($i=0;$i<($network_hash->{$network}->{nr_ips}/256);$i++) {
				push @pagevalues,$i;
				my $r_start=&convert_dec2ip($network_hash->{$network}->{network} + (256 * $i));
				my $r_end=&convert_dec2ip($network_hash->{$network}->{network} + (256 * $i) + 255);
				$pagelabels{$i}="($i) $r_start  -  $r_end";
			}
		}
	
		$this_start=$network_hash->{$network}->{network} + (256 * $page);
		$this_end=$this_start + $network_hash->{$network}->{nr_ips} -1 ;
		if ($network_hash->{$network}->{nr_ips} >=255) {
			$this_end=$this_start + 255;
		}

		my $restricted_sql="
			SELECT ip 
			FROM ip_hosts_restricted 
		 	WHERE ip >= $this_start and ip <= $this_end
		 	ORDER BY ip
		 	;";
		@restricted_ip=&select_1dim_array($restricted_sql);
		@restricted_ip=(@restricted_ip,$network_hash->{$network}->{network},$network_hash->{$network}->{broadcast});

		print STDERR "Restricted:\n";
		foreach my $a (@restricted_ip) {
			print STDERR  "$a ", &convert_dec2ip($a), " \n";
		}
		print STDERR "\n\n";
	
		$sql_cmd="
		 	SELECT ip,hostname,aliases,comment,modified,modifier,DATE_FORMAT(modified,'%d-%b-%Y %H:%i') 
		 	FROM ip_hosts 
		 	WHERE ip >= $this_start and ip <= $this_end
		 	ORDER BY ip
		 	;";
	}
	print STDERR "\$sql_cmd=$sql_cmd\n";

	my @ip_array=();
	@ip_array=select_array($sql_cmd) if ($sql_cmd ne '');

	my $ip_hash;
	my $ping_list='';
	foreach my $e (@ip_array) {
		my ($ip,$hostname,$aliases,$comment,$modified,$modifier,$dfmodified)=@$e;
		$ping_list.=$ip . ",";
		$ip_hash->{$ip}->{ip}=$ip;
		$ip_hash->{$ip}->{ip_dotted}=&convert_dec2ip($ip);
		$ip_hash->{$ip}->{hostname}=$hostname;
		$ip_hash->{$ip}->{aliases}=$aliases;
		$ip_hash->{$ip}->{comment}=$comment;
		$ip_hash->{$ip}->{modified}=$modified;
		$ip_hash->{$ip}->{modifier}=$modifier;
		$ip_hash->{$ip}->{dfmodified}=$dfmodified;
	}

	if (! $search_flag) {
		for (my $k=$this_start;$k<=$this_end;$k++) {
			if (! $ip_hash->{$k}->{ip}) {
				$ip_hash->{$k}->{ip}=$k;
				$ip_hash->{$k}->{ip_dotted}=&convert_dec2ip($k);
			}
		}
	}

	my @ip_ping_array=();
	# the ping status, must be seperate, because it could be that an ip pings but that there is no name !!!
	if ($search_flag) {
		$ping_list=~s/,$//;
		$sql_cmd="
	 	SELECT ip,ping,DATE_FORMAT(modified,'%d-%b-%Y %H:%i')
		 	FROM ipmanage_last_ping_status
			WHERE ip in ($ping_list)
		 	ORDER BY ip
		 	;
		";
		if ($ping_list ne '') {
			# print STDERR "\$sql_cmd=$sql_cmd\n";
			@ip_ping_array=select_array($sql_cmd);
		}
	} else {
		$sql_cmd="
	 	SELECT ip,ping,DATE_FORMAT(modified,'%d-%b-%Y %H:%i')
		 	FROM ipmanage_last_ping_status
			WHERE ip >= $this_start and ip <= $this_end
		 	ORDER BY ip
		 	;
		";
		print STDERR "\$sql_cmd=$sql_cmd\n";
		@ip_ping_array=select_array($sql_cmd);
	}

	my $ip_ping_hash;
	foreach my $e (@ip_ping_array) {
		my ($ip,$ping_status,$modified)=@$e;
		$ip_ping_hash->{$ip}->{ping_status}=$ping_status;
		$ip_ping_hash->{$ip}->{modified}=$modified;
	}

	# create a hash of $ips_selected
	my $ips_selected_hash;
	foreach my $n (split /,/,$ips_selected) {
		$ips_selected_hash->{$n}=1;
	}

	print $q->hidden(-name=>'order_by',-value=>$order_by,-override=>1);
	print $q->hidden(-name=>'ip_checkbox',-value=>'off',-override=>1),"\n";	
	print $q->hidden(-name=>'ips_selected',-value=>$ips_selected,-override=>1),"\n";	

	### the header part, title, login name etc
	print $q->start_center(),"\n";
	print "<DIV id=part1>\n";

	if ($search_flag) {
		$info="Search IP database table";
		if ($#ip_array > -1) {
			$info.=" (" . scalar(@ip_array) . " results)";
		} 
		if ($#ip_array > 1024) {
			print "<SCRIPT language=javascript>";
			print "alert('Number of results > 1024, this may take a while to display');";
			print "</SCRIPT>";
		}
	} else {
		$info=$prog_title . " (" . $network_hash->{$network}->{nr_ips} . " IP-addresses)";
	}
	&show_head($info);
	print "<BR>\n";

	if ($search_flag) {
		&search_screen($FORMNAME);
	} else {
		if ($network_hash->{$network}->{nr_ips} > 256) { 			# and really, then it's a multiple of 256 ;-)
			print "Display Range: ";
			print $q->popup_menu(
				-name=>page,
				-values=>\@pagevalues,
				-labels=>\%pagelabels,
				-default=>$page,
				-onchange=>"
					document.$FORMNAME.submit();
					"
				),"\n";
		}
	}
	print "<BR>\n";
	print "<BR>\n";

	print "<IFRAME ";
	print "name='Duplicate_Hostname_Check' id='Duplicate_Hostname_Check' src='' style='display:none;'>";
	# print "name='Duplicate_Hostname_Check' id='Duplicate_Hostname_Check' src='' style='display:block;'>";
	print "</IFRAME>\n";
	print $q->hidden(-name=>'duplicate_hostname_check_error',-value=>'', -override=>1),"\n";	

	print "</DIV>\n";
	print $q->end_center(),"\n";
	
	### the table part 
	print $q->start_center(),"\n";
	print "<DIV id=mytable style='height:auto;max-height:550px;opacity:0;'>\n";

	print $q->start_table({-id=>ip_table, -cellpadding=>0, -cellspacing=>0, border=>0, }),"\n";

	$arows=0;
	$acols=0;

	# start table1_HeaderCorner (stickey columns are: select,network (and netmask	
	print "<TR>\n";
	print "<TD class='BODYt headercorner_td'>\n";
	print "<DIV id=table1_HeaderCornerDiv>\n";
	print $q->start_table({-class=>iptable, -StickyTableHeaders=>yes, -id=>table1_HeaderCorner, -cellpadding=>0, -cellspacing=>0, -border=>0} ),"\n";
	print "<TR class=table1_r", $arows++, ">\n";
	print "<TH class='wsNoWrap table1_c", $acols++, "'>Select</TH>\n";	 		# Select
	print "<TH class='wsNoWrap table1_c", $acols++, "'>";
	&normal_sort('ip',$FORMNAME) if ($search_flag);
	print "IP";										# host IP
	&reversed_sort('ip DESC',$FORMNAME) if ($search_flag);
	print "</TH>\n";								
	print "<TH class='wsNoWrap table1_c", $acols++, "'><IMG HEIGHT=16 SRC=../images/heartbeat.gif></TH>\n";			# Ping result

	if (! $search_flag) {
		print "<TH class='wsNoWrap table1_c", $acols++, "'>#</TH>\n";			# Host Number in Network
	}
	print "<TH class='wsNoWrap table1_c", $acols++, "'>";
	&normal_sort('hostname',$FORMNAME) if ($search_flag);
	print "Hostname";									# hostname (DNS A-record)
	&reversed_sort('hostname DESC',$FORMNAME) if ($search_flag);
	print "</TH>\n";			
	print "</TR>\n";
	print $q->end_table(),"\n";
	print "</DIV>\n";
	print "</TD>\n";
	### end HeaderCorner

	$arows=0;

	## start table1_HeaderRow
	print "<TD class='BODYt headerrow_td' >\n";
	print "<DIV id=table1_HeaderRowDiv>\n";
	print $q->start_table({-class=>iptable, -StickyTableHeaders=>yes, -id=>table1_HeaderRow, -cellpadding=>0, -cellspacing=>0, border=>0} ),"\n";
	print "<TR class=table1_r", $arows++, ">\n";
	print "<TH class='wsNoWrap table1_c", $acols++, "'>";
	&normal_sort('aliases',$FORMNAME) if ($search_flag);
	print "Aliases";
	&reversed_sort('aliases DESC',$FORMNAME) if ($search_flag);
	print "</TH>\n";
	print "<TH class='wsNoWrap table1_c", $acols++, "'><IMG HEIGHT=16 SRC=../images/copy.gif></TH>\n";
	print "<TH class='wsNoWrap table1_c", $acols++, "'>";
	&normal_sort('comment',$FORMNAME) if ($search_flag);
	print "Comment";
	&reversed_sort('comment DESC',$FORMNAME) if ($search_flag);
	print "</TH>\n";
	print "<TH class='wsNoWrap table1_c", $acols++, "'>";
	&normal_sort('modified',$FORMNAME) if ($search_flag);
	print "Last Modified";
	&reversed_sort('modified DESC',$FORMNAME) if ($search_flag);
	print "</TH>\n";
	print "<TH class='wsNoWrap table1_c", $acols++, "'>";
	&normal_sort('modifier',$FORMNAME) if ($search_flag);
	print "Last Modifier";
	&reversed_sort('modifier DESC',$FORMNAME) if ($search_flag);
	print "</TH>\n";
	print "</TR>\n";
	print $q->end_table(),"\n";             
	print "</DIV>\n";                       
	print "</TD>\n";
	print "</TR>\n";
	## end table1_HeaderRow

	### HeaderColumn
	my $row_count=0;
	$acols=0;					# RESET the $acols, we start at 0 again

	print "<TR>\n";
	print "<TD valign=top class='headercolumn_td'>\n";
	print "<DIV id=table1_HeaderColumnWrapperDiv style='overflow:hidden'>\n";
	print "<DIV id=table1_HeaderColumnDiv>\n";
	print $q->start_table({-class=>iptable, -StickyTableHeaders=>yes, -id=>table1_HeaderColumn, -cellpadding=>0, -cellspacing=>0, -border=>0} ),"\n";

	my $editfield_count=0;
	my $selected_nr=scalar keys %{$ips_selected_hash};

	foreach my $k (ip_hash_sort($ip_hash,$order_by)) {
		if (! $ip_hash->{$k}->{ip}) {
			$ip_hash->{$k}->{ip}=$k;
			$ip_hash->{$k}->{ip_dotted}=&convert_dec2ip($k);
		}
		$max_hostname_length=length($ip_hash->{$k}->{ip_dotted}) if ($max_hostname_length < length($ip_hash->{$k}->{ip_dotted}));  
		$max_aliases_length=length($ip_hash->{$k}->{aliases})    if ($max_aliases_length < length($ip_hash->{$k}->{aliases}));
		$max_comment_length=length($ip_hash->{$k}->{comment})    if ($max_comment_length < length($ip_hash->{$k}->{comment}));

		my $ip_row_id=$k . "_row_id_hc";
		my $ip_checkbox_id=$k . "_checkbox_id"; 
		my $ip_row_name=$k . "_row_name";

		print "<TR class=table1_r", $arows++, " id=$ip_row_id>\n";
		if ($ips_selected_hash->{$k}) {
			($row_count) ? print "<TD class='wsNoWrap ls11px_edit' align=center>" : print "<TD class='table1_c", $acols++, " wsNoWrap ls11px_edit' align=center>";
		} else {
			($row_count) ? print "<TD class='wsNoWrap' align=center>" : print "<TD class='table1_c", $acols++, " wsNoWrap' align=center>";
		}
		
		# place the anchor(the dec ip address), to go back to if you make a change, or if you want to edit something
		print "<A NAME=$k></A>";

		my $nr_checkbox=$row_count+1;

		print "<SPAN style='position:relative;top:-1px; background-color:#777777;' id=span_$nr_checkbox >";
		if ($ips_selected eq '') {
			### if not in search mode the $network is a given
			if ($network_hash->{$network}->{network} == $k or $network_hash->{$network}->{broadcast} == $k) {
				print $q->checkbox(
					-name=>'ip_checkbox',
					-id=>$ip_checkbox_id,
					-label=>'',
					-disabled=>1,
					-class=>checkbox_span,
					-value=>$ip_hash->{$k}->{ip},
					);
			} else {
				if ($search_flag) {
					# bummer! the search result may have resulted in numerous networks, so each ip address 
					# must be checked in which network this is, and if the user is allowed to edit this ip-address!
					if ($remote_user ne 'root' or $remote_user ne 'admin') {
						$user_allowed=&check_network_modify_permissions($k);
					}
				}
				if ($user_allowed) {
					# adding a delay of 1000 ms in popupmessage ....
					print $q->checkbox(
						-name=>'ip_checkbox',
						-id=>$ip_checkbox_id,
						-label=>'',
						-value=>$ip_hash->{$k}->{ip},
						-class=>checkbox_span,	
						-onmouseover=>"saved_this=this;this.balloonDelay=setTimeout('balloon_popLayer(saved_this,\"$select_multi_checkboxes_help\")',1000);",
						-onmouseout=>"balloon_hideLayer();",
						-onclick=>"
							select_multi_checkboxes(event,this,document.$FORMNAME,document.$FORMNAME.ip_checkbox,$nr_checkbox);
							",
						);
				} else {
					print $q->checkbox(
						-name=>'ip_checkbox',
						-id=>$ip_checkbox_id,
						-label=>'',
						-disabled=>1,
						-class=>checkbox_span,
						-value=>$ip_hash->{$k}->{ip},
						);
				}
			}
		} else {
			print $q->checkbox(
				-name=>'ip_checkbox',
				-id=>$ip_checkbox_id,
				-label=>'',
				-disabled=>1,
				-class=>checkbox_span,
				-value=>$ip_hash->{$k}->{ip},
				);
		}
		print "</SPAN>\n";
		print "</TD>\n";
	
		if ($ips_selected_hash->{$k}) {
			print $q->hidden(-name=>'ip', -value=>$ip_hash->{$k}->{ip_dotted}, -override=>1),"\n";
			print $q->hidden(-name=>'ip_dec', -value=>$k, -override=>1),"\n";
		}
		($row_count) ? print "<TD class='wsNoWrap'>" : print "<TD class='table1_c", $acols++, " wsNoWrap'>";

		if ($ips_selected eq '') {
			my $restricted_msg="To toggle this ip address to restricted/unrestricted press the <FONT COLOR=#ff0000>r</FONT> key while this message is in view.";
			if ( $k != $network_hash->{$network}->{network} and $k != $network_hash->{$network}->{broadcast}) {
				print "<A HREF='javascript:function nothing(){};' class=nohrefurl ";
				print "onmouseover=\"this.focus();balloon_popLayer(this,'$restricted_msg');\" ";
				print "onmouseout=\"this.blur();balloon_hideLayer();\" ";
				print "onkeydown=\"toggle_restricted(event,'$k','$modifier');\" ";
				print ">";
				($ip_hash->{$k}->{ip_dotted} eq '' ) ? print "&nbsp;" : print "<span name=$ip_row_name>", &mark($ip_hash->{$k}->{ip_dotted},$searchstring), "</span>";
				print "</A>";
			} else {
				($ip_hash->{$k}->{ip_dotted} eq '' ) ? print "&nbsp;" : print "<span name=$ip_row_name>", &mark($ip_hash->{$k}->{ip_dotted},$searchstring), "</span>";
			}
		} else {
			($ip_hash->{$k}->{ip_dotted} eq '' ) ? print "&nbsp;" : print "<span name=$ip_row_name>", &mark($ip_hash->{$k}->{ip_dotted},$searchstring), "</span>";
		}

		print "</TD>\n";

		($row_count) ? print "<TD class='wsNoWrap'>" : print "<TD class='table1_c", $acols++, " wsNoWrap'>";
		my $ping_msg="IP address ". $ip_hash->{$k}->{ip_dotted} . " was never scanned."; 
		if (ref($ip_ping_hash->{$k}) eq "HASH") {
			if ($ip_ping_hash->{$k}->{ping_status}) {
				$ping_msg="IP address " . $ip_hash->{$k}->{ip_dotted} . " was last ALIVE at " . $ip_ping_hash->{$k}->{modified} . "."; 
				print "<IMG SRC=../images/ping_green.png ";
			} else {
				$ping_msg="IP address " . $ip_hash->{$k}->{ip_dotted} . " was last DOWN  at " . $ip_ping_hash->{$k}->{modified} . "."; 
				print "<IMG SRC=../images/ping_red.png ";
			}
		} else {
			print "<IMG SRC=../images/ping_grey.png ";
		}
		print "ONMOUSEOVER=\"balloon_popLayer(this,'$ping_msg');\" ";
		print "ONMOUSEOUT=\"balloon_hideLayer();\" ";
		print ">";
		print "</TD>\n";

		if (! $search_flag) {
			($row_count) ? print "<TD class='wsNoWrap'>" : print "<TD class='table1_c", $acols++, " wsNoWrap'>";
			print "<span name=$ip_row_name>", $k - $network, "</span>";
			print "</TD>\n";
		}

		($row_count) ? print "<TD class='wsNoWrap'>" : print "<TD class='table1_c", $acols++, " wsNoWrap'>";
		if ($ips_selected_hash->{$k}) {
			print $q->textfield(
				-name=>'hostname',
				-size=>40,
				-maxlength=>63,
				-class=>ls11px_edit,
				-default=>$ip_hash->{$k}->{hostname},
				-override=>1,
				-onchange=>"
					var selected_nr=$selected_nr;
					if (selected_nr > 1) {
						document.$FORMNAME.hostname[$editfield_count].value=check_hostname_field(document.$FORMNAME.hostname[$editfield_count].value);
						document.$FORMNAME.aliases[$editfield_count].value=check_aliases_field(document.$FORMNAME.aliases[$editfield_count].value);
						// take out ANY aliases that are already in the hostname field
						var a=document.$FORMNAME.aliases[$editfield_count].value.split(/\\s+/);
						var new_aliases='';
						for (j=0;j<a.length;j++) {
							// no replace for the whole field, it could be a partial match for other names ...
							// if there is a match on the whole name we should take it out.
							// we rewrite the NEW string in 'new_aliases' ...
							if (a[j] != document.$FORMNAME.hostname[$editfield_count].value) {
								new_aliases+=a[j] + ' ';
							}
						}
						document.$FORMNAME.aliases[$editfield_count].value=trim(new_aliases);
						if (document.$FORMNAME.confirm_duplicate[$editfield_count].checked==true) {
							document.$FORMNAME.duplicate_hostname_check_error.value='';
							document.getElementById('save_changes').className='button';
							return(true);
						}
					} else {
						document.$FORMNAME.hostname.value=check_hostname_field(document.$FORMNAME.hostname.value);
						document.$FORMNAME.aliases.value=check_aliases_field(document.$FORMNAME.aliases.value);
						// take out ANY aliases that are already in the hostname field
						var a=document.$FORMNAME.aliases.value.split(/\\s+/);
						var new_aliases='';
						for (j=0;j<a.length;j++) {
							// no replace for the whole field, it could be a partial match for other names ...
							// if there is a match on the whole name we should take it out.
							// we rewrite the NEW string in 'new_aliases' ...
							if (a[j] != document.$FORMNAME.hostname.value) {
								new_aliases+=a[j] + ' ';
							}
						}
						document.$FORMNAME.aliases.value=trim(new_aliases);
						if (document.$FORMNAME.confirm_duplicate.checked==true) {
							document.$FORMNAME.duplicate_hostname_check_error.value='';
							document.getElementById('save_changes').className='button';
							return(true);
						}
					}

					var url_src='./ipmanage_hostname_unique_check.pl?';
					url_src+='&ip=$k';
					if (selected_nr > 1) {
						url_src+='&hostname=' + document.$FORMNAME.hostname[$editfield_count].value;
						url_src+='&aliases=' + document.$FORMNAME.aliases[$editfield_count].value;
						url_src+='&editfield_count=' + $editfield_count;
						url_src+='&selected_nr=' + $selected_nr;
						url_src+='&calling_form=' + 'network';
					} else {
						url_src+='&hostname=' + document.$FORMNAME.hostname.value;
						url_src+='&aliases=' + document.$FORMNAME.aliases.value;
						url_src+='&selected_nr=' + $selected_nr;
						url_src+='&calling_form=' + 'network';
					}
					document.getElementById('Duplicate_Hostname_Check').src=url_src;
				"
				);
		} else {
			($ip_hash->{$k}->{hostname} eq '' ) ? print "&nbsp;" : print "<span name=$ip_row_name>", &mark($ip_hash->{$k}->{hostname},$searchstring), "</span>";
		}
		print "</TD>\n";

		print "</TR>\n";

		if ($ips_selected_hash->{$k}) {
			$editfield_count++;
		}
		$row_count++;
	}
	print $q->end_table(),"\n";
	print "</DIV>\n";               # id=table1_HeaderColumnDiv
	print "</DIV>\n";               # id=table1_HeaderColumnWrapperDiv
	print "</TD>\n";
	### end HeaderColumn

	$arows=1;					# RESET the $arows, we start at 1 again (0 is used by the header)
	
	### Body
	$row_count=0;
	$editfield_count=0;
	print "<TD VALIGN=top class='body_td'>\n";
	print "<DIV id=table1_BodyDiv>\n";
	print $q->start_table({-class=>iptable, -StickyTableHeaders=>yes, -id=>table1_Body, -cellpadding=>0, -cellspacing=>0, -border=>0} ),"\n";

	foreach my $k (ip_hash_sort($ip_hash,$order_by)) {
		my $ip_row_id=$k . "_row_id_body";
		my $ip_row_name=$k . "_row_name";
		print "<TR class=table1_r", $arows++, " id=$ip_row_id>\n";
		($row_count) ? print "<TD class='wsNoWrap'>" : print "<TD class='table1_c", $acols++, " wsNoWrap'>";
		if ($ips_selected_hash->{$k}) {
			print $q->textfield(
				-name=>'aliases',
				-size=>$max_aliases_length,
				-maxlength=>255,
				-class=>ls11px_edit,
				-default=>$ip_hash->{$k}->{aliases},
				-override=>1,
				-onchange=>"
					var selected_nr=$selected_nr;
					if (selected_nr > 1) {
						document.$FORMNAME.hostname[$editfield_count].value=check_hostname_field(document.$FORMNAME.hostname[$editfield_count].value);
						document.$FORMNAME.aliases[$editfield_count].value=check_aliases_field(document.$FORMNAME.aliases[$editfield_count].value);
						// take out ANY aliases that are already in the hostname field
						var a=document.$FORMNAME.aliases[$editfield_count].value.split(/\\s+/);
						var new_aliases='';
						for (j=0;j<a.length;j++) {
							// no replace for the whole field, it could be a partial match for other names ...
							// if there is a match on the whole name we should take it out.
							// we rewrite the NEW string in 'new_aliases' ...
							if (a[j] != document.$FORMNAME.hostname[$editfield_count].value) {
								new_aliases+=a[j] + ' ';
							}
						}
						document.$FORMNAME.aliases[$editfield_count].value=trim(new_aliases);
						if (document.$FORMNAME.confirm_duplicate[$editfield_count].checked) {
							document.$FORMNAME.duplicate_hostname_check_error.value='';
							document.getElementById('save_changes').className='button';
							return(true);
						}
					} else {
						document.$FORMNAME.hostname.value=check_hostname_field(document.$FORMNAME.hostname.value);
						document.$FORMNAME.aliases.value=check_aliases_field(document.$FORMNAME.aliases.value);
						// take out ANY aliases that are already in the hostname field
						var a=document.$FORMNAME.aliases.value.split(/\\s+/);
						var new_aliases='';
						for (j=0;j<a.length;j++) {
							// no replace for the whole field, it could be a partial match for other names ...
							// if there is a match on the whole name we should take it out.
							// we rewrite the NEW string in 'new_aliases' ...
							if (a[j] != document.$FORMNAME.hostname.value) {
								new_aliases+=a[j] + ' ';
							}
						}
						document.$FORMNAME.aliases.value=trim(new_aliases);
						if (document.$FORMNAME.confirm_duplicate.checked) {
							document.$FORMNAME.duplicate_hostname_check_error.value='';
							document.getElementById('save_changes').className='button';
							return(true);
						}
					}
					var url_src='./ipmanage_hostname_unique_check.pl?';
					url_src+='&ip=$k';
					if (selected_nr > 1) {
						url_src+='&hostname=' + document.$FORMNAME.hostname[$editfield_count].value;
						url_src+='&aliases=' + document.$FORMNAME.aliases[$editfield_count].value;
						url_src+='&editfield_count=' + $editfield_count;
						url_src+='&selected_nr=' + $selected_nr;
						url_src+='&calling_form=' + 'network';
					} else {
						url_src+='&hostname=' + document.$FORMNAME.hostname.value;
						url_src+='&aliases=' + document.$FORMNAME.aliases.value;
						url_src+='&selected_nr=' + $selected_nr;
						url_src+='&calling_form=' + 'network';
					}
					document.getElementById('Duplicate_Hostname_Check').src=url_src;
				"
				);
		} else {
			($ip_hash->{$k}->{aliases} eq '' ) ? print "&nbsp;" : print "<span name=$ip_row_name>", &mark($ip_hash->{$k}->{aliases},$searchstring), "</span>";
		}
		print "</TD>\n";

		my $nr_dups=scalar keys %{$duplicates_byip_hash->{$k}};

		$dup_message="";
		if ($nr_dups) {
			$dup_message.="The following ";
			if ((scalar keys %{$duplicates_byip_hash->{$k}}) > 1) {
				$dup_message.="hosts have ";
			} else {
				$dup_message.="host has ";
			}
			$dup_message.="<BR>multiple IP addresses!<BR>";
			$dup_message.="<TABLE BORDER=1 CELLPADDING=1 CELLSPACING=1>";
			foreach my $h (sort keys %{$duplicates_byip_hash->{$k}}) {
				$dup_message.= "<TR>";
				my $rowspan=scalar @{$duplicates_byip_hash->{$k}->{$h}};
				$dup_message.="<TD ROWSPAN=$rowspan>$h</TD>";
				my $a_cnt=0;
				foreach my $a (@{$duplicates_byip_hash->{$k}->{$h}}) {
					if ($a_cnt) {
						$dup_message.="<TR><TD>" . &convert_dec2ip($a) . "</TD></TR>";
					} else {
						$dup_message.="<TD>" . &convert_dec2ip($a) . "</TD>";
					}
					$a_cnt++;
				}
				$dup_message.="</TR>";
			}
			$dup_message.="</TABLE>";
		}

		$dup_message_input="Check this box to allow hostnames with multiple ip addresses.";

		if ($row_count) {
			print "<TD class='wsNoWrap' ";
		} else {
			print "<TD class='table1_c", $acols++, " wsNoWrap' ";
		}
		if ($nr_dups and !$ips_selected_hash->{$k}) {
			print "ONMOUSEOVER=\"balloon_popLayer(this,'$dup_message');\" ";
			print "ONMOUSEOUT=\"balloon_hideLayer();\" ";
		}
		print ">";

		if ($nr_dups) {
			print "<SPAN style='position:relative;top:-1px;left:3px;background-color:#ff0000;' >";
		} else {
			print "<SPAN style='position:relative;top:-1px;left:3px;background-color:#777777;' >";
		}
		if ($ips_selected_hash->{$k}) {
			print "<INPUT ";
			print "TYPE=checkbox ";
			print "NAME=confirm_duplicate ";
			if ($nr_dups) {
				print "CHECKED ";
				print "VALUE=on ";
				print "ONMOUSEOVER=\"balloon_popLayer(this,'$dup_message');\" ";
				print "ONMOUSEOUT=\"balloon_hideLayer();\" ";
			} else {
				print "ONMOUSEOVER=\"balloon_popLayer(this,'$dup_message_input');\" ";
				print "ONMOUSEOUT=\"balloon_hideLayer();\" ";
				print "VALUE=off ";
			}
			print "CLASS=checkbox_span ";
			print "ONCLICK=\"";
			print "
					var selected_nr=$selected_nr;
					var url_src='./ipmanage_hostname_unique_check.pl?';
					url_src+='&ip=$k';
					if (this.checked) {
						this.value='on';
					} else {
						this.value='off';
					}
					if (selected_nr > 1) {
						if (this.checked) {
							document.$FORMNAME.hostname[$editfield_count].style.color='#000000';
							document.$FORMNAME.aliases[$editfield_count].style.color='#000000';
							document.$FORMNAME.duplicate_hostname_check_error.value='';
							document.getElementById('save_changes').className='button';
						} else {
							document.$FORMNAME.hostname[$editfield_count].style.color='#000000';
							document.$FORMNAME.aliases[$editfield_count].style.color='#000000';
							url_src+='&hostname=' + document.$FORMNAME.hostname[$editfield_count].value;
							url_src+='&aliases=' + document.$FORMNAME.aliases[$editfield_count].value;
							url_src+='&editfield_count=' + $editfield_count;
							url_src+='&selected_nr=' + $selected_nr;
							url_src+='&calling_form=' + 'network';
							document.getElementById('Duplicate_Hostname_Check').src=url_src;
						}
					} else {
						if (this.checked) {
							document.$FORMNAME.hostname.style.color='#000000';
							document.$FORMNAME.aliases.style.color='#000000';
							document.$FORMNAME.duplicate_hostname_check_error.value='';
							document.getElementById('save_changes').className='button';
						} else {
							document.$FORMNAME.hostname.style.color='#000000';
							document.$FORMNAME.aliases.style.color='#000000';
							url_src+='&hostname=' + document.$FORMNAME.hostname.value;
							url_src+='&aliases=' + document.$FORMNAME.aliases.value;
							url_src+='&selected_nr=' + $selected_nr;
							url_src+='&calling_form=' + 'network';
							document.getElementById('Duplicate_Hostname_Check').src=url_src;
						}
					}
				";
			print "\"";
			print ">";
		} else {
			if ($nr_dups) {
				print "<INPUT TYPE=checkbox NAME=dummy_checkbox VALUE='' ";
				print "CLASS=checkbox_span ";
				print "ONMOUSEOVER=\"balloon_popLayer(this,'$dup_message');\" ";
				print "ONMOUSEOUT=\"balloon_hideLayer();\" ";
				print "DISABLED CHECKED ";
				print ">";
			} else {
				print "<INPUT TYPE=checkbox NAME=dummy_checkbox VALUE='' DISABLED CLASS=checkbox_span >";
			}
		}
		print "<SPAN>";
		print "</TD>\n";
	
		($row_count) ? print "<TD class='wsNoWrap'>" : print "<TD class='table1_c", $acols++, " wsNoWrap'>";
		if ($ips_selected_hash->{$k}) {
			print $q->textfield(
				-name=>'comment',
				-size=>$max_comment_length,
				-maxlength=>255,
				-class=>ls11px_edit,
				-default=>$ip_hash->{$k}->{comment},
				-override=>1,
				-onblur=>"
					var re=/\\\"/;
					document.$FORMNAME.comment.value=document.$FORMNAME.comment.value.replace(re,'\\\'');
					",
				);
		} else {
			($ip_hash->{$k}->{comment} eq '' ) ? print "&nbsp;" : print "<span name=$ip_row_name>", &mark($ip_hash->{$k}->{comment},$searchstring), "</span>";
		}
		print "</TD>\n";
	
		($row_count) ? print "<TD class='wsNoWrap'>" : print "<TD class='table1_c", $acols++, " wsNoWrap'>";
		($ip_hash->{$k}->{dfmodified} eq '' ) ? print "&nbsp;" : print "<span name=$ip_row_name>", $ip_hash->{$k}->{dfmodified}, "</span>";
		print "</TD>\n";
	
		($row_count) ? print "<TD class='wsNoWrap'>" : print "<TD class='table1_c", $acols++, " wsNoWrap'>";
		($ip_hash->{$k}->{modifier} eq '' ) ? print "&nbsp;" : print "<span name=$ip_row_name>", &mark($ip_hash->{$k}->{modifier},$searchstring), "</span>";
		print "</TD>\n";

		print "</TR>\n";
		$row_count++;
		if ($ips_selected_hash->{$k}) {
			$editfield_count++;
		}
	}
	print $q->end_table(),"\n";
	print "</DIV>\n";
	print "</TD>\n";
	print "</TR>\n";
	print $q->end_table(),"\n";
	print "</DIV>\n\n";       # end of id=mytable
	print $q->end_center(),"\n";
	
	print $q->start_center(),"\n";
	print "<DIV id=part2>\n";
	print "<BR>\n";






	if ($ips_selected eq '') {
		print $q->submit(
			-name=>'action',
			-value=>'Edit Selected IP Address(es)',
			-class=>'button',
			-onclick=>"
				var ips='';
				var msg='';
				var anchor_flag=0;
				for(i=1;i<document.$FORMNAME.ip_checkbox.length;i++) {
					if (document.$FORMNAME.ip_checkbox[i].checked) {
						// set the anchor on the first selected item if the anchor flag is not set yet.
						if (!anchor_flag) {
							document.$FORMNAME.anchor.value=document.$FORMNAME.ip_checkbox[i].value;
							anchor_flag++;
						}
						msg+=i + '=' + 'checked\\n';		
						ips+=document.$FORMNAME.ip_checkbox[i].value + ',';
					}	
				}
				var re=/,\$/;
				ips=ips.replace(re,'');
				// alert(msg + '\\n' + ips);
				document.$FORMNAME.ips_selected.value=ips;

				",
			),"\n";

		print $q->submit(
			-name=>'action',
			-value=>'Delete Selected IP Address(es)',
			-class=>'button',
			-onclick=>"
				var ips='';
				var msg='';
				var anchor_flag=0;
				for(i=1;i<document.$FORMNAME.ip_checkbox.length;i++) {
					if (document.$FORMNAME.ip_checkbox[i].checked) {
						// set the anchor on the first selected item if the anchor flag is not set yet.
						if (!anchor_flag) {
							document.$FORMNAME.anchor.value=document.$FORMNAME.ip_checkbox[i].value;
							anchor_flag++;
						}
						msg+=i + '=' + 'checked\\n';		
						ips+=document.$FORMNAME.ip_checkbox[i].value + ',';
					}	
				}
				var re=/,\$/;
				ips=ips.replace(re,'');
				// alert(msg + '\\n' + ips);

				var del=confirm('Are you sure you want to delete the selected IP addresses ?');
				if (del) {
					document.$FORMNAME.ips_selected.value=ips;
				} else {
					document.$FORMNAME.ips_selected.value='';
					return false;
				}
				",
			),"\n";

		print $q->submit(
			-name=>'action',
			-value=>'Ping Selected IP Address(es)',
			-class=>'button',
			-onclick=>"
				var ips='';
				var msg='';
				var anchor_flag=0;
				for(i=1;i<document.$FORMNAME.ip_checkbox.length;i++) {
					if (document.$FORMNAME.ip_checkbox[i].checked) {
						// set the anchor on the first selected item if the anchor flag is not set yet.
						if (!anchor_flag) {
							document.$FORMNAME.anchor.value=document.$FORMNAME.ip_checkbox[i].value;
							anchor_flag++;
						}
						msg+=i + '=' + 'checked\\n';		
						ips+=document.$FORMNAME.ip_checkbox[i].value + ',';
					}	
				}
				var re=/,\$/;
				ips=ips.replace(re,'');
				// alert(msg + '\\n' + ips);
				document.$FORMNAME.ips_selected.value=ips;
				if (ips.length == 0) {
					alert('Please select IP address(es)');
					return false;
				}
				",
			),"\n";

		print "<BR>\n";
		print $q->submit(
			-name=>'refresh',
			-value=>'Refresh',
			-class=>'button',
			),"\n";
		print $q->button(
			-name=>'close_window',
			-value=>'Close Window',
			-class=>'button',
			-onclick=>'window.close();',
			),"\n";
	} else {
		my $disabled_message="Button is disabled since there are duplicate hostnames/aliases.<BR>You should fix that first!";
		print $q->submit(
			-name=>'action',
			-id=>'save_changes',
			-value=>'Save Changes',
			-class=>'button',
			-onmouseover=>"
					if (this.className == 'BUTTONdisabled') {
						balloon_popLayer(this,'$disabled_message');
					}
					var selected_nr=$selected_nr;
					if (selected_nr > 1) {
						for (i=0;i<document.$FORMNAME.hostname.length;i++) {
							if (document.$FORMNAME.confirm_duplicate[i].checked==true) {
								document.$FORMNAME.duplicate_hostname_check_error.value='';
								document.getElementById('save_changes').className='button';
								continue;
							}
							var url_src='./ipmanage_hostname_unique_check.pl?';
							url_src+='&hostname=' + document.$FORMNAME.hostname[i].value;
							url_src+='&aliases=' + document.$FORMNAME.aliases[i].value;
							url_src+='&ip=' + document.$FORMNAME.ip_dec[i].value;
							url_src+='&editfield_count=' + i;
							url_src+='&selected_nr=' + $selected_nr;
							url_src+='&calling_form=' + 'network';
							document.getElementById('Duplicate_Hostname_Check').src=url_src;
						}
					} else {
						if (document.$FORMNAME.confirm_duplicate.checked==true) {
							document.$FORMNAME.duplicate_hostname_check_error.value='';
							document.getElementById('save_changes').className='button';
							return true;
						}
						var url_src='./ipmanage_hostname_unique_check.pl?';
						url_src+='&hostname=' + document.$FORMNAME.hostname.value;
						url_src+='&aliases=' + document.$FORMNAME.aliases.value;
						url_src+='&ip=' + document.$FORMNAME.ip_dec.value;
						url_src+='&selected_nr=' + $selected_nr;
						url_src+='&calling_form=' + 'network';
						document.getElementById('Duplicate_Hostname_Check').src=url_src;
					}
				",
			-onmouseout=>"setTimeout('balloon_hideLayer()',1000);",
			-onclick=>"
				if (document.$FORMNAME.duplicate_hostname_check_error.value.length > 0) {
					alert('You have duplicate hostnames/aliases, please solve this first!');
					return false;
				}
				",
			),"\n";
		print $q->submit(
			-name=>'cancel',
			-value=>'Cancel',
			-class=>'button',
			),"\n";
		
	}

	print "</DIV>\n";   # end of id=part2>
	print $q->end_center;

	print "<SCRIPT language=javascript>\n";
	foreach my $r_ip (@restricted_ip) {
		print "disable_restricted('$r_ip');\n";
	}
	print "</SCRIPT>\n";

	if ($ips_selected eq '') {
		print <<___Refresh_HTML___;
		<SCRIPT language=javascript>
		function js_check_updates() {
			// alert('loading page');
			document.getElementById('refresh_frame').src='./ipmanage_check_db_updates.pl?&form=$FORMNAME';
		}
		var refresh_interval=setInterval(\"js_check_updates()\",30000); 
	
		</SCRIPT>
___Refresh_HTML___
	}
} #end of show_networks

if (lc($action) eq 'edit selected ip address(es)') {
	# fine, it's in &show_ips(), we will get there anyway ;-)
} elsif (lc($action) eq 'delete selected ip address(es)') {
	&delete_selected_ips();
	$ips_selected='';
} elsif (lc($action) eq 'ping selected ip address(es)') {
	&ping_selected_ips();
	$ips_selected='';
} elsif (lc($action) eq 'save changes') {
	if (! save_changes()) {
		$ips_selected='';
	}
} else {
	$ips_selected='';
}

&show_ips();

print <<___WAIT___;
<SCRIPT language=javascript>

function my_pause(ms) {
	ms += new Date().getTime();
	while (new Date() < ms){}
} 

function createRequestObject() {
	var ro;
	if (navigator.appName=='Microsoft Internet Explorer') {
		ro = new ActiveXObject('Microsoft.XMLHTTP');
	} else {
		ro = new XMLHttpRequest();
	}
	return ro;
}

function sendScanRequest(url,obj) {
	var http = createRequestObject();
	http.open('get', url);
	http.onreadystatechange = function () {
		if (http.readyState == 4) {
			document.getElementById(obj).innerHTML=http.responseText;
		}
	}
	http.send(null);
}
</SCRIPT>

___WAIT___


print <<___SIZING___;
<SCRIPT language=javascript>
// for the table ...
var table_sizes={};
var paddingleft=0;
var paddingright=0;
var paddingtop=1;
var paddingbottom=1;

var cell_dups=[
];


function mytable_resize() {
        var s_part1=DivCoordinates('part1');
        var s_part2=DivCoordinates('part2');
        var mytable_height=window.innerHeight - s_part1.height - s_part2.height - 50;

        document.getElementById('mytable').style.maxHeight=mytable_height + 'px';
	table_sizes['table1']=[window.innerWidth-50,mytable_height];

	resize_scrolling_area_sticky_headers();

	show_table();
}

function show_table() {
	document.getElementById('mytable').style.opacity=1;
}

</SCRIPT>
___SIZING___

print "<BODY ONLOAD=\"\n";
print "initializetooltip();\n";
if ($search_flag) {
	print "initialize_sticky_headers();\n" if ($searchstring ne '' or $advancedsearchflag eq 'yes');
} else {
	print "initialize_sticky_headers();\n";
}
print "mytable_resize();\n";
print "window.location.hash=$anchor;\n";
print "\" \n";
print "ONRESIZE=\"\n";
print "mytable_resize();\n";
print "\" \n";
print "/>\n";
### end of BODY onload ...

print $q->end_form();

