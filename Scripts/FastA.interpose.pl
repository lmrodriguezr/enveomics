#!/usr/bin/env perl

# Interpose sequences in FastA format from two files into one output file.  If more than two files are
# provided, the script will interpose all the input files.
# Please note that this script will check for the consistency of the names (assuming a pair of related reads
# contains the same name varying only in a trailing slash (/) followed by a digit.  If you want to turn this
# feature off just set the $eval_T variable to zero.  If you want to decrease the sampling period (to speed
# the script up) or increase it (to make it more sensitive to errors) just change $eval_T accordingly.
# 
# @author Luis M. Rodriguez-R
# @version 1.0
# @created Nov-27-2012
# @update Mar-23-2015
# @license artistic license 2.0
# 
# Usage: FastQ.interpose.pl <output_fastq> <input_fastq_1> <input_fastq_2> [additional input files...]

use strict;
use warnings;
use Symbol;

my $HELP = <<HELP
  Usage:
     $0 <output_fasta> <input_fasta_1> <input_fasta_2> [additional input files...]

  Where,
     output_fasta	: Output file
     input_fasta_1	: First FastA file
     input_fasta_2	: Second FastA file
     ...		: Any additional FastA files (or none)

HELP
;
my $eval_T = 1000;	# Period (in number of entries) of evaluation for consistency of the names.
			# To turn off evaluation set to 0 (zero).
my $out = shift @ARGV;
my @in = @ARGV;
$/ = "\n>";


die $HELP unless $out and $#in >= 1;
open OUT, ">", $out or die "Unable to write on $out: $!\n";
print "Output file: $out\n";

my @in_fh = ();

for my $k (0 .. $#in) {
   $in_fh[$k] = gensym;
   open $in_fh[$k], "<", $in[$k] or die "Unable to read $in[$k]: $!\n";
   print "Input file: $in[$k]\n";
}

my $i = 0;
my $frl;
LINE: while(1){
   my $name = "";
   print STDERR "\rEntry: $i    " unless $i % 1000;
   FILE: for my $k (0 .. $#in_fh){
      my $ln = readline($in_fh[$k]);
      last LINE if $k==0 and not defined $ln;
      defined $ln or die "Impossible to read next entry ($.) from $in[$k]: $!\n";
      $ln =~ s/^\>?/>/;
      $ln =~ s/\>$//;
      $ln =~ s/^;.*//gm;
      if($eval_T and not $i % $eval_T){
	 unless($name){
	    $ln =~ m/^>(.*?)[\/ \\_]\d+/ or die "Impossible to evaluate names!\n offending entry:\n$ln\n";
	    $name = $1;
	 }
	 die "Inconsistent name!\n base name is $name\n offending entry is:\n$ln\n" unless $ln =~ /^>$name/;
      }
      unless($frl){
         $ln =~ m/^>.*?\n(.*?)\n/ or die "Unexpected format!\n offending entry:\n$ln\n";
	 my $i = $ln;
	 $i =~ s/^>.*?\n//;
	 $i =~ s/\n//g;
	 $frl = length $i;
      }
      print OUT $ln;
   }
   $i++;
}
print "\rNumber of entries: $i     \nFirst read length: $frl\n";
close OUT;

for my $k(0..$#in_fh){print "ALERT: The file $in[$k] contains trailing entries\n" if defined readline($in_fh[$k])}

