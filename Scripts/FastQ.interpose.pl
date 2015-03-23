#!/usr/bin/env perl
# 
# @author Luis M. Rodriguez-R
# @version 2.0
# @update: Mar-23-2015
# @license artistic license 2.0
# 
# Usage: FastQ.interpose.pl <output_fastq> <input_fastq_1> <input_fastq_2> [additional input files...]

use strict;
use warnings;
use Symbol;

my $HELP = <<HELP

  Description:
    Interposes sequences in FastQ format from two files into one output file.  If more than two files are
    provided, the script will interpose all the input files.
    Note that this script will check for the consistency of the names (assuming a pair of related reads
    contains the same name varying only in a trailing slash (/) followed by a digit.  If you want to turn
    this feature off just set the -T option to zero.  If you want to decrease the sampling period
    (to speed the script up) or increase it (to make it more sensitive to errors) just change -T option
    accordingly.
     
  Usage:
     $0 [-T <int> ]<output_fastq> <input_fastq_1> <input_fastq_2> [additional input files...]

  Where,
     -T <int>		: Optional.  Integer indicating the sampling period for names evaluation (see
     			  Description above).  By default: 1000.
     output_fastq	: Output file
     input_fastq_1	: First FastQ file
     input_fastq_2	: Second FastQ file
     ...		: Any additional FastQ files (or none)

HELP
;
my $eval_T = 1000;
if(exists $ARGV[0] and exists $ARGV[1] and $ARGV[0] eq '-T'){
   $eval_T = $ARGV[1]+0;
   shift @ARGV;
   shift @ARGV;
}
my $out = shift @ARGV;
my @in = @ARGV;

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
      my @ln = ();
      for my $l (0 .. 3){
	 $ln[$l] = readline($in_fh[$k]);
	 last LINE if $k==0 and $l==0 and (not defined $ln[$l]);
	 defined $ln[$l] or die "Impossible to read next entry (line $.) from $in[$k]: $!\n";
	 chomp $ln[$l];
      }
      if($eval_T and not $i % $eval_T){
	 $ln[0] =~ m/^\@(.*?)\/\d+\s*$/ or die "Impossible to evaluate names!\n offending entry:\n$ln[0]\n";
	 $name ||= $1;
	 die "Inconsistent name!\n base name is $name\n offending entry is:\n$ln[0]\n" unless $1 eq $name;
      }
      unless($frl){
	 $ln[0] =~ /^@/ or die "Unexpected format! (missing @)\n offending entry: $ln[0].\n";
         $ln[2] =~ /^\+/ or die "Unexpected format! (missing +)\n offending entry: $ln[0].\n";
	 $frl = length $ln[1];
      }
      print OUT "".join("\n", @ln, "");
   }
   $i++;
}
print "\rNumber of entries: $i     \nFirst read length: $frl\n";
close OUT;

for my $k(0..$#in_fh){print "ALERT: The file $in[$k] contains trailing entries\n" if defined readline($in_fh[$k])}

