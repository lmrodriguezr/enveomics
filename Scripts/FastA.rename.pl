#!/usr/bin/env perl
#
# @author  Luis M. Rodriguez-R <lmrodriguezr at gmail dot com>
# @update  Oct-07-2015
# @license artistic license 2.0
#

use warnings;
use strict;
use Getopt::Std;

sub HELP_MESSAGE { die "
.Description:
   Renames a set of sequences in FastA format.

.Usage: $0 [options] list.txt seqs.fa > renamed.fa
   
   [options]
   -f		Filter list.  Ignores sequences NOT present in the list.
   -q		Runs quietly.
   -h		Prints this message and exits.

   [mandatory]
   list.txt	Tab-delimited list of sequences, with the original ID in the
   		first column and the ID to use in the second.
   seqs.fa	FastA file containing the superset of sequences.
   renamed.fa	FastA file to be created.

" }

my %o=();
getopts('fhq', \%o);
my($list, $fa) = @ARGV;
($list and $fa) or &HELP_MESSAGE;
$o{h} and &HELP_MESSAGE;

print STDERR "Reading list.\n" unless $o{q};
open LI, "<", $list or die "Cannot read file: $list: $!\n";
my %li = map { my $l=$_; chomp $l; my @r=split(/\t/,$l); $r[0] => $r[1] } <LI>;
close LI;

print STDERR "Renaming FastA.\n" unless $o{q};
open FA, "<", $fa or die "Cannot read file: $fa: $!\n";
my $good = 0;
while(my $ln = <FA>){
   next if $ln =~ /^;/;
   chomp $ln;
   if($ln =~ m/^>((\S+).*)/){
      my $rep=0;
      $rep = ">".$li{$ln} if exists $li{$ln};
      $rep = ">".$li{$1} if exists $li{$1} and not $rep;
      $rep = ">".$li{">$1"} if exists $li{">$1"} and not $rep;
      $rep = ">".$li{$2} if exists $li{$2} and not $rep;
      if($rep){
	 $ln = $rep;
	 $good = 1;
      }
   }elsif($ln =~ m/^>/){
      $good=0;
      print STDERR "Warning: Non-cannonical defline, line $.: $ln\n";
   }
   print "$ln\n" if $good or not $o{f};
}
close FA;

