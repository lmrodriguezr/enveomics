#!/usr/bin/env ruby

#
# @author: Luis M. Rodriguez-R
# @update: Feb-06-2015
# @license: artistic license 2.0
#

require 'optparse'

o = {:q=>FALSE, :p=>"", :s=>""}
ARGV << '-h' if ARGV.size==0
OptionParser.new do |opts|
   opts.banner = "
Generates easy-to-parse tagged reads from FastQ files.

Usage: #{$0} [options]"
   opts.separator ""
   opts.separator "Mandatory"
   opts.on("-i", "--in FILE", "Path to the FastQ file containing the sequences."){ |v| o[:in] = v }
   opts.on("-o", "--out FILE", "Path to the FastQ to create."){ |v| o[:out] = v }
   opts.separator ""
   opts.separator "ID options"
   opts.on("-p", "--prefix STR", "Prefix to use in all IDs."){ |v| o[:p] = v }
   opts.on("-s", "--suffix STR", "Suffix to use in all IDs."){ |v| o[:s] = v }
   opts.separator ""
   opts.separator "Other Options"
   opts.on("-q", "--quiet", "Run quietly (no STDERR output)"){ o[:q] = TRUE }
   opts.on("-h", "--help", "Display this screen") do
      puts opts
      exit
   end
   opts.separator ""
end.parse!
abort "-i is mandatory" if o[:in].nil?
abort "-o is mandatory" if o[:out].nil?
   
begin
   ifh = File.open(o[:in], 'r');
   ofh = File.open(o[:out], 'w');
   i=0
   while ln=ifh.gets
      ln.chomp!
      if $.%4==1 and not /^@/.match(ln).nil?
	 i+=1
	 ofh.puts "@#{o[:p]}#{i}#{o[:s]}"
      elsif $.%4==2 or $.%4==0
         ofh.puts ln
      elsif $.%4==3 and not /^\+/.match(ln).nil?
         ofh.puts "+"
      else
         abort "Impossible to parse line #{$.}: #{ln}.\n"
      end
   end
   ifh.close
   ofh.close
rescue => err
   $stderr.puts "Exception: #{err}\n\n"
   err.backtrace.each { |l| $stderr.puts l + "\n" }
   err
end


