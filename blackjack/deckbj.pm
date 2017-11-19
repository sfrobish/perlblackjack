package deckbj;

require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(dealhands deal1card builddeck stackdeck);

use strict;
use warnings;

sub dealhands {

  my ($deckref, $tabref, $cfgref, $runcntref) = @_;

  foreach my $card (0..1) {
    foreach my $seat (0..$$cfgref{NUMPLAYERS}) {
      $$tabref[$seat][0]{CARDS}[$card] = deal1card($deckref, $$cfgref{COUNTSYS}, $runcntref);
      $$tabref[$seat][0]{BET} = 1 if $seat != $$cfgref{NUMPLAYERS};
    }
  }
  
}

sub deal1card {

  my ($deckref, $cntsys, $runcntref) = @_;

  my $card = shift @$deckref;

  my $rank = substr($card,-1);
  $$runcntref += cntcards($cntsys, $rank);
  return($card);
  
}

sub cntcards { 

  my ($cntsys, $rank) = @_;
  
  if ($cntsys eq 'Hi-Lo') {
    return -1 if $rank =~ /A|T|Q|J|K/;
    return +1 if $rank =~ /2|3|4|5|6/;
	return 0;
  }  
  
}

sub builddeck {

  my ($deckref, $numdecks, $suitsref, $ranksref) = @_;
  
  @$suitsref = ('H', 'D', 'S', 'C');
  @$ranksref = ('A', '2', '3', '4', '5', '6', '7', '8', '9', 'T', 'J', 'Q', 'K');
  for (1..$numdecks) {
    foreach my $cardrank (@$ranksref) {
      foreach my $cardsuit (@$suitsref) {
        push @$deckref, $cardsuit . $cardrank;
      }
    }
  }
  use List::Util 'shuffle';
  @$deckref = shuffle(@$deckref);
  
}

sub stackdeck {

  my ($deckref, $cfgref, $runcntref, $handnum) = @_;
  
  $$cfgref{STARTHAND} =~ /^\s*(.{2})\s*,\s*(.{2})\s*$/;
  my $playercard1 = $1;
  my $playercard2 = $2;
  my ($fnd1, $fnd2, $fnddlr);
  my $dealercard = 'N';
  if ($$cfgref{DEALERSHOW} =~ /^\s*(.{2})\s*$/) {
    $dealercard = $1;
  }
  else {
    $fnddlr = '-1';
  }
  
  FIND:
  for my $x (0..$#$deckref) {
    if (!defined($fnd1) and $playercard1 eq $$deckref[$x] and $x != $$cfgref{STACKSEAT} - 1) {
	  $$deckref[$x] = $$deckref[$$cfgref{STACKSEAT} - 1];
      $$deckref[$$cfgref{STACKSEAT} - 1] = $playercard1;
	  $fnd1 = 'Y';
	  next FIND;
    }
	if (!defined($fnd2) and $playercard2 eq $$deckref[$x] and $x != $$cfgref{STACKSEAT} - 1 + $$cfgref{NUMPLAYERS} + 1) {
	  $$deckref[$x] = $$deckref[$$cfgref{STACKSEAT} - 1 + $$cfgref{NUMPLAYERS} + 1];
      $$deckref[$$cfgref{STACKSEAT} - 1 + $$cfgref{NUMPLAYERS} + 1] = $playercard2;
	  $fnd2 = 'Y';
	  next FIND;
	}
	if (!defined($fnddlr) and $dealercard eq $$deckref[$x]) {
	  $fnddlr = $x;
	}
	last FIND if (defined($fnd1) and defined($fnd2) and defined($fnddlr));
  }

  if ($fnddlr != -1) {
    $$deckref[$fnddlr] = $$deckref[$$cfgref{NUMPLAYERS}];
    $$deckref[$$cfgref{NUMPLAYERS}] = $dealercard;
  }
  
  if ($$deckref[$$cfgref{NUMPLAYERS}] ne $dealercard) {
    print "Wrong dealer\n";
	print join(',',@$deckref[0..(($$cfgref{NUMPLAYERS}+1)*2)-1]) ."\n";
  }
  
  # Interesting question here.  In determining the running count after a certain 
  # deck penetration.  Does it really matter if the count came from the back of the shoe
  # or the front?  For example, if I count in from the front like you would in Vegas and get
  # +5 true cnt half way through the shoe- is that any different than if the dealer just showed
  # the last half of the shoe and found it to be +5.  
  # It is easier to shorten the deck by the back for certain.
  my $penidx;
  if ($$cfgref{DECKPEN} eq 'RANDOM') {
    $penidx = int(rand($#$deckref * $$cfgref{CUTPCT}));
  }
  elsif ($$cfgref{DECKPEN} =~ /^(\.\d+)/) {
    $penidx = int($#$deckref * $1);
  }
  else {
    $penidx = 0;
  }
  if ($penidx != 0) {
    for (0 .. $penidx) {
	  my $card = pop @$deckref;
	  my $rank = substr($card,1,1);
	  $$runcntref += cntcards($$cfgref{COUNTSYS}, $rank);
	}
  }
  
}
 
1