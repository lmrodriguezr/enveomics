#!/usr/bin/perl

#
# @author: Luis M. Rodriguez-R <lmrodriguezr at gmail dot com>
# @update: Apr-08-2013
# @license: artistic license 2.0
#

use warnings;
use strict;
use Getopt::Std;

sub HELP_MESSAGE {
die "
.Description
   Sums the weights of all the queries hitting each subject.  Often (but not necessarily) the BLAST
   files contain only best matches.  The weights can be any number, but a common use of this Script
   is to add up counts (weights are integers).  For example, in a BLAST of predicted genes vs some
   annotation source, the weights could be the number of reads recruited by each gene.

.Usage:
   $0 [options] blast... > out-file

   blast... *	One or more BLAST files.
   out-file	A two-columns tab-delimited file containing the summed weights per hit.
   
   -w <str> *	Weights file: A two-columns tab-delimited file containing the weight of each query.
   -s <float>	Minimum score.  By default: 0.
   -i <float>	Minimum identity (in percentage).  By default: 0.
   -m <int>	Maximum number of queries.  Set to 0 for all.  By default: 0.
   -n		Normalize weights by the number of hits per query.
   -q		Run quietly.
   -h		Display this message and exit.

   * Mandatory

"
}

my %o = ();
getopts('w:s:i:m:nqh', \%o);
$o{w} or &HELP_MESSAGE;
$o{s}||=0;
$o{i}||=0;
$o{m}||=0;

print STDERR "Reading counts.\n" unless $o{q};
open COUNT, "<", $o{w} or die "Cannot open file: $o{w}: $!\n";
my %count = map {split /\t/} <COUNT>;
close COUNT;

print STDERR "Reading BLASTs.\n" unless $o{q};
my $qry = '';
my $hits = 0;
my @buf = ();
my $qries = 0;
my $noQry = 0;
my $ln1   = 0;
my %out = ();
BFILE: for my $blast (@ARGV){
   print STDERR " o $blast\n" unless $o{q};
   open BLAST, "<", $blast or die "Cannot open file: $blast: $!\n";
   BLINE: while(<BLAST>){
      chomp;
      my @ln = split /\t/;
      $ln1 ||= $#ln;
      die "Bad line $.: $_\n" unless $#ln==$ln1;
      next if $ln[11]<$o{s} or $ln[2]<$o{i};
      unless(exists $count{$ln[0]}){
	 $noQry++;
	 next;
      }
      
      if($qry ne $ln[0]){
	 $qries++;
	 ($out{$_->[0]}||=0) += ($_->[1]/($o{n}?$hits:1)) for @buf
	 last BFILE if $o{m} and $qries >= $o{m};
	 @buf = ();
	 $qry  = $ln[0];
	 $hits = 0;
      }
      
      push @buf, [$ln[1], $count{$ln[0]}];
      $hits++;
   }
   ($out{$_->[0]}||=0) += ($_->[1]/($o{n}?$hits:1)) for @buf
   close BLAST;
}
print STDERR "Warning: Couldn't find $noQry queries\n" if $noQry;

for my $h (keys %out){
   print "$h\t".$out{$h}."\n";
}

