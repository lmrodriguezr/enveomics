#!/usr/bin/env ruby

#
# @author Luis M. Rodriguez-R <lmrodriguezr at gmail dot com>
# @license Artistic-2.0
#

require 'optparse'

o = {q: false}
ARGV << '-h' if ARGV.size==0

OptionParser.new do |opt|
  opt.banner = "
Extracts a list of sequences and/or coordinates from multi-FastA files.

Usage: #{$0} [options]"
  opt.separator ''
  opt.separator 'Mandatory'
  opt.on('-i', '--in PATH', 'Input FastA file.'){ |v| o[:i] = v }
  opt.on('-o', '--out PATH', 'Output FastA file.'){ |v| o[:o] = v }
  opt.on('-c', '--coords STRING',
    'Comma-delimited list of coordinates (mandatory unless -C is passed).',
    'The format of the coordinates is "SEQ:FROM..TO" or "SEQ:FROM~LEN":',
    'SEQ: Sequence ID, or * (asterisk) to extract range from all sequences',
    'FROM: Integer, position of the first base to include (can be negative)',
    'TO: Integer, last base to include (can be negative)',
    'LEN: Length of the range to extract'
    ){ |v| o[:c] = v }
  opt.separator ''
  opt.separator 'Options'
  opt.on('-C', '--coords-file PATH',
    'File containing the coordinates, one per line.',
    'Each line must follow the format described for -c.'){ |v| o[:C] = v }
  opt.on('-q', '--quiet', 'Run quietly (no STDERR output).'){ o[:q] = true }
  opt.on('-h', '--help', 'Display this screen.') do
    puts opt
    exit
  end
  opt.separator ''
end.parse!
abort '-i is mandatory.' if o[:i].nil?
abort '-o is mandatory.' if o[:o].nil?
abort '-c is mandatory.' if o[:c].nil? and o[:C].nil?

# Classses to parse coordinates
class SeqCoords
  attr :id, :from, :to, :length, :str
  def initialize(str)
    @str = str
    m = /(\S+):(-?\d+)(~|\.\.)(-?\d+)/.match str
    raise "Cannot parse coordinates: #{str}" if m.nil?
    @id = m[1]
    @from = m[2].to_i
    if m[3] == '~'
      @length = m[4].to_i
    else
      @to = m[4].to_i
    end
  end

  def extract(id, seq)
    return nil unless concerns? id
    from_i = from > 0 ? from : seq.length + 1 + from
    if to.nil?
      seq[from_i, length]
    else
      to_i = to > 0 ? to : seq.length + 1 + to
      seq[from_i .. to_i]
    end
  end

  def concerns?(seq_id)
    return true if id == '*'
    return id == seq_id
  end
end

class SeqCoordsCollection
  class << self
    def from_str(str)
      c = new
      str.split(',').each { |i| c << SeqCoords.new(i) }
      c
    end
    def from_file(path)
      c = new
      File.open(path, 'r') do |fh|
        fh.each{ |i| c << SeqCoords.new(i.chomp) }
      end
      c
    end
  end

  attr :collection

  def initialize
    @collection = []
  end

  def <<(coords)
    @collection << coords
  end

  def extract(id, seq)
    @collection.map{ |c| c.extract(id, seq) }.compact
  end
end

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

# Parse coordinates
$stderr.puts 'Parsing coordinates' unless o[:q]
@coll = o[:c].nil? ? SeqCoordsCollection.from_file(o[:C]) :
  SeqCoordsCollection.from_str(o[:c])
$stderr.puts "  Coordinates found: #{@coll.collection.size}"

# Parse sequences
$stderr.puts 'Parsing sequences' unless o[:q]
@n_in = 0
@n_out = 0
@ofh = File.open(o[:o], 'w')
File.open(o[:i], 'r') do |fh|
  id = nil
  sq = ''
  fh.each do |ln|
    next if ln =~ /^;/
    if ln =~ /^>(\S+)/
      id = $1
      do_stuff(id, sq)
      sq = ''
    else
      sq << ln
    end
  end
  do_stuff(id, sq)
end
@ofh.close
$stderr.puts "  Input sequences: #{@n_in}"
$stderr.puts "  Output fragments: #{@n_out}"

