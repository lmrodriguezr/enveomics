#!/usr/bin/env ruby

# frozen_string_literal: false

$VERSION = 1.0
$:.push File.expand_path('../lib', __FILE__)
require 'enveomics_rb/enveomics'

o = { q: false, rep: false }

OptionParser.new do |opt|
  Enveomics.opt_banner(
    opt, 'Samples a random set of sequences from a multi-FastA file',
    "#{File.basename($0)} -i seq.fa -o 10pc.fa -f 0.1 [options]"
  )
  opt.separator 'Mandatory'
  opt.on(
    '-i', '--in PATH',
    'Input FastA file',
    'Supports compression with .gz extension, use - for STDIN'
  ) { |v| o[:i] = v }
  opt.on(
    '-o', '--out PATH',
    'Output FastA file',
    'Supports compression with .gz extension, use - for STDOUT'
  ) { |v| o[:o] = v }
  opt.on(
    '-f', '--fraction FLOAT', Float,
    'Fraction of sequences to sample [0-1].',
    'Mandatory unless -c is provided.'
  ) { |v| o[:f] = v }
  opt.separator ''

  opt.separator 'Options'
  opt.on(
    '-c', '--number INT', Integer,
    'Number of sequences to sample',
    'Mandatory unless -f is provided'
  ) { |v| o[:n] = v }
  opt.on('-r', '--replacement','Sample with replacement') { |v| o[:rep] = v }
  opt.on('-q', '--quiet', 'Run quietly (no STDERR output)') { o[:q] = true }
  opt.on('-h', '--help', 'Display this screen.') do
    puts opt
    exit
  end
  opt.separator ''
end.parse!

raise Enveomics::OptionError.new('-i is mandatory') if o[:i].nil?
raise Enveomics::OptionError.new('-o is mandatory') if o[:o].nil?
if o[:f].nil? && o[:n].nil?
  raise Enveomics::OptionError.new('-f or -n is mandatory')
end
$QUIET = o[:q]

# Functions to parse sequences
def do_stuff(id, sq)
  return if id.nil? or sq.empty?
  @n_in += 1
  sq.gsub!(/[^A-Za-z]/, '')
  i = 0
  @coll.extract(id, sq).each do |new_sq|
    @ofh.puts ">#{id}:#{i += 1}"
    @ofh.puts new_sq
    @n_out += 1
  end
end

# Parse sequences
say 'Parsing sequences'
seq = []
fh = reader(o[:i])
id = nil
sq = ''
fh.each do |ln|
  next if ln =~ /^;/
  if ln =~ /^>(.+)/
    seq << [id, sq] unless id.nil?
    id = $1
    sq = ''
  else
    sq << ln
  end
end
seq << [id, sq] unless id.nil?
fh.close
say "Input sequences: #{seq.size}"

o[:n] ||= (seq.size * o[:f]).round
seq_o = o[:rep] ? o[:n].times.map { seq.sample } : seq.sample(o[:n])
fh = writer(o[:o])
seq_o.each do |i|
  fh.puts ">#{i[0]}"
  fh.puts i[1]
end
fh.close
say "Output sequences: #{seq_o.size}"

