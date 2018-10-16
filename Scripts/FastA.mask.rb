#!/usr/bin/env ruby

require 'optparse'
o = {x: 'N', trim: false, wrap: 70}
ARGV << '-h' if ARGV.empty?
OptionParser.new do |opts|
  opts.banner = "
Mask sequence region(s) in a FastA file.

Usage: #{$0} [options]"
  opts.separator ''
  opts.separator 'Mandatory'
  opts.on('-i', '--in FILE', 'Input FastA file.'){ |v| o[:in] = v }
  opts.on('-o', '--out FILE', 'Output FastA file.'){ |v| o[:out] = v }
  opts.on('-r', '--regions REG1,REG2,...', Array,
    'Regions to mask separated by commas.',
    'Each region must be in the format "sequence_id:from..to"'
    ){ |v| o[:reg] = v }
  opts.separator ''
  opts.separator 'Options'
  opts.on('-x', '--symbol CHAR',
    'Character used to mask the region(s)',
    "By default: #{o[:x]}."){ |v| o[:x] = v }
  opts.on('-t', '--trim',
    'Trim masked regions extending to the edge of a sequence'
    ){ |v| o[:trim] = v }
  opts.on('-w', '--wrap INT',
    'Line length to wrap sequences. Use 0 to generate 1-line sequences.',
    "By default: #{o[:wrap]}."){ |v| o[:wrap] = v.to_i }
  opts.on('-h', '--help', 'Display this screen.') do
    puts opts
    exit
  end
  opts.separator ''
end.parse!
abort '-i is mandatory' if o[:in].nil?
abort '-o is mandatory' if o[:out].nil?
abort '-r is mandatory' if o[:reg].nil?

def wrap_width(txt, len)
  return "" if txt.empty?
  return "#{txt}\n" if len==0
  txt.gsub(/(.{1,#{len}})/,"\\1\n")
end

# Read input sequences
sq = {}
File.open(o[:in], 'r') do |ifh|
  bf = ''
  ifh.each('>') do |i|
    (dln, seq) = i.split(/[\n\r]+/, 2)
    next if seq.nil?
    id = dln.gsub(/\s.*/,  '')
    seq.gsub!(/[\s>]/, '')
    sq[id] = [dln, seq]
  end
end

# Parse coordinates and mask regions
last_id = nil
o[:reg].each do |i|
  m = i.match(/^(?:(.+):)?(\d+)\.\.(\d+)$/) or
    abort "Unexpected region format: #{i}"
  r = [m[1], m[2].to_i-1, m[3].to_i-1]
  if r[0].nil?
    abort "Region missing sequence ID: #{i}" if last_id.nil?
    r[0] = last_id
  end
  last_id = r[0]
  sq[r[0]] or abort "Cannot find sequence #{r[0]}"
  r[1] <= r[2] or abort "Malformed range: #{i}"
  if r[1] < 0 or r[2] > sq[r[0]][1].size
    abort "Range extends beyond the edge of the sequence: #{i}"
  end
  sq[r[0]][1][r[1] .. r[2]] = o[:x]*(1+r[2]-r[1])
end

# Trim sequences and generate output
ofh = File.open(o[:out], 'w')
sq.each do |_k,v|
  ofh.puts ">#{v[0]}"
  if o[:trim]
    v[1].gsub!(/^#{o[:x]}+/,'')
    v[1].gsub!(/#{o[:x]}+$/,'')
  end
  ofh.print wrap_width(v[1], o[:wrap])
end
ofh.close

