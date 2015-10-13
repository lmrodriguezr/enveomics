#!/usr/bin/env ruby

#
# @author  Luis M. Rodriguez-R
# @update  Oct-07-2015
# @license artistic license 2.0
#

require 'optparse'

o = {:q=>FALSE, :p=>"", :s=>"", :d=>FALSE}
ARGV << '-h' if ARGV.size==0
OptionParser.new do |opts|
   opts.banner = "
Generates easy-to-parse tagged reads from FastA files.

Usage: #{$0} [options]"
   opts.separator ""
   opts.separator "Mandatory"
   opts.on("-i", "--in FILE",
      "Path to the FastA file containing the sequences."){ |v| o[:in] = v }
   opts.on("-o", "--out FILE",
      "Path to the FastA to create."){ |v| o[:out] = v }
   opts.separator ""
   opts.separator "ID options"
   opts.on("-p", "--prefix STR", "Prefix to use in all IDs."){ |v| o[:p] = v }
   opts.on("-s", "--suffix STR", "Suffix to use in all IDs."){ |v| o[:s] = v }
   opts.on("-d", "--defline",
      "Keep the original defline after a space."){ o[:d]=TRUE }
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
      next if ln =~ /^;/
      unless /^>/.match(ln).nil?
	 i+=1
	 ofh.puts ">#{o[:p]}#{i}#{o[:s]}#{ o[:d]?" #{ln[1, ln.size-1]}":"" }"
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


