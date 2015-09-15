
##### CLASSES:
# SeqRange.parse(str): Initializes a new SeqRange from a string. A SeqRange is a
#    representation of any collection of coordinates in a given sequence.
#    Coordinates here are 1-based and base-located. Admitedly, the
#    0-based/interbase-located system is much more convenient for range
#    operations, but GenBank (together with most common Software) is built on
#    the 1-based/base-located system.
# str: A string describing the sequence range as in GenBank records.
#    Note that "ID:location" notation is NOT supported by this implementation,
#    althought it is permitted by GenBank. Some examples of valid `str`:
#       "<1..123"
#       "complement(3..6)"
#       "join(complement(join(13..43,complement(45..46),complement(1..12),
#           <1..12)),12..15,13..22)"
#    The last one is valid, but once parsed it's internally simplified as:
#       "join(complement(<1..12),1..12,45..46,complement(13..43),12..15,13..22)"
#    Which is exactly equivalent. The common (but non-GenBank-compliant)
#    practice of inverting coordinates instead of using the `complement()`
#    operator is also supported. For example:
#       "123..3"
#    Is interpreted as:
#       "complement(3..123)"
# See also http://www.insdc.org/files/feature_table.html
# 
# SeqRange.new(c): Initializes a new SeqRange from an object.
# c: Any object supported by the `<<` operator, or `nil` to create an empty
#    SeqRange.
# 
# See also ContigSeqRange.parse.
class SeqRange
   # Class-level
   def self.parse(str)
      str.gsub!(/[^A-Za-z0-9\.\(\)<>,]/,"")
      sr = nil
      if str =~ /^join\((.+)\)$/i
	 str1 = $1
	 str2 = ""
	 sr = SeqRange.new
	 parens = 0
	 str1.each_char do |chr|
	    if chr=="," and parens==0
	       sr += SeqRange.parse(str2)
	       str2 = ""
	       next
	    elsif chr=="("
	       parens += 1
	    elsif chr==")"
	       parens -= 1
	       raise "Unbalanced parenthesis in '#{str1}'." if parens < 0
	    end
	    str2 += chr
	 end
	 sr += SeqRange.parse(str2) unless str2.empty?
	 sr
      elsif str =~ /^complement\((.+)\)$/i
	 sr = SeqRange.parse($1)
	 sr.reverse!
	 sr
      else
	 sr = SeqRange.new(ContigSeqRange.parse(str))
      end
      sr
   end
   # Instance-level
   attr_reader :contig
   def initialize(c=nil)
      @contig = []
      self << c unless c.nil?
   end
   def leftmost; contig.map{ |c| c.left }.min; end
   def rightmost; contig.map{ |c| c.right }.max; end
   def size; contig.map{ |c| c.size }.inject(0,:+); end
   def +(sr)
      return(self + SeqRange.new(sr)) if sr.is_a? ContigSeqRange
      raise "Unsupported operation '+' with class #{sr.class.to_s}." unless
	 sr.is_a? SeqRange
      out = SeqRange.new(self)
      out << sr
      out
   end
   def /(sr)
      if sr.is_a? SeqRange
	 sr2 = sr.sort.compact
	 raise "Denominator is not a contiguous domain." unless sr2.size==1
	 return(self/sr2.contig.first)
      end
      raise "Unsupported operation '/' with class #{sr.class.to_s}" unless
	 sr.is_a? ContigSeqRange
      raise "Denominator doesn't span the whole domain of numerator." unless
	 sr.left <= leftmost and sr.right >= rightmost
      i = ContigSeqRange.IGNORE_STRAND
      ContigSeqRange.IGNORE_STRAND = false
      range = self.sort.compact.size
      ContigSeqRange.IGNORE_STRAND = i
      range.to_f / sr.size
   end
   def <<(c)
      if c.is_a? ContigSeqRange
	 @contig << c
      elsif c.is_a? SeqRange
	 @contig += c.contig
      elsif c.is_a? Array
	 raise "Array must contain only objects of class ContigSeqRange." unless
	    c.map{ |cc| cc.is_a? ContigSeqRange }.all?
	 @contig += c
      else
	 raise "Unsupported operation '<<' with class #{c.class.to_s}."
      end
   end
   def reverse ; SeqRange.new(self).reverse! ; end
   def sort ; SeqRange.new(self).sort! ; end
   def compact ; SeqRange.new(self).compact! ; end
   def reverse!
      @contig.each{ |c| c.reverse! }
      @contig.reverse!
      self
   end
   def sort!
      @contig.sort!{ |x,y| x.left <=> y.left }
      self
   end
   def compact!
      return self if contig.size < 2
      clean = false
      while not clean
	 clean = true
	 (2 .. contig.size).each do |i|
	    next unless contig[i-2].reverse? == contig[i-1].reverse?
	    next unless contig[i-2].contig? contig[i-1]
	    contig[i-2] += contig[i-1]
	    contig[i-1] = nil
	    clean = false
	    break
	 end
	 @contig.compact!
      end
      self
   end
   def to_s
      o = contig.map{ |c| c.to_s }.join(",")
      o = "join(#{o})" if contig.size > 1
      o
   end
end


# ContigSeqRange.parse(str): Initializes a new ContigSeqRange from a string. A 
#    ContigSeqRange is a primitive of `SeqRange` that doesn't support the
#    `join()` operator. Other than that, syntax is identical to `SeqRange`.
# str: A string describing the sequence range as in GenBank records (except
#    `join()`).
#
# ContigSeqRange.new(a,b): Initializes a new ContigSeqRange from the
#    coordinates as integers.
# a: Start of the range.
# b: End of the range. If a>b, the `complement()` operator is assumed.
#
# ContigSeqRange.IGNORE_STRAND = true: Use this pragma to ignore strandness.
#    If set, it globally affects the behavior of of the class. Note that
#    `SeqRange` instances contain a collection of `ContigSeqRange` objects, so
#    that class is also affected.
class ContigSeqRange
   # Class-level
   @@IGNORE_STRAND = false
   def self.IGNORE_STRAND=(v); @@IGNORE_STRAND = !!v ; end
   def self.IGNORE_STRAND; @@IGNORE_STRAND ; end
   def self.parse(str)
      str.downcase!
      m = %r{^
	 (?<c>complement\()?	# Reverse
	 (?<lt><?)		# Open-ended to the left
	 (?<left>\d+)		# Left coordinate
	 (
	    \.\.\.?		# 2 or 3 dots
	    (?<gt1>>?)		# Open-ended to the right
	    (?<right>\d+)	# Right coordinate
	 )?
	 (?<gt2>>?)		# Open-ended to the right
	 \)?			# If reverse
      $}x.match(str)
      raise "Cannot parse range: #{str}." if m.nil?
      c = ContigSeqRange.new(m[:left].to_i, m[:right].to_i)
      c.open_left = true if m[:lt]=="<"
      c.open_right = true if m[:gt1]==">" or m[:gt2]==">"
      c.reverse! if m[:c]=="complement("
      c
   end
   # Instance-level
   attr_accessor :open_left, :open_right
   attr_reader :coords
   def initialize(a,b)
      @coords = [[a,b].min, [a,b].max]
      @open_left = false
      @open_right = false
      @reverse = (a > b)
   end
   def from; coords[ reverse ? 1 : 0 ] ; end
   def to; coords[ reverse ? 0 : 1 ] ; end
   def left; coords[0] ; end
   def right; coords[1] ; end
   def size; right-left+1 ; end
   def reverse?; @reverse ; end
   def reverse!
      @reverse = ! reverse? unless @@IGNORE_STRAND
      self
   end
   def overlap?(sr) !(right < sr.left or left > sr.right) ; end
   def contig?(sr) !(right+1 < sr.left or left-1 > sr.right) ; end
   def +(sr)
      raise "Unsupported operation '+' with class #{sr.class.to_s}" unless
	 sr.is_a? ContigSeqRange
      raise "Non-contiguous ranges cannot be added." unless contig? sr
      raise "Ranges in different strands cannot be added." unless
	 reverse? == sr.reverse?
      out = ContigSeqRange.new([left,sr.left].min, [right,sr.right].max)
      out.reverse! if reverse?
      out.open_left=true if (left < sr.left ? self : sr).open_left
      out.open_right=true if (right > sr.right ? self : sr).open_right
      out
   end
   def to_s
      o = ""
      o += "<" if open_left
      o += left.to_s
      if left == right
	 o += ">" if open_right
      else
	 o += ".."
	 o += ">" if open_right
	 o += right.to_s
      end
      o = "complement(#{o})" if reverse?
      o
   end
end

