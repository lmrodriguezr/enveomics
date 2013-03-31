#!/usr/bin/ruby -w

#
# @author Luis M. Rodriguez-R <lmrodriguezr at gmail dot com>
# @license artistic license 2.0
#

require 'trollop'

opts = Trollop::options do
   banner "Identifies the best hits of paired-reads."
   opt :blast, "Input BLAST file.", :type=>:string, :short=>'i'
   opt :minscore, "Minimum (summed) Bit-Score to consider a pair-match.", :short=>'s', :default=>0
   opt :besthits, "Outputs top best-hits only (use 0 to output all the paired hits).", :short=>'b', :default=>0
   opt :orient, "Checks the orientation of the hit.  Values are: 0, no checking; 1, same direction; 2, " +
   		"inwards; 3, outwards; 4, different direction (i.e., 2 or 3).", :short=>'o', :default=>0
   opt :sisprefix, "Sister read number prefix in the name of the reads.  Escape characters as dots (\\.), " +
   		"parenthesis (\\(, \\), \\[, \\]), or other characters with special meaning in regular expressions " +
		"(\*, \+, \^, \$, \|).  This prefix allows regular expressions (for example, use ':|\\.' to use any of " +
		"colon or dot).  Notice that the prefix will not be included in the base name reported in the output.", :short=>'p', :default=>"_"
end

Trollop::die :blast, "is mandatory" unless opts[:blast]
Trollop::die :blast, "must exist" unless File.exist?(opts[:blast]) if opts[:blast]

class SingleHit
   attr_reader :sbj, :score, :orient, :sfrom, :sto, :qfrom, :qto
   def initialize(blast_ln)
      blast_ln.chomp!
      ln = blast_ln.split("\t")
      @sbj    = ln[1]
      @score  = ln[11].to_f
      @qfrom  = ln[6].to_i
      @qto    = ln[7].to_i
      @sfrom  = ln[8].to_i
      @sto    = ln[9].to_i
      @orient = @sfrom < @sto ? 1 : -1;
   end
end
class DoubleHit
   attr_reader :name, :sbj, :score, :orient, :hitA, :hitB
   def initialize(name, hitA, hitB)
      raise "Trying to set DoubleHit from hits with different subjects" unless hitA.sbj == hitB.sbj
      @name = name
      @hitA = hitA
      @hitB = hitB
      @sbj = hitA.sbj
      @score = hitA.score + hitB.score
      @orient = (hitA.orient == hitB.orient ? 1:
      		((hitA.orient>0 and hitB.orient<0) ? 2: 3))
   end
   def to_s
      @name + "\t" + @sbj + "\t" + @score.to_s + "\t" +
      	@hitA.sfrom.to_s + "\t" + @hitA.sto.to_s + "\t" +
      	@hitB.sfrom.to_s + "\t" + @hitB.sto.to_s + "\t" +
	@orient.to_s + "\n"
   end
end
class PairedHits
   attr_reader :name, :hitsA, :hitsB
   @@minscore = 0
   @@orient = 0
   @@besthits = 0
   def initialize(name)
      @name = name
      @hitsA = []
      @hitsB = []
      @hits  = []
   end
   def hits
      @hits = []
      # Search for paired hits
      @hitsA.each do |hitA|
         @hitsB.each do |hitB|
	    if hitA.sbj == hitB.sbj
	       hit = DoubleHit.new(@name, hitA, hitB)
	       next if hit.score <= @@minscore # Minimum bit-score check
	       next if ((1 .. 3).include?(@@orient) and @@orient != hit.orient) # "typical" orientation check
	       next if (@@orient == 4 and not((2 .. 3).include?(hit.orient))) # "different-orientation" check
	       @hits.push(hit)
	    end
	 end
      end
      # Sort the hits
      @hits.sort! {|x,y| x.score <=> y.score }
      if @@besthits==0
         @hits
      else
         @hits.take(@@besthits)
      end
   end
   def hitsX(x)
      if x == 1
         @hitsA
      else
         @hitsB
      end
   end
   # Class methods
   def PairedHits.minscore=(value)
      @@minscore = value
   end
   def PairedHits.orient=(value)
      @@orient = value
   end
   def PairedHits.besthits=(value)
      @@besthits = value
   end
end

PairedHits.minscore = opts[:minscore]
PairedHits.orient   = opts[:orient]
PairedHits.besthits = opts[:besthits]

begin
   f = File.open(opts[:blast], "r")
   currPair = PairedHits.new("  ")
   while(ln = f.gets)
      m = /^(?<read>[^\s]*)(#{opts[:sisprefix]})(?<sister>[12])/.match(ln)
      raise "Impossible to parse read name in line #{$.} using sister prefix '#{opts[:sisprefix]}':\n#{ln}"  unless m
      if m[:read] != currPair.name
	 currPair.hits.each { |hit| puts hit.to_s }
	 currPair = PairedHits.new(m[:read])
      end
      currPair.hitsX(m[:sister].to_i).push(SingleHit.new(ln));
   end
   currPair.hits.each { |hit| puts hit.to_s }
   f.close
rescue => err
   $stderr.puts "Exception: #{err}\n\n"
   err.backtrace.each { |l| $stderr.puts l + "\n" }
   err
end

