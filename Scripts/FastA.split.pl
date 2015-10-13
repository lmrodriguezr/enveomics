#!/usr/bin/env perl
#
# @author Luis M. Rodriguez-R <lmrodriguezr at gmail dot com>
# @update Oct-13-2015
# @license artistic license 2.0
#

use warnings;
use strict;
use Symbol;

my ($file, $base, $outN) = @ARGV;

$outN ||= 12;
($file and $base) or die "
Usage
   $0 in_file.fa out_base[ no_files]
   
   in_file.fa	Input file in FastA format.
   out_base	Prefix for the name of the output files.  It will
   		be appended with .<i>.fa, where <i> is a consecutive
		number starting in 1.
   no_files	Number of files to generate.  By default: 12.

";


my @outSym = ();
for my $i (1 .. $outN){
   $outSym[$i-1] = gensym;
   open $outSym[$i-1], ">", "$base.$i.fa" or
      die "I can not create the file: $base.$i.fa: $!\n";
}


my($i, $seq) = (-1, '');
open FILE, "<", $file or die "I can not read the file: $file: $!\n";
while(my $ln=<FILE>){
   next if $ln=~/^;/;
   if($ln =~ m/^>/){
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

