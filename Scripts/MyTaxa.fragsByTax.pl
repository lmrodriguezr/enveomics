#!/usr/bin/env perl
#
# @author: Luis M. Rodriguez-R <lmrodriguezr at gmail dot com>
# @update: Mar-23-2015
# @license: artistic license 2.0
#

use warnings;
use strict;

my($file,$tax,$rank) = @ARGV;
($file and $tax) or die "
.Usage:
   $0 file.txt taxon[ rank]

   file.txt	MyTaxa output.
   taxon	Taxon to look for.
   rank		Rank of taxon (optional). By default: any rank.

";
$rank ||= ".*";
$rank = lc $rank;

open MT, "<", $file or die "Cannot read file: $file: $!\n";
my $last = '';
while(my $ln=<MT>){
   chomp $ln;
   if($ln =~ /<$rank>$tax(;|$)/){
      $last =~ s/\t.*//;
      print $last, "\n";
   }
   $last = $ln;
}
close MT;

