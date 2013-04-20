#!/usr/bin/ruby -w

#
# @author  Luis M. Rodriguez-R <lmrodriguezr at gmail dot com>
# @update  Apr-20-2013
# @license artistic 2.0
#

require 'optparse'

o = {:quiet=>FALSE, :model=>TRUE}

OptionParser.new do |opts|
   opts.banner = "
Extracts the sequence IDs and query model form a (multiple) HMMsearch report (for HMMer 3.0).

Usage: #{$0} [options] < input.hmmsearch > list.txt"
   opts.separator ""
   opts.separator "Options"
   opts.on("-E", "--all-evalue FLOAT", "Maximum e-value of sequence to report result."){|v| o[:all_evalue]=v }
   opts.on("-S", "--all-score FLOAT", "Minimum score of sequence to report result."){|v| o[:all_score]=v }
   opts.on("-e", "--best-evalue FLOAT", "Maximum e-value of best domain to report result."){|v| o[:best_evalue]=v }
   opts.on("-s", "--best-score FLOAT", "Minimum score of best domain to report result."){|v| o[:best_score]=v }
   opts.on("-n", "--no-model", "Do not include the query model in the output list."){ o[:model]=FALSE }
   opts.on("-q", "--quiet", "Run quietly."){ o[:quiet]=TRUE }
   opts.on("-h", "--help", "Display this screen.") do
      puts opts
      exit
   end
   opts.separator ""
end.parse!

at = :header
query = ""
ARGF.each_line do |ln|
   next unless /^(#.*|\s+)$/.match(ln).nil?
   ln.chomp!
   case at
   when :header
      qm = /Query:\s+(.*?)\s+/.match(ln)
      qm.nil? or query=qm[1]
      at = :list unless /^[\-\s]+$/.match(ln).nil?
   when :list
      if /^\s+$/.match(ln).nil?
         row = ln.split(/\s+/)
	 raise "Unable to parse seemingly malformed list of hits in line #{$.}:\n#{ln}" unless row.length==11
	 good = TRUE
	 good and good = ( o[:all_evalue].nil? || row[1]<=o[:all_evalue] )
	 # TODO The rest of the filtering
	 good and puts row[9]+(o[:model]?"\t#{query}":"")+"\n"
      else
         at = :align
      end
   when :align
      at = :header unless /^\/\/$/.match(ln).nil?
   end
end

