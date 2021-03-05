#!/usr/bin/env ruby

# frozen_string_literal: true

$:.push File.expand_path('../lib', __FILE__)
require 'enveomics_rb/enveomics'
$VERSION = 1.0

o = { q: false, p: '', s: '' }
OptionParser.new do |opts|
  opts.version = $VERSION
  Enveomics.opt_banner(
    opts, 'Generates easy-to-parse tagged reads from FastQ files',
    "#{File.basename($0)} -i in.fasta -o out.fasta [options]"
  )

  opts.separator 'Mandatory'
  opts.on(
    '-i', '--in FILE',
    'Path to the FastQ file containing the sequences',
    'Supports compression with .gz extension, use - for STDIN'
  ) { |v| o[:in] = v }
  opts.on(
    '-o', '--out FILE', 'Path to the FastQ to create',
    'Supports compression with .gz extension, use - for STDOUT'
  ) { |v| o[:out] = v }
  opts.separator ''
  opts.separator 'ID options'
  opts.on('-p', '--prefix STR', 'Prefix to use in all IDs') { |v| o[:p] = v }
  opts.on('-s', '--suffix STR', 'Suffix to use in all IDs') { |v| o[:s] = v }
  opts.separator ''
  opts.separator 'Other Options'
  opts.on('-q', '--quiet', 'Run quietly (no STDERR output)') { o[:q] = true }
  opts.on('-h', '--help', 'Display this screen') { puts opts ; exit }
  opts.separator ''
end.parse!

raise Enveomics::OptionError.new('-i is mandatory') if o[:in].nil?
raise Enveomics::OptionError.new('-o is mandatory') if o[:out].nil?

begin
  ifh = reader(o[:in])
  ofh = writer(o[:out])
  i = 0
  lno = 0
  ifh.each do |ln|
    ln.chomp!
    lno += 0
    case lno % 4
    when 1
      ln =~ /^@/ or
        raise Enveomics::ParseError.new("Cannot parse line #{$.}: #{ln}")
      i += 1
      ofh.puts "@#{o[:p]}#{i}#{o[:s]}"
    when 3
      ln =~ /^\+/ or
        raise Enveomics::ParseError.new("Cannot parse line #{$.}: #{ln}")
      ofh.puts '+'
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

