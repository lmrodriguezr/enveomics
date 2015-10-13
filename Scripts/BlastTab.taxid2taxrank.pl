#!/usr/bin/env perl
#
# @author  Luis M. Rodriguez-R <lmrodriguezr at gmail dot com>
# @license artistic 2.0
# @update  Oct-13-2015
#

use warnings;
use strict;

my($blast, $nodes, $names, $rank, $bh) = @ARGV;
($blast and $nodes and $names) or die <<HELP

Takes a BLAST with NCBI Taxonomy IDs as subjects and replaces them by names at a
given taxonomic rank.

Usage:
   $0 tax_blast.txt nodes.dmp names.dmp[ rank[ best-hit]] > taxrank_blast.txt

   tax_blast.txt	BLAST output, where subject IDs are NCBI Taxonomy IDs.
   nodes.dmp		Nodes file from NCBI Taxonomy*.
   names.dmp		Names file from NCBI Taxonomy*.
   rank			The rank to be reported.  All the reported nodes will
   			have the same rank.  By default, genus.  To see
			supported values, run:
			cut -f 5 nodes.dmp | sort -u
   best-hit		A word (yes or no) telling the program whether or not it
   			should take into account the best hit per query only.
			By default: yes.
   taxrank_list.txt	BLAST-like output, where subject IDs are Taxonomy names.

   * Download from ftp://ftp.ncbi.nih.gov/pub/taxonomy/taxdump.tar.gz

HELP
;
$rank ||= "genus";
$bh   ||= "yes";

# %nodes structure:
#   taxid => [parent's taxid, rank, nil, name, name type]

print STDERR "Reading $nodes.\n";
open NODES, "<", $nodes or die "Cannot read file: $nodes: $!\n";
my %nodes = map { my @a=split /\t\|\t/; ($a[0] => [$a[1], $a[2]]) } <NODES>;
close NODES;

print STDERR "Reading $names.\n";
open NAMES, "<", $names or die "Cannot read file: $names: $!\n";
while(<NAMES>){
   my @a=split /\t\|\t/;
   next if exists $nodes{$a[0]}->[3] and
      $nodes{$a[0]}->[4] eq "scientific name";
   next if exists $nodes{$a[0]}->[3] and
      $a[3] ne "scientific name";
   $nodes{$a[0]}->[3] = $a[1];
   $nodes{$a[0]}->[4] = $a[3];
}
close NAMES;

my $i     = 0;
my $nomap = 0;
my $qry   = "";
open BLAST, "<", $blast or die "Cannot read file: $blast: $!\n";
HIT:while(<BLAST>){
   if(/^#/){
      print $_;
      next;
   }
   chomp;
   my @row = split /\t/;
   next if $bh eq "yes" and $row[0] eq $qry;
   $i++;
   print STDERR " Mapping hit $i\r" unless $i%10;
   exists $nodes{$row[1]} or die "Cannot find Taxonomy node: $row[1].\n";
   my $n = $nodes{$row[1]};
   while($n->[1] ne $rank){
      if($n->[0] eq $nodes{$n->[0]}->[0]){
	 $nomap++;
	 next HIT;
      }
      $n = $nodes{$n->[0]};
   }
   $row[1] = $n->[3];
   print "".join("\t", @row)."\n";
}
close BLAST;
print STDERR " Mapped $i hits\n";
print STDERR
   " WARNING: $nomap hits above rank or in a lineage without rank.\n" if $nomap;

