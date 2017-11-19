package playbj;

require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(playround playhand peekdealer playdealer calcpayouts);

use strict;
use warnings;
use Data::Dumper;

use deckbj;
use reportbj;

sub playround {

  my ($outfh, $deckref, $seqnum, $ranksref, $suitsref, $cfgref, $valhref, $strathref,
      $runcntref, $dealerstrkref) = @_;
  
  if ($#$deckref < $$cfgref{NUMDECKS} * ($#$ranksref + 1) * ($#$suitsref + 1) * (1-$$cfgref{CUTPCT})) {
    #print $outfh "Shuffle-> Cut Card\n";
    @$deckref = ();
    builddeck($deckref,$$cfgref{NUMDECKS},$suitsref,$ranksref);
	$$runcntref = 0;
  }
  
  if (defined($$cfgref{DEALERWONTBUST}) and $$cfgref{DEALERWONTBUST} <= $$dealerstrkref) {
    #print $outfh "Shuffle-> Dealer too hot\n";
    @$deckref = ();
    builddeck($deckref,$$cfgref{NUMDECKS},$suitsref,$ranksref);
	$$runcntref = 0;
	$$dealerstrkref = 0;
  }
  
  if (defined($$cfgref{STACKDECK}) and $$cfgref{STACKDECK} eq 'Y') {
    #print $outfh "Shuffle-> Stack Deck\n";
    @$deckref = ();
    builddeck($deckref,$$cfgref{NUMDECKS},$suitsref,$ranksref);
	$$runcntref = 0;
    stackdeck($deckref,$cfgref,$runcntref,$seqnum);
  }
  
  my $oldcnt = $$runcntref;
  my $numrem = $#$deckref + 1;
  my $truecnt;
  if ($oldcnt > 0) {
    $truecnt = int($$runcntref / ($numrem / (($#$ranksref + 1) * ($#$suitsref + 1))) + .5);
  }
  else {
    $truecnt = int($$runcntref / ($numrem / (($#$ranksref + 1) * ($#$suitsref + 1))) - .5);
  }
  
  if (defined($$cfgref{WALKCOUNT}) and $truecnt <= $$cfgref{WALKCOUNT}) {
    #print $outfh "Shuffle-> Count too low\n";
    @$deckref = ();
	builddeck($deckref,$$cfgref{NUMDECKS},$suitsref,$ranksref);
	$$runcntref = 0;
	$truecnt = 0;
	$numrem = $#$deckref + 1;
  }
  
  my $dealerresult = 0;
  my @tabhands;
  dealhands($deckref,\@tabhands,$cfgref,$runcntref);
  my ($offerins, $dealerbj) = peekdealer(\@tabhands, $valhref);
  # Offer insurance here
  if ($dealerbj ne 'BJ') {
    foreach my $x (0..$$cfgref{NUMPLAYERS} - 1) {
      playhand($deckref,\@tabhands,$valhref,$strathref,$cfgref,$x,0,undef,1,$$cfgref{COUNTSYS},$runcntref);
    }
    my $allbust = 1;
    foreach my $playerref (@tabhands[0..$#tabhands - 1]) {
      foreach my $handref (@$playerref) {
        $allbust = 0 if $$handref{ACTIONS}[-1] ne 'B';
      }
    }
    if (! $allbust) {
      $dealerresult = playdealer($deckref,\@tabhands,$valhref,$cfgref,$runcntref);
    }
    else {
      my $dealercard1 = substr($tabhands[-1][0]{CARDS}[0],1,1);
	  my $dealercard2 = substr($tabhands[-1][0]{CARDS}[1],1,1);
	  $tabhands[-1][0]{TOTAL} = $$valhref{$dealercard1} + $$valhref{$dealercard2};
    }
  }
  else {
    # If the dealer has BJ we really only need to see if the player also has BJ
	# otherwise he loses.
	$dealerresult = 1;
	foreach my $seatref (@tabhands) {
	  my $card1 = substr($$seatref[0]{CARDS}[0],1,1);
	  my $card2 = substr($$seatref[0]{CARDS}[1],1,1);
      if (   ($card1 eq 'A' and $$valhref{$card2} == 10)
          or ($$valhref{$card1} == 10 and $card2 eq 'A')) {
        push(@{$$seatref[0]{ACTIONS}}, 'BJ');
	    $$seatref[0]{TOTAL} = 21;
      }
	  else {
	    push(@{$$seatref[0]{ACTIONS}}, 'NA');
	  } 
    }
  }
  if ($dealerresult < 0) {
    $$dealerstrkref = 0;
  }
  elsif ($dealerresult > 0) {
    $$dealerstrkref ++;
  }
  calcpayouts(\@tabhands, $dealerbj);
  writehand($outfh, \@tabhands, $seqnum, $numrem, $oldcnt, $truecnt);
  
}

sub playhand {

  my ($deckref, $tabref, $valref, $strathref, $cfgref, $seat, $handnum, $wassplit, $allowdbl,
      $cntsys, $runcntref) = @_;

  my $card1 = substr($$tabref[$seat][$handnum]{CARDS}[0],1,1);
  # If the 2nd card hasn't been dealt- perhaps after split- deal a new card
  $$tabref[$seat][$handnum]{CARDS}[1] = shift @$deckref if ! $$tabref[$seat][$handnum]{CARDS}[1];
  my $card2 = substr($$tabref[$seat][$handnum]{CARDS}[1],1,1);
  my $dealerup = substr($$tabref[-1][0]{CARDS}[0],1,1);

  my $action = '';
  my $cardsum = 0;
  my $acespair = 'N';

  # Is it a BJ?
  if (    (   ($card1 eq 'A' and $$valref{$card2} == 10)
           or ($$valref{$card1} == 10 and $card2 eq 'A'))
      and (! $wassplit)
     ) {
    push(@{$$tabref[$seat][$handnum]{ACTIONS}}, 'BJ');
	$$tabref[$seat][$handnum]{TOTAL} = 21;
    return;
  }
	
  # Actions come from config?
  if (    defined($$cfgref{STACKDECK}) and $$cfgref{STACKDECK} eq 'Y'
      and defined($$cfgref{STACKSEAT}) and $$cfgref{STACKSEAT} == $seat + 1
      and defined($$cfgref{ACTIONS}) and length($$cfgref{ACTIONS}) != 0
	  and !defined($$tabref[$seat][$handnum]{ACTIONS}[0])) {
	my @actar = split(',',$$cfgref{ACTIONS});
	$action = $actar[int(rand($#actar + 1))];
	$cardsum = $$valref{$card1} + $$valref{$card2};
	$cardsum += 10 if ($card1 eq 'A' or $card2 eq 'A');
  }
  # Actions come from strategy
  else {
    # Is it a pair?
    if ($$valref{$card1} == $$valref{$card2}
	    and defined($$cfgref{MAXSPLIT}) 
		and $$cfgref{MAXSPLIT} > $#{$$tabref[$seat]} + 1) {
	  # Is it aces?
	  $acespair = 'Y' if $card1 eq 'A';
      $action = $$strathref{'pair'}{$$valref{$card1}}[$$valref{$dealerup}-1];
	  $cardsum = $$valref{$card1} + $$valref{$card2};
    }
    # Is it a soft hand?
    elsif ($card1 eq 'A' or $card2 eq 'A') {
      $cardsum = $$valref{$card1} + $$valref{$card2} + 10;
      $action = $$strathref{'ace'}{$cardsum}[$$valref{$dealerup}-1];
    }
    else {
      $cardsum = $$valref{$card1} + $$valref{$card2};
      $action = $$strathref{'norm'}{$cardsum}[$$valref{$dealerup}-1];
    } 
  }

  push(@{$$tabref[$seat][$handnum]{ACTIONS}}, $action);
  if ($action eq 'P') {
    push @{$$tabref[$seat]}, { CARDS => [ $$tabref[$seat][$handnum]{CARDS}[1] ],
                               BET => 1 ,
                               ACTIONS => ['P']};
    pop @{$$tabref[$seat][$handnum]{CARDS}};
	my $splithand = $#{$$tabref[$seat]};
	if ($acespair ne 'Y') {
	  playhand($deckref,$tabref,$valref,$strathref,$cfgref,$seat,$handnum,1,$allowdbl,$cntsys,$runcntref);
      playhand($deckref,$tabref,$valref,$strathref,$cfgref,$seat,$splithand,1,$allowdbl,$cntsys,$runcntref);
	}
	else {
	  if ($$cfgref{RESPLITACES} eq 'N') {
	    # First ace
	    push @{$$tabref[$seat][$handnum]{CARDS}}, deal1card($deckref, $cntsys, $runcntref);
		print Dumper($tabref);
		my $card2 = substr($$tabref[$seat][$handnum]{CARDS}[1],1,1);
		$$tabref[$seat][$handnum]{TOTAL} = $$valref{$card1} + $$valref{$card2} + 10;
		# Second ace
		push @{$$tabref[$seat][$splithand]{CARDS}}, deal1card($deckref, $cntsys, $runcntref);
	    $card2 = substr($$tabref[$seat][$splithand]{CARDS}[1],1,1);
		$$tabref[$seat][$splithand]{TOTAL} = $$valref{$card1} + $$valref{$card2} + 10;
	  }
	  else {
        playsplitaces($deckref, $tabref, $valref, $cfgref, $seat, $handnum, $splithand, $cntsys, $runcntref)
	  }
	}	    
  }
  elsif ($action eq 'D' or ($action eq 'd' and $allowdbl)) {
    push @{$$tabref[$seat][$handnum]{CARDS}}, deal1card($deckref, $cntsys, $runcntref);
	my $card3 = substr($$tabref[$seat][$handnum]{CARDS}[2],1,1);
	my $handsum = $$valref{$card1} + $$valref{$card2} + $$valref{$card3};
	if ($handsum <= 11) {
	  $handsum += 10 if $card1 eq 'A' or $card2 eq 'A' or $card3 eq 'A';
	}
    $$tabref[$seat][$handnum]{TOTAL} = $handsum;
	# This next line look crazy, but what if we weren't playing smart?
	push(@{$$tabref[$seat][$handnum]{ACTIONS}},'B') if $handsum > 21;
    $$tabref[$seat][$handnum]{BET} *= 2;
  }
  elsif ($action eq 'H' or ($action eq 'D' and ! $allowdbl)) {
    push @{$$tabref[$seat][$handnum]{CARDS}}, deal1card($deckref, $cntsys, $runcntref);
    my $finres = playafterhit($deckref,$tabref,$valref,$strathref,$seat,$handnum, $cntsys, $runcntref);
  }
  elsif ($action eq 'S' or ($action eq 'd' and ! $allowdbl)) {
    $$tabref[$seat][$handnum]{TOTAL} = $cardsum;
  }

}

sub playafterhit {

    my ($deckref, $tabref, $valref, $strathref, $seat, $handnum, $cntsys, $runcntref) = @_;

    my $dealerup = substr($$tabref[-1][0]{CARDS}[0],1,1);
    my ($stand,$bust) = (0,0);

    CARD:
    while (! $stand and ! $bust) {
      my @temphandar;
      my ($handsumlow, $handsumhigh) = (0,0);
      foreach my $card (@{$$tabref[$seat][$handnum]{CARDS}}) {
        my $value = $$valref{substr($card,1,1)};
        push @temphandar, $value;
        $handsumlow += $value;
        $handsumhigh += $value; 
		$handsumhigh += 10 if $value == 1 and $handsumhigh == $handsumlow;
      }
      if ($handsumlow > 21) {
        push @{$$tabref[$seat][$handnum]{ACTIONS}}, 'B';
		$$tabref[$seat][$handnum]{TOTAL} = $handsumlow;
        $bust = -1;
        next CARD;
      }
      # No aces in the hand?
      if (! grep( {$_ == 1} @temphandar) ) {
        if ($handsumlow >= 17 or $$strathref{'norm'}{$handsumlow}[$$valref{$dealerup}-1] eq 'S') {
          push @{$$tabref[$seat][$handnum]{ACTIONS}}, 'S';
		  $$tabref[$seat][$handnum]{TOTAL} = $handsumlow;
          $stand = 1;
          next CARD;
        }
        else {
          push @{$$tabref[$seat][$handnum]{CARDS}}, deal1card($deckref, $cntsys, $runcntref);
          push @{$$tabref[$seat][$handnum]{ACTIONS}}, 'H';
          next CARD;
        }
      }
      else {
        if ($handsumhigh <= 21) {
          if ($$strathref{'ace'}{$handsumhigh}[$$valref{$dealerup}-1] =~ /[dS]/) {
            push @{$$tabref[$seat][$handnum]{ACTIONS}}, 'S';
			$$tabref[$seat][$handnum]{TOTAL} = $handsumhigh;
            $stand = 1;
            next CARD;
          }
          else {
            push @{$$tabref[$seat][$handnum]{CARDS}}, deal1card($deckref, $cntsys, $runcntref);
            push @{$$tabref[$seat][$handnum]{ACTIONS}}, 'H';
            next CARD;
          }
        }
        else {
          if ($$strathref{'norm'}{$handsumlow}[$$valref{$dealerup}-1] eq 'S') {
            push @{$$tabref[$seat][$handnum]{ACTIONS}}, 'S';
			$$tabref[$seat][$handnum]{TOTAL} = $handsumlow;
            $stand = 1;
            next CARD;
          }
          else {
            push @{$$tabref[$seat][$handnum]{CARDS}}, deal1card($deckref, $cntsys, $runcntref);
            push @{$$tabref[$seat][$handnum]{ACTIONS}}, 'H';
            next CARD;
          }
        }
      }
    }
    return $bust + $stand;

}

sub playsplitaces {
  
  my ($deckref, $tabref, $valref, $cfgref, $seat, $handnum, $splithand, $cntsys, $runcntref) = @_;
  
  my $card1 = 'A';
  # Play first ace
  push @{$$tabref[$seat][$handnum]{CARDS}}, deal1card($deckref, $cntsys, $runcntref);
  my $card2 = substr($$tabref[$seat][$handnum]{CARDS}[1],1,1);
  if ($card2 eq 'A' 
      and defined($$cfgref{MAXSPLIT}) 
	  and $$cfgref{MAXSPLIT} > $#{$$tabref[$seat]} + 1) {
    push @{$$tabref[$seat]}, { CARDS => [ $$tabref[$seat][$handnum]{CARDS}[1] ],
                               BET => 1 ,
                               ACTIONS => ['P']};
    pop @{$$tabref[$seat][$handnum]{CARDS}};
	my $newsplithand = $#{$$tabref[$seat]};
    playsplitaces($deckref, $tabref, $valref, $cfgref, $seat, $handnum, $newsplithand, $cntsys, $runcntref);
  }
  else {
    $$tabref[$seat][$handnum]{TOTAL} = $$valref{$card1} + $$valref{$card2} + 10;
  }
  # Play second ace
  push @{$$tabref[$seat][$splithand]{CARDS}}, deal1card($deckref, $cntsys, $runcntref);
  $card2 = substr($$tabref[$seat][$splithand]{CARDS}[1],1,1);
  if ($card2 eq 'A' 
      and defined($$cfgref{MAXSPLIT}) 
	  and $$cfgref{MAXSPLIT} > $#{$$tabref[$seat]} + 1) {
    push @{$$tabref[$seat]}, { CARDS => [ $$tabref[$seat][$splithand]{CARDS}[1] ],
                               BET => 1 ,
                               ACTIONS => ['P']};
    pop @{$$tabref[$seat][$splithand]{CARDS}};
	my $newsplithand = $#{$$tabref[$seat]};
    playsplitaces($deckref, $tabref, $valref, $cfgref, $seat, $splithand, $newsplithand, $cntsys, $runcntref);
  }
  else {
    $$tabref[$seat][$splithand]{TOTAL} = $$valref{$card1} + $$valref{$card2} + 10;
  }
  		 
}

sub peekdealer {

  my ($tabref, $valref) = @_;

  my $upcard = $$tabref[-1][0]{CARDS}[0];
  my $holecard = $$tabref[-1][0]{CARDS}[1];
  if ($$valref{substr($upcard,1,1)} == 10) {
    if (substr($holecard,1,1) eq 'A') {
      return ('NI','BJ');
    }
    else {
      return ('NI', 'NBJ');
    }
  }
  elsif (substr($upcard,1,1) eq 'A') {
    if ($$valref{substr($holecard,1,1)} == 10) {
      return ('I','BJ');
    }
    else {
      return ('I','NBJ');
    }
  }
  else {
    return ('NI', 'NBJ');
  }

}

sub playdealer {

    my ($deckref, $tabref, $valref, $cfgref, $runcntref) = @_;

    my ($stand,$bust) = (0,0);
    
    CARD:
    while (! $stand and ! $bust) {
      my ($handsumlow, $handsumhigh) = (0,0);
      foreach my $card (@{$$tabref[-1][0]{CARDS}}) {
        my $value = $$valref{substr($card,1,1)};
        $handsumlow += $value;
        $handsumhigh += $value;
        $handsumhigh += 10 if $value == 1 and $handsumhigh <= 11;
      }
      if (    ($handsumhigh > 17 and $handsumhigh < 22)
           or ($handsumhigh == 17 and $$cfgref{SOFT17} eq 'S')
         ) {
		$$tabref[-1][0]{TOTAL} = $handsumhigh;
        $stand = 1;
        next CARD;
      }
	  elsif ($handsumlow >= 17 and $handsumlow < 22) {
	    $$tabref[-1][0]{TOTAL} = $handsumlow;
	    $stand = 1;
		next CARD;
	  }
      elsif ($handsumlow > 21) {
	    $$tabref[-1][0]{TOTAL} = $handsumlow;
        $bust = 1;
        next CARD;
      }
      else {
        push @{$$tabref[-1][0]{CARDS}}, deal1card($deckref, $$cfgref{COUNTSYS}, $runcntref);
        next CARD;
      }
    }

    return $stand - $bust;

}

sub calcpayouts {

  my ($tabhandsref, $dealerbj) = @_;
  
  if ($dealerbj ne 'BJ') {
    my $dealertot = $$tabhandsref[-1][0]{TOTAL};
    foreach my $seatref (@$tabhandsref[0 .. $#$tabhandsref - 1]) {
      foreach my $handref (@$seatref) {
	    #print "Action = $$handref{ACTIONS}[0]; Dealertot = $dealertot; Handtot = $$handref{TOTAL}\n" 
		#  if $$handref{ACTIONS}[0] eq 'S';
	    if ($$handref{ACTIONS}[0] eq 'BJ') {
	      $$handref{PAYOUT} = $$handref{BET} * 2.5;
	    }
	    elsif ($$handref{ACTIONS}[-1] eq 'B') {
          $$handref{PAYOUT} = 0;
	    }
	    elsif ($dealertot > 21) {
	      $$handref{PAYOUT} = $$handref{BET} * 2;
	    }
	    elsif ($$handref{TOTAL} > $dealertot) {
	      $$handref{PAYOUT} = $$handref{BET} * 2;
	    }
	    elsif ($$handref{TOTAL} < $dealertot) {
	      $$handref{PAYOUT} = 0;
	    }
	    else {
	      $$handref{PAYOUT} = $$handref{BET};
	    }
	  }
    }
  }
  else {
    foreach my $seatref (@$tabhandsref[0 .. $#$tabhandsref - 1]) {
	  no warnings 'uninitialized';
	  if ($$seatref[0]{ACTIONS}[0] ne 'BJ') {
	    $$seatref[0]{PAYOUT} = 0;
	  }
	  else {
	    $$seatref[0]{PAYOUT} = $$seatref[0]{BET};
	  }
	}
  }
}

1
