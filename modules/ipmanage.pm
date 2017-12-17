$mailprog=	"/usr/lib/sendmail -t";

sub tmpfile_pre_post {
	my ($pre,$post)=@_;
	my $file="/tmp/$pre" .
		join("", ('a'..'z','A'..'Z',0..9)[map rand $_, (62)x16]) .
		$post;
	return $file;
}

sub myrandom {
	# returns a random string of 16 chars
	return join("", ('a'..'z','A'..'Z',0..9)[map rand $_, (62)x16]);
}

sub random_tmp_file {
	my $file="/tmp/" .
		join("", ('a'..'z','A'..'Z',0..9)[map rand $_, (62)x16]);
	return $file;
}

sub mydate {
	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime(time);
	$mon=$mon+1;
	$year=$year+1900;
}

sub yyyymmdd {
	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime(time);
	$mon=$mon+1;
	$year=$year+1900;
	my $date=sprintf("%04d%02d%02d",$year,$mon,$mday);
	return $date;
}

sub date_and_time_stamp {
	my ($sec,$min,$hour,$mday,$mon,
		$year,$wday,$yday,$isdst)=localtime(time);
	$mon=$mon+1;
	$year=$year+1900;
	my $date=sprintf("%04d-%02d-%02d %02d:%02d",
		$year,$mon,$mday,$hour,$min);
	return $date;
}

sub yyyymmddhhmmss{
	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime(time);
	$mon=$mon+1;
	$year=$year+1900;
	my $date=sprintf("%04d%02d%02d%02d%02d%02d",$year,$mon,$mday,$hour,$min,$sec);
	return $date;
}

sub sort_first_field {
	$a->[0] cmp $b->[0];
}

sub sort_1dim_host_array {			
	my (@sortarray)=@_;
	return sort {
		# these are hostnames, right ???
		# so they MUST start with a letter
		# given this, we can split each hostname in a sequence of string,number,string,number .....
		my @a_array=split(/(\d+)/, $a);
		my @b_array=split(/(\d+)/, $b);

		my ($a0,$a1,$a2,$a3,$a4,$a5,$a6,$a7,$a8,$a9)=($a,$a,$a,$a,$a,$a,$a,$a,$a,$a);
		$a0=~s/^.*$/$a_array[0]/;
		$a1=~s/^.*$/$a_array[1]/;
		$a2=~s/^.*$/$a_array[2]/;
		$a3=~s/^.*$/$a_array[3]/;
		$a4=~s/^.*$/$a_array[4]/;
		$a5=~s/^.*$/$a_array[5]/;
		$a6=~s/^.*$/$a_array[6]/;
		$a7=~s/^.*$/$a_array[7]/;
		$a8=~s/^.*$/$a_array[8]/;
		$a9=~s/^.*$/$a_array[9]/;

		my ($b0,$b1,$b2,$b3,$b4,$b5,$b6,$b7,$b8,$b9)=($b,$b,$b,$b,$b,$b,$b,$b,$b,$b);
		$b0=~s/^.*$/$b_array[0]/;
		$b1=~s/^.*$/$b_array[1]/;
		$b2=~s/^.*$/$b_array[2]/;
		$b3=~s/^.*$/$b_array[3]/;
		$b4=~s/^.*$/$b_array[4]/;
		$b5=~s/^.*$/$b_array[5]/;
		$b6=~s/^.*$/$b_array[6]/;
		$b7=~s/^.*$/$b_array[7]/;
		$b8=~s/^.*$/$b_array[8]/;
		$b9=~s/^.*$/$b_array[9]/;
		
		
		$a0 cmp $b0
		||
		$a1 <=> $b1
		||
		$a2 cmp $b2
		||
		$a3 <=> $b3
		||
		$a4 cmp $b4
		||
		$a5 <=> $b5
		||
		$a6 cmp $b6
		||
		$a7 <=> $b7
		||
		$a8 cmp $b8
		||
		$a9 <=> $b9
	} @sortarray;
}


sub sort_list {			
	my (@sortarray)=@_;
	# newer routine than above, split alpha and numeric, and then sort 
	return sort {
		# these are hostnames, right ???
		# so they MUST start with a letter
		# given this, we can split each hostname in a sequence of string,number,string,number .....
		my @a_array=split(/(\d+)/, $a);
		my @b_array=split(/(\d+)/, $b);

		my ($a0,$a1,$a2,$a3,$a4,$a5,$a6,$a7,$a8,$a9)=($a,$a,$a,$a,$a,$a,$a,$a,$a,$a);
		$a0=~s/^.*$/$a_array[0]/;
		$a1=~s/^.*$/$a_array[1]/;
		$a2=~s/^.*$/$a_array[2]/;
		$a3=~s/^.*$/$a_array[3]/;
		$a4=~s/^.*$/$a_array[4]/;
		$a5=~s/^.*$/$a_array[5]/;
		$a6=~s/^.*$/$a_array[6]/;
		$a7=~s/^.*$/$a_array[7]/;
		$a8=~s/^.*$/$a_array[8]/;
		$a9=~s/^.*$/$a_array[9]/;

		my ($b0,$b1,$b2,$b3,$b4,$b5,$b6,$b7,$b8,$b9)=($b,$b,$b,$b,$b,$b,$b,$b,$b,$b);
		$b0=~s/^.*$/$b_array[0]/;
		$b1=~s/^.*$/$b_array[1]/;
		$b2=~s/^.*$/$b_array[2]/;
		$b3=~s/^.*$/$b_array[3]/;
		$b4=~s/^.*$/$b_array[4]/;
		$b5=~s/^.*$/$b_array[5]/;
		$b6=~s/^.*$/$b_array[6]/;
		$b7=~s/^.*$/$b_array[7]/;
		$b8=~s/^.*$/$b_array[8]/;
		$b9=~s/^.*$/$b_array[9]/;
		
		
		$a0 cmp $b0
		||
		$a1 <=> $b1
		||
		$a2 cmp $b2
		||
		$a3 <=> $b3
		||
		$a4 cmp $b4
		||
		$a5 <=> $b5
		||
		$a6 cmp $b6
		||
		$a7 <=> $b7
		||
		$a8 cmp $b8
		||
		$a9 <=> $b9
	} @sortarray;
}

sub sort_array_of_array {
	my (@sortarray)=@_;
	return sort {
		# these are hostnames, right ???
		# so they MUST start with a letter
		# given this, we can split each hostname in a sequence of string,number,string,number .....
		my @a_array=split(/(\d+)/, $a->[0]);
		my @b_array=split(/(\d+)/, $b->[0]);

		my ($a0,$a1,$a2,$a3,$a4,$a5,$a6,$a7,$a8,$a9)=($a->[0],$a->[0],$a->[0],$a->[0],$a->[0],$a->[0],$a->[0],$a->[0],$a->[0],$a->[0]);
		$a0=~s/^.*$/$a_array[0]/;
		$a1=~s/^.*$/$a_array[1]/;
		$a2=~s/^.*$/$a_array[2]/;
		$a3=~s/^.*$/$a_array[3]/;
		$a4=~s/^.*$/$a_array[4]/;
		$a5=~s/^.*$/$a_array[5]/;
		$a6=~s/^.*$/$a_array[6]/;
		$a7=~s/^.*$/$a_array[7]/;
		$a8=~s/^.*$/$a_array[8]/;
		$a9=~s/^.*$/$a_array[9]/;

		my ($b0,$b1,$b2,$b3,$b4,$b5,$b6,$b7,$b8,$b9)=($b->[0],$b->[0],$b->[0],$b->[0],$b->[0],$b->[0],$b->[0],$b->[0],$b->[0],$b->[0]);
		$b0=~s/^.*$/$b_array[0]/;
		$b1=~s/^.*$/$b_array[1]/;
		$b2=~s/^.*$/$b_array[2]/;
		$b3=~s/^.*$/$b_array[3]/;
		$b4=~s/^.*$/$b_array[4]/;
		$b5=~s/^.*$/$b_array[5]/;
		$b6=~s/^.*$/$b_array[6]/;
		$b7=~s/^.*$/$b_array[7]/;
		$b8=~s/^.*$/$b_array[8]/;
		$b9=~s/^.*$/$b_array[9]/;
		
		
		$a0 cmp $b0
		||
		$a1 <=> $b1
		||
		$a2 cmp $b2
		||
		$a3 <=> $b3
		||
		$a4 cmp $b4
		||
		$a5 <=> $b5
		||
		$a6 cmp $b6
		||
		$a7 <=> $b7
		||
		$a8 cmp $b8
		||
		$a9 <=> $b9
	} @sortarray;
}

sub show_tree {
	my ($subtree,$indent)=@_;
	if (ref($subtree) eq "HASH") {
		$indent++;
		foreach my $key_item (keys %{$subtree}) {
			print STDERR "\t" x $indent;
			print STDERR "$key_item";
			my $new_item=${$subtree}{$key_item};
			# print the content if not a hash or array anymore, 
			# else walk the tree
			if (ref($new_item) eq "HASH") {
				print STDERR "\n";
				&show_tree($new_item,$indent);
			} elsif (ref($new_item) eq "ARRAY") {
				&show_tree($new_item,$indent);
			} else {
				print STDERR "=$new_item\n";
			}
		}
	} elsif (ref($subtree) eq "ARRAY") {
		my @subtree_array=@$subtree;
		for my $i (0 .. $#subtree_array) {
			my $new_item=$subtree_array[$i];
			# print the content if not a hash or array anymore, 
			# else walk the tree
			if (ref($new_item) eq "HASH") {
				print STDERR "\n";
				&show_tree($new_item,$indent);
			} elsif (ref($new_item) eq "ARRAY") {
				&show_tree($new_item,$indent);
			} else {
				print STDERR "=$new_item\n";
			}
		}
	} else {
		print STDERR "Unknown ....\n";
		return;
	} 
}

sub pwd_crypt {
	my ($pwd,$digest)=@_; 
	# $pwd  is the unencrypted password
	# $digest is one of : unix|md5|sha256|sha512

	my $unix_salt=join("", ('a'..'z','A'..'Z', 0..9)[map rand $_, (62)x2]);

	my @valid_salt = ("a".."z","A".."Z","0".."9");
	my $e_salt=join "", map { $valid_salt[rand(@valid_salt)] } 1..8;
	my $md5_salt='$1$'.$e_salt;
	my $sha256_salt='$5$'.$e_salt;
	my $sha512_salt='$6$'.$e_salt;

	my $pwd_encrypted='';

	if ($digest eq 'unix') {
		$pwd_encrypted=crypt($pwd,$unix_salt);
	} elsif ($digest eq 'md5') {
		$pwd_encrypted=crypt($pwd,$md5_salt);
	} elsif ($digest eq 'sha256') {
		$pwd_encrypted=crypt($pwd,$sha256_salt);
	} elsif ($digest eq 'sha512') {
		$pwd_encrypted=crypt($pwd,$sha512_salt);
	}

	return ($pwd_encrypted);
}

sub file_mtime2 {
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

sub date_now {
	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime(time);
	$mon=$mon+1;
	$year=$year+1900;
	my $ret_date=sprintf("%04d%02d%02d%02d%02d%02d",
	$year,$mon,$mday,$hour,$min,$sec);
	return ($ret_date);
}

sub trimstr {
	# trim leading and trailing blanks from a string
        my ($str)=@_;
        $str=~s/^\s+//;
        $str=~s/\s+$//;
        return($str);
}

sub convert_ip2hex_lower {
	# converts an ip address to hexadecimal
	my ($d_ip)=@_;
	chomp $d_ip;
	my ($ip_1,$ip_2,$ip_3,$ip_4)=split(/\./,$d_ip);
	return (sprintf("%02x%02x%02x%02x",$ip_1,$ip_2,$ip_3,$ip_4));
}

sub convert_ip2dec {
	# converts an ip address to decimal, so it's easy to subtract and add values.
	my ($d_ip)=@_;
        chomp $d_ip;
        my ($ip_1,$ip_2,$ip_3,$ip_4)=split(/\./,$d_ip);
	my $dec_value=$ip_1*256*256*256 + $ip_2*256*256 + $ip_3*256 + $ip_4;
	return ($dec_value);
}

sub convert_dec2ip_old {
	# converts an decimal ip address to a dotted notation
	my ($d_ip)=@_;
        chomp $d_ip;

	$bla='';
	$hip=sprintf("%08lx",$d_ip);
	if ($hip=~/([0-z][0-z])([0-z][0-z])([0-z][0-z])([0-z][0-z])/) {
		$d1=hex($1);
		$d2=hex($2);
		$d3=hex($3);
		$d4=hex($4);
		$bla=sprintf("%d.%d.%d.%d\t",$d1,$d2,$d3,$d4);
	}
	return $bla;
}

sub convert_dec2ip {
	# converts an decimal ip address to a dotted notation
	my ($d_ip)=@_;
        chomp $d_ip;
	# conventional way ....
	# $d1=int($d_ip /256 /256 /256);
	# $d2=int(($d_ip -$d1*256*256*256) /256 /256);
	# $d3=int(($d_ip -$d1*256*256*256 - $d2*256*256) /256);
	# $d4=int(($d_ip - $d1*256*256*256 - $d2*256*256 - $d3*256));
	# $bla=$d1 . "." . $d2 . "." . $d3 . "." . $d4;

	# quicker way, Idea came from the method above ...
	$bla = (($d_ip >> 24) & 255) . "." . (($d_ip >> 16) & 255) . "." . (($d_ip >> 8) & 255) . "." . ($d_ip & 255);
	return $bla;
}

sub dec2ip_short () {
	### this sub converts a decimal IP to a dotted IP
	my ($a)=@_;
        chomp $a;
	$ret=join '.', unpack 'C4', pack 'N', $a;
	return($ret);
}

sub ip2dec_short () {
	### this sub converts a dotted IP to a decimal IP
	my ($a)=@_;
        chomp $a;
	$ret=unpack N, pack C4, split /\./, $a;
	return($ret);
}

sub dec2bin_short {
	my ($dec)=@_;
	my $str = unpack("B32", pack("N", $dec));
	return $str;
}

sub short_nm2long() {
	my ($short_netmask)=@_;
        chomp $short_netmask;
	if (short_netmask >32) {return -1;}
	$long_netmask=2**32 - (2**(32-$short_netmask));
	return (&convert_dec2ip($long_netmask));
}

sub dec2bin {
	# this is the way you would learn it at school ;-)
	# the same way you would convert a decimal number to ANY base 
	my ($dec)=@_;
	my $bin="";     # string with 0's and 1's

	while ($dec) {
		if ($dec % 2) {
			$bin="1" . $bin;
		} else {
			$bin="0" . $bin;
		}
		$dec=int($dec/2); #loop will end if $dec < 1 (like 1/2)
	}
	return $bin;  # as a string 
}

sub dec2hex {
	# this is the way you would learn it at school ;-)
	my ($dec)=@_;
	my $hex="";     # string with 0-9 and a-f

	while ($dec) {
		my $r=$dec%16;
		if ($r >0 and $r < 10) {
			$hex=$r . $hex;
		} elsif ($r == 10 ) {
			$hex="a" . $hex;
		} elsif ($r == 11 ) {
			$hex="b" . $hex;
		} elsif ($r == 12 ) {
			$hex="c" . $hex;
		} elsif ($r == 13 ) {
			$hex="d" . $hex;
		} elsif ($r == 14 ) {
			$hex="e" . $hex;
		} elsif ($r == 15 ) {
			$hex="f" . $hex;
		} else {
			$hex="0" . $hex;
		}
		$dec=int($dec/16); #loop will end if $dec < 1 (like 1/16)
	}
	return $hex;  # as a string 
}

sub long_nm2short () {
	# check if the long netmask is realy valid. It should have in binary 
	# form, ONLY 1's followed by ONLY 0's
	# a 1 cannot be in between 0's and a 0 cannot be in between 1's 
	# and return the short netmask, return -1 if invalid

	my ($nm)=@_;
        chomp $nm;
	my @octet=split(/\./,$nm,4);
	if (scalar @octet < 3) {
		print "Not a valid netmask, must be 4 octets! \n";
		return -1;
	}

	my $binary_netmask="";
	foreach $o (@octet) {
		if ($o > 255 or $o < 0) {
			print "Invalid octet: ($o)! Values cannot be greater than 255!\n";
			return -1;
		}
		# make sure we have 8 bits length...
		my $tmp_dec2bin=sprintf("%08d",&dec2bin($o)+0);
		$binary_netmask.=$tmp_dec2bin;
		# print $tmp_dec2bin, " ";
	}
	# print "\n";

	@bin_nm_array=split //, $binary_netmask;

	my $bm_short=-1;
	# Counting the 1's will give us the short netmask.
	# Stop counting if we hit a 0 for the presumed value, but we keep on checking 
	# just to see if the netmask is stil valid  
	my $ones=0;
	my $nulls=0;
	foreach $b (@bin_nm_array) {
		$b=$b+0; 
		if ($b and !$nulls) { 
			# this is all correct, we count 1's while we haven't seen 0's
			$ones++;
		}
		if (!$b) {
			$nulls++;
		}
		if ($b and $nulls) {
			print "Not a valid netmask!\n";
			return -1;
		}
	}
	return $ones;
}

sub check_ip () {
	# returns 1 if input is a dotted ip address
	# returns 0 if input is not an ip address
	my ($ip)=@_;
        chomp $ip;
	my @octet=split(/\./,$ip,4);
	if (scalar @octet < 4) {
		print "$0: $ip is not a valid ip address, must be 4 octets! \n";
		return 0;
	}
	foreach $o (@octet) {
		if ($o > 255 or $o < 0) {
			print "Invalid octet: ($o) in $ip! Values cannot be greater than 255!\n";
			return 0;
		}
	}
	return 1;
}

sub ip_and_network_info () {
	# returns the following information in a hash:
	# ip (the requested ip,dotted)
	# hex_ip (the requested ip address in hex)
	# netmask (dotted)
	# bitmask (short netmask)
	# network (dotted)
	# broadcast (dotted)
	# host_ip_start	(first available ip that can be assigned to a host)
	# host_ip_end	(last available ip that can be assigned to a host)
	# host_range (network+1   .... broadcast-1, in other words the usable ip addresses for hosts) 
	# nr_ips (numbers of ip addresses in the network)

	# error : 1 is error
	

	my ($ip,$nm)=@_;

	my $ret;
	$ret->{error}=0;

	if ($ip !~ /^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}/ ) {
		# oh, ip is decimal, not dotted!
		$ip=&convert_dec2ip($ip);
	}

	if ($nm>=0 and $nm <=32) {
		$nm=&short_nm2long($nm);
	}

	$ret->{error}=1 if (! &check_ip($ip)); 
	$ret->{error}=1 if (! &check_ip($nm));

	my $ip_dec=&convert_ip2dec($ip);
	my $nm_dec=&convert_ip2dec($nm);

	my $network_dec=$ip_dec & $nm_dec; 
	my $network_dotted=&convert_dec2ip($network_dec);

	$ret->{ip}=$ip;
	$ret->{hex_ip}=sprintf("%08x",$ip_dec);
	$ret->{dec_ip}=$ip_dec;
	$ret->{netmask}=$nm;
	$ret->{bitmask}=&long_nm2short($nm);
	$ret->{error}=1 if ($ret->{bitmask} == -1);
	$ret->{network}=$network_dotted;
	$ret->{dec_network}=$network_dec;
	$ret->{nr_ips}=2**(32-$ret->{bitmask});        # number of ip addresses in this network
	$ret->{broadcast}=&convert_dec2ip($network_dec + $ret->{nr_ips} - 1);
	$ret->{ip_start}=$network_dotted;
	$ret->{ip_end}=&convert_dec2ip($network_dec + $ret->{nr_ips});
	$ret->{host_ip_start}=&convert_dec2ip($network_dec + 1);
	$ret->{host_ip_end}=&convert_dec2ip($network_dec + $ret->{nr_ips} - 2);
	$ret->{host_range}=$ret->{host_ip_start} . " - " . $ret->{host_ip_end};

	return($ret);
}

sub create_network_hash {
	# returns a hash to easily find out what ip address is in what network
	# use another routine with this hash with the ip address as input to get the network

	my $sql_cmd="SELECT network,network_dotted,bitmask,comment,owners,global_domain,local_domain,public,modified,modifier,DATE_FORMAT(modified,'%d-%b-%Y %H:%i') FROM ip_nets ORDER BY network;"; 
	my @networks=&select_array($sql_cmd);

	my $h;	# the hash we will return

	foreach my $i (@networks) { 
		my ($network,$network_dotted,$bitmask,$comment,$owners,$global_domain,$local_domain,$public,$modified,$modifier,$dfmodified)=@$i;
		$h->{$network}->{network}=$network;
		$h->{$network}->{network_dotted}=$network_dotted;
		$h->{$network}->{bitmask}=$bitmask;
		$h->{$network}->{netmask}=&short_nm2long($bitmask);
		$h->{$network}->{comment}=$comment;
		$h->{$network}->{owners}=$owners;
		$h->{$network}->{global_domain}=$global_domain;
		$h->{$network}->{local_domain}=$local_domain;
		$h->{$network}->{public}=$public;
		$h->{$network}->{modified}=$modified;
		$h->{$network}->{dfmodified}=$dfmodified;
		$h->{$network}->{modifier}=$modifier;
		$h->{$network}->{nr_ips}=2**(32-$bitmask);        # number of ip addresses in this network
		$h->{$network}->{broadcast}=$network + $h->{$network}->{nr_ips} - 1;
		$h->{$network}->{broadcast_dotted}=&convert_dec2ip($h->{$network}->{broadcast});
	}
	return ($h);
}

sub get_host_ip {
	my ($hostname)=@_;
	my ($name,$aliases,$addrtype,$length,@addrs)=gethostbyname($hostname);
	my $ip="";
	foreach my $i (@addrs) {
		my ($a,$b,$c,$d)=unpack('C4',$i);
		$ip="$a.$b.$c.$d";
	}
	return($ip);
}

###  geez, how stupid the get_host_ip is, one host can have MULTIPLE ip's, so return an ARRAY!
sub get_host_ips {
	my ($hostname)=@_;
	my ($name,$aliases,$addrtype,$length,@addrs)=gethostbyname($hostname);
	my @ips=();
	foreach my $i (@addrs) {
		my ($a,$b,$c,$d)=unpack('C4',$i);
		my $ip_str=$a . "." . $b . "." . $c . "." . $d;
		push @ips,$ip_str;
	}
	return(@ips);
}

sub get_all_networks {
	my $sql_cmd="SELECT network,bitmask,comment,owners,modified,modifier FROM ip_nets ORDER BY network;";
	return &select_array($sql_cmd);
}

sub get_network_for_ip {
	# get the network info for the given ip_address
	my ($ip)=@_;
	my @networks=&get_all_networks;

	foreach my $e (@networks) {
		my ($network,$bitmask,$comment,$owners,$modified,$modifier)=@$e;
		# print STDERR "[$ip,$network,$bitmask,$comment,$owners,$modified,$modifier]\n";
		my $broadcast=2**(32-$bitmask) + $network - 1;
		if ($ip >= $network and $ip <= $broadcast) {
			return(@$e);
		}
	}
	return(0);
}

sub create_duplicate_hashes {
	# returns 2 hashes, $duplicates_byname, and $duplicates_byip
	my @duplicates=select_array("SELECT name,ip FROM ip_hosts_duplicates ORDER BY ip;");
	my $duplicates_byname_hash=();
	my $duplicates_byip_hash=();
	foreach my $e (@duplicates) {
		my ($n,$i)=@$e;
		push @{$duplicates_byname_hash->{$n}},$i;
	}
	foreach my $e (@duplicates) {
		my ($n,$i)=@$e;
		if (! scalar @{$duplicates_byip_hash->{$i}->{$n}}) {
			push @{$duplicates_byip_hash->{$i}->{$n}},@{$duplicates_byname_hash->{$n}};
		}
	}
	return($duplicates_byname_hash,$duplicates_byip_hash);
}

sub check_duplicate_hostnames {
	# Look at the database table ip_hosts_duplicates and see if these entries are still duplicates.
	# It could very well be that the DNS entries take some time to propagate after an update, or the updates
	# are delayed for some reason. 
	# Whatever the scheme or workflow for DNS update is, fact is we need to check if duplicate names we 
	# flagged as duplicates need to be checked periodically. 


	# initialize the hash table
	my $check_duplicates_byname_hash=();

	$dbh->do("LOCK TABLES ip_hosts_duplicates WRITE, ip_hosts READ, ip_nets READ;");

	my $cmd="select name,ip,INET_NTOA(ip) from ip_hosts_duplicates;";
	$cmd="SELECT name,ip FROM ip_hosts_duplicates;";

	foreach my $e (&select_array($cmd)) {
		my ($hostname,$ip)=@$e;
	
		# first query the database for hostnames that are already there, we don't want duplicates.
		$sql_cmd="SELECT ip,hostname FROM ip_hosts WHERE ip!=$ip AND hostname='$hostname';";
		# print STDERR "$sql_cmd\n";
		my @existing_hostnames=&select_array($sql_cmd);
	
		# now query the database for aliases 
		$sql_cmd="SELECT ip,aliases FROM ip_hosts WHERE ip!=$ip AND aliases like '%${hostname}%';";
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

		if ($host_hash->{$hostname}) {
			# printf STDERR ("Hostname/Alias \"%s\" already exist and has ip address: %s\n",  $hostname, &convert_dec2ip($host_hash->{$hostname}));
			push @{$check_duplicates_byname_hash->{$hostname}},$host_hash->{$hostname};
		}
	
		my ($network,$bitmask,$comment,$owners,$modified,$modifier)=get_network_for_ip($ip);
		my @domains;
		push @domains, $network_hash->{$network}->{global_domain} if ($network_hash->{$network}->{global_domain} ne '');
		push @domains, $network_hash->{$network}->{local_domain} if ($network_hash->{$network}->{local_domain} ne '');
	
		### now check our domains !!!!
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
				# printf STDERR ("Hostname/Alias \"%s (%s)\" already exist and has ip address: %s\n", $hostname,$h,$e);
				push @{$check_duplicates_byname_hash->{$hostname}},$q_ip_dec;
			}
		}
	}
		
	# clean up the $check_duplicates_byname_hash, there might be duplicate ip addresses with each name ...
	foreach my $k (keys %{$check_duplicates_byname_hash}) {
		my $tmp_hash=();
		foreach my $i (@{$check_duplicates_byname_hash->{$k}}) {
			$tmp_hash->{$i}=1;
		}
		delete $check_duplicates_byname_hash->{$k};
		my @tmp_array=();
		foreach my $l (keys %{$tmp_hash}) {
			push @{$check_duplicates_byname_hash->{$k}},$l;
		}
	}


	# print STDERR "\$check_duplicates_byname_hash:\n";
	# print STDERR Dumper($check_duplicates_byname_hash),"\n";

	### now rewrite the ip_hosts_duplicates table .....
	foreach my $h (keys %{$check_duplicates_byname_hash} ) {
		# print STDERR $h, ":", scalar @{$check_duplicates_byname_hash->{$h}}, "\n";
		$cmd="DELETE FROM ip_hosts_duplicates WHERE name='$h';";
		&do_row($cmd);
		# print STDERR "$cmd\n"; 
		if (scalar @{$check_duplicates_byname_hash->{$h}} >1 ) {
			foreach my $i (@{$check_duplicates_byname_hash->{$h}}) {
				$cmd="INSERT INTO ip_hosts_duplicates VALUES('$h','$i');";
				# print STDERR $cmd,"\n";
				&do_row($cmd);
			}
		}
	}
	$dbh->do("UNLOCK TABLES;");
}

1;
