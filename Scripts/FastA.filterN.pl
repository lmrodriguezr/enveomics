#!/usr/bin/env perl
# 
# @author  Luis M. Rodriguez-R
# @update  Oct-07-2015
# @license artistic license 2.0
# 

use warnings;
use strict;

my($file, $content, $stretch) = @ARGV;
$file or die <<HELP

Description:
   Filter sequences by N-content and presence of long homopolymers.
Usage:
   $0 sequences.fa [content [stretch]] > filtered.fa
Where:
   sequences.fa	Input file in FastA format
   content	A number between 0 and 1 indicating the maximum proportion of Ns
   		(1 to turn off, 0.5 by default)
   stretch	A number indicating the maximum number of consecutive identical
   		nucleotides allowed (0 to turn off, 100 by default)
   filtered.fa	Filtered set of sequences.

HELP
;
($content ||= 0.5)+=0;
($stretch ||= 100)+=0;

my $good = 0;
my $N = 0;

FASTA: {
   local $/ = "\n>";
   open FILE, "<", $file or die "I can not open the file: $file: $!\n";
   SEQ: while(<FILE>){
      $N++;
      s/^;.*//gm;
      s/>//g;
      my($n,$s) = split /\n/, $_, 2;
      (my $clean = $s) =~ s/[^ACTGN]//g;
      if($content < 1){
         (my $Ns = $clean) =~ s/[^N]//g;
	 next SEQ if length($Ns)>length($clean)*$content;
      }
      if($stretch > 0){
         for my $nuc (qw(A C T G N)){
	    next SEQ if $clean =~ m/[$nuc]{$stretch}/;
	 }
      }
      print ">$n\n$s\n";
      $good++;
   }
   close FILE;
   print STDERR "Total sequences: $N\nAfter filtering: $good\n";
}



