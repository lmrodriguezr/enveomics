#!/usr/bin/env perl
#
# @author: Luis M. Rodriguez-R <lmrodriguezr at gmail dot com>
# @update: Mar-23-2015
# @license: artistic license 2.0
#

use warnings;
use strict;
use Getopt::Std;

sub HELP_MESSAGE { die "
.Description:
   Extracts a subset of sequences from a FastQ file.

.Usage: $0 [options] list.txt seqs.fq > subset.fq
   
   [options]
   -r		Reverse list.  Extracts sequences NOT present in the list.
   -q		Runs quietly.
   -h		Prints this message and exits.

   [mandatory]
   list.txt	List of sequences to extract.
   seqs.fq	FastQ file containing the superset of sequences.
   subset.fq	FastQ file to be created.

" }

my %o=();
getopts('rhq', \%o);
my($list, $fq) = @ARGV;
($list and $fq) or &HELP_MESSAGE;
$o{h} and &HELP_MESSAGE;

print STDERR "Reading list.\n" unless $o{q};
open LI, "<", $list or die "Cannot read file: $list: $!\n";
my %li = map { chomp; $_ => 1 } <LI>;
close LI;

print STDERR "Filtering FastQ.\n" unless $o{q};
open FQ, "<", $fq or die "Cannot read file: $fq: $!\n";
my $good = 0;
while(my $ln = <FQ>){
   my @ln = ();
   $ln[$_] = <FQ> for 0 .. 2;
   chomp $ln;
   if($ln =~ m/^@((\S+).*)/){ $good = (exists $li{$1} or exists $li{">$1"} or exists $li{"\@$1"} or exists $li{$2} or exists $li{$ln}) }
   elsif($ln =~ m/^>/){ $good=0; print STDERR "Warning: Non-cannonical defline, line $.: $ln\n" }
   else{ $good=$o{r}; print STDERR "Warning: Non-cannonical defline, line $.: $ln\n" }
   print "".join("", "$ln\n", @ln) if (($good and not $o{r}) or ($o{r} and not $good));
}
close FQ;

