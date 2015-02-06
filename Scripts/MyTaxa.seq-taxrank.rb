#!/usr/bin/env ruby

#
# @author Luis M. Rodriguez-R <lmrodriguezr at gmail dot com>
# @update: Feb-06-2015
# @license artistic license 2.0
#

require 'optparse'

opts = {:rank=>'genus', :quiet=>FALSE}
ARGV << '-h' if ARGV.size==0
OptionParser.new do |opt|
   opt.separator "Generates a simple tabular file with the classification of each sequence at a given taxonomic rank from a MyTaxa output."
   opt.separator ""
   opt.on("-i", "--mytaxa FILE", "Input MyTaxa file."){ |v| opts[:mytaxa]=v }
   opt.on("-r", "--rank STR", "Taxonomic rank.  By default: #{opts[:rank]}."){ |v| opts[:rank] = v.downcase }
   opt.on("-q","--quiet","Run quietly.") { opts[:quiet]=TRUE }
   opt.on("-h","--help","Display this screen.") do
      puts opt
      exit
   end
   opt.separator ""
end.parse!
abort "-i/--mytaxa is mandatory." if opts[:mytaxa].nil?
abort "-i/--mytaxa must exist." unless File.exists? opts[:mytaxa]

begin
   f = File.open(opts[:mytaxa], "r")
   ctg = nil;
   while(ln = f.gets)
      m = /^(.+)(\t.+){3}/.match(ln)
      if m
	 raise "Couldn't find classification for contig #{ctg}" unless ctg.nil?
	 ctg = m[1]
      else
	 raise "Couldn't find the contig name at line #{$.}" if ctg.nil?
	 m = /<#{opts[:rank]}>([^;]+)/.match(ln)
	 puts "#{ctg}\t#{m ? m[1] : "Unclassified"}"
	 ctg = nil
      end
   end
   f.close
rescue => err
   $stderr.puts "Exception: #{err}\n\n"
   err.backtrace.each { |l| $stderr.puts l + "\n" }
   err
end

