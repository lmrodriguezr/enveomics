#!/usr/bin/env ruby

# @author  Luis M. Rodriguez-R
# @license artistic license 2.0

$:.push File.expand_path('../lib', __FILE__)
require 'enveomics_rb/enveomics'
$VERSION = 1.0

o = {
  q: false, missing: '-', model: 'AUTO', removeinvar: false, undefined: '-.Xx?'
}

OptionParser.new do |opt|
  cmd = File.basename($0)
  opt.banner = <<~BANNER

    [Enveomics Collection: #{cmd} v#{$VERSION}]

    Concatenates several multiple alignments in FastA format into a single
    multiple alignment.  The IDs of the sequences (or the ID prefixes, if using
    --ignore-after) must coincide across files.
  
    Usage: #{cmd} [options] aln1.fa aln2.fa ... > aln.fa

  BANNER
  opt.on(
    '-c', '--coords FILE',
    'Output file of coordinates in RAxML-compliant format'
  ) { |v| o[:coords] = v }
  opt.on(
    '-i', '--ignore-after STRING',
    'Remove everything in the IDs after the specified string'
  ) { |v| o[:ignoreafter] = v }
  opt.on(
    '-I', '--remove-invariable', 'Remove invariable sites',
    'Note: Invariable sites are defined as columns with only one state and',
    'undefined characters.  Additional ambiguous characters may exist and',
    'should be declared using --undefined'
  ) { |v| o[:removeinvar] = v }
  opt.on(
    '-u', '--missing-char CHAR',
    "Character denoting missing data. By default: '#{o[:missing]}'"
  ) do |v|
    if v.length != 1
      abort "-missing-char can only be denoted by single characters: #{v}"
    end
    o[:missing] = v
  end
  opt.on(
    '-m', '--model STRING',
    'Name of the model to use if --coords is used. See RAxML docs;',
    'supported values in v8+ include:',
    '~ For DNA alignments:',
    '  "DNA[F|X]", or "DNA[F|X]/3" (to estimate rates per codon position,',
    '  particular notation for this script)',
    '~ General protein alignments:',
    '  "AUTO" (default in this script), "DAYHOFF" (1978), "DCMUT" (MBE 2005;',
    '  22(2):193-199), "JTT" (Nat 1992;358:86-89), "VT" (JCompBiol 2000;',
    '  7(6):761-776), "BLOSUM62" (PNAS 1992;89:10915), and "LG" (MBE 2008;',
    '  25(7):1307-1320)',
    '~ Specialized protein alignments:',
    '  "MTREV" (mitochondrial, JME 1996;42(4):459-468), "WAG" (globular, MBE',
    '  2001;18(5):691-699), "RTREV" (retrovirus, JME 2002;55(1):65-73),',
    '  "CPREV" (chloroplast, JME 2000;50(4):348-358), and "MTMAM" (nuclear',
    '  mammal proteins, JME 1998;46(4):409-418)'
  ) { |v| o[:model] = v }
  opt.on(
    '--undefined STRING',
    'All characters to be regarded as "undefined". It should include all',
    'ambiguous and missing data chars.  Ignored unless --remove-invariable',
    "By default: '#{o[:undefined]}'"
  ) { |v| o[:undefined] = v }
  opt.on('-q', '--quiet', 'Run quietly (no STDERR output)') { o[:q] = true }
  opt.on('-V', '--version', 'Returns version') { puts $VERSION ; exit }
  opt.on('-h', '--help', 'Display this screen') { puts opt ; exit }
  opt.separator ''
end.parse!
files = ARGV
abort 'Alignment files are mandatory' if files.nil? || files.empty?
$quiet = o[:q]

# Send +msg+ to +$stderr+ if +@opts[:q]+ is true
def say(*msg)
  $stderr.puts(*msg) unless $quiet
end

# Read individual gene alignments and return them as a single hash with genome
# IDs as keys and arrays of single-line strings as values
#
# IDs are trimmed after the first occurrence of +ignoreafter+, if defined
def read_alignments(files, ignoreafter = nil)
  aln = {}
  files.each_with_index do |file, i|
    key = nil
    File.open(file, 'r').each do |ln|
      ln.chomp!
      if ln =~ /^>(\S+)/
        key = $1
        key.sub!(/#{ignoreafter}.*/, '') if ignoreafter
        aln[key] ||= []
        aln[key][i] = ''
      else
        if key.nil?
          abort "Invalid FastA file: #{file}: Leading line not a def-line"
        end
        ln.gsub!(/\s/, '')
        aln[key][i] += ln
      end
    end
    abort "Empty alignment file: #{file}" if key.nil?
  end
  aln
end

# Remove invariable sites from the alignment hash +aln+, using +undefined+ as
# a string including all characters representing undefined positions (e.g., X)
#
# Returns number of columns removed
def remove_invariable(aln, undefined)
  invs = 0
  lengths = aln.values.first.map(&:length)
  undef_chars = undefined.chars

  lengths.each_with_index do |len, i|
    (0 .. len - 1).each do |pos|
      chr = nil
      inv = true
      aln.each_key do |key|
        next if aln[key][i].nil?
        chr = aln[key][i][pos] if chr.nil? || undefined.chars.include?(chr)
        if chr != aln[key][i][pos] && !undef_chars.include?(aln[key][i][pos])
          inv = false
          break
        end
      end
      if inv
        aln.each_key { |key| aln[key][i][pos] = '!' unless aln[key][i].nil? }
        lengths[i] -= 1
        invs += 1
      end
    end
    aln.each_key { |key| aln[key][i].gsub!('!', '') unless aln[key][i].nil? }
  end
  invs
end

# Concatenate the alignments hash +aln+ using the character +missing+ to
# indicate missing alignments, and send each entry in the concatenated alignment
# to +blk+ as two variables: key (name) and value (alignment string)
#
# Returns an array with the lengths of each individual alignment
def concatenate(aln, missing, &blk)
  say 'Concatenating'
  lengths = aln.values.first.map(&:length)
  aln.each_key do |key|
    # Pad missing entries
    lengths.each_with_index { |len, i| aln[key][i] ||= missing * len }

    # Check length
    obs_len = aln[key].map(&:length)
    unless lengths == obs_len
      abort "Inconsistent lengths in '#{key}'\nexp: #{lengths}\nobs: #{obs_len}"
    end

    # Pass entry to the block and remove from alignment hash
    blk[key, aln[key].join('')]
    aln.delete(key)
  end
  lengths
end

# Save the coordinates in +file+ based on +files+ paths (for the names), and
# using +lengths+ individual alignment lengths
#
# The saved format is RAxML coords, including the +model+ for each alignment
def save_coords(file, names, lengths, model)
  File.open(file, 'w') do |fh|
    s = 0
    names.each_with_index do |name, i|
      l = lengths[i]
      next unless l > 0
      name += "_#{i}" while names.count(name) > 1
      if model =~ /(DNA.?)\/3/
        fh.puts "#{$1}, #{name}codon1 = #{s + 1}-#{s + l}\\3"
        fh.puts "#{$1}, #{name}codon2 = #{s + 2}-#{s + l}\\3"
        fh.puts "#{$1}, #{name}codon3 = #{s + 3}-#{s + l}\\3"
      else
        fh.puts "#{model}, #{name} = #{s + 1}-#{s + l}"
      end
      s += l
    end
  end
end

# ------ MAIN ------
begin
  say 'Reading'
  alignments = read_alignments(files, o[:ignoreafter])

  if o[:removeinvar]
    say 'Removing invariable sites'
    inv = remove_invariable(alignments, o[:undefined])
    say "  Removed #{inv} sites"
  end

  lengths = concatenate(alignments, o[:missing]) do |name, seq|
    puts ">#{name}", seq.gsub(/(.{1,60})/, "\\1\n")
  end
  say "  #{lengths.inject(:+)} columns"

  unless o[:coords].nil?
    say 'Generating coordinates'
    names = files.map do |i|
      File.basename(i).gsub(/\..*/, '').gsub(/[^A-Za-z0-9_]/, '_')
    end
    save_coords(o[:coords], names, lengths, o[:model])
  end

  $stderr.puts 'Done' unless o[:q] 
rescue => err
  $stderr.puts "Exception: #{err}\n\n"
  err.backtrace.each { |l| $stderr.puts l + "\n" }
  err
end

