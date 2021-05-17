#!/usr/bin/env ruby

# frozen_string_literal: true

$VERSION = 1.01
$:.push File.expand_path('../lib', __FILE__)
require 'enveomics_rb/rbm'
require 'tmpdir'

bms_dummy = Enveomics::RBM.new('1', '2').bms1
o = { q: false, out: '-' }
%i[thr len id fract score bin program nucl].each do |k|
  o[k] = bms_dummy.opt(k)
end

OptionParser.new do |opts|
  opts.version = $VERSION
  cmd = File.basename($0)
  opts.banner = <<~BANNER

    [Enveomics Collection: #{cmd} v#{$VERSION}]

    Finds the reciprocal best matches between two sets of sequences

    Usage: #{cmd} [options]

  BANNER

  opts.separator 'Mandatory'
  opts.on(
    '-1', '--seq1 FILE',
    'Path to the FastA file containing the set 1'
  ) { |v| o[:seq1] = v }
  opts.on(
    '-2', '--seq2 FILE',
    'Path to the FastA file containing the set 2'
  ) { |v| o[:seq2] = v }
  opts.on(
    '-o', '--out FILE',
    'Reciprocal Best Matches in BLAST tabular format.',
    'Supports compression with .gz extension, use - for STDOUT (default)'
  ) { |v| o[:out] = v }
  opts.separator ''
  opts.separator 'Search Options'
  opts.on(
    '-n', '--nucl',
    'Sequences are assumed to be nucleotides (proteins by default)',
    'Incompatible with -p diamond'
  ) { |v| o[:nucl] = true }
  opts.on(
    '-l', '--len INT', Integer,
    'Minimum alignment length (in residues)',
    "By default: #{o[:len]}"
  ) { |v| o[:len] = v }
  opts.on(
    '-f', '--fract FLOAT', Float,
    'Minimum alignment length (as a fraction of the query)',
    'If set, requires BLAST+ or Diamond (see -p)',
    "By default: #{o[:fract]}"
  ) { |v| o[:fract] = v }
  opts.on(
    '-i', '--id NUM', Float,
    'Minimum alignment identity (in %)',
    "By default: #{o[:id]}"
  ){ |v| o[:id] = v }
  opts.on(
    '-s', '--score NUM', Float,
    'Minimum alignment score (in bits)',
    "By default: #{o[:score]}"
  ) { |v| o[:score] = v }
  opts.separator ''
  opts.separator 'Software Options'
  opts.on(
    '-b', '--bin DIR',
    'Path to the directory containing the binaries of the search program'
  ) { |v| o[:bin] = v }
  opts.on(
    '-p', '--program STR',
    'Search program to be used',
    'One of: blast+ (default), blast, diamond, blat'
  ) { |v| o[:program] = v.downcase.to_sym }
  opts.on(
    '-t', '--threads INT', Integer,
    'Number of parallel threads to be used',
    "By default: #{o[:thr]}"
  ) { |v| o[:thr] = v }
  opts.separator ''
  opts.separator 'Other Options'
  opts.on('-q', '--quiet', 'Run quietly (no STDERR output)') { $QUIET = true }
  opts.on('-h', '--help', 'Display this screen') { puts opts ; exit }
  opts.separator ''
end.parse!

raise Enveomics::OptionError.new('-1 is mandatory') if o[:seq1].nil?
raise Enveomics::OptionError.new('-2 is mandatory') if o[:seq2].nil?
raise Enveomics::OptionError.new(
  'Argument -f/--fract requires -p blast+ or -p diamond'
) if o[:fract] > 0.0 && !%i[blast+ diamond].include?(o[:program])

rbm = Enveomics::RBM.new(o[:seq1], o[:seq2], o)
ofh = writer(o[:out])
rbm.each { |bm| ofh.puts bm.to_s }
ofh.close

say('Forward Best Matches: ', rbm.bms1.count)
say('Reverse Best Matches: ', rbm.bms2.count)
say('Reciprocal Best Matches: ', rbm.count)

