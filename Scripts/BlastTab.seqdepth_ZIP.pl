#!/usr/bin/env perl
#
# @author: Luis M Rodriguez-R <lmrodriguezr at gmail dot com>
# @license: artistic license 2.0
# @update: Mar-23-2015
#

use strict;
use warnings;
use List::Util qw/min max sum/;

my $fna = shift @ARGV;
$fna or die "
Description:
   Estimates the average sequencing depth of subject sequences (genes or contigs)
   assuming a Zero-Inflated Poisson distribution (ZIP) to correct for non-covered
   positions. It uses the corrected method of moments estimators (CMMEs) as described
   by Beckett et al [1]. Note that [1] has a mistake in eq. (2.4), that should be:
      pi-hat-MM = 1 - (X-bar / lambda-hat-MM)
   
   Also note that a more elaborated mixture distribution can arise from coverage
   histograms (e.g., see [2] for an additional correction called 'tail distribution'
   and mixtures involving negative binomial) so take these results cum grano salis.

Usage:
   cat blast1... | $0 genes_or_ctgs.fna > genes_or_ctgs.cov

   blast1...		One or more Tabular BLAST files of reads vs genes (or contigs).
   genes_or_ctgs.fna	A FastA file containing the genes or the contigs (db).
   genes_or_ctgs.cov	The output file.
   
Output:
   A tab-delimited file with the following columns (the one you want is #2):
   1. Subject ID
   2. Estimated average sequencing depth (CMME lambda)
   3. Zero-inflation (CMME pi)
   4. Observed average sequencing depth
   5. Observed median sequencing depth
   6. Observed median sequencing depth excluding zeroes
   7. Number of mapped reads
   8. Length of the subject sequence

References:
   [1] http://anisette.ucs.louisiana.edu/Academic/Sciences/MATH/stage/stat2012.pdf
   [2] Lindner et al, Bioinformatics, 2013.

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
      $g[0] =~ s/\s.*//;
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
      $gene->{$ln[1]} ||= [];
      for my $pos (min($ln[8], $ln[9]) .. max($ln[8], $ln[9])){ ($gene->{$ln[1]}->[$pos]||=0)++ }
      ($reads->{$ln[1]} ||= 0)++;
      print STDERR " Saving hit ".($i).": $ln[1]      \r" unless ++$i%5000;
   }
   print STDERR " Found $i hits".(" "x30)."\n";
}

OUT:{
   print STDERR "== Creating output\n";
   my $i=0;
   for my $g (keys %$gene){
      unless(exists $size->{$g}){
         warn "Warning: Cannot find gene in $fna: $g.\n";
	 next;
      }
      $gene->{$g}->[$_] ||= 0 for (0 .. $size->{$g});
      die "Hits out-of-boundaries in gene $g: $#{$gene->{$g}} != $size->{$g}.\n" if $#{$gene->{$g}} != $size->{$g};
      my @sorted = sort {$a <=> $b} @{$gene->{$g}};
      my @sorted_nz = grep { $_>0 } @sorted;
      my $xbar = sum(@{$gene->{$g}})/$size->{$g};
      my $xsqbar = sum(map { ($_ - $xbar)**2 } @{$gene->{$g}})/($size->{$g}-1); 
      my $var = $xsqbar - $xbar**2;
      my $lambdaMM = $xbar + ($var/$xbar) - 1;
      my $piMM = $lambdaMM==0 ? 0 : 1 - $xbar/$lambdaMM;
      printf "%s\t%.6f\t%.6f\t%.6f\t%d\t%d\t%d\t%d\n", $g,
	   ($xbar >= $var ? $xbar : $lambdaMM),
	   ($xbar >= $var ? 0 : $piMM),
	   #$lambdaMM,
	   #$piMM,
	   sum(@{$gene->{$g}})/$size->{$g},
	   $sorted[$#sorted/2],
	   $sorted_nz[$#sorted_nz/2],
	   $reads->{$g},
	   $size->{$g};
      delete $gene->{$g};
      print STDERR " Saving sequence $g:".($i)."   \r" unless ++$i%500;
   }
   print STDERR " Saved $i sequences".(" "x30)."   \n";
}

print STDERR " done.\n";

