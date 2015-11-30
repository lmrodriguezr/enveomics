class Task
   attr_accessor :hash
   def initialize(o)
      @hash = o
      raise "task field required to set Task." if @hash[:task].nil?
      raise "options field required to set Task." if @hash[:options].nil?
   end
   def task
      hash[:task]
   end
   def description
      hash[:description]
   end
   def options
      @options ||= hash[:options].map{ |o| Option.new(o) }
      @options
   end
   def requires
      @hash[:requires] ||= []
      @requires ||= hash[:requires].map{ |r| Requires.new(r) }
      @requires
   end
end

class Option
   @@TYPE = {
      nil: {name: "Nil"},
      in_file: {name: "Input file"},
      out_file: {name: "Output file"},
      string: {name: "String"},
      integer: {name: "Integer"},
      float: {name: "Floating-point number"}
   }
   def self.TYPE
      @@TYPE
   end
   attr_accessor :hash
   def initialize(o)
      if o.is_a? Hash
	 @hash = o
      elsif o.is_a? String
	 @hash = {hidden:true, arg:o, asis:true}
      else
	 raise "Unsupported object to initialize Option: #{o.class}."
      end
   end
   def name
      if hash[:name].nil?
	 @hash[:name] = (not hash[:opt].nil?) ?
	    hash[:opt].sub(/^-+/,"").gsub(/[-_]/," ") :
	    (not hash[:arg].nil?) ?
	    Option.TYPE[ hash[:arg].to_sym ][:name] :
	    ""
      end
      hash[:name]
   end
   def arg
      @hash[:arg] ||= :nil
      hash[:arg].to_sym
   end
end

class Requires
   attr_accessor :hash
   def initialize(o)
      @hash = o
      raise "Empty requirement." if
	 @hash[:test].nil? and @hash[:description].nil?
   end
   def pass?
      return true if hash[:test].nil?
      `#{hash[:test]}`==1
   end
   def description
      @hash[:description] ||= hash[:test]
      hash[:description]
   end
end
