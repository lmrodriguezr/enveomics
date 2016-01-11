#!/usr/bin/env ruby

#
# @author  Luis M. Rodriguez-R <lmrodriguezr at gmail dot com>
# @update  Jan-11-2016
# @license artistic license 2.0
#

$:.push File.expand_path(File.dirname(__FILE__) + "/lib")
require "enveomics_rb/remote_data"
use "nokogiri"

#================================[ Options parsing ]
o = {	:q=>false, :gis=>[], :dbfrom=>"nuccore", :header=>true,
   :exact_gi=>false, :no_nil=>false, :ret=>"ScientificName",
   :ranks=>%w(superkingdom phylum class order family genus species)}
OptionParser.new do |opt|
   opt.banner = "
   Maps a list of NCBI GIs to their corresponding taxonomy using the NCBI
   EUtilities. Avoid using this script on millions of entries at a time, since
   each entry elicits two requests to NCBI's servers.

   Usage: #{$0} [options]".gsub(/^ +/,"")
   opt.separator ""
   opt.on("-g", "--gis GI1,GI2,...", Array,
      "Comma-separated list of GIs. Required unless -i is passed."
      ){ |v| o[:gis]=v }
   opt.on("-i", "--infile FILE",
      "Raw text file containing the list of GIs, one per line.",
      "Required unless -g is passed."){ |v| o[:infile]=v }
   opt.on("-p", "--protein",
      "Use if the GIs are proteins. Otherwise, GIs are assumed to be from " +
      "the Nuccore Database."){ o[:dbfrom]="protein" }
   opt.on("-r", "--ranks RANK1,RANK2,...", Array,
      "Taxonomic ranks to report. By default: #{o[:ranks].join(",")}."
      ){ |v| o[:ranks]=v }
   opt.on("-n", "--noheader",
      "Do not include a header in the output."){ o[:header]=false }
   opt.on("-t", "--taxids",
      "Return Taxonomy IDs instead of scientific names."){ o[:ret]="TaxId" }
   opt.on("--exact-gi",
      "Returns only taxonomy associated with the exact GI passed.",
      "By default, it attempts to update accession versions if possible."
      ){ |v| o[:exact_gi]=v }
   opt.on("--ignore-missing",
      "Does not report missing GIs in the output file.",
      "By default, it reports GI and empty values for all other columns."
      ){ |v| o[:no_nil]=v }
   opt.on("-q", "--quiet", "Run quietly."){ |v| o[:q]=true }
   opt.on("-h", "--help","Display this screen") do
      puts opt
      exit
   end
   opt.separator ""
end.parse!

#================================[ Functions ]
def gi2taxid(db, gi)
   doc = Nokogiri::XML( RemoteData.elink({:dbfrom=>db,
      :db=>"taxonomy", :id=>gi}) )
   doc.at_xpath("/eLinkResult/LinkSet/LinkSetDb/Link/Id")
end
#================================[ Main ]
begin
   o[:gis] += File.readlines(o[:infile]).map{ |l| l.chomp } unless
      o[:infile].nil?
   o[:ranks].map!{ |r| r.downcase }
   puts (["GI", "TaxId"] + o[:ranks].map{ |r| r.capitalize }).join("\t") if
      o[:header]
   o[:gis].each do |gi|
      taxid = gi2taxid(o[:dbfrom], gi)
      status = ""
      if taxid.nil? and not o[:exact_gi]
	 new_gi, status = RemoteData.update_gi(o[:dbfrom], gi)
	 taxid = gi2taxid(o[:dbfrom], new_gi) unless new_gi.nil?
      end
      if taxid.nil?
	 warn "Cannot find link to taxonomy: #{gi} #{status}"
	 puts ([gi, ""] + o[:ranks].map{ |i| "" }).join("\t") unless o[:no_nil]
	 next
      end
      taxonomy = {}
      unless taxid.nil?
	 doc = Nokogiri::XML( RemoteData.efetch({:db=>"taxonomy",
	    :id=>taxid.content}) )
	 taxonomy[ doc.at_xpath("/TaxaSet/Taxon/Rank").content ] =
	    doc.at_xpath("/TaxaSet/Taxon/#{o[:ret]}").content
	 doc.xpath("/TaxaSet/Taxon/LineageEx/Taxon").each do |taxon|
	    taxonomy[ taxon.at_xpath("./Rank").content ] =
	       taxon.at_xpath("./#{o[:ret]}").content
	 end
      end
      puts ([gi, taxid.content] +
	 o[:ranks].map{ |rank| taxonomy[ rank ] ||= "" }).join("\t")
   end
rescue => err
   $stderr.puts "Exception: #{err}\n\n"
   err.backtrace.each { |l| $stderr.puts l + "\n" }
   err
end
