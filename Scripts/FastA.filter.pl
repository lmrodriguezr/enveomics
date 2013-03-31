#!/usr/bin/perl
#
# @author: Luis M. Rodriguez-R <lmrodriguezr at gmail dot com>
# @update: Jan 09 2013
# @license: artistic license 2.0
#

use warnings;
use strict;

my($list, $fa) = @ARGV;

($list and $fa) or die "
.Description:
   Extracts a subset of sequences from a FastA file.

.Usage: $0 list.txt seqs.fa > subset.fa
   
   list.txt	List of sequences to extract.
   seqs.fa	FastA file containing the superset of sequences.
   subset.fa	FastA file to be created.

";

open LI, "<", $list or die "Cannot read file: $list: $!\n";
my %li = map { chomp; $_ => 1 } <LI>;
close LI;

open FA, "<", $fa or die "Cannot read file: $fa: $!\n";
my $good = 0;
while(my $ln = <FA>){
   chomp $ln;
   if($ln =~ m/^>((\S+).*)/){ $good = (exists $li{$1} or exists $li{">$1"} or exists $li{$2} or exists $li{$ln}) }
   elsif($ln =~ m/^>/){ $good=0; warn "Non-cannonical defline, line $.: $ln\n" }
   print "$ln\n" if $good;
}
close FA;

