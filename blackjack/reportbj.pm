package reportbj;

require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(writehand writestack);

use strict;
use warnings;

sub writehand {

  my ($outfh, $tabref, $seqnum, $cardsrem, $runcnt, $truecnt) = @_;

  my $outln = '';
  foreach my $seat (@$tabref) {
    foreach my $handref (@$seat) {
      $outln .= $$handref{BET} . ':' if defined($$handref{BET});
      $outln .= join(',', @{$$handref{ACTIONS}}) . ':' if defined($$handref{ACTIONS});
      $outln .= join(',', @{$$handref{CARDS}});
	  $outln .= ":$$handref{TOTAL}" if $$handref{TOTAL};
	  $outln .= ":$$handref{PAYOUT}" if defined($$handref{PAYOUT});
      $outln .= '~';
    }
    $outln =~ s/~$//;
    $outln .= '|';
  }
  $outln =~ s/\|$//;
  print $outfh "$seqnum|$cardsrem|$runcnt|$truecnt|$outln\n";
  
}

sub writestack {

  my ($outfh, $seqnum, $chipsaref) = @_;
  
  my $outln = join(',',@$chipsaref);

  print $outfh "$seqnum,$outln\n"; 
  
}
  
1