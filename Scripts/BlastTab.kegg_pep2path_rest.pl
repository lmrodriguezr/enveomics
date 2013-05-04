#!/usr/bin/env perl

use warnings;
use strict;
use LWP::Simple;
use JSON;

my($blast, $cache_file, $max_cache) = @ARGV;
($blast) or die "
Description:
   Takes a BLAST against KEGG_PEP and retrieves the pathways in which the subject
   peptides are involved.

Usage:
   $0 blast.txt[ cache_file[ max_cache]] > output.txt

   blast.txt	Input (filtered) BLAST file.
   cache_file	(optional) File containing the saved cache.  If unset, the
   		cache won't be recoverable across instances of this script.
   max_cache	(optional) Maximum number of proteins to store in RAM.
   		0 for unlimited cache.  By default: 0.
   output.txt	Tab-delimited output file, with the columns:
   		 o Query ID
		 o Subject ID
		 o Pathway ID
		 o Pathway (reference) description
		 o Organism

";

my $cache = {};
my $cache_n = 0;
$max_cache ||= 0;
$cache_file ||= "";

JSON_IN:{
   if($cache_file and -s $cache_file){
      local $/;
      open CACHE, "<", $cache_file or die "Cannot read file: $cache_file: $!\n";
      my $json = <CACHE>;
      $cache = decode_json($json);
      close CACHE;
      $cache_n = scalar keys %$cache;
   }
}

open BLAST, "<", $blast or die "Cannot read file: $blast: $!\n";
while(<BLAST>){
   chomp;
   my @l = split /\t/;
   if(exists $cache->{$l[1]}){
      print $l[0], "\t", $l[1], "\t", $_, "\n" for @{$cache->{$l[1]}};
   }else{
      my @descs = ();
      #my $results = $server->get_linkdb_by_entry($l[1], "pathway", $offset, $limit);
      #last unless $#$results>=0;
      #for (@$results){
#	 my $desc = $server->btit($_->{"entry_id2"});
#	 $desc =~ s/ /\t/;
#	 $desc =~ s/ - /\t/;
#	 print $l[0], "\t", $l[1], "\t", $desc;
#	 push @descs, $desc;
 #     }
      my $list = get "http://rest.kegg.jp/link/pathway/".$l[1];
      $list ||= "";
      chomp $list;
      for my $res (split /\n/, $list){
         my @p = split /\t/, $res;
	 $#p==1 or die "Unexpected number of columns in result for $l[1]:\n$res\n";
	 my $id = $p[1];
	 my $path = get "http://rest.kegg.jp/list/$id";
	 chomp $path;
	 die "More than one path with id $id:\n$path\n" if $path =~ /[\n\r]/;
	 $path =~ s/ - /\t/;
	 print "", join("\t", $l[0], $l[1], $path), "\n";
	 push @descs, $path;
      }
      if($cache_n <= $max_cache or not $max_cache){
	 $cache->{$l[1]} = \@descs;
	 $cache_n++;
      }
   }
}
close BLAST;

JSON_OUT:{
   if($cache_file){
      open CACHE, ">", $cache_file or die "Cannot create file: $cache_file: $!\n";
      print CACHE encode_json($cache);
      close CACHE;
   }
}

