#!/usr/bin/env perl
#
# @author  Luis M Rodriguez-R
# @update  Oct-07-2015
# @license artistic license 2.0
#

use warnings;
use strict;

$#ARGV>=0 or die "
Usage:
   $0 seqs.fa... > length.txt

   seqs.fa	One or more FastA files.
   length.txt	A table with the lengths of the sequences.

";

for my $fa (@ARGV){
   open FA, "<", $fa or die "Cannot open file: $fa: $!\n";
   my $def = '';
   my $len = 0;
   while(<FA>){
      next if /^;/;
      if(m/^>(\S+)\s?/){
         print "$def\t$len\n" if $def;
	 $def = $1;
	 $len = 0;
      }else{
         s/[^A-Za-z]//g;
	 $len+= length $_;
      }
   }
   print "$def\t$len\n" if $def;
   close FA;
}

