#!/usr/bin/env ruby

#
# @author  Luis M. Rodriguez-R <lmrodriguezr at gmail dot com>
# @update  Jun-23-2015
# @license artistic license 2.0
#

require 'optparse'

#================================[ Options parsing ]
$o = {	:q=>false, :ids=>[], :dbfrom=>'uniprotkb', :header=>true, :ret=>'ScientificName',
	:ranks=>%w(superkingdom phylum class order family genus species)}
ARGV << '-h' if ARGV.size==0
$eutils = 'http://eutils.ncbi.nlm.nih.gov/entrez/eutils'
begin
   require 'rubygems'
   require 'restclient'
   require 'nokogiri'
rescue LoadError
   abort "Unmet requirements, please install required gems:\n\ngem install rubygems\ngem install rest-client\ngem install nokogiri"
end
opts = OptionParser.new do |opt|
   opt.banner = "
Maps a list of EBI-supported IDs to their corresponding NCBI taxonomy using EBI RESTful API. Avoid using this script on
millions of entries at a time, since each entry elicits a request to EBI's servers and a request to NCBI's servers.

Usage: #{$0} [options]"
   opt.separator ""
   opt.on("-i", "--ids ID1,ID2,...", Array, "Comma-separated list of EBI IDs. Required unless -I is passed."){ |v| $o[:ids]=v }
   opt.on("-I", "--infile FILE", "Raw text file containing the list of EBI IDs, one per line. Required unless -i is passed."){ |v| $o[:infile]=v }
   opt.on("-d", "--database DB", "EBI database defining the EBI IDs. By default: #{$o[:dbfrom]}."){ |v| $o[:dbfrom]=v }
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
   response = nil
   (1 .. 5).each do |i|
      response = RestClient.get "#{$eutils}/#{script}", {:params=>params}
      break if response.code == 200
   end
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
def ebiFetch(db, id, format, outfile=nil)
   url = "http://www.ebi.ac.uk/Tools/dbfetch/dbfetch/#{db}/#{id}/#{format}"
   response = RestClient::Request.execute(:method=>:get,  :url=>url, :timeout=>600)
   raise "Unable to reach EBI REST client, error code #{response.code}." unless response.code == 200
   response.to_s
end
def seq2taxid(id, db)
   doc = ebiFetch(db, id, 'annot').split(/[\n\r]/)
   ln = doc.grep(/^FT\s+\/db_xref="taxon:/).first
   ln = doc.grep(/^OX\s+NCBI_TaxID=/).first if ln.nil?
   return nil if ln.nil?
   ln.sub!(/.*(?:"taxon:|NCBI_TaxID=)(\d+)["; ].*/, "\\1")
   return nil unless ln =~ /^\d+$/
   ln
end


#================================[ Main ]
begin
   $o[:is] += File.readlines($o[:infile]).map{ |l| l.chomp } unless $o[:infile].nil?
   $o[:ranks].map!{ |r| r.downcase }
   puts (["ID", "TaxId"] + $o[:ranks].map{ |r| r.capitalize }).join("\t") if $o[:header]
   $o[:ids].each do |id|
      taxid = seq2taxid(id, $o[:dbfrom])
      if taxid.nil?
	 warn "Cannot find link to taxonomy: #{id}"
	 next
      end
      taxonomy = {}
      unless taxid.nil?
	 doc = Nokogiri::XML( efetch({:db=>'taxonomy', :id=>taxid}) )
	 taxonomy[ doc.at_xpath("/TaxaSet/Taxon/Rank").content ] = doc.at_xpath("/TaxaSet/Taxon/#{$o[:ret]}").content
	 doc.xpath("/TaxaSet/Taxon/LineageEx/Taxon").each do |taxon|
	    taxonomy[ taxon.at_xpath("./Rank").content ] = taxon.at_xpath("./#{$o[:ret]}").content
	 end
      end
      puts ([id, taxid] + $o[:ranks].map{ |rank| taxonomy[ rank ] ||= '' }).join("\t")
   end
rescue => err
   $stderr.puts "Exception: #{err}\n\n"
   err.backtrace.each { |l| $stderr.puts l + "\n" }
   err
end

