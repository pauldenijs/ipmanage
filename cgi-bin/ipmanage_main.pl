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

$action=		$q->param('action');
$networks_selected=	$q->param('networks_selected');		# just a list of networks (comma seperated) that were selected with the checkbox;

# edits
@network_mask=		$q->param('network_mask');
@comment=		$q->param('comment');
@owners=		$q->param('owners');
@global_domain=		$q->param('global_domain');
@local_domain=		$q->param('local_domain');
@public=		$q->param('public');

if ($debug) {
	print STDERR "================= PARAMETERS ($my_own_url)====================\n";
	foreach my $key ($q->param()) {
		print STDERR "key:" , $key , ",value:" ,$q->param($key),"\n";
	}
	print STDERR "================= END PARAMETERS ====================\n";
}


$this_hostname=         `/bin/hostname`;
chomp $this_hostname;


my $prog_title="Networks";
&header($VERSION . " on " . $this_hostname . " - " . $prog_title);
&js_include('../javascript/StickyTableHeaders.js');


if ($q->cookie(-name=>$cookie_id2) eq not_valid) {
        $remote_user="";
} else {
        $remote_user=$q->cookie(-name=>$cookie_id1);
}

if(&check_cookies($remote_user) == 0) {
	&check_duplicate_hostnames;
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

$FORMNAME="main";
print $q->start_form(-name=>$FORMNAME),"\n";
# Create iframe where we run updateusercount.pl
# but the url is hidden, we only need to copy
# the value
print "<IFRAME ";
print "NAME=UserCountFrame SRC='./ipmanage_updateusercount.pl?&refreshrate=$update_refreshrate&who=$remote_user&validlogin=$cookie_id2' style='display:none;'>";
print "</IFRAME>\n";
print $q->hidden(-name=>'csflag',-value=>0,-override=>1),"\n";
print $q->hidden(-name=>'usertable',-value=>"",-override=>1),"\n";

sub save_changes {
	print STDERR "Saving changes for networks: $networks_selected\n";

	my @nw=split /,/,$networks_selected;
	for my $i (0 .. $#nw) {
		my $a='';
		if ( $nw[$i] == -1 ) {
			# Oh, this is a record that must be added!
			$a="-a";
		}
		my $cmd="../bin/ipmanage_net.pl -Z $remote_user $a -O \"$owners[$i]\" -c \"$comment[$i]\" -g \"$global_domain[$i]\" -l \"$local_domain[$i]\" -P $public[$i] $network_mask[$i]";
		print STDERR "$cmd\n";
		my $out=`$cmd`;
		
		my $err=$? >> 8;

		if ($err == 10) {
			my $tmpfile=&tmpfile_pre_post('add_new_network','err');
			open (ERRFILE,">$tmpfile");
			print ERRFILE $out;
			close ERRFILE;
			# oops something went wrong with HTML output (the exit code 10) 
			print "<SCRIPT LANGUAGE=javascript>";
			my $url="./ipmanage_show_msg.pl?&messagefile=$tmpfile&ok_to_remove=1";
			print "SizedNewWindow('$url','oops',300,300);";
			print "</SCRIPT>";
		}
	}
}

sub delete_selected_networks {
	print STDERR "Deleting networks: $networks_selected\n";
	my $network_hash=&create_network_hash; 		### network hash has ALL the network information from the database!!!
	
	foreach my $e (split /,/,$networks_selected) {
		my $network_and_mask=$network_hash->{$e}->{network_dotted} . "/" . $network_hash->{$e}->{bitmask};
		next if (! $network_hash->{$e}->{network});
		my $cmd="../bin/ipmanage_net.pl -Z $remote_user -d $network_and_mask";
		print STDERR "$cmd\n";
		system($cmd);
	}
}

sub ping_selected_networks {
	print STDERR "Ping networks: $networks_selected\n";
	my $cmd="../bin/ipmanage_ping.pl -n $networks_selected &"; 

	my $total_time_to_run=0;
	my $network_hash=&create_network_hash; 		### network hash has ALL the network information from the database!!!
	foreach my $nw (split/,/,$networks_selected) {
		my $start=$network_hash->{$nw}->{network};
		my $end=$network_hash->{$nw}->{broadcast};
		my $chunk_loops=int(($end-$start)/$max_db_connections);
		### report the max time for this program to run:
		$total_time_to_run+=$chunk_loops * ($ping_timeout + 1) + ($ping_timeout + 1);
	}

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
}

sub show_networks {
	my @flagvalues=[0,1];
        my %flaglabels=(0=>'No',1=>'Yes');

	# make sure we can reference this as an array with length, if we have only 1 network entry
	# show all the networks. Since we don't know what the heck we are going to need, just stuff them in a hash ...
	my $network_hash=&create_network_hash; 		### network hash has ALL the network information from the database!!!

	$select_multi_checkboxes_help="To select multiple boxes, click the first selection (checked or unchecked).<BR> " .
		"Hold the Shift-Key and click the last box. The range will follow the red (last) bordered checkbox selection"; 

	print "<SCRIPT language=javascript>var previous_checkbox_checked=0</SCRIPT>\n";

	# create a hash of $networks_selected
	my $networks_selected_hash;
	foreach my $n (split /,/,$networks_selected) {
		$networks_selected_hash->{$n}=1;
		if ($n == -1) {
			print STDERR " New entry dude!\n";
			# WOW, a new entry -1 which is impossible 
			$network_hash->{$n}->{network}=$n;
		} 
		
	}

	### the header part, title, login name etc
	print $q->start_center(),"\n";
	print "<DIV id=part1>\n";
	&show_head($prog_title);
	print "<BR>\n";
	print "</DIV>\n";
	print $q->end_center(),"\n";
	
	### the table part 
	print $q->start_center(),"\n";
	print "<DIV id=mytable style='height:auto;max-height:550px;opacity:0;'>\n";
	print $q->start_table({-id=>network_table, -cellpadding=>0, -cellspacing=>0, border=>0, }),"\n";

	$arows=0;
	$acols=0;
 
	# start table1_HeaderCorner (stickey columns are: select,network (and netmask	
	print "<TR>\n";
	print "<TD class='BODYt headercorner_td'>\n";
	print "<DIV id=table1_HeaderCornerDiv>\n";
	print $q->start_table({-class=>networktable, -StickyTableHeaders=>yes, -id=>table1_HeaderCorner, -cellpadding=>0, -cellspacing=>0, -border=>0} ),"\n";
	print "<TR class=table1_r", $arows++, ">\n";
	print "<TH class='wsNoWrap table1_c", $acols++, "'>Select</TH>\n";	 		# Select
	print "<TH class='wsNoWrap table1_c", $acols++, "'>Network</TH>\n";			# Network (IP)
	print "<TH class='wsNoWrap table1_c", $acols++, "'>NetMask</TH>\n";			# NetMask (BitMask)
	print "</TR>\n";
	print $q->end_table(),"\n";
	print "</DIV>\n";
	print "</TD>\n";
	### end HeaderCorner

	$arows=0;

	## start table1_HeaderRow
	print "<TD class='BODYt headerrow_td' >\n";
	print "<DIV id=table1_HeaderRowDiv>\n";
	print $q->start_table({-class=>networktable, -StickyTableHeaders=>yes, -id=>table1_HeaderRow, -cellpadding=>0, -cellspacing=>0, border=>0} ),"\n";
	print "<TR class=table1_r", $arows++, ">\n";
	print "<TH class='wsNoWrap table1_c", $acols++, "'>Comment</TH>\n";
	print "<TH class='wsNoWrap table1_c", $acols++, "'>Owners</TH>\n";
	print "<TH class='wsNoWrap table1_c", $acols++, "'>Global Domain</TH>\n";
	print "<TH class='wsNoWrap table1_c", $acols++, "'>Local Domain</TH>\n";
	print "<TH class='wsNoWrap table1_c", $acols++, "'>Public</TH>\n";
	print "<TH class='wsNoWrap table1_c", $acols++, "'>Last Modified</TH>\n";
	print "<TH class='wsNoWrap table1_c", $acols++, "'>Last Modifier</TH>\n";
	print "</TR>\n";
	print $q->end_table(),"\n";             
	print "</DIV>\n";                       
	print "</TD>\n";
	print "</TR>\n";
	## end table1_HeaderRow

	# create at least 1 entry for network_checkbox and networks_selected
	# so we can always refer to an array in javascript, if we select 1 item!
	print $q->hidden(-name=>'network_checkbox',-value=>'off',-override=>1),"\n";	
	print $q->hidden(-name=>'networks_selected',-value=>$networks_selected,-override=>1),"\n";	

	### HeaderColumn
	my $network_count=0;
	$acols=0;					# RESET the $acols, we start at 0 again

	print "<TR>\n";
	print "<TD valign=top class='headercolumn_td'>\n";
	print "<DIV id=table1_HeaderColumnWrapperDiv style='overflow:hidden'>\n";
	print "<DIV id=table1_HeaderColumnDiv>\n";
	print $q->start_table({-class=>networktable, -StickyTableHeaders=>yes, -id=>table1_HeaderColumn, -cellpadding=>0, -cellspacing=>0, -border=>0} ),"\n";
	foreach my $k (sort keys %{$network_hash}) {
		# see if we are allowed to change this record!
		my $user_allowed=0;
		foreach my $o ('admin','root',(split /\s+/,$network_hash->{$k}->{owners}),$network_hash->{$k}->{modifier} ) {
			if ($o eq $remote_user) {
				$user_allowed++;
				last;
			}
		}

		print "<TR class=table1_r", $arows++, ">\n";

		my $nr_checkbox=$network_count+1;
		if ($networks_selected_hash->{$k}) {
			($network_count) ? print "<TD class='wsNoWrap ls11px_edit' align=center  >" : print "<TD class='table1_c", $acols++, " wsNoWrap ls11px_edit' align=center  >";
		} else {
			($network_count) ? print "<TD class='wsNoWrap' align=center  >" : print "<TD class='table1_c", $acols++, " wsNoWrap' align=center  >";
		}

		if ($k == -1) {
			print "<SPAN id=span_$nr_checkbox >"; 
		} else {
			print "<SPAN style='position:relative;top:-1px; background-color:#777777;' id=span_$nr_checkbox >"; 
		}
		if ($networks_selected eq '') {
			if ($user_allowed) {
				print $q->checkbox(
					-name=>'network_checkbox',
					-label=>'',
					-id=>$nr_checkbox,
					-value=>$network_hash->{$k}->{network},
					-class=>checkbox_span,
					-onmouseover=>"balloon_popLayer(this,'$select_multi_checkboxes_help')",
					-onmouseout=>"balloon_hideLayer();",
					-onclick=>"
						select_multi_checkboxes(event,this,document.$FORMNAME,document.$FORMNAME.network_checkbox,$nr_checkbox);
						",
					);
			} else {
				print $q->checkbox(
					-name=>'network_checkbox',
					-label=>'',
					-disabled=>1,
					-class=>checkbox_span,
					-value=>$network_hash->{$k}->{network},
					);
			}
		} else {
			if ($k == -1) {
				print "<FONT COLOR=#ff0000>New</FONT>";
			} else {
				print $q->checkbox(
					-name=>'network_checkbox',
					-label=>'',
					-disabled=>1,
					-class=>checkbox_span,
					-value=>$network_hash->{$k}->{network},
					);
			}
		}
		print "</SPAN>";
		print "</TD>\n";
	
		my $network_mask_string=$network_hash->{$k}->{network_dotted} . "/" .  $network_hash->{$k}->{bitmask};
		($network_count) ? print "<TD class='wsNoWrap'>" : print "<TD class='table1_c", $acols++, " wsNoWrap'>";
		if ($k == -1) {
			# make this a field entry -> network / bitmask
			print $q->textfield(
				-name=>'network_mask',
				-size=>18,
				-maxlength=>18,
				-class=>ls11px_edit,
				-default=>'',
				-override=>1,
				-onblur=>"
					return validate_network_input(document.$FORMNAME.network_mask);
					",
				);
		} else {
			my $url="./ipmanage_network.pl?" . "&network=" . $k . "&bitmask=" . $network_hash->{$k}->{bitmask};
			print "<A ";
			print "CLASS=hrefurl ";
			print "ONCLICK=\"SizedNewWindow('$url','$k',1024,900);\" ";
			print ">";
			print "$network_mask_string";
			print "</A>";
			if ($networks_selected_hash->{$k}) {
				print $q->hidden(-name=>'network_mask', -value=>$network_mask_string, -override=>1),"\n";
			}
		}

		($network_count) ? print "<TD class='wsNoWrap'>" : print "<TD class='table1_c", $acols++, " wsNoWrap'>";
		($network_hash->{$k}->{netmask} eq "") ? print "&nbsp;" : print $network_hash->{$k}->{netmask};
		print "</TD>\n";

		print "</TR>\n";
		$network_count++;
	}
	print $q->end_table(),"\n";
	print "</DIV>\n";               # id=table1_HeaderColumnDiv
	print "</DIV>\n";               # id=table1_HeaderColumnWrapperDiv
	print "</TD>\n";
	### end HeaderColumn

	$arows=1;					# RESET the $arows, we start at 1 again (0 is used by the header)
	
	### Body
	$network_count=0;
	print "<TD VALIGN=top class='body_td'>\n";
	print "<DIV id=table1_BodyDiv>\n";
	print $q->start_table({-class=>networktable, -StickyTableHeaders=>yes, -id=>table1_Body, -cellpadding=>0, -cellspacing=>0, -border=>0} ),"\n";
	foreach my $k (sort keys %{$network_hash}) {
		print "<TR class=table1_r", $arows++, ">\n";

		($network_count) ? print "<TD class='wsNoWrap'>" : print "<TD class='table1_c", $acols++, " wsNoWrap'>";
		if ($networks_selected_hash->{$k}) {
			print $q->textfield(
				-name=>'comment',
				-size=>40,
				-maxlength=>255,
				-class=>ls11px_edit,
				-default=>$network_hash->{$k}->{comment},
				-override=>1,
				);
		} else {
			($network_hash->{$k}->{comment} eq '' ) ? print "&nbsp;" : print $network_hash->{$k}->{comment};
		}
		print "</TD>\n";
	
		($network_count) ? print "<TD class='wsNoWrap'>" : print "<TD class='table1_c", $acols++, " wsNoWrap'>";
		if ($networks_selected_hash->{$k}) {
			print $q->textfield(
				-name=>'owners',
				-size=>40,
				-maxlength=>255,
				-class=>ls11px_edit,
				-default=>$network_hash->{$k}->{owners},
				-override=>1,
				);
		} else {
			($network_hash->{$k}->{owners} eq '' ) ? print "&nbsp;" : print $network_hash->{$k}->{owners};
		}
		print "</TD>\n";
	
		($network_count) ? print "<TD class='wsNoWrap'>" : print "<TD class='table1_c", $acols++, " wsNoWrap'>";
		if ($networks_selected_hash->{$k}) {
			print $q->textfield(
				-name=>'global_domain',
				-size=>40,
				-maxlength=>80,
				-class=>ls11px_edit,
				-default=>$network_hash->{$k}->{global_domain},
				-override=>1,
				);
		} else {
			($network_hash->{$k}->{global_domain} eq '' ) ? print "&nbsp;" : print $network_hash->{$k}->{global_domain};
		}
		print "</TD>\n";
	
		($network_count) ? print "<TD class='wsNoWrap'>" : print "<TD class='table1_c", $acols++, " wsNoWrap'>";
		if ($networks_selected_hash->{$k}) {
			print $q->textfield(
				-name=>'local_domain',
				-size=>40,
				-maxlength=>80,
				-class=>ls11px_edit,
				-default=>$network_hash->{$k}->{local_domain},
				-override=>1,
				);
		} else {
			($network_hash->{$k}->{local_domain} eq '' ) ? print "&nbsp;" : print $network_hash->{$k}->{local_domain};
		}
		print "</TD>\n";
	
		($network_count) ? print "<TD class='wsNoWrap'>" : print "<TD class='table1_c", $acols++, " wsNoWrap'>";
		if ($networks_selected_hash->{$k}) {
			print $q->popup_menu(
				-name=>'public',
				-values=>@flagvalues,
				-default=>$network_hash->{$k}->{public},
				-labels=>\%flaglabels,
				-class=>ls11px_edit,
				);
		} else {
			($network_hash->{$k}->{public}) ? print "Yes" : print "No"; 
		}
		print "</TD>\n";
	
		($network_count) ? print "<TD class='wsNoWrap'>" : print "<TD class='table1_c", $acols++, " wsNoWrap'>";
		($network_hash->{$k}->{dfmodified} eq '') ? print "&nbsp;" :  print $network_hash->{$k}->{dfmodified};
		print "</TD>\n";
	
		($network_count) ? print "<TD class='wsNoWrap'>" : print "<TD class='table1_c", $acols++, " wsNoWrap'>";
		($network_hash->{$k}->{modifier} eq '') ? print "&nbsp;" : print $network_hash->{$k}->{modifier};
		print "</TD>\n";

		print "</TR>\n";
		$network_count++;
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

	if ($networks_selected eq '') {
		print $q->submit(
			-name=>'action',
			-value=>'Add Network',
			-class=>'button',
			-onclick=>"
				document.$FORMNAME.networks_selected.value='';
				for(i=1;i<document.$FORMNAME.network_checkbox.length;i++) {
					document.$FORMNAME.network_checkbox[i].checked=false;
				}
				// make value 0xffffffff + 1
				document.$FORMNAME.networks_selected.value='-1' 
				",
			),"\n";
	
		print $q->submit(
			-name=>'action',
			-value=>'Edit Selected Network(s)',
			-class=>'button',
			-onclick=>"
				var networks='';
				var msg='';
				for(i=1;i<document.$FORMNAME.network_checkbox.length;i++) {
					if (document.$FORMNAME.network_checkbox[i].checked) {
						msg+=i + '=' + 'checked\\n';		
						networks+=document.$FORMNAME.network_checkbox[i].value + ',';
					}	
				}
				var re=/,\$/;
				networks=networks.replace(re,'');
				// alert(msg + '\\n' + networks);
				document.$FORMNAME.networks_selected.value=networks;
				",
			),"\n";

		print $q->submit(
			-name=>'action',
			-value=>'Delete Selected Network(s)',
			-class=>'button',
			-onclick=>"
				var networks='';
				var msg='';
				for(i=1;i<document.$FORMNAME.network_checkbox.length;i++) {
					if (document.$FORMNAME.network_checkbox[i].checked) {
						msg+=i + '=' + 'checked\\n';		
						networks+=document.$FORMNAME.network_checkbox[i].value + ',';
					}	
				}
				var re=/,\$/;
				networks=networks.replace(re,'');
				// alert(msg + '\\n' + networks);

				var del=confirm('Are you sure you want to delete the selected networks ?');
				if (del) {
					document.$FORMNAME.networks_selected.value=networks;
				} else {
					document.$FORMNAME.networks_selected.value='';
					return false;
				}
				",
			),"\n";

		print $q->submit(
			-name=>'action',
			-value=>'Ping Selected Network(s)',
			-class=>'button',
			-onclick=>"
				var networks='';
				var msg='';
				for(i=1;i<document.$FORMNAME.network_checkbox.length;i++) {
					if (document.$FORMNAME.network_checkbox[i].checked) {
						msg+=i + '=' + 'checked\\n';		
						networks+=document.$FORMNAME.network_checkbox[i].value + ',';
					}	
				}
				var re=/,\$/;
				networks=networks.replace(re,'');
				// alert(msg + '\\n' + networks);
				document.$FORMNAME.networks_selected.value=networks;
				if (networks.length == 0) {
					alert('Please select network(s)');
					return false;
				}
				",
			),"\n";

		print $q->button(
			-name=>'action',
			-value=>'Search',
			-class=>'button',
			-onclick=>"
				var url='./ipmanage_network.pl?&search_flag=1';
				SizedNewWindow(url,'search',1200,800);
				",
			),"\n";
		print "<BR>\n";
		print $q->submit(
			-name=>'refresh',
			-value=>'Refresh',
			-class=>'button',
			),"\n";
	} else {
		print $q->submit(
			-name=>'action',
			-value=>'Save Changes',
			-class=>'button',
			),"\n";
		print $q->submit(
			-name=>'cancel',
			-value=>'Cancel',
			-class=>'button',
			),"\n";
	}

	print "</DIV>\n";   # end of id=part2>
	print $q->end_center;

	if ($networks_selected eq '') {
		print <<___Refresh_HTML___;
		<SCRIPT language=javascript>
		function reload_or_updateusercount() {
			document.main.usercount.value=UserCountFrame.document.usercount.uc.value;
			document.main.csflag.value=UserCountFrame.document.usercount.csflag.value;
			document.main.usertable.value=UserCountFrame.document.usercount.usertable.value;
			if (document.main.usercount.value == -1) {
				SetCookie('$cookie_id2','','$pathinfo',-1);
				window.self.document.main.refresh.click();
			} 
			if (document.main.csflag.value == 1) {
				document.main.refresh.className="buttonalert";
				var ar="0";
				ar=GetCookie('AutoRefreshOFF');
				if (ar=="1") {
					change_text_in_id("autorefresh","Autorefresh: OFF (Refresh Required)",1);
				} else {
					DelCookie('update_warning');
					window.self.document.main.refresh.click();
				}
			}
		}
	
		function userrefresh() {
			load('./ipmanage_updateusercount.pl?&refreshrate=$update_refreshrate&who=$remote_user&validlogin=$cookie_id2',UserCountFrame);
			setTimeout('reload_or_updateusercount()',5000);
		}
	
		// call userrefresh every $update_refreshrate seconds
		setInterval('userrefresh()',$update_refreshrate * 1000);
		// call userrefresh at startup, except if Submit is pressed
		setTimeout('reload_or_updateusercount()',5000);
		</SCRIPT>
___Refresh_HTML___
	}
} #end of show_networks

if (lc($action) eq 'add network') {
	$add_network_flag=1;
} elsif (lc($action) eq 'edit selected network(s)') {
	# fine, it's in &show_networks(), we will get there anyway ;-)
} elsif (lc($action) eq 'delete selected network(s)') {
	&delete_selected_networks();
	$networks_selected='';
} elsif (lc($action) eq 'ping selected network(s)') {
	&ping_selected_networks();
	$networks_selected='';
} elsif (lc($action) eq 'save changes') {
	&save_changes();
	$networks_selected='';
} else {
	$networks_selected='';
}

&show_networks();


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
print "initialize_sticky_headers();\n";
print "mytable_resize()\n";
print "\" \n";
print "ONRESIZE=\"\n";
print "mytable_resize();\n";
print "\" \n";
print "/>\n";
### end of BODY onload ...

print $q->end_form();

