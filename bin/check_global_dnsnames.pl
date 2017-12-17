#! /usr/bin/perl
#


sub convert_ip2dec {
	# converts an ip address to decimal, so it's easy to subtract and add values.
	my ($d_ip)=@_;
	chomp $d_ip;
	my ($ip_1,$ip_2,$ip_3,$ip_4)=split(/\./,$d_ip);
	my $dec_value=$ip_1*256*256*256 + $ip_2*256*256 + $ip_3*256 + $ip_4;
	return ($dec_value);
}



open(FD,"/etc/nis/hosts");
@data=<FD>;
close FD;

$ip_list="";


foreach my $l (@data) {
	chomp  $l;
	next if ($l =~ /^#/);
	$l=~s/#.*$//;
	my ($ip,$aliases)=split /\s+/, $l, 2;
	@names=split /\s+/,$aliases;

	if ($ip =~ /^10.137./) {
		foreach my $n (@names) {
			$n_full=$n;
			$n_full.=".us.business.com";
			my ($t_name,$t_aliases,$t_addrtype,$t_length,@t_addrs)=gethostbyname($n_full);
			if ($t_name eq '') {
				my $ip_dec=&convert_ip2dec($ip);
				print "$ip_dec $n ($ip) not found in BUSINESS DNS as $n_full\n"; 
				#$ip_list.="'" . $ip_dec . "',";
				$ip_list.=$ip_dec . ",";
			}
		}
	}
}

$ip_list=~s/,$//;

print "\n\n";
print "To update the ipmanage database submit the following queries:\n";
print "update ip_hosts set modifier='root' where ip in ($ip_list);\n";
print "update ip_hosts_history set modifier='root', modified=NOW() where ip in ($ip_list);\n";
			
		



