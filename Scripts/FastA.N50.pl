#!/usr/bin/env perl
#
# @author: Luis M. Rodriguez-R <lmrodriguezr at gmail dot com>
# @update: Oct 07 2015
# @license: artistic license 2.0
#
use strict;
use warnings;
use List::Util qw/sum min max/;

my ($seqs, $minlen, $n__) = @ARGV;
$seqs or die "
Description:
   Calculates the N50 value of a set of sequences.  Alternatively, it
   can calculate other N** values.  It also calculates the total number
   of sequences and the total added length.
   
Usage:
   $0 seqs.fa[ minlen[ **]]

   seqs.fa	A FastA file containing the sequences.
   minlen	(optional) The minimum length to take into consideration.
   		By default: 0.
   **		Value N** to calculate.  By default: 50 (N50).
";
$minlen ||= 0;
$n__    ||= 50;

my @len = ();
open SEQ, "<", $seqs or die "Cannot open file: $seqs: $!\n";
while(<SEQ>){
   if(/^>/){
      push @len, 0;
   }else{
      next if /^;/;
      chomp;
      s/\W//g;
      $len[-1]+=length $_;
   }
}
close SEQ;
@len = sort { $a <=> $b } map { $_>=$minlen?$_:() } @len;
my $tot = (sum(@len) || 0);

my $thr = $n__*$tot/100;
my $pos = 0;
for(@len){
   $pos+= $_;
   if($pos>=$thr){
      print "N$n__: $_\n";
      last;
   }
}
print "Sequences: ".scalar(@len)."\n";
print "Total length: $tot\n";

