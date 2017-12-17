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

my $now=&yyyymmddhhmmss();
my $this_hostname=`hostname`;
chomp $this_hostname;

my $last_changed=0;
####### my $interval=7*24*3600;				# in seconds ... 7 days
####### $last_changed=select1("SELECT DATE_SUB(NOW(), INTERVAL $interval SECOND)+0;");  
### better is to check for the LAST time this program ran, and put that in the database (table ipmanage_last_updates)
### so the interval is actually variable, just depends when you run it!

my $network_hash=&create_network_hash;

sub all_dns_changes {
	my ($public)=@_;	# mail changes to $public_dns_manager ONLY for public=1;
				# mail changes to $local_dns_manager ONLY FOR public=0;

	my $mail_to="";
	if ($public) { 
		$mail_to=$public_dns_manager;
	} else {
		$mail_to=$local_dns_manager;
	}
	if ($opts{m}) {
		$mail_to="";
	}
	$mail_to=$admin_email if ($mail_to eq '');

	my $mail_from="";
	if ($public) { 
		$mail_from=$admin_email;
	} else {
		$mail_from=$admin_email;
	}
	if ($opts{m}) {
		$mail_from="";
	}
	$mail_from=$admin_email if ($mail_from eq '');

	my $last_changed=0;
	if ($public) {
		$last_changed=select1("SELECT DATE_FORMAT(timestamp_public,'%Y%m%d%H%i%S') FROM ipmanage_db_updates ORDER BY timestamp_public DESC LIMIT 1;");
	} else {
		$last_changed=select1("SELECT DATE_FORMAT(timestamp_private,'%Y%m%d%H%i%S') FROM ipmanage_db_updates ORDER BY timestamp_private DESC LIMIT 1;");
	}
	if ($opts{m}) {
		$last_changed=select1("SELECT DATE_FORMAT(timestamp_changes,'%Y%m%d%H%i%S') FROM ipmanage_db_updates ORDER BY timestamp_changes DESC LIMIT 1;");
	}
	$last_changed=$last_changed + 0;

	my $mail_plain=&random_tmp_file;
	open(PLAIN,">$mail_plain") or die "Cannot open file \"$mail_plain\": $!\n";
	my $mail_html=&random_tmp_file;
	open(HTML,">$mail_html") or die "Cannot open file \"$mail_html\": $!\n";

	# open a file that contains only: 
	# IP-address hostname alias(es)
	# kind of the same as a /etc/hosts file, but without comments 
	my $hostfile=&random_tmp_file;
	open(HOSTFILE,">$hostfile") or die "Cannot open file \"$hostfile\": $!\n";


	my $mailfile=&random_tmp_file;
	open(MF,">$mailfile") or die "Cannot open file \"$mailfile\": $!\n";
	print MF "To:",		$mail_to, "\n";
	print MF "From:ipmanage at $site <", $mail_from, ">\n";

	my $change_id=$now;

	if ($opts{D}) {
		if ($opts{A}) {
			$change_id=$now . "_REFRESH";
			print MF "Subject:",	"IP address REFRESH in 'IPmanage' for Public DNS (ChangeID=$change_id) at $site ", "\n";
		} else {
			print MF "Subject:",	"IP address changes in 'IPmanage' for Public DNS (ChangeID=$change_id) at $site ", "\n";
		}
	} else {
		print MF "Subject:",	"IP address changes in 'IPmanage' at $site", "\n";
	}

	my $boundary_1= "___" . join("", ('a'..'z','A'..'Z',0..9)[map rand $_, (62)x24]) . "___";
	my $boundary_2= "___" . join("", ('a'..'z','A'..'Z',0..9)[map rand $_, (62)x24]) . "___";

	# start the multipart/related section  with $boundary_1
	# print MF "Content-Type: multipart/related; boundary=" , $boundary_1 , "\n";  # this will NOT show the text (attachement) in the mail, you realy have to save it!
	print MF "Content-Type: multipart/mixed; boundary=" , $boundary_1 , "\n";      # this will show the text also in the mail unformatted
	print MF "MIME-Version: 1.0\n";
	print MF "\n";
	print MF "This is a multi-part message in MIME format.\n";
	print MF "--", $boundary_1,"\n";
	
	# start the multipart/alternative section with $boundary_2 (
	print MF "Content-Type: multipart/alternative; boundary=" , $boundary_2 , "\n";
	print MF "MIME-Version: 1.0\n\n";

	$update_flag=0;	

	print PLAIN "# Change ID: $change_id\n";
	print PLAIN "# Site : $site\n";
	print HTML  "# Change ID: $change_id <BR>\n";
	print HTML  "# Site : $site<BR>\n";

	print HTML  "<BR>\n";
	print PLAIN "\n";
	
	foreach my $k (sort keys %{$network_hash}) {
		if (! $opts{m}) {
			next if ($network_hash->{$k}->{public} != $public);
		}

		my $max_hostname_length=length("Hostname");
		my $max_aliases_length=length("Aliases");
		my $max_comment_length=length("Comment");
		my $max_modifier_length=length("Modifier");

		### get all the deleted/changed ip addresses first
		my $sql_cmd="
			SELECT ip,hostname,aliases,comment,modifier,mod_type  
			FROM ip_hosts_history
			WHERE ip >= $network_hash->{$k}->{network} AND ip <= $network_hash->{$k}->{broadcast}
			AND modified >= $last_changed  
                	ORDER by modified;
			";

		# print STDERR $sql_cmd,"\n";
		my @history_entries=&select_array($sql_cmd);

		# put all entries in a hash
		my $changes_hash=();

		foreach my $e (@history_entries) {
			my ($ip,$hostname,$aliases,$comment,$modifier,$mod_type)=@$e;
			$max_hostname_length=length($hostname) if (length($hostname) > $max_hostname_length);
			$max_aliases_length=length($aliases) if (length($aliases) > $max_aliases_length);
			$max_comment_length=length($comment) if (length($comment) > $max_comment_length);
			$max_modifier_length=length($modifier) if (length($modifier) > $max_modifier_length);

			### pick the LAST changes, which can be:
			### throw the items in a hash and overwrite each time, because the array is ordered by modify date,
			### and we can have multiple ip addresses

			# throw away ANY previous entry for this ip where mod_type='deleted' or 'changed'...
			delete $changes_hash->{$ip};

			# save any last entry
			$changes_hash->{$ip}->{$mod_type}->{hostname}=$hostname;
			$changes_hash->{$ip}->{$mod_type}->{aliases}=$aliases;
			$changes_hash->{$ip}->{$mod_type}->{comment}=$comment;
			$changes_hash->{$ip}->{$mod_type}->{modifier}=$modifier;
		}

		### get all the entries that were modified since the last change. There are no duplicates in ip addresses
		$sql_cmd="
			SELECT ip,hostname,aliases,comment,modifier  
			FROM ip_hosts
			WHERE ip >= $network_hash->{$k}->{network} AND ip <= $network_hash->{$k}->{broadcast}
			AND modified >= $last_changed  
                       	ORDER by ip;
                        ";
		# print STDERR $sql_cmd,"\n";
		my @changes=&select_array($sql_cmd);
		my $list="";

		foreach my $e (@changes) {
			# put all entries in the 
			my ($ip,$hostname,$aliases,$comment,$modifier)=@$e;
			$max_hostname_length=length($hostname) if (length($hostname) > $max_hostname_length);
			$max_aliases_length=length($aliases) if (length($aliases) > $max_aliases_length);
			$max_comment_length=length($comment) if (length($comment) > $max_comment_length);
			$max_modifier_length=length($modifier) if (length($modifier) > $max_modifier_length);
			
			### 
			$changes_hash->{$ip}->{'current'}->{hostname}=$hostname;
			$changes_hash->{$ip}->{'current'}->{aliases}=$aliases;
			$changes_hash->{$ip}->{'current'}->{comment}=$comment;
			$changes_hash->{$ip}->{'current'}->{modifier}=$modifier;
		}

		# print STDERR Dumper($changes_hash),"\n";

		if ($opts{A} and $opts{D}) {
			# this will be merely an TOTAL update of DNS for this network, 
        		# with IP-addresses that do NOT exist or are not in the database
			# written as and entry (see below in program for $changes_hash_{$ip}->{deleted}
			# so we only will have:
			# $changes_hash_{$ip}->{current} 
			# $changes_hash_{$ip}->{deleted} 
			# we will process if they have something recorded

			### using the changes hash again, but tthen totally emptied
			$changes_hash=();
		
			$sql_cmd="
				SELECT ip,hostname,aliases,comment,modifier  
				FROM ip_hosts
				WHERE ip >= $network_hash->{$k}->{network} AND ip <= $network_hash->{$k}->{broadcast}
                       		ORDER by ip;
                       		";
				
			my @entries=&select_array($sql_cmd);

			$max_hostname_length=length("Hostname");
			$max_aliases_length=length("Aliases");
			$max_comment_length=length("Comment");
			$max_modifier_length=length("Modifier");
	
			for (my $ip=$network_hash->{$k}->{network};$ip<=$network_hash->{$k}->{broadcast};$ip++) {
				my $ip_str=&convert_dec2ip($ip);
				$ip_str=~s/\./-/g;
				my $no_hostname=lc($site) . "-" . $ip_str;
				
				my ($hostname,$aliases,$comment,$modifier)=($no_hostname,'','','none');
				$max_hostname_length=length($hostname) if (length($hostname) > $max_hostname_length);
				$max_aliases_length=length($aliases) if (length($aliases) > $max_aliases_length);
				$max_comment_length=length($comment) if (length($comment) > $max_comment_length);
				$max_modifier_length=length($modifier) if (length($modifier) > $max_modifier_length);
	
				$changes_hash->{$ip}->{'deleted'}->{hostname}=$hostname;
				$changes_hash->{$ip}->{'deleted'}->{aliases}=$aliases;
				$changes_hash->{$ip}->{'deleted'}->{comment}=$comment;
				$changes_hash->{$ip}->{'deleted'}->{modifier}=$modifier;
			}
	
			foreach my $e (@entries) {
				my ($ip,$hostname,$aliases,$comment,$modifier)=@$e;
				$max_hostname_length=length($hostname) if (length($hostname) > $max_hostname_length);
				$max_aliases_length=length($aliases) if (length($aliases) > $max_aliases_length);
				$max_comment_length=length($comment) if (length($comment) > $max_comment_length);
				$max_modifier_length=length($modifier) if (length($modifier) > $max_modifier_length);
	
				delete $changes_hash->{$ip}->{'deleted'};	# delete the entry from 'deleted' because we have one here!
	
				$changes_hash->{$ip}->{'current'}->{hostname}=$hostname;
				$changes_hash->{$ip}->{'current'}->{aliases}=$aliases;
				$changes_hash->{$ip}->{'current'}->{comment}=$comment;
				$changes_hash->{$ip}->{'current'}->{modifier}=$modifier;
			}

			# take out: 
			# network ip 
			# the broadcast ip
			# and the ip-addresses that are marked as routers 
			#  (GIT would be very upset if the router names would change) 
			delete $changes_hash->{$network_hash->{$k}->{network}};
			delete $changes_hash->{$network_hash->{$k}->{broadcast}};
			
			# also take out the restricted ip addresses ..
			my $restricted_sql="SELECT ip FROM ip_hosts_restricted ORDER BY ip;";
                	foreach my $r (&select_1dim_array($restricted_sql)) {
				delete $changes_hash->{$r};
			}
		}

		if ($changes_hash) {
			$update_flag++;
			my $domain='';
			print HTML "<TABLE BORDER=0 CELLSPACING=0 CELLPADDING=0>\n"; 	# outer table
			print HTML "<TR><TD>\n"; 					# outer table

			print HTML "<TABLE BORDER=1 CELLSPACING=1 CELLPADDING=1 WIDTH=100%>\n";
			if ($opts{m}) {
				print HTML "<TR>\n";
				print HTML "<TD style='font-family:Arial,\"Lucida Sans\",sans-serif;font-size:11px;'>global domain</TD>\n";
				if ($network_hash->{$k}->{global_domain} ne '') {
					print HTML "<TD style='font-family:Arial,\"Lucida Sans\",sans-serif;font-size:11px;'>", $network_hash->{$k}->{global_domain}, "</TD>\n";
				} else {
					print HTML "<TD style='font-family:Arial,\"Lucida Sans\",sans-serif;font-size:11px;'>&nbsp;</TD>\n";
				}
				print HTML "</TR>\n";
				print HTML "<TR>\n";
				print HTML "<TD style='font-family:Arial,\"Lucida Sans\",sans-serif;font-size:11px;'>local domain</TD>";
				if ($network_hash->{$k}->{local_domain} ne '') {
					print HTML "<TD style='font-family:Arial,\"Lucida Sans\",sans-serif;font-size:11px;'>", $network_hash->{$k}->{local_domain}, "</TD>\n";
				} else {
					print HTML "<TD style='font-family:Arial,\"Lucida Sans\",sans-serif;font-size:11px;'>&nbsp;</TD>\n";
				}
				print HTML "</TR>\n";
				print PLAIN "# global domain : ", $network_hash->{$k}->{global_domain}, "\n";
				print PLAIN "# local  domain : ", $network_hash->{$k}->{local_domain}, "\n";
			} else {
				if ($public) {
					print HTML "<TR>\n";
					print HTML "<TD style='font-family:Arial,\"Lucida Sans\",sans-serif;font-size:11px;'>domain</TD>";
					if ($network_hash->{$k}->{global_domain} ne '') {
						print HTML "<TD style='font-family:Arial,\"Lucida Sans\",sans-serif;font-size:11px;'>", $network_hash->{$k}->{global_domain}, " (public)</TD>\n";
					} else {
						print HTML "<TD style='font-family:Arial,\"Lucida Sans\",sans-serif;font-size:11px;'>&nbsp;</TD>\n";
					}
					print HTML "</TR>\n";
					print PLAIN "# domain : ", $network_hash->{$k}->{global_domain}, " (public)\n";
				} else {
					print HTML "<TR><TD style='font-family:Arial,\"Lucida Sans\",sans-serif;font-size:11px;'>domain</TD>";
					if ($network_hash->{$k}->{local_domain} ne '') {
						print HTML "<TD style='font-family:Arial,\"Lucida Sans\",sans-serif;font-size:11px;'>", $network_hash->{$k}->{local_domain}, " (private)</TD>\n";
					} else {
						print HTML "<TD style='font-family:Arial,\"Lucida Sans\",sans-serif;font-size:11px;'>&nbsp;</TD>\n";
					}
					print HTML "</TR>\n";
					print PLAIN "# domain : ", $network_hash->{$k}->{local_domain}, " (private)\n";
				}
			}
			print HTML "<TR>\n";
			print HTML "<TD style='font-family:Arial,\"Lucida Sans\",sans-serif;font-size:11px;'>network</TD>";
			print HTML "<TD style='font-family:Arial,\"Lucida Sans\",sans-serif;font-size:11px;'>", &convert_dec2ip($network_hash->{$k}->{network}), "/", $network_hash->{$k}->{bitmask}, "</TD>\n";
			print HTML "</TR>\n";
			print HTML "</TABLE>\n";

			print HTML "</TD></TR>\n"; # outer table
			print HTML "<TR><TD HEIGHT=5></TD></TR>\n"; # outer table

			print HTML "<TR><TD>\n"; # outer table

			print PLAIN "# network: ", &convert_dec2ip($network_hash->{$k}->{network}), "/", $network_hash->{$k}->{bitmask}, "\n";
			print PLAIN "\n";

			print HTML "<TABLE BORDER=1 CELLPADDING=1 CELLSPACING=1 WIDTH=100%>\n";
			print HTML "<TR>\n";
			if ($opts{m}) {
				print HTML "<TH style='font-family:Arial,\"Lucida Sans\",sans-serif;font-size:11px;'>Modifier</TH>\n";
			}
			print HTML "<TH style='font-family:Arial,\"Lucida Sans\",sans-serif;font-size:11px;'>IP address</TH>\n";
			print HTML "<TH style='font-family:Arial,\"Lucida Sans\",sans-serif;font-size:11px;'>Hostname</TH>\n";
			print HTML "<TH style='font-family:Arial,\"Lucida Sans\",sans-serif;font-size:11px;'>Aliases</TH>\n";
			print HTML "<TH style='font-family:Arial,\"Lucida Sans\",sans-serif;font-size:11px;'>Comment</TH>\n";

			$line='';
			if ($opts{m}) {
				$line.="+";
				for (my $i=0;$i<length("MOD");$i++) { $line.="-"; }
				$line.="+";
				for (my $i=0;$i<${max_modifier_length};$i++) { $line.="-"; }
				$line.="+";
				for (my $i=0;$i<15;$i++) { $line.="-"; }
				$line.="+";
				for (my $i=0;$i<${max_hostname_length};$i++) { $line.="-"; }
				$line.="+";
				for (my $i=0;$i<${max_aliases_length};$i++) { $line.="-"; }
				$line.="+";
				for (my $i=0;$i<${max_comment_length};$i++) { $line.="-"; }
				$line.="+";
				print PLAIN $line,"\n";
				printf(PLAIN "|MOD|%-${max_modifier_length}s|%-15s|%-${max_hostname_length}s|%-${max_aliases_length}s|%-${max_comment_length}s|\n", 
					"Modifier", "IP address", "Hostname", "Aliases", "Comment");
				print PLAIN $line,"\n";
			} else {
				## sorry, no fancy boxes, mail should be good to cut'n paste
				$line.="# -";
				for (my $i=0;$i<15;$i++) { $line.="-"; }
				$line.="-";
				for (my $i=0;$i<${max_hostname_length};$i++) { $line.="-"; }
				$line.="-";
				for (my $i=0;$i<${max_aliases_length};$i++) { $line.="-"; }
				$line.="-";
				print PLAIN $line,"\n";
				printf(PLAIN "# %-15s %-${max_hostname_length}s %-${max_aliases_length}s \n", 
					"IP address", "Hostname", "Aliases");
				print PLAIN $line,"\n";
			}
			print HTML "</TR>\n";

			foreach my $ip (sort keys %{$changes_hash}) {
			 	if ($opts{m}) {
					if ($changes_hash->{$ip}->{changed}) {
						print HTML "<TR>\n";
						print HTML "<TD style='text-decoration:none;background-color:#ffa500;color:#000000;font-size:11px;'>", $changes_hash->{$ip}->{changed}->{modifier}, "</TD>\n";
						print HTML "<TD style='text-decoration:line-through;background-color:#ffa500;color:#000000;font-size:11px;'>", &convert_dec2ip($ip),                        "</TD>\n";
						print HTML "<TD style='text-decoration:line-through;background-color:#ffa500;color:#000000;font-size:11px;'>", $changes_hash->{$ip}->{changed}->{hostname}, "</TD>\n";
						if ($changes_hash->{$ip}->{changed}->{aliases} ne '') {
							print HTML "<TD style='text-decoration:line-through;background-color:#ffa500;color:#000000;font-size:11px;'>", $changes_hash->{$ip}->{changed}->{aliases},  "</TD>\n";
						} else {
							print HTML "<TD style='text-decoration:none;background-color:#ffa500;color:#000000;font-size:11px;'>&nbsp;</TD>\n";
						}
						if ($changes_hash->{$ip}->{changed}->{comment} ne '') {
							print HTML "<TD style='text-decoration:line-through;background-color:#ffa500;color:#000000;font-size:11px;'>", $changes_hash->{$ip}->{changed}->{comment},  "</TD>\n";
						} else {
							print HTML "<TD style='text-decoration:none;background-color:#ffa500;color:#000000;font-size:11px;'>&nbsp;</TD>\n";
						}
						print HTML "</TR>\n";

			 			printf(PLAIN "|OLD|%-${max_modifier_length}s|%-15s|%-${max_hostname_length}s|%-${max_aliases_length}s|%-${max_comment_length}s|\n", 
							$changes_hash->{$ip}->{changed}->{modifier},
							&convert_dec2ip($ip),
							$changes_hash->{$ip}->{changed}->{hostname},
							$changes_hash->{$ip}->{changed}->{aliases},
							$changes_hash->{$ip}->{changed}->{comment}
							);
					} 

					if ($changes_hash->{$ip}->{deleted}) {
						print HTML "<TR>\n";
						print HTML "<TD style='text-decoration:none;background-color:#ff0000;color:#ffffff;font-size:11px;'>", $changes_hash->{$ip}->{deleted}->{modifier}, "</TD>\n";
						print HTML "<TD style='text-decoration:line-through;background-color:#ff0000;color:#ffffff;font-size:11px;'>", &convert_dec2ip($ip),                        "</TD>\n";
						print HTML "<TD style='text-decoration:line-through;background-color:#ff0000;color:#ffffff;font-size:11px;'>", $changes_hash->{$ip}->{deleted}->{hostname}, "</TD>\n";
						if ($changes_hash->{$ip}->{deleted}->{aliases} ne '') {
							print HTML "<TD style='text-decoration:line-through;background-color:#ff0000;color:#ffffff;font-size:11px;'>", $changes_hash->{$ip}->{deleted}->{aliases},  "</TD>\n";
						} else {
							print HTML "<TD style='text-decoration:none;background-color:#ff0000;color:#ffffff;font-size:11px;'>&nbsp;</TD>\n";
						}
						if ($changes_hash->{$ip}->{deleted}->{comment} ne '') {
							print HTML "<TD style='text-decoration:line-through;background-color:#ff0000;color:#ffffff;font-size:11px;'>", $changes_hash->{$ip}->{deleted}->{comment},  "</TD>\n";
						} else {
							print HTML "<TD style='text-decoration:none;background-color:#ff0000;color:#ffffff;font-size:11px;'>&nbsp;</TD>\n";
						}
						print HTML "</TR>\n";

			 			printf(PLAIN "|DEL|%-${max_modifier_length}s|%-15s|%-${max_hostname_length}s|%-${max_aliases_length}s|%-${max_comment_length}s|\n", 
							$changes_hash->{$ip}->{deleted}->{modifier},
							&convert_dec2ip($ip),
							$changes_hash->{$ip}->{deleted}->{hostname},
							$changes_hash->{$ip}->{deleted}->{aliases},
							$changes_hash->{$ip}->{deleted}->{comment}
							);
					}

					if ($changes_hash->{$ip}->{current}) {
						print HTML "<TR>\n";
						print HTML "<TD style='background-color:#00ff00;color:#000000;font-size:11px;'>", $changes_hash->{$ip}->{current}->{modifier}, "</TD>\n";
						print HTML "<TD style='background-color:#00ff00;color:#000000;font-size:11px;'>", &convert_dec2ip($ip),                        "</TD>\n";
						print HTML "<TD style='background-color:#00ff00;color:#000000;font-size:11px;'>", $changes_hash->{$ip}->{current}->{hostname}, "</TD>\n";
						if ($changes_hash->{$ip}->{current}->{aliases} ne '') {
							print HTML "<TD style='background-color:#00ff00;color:#000000;font-size:11px;'>", $changes_hash->{$ip}->{current}->{aliases},  "</TD>\n";
						} else {
							print HTML "<TD style='background-color:#00ff00;color:#000000;font-size:11px;'>&nbsp;</TD>\n";
						}
						if ($changes_hash->{$ip}->{current}->{comment} ne '') {
							print HTML "<TD style='background-color:#00ff00;color:#000000;font-size:11px;'>", $changes_hash->{$ip}->{current}->{comment},  "</TD>\n";
						} else {
							print HTML "<TD style='background-color:#00ff00;color:#000000;font-size:11px;'>&nbsp;</TD>\n";
						}
						print HTML "</TR>\n";

			 			printf(PLAIN "|NEW|%-${max_modifier_length}s|%-15s|%-${max_hostname_length}s|%-${max_aliases_length}s|%-${max_comment_length}s|\n", 
							$changes_hash->{$ip}->{current}->{modifier},
							&convert_dec2ip($ip),
							$changes_hash->{$ip}->{current}->{hostname},
							$changes_hash->{$ip}->{current}->{aliases},
							$changes_hash->{$ip}->{current}->{comment}
							);
					}
			 	} else {
					if ($changes_hash->{$ip}->{current}) {
						print HTML "<TR>\n";
						print HTML "<TD style='background-color:#ffffff;color:#000000;font-size:11px;'>", &convert_dec2ip($ip),                        "</TD>\n";
						print HTML "<TD style='background-color:#ffffff;color:#000000;font-size:11px;'>", $changes_hash->{$ip}->{current}->{hostname}, "</TD>\n";
						if ($changes_hash->{$ip}->{current}->{aliases} ne '') {
							print HTML "<TD style='background-color:#ffffff;color:#000000;font-size:11px;'>", $changes_hash->{$ip}->{current}->{aliases},  "</TD>\n";
						} else {
							print HTML "<TD style='background-color:#ffffff;color:#000000;font-size:11px;'>&nbsp;</TD>\n";
						}
						if ($changes_hash->{$ip}->{current}->{comment} ne '') {
							print HTML "<TD style='background-color:#ffffff;color:#000000;font-size:11px;'>", $changes_hash->{$ip}->{current}->{comment},  "</TD>\n";
						} else {
							print HTML "<TD style='background-color:#ffffff;color:#000000;font-size:11px;'>&nbsp;</TD>\n";
						}
						print HTML "</TR>\n";

			 			printf(PLAIN "  %-15s %-${max_hostname_length}s %-${max_aliases_length}s \n", 
							&convert_dec2ip($ip),$changes_hash->{$ip}->{current}->{hostname},$changes_hash->{$ip}->{current}->{aliases});
			 			print HOSTFILE &convert_dec2ip($ip), " ", $changes_hash->{$ip}->{current}->{hostname}, " ", $changes_hash->{$ip}->{current}->{aliases}, "\n";
					}
					if ($changes_hash->{$ip}->{deleted}) {
						my $ip_str=&convert_dec2ip($ip);
						$ip_str=~s/\./-/g;
						my $del_hostname=lc($site) . "-" . $ip_str;

						print HTML "<TR>\n";
						print HTML "<TD style='background-color:#ffffff;color:#000000;font-size:11px;'>", &convert_dec2ip($ip),                        "</TD>\n";
						print HTML "<TD style='background-color:#ffffff;color:#000000;font-size:11px;'>", $del_hostname, "</TD>\n";
						print HTML "<TD style='background-color:#ffffff;color:#000000;font-size:11px;'>&nbsp;</TD>\n";
						print HTML "<TD style='background-color:#ffffff;color:#000000;font-size:11px;'>&nbsp;</TD>\n";
						print HTML "</TR>\n";

			 			printf(PLAIN "  %-15s %-${max_hostname_length}s %-${max_aliases_length}s \n", 
							&convert_dec2ip($ip),$del_hostname,"");
			 			print HOSTFILE &convert_dec2ip($ip), " ", $del_hostname, "\n";
					}
			 	}
			}
			print HTML "</TABLE>\n";
			print HTML "</TD></TR>\n";	# outer table
			print HTML "</TABLE>\n";		# outer table
			print HTML "<BR><BR>\n";

			print PLAIN $line,"\n";
			print PLAIN "\n\n\n\n\n";
		}
	}

	# close the content files for writing 
	close PLAIN;
	close HTML;
	close HOSTFILE;

	# open the content file again, stuff their contents in the mail (MF)
	open(PLAIN,"$mail_plain") or die "Cannot open file \"$mail_plain\": $!\n";
	my @plain_data=<PLAIN>;
	close PLAIN;

	open(HTML,"$mail_html") or die "Cannot open file \"$mail_html\": $!\n";
	my @html_data=<HTML>;
	close HTML;

	open(HOSTFILE,"$hostfile") or die "Cannot open file \"$hostfile\": $!\n";
	my @hostfile_data=<HOSTFILE>;
	close HOSTFILE;

	######## start the PLAIN text
	print MF "--", $boundary_2,"\n";
	print MF "Content-Type: text/plain; charset=ISO-8859-1;\n";
	print MF "MIME-Version: 1.0\n";
	print MF "Content-Transfer-Encoding: 7bit\n";
	print MF "\n";
	print MF @plain_data,"\n";
	if (! $opts{m}) {
		print MF "NOTE: The real data is attached!\n";
	}
	print MF "-----------------------------------------------------------------------------------------\n";
	print MF "You are viewing this message in PLAIN text, switch your view to HTML to see more details!\n";
	print MF "-----------------------------------------------------------------------------------------\n";
	######## end of PLAIN text

	######## Start of HTML	
	print MF "\n--", $boundary_2,"\n";
	print MF "Content-Type: text/html; charset=ISO-8859-1\n";
	print MF "MIME-Version: 1.0\n";
	print MF "Content-Transfer-Encoding: 7bit\n";
	print MF "\n";
	print MF "<!DOCTYPE HTML PUBLIC '-//W3C//DTD HTML 4.01 Transitional//EN'>\n";
	print MF "<HTML>\n";
	print MF "<HEAD>\n";
	print MF "<meta http-equiv='content-type' content='text/html; charset=ISO-8859-1'>\n";
	print MF "</HEAD>\n";
	print MF "<BODY bgcolor='#ffffff' text='#000000' style='background-color:#FFFFFF;font-family:Arial,\"Lucida Sans\",sans-serif;font-size:11px;'>\n";
	print MF @html_data,"\n";
	if (! $opts{m}) {
		print MF "<BR><BR>\n";
		print MF "<B>NOTE:</B> The real data is attached!\n";
	}
	print MF "</BODY>\n";
	print MF "</HTML>\n";
	######## END of HTML

	print MF "\n--", $boundary_2, ,"--" , "\n";             #End of boundary_2
	### Start whatever attachments (well, the images ....)
	if ($ipmanage_image ne '') {
		print MF "\n--", $boundary_1, "\n";
		print MF "Content-Type: image/gif; name='$ipmanage_image'\n";
		print MF "Content-Transfer-Encoding: base64\n";
		print MF "Content-ID: ", $content_id1, "\n";
		print MF "Content-Disposition: inline; filename='$ipmanage_image'\n\n";
		open (IMG,"$ipmanage_image");
		while (read(IMG, $buf, 60*57)) {
			print MF encode_base64($buf);
		}
		close IMG;
	}
	if (! $opts{m}) {
		# do the attachement (the HOSTFILE);
		$attachment_name="hostfile_" . $now . "_" . $site;
		print MF "\n--", $boundary_1, "\n";
		print MF "Content-Type: text/plain; charset=us-ascii name=\"$attachment_name\"\n";
		print MF "Content-Transfer-Encoding: 7bit\n";
		print MF "Content-Disposition: attachement; filename=\"$attachment_name\"\n\n";
		print MF @hostfile_data, "\n";
	} 
	print MF "\n--", $boundary_1, "--\n";           # End of boundary_1
	close MF;

	if ($update_flag) {
		# send mail if there is anything to report.
		open(MAIL,"| $mailprog");
		open(MF,"$mailfile");
		my @data=<MF>;
		print MAIL @data;
		if (! $opts{m}) {
			# copy the mailfile to the log directory
			if ($public) {
				$mail_log_file=$logdir . "/mail_dns_public." . $now;
			} else {
				$mail_log_file=$logdir . "/mail_dns_private." . $now;
			}
			open(LOG,">$mail_log_file") or die "Cannot open \"$mail_log_file\":$!\n";
			print LOG @data;
			close LOG;
		} else {
			$mail_log_file=$logdir . "/change_report." . $now;
			open(LOG,">$mail_log_file") or die "Cannot open \"$mail_log_file\":$!\n";
			print LOG @data;
			close LOG;
		}
		close MF;
		close MAIL;
	}
	unlink $mailfile;
	unlink $mail_plain;
	unlink $mail_html;
	unlink $hostfile;

	if (! $opts{A}) {
		if ($opts{m}) {
			$sql_cmd="INSERT INTO ipmanage_db_updates (site,hostname,timestamp_changes) VALUES('$site','$this_hostname','$now');";
		} else {
			if ($public) {
				$sql_cmd="INSERT INTO ipmanage_db_updates (site,hostname,timestamp_public) VALUES('$site','$this_hostname','$now');";
			} else {
				$sql_cmd="INSERT INTO ipmanage_db_updates (site,hostname,timestamp_private) VALUES('$site','$this_hostname','$now');";
			}
		}
		&do_row($sql_cmd);
	}
}

### MAIN ##########################################################################################################

getopts('mDPA', \%opts);
# -D option is for DNS updates, 
# -A option is for DNS but will include ALL records, not only the latest updates (only works with -D option)
# -P option is for Public updates, default private  
# -m option is for updates  includes everything, also prints the comment field , only mails to $admin_email!!!

$opts{D}+=0;
$opts{P}+=0;
$opts{m}+=0;
$opts{A}+=0;

if ($opts{D}) {
	&all_dns_changes($opts{P}); 
	exit;
}

if ($opts{m}) {
	$opts{A}=0;
	&all_dns_changes(1);	# 1 or 0 it doesn't matter ... 
}

