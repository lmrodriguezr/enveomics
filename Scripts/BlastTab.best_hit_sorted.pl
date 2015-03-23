#!/usr/bin/env perl

#
# @author: Luis M. Rodriguez-R <lmrodriguezr at gmail dot com>
# @license: artistic license 2.0
# @last_update: Mar-23-2015
#

use strict;
use warnings;

die "
Usage:
   sort blast.txt ... | $0 > blast.bh.txt
   $0 blast_sorted.txt ... > blast.bh.txt
   $0 -h|--help|-?

   blast.txt ...	One or more files in Tabular BLAST format.
   blast_sorted.txt ...	One or more files in Tabular BLAST format pre-sorted.
   blast.bh.txt		Output file in BLAST format containing best-hits only.
   -h|--help|-?		Any of these flags trigger this help message and exits.

   NOTE: This script assumes that the BLAST is sorted.  Because it can read
   from the STDIN, calling this script without arguments cause it to still until
   killed or until an EOF (^D) is presented.

" if exists $ARGV[0] and $ARGV[0] =~ /^\-?\-(h(elp)?|\?)/i;

my $last_qry = '';
my @best_res;

sub best_result($$){
   my($r1, $r2)=@_;
   return $r1 unless $r2;
   return $r1->[11] > $r2->[11] ? @$r1 : @$r2;
}

my $i=0;
while(<>){
   chomp;
   #print STDERR " Reading entry $i...                             \r" unless $i%1000;
   my @res = split /\t/;
   die "\nCannot parse BLAST line $.: $_\n" unless exists $res[1];
   if($last_qry eq $res[0]){
      @best_res = &best_result(\@res, \@best_res);
   }else{
      print join("\t", @best_res), "\n" if $#best_res>0;
      @best_res = @res;
      $last_qry = $res[0];
   }
}
print join("\t", @best_res), "\n" if @best_res;



