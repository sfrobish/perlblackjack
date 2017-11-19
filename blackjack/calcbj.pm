package calcbj;

require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(calctotwinpct calcstreak);

sub calctotwinpct {
 
  my ($winpctref,$x,$bet,$pay) = @_;
  
  $$winpctref[0] ++ if $x == 1;
  
  if ($pay - $bet > 0) {
    $$winpctref[$x]{WIN} ++;
  }
  elsif ($pay - $bet < 0) {
    $$winpctref[$x]{LOSS} ++;
  }
  else {
    $$winpctref[$x]{PUSH} ++;
  }
  
}

sub calcstreak {

  my ($streakref, $curstrref, $x, $bet, $pay, $seqnum) = @_;
  
  #print "\n" if $x == 1;
  #print "$x:$$curstrref[$x]:$pay:$bet|";
  
  if ($$curstrref[$x] == 0) {
    $$curstrref[$x] ++ if $pay - $bet > 0;
	$$curstrref[$x] -- if $pay - $bet < 0;
  }
  elsif ($$curstrref[$x] < 0) {
    if ($pay - $bet > 0) {
	  $$streakref{$$curstrref[$x]} ++;
	  $$curstrref[$x] = 1;
	}
	elsif ($pay - $bet < 0) {
	  $$curstrref[$x] --;
	}
  }
  else {
    if ($pay - $bet > 0) {
	  $$curstrref[$x] ++;
	}
	elsif ($pay - $bet < 0) {
	  $$streakref{$$curstrref[$x]} ++;
	  print "$seqnum\n" if $$curstrref[$x] > 15;
	  $$curstrref[$x] = -1;
	}
  }
	  
} 
  
1	
    
