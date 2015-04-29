#!/usr/bin/env ruby

#
# @author: Luis M. Rodriguez-R
# @update: Apr-29-2015
# @license: artistic license 2.0
#

$:.push File.expand_path(File.dirname(__FILE__) + '/lib')
require 'enveomics_rb/og'
require 'optparse'
require 'tmpdir'

o = {:q=>FALSE, :f=>"(\\S+)-(\\S+)\\.rbm", :mcl=>"", :I=>1.5, :blind=>FALSE, :evalue=>FALSE, :thr=>2}
ARGV << '-h' if ARGV.size==0
OptionParser.new do |opts|
   opts.banner = "
Identifies Orthology Groups (OGs) in Reciprocal Best Matches (RBM)
between all pairs in a collection of genomes, using the Markov Cluster
Algorithm. It requires mcl (see http://www.micans.org/mcl).

Usage: #{$0} [options]"
   opts.separator ""
   opts.separator "Mandatory"
   opts.on("-o", "--out FILE", "Output file containing the detected OGs."){ |v| o[:out]=v }
   opts.on("-d", "--dir DIR", "Directory containing the RBM files."){ |v| o[:dir]=v }
   opts.separator ""
   opts.separator "Other Options"
   opts.on("-f", "--format STRING", "Format of the filenames for the RBM files (within -d), using regex syntax. By default: '#{o[:f]}'."){ |v| o[:f]=v }
   opts.on("-I", "--inflation FLOAT", "Inflation parameter for MCL clustering. By default: #{o[:I]}."){ |v| o[:I]=v.to_f }
   opts.on("-b", "--blind", "If set, computes clusters without taking bitscore into account."){ |v| o[:blind]=v }
   opts.on("-e", "--evalue", "If set, uses the e-value to weight edges, instead of the default Bit-Score."){ |v| o[:evalue]=v }
   opts.on("-m", "--mcl-bin DIR", "Path to the directory containing the mcl binaries. By default, assumed to be in the PATH."){ |v| o[:mcl]=v+"/" }
   opts.on("-t", "--threads INT", "Number of threads to use. By default: #{o[:thr]}."){ |v| o[:thr]=v.to_i }
   opts.on("-q", "--quiet", "Run quietly (no STDERR output)."){ o[:q] = TRUE }
   opts.on("-h", "--help", "Display this screen.") do
      puts opts
      exit
   end
   opts.separator ""
end.parse!
abort "-o is mandatory" if o[:out].nil?
abort "-d is mandatory" if o[:dir].nil?

##### MAIN:
begin
   Dir.mktmpdir do |dir|
      # Read the pre-computed OGs (if -p is passed).`
      #o[:pre].each do |pre|
      #   $stderr.puts "Reading pre-computed OGs in '#{pre}'." unless o[:q]
      #   f = File.open(pre, 'r')
      #   h = f.gets.chomp.split /\t/
      #   while ln = f.gets
   #	 collection << OG.new(h, ln.chomp.split(/\t/))
   #      end
   #      f.close
   #      $stderr.puts " Loaded OGs: #{collection.ogs.length}." unless o[:q]
      #end
      # Read the RBM files in the directory (if -d is passed)
      abort "-d must exist and be a directory" unless File.exists?(o[:dir]) and File.directory?(o[:dir])
      # Traverse the whole directory
      file_i = 0
      ln_i = 0
      $stderr.puts "Reading RBM files within '#{o[:dir]}'." unless o[:q] 
      abc = File.open("#{dir}/rbms.abc", "w")
      Dir.entries(o[:dir]).each do |rbm_file|
	 next unless File.file?(o[:dir]+"/"+rbm_file)
	 # Parse the filename to identify the genomes
	 m = /#{o[:f]}/.match(rbm_file)
	 if m.nil? or m[2].nil?
	    warn "Cannot parse filename: #{rbm_file} (doesn't match /#{o[:f]}/)."
	    next
	 end
	 file_i += 1
	 # Read the RBMs list
	 f = File.open(o[:dir]+"/"+rbm_file, "r")
	 while ln = f.gets
	    # Add the RBM to the abc file
	    row = ln.split(/\t/)
	    abc.puts [m[1]+">"+row[0], m[2]+">"+row[1], (o[:blind] ? "1" : (o[:evalue] ? row[10] : row[11]))].join("\t")
	    ln_i += 1
	 end
	 f.close
	 $stderr.print " Scanned files: #{file_i}. Found RBMs: #{ln_i}.   \r" unless o[:q]
      end
      abc.close
      $stderr.print "\n" unless o[:q]

      # Build .mci file (mcxload) and compute .mccl file (mcl)
      $stderr.puts "Markov-Clustering" unless o[:q]
      `'#{o[:mcl]}mcxload' --stream-mirror -abc '#{dir}/rbms.abc' -o '#{dir}/rbms.mci' --write-binary -write-tab '#{dir}/genes.tab' #{(!o[:blind] and o[:evalue]) ? "--stream-neg-log10" : ""} &>/dev/null`
      `'#{o[:mcl]}mcl' '#{dir}/rbms.mci' -V all -I #{o[:I].to_s} -o '#{dir}/ogs.mcl' -te #{o[:thr].to_s}`

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
      $stderr.puts " Got #{genes.size} genes in #{Gene.genomes.size} genomes." unless o[:q]
      
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
	       ln.sub! /^\d+\s+/, ''
	       my_genes = []
	    end
	    ln.sub! /^\s+/, ''
	    raise "Incomplete mcl matrix, offending line: #{$.}: #{ln}" if my_genes.nil?
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


