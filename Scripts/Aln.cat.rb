#!/usr/bin/env ruby
#
# @author  Luis M. Rodriguez-R
# @update  Nov-30-2015
# @license artistic license 2.0
#

$:.push File.expand_path(File.dirname(__FILE__) + "/lib")
require "enveomics_rb/enveomics"

o = {:q=>false, :missing=>"-", :model=>"AUTO", :removeinvar=>false,
   :undefined=>"-.Xx?"}
OptionParser.new do |opt|
   opt.banner = "
   Concatenates several multiple alignments in FastA format into a single
   multiple alignment.  The IDs of the sequences (or the ID prefixes, if using
   --ignore-after) must coincide across files.

   Usage: #{$0} [options] aln1.fa aln2.fa ... > aln.fa".gsub(/^ +/,"")
   opt.separator ""
   opt.on("-c", "--coords FILE",
      "Output file of coordinates in RAxML-compliant format."
      ){ |v| o[:coords]=v }
   opt.on("-i", "--ignore-after STRING",
      "Remove everything in the IDs after the specified string."
      ){ |v| o[:ignoreafter]=v }
   opt.on("-I", "--remove-invariable", "Remove invariable sites.",
      "Note: Invariable sites are defined as columns with only one state and",
      "undefined characters.  Additional ambiguous characters may exist and",
      "should be declared using --undefined."){ |v| o[:removeinvar]=v }
   opt.on("-u", "--missing-char CHAR",
      "Character denoting missing data. By default: '#{o[:missing]}'.") do |v|
	 abort "Missing positions can only be denoted by single characters, " +
	    "offending value: '#{v}'." if v.length != 1
	 o[:missing]=v
      end
   opt.on("-m", "--model STRING",
      "Name of the model to use if --coords is used. See RAxML's docs; ",
      "supported values in v8+ include:",
      "o For DNA alignments:",
      "  'DNA[F|X]', or 'DNA[F|X]/3' (to estimate rates per codon position,",
      "  particular notation for this script).",
      "o General protein alignments:",
      "  'AUTO' (default in this script), 'DAYHOFF' (1978), 'DCMUT' (MBE 2005;",
      "  22(2):193-199), 'JTT' (Nat 1992;358:86-89), 'VT' (JCompBiol 2000;",
      "  7(6):761-776), 'BLOSUM62' (PNAS 1992;89:10915), and 'LG' (MBE 2008;",
      "  25(7):1307-1320).",
      "o Specialized protein alignments:",
      "  'MTREV' (mitochondrial, JME 1996;42(4):459-468), 'WAG' (globular, MBE",
      "  2001;18(5):691-699), 'RTREV' (retrovirus, JME 2002;55(1):65-73), ",
      "  'CPREV' (chloroplast, JME 2000;50(4):348-358), and 'MTMAM' (nuclear",
      "  mammal proteins, JME 1998;46(4):409-418)."){|v| o[:model]=v}
   opt.on("--undefined STRING",
      "All characters to be regarded as 'undefined'. It should include all",
      "ambiguous and missing data chars.  Ignored unless --remove-invariable.",
      "By default: '#{o[:undefined]}'."){|v| o[:undefined]=v}
   opt.on("-q", "--quiet", "Run quietly (no STDERR output)."){ o[:q] = TRUE }
   opt.on("-h", "--help", "Display this screen.") do
      puts opt
      exit
   end
   opt.separator ""
end.parse!
alns = ARGV
abort "Alignment files are mandatory" if alns.nil? or alns.empty?

##### MAIN:
begin
   $stderr.puts "Reading." unless o[:q]
   a = {}
   n = alns.size-1
   lengths = []
   (0 .. n).each do |i|
      key = nil
      File.open(alns[i],"r").each do |ln|
	 ln.chomp!
	 if ln =~ /^>(\S+)/
	    key = $1
	    key.sub!(/#{o[:ignoreafter]}.*/,"") unless o[:ignoreafter].nil?
	    a[key] ||= []
	    a[key][i] = ""
	 else
	    abort "#{alns[i]}: Leading line is not a def-line, is this a "+
	       "valid FastA file?" if key.nil?
	    ln.gsub!(/\s/,"")
	    a[key][i] += ln
	 end
      end
      abort "#{alns[i]}: Empty alignment?" if key.nil?
      lengths[i] = a[key][i].length
   end
   if o[:removeinvar]
      $stderr.puts "Removing invariable sites." unless o[:q]
      invs = 0
      (0 .. n).each do |i|
	 olen = lengths[i]
	 (0 .. (lengths[i]-1)).each do |pos|
	    chr = nil
	    inv = true
	    a.keys.each do |key|
	       next if a[key][i].nil?
	       chr = a[key][i][pos] if
		  chr.nil? or o[:undefined].chars.include? chr
	       if chr != a[key][i][pos] and
		     not o[:undefined].chars.include? a[key][i][pos]
		  inv = false
		  break
	       end
	    end
	    if inv
	       a.keys.each{|key| a[key][i][pos]="!" unless a[key][i].nil?}
	       lengths[i] -= 1
	       invs += 1
	    end
	 end
	 a.keys.each{|key| a[key][i].gsub!("!", "") unless a[key][i].nil?}
      end
      $stderr.puts "  Removed #{invs} sites." unless o[:q]
   end
   $stderr.puts "Concatenating." unless o[:q]
   a.keys.each do |key|
      (0 .. n).each do |i|
	 a[key][i] = (o[:missing] * lengths[i]) if a[key][i].nil?
      end
      abort "Inconsistent lengths in '#{key}'
      exp:#{lengths.join(" ")}
      obs:#{a[key].map{|i| i.length}.join(" ")}." unless
	 lengths == a[key].map{|i| i.length}
      puts ">#{key}", a[key].join("").gsub(/(.{1,60})/, "\\1\n")
      a.delete(key)
   end
   unless o[:coords].nil?
      $stderr.puts "Generating coordinates." unless o[:q]
      coords = File.open(o[:coords],"w")
      s = 0
      names = (alns.map do |a|
	 File.basename(a).gsub(/\..*/,"").gsub(/[^A-Za-z0-9_]/,"_")
      end)
      (0 .. n).each do |i|
	 l = lengths[i]
	 next unless l > 0
	 names[i] += "_#{i}" while names.count(names[i])>1
	 if o[:model] =~ /(DNA.?)\/3/
	    coords.puts "#{$1}, #{names[i]}codon1 = #{s+1}-#{s+l}\\3"
	    coords.puts "#{$1}, #{names[i]}codon2 = #{s+2}-#{s+l}\\3"
	    coords.puts "#{$1}, #{names[i]}codon3 = #{s+3}-#{s+l}\\3"
	 else
	    coords.puts "#{o[:model]}, #{names[i]} = #{s+1}-#{s+l}"
	 end
	 s += l
      end
      coords.close
   end
   # Save the output matrix
   $stderr.puts "Done.\n" unless o[:q] 
rescue => err
   $stderr.puts "Exception: #{err}\n\n"
   err.backtrace.each { |l| $stderr.puts l + "\n" }
   err
end


