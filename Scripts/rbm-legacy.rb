#!/usr/bin/env ruby

# frozen_string_literal: true

$VERSION = 0.1
$:.push File.expand_path('../lib', __FILE__)
require 'enveomics_rb/enveomics'
require 'tmpdir'

o = {
  q: false, thr: 1,
  len: 0, id: 0.0, fract: 0.0, score: 0.0,
  bin: '', program: :'blast+', nucl: false
}

OptionParser.new do |opts|
  cmd = File.basename($0)
  opts.banner = <<~BANNER

    [Enveomics Collection: #{cmd} v#{$VERSION}]

    [DEPRECATED: Please use rbm.rb instead]

    Finds the reciprocal best matches between two sets of sequences

    Usage: #{cmd} [options]

  BANNER

  opts.separator 'Mandatory'
  opts.on(
    '-1', '--seq1 FILE',
    'Path to the FastA file containing the set 1'
  ) { |v| o[:seq1] = v }
  opts.on(
    '-2', '--seq2 FILE',
    'Path to the FastA file containing the set 2'
  ) { |v| o[:seq2] = v }
  opts.separator ''
  opts.separator 'Search Options'
  opts.on(
    '-n', '--nucl',
    'Sequences are assumed to be nucleotides (proteins by default)',
    'Incompatible with -p diamond'
  ) { |v| o[:nucl] = true }
  opts.on(
    '-l', '--len INT', Integer,
    'Minimum alignment length (in residues)',
    "By default: #{o[:len]}"
  ) { |v| o[:len] = v }
  opts.on(
    '-f', '--fract FLOAT', Float,
    'Minimum alignment length (as a fraction of the query)',
    'If set, requires BLAST+ or Diamond (see -p)',
    "By default: #{o[:fract]}"
  ) { |v| o[:fract] = v }
  opts.on(
    '-i', '--id NUM', Float,
    'Minimum alignment identity (in %)',
    "By default: #{o[:id]}"
  ){ |v| o[:id] = v }
  opts.on(
    '-s', '--score NUM', Float,
    'Minimum alignment score (in bits)',
    "By default: #{o[:score]}"
  ) { |v| o[:score] = v }
  opts.separator ''
  opts.separator 'Software Options'
  opts.on(
    '-b', '--bin DIR',
    'Path to the directory containing the binaries of the search program'
  ) { |v| o[:bin] = v }
  opts.on(
    '-p', '--program STR',
    'Search program to be used.  One of: blast+ (default), blast, diamond'
  ) { |v| o[:program] = v.downcase.to_sym }
  opts.on(
    '-t', '--threads INT', Integer,
    'Number of parallel threads to be used',
    "By default: #{o[:thr]}"
  ) { |v| o[:thr] = v }
  opts.separator ''
  opts.separator 'Other Options'
  opts.on('-q', '--quiet', 'Run quietly (no STDERR output)') { o[:q] = true }
  opts.on('-h', '--help', 'Display this screen') { puts opts ; exit }
  opts.separator ''
end.parse!

abort '-1 is mandatory' if o[:seq1].nil?
abort '-2 is mandatory' if o[:seq2].nil?
if o[:program] == :diamond && o[:nucl]
  abort '-p diamond is incompatible with -n'
end
if o[:fract] > 0.0 && o[:program] == :blast
  abort 'Argument -f/--fract requires -p blast+ or -p diamond'
end
o[:bin] = o[:bin] + '/' if o[:bin].size > 0
$quiet = o[:q]

Dir.mktmpdir do |dir|
  say('Temporal directory: ', dir)

  # Create databases
  say 'Creating databases'
  %i[seq1 seq2].each do |seq|
    case o[:program]
    when :blast
      `"#{o[:bin]}formatdb" -i "#{o[seq]}" -n "#{dir}/#{seq}" \
        -p #{o[:nucl] ? 'F' : 'T'}`
    when :'blast+'
      `"#{o[:bin]}makeblastdb" -in "#{o[seq]}" -out "#{dir}/#{seq}" \
        -dbtype #{o[:nucl] ? 'nucl' : 'prot'}`
    when :diamond
      `"#{o[:bin]}diamond" makedb --in "#{o[seq]}" \
        --db "#{dir}/#{seq}.dmnd" --threads "#{o[:thr]}"`
    else
      abort "Unsupported program: #{o[:program]}"
    end
  end

  # Best-hits
  rbh = {}
  n2 = 0
  say ' Running comparisons'
  [2, 1].each do |i|
    qry_seen = {}
    q = o[:"seq#{i}"]
    s = "#{dir}/seq#{i == 1 ? 2 : 1}"
    say('  Query: ', q)
    case o[:program]
    when :blast
      `"#{o[:bin]}blastall" -p #{o[:nucl] ? 'blastn' : 'blastp'} -d "#{s}" \
        -i "#{q}" -v 1 -b 1 -a #{o[:thr]} -m 8 -o "#{dir}/#{i}.tab"`
    when :'blast+'
      `"#{o[:bin]}#{o[:nucl] ? 'blastn' : 'blastp'}" -db "#{s}" -query "#{q}" \
        -max_target_seqs 1 -num_threads #{o[:thr]} -out "#{dir}/#{i}.tab" \
        -outfmt "6 qseqid sseqid pident length mismatch gapopen qstart qend \
        sstart send evalue bitscore qlen slen"`
    when :diamond
      `"#{o[:bin]}diamond" blastp --threads "#{o[:thr]}" --db "#{s}.dmnd" \
        --query "#{q}" --sensitive --daa "#{dir}/#{i}.daa" --quiet \
        && "#{o[:bin]}diamond" view --daa "#{dir}/#{i}.daa" --outfmt \
        6 qseqid sseqid pident length mismatch gapopen qstart qend sstart \
        send evalue bitscore qlen slen --out "#{dir}/#{i}.tab" --quiet`
    else
      abort "Unsupported program: #{o[:program]}"
    end

    n = 0
    File.open("#{dir}/#{i}.tab", 'r') do |fh|
      fh.each do |ln|
        ln.chomp!
        row = ln.split(/\t/)
        row[12] = '1' unless %i[blast+ diamond].include? o[:program]
        next unless qry_seen[row[0]].nil? &&
          row[3].to_i >= o[:len] && row[2].to_f >= o[:id] &&
          row[11].to_f >= o[:score] && row[3].to_f / row[12].to_i >= o[:fract]

        qry_seen[row[0]] = 1
        n += 1
        if i == 2
          rbh[row[0]] = row[1]
        elsif !rbh[row[1]].nil? && rbh[row[1]] == row[0]
          puts ln
          n2 += 1
        end
      end
    end
    say "    #{n} sequences with hit"
  end
  say "  #{n2} RBMs"
end
