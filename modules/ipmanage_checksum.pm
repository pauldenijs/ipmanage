sub checksum_tmp_file {
        my $file="/tmp/" .
                join("", ('a'..'z','A'..'Z',0..9)[map rand $_, (62)x16]);
        return $file;
}

sub get_checksum {
	my @checksum_data;

	# check the last modified data
	$cmd="SELECT modified FROM ip_hosts ORDER BY modified DESC limit 1;"; 
	$ip_hosts_timestamp=&select1($cmd);

	$cmd="SELECT modified FROM ip_nets ORDER BY modified DESC limit 1;"; 
	$ip_nets_timestamp=&select1($cmd);

	my @sum=<SUM>;
	$md5=Digest::MD5->new;

	$md5->add($ip_hosts_timestamp,$ip_nets_timestamp);
	my $md5_checksum=$md5->hexdigest;
	return ($md5_checksum);
}

sub update_checksum {
	my ($what)=@_;

	my $newchecksum="";
	if ($what eq "") {
		$newchecksum=&get_checksum;
	} else {
		$newchecksum=$what;
	}
	print STDERR "checksum: $newchecksum\n";
	$dbh->do("LOCK TABLES ipmanage_checksum WRITE;") if ($mysql);
	$cmd="DELETE FROM ipmanage_checksum";
	$dbh->do($cmd);
	$cmd="INSERT INTO ipmanage_checksum (checksum) VALUES ('$newchecksum')";
	$dbh->do($cmd);
	$dbh->do("UNLOCK TABLES;") if ($mysql);
	print "<SCRIPT language=javascript>\n";
       	print "SetCookie('checksum','$newchecksum','',7776000000);";
	print STDERR "Setting new checksumcookie from check: $newchecksum\n" if ($debug);
       	print "</SCRIPT>";
}

sub update_checksum_cookie {
	$cmd="SELECT checksum FROM ipmanage_checksum";
	$dbh->do("LOCK TABLES ipmanage_checksum READ;") if ($mysql);
	my $cs=&select1($cmd);
	$dbh->do("UNLOCK TABLES;") if ($mysql);
	print "<SCRIPT language=javascript>\n";
       	print "SetCookie('checksum','$cs','',7776000000);";
	print STDERR "Setting new checksumcookie from DB: $cs\n" if ($debug);
       	print "</SCRIPT>";
}

1;
