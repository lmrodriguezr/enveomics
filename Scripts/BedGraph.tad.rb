#!/usr/bin/env ruby

$VERSION = 1.01
$:.push File.expand_path('../lib', __FILE__)
require 'enveomics_rb/enveomics'

o = { range: 0.5, perseq: false, length: false, o: '-' }
OptionParser.new do |opts|
  opts.version = $VERSION
  banner = <<~BANNER
    Estimates the truncated average sequencing depth (TAD) from a BedGraph file

    IMPORTANT: This script doesn't consider zero-coverage positions if missing
    from the file. If you produce your BedGraph file with bedtools genomecov and
    want to consider zero-coverage position, be sure to use -bga (not -bg).
  BANNER
  Enveomics.opt_banner(opts, banner, "#{File.basename($0)} [options]")

  opts.separator 'Mandatory'
  opts.on(
    '-i', '--input PATH',
    'Input BedGraph file',
    'Supports compression with .gz extension, use - for STDIN'
  ) { |v| o[:i] = v }

  opts.separator ''
  opts.separator 'Other Options'
  opts.on(
    '-o', '--out PATH',
    'Output tab-delimited values (by default, STDOUT)',
    'Supports compression with .gz extension, use - for STDOUT'
  ) { |v| o[:o] = v }
  opts.on(
    '-r', '--range FLOAT', Float,
    'Central range to consider, between 0 and 1',
    "By default: #{o[:range]} (inter-quartile range)"
  ) { |v| o[:range] = v }
  opts.on(
    '-n', '--name STRING',
    'Name (ID) of the sequence (added as first column)'
  ) { |v| o[:name] = v }
  opts.on(
    '-s', '--per-seq',
    'Calculate averages per reference sequence, not total',
    'Assumes a sorted BedGraph file'
  ) { |v| o[:perseq] = v }
  opts.on(
    '-l', '--length',
    'Add sequence length to the output'
  ) { |v| o[:length] = v }
  opts.on(
    '-b', '--breadth',
    'Add sequencing breadth to the output'
  ) { |v| o[:breadth] = v }
  opts.on('-h', '--help', 'Display this screen') do
    puts opts
    exit
  end
  opts.separator ''
end.parse!
raise Enveomics::OptionError.new('-i is mandatory') if o[:i].nil?

##
# Pad an array to include all index values up to +r+ entries:
# - d:   Array of [ depth => counts ]
# - idx: Array of [ depth, depth, ... ]
# - r:   Expected number of entries in the array
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

##
# Report the results for:
# - sq: Contig ID
# - d:  Array of [ depth => counts ]
# - ln: Length of the sequence
# - o:  CLI Options
def report(sq, d, ln, o)
  # Estimate padding ranges
  pad = (1.0 - o[:range]) / 2.0
  r = (pad * ln).round
  zeroes = d[0].to_i

  # Pad (truncation)
  d = pad(d, d.each_index.to_a, r + 0)
  d = pad(d, d.each_index.to_a.reverse, r + 0)

  # Average
  y = [0.0]
  unless d.compact.empty?
    s = d.each_with_index.to_a.map { |v, i| v.nil? ? 0 : i * v }.inject(0, :+)
    y[0] = s.to_f / d.compact.inject(:+)
  end

  # Report
  y.unshift(sq) if o[:perseq]
  y.unshift(o[:name]) if o[:name]
  y << ln if o[:length]
  y << (ln - zeroes).to_f / ln if o[:breadth]
  y.join("\t")
end

# Read BedGraph
d  = [] # [ depth => count ]
ln = 0
pre_sq = nil
ifh = reader(o[:i])
ofh = writer(o[:o])
ifh.each_line do |i|
  next if i =~ /^#/
  r  = i.chomp.split("\t")
  sq = r.shift # Contig ID
  if o[:perseq] && !pre_sq.nil? && pre_sq != sq
    ofh.puts(report(pre_sq, d, ln, o))
    d  = []
    ln = 0
  end
  r.map!(&:to_i) # From, To, Depth
  l = r[1] - r[0] # Window length: To - From
  d[ r[2] ] ||= 0
  d[ r[2] ]  += l # Add these "l" positions with depth "Depth"
  ln += l
  pre_sq = sq
end
ofh.puts(report(pre_sq, d, ln, o))

ifh.close
ofh.close

