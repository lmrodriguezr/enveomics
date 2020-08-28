#!/usr/bin/env ruby

# frozen_string_literal: true

$VERSION = 1.0
$:.push File.expand_path('../lib', __FILE__)
require 'enveomics_rb/enveomics'
use 'shellwords'

o = {
  q: false, threads: 2, m_format: :sam, g_format: :fasta, identity: 95.0,
  o: '-', header: true
}

OptionParser.new do |opt|
  Enveomics.opt_banner(
    opt, 'Filters a SAM or BAM file by target sequences and/or identity',
    "#{File.basename($0)} -m map.sam -o filtered_map.sam [options]"
  )

  opt.separator 'Input/Output'
  opt.on(
    '-g', '--genome PATH',
    'Genome assembly',
    'Supports compression with .gz extension, use - for STDIN'
  ) { |v| o[:g] = v }
  opt.on(
    '-m', '--mapping PATH',
    'Mapping file',
    'Supports compression with .gz extension, use - for STDIN'
  ) { |v| o[:m] = v }
  opt.on(
    '-o', '--out-sam PATH',
    'Output filtered file in SAM format',
    'Supports compression with .gz extension, use - for STDOUT (default)'
  ) { |v| o[:o] = v }
  opt.separator ''

  opt.separator 'Formats'
  opt.on(
    '--g-format STRING',
    'Genome assembly format: fasta (default) or list'
  ) { |v| o[:g_format] = v.downcase.to_sym }
  opt.on(
    '--m-format STRING',
    'Mapping file format: sam (default) or bam',
    'sam supports compression with .gz file extension'
  ) { |v| o[:m_format] = v.downcase.to_sym }
  opt.separator ''

  opt.separator 'General'
  opt.on(
    '-i', '--identity FLOAT', Float,
    "Set a fixed threshold of percent identity (default: #{o[:identity]})"
  ) { |v| o[:identity] = v }
  opt.on('--no-header', 'Do not include the headers') { |v| o[:header] = v }
  opt.separator ''
  opt.on(
    '-t', '--threads INT', Integer, "Threads to use (default: #{o[:threads]})"
  ) { |v| o[:threads] = v }
  opt.on('-l', '--log PATH', 'Log file to save output') { |v| o[:log] = v }
  opt.on('-q', '--quiet', 'Run quietly') { |v| o[:q] = v }
  opt.on('-h', '--help', 'Display this screen') do
    puts opt
    exit
  end
  opt.separator ''
end.parse!

$QUIET = o[:q]

# Functions

##
# Parses one line +ln+ in SAM format and outputs filtered lines to +ofh+
# Filters by minimum +identity+ and +target+ sequences, and prints
# the headers if +header+
def parse_sam_line(ln, identity, target, header, ofh)
  if ln =~ /^@/ || ln =~ /^\s*$/
    ofh.puts ln if header
    return
  end

  # No match
  row = ln.chomp.split("\t")
  return if row[2] == '*'

  # Filter by target
  return if !target.nil? && !target.include?(row[2])

  # Exclude unless concordant or unaligned
  length = row[9].size
  row.shift(11) # Discard non-flag columns
  flags = Hash[row.map { |i| i.sub(/:.:/, ':').split(':', 2) }]
  return if flags['YT'] && !%w[CP UU].include?(flags['YT'])

  # Filter by identity
  unless flags['MD']
    raise Enveomics::ParseError.new(
      "SAM line missing MD flag:\n#{ln}\nFlags: #{flags}"
    )
  end
  mismatches = flags['MD'].scan(/[^\d]/).count
  id = 100.0 * (length - mismatches) / length
  ofh.puts ln if id >= identity
end

# Reading targets
if o[:g]
  say 'Loading target sequences to filter'
  reader = reader(o[:g])
  target =
    case o[:g_format]
    when :fasta
      reader.each.map { |ln| $1 if ln =~ /^>(\S+)/ }.compact
    when :list
      reader.each.map(&:chomp)
    else
      raise Enveomics::OptionError.new(
        "Unsupported target sequences format: #{o[:g_format]}"
      )
    end
  reader.close
else
  target = nil
end

# Reading and filtering mapping
say 'Reading mapping file'
ofh = writer(o[:o])
case o[:m_format]
when :sam
  reader = reader(o[:m])
  reader.each { |ln| parse_sam_line(ln, o[:identity], target, o[:header], ofh) }
  reader.close
when :bam
  cmd = ['samtools', 'view', o[:m], '-@', o[:threads]]
  cmd << '-h' if o[:header]
  IO.popen(cmd.shelljoin) do |fh|
    fh.each { |ln| parse_sam_line(ln, o[:identity], target, o[:header], ofh) }
  end
else
  raise Enveomics::OptionError.new(
    "Unsupported mapping format: #{o[:m_format]}"
  )
end
ofh.close

