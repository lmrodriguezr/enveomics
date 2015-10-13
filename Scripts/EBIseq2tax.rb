#!/usr/bin/env ruby

#
# @author  Luis M. Rodriguez-R <lmrodriguezr at gmail dot com>
# @update  Oct-13-2015
# @license Artistic License 2.0
#

$:.push File.expand_path(File.dirname(__FILE__) + "/lib")
require "enveomics_rb/remote_data"
use "nokogiri"

#================================[ Options parsing ]
$o = {
   q: false, ids: [], dbfrom: "uniprotkb", header: true,
   ret: "ScientificName",
   ranks: %w(superkingdom phylum class order family genus species)}

OptionParser.new do |opt|
   opt.banner = "
   Maps a list of EBI-supported IDs to their corresponding NCBI taxonomy using
   EBI RESTful API. Avoid using this script on millions of entries at a time,
   since each entry elicits requests to EBI and NCBI servers.

   Usage: #{$0} [options]".gsub(/^ +/,"")
   opt.separator ""
   opt.on("-i", "--ids ID1,ID2,...", Array,
      "Comma-separated list of EBI IDs. Required unless -I is passed."
      ){ |v| $o[:ids]=v }
   opt.on("-I", "--infile FILE",
      "Raw text file containing the list of EBI IDs, one per line.",
      "Required unless -i is passed."){ |v| $o[:infile]=v }
   opt.on("-d", "--database DB",
      "EBI database defining the EBI IDs. By default: " + $o[:dbfrom].to_s + "."
      ){ |v| $o[:dbfrom]=v }
   opt.on("-r", "--ranks RANK1,RANK2,...", Array,
      "Taxonomic ranks to report. By default:",
      $o[:ranks].join(",") + "."){ |v| $o[:ranks]=v }
   opt.on("-n", "--noheader",
      "Do not includ a header in the output."){ $o[:header]=false }
   opt.on("-t", "--taxids",
      "Return Taxonomy IDs instead of scientific names."){ $o[:ret]="TaxId" }
   opt.on("-q", "--quiet", "Run quietly."){ |v| $o[:q]=true }
   opt.on("-h", "--help","Display this screen") do
      puts opt
      exit
   end
   opt.separator ""
end.parse!

#================================[ Main ]
begin
   $o[:ids] += File.readlines($o[:infile]).map{ |l| l.chomp } unless
      $o[:infile].nil?
   $o[:ranks].map!{ |r| r.downcase }
   puts (["ID", "TaxId"] + $o[:ranks].map{ |r| r.capitalize }).join("\t") if
      $o[:header]
   $o[:ids].each do |id|
      id = $1 if id =~ /^[a-z]+\|\S+\|(\S+)/
      taxid = RemoteData.ebiseq2taxid(id, $o[:dbfrom])
      if taxid.nil?
	 warn "Cannot find link to taxonomy: #{id}"
	 next
      end
      taxonomy = {}
      unless taxid.nil?
	 doc = Nokogiri::XML( RemoteData.efetch({db: "taxonomy", id: taxid}) )
	 taxonomy[ doc.at_xpath("/TaxaSet/Taxon/Rank").content ] =
	    doc.at_xpath("/TaxaSet/Taxon/#{$o[:ret]}").content
	 doc.xpath("/TaxaSet/Taxon/LineageEx/Taxon").each do |taxon|
	    taxonomy[ taxon.at_xpath("./Rank").content ] =
	       taxon.at_xpath("./#{$o[:ret]}").content
	 end
      end
      puts ([id, taxid] +
	 $o[:ranks].map{ |rank| taxonomy[ rank ] ||= "" }).join("\t")
   end # $o[:ids].each
rescue => err
   $stderr.puts "Exception: #{err}\n\n"
   err.backtrace.each { |l| $stderr.puts l + "\n" }
   err
end

