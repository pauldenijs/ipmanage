#! /usr/bin/perl

use Getopt::Std;
getopts('d:p', \%opts);

$passwd_in=$ARGV[0];

if ($passwd_in eq "") {
	&usage;
}

$unix_salt=join("", ('a'..'z','A'..'Z', 0..9)[map rand $_, (62)x2]);

my @valid_salt = ("a".."z","A".."Z","0".."9");
$e_salt=join "", map { $valid_salt[rand(@valid_salt)] } 1..8;
$md5_salt='$1$'.$e_salt;
$sha256_salt='$5$'.$e_salt;
$sha512_salt='$6$'.$e_salt;


sub usage {
	print "Usage: $0 [-p] [-d unix|md5|sha256|sha512]  <passwd>  \n";
	exit;
}

sub encrypt {
	my ($pwd,$digest)=@_; 
	if ($digest eq 'unix') {
		$pwd_encrypted=crypt($pwd,$unix_salt);
		if (! $opts{'p'}) {
			printf("encryped password (unix):     %-64s  %15s\n", 
				"[$pwd_encrypted]", "(between the [] brackets)");
		} else {
			print $pwd_encrypted,"\n";
		}
	} elsif ($digest eq 'md5') {
		$pwd_encrypted=crypt($pwd,$md5_salt);
		if (! $opts{'p'}) {
			printf("encryped password (md5):      %-64s  %15s\n", 
				"[$pwd_encrypted]", "(between the [] brackets)");
		} else {
			print $pwd_encrypted,"\n";
		}
	} elsif ($digest eq 'sha256') {
		$pwd_encrypted=crypt($pwd,$sha256_salt);
		if (! $opts{'p'}) {
			printf("encryped password (sha256):   %-64s  %15s\n", 
				"[$pwd_encrypted]", "(between the [] brackets)");
		} else {
			print $pwd_encrypted,"\n";
		}
	} elsif ($digest eq 'sha512') {
		$pwd_encrypted=crypt($pwd,$sha512_salt);
		if (! $opts{'p'}) {
			printf("encryped password (sha512):   %-64s  %15s\n", 
				"[$pwd_encrypted]", "(between the [] brackets)");
		} else {
			print $pwd_encrypted,"\n";
		}
	} else {
		&usage;
	}
}

if (! $opts{'p'}) {
	printf("uncrypted password:           %-64s  %15s\n", 
		"[$passwd_in]", "(between the [] brackets)");
}
if ($opts{'d'} eq '' and $opts{'p'}==0) {
	# oh, you want them all ...
	foreach my $digest ('unix','md5','sha256','sha512') {
		encrypt($passwd_in,$digest);
	}
} else {
	if ($opts{'d'} eq '') {
		encrypt($passwd_in,'unix');
	} else {
		encrypt($passwd_in,$opts{'d'});
	} 
}

