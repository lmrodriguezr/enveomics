#!/usr/bin/perl
#
# @author: Luis M. Rodriguez-R <lmrodriguezr at gmail dot com>
# @update: Jun 11 2013
# @license: artistic license 2.0
#

use warnings;
use strict;
use Getopt::Std;

my %o;
getopts('k:s:i', \%o);
my($list, $table) = @ARGV;

($list and $table) or die "
.Description:
   Extracts (and re-orders) a subset of rows from a raw table.

.Usage: $0 [options] list.txt table.txt > subset.txt
   
   Options:
      -k <int>	Column of the table to use as key to filter.  By default, 1.
      -s <str>	String to use as separation between rows.  By default, tabulation.
      -i	If set, reports the inverse of the list (i.e., reports only rows
      		absent in the list).

   list.txt	List of IDs to extract.
   table.txt	Table file containing the superset.
   subset.txt	Table file to be created.

";

$o{k} ||= 1;
$o{s} ||= "\t";

open TBL, "<", $table or die "Cannot read file: $table: $!\n";
my %tbl = map { my $l=$_; chomp $l; my @r=split $o{s}, $l; $r[$o{k}-1] => $l } <TBL>;
close TBL;

open LI, "<", $list or die "Cannot read file: $list: $!\n";
while(my $ln = <LI>){
   chomp $ln;
   my $good = exists $tbl{$ln};
   $good = not $good if $o{i};
   print "".$tbl{$ln}."\n" if $good;
}
close LI;

