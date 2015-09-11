#!/usr/bin/env ruby

#
# @author: Luis M. Rodriguez-R
# @update: Sep-11-2015
# @license: artistic license 2.0
#

$:.push File.expand_path(File.dirname(__FILE__) + "/lib")
require 'enveomics_rb/og'
require 'optparse'
require 'tmpdir'

o = {q:false, f:"(\\S+)-(\\S+)\\.rbm", mcl:"", inflation:1.5, blind:false,
   evalue:false, thr:2, identity:false, bestmatch:false}
ARGV << "-h" if ARGV.size==0
OptionParser.new do |opts|
   opts.banner = "
Identifies Orthology Groups (OGs) in Reciprocal Best Matches (RBM)
between all pairs in a collection of genomes, using the Markov Cluster
Algorithm.

Requires MCL (see http://www.micans.org/mcl).

Usage: #{$0} [options]"
   opts.separator ""
   opts.separator "Mandatory"
   opts.on("-o", "--out FILE",
      "Output file containing the detected OGs."){ |v| o[:out]=v }
   opts.on("-d", "--dir DIR",
      "Directory containing the RBM files.",
      "Becomes optional iff --abc is set to a non-empty file."){ |v| o[:dir]=v }
   opts.separator ""
   opts.separator "Other Options"
   opts.on("-f", "--format STRING",
      "Format of the filenames for the RBM files (within -d), using regex " +
      "syntax.", "By default: '#{o[:f]}'."){ |v| o[:f]=v }
   opts.on("-I", "--inflation FLOAT",
      "Inflation parameter for MCL clustering. By default: #{o[:inflation]}."
      ){ |v| o[:inflation]=v.to_f }
   opts.on("-b", "--blind",
      "If set, computes clusters without taking bitscore into account."
      ){ |v| o[:blind]=v }
   opts.on("-e", "--evalue",
      "If set, uses the e-value to weight edges, instead of the default " +
      "Bit-Score."){ |v| o[:evalue]=v }
   opts.on("-i", "--identity",
      "If set, uses the identity to weight edges, instead of the default " +
      "Bit-Score."){ |v| o[:identity]=v }
   opts.on("-B", "--best-match",
      "If set, it assumes best-matches instead reciprocal best matches."
      ){ |v| o[:bestmatch]=v }
   opts.on("-m", "--mcl-bin DIR",
      "Path to the directory containing the mcl binaries.",
      "By default, assumed to be in the PATH."){ |v| o[:mcl]=v+"/" }
   opts.on("--abc FILE",
      "Use this abc file instead of a temporal file."){ |v| o[:abc] = v }
   opts.on("-t", "--threads INT",
      "Number of threads to use. By default: #{o[:thr]}."){ |v| o[:thr]=v.to_i }
   opts.on("-q", "--quiet", "Run quietly (no STDERR output)."){ o[:q] = true }
   opts.on("-h", "--help", "Display this screen.") do
      puts opts
      exit
   end
   opts.separator ""
end.parse!
abort "-o is mandatory" if o[:out].nil?
o[:evalue] = false if o[:identity]
o[:evalue] = false if o[:blind]
o[:identity] = false if o[:blind]

##### MAIN:
begin
   Dir.mktmpdir do |dir|
      o[:abc] = "#{dir}/rbms.abc" if o[:abc].nil?
      abort "-d must exist and be a directory" unless
	 File.size?(o[:abc]) or
	 (!o[:dir].nil? and File.exists?(o[:dir]) and File.directory?(o[:dir]))
      # Traverse the whole directory
      if File.size? o[:abc]
	 $stderr.puts "Reusing existing abc file '#{o[:abc]}'." unless o[:q]
      else
	 file_i = 0
	 ln_i = 0
	 $stderr.puts "Reading RBM files within '#{o[:dir]}'." unless o[:q]
	 abc = File.open(o[:abc] + ".tmp", "w")
	 Dir.entries(o[:dir]).each do |rbm_file|
	    next unless File.file?(o[:dir]+"/"+rbm_file)
	    # Parse the filename to identify the genomes
	    m = /#{o[:f]}/.match(rbm_file)
	    if m.nil? or m[2].nil?
	       warn "Ignoring #{rbm_file}: doesn't match /#{o[:f]}/."
	       next
	    end
	    file_i += 1
	    # Read the RBMs list
	    f = File.open(o[:dir]+"/"+rbm_file, "r")
	    while ln = f.gets
	       # Add the RBM to the abc file
	       row = ln.split(/\t/)
	       abc.puts [m[1]+">"+row[0], m[2]+">"+row[1],
		  (o[:blind] ? "1" :
		  (o[:evalue] ? row[10] :
		  (o[:identity] ? row[2] : row[11])))].join("\t")
	       ln_i += 1
	    end
	    f.close
	    $stderr.print " Scanned files: #{file_i}. " +
	       "Found RBMs: #{ln_i}.   \r" unless o[:q]
	 end
	 abc.close
	 File.rename(o[:abc] + ".tmp", o[:abc])
	 $stderr.print "\n" unless o[:q]
      end # if File.size? o[:abc] ... else

      # Build .mci file (mcxload) and compute .mccl file (mcl)
      $stderr.puts "Markov-Clustering" unless o[:q]
      `'#{o[:mcl]}mcxload' #{"--stream-mirror" unless o[:bestmatch]} \
	 -abc '#{o[:abc]}' -o '#{dir}/rbms.mci' --write-binary \
	 -write-tab '#{dir}/genes.tab' #{"--stream-neg-log10" if o[:evalue]} \
	 &>/dev/null`
      `'#{o[:mcl]}mcl' '#{dir}/rbms.mci' -V all -I #{o[:inflation].to_s} \
	 -o '#{dir}/ogs.mcl' -te #{o[:thr].to_s}`

      # Load .tab as Gene objects
      $stderr.puts "Loading gene table from '#{dir}/genes.tab'." unless o[:q]
      genes = []
      tab = File.open("#{dir}/genes.tab", "r")
      while ln = tab.gets
	 ln.chomp!
	 r = ln.split /\t|>/
	 genes[ r[0].to_i ] = Gene.new(r[1], r[2])
      end
      tab.close
      $stderr.puts " Got " + genes.size.to_s + " genes in " +
	 Gene.genomes.size.to_s + " genomes." unless o[:q]
      
      # Load .mcl file as OGCollection
      $stderr.puts "Loading clusters from '#{dir}/ogs.mcl'." unless o[:q]
      collection = OGCollection.new
      mcl = File.open("#{dir}/ogs.mcl", "r")
      in_matrix = false
      my_genes = nil
      while ln = mcl.gets
         ln.chomp!
	 if ln =~ /^\(mclmatrix$/
	    in_matrix = true
	    next
	 end
	 next if ln =~ /^begin$/
	 if in_matrix
	    break if ln =~ /^\)$/
	    if ln =~ /^\d+\s+/
	       ln.sub!(/^\d+\s+/, "")
	       my_genes = []
	    end
	    ln.sub!(/^\s+/, "")
	    raise "Incomplete mcl matrix, offending line: #{$.}: #{ln}" if
	       my_genes.nil?
	    my_genes += ln.split(/\s/)
	    if my_genes.last == "$"
	       my_genes.pop
	       og = OG.new
	       my_genes.each{|i| og << genes[ i.to_i ]}
	       collection << og
	       my_genes = nil
	    end
	 end
      end
      mcl.close
      $stderr.puts " Got #{collection.ogs.size} clusters." unless o[:q]
      
      # Save the output matrix
      $stderr.puts "Saving matrix into '#{o[:out]}'." unless o[:q]
      f = File.open(o[:out], "w")
      f.puts collection.to_s
      f.close
      $stderr.puts "Done.\n" unless o[:q] 
   end
rescue => err
   $stderr.puts "Exception: #{err}\n\n"
   err.backtrace.each { |l| $stderr.puts l + "\n" }
   err
end


