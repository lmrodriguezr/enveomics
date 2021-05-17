#!/usr/bin/env ruby

# frozen_string_literal: true

$:.push File.expand_path('../lib', __FILE__)
require 'enveomics_rb/enveomics'
require 'enveomics_rb/match'
$VERSION = 1.0

o = { n: 5, sortby: :bitscore, out: '-' }
OptionParser.new do |opts|
  opts.version = $VERSION
  Enveomics.opt_banner(
    opts, 'Reports the top-N best hits of a BLAST, pre-sorted by query',
    "#{File.basename($0)} -i in.tsv -o out.tsv [options]"
  )
  
  opts.separator 'Mandatory'
  opts.on(
    '-i', '--blast FILE',
    'Path to the BLAST file',
    'Supports compression with .gz extension, use - for STDIN'
  ) { |v| o[:in] = v }
  opts.on(
    '-o', '--out FILE',
    'Output filtered BLAST file',
    'Supports compression with .gz extension, use - for STDOUT (default)'
  ) { |v| o[:out] = v }
  opts.separator ''
  opts.separator 'Filter Options'
  opts.on(
    '-n', '--top INTEGER', Integer,
    'Maximum number of hits to report for each query',
    "By default: #{o[:n]}"
  ) { |v| o[:n] = v }
  opts.on(
    '-s', '--sort-by STRING',
    'Parameter used to detect the "best" hits',
    'Any of: bitscore (default), evalue, identity, length, no (pick first)'
  ) { |v| o[:sortby] = v.to_sym }
  opts.separator ''
  opts.separator 'Other Options'
  opts.on('-q', '--quiet', 'Run quietly (no STDERR output)') { $QUIET = true }
  opts.on('-h', '--help', 'Display this screen') { puts opts; exit }
  opts.separator ''
end.parse!

raise Enveomics::OptionError.new('-i is mandatory') if o[:in].nil?
unless o[:sortby] == :no || Enveomics::Match.column(o[:sortby])
  raise Enveomics::OptionError.new("Unrecognized value for -s: #{o[:sortby]}")
end

class Enveomics::Match
  attr_accessor :sortby

  def <=>(other)
    ans = send(sortby) <=> other.send(sortby)
    sortby == :evalue ? ans : ans * -1
  end
end

class Enveomics::MatchSet
  attr_reader :query, :hits, :sortby

  def initialize(sortby)
    @hits = []
    @query = nil
    @sortby = sortby
  end

  def <<(hit)
    @query ||= hit.qry
    unless query == hit.qry
      raise "Inconsistent query, expecting #{query}"
    end

    @hits << hit.tap { |i| i.sortby = sortby }
  end

  def empty?
    hits.empty?
  end

  def filter!(n)
    @hits.sort! unless sortby == :no
    @hits.slice!(n, @hits.length)
  end

  def to_s
    hits.join("\n")
  end
end

begin
  ifh = reader(o[:in])
  ofh = writer(o[:out])

  say 'Parsing BLAST'
  hs = Enveomics::MatchSet.new(o[:sortby])
  lno = 0
  ifh.each do |ln|
    lno += 1
    hit = Enveomics::Match.new(ln)
    if hs.query != hit.qry
      hs.filter! o[:n]
      ofh.puts hs unless hs.empty?
      hs = Enveomics::MatchSet.new(o[:sortby])
      say_inline("Parsing line #{lno}... \r")
    end
    hs << hit
  end
  say("Parsed #{lno} lines    ")
  ifh.close

  hs.filter! o[:n]
  ofh.puts hs unless hs.empty?
  ofh.close
rescue => err
  $stderr.puts "Exception: #{err}\n\n"
  err.backtrace.reverse.each { |l| $stderr.puts "DEBUG: %s\n" % l }
  err
end

