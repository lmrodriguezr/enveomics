#!/usr/bin/env perl
# 
# @author  Luis M. Rodriguez-R <lmrodriguezr at gmail dot com>
# @update  Oct-07-2015
# @license artistic license 2.0
# 

use strict;
use warnings;
use List::Util qw| max min sum |;
use Getopt::Std;
use Symbol;

my %o;
getopts('f:r:o:Fzhq', \%o);

my $HELP = <<HELP

  Description:
    Subsamples a set of sequences.

  Usage:
    # IMPORTANT: options *MUST* precede the input file(s).
    $0 [options] input.fa...
  
  Where,
    input.fa...	: File (or files) containing the sequences.
  
  Options:
    -f <float>	: Fraction of the library to be sampled (as percentage).  It can
    		  include several values (separated by comma), as well as ranges
		  of values in the form 'from-to/by'.  For example, the -f value
		  1-5/1,10-50/10,75,99 will produce 12 subsamples with expected
		  fractions 1%, 2%, 3%, 4%, 5%, 10%, 20%, 30%, 40%, 50%, 75%,
		  and 99%.  By default: 10.
    -r <int>	: Number of replicates per fraction.  By default: 1.
    -o <str>	: Prefix of the output files to be created.  The output files
		  will have a suffix of the form '.fraction-replicate.fa', where
		  'fraction' is the percentage sampled and 'replicate' is an
		  increasing integer for replicates of the same fraction.  By
		  default: Path to the input file.
    -F		: Force overwriting output file(s).
    -z		: Include leading zeroes in the numeric parts of the output
    		  files (e.g., file.002.50-01.fa instead of file.2.50-1.fa), so
		  that alphabetic sorting of files reflects the sampled
		  fraction.
    -q		: Run quietly.
    -h		: Displays this message and exits.

HELP
;

sub thousands($){ my $i=shift; $i=~s/(\d{1,3}?)(?=(\d{3})+$)/$1,/g; $i }
my @in  = @ARGV;
$o{f} ||= '10';
$o{r} ||= 1;
$o{o} ||= $in[0];
$#in>=0 or die $HELP;

my $samples = {};
my $sample_no=0;
my $format = ($o{z} ? "%s\.%08s\-%02i.fa" : "%s.%s-%s.fa");
for my $value (split /,/, $o{f}){
   my $from = $value;
   my $to   = $value;
   my $by   = 1;
   if($value =~ m/^([^-]+)-([^\/]+)\/(.+)$/){
      $from = $1;
      $to   = $2;
      $by   = $3;
      ($from,$to) = ($to,$from) if $from > $to;
   }
   for(my $p=$from; $p<=$to; $p+=$by){
      die "Percentage out of the [0,100] range: $p\n" if $p>100 or $p<0;
      $samples->{$p} ||= [];
      for (1 .. $o{r}){
         my $r = $#{$samples->{$p}}+2;
         my $file = sprintf $format, $o{o}, sprintf("%.4f", $p), $r;
	 die "File exists: $file.\n" if !$o{F} and -e $file;
	 $samples->{$p}->[$r-1] = [$p, 0, gensym(), $file];
	 open $samples->{$p}->[$r-1]->[2], ">", $file;
	 $sample_no++;
      }
   }
}
print STDERR "Open samples: $sample_no.\n" unless $o{q};

my $sprob = ($o{s} || '10');

die $HELP unless $sprob and $#in>=0;
$o{'h'} and die $HELP;

my $N  = 0;
my @ck = qw(*... **.. ***. .*** ..** ...*);
SAMPLING: {
   local $/ = "\n>";
   print STDERR "Sampling sequences.\n" unless $o{q};
   FILE: for my $in (@in){
      open IN, '<', $in or die "I can not open $in: $!\n";
      SEQ: while(my $seq = <IN>){
	 $N++;
	 $seq =~ s/^>?/>/;
	 $seq =~ s/>$//;
	 $seq =~ s/^;.*//gm;
	 PERC: for my $sperc (values %$samples){
	    SAMPLE: for my $sample (@$sperc){
	       if($sample->[0] > rand 100){
		  $sample->[1]++;
		  print { qualify_to_ref $sample->[2] } $seq;
	       }
	    }
	 }
	 print STDERR " [".$ck[($N/5000)%@ck]."] ".&thousands($N).
	    " seqs.    \r" unless $o{q} or $N%5000;
      }
      close IN;
   }
}

print STDERR "  Total sequences: ".&thousands($N).".    \n" unless $o{q};
for my $p (values %$samples){
   for my $s (@$p){
      printf STDERR "
      Sample file:       %s
      Sampled sequences: %d
      Sampled fraction:  %.2f%%\n",
      $s->[3], $s->[1], $s->[1]*100/$N unless $o{q};
      close $s->[2];
   }
}

