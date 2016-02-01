#!/usr/bin/env perl
#
# @author Luis M. Rodriguez-R <lmrodriguezr at gmail dot com>
# @update Feb-01-2016
# @license artistic license 2.0
#

use warnings;
use strict;
use Getopt::Std;
use Symbol;

my %o;
getopts('i:o:d:e:h', \%o);
my $file = shift @ARGV;

($file and not $o{h}) or die "
.Description:
   Split a file with multiple columns into multiple two-columns lists.

.Usage:
   $0 [options] file
   
   Options:
      -i <str>	Input field-delimiter.  By default: tabulation (\"\\t\").
      -o <str>	Prefix of the output files.  By default: no prefix (\"\").
      -d <str>	Output directory. By default: current directory (\"\").

";
$o{i} ||= "\t";
$o{o} ||= "";
$o{o} = $o{d}."/".$o{o} if $o{d};

my $open=0;
my @fhs=();
open IN, "<", $file or die "Cannot read file: $file: $!\n";
while(<IN>){
   chomp;
   my @row = split $o{i};
   my $h = shift @row;
   if($open){
      for my $i (0 .. $#row){
         print { qualify_to_ref $fhs[$i] } $h.$o{i}.$row[$i]."\n" if $row[$i];
      }
   }else{
      $open++;
      for my $l (@row){
         $l =~ s/[\.\/:]/_/g;
	 my $gs = gensym;
	 open($gs, '>', $o{o}.$l.".txt") or die "Cannot create file: $o{o}$l.txt: $!\n";
	 push @fhs, $gs;
      }
   }
}
close IN;
close $_ for @fhs;

