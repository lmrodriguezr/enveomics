#!/usr/bin/env ruby

require 'optparse'

o = {q:false, key:2}
ARGV << '-h' if ARGV.empty?
OptionParser.new do |opts|
   opts.banner = "
Compares the estimated error of sequencing reads (Q-score) with
observed mismatches (identity against a know reference sequence).

Usage: #{$0} [options]"
  opts.separator ""
  opts.separator "Mandatory"
  opts.on("-f", "--fastq FILE",
       "Path to the FastQ file containing the sequences."){ |v| o[:fastq] = v }
  opts.on("-b", "--blast FILE",
       "Path to the tabular BLAST file mapping reads to reference sequences."
       ){ |v| o[:blast] = v }
  opts.on("-o", "--out FILE",
      "Path to the output tab-delimited file to create."){ |v| o[:out] = v }
  opts.separator ""
  opts.separator "Other Options"
  opts.on("-q", "--quiet", "Run quietly (no STDERR output)"){ o[:q] = TRUE }
  opts.on("-h", "--help", "Display this screen") do
    puts opts
    exit
  end
  opts.separator ""
end.parse!
abort "-f is mandatory" if o[:fastq].nil?
abort "-b is mandatory" if o[:blast].nil?
abort "-o is mandatory" if o[:out].nil?

# Read the Q scores and estimate expected mismatches
mm = {} # <- Hash with read IDs as key, and arrays as values:
        #    [ expected mismatches, variance of mismatches, length ]
$stderr.puts "Reading FastQ file" unless o[:q]
File.open(o[:fastq], "r") do |fh|
  id = nil
  fh.each_line do |ln|
    case $.%4
    when 1
      ln =~ /^@(\S+)/ or raise "Unexpected defline format: #{ln}"
      id = $1
      $stderr.print " #{mm.size} reads...\r" unless o[:q]
    when 0
      ln.chomp!
      # I'm assuming ALWAYS Phred+33!!!
      p = ln.split('').map{ |i| (i.ord - 33).to_f }.map{ |q| 10.0**(-q/10.0) }
      mu = p.inject(:+)
      var = p.map{ |i| i*(1.0-i) }.inject(:+)
      mm[id] = [mu, var, p.size]
    end
  end
  $stderr.puts " Found: #{mm.size} reads." unless o[:q]
end

ofh = File.open(o[:out], "w")
ofh.puts %w[id obs_subs obs_id aln_len obs_ins obs_del obs_gap mu var len].join("\t")

# Read Identities and compare against expectation
$stderr.puts "Reading Tabular BLAST file" unless o[:q]
File.open(o[:blast], "r") do |fh|
  k = 0
  fh.each_line do |ln|
    r = ln.chomp.split("\t")
    id = r[0]
    next if mm[id].nil?
    k += 1
    $stderr.print " #{k} alignments...\r" unless o[:q]
    obs_m = r[4].to_i + (r[6].to_i - 1) + (mm[id][2] - r[7].to_i)
    obs_del = r[3].to_i - (r[7].to_i - r[6].to_i).abs
    obs_ins = r[3].to_i - (r[9].to_i - r[8].to_i).abs
    ofh.puts ([id, obs_m, r[2], r[7].to_i - r[6].to_i + 1,
          obs_ins, obs_del, r[5]] + mm[id]).join("\t")
  end
  $stderr.puts " Found #{k} alignments." unless o[:q]
end

ofh.close
