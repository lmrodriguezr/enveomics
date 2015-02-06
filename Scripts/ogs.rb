#!/usr/bin/env ruby

#
# @author: Luis M. Rodriguez-R
# @update: Feb-06-2015
# @license: artistic license 2.0
#

require 'optparse'

o = {:q=>FALSE, :f=>"(\\S+)-(\\S+)\\.rbm", :consolidate=>TRUE, :pre=>[]}
ARGV << '-h' if ARGV.size==0
OptionParser.new do |opts|
   opts.banner = "
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

##### CLASSES:
# Gene.new(genome, id): Initializes a new Gene.
# genome: A string uniquely identifying the parent genome.
# id: A string uniquely identifying the gene within the genome. It can be non-unique across genomes.
class Gene
   attr_reader :genome_id, :id
   @@genomes = []
   def self.genomes
      @@genomes
   end
   def initialize(genome, id)
      if genome.is_a? Integer
         abort "Internal error: Genome #{genome} does not exist yet." if @@genomes[genome].nil?
	 @genome_id = genome
      else
	 @@genomes << genome unless @@genomes.include? genome
	 @genome_id = @@genomes.index(genome)
      end
      @id = id
   end
   # Compare if two Gene objects refer to the same gene.
   def ==(b)
      self.genome_id==b.genome_id and self.id==b.id
   end
   # Get all genomes in the run as an array of strings.
   def genome
      @@genomes[self.genome_id]
   end
   def to_s
      "#{self.genome}:#{self.id}"
   end
end

# OG.new(): Initializes an empty OG.
# OG.new(genomes, genes): Initializes a pre-computed OG.
# genomes: List of genomes as an array of strings (as in Gene.genomes).
# genes: List of genes as an array of strings, with '-' indicating no genes and multiple genes separated by ','.
class OG
   attr_reader :genes
   def initialize(genomes=nil, genes=nil)
      @genes = []
      unless genomes.nil? or genes.nil?
	 (0 .. genes.length-1).each do |genome_i|
	    next if genes[genome_i]=="-"
	    genes[genome_i].split(/,/).each do |gene_id|
	       self << Gene.new(genomes[genome_i], gene_id)
	    end
	 end
      end
   end
   # Add genes or combine another OG into the loaded OG (self).
   def <<(obj)
      if obj.is_a? Gene
	 @genes[obj.genome_id] = [] if @genes[obj.genome_id].nil?
	 @genes[obj.genome_id] << obj.id unless self.include? obj
      elsif obj.is_a? OG
	 obj.genes_obj.each{ |gene| self << gene }
      else
	 abort "Unsupported class for #{obj}"
      end
   end
   # Get the list of genes as objects (internally saved as strings to save RAM).
   def genes_obj
      o = []
      (0 .. Gene.genomes.length-1).map do |genome_id|
         o += self.genes[genome_id].map{ |gene_id| Gene.new(Gene.genomes[genome_id], gene_id) } unless self.genes[genome_id].nil?
      end
      return o
   end
   # Evaluates if the OG contains the passed gene.
   def include?(gene)
      return false if self.genes[gene.genome_id].nil?
      self.genes[gene.genome_id].include? gene.id
   end
   def to_s
      (0 .. Gene.genomes.length-1).map do |genome_id|
	 self.genes[genome_id].nil? ? "-" : self.genes[genome_id].join(",")
      end.join("\t")
   end
end

# OGCollection.new(): Initializes an empty collection of OGs.
class OGCollection
   attr_reader :ogs
   def initialize
      @ogs = []
   end
   # Add an OG to the collection
   def <<(og)
      @ogs << og
   end
   # Compare OGs all-vs-all to identify groups that should be merged.
   def consolidate!
      old_ogs = self.ogs
      @ogs = []
      old_ogs.each do |og|
	 is_new = true
	 og.genes_obj.each do |gene|
	    o = self.get_og gene
	    unless o.nil?
	       o << og
	       is_new = false
	       break
	    end
	 end
	 self << og if is_new
      end
   end
   # Add a pair of RBM genes into the corresponding OG, or create a new OG.
   def add_rbm(a, b)
      og = self.get_og(a)
      og = self.get_og(b) if og.nil?
      if og.nil?
	 og = OG.new
	 @ogs << og
      end
      og << a
      og << b
   end
   # Get the OG containing the gene (returns the first, if multiple).
   def get_og(gene)
      idx = self.ogs.index { |og| og.include? gene }
      idx.nil? ? nil : self.ogs[idx]
   end
   def to_s
      Gene.genomes.join("\t") + "\n" + self.ogs.map{ |og| og.to_s }.join("\n")
   end
end

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


