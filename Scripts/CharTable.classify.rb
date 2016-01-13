#!/usr/bin/env ruby

#
# @author  Luis M. Rodriguez-R
# @update  Jan-13-2016
# @license artistic license 2.0
#

require "optparse"

o = {:q=>false}
ARGV << "-h" if ARGV.size==0
OptionParser.new do |opts|
   opts.banner = "
Uses a dichotomous key to classify objects parsing a character table.

Usage: #{$0} [options]"
   opts.separator ""
   opts.separator "Input Options (mandatory)"
   opts.on("-t", "--table FILE",
      "Input table containing the states (columns) per object (row).",
      "It must be tab-delimited and with row and column names.",
      "See Tests/anthrax-cansnp-data.tsv for an example."){ |v| o[:table]=v }
   opts.on("-k", "--key FILE",
      "Input table containing the dychotomous key in linked style, defined in",
      "four columns (can contain #-lead comment lines):",
      "  1. ID of the step, typically a sequential integer.",
      "  2. Name of character to evaluate. Must coincide with the -t headers.",
      "  3. First character decision (see below).",
      "  4. Second character decision (see below).",
      "A character decision must be formated as: state (must coincide with the",
      "values in -t), colon (:), step to follow. If the state is * (star) any",
      "state triggers the decision (this should be the norm in column 4). The",
      "step to follow should be a step ID in square brackets, or the name of",
      "the classification. See Tests/anthrax-cansnp-key.tsv for an example."
      ){ |v| o[:key]=v }
   opts.separator ""
   opts.separator "Output Options"
   opts.on("-c", "--classification FILE",
      "Two-column table with the classification of the input objects."
      ){ |v| o[:class]=v }
   opts.on("-n", "--newick FILE",
      "Tree containing all the classified objects. This only makes sense for",
      "synoptic keys."){ |v| o[:nwk]=v }
   opts.separator ""
   opts.separator "Additional Options"
   opts.on("-q", "--quiet", "Run quietly (no STDERR output)."){ o[:q] = true }
   opts.on("-h", "--help", "Display this screen.") do
      puts opts
      exit
   end
   opts.separator ""
end.parse!
abort "-t is mandatory" if o[:table].nil?
abort "-k is mandatory" if o[:key].nil?

##### Extensions:
class String
   def nwk_sanitize() self.gsub(/[\(\):;,"'\s]/,'_') ; end
end

##### Classes:
module Dychotomous
   class Decision
      attr_reader :state, :terminal, :conclusion
      def initialize(string)
	 r = string.split /:/
	 @state = r[0]
	 @terminal = !(r[1] =~ /^\[(.*)\]$/)
	 @conclusion = @terminal ? r[1] : $1
      end
      def ==(state)
         return true if self.state == '*'
	 self.state == state.to_s
      end
   end
   class Character
      attr_reader :name, :a, :b
      def initialize(name, a, b)
	 @name = name
	 @a = a
	 @b = b
      end
      def eval(object)
	 state = object.state(self.name)
	 return self.a if self.a == state
	 return self.b if self.b == state
	 raise "Impossible to make a decision for #{object.name} based on " +
	    "character #{self.name}. Offending state: #{state.to_s}."
      end
   end
   class Key
      attr_reader :first
      def initialize(file)
	 @characters = {}
	 fh = File.open(file, 'r')
	 while ln = fh.gets
	    next if ln=~/^#/ or ln=~/^\s*$/
	    r = ln.chomp.split /\t/
	    @characters[ r[0] ] = Character.new(r[1],
	       Decision.new(r[2]), Decision.new(r[3]))
	    @first = @characters[ r[0] ] if @first.nil?
	 end
	 fh.close
      end
      def [](name)
	 raise "Cannot find character #{name} in key." if @characters[name].nil?
	 @characters[name]
      end
   end
end
module CharData
   class Object
      attr_reader :name, :states
      def initialize(name)
	 @name = name
	 @states = {}
      end
      def <<(state) @states[state.character] = state ; end
      def state(name) @states[name] ; end
   end
   class State
      attr_reader :character, :state
      def initialize(character, state)
	 @character = character
	 @state = state
      end
      def to_s() self.state.to_s ; end
   end
   class Table
      attr_reader :objects
      def initialize(file)
	 @objects = []
	 fh = File.open(file, 'r')
	 header = fh.gets.chomp.split(/\t/)
	 while ln = fh.gets
	    next if ln=~/^#/ or ln=~/^\s*$/
	    r = ln.chomp.split /\t/
	    o = Object.new(r[0])
	    (1 .. r.size).each{ |i| o << State.new(header[i], r[i]) }
	    self << o
	 end
	 fh.close
      end
      def <<(object) @objects << object ; end
   end
end
module ClassData
   class Classification
      attr_reader :key, :object, :result
      def initialize key, object
	 @key = key
	 @object = object
	 self.classify!
      end
      def classify!
	 @result = self.key.first.eval(object)
	 while ! self.result.terminal
	    @result = self.key[ self.result.conclusion ].eval(object)
	 end
      end
   end
   class Collection
      attr_reader :key, :table, :classifications
      def initialize(key, table)
	 @key = key
	 @table = table
	 @classifications = []
	 self.classify!
      end
      def classify!
	 table.objects.each do |object|
	    @classifications << Classification.new(key, object)
	 end
      end
      def classified_as(conclusion)
         self.classifications.select{ |c|
	    c.result.conclusion==conclusion }.map{ |c| c.object }
      end
      def to_nwk
	 self.to_nwk_node(self.key.first) + ";"
      end
      def to_nwk_node(node)
	 if node.is_a? Dychotomous::Character
	    a = self.to_nwk_node(node.a)
	    b = self.to_nwk_node(node.b)
	    return "" if (a + b)==""
	    return "(" + a + b + ")#{node.name.nwk_sanitize}" if a=="" or b==""
	    return "(" + self.to_nwk_node(node.a) + "," +
	       self.to_nwk_node(node.b) + ")#{node.name.nwk_sanitize}"
	 end
	 if node.is_a? Dychotomous::Decision and node.terminal
	    objects = self.classified_as(node.conclusion)
	    return '' if objects.empty?
	    return objects[0].name.nwk_sanitize if objects.size==1
	    return "(" + objects.map{|o| o.name.nwk_sanitize}.join(",") + ")"
	 end
	 return self.to_nwk_node( self.key[node.conclusion] ) if
	    node.is_a? Dychotomous::Decision
	 raise "Unsupported class: to_nwk_node: #{node}."
      end
   end
end

##### MAIN:
begin
   $stderr.puts "Reading dychotomous key." unless o[:q]
   key = Dychotomous::Key.new(o[:key])
   $stderr.puts "Reading character table." unless o[:q]
   table = CharData::Table.new(o[:table])
   $stderr.puts "Classifying objects." unless o[:q]
   classif = ClassData::Collection.new(key, table)
   
   unless o[:class].nil?
      $stderr.puts "Generating classification table." unless o[:q]
      fh = File.open(o[:class], 'w')
      classif.classifications.each do |c|
         fh.puts c.object.name + "\t" + c.result.conclusion
      end
      fh.close
   end

   unless o[:nwk].nil?
      $stderr.puts "Generating classification tree." unless o[:q]
      fh = File.open(o[:nwk], 'w')
      fh.puts classif.to_nwk
      fh.close
   end
   
rescue => err
   $stderr.puts "Exception: #{err}\n\n"
   err.backtrace.each { |l| $stderr.puts l + "\n" }
   err
end
