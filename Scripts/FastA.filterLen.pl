#!/usr/bin/env perl

use warnings;
use strict;
use Bio::SeqIO;

my $file = $ARGV[0]; 
my $min = $ARGV[1];
($file and $min) or die <<HELP

This script will filter a multi fastA file by length

Usage "perl $0 fastafile minlenght "
HELP
;
my $seq_in  = Bio::SeqIO->new( -format => 'fasta',-file => $file);

while( my $seq1 = $seq_in->next_seq() ) {	
	
	my $id  = $seq1->primary_id;
	chomp $id;
	my $seq = $seq1->seq;
	chomp $seq;
	my $lseq = length($seq);
	if($lseq>=$min){
		print ">$id","\n",$seq,"\n";	
	}
}
