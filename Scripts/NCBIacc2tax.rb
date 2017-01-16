#!/usr/bin/env ruby

#
# @author  Luis M. Rodriguez-R <lmrodriguezr at gmail dot com>
# @license artistic license 2.0
#

$:.push File.expand_path(File.dirname(__FILE__) + "/lib")
require "enveomics_rb/remote_data"
use "nokogiri"

#================================[ Options parsing ]
o = {
  :q=>false, :accs=>[], :dbfrom=>"nuccore", :header=>true,
  :no_nil=>false, :ret=>"ScientificName",
  :ranks=>%w(superkingdom phylum class order family genus species)}
OptionParser.new do |opt|
  opt.banner = "
  Maps a list of NCBI accessions to their corresponding taxonomy using the NCBI
  EUtilities. Avoid using this script on millions of entries at a time, since
  each entry elicits two requests to NCBI's servers.

  Usage: #{$0} [options]".gsub(/^ +/,"")
  opt.separator ""
  opt.on("-a", "--acc acc1,acc2.ver,...", Array,
    "Comma-separated list of accessions. Required unless -i is passed."
    ){ |v| o[:accs]=v }
  opt.on("-i", "--infile FILE",
    "Raw text file containing the list of accessions, one per line.",
    "Required unless -g is passed."){ |v| o[:infile]=v }
  opt.on("-p", "--protein",
    "Use if the accessions are proteins. Otherwise, accessions are assumed " +
    "to be from the Nuccore Database."){ o[:dbfrom]="protein" }
  opt.on("-r", "--ranks RANK1,RANK2,...", Array,
    "Taxonomic ranks to report. By default: #{o[:ranks].join(",")}."
    ){ |v| o[:ranks]=v }
  opt.on("-n", "--noheader",
    "Do not include a header in the output."){ o[:header]=false }
  opt.on("-t", "--taxids",
    "Return Taxonomy IDs instead of scientific names."){ o[:ret]="TaxId" }
  opt.on("--ignore-missing",
    "Does not report missing accessions in the output file.",
    "By default, it reports accessions and empty values for all other columns."
    ){ |v| o[:no_nil]=v }
  opt.on("-q", "--quiet", "Run quietly."){ |v| o[:q]=true }
  opt.on("-h", "--help","Display this screen") do
    puts opt
    exit
  end
  opt.separator ""
end.parse!

#================================[ Functions ]
def acc2taxid(db, acc)
  doc = Nokogiri::XML( RemoteData.elink({:dbfrom=>db,
    :db=>"taxonomy", :id=>acc, :idtype=>"acc"}) )
  doc.at_xpath("/eLinkResult/LinkSet/LinkSetDb/Link/Id")
end
#================================[ Main ]
begin
  o[:accs] += File.readlines(o[:infile]).map{ |l| l.chomp } unless
    o[:infile].nil?
  o[:ranks].map!{ |r| r.downcase }
  puts (["Acc", "TaxId"] + o[:ranks].map{ |r| r.capitalize }).join("\t") if
    o[:header]
  o[:accs].each do |acc|
    taxid = acc2taxid(o[:dbfrom], acc)
    status = ""
    if taxid.nil?
      warn "Cannot find link to taxonomy: #{acc} #{status}"
      puts ([acc, ""] + o[:ranks].map{ |i| "" }).join("\t") unless o[:no_nil]
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
    puts ([acc, taxid.content] +
      o[:ranks].map{ |rank| taxonomy[ rank ] ||= "" }).join("\t")
  end
rescue => err
  $stderr.puts "Exception: #{err}\n\n"
  err.backtrace.each { |l| $stderr.puts l + "\n" }
  err
end
