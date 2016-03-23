#!/usr/bin/env ruby

#
# @author  Luis M. Rodriguez-R <lmrodriguezr at gmail dot com>
# @update  Mar-23-2016
# @license artistic license 2.0
#

require "optparse"

o = {:cog=>false, :desc=>false, :q=>false, :w=>true}
ARGV << "-h" if ARGV.size==0
OptionParser.new do |opts|
   opts.banner = "Replaces the COG gene IDs in a BLAST for the COG category."
   opts.separator ""
   opts.separator "Mandatory"
   opts.on("-w", "--whog FILE", "Path to the whog file."){ |v| o[:whog]=v }
   opts.on("-i", "--blast FILE",
      "Path to the Tabular BLAST file with COG IDs as subject."
      ){ |v| o[:blast]=v }
   opts.separator ""
   opts.separator "Optional"
   opts.on("-g", "--cog",
      "If set, returns the COG ID, not the COG category."){ o[:cog]=true }
   opts.on("-d", "--desc",
      "Includes COG description (requires -g/--cog)."){ o[:desc]=true }
   opts.on("-n", "--noverbose", "Run quietly, but show warnings."){ o[:q]=true }
   opts.on("-q", "--quiet", "Run quietly."){ o[:q]=true; o[:w]=false }
   opts.on("-h", "--help", "Display this screen") do
      puts opts
      exit
   end
   opts.separator ""
end.parse!

abort "-w/--whog is mandatory." if o[:whog].nil?
abort "-i/--blast is mandatory." if o[:blast].nil?

$stderr.puts "Parsing whog file." unless o[:q]
cat = {}
curCats = []
fh = File.open o[:whog], "r"
while ln=fh.gets
   ln.chomp!
   next if /^\s*$/.match ln
   if m=/^\[([A-Z]+)\] (COG\d+) (.*)/.match(ln)
      curCats = o[:cog] ? [ m[2]+(o[:desc]?" #{m[3]}":"") ] : m[1].split(//)
   elsif /^_+$/.match ln
      curCats = []
   elsif m=/^\s+(?:.+?:\s+)?(.*)/.match(ln)
      m[1].split(/\s+/).each do |g|
         cat[g] ||= []
	 curCats.each { |i| cat[g] << i }
      end
   else
      abort "Impossible to parse line #{$.}: #{ln}"
   end
end
fh.close

$stderr.puts "Parsing BLAST." unless o[:q]
fh = File.open(o[:blast], "r")
while ln=fh.gets
   row = ln.split(/\t/)
   if cat[ row[1] ].nil?
      $stderr.puts "Warning: line #{$.}: #{row[1]}: " +
	 "Impossible to find category.\n" if o[:w]
   else
      cat[ row[1] ].each do |c|
         row[1] = c
	 puts row.join("\t")
      end
   end
end
fh.close

