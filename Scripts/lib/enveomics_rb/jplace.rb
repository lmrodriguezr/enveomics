
#
# @author: Luis M. Rodriguez-R
# @update: Jul-14-2015
# @license: artistic license 2.0
#

module JPlace
   ##### CLASSES:
   # Placement.new(placement[, fields]): Initializes a new read placement.
   # placement: A hash containing the placement.
   # fields: If passed, sets the field order for all subsequent placements.
   class Placement
      attr_writer :flag # This attribute is used by JPlace.distances.rb as a placeholder
      attr_reader :p, :n, :m, :flag
      @@fields = nil
      def self.fields=(fields)
	 @@fields=fields
      end
      def self.fields
	 @@fields
      end
      def initialize(placement, fields=nil)
	 @@fields = fields if @@fields.nil? and not fields.nil?
	 # Save only the best (first) placement:
	 abort "Placements must contain a 'p' field.\n" if placement["p"].nil?
	 abort "Placements must contain a 'p' field with at least one entry.\n" if placement["p"][0].nil?
	 @p = [placement["p"][0]]
	 # Find name-only placements (EPA-style):
	 unless placement["n"].nil?
	    @n = placement["n"]
	    @m = @n.map{ |n| 1 }
	 end
	 # Find multiplicity placements (pplacer-style):
	 unless placement["nm"].nil?
	    @n = placement["nm"].map{ |nm| nm[0] }
	    @m = placement["nm"].map{ |nm| nm[1].to_i }
	 end
	 abort "Placements must contain one of 'n' or 'nm' fields.\n" if @n.nil? or @m.nil?
      end
      def nm
	 (0 .. (self.n.length-1)).map{ |i| {:n=>self.n[i], :m=>self.m[i]} }
      end
      def get_field_value(field)
	 abort "Impossible to read placement with undefined fields." if @@fields.nil?
	 f = @@fields.find_index(field)
	 abort "Undefined field #{field}." if f.nil?
	 self.p[0][f]
      end
      def set_field_value(field, value)
	 f = @@fields.find_index(field)
	 abort "Undefined field #{field}." if f.nil?
	 self.p[0][f] = value
      end
      def edge_num
	 self.get_field_value('edge_num').to_i
      end
      def likelihood
	 self.get_field_value('likelihood').to_f
      end
      def like_weight_ratio
	 self.get_field_value('like_weight_ratio').to_f
      end
      def distal_length
	 (self.get_field_value('distal_length') || 0).to_f
      end
      def pendant_length
	 (self.get_field_value('pendant_length') || 0).to_f
      end
      def to_s
	 "#<Placement of #{self.n}: #{self.p}>"
      end
   end

   # Ancilliary class Tree
   class Tree
      @@HAS_ICONV = nil
      def self.has_iconv?
	 if @@HAS_ICONV.nil?
	    @@HAS_ICONV = true
	    begin
	       require 'rubygems'
	       require 'iconv'
	    rescue LoadError
	       @@HAS_ICONV = false
	    end
	 end
	 @@HAS_ICONV
      end
      def self.from_nwk(nwk)
	 if Tree.has_iconv?
	    ic = Iconv.new('UTF-8//IGNORE','UTF-8')
	    nwk = ic.iconv(nwk + ' ')[0..-2]
	 end
	 Node.new(nwk)
      end
   end
   
   # Node.new(nwk[, parent]): Initializes a new Node.
   # nwk: Node's description in Newick format.
   # parent: Node's parent, or nil if root node.
   class Node
      # Class
      @@edges = []
      def self.edges
	 @@edges
      end
      def self.register(node)
	 @@edges[node.index] = node unless node.index.nil?
      end
      # Class-level functions related to JPlace
      def self.link_placement(placement)
	 abort "Trying to link placement in undefined edge #{placement.edge_num}: #{placement.to_s}" if @@edges[placement.edge_num].nil?
	 @@edges[placement.edge_num].add_placement!(placement)
      end
      def self.unlink_placement(placement)
	 @@edges[placement.edge_num].delete_placement!(placement)
      end
      # Instance
      attr_reader :children, :length, :name, :label, :index, :nwk, :parent, :placements, :collapsed
      def initialize(nwk, parent=nil)
	 abort "Empty newick.\n" if nwk.nil? or nwk==''
	 nwk.gsub! /;(.)/, '--\1'
	 @nwk = nwk
	 @parent = parent
	 @placements = []
	 @collapsed = false
	 # Find index
	 index_m = /^(?<pre>.*){(?<idx>[0-9]+)}(?<post>[^\(\),;]*);?$/.match(nwk)
	 if index_m.nil? and parent.nil? and nwk[nwk.length-1]==';'
	    @index = nil
	 else
	    abort "Unindexed edge found:\n#{@nwk}\n" if index_m.nil?
	    nwk = index_m[:pre]+index_m[:post]
	    @index = index_m[:idx].to_i
	 end
	 # Find name, label, and length
	 meta_m = /^(\((?<cont>.+)\))?(?<name>[^:\(\);]*)(:(?<length>[0-9\.Ee+-]*)(?<label>\[[^\[\]\(\);]+\])?)?;?$/.match(nwk) or
	    abort "Cannot parse node metadata (index #{@index}):\n#{@nwk}\n"
	 nwk = meta_m[:cont]
	 @name = meta_m[:name]
	 @length = meta_m[:length]
	 @label = meta_m[:label]
	 # Find children
	 @children = []
	 nwk ||= ''
	 quote = nil
	 while nwk != ''
	    i = 0
	    j = 0
	    nwk.each_char do |chr|
	       if quote.nil?
		  if chr=='"' or chr=="'"
		     quote = chr
		  else
		     i += 1 if chr=='('
		     i -= 1 if chr==')'
		     if i==0 and chr==','
			i=nil
			break
		     end
		  end
	       else
		  quote = nil if chr==quote
	       end
	       j += 1
	    end
	    abort "Unbalanced node at edge {#{@index}}, with leftness #{i}:\n#{@nwk}\n" unless i.nil? or i==0
	    @children << Node.new(nwk[0 .. j-1],self)
	    nwk = nwk.length==j ? '' : nwk[j+1 .. -1]
	 end
	 Node.register(self)
      end
      # Accessors/Setters
      def name=(new_name)
	 @name = new_name.gsub(/[\s\(\),;:]/, '_')
      end
      # Tree algorithms
      def post_order &blk
	 self.children.each { |n| n.post_order &blk }
	 blk[self]
      end
      def in_order &blk
	 abort "Tree must be dycotomic to traverse in_order, node #{self.cannonical_name} "+
	    "has #{self.children.lenght} children." unless [0,2].include? self.children.length
	 self.children[0].in_order &blk unless self.children[0].nil?
	 blk[self]
	 self.children[1].in_order &blk unless self.children[1].nil?
      end
      def pre_order &blk
	 blk[self]
	 self.children.each { |n| n.pre_order &blk }
      end
      def path_to_root
	 if @path_to_root.nil?
	    @path_to_root = [self]
	    @path_to_root += self.parent.path_to_root unless self.parent.nil?
	 end
	 @path_to_root
      end
      def distance_to_root
	 if @distance_to_root.nil?
	    @distance_to_root = path_to_root.map{ |n| n.length.nil? ? 0.0 : n.length.to_f }.reduce(0.0, :+)
	 end
	 @distance_to_root
      end
      def lca(node)
	 p1 = self.path_to_root
	 p2 = node.path_to_root
	 p1.find{ |n| p2.include? n }
      end
      def distance(node)
	 self.distance_to_root + node.distance_to_root - (2.0 * self.lca(node).distance_to_root)
      end
      def ==(node) self.index == node.index ; end
      # Tree representation
      def cannonical_name
	 return(self.name) unless self.name.nil? or self.name == ""
	 return(self.label) unless self.label.nil? or self.label == ""
	 return("{#{self.index.to_s}}") unless self.index.nil?
	 ""
      end
      def to_s
	 o = ""
	 o += "(" + self.children.map{ |c| c.to_s }.join(",") + ")" if self.children.length > 0
	 o += self.cannonical_name
	 u = "#{self.length.nil? ? "" : self.length}#{self.label.nil? ? "" : self.label}"
	 o += ":#{u}" unless u==""
	 o
      end
      # Instance-level functions related to JPlace
      def collapse!
	 self.pre_order do |n|
	    if n!=self
	       while n.placements.length > 0
		  p = Node.unlink_placement(n.placements[0])
		  p.set_field_value('edge_num', self.index)
		  Node.link_placement(p)
	       end
	    end
	 end
	 @collapsed = true
      end
      def add_placement!(placement)
	 @placements << placement
      end
      def delete_placement!(placement)
	 @placements.delete(placement)
      end
   end

end # module JPlace

