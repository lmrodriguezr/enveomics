#!/usr/bin/env ruby

#
# @author: Luis M. Rodriguez-R
# @license: artistic-2.0
#

$:.push File.expand_path("../lib", __FILE__)
require "optparse"
require "json"
require "tmpdir"

o = {q:false, n:100, thr:2}
ARGV << "-h" if ARGV.size==0
OptionParser.new do |opts|
  opts.banner = "
Subsamples the genomes in a set of Orthology Groups (OGs) and estimates the
trend of core genome and pangenome sizes.

Usage: #{$0} [options]"
  opts.separator ""
  opts.separator "Mandatory"
  opts.on("-o", "--ogs FILE",
    "Input file containing the precomputed OGs."){ |v| o[:ogs]=v }
  opts.separator ""
  opts.separator "Output Options"
  opts.on("-s", "--summary FILE",
    "Output file in tabular format with summary statistics."){ |v| o[:summ]=v }
  opts.on("-t", "--tab FILE","Output file in tabular format."){ |v| o[:tab]=v }
  opts.on("-j", "--json FILE", "Output file in JSON format."){ |v| o[:json]=v }
  opts.separator ""
  opts.separator "Other Options"
  opts.on("-n", "--replicates INT",
    "Number of replicates to estimate. By default: #{o[:n]}."
    ){ |v| o[:n]=v.to_i }
  opts.on("--threads INT",
    "Children threads to spawn. By default: #{o[:thr]}."){ |v| o[:thr]=v.to_i}
  opts.on("-q", "--quiet", "Run quietly (no STDERR output)."){ o[:q] = true }
  opts.on("-h", "--help", "Display this screen.") do
    puts opts
    exit
  end
  opts.separator ""
end.parse!
abort "-o is mandatory" if o[:ogs].nil?

##### MAIN:
begin
  # Read the pre-computed OGs
  $stderr.puts "Reading pre-computed OGs in '#{o[:ogs]}'." unless o[:q]
  bool_a = []
  genomes_n = nil
  File.open(o[:ogs], "r") do |f|
    h = f.gets.chomp.split "\t"
    genomes_n = h.size
    while ln = f.gets
      bool_a << ln.chomp.split("\t").map{ |g| g!="-" }
    end
  end
  $stderr.puts " Loaded OGs: #{bool_a.size}." unless o[:q]
  bool_a_b = bool_a.map{ |og| og.map{ |g| g ? "1" : "0" }.join("").to_i(2) }

  # Generate subsamples
  size = {core:[], pan:[]}
  Dir.mktmpdir do |dir|
    children = 0
    (0 .. o[:n]-1).each do |i|
      fork do
        # Generate trajectory
        genomes = (0 .. genomes_n-1).to_a.shuffle
        genomes_b = (2 ** genomes_n) - 1
        core = []
        pan = []
        while not genomes.empty?
          core.unshift 0
          pan.unshift 0
          bool_a_b.map! do |og|
            r_og = og & genomes_b
            if r_og>0
              core[0] += 1 if r_og==genomes_b
              pan[0]  += 1
              og
            else
              nil
            end
          end
          bool_a_b.compact!
          genomes_b ^= 2 ** genomes.pop
        end
        abort "UNEXPECTED ERROR: Final genomes_b=#{genomes_b}." if genomes_b>0
        # Store trajectory
        File.open("#{dir}/#{i}", "w") do |tfh|
          tfh.puts JSON.generate({core:core, pan:pan})
        end
      end # fork
      children += 1
      if children >= o[:thr]
        Process.wait
        children -= 1
      end
    end
    Process.waitall
    # Recover trajectories
    (0 .. o[:n]-1).each do |i|
      s = JSON.parse(File.read("#{dir}/#{i}"), {:symbolize_names=>true})
      size[:core][i] = s[:core]
      size[:pan][i] = s[:pan]
    end
  end # Dir.mktmpdir

  # Show result
  $stderr.puts "Generating reports." unless o[:q]

  # Save results in JSON
  unless o[:json].nil?
    ofh = File.open(o[:json], "w")
    ofh.puts JSON.pretty_generate(size)
    ofh.close
  end

  # Save results in tab
  unless o[:tab].nil?
    ofh = File.open(o[:tab], "w")
    ofh.puts (%w{replicate metric}+(1 .. genomes_n).to_a).join("\t")
    (0 .. o[:n]-1).each do |i|
      ofh.puts ([i+1,"core"] + size[:core][i]).join("\t")
      ofh.puts ([i+1,"pan"] + size[:pan][i]).join("\t")
    end
    ofh.close
  end

  # Save summary results in tab
  unless o[:summ].nil?
    ofh = File.open(o[:summ], "w")
    ofh.puts %w{genomes core_avg core_sd core_q1 core_q2 core_q3
      pan_avg pan_sd pan_q1 pan_q2 pan_q3}.join("\t")
    (0 .. genomes_n-1).each do |i|
      res = [ i+1 ]
      [:core, :pan].each do |met|
        a = size[met].map{ |r| r[i] }.sort
        avg = a.inject(0,:+).to_f / a.size
        var = a.map{ |v| v**2 }.inject(0,:+).to_f/a.size - avg**2
        sd = Math.sqrt(var)
        q1 = a[ a.size*1/4 ]
        q2 = a[ a.size*2/4 ]
        q3 = a[ a.size*3/4 ]
        res += [avg,sd,q1,q2,q3]
      end
      ofh.puts res.join("\t")
    end
    ofh.close
  end

  $stderr.puts "Done.\n" unless o[:q] 
rescue => err
  $stderr.puts "Exception: #{err}\n\n"
  err.backtrace.each { |l| $stderr.puts l + "\n" }
  err
end

