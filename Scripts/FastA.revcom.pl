#!/usr/bin/env perl
#
# @author: Luis M. Rodriguez-R <lmrodriguezr at gmail dot com>
# @update: Dec-25-2015
# @license: artistic license 2.0
#
use strict;
use warnings;
use Bio::SeqIO;

($ARGV[0] and $ARGV[0] =~ /--?h(elp)?/) and die "
Description:
   Reverse-complement sequences in FastA format.

Usage:
   $0 < input.fa > output.fa

";

my @len = ();
my $seqI = Bio::SeqIO->new(-fh => \*STDIN, -format=>"FastA");
my $seqO = Bio::SeqIO->new(-fh => \*STDOUT, -format=>"FastA");
while(my $seq = $seqI->next_seq){ $seqO->write_seq($seq->revcom) }
