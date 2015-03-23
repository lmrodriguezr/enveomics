#!/usr/bin/env perl

#
# @author: Luis M. Rodriguez-R
# @update: Mar-23-2015
# @license: artistic license 2.0
#

use Bio::AlignIO;

my($iformat,$oformat) = @ARGV;
($iformat and $oformat) or die "
Usage:
   $0 in-format out-format < in_file > output_file

   in-format	Input file's format.
   out-format	Output file's format.
   in_file	Input file.
   out_file	Output file.

Example:
   # Re-format example.fa into Stockholm
   $0 fasta stockholm < example.fa > example.stk

Supported formats are:
   bl2seq, clustalw, emboss, fasta, maf, mase, mega,
   meme, metafasta, msf, nexus, pfam, phylip, po,
   prodom, psi, selex, stockholm, XMFA, arp

";

$in  = Bio::AlignIO->new(-fh => \*STDIN, -format => $iformat);
$out = Bio::AlignIO->new(-fh => \*STDOUT, -format => $oformat);
while ( my $aln = $in->next_aln ) { $out->write_aln($aln) }

