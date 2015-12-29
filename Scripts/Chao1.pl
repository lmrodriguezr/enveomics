#!/usr/bin/env perl
#
# @author  Luis M. Rodriguez-R <lmrodriguezr at gmail dot com>
# @license artistic license 2.0
# @update  Dec-29-2015
#

use warnings;
use strict;
use Getopt::Std;
use List::Util qw/min max/;

sub VERSION_MESSAGE(){print "Home-made Chao1 (enveomics)\n"}
sub HELP_MESSAGE(){die "
Description:
   Takes a table of OTU abundance in one or more samples and calculates the
   chao1 index (with 95% Confidence Interval) for each sample.  To use it with
   Qiime OTU Tables, run it as:
   $0 -i OTU_Table.txt -c 1 -h

Usage:
   $0 [opts]

   -i <str>	* Input table (columns:samples, rows:OTUs).
   -r <int>	Number of rows to ignore.  By default: 0.
   -c <int>	Number of columns to ignore.  By default: 0.
   -C <int>	Number of columns to ignore at the end. By default: 0.
   -d <str>	Delimiter.  Supported escaped characters are: \"\\t\"
		(tabulation), and \"\\0\" (null bit).  By default: \"\\t\".
   -h		If set, the first row is assumed to have the names of the
		samples.
   --help	This help message.

   * Mandatory.

To improve:
   o Account for n1==0 and n2==0 cases.  See http://www.mothur.org/wiki/Chao.

"}

my %o;
getopts('i:c:C:r:d:h', \%o);

&HELP_MESSAGE() unless $o{i};
$o{c} ||= 0;
$o{C} ||= 0;
$o{r} ||= 0;
$o{d} ||= "\\t";

$o{d}="\t" if $o{d} eq "\\t";
$o{d}="\0" if $o{d} eq "\\0";

my @names = ();
my @values = ();
open TABLE, "<", $o{i} or die "Cannot open file: ".$o{i}.": $!\n";
<TABLE> for (1 .. $o{r});
if($o{h}){
   my $h = <TABLE>;
   $h or die "Empty table!\n";
   chomp $h;
   @names = split $o{d}, $h;
   shift @names for (1 .. $o{c});
   pop @names for (1 .. $o{C});
}
while(<TABLE>){
   chomp;
   my @ln = split $o{d};
   shift @ln for (1 .. $o{c});
   pop @ln for (1 .. $o{C});
   push @{$values[$_] ||= []}, $ln[$_] for (0 .. $#ln);
}
close TABLE;

print "Sample\tObs\tChao1\tChao1_LB\tChao1_UL\n";
for my $i (0 .. $#values){
   print "".(exists $names[$i] ? $names[$i] : $i).$o{d};
   my $n1=0;
   my $n2=0;
   my $ob=0;
   for my $v (@{$values[$i]}){
      $n1++ if $v==1;
      $n2++ if $v==2;
      $ob++ if $v>=1;
   }
   if($ob and $n1 and $n2){
      my $m   = $n1/$n2;
      my $ch  = $ob + (($n1**2)/(2*$n2));
      my $var = ($n2*((($m**4)/4) + ($m**3) + (($m**2)/2)));
      my $c   = exp(1.96*sqrt(log(1+ $var/(($ch-$ob)**2))));
      my $lc  = max($ob + ($ch-$ob)/$c, $ob);
      my $uc  = $ob + $c*($ch-$ob);
      print "".join($o{d}, $ob, $ch, $lc, $uc)."\n"
   }else{
      print "".join($o{d}, $ob, $ob, 0, 0)."\n"
   }
}

