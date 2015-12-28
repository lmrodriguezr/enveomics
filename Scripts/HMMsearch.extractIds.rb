#!/usr/bin/env ruby

#
# @author  Luis M. Rodriguez-R <lmrodriguezr at gmail dot com>
# @update  Dec-01-2015
# @license artistic 2.0
#

require "optparse"

o = {quiet:false, model:true}

OptionParser.new do |opts|
   opts.banner = "
Extracts the sequence IDs and query model form a (multiple) HMMsearch report
(for HMMer 3.0).

Usage: #{$0} [options] < input.hmmsearch > list.txt"
   opts.separator ""
   opts.separator "Options"
   opts.on("-E", "--all-evalue FLOAT",
      "Maximum e-value of sequence to report result."
      ){|v| o[:all_evalue] = v.to_f }
   opts.on("-S", "--all-score FLOAT",
      "Minimum score of sequence to report result."
      ){|v| o[:all_score] = v.to_f }
   opts.on("-e", "--best-evalue FLOAT",
      "Maximum e-value of best domain to report result."
      ){|v| o[:best_evalue] = v.to_f }
   opts.on("-s", "--best-score FLOAT",
      "Minimum score of best domain to report result."
      ){|v| o[:best_score] = v.to_f }
   opts.on("-n", "--no-model",
      "Do not include the query model in the output list."){ o[:model]=false }
   opts.on("-q", "--quiet", "Run quietly."){ o[:quiet]=true }
   opts.on("-h", "--help", "Display this screen.") do
      puts opts
      exit
   end
   opts.separator ""
end.parse!

at = :header
query = ""
i = 0
ARGF.each_line do |ln|
   next unless /^(#.*)$/.match(ln).nil?
   ln.chomp!
   case at
   when :header
      qm = /Query:\s+(.*?)\s+/.match(ln)
      qm.nil? or query=qm[1]
      unless /^[\-\s]+$/.match(ln).nil?
         at = :list
	 i  = 0
	 STDERR.print "Parsing hits against #{query}: " unless o[:quiet]
      end
   when :list
      if /^\s*$/.match(ln).nil?
         next if ln =~ /^\s*-+ inclusion threshold -+$/
	 ln.gsub!(/#.*/,"")
	 row = ln.split(/\s+/)
	 row << nil if row.count==10
	 raise "Unable to parse seemingly malformed list of hits in line " +
	    "#{$.}:\n#{ln}" unless row.count==11
	 good   = true
	 good &&= ( o[:all_evalue].nil? || row[1].to_f <= o[:all_evalue] )
	 good &&= ( o[:all_score].nil? || row[2].to_f >= o[:all_score] )
	 good &&= ( o[:best_evalue].nil? || row[4].to_f <= o[:best_evalue] )
	 good &&= ( o[:best_score].nil? || row[5].to_f >= o[:best_score] )
	 if good
	    puts row[9]+(o[:model]?"\t#{query}":"")
	    i+=1
	 end
      else
         at = :align
         STDERR.puts "#{i} results." unless o[:quiet]
      end
   when :align
      at = :header unless /^\/\/$/.match(ln).nil?
   end
end

