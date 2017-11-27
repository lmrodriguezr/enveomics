#!/usr/bin/env ruby

require "optparse"

o = {range:0.5}
ARGV << "-h" if ARGV.empty?
OptionParser.new do |opt|
  opt.banner = "
  Estimates the truncated average sequencing depth (TAD) from a BedGraph file.

  IMPORTANT: This script doesn't consider zero-coverage positions if missing
  from the file. If you produce your BedGraph file with bedtools genomecov and
  want to consider zero-coverage position, be sure to use -bga (not -bg).

  Usage: #{$0} [options]"
  opt.separator ""
  opt.on("-i", "--input PATH",
    "Input BedGraph file (mandatory)."){ |v| o[:i]=v }
  opt.on("-r", "--range FLOAT",
    "Central range to consider, between 0 and 1.",
    "By default: #{o[:range]} (inter-quartile range)."
    ){ |v| o[:range]=v.to_f }
  opt.on("-h", "--help", "Display this screen.") do
    puts opt
    exit
  end
  opt.separator ""
end.parse!
abort "-i is mandatory." if o[:i].nil?

def pad(d, idx, r)
  idx.each do |i|
    next if d[i].nil?
    d[i] -= r
    break unless d[i] < 0
    r = -d[i]
    d[i] = nil
  end
  d
end

# Read BedGraph
d = []
ln = 0
File.open(o[:i], "r") do |ifh|
  ifh.each_line do |i|
    next if i =~ /^#/
    r = i.chomp.split("\t")[1 .. -1].map{ |j| j.to_i }
    l = r[1]-r[0]
    d[ r[2] ] ||= 0
    d[ r[2] ] += l
    ln += l
  end
end

# Estimate padding ranges
pad = (1.0-o[:range])/2.0
r = (pad*ln).round

# Pad
d = pad(d, d.each_index.to_a, r+0)
d = pad(d, d.each_index.to_a.reverse, r+0)

# Average
if d.compact.empty?
  p 0.0
else
  s = d.each_with_index.to_a.map{ |v,i| v.nil? ? 0 : i*v }.inject(0,:+)
  p s.to_f/d.compact.inject(:+)
end

