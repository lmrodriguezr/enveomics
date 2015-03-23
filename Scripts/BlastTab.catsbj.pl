#!/usr/bin/env perl
# 
# @author: Luis M. Rodriguez-R <lmrodriguezr at gmail dot com>
# @updated: Mar-23-2015
# @license: artistic license 2.0
# 

use warnings;
use strict;
use List::Util qw/min max/;
use Getopt::Std;

sub HELP_MESSAGE { die "

Description:
   Generates a list of hits from a BLAST result concatenating the subject
   sequences.  This can be used, e.g., to analyze BLAST results against
   draft genomes.

Usage:
   $0 [options] seq.fa map.bls

   seq.fa	Subject sequences (ref) in FastA format.
   map.bls	Mapping of the reads to the reference in BLAST Tabular
   		format.
   
   Options:
   -i <float>	Minimum identity to report a result.  By default: 70.
   -l <int>	Minimum alignment length to report a result.  By default: 60.
   -s		The FastA provided is to be treated as a subset of the subject.
   		By default, it expects all the subjects to be present in the
		BLAST.
   -q		Run quietly.
   -h		Display this message and exit.
   
   This script creates two files using <map.bls> as prefix with extensions
   .rec (for the recruitment plot) and .lim (for the limits of the different
   sequences in <seq.fa>).

";}

my %o;
getopts('i:l:sqh', \%o);
my($fa, $map) = @ARGV;
($fa and $map) or &HELP_MESSAGE;
$o{h} and &HELP_MESSAGE;
$o{i} ||= 70;
$o{l} ||= 60;

my %seq = ();
my @seq = ();
my $tot = 0;

SEQ:{
   print STDERR "== Reading reference sequences\n" unless $o{q};
   open FA, "<", $fa or die "Cannot read the file: $fa: $!\n";
   my $cur_seq = '';
   while(<FA>){
      chomp;
      if(m/^>(\S+)/){
         my $c = $1;
	 $seq{$c} = exists $seq{$cur_seq} ? $seq{$cur_seq}+1 : 1;
	 push @seq, $c;
	 $cur_seq = $c;
      }else{
         s/[^A-Za-z]//g;
	 $seq{$cur_seq} += length $_;
      }
   }
   close FA;
   print STDERR " Found ".(scalar @seq)." sequences.\n" unless $o{q};
}

open LIM, ">", "$map.lim" or die "Cannot create the file: $map.lim: $!\n";
my $l = 0;
for my $s (@seq){
   print LIM "$s\t".(++$l)."\t$seq{$s}\n";
   ($l, $seq{$s}) = ($seq{$s}, $l);
}
close LIM;

MAP:{
   print STDERR "== Reading mapping\n" unless $o{q};
   open BLS, "<", $map or die "Cannot read the file: $map: $!\n";
   open REC, ">", "$map.rec" or die "Cannot create the file: $map.rec: $!\n";
   RESULT:while(<BLS>){
      chomp;
      my @ln = split /\t/;
      $ln[11] or die "Cannot parse line $map:$.: $_\n";
      next unless $ln[3]>=$o{l};
      next unless $ln[2]>=$o{i};
      unless(exists $seq{$ln[1]}){
         die "Cannot find the subject sequence: $ln[1]\n" unless $o{s};
	 next RESULT;
      }
      my $start = $seq{$ln[1]}+min($ln[8], $ln[9]);
      my $end   = $seq{$ln[1]}+max($ln[8], $ln[9]);
      print REC "$start\t$end\t$ln[2]\t$ln[11]\t$ln[0]",
      		(exists($ln[13])?"\t".($ln[2]*$ln[3]/min($ln[12],$ln[13]))."\t":
		exists($ln[12])?"\t".($ln[2]*$ln[3]/$ln[12])."\t":""),"\n";
   }
   close BLS;
   close REC;
   print STDERR " done.\n" unless $o{q};
}

