#!/usr/bin/env ruby

require 'optparse'

o = {win: 1000}
ARGV << '-h' if ARGV.empty?
OptionParser.new do |opt|
  opt.banner = "
  Estimates the sequencing depth per windows from a BedGraph file.

  IMPORTANT: This script doesn't consider zero-coverage positions if missing
  from the file. If you produce your BedGraph file with bedtools genomecov and
  want to consider zero-coverage position, be sure to use -bga (not -bg).

  Usage: #{$0} [options]"
  opt.separator ''
  opt.on('-i', '--input PATH',
    'Input BedGraph file (mandatory).'){ |v| o[:i]=v }
  opt.on('-w', '--win INT',
    'Window size, in base pairs.', "By default: #{o[:win]}."
    ){ |v| o[:win]=v.to_i }
  opt.on('-h', '--help', 'Display this screen.') do
    puts opt
    exit
  end
  opt.separator ''
end.parse!
abort '-i is mandatory.' if o[:i].nil?

def report(d, a, b, seqs)
  # Average
  y = 0.0
  unless d.compact.empty?
    s = d.each_with_index.to_a.map{ |v,i| v.nil? ? 0 : i*v }.inject(0,:+)
    y = s.to_f/d.compact.inject(:+)
  end

  # Report
  puts [a, b, y, seqs.keys.join(",")].join("\t")
end

# Read BedGraph
d  = []
ln = 0
a = 1
seqs = {}
b = o[:win]
File.open(o[:i], "r") do |ifh|
  ifh.each_line do |i|
    next if i =~ /^#/
    r  = i.chomp.split("\t")
    sq = r.shift
    seqs[sq] = 1
    r.map!{ |j| j.to_i }
    l = r[1]-r[0]
    d[ r[2] ] ||= 0
    d[ r[2] ]  += l
    ln += l
    while ln >= b
      d[ r[2] ] -= (ln-b)
      report(d, a, b, seqs)
      seqs = {}
      seqs[ sq ] = 1 if ln > b
      d = []
      d[ r[2] ] = (ln-b)
      a = b + 1
      b = a + o[:win] - 1
    end
  end
end

