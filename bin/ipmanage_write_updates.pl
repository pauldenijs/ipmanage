#! /usr/bin/perl
#

use Data::Dumper;
use Getopt::Std;

BEGIN {
        push (@INC,"../modules");
}

use ipmanage_config;
use sql;
use ipmanage;

$ENV{'PATH'}="/usr/sbin:/usr/bin:/usr/ccs/bin";


# This script shoudl go into the crontab pf root. 
# it will call:
# ipmanage_write_hosts.pl $hostfile # ($hostfile is defined in ipmanage_config.pm)
# and 
# ipmanage_write_dns_files.pl
#
# needs to keep track of when this script ran for the last time (ipmanage_last_cron_update.last.run)
# and the last timestamp in the ip_hosts.modified

my $last_run=&select1("SELECT DATE_FORMAT(last_run,'%Y%m%d%H%i%S') FROM ipmanage_last_cron_update ORDER BY last_run DESC LIMIT 1");
my $last_ip_update=&select1("SELECT DATE_FORMAT(modified,'%Y%m%d%H%i%S') FROM ip_hosts ORDER BY modified DESC LIMIT 1");
my $last_ip_update2=&select1("SELECT DATE_FORMAT(modified,'%Y%m%d%H%i%S') FROM ip_hosts_history ORDER BY modified DESC LIMIT 1");

if ($last_ip_update2 > $last_ip_update) {
	$last_ip_update=$last_ip_update2;
}

print "\$last_run=\t\t$last_run\n";
print "\$last_ip_update=\t$last_ip_update\n";
print "\$last_ip_update2=\t$last_ip_update2\n";

if ($last_run < $last_ip_update) {
	print "Update ...\n";
	system("./ipmanage_write_hosts.pl $hostfile");
	system("cd /var/yp;make;");
	system("./ipmanage_write_dns_files.pl");
}

&do_row("DELETE FROM ipmanage_last_cron_update;");
&do_row("INSERT INTO ipmanage_last_cron_update (last_run) VALUES(NOW());");


&check_duplicate_hostnames;

