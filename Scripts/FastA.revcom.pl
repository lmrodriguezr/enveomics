#!/usr/bin/env perl
#
# @author: Luis M. Rodriguez-R <lmrodriguezr at gmail dot com>
# @update: Mar-23-2015
# @license: artistic license 2.0
#
use strict;
use warnings;
use Bio::SeqIO;

my @len = ();
my $seqI = Bio::SeqIO->new(-fh => \*STDIN, -format=>"FastA");
my $seqO = Bio::SeqIO->new(-fh => \*STDOUT, -format=>"FastA");
while(my $seq = $seqI->next_seq){ $seqO->write_seq($seq->revcom) }

