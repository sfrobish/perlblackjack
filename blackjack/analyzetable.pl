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
open my $outfh, '>', "$cfg{REPORTFILE}" or die "Can't open report file";
print $outfh "Sequence Num,";
print $outfh join(',',map{'Player' . $_} (1..$cfg{NUMPLAYERS}));
print $outfh "\n";

my @chipsar;
for my $x (1..$cfg{NUMPLAYERS}) {
  $chipsar[$x-1] = $cfg{STARTSTACK};
}

my @lasthandar; 
for my $x (1..$cfg{NUMPLAYERS}) {
  $lasthandar[$x-1] = 0;
}

my @sidebetar; 
for my $x (0..$cfg{NUMPLAYERS} - 1) {
  $sidebetar[$x]{PLAYED} = 0;
  $sidebetar[$x]{WIN}{PAY4to1} = 0;
  $sidebetar[$x]{WIN}{PAY10to1} = 0;
  $sidebetar[$x]{WIN}{PAY25to1} = 0;
  $sidebetar[$x]{WIN}{PAY200to1} = 0;
  $sidebetar[$x]{WIN}{PAY1000to1} = 0;
  $sidebetar[$x]{LOSS} = 0;
  $sidebetar[$x]{VALUE} = 0;
}


my @winpct;
my %streak;
my @curstr;
my $betfactor = 1;  # For the team martingale system

HAND:
while (<$infh>) {
  next HAND if /Shuffle/i;
  my @handar = split /\|/; 
  my $seqnum = $handar[0];
  my $truecnt = $handar[3];
  my $dealerbj = 'Y' if substr($handar[-1],0,index($handar[-1],':')) eq 'BJ';
  my @rsltar;
  for my $x (1..$cfg{NUMPLAYERS}) {
    my $handtxt = $handar[$x + 3];
	my ($bet,$pay) = (0,0);
	$sidebetar[$x-1]{PLAYED} ++ if $truecnt >= $cfg{SIDEGAMETC};
	if ($handtxt !~ /~/) {
	  my @playerhandar = split(':',$handtxt);
	  $bet = $playerhandar[0] * $cfg{BETUNIT} * $betfactor;
	  $pay = $playerhandar[-1] * $cfg{BETUNIT} * $betfactor;
	  # Here is the lucky ladies bet we'll assume that we are never splitting 10's
	  if ($cfg{SIDEGAME} =~ /luckyladies/i) {
	    if ($truecnt >= $cfg{SIDEGAMETC}) {
		  luckyladies(\@sidebetar, \@playerhandar, $x-1, $dealerbj, $cfg{SIDEBETUNIT});
		}
	  }
	}
	else {
	  my @subhands = split(/~/,$handtxt);
	  foreach my $splithand (@subhands) {
	    my @playerhandar = split(':', $splithand);
	    $bet += $playerhandar[0] * $cfg{BETUNIT} * $betfactor;
		$pay += $playerhandar[-1] * $cfg{BETUNIT} * $betfactor;
	  }
	  # This is for when we played lucky ladies but clearly didn't win because we are splitting
	  if ($cfg{SIDEGAME} =~ /luckyladies/i) {
	    if ($truecnt >= $cfg{SIDEGAMETC}) {
		  $sidebetar[$x-1]{VALUE} -= $cfg{SIDEBETUNIT};
		  $sidebetar[$x-1]{LOSS} ++;
		}
	  }
	}
	calctotwinpct(\@winpct, $x, $bet, $pay);
	calcstreak(\%streak, \@curstr, $x, $bet, $pay, $seqnum);
	$chipsar[$x-1] += $pay - $bet if $cfg{BETSYSTEM} =~ /flat/i;
	negprog3(\@chipsar, \@lasthandar, $x, \$pay, \$bet) if $cfg{BETSYSTEM} eq 'negprog3';
	negprog(\@chipsar, \@lasthandar, $x, \$pay, \$bet) if $cfg{BETSYSTEM} eq 'negprog';
	posprog(\@chipsar, \@lasthandar, $x, \$pay, \$bet) if $cfg{BETSYSTEM} eq 'posprog';
	truecnt(\@chipsar, $x, $truecnt, \$pay, \$bet) if $cfg{BETSYSTEM} eq 'truecnt';
	randompos4(\@chipsar, $x, $truecnt, \$pay, \$bet) if $cfg{BETSYSTEM} eq 'randompos4';
	randompos6(\@chipsar, $x, $truecnt, \$pay, \$bet) if $cfg{BETSYSTEM} eq 'randompos6';
	randompos8(\@chipsar, $x, $truecnt, \$pay, \$bet) if $cfg{BETSYSTEM} eq 'randompos8';
	$chipsar[$x-1] += $pay - $bet if $cfg{BETSYSTEM} eq 'teammart';
	$rsltar[$x-1] = [$bet, $pay];
  }
  betemall(\@chipsar, $truecnt, \@rsltar, $cfg{NUMPLAYERS}) if $cfg{SIDEGAME} eq 'betemall';
  teammart(\@rsltar, \$betfactor) if $cfg{BETSYSTEM} eq 'teammart';
  writestack($outfh, $seqnum, \@chipsar) if (defined($cfg{TREND}) and $cfg{TREND} eq 'Y');
}

my $outln = join(',',@chipsar);
print $outln;
#print Dumper(\@sidebetar);
#print Dumper(\@winpct);
#print Dumper(\%streak);
