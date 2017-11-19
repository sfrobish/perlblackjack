#!/usr/bin/perl

use warnings;
use strict;

use Data::Dumper;
use Benchmark;

use lib '.';
use chipstack;
use betsystem;
use reportbj;
use calcbj;

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

my @playerfirstact;
my $dealerbust = 0;

HAND:
while(<$infh>) {
  chomp;
  next HAND if /Shuffle/i;
  my @seatar = split /\|/; 
  my $seqnum = $seatar[0];
  my $truecnt = $seatar[3];
  for my $x (1..$cfg{NUMPLAYERS}) {
    my $handtxt = $seatar[$x + 3];
	my ($bet,$pay) = (0,0);
	my $firstact;
	if ($handtxt !~ /~/) {
	  my @handar = split(':',$handtxt);
	  $firstact = substr($handar[1],0,1);
	  $bet = $handar[0];
	  $pay = $handar[-1];
	}
	else {
	  $firstact = 'P';
	  my @subhands = split(/~/,$handtxt);
	  foreach my $splithand (@subhands) {
	    my @handar = split(':', $splithand);
	    $bet += $handar[0];
		$pay += $handar[-1];
	  }
	}
	firstact(\@playerfirstact,$firstact,$bet,$pay,$x);
  }
  $dealerbust ++ if substr($seatar[-1],-2) > 21;
}

print "$dealerbust\n";
print Dumper(\$playerfirstact[$cfg{STACKSEAT}-1]);

sub firstact {

  my ($playerfirstact, $firstact, $bet, $pay, $x) = @_;
  
  $$playerfirstact[$x-1]{$firstact}{NUM} ++;
  $$playerfirstact[$x-1]{$firstact}{WIN} ++ if $pay - $bet > 0;
  $$playerfirstact[$x-1]{$firstact}{LOSS} ++ if $pay - $bet < 0;
  $$playerfirstact[$x-1]{$firstact}{PUSH} ++ if $pay - $bet == 0;
  $$playerfirstact[$x-1]{$firstact}{VALUE} += $pay - $bet;
  
}

