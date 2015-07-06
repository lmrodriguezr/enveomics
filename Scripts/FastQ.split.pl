#!/usr/bin/env perl
#
# @author Luis M. Rodriguez-R <lmrodriguezr at gmail dot com>
# @license artistic license 2.0
# @update Jul-05-2015
#

use warnings;
use strict;
use Symbol;

my ($file, $base, $outN) = @ARGV;

$outN ||= 2;
($file and $base) or die "
Usage
   $0 in_file.fq out_base[ no_files]
   
   in_file.fq	Input file in FastA format.
   out_base	Prefix for the name of the output files.  It will
   		be appended with .<i>.fastq, where <i> is a consecutive
		number starting in 1.
   no_files	Number of files to generate.  By default: 2.

";


my @outSym = ();
for my $i (1 .. $outN){
   $outSym[$i-1] = gensym;
   open $outSym[$i-1], ">", "$base.$i.fastq" or die "I can not create the file: $base.$i.fa: $!\n";
}


my($i, $seq) = (-1, '');
open FILE, "<", $file or die "I can not read the file: $file: $!\n";
while(my $ln=<FILE>){
   if($.%4 == 1){
      print { $outSym[$i % $outN] } $seq if $seq;
      $i++;
      $seq = '';
   }
   $seq.=$ln;
}
print { $outSym[$i % $outN] } $seq if $seq;
close FILE;

for(my $j=0; $j<$outN; $j++){
   close $outSym[$j];
}

print STDERR "Sequences: ".($i+1)."\nFiles: $outN\n";

