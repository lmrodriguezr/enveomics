#!/usr/bin/env ruby

#
# @author Luis M. Rodriguez-R <lmrodriguezr at gmail dot com>
# @license Artistic-2.0
#

require 'optparse'

o = {q: false, rep: false}
ARGV << '-h' if ARGV.size==0

OptionParser.new do |opt|
  opt.banner = "
Samples a random set of sequences from a multi-FastA file.

Usage: #{$0} [options]"
  opt.separator ''
  opt.separator 'Mandatory'
  opt.on('-i', '--in PATH', 'Input FastA file.'){ |v| o[:i] = v }
  opt.on('-o', '--out PATH', 'Output FastA file.'){ |v| o[:o] = v }
  opt.on('-f', '--fraction FLOAT',
    'Fraction of sequences to sample [0-1].',
    'Mandatory unless -c is provided.'){ |v| o[:f] = v.to_f }
  opt.separator ''
  opt.separator 'Options'
  opt.on('-c', '--number INT',
    'Number of sequences to sample.',
    'Mandatory unless -f is provided.'){ |v| o[:n] = v.to_i }
  opt.on('-r', '--replacement','Sample with replacement'){ |v| o[:rep] = v }
  opt.on('-q', '--quiet', 'Run quietly (no STDERR output).'){ o[:q] = true }
  opt.on('-h', '--help', 'Display this screen.') do
    puts opt
    exit
  end
  opt.separator ''
end.parse!
abort '-i is mandatory.' if o[:i].nil?
abort '-o is mandatory.' if o[:o].nil?
abort '-f or -n is mandatory.' if o[:f].nil? and o[:n].nil?

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
$stderr.puts 'Parsing sequences' unless o[:q]
seq = []
File.open(o[:i], 'r') do |fh|
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
end
$stderr.puts "  Input sequences: #{seq.size}"
o[:n] ||= (seq.size * o[:f]).round
seq_o = o[:rep] ? o[:n].times.map{ seq.sample } : seq.sample(o[:n])
File.open(o[:o], 'w') do |fh|
  seq_o.each do |i|
    fh.puts ">#{i[0]}"
    fh.puts i[1]
  end
end
$stderr.puts "  Output sequences: #{seq_o.size}"

