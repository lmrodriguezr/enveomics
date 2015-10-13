#!/usr/bin/env perl
#
# @author  Luis M. Rodriguez-R <lmrodriguezr at gmail dot com>
# @update  Oct-07-2015
# @license artistic license 2.0
# 

use strict;
use List::Util qw/min/;

push @ARGV, undef unless $#ARGV%2;
my %params = @ARGV;

die "
Usage:
   $0 [options] < in.fa > out.fa

   in.fa	Input file in FastA format.
   out.fa	Output file in FastA format.

Options:
   -seq <str>	Input file.  If not set, it is expected to be in STDIN.
   -out <str>	Output file.  If not set, it is sent to STDOUT.
   -win <int>	Window size.  By default: 18.
   -step <int>	Step size.  By default: 1.
   -lerr <int>	Expected error in chunks length.  By default: 2.
   -comm <1|0>	Generate FastA comments (leaded by semi-colon) to separate
		input sequences.  By default: 0.
   -short <1|0>	Use chunks shorter than the window size 'as is'. By
		default: 0 (discard those chunks).
   -h		Displays this help message and exits.

" if exists $params{'--help'} or
   exists $params{'-h'} or exists $params{'-help'};

if($params{'-seq'}){
   open SEQ, "<", $params{'-seq'} or
      die "I can not open '".$params{'-seq'}."': $!\n";
}else{
   *SEQ = *STDIN;
   print STDERR "Please input your sequence, and hit ".
      "Intro and Ctrl+D when you are done:\n";
}

if($params{'-out'}){
   open OUT, ">", $params{'-out'} or
      die "I can not open '".$params{'-out'}."': $!\n";
}else{
   *OUT = *STDOUT;
}

$params{'-win'} ||= 18;
$params{'-step'} ||= 1;
$params{'-lerr'} ||= 2;
$params{'-comm'} ||= 0;
$params{'-short'} ||= 0;

my $win = $params{'-win'}+0;
my $stp = $params{'-step'}+0;
my $lerr = $params{'-lerr'}+0;
my $buffer = "";
my $i = 0;
while(<SEQ>){
   next if /^;/;
   chomp;
   if(m/^>/){
      print OUT ">", ++$i, "\n", $buffer, "\n" if
	 $params{'-short'}==1 and $buffer;
      $buffer = "";
      print OUT ";--- INPUT: $_ ---\n" unless $params{'-comm'}==0;
      next;
   }
   s/[^A-Za-z]//g;
   $buffer.= $_;
   while(length($buffer) >= $win){
      print OUT ">", ++$i, "\n",
	 substr($buffer, 0, $win+int(rand($lerr*2)-$lerr)), "\n";
      $buffer = substr $buffer, $stp;
   }
}
close SEQ if $params{'-seq'};
close OUT if $params{'-out'};
print STDERR "$i chunks produced.\n";


