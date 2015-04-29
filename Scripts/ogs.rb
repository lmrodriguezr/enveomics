#!/usr/bin/env ruby

#
# @author: Luis M. Rodriguez-R
# @update: Apr-29-2015
# @license: artistic license 2.0
#

$:.push File.expand_path(File.dirname(__FILE__) + '/lib')
require 'enveomics_rb/og'
require 'optparse'

o = {:q=>FALSE, :f=>"(\\S+)-(\\S+)\\.rbm", :consolidate=>TRUE, :pre=>[]}
ARGV << '-h' if ARGV.size==0
OptionParser.new do |opts|
   opts.banner = "
***IMPORTANT NOTE***
This script suffers from chaining effect and is very sensitive to spurious connections,
because it applies a greedy clustering algorithm. For most practical purposes, the use
of this script is discouraged and `ogs.mcl.rb` should be preferred. [ Apr-29-2015 ]

Identifies Orthology Groups (OGs) in Reciprocal Best Matches (RBM)
between all pairs in a collection of genomes.

Usage: #{$0} [options]"
   opts.separator ""
   opts.separator "Mandatory"
   opts.on("-o", "--out FILE", "Output file containing the detected OGs."){ |v| o[:out]=v }
   opts.separator ""
   opts.separator "Other Options"
   opts.on("-d", "--dir DIR", "Directory containing the RBM files."){ |v| o[:dir]=v }
   opts.on("-p", "--pre-ogs FILE1,FILE2,...", Array, "Pre-computed OGs file(s), separated by commas."){ |v| o[:pre]=v }
   opts.on("-n", "--unchecked", "Do not check internal redundancy in OGs."){ o[:consolidate]=FALSE }
   opts.on("-f","--format STRING", "Format of the filenames for the RBM files (within -d), using regex syntax. By default: '#{o[:f]}'."){ |v| o[:f]=v }
   opts.on("-q", "--quiet", "Run quietly (no STDERR output)."){ o[:q] = TRUE }
   opts.on("-h", "--help", "Display this screen.") do
      puts opts
      exit
   end
   opts.separator ""
end.parse!
abort "-o is mandatory" if o[:out].nil?

##### MAIN:
begin
   # Initialize the collection of OGs.
   collection = OGCollection.new
   # Read the pre-computed OGs (if -p is passed).
   o[:pre].each do |pre|
      $stderr.puts "Reading pre-computed OGs in '#{pre}'." unless o[:q]
      f = File.open(pre, 'r')
      h = f.gets.chomp.split /\t/
      while ln = f.gets
	 collection << OG.new(h, ln.chomp.split(/\t/))
      end
      f.close
      $stderr.puts " Loaded OGs: #{collection.ogs.length}." unless o[:q]
   end
   # Read the RBM files in the directory (if -d is passed).
   unless o[:dir].nil?
      abort "-d must exist and be a directory" unless File.exists?(o[:dir]) and File.directory?(o[:dir])
      # Traverse the whole directory.
      file_i = 0
      $stderr.puts "Reading RBM files within '#{o[:dir]}'." unless o[:q] 
      Dir.entries(o[:dir]).each do |rbm_file|
	 next unless File.file?(o[:dir]+"/"+rbm_file)
	 # Parse the filename to identify the genomes.
	 m = /#{o[:f]}/.match(rbm_file)
	 if m.nil? or m[2].nil?
	    warn "Cannot parse filename: #{rbm_file} (doesn't match /#{o[:f]}/)."
	    next
	 end
	 file_i += 1
	 # Read the RBMs list
	 f = File.open(o[:dir]+"/"+rbm_file, "r")
	 while ln = f.gets
	    # Add the RBM to the collection of OGs. Only the first two columns are used.
	    row = ln.split(/\t/)
	    collection.add_rbm( Gene.new(m[1],row[0]), Gene.new(m[2],row[1]) )
	 end
	 f.close
	 $stderr.print " Scanned files: #{file_i}. Found OGs: #{collection.ogs.length}.   \r" unless o[:q]
      end
      $stderr.print "\n" unless o[:q]
   end
   # Evaluate internal consistency merging linked OGs (unless -n is passed).
   if o[:consolidate]
      $stderr.puts "Evaluating internal consistency." unless o[:q] 
      collection.consolidate!
      $stderr.puts " Final OGs: #{collection.ogs.length}." unless o[:q]
   end
   # Save the output matrix
   $stderr.puts "Saving matrix into '#{o[:out]}'." unless o[:q]
   f = File.open(o[:out], "w")
   f.puts collection.to_s
   f.close
   $stderr.puts "Done.\n" unless o[:q] 
rescue => err
   $stderr.puts "Exception: #{err}\n\n"
   err.backtrace.each { |l| $stderr.puts l + "\n" }
   err
end


