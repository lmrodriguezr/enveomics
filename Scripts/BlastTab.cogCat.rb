#!/usr/bin/ruby -w

#
# @author: Luis M. Rodriguez-R <lmrodriguezr at gmail dot com>
# @update: Apr-08-2013
# @license: artistic license 2.0
#

require 'optparse'

o = {:cog=>FALSE, :q=>FALSE, :w=>TRUE}
OptionParser.new do |opts|
   opts.banner = "Replaces the COG gene IDs in a BLAST for the COG category"
   opts.separator ""
   opts.separator "Mandatory"
   opts.on("-w", "--whog FILE", "Path to the whog file."){ |v| o[:whog]=v }
   opts.on("-i", "--blast FILE", "Path to the BLAST file."){ |v| o[:blast]=v }
   opts.separator ""
   opts.separator "Optional"
   opts.on("-g", "--cog", "If set, returns the COG ID, not the COG category."){ o[:cog]=TRUE }
   opts.on("-n", "--noverbose", "Run quietly, but show warnings."){ o[:q]=TRUE }
   opts.on("-q", "--quiet", "Run quietly."){ o[:q]=TRUE; o[:w]=FALSE }
   opts.separator ""
end.parse!

abort "-w/--whog is mandatory." if o[:whog].nil?
abort "-i/--blast is mandatory." if o[:blast].nil?

STDERR.puts "Parsing whog file.\n" unless o[:q]
cat = {}
curCats = []
fh = File.open o[:whog], "r"
while ln=fh.gets
   ln.chomp!
   next if /^\s*$/.match ln
   if m=/^\[([A-Z]+)\] (COG\d+) /.match(ln)
      curCats = o[:cog] ? [ m[2] ] : m[1].split(//)
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

STDERR.puts "Parsing BLAST.\n" unless o[:q]
fh = File.open o[:blast], "r"
while ln=fh.gets
   row = ln.split(/\t/)
   if cat[ row[1] ].nil?
      STDERR.puts "Warning: line #{$.}: #{row[1]}: Impossible to find category.\n" if o[:w]
   else
      cat[ row[1] ].each do |c|
         row[1] = c
	 puts row.join "\t"
      end
   end
end
fh.close

