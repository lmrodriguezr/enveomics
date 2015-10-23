
#
# @author: Luis M. Rodriguez-R
# @update: Oct-21-2015
# @license: artistic license 2.0
#

require "optparse"
ARGV << "-h" if ARGV.size==0

def use(gems, mandatory=true)
   gems = [gems] unless gems.is_a? Array
   begin
      require "rubygems"
      while ! gems.empty?
         require gems.first
	 gems.shift
      end
      return true
   rescue LoadError
      abort "\nUnmet requirements, please install required gems:" +
	 gems.map{ |gem| "\n   gem install #{gem}" }.join + "\n\n" if mandatory
      return false
   end
end

