#!/usr/bin/env ruby

#
# @author: Luis M. Rodriguez-R <lmrodriguezr at gmail dot com>
# @update: Feb 04 2015
# @license: artistic license 2.0
#

require 'optparse'

o = {:ndigits=>0, :action=>:round, :delimiter=>"\t"}
ARGV << '-h' if ARGV.size==0
OptionParser.new do |opts|
   opts.banner = "\nRounds numbers in a table."
   opts.on("-i", "--in FILE", "Input table."){ |v| o[:in] = v}
   opts.on("-o", "--out FILE", "Output table."){ |v| o[:out] = v }
   opts.on("-n", "--ndigits INT", "Number of decimal digits. By default: #{o[:ndigits]}"){ |v| o[:ndigits] = v.to_i }
   opts.on("-f", "--floor", "Floors the values instead of rounding them. Ignores -n."){ o[:action] = :floor }
   opts.on("-c", "--ceil", "Ceils the values instead of rounding them. Ignores -n."){ o[:action] = :ceil }
   opts.on("-d", "--delimiter STR", "String delimiting columns. By default, tabulation."){ |v| o[:delimiter] = v }
   opts.on("-h", "--help", "Display this screen") do
      puts opts
      exit
   end
   opts.separator ""
end.parse!
abort "-i is mandatory" if o[:in].nil?
abort "-o is mandatory" if o[:out].nil?

class String
   def is_number?
      true if Float(self) rescue false
   end
end

begin
   ifh = File.open(o[:in], "r")
   ofh = File.open(o[:out], "w")
   while(ln = ifh.gets)
      ln.chomp!
      row = []
      ln.split(o[:delimiter]).each do |value|
	 if value.is_number?
	    case o[:action]
	    when :round
	       value = value.to_f.round(o[:ndigits])
	    when :floor
	       value = value.to_f.floor
	    when :ceil
	       value = value.to_f.ceil
	    end
	 end
	 row.push value.to_s
      end
      ofh.puts(row.join(o[:delimiter]))
   end
   ifh.close
   ofh.close
rescue => err
   $stderr.puts "Exception: #{err}\n\n"
   err.backtrace.each { |l| $stderr.puts " - " + l + "\n" }
   err
end
