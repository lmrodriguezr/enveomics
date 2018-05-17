#!/usr/bin/env ruby

require 'optparse'

o = {range: 0.5, perseq: false, length: false}
ARGV << '-h' if ARGV.empty?
OptionParser.new do |opt|
  opt.banner = "
  Estimates the truncated average sequencing depth (TAD) from a BedGraph file.

  IMPORTANT: This script doesn't consider zero-coverage positions if missing
  from the file. If you produce your BedGraph file with bedtools genomecov and
  want to consider zero-coverage position, be sure to use -bga (not -bg).

  Usage: #{$0} [options]"
  opt.separator ''
  opt.on('-i', '--input PATH',
    'Input BedGraph file (mandatory).'){ |v| o[:i]=v }
  opt.on('-r', '--range FLOAT',
    'Central range to consider, between 0 and 1.',
    "By default: #{o[:range]} (inter-quartile range)."
    ){ |v| o[:range]=v.to_f }
  opt.on('-s', '--per-seq',
    'Calculate averages per reference sequence, not total.',
    'Assumes a sorted BedGraph file.'
    ){ |v| o[:perseq] = v }
  opt.on('-l', '--length',
    'Add sequence length to the output.'){ |v| o[:length] = v }
  opt.on('-h', '--help', 'Display this screen.') do
    puts opt
    exit
  end
  opt.separator ''
end.parse!
abort '-i is mandatory.' if o[:i].nil?

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

def report(sq, d, ln, o)
  # Estimate padding ranges
  pad = (1.0-o[:range])/2.0
  r = (pad*ln).round

  # Pad
  d = pad(d, d.each_index.to_a, r+0)
  d = pad(d, d.each_index.to_a.reverse, r+0)

  # Average
  y = [0.0]
  unless d.compact.empty?
    s = d.each_with_index.to_a.map{ |v,i| v.nil? ? 0 : i*v }.inject(0,:+)
    y[0] = s.to_f/d.compact.inject(:+)
  end

  # Report
  y.unshift(sq) if o[:perseq]
  y << ln if o[:length]
  puts y.join("\t")
end

# Read BedGraph
d  = []
ln = 0
pre_sq = nil
File.open(o[:i], "r") do |ifh|
  ifh.each_line do |i|
    next if i =~ /^#/
    r  = i.chomp.split("\t")
    sq = r.shift
    if o[:perseq] and !pre_sq.nil? and pre_sq!=sq
      report(pre_sq, d, ln, o)
      d  = []
      ln = 0
    end
    r.map! { |j| j.to_i }
    l = r[1]-r[0]
    d[ r[2] ] ||= 0
    d[ r[2] ]  += l
    ln += l
    pre_sq = sq
  end
end
report(pre_sq, d, ln, o)

