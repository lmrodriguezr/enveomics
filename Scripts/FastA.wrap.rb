#!/usr/bin/env ruby

require "optparse"
o = {wrap:70}
ARGV << "-h" if ARGV.empty?
OptionParser.new do |opts|
  opts.banner = "
Wraps sequences in a FastA to a given line length.

Usage: #{$0} [options]"
  opts.separator ""
  opts.separator "Options"
  opts.on("-i", "--in FILE", "Input FastA file."){ |v| o[:in] = v }
  opts.on("-o", "--out FILE", "Output FastA file."){ |v| o[:out] = v }
  opts.on("-w", "--wrap INT",
    "Line length to wrap sequences. Use 0 to generate 1-line sequences.",
    "By default: #{o[:wrap]}."){ |v| o[:wrap] = v.to_i }
  opts.on("-h", "--help", "Display this screen.") do
    puts opts
    exit
  end
  opts.separator ""
end.parse!
abort "-i is mandatory" if o[:in].nil?
abort "-o is mandatory" if o[:out].nil?

def wrap_width(txt, len)
  return "" if txt.empty?
  return "#{txt}\n" if len==0
  txt.gsub(/(.{1,#{len}})/,"\\1\n")
end

ofh = File.open(o[:out], "w")
File.open(o[:in], "r") do |ifh|
  bf = ""
  ifh.each_line do |ln|
    if ln =~ /^>/
      ofh.print wrap_width(bf, o[:wrap])
      ofh.puts ln
      bf = ""
    else
      ln.chomp!
      bf << ln
    end
  end
  ofh.print wrap_width(bf, o[:wrap])
end
ofh.close
