require "json"
require "enve-task"

class EnveCollection
   attr_accessor :hash
   def initialize(manif)
      @hash = JSON.parse(File.read(manif), {symbolize_names: true})
      @hash[:categories] ||= {}
      unless @hash[:tasks].nil?
	 @tasks = Hash[@hash[:tasks].map do |h|
	    t = EnveTask.new(h)
	    [t.task, t]
	 end]
      end
      raise "Impossible to initialize collection with empty manifest: " +
	 "#{manif}." if @tasks.nil?
   end
   def tasks
      @tasks.values
   end
   def task(name)
      @tasks[name]
   end
   def each_category(&blk)
      hash[:categories].each do |name,set|
	 blk[name, set]
      end
   end
   def category(name)
      @hash[:categories][name.to_sym] ||= {}
      hash[:categories][name.to_sym]
   end
   def each_subcategory(cat_name, &blk)
      category(cat_name).each do |name,set|
	 blk[name, set]
      end
   end
   def subcategory(cat_name, name)
      category(cat_name)[name.to_sym]
   end
end
