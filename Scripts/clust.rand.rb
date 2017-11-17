#!/usr/bin/env ruby

#
# @author: Luis M. Rodriguez-R
# @license: artistic license 2.0
#

require "optparse"

o = { q:false, prec:6 }
ARGV << "-h" if ARGV.empty?
OptionParser.new do |opts|
   opts.banner = "
Calculates the Rand Index and the Adjusted Rand Index between two clusterings.

The clustering format is a raw text file with one cluster per line, each
defined as comma-delimited members, and a header line (ignored). Note that this
is equivalent to the OGs format for 1 genome.

Usage: #{$0} [options]"
  opts.separator ""
  opts.separator "Mandatory"
  opts.on("-1", "--clust1 FILE", "First input file."){ |v| o[:clust1]=v }
  opts.on("-2", "--clust2 FILE", "Second input file."){ |v| o[:clust2]=v }
  opts.separator ""
  opts.separator "Other options"
  opts.on("-p", "--prec INT",
    "Precision to report. By default: #{o[:prec]}"){ |v| o[:prec]=v.to_i }
  opts.on("-q", "--quiet", "Run quietly (no STDERR output)."){ o[:q] = true }
  opts.on("-h", "--help", "Display this screen.") do
    puts opts
    exit
  end
  opts.separator ""
end.parse!
abort "-1 is mandatory" if o[:clust1].nil?
abort "-2 is mandatory" if o[:clust2].nil?

def load_clust(file, q)
  $stderr.puts "Reading clusters in '#{file}'." unless q
  out = []
  File.open(file, "r") do |fh|
    fh.each_line do |ln|
      next if $.==1
      out[$.-2] = ln.chomp.split(",")
    end
  end
  $stderr.puts " Loaded clusters: #{out.size}." unless q
  out
end

def choose_2(n)
  return 0 if n<2
  n*(n-1)/2
end

##### MAIN:
begin
  # Read the pre-computed OGs
  clust1 = load_clust(o[:clust1], o[:q])
  clust2 = load_clust(o[:clust2], o[:q])
  
  # Contingency table
  $stderr.puts "Estimating the contingency table." unless o[:q]
  cont = []
  b_sums = []
  clust1.each_with_index do |x_i, i|
    cont[i] = []
    clust2.each_with_index do |y_j, j|
      cont[i][j] = (x_i & y_j).size
      b_sums[j]||= 0
      b_sums[j] += cont[i][j]
    end
  end
  a_sums = cont.map{ |i| i.inject(:+) }

  # Calculate variables
  # - see http://i11www.iti.kit.edu/extra/publications/ww-cco-06.pdf
  $stderr.puts "Estimating indexes." unless o[:q]
  n = clust1.map{ |i| i.size }.inject(:+)
  pairs = choose_2(n)
  n11 = clust1.each_index.map do |i|
    clust2.each_index.map do |j|
      choose_2(cont[i][j])
    end.inject(:+)
  end.inject(:+).to_f
  t1 = a_sums.map{ |a_i| choose_2(a_i) }.inject(:+).to_f
  t2 = b_sums.map{ |b_j| choose_2(b_j) }.inject(:+).to_f
  t3 = 2*t1*t2/(n*(n-1))
  n00 = pairs + n11 - t1 - t2
  r_index = (n11 + n00)/pairs
  r_adjusted = (n11 - t3)/((t1+t2)/2 - t3)
  
  # Report
  puts "Rand Index = %.#{o[:prec]}f" % r_index
  puts "Adjusted Rand Index = %.#{o[:prec]}f" % r_adjusted
rescue => err
  $stderr.puts "Exception: #{err}\n\n"
  err.backtrace.each { |l| $stderr.puts l + "\n" }
  err
end

