#!/usr/bin/perl

#
# @author: Luis M Rodriguez-R <lmrodriguezr at gmail dot com>
# @license: artistic license 2.0
# @update: Aug-21-2014
#

use strict;
use warnings;
use List::Util qw/min max sum/;

my $fna = shift @ARGV;
$fna or die "
Usage:
   cat blast1... | $0 genes_or_ctgs.fna > genes_or_ctgs.cov

   blast1...		One or more Tabular BLAST files of reads vs genes (or contigs).
   genes_or_ctgs.fna	A FastA file containing the genes or the contigs (db).
   genes_or_ctgs.cov	The output file, containing the average sequencing depth, and
   			the number of reads.

";

my $size  = {};
my $gene  = {};
my $reads = {};

SIZE:{
   local $/=">";
   print STDERR "== Reading fasta\n";
   open FNA, "<", $fna or die "Cannot read the file: $fna: $!\n";
   my $i=0;
   while(<FNA>){
      chomp;
      my @g = split /\n/, $_, 2;
      next unless $g[1];
      #$g[1] =~ s/[^A-Za-z]//g;
      #$size->{$g[0]} = length $g[1];
      $g[0] =~ s/[\s_].*//;
      $size->{$g[0]} = ( $g[1] =~ tr/[A-Za-z]// );
      print STDERR " Measuring sequence ".($i).": $g[0]      \r" unless ++$i%500;
   }
   close FNA;
   print STDERR " Found $i sequences".(" "x30)."\n";
}

MAP:{
   print STDERR "== Reading mapping\n";
   my $i=0;
   while(<>){
      my @ln = split /\t/;
      $gene->{$ln[1]} ||= 0;
      $gene->{$ln[1]} += abs($ln[6]-$ln[7])+1;
      ($reads->{$ln[1]} ||= 0)++;
      print STDERR " Saving hit ".($i).": $ln[1]      \r" unless ++$i%5000;
   }
   print STDERR " Found $i hits".(" "x30)."\n";
}

OUT:{
   print STDERR "== Creating output\n";
   my $i=0;
   for my $g (keys %$gene){
      printf "%s\t%.6f\t%d\n", $g,
	   $gene->{$g}/$size->{$g},
	   $reads->{$g};
      print STDERR " Saving sequence $g:".($i)."\r" unless ++$i%500;
   }
   print STDERR " Saved $i sequences".(" "x30)."\n";
}

print STDERR " done.\n";

