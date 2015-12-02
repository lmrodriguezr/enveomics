#
# @package enveomics
# @author  Luis M. Rodriguez-R <lmrodriguezr at gmail dot com>
# @license artistic license 2.0
# @update  Dec-02-2015
#

require "date"
require "tempfile"
require "enve-collection"
if $IS_CLI
   require "shoes"
   require "shoes/swt"
   Shoes::Swt.initialize_backend
end

class EnveGUI < Shoes
   url "/", :home
   url "/index", :index
   url "/about", :about
   url "/script-(.*)", :script
   $enve_path  = File.expand_path("../../Scripts", File.dirname(__FILE__))
   $img_path   = File.expand_path("../img", File.dirname(__FILE__))
   $enve_jobs  = {}
   $citation   = [
      "Rodriguez-R and Konstantinidis. In preparation. The enveomics ",
      "collection: a toolbox for specialized analyses in genomics and ",
      "metagenomics."].join

   def self.init (&block)
      Shoes.app(title: "Enveomics | Everyday bioinformatics",
	 width: 750, height: 500, &block)
   end
   
   # =====================[ View : Windows ]
   # Main window
   def home
      header
      stack(margin:40) do
	 title "Welcome to the Enveomics collection!", align:"center"
	 $home_info = para "Retrieving enveomics..."
	 $manif_path = EnveCollection.manif
	 if $manif_path.nil?
	    download EnveCollection.master_url,
	       save: File.expand_path("master.zip", EnveCollection.home),
	       finish: proc { |d|
		  $home_info.text = "Unzipping..."
		  `cd #{EnveCollection.home.shellescape} && unzip master.zip`
		  $manif_path = EnveCollection.manif
		  show_home
	       }
	 else
	    show_home
	 end
      end
      footer
   end
   # Index of tasks
   def index
      header
      stack(margin:40) do
	 title "Welcome to the Enveomics collection!", align:"center"
	 para ""
	 stack do
	    $collection.each_category do |cat_name, cat_set|
	       stack(margin: 20) do
		  subtitle cat_name
		  cat_set.each do |subcat_name, subcat_set|
		     stack(margin: 10) do
			para strong(subcat_name)
			subcat_set.each do |t_name|
			   t = $collection.task(t_name)
			   if t.nil?
			      para t_name, stroke: "#777", margin: 5
			   else
			      para link(t.task, click: "/script-#{t.task}"),
				 ": ", t.description, margin: 5
			   end
			end # each task
		     end # stack (subcategory)
		  end # each subcategory
	       end # stack (category)
	    end # each category
	 end # stack (collection)
      end # stack (main)
      footer
   end

   # About enveomics
   def about
      header
      stack(margin:40) do
	 title "About the enveomics collection", align:"center"
	 para ""
	 subtitle "Citation"
	 para $citation
	 para ""
	 subtitle "GUI Resources"
	 para "The Graphical User Interface was developed on Shoes4 by ",
	    "Luis M. Rodriguez-R [lmrodriguezr@gmail.com]. ",
	    "Icons by Yu Luck from the Noun Project ",
	    "[https://thenounproject.com/yuluck/uploads]."
      end
      footer
   end

   # Script query
   def script(task)
      header
      stack(margin:40) do
	 @t = $collection.task(task)
	 title @t.task
	 subtitle @t.description
	 unless @t.ready?
	    para ""
	    stack(margin:[50,0,50,0]) do
	       background "#fdd"..."#f99"
	       border "#300"
	       stack(margin:[20,0,20,0]) do
		  para ""
		  para strong("This script cannot be used due to unmet" +
		     " requirements:")
		  @t.unmet.each do |r|
		     para r.description, margin:[10,0,10,0]
		  end
		  para ""
	       end
	    end
	 end
	 para "", margin:10
	 @opt_value = []
	 @opt_elem  = []
	 @t.each_option do |opt_i,opt|
	    next if opt.hidden?
	    stack(margin:[10,0,10,0]) do
	       subtitle opt.name
	       para opt.description if opt.description and opt.arg!=:nil
	       case opt.arg
		  when :nil
		     flow do
			@opt_elem[opt_i] = check
			para opt.description if opt.description
		     end
		  when :in_file,:out_file
		     flow do
			button("Open file") do
			   @file = opt.arg==:in_file ?
			      Shoes.ask_open_file :
			      Shoes.ask_save_file
			   unless @file.nil?
			      @opt_value[opt_i] = @file
			      @opt_elem[opt_i].text = @opt_value[opt_i]
			   end
			end
			@opt_elem[opt_i] = edit_line ""
		     end
		  when :select
		     @opt_elem[opt_i] = list_box items: opt.values
		  when :string, :integer, :float
		     @opt_elem[opt_i] = edit_line opt.default
	       end
	       inscription opt.note if opt.note
	    end # stack (option)
	    para "", margin:10
	 end # each option
	 para strong("* Required"), margin:[10,0,10,0]
	 para ""
	 flow do
	    button("Execute") do
	       @values = []
	       @t.each_option do |opt_i, opt|
		  e = @opt_elem[opt_i]
		  @values[opt_i] = e.nil? ? nil :
		     e.is_a?(Check) ? e.checked? : e.text
	       end
	       launch_analysis(@t, @values)
	    end
	    button("Reset defaults"){ visit "/script-#{task}" }
	 end
      end # stack (task)
      footer
   end

   # =====================[ View : Elements ]
   def header
      self.scroll_top = 0
      background "#eefefe"..."#bbacac"
      stack(margin:[40,0,40,5]) do
	 flow(width:1.0, height:60) do
	    stack(width:64, margin:5) do
	       image img_path("noun_208357_cc.png"),
		  width:50, height:50, margin:2
	       inscription "Home", align:"center"
	    end.click{ visit "/" }
	    stack(width:64, margin:5) do
	       image img_path("noun_229118_cc.png"),
		  width:50, height:50, margin:2
	       inscription "About", align:"center"
	    end.click{ visit "/about" }
	 end
	 inscription ""
	 stack(height:2, width:1.0) { background black }
      end
   end

   def footer
      para "", margin:50
   end
   
   # =====================[ Controller : Tasks ]
   def launch_analysis(t, values)
      begin
	 log = Tempfile.new("enveomics")
	 log.close
	 cmd = t.build_cmd(values, log)
	 window(title: "Running #{t.task}", width: 750, height: 512) do
	    background "#eefefe"..."#bbacac"
	    @cmd = cmd
	    @log = log
	    stack(margin:30, width:1.0) do
	       subtitle t.task
	       para strong("Start time: "), DateTime.now.ctime
	       para ""
	       para strong("Command:")
	       edit_box @cmd, width:1.0, height:40, state:"readonly"
	       @running = para ""
	       animate(4) do |frame|
		  @running.text = "   " + ("." * (frame%4)) unless @running.nil?
	       end
	       timer(1) do
		  status = `#{@cmd}`
		  @running.text = ""
		  @running = nil
		  unless status
		     para "Execution failed: ", $?
		  end
		  para strong("Log: "), @log.path
		  stack do
		     File.open(@log.path, "r") do |f|
			edit_box f.read, state:"readonly",
			   width:1.0, height: 275
		     end
		  end
		  @log.unlink
		  para ""
		  para strong("End time: "), DateTime.now.ctime
	       end
	    end
	 end
      rescue => e
	 Shoes.alert e
      end
   end

   def img_path(img)
      # Easy peasy for normal files
      o = File.expand_path(img,$img_path)
      return o if __FILE__ !~ /\.jar!\//
      # Juggling around packages:
      $img_cache ||= {}
      if $img_cache[img].nil?
	 f = Tempfile.new("enveomics")
	 f.close
	 FileUtils.copy o, f.path
	 $img_cache[img] = f.path
      end
      $img_cache[img]
   end
   
   def show_home
      $home_info.text = "Loading collection..."
      $collection ||= EnveCollection.new($manif_path)
      $home_info.text = ""
   end
end
