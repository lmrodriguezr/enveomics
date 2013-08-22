#!/usr/bin/ruby

#
# @author: Luis M. Rodriguez-R
# @update: Aug-17-2013
# @license: artistic license 2.0
#

require 'optparse'
require 'tmpdir'

o = {:len=>0, :id=>0, :score=>0, :q=>FALSE, :bin=>'', :program=>'blast+', :thr=>1, :nucl=>FALSE}
OptionParser.new do |opts|
   opts.banner = "
Finds the reciprocal best matches between two sets of sequences.

Usage: #{$0} [options]"
   opts.separator ""
   opts.separator "Mandatory"
   opts.on("-1", "--seq1 FILE", "Path to the FastA file containing the set 1."){ |v| o[:seq1] = v }
   opts.on("-2", "--seq2 FILE", "Path to the FastA file containing the set 2."){ |v| o[:seq2] = v }
   opts.separator ""
   opts.separator "Search Options"
   opts.on("-n", "--nucl", "Sequences are assumed to be nucleotides (proteins by default)."){ |v| o[:nucl] = TRUE }
   opts.on("-l", "--len INT", "Minimum alignment length (in residues).  By default: #{o[:len].to_s}."){ |v| o[:len] = v.to_i }
   opts.on("-i", "--id NUM", "Minimum alignment identity (in %).  By default: #{o[:id].to_s}."){ |v| o[:id] = v.to_f }
   opts.on("-s", "--score NUM", "Minimum alignment score (in bits).  By default: #{o[:score].to_s}."){ |v| o[:score] = v.to_f }
   opts.separator ""
   opts.separator "Software Options"
   opts.on("-b", "--bin DIR", "Path to the directory containing the binaries of the search program."){ |v| o[:bin] = v }
   opts.on("-p", "--program STR", "Search program to be used.  One of: blast+ (default), blast."){ |v| o[:program] = v }
   opts.on("-t", "--threads INT", "Number of parallel threads to be used.  By default: #{o[:thr]}."){ |v| o[:thr] = v.to_i }
   opts.separator ""
   opts.separator "Other Options"
   opts.on("-q", "--quiet", "Run quietly (no STDERR output)"){ o[:q] = TRUE }
   opts.on("-h", "--help", "Display this screen") do
      puts opts
      exit
   end
   opts.separator ""
end.parse!
abort "-1 is mandatory" if o[:seq1].nil?
abort "-2 is mandatory" if o[:seq2].nil?
o[:bin] = o[:bin]+"/" if o[:bin].size > 0

Dir.mktmpdir do |dir|
   $stderr.puts "Temporal directory: #{dir}." unless o[:q]

   # Create databases.
   $stderr.puts "Creating databases." unless o[:q]
   [:seq1, :seq2].each do |seq|
      case o[:program].downcase
      when "blast"
         `"#{o[:bin]}formatdb" -i "#{o[seq]}" -n "#{dir}/#{seq.to_s}" -p #{(o[:nucl]?'F':'T')}`
      when "blast+"
         `"#{o[:bin]}makeblastdb" -in "#{o[seq]}" -out "#{dir}/#{seq.to_s}" -dbtype #{(o[:nucl]?'nucl':'prot')}`
      else
         abort "Unsupported program: #{o[:program]}."
      end
   end # |seq|

   # Best-hits.
   rbh = {}
   n2 = 0
   $stderr.puts " Running comparisons." unless o[:q]
   [2,1].each do |i|
      q = o[:"seq#{i}"]
      s = "#{dir}/seq#{i==1?2:1}"
      $stderr.puts "  Query: #{q}." unless o[:q]
      case o[:program].downcase
      when "blast"
	 `"#{o[:bin]}blastall" -p #{o[:nucl]?'blastn':'blastp'} -d "#{s}" -i "#{q}" \
	 -v 1 -b 1 -a #{o[:thr]} -m 8 -o "#{dir}/#{i}.tab"`
      when "blast+"
	 `"#{o[:bin]}#{o[:nucl]?'blastn':'blastp'}" -db "#{s}" -query "#{q}" \
	 -max_target_seqs 1 \
	 -num_threads #{o[:thr]} -outfmt 6 -out "#{dir}/#{i}.tab"`
      else
	 abort "Unsupported program: #{o[:program]}."
      end
      fh = File.open("#{dir}/#{i}.tab", "r")
      n = 0
      fh.each_line do |ln|
	 ln.chomp!
	 row = ln.split(/\t/)
	 if row[3].to_i >= o[:len] and row[2].to_f >= o[:id] and row[12].to_f >= o[:score]
	    n += 1
	    if i==2
	       rbh[ row[0] ] = row[1]
	    else
	       if !rbh[ row[1] ].nil? and rbh[ row[1] ]==row[0]
		  puts ln
		  n2 += 1
	       end
	    end
	 end
      end # |ln|
      fh.close()
      $stderr.puts "    #{n} sequences with hit." unless o[:q]
   end # |i|
   $stderr.puts "  #{n2} RBMs." unless o[:q]
end # |dir|



