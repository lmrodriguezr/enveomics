#!/usr/bin/env perl

use warnings;
use strict;
use LWP::Simple;
use JSON;
use File::Copy;

my($blast, $cache_file, $max_cache) = @ARGV;
($blast) or die "
Description:
   Takes a BLAST against KEGG_PEP (or KO) and retrieves the pathways in which the subject
   peptides are involved.

Usage:
   $0 blast.txt[ cache_file] > output.txt

   blast.txt	Input (filtered) BLAST file.
   cache_file	(optional) File containing the saved cache.  If unset, the
   		cache won't be recoverable across instances of this script.
		It is strongly recommended to set a file.  Multiple
		parallel instances of this script may use the same cache
		file.
   output.txt	Tab-delimited output file, with the columns:
   		 o Query ID
		 o Subject ID
		 o Pathway ID
		 o Pathway (reference) description
		 o Organism

";

$max_cache ||= 0;
$cache_file ||= "";

sub read_cache($){
   my ($cache_file) = @_;
   my $cache = {};
   my $n = 0;
   if($cache_file and -s $cache_file){
      local $/;
      my $json = "";
      while(-e "$cache_file.tmp"){
         print STDERR "Locked cache (read), waiting 1 sec.\n";
	 sleep 1;
      }
      open CACHE, "<", $cache_file or die "Cannot read file: $cache_file: $!\n";
      while(<CACHE>){ $json.=$_ }
      close CACHE;
      $cache = decode_json($json);
      $n = scalar keys %$cache;
   }
   return ($cache, $n);
}

sub write_cache($$){
   my($cache, $cache_file) = @_;
   if($cache_file){
      # Get previously saved entries.
      my($cache2, $cache_n2) = &read_cache($cache_file);
      for my $k (keys %$cache2){
	 $cache->{$k} ||= $cache2->{$k} unless $k eq "###:paths";
      }
      $cache->{'###:paths'} ||= {};
      for my $p (keys %{$cache2->{'###:paths'}}){
         $cache->{'###:paths'}->{$p} ||= $cache2->{'###:paths'}->{$p};
      }
      # Save merged cache.
      if(-s $cache_file){ copy $cache_file, "$cache_file.pre" or die "Cannot create file: $cache_file.tmp: $!\n" }
      my $json = encode_json($cache);
      while(-e "$cache_file.tmp"){
         print STDERR "Locked cache (write), waiting 1 sec.\n";
	 sleep 1;
      }
      open CACHE, ">", "$cache_file.tmp" or die "Cannot create file: $cache_file.tmp: $!\n";
      print CACHE $json;
      close CACHE;
      copy "$cache_file.tmp", $cache_file or die "Cannot create file: $cache_file: $!\n";
      unlink "$cache_file.tmp" or die "Cannot unlink file: $cache_file.tmp: $!\n";
   }
}

sub download_pathways($$){
   my($cache, $ids) = @_;
   my @todownload = ();
   for my $id (@$ids){
      push @todownload, $id unless exists $cache->{'###:paths'}->{$id};
   }
   while($#todownload>=0){
      my @downloading = splice(@todownload, 0, 100);
      my $path = get "http://rest.kegg.jp/list/".join("+", @downloading);
      if($path){
	 chomp $path;
	 for my $p (split /\n/, $path){
	    my @wl = split /\t/, $p;
	    $wl[1] =~ s/ - /\t/;
	    $cache->{'###:paths'}->{$wl[0]} = $wl[1];
	 }
      }
   }
   return $cache;
}

sub download($$){
   my($cache, $todownload) = @_;
   $cache->{'###:paths'} ||= {};
   return $cache unless $#$todownload>=0;
   $cache->{$_} = [] for @$todownload;
   my $list = get "http://rest.kegg.jp/link/pathway/".join("+", @$todownload);
   $list ||= "";
   chomp $list;
   my @pathids = ();
   for my $res (split /\n/, $list){
      my @rel = split /\t/, $res;
      $#rel==1 or die "Unexpected number of columns:\n$res\n";
      my $id = $rel[1];
      push @pathids, $id;
      unless(exists $cache->{$rel[0]}){
	 #print STDERR "Request/response difference in ID: ".$rel[0].", searching match.\n";
         for my $id (@$todownload){
	    $rel[0] = $id if lc $id eq lc $rel[0];
	 }
	 die "Cannot find corresponding request.\n" unless exists $cache->{$rel[0]};
      }
      push @{ $cache->{$rel[0]} }, $id;
   }
   return &download_pathways($cache, \@pathids);
}

sub print_out($$){
   my($cache, $hits) = @_;
   for my $hit (@$hits){
      die "Impossible to find gene in cache: ".$hit->[1]."\n" unless exists $cache->{$hit->[1]};
      for my $path (@{$cache->{$hit->[1]}}){
	 next if $path =~ /^path:ko\d/;
	 unless(exists $cache->{'###:paths'}->{$path}){
	    print STDERR "Cannot find pathway in cache: $path (from ".$hit->[1]."), emergency download\n";
	    $cache = &download_pathways($cache, [$path]);
	    die "Impossible to find pathway: $path.\n" unless exists $cache->{'###:paths'}->{$path};
	 }
	 print "", join("\t", $hit->[0], $hit->[1], $path, $cache->{'###:paths'}->{$path}), "\n";
      }
   }
}

print STDERR "Loading cache.\n";
my ($cache, $n) = &read_cache($cache_file);
print STDERR "   $n entries loaded.\n";
my @nopath = ();
for my $k (keys %$cache){
   next if $k eq "###:paths";
   for my $p (@{ $cache->{$k} }){
      push @nopath, $p unless exists $cache->{'###:paths'}->{$p};
   }
}
if($#nopath>=0){
   print STDERR "   Sanitizing ".@nopath." pathways in cache.\n";
   while($#nopath>=0){
      my @paths = ();
      for(1 .. 15){ push @paths, shift @nopath unless $#nopath==-1 }
      $cache = &download_pathways($cache, \@paths);
   }
   &write_cache($cache, $cache_file);
}

my $lines=0;
my $downs=0;
my @buff = ();
my @todownload = ();
print STDERR "Mapping genes.\n";
open BLAST, "<", $blast or die "Cannot read file: $blast: $!\n";
while(<BLAST>){
   chomp;
   my @l = split /\t/;
   print STDERR "   Mapping line ".(++$lines).". \r";
   unless(($#todownload+2)%100){
      print STDERR "+\r";
      print STDERR " *\r" unless ++$downs%10;
      $cache = &download($cache, \@todownload);
      @todownload = ();
      &print_out($cache, \@buff);
      @buff = ();
      &write_cache($cache, $cache_file) unless $downs%10;
   }
   push @buff, \@l;
   push @todownload, $l[1] unless exists $cache->{$l[1]};
}
print STDERR "\nDone.\n";
close BLAST;

$cache = &download($cache, \@todownload);
&print_out($cache, \@buff);
&write_cache($cache, $cache_file);

