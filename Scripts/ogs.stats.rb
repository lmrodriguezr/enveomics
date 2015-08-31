#!/usr/bin/env ruby

#
# @author: Luis M. Rodriguez-R
# @update: Aug-30-2015
# @license: artistic license 2.0
#

$:.push File.expand_path(File.dirname(__FILE__) + '/lib')
require 'enveomics_rb/og'
require 'optparse'
require 'json'

o = {q:false, a:false}
ARGV << '-h' if ARGV.size==0
OptionParser.new do |opts|
   opts.banner = "
Estimates some descriptive statistics on a set of Orthology Groups (OGs).

Usage: #{$0} [options]"
   opts.separator ""
   opts.separator "Mandatory"
   opts.on("-o", "--ogs FILE",
      "Input file containing the precomputed OGs."){ |v| o[:ogs]=v }
   opts.separator ""
   opts.separator "Other Options"
   opts.on("-j", "--json FILE", "Output file in JSON format."){ |v| o[:json]=v }
   opts.on("-t", "--tab FILE","Output file in tabular format."){ |v| o[:tab]=v }
   opts.on("-T", "--transposed-tab FILE",
      "Output file in transposed tabular format."){ |v| o[:ttab]=v }
   opts.on("-a", "--auto", "Run completely quiertly (no STDERR or STDOUT)") do
      o[:q] = true
      o[:a] = true
   end
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
   # Initialize the collection of OGs.
   collection = OGCollection.new
   
   # Read the pre-computed OGs
   $stderr.puts "Reading pre-computed OGs in '#{o[:ogs]}'." unless o[:q]
   f = File.open(o[:ogs], "r")
   h = f.gets.chomp.split /\t/
   while ln = f.gets
      collection << OG.new(h, ln.chomp.split(/\t/))
   end
   f.close
   $stderr.puts " Loaded OGs: #{collection.ogs.length}." unless o[:q]
   
   # Estimate descriptive stats
   stat_name = {
      genomes: "Number of genomes",
      pangenome: "Pangenome (OGs)",
      core_genome: "Core genome (OGs)",
      core90pc_genome: "OGs in 90% of the genomes",
      core80pc_genome: "OGs in 80% of the genomes",
      avg_genome: "Average number of OGs in a genome",
      avg_shared: "Average fraction of genomes per OG",
      core_avg: "Core genome (OGs) / Average genome (OGs)"
   }
   stats = {}
   stats[:genomes] = Gene.genomes.length
   stats[:pangenome] = collection.ogs.length
   stats[:core_genome] = collection.ogs.map do |og|
      (og.genomes.length == Gene.genomes.length) ? 1 : 0
   end.inject(0,:+)
   stats[:core90pc_genome] = collection.ogs.map do |og|
      (og.genomes.length >= 0.9*Gene.genomes.length) ? 1 : 0
   end.inject(0,:+)
   stats[:core80pc_genome] = collection.ogs.map do |og|
      (og.genomes.length >= 0.8*Gene.genomes.length) ? 1 : 0
   end.inject(0,:+)
   og_genomes = collection.ogs.map{ |og| og.genomes.length }.inject(0,:+)
   stats[:avg_genome] = og_genomes.to_f/Gene.genomes.length
   stats[:avg_shared] = stats[:avg_genome]/stats[:pangenome]
   stats[:core_avg] = stats[:core_genome].to_f/stats[:avg_genome]

   # Show result
   $stderr.puts "Generating reports." unless o[:q]
   stats.each_pair{ |k,v| puts " #{stat_name[k]}: #{v}" } unless o[:a]

   # Save results in JSON
   unless o[:json].nil?
      ohf = File.open(o[:json], "w")
      ohf.puts JSON.pretty_generate(stats)
      ohf.close
   end

   # Save results in tab
   unless o[:tab].nil?
      ohf = File.open(o[:tab], "w")
      stats.each_pair{ |k,v| ohf.puts "#{k}\t#{v}" }
      ohf.close
   end

   # Save results in T(tab)
   unless o[:ttab].nil?
      ohf = File.open(o[:ttab], "w")
      ohf.puts stats.keys.join("\t")
      ohf.puts stats.values.join("\t")
      ohf.close
   end

   $stderr.puts "Done.\n" unless o[:q] 
rescue => err
   $stderr.puts "Exception: #{err}\n\n"
   err.backtrace.each { |l| $stderr.puts l + "\n" }
   err
end


