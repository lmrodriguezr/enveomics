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
getopts('k:s:ihn', \%o);
my($list, $table) = @ARGV;

($list and $table) or die "
.Description:
   Extracts (and re-orders) a subset of rows from a raw table.

.Usage: $0 [options] list.txt table.txt > subset.txt
   
   Options:
      -k <int>	Column of the table to use as key to filter.  By default, 1.
      -s <str>	String to use as separation between rows.  By default, tabulation.
      -i	If set, reports the inverse of the list (i.e., reports only rows
      		absent in the list).  Implies -n.
      -h	Keep first row of the table (header) untouched.
      -n	No re-order.  The output has the same order of the table.  By
      		default, it prints in the order of the list.

   list.txt	List of IDs to extract.
   table.txt	Table file containing the superset.
   subset.txt	Table file to be created.

";

$o{k} ||= 1;
$o{s} ||= "\t";
$o{n}=1 if $o{i};
my $HEADER = "";

my $tbl2 = $o{n} ? $list : $table;
open TBL, "<", $tbl2 or die "Cannot read file: $tbl2: $!\n";
$HEADER = <TBL> if $o{h} and not $o{n};
my %tbl2 = map { my $l=$_; chomp $l; my @r=split $o{s}, $l; $r[ $o{n} ? 0 : $o{k}-1] => $l } <TBL>;
close TBL;

my $tbl1 = $o{n} ? $table : $list;
open TBL, "<", $tbl1 or die "Cannot read file: $tbl1: $!\n";
$HEADER = <TBL> if $o{h} and $o{n};
print $HEADER;
while(my $ln = <TBL>){
   chomp $ln;
   next unless $ln;
   my @ln = split $o{s}, $ln;
   my $good = exists $tbl2{ $ln[$o{n} ? $o{k}-1 : 0] };
   $good = not $good if $o{i};
   print "".($o{n} ? $ln : $tbl2{$ln[0]})."\n" if $good;
}
close TBL;

