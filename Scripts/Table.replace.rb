#!/usr/bin/env ruby

#
# @author  Luis M. Rodriguez-R <lmrodriguezr at gmail dot com>
# @update  Feb 01 2016
# @license artistic license 2.0
#

require "optparse"

o = {delimiter: "\t", key: 1, default: ""}
ARGV << "-h" if ARGV.size==0
OptionParser.new do |opts|
   opts.banner = "\nReplaces a field in a table using a mapping file."
   opts.on("-m", "--map FILE",
      "Mapping file with two columns (key and replacement)."){ |v| o[:map] = v }
   opts.on("-i", "--in FILE", "Input table."){ |v| o[:in] = v }
   opts.on("-o", "--out FILE", "Output table."){ |v| o[:out] = v }
   opts.on("-k", "--key INT",
      "Column to replace in --in. By deafult: 1."){ |v| o[:key] = v.to_i }
   opts.on("-u", "--unknown STR",
      "String to use whenever the key is not found in --map."
      ){ |v| o[:default] = v }
   opts.on("-d", "--delimiter STR",
      "String delimiting columns. By default, tabulation."
      ){ |v| o[:delimiter] = v }
   opts.on("-h", "--help", "Display this screen") do
      puts opts
      exit
   end
   opts.separator ""
end.parse!
abort "-m is mandatory" if o[:map].nil?
abort "-i is mandatory" if o[:in].nil?
abort "-o is mandatory" if o[:out].nil?

class String
   def is_number?
      true if Float(self) rescue false
   end
end

begin
   # Read mapping file
   ifh = File.open(o[:map], "r")
   map = {}
   while(ln = ifh.gets)
      row = ln.chomp.split(o[:delimiter])
      map[ row[0] ] = row[1]
   end
   ifh.close
   # Process table
   ifh = File.open(o[:in], "r")
   ofh = File.open(o[:out], "w")
   while(ln = ifh.gets)
      row = ln.chomp.split(o[:delimiter])
      k = row[ o[:key]-1 ]
      v = map[ k ]
      v = o[:default] if v.nil?
      row[ o[:key]-1 ] = v
      ofh.puts(row.join(o[:delimiter]))
   end
   ifh.close
   ofh.close
rescue => err
   $stderr.puts "Exception: #{err}\n\n"
   err.backtrace.each { |l| $stderr.puts " - " + l + "\n" }
   err
end
