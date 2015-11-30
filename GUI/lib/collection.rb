require "json"
require "task"

class Collection
   attr_accessor :hash, :tasks
   def initialize(manif)
      @hash = JSON.parse(File.read(manif), {symbolize_names: true})
      @tasks = @hash[:tasks].map{ |h| Task.new(h) } unless @hash[:tasks].nil?
      raise "Impossible to initialize collection with empty manifest: #{manif}." if @tasks.nil?
   end
   def task(name)
      tasks.first{ |t| t.task==t }
   end
end
