#!/usr/bin/env ruby

#
# @author Luis M. Rodriguez-R <lmrodriguezr at gmail dot com>
# @update: Feb-06-2015
# @license artistic license 2.0
#

require 'optparse'

$opts = {:warns=>false}
ARGV << '-h' if ARGV.size==0
OptionParser.new do |opt|
   opt.separator "Re-formats Silva taxonomy into NCBI-like taxonomy dump files."
   opt.separator ""
   opt.separator "Mandatory arguments"
   opt.on("-k", "--silvaranks FILE", "Input Silva ranks file (e.g., tax_ranks_ssu_115.txt)."){ |v| $opts[:silvaranks]=v }
   opt.on("-f", "--silvaref FILE", "Input Silva ref alignment file (e.g., SSURef_NR99_115_tax_silva_full_align_trunc.fasta)."){ |v| $opts[:silvaref]=v }
   opt.separator ""
   opt.separator "Additional options"
   opt.on("-p", "--patch FILE", "If passed, it replaces the paths specified in the patch."){ |v| $opts[:patch]=v }
   opt.on("-s", "--seqinfo FILE", "If passed, it creates a CSV seq-info file compatible with taxtastic."){ |v| $opts[:seqinfo]=v }
   opt.on("-t", "--taxfile FILE", "If passed, it creates a simple TSV taxonomy file."){ |v| $opts[:taxfile]=v }
   opt.on("-n", "--ncbi FILE", "If passed, output folder for the NCBI dump files (e.g., taxdmp)."){ |v| $opts[:ncbi]=v }
   opt.on("-w", "--warns", "Verbously display warnings."){ $opts[:warns]=true }
   opt.on("-h", "--help","Display this screen") do
      puts opt
      exit
   end
   opt.separator ""
end.parse!
abort "-k/--silvaranks is mandatory." if $opts[:silvaranks].nil?
abort "-k/--silvaranks must exist." unless File.exists? $opts[:silvaranks]
abort "-f/--silvaref is mandatory." if $opts[:silvaref].nil?
abort "-f/--silvaref must exist." unless File.exists? $opts[:silvaref]

class Node
   attr_accessor :id, :tax, :leaf, :name_type
   attr_reader :name, :rank, :parent, :children
   def initialize(name, rank=nil)
      @name = name
      @rank = rank.nil? ? "no rank" : rank
      @children = []
      @leaf = false
      @name_type = "scientific name";
   end
   def parent=(node)
      @parent=node
      node.add_child(self)
   end
   def add_child(node)
      @children << node
   end
   def ncbirank
      ncbirank =
	 self.rank == "superkingdom" ? "no rank" :
	 self.rank == "domain" ? "superkingdom" :
	 self.rank == "major_clade" ? "no rank" : self.rank
      return ncbirank
   end
   def path
      if self.parent.nil?
         self.name
      else
         "#{self.parent.path};#{self.name}"
      end
   end
   def each_desc internals, leaves, &blk
      blk[self] if (leaves and self.leaf) or (internals and not self.leaf)
      self.children.each {|child| child.each_desc internals, leaves, &blk}
   end
   def to_s
      "#{self.name} (#{self.rank})"
   end
end

class Taxonomy
   attr_reader :root, :next_id
   def initialize
      @root = Node.new('root')
      @root.id = 1
      @next_id = 2
   end
   def register(node)
      node.id = self.next_id
      node.parent = self.root if node.parent.nil?
      @next_id += 1
   end
   def node(path)
      node = self.root
      path.each do |level|
         node.children.each do |child|
	    if child.name == level
	       node = child
	       break
	    end
	 end
	 unless node.name == level
	    $stderr.puts "Warning: Impossible to find #{level} at #{node.to_s}, making it up." if $opts[:warns]
	    child = Node.new(level)
	    child.parent = node
	    self.register(child)
	    node = child
	 end
      end
      node
   end
   def each_node &blk
      self.root.each_desc true, true, &blk
   end
   def each_leaf &blk
      self.root.each_desc false, true, &blk
   end
   def each_internal &blk
      self.root.each_desc true, false, &blk
   end
end

begin
   taxo = Taxonomy.new()
   
   ## Read patch
   patch = {}
   unless $opts[:patch].nil?
      $stderr.puts "Reading patch: #{$opts[:patch]}"
      f = File.open($opts[:patch], "r")
      while(ln = f.gets)
	 m = ln.chomp.split(/\t/)
	 patch[ m[0] ] = m[1]
      end
   end
   
   ## Read the Silva ranks
   $stderr.puts "Reading Silva ranks: #{$opts[:silvaranks]}"
   f = File.open($opts[:silvaranks], "r")
   f.gets # header
   while(ln = f.gets)
      m = ln.chomp.split(/\t/)
      m[0] = patch[ m[0] ] unless patch[ m[0] ].nil?
      p = m[0].split(/;/)
      raise "Inconsistent path and node name at line #{$.}: #{ln}." unless m[1] == p.pop
      if m[3] != "w"
	 node = Node.new(m[1], m[2])
	 node.name_type = "common name" if m[3] == "a"
	 node.parent = taxo.node(p)
	 taxo.register(node)
      end
   end
   f.close

   $stderr.puts "  Top taxa:"
   taxo.root.children.each do |top|
      $stderr.puts "    o #{top.to_s} has #{top.children.length} children."
   end

   ## Read the Silva ref alignment
   $stderr.puts "Reading Silva ref alignment: #{$opts[:silvaref]}"
   i = 0
   f = File.open($opts[:silvaref], "r")
   while(ln = f.gets)
      m = />([^\s]+)\s(.*)/.match(ln)
      next unless m
      # Patch
      pm = /(.+);([^;]+)/.match(m[2])
      path = "#{patch[ pm[1] ].nil? ? pm[1] : patch[ pm[1] ]};#{pm[2]}".split(/;/)
      # Register
      node = taxo.node(path)
      taxo.register(node)
      refseq = Node.new(m[1], 'refseq')
      refseq.parent = node
      refseq.leaf = true
      taxo.register(refseq)
      i += 1
   end
   f.close
   $stderr.puts "  Saved #{i} leaves."

   ### NCBI
   unless $opts[:ncbi].nil?
      ## Create taxonomy .dmp files
      $stderr.puts "Creating NCBI-like files: #{$opts[:ncbi]}"
      Dir.mkdir($opts[:ncbi]) unless Dir.exists?($opts[:ncbi]);
      # merged.dmp
      $stderr.puts "  o Creating merged.dmp"
      File.open(File.join($opts[:ncbi], 'merged.dmp'), 'w'){}
      # names.dmp
      $stderr.puts "  o Creating names.dmp"
      f = File.open(File.join($opts[:ncbi], 'names.dmp'), 'w')
      taxo.each_internal do |n|
	 f.puts [n.id, n.name, "", n.name_type].join("\t|\t")+"\t|"
      end
      f.close
      # nodes.dmp
      $stderr.puts "  o Creating nodes.dmp"
      f = File.open(File.join($opts[:ncbi], 'nodes.dmp'), 'w')
      taxo.each_internal do |n|
	 f.puts ([n.id, n.parent.nil? ? n.id : n.parent.id, n.ncbirank, ""] << Array.new(8,0) << "").join("\t|\t")+"\t|"
      end
      f.close
   end

   ## Taxtastic
   unless $opts[:seqinfo].nil?
      $stderr.puts "Creating seq-info file: #{$opts[:seqinfo]}"
      f = File.open($opts[:seqinfo], 'w')
      f.puts "\"seqname\",\"tax_id\",\"group_name\""
      taxo.each_leaf { |n| f.puts "\"#{n.name}\",\"#{n.parent.id}\",\"#{n.parent.name}\"" }
      f.close
   end
   
   ## Misc
   unless $opts[:taxfile].nil?
      $stderr.puts "Creating taxonomy file: #{$opts[:taxfile]}"
      f = File.open($opts[:taxfile], 'w')
      f.puts "tax_id\tparent_id\trank\ttax_name"
      taxo.each_internal do |n|
	 f.puts [n.id, n.parent.nil? ? n.id : n.parent.id, n.rank, n.name].join("\t")
      end
      f.close
   end
rescue => err
   $stderr.puts "Exception: #{err}\n\n"
   err.backtrace.each { |l| $stderr.puts l + "\n" }
   err
end


