#! /usr/bin/perl

my ($name,$aliases,$addrtype,$length,@addrs)=gethostbyname($ARGV[0]);

print "[$name,$aliases,$addrtype,$length]\n";
my $ip="";
foreach $i (@addrs) {
	my ($a,$b,$c,$d)=unpack('C4',$i);
	print "$a.$b.$c.$d\n";
	$ip="$a.$b.$c.$d";
}

print "nr of addresses: ", scalar @addrs,"\n";

my ($i_name,$i_aliases,$i_addrtype,$i_net)=getnetbyaddr('10.173.0.0',$addrtype);

print "[$i_net]\n";
