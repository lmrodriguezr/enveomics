#!/usr/bin/env ruby

# @author  Luis M. Rodriguez-R
# @license artistic license 2.0

$:.push File.expand_path("../lib", __FILE__)
require "enveomics_rb/enveomics"
require "enveomics_rb/stat"

o = {q:false, completeness:nil, minlen:500, shuffle:true}
OptionParser.new do |opts|
  opts.banner = "
Simulates incomplete (fragmented) drafts from complete genomes.

Usage: #{$0} [options]"
  opts.separator ""
  opts.separator "Mandatory"
  opts.on("-i", "--in FILE",
    "Path to the FastA file containing the complete sequences."
    ){ |v| o[:in] = v }
  opts.on("-o", "--out FILE", "Path to the FastA to create."){ |v| o[:out] = v }
  opts.on("-c", "--completeness FLOAT",
    "Fraction of genome completeness to simulate from 0 to 1."
    ){ |v| o[:completeness] = v.to_f }
  opts.separator ""
  opts.separator "Options"
  opts.on("-m", "--minlen INT",
    "Minimum fragment length to report. By default: #{o[:minlen]}."
    ){ |v| o[:minlen] = v.to_i }
  opts.on("-s", "--sorted", "Keep fragments sorted as in the input file. ",
    "By default, fragments are shuffled."){ |v| o[:shuffle] = !v }
  opts.on("-q", "--quiet", "Run quietly (no STDERR output)"){ o[:q] = true }
  opts.on("-h", "--help", "Display this screen") do
    puts opts
    exit
  end
  opts.separator ""
end.parse!
abort "-i is mandatory" if o[:in].nil?
abort "-o is mandatory" if o[:out].nil?
abort "-c is mandatory" if o[:completeness].nil?

begin
  # Read input sequences
  g_id  = []
  g_seq = []
  File.open(o[:in], "r") do |ifh|
    id = ""
    ifh.each_line do |ln|
      if ln =~ /^>(\S*)/
        g_id  << $1
        g_seq << ""
      else
        g_seq[g_seq.size-1] += ln.gsub(/[^A-Za-z]/,"")
      end
    end
  end
  
  # Fragment genomes
  f = {}
  binlen = [1, (o[:minlen].to_f/(1.5**2)).ceil].max
  p = [0.001, [1.0, 1.0 - (o[:completeness]/1.25 + 0.1)].min].max
  while not g_seq.empty?
    id  = g_id.shift
    seq = g_seq.shift
    gL  = seq.length
    while not seq.empty?
      fL = [0, ((Enve::Stat.r_geom(p).to_f +
                  Enve::Stat.r_unif(-0.5,0.5))*binlen).round].max
      f["#{f.size+1}_#{id}"] = seq[0,fL] if fL >= o[:minlen]
      seq = seq[(fL+1) .. -1]
      seq = "" if seq.nil?
    end
  end

  # Save output
  k = f.keys
  k.shuffle! if o[:shuffle]
  File.open(o[:out], "w") do |ofh|
    k.each do |id|
      ofh.puts ">#{id}"
      ofh.puts f[id].gsub(/(\S{50})/, "\\1\n")
    end
  end
  
rescue => err
   $stderr.puts "Exception: #{err}\n\n"
   err.backtrace.each { |l| $stderr.puts l + "\n" }
   err
end


