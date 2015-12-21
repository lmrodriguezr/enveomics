#!/usr/bin/env perl
# 
# @authors Konstantinos Konstantinidis (initial version)
#          modified to work with the BLASTp 2.2.25+ m0 output by
#          Despina Tsementzi & Luis M. Rodriguez-R
# @updated Dec-21-2015
#


$/ = "Lambda     ";
use strict;
my %hash_depth;

my @query;
my @subject;
my @similarity;
my $length = "0";

my($cigar_chr, $blast) = @ARGV;

($cigar_chr and $blast) or die "
.Description:
   Counts the different AA substitutions in the best hit blast alignments, from
   a BLASTP pairwise format output (-outfmt 0 in BLAST+, -m 0 in legacy BLAST).

.Usage: $0 cigar_char blast.m0.txt > aa-subs.list

   cigar_char    Use '+' for similar substitutions, use '_' for non similar
                 substitutions
   blast.m0.txt  Blast in 'text' format (-outfmt/-m 0).
   aa-subs.list  A tab-delimited raw file with one substitution per row and
                 columns:
                 (1) Name-of-query_Name-of-subject
		 (2) AA-in-subject
		 (3) AA-in-query
		 (4) Total-Align-Length

";

# For each blast result (i.e., for each query)
open BLAST, "<", $blast or die "Cannot read file: $blast: $!\n";
while(my $data=<BLAST>) {
   $data =~ s/\r//g;
   my ($data_q, @array_matches) = split(/>/,$data);
   my ($name_query) = ($data_q =~ /Query\= (\S+?)(?:_GENE|\s)/);
   my ($length_query) = ($data_q =~ /\(([\d,]+) letters/ );
   ($length_query) = ($data_q =~ /Length=([\d,]+)/) unless $length_query;
   $length_query =~ tr/,//d;
   
   # For each alignment (i.e., for each HSP),
   # note the "last" at the end of the block,
   # so only the best match is considered
   foreach my $data_f (@array_matches) {
      # Capture statistics
      my ($length_match) = ($data_f =~ /Identities = \d+\/(\d+)/);
      my ($identity_match) = ($data_f =~ /Identities = \d+\/\d+ \((\d+)%/);
      my ($target_name) = ($data_f =~ /^\s?(\S+)/);

      # If the alignment meets minimum requirements
      if ($length_query >30 && ($length_match/$length_query > 0.7) && $identity_match > 60) {
	 $data_f =~ tr/ /_/;
	 my @array = split ("\n", $data_f);
	 my $blanks = 0;
	 my $prefix_size = 0;

	 # For each line in the alignment
	 for my $data_fff (@array) {	
	    if ($data_fff =~ /(Query[:_]_+\d+_+)([^_]+)/){
	       # Query lines
	       $prefix_size = length($1);
	       $length = length($2);
	       @query = split (//, $2);
	    }elsif ($data_fff =~ /^_{11}/){
	       # Cigar lines
	       @similarity = split(//, substr($data_fff, $prefix_size, $length));
	    }elsif ($data_fff =~ /Sbjct[:_]_+\d+_+([^_]+)/){
	       # Subject lines
	       @subject = split(//, $1);
	       # For each alignment column
	       for(my $i=0; $i <= $length; $i++){
		  if ($similarity[$i] eq $cigar_chr) {
		     print "$name_query\_$target_name\t$subject[$i]\t$query[$i]\t$length_match\n";
		  }
	       }
	       undef @query;
	       undef @similarity;
	       undef @subject; 
	    }
	    
	    # Remove secondary alignments
	    if ($data_fff =~ /^$/){
	       $blanks++;
	       last if $blanks >= 3;
	    }else{
	       $blanks=0;
	    }
	 } # for my $data_fff (@array)
      } # if ($length_query >30 ...
      last; # <---- So it takes only the best match!
   } # foreach my $data_f (@array_matches)
} # while(my $data=<>)

