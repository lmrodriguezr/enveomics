#!/usr/bin/env ruby

# frozen_string_literal: true

$:.push File.expand_path('../lib', __FILE__)
require 'enveomics_rb/enveomics'
require 'enveomics_rb/stats'
require 'fileutils'
require 'shellwords'
require 'tmpdir'
require 'zlib'
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

# Wrapper class for ANIr estimation
#
# Use as: +ANIr.new(opts).go!+
class ANIr
  # Options hash
  attr :opts

  # Identities list (unsorted)
  attr :identities

  def initialize(opts)
    @opts = opts
    @identities = []
  end

  # ----------------------------------------------------[ High-level pipelines ]

  # Perform all the analyses
  def go!
    read_input
    detect_identity
    estimate_ani_r
  end

  # Identify input/output mode and read mapping
  def read_input
    if opts[:m_format] != :list
      @tmpdir = Dir.mktmpdir
      @filter_contigs = !opts[:g].nil?
      opts[:m] = File.join(@tmpdir, 'map.sam') if opts[:m].nil?
      run_mapping unless File.exist? opts[:m]
      load_contigs_to_filter if @filter_contigs
    end
    read_mapping = :"read_mapping_from_#{opts[:m_format]}"
    unless respond_to? read_mapping
      raise "Unsupported mapping format: #{opts[:m_format]}"
    end
    @identities = []
    send(read_mapping)
    say "- Unfiltered average identity: #{sample.mean}"
    say "- Reads mapped: #{sample.n}"
    save_identities
    save_histogram
  ensure
    @tmpdir ||= nil
    FileUtils.rm_rf @tmpdir if @tmpdir
  end

  # Identify the identity threshold
  def detect_identity
    say 'Detecting identity threshold'
    if opts[:algorithm] == :auto
      say "- Bimodality: #{bimodality}"
      opts[:algorithm] = bimodality >= opts[:bimodality] ? :gmm : :fix
    end
    say "- Algorithm: #{opts[:algorithm]}"
    if opts[:algorithm] == :gmm
      detect_identity_by_gmm
    end
  end

  # Estimate ANIr
  def estimate_ani_r
    say 'Estimating ANIr'
    @sample = nil # Empty cached sample
    @identities.delete_if { |i| i < opts[:identity] }
    say "- ANIr: #{sample.mean}"
  end

  # -------------------------------------------------------------------[ Utils ]

  # Show progress unless +opts[:q]+
  def say(*msg)
    o = '[%s] %s' % [Time.now, msg.join('')]
    $stderr.puts(o) unless opts[:q]
    File.open(opts[:log], 'a') { |fh| fh.puts o } if opts[:log]
  end

  # Execute command in the shell
  def run(cmd)
    say "  - Running: #{cmd.join(' ')}"
    `#{cmd.shelljoin} 2>&1 | tee >> #{opts[:log] || '/dev/null'}`
    abort "#{cmd.first} failed: #{$?}" unless $?.success?
  end

  # Returns an open file handler for the file, supporting .gz
  def reader(file)
    file =~ /\.gz$/ ? Zlib::GzipReader.open(file) : File.open(file, 'r')
  end

  # Is the mapping in SAM format?
  def sam?
    opts[:m_format] == :sam
  end

  # --------------------------------------------------------------[ Map it out ]

  # Execute Bowtie2 and generate SAM file
  def run_mapping
    say 'Running mapping using Bowtie2'
    raise 'Only SAM output is supported for mapping' unless sam?
    @filter_contigs = false

    say '- Indexing input sequences'
    unless opts[:g_format] == :fasta
      raise 'Only FastA genome input is supported for mapping'
    end
    idx = File.join(@tmpdir, 'genome.idx')
    run(['bowtie2-build', opts[:g], idx])

    say '- Mapping metagenomic reads to genome assembly'
    cmd = [
      'bowtie2', '-x', idx, '-p', opts[:threads], '-S', opts[:m], '--no-mixed'
    ]
    cmd << '-f' if opts[:r_format] == :fasta
    cmd +=
      case opts[:r_type]
      when :single
        ['-U', opts[:r]]
      when :coupled
        pairs = opts[:r].split(',', 2)
        ['-1', pairs[0], '-2', pairs[1], '--no-discordant']
      when :interleaved
        ['--interleaved', opts[:r], '--no-discordant']
      else
        raise "Unsupported reads type: #{o[:r_type]}"
      end
    run(cmd)
  end

  # If +@filter_contigs+ is true, reads the genome assembly and saves contig
  # names to filter the mapping
  def load_contigs_to_filter
    return unless @filter_contigs
    say 'Loading contigs to filter'
    reader = reader(opts[:g])
    @contigs_to_filter =
      case opts[:g_format]
      when :fasta
        reader.each.map { |ln| $1 if ln =~ /^>(\S+)/ }.compact
      when :list
        reader.each.map(&:chomp)
      else
        raise "Unsupported genome assembly format: #{opts[:g_format]}"
      end
    reader.close
    say "- Got #{@contigs_to_filter.size} contigs"
  end

  # Reads the mapping file assuming SAM format
  def read_mapping_from_sam
    say 'Reading mapping from SAM file'
    reader = reader(opts[:m])
    reader.each { |ln| parse_sam_line(ln) }
    reader.close
  end

  # Reads the mapping file assuming BAM format
  def read_mapping_from_bam
    say 'Reading mapping from BAM file'
    IO.popen(['samtools', 'view', opts[:m]].shelljoin) do |fh|
      fh.each { |ln| parse_sam_line(ln) }
    end
  end

  # Reads the mapping file assuming a Tabular BLAST format
  def read_mapping_from_tab
    say 'Reading mapping from Tabular BLAST file'
    reader = reader(opts[:m])
    reader.each do |ln|
      next if ln =~ /^\s*(#.*)?$/ # Comment or empty line
      row = ln.chomp.split("\t")
      next if @filter_contigs && !@contigs_to_filter.include?(row[1])
      @identities << row[2].to_f
    end
    reader.close
  end

  # Reads the identities from a raw-text list
  def read_mapping_from_list
    say 'Reading identities from raw text list'
    reader = reader(opts[:m])
    @identities = reader.each.map(&:to_f)
    reader.close
  end

  # Parses one line in SAM format
  def parse_sam_line(ln)
    return if ln =~ /^@/ || ln =~ /^\s*$/
    row = ln.chomp.split("\t")
    return if row[2] == '*'
    return if @filter_contigs && !@contigs_to_filter.include?(row[2])
    length = row[9].size
    row.shift(11) # Discard non-flag columns
    flags = Hash[row.map { |i| i.sub(/:.:/, ':').split(':', 2) }]
    return if flags['YT'] && !%w[CP UU].include?(flags['YT'])
    abort "SAM line missing MD flag:\n#{ln}\nFlags: #{flags}" unless flags['MD']
    mismatches = flags['MD'].scan(/[^\d]/).count
    @identities << 100.0 * (length - mismatches) / length
  end

  # Save identites as raw text
  def save_identities
    return unless opts[:L]
    say '- Saving identities'
    File.open(opts[:L], 'w') do |fh|
      identities.each { |i| fh.puts i }
    end
  end

  # Save identity histogram as raw text
  def save_histogram
    return unless opts[:H]
    say '- Saving histogram'
    File.open(opts[:H], 'w') do |fh|
      fh.puts "from\tto\tcount"
      sample.histo_ranges.each_with_index do |r, k|
        fh.puts (r + [sample.histo_counts[k]]).join("\t")
      end
    end
  end

  # -------------------------------------------------------------[ Peak finder ]

  # Detect identity threshold by gaussian mixture model EM
  def detect_identity_by_gmm
    model_identities_by_gmm_em
    detect_valley_by_gmm
  end

  # Model identities as a 2-gaussian mix by EM
  def model_identities_by_gmm_em
    say 'Modeling identities by gaussian mixture model using EM'
    # TODO: Implement
    raise 'Unimplemented operation'
  end

  # Detect valley by gaussian mix
  def detect_valley_by_gmm
    say 'Detecting valley by gaussian mixture model'
    # TODO: Implement
    raise 'Unimplemented operation'
  end

  # -------------------------------------------------------------[ Do the math ]

  # Identities as a Enveomics::Stats::Sample object
  def sample
    @sample ||= Enveomics::Stats::Sample.new(
      identities,
      effective_range: [nil, 100.0],
      histo_bin_size: opts[:bin_size]
    )
  end

  # Returns the bimodality coefficient indicated by +opts[:coefficient]+
  def bimodality
    @bimodality ||=
      case opts[:coefficient]
      when :sarle
        sample.sarle_bimodality
      when :dma
        sample.dma_bimodality
      else
        abort "Unsupported coefficient of bimodality: #{opts[:coefficient]}"
      end
  end
end

ANIr.new(o).go!

