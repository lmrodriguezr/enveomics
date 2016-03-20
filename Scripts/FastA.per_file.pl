#!/usr/bin/env perl
#
# @author  Luis M Rodriguez-R
# @update  Mar-17-2016
# @license artistic license 2.0
#

use warnings;
use strict;

$#ARGV>=1 or die "
Usage:
   $0 outdir seqs.fa...

   outdir	Output directory for the individual files.
   seqs.fa	One or more FastA files.

";

my $dir = shift @ARGV;

for my $fa (@ARGV){
   open FA, "<", $fa or die "Cannot open file: $fa: $!\n";
   my $file = '';
   while(<FA>){
      next if /^;/;
      if(m/^>(\S+)\s?/){
	 close ONE if $file;
         $file = $dir."/".$1.".fasta";
	 open ONE, ">", $file or die "Cannot open file: $file: $!\n";
      }
      print ONE $_ if $file;
   }
   close ONE if $file;
}

