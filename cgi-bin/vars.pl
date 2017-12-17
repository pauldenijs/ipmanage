#! /usr/bin/perl

print "Content-Type: text/html\n\n";
print "<html><body>\n";
foreach $var (sort keys(%ENV)) {
	print($var, ' = ', $ENV{$var}, "<br/>\n");
}
print "</html></body>\n";
