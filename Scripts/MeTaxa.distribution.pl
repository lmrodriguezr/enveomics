#!/usr/bin/perl

#
# @author Luis M. Rodriguez-R <lmrodriguezr at gmail dot com>
# @license artistic license 2.0
#
use warnings;
use strict;
use Symbol;

my($gff, $map, $metaxa, $base, $minScore) = @ARGV;
($gff and $map and $metaxa and $base) or die "
Usage:
   $0 genes.gff2 mapping.txt metaxa.txt baseOut[ minScore]

   genes.gff2	Genes predicted in Gff2 format (as produced by
   		MetaGeneMark).
   mapping.txt	Genes and reads per gene in a tab-delimited file.
   metaxa.txt	Metaxa output.
   baseOut	Prefix of the output to be generated.
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
}
close GFF;
print STDERR " Found ".(scalar(keys %gene))." genes.\n";

print STDERR "Reading read-counts.\n";
my %count;
my $Nreads = 0;
open COUNT, "<", $map or die "Cannot read file: $map: $!\n";
while(<COUNT>){
   chomp;
   my @l = split /\t/;
   exists $gene{$l[0]} or die "Cannot find gene's contig: $l[0].\n";
   $count{ $gene{$l[0]} } += $l[1];
   $Nreads += $l[1];
   delete $gene{$l[0]};
}
close COUNT;
print STDERR " Found ".scalar(keys %gene)." genes without reads.\n" if scalar(keys %gene);
$count{$_}+=0 for values %gene;
print STDERR " Found ".scalar(keys %count)." contigs and $Nreads reads.\n";

print STDERR "Reading Metaxa results.\n";
open METAXA, "<", $metaxa or die "Cannot read file: $metaxa: $!\n";
my $ctg;
my $rank;
my @ofh = ();
my @n   = ();
for my $i (1 .. 3){
   $ofh[$i-1] = gensym;
   open $ofh[$i-1], ">", "$base.$i.txt" or die "Cannot create file: $base.$i.txt: $!\n";
   $n[$i-1] = 0;
}
while(<METAXA>){
   chomp;
   if(m/^##(.*)/){
      $ctg = $1;
      $rank = 0;
   }else{
      my @l = split /\t/;
      exists $l[2] or die "Cannot parse metaxa file, line $.: $_\n";
      exists $count{$ctg} or die "Cannot find counts for contig $ctg.\n";
      if($l[2]>=$minScore){
	 printf {$ofh[$rank]} "%s\t%.20f\n", $l[0], 1000*$count{$ctg}/$Nreads if $l[2]>=$minScore;
	 $n[$rank]++;
      }
      $rank++;
   }
}
close METAXA;
print " Found $n[$_] results in rank $_.\n" for (0 .. 2);

