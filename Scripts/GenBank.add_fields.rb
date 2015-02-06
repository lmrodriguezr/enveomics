#!/usr/bin/env ruby

#
# @author: Luis M. Rodriguez-R
# @update: Feb-06-2015
# @license: artistic license 2.0
#

require 'optparse'

o = {:q=>FALSE, :k=>1, :split=>"#"}
ARGV << '-h' if ARGV.size==0
OptionParser.new do |opts|
   opts.banner = "
Adds annotations to GenBank files.

Usage: #{$0} [options]"
   opts.separator ""
   opts.separator "Mandatory"
   opts.on("-g", "--genbank FILE", "Input GenBank file."){ |v| o[:gb]=v }
   opts.on("-t", "--table FILE", "Input file containing the annotations. It must be a ",
   				"tab-delimited raw table including a header row with ",
				"the names of the fields."){ |v| o[:table]=v }
   opts.on("-o", "--out FILE", "Output file containing the annotated GenBank."){ |v| o[:out]=v }
   opts.separator ""
   opts.separator "Other Options"
   opts.on("-k", "--key NUMBER", "Key of the column to use as identifier. By default: #{o[:k]}"){ |v| o[:k] = v.to_i }
   opts.on("-s", "--split STRING", "String that separates multiple entries in the annotation features. By default: \"#{o[:split]}\""){ |v| o[:k] = v.to_i }
   opts.on("-q", "--quiet", "Run quietly (no STDERR output)."){ o[:q] = TRUE }
   opts.on("-h", "--help", "Display this screen.") do
      puts opts
      exit
   end
   opts.separator ""
end.parse!
abort "-g is mandatory" if o[:gb].nil?
abort "-t is mandatory" if o[:table].nil?
abort "-o is mandatory" if o[:out].nil?

##### MAIN:
begin
   puts "Reading annotation table: #{o[:table]}." unless o[:q]
   ifh = File.open(o[:table], "r")
   header = ifh.gets.chomp.split(/\t/)
   puts "  * using #{header[ o[:k]-1 ]} column as feature identifier."
   annot = {}
   while ln=ifh.gets
      row = ln.chomp.split(/\t/)
      warn "WARNING: #{header[ o[:k]-1 ]} #{row[ o[:k]-1 ]} found more than once." unless annot[ row[ o[:k]-1 ] ].nil?
      annot[ row[ o[:k]-1 ] ] = row
   end
   ifh.close
   puts "  * found #{annot.size} annotation entries with #{header.size} fields." unless o[:q]
   puts "Annotating GenBank." unless o[:q]
   ifh = File.open(o[:gb], "r")
   ofh = File.open(o[:out], "w")
   found = 0
   notfound = 0
   while ln=ifh.gets
      ofh.print ln
      m = /^(?<sp>\s+)\/#{header[ o[:k]-1 ]}="(?<id>.+)"/.match(ln)
      next if m.nil?
      if annot[ m[:id] ].nil?
	 notfound += 1
	 next
      end
      found += 1
      annot[ m[:id] ].each_index do |i|
         next if i == o[:k]-1 or annot[ m[:id] ][i]==""
	 annot[ m[:id] ][i].split(/#{o[:split]}/).each{ |v| ofh.puts "#{m[:sp]}/#{header[i]}=\"#{v}\"" }
      end
   end
   ofh.close
   ifh.close
   puts "  * annotated #{found} features." unless o[:q]
   puts "  * couldn't find #{notfound} features in the annotation table." unless o[:q] or notfound==0
   $stderr.puts "Done.\n" unless o[:q]
rescue => err
   $stderr.puts "Exception: #{err}\n\n"
   err.backtrace.each { |l| $stderr.puts l + "\n" }
   err
end


