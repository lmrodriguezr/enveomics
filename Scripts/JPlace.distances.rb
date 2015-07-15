#!/usr/bin/env ruby

#
# @author: Luis M. Rodriguez-R
# @update: Jul-14-2015
# @license: artistic license 2.0
#

$:.push File.expand_path(File.dirname(__FILE__) + '/lib')
require 'enveomics_rb/jplace'
require 'optparse'
require 'json'

o = {:q=>false}
ARGV << '-h' if ARGV.size==0
OptionParser.new do |opts|
   opts.banner = "
Extracts the distance (estimated branch length) of each placed read to a given node in a JPlace file.

Usage: #{$0} [options]"
   opts.separator ""
   opts.separator "Mandatory"
   opts.on("-i", "--in FILE", ".jplace input file containing the read placement."){ |v| o[:in]=v }
   opts.on("-n", "--node STR", "Index (number in curly brackets) of the node to which distances should be measured."){ |v| o[:node]=v }
   opts.on("-o", "--out FILE", "Ouput file."){ |v| o[:out]=v }
   opts.separator ""
   opts.separator "Other Options"
   opts.on("-N", "--in-node STR","Report only reads placed at this node or it's children."){ |v| o[:onlynode]=v }
   opts.on("-q", "--quiet", "Run quietly (no STDERR output)."){ o[:q] = true }
   opts.on("-h", "--help", "Display this screen.") do
      puts opts
      exit
   end
   opts.separator ""
end.parse!
abort "-i is mandatory" if o[:in].nil?
abort "-o is mandatory" if o[:out].nil?
abort "-n is mandatory" if o[:node].nil?

##### MAIN:
begin
   $stderr.puts "Loading jplace file." unless o[:q]
   ifh = File.open(o[:in], 'r')
   jplace = JSON.load(ifh)
   ifh.close
   
   $stderr.puts "Parsing tree." unless o[:q]
   tree = JPlace::Tree.from_nwk(jplace["tree"])
   node = JPlace::Node.edges[ o[:node].gsub(/[{}]/,"").to_i ]
   from_node = o[:onlynode].nil? ? tree : JPlace::Node.edges[ o[:onlynode].gsub(/[{}]/,"").to_i ]
   raise "Cannot find node with index #{o[:node]}." if node.nil?
   raise "Cannot find node with index #{o[:onlynode]}." if from_node.nil?

   $stderr.puts "Parsing placements." unless o[:q]
   JPlace::Placement.fields = jplace["fields"]
   placements_n = 0
   jplace["placements"].each do |placement|
      JPlace::Node.link_placement(JPlace::Placement.new(placement))
      placements_n += 1
   end
   $stderr.puts " #{placements_n} placements in tree, #{node.placements.length} direct placements to {#{node.index}}." unless o[:q]
   
   # First, calculate distances
   from_node.pre_order do |n|
      d = n.distance(node)
      if node.path_to_root.include? n
	 n.placements.each{ |p| p.flag = d + p.pendant_length + p.distal_length }
      else
	 n.placements.each{ |p| p.flag = d + p.pendant_length - p.distal_length }
      end
   end
   
   # Finally, report results
   ofh = File.open(o[:out], "w")
   ofh.puts %w(read distance multiplicity edge_index node_name).join("\t")
   from_node.pre_order do |n|
      n.placements.each do |p|
	 p.nm.each{ |r| ofh.puts [ r[:n], p.flag, r[:m], n.index, n.name ].join("\t") }
      end
   end
   ofh.close
rescue => err
   $stderr.puts "Exception: #{err}\n\n"
   err.backtrace.each { |l| $stderr.puts l + "\n" }
   err
end


