#!/usr/bin/ruby

#
# @author: Luis M. Rodriguez-R
# @update: Aug-21-2013
# @license: artistic license 2.0
#

require 'optparse'
require 'rubygems'
require 'restclient'
require 'open-uri'
require 'JSON'

o = {:q=>FALSE, :url=>'http://api.metagenomics.anl.gov/m5nr', :max=>0}
OptionParser.new do |opts|
   opts.banner = "
Downloads a set of sequences from M5nr with a given functional annotation.

Usage: #{$0} [options]"
   opts.separator ""
   opts.separator "Mandatory"
   opts.on("-f", "--function STR", "Functional annotation."){ |v| o[:function] = v }
   opts.separator ""
   opts.separator "Options"
   opts.on("-m", "--max INT", "Maximum number of sequences to download.  By default: all (0)."){ |v| o[:max] = v.to_i }
   opts.on("-n", "--url STR", "URL for M5nr API.  By default: #{o[:url]}."){ |v| o[:url] = v }
   opts.on("-o", "--out FILE", "File containing the sequences.  By default: value of -f appended with .fa."){ |v| o[:out] = v }
   opts.on("-q", "--quiet", "Run quietly (no STDERR output)"){ o[:q] = TRUE }
   opts.on("-h", "--help", "Display this screen") do
      puts opts
      exit
   end
   opts.separator ""
end.parse!
abort "-f is mandatory" if o[:function].nil?
o[:out] = "#{o[:function].gsub(/ /,'_')}.fa" if o[:out].nil?
uri_fun = URI::encode(o[:function])


of = File.open(o[:out], "w")
next_url = "#{o[:url]}/function/#{uri_fun}"
i = 0
loop do
   $stderr.print "Downloading sequence #{i+1}.   \r" unless o[:q]
   res_fun = RestClient.get next_url
   abort "Unable to reach MG-RAST M5nr API, error code #{res_fun.code}." unless res_fun.code == 200
   fun = JSON.parse(res_fun.to_str)
   fun["data"].each do |datum|
      res_seq = RestClient.get "#{o[:url]}/md5/#{datum["md5"]}", {:params=>{:sequence=>1}}
      abort "Unable to reach MG-RAST M5nr API, error code #{res_seq.code}." unless res_seq.code == 200
      seq = JSON.parse(res_seq.to_str)
      of.puts ">#{datum["source"]}:#{datum["accession"]} #{datum["function"]} [#{datum["organism"]} taxid:#{datum["ncbi_tax_id"]}]"
      of.puts seq["data"]["sequence"].scan(/.{80}|.+/).map{ |x| x.strip }.join($/)
      i += 1
      break if o[:max]>0 and i >= o[:max]
   end # |datum|
   next_url = fun["next"]
   break if next_url.nil? or (o[:max] > 0 and i >= o[:max])
end
of.close

$stderr.puts "Downloaded #{i} sequences." unless o[:q]

