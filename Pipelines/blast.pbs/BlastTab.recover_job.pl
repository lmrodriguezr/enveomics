#!/usr/bin/perl

use warnings;
use strict;
use File::Copy;

my($fasta, $blast) = @ARGV;

($fasta and $blast) or die "
.USAGE:
   $0 query.fa blast.txt

   query.fa	Query sequences in FastA format.
   blast.txt	Incomplete BLAST output in tabular format.

";

print "Fixing $blast:\n";
my $blast_res;
for(my $i=0; 1; $i++){
   $blast_res = "$blast-$i";
   last unless -e $blast_res;
}
open BLAST, "<", $blast or die "Cannot read the file: $blast: $!\n";
open TMP, ">", "$blast-tmp" or die "Cannot create the file: $blast-tmp: $!\n";
my $last="";
my $last_id="";
my $before = "";
while(my $ln=<BLAST>){
   chomp $ln;
   last unless $ln =~ m/(.+?)\t/;
   my $id = $1;
   if($id eq $last_id){
      $last.= $ln."\n";
   }else{
      print TMP $last if $last;
      $before = $last_id;
      $last = $ln."\n";
      $last_id = $id;
   }
}
close BLAST;
close TMP;

move "$blast-tmp", $blast_res or die "Cannot move file $blast-tmp into $blast_res: $!\n";
unlink $blast or die "Cannot delete file: $blast: $!\n";

unless($before eq ""){
   print "[$before] ";
   $before = ">$before";
   
   open FASTA, "<", $fasta or die "Cannot read file: $fasta: $!\n";
   open TMP, ">", "$fasta-tmp" or die "Cannot create file: $fasta-tmp: $!\n";
   my $print = 0;
   my $at = 0;
   my $i = 0;
   while(my $ln=<FASTA>){
      $i++;
      $print = 1 if $at and $ln =~ /^>/;
      print TMP $ln if $print;
      $ln =~ s/\s+.*//;
      chomp $ln;
      $at = $i if $ln eq $before;
   }
   close TMP;
   close FASTA;
   printf 'recovered at %.2f%% (%d/%d).'."\n", 100*$at/$i, $at, $i if $i;

   move $fasta, "$fasta.old" or die "Cannot move file $fasta into $fasta.old: $!\n";
   move "$fasta-tmp", $fasta or die "Cannot move file $fasta-tmp into $fasta: $!\n";
}

