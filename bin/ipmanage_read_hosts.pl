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

$hosts_file=$ARGV[0];

open(HF,"$hosts_file") or die "cannot open file\n";
@data=<HF>;
close HF;

foreach my $l (@data) {
	chomp $l;
	if ($l =~ /^(\d{1,3}.\d{1,3}.\d{1,3}.\d{1,3})(\s+)/ ) {
		my $ip=$1;
		my $rest=$l;
		$rest=~s/$ip//;
		my ($names,$comment)=split /\#/, $rest;
		$names=&trimstr($names);
		my ($hostname,$aliases)=split /\s+/, $names,2; 
		$aliases=&trimstr($aliases);
		$aliases=~s/\s+/ /g;
		$comment=~s/\s+/ /g;
		$comment=~s/"/\\\"/g;
		$comment=&trimstr($comment);
		print "$ip | $hostname | $aliases | $comment\n";
		my $cmd="./ipmanage_ip.pl -n $hostname -A \"$aliases\" -c \"$comment\" $ip";
		system($cmd);
	} else {
		next;
	}
}
