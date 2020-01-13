#!/usr/bin/env ruby

require 'optparse'
require 'zlib'

o = { qual: 31, encoding: 33 }
ARGV << '-h' if ARGV.empty?
OptionParser.new do |opts|
  opts.banner = "
Creates a FastQ-compliant file from a FastA file.

Usage: #{$0} [options]"
  opts.separator ''
  opts.separator 'Options'
  opts.on(
    '-i', '--in FILE', 'Input FastA file (supports .gz compression)'
  ) { |v| o[:in] = v }
  opts.on(
    '-o', '--out FILE', 'Output FastQ file (supports .gz compression)'
  ) { |v| o[:out] = v }
  opts.on(
    '-q', '--quality INT', Integer,
    'PHRED quality score to use (fixed), in the range [-5, 41]',
    "By default: #{o[:qual]}"
  ) { |v| o[:qual] = v }
  opts.on(
    '--encoding INT', Integer,
    "Base encoding (33 or 64). By default: #{o[:encoding]}"
  ) { |v| o[:encoding] = v }
  opts.on('-h', '--help', 'Display this screen.') do
    puts opts
    exit
  end
  opts.separator ''
end.parse!
abort '-i is mandatory' if o[:in].nil?
abort '-o is mandatory' if o[:out].nil?
abort '-q must be in the range -5 .. 41' if o[:qual] < -5 || o[:qual] > 41

# Determine quality character
$qchar = (o[:qual] + o[:encoding]).chr

# Create file handlers
ifh = o[:in] =~ /\.gz$/ ?
  Zlib::GzipReader.open(o[:in]) : File.open(o[:in], 'r')
ofh = o[:out] =~ /\.gz$/ ?
  Zlib::GzipWriter.open(o[:out]) : File.open(o[:out], 'w')

def print_seq(ofh, id, seq)
  ofh.puts "@#{id}", seq, '+', $qchar * seq.length unless seq.empty?
end

# Generate FastQ
id = ''
seq = ''
ifh.each_line do |ln|
  next if ln =~ /^;/
  if ln =~ /^>(.*)/
    print_seq(ofh, id, seq)
    seq = ''
    id = $1
  else
    seq += ln.chomp.upcase.gsub(/[^A-Z]/,'')
  end
end
print_seq(ofh, id, seq)
ofh.close
ifh.close

