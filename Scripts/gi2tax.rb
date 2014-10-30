#!/usr/bin/ruby -w

#
# @author Luis M. Rodriguez-R <lmrodriguezr at gmail dot com>
# @license artistic license 2.0
# @update Oct-30-2014
#

require 'optparse'

#================================[ Options parsing ]
$o = {	:q=>false, :gis=>[], :dbfrom=>'nuccore', :header=>true, :ret=>'ScientificName',
	:ranks=>%w(superkingdom phylum class order family genus species)}
ARGV << '-h' if ARGV.size==0
$eutils = 'http://eutils.ncbi.nlm.nih.gov/entrez/eutils'
begin
   require 'rubygems'
   require 'restclient'
   require 'nokogiri'
rescue LoadError
   abort "Unmet requirements, please install required gems:\n\ngem install rubygems\ngem install rest_client"
end
opts = OptionParser.new do |opt|
   opt.banner = "
Maps a list of NCBI GIs to their corresponding taxonomy using NCBI-EUtilities. Avoid using this script on
millions of entries at a time, since each entry elicits two requests to NCBI's servers.

Usage: #{$0} [options]"
   opt.separator ""
   opt.on("-g", "--gis GI1,GI2,...", Array, "Comma-separated list of GIs. Required unless -i is passed."){ |v| $o[:gis]=v }
   opt.on("-i", "--infile FILE", "Raw text file containing the list of GIs, one per line. Required unless -g is passed."){ |v| $o[:infile]=v }
   opt.on("-p", "--protein", "Use if the GIs are proteins. Otherwise, GIs are assumed to be from the Nuccore Database."){ $o[:dbfrom]='protein' }
   opt.on("-r", "--ranks RANK1,RANK2,...", Array, "Taxonomic ranks to report. By default: #{$o[:ranks].join(',')}."){ |v| $o[:ranks]=v }
   opt.on("-n", "--noheader", "Do not includ a header in the output."){ $o[:header]=false }
   opt.on("-t", "--taxids", "Return Taxonomy IDs instead of scientific names."){ $o[:ret]='TaxId' }
   opt.on("-q", "--quiet", "Run quietly."){ |v| $o[:q]=true }
   opt.on("-h", "--help","Display this screen") do
      puts opt
      exit
   end
   opt.separator ""
end
opts.parse!

#================================[ Functions ]
def eutils(script, params={}, outfile=nil)
   response = RestClient.get "#{$eutils}/#{script}", {:params=>params}
   abort "Unable to reach NCBI EUtils, error code #{response.code}." unless response.code == 200
   unless outfile.nil?
      ohf = File.open(outfile, 'w')
      ohf.print response.to_s
      ohf.close
   end
   response.to_s
end
def efetch(*etc)
   eutils 'efetch.fcgi', *etc
end
def elink(*etc)
   eutils 'elink.fcgi', *etc
end

#================================[ Main ]
begin
   $o[:gis] += File.readlines($o[:infile]).map{ |l| l.chomp } unless $o[:infile].nil?
   $o[:ranks].map!{ |r| r.downcase }
   puts (["GI", "TaxId"] + $o[:ranks].map{ |r| r.capitalize }).join("\t") if $o[:header]
   $o[:gis].each do |gi|
      doc = Nokogiri::XML( elink({:dbfrom=>$o[:dbfrom], :db=>'taxonomy', :id=>gi}) )
      taxid = doc.at_xpath("/eLinkResult/LinkSet/LinkSetDb/Link/Id")
      taxonomy = {}
      unless taxid.nil?
	 doc = Nokogiri::XML( efetch({:db=>'taxonomy', :id=>taxid.content}) )
	 taxonomy[ doc.at_xpath("/TaxaSet/Taxon/Rank").content ] = doc.at_xpath("/TaxaSet/Taxon/#{$o[:ret]}").content
	 doc.xpath("/TaxaSet/Taxon/LineageEx/Taxon").each do |taxon|
	    taxonomy[ taxon.at_xpath("./Rank").content ] = taxon.at_xpath("./#{$o[:ret]}").content
	 end
      end
      puts ([gi, taxid.content] + $o[:ranks].map{ |rank| taxonomy[ rank ] ||= '' }).join("\t")
   end
rescue => err
   $stderr.puts "Exception: #{err}\n\n"
   err.backtrace.each { |l| $stderr.puts l + "\n" }
   err
end

