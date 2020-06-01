#!/usr/bin/env ruby

# frozen_string_literal: true

$:.push File.expand_path('../lib', __FILE__)
require 'enveomics_rb/enveomics'
require 'enveomics_rb/anir'
$VERSION = 1.0

o = {
  q: false, threads: 2,
  r_format: :fastq, g_format: :fasta, m_format: :sam, r_type: :single,
  identity: 95.0, algorithm: :auto, bimodality: 0.5, bin_size: 1.0,
  coefficient: :sarle
}

OptionParser.new do |opt|
  cmd = File.basename($0)
  opt.banner = <<~BANNER

    [Enveomics Collection: #{cmd} v#{$VERSION}]

    Estimates ANIr: the Average Nucleotide Identity of reads against a genome

    Usage
        # [ Input/output modes ]
        # Run mapping and (optionally) save it as SAM
        # Requires bowtie2
        #{cmd} -r reads.fastq -g genome.fasta -m out_map.sam [options]

        # Read mapping from BAM file
        # Requires samtools
        #{cmd} -m map.bam --m-format bam [options]

        # Read mapping from other formats: SAM or Tabular BLAST
        #{cmd} -m map.blast --m-format tab [options]

        # Read a list of identities as percentage (contig filtering off)
        #{cmd} -m identities.txt --m-format list [options]

        # [ Identity threshold modes ]
        #{cmd} -i 95 -a fix [options] # Set fixed identity threshold
        #{cmd} -a gmm [options]       # Find valley by EM of GMM
        #{cmd} -a auto [options]      # Pick method by bimodality (default)"

  BANNER

  opt.separator 'Input/Output'
  opt.on('-r', '--reads PATH', 'Metagenomic reads') { |v| o[:r] = v }
  opt.on('-g', '--genome PATH', 'Genome assembly') { |v| o[:g] = v }
  opt.on('-m', '--mapping PATH', 'Mapping file') { |v| o[:m] = v }
  opt.on('-L', '--list PATH', 'Output file with identities') { |v| o[:L] = v }
  opt.on('-H', '--hist PATH', 'Output file with histogram') { |v| o[:H] = v }
  opt.separator ''

  opt.separator 'Formats'
  opt.on(
    '--r-format STRING',
    'Metagenomic reads format: fastq (default) or fasta',
    'Both options support compression with .gz file extension'
  ) { |v| o[:r_format] = v.downcase.to_sym }
  opt.on(
    '--r-type STRING', 'Type of metagenomic reads:',
    '~ single (default): Single reads',
    '~ coupled: Coupled reads in separate files (-m must be comma-delimited)',
    '~ interleaved: Coupled reads in a single interposed file'
  ) { |v| o[:r_type] = v.downcase.to_sym }
  opt.on(
    '--g-format STRING',
    'Genome assembly format: fasta (default) or list',
    'Both options support compression with .gz file extension',
    'If passed in mapping-read mode, filters only matches to these contigs'
  ) { |v| o[:g_format] = v.downcase.to_sym }
  opt.on(
    '--m-format STRING',
    'Mapping file format: sam (default), bam, tab, or list',
    'sam, tab, and list options support compression with .gz file extension'
  ) { |v| o[:m_format] = v.downcase.to_sym }
  opt.separator ''

  opt.separator 'Identity threshold'
  opt.on(
    '-i', '--identity FLOAT', Float,
    "Set a fixed threshold of percent identity (default: #{o[:identity]})"
  ) { |v| o[:identity] = v }
  opt.on(
    '-a', '--algorithm STRING',
    'Set an algorithm to automatically detect identity threshold:',
    '~ gmm: Valley detection by E-M of Gaussian Mixture Model',
    '~ fix: Fixed threshold, see -i',
    '~ auto (default): Pick gmm or fix depending on bimodality, see -b'
  ) { |v| o[:algorithm] = v.downcase.to_sym }
  opt.on(
    '-b', '--bimodality FLOAT', Float,
    'Threshold of bimodality below which the algorithm is set to fix',
    'The coefficient used is the de Michele & Accantino (2014) B index',
    "By default: #{o[:bimodality]}"
  ) { |v| o[:bimodality] = v }
  opt.on(
    '--coefficient STRING',
    'Coefficient of bimodality for -a auto:',
    '~ sarle (default): Sarle\'s bimodality coefficient b',
    '~ dma: de Michele and Accatino (2014 PLoS ONE) B index, use with -b 0.1'
  ) { |v| o[:coefficient] = v.downcase.to_sym }
  opt.on(
    '--bin-size FLOAT', Float,
    "Width of histogram bins (in percent identity). By default: #{o[:bin_size]}"
  ) { |v| o[:bin_size] = v }
  opt.separator ''

  opt.separator 'General'
  opt.on(
    '-t', '--threads INT', Integer, 'Threads to use'
  ) { |v| o[:threads] = v }
  opt.on('-l', '--log PATH', 'Log file to save output') { |v| o[:log] = v }
  opt.on('-q', '--quiet', 'Run quietly') { |v| o[:q] = v }
  opt.on('-h', '--help', 'Display this screen') do
    puts opt
    exit
  end
  opt.separator ''
end.parse!

Enveomics::ANIr.new(o).go!
