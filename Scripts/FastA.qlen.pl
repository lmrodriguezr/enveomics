#!/usr/bin/env perl
#
# @author  Luis M. Rodriguez-R <lmrodriguezr at gmail dot com>
# @update  Dec-22-2015
# @license artistic license 2.0
#
use strict;
use warnings;
use List::Util qw/sum min max/;

my ($seqs, $minlen) = @ARGV;
$seqs or die "
Description:
   Calculates the quartiles of the length in a set of sequences.  The Q2 is
   also known as the median.  Q0 is the minimum length, and Q4 is the maximum
   length.  It also calculates TOTAL, the added length of the sequences in
   the file, and AVG, the average length.
   
Usage:
   $0 seqs.fa[ minlen]

   seqs.fa	A FastA file containing the sequences.
   minlen	(optional) The minimum length to take into consideration.
   		By default: 0.

";
$minlen ||= 0;

# Read files
my @len = ();
open FA, "<", $seqs or die "Cannot open file: $seqs: $!\n";
my $def = '';
my $len = 0;
while(<FA>){
   next if /^;/;
   if(m/^>(\S+)\s?/){
      push(@len, int($len)) if $def and not $len<$minlen;
      $def = $1;
      $len = 0;
   }else{
      s/[^A-Za-z]//g;
      $len+= length $_;
   }
}
push(@len, int($len)) if $def and not $len<$minlen;
close FA;

# Sort and estimates quantiles
@len = sort { $a <=> $b } @len;
for my $q (0 .. 4){
   my $ii = int(my $i = $#len*$q/4);
   print "Q$q: ".($i==$ii ? $len[$i] : ($len[$ii]+$len[$ii+1])/2 )."\n";
}
my $sum = sum @len;
print "N: ".scalar(@len)."\n";
print "TOTAL: $sum\n";
print "AVG: ".($sum/scalar(@len))."\n";
