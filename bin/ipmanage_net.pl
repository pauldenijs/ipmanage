#! /usr/bin/perl
#

$|=1;

use DBI();
use Data::Dumper;
use Getopt::Std;

BEGIN {
        push (@INC,"../modules");
}

use ipmanage_config;
use sql;
use ipmanage;

sub usage () {
	print STDERR "\n";
	print STDERR "Usage: $0 [-a -c <comment> -O|o <owners> -d | -p -g <gd> -l <ld>]  [-p -d -h] network/mask \n";
	print STDERR "\t-a: add\n";
	print STDERR "\t-O <owners>: NEW owners - comma seperated list of usernames allowed to change this network\n";
	print STDERR "\t\tNote: only known users can add new owners, unless a new network is initially created\n";
	print STDERR "\t-o <owners>: add owners - comma seperated list of usernames allowed to change this network\n";
	print STDERR "\t\tNote: only known users can add new owners, unless a new network is initially created\n";
	print STDERR "\t-c: <comment>; use quotes when spaces are needed\n";
	print STDERR "\t-g: <global DNS domain>\n";
	print STDERR "\t-l: <local DNS domain>\n";
	print STDERR "\t-P: 0|1; set network to Private (0) or Public (1) (default is private!)\n";
	print STDERR "\t-d: delete\n";
	print STDERR "\t-p: print entries\n";
	print STDERR "\t-h: print usage/help\n";
	print STDERR "\tnetwork/mask: mask can be a short notation or long notation\n";
	print STDERR "\n";
}

sub show_entries {
	# if $network and $netmask given, show entries for those values, 
	# otherwise show all entries

	my ($nw,$nm)=@_;	# both entries MUST BE DECIMAL!!

	my $sql_cmd='';
	if ($nw and $nm) {
		$sql_cmd="
			SELECT 
				network,
				bitmask,
				comment,
				owners,
				global_domain,
				local_domain,
				public,
				modified,
				modifier,
				DATE_FORMAT(modified,'%d-%b-%Y %H:%i')
			FROM ip_nets
			WHERE network=$nw AND bitmask=$nm 
			ORDER BY network;
			";
	} else {
		$sql_cmd="
			SELECT 
				network,
				bitmask,
				comment,
				owners,
				global_domain,
				local_domain,
				public,
				modified,
				modifier,
				DATE_FORMAT(modified,'%d-%b-%Y %H:%i')
			FROM ip_nets
			ORDER BY network;
			";
	}

	my @info=&select_array($sql_cmd);

	foreach my $i (@info) {
		my ( 	$network,
			$bitmask,
			$comment,
			$owners,
			$global_domain,
			$local_domain,
			$public,
			$modified,
			$modifier,
			$dfmodified,
			)=@$i;
		
		printf("%15s/%s:\n",&convert_dec2ip($network),$bitmask);
		print "\tcomment:       $comment\n";
		print "\towners:        $owners\n";
		print "\tglobal domain: $global_domain\n";
		print "\tlocal domain:  $local_domain\n";
		print "\tpublic:        ";
		( $public ) ? print "Yes\n" : print "No\n";
		print "\tmodified:      $dfmodified\n";
		print "\tmodifier:      $modifier\n";
	}
}

sub add_network {
	# add new network
	my ($nw,$nm)=@_;	# both entries MUST BE DECIMAL!!

	# Lets check if network and netmask match ....
	my $network_info=&ip_and_network_info($nw,$nm);
	if ($network_info->{dec_network} != $nw) {
		if ($ENV{HTTP_HOST} ne '') {
			# oh, print the error also in HTML, the caller will print that in a popup
			print "<CENTER>\n";
			print "<BR>\n";
			print "<H2><FONT COLOR=#ff0000>ERROR!</FONT></H2>" , 
				" Network ip address: ", &convert_dec2ip($nw) , 
				" does not match with network mask $network_info->{netmask} (/", 
				$network_info->{bitmask}, ")!!\n";
			print "<BR>\n";
			print " The network should be: <FONT COLOR=#ff0000>", $network_info->{network}, "</FONT>\n";
			print "<BR>\n";
			print "<TABLE border=1>\n";
			print "<TR><TD>ip:</TD><TD>",$network_info->{ip},"</TD></TR>\n";
			print "<TR><TD> network:</TD><TD>",$network_info->{network},"</TD></TR>\n";
			print "<TR><TD> netmask:</TD><TD>",$network_info->{netmask},"</TD></TR>\n";
			print "<TR><TD> bitmask:</TD><TD>",$network_info->{bitmask},"</TD></TR>\n";
			print "<TR><TD> broadcast:</TD><TD>",$network_info->{broadcast},"</TD></TR>\n";
			print "<TR><TD> Number of usable ip addresses:</TD><TD>",$network_info->{nr_ips} - 2, "</TD></TR>\n";
			print "<TR><TD> Host Range:</TD><TD>",$network_info->{host_range},"</TD></TR>\n";
			print "<TR><TD> ip in hex:</TD><TD>",$network_info->{hex_ip},"</TD></TR>\n";
			print "</TABLE>\n";
			exit 10;
		} 
		print STDERR "ERROR\n";
		print STDERR " Network ip address: ", &convert_dec2ip($nw) , 
			" does not match with network mask $network_info->{netmask} (/", 
			$network_info->{bitmask}, ")!!\n";
		print STDERR " The network should be: ", $network_info->{network}, "\n";
		print STDERR "\n";
		print STDERR " ip:                            $network_info->{ip}\n";
		print STDERR " network:                       $network_info->{network}\n";
		print STDERR " netmask:                       $network_info->{netmask}\n";
		print STDERR " bitmask:                       $network_info->{bitmask}\n";
		print STDERR " broadcast:                     $network_info->{broadcast}\n";
		print STDERR " Number of usable ip addresses: " , $network_info->{nr_ips} - 2, "\n";
		print STDERR " Host Range:                    $network_info->{host_range}\n";
		print STDERR " ip in hex:                     $network_info->{hex_ip}\n";
		exit 1;
	}

	# lets' see if this network with bitmap is available ...
	my $nw_start=$nw;
	my $nw_end=$nw + 2**(32-$nm) - 1;

	my @networks=&select_array("SELECT network,bitmask,comment,owners,modified,modifier FROM ip_nets ORDER BY network;");
	
	foreach my $e (@networks) {
		my ($db_nw_start, $db_bitmask, $db_comment, $db_owners, $db_modified, $db_modifier)=@$e;
		my $db_nw_end=$db_nw_start + 2**(32-$db_bitmask) - 1;

		# print STDERR "\$nw_start=$nw_start \$nw_end=$nw_end \$db_nw_start=$db_nw_start \$db_nw_end=$db_nw_end \$db_bitmask=$db_bitmask\n";

		if ($db_nw_start >= $nw_start and $db_nw_start <= $nw_end and $db_nw_end >= $nw_end) {
			print STDERR "ERROR(): Entry ", $network_info->{network}, "/", $network_info->{bitmask}, " overlaps following network:\n";
			&show_entries($db_nw_start,$db_bitmask);
			exit 1;
		}
		if ($db_nw_start <= $nw_start and $db_nw_end >= $nw_end) {
			print STDERR "ERROR(): Entry ", $network_info->{network}, "/", $network_info->{bitmask}, " overlaps following network:\n";
			&show_entries($db_nw_start,$db_bitmask);
			exit 1;
		}
		if ($db_nw_start >= $nw_start and $db_nw_end <= $nw_end) {
			print STDERR "ERROR(): Entry ", $network_info->{network}, "/", $network_info->{bitmask}, " overlaps following network:\n";
			&show_entries($db_nw_start,$db_bitmask);
			exit 1;
		}
		if ($db_nw_start <= $nw_start and $db_nw_end >= $nw_start and $db_nw_end <= $nw_end) {
			print STDERR "ERROR(): Entry ", $network_info->{network}, "/", $network_info->{bitmask}, " overlaps following network:\n";
			&show_entries($db_nw_start,$db_bitmask);
			exit 1;
		}
	} 

	# Entry is available, just add it !
	$new_entry->{network}=$nw;
	$new_entry->{bitmask}=$nm;
}

sub ok2change {
	# returns 1 if modifier ($r_user) is in the list of owners or is the modifier
	# if modifier and owners do not exist or is empy, return 1 as well, since this is a new entry
	my ($nw,$nm,$user)=@_;	# both $nw and $nm MUST BE DECIMAL!!

	# of course the last modifier should be allowed to change stuff as well ;-)
	my $last_modifier=select1("SELECT modifier FROM ip_nets WHERE network=$nw AND bitmask=$nm LIMIT 1");

	my $current_list=&select1("SELECT owners FROM ip_nets WHERE network=$nw AND bitmask=$nm LIMIT 1");

	my @current_owners=split /\s+/,$current_list;
	if ($last_modifier ne '') {
		@current_owners=(@current_owners,$last_modifier);
	}

	my $ok_2_change=0;
	if (! @current_owners) {
		$ok_2_change++;
	} else {
		foreach my $u (@current_owners,'admin','root') { 	# admin and root are always allowed
			if ($u eq $user) {
				$ok_2_change++;
				last;
			}
		}
	}
	if ($ok_2_change) {
		return(1);
	} else {
		print STDERR "Sorry, You have no permissions to change this record!\n";
		return(0);
	}
}

sub change_comment {
	# change comment for the given network/netmask 
	my ($nw,$nm,$comment,$user)=@_;	# both $nw and $nm MUST BE DECIMAL!!, $comment is a string

	my $ok_2_change=&ok2change($nw,$nm,$user);

	$new_entry->{network}=$nw;
	$new_entry->{bitmask}=$nm;

	if ($comment eq 'NULL') {
		$comment='';
	}

	$new_entry->{comment}=$comment;
}

sub change_global_domain {
	# change global_domain for the given network/netmask 
	my ($nw,$nm,$global_domain,$user)=@_;	# both $nw and $nm MUST BE DECIMAL!!, $global_domain is a string

	my $ok_2_change=&ok2change($nw,$nm,$user);

	$new_entry->{network}=$nw;
	$new_entry->{bitmask}=$nm;

	$global_domain=&trimstr($global_domain);

	if ($global_domain !~ /^([0-9A-z-\.]+)$/ ) {
		print STDERR "Illegal character in \"global domain name\" \n";
		exit 1;
	}

	if ($global_domain eq 'NULL') {
		$global_domain='';
	}

	$new_entry->{global_domain}=$global_domain;
}

sub change_local_domain {
	# change local_domain for the given network/netmask 
	my ($nw,$nm,$local_domain,$user)=@_;	# both $nw and $nm MUST BE DECIMAL!!, $local_domain is a string

	my $ok_2_change=&ok2change($nw,$nm,$user);

	$new_entry->{network}=$nw;
	$new_entry->{bitmask}=$nm;

	$local_domain=&trimstr($local_domain);

	if ($local_domain !~ /^([0-9A-z-\.]+)$/ ) {
		print STDERR "Illegal character in \"local_domain name\" \n";
		exit 1;
	}

	if ($local_domain eq 'NULL') {
		$local_domain='';
	}

	$new_entry->{local_domain}=$local_domain;
}

sub change_public_private {
	# change local_domain for the given network/netmask 
	my ($nw,$nm,$public,$user)=@_;	# both $nw and $nm MUST BE DECIMAL!!, $public is 0 or 1 

	my $ok_2_change=&ok2change($nw,$nm,$user);

	$new_entry->{network}=$nw;
	$new_entry->{bitmask}=$nm;

	$new_entry->{public}=$public;
}

sub change_owners {
	# change owners for the given network/netmask 
	my ($nw,$nm,$owners,$user)=@_;	# both $nw and $nm MUST BE DECIMAL!!, $owners is a comma/blank seperated string

	my $ok_2_change=&ok2change($nw,$nm,$user);

	$new_entry->{network}=$nw;
	$new_entry->{bitmask}=$nm;

	if ($owners eq 'NULL') {
		$owners='';
	}

	# make sure the $owners do not have spaces. if there are spaces, replace them with a comma
	$owners=~s/\s+/,/g;

	# now replace the owners with the new list ($owners), and make sure the list doesn't contain double entries.
	my $owners_hash;
	foreach my $o (split /,/, $owners) {
		$owners_hash->{$o}=1;
	}

	$owners='';
	foreach my $k (sort keys %{$owners_hash} ){
		$owners.=" $k";
	}
	$owners=~s/^\s+//;
	$new_entry->{owners}=$owners;
}

sub add_owners {
	# add owners for the given network/netmask 
	my ($nw,$nm,$owners,$user)=@_;	# both $nw and $nm MUST BE DECIMAL!!, $owners is a comma/blank seperated string

	my $ok_2_change=&ok2change($nw,$nm,$user);

	$new_entry->{network}=$nw;
	$new_entry->{bitmask}=$nm;

	my $current_list=&select1("SELECT owners FROM ip_nets WHERE network=$nw AND bitmask=$nm LIMIT 1");
	my @current_owners=split /\s+/, $current_list;

	# make sure the $owners do not have spaces. if there are spaces, replace them with a comma
	$owners=~s/\s+/,/g;
	# now replace the owners with the new list ($owners), and make sure the list doesn't contain double entries.
	my @new_owners=split /,/, $owners;
	foreach my $o (@current_owners,@new_owners) {
		$owners_hash->{$o}=1;
	}

	$owners='';
	foreach my $k (sort keys %{$owners_hash} ){
		$owners.=" $k";
	}
	$owners=~s/^\s+//;
	$new_entry->{owners}=$owners;
}

sub delete_network {
	# delete given network/netmask 
	my ($nw,$nm,$user)=@_;	# both $nw and $nm MUST BE DECIMAL!!, $owners is a comma/blank seperated string

	my $ok_2_change=&ok2change($nw,$nm,$user);

	my $sql_cmd="DELETE FROM ip_nets WHERE network=$nw AND bitmask=$nm;";
	&do_row($sql_cmd);
}

### MAIN ##################################################################################################### 
getopts('o:O:c:Z:g:l:P:adph', \%opts);


foreach my $k (keys %opts) {
	# print STDERR "option $k (", $opts{$k}, ") \n";

	if ($k eq "O" and $opts{O} eq '') {
		# oh you want to CLEAR all owners!
		$opts{O}="NULL";
	}
	if ($k eq "c" and $opts{c} eq '') {
		# oh you want to CLEAR the comment
		$opts{c}="NULL";
	}
	if ($k eq "g" and $opts{g} eq '') {
		# oh you want to CLEAR the global DNS domain
		$opts{g}="NULL";
	}
	if ($k eq "l" and $opts{l} eq '') {
		# oh you want to CLEAR the local DNS domain
		$opts{l}="NULL";
	}
	if ($k eq "P" and ($opts{P} < 0 or $opts{P} > 1)) {
		print STDERR "-P must be 0 or 1\n";
		usage();
		exit 1;
	} 
	
}

if ($opts{h}) {
	&usage();
	exit;
}

my ($r_name,$r_passwd,$r_uid,$r_gid,$r_quota,$r_comment,$r_gcos,$r_dir,$r_shell)=getpwuid($>);

if ($opts{Z} ne '' and $ENV{HTTP_HOST} ne '') {
	# REMOTE_USER (if called from CGI)
	$r_name=$opts{Z};
}

my ($network_dotted,$mask)=split /\//, $ARGV[0], 2;
my $netmask_dotted="";

if ($network_dotted eq "" and $mask eq "" and $opts{p}) {
	show_entries(0,0);
	exit;
}

if (! &check_ip($network_dotted)) {
	&usage();
	exit 1;
}

if ($mask >=0 and $mask<=32) {
	$netmask_dotted=&short_nm2long($mask);
} else {
	$netmask_dotted=$mask;
}

if (! &check_ip($netmask_dotted)) {
	&usage();
	exit 1;
}

$network_dec=&convert_ip2dec($network_dotted);
$bitmask=&long_nm2short($netmask_dotted);

if ($opts{p}) {
	show_entries($network_dec,$bitmask);
	exit;
}
my @old_entry=&select_1dim_array("SELECT network,bitmask,comment,owners,global_domain,local_domain,public,modified,modifier FROM ip_nets WHERE network=$network_dec and bitmask=$bitmask LIMIT 1;");
($o_network,$o_bitmask,$o_comment,$o_owners,$o_global_domain,$o_local_domain,$o_public,$o_modified,$o_modifier)=@old_entry;
$new_entry->{network}=$o_network;
$new_entry->{bitmask}=$o_bitmask;
$new_entry->{comment}=$o_comment;
$new_entry->{owners}=$o_owners;
$new_entry->{global_domain}=$o_global_domain;
$new_entry->{local_domain}=$o_local_domain;
$new_entry->{public}=$o_public;

my $sql_cmd='';
my $now=&date_now();

if (! &ok2change($network_dec,$bitmask,$r_name)) {
	exit 1;
}

if (! $opts{a}) {
	if (! $o_network) {
		print STDERR "Entry \"$network_dotted/$mask\" does not exist. Use the -a option to add.\n";
		exit 1; 
	}
}

if ($opts{d}) {
	&delete_network($network_dec,$bitmask,$r_name);
} else {
	if ($opts{a} ne '') {
		&add_network($network_dec,$bitmask);
	}
	if ($opts{c} ne '') {
		&change_comment($network_dec,$bitmask,$opts{c},$r_name);
	}
	if ($opts{g} ne '') {
		&change_global_domain($network_dec,$bitmask,$opts{g},$r_name);
	}
	if ($opts{l} ne '') {
		&change_local_domain($network_dec,$bitmask,$opts{l},$r_name);
	}
	if ($opts{P} ne '') {
		&change_public_private($network_dec,$bitmask,$opts{P},$r_name);
	}
	if ($opts{O} ne '' or $opts{o} ne '') {
		if ($opts{O} ne '') {
			&change_owners($network_dec,$bitmask,$opts{O},$r_name);
		}
		if ($opts{o} ne '') {
			&add_owners($network_dec,$bitmask,$opts{o},$r_name);
		}
	}
	# let's check if we actually made any changes. if everything stays the same, just quit ...
	if (	$new_entry->{network} == $o_network and 
		$new_entry->{bitmask} eq $o_bitmask and 
		$new_entry->{comment} eq $o_comment and 
		$new_entry->{owners} eq $o_owners  and 
		$new_entry->{global_domain} eq $o_global_domain  and 
		$new_entry->{local_domain} eq $o_local_domain  and 
		$new_entry->{public} == $o_public
		) {
		print STDERR "Geez, no changes! \n";
		exit 0;
	}

	$enter_comment=$new_entry->{comment};
	$enter_comment=~s/'/\\'/g;
	my $network_dotted=&convert_dec2ip($new_entry->{network});

	if ($o_network and $o_bitmask) {
		&delete_network($network_dec,$bitmask,$r_name);
	}

	$sql_cmd="
		INSERT INTO ip_nets (
			network,
			network_dotted,
			bitmask,
			comment,
			owners,
			global_domain,
			local_domain,
			public,
			modified,
			modifier
		)
		VALUES (
			$new_entry->{network},
			'$network_dotted',
			$new_entry->{bitmask},
			'$new_entry->{comment}',
			'$new_entry->{owners}',
			'$new_entry->{global_domain}',
			'$new_entry->{local_domain}',
			'$new_entry->{public}',
			$now,
			'$r_name'
		);";
	#print STDERR "\n$sql_cmd\n";
	&do_row($sql_cmd);
}

# if the record has been changed/deleted, save the original date to table ip_hosts_history.
# there are 3 types of modifications:
#       deleted: record has been deleted totally
#       changed: record has hostname and/or aliases changed
#       modified: record has non-significant data changed, like comments etc, not important for 'operation'

$mod_type='unknown';



# if this was a totally new entry, we don't need to save anything!
if (@old_entry) {       # aha, old entry existed, save it, we made changes!
	if ($opts{d}) {
		$mod_type='deleted';
	} else {
		if ($new_entry->{comment} ne $o_comment) {
			$mod_type='modified';
		}
		if ($new_entry->{owners} ne $o_owners) {
			$mod_type='changed';
		}
	}

	$enter_comment=$o_comment;
	$enter_comment=~s/'/\\'/g;
	my $network_dotted=&convert_dec2ip($o_network);

	$sql_cmd="
		INSERT INTO ip_nets_history (
			network,
			network_dotted,
			bitmask,
			comment,
			owners,
			global_domain,
			local_domain,
			public,
			old_modified,
			old_modifier,
			modified,
			modifier,
			mod_type
		)
		VALUES (
			$o_network,
			'$network_dotted',
			$o_bitmask,
			'$o_comment',
			'$o_owners',
			'$o_global_domain',
			'$o_local_domain',
			$o_public,
			'$o_modified',
			'$o_modifier',
			$now,
			'$r_name',
			'$mod_type'
		);";
	#print STDERR "\n$sql_cmd\n";
	&do_row($sql_cmd);
}
