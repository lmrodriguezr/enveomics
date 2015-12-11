#!/usr/bin/env ruby

#
# @author:  Luis M. Rodriguez-R <lmrodriguezr at gmail dot com>
# @update:  Dec-11-2015
# @license: artistic license 2.0
#

require "optparse"

$opts = {n:5, sortby:"bitscore", q:false}
$cols = {"bitscore"=>11, "evalue"=>10, "identity"=>2, "length"=>3}
ARGV << "-h" if ARGV.size==0
OptionParser.new do |opts|
   opts.banner = "Reports the top-N best hits of a BLAST, pre-sorted by query."
   opts.separator ""
   opts.separator "Mandatory"
   opts.on("-i", "--blast FILE",
      "Path to the BLAST file."){ |v| $opts[:blast]=v }
   opts.separator ""
   opts.separator "Optional"
   opts.on("-n", "--top INTEGER",
      "Maximum number of hits to report for each query.",
      "By default: #{$opts[:n]}"){ |v| $opts[:n]=v.to_i }
   opts.on("-s", "--sort-by STRING",
      "Parameter used to detect the 'best' hits.",
      "Any of: bitscore (default), evalue, identity, length."
      ){ |v| $opts[:sortby]=v }
   opts.on("-q", "--quiet", "Run quietly."){ $opts[:q]=true }
   opts.on("-h", "--help", "Display this screen") do
      puts opts
      exit
   end
   opts.separator ""
end.parse!

abort "-i/--blast is mandatory." if $opts[:blast].nil?
abort "Unrecognized value for -s/--sortby: #{$opts[:sortby]}." if
   $cols[ $opts[:sortby] ].nil?

class Hit
   attr_reader :blast_line
   def initialize(blast_line)
      @blast_line = blast_line.chomp.split(/\t/)
   end
   def col(i)
      @blast_line[i]
   end
   def <=>(other)
      ans = self.col( $cols[ $opts[:sortby] ] ).to_f <=> other.col( $cols[ $opts[:sortby] ] ).to_f
      ans = ans * -1 unless $opts[:sortby] == "evalue"
      return ans
   end
   def to_s
      @blast_line.join("\t")
   end
end

class HitSet
   attr_reader :query, :hits
   def initialize
      @hits = []
      @query = nil
   end
   def <<(hit)
      @query = hit.col(0) if @query.nil?
      raise "Inconsistent query, expecting #{self.query}" unless
	 self.query == hit.col(0)
      @hits << hit
   end
   def empty?
      self.hits.length == 0
   end
   def filter!
      @hits.sort!
      @hits.slice!($opts[:n], @hits.length)
   end
   def to_s
      @hits.join("\n")
   end
end

$stderr.puts "Parsing BLAST." unless $opts[:q]
fh = File.open $opts[:blast], "r"
hs = HitSet.new
while ln=fh.gets
   hit = Hit.new( ln )
   if hs.query != hit.col(0)
      hs.filter!
      puts hs unless hs.empty?
      hs = HitSet.new
      $stderr.print "Parsing line #{$.}... \r" unless $opts[:q]
   end
   hs << hit
end
$stderr.print "Parsed #{$.} lines.   \n" unless $opts[:q]
fh.close

hs.filter!
puts hs unless hs.empty?

