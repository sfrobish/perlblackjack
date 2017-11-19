#!/usr/bin/perl

use warnings;
use strict;

use Data::Dumper;


my $iter = shift;

my @avgar;
my @hiar;
my @lowar;

for (my $x=0; $x < $iter; $x++) {

  no warnings 'uninitialized';
  qx|./blackjack.pl|;
  my $line = qx|./analyzetable.pl|;
  chomp($line);
  my @tmpar = split(/,/ , $line);
  #print Dumper(\@tmpar);
  for (my $z = 0; $z < scalar(@tmpar); $z++) {
	$avgar[$z] = $avgar[$z] + $tmpar[$z];
	$hiar[$z] = $tmpar[$z] if $tmpar[$z] > $hiar[$z];
	$lowar[$z] = $tmpar[$z] if $tmpar[$z] < $lowar[$z];
  }
  

}

print 'avg: ';
foreach my $i (@avgar) {
  my $final = $i / $iter;
  print "$final,";
}
print "\n";

print 'hi: ';
foreach my $j (@hiar) {
  my $final = $j;
  print "$final,";
}
print "\n";

print 'low: ';
foreach my $k (@lowar) {
  my $final = $k;
  print "$final,";
}
print "\n";
