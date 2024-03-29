#!/usr/bin/env ruby

$:.push File.expand_path('../lib', __FILE__)

require 'enveomics_rb/enveomics'
require 'enveomics_rb/og'
require 'json'
$VERSION = 1.1

o = { q: false, a: false }
OptionParser.new do |opts|
  opts.version = $VERSION
  cmd = File.basename($0)
  Enveomics.opt_banner(
    opts,
    'Estimates some descriptive statistics on a set of Orthology Groups (OGs)',
    "#{cmd} -o file.ogs [options]"
  )

  opts.separator 'Mandatory'
  opts.on(
    '-o', '--ogs FILE',
    'Input file containing the precomputed OGs',
    'Supports compression with .gz extension, use - for STDIN'
  ) { |v| o[:ogs] = v }
  opts.separator ''
  opts.separator 'Other Options'
  opts.on(
    '-j', '--json FILE', 'Output file in JSON format',
    'Supports compression with .gz extension, use - for STDOUT'
  ) { |v| o[:json] = v }
  opts.on(
    '-t', '--tab FILE', 'Output file in tabular format',
    'Supports compression with .gz extension, use - for STDOUT'
  ) { |v| o[:tab] = v }
  opts.on(
    '-T', '--transposed-tab FILE',
    'Output file in transposed tabular format',
    'Supports compression with .gz extension, use - for STDOUT'
  ){  |v| o[:ttab] = v }
  opts.on('-a', '--auto', 'Run completely quietly (no STDERR or STDOUT)') do
    o[:q] = true
    o[:a] = true
  end
  opts.on('-q', '--quiet', 'Run quietly (no STDERR output)') { o[:q] = true }
  opts.on('-h', '--help', 'Display this screen') do
    puts opts
    exit
  end
  opts.separator ''
end.parse!

raise Enveomics::OptionError.new('-i is mandatory') if o[:ogs].nil?

begin
  # Initialize the collection of OGs.
  collection = OGCollection.new

  # Read the pre-computed OGs
  $stderr.puts "Reading pre-computed OGs in '#{o[:ogs]}'." unless o[:q]
  f = reader(o[:ogs])
  h = f.gets.chomp.split /\t/
  while ln = f.gets
    collection << OG.new(h, ln.chomp.split(/\t/))
  end
  f.close
  $stderr.puts " Loaded OGs: #{collection.ogs.length}." unless o[:q]

  # Estimate descriptive stats
  stat_name = {
    genomes:     'Number of genomes',
    pan:         'Pangenome (OGs)',
    core:        'Core genome (OGs)',
    core90pc:    'OGs in 90% of the genomes',
    core80pc:    'OGs in 80% of the genomes',
    unus:        'Unus genome, core genome discarding paralogs (OGs)',
    avg:         'Average number of OGs in a genome',
    avg_pan:     'Average genome (OGs) / Pangenome (OGs)',
    core_avg:    'Core genome (OGs) / Average genome (OGs)',
    core_pan:    'Core genome (OGs) / Pangenome (OGs)',
    ogs_shannon: 'Entropy of the OG frequencies (bits)'
  }
  stats = {}
  stats[:genomes] = Gene.genomes.length
  stats[:pan] = collection.ogs.length
  stats[:core] = collection.ogs.map do |og|
    (og.genomes.length == Gene.genomes.length) ? 1 : 0
  end.inject(0, :+)
  stats[:core90pc] = collection.ogs.map do |og|
    (og.genomes.length >= 0.9 * Gene.genomes.length) ? 1 : 0
  end.inject(0, :+)
  stats[:core80pc] = collection.ogs.map do |og|
    (og.genomes.length >= 0.8 * Gene.genomes.length) ? 1 : 0
  end.inject(0, :+)
  stats[:unus] = collection.ogs.map do |og|
    (og.genomes.length != Gene.genomes.length) ? 0 :
      (og.genes.all? { |i| i.size == 1 }) ? 1 : 0
  end.inject(0, :+)
  og_genomes       = collection.ogs.map { |og| og.genomes.length }.inject(0, :+)
  stats[:avg]      = og_genomes.to_f / Gene.genomes.length
  stats[:avg_pan]  = stats[:avg] / stats[:pan]
  stats[:core_avg] = stats[:core].to_f / stats[:avg]
  stats[:core_pan] = stats[:core].to_f / stats[:pan]
  stats[:ogs_shannon] = -1 * collection.ogs.map do |og|
    pi = og.genomes.length.to_f / Gene.genomes.length
    pi * Math.log(pi)
  end.inject(0.0, :+)

  # Show result
  $stderr.puts 'Generating reports' unless o[:q]
  stats.each_pair { |k, v| puts " #{stat_name[k]}: #{v}" } unless o[:a]

  # Save results in JSON
  unless o[:json].nil?
    ohf = writer(o[:json])
    ohf.puts(JSON.pretty_generate(stats))
    ohf.close
  end

  # Save results in tab
  unless o[:tab].nil?
    ohf = writer(o[:tab])
    stats.each_pair { |k, v| ohf.puts "#{k}\t#{v}" }
    ohf.close
  end

  # Save results in T(tab)
  unless o[:ttab].nil?
    ohf = writer(o[:ttab])
    ohf.puts stats.keys.join("\t")
    ohf.puts stats.values.join("\t")
    ohf.close
  end

  $stderr.puts 'Done' unless o[:q] 
rescue => err
  $stderr.puts "Exception: #{err}\n\n"
  err.backtrace.each { |l| $stderr.puts l + "\n" }
  err
end


