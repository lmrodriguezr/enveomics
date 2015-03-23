#!/usr/bin/env perl
#
# @author Luis M. Rodriguez-R <lmrodriguezr at gmail dot com>
# @license artistic license 2.0
# @update Mar-23-2015
#
use warnings;
use strict;
use Symbol;
use Getopt::Std;
use List::Util qw/max/;

sub HELP_MESSAGE { die "
Usage:
   $0 [args]

Mandatory:
   -m <str>	MyTaxa output.

Optional:
   -g <str>	Genes predicted in the format defined by -f.  If not passed, abundance is assumed to be based
   		on contigs.
   -f <str>	Format of the predicted genes.  One of:
   		o gff2: GFF v2 as produced by MetaGeneMark.hmm (default).
		o gff3: GFF v3, including the field id in the last column (with the Gene ID).
		o tab: A tab-delimited file with the gene ID (col #1), the length of the gene in bp (col #2),
		  and the ID of the corresponding contig (col #3). The length of the gene (col #2) isn't used
		  (and it can be empty),  but the column must exist (i.e., 2 tabs per line) for compatibility
		  with BlastTab.metaxaPrep.pl
   -c <str>	Counts file: Sequence IDs (genes if -g is provided, contigs otherwise) and reads per sequence
   		in a tab-delimited file.  If not provided, each sequence counts as 1.
   -O <str>	Prefix of the output files to be generated.  By default, the value of -m.
   -I <str>	File containing the complete classification of all the contigs identified as Innominate taxa.
		By default, this file is not created.
   -G <str>	File containing the classification of each gene.  By default, this file is not created.  This
   		requires -g to be set.  Note: This option requires extra RAM.
   -K <str>	File containing a krona input file.  By default, this file is not created.
   -k <str>	List of ranks to include in the Krona file, delimited by comma.   It MUST be decreasing rank.
   		By default: 'superkingdom,phylum,class,family,genus,species'.  This is ignored unless -K also
		is passed.
   -R <str>	List of taxonomic ranks for which individual reports should be generated, delimited by comma.
   		It MUST be decreasing rank.  By default: 'phylum,genus,species'.
   -r		If set, reports raw counts.  Otherwise, reports permil of the rank.
   -u		Report Unknown taxa.
   -q		Run quietly.
   -h		Display this help message and exits.

" }

my %o;
getopts('g:f:c:m:O:I:G:K:k:R:ruqh', \%o);
$o{h} and &HELP_MESSAGE;
$o{m} or  &HELP_MESSAGE;
$o{O} ||= $o{m};
$o{f} ||= "gff2";
$o{k} ||= "superkingdom,phylum,class,family,genus,species";
my @K = split /,/, lc $o{k};
$o{R} ||= "phylum,genus,species";
my @R = split /,/, lc $o{R};
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
      my($id,$ctg);
      my @ln = split /\t/;
      if($o{f} eq 'gff2'){
	 exists $ln[8] or die "Cannot parse line $., expecting 9 columns: $_\n";
	 $id = $ln[8];
	 $id =~ s/gene_id /gene_id_/;
	 $ctg=$ln[0];
      }elsif($o{f} eq 'gff3'){
	 exists $ln[8] or die "Cannot parse line $., expecting 9 columns: $_\n";
	 $ln[8] =~ /id=([^;]+)/ or die "Cannot parse line $.: $_\n";
	 $id = $1;
	 $ctg = $ln[0];
      }elsif($o{f} eq 'tab'){
         exists $ln[2] or die "Cannot parse line $., expecting 3 columns: $_\n";
	 $id = $ln[0];
	 $ctg = $ln[2];
      }else{
         die "Unsupported format: ".$o{f}.".\n";
      }
      $ctg =~ s/ .*//;
      if($o{c}){
	 $gene{$id} = $ctg;
      }else{
         $count{$ctg}++;
      }
      push( @{$ctg{$ctg}||=[]}, $id ) if $o{G};
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
my @rank_name = map { ucfirst } ('unknown', @R);
my %rank = map { ($rank_name[$_]=>$_) } 0 .. $#rank_name;
my @rank_tag  = ("NA", map { "<$_>" } @R);
$o{I} and (open OUT_I, ">", $o{I} or die "Cannot create file: $o{I}: $!\n");
$o{K} and (open OUT_K, ">", $o{K} or die "Cannot create file: $o{K}: $!\n");
$o{G} and (open OUT_G, ">", $o{G} or die "Cannot create file: $o{G}: $!\n");

my $Nreads_class = 0;
my $Nno_read_ctg = 0;
while(not eof(METAXA)){
   my @h=split /\t/, <METAXA>;
   my $t=<METAXA>; chomp $t;
   exists $h[3] or die "Cannot parse MyTaxa file, line $.: $_\n";
   my $count_h;
   if($o{c} or $o{g}){
      unless(exists $count{$h[0]}){
         $Nno_read_ctg++;
	 next;
      }
      $count_h = $count{$h[0]};
   }else{
      $count_h = 1;
   }
   if($o{G}){ print OUT_G "$_\t$t\n" for @{$ctg{$h[0]}} }
   next unless $count_h;
   my $last = 'organism';
   $n[0] += $count_h;
   for my $r (1 .. max(values %rank)){
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
      for my $r (@K){ $ln.= "\t".($t=~m/<$r>([^;]+)/?$1:'') }
      print OUT_K "$ln\n";
   }
   $Nreads_class+= $count_h;
}
print OUT_K "".($Nreads-$Nreads_class)."\n" if $o{K} and $Nreads>$Nreads_class;
close METAXA;
$o{I} and close OUT_I;
$o{K} and close OUT_K;
$o{G} and close OUT_G;
print " Found $n[0] reads.\n" unless $o{q};
print " Couldn't find counts for $Nno_read_ctg contigs.\n" if $Nno_read_ctg;
unless($o{q}){ print " Found $n[$_] classified reads at ".$rank_name[$_]." level.\n" for (1 .. max(values %rank)) }

print STDERR "Generating output.\n" unless $o{q};
for my $rank (1 .. max(values %rank)){
   open OUT, ">", "$o{O}.".$rank_name[$rank].".txt" or die "Cannot create file: $o{O}.".$rank_name[$rank].".txt: $!\n";
   for my $class (keys %{$out[$rank]}){
      printf OUT "%s\t%.20f\n", $class, ($out[$rank]->{$class}*($o{r}?1:1000/$n[$rank]));
   }
   close OUT;
}

