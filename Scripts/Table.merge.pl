#!/usr/bin/env perl
#
# @author: Luis M. Rodriguez-R <lmrodriguezr at gmail dot com>
# @update: Mar-23-2015
# @license: artistic license 2.0
#

use warnings;
use strict;
use Getopt::Std;

my %o;
getopts('si:o:ne:h:', \%o);
my @files = @ARGV;

$#files>0 or die "
.Description:
   Merges multiple (two-column) lists into one table.

.Usage:
   $0 [options] files... > output.txt
   
   Options:
      -s	Values are read as Strings.  By default, values are read as numbers.
      -i <str>	Input field-delimiter.  By default: tabulation (\"\\t\").
      -o <str>	Output field-delimiter.  By default: tabulation (\"\\t\").
      -n	No-header.  By default, the header is determined by the file names.
      -e <str>	Default string when no value is found.  By default, the \"empty\" value
      		is 0 if values are numeric (i.e., unless -s is set) or an empty string
		otherwise.
      -h <str>	Header of the first column, containing the IDs.  By default: \"Tag\".

";
$o{i} ||= "\t";
$o{o} ||= "\t";
$o{e} ||= ($o{s} ? "" : 0);
$o{h} ||= "Tag";

my $notes = {};
#my $total = [];

print $o{h} unless $o{n};
my $i = 0;
for my $file (@files){
   (my $tag=$file) =~ s{.*/}{};
   $tag=~s/\..*//;
   print $o{o}.$tag unless $o{n};
   open IN, "<", $file or die "Cannot read file: $file: $!\n";
   while(<IN>){
      chomp;
      #m/^\s*(\d+)\s(.+)/ or die "I can not parse the line $. from the file $file: $_\n";
      #m/^\s*(.+)\s([\d\.]+)/ or die "I can not parse the line $. from the file $file: $_\n";
      my @l = split $o{i};
      $l[1]+=0 unless $o{s};
      $notes->{$l[0]} ||= [];
      $notes->{$l[0]}->[$i] = $l[1];
      #($total->[$i] ||= 0) += $l[1];
   }
   close IN;
   $i++;
}
print "\n" unless $o{n};

for my $id (keys %$notes){
   print $id;
   for my $i (0 .. $#files){
      print $o{o}.(( defined $notes->{$id}->[$i] ? $notes->{$id}->[$i] : $o{e} ));
   }
   print "\n";
}

