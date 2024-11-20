#!/usr/bin/env ruby

# frozen_string_literal: true

$:.push File.expand_path('../lib', __FILE__)
require 'enveomics_rb/enveomics'
$VERSION = 1.0

o = { q: false, p: '', s: '', d: false }

OptionParser.new do |opts|
  opts.version = $VERSION
  Enveomics.opt_banner(
    opts, 'Generates easy-to-parse tagged reads from FastA files',
    "#{File.basename($0)} -i in.fasta -o out.fasta [options]"
  )

  opts.separator 'Mandatory'
  opts.on(
    '-i', '--in FILE',
    'Path to the FastA file containing the sequences',
    'Supports compression with .gz extension, use - for STDIN'
  ) { |v| o[:in] = v }
  opts.on(
    '-o', '--out FILE',
    'Path to the FastA to create',
    'Supports compression with .gz extension, use - for STDOUT'
  ) { |v| o[:out] = v }

  opts.separator ''
  opts.separator 'ID options'
  opts.on('-p', '--prefix STR', 'Prefix to use in all IDs') { |v| o[:p] = v }
  opts.on('-s', '--suffix STR', 'Suffix to use in all IDs') { |v| o[:s] = v }
  opts.on(
    '-d', '--defline', 'Keep the original defline after a space'
  ) { o[:d] = true }
  opts.on(
    '-l', '--list FILE', 'Reads a list of IDS',
    'Supports compression with .gz extension, use - for STDIN'
  ) { |v| o[:l] = v }

  opts.separator ''
  opts.separator 'Other Options'
  opts.on('-q', '--quiet', 'Run quietly (no STDERR output)') { o[:q] = true }
  opts.on('-h', '--help', 'Display this screen') { puts opts; exit }
  opts.separator ''
end.parse!

raise Enveomics::OptionError.new('-i is mandatory') if o[:in].nil?
raise Enveomics::OptionError.new('-o is mandatory') if o[:out].nil?
   
begin
  list = nil
  unless o[:l].nil?
    lfh = reader(o[:l])
    list = lfh.map { |i| i.chomp.gsub(/^>/, '') }
    lfh.close
  end
  
  ofh = writer(o[:out])
  i = 0
  ifh = reader(o[:in])
  ifh.each do |ln|
    ln.chomp!
    next if ln =~ /^;/
    unless /^>/.match(ln).nil?
      i += 1
      new_id = o[:l].nil? ? i : list.shift
      ofh.puts ">#{o[:p]}#{new_id}#{o[:s]}#{o[:d]?" #{ln[1, ln.size-1]}":''}"
    else
      ofh.puts ln
    end
  end
  ifh.close
  ofh.close
rescue => err
  $stderr.puts "Exception: #{err}\n\n"
  err.backtrace.each { |l| $stderr.puts l + "\n" }
  err
end

