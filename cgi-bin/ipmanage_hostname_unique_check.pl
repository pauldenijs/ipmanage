#! /usr/bin/perl

use CGI;
use CGI::Carp qw(fatalsToBrowser);
use CGI::Cookie;
use File::Basename;
use Data::Dumper;
$q = new CGI;

BEGIN {
	push (@INC,"../modules");
}

use ipmanage_config;
use ipmanage_commoncgi;
use ipmanage;
use sql;

$ip=			$q->param('ip');
$hostname=		$q->param('hostname');
$aliases=		$q->param('aliases');

$editfield_count=	$q->param('editfield_count');
$selected_nr=		$q->param('selected_nr');
$calling_form=		$q->param('calling_form');

if ($debug) {
	print STDERR "================= PARAMETERS ($my_own_url)====================\n";
	foreach my $key ($q->param()) {
		print STDERR "key:" , $key , ",value:" ,$q->param($key),"\n";
	}
	print STDERR "================= END PARAMETERS ====================\n";
}

if ($editfield_count eq '') {
	$editfield_count=0;
}
$selected_nr--;

sub get_ips {
        my ($hname)=@_;
        my ($name,$aliases,$addrtype,$length,@addrs)=gethostbyname($hname);
        my @ip_array=();
        foreach my $i (@addrs) {
                my ($a,$b,$c,$d)=unpack('C4',$i);
		my $ip_str=$a . "." . $b . "." . $c . "." . $d;
                push @ip_array,$ip_str;
        }
        return($name,@ip_array);
}


print $q->header(),"\n";

my $name2check_hash=();
foreach my $name ((split /\s+/, $aliases),$hostname)  {
	next if ($name eq '');
	$names2check->{$name}=1;
}

# print STDERR "names2check: ", Dumper($names2check),"\n";

$hostname_hash=();

# look for the hostname in the database in column hostname OR column aliases
if ($hostname ne '') {
	$sql_cmd="SELECT ip,hostname,aliases FROM ip_hosts WHERE hostname='$hostname' OR aliases rlike ('$hostname');";
	print STDERR $sql_cmd,"\n";
	foreach my $b (&select_array($sql_cmd)) {
		my ($db_ip,$db_hostname,$db_aliases)=@$b;
		if ($db_ip != $ip) {
			foreach my $c ((split /\s+/,$db_aliases),$db_hostname) {
				if ($names2check->{$c} == 1) {
					push @{$hostname_hash->{$hostname}->{'[DATABASE]'}->{ip}},&convert_dec2ip($db_ip);
				}
			}
		}
	}
}

foreach my $a (split /\s+/, $aliases) {
	# now look for all the aliases in column hostname or column aliases 
	$sql_cmd="SELECT ip,hostname,aliases FROM ip_hosts WHERE aliases rlike ('$a') OR hostname='$a';";
	print STDERR $sql_cmd,"\n";
	foreach my $b (&select_array($sql_cmd)) {
		my ($db_ip,$db_hostname,$db_aliases)=@$b;
		if ($db_ip != $ip) {
			foreach my $c ((split /\s+/,$db_aliases),$db_hostname) {
				if ($names2check->{$c} == 1) {		# $c is name we need to check ....
					push @{$hostname_hash->{$a}->{'[DATABASE]'}->{ip}},&convert_dec2ip($db_ip);
				}
			}
		}
	}
}
	
foreach my $name ((split /\s+/, $aliases),$hostname)  {
	next if ($name eq '');
	my ($fullname,@ip_array)=&get_ips($name);
	foreach my $e (@ip_array) {
		if (convert_ip2dec($e) != $ip and $e ne '') { 
			my ($n,$d)=split /\./,$fullname,2;
			if ($n,$name) { 
				push @{$hostname_hash->{$name}->{$d}->{ip}},$e;
			} else {
				push @{$hostname_hash->{$name}->{$d}->{ip}},$e;
			}
		}
	}
}

# print STDERR Dumper($hostname_hash),"\n";

print $q->start_form(-name=>check)."\n";
print "<TABLE>\n";
for ($i=0;$i<1;$i++) {
	print "<TR>";
	print "<TD>";
	print $q->textfield(-name=>'hostname', -value=>'dummy',-override=>1),"\n";
	print "</TD>";
	print "<TD>";
	print $q->textfield(-name=>'domainname', -value=>'dummy',-override=>1),"\n";
	print "</TD>";
	print "<TD>";
	print $q->textfield(-name=>'ip', -value=>'dummy',-override=>1),"\n";
	print "</TD>";
	print "</TR>";
}

foreach my $name (keys %{$hostname_hash}) {
	print STDERR "> $name\n";
	foreach my $dom (keys %{$hostname_hash->{$name}}) {
		print STDERR "> $name > $dom\n";
		foreach my $e (sort @{$hostname_hash->{$name}->{$dom}->{ip}}) {
			print "<TR>";
			print "<TD>";
			print $q->textfield(-name=>'hostname', -value=>$name,-override=>1, -id=>'frame_text'),"\n";
			print "</TD>";
			print "<TD>";
			print $q->textfield(-name=>'domainname', -value=>$dom,-override=>1),"\n";
			print "</TD>";
			print "<TD>";
			print $q->textfield(-name=>'ip', -value=>$e,-override=>1),"\n";
			print "</TD>";
			print "</TR>";
		}
	}
}

print "</TABLE>\n";
print $q->end_form(),"\n";

print <<___JS___;
<SCRIPT LANGUAGE=javascript>
var rows=$selected_nr;
var editfield_count=$editfield_count;
if (rows) {
	parent.document.$calling_form.hostname[$editfield_count].style.color='#000000';
	parent.document.$calling_form.aliases[$editfield_count].style.color='#000000';
} else {
	parent.document.$calling_form.hostname.style.color='#000000';
	parent.document.$calling_form.aliases.style.color='#000000';
}
parent.document.$calling_form.duplicate_hostname_check_error.value='';
parent.document.getElementById('save_changes').className='button';

if (document.check.hostname.length >1) {
	parent.document.$calling_form.duplicate_hostname_check_error.value='ERROR';
	parent.document.getElementById('save_changes').className='BUTTONdisabled';
	var msg="You specified a hostname that already exist:\\n";
	for (i=1;i<document.check.hostname.length;i++) {
		var ip=document.check.ip[i].value;
		var hostname=document.check.hostname[i].value;
		var domainname=document.check.domainname[i].value;
		var fullname=hostname;
		if (domainname != '' && domainname != "[DATABASE]") {
			fullname+="." + domainname;
		}
		if (rows) {
			if (hostname == parent.document.$calling_form.hostname[$editfield_count].value) {
				if (domainname=="[DATABASE]") {
					msg+=hostname + " " + ip + " (database)\\n";
				} else {
					if (fullname != hostname) {
						msg+=hostname + " " + ip + " (" + fullname + ")\\n";
					} else {
						msg+=hostname + " " + ip + "\\n";
					}
				}
				parent.document.$calling_form.hostname[$editfield_count].style.color='#ff0000';
			}
			var a=parent.document.$calling_form.aliases[$editfield_count].value.split(/\\s+/);
			for (j=0;j<a.length;j++) {
				if (hostname == a[j]) {
					if (domainname=="[DATABASE]") {
						msg+=hostname + " " + ip + " (database)\\n";
					} else {
						if (fullname != hostname) {
							msg+=hostname + " " + ip + " (" + fullname + ")\\n";
						} else {
							msg+=hostname + " " + ip + "\\n";
						}
					}
					parent.document.$calling_form.aliases[$editfield_count].style.color='#ff0000';
				}
			}

			// see if we did not use these names before when editing multiple rows
			var h_array=new Array();
			for(i=0;i<parent.document.$calling_form.hostname.length;i++) {
				if (i == editfield_count) {
					continue;
				}
				if (hostname == parent.document.$calling_form.hostname[i].value) { 
					msg+=hostname + " " + parent.document.$calling_form.ip[i].value + " (form)\\n";
				}
				var a=parent.document.$calling_form.aliases[i].value.split(/\\s+/);
				for (j=0;j<a.length;j++) {
					if (a[j] != '') {
						msg+=a[j] + " " + parent.document.$calling_form.ip[i].value + " (form)\\n";
					}
				}
			}	
		} else {
			if (hostname == parent.document.$calling_form.hostname.value) {
				if (domainname=="[DATABASE]") {
					msg+=hostname + " " + ip + " (database)\\n";
				} else {
					if (fullname != hostname) {
						msg+=hostname + " " + ip + " (" + fullname + ")\\n";
					} else {
						msg+=hostname + " " + ip + "\\n";
					}
				}
				parent.document.$calling_form.hostname.style.color='#ff0000';
			}
			var a=parent.document.$calling_form.aliases.value.split(/\\s+/);
			for (j=0;j<a.length;j++) {
				if (hostname == a[j]) {
					if (domainname=="[DATABASE]") {
						msg+=hostname + " " + ip + " (database)\\n";
					} else {
						if (fullname != hostname) {
							msg+=hostname + " " + ip + " (" + fullname + ")\\n";
						} else {
							msg+=hostname + " " + ip + "\\n";
						}
					}
					parent.document.$calling_form.aliases.style.color='#ff0000';
				}
			}
		}
	}

	msg+="\\nFields are in red\\n"; 
	msg+="\\nIf this is intentional, you can override this check by checking the box in the 'duplicate' column, next to the Aliases.\\n"; 
	alert(msg);
}
</SCRIPT>
___JS___


