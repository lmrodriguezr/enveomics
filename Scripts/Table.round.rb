#!/usr/bin/ruby -w
#
# @author: Luis M. Rodriguez-R <lmrodriguezr at gmail dot com>
# @update: Jan 09 2013
# @license: artistic license 2.0
#

require 'trollop'

opts = Trollop::options do
   banner "Rounds (or floors) numbers in a table."
   opt :in, "Input table.", :type=>:string, :short=>'i'
   opt :out, "Output table.", :type=>:string, :short=>'o'
   opt :ndigits, "Number of digits.", :type=>:integer, :short=>'n', :default=>0
   opt :floor, "Floors the values instead of rounding them.", :short=>'f'
   opt :delimiter, "String delimiting columns.", :short=>'d', :default=>"\t"
end

Trollop::die :in, "is mandatory" unless opts[:in]
Trollop::die :out, "is mandatory" unless opts[:out]

class String
   def is_number?
      true if Float(self) rescue false
   end
end

begin
   i = File.open(opts[:in], "r")
   o = File.open(opts[:out], "w")
   while(ln = i.gets)
      ln.chomp!
      row = []
      ln.split(opts[:delimiter]).each do |value|
         if opts[:floor]
	    row.push( value.is_number? ? value.to_f.floor.to_s : value )
	 else
	    row.push( value.is_number? ? value.to_f.round(opts[:ndigits]).to_s : value )
         end
      end
      o.puts(row.join(opts[:delimiter]))
   end
   i.close
   o.close
rescue => err
   $stderr.puts "Exception: #{err}\n\n"
   err.backtrace.each { |l| $stderr.puts " - " + l + "\n" }
   err
end
