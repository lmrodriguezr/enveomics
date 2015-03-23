#!/usr/bin/env perl
#
# @author: Luis M. Rodriguez-R <lmrodriguezr at gmail dot com>
# @update: Mar-23-2015
# @license: artistic license 2.0
#

use warnings;
use strict;
use Getopt::Std;

my %o;
getopts('si', \%o);
my($list, $blast) = @ARGV;

($list and $blast) or die "
.Description:
   Extracts a subset of hits (queries or subjects) from a tabular BLAST.

.Usage: $0 [options] list.txt blast.txt > subset.txt
   
   Options:
      -s	If set, assumes that list.txt contains subject IDs.
   		By default: assumes query IDs.
      -i	If set, reports the inverse of the list (i.e., reports
      		only hits absent in the list).

   list.txt	List of IDs to extract.
   blast.txt	Tabular BLAST file containing the superset of hits.
   subset.txt	Tabulat BLAST file to be created.

";

open LI, "<", $list or die "Cannot read file: $list: $!\n";
my %li = map { chomp; $_ => 1 } <LI>;
close LI;

open BLAST, "<", $blast or die "Cannot read file: $blast: $!\n";
while(my $ln = <BLAST>){
   chomp $ln;
   my @ln = split("\t", $ln);
   my $good = exists $li{$ln[ ($o{s} ? 1 : 0) ]};
   $good = not $good if $o{i};
   print "$ln\n" if $good;
}
close BLAST;

