package betsystem;

require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(negprog3 negprog posprog truecnt luckyladies randompos4 randompos6 randompos8 betemall teammart);

sub negprog3 {

  my ($chipsaref, $lasthandaref, $x, $payref, $betref) = @_;
  
  if ($$lasthandaref[$x-1] == -1) {
    $$payref *= 2;
	  $$betref *= 2;
  }
  elsif ($$lasthandaref[$x-1] == -2) {
    $$payref *= 4;
	  $$betref *= 4;
  }
  
  my $handresult;
  if ($$payref - $$betref > 0) {
    $handresult = 'W';
	  $$lasthandaref[$x-1] = 0;
  }
  elsif ($$payref - $$betref == 0) {
    $handresult = 'P';
  }
  else {
    $handresult = 'L';
	  if ($$lasthandaref[$x-1] > -2) {
	    $$lasthandaref[$x-1] --;
	  }
	  else {
	    $$lasthandaref[$x-1] = 0;
	  }
  }
  
  $$chipsaref[$x-1] += $$payref - $$betref;

}

sub negprog {

  my ($chipsaref, $lasthandaref, $x, $payref, $betref) = @_;
  
  if ($$lasthandaref[$x-1] < 0) {
	  $$payref *= 2 ** ($$lasthandaref[$x-1] * -1);
	  $$betref *= 2 ** ($$lasthandaref[$x-1] * -1);
  }
  
  my $handresult;
  if ($$payref - $$betref > 0) {
    $handresult = 'W';
	  $$lasthandaref[$x-1] = 0;
  }
  elsif ($$payref - $$betref == 0) {
    $handresult = 'P';
  }
  else {
    $handresult = 'L';
	  if ($$lasthandaref[$x-1] > -6) {
	    $$lasthandaref[$x-1] --;
	  }
	  else {
	    $$lasthandaref[$x-1] = 0;
	  }
  }
  
  $$chipsaref[$x-1] += $$payref - $$betref;

}

sub posprog {

  my ($chipsaref, $lasthandaref, $x, $payref, $betref) = @_;
  
  if ($$lasthandaref[$x-1] > 0) {
    $$payref *= $$lasthandaref[$x-1];
	  $$betref *= $$lasthandaref[$x-1];
  }
  
  my $handresult;
  if ($$payref - $$betref > 0) {
    $handresult = 'W';
	  $$lasthandaref[$x-1] ++;
  }
  elsif ($$payref - $$betref < 0) {
    $handresult = 'L';
	  $$lasthandaref[$x-1] = 0;
  }
  else {
    $handresult = 'P';
  }
  
  $$chipsaref[$x-1] += $$payref - $$betref;
  
}

sub truecnt {

  my ($chipsaref, $x, $truecnt, $payref, $betref) = @_;
  
  if ($truecnt > 0) {
    $$payref *= $truecnt;
	  $$betref *= $truecnt;
  }
  
  $$chipsaref[$x-1] += $$payref - $$betref;
  
}

sub luckyladies {

  my ($sidebetaref, $handaref, $x, $dealerbj, $betunit) = @_;
  
  my $value;
  my ($card1, $card2) = split(',', $$handaref[2]);
  my %valhash = ('A'=>11, '2'=>2, '3'=>3, '4'=>4, '5'=>5, '6'=>6, '7'=>7, '8'=>8, '9'=>9, 'T'=>10, 'J'=>10, 'Q'=>10, 'K'=>10);
  if ($valhash{substr($card1,-1)} + $valhash{substr($card2,-1)} == 20) {
    if (substr($card1,0,1) eq substr($card2,0,1)) {
	    if ($card1 eq $card2) {
	      if ($card1 eq 'HQ') {
		      if ($dealerbj eq 'Y') {
		        $$sidebetaref[$x]{WIN}{pay1000to1} ++;
		        $value = $betunit * 1000;
		      }
		      else {
		        $$sidebetaref[$x]{WIN}{pay200to1} ++;
			      $value = $betunit * 200;
		      }
		    }
		    else {
	        $$sidebetaref[$x]{WIN}{pay25to1} ++;
		      $value = $betunit * 25;
		    }
	    }
	    else {
	      $$sidebetaref[$x]{WIN}{pay10to1} ++;
		    $value = $betunit * 10;
	    }
	  }
	  else {
	    $$sidebetaref[$x]{WIN}{pay4to1} ++;
	    $value = $betunit * 4;
	  }
  }
  else {
    $$sidebetaref[$x]{LOSS} ++;
	  $value = $betunit * -1;
  }	
  
  $$sidebetaref[$x]{VALUE} += $value; 
  
}

sub randompos4 {

  my ($chipsaref, $x, $truecnt, $payref, $betref) = @_;

  if ($truecnt > 1) {
    my $betmult = int(rand(3)) + 2;
    $$payref *= $betmult;
	  $$betref *= $betmult;
  }
  
  $$chipsaref[$x-1] += $$payref - $$betref; 
 
}

sub randompos6 {

  my ($chipsaref, $x, $truecnt, $payref, $betref) = @_;

  if ($truecnt > 1) {
    my $betmult = int(rand(5)) + 2;
    $$payref *= $betmult;
	  $$betref *= $betmult;
  }
  
  $$chipsaref[$x-1] += $$payref - $$betref; 
 
}

sub randompos8 {

  my ($chipsaref, $x, $truecnt, $payref, $betref) = @_;

  if ($truecnt > 1) {
    my $betmult = int(rand(7)) + 2;
    $$payref *= $betmult;
	  $$betref *= $betmult;
  }
  
  $$chipsaref[$x-1] += $$payref - $$betref; 
 
}

sub betemall {

  my ($chipsaref, $truecnt, $rsltaref, $nump) = @_;
  
  if ($truecnt > 0) {
    for my $x (0..$nump-1) {
      for my $y (0..$nump-1) {
	      if ($x != $y) {
          $$chipsaref[$x] += $$rsltaref[$y][1] - $$rsltaref[$y][0];
  		  }
	    }
	  }
  }
    
}

sub teammart {
  
  my ($rsltaref, $betfactref) = @_;
  
  my $totbet = 0;
  my $totpay = 0;
  foreach my $player (@$rsltaref) {
    $totbet += $$player[0];
    $totpay += $$player[1];
  }
  
  if ($totbet > $totpay and $$betfactref < 64) {
    $$betfactref *= 2;
  }
  else {
    $$betfactref = 1;
  }
    
}

1
