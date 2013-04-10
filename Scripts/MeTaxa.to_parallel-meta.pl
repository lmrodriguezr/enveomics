#!/usr/bin/perl

#
# @author Luis M. Rodriguez-R <lmrodriguezr at gmail dot com>
# @update apr-09-2013
# @license artistic license 2.0
#
use warnings;
use strict;
use Symbol;

my($gff, $map, $metaxa, $out, $minScore) = @ARGV;
($gff and $map and $metaxa and $out) or die "
Description:
   Generates a file compatible with Parallel-meta's class-tax.
   class-tax can use the output of this script to generate an
   HTML browsable version of MeTaxa's output.
   
Usage:
   $0 genes.gff2 mapping.txt metaxa.txt output.txt[ minScore]

   genes.gff2	Genes predicted in Gff2 format (as produced by
   		MetaGeneMark).
   mapping.txt	Genes and reads per gene in a tab-delimited file.
   metaxa.txt	Metaxa output.
   output.txt	File to be generated.
   minScore	(optional) Minimum Metaxa score.  By default: 0.5.

";

$minScore ||= 0.5;

print STDERR "Reading genes collection.\n";
my %gene;
open GFF, "<", $gff or die "Cannot read file: $gff: $!\n";
while(<GFF>){
   next if /^#/;
   next if /^\s*$/;
   chomp;
   my @ln = split /\t/;
   exists $ln[8] or die "Cannot parse line $.: $_\n";
   ###
   #$ln[8] =~ m/gene_id (\d+)/ or die "Cannot parse line $., column 9: $_\n";
   #my $id = "gene_id_$1";
   my $id = $ln[8];
   $id =~ s/gene_id /gene_id_/;
   ###
   $ln[0] =~ s/ .*//;
   $gene{$id} = $ln[0];
   print STDERR " $id  \r";
}
close GFF;
print STDERR " Found ".(scalar(keys %gene))." genes.   \n";

print STDERR "Reading read-counts.\n";
my %count;
my $Nreads = 0;
open COUNT, "<", $map or die "Cannot read file: $map: $!\n";
while(<COUNT>){
   chomp;
   my @l = split /\t/;
   print STDERR " ".$l[0]."  \r";
   exists $gene{$l[0]} or die "Cannot find gene's contig: $l[0].\nListed in $map:$. but not declared in $gff.\n";
   #unless(exists $gene{$l[0]}){print STDERR "Cannot find gene's contig: $l[0].\nListed in $map:$. but not declared in $gff.\n"; next};
   $count{ $gene{$l[0]} } += $l[1];
   $Nreads += $l[1];
   delete $gene{$l[0]};
}
close COUNT;
print STDERR " Found ".scalar(keys %gene)." genes without reads.  \n" if scalar(keys %gene);
$count{$_}+=0 for values %gene;
print STDERR " Found ".scalar(keys %count)." contigs and $Nreads reads.  \n";

print STDERR "Reading Metaxa results.\n";
open METAXA, "<", $metaxa or die "Cannot read file: $metaxa: $!\n";
my $ctg;
my $rank;
my @class = ();
my $n = 0;

open OUT, ">", $out or die "Cannot create file: $out: $!\n";
while(<METAXA>){
   chomp;
   if(m/^##(.*)/){
      $ctg = $1;
      $rank = 0;
      @class = ();
      print STDERR " $ctg\r";
   }else{
      my @l = split /\t/;
      exists $l[2] or die "Cannot parse metaxa file, line $.: $_\n";
      push @class, ($l[2]>=$minScore ? $l[0] : "unknown");
      next if $class[0] eq 'unknown';
      $rank++;
      if($rank==3){
	 exists $count{$ctg} or die "Cannot find counts for contig $ctg.\n";
	 print OUT "".join("\t", "$ctg.$_", 0, 100, 0, join("; ", @class))."\n" for (1 .. $count{$ctg});
	 $n++;
      }
   }
}
close METAXA;
close OUT;
print " Found $n results.\n";

