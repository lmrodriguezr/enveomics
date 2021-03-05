#!/usr/bin/env ruby

# frozen_string_literal: true

$:.push File.expand_path('../lib', __FILE__)
require 'enveomics_rb/enveomics'
require 'enveomics_rb/stats'
$VERSION = 1.0

o = { q: false, completeness: nil, minlen: 500, shuffle: true }
OptionParser.new do |opts|
  opts.version = $VERSION
  Enveomics.opt_banner(
    opts, 'Simulates incomplete (fragmented) drafts from complete genomes',
    "#{File.basename($0)} -i in.fasta -o out.fasta -c 0.5 [options]"
  )

  opts.separator 'Mandatory'
  opts.on(
    '-i', '--in FILE',
    'Path to the FastA file containing the complete sequences',
    'Supports compression with .gz extension, use - for STDIN'
  ) { |v| o[:in] = v }
  opts.on(
    '-o', '--out FILE', 'Path to the FastA to create',
    'Supports compression with .gz extension, use - for STDOUT'
  ) { |v| o[:out] = v }
  opts.on(
    '-c', '--completeness FLOAT',
    'Fraction of genome completeness to simulate from 0 to 1'
  ) { |v| o[:completeness] = v.to_f }

  opts.separator ''
  opts.separator 'Options'
  opts.on(
    '-m', '--minlen INT',
    "Minimum fragment length to report. By default: #{o[:minlen]}"
  ) { |v| o[:minlen] = v.to_i }
  opts.on(
    '-s', '--sorted', 'Keep fragments sorted as in the input file',
    'By default, fragments are shuffled'
  ) { |v| o[:shuffle] = !v }
  opts.on('-q', '--quiet', 'Run quietly (no STDERR output)') { o[:q] = true }
  opts.on('-h', '--help', 'Display this screen') { puts opts ; exit }
  opts.separator ''
end.parse!

raise Enveomics::OptionError.new('-i is mandatory') if o[:in].nil?
raise Enveomics::OptionError.new('-o is mandatory') if o[:out].nil?
raise Enveomics::OptionError.new('-c is mandatory') if o[:completeness].nil?

begin
  # Read input sequences
  g_id  = []
  g_seq = []
  ifh = reader(o[:in])
  id = ''
  ifh.each_line do |ln|
    if ln =~ /^>(\S*)/
      g_id  << $1
      g_seq << ''
    else
      g_seq[g_seq.size - 1] += ln.gsub(/[^A-Za-z]/, '')
    end
  end
  ifh.close

  # Fragment genomes
  f = {}
  binlen = [1, (o[:minlen].to_f/(1.5**2)).ceil].max
  p = [0.001, [1.0, 1.0 - (o[:completeness]/1.25 + 0.1)].min].max
  while !g_seq.empty?
    id  = g_id.shift
    seq = g_seq.shift
    gL  = seq.length
    while !seq.empty?
      rand_x =
        Enveomics::Stats.r_geom(p).to_f + Enveomics::Stats.r_unif(-0.5, 0.5)
      fL = [0, (rand_x * binlen).round].max
      f["#{f.size+1}_#{id}"] = seq[0, fL] if fL >= o[:minlen]
      seq = seq[(fL + 1) .. -1]
      seq = '' if seq.nil?
    end
  end

  # Save output
  k = f.keys
  k.shuffle! if o[:shuffle]
  ofh = writer(o[:out])
  k.each do |id|
    ofh.puts ">#{id}"
    ofh.puts f[id].gsub(/(\S{50})/, "\\1\n")
  end
  ofh.close
rescue => err
  $stderr.puts "Exception: #{err}\n\n"
  err.backtrace.each { |l| $stderr.puts l + "\n" }
  err
end

