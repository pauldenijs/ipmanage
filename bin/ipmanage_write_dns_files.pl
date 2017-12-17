#! /usr/bin/perl
#

use Data::Dumper;
use Getopt::Std;
use File::Basename;

BEGIN {
        push (@INC,"../modules");
}

use ipmanage_config;
use sql;
use ipmanage;
use POSIX;

my $now=&date_and_time_stamp;
my $network_hash=&create_network_hash;

### These variables should go in a config file ...
### $ttl=10800;
### $refresh=10800;
### $retry=3600;
### $expire=604800;
### $minimum=86400;
### Following are the name servers, where the FIRST one is the master, the rest are slaves!
### Also be sure that root can do a 'rcp' to all systems, even the master if this host is not the master!!
### @nameservers=('mickey.us.business.com','goofy.us.business.com','donald.us.business.com','pluto.us.business.com');
### @mailservers=(onager.us.business.com);
### @forwarders=('130.35.249.52','138.2.202.15','130.35.249.41');
### $named_dir="/var/named";
### $named_conf="/etc/named.conf";
### END of variables that go in config file

# some security for this script ...
$named_conf="/etc/named.conf" if ($named_conf eq '');
$named_dir="/var/named" if ($named_dir eq '');

# we need a temporary directory to put the generated files in. After that we copy (with rcp) the needed files to
# the master and slaves.

my $tmpdir=&random_tmp_file;
# some security for this script ...
$tmpdir="/tmp/named_stuff" if ($tmpdir eq '' or $tmpdir eq '/');

if (! -d "${tmpdir}${named_dir}") {
	$cmd="/bin/mkdir -m 755 -p ${tmpdir}${named_dir}";
	system($cmd);
	print $cmd,"\n";
}

if (! -d dirname("${tmpdir}${named_conf}")) {
	$cmd="/bin/mkdir -m 755 -p " . dirname("${tmpdir}${named_conf}");
	system($cmd);
	print $cmd,"\n";
}


sub get_serial {
	my $yyyymmdd=&yyyymmdd();
	my $serialcounter=select1("SELECT serial FROM ipmanage_zoneserial WHERE lastdate=$yyyymmdd;");
	$serialcounter+=0;
	if ($serialcounter) {
		$sql_cmd="DELETE FROM ipmanage_zoneserial  WHERE lastdate=$yyyymmdd;"; 
		&do_row($sql_cmd);
	} 
	$serialcounter++;
	$sql_cmd="INSERT INTO ipmanage_zoneserial (lastdate,serial) VALUES($yyyymmdd,$serialcounter)";
	&do_row($sql_cmd);
	my $serial=$yyyymmdd . sprintf("%02d",$serialcounter);
	return $serial;
}

sub create_named_conf {
        my @networks = map { $network_hash->{$_}->{network_dotted}.'/'.$network_hash->{$_}->{bitmask}.';' } sort keys %{$network_hash};
	foreach my $type ('master','slave') {
		print "Creating named.conf in ${tmpdir}${named_conf}.${type} ... \n";
		open(NC,">${tmpdir}${named_conf}.${type}") or die "Cannot open ${tmpdir}${named_conf}.${type} file for write: $!\n";
		print NC "options {\n";
		print NC "\tdirectory \"$named_dir\";\n";
		print NC "\tversion \"duh???\";\n";
	
		if (@forwarders) {
			print NC "\tforward first;\n";
			print NC "\tforwarders {\n";
			foreach my $fw (@forwarders) {
				print NC "\t\t$fw;\n";
			}
			print NC "\t};\n";
		}
                if (@networks) {
                        print NC "\n";
                	print NC "\t// disables all zone transfer requests from outside our networks\n";
                        print NC "\tallow-transfer {\n";
                        print NC "\t\t".join("\n\t\t", @networks)."\n";
                        print NC "\t};\n";
                        print NC "\n";
                        print NC "\t// Closed DNS - permits only local IPs to issue queries\n";
                        print NC "\tallow-query {\n";
			print NC "\t\t127.0.0.0/8;\n";
                        print NC "\t\t".join("\n\t\t", @networks)."\n";
                        print NC "\t};\n";
                        print NC "\n";

			if (@rpz_hosts) {
				print NC "\tresponse-policy { zone \"rpz\";};";
				print NC "\n";
			}
                }
		print NC "};\n";
		print NC "\n";

	
		# for the zone files by domain, we need to gather all the domain-names in a hash with their
		# ip addresses. Then we create the zone db files per domain name
		# forget the GLOBAL DOMAIN, we do NOT control it !
		my $local_domain_hash=();
		foreach my $k (sort keys %{$network_hash} ) {
			my $local_domain=$network_hash->{$k}->{local_domain};
			next if ($local_domain eq '');
			# throw all the info in an array
			push @{$local_domain_hash->{$local_domain}},$network_hash->{$k};
		}

		if ($type eq 'slave') {
			foreach my $ld (sort keys %{$local_domain_hash} ) {
				print NC "masters ", $ld, " {\n";
				foreach my $h (@nameservers) {
					# hey, lets be sure that for now we don't include the domainname of the nameserver ..
					my ($simple_name,$rest)=split /\./,$h; 
					printf NC "\t%s; \t// %s\n",&get_host_ip($simple_name),$h;
				}
				print NC "};\n\n";
			}
		}	
	
		# we have the hash local_domain_hash with the keys: local_domain, which are arrays of all the networks.
		# write the zonefiles now ...
		foreach my $ld (sort keys %{$local_domain_hash} ) {
			print NC "zone \"$ld\" {\n";
			print NC "\ttype $type;\n";
			$file="db." . $ld;
			print NC "\tfile \"$file\";\n";
			if ($type eq 'slave') { 
				printf NC "\tmasters { %s; };\n",$ld;
			} else {
				print NC "\tallow-update { none; }; \n";
			}
			print NC "};\n\n";

			if (@rpz_hosts) {
				print NC "zone \"rpz\" {\n";
				print NC "\ttype $type;\n";
				$file="db." . rpz;
				print NC "\tfile \"$file\";\n";
				print NC "};\n\n";
				if ($type eq 'master') {
					&create_rpz_file($ld,@{$local_domain_hash->{$ld}}); 
				}
			}

			#print STDERR Dumper($local_domain_hash->{$ld}),"\n";
			if ($type eq 'master') {
				&create_zone_file($ld,@{$local_domain_hash->{$ld}}); 
			}
		}

		foreach my $k (sort keys %{$network_hash} ) {
			my $multiplier=int((32-$network_hash->{$k}->{bitmask})/8);
			if ($multiplier > 0 ) {
				for (my $i=$network_hash->{$k}->{network}; $i<=$network_hash->{$k}->{broadcast}; $i+=(256**$multiplier)) {
					my $start=$i;
					my $end=$i + 256**$multiplier -1;
					my $domain=$network_hash->{$k}->{local_domain}; 
					if ($domain eq '') {
						$domain=$network_hash->{$k}->{global_domain};
					}
					my @a=split(/\./,&convert_dec2ip($i));
					my $reversed_addr='';
					for (my $r=3;$r>-1;$r--) {
						if ($a[$r] > 0 ) {
							$reversed_addr.=$a[$r] . ".";
						}
					}
					print NC "zone \"", $reversed_addr, "in-addr.arpa\" {\n"; 
					print NC "\ttype $type;\n";
					# lets name the file as real classes (boundaries of 24, 16, 8, 0)
					# with the 9's stripped:
					# 10.196.0.0 -> db.10.196
					$file="db";
					for (my $r=0;$r<4;$r++) {
						if ($a[$r] > 0 ) {
							$file.="." . $a[$r];
						}
					}
					print NC "\tfile \"$file\";\n";
					if ($type eq 'slave') { 
						printf NC "\tmasters { %s; };\n",$domain;
					} else {
						print NC "\tallow-update { none; }; \n";
					}
					print NC "};\n\n";
					if ($type eq 'master') {
						&create_reverse_zone_file($file,$domain,$start,$end);
					}
				}  
			} else {
				print "Sorry, not supported\n";
				last;
			}
	
		}
		print "Done with Creating named.conf...\n";
	}
}


sub create_zone_file {
	my ($domain,@local_domain_array)=@_;

	my @host_array=();
	foreach my $k (@local_domain_array) {
		# get the network ranges from the array, do a query on the database and add the result array in another array 
		my $sql_cmd="
			SELECT ip,hostname,aliases 
			FROM ip_hosts 
			WHERE ip >= $k->{network} AND ip<=$k->{broadcast}
			ORDER by ip
			";
		#print STDERR $sql_cmd,"\n";
		push @host_array,&select_array($sql_cmd);
	}


	$file=${tmpdir} . ${named_dir} . "/db." . $domain;
	print "\tCreating zone file as $file ... ";
	open(ZF,">$file") or die "Cannot open $file file for write: $!\n";
	print ZF "\$TTL $ttl\n";
	print ZF "\@ IN SOA ", $nameservers[0] , ". root." , $nameservers[0], ". (\n";
	printf(ZF "\t%-20s; serial\n", $serial); 
	printf(ZF "\t%-20s; refresh\n", $refresh); 
	printf(ZF "\t%-20s; retry\n", $retry); 
	printf(ZF "\t%-20s; expire\n", $expire); 
	printf(ZF "\t%-20s; minimum\n", $minimum); 
	print ZF "\t)\n";
	foreach my $ns (@nameservers) {
		print ZF "  IN NS ", $ns, ".\n";
	}
	print ZF "\n";

	print ZF "\$ORIGIN ", $domain , ".\n\n";

	printf(ZF "%-64s %-8s %s.\n", "_nfsv4idmapdomain", "IN TXT" , $domain); 

	$local_mailhost_flag=0;
	foreach my $i (@host_array) {
		my ($ip,$hostname,$aliases,$comment)=@$i;
		$ip_dotted=&convert_dec2ip($ip);
		if ($local_mailhost eq $ip_dotted) {
			if (! $local_mailhost_flag) {
				printf(ZF "%-64s %-8s %s\n","mailhost", "IN A", $ip_dotted);
				$local_mailhost_flag++;
			}
		}
		printf(ZF "%-64s %-8s %s\n",$hostname, "IN A", $ip_dotted);
		foreach my $a (split/\s+/,$aliases) {
			if ($domain ne '') {
				printf(ZF "%-64s %-8s %s.%s.\n",$a, "IN CNAME" , $hostname, $domain);
			} else {
				printf(ZF "%-64s %-8s %s.\n",$a, "IN CNAME" , $hostname);
			}
		}
	}
	close ZF;
	print "done\n";
}


sub create_rpz_file {
	my ($domain,@local_domain_array)=@_;

	if (! @rpz_hosts) {
		return;
	}
	$file=${tmpdir} . ${named_dir} . "/db." . rpz;
	print "\tCreating zone file as $file ... ";
	open(ZF,">$file") or die "Cannot open $file file for write: $!\n";
	print ZF "\$TTL $ttl\n";
	print ZF "\@ IN SOA ", $nameservers[0] , ". root." , $nameservers[0], ". (\n";
	printf(ZF "\t%-20s; serial\n", $serial); 
	printf(ZF "\t%-20s; refresh\n", $refresh); 
	printf(ZF "\t%-20s; retry\n", $retry); 
	printf(ZF "\t%-20s; expire\n", $expire); 
	printf(ZF "\t%-20s; minimum\n", $minimum); 
	print ZF "\t)\n";
	foreach my $ns (@nameservers) {
		print ZF "  IN NS ", $ns, ".\n";
	}
	print ZF "\n";

	foreach my $i (@rpz_hosts) {
		my ($hostname,$ip)=@$i;
		printf(ZF "%-64s %-8s %s\n",$hostname, "IN A", $ip);
	}
	close ZF;
	print "done\n";
}

sub create_reverse_zone_file {
	my ($file,$domain,$start,$end)=@_;
	# get the network ranges from the array, do a query on the database and add the result array in another array 
	my $sql_cmd="
		SELECT ip,hostname,aliases 
		FROM ip_hosts 
		WHERE ip >= $start AND ip <= $end
		ORDER by ip
		";

	#print STDERR "$sql_cmd\n";
	my @host_array=&select_array($sql_cmd);
	$file=${tmpdir} . ${named_dir} . "/" . $file;
	print "\tCreating reverse zone file as $file ... ";
	open(ZF,">$file") or die "Cannot open $file file for write: $!\n";
	print ZF "\$TTL $ttl\n";
	print ZF "\@ IN SOA ", $nameservers[0] , ". root." , $nameservers[0], ". (\n";
	printf(ZF "\t%-20s; serial\n", $serial); 
	printf(ZF "\t%-20s; refresh\n", $refresh); 
	printf(ZF "\t%-20s; retry\n", $retry); 
	printf(ZF "\t%-20s; expire\n", $expire); 
	printf(ZF "\t%-20s; minimum\n", $minimum); 
	print ZF "\t)\n";
	foreach my $ns (@nameservers) {
		print ZF "  IN NS ", $ns, ".\n";
	}
	print ZF "\n";

	foreach my $i (@host_array) {
		my ($ip,$hostname,$aliases,$comment)=@$i;
		$ip_dotted=&convert_dec2ip($ip);
		my @o=split(/\./,$ip_dotted);
		my $rev=$o[3] . "." . $o[2] . "." . $o[1] . "." .$o[0] . ".in-addr.arpa.";
		if ($domain ne '') {
			printf(ZF "%-30s %-8s %s.%s.\n",$rev, "IN PTR", $hostname,$domain);
		} else {
			printf(ZF "%-30s %-8s %s.\n",$rev, "IN PTR", $hostname);
		}
	}
	close ZF;
	print "done\n";
}

sub named_checkconf {
	# calls named-checkconf - named configuration file  syntax  checking tool
	# if this fails, send email to $admin_email with the error and quit

	my $err_file=&random_tmp_file;
	my $rel_named_conf_master=$named_conf . ".master";
	$rel_named_conf_master=~s/$tmpdir//;

	# since named-checkconf does a chroot to $tmpdir, it cannot find it's own libraries anymore....
	# bug or not, we have to copy all the libraries used to the $tmpdir as well!

	$cmd="/usr/bin/ldd /usr/sbin/named-checkconf";
	open(LIBS,"$cmd |");
	@libs=<LIBS>;
	close LIBS;

	my $lib_hash=();
	foreach my $l (@libs) {
		chomp $l;
		my ($dummy1,$file)=split /=>/, $l;
		$file=~s/\s+\(.*$//;
		next if ($file eq '');
		$file=~s/\s+//g;
		my $f=basename($file);
		my $d=dirname($file);
		push @{$lib_hash->{$d}}, $f;
	}

	foreach my $d (keys %{$lib_hash}) {
		$cmd="mkdir -p " . $tmpdir . $d;
		system($cmd);
		foreach my $f (@{$lib_hash->{$d}}) {
			$cmd="cp " . $d . "/" . $f . " " . $tmpdir . $d . "/" . $f;
			system($cmd);
		}
	}

	# $cmd="/usr/sbin/named-checkconf -t " .  $tmpdir . " -z " . $named_conf . ".master" . " >" . $err_file . " 2>&1";
	$cmd="/usr/sbin/named-checkconf -t " .  $tmpdir . " -z " . $rel_named_conf_master . " >" . $err_file . " 2>&1";
	print "$cmd\n";

	my $rc=system($cmd);
	if ($rc != 0 ) {
		my $err_mail=&random_tmp_file;
		open(ERRMAIL,">$err_mail");
		# $admin_email="paul.de.nijs\@business.com";
		print ERRMAIL "To:",$admin_email,"\n";
		print ERRMAIL "From:ipmanage at $site <$admin_email>\n";
		print ERRMAIL "Subject:named config error detected\n";
		print ERRMAIL "\n\n";

		print ERRMAIL "/usr/sbin/named-checkconf detected a configuration error:\n\n";
		open (ERRFILE,"$err_file");
		print ERRMAIL <ERRFILE>;
		close ERRFILE;
		print ERRMAIL "\nThis means that the DNS services could not be restarted, and probably have no updates.\n";
		print ERRMAIL "Please check the configuration\n";
		close ERRMAIL;

		open(MAIL,"| $mailprog");
		open(ERRMAIL,$err_mail);
		print MAIL <ERRMAIL>;
		close MAIL;
		close ERRMAIL;

		unlink $err_file;
		unlink $err_mail;
		exit;
	}
}


sub distribute_files {
	# copy all created files to the master and slaves 
	$cnt=0;
	my $cmd='';
	my $slave_update_flag=0;

	foreach my $host (@nameservers) {
		if ($cnt == 0) {
			# this is the master 
			# check if we actually have to update the named.conf. if they are the same
			# we also don't need to update the slaves! 
			$cmd="scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null $host:$named_conf /tmp/name.conf.check;";
			system($cmd);
			my $sum1=`sum /tmp/name.conf.check`;
			my $m=${tmpdir} . ${named_conf} . ".master";
			my $sum2=`sum $m`;

			my ($s1,$d1)=split /\s+/, $sum1;
			my ($s2,$d2)=split /\s+/, $sum2;
			if ($s1 ne $s2) {
				print "Slaves need updates!\n";
				$slave_update_flag++;
			}

			$cmd='';
			if ($slave_update_flag) {
				$cmd.= "scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null " . $tmpdir . $named_conf . ".master " .  $host . ":" . $named_conf . ";\n";
				print $cmd,"\n";
			}
			$cmd.="scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null " . $tmpdir . $named_dir . "/* " .  $host . ":" . $named_dir . ";\n";
			#$cmd.="ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null $host '/usr/sbin/svcadm restart svc:/network/dns/server';\n";
			$cmd.="ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null $host 'systemctl restart bind9';\n";
			print $cmd,"\n";
			system($cmd);
		} else {
			# this is the slave
			if ($slave_update_flag) {
				$cmd= "scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null " . $tmpdir . $named_conf . ".slave " .  $host . ":" . $named_conf . ";\n";
				print $cmd,"\n";
				#$cmd.="ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null $host '/usr/sbin/svcadm restart svc:/network/dns/server';\n";
				$cmd.="ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null $host 'systemctl restart bind9';\n";
				print $cmd,"\n";
				system($cmd);
			}
		}
		$cnt++;
	} 
	if ($tmpdir =~ /^\/tmp\//) {	### secure yourself that it's really /tmp ;-)
#		$cmd="rm -rf " . $tmpdir;
		print $cmd,"\n";
		system($cmd);
	}
}


### MAIN #####
$serial=&get_serial();
&create_named_conf();
&named_checkconf();
&distribute_files();
