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
   $0 seqs.fa... > gc.txt

   seqs.fa	One or more FastA files.
   gc.txt	A table with the G+C content of the sequences.

";

for my $fa (@ARGV){
   open FA, "<", $fa or die "Cannot open file: $fa: $!\n";
   my $def = '';
   my $len = 0;
   my $gc  = 0;
   while(<FA>){
      next if /^;/;
      if(m/^>(\S+)\s?/){
         print "$def\t".($gc/$len)."\n" if $def;
	 $def = $1;
	 $len = 0;
	 $gc  = 0;
      }else{
         s/[^A-Za-z]//g;
	 $len += length $_;
	 s/[^GC]//g;
	 $gc  += length $_;
      }
   }
   print "$def\t".($gc/$len)."\n" if $len;
   close FA;
}

