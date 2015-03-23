#!/usr/bin/env perl
#
# @author Luis M. Rodriguez-R <lmrodriguezr at gmail dot com>
# @update Mar-23-2015
# @license artistic license 2.0
#

use warnings;
use strict;

my ($in, $off, $force) = @ARGV;
$in or die "
.Description:
   There are several FastQ formats (see http://en.wikipedia.org/wiki/FASTQ_format).
   This script takes a FastQ in any of them, identifies the type of FastQ (this is,
   the offset), and generates a FastQ with the given offset.  Note that Solexa+64
   FastQ can cause problematic values when using the offset 33, since there is no
   equivalent in Phred+33 for negative values (the range of Solexa+64 is -5 to 40).

.Usage:
   $0 in.fastq[ offset[ force]] > out.fastq

   in.fastq	Input file in FastQ format (range is automatically detected).
   offset	(optional) Offset to use for the output.  Use 0 (zero) to detect
   		the input format and exit.  By default: 33.
   force	(optional) If true, turns errors into warnings and continues.
   		Out-of-range values are set to the closest range limit.
   out.fastq	Output file in FastQ format with the specified offset.

";

$off = 33 unless defined $off;

my $in_off = 0;
open IN, "<", $in or die "Cannot read file: $in: $!\n";
GUESS_FORMAT: while(<IN>){
   unless($.%4){
      chomp;
      for my $chr (split //){
         my $o = ord $chr;
	 if($o < 55){
	    $in_off = 33;
	    last GUESS_FORMAT;
	 }elsif($o > 80){
	    $in_off = 64;
	    last GUESS_FORMAT;
	 }
      }
   }
}
close IN;
print STDERR "Detected input offset: Phred+$in_off\n";
exit unless $off;

my $Solexa64=0;
die "Couldn't guess input format.\n" unless $in_off;
open IN, "<", $in or die "Cannot read file: $in: $!\n";
while(<IN>){
   if($in_off==$off or $.%4){
      print $_;
   }else{
      chomp;
      for my $chr (split //){
         my $score = ord($chr) - $in_off;
	 my $err = '';
	 if($score < -5){
	    $err = "Out-of-range value $chr ($score) in line $..\n";
	    $score = $off==64 ? -5 : 0;
	 }elsif(!$Solexa64 and $score < 0){
	    if($in_off==64){
	       print STDERR "Format variant: Solexa+64\n";
	       $Solexa64 = 1;
	    }else{
	       $err = "Out-of-range value $chr ($score) in line $..\n";
	       $score = 0;
	    }
	 }elsif($score>41){
	    $err = "Out-of-range value $chr ($score) in line $..\n";
	    $score = 41;
	 }
	 if($err){
	    if($force){ warn $err } else { die $err }
	 }
	 print chr( $score + $off );
      }
      print "\n";
   }
}
close IN;

