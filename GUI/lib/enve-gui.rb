#
# @package enve-omics
# @author  Luis M. Rodriguez-R <lmrodriguezr at gmail dot com>
# @license artistic license 2.0
# @update  Nov-30-2015
#

require "collection"
require "shoes"
if $IS_CLI
   require "shoes/swt"
   Shoes::Swt.initialize_backend
end

class EnveGUI < Shoes
   url "/", :index
   url "/script-(.*)", :script
   $manif_path = File.expand_path("../manifest.json", File.dirname(__FILE__))
   $enve_path  = File.expand_path("../../Scripts", File.dirname(__FILE__))
   $collection = Collection.new($manif_path)
   $enve_jobs  = {}

   def self.init (&block)
      Shoes.app(title: "Enve-omics | Everyday bioinformatics",
	 width: 750, height: 500, &block)
   end
   
   # =====================[ View : Windows ]
   # Main window
   def index
      background gradient("#eefefe","#bbacac")
      stack(margin:40) do
	 title "Welcome to the Enve-omics collection!", align:"center"
	 para ""
	 para "To begin, please select one of the following tasks:"
	 stack do
	    $collection.tasks.each do |t|
	       para link(t.task){ visit "/script-#{t.task}" }, ": ",
		  t.description
	    end
	 end
      end
   end

   # Script query
   def script(task)
      background gradient("#eefefe","#bbacac")
      para link("home"){ visit "/" }, align:"right"
      stack(margin:40) do
	 t = $collection.task(task)
	 title t.task
	 subtitle t.description
      end
   end

   # =====================[ View : Elements ]
   
   
   # =====================[ Controller : Tasks ]
   
   

end
