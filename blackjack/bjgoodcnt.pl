#!/usr/bin/perl

use warnings;
use strict;

use Data::Dumper;
use Benchmark;

open my $cfgfh, '<', './blackjack.cfg' or die "Can't open config file";
my %cfg;
while (<$cfgfh>) {
  next if /^\[/;
  next if /^#/;
  next if /^\s*$/;
  /([^=\s]*)\s*=\s*(.*)\s*$/;
  $cfg{$1} = $2;
}

open my $infh, '<', "$cfg{HANDSFILE}" or die "Can't open hand history file";

my %bjcnt;
my $bjhands = 0;

HAND:
while (<$infh>) {
  next HAND if $_ !~ /BJ/;
  $bjhands ++;
  my @handar = split /\|/;
  my $truecnt = $handar[3];
  for my $x (4..($cfg{NUMPLAYERS} + 3)) {
	#if ($handar[$x] =~ /BJ/) {
      $bjcnt{$truecnt}{player}{cnt} ++;
      my @playerhand = split(/:/, $handar[$x]);
      $bjcnt{$truecnt}{player}{bet} += $playerhand[0];
      $bjcnt{$truecnt}{player}{pay} += $playerhand[-1];
    #} 
  }
  $bjcnt{$truecnt}{dealer}{cnt} ++ if $handar[-1] =~ /BJ/;
  #last HAND if $handar[0] > 10;
}

for my $tc (sort {$a<=>$b} keys %bjcnt) {
  $bjcnt{$tc}{dealer}{cnt} = 0 if not defined $bjcnt{$tc}{dealer}{cnt};
  $bjcnt{$tc}{player}{cnt} = 0 if not defined $bjcnt{$tc}{player}{cnt};
  #print $tc . ': ' . $bjcnt{$tc}{player}{cnt} . '|' . $bjcnt{$tc}{dealer}{cnt} . '=';
  #my $ratio = $bjcnt{$tc}{player}{cnt} / ($bjcnt{$tc}{player}{cnt} + $bjcnt{$tc}{dealer}{cnt});
  #print "$ratio\n";
  print $tc . ':' . eval($bjcnt{$tc}{player}{pay} - $bjcnt{$tc}{player}{bet}) . "\n";
}

print "BJHANDS = $bjhands\n";
