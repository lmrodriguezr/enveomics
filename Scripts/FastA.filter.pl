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
   Extracts a subset of sequences from a FastA file.

.Usage: $0 [options] list.txt seqs.fa > subset.fa
   
   [options]
   -r		Reverse list.  Extracts sequences NOT present in the list.
   -q		Runs quietly.
   -h		Prints this message and exits.

   [mandatory]
   list.txt	List of sequences to extract.
   seqs.fa	FastA file containing the superset of sequences.
   subset.fa	FastA file to be created.

" }

my %o=();
getopts('rhq', \%o);
my($list, $fa) = @ARGV;
($list and $fa) or &HELP_MESSAGE;
$o{h} and &HELP_MESSAGE;

print STDERR "Reading list.\n" unless $o{q};
open LI, "<", $list or die "Cannot read file: $list: $!\n";
my %li = map { chomp; $_ => 1 } <LI>;
close LI;

print STDERR "Filtering FastA.\n" unless $o{q};
open FA, "<", $fa or die "Cannot read file: $fa: $!\n";
my $good = 0;
while(my $ln = <FA>){
   next if $ln =~ /^;/;
   chomp $ln;
   if($ln =~ m/^>((\S+).*)/){ $good = (exists $li{$1} or exists $li{">$1"} or exists $li{$2} or exists $li{$ln}) }
   elsif($ln =~ m/^>/){ $good=$o{r}; print STDERR "Warning: Non-cannonical defline, line $.: $ln\n" }
   print "$ln\n" if (($good and not $o{r}) or ($o{r} and not $good));
}
close FA;

