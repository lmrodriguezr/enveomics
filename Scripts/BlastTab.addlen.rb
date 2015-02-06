#!/usr/bin/env ruby

#
# @author: Luis M. Rodriguez-R
# @update: Feb-06-2015
# @license: artistic license 2.0
#

require 'optparse'

o = {:subject=>FALSE, :quiet=>FALSE}
ARGV << '-h' if ARGV.size==0
OptionParser.new do |opts|
   opts.banner = "
Appends an extra column to a BLAST with the length of the query or the subject sequence.
You can pipe two instances to add both:
   cat input.blast | #{$0} -f queries.fa | #{$0} -f subjects.fa -s > output.blast

Usage: #{$0} [options] < input.blast > output.blast"
   opts.separator ""
   opts.separator "Mandatory"
   opts.on("-f", "--fasta FILE", "Path to the FastA file"){ |v| o[:fasta] = v }
   opts.separator ""
   opts.separator "Options"
   opts.on("-s", "--subject",
   	"Use the subject column of the BLAST, by default the query column is used"){ o[:subject] = TRUE }
   opts.on("-q", "--quiet", "Run quietly (no STDERR output)"){ o[:quiet] = TRUE }
   opts.on("-h", "--help", "Display this screen") do
      puts opts
      exit
   end
   opts.separator ""
end.parse!
abort "-f is mandatory" if o[:fasta].nil?

len = {}
id  = ""
$stderr.puts "Reading FastA file: #{o[:fasta]}" unless o[:quiet]
fh = File.open(o[:fasta], "r")
fh.each_line do |ln|
   defline = /^>(\S+)/.match(ln)
   if defline.nil?
      ln.gsub! /[^A-Za-z]/, ''
      abort "Error: Unsupported format, expecting FastA" if len[id].nil?
      len[id] = len[id] + ln.size
   else
      id = defline[1]
      len[id] = 0
   end
end
fh.close

$stderr.puts "Appending #{o[:subject]?"subject":"query"} length column" unless o[:quiet]
ARGF.each_line do |ln|
   ln.chomp!
   row = ln.split /\t/
   id = o[:subject] ? row[1] : row[0];
   abort "Impossible to find sequence of #{id}" if len[id].nil?
   puts "#{ln}\t#{len[id]}"
end

