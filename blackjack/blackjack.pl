#!/usr/bin/perl

use warnings;
use strict;

use threads;
use Data::Dumper;
use Benchmark;

use lib '.';
use playbj;
use deckbj;

my $valhash = {'A'=>1, '2'=>2, '3'=>3, '4'=>4, '5'=>5, '6'=>6, '7'=>7, '8'=>8, '9'=>9, 'T'=>10, 'J'=>10, 'Q'=>10, 'K'=>10};

# Dealer upcard                   A    2    3    4    5    6    7    8    9   10
my $strat = { 'norm' => { 3 => [ 'H', 'H', 'H', 'H', 'H', 'H', 'H', 'H', 'H', 'H' ],
                          4 => [ 'H', 'H', 'H', 'H', 'H', 'H', 'H', 'H', 'H', 'H' ],
                          5 => [ 'H', 'H', 'H', 'H', 'H', 'H', 'H', 'H', 'H', 'H' ],
                          6 => [ 'H', 'H', 'H', 'H', 'H', 'H', 'H', 'H', 'H', 'H' ],
                          7 => [ 'H', 'H', 'H', 'H', 'H', 'H', 'H', 'H', 'H', 'H' ],
                          8 => [ 'H', 'H', 'H', 'H', 'H', 'H', 'H', 'H', 'H', 'H' ],
                          9 => [ 'H', 'H', 'D', 'D', 'D', 'D', 'H', 'H', 'H', 'H' ],
                         10 => [ 'H', 'D', 'D', 'D', 'D', 'D', 'D', 'D', 'H', 'H' ],
                         11 => [ 'H', 'D', 'D', 'D', 'D', 'D', 'D', 'D', 'D', 'H' ],
                         12 => [ 'H', 'H', 'H', 'S', 'S', 'S', 'H', 'H', 'H', 'H' ],
                         13 => [ 'H', 'S', 'S', 'S', 'S', 'S', 'H', 'H', 'H', 'H' ],
                         14 => [ 'H', 'S', 'S', 'S', 'S', 'S', 'H', 'H', 'H', 'H' ],
                         15 => [ 'H', 'S', 'S', 'S', 'S', 'S', 'H', 'H', 'H', 'H' ],
                         16 => [ 'H', 'S', 'S', 'S', 'S', 'S', 'H', 'H', 'H', 'H' ],
                         17 => [ 'S', 'S', 'S', 'S', 'S', 'S', 'S', 'S', 'S', 'S' ],
                         18 => [ 'S', 'S', 'S', 'S', 'S', 'S', 'S', 'S', 'S', 'S' ],
                         19 => [ 'S', 'S', 'S', 'S', 'S', 'S', 'S', 'S', 'S', 'S' ],
                         20 => [ 'S', 'S', 'S', 'S', 'S', 'S', 'S', 'S', 'S', 'S' ],
                         21 => [ 'S', 'S', 'S', 'S', 'S', 'S', 'S', 'S', 'S', 'S' ]
                        },
              'ace' =>  {12 => [ 'H', 'H', 'H', 'H', 'D', 'D', 'H', 'H', 'H', 'H' ],
                         13 => [ 'H', 'H', 'H', 'H', 'D', 'D', 'H', 'H', 'H', 'H' ],
                         14 => [ 'H', 'H', 'H', 'H', 'D', 'D', 'H', 'H', 'H', 'H' ],
                         15 => [ 'H', 'H', 'H', 'D', 'D', 'D', 'H', 'H', 'H', 'H' ],
                         16 => [ 'H', 'H', 'H', 'D', 'D', 'D', 'H', 'H', 'H', 'H' ],
                         17 => [ 'H', 'H', 'D', 'D', 'D', 'D', 'H', 'H', 'H', 'H' ],
                         18 => [ 'H', 'd', 'd', 'd', 'd', 'd', 'S', 'S', 'H', 'H' ],
                         19 => [ 'S', 'S', 'S', 'S', 'S', 'd', 'S', 'S', 'S', 'S' ],
                         20 => [ 'S', 'S', 'S', 'S', 'S', 'S', 'S', 'S', 'S', 'S' ],
                         21 => [ 'S', 'S', 'S', 'S', 'S', 'S', 'S', 'S', 'S', 'S' ]
                        },
              'pair' => { 1 => [ 'P', 'P', 'P', 'P', 'P', 'P', 'P', 'P', 'P', 'P' ],
                          2 => [ 'H', 'H', 'H', 'P', 'P', 'P', 'P', 'H', 'H', 'H' ],
                          3 => [ 'H', 'H', 'H', 'P', 'P', 'P', 'P', 'H', 'H', 'H' ],
                          4 => [ 'H', 'H', 'H', 'H', 'P', 'P', 'H', 'H', 'H', 'H' ],
                          5 => [ 'H', 'D', 'D', 'D', 'D', 'D', 'D', 'D', 'D', 'H' ],
                          6 => [ 'H', 'P', 'P', 'P', 'P', 'P', 'H', 'H', 'H', 'H' ],
                          7 => [ 'H', 'P', 'P', 'P', 'P', 'P', 'P', 'H', 'H', 'H' ],
                          8 => [ 'P', 'P', 'P', 'P', 'P', 'P', 'P', 'P', 'P', 'P' ],
                          9 => [ 'S', 'P', 'P', 'P', 'P', 'P', 'S', 'P', 'P', 'S' ],
                         10 => [ 'S', 'S', 'S', 'S', 'S', 'S', 'S', 'S', 'S', 'S' ]
                        }
            };

open my $cfgfh, '<', './blackjack.cfg' or die "Can't open config file";
my %cfg;
while (<$cfgfh>) {
  next if /^\[/;
  next if /^#/;
  next if /^\s*$/;
  /([^=\s]*)\s*=\s*(.*)\s*$/;
  $cfg{$1} = $2;
}

my @suits;
my @ranks;
my @deck;
my $runcnt = 0;
my $t0 = Benchmark->new;

#builddeck(\@deck,$cfg{NUMDECKS},\@suits,\@ranks);
#stackdeck(\@deck,\%cfg,\$runcnt) if defined($cfg{STACKDECK}) and $cfg{STACKDECK} eq 'Y';  
  
#foreach my $x (1 .. $cfg{THREADS}) {
  my $filenm = $cfg{HANDSFILE};
#  $filenm =~ s/(\.*).{3}$/$1_$x.txt/;
  open my $fh, '>', "$filenm" or die "Can't open output file";
#  my $thr = threads->create(
#                       sub {playround($fh, \@deck, \@ranks, \@suits, \%cfg, $valhash, $strat) 
#		                     for 1..$cfg{NUMROUNDS};
#				       });       
#  $thr->detach();
  my $dealerstrk = 0;
  for my $x (1..$cfg{NUMROUNDS}) {
    playround($fh, \@deck, $x, \@ranks, \@suits, \%cfg, $valhash, $strat, \$runcnt, \$dealerstrk);
  }
    
#}

my $t1 = Benchmark->new;
my $td = timediff($t1, $t0);
print timestr($td);
