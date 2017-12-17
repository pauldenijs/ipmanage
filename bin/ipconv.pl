#! /usr/bin/perl
#
# small utility to convert ip from decimal to dotted or vise versa

use Data::Dumper;

BEGIN {
        push (@INC,"../modules");
}

use ipmanage;

$ipdotted='';
$ipdec=0;

foreach my $e (@ARGV) {
	if ($e =~ /\./) {
		if (! &check_ip($e)) {
			next;
		} 
		$ipdotted=$e;
		$ipdec=&convert_ip2dec($ipdotted);
	} else {
		$ipdec=$e;
		$ipdotted=&convert_dec2ip($ipdec);
	}
	print "IP: $ipdotted = $ipdec\n";
}

