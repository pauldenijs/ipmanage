# mysql module
#

use DBI();

if ($mysql) {
	$dsn=			"DBI:mysql:$database";
} else {
	$database=		$flatdb;
	$dsn=			"DBI:Sprite:$database";
}
$dbh=			DBI->connect($dsn,$dbuser,$dbpasswd);

sub do_row {
	$dbh->disconnect() if (!$mysql);
	$dbh=DBI->connect($dsn,$dbuser,$dbpasswd) if (!$mysql);
	# executes command and returns the number of rows changed
	# like inserting a row with a duplicate key ...
	my $ret_string="";
	my $ret_value=0;
	my $cmd=$_[0];
	my $sth=$dbh->prepare($cmd);
	if (!$sth) { die "Error:" . $dbh->errstr . "\n"; }
	$sth->execute;
	my $rv=$sth->rows;
	$sth->finish();
	$dbh->disconnect() if (!$mysql);
	return($rv);
}

sub select1 {
	# returns a single value
	$dbh->disconnect() if (!$mysql);
	$dbh=DBI->connect($dsn,$dbuser,$dbpasswd) if (!$mysql);
	my $cmd=$_[0];
	my $sth=$dbh->prepare($cmd);
	if (!$sth) { die "Error:" . $dbh->errstr . "\n"; }
	if (!$sth->execute) { die "Error:" . $sth->errstr . "\n"; }
	my $return_value=$sth->fetchrow_array(); 
	$sth->finish();
	$dbh->disconnect() if (!$mysql);
	return($return_value);
}

sub select_1dim_array {
	# returns an array with values, (selecting 1 row from a table)
	$dbh->disconnect() if (!$mysql);
	$dbh=DBI->connect($dsn,$dbuser,$dbpasswd) if (!$mysql);
	my $cmd=$_[0];
	my $sth=$dbh->prepare($cmd);
	if (!$sth) { die "Error:" . $dbh->errstr . "\n"; }
	if (!$sth->execute) { die "Error:" . $sth->errstr . "\n"; }
	my @return_value;
	while (my @ref = $sth->fetchrow_array()) {
        	push (@return_value,@ref);
	}
	$sth->finish();
	$dbh->disconnect() if (!$mysql);
	return(@return_value);
}

sub select_multi {
	# returns an array with fields separated by "|"
	$dbh->disconnect() if (!$mysql);
	$dbh=DBI->connect($dsn,$dbuser,$dbpasswd) if (!$mysql);
	my $cmd=$_[0];
	my $sth=$dbh->prepare($cmd);
	if (!$sth) { die "Error:" . $dbh->errstr . "\n"; }
	if (!$sth->execute) { die "Error:" . $sth->errstr . "\n"; }
	my @return_value;
	while (my @ref=$sth->fetchrow_array()) {
		$fields="";
		$st=0;
		foreach $i (@ref) {
			if ($st == 0) {$fields=$i;}
			else {$fields="$fields"."|".$i;}
			$st++;
		}
		push (@return_value,$fields."|"); 
	}
	$sth->finish();
	$dbh->disconnect() if (!$mysql);
	return(@return_value);
}

sub select_2dim_array {
	# returns an 2_dim array like ['field1','field2',.....]
	$dbh->disconnect() if (!$mysql);
	$dbh=DBI->connect($dsn,$dbuser,$dbpasswd) if (!$mysql);
	my $cmd=$_[0];
	my $sth=$dbh->prepare($cmd);
	if (!$sth) { die "Error:" . $dbh->errstr . "\n"; }
	if (!$sth->execute) { die "Error:" . $sth->errstr . "\n"; }
	my @return_value;
	my $count=0;
	while (my @ref=$sth->fetchrow_array()) {
		foreach $i (@ref) {
			$return_value[0][$count++]=$i;
		}
	}
	$sth->finish();
	$dbh->disconnect() if (!$mysql);
	return(@return_value);
}

sub select_array {
	# returns an array like :
	# [['field1','field2',...],['field1','field2',...]]
	$dbh->disconnect() if (!$mysql);
	$dbh=DBI->connect($dsn,$dbuser,$dbpasswd) if (!$mysql);
	my $cmd=$_[0];
	my $sth=$dbh->prepare($cmd);
	if (!$sth) { die "Error:" . $dbh->errstr . "\n"; }
	if (!$sth->execute) { die "Error:" . $sth->errstr . "\n"; }
	my @return_value;
	my $count=0;
	while (my @ref=$sth->fetchrow_array()) {
		push(@return_value,[@ref]);
	}
	$sth->finish();
	$dbh->disconnect() if (!$mysql);
	return(@return_value);
}

1;

