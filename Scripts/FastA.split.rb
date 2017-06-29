#!/usr/bin/env ruby
#
# @author Luis M. Rodriguez-R <lmrodriguezr at gmail dot com>
# @license Artistic-2.0
#

require "optparse"

o = {q:false, n:12, lett:false, dc:false, z:false, out:"%s.%s.fa"}
ARGV << "-h" if ARGV.size==0

OptionParser.new do |opt|
  opt.banner = "
  Evenly splits a multi-FastA file into multiple multi-FastA files.
  
  Usage: #{$0} [options]"
  opt.separator ""
  opt.separator "Mandatory"
  opt.on("-i", "--input PATH", "Input FastA file."){ |v| o[:i] = v}
  opt.on("-p", "--prefix PATH", "Prefix of output FastA files."){ |v| o[:p] = v}
  opt.separator ""
  opt.separator "Options"
  opt.on("-n", "--number INT",
    "Number of output files to produce. By default: #{o[:n]}."
    ){ |v| o[:n] = v.to_i }
  opt.on("-z", "--zero-padded",
    "Use zero-padded numbers as output index."){ o[:lett]=false; o[:z]=true }
  opt.on("-l", "--lowercase-letters",
    "Use lowercase letters as output index."){ o[:lett]=true ; o[:dc]=true }
    opt.on("-u", "--uppercase-letters",
    "Use uppercase letters as output index."){ o[:lett]=true }
  opt.on("-o", "--out STR",
    "Format of output filenames, where %s are replaced by prefix and index.",
    "By default: #{o[:out]}."){ |v| o[:out] = v }
  opt.on("-q", "--quiet", "Run quietly (no STDERR output)."){ o[:q] = TRUE }
  opt.on("-h", "--help", "Display this screen.") do
    puts opt
    exit
  end
  opt.separator ""
end.parse!
abort "-i is mandatory." if o[:i].nil?
abort "-p is mandatory." if o[:p].nil?

ofh = []
idx = if o[:lett]
  k = Math::log(o[:n], 26).ceil
  r = o[:dc] ? ["a","z"] : ["A","Z"]
  ((r[0]*k) .. (r[1]*k)).first(o[:n])
elsif o[:z]
  k = Math::log(o[:n], 10).ceil
  (1 .. o[:n]).map{ |i| "%0#{k}d" % i }
else
  (1 .. o[:n]).map{ |i| i.to_s }
end
idx.each do |i|
  fn = o[:out] % [o[:p], i]
  ofh << File.open(fn, "w")
end

i = -1
seq = ""
File.open(o[:i], "r") do |ifh|
  ifh.each_line do |ln|
    next if ln =~ /^;/
    if ln =~ /^>/
      ofh[i % o[:n]].print seq
      i += 1
      seq = ""
    end
    seq << ln
  end
  ofh[i % o[:n]].print seq
end

ofh.each{ |i| i.close }

$stderr.puts "Sequences: #{i+1}.", "Files: #{o[:n]}." unless o[:q]

