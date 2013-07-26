#!/usr/bin/perl

#
# @author Luis M. Rodriguez-R <lmrodriguezr at gmail dot com>
# @license artistic license 2.0
# @update Jul-25-2013
#
use warnings;
use strict;
use Symbol;
use Getopt::Std;

sub HELP_MESSAGE { die "
Usage:
   $0 [args]

Mandatory:
   -m <str>	MeTaxa output.

Optional:
   -g <str>	Genes predicted in GFF2 format (as produced by
   		MetaGeneMark).  If not passed, abundance is assumed
		to be based on contigs.
   -c <str>	Counts file.  Sequence IDs (genes if -g is provided,
   		contigs otherwise) and reads per sequence in a
   		tab-delimited file.  If not provided, each sequence
		counts as 1.
   -O <str>	Prefix of the output files to be generated.  By
   		default, the value of -m.
   -I <str>	File containing the complete classification of
   		all the contigs identified as 'Innominate' taxa.
		By default, this file is not created.
   -G <str>	File containing the classification of each gene.
		By default, this file is not created.  Requires
		-g to be set.
   		Note: This option requires extra RAM.
   -K <str>	File containing a krona input file.  By default,
   		this file is not created.
   -k <str>	List of ranks to include in the Krona file,
   		delimited by commas.  By default:
		superkingdom,phylum,class,family,genus,species.
		Ignored unless -K is also passed.
   -u		Report Unknown taxa.
   -q		Run quietly.
   -h		Display this help message and exits.

" }

my %o;
getopts('g:c:m:O:I:G:K:k:uqh', \%o);
$o{h} and &HELP_MESSAGE;
$o{m} or  &HELP_MESSAGE;
$o{O} ||= $o{m};
$o{k} ||= "superkingdom,phylum,class,family,genus,species";
my @K = split /,/,$o{k};
($o{G} and not $o{g}) and die "-G requires -g to be set.\n";


my %gene;
my %count;
my %ctg=();
if($o{g}){
   print STDERR "Reading genes collection.\n" unless $o{q};
   open GFF, "<", $o{g} or die "Cannot read file: $o{g}: $!\n";
   while(<GFF>){
      next if /^#/;
      next if /^\s*$/;
      chomp;
      my @ln = split /\t/;
      exists $ln[8] or die "Cannot parse line $.: $_\n";
      my $id = $ln[8];
      $id =~ s/gene_id /gene_id_/;
      $ln[0] =~ s/ .*//;
      if($o{c}){
	 $gene{$id} = $ln[0];
      }else{
         $count{$ln[0]}++;
      }
      push( @{$ctg{$ln[0]}||=[]}, $id ) if $o{G};
   }
   close GFF;
   print STDERR " Found ".(scalar(keys %gene))." genes.\n" unless $o{q};
}

my $Nreads = 0;
if($o{c}){
   print STDERR "Reading read-counts.\n" unless $o{q};
   open COUNT, "<", $o{c} or die "Cannot read file: $o{c}: $!\n";
   while(<COUNT>){
      chomp;
      my @l = split /\t/;
      if($o{g}){
	 exists $gene{$l[0]} or die "Cannot find gene's contig: $l[0].\n";
	 $count{ $gene{$l[0]} } += $l[1];
	 delete $gene{$l[0]};
      }else{
	 $count{ $l[0] } += $l[1];
      }
      $Nreads += $l[1];
   }
   close COUNT;
   print STDERR " Found ".scalar(keys %gene)." genes without reads.\n" if scalar(keys %gene) and not $o{q};
   $count{$_}+=0 for values %gene;
   print STDERR " Found ".scalar(keys %count)." sequences and $Nreads reads.\n" unless $o{q};
}

print STDERR "Reading Metaxa results.\n";
open METAXA, "<", $o{m} or die "Cannot read file: $o{m}: $!\n";
my $ctg;
my $rank;
my @ofh = ();
my @n   = (0,0,0);
my @out = ({},{},{});
my %rank = (Unknown=>0, Phylum=>1, Genus=>2, Species=>3);
my @rank_name = qw/Biota Phylum Genus Species/;
my @rank_tag  = qw/NA <phylum> <genus> <species>/;
$o{I} and (open OUT_I, ">", $o{I} or die "Cannot create file: $o{I}: $!\n");
$o{K} and (open OUT_K, ">", $o{K} or die "Cannot create file: $o{K}: $!\n");
$o{G} and (open OUT_G, ">", $o{G} or die "Cannot create file: $o{G}: $!\n");

my $Nreads_class = 0;
while(not eof(METAXA)){
   my @h=split /\t/, <METAXA>;
   my $t=<METAXA>; chomp $t;
   exists $h[3] or die "Cannot parse metaxa file, line $.: $_\n";
   my $count_h;
   if($o{c} or $o{g}){
      exists $count{$h[0]} or die "Cannot find counts for contig $h[0].\n";
      $count_h = $count{$h[0]};
   }else{
      $count_h = 1;
   }
   if($o{G}){ print OUT_G "$_\t$t\n" for @{$ctg{$h[0]}} }
   next unless $count_h;
   my $last = 'organism';
   $n[0] += $count_h;
   for my $r (1 .. 3){
      if($rank{$h[1]} >= $r){
	 if($t =~ m/$rank_tag[$r]([^;]*)/){
	    $last = $1 if $1;
	 }else{
	    $last = $last=~/^Innominate / ? $last : "Innominate $last";
	    $o{I} and print OUT_I "$h[0]\t$rank_name[$r]\t$last\t$t\n";
	 }
	 $out[$r]->{$last} += $count_h;
	 $n[$r] += $count_h;
      }else{
         $out[$r]->{"Unknown $last"} += $count_h if $o{u};
      }
   }
   if($o{K}){
      my $ln = $count_h;
      for my $r (@K){ $ln.= "\t".($t=~m/<$r>([^;]+);/?$1:'') }
      print OUT_K "$ln\n";
   }
   $Nreads_class+= $count_h;
}
print OUT_K "".($Nreads-$Nreads_class)."\n" if $o{K} and $Nreads>$Nreads_class;
close METAXA;
$o{I} and close OUT_I;
$o{K} and close OUT_K;
$o{G} and close OUT_G;
unless($o{q}){ print " Found $n[$_] classified reads at ".$rank_name[$_]." level.\n" for (0 .. 3) }

print STDERR "Generating output.\n" unless $o{q};
for my $rank (1 .. 3){
   open OUT, ">", "$o{O}.".$rank_name[$rank].".txt" or die "Cannot create file: $o{O}.".$rank_name[$rank].".txt: $!\n";
   for my $class (keys %{$out[$rank]}){
      printf OUT "%s\t%.20f\n", $class, (1000*$out[$rank]->{$class}/$n[$rank]);
   }
   close OUT;
}

