#!/usr/bin/env perl

#
# @author: Luis M. Rodriguez-R <lmrodriguezr at gmail dot com>
# @update: Nov-29-2015
# @license: artistic license 2.0
#

use warnings;
use strict;
use Getopt::Std;
use List::Util qw/min max sum/;

sub VERSION_MESSAGE(){print "Alpha-diversity indices (enveomics)\n"}
sub HELP_MESSAGE(){die "
Description:
   Takes a table of OTU abundance in one or more samples and calculates the Rao
   (Q_alpha), Rao-Jost (Q_alpha_eqv), Shannon (Hprime), and inverse Simpson
   (1_lambda) indices of alpha diversity for each sample.
   
   To use it with Qiime OTU Tables, run it as:
   $0 -i OTU_Table.txt -h

Usage:
   $0 [opts]

   -i <str>	* Input table (columns:samples, rows:OTUs, first column:OTU
		names).
   -r <int>	Number of rows to ignore.  By default: 0.
   -c <int>	Number of columns to ignore after the first column (i.e.,
		between the first column, containing the name of the categories,
		and the first column of abundance values).  By default: 0.
   -C <int>	Number of columns to ignore at the end of each line.
		By default: 0.
   -d <str>	Delimiter.  Supported escaped characters are: \"\\t\"
		(tabulation), and \"\\0\" (null bit).  By default: \"\\t\".
   -h		If set, the first row is assumed to have the names of the
		samples.
   -D <str>	Distances file.  A squared matrix (or bottom-left half matrix)
		with the distances between categories (OTUs or functions).  The
		first column must contain the names of the categories, and it
		shouldn't have headers.  If not set, all distances are assumed
		to be one.  Only used for Rao.
   -R		Do not calculate Rao indices.  This significantly decreases the
		total running time. Note that Rao indices are highly susceptible
		to precision errors, and shouldn't be trusted for very big
		numbers.
   -q <int>	Estimate the qD index (true diversity order q).  By default: 0.
   --help	This help message.

   * Mandatory.

"}

# Input arguments
my %o;
getopts('i:c:C:d:r:hD:Rq:', \%o);

#$o{B} and (eval("use bignum; 1") or die "Cannot use bignum.\n");
&HELP_MESSAGE() unless $o{i};
$o{c} ||= 0;
$o{C} ||= 0;
$o{r} ||= 0;
$o{d} ||= "\\t";
$o{q} ||= 0;

$o{d}="\t" if $o{d} eq "\\t";
$o{d}="\0" if $o{d} eq "\\0";

# Distance matrix
my $D = {};
if($o{D} and not $o{R}){
   my @Didx = ();
   open DIST, "<", $o{D} or die "Cannot read file: $o{D}: $!\n";
   while(<DIST>){
      chomp;
      my @d = split /\t/;
      my $idx = shift @d;
      push  @Didx,  $idx;
      $D->{ $idx } ||= {};
      $D->{ $idx }->{ $Didx[$_] } = $d[$_] for(0 .. $#d);
   }
   close DIST;
   undef @Didx;
}

# Abundance matrix
my @names  = ();
my @cats   = ();
my @values = ();
open TABLE, "<", $o{i} or die "Cannot open file: ".$o{i}.": $!\n";
<TABLE> for (1 .. $o{r});
if($o{h}){
   my $h = <TABLE>;
   $h or die "Empty table!\n";
   chomp $h;
   @names = split $o{d}, $h;
   shift @names for (0 .. $o{c});
}

while(<TABLE>){
   chomp;
   my @ln = split $o{d};
   push @cats, shift(@ln);
   shift @ln for (1 .. $o{c});
   pop @ln for (1 .. $o{C});
   push @{$values[$_] ||= []}, $ln[$_] for (0 .. $#ln);
   push @{$values[$#ln+1]}, sum(@ln);
}
close TABLE;
$names[$#values] = "gamma";

if($o{R}){
   print "".join($o{d}, qw/Sample Hprime 1_lambda qD/)."\n";
}else{
   print "".join($o{d}, qw/Sample Q_alpha Q_alpha_eqv Hprime 1_lambda qD/)."\n";
}
for my $i (0 .. $#values){
   print "".(exists $names[$i] ? $names[$i] : $i).$o{d};
   my $N = sum @{$values[$i]};
   my $Q = 0;
   my $H = 0;
   my $l = 0;
   my $qD = 0 unless $o{q}==1;
   for my $ik (0 .. $#{$values[$i]}){
      unless($o{R}){
	 my $Qi = 0;
	 for my $jk (0 .. $#{$values[$i]}){
	    my $dij = (!$o{D}) ? 1 : 
	       exists $D->{ $cats[$ik] }->{ $cats[$jk] } ?
	       $D->{ $cats[$ik] }->{ $cats[$jk] } :
	       exists $D->{ $cats[$jk] }->{ $cats[$ik] } ?
	       $D->{ $cats[$jk] }->{ $cats[$ik] } :
	       die "Cannot find distance between ".$cats[$ik].
		  " and ".$cats[$jk].".\n";
	    $Qi += $dij * ($values[$i]->[$ik]/$N) * ($values[$i]->[$jk]/$N);
	 }
	 $Q += $Qi;
      }
      my $pi = $N ? $values[$i]->[$ik]/$N : 0;
      $H  -= $pi * log($pi) if $pi;
      $l  += $pi**2;
      $qD += $pi * ($pi**($o{q}-1)) unless $o{q}==1 or not $pi;
   }
   $qD = $o{q}==1 ? exp($H) : 1/($qD**(1/($o{q}-1)));
   if($o{R}){
      print "".join($o{d}, $H, $l ? 1/$l : "Inf", $qD)."\n";
   }else{
      print "".join($o{d}, $Q, ($Q==1 ? "NA" : 1/(1-$Q)), $H, 1/$l, $qD)."\n";
   }
}

