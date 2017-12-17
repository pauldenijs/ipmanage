#! /usr/bin/perl
#

$|=1;

use Data::Dumper;
use Getopt::Std;

BEGIN {
        push (@INC,"../modules");
}

use ipmanage_config;
use sql;
use ipmanage;

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

sub usage () {
	print STDERR "\n";
	print STDERR "Usage: $0 [ -n <hostname> -a <aliases> -c <comment> -d | -p] ip_address\n";
	print STDERR "\t-n: add/change hostname; unique hostname\n";
	print STDERR "\t-A: replace with NEW aliases; comma/space seperated list of aliases\n";
	print STDERR "\t-a: add aliases to existing ones; comma/space seperated list of aliases\n";
	print STDERR "\t-c: add/change comment; use quotes when spaces are needed\n";
	print STDERR "\t-d: delete; delete all entries for the ip_address\n";
	print STDERR "\t-f: Force; allow duplicate hostnames/aliases for this ip_address\n";
	print STDERR "\t-p: print; print entries\n";
	print STDERR "\t-h: print usage/help\n";
	print STDERR "\tip_address; in dotted notation\n";
	print STDERR "\n";
}

sub get_network_info_for_ip {
	# input is ip address (decimal) the returns the network. $network_hash is must be a GLOBAL variable!!!!!
	my ($ip)=@_;

	if (! $network_hash) {
		print STDERR "??? no \$network_hash ?\n";
	}
	
	foreach my $k (sort keys %{$network_hash} ) {
		if ($ip >= $network_hash->{$k}->{network} and $ip <= $network_hash->{$k}->{broadcast}) {
			return $k;
		} 
	}
}

sub show_entries {
	my ($ip)=@_;	# MUST BE DECIMAL!!

	my $sql_cmd='';
	if ($ip) {
		$sql_cmd="
			SELECT ip,hostname,aliases,comment,modified,modifier,DATE_FORMAT(modified,'%d-%b-%Y %H:%i')
			FROM ip_hosts
			WHERE ip=$ip
			ORDER BY ip;
			";
	} else {
		$sql_cmd="
			SELECT ip,hostname,aliases,comment,modified,modifier,DATE_FORMAT(modified,'%d-%b-%Y %H:%i')
			FROM ip_hosts
			WHERE ip != 0
			ORDER BY ip;
			";
	}

	my @info=&select_array($sql_cmd);


	foreach my $i (@info) {
		my ($i_ip,$i_hostname,$i_aliases,$i_comment,$i_modified,$i_modifier,$i_dfmodified)=@$i;
		my $ip_network=&get_network_info_for_ip($i_ip);

		my $host_nr=$i_ip - $network_hash->{$ip_network}->{network};
		my $bm=$network_hash->{$ip_network}->{bitmask};
		my $ip_dec=&convert_dec2ip($i_ip);
		printf (" %s/%d: (#%d)\n",$ip_dec,$bm,$host_nr);
		print  "\thostname: $i_hostname\n";
		print  "\taliases:  $i_aliases\n";
		print  "\tcomment:  $i_comment\n";
		print  "\tmodified: $i_dfmodified\n";
		print  "\tmodifier: $i_modifier\n";
	}
}

sub allowed_user {
	my ($user,$users2check)=@_;
	# check if the $user is in $users2check
	foreach my $u (split /\s+/, $users2check) {
		if ($u eq $user) {
			return 1;
		}
	}
	return 0;
}

sub get_network_for_ip_and_allowed_user {
	# get the network info for the given ip_address and the ok to change the entry

	my ($ip,$user)=@_;
	my @networks=&get_all_networks;

	foreach my $e (@networks) {
		my ($network,$bitmask,$comment,$owners,$modified,$modifier)=@$e;
		# print STDERR "[$ip,$network,$bitmask,$comment,$owners,$modified,$modifier]\n";
		my $broadcast=2**(32-$bitmask) + $network - 1; 
		if ($ip >= $network and $ip <= $broadcast) {
			my $allowed_modifiers=$owners . " " . $modifier . " " . "admin" . " " . "root";
			$allowed_modifiers=trimstr($allowed_modifiers);
			my $mod_flag=0;
			foreach my $u (split /\s+/, $allowed_modifiers) {
				if ($u eq $user) {
					$mod_flag++;
					last;
				}
			}
			return($mod_flag,@$e);
		} 
	}
	return(0);
}

sub check_unique_hostname {
	# checks if the hostnames are unique, for other than the requested ip address exits if not unique
	# $hostnames is a string with names
	my ($ip,$hostnames)=@_;

	# first query the database for hostnames that are already there, we don't want duplicates.
	$sql_cmd="SELECT ip,hostname FROM ip_hosts WHERE ip!=$ip;";
	# print STDERR "$sql_cmd\n";
	my @existing_hostnames=&select_array($sql_cmd);

	# now query the database for aliases 
	$sql_cmd="SELECT ip,aliases FROM ip_hosts WHERE ip!=$ip;";
	# print STDERR "$sql_cmd\n";
	my @existing_aliases=&select_array($sql_cmd);

	my $host_hash;
	foreach my $e (@existing_hostnames) { 
		my ($e_ip,$e_hostname)=@$e;
		$host_hash->{$e_hostname}=$e_ip;
	}

	foreach my $e (@existing_aliases) { 
		my ($e_ip,$e_aliases)=@$e;
		foreach my $a (split /\s+/, $e_aliases) {
			$host_hash->{$a}=$e_ip;
		}
	}

	# let's set up a list of ip addresses and names if the -D option is used to allow duplicate hostnames!
	# the should go into the database if they are discovered, and we should NOT exit here
	# to make it easy to maintain duplicates, it's a good practice to update the list with every change.
	# since we always check for duplicates, just do NOT exit when the -D option (allow duplicate hostnames/aliases) is used.

	my $duplicate_error="";

	foreach my $hostname (split /\s+/, $hostnames) {
		if ($host_hash->{$hostname}) {
			if (! $opts{f}) {
				$duplicate_error.=sprintf("Hostname/Alias \"%s\" already exist and has ip address: %s\n",  $hostname, &convert_dec2ip($host_hash->{$hostname}));
			} else {
				push @{$duplicates_byname_hash->{$hostname}},$ip;
				push @{$duplicates_byname_hash->{$hostname}},$host_hash->{$hostname};
				$duplicates_flag++;
			}
		}
	}

	my ($network,$bitmask,$comment,$owners,$modified,$modifier)=get_network_for_ip($ip);
	my @domains;
	push @domains, $network_hash->{$network}->{global_domain} if ($network_hash->{$network}->{global_domain} ne '');
	push @domains, $network_hash->{$network}->{local_domain} if ($network_hash->{$network}->{local_domain} ne '');

	### now check the our domains !!!!
	foreach my $hostname (split /\s+/, $hostnames) {
		foreach my $d (@domains,'' ) {
			my $h=$hostname . "." . $d;
			if ($d eq '') {
				$h=$hostname;
			}
			my @ip_array=&get_host_ips($h);				# ip_array is array with dotted ip's
			my @ip_array_simple=();
			if ($hostname ne $h) {
				@ip_array_simple=&get_host_ips($hostname);		# ip_array is array with dotted ip's
			}
			next if (scalar @ip_array == 0);
			foreach my $e (@ip_array,@ip_array_simple) {
				my $q_ip_dec=&convert_ip2dec($e);
				if ($q_ip_dec != $ip) {
					if (! $opts{f}) {
						$duplicate_error.=sprintf("Hostname/Alias \"%s (%s)\" already exist and has ip address: %s\n", $hostname,$h,$e);
					} else {
						push @{$duplicates_byname_hash->{$hostname}},$ip;
						push @{$duplicates_byname_hash->{$hostname}},$q_ip_dec;
						$duplicates_flag++;
					}
				}
			}
		}
	}

	if ($duplicate_error ne '') {
		if ($opts{Z} ne '' and $ENV{HTTP_HOST} ne '') {
			$oops=$duplicate_error;
			$oops=~s/\(/\\\(/g;
			$oops=~s/\)/\\\)/g;
			$oops=~s/"//g;
			print $oops;
		}
		print STDERR $duplicate_error;
		exit 1;
	}

	# clean up the $duplicates_byname_hash, there might be duplicate ip addresses with each name ...
	foreach my $k (keys %{$duplicates_byname_hash}) {
		my $tmp_hash=();
		foreach my $i (@{$duplicates_byname_hash->{$k}}) {
			$tmp_hash->{$i}=1;
		}
		delete $duplicates_byname_hash->{$k};
		my @tmp_array=();
		foreach my $l (keys %{$tmp_hash}) {
			push @{$duplicates_byname_hash->{$k}},$l;
		}
	}
}

sub add_change_hostname {
	# add or change new hostname
	my ($hostname,$ip)=@_;	# ip MUST BE DECIMAL!!

	if ($hostname !~ /^([A-z0-9][A-z0-9-]+)$/ or $hostname =~ /^([0-9+]{1,})$/ ) {
		print STDERR "Allowable characters in a hostname :\n";
		print STDERR "\tA to Z ; upper case characters\n";
		print STDERR "\ta to z ; lower case characters\n";
		print STDERR "\t0 to 9 ; numeric characters 0 to 9\n";
		print STDERR "\t-      ; dash\n\n";

		print STDERR "\tRFC 952 and RFC 1123 say:\n"; 
		print STDERR "\tA host name (label) can start or end with a letter or a number\n";
		print STDERR "\tA host name (label) MUST NOT start or end with a '-' (dash)\n";
		print STDERR "\tA host name (label) MUST NOT consist of all numeric values\n";
		print STDERR "\tA host name (label) can be up to 63 characters\n";
		exit 1;
	}

	&check_unique_hostname($ip,$hostname);

	$new_entry->{ip_dec}=$ip;
	$new_entry->{hostname}=$hostname;
}

sub add_change_comment {
	# change comment for the given network/netmask 
	my ($comment,$ip)=@_;	# $ip MUST BE DECIMAL!!, $comment is a string

	if ($o_hostname eq '' ) {
		if ($new_entry->{hostname} eq '') {
			print STDERR "No hostname found for this ip address, comment has no use\n";
			exit 1;
		}
	}

	$new_entry->{comment}=$comment;
	if ($comment eq 'NULL') {
		$new_entry->{comment}='';
	}
}

sub add_change_aliases {
	# change aliases for the given network/netmask 
	my ($ip,$aliases)=@_;	#  $ip MUST BE DECIMAL!!, $aliases is a comma/blank seperated string

	# make a $aliases_hash with unique aliases. The numbers will indicate duplicates ...
	$aliases =~ s/,/ /g;

	if (lc($aliases) eq 'null') {
		$aliases='';
	}
	&check_unique_hostname($ip,$aliases);

	my $alias_hash;
	my $alias_hash_combined;

	# the combined  entries
	foreach my $z ((split /\s+/, $aliases),(split /\s+/, $o_aliases)) {
		if ($alias_hash_combined->{$z}) {
			$alias_hash_combined->{$z}++;
		} else {
			$alias_hash_combined->{$z}=1;
		}
	}

	# the existing entries;
	foreach my $z (split /\s+/, $o_aliases) {
		if ($alias_hash->{$z}) {
			$alias_hash->{$z}++;
		} else {
			$alias_hash->{$z}=1;
		}
	}

	# the NEW entries;
	foreach my $z (split /\s+/, $aliases) {
		if ($alias_hash_new->{$z}) {
			$alias_hash_new->{$z}++;
		} else {
			$alias_hash_new->{$z}=1;
		}
	}

	# delete the alias if it's the same as the hostname itself ...
	# but ONLY if the hostname is not specified with -n
	if ($opts{n}) {
		if ($alias_hash_combined->{lc($opts{n})}) {
			delete $alias_hash_combined->{lc($opts{n})};
		}
		if ($alias_hash->{lc($opts{n})}) {
			delete $alias_hash->{lc($opts{n})};
		}
		if ($alias_hash_new->{lc($opts{n})}) {
			delete $alias_hash_new->{lc($opts{n})};
		}
	} else {
		if ($alias_hash_combined->{$o_hostname}) {
			delete $alias_hash_combined->{$o_hostname};
		}
		if ($alias_hash->{$o_hostname}) {
			delete $alias_hash->{$o_hostname};
		}
		if ($alias_hash_new->{$o_hostname}) {
			delete $alias_hash_new->{$o_hostname};
		}
	}

	my $new_aliases='';
	foreach my $z (sort keys %{$alias_hash_combined}) {
		$new_aliases.=" " . $z;
	}
	$new_aliases=&trimstr($new_aliases);
	
	if ($opts{A}) {
		# REPLACE all aliases with the aliases list 
		if ($o_aliases ne '') {
			$new_aliases='';
			foreach my $z (sort keys %{$alias_hash_new}) {
				$new_aliases.=" " . $z;
			}
			$new_entry->{aliases}=&trimstr($new_aliases);
			if (lc($new_aliases) eq 'null') {
				$new_entry->{aliases}='';
			}
		} else {
			if (lc($new_aliases) eq 'null') {
				$new_entry->{aliases}='';
			}
			$new_entry->{aliases}=$new_aliases;
		}
	} elsif ($opts{a}) {
		$new_entry->{aliases}=$new_aliases;
	}
}

sub delete_ip {
	# delete given network/netmask 
	my ($ip)=@_;	# $ip MUST BE DECIMAL!!

	$sql_cmd="DELETE FROM ip_hosts WHERE ip=$ip;"; 
	&do_row($sql_cmd);
	if ($opts{d}) {
		# if this is only a delete, touch the ip_hosts table by inserting something at ip address 0 (0.0.0.0)
		# this will trigger a refresh !
		$sql_cmd="DELETE FROM ip_hosts WHERE ip=0;";
		&do_row($sql_cmd);
        	$sql_cmd="INSERT INTO ip_hosts (ip,ipdotted) VALUES (0,'0.0.0.0');";
		&do_row($sql_cmd);
	}

	$sql_cmd="DELETE FROM ip_hosts_duplicates WHERE ip=$ip;"; 
	&do_row($sql_cmd);
}

### MAIN ############################################################################################################################################# 
getopts('n:a:A:c:fpdhZ:D:', \%opts);

$debug=$opts{D}; 

foreach my $k (keys %opts) {
	print STDERR "option $k (", $opts{$k}, ") \n" if ($debug);

	if ($k eq "A" and $opts{A} eq '') {
		# oh you want to CLEAR all aliases!
		$opts{A}="null";
	}
	if ($k eq "c" and $opts{c} eq '') {
		# oh you want to CLEAR the comment
		$opts{c}="NULL";
	}
	if ($k eq "n" and $opts{n} eq '') {
		&usage();
		exit 1;
	}
}
print STDERR "arg: $ARGV[0]\n" if ($debug);

if ($opts{h}) {
	&usage();
	exit 0;
}

my ($r_name,$r_passwd,$r_uid,$r_gid,$r_quota,$r_comment,$r_gcos,$r_dir,$r_shell)=getpwuid($>);

if ($opts{Z} ne '' and $ENV{HTTP_HOST} ne '') {
	# REMOTE_USER (if called from CGI)
	$r_name=$opts{Z}; 
}

$network_hash=&create_network_hash;
$duplicates_byname_hash=();
$duplicates_byip_hash=();
$duplicates_flag=0;

my $ip_dotted=$ARGV[0];
if ($ip_dotted eq "") {
	show_entries(0);
	exit;
}

# is $ip_dotted a valid entry ?
if (! &check_ip($ip_dotted)) {
	&usage();
	exit 1;
}
my $ip_dec=&convert_ip2dec($ip_dotted);

if ($opts{p}) {
	show_entries($ip_dec);
	exit;
}

my @network=&get_network_for_ip_and_allowed_user($ip_dec,$r_name);
my ($ok2modify,$nw_network,$nw_bitmask,$nw_comment,$nw_owners,$nw_modified,$nw_modifier)=@network;

if ($nw_network) {
	if (! $ok2modify) {
		print STDERR "User \"$r_name\" is not allowed to edit ip addresses in network \"", &convert_dec2ip($nw_network), "/" , $nw_bitmask ,"\"\n";
		exit 1;
	}
} else {
	if (! $opts{d}) {
		print STDERR "No network defined for this ip address: \"", &convert_dec2ip($ip_dec) ,"\"\n";
		exit 1;
	}
}

### remember all entries for the given IP address. If any changes are made, save it to the history
my @old_entry=&select_1dim_array("SELECT ip,hostname,aliases,comment,modified,modifier FROM ip_hosts WHERE ip=$ip_dec LIMIT 1;");
($o_ip,$o_hostname,$o_aliases,$o_comment,$o_modified,$o_modifier)=@old_entry;
$new_entry->{ip_dec}=$o_ip;
$new_entry->{hostname}=$o_hostname;
$new_entry->{aliases}=$o_aliases;
$new_entry->{comment}=$o_comment;

my $sql_cmd='';

my $now=&date_now();

if ($opts{d}) {
	&delete_ip($ip_dec);
} else { 
	if ($opts{n} ne '') {	# hostname cannot be empty
		&add_change_hostname(lc($opts{n}),$ip_dec);
	}

	if ($opts{c}) {	 # comment can be empty
		&add_change_comment($opts{c},$ip_dec);
	}

	if ($opts{A} or $opts{a} ne '') {
		if ($opts{A}) { # alias can be empty
			&add_change_aliases($ip_dec,lc($opts{A}));
		}
	
		if ($opts{a} ne '') { # adding '' doesn't make sense ... 
			&add_change_aliases($ip_dec,lc($opts{a}));
		}
	}

	# let's check if we actually made any changes. if everything stays the same, just quit ...
	if ($new_entry->{hostname} eq $o_hostname and $new_entry->{aliases} eq $o_aliases and $new_entry->{comment} eq $o_comment) {
		exit 0;
	} 

	$enter_comment=$new_entry->{comment};
	$enter_comment=~s/'/\\'/g;

	if ($o_ip) {
		&delete_ip($ip_dec);
	}

	$now=&date_now();

	# Lets see if we actually changed/updated the hostname or aliases fields, otherwise it's not really a change (who cares about the comment ...;-)
	if ($new_entry->{hostname} eq $o_hostname and $new_entry->{aliases} eq $o_aliases) {
		# not really an update, so keep the old timestamp!
		$now=$o_modified;
	}

	$new_ip_dotted=&convert_dec2ip($new_entry->{ip_dec});

	$sql_cmd="INSERT INTO ip_hosts (
			ip,
			ipdotted,
			hostname,
			aliases,
			comment,
			modified,
			modifier
		) 
		VALUES (
			$new_entry->{ip_dec},
			'$new_ip_dotted',
			'$new_entry->{hostname}',
			'$new_entry->{aliases}',
			'$enter_comment',
			'$now',
			'$r_name'
		);";
	print STDERR "\n$sql_cmd\n" if ($debug);
	&do_row($sql_cmd);

	if ($duplicates_flag) {
		# do the duplicates ...
		print STDERR Dumper($duplicates_byname_hash),"\n" if ($debug);
		foreach my $k (keys %{$duplicates_byname_hash}) {
			foreach my $i (@{$duplicates_byname_hash->{$k}}) {
				$sql_cmd="SELECT name,ip FROM ip_hosts_duplicates WHERE ip=$i AND name='$k';"; 
				my @arr=select_array($sql_cmd);
				if ($#arr <0) {
					$sql_cmd="INSERT INTO ip_hosts_duplicates (name,ip) VALUES ('$k',$i);";
					print STDERR "\n$sql_cmd\n" if ($debug);
					&do_row($sql_cmd);
				}
			}
		}
	}
}

# if the record has been changed/deleted, save the original date to table ip_hosts_history.
# there are 3 types of modifications:
# 	deleted: record has been deleted totally
# 	changed: record has hostname and/or aliases changed
# 	modified: record has non-significant data changed, like comments etc, not important for 'operation'

$mod_type='unknown';

# if this was a totally new entry, we don't need to save anything!
if (@old_entry) {	# aha, old entry existed, save it, we made changes!
	if ($opts{d}) {
		$mod_type='deleted';
	} else {
		if ($new_entry->{comment} ne $o_comment) {
			$mod_type='modified';
		}
		if ($new_entry->{hostname} ne $o_hostname or $new_entry->{aliases} ne $o_aliases) {
			$mod_type='changed';
		} 
	}
	
	$enter_comment=$o_comment;
	$enter_comment=~s/'/\\'/g;

	$new_ip_dotted=&convert_dec2ip($o_ip);

	$sql_cmd="INSERT INTO ip_hosts_history (
			ip,
			ipdotted,
			hostname,
			aliases,
			comment,
			old_modified,
			old_modifier,
			modified,
			modifier,
			mod_type
		)
		VALUES (
			$o_ip,
			'$new_ip_dotted',
			'$o_hostname',
			'$o_aliases',
			'$enter_comment',
			'$o_modified',
			'$o_modifier',
			'$now',
			'$r_name',
			'$mod_type'
		);";
	
	print STDERR "\n$sql_cmd\n" if ($debug);
	&do_row($sql_cmd);
}

