#!/usr/bin/perl

#
# @author Luis M. Rodriguez-R <lmrodriguezr at gmail dot com>
# @license artistic license 2.0
#
use warnings;
use strict;

my $minLen = 0.75;

my ($gff, @blasts) = @ARGV;
($gff and $#blasts>=0) or die "
Usage:
   $0 genes.gff2 blast.txt ... > blast_metaxa.txt

   genes.gff2		Gff v2 file containing the genes (e.g. as produced
   			by MetaGeneMark).
   blast.txt ...	One or more tabular BLAST files.
   blast_metaxa.txt	Input file for MeTaxa.

   NOTE: This script is filtering out alignments shorter than $minLen
   times the length of the query genes.

";

print STDERR "Reading genes collection.\n";
my %gene;
open GFF, "<", $gff or die "Cannot read file: $gff: $!\n";
while(<GFF>){
   next if /^#/;
   next if /^\s*$/;
   chomp;
   my @ln = split /\t/;
   exists $ln[8] or die "Cannot parse line $.: $_\n";
   ###########
   #$ln[8] =~ m/gene_id (\d+)/ or die "Cannot parse line $., column 9: $_\n";
   #my $id = "gene_id_$1";
   my $id = $ln[8];
   $id =~ s/gene_id /gene_id_/;
   ###########
   $ln[0] =~ s/ .*//;
   $gene{$id} = [$ln[0], (1+$ln[4]-$ln[3])/3];
}
close GFF;

my $i=0;
my $p=0;
print STDERR "Generating MeTaxa input.\n";
for my $blast (@blasts){
   print STDERR "  o $blast\n";
   open BLAST, "<", $blast or die "Cannot read file: $blast: $!\n";
   while(<BLAST>){
      chomp;
      my @l = split /\t/;
      exists $gene{$l[0]} or die "Cannot find contig for gene $l[0].\n";
      $i++;
      next unless $l[3] >= $minLen*$gene{$l[0]}->[1];
      $p++;
      $l[1] =~ m/gi\|(\d+)\|/ or die "Cannot parse GI in $l[1].\n";
      print "".join("\t", @l, $gene{$l[0]}->[0], $l[0], $1)."\n";
   }
   close BLAST;
}
print STDERR " Found $i results, reported $p.\n";

