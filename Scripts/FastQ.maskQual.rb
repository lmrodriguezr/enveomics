#!/usr/bin/env ruby

$VERSION = 1.0
$:.push File.expand_path('../lib', __FILE__)
require 'enveomics_rb/enveomics'

o = { q: false, offset: 33, qual: 15 }
OptionParser.new do |opts|
  cmd = File.basename($0)
  opts.banner = <<~BANNER

    [Enveomics Collection: #{cmd} v#{$VERSION}]

    Masks low-quality bases in a FastQ file

    Usage
      #{cmd} -i input.fastq -o output.fastq [options]

  BANNER

  opts.separator 'Mandatory'
  opts.on(
    '-i', '--input FILE',
    'Path to the FastQ file containing the sequences',
    'Supports compression with .gz extension, use - for STDIN'
  ) { |v| o[:in] = v }
  opts.on(
    '-o', '--out FILE',
    'Path to the output FastQ file',
    'Supports compression with .gz extension, use - for STDOUT'
  ) { |v| o[:out] = v }

  opts.separator ''
  opts.separator 'Quality Options'
  opts.on(
    '-q', '--qual INT', Integer,
    "Minimum quality score to allow a base, by default: #{o[:qual]}"
  ) { |v| opts[:qual] = v }
  opts.on(
    '--offset INT', Integer,
    "Q-score offset, by default: #{o[:offset]}"
  ) { |v| opts[:offset] = v }

  opts.separator ''
  opts.separator 'Other Options'
  opts.on('-q', '--quiet', 'Run quietly (no STDERR output)'){ o[:q] = true }
  opts.on('-h', '--help', 'Display this screen') do
    puts opts
    exit
  end
  opts.separator ''
end.parse!

raise Enveomics::OptionError.new('-i is mandatory') if o[:in].nil?
raise Enveomics::OptionError.new('-o is mandatory') if o[:out].nil?
$QUIET = o[:q]

# Open in/out files
say 'Reading FastQ file'
ifh = reader(o[:in])
ofh = writer(o[:out])

# Parse and mask
entry = []
lno = 0
ifh.each_line do |ln|
  lno += 1 # <- Gzip doesn't support $.
  case lno % 4
  when 1
    ln =~ /^@(\S+)/ or
      raise Enveomics::ParseError.new("Unexpected defline format: #{ln}")
    entry << ln
  when 2, 3
    entry << ln
  when 0
    entry << ln
    q = entry[3].chomp.split('').map { |i| (i.ord - o[:offset]) }
    q.map { |i| i < o[:qual] }.each_with_index { |i, k| entry[1][k] = 'N' if i }
    ofh.puts entry
    entry = []
  end
end

# Finalize
say "  Lines: #{lno}"
unless entry.empty?
  raise Enveomics::ParseError.new('Unexpected trailing lines in FastQ')
end
say "  Sequences: #{lno / 4}"
ifh.close
ofh.close

