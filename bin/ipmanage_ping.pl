#! /usr/bin/perl
#

$|=1;

use Data::Dumper;
use Getopt::Std;


BEGIN {
        push (@INC,"../modules");
}

use ipmanage_config;
use ipmanage;
use sql;

sub usage () {
	print STDERR "\n";
	print STDERR "Usage: $0 [ -n <network1,network2,...,networkN> | -i ip1,ip2,ip3,....,ipN ]\n";
	print STDERR "\n";
}

sub ping_networks {
	print STDERR "START pinging Networks\n" if ($debug);
	foreach my $network (@networks) {
		my $network_dec=&convert_ip2dec($network);
		my $start=$network_hash->{$network_dec}->{network};
		my $end=$network_hash->{$network_dec}->{broadcast};
		$dbh->do("LOCK TABLES ipmanage_last_ping_status WRITE;");
		$sql_cmd="DELETE FROM ipmanage_last_ping_status WHERE ip >= $start and  ip <= $end";
		&do_row($sql_cmd);
		$dbh->do("UNLOCK TABLES;");
		$dbh->disconnect();
		
		# print "\$start=$start ($network_hash->{$network_dec}->{network_dotted})\n";;
		# print "\$end=$end ($network_hash->{$network_dec}->{broadcast_dotted})\n";;
		
		my $chunk_loops=int(($end-$start)/$max_db_connections);
		my $rest_chunk=($end-$start)%$max_db_connections;
		
		for($l=0;$l<$chunk_loops;$l++) {
			my @children=();
			if ($debug) {
				print STDERR "start = ", $start ;
				print STDERR " (" , &convert_dec2ip($start) ,")\n";
				print STDERR "end = ", $start+$max_db_connections -1 ;
				print STDERR " (" , &convert_dec2ip($start+$max_db_connections-1) , ")\n";
			}
		
			my $ip=0;
		 	for($ip=$start;$ip<$start+$max_db_connections;$ip++) {
				if (my $pid=fork) {
					push @children,[$pid,$ip];
				} elsif (defined $pid) {
					my $ip_dotted=&convert_dec2ip($ip);
					# $cmd="/usr/sbin/ping $ip_dotted $ping_timeout";
					$cmd="/usr/sbin/ping $ip_dotted $ping_timeout >/dev/null 2>&1";
					$cmd="/bin/ping -W $ping_timeout -c 2 $ip_dotted >/dev/null 2>&1";
					my $err_code=system($cmd);
					### reconnect to the database, because this is a new process, and we connected
					### to the database by reading module sql.pm. 
					$dbh=DBI->connect($dsn,$dbuser,$dbpasswd);
					$dbh->do("LOCK TABLES ipmanage_last_ping_status WRITE;");
					if ($err_code == 0) {
						# ok, system pings ...
						$sql_cmd="INSERT INTO ipmanage_last_ping_status (ip,ipdotted,ping) VALUES ($ip,'$ip_dotted',1)";
					} else {
						$sql_cmd="INSERT INTO ipmanage_last_ping_status (ip,ipdotted,ping) VALUES ($ip,'$ip_dotted',0)";
					}
					&do_row($sql_cmd);
					$dbh->do("UNLOCK TABLES;");
					$dbh->disconnect();
					exit;
				} else {
					die "Cannot fork: $!\n";
				}
				if ($ip == (($start+$max_db_connections) + $start)/2) {
					sleep 1;
				}
		        }
		
			# now wait for the children to finish ...
			while ($#children != -1) {
				my $kid=waitpid(-1,WNOHANG);
				if ($kid >0 ) {
					# delete from array
					for my $e (0..$#children) {
						my ($p,$ip)=(
							$children[$e][0],
							$children[$e][1],
						);
						if ($p==$kid) {
							splice(@children,$e,1);
							last;
						}
					}
				}
			}
		        $start=$ip;
		}
		
		if ($debug) {
			print STDERR "start = ", $start ;
			print STDERR " (" , &convert_dec2ip($start) ,")\n";
			print STDERR "end = ", $end ;
			print STDERR " (" , &convert_dec2ip($end) , ")\n";
		}
		
		undef @children;
		@children=();
		for($ip=$start;$ip<=$end;$ip++) {
			if (my $pid=fork) {
				push @children,[$pid,$ip];
			} elsif (defined $pid) {
				my $ip_dotted=&convert_dec2ip($ip);
				$cmd="/usr/sbin/ping $ip_dotted $ping_timeout >/dev/null 2>&1";
				# $cmd="/usr/sbin/ping $ip_dotted $ping_timeout";
				$cmd="/bin/ping -W $ping_timeout -c 2 $ip_dotted >/dev/null 2>&1";
				my $err_code=system($cmd);
				### reconnect to the database, because this is a new process, and we connected
				### to the database by reading module sql.pm. 
				$dbh=DBI->connect($dsn,$dbuser,$dbpasswd);
				$dbh->do("LOCK TABLES ipmanage_last_ping_status WRITE;");
				if ($err_code == 0) {
					# ok, system pings ...
					$sql_cmd="INSERT INTO ipmanage_last_ping_status (ip,ipdotted,ping) VALUES ($ip,'$ip_dotted',1)";
				} else {
					$sql_cmd="INSERT INTO ipmanage_last_ping_status (ip,ipdotted,ping) VALUES ($ip,'$ip_dotted',0)";
				}
				&do_row($sql_cmd);
				$dbh->do("UNLOCK TABLES;");
				$dbh->disconnect();
				exit;
			} else {
				die "Cannot fork: $!\n";
			}
			if ($ip == ($end + $start)/2) {
				sleep 1;
			}
		}
		
		# now wait for the children to finish ...
		while ($#children != -1) {
			my $kid=waitpid(-1,WNOHANG);
			if ($kid >0 ) {
				# delete from array
				for my $e (0..$#children) {
					my ($p,$ip)=(
						$children[$e][0],
						$children[$e][1],
					);
					if ($p==$kid) {
						splice(@children,$e,1);
						last;
					}
				}
			}
		}
	}
	print STDERR "END pinging Networks\n" if ($debug);
}


sub ping_ips {
	print STDERR "START pinging ip addresses\n" if ($debug);
	# create new database with ipaddress in dec and ipaddress in dotted...
	# and create a where_list at the same time ..
	my @ips=();

	my $ip_list="";
	for my $i (0 .. $#ipaddresses) {
		my $ip_dotted=$ipaddresses[$i];
		my $ip_dec=&convert_ip2dec($ip_dotted);
		push @ips,[$ip_dec,$ip_dotted];
		if ($i == $#ipaddresses) {
			$ip_list.=$ip_dec;
		} else {
			$ip_list.=$ip_dec . ",";
		}
	}
	$dbh->do("LOCK TABLES ipmanage_last_ping_status WRITE;");
	$sql_cmd="DELETE FROM ipmanage_last_ping_status WHERE ip in ($ip_list);";
	&do_row($sql_cmd);
	$dbh->do("UNLOCK TABLES;");
	$dbh->disconnect();

	@children=();
	my $cnt=0;
	foreach my $ip (@ips) {
		my ($ip_dec,$ip_dotted)=@$ip;
		if (my $pid=fork) {
			push @children,[$pid,$ip_dec];
		} elsif (defined $pid) {
			$cmd="/usr/sbin/ping $ip_dotted $ping_timeout >/dev/null 2>&1";
			$cmd="/bin/ping -W $ping_timeout -c 2 $ip_dotted >/dev/null 2>&1";
			my $err_code=system($cmd);
			### reconnect to the database, because this is a new process, and we connected
			### to the database by reading module sql.pm. 
			$dbh=DBI->connect($dsn,$dbuser,$dbpasswd);
			$dbh->do("LOCK TABLES ipmanage_last_ping_status WRITE;");
			if ($err_code == 0) {
				# ok, system pings ...
				$sql_cmd="INSERT INTO ipmanage_last_ping_status (ip,ipdotted,ping) VALUES ($ip_dec,'$ip_dotted',1)";
			} else {
				$sql_cmd="INSERT INTO ipmanage_last_ping_status (ip,ipdotted,ping) VALUES ($ip_dec,'$ip_dotted',0)";
			}
			&do_row($sql_cmd);
			$dbh->do("UNLOCK TABLES;");
			$dbh->disconnect();
			exit;
		} else {
			die "Cannot fork: $!\n";
		}
		if ($cnt%256 == 0) {	# sleep 1 if multiple of 256
			sleep 1;
		}
		$cnt++;
	}
		
	# now wait for the children to finish ...
	while ($#children != -1) {
		my $kid=waitpid(-1,WNOHANG);
		if ($kid >0 ) {
			# delete from array
			for my $e (0..$#children) {
				my ($p,$ip)=(
					$children[$e][0],
					$children[$e][1],
				);
				if ($p==$kid) {
					splice(@children,$e,1);
					last;
				}
			}
		}
	}
	print STDERR "END pinging ip addresses\n" if ($debug);
}


### MAIN ###
getopts('i:n:',\%opts);

if (!$opts{n} ne '' and ! $opts{i} ne '') { 
	&usage();
	exit 1;
}

if ($opts{n}) {
	print "ping all IP addresses in network(s): $opts{n}\n";
} 

if ($opts{i}) {
	print "ping all IP-addresses: $opts{i}\n";
}

@networks=split /,/, $opts{n};
@ipaddresses=split /,/, $opts{i};

### create the network hash (actually all networks in the database), so we have all the network info ...
$network_hash=&create_network_hash; 

$cnt=0;
$total_time_to_run=0;
foreach my $network (@networks) {
	if ($network =~ /^(\d+)$/) {
		# oh, network in decimal, must be from the CGI ...
		$network=&convert_dec2ip($network);
		$networks[$cnt]=$network;
	}
	if (! &check_ip($network)) {
		exit 1;
	}
	my $network_dec=&convert_ip2dec($network);

	# see if we have this network in the database..
	if ($network_hash->{$network_dec}->{network_dotted} ne "$network") {
		print STDERR "$0: unknown network $network\n";
		exit 1;
	}
	$cnt++;

	my $start=$network_hash->{$network_dec}->{network};
	my $end=$network_hash->{$network_dec}->{broadcast};
	
	my $chunk_loops=int(($end-$start)/$max_db_connections);
	my $rest_chunk=($end-$start)%$max_db_connections;
	
	### report the max time for this program to run:
	$total_time_to_run+=$chunk_loops * ($ping_timeout + 1) + ($ping_timeout + 1);
}

$cnt=0;
foreach my $ipaddress (@ipaddresses) {
	if ($ipaddress =~ /^(\d+)$/) {
		# oh, ipaddress in decimal, must be from the CGI ...
		$ipaddress=&convert_dec2ip($ipaddress);
		$ipaddresses[$cnt]=$ipaddress;
	}
	if (! &check_ip($ipaddress)) {
		exit 1;
	}
	$cnt++;
	$total_time_to_run+=$ping_timeout + 1;
}

if ($ENV{HTTP_HOST} eq '') {
	print "Program will take at least $total_time_to_run seconds to run.\n";
}

if ($opts{n}) {
	&ping_networks();
} 

if ($opts{i}) {
	&ping_ips();
}

# All childeren are done, let's poke the database, and delete and create a bugus entry
sleep 3;
$dbh=DBI->connect($dsn,$dbuser,$dbpasswd);
$dbh->do("LOCK TABLES ip_hosts WRITE;");
$sql_cmd="DELETE FROM ip_hosts WHERE ip=0;";
&do_row($sql_cmd);
$sql_cmd="DELETE FROM ip_hosts WHERE ip=0;";
&do_row($sql_cmd);
$sql_cmd="INSERT INTO ip_hosts (ip,ipdotted) VALUES (0,'0.0.0.0');";
&do_row($sql_cmd);


