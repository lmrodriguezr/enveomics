#!/usr/bin/env ruby

# @author: Luis M. Rodriguez-R
# @license: artistic license 2.0

$:.push File.expand_path("../lib", __FILE__)
require "enveomics_rb/enveomics"
require "enveomics_rb/jplace"
require "optparse"
require "json"

o = {q: false, regex: "^(?<dataset>.+?):.*", area: false, norm: :counts,
  olditol: false}
ARGV << "-h" if ARGV.size==0
OptionParser.new do |opts|
  opts.banner = "
Generates iToL-compatible files from a .jplace file (produced by RAxML's EPA
or pplacer), that can be used to draw pie-charts in the nodes of the reference
tree.

Usage: #{$0} [options]"
  opts.separator ""
  opts.separator "Mandatory"
  opts.on("-i", "--in FILE",
    ".jplace input file containing the read placement."){ |v| o[:in]=v }
  opts.on("-o", "--out FILE", "Base of the output files."){ |v| o[:out]=v }
  opts.separator ""
  opts.separator "Other Options"
  opts.on("-u", "--unique STR",
    "Name of the dataset (if only one is used). Conflicts with -r and -s."
    ){ |v| o[:unique]=v }
  opts.on("-r", "--regex STR",
    "Regular expression capturing the sample ID (named dataset) in read names.",
    "By default: '#{o[:regex]}'. Conflicts with -s."){ |v| o[:regex]=v }
  opts.on("-s", "--separator STR",
    "String separating the dataset name and the rest of the read name.",
    "It assumes that the read name starts by the dataset name. Conflicts with -r."
    ){ |v| o[:regex]="^(?<dataset>.+?)#{v}" }
  opts.on("-m", "--metadata FILE",
    "Datasets metadata in tab-delimited format with a header row.",
    "Valid headers: name (required), color (in Hex), size (# reads), norm (any float)."
    ){ |v| o[:metadata]=v }
  opts.on("-n", "--norm STR", %w[none counts size norm],
    "Normalization strategy. Must be one of:",
    "none: Direct read counts are reported without normalization.",
    "count (default): The counts are normalized (divided) by the total counts per dataset.",
    "size: The counts are normalized (divided) by the size column in metadata (must be integer).",
    "norm: The counts are normalized (divided) by the norm column in metadata (can be any float)."
    ){ |v| o[:norm]=v.to_sym }
  opts.on("--old-itol",
    "Generate output file using the old iToL format (pre v3.0)."
    ){ |v| o[:olditol] = v }
  opts.on("-c", "--collapse FILE",
    "Internal nodes to collapse (requires rootted tree)."){ |v| o[:collapse]=v }
  opts.on("-a", "--area",
    "If set, the area of the pies is proportional to the placements. Otherwise, the radius is."
    ){ o[:area]=true }
  opts.on("-q", "--quiet", "Run quietly (no STDERR output)."){ o[:q] = true }
  opts.on("-h", "--help", "Display this screen.") do
    puts opts
    exit
  end
  opts.separator ""
  opts.separator "Quick how-to in 5 steps"
  opts.separator "    1. Create the placement file using RAxML's EPA [1] or pplacer [2]. You can use any other software"
  opts.separator "       producing a compliant .jplace file [3]. If you're using multiple datasets, include the name of"
  opts.separator "       the dataset somewhere in the read names."
  opts.separator "    2. If you have multiple datasets, it's convenient to create a metadata table. It's not necessary,"
  opts.separator "       but it allows you to control the colors and the normalization method (see -m)."
  opts.separator "    3. Execute this script passing the .jplace file created in step 1 (see -i).  If you have a single"
  opts.separator "       dataset, use the option -u to give it a short name.  If you have multiple datasets, use the -s"
  opts.separator "       or -r options to tell the script how to find the dataset name within the read name.  Note that"
  opts.separator "       some programs (like CheckM) may produce nonstandard characters that won't be correctly parsed."
  opts.separator "       To avoid this problem,  install iconv support (gem install iconv) before running this script"
  opts.separator "       (currently "+(JPlace::Tree.has_iconv? ? "" : "NOT ")+"installed)."
  opts.separator "    4. Upload the tree (.nwk file) to iToL  [4].  Make sure you check 'Keep internal node IDs' in the"
  opts.separator "       advanced options.  In that same page, upload the dataset (.itol file), pick a name, and select"
  opts.separator "       the data type 'Multi-value Bar Chart or Pie Chart'. If you used the -c option, upload the list"
  opts.separator "       of nodes to collapse (.collapse file) in the 'Pre-collapsed clades' field (advanced options)."
  opts.separator "    5. Open the tree. You can now see the names of the internal nodes. If you want to collapse nodes,"
  opts.separator "       simply list the nodes to collapse and go back to step 3, this time using the -c option."
  opts.separator ""
  opts.separator "References"
  opts.separator "    [1] SA Berger, D Krompass and A Stamatakis, 2011, Syst Biol 60(3):291-302."
  opts.separator "        http://sysbio.oxfordjournals.org/content/60/3/291"
  opts.separator "    [2] FA Matsen, RB Kodner and EV Armbrust, 2010, BMC Bioinf 11:538."
  opts.separator "        http://www.biomedcentral.com/1471-2105/11/538/"
  opts.separator "    [3] FA Matsen, NG Hoffman, A Gallagher and A Stamatakis, 2012, PLoS ONE 7(2):e31009."
  opts.separator "        http://www.plosone.org/article/info%3Adoi%2F10.1371%2Fjournal.pone.0031009"
  opts.separator "    [4] I Letunic and P Bork, 2011, NAR 39(suppl 2):W475-W478."
  opts.separator "        http://nar.oxfordjournals.org/content/39/suppl_2/W475.full"
  opts.separator ""
end.parse!
abort "-o is mandatory" if o[:out].nil?

##### CLASSES:

class Dataset
  attr_reader :name, :data
  def initialize(name)
    @name = name
    @data = {:count=>0}
  end
  def count
    self.datum :count
  end
  def add_count(n)
    @data[:count] += n
  end
  def datum(k)
    @data[k]
  end
  def add_datum(k, v)
    @data[k] = v
  end
  def color
    if @data[:color].nil?
      @data[:color] = "#" + (1 .. 3).map{ |i|
        sprintf("%02X", rand(255)) }.join("")
    end
    @data[:color].sub(/^#?/, "#")
    self.datum :color
  end
  def size
    self.datum :size
  end
  def norm
    self.datum :norm
  end
end

class Metadata
  attr_reader :datasets
  def initialize
    @datasets = {}
  end
  def load_table(file)
    f = File.open(file, "r")
    h = f.gets.chomp.split(/\t/)
    name_idx = h.find_index "name"
    color_idx = h.find_index "color"
    size_idx = h.find_index "size"
    norm_idx = h.find_index "norm"
    abort "The metadata table must contain a 'name' column." if name_idx.nil?
    while ln = f.gets
      vals = ln.chomp.split(/\t/)
      name = vals[name_idx]
      self[name] # Create sample, in case "name" is the only column
      self[name].add_datum(:color, vals[color_idx]) unless color_idx.nil?
      self[name].add_datum(:size, vals[size_idx].to_i) unless size_idx.nil?
      self[name].add_datum(:norm, vals[norm_idx].to_f) unless norm_idx.nil?
    end
    f.close
  end
  def [](name)
    self << Dataset.new(name) unless @datasets.has_key?(name)
    @datasets[name]
  end
  def <<(dataset)
    @datasets[dataset.name] = dataset
  end
  def names
    @datasets.keys
  end
  def colors
    @datasets.values.map{ |d| d.color }
  end
  def data(k)
    self.names.map{ |name| self[name].datum[k] }
  end
  def set_unique!(n)
    u = self[n]
    @datasets = {}
    @datasets[n] = u
  end
  def size
    self.datasets.length
  end
end

##### MAIN:
begin
  $stderr.puts "Parsing metadata." unless o[:q]
  metadata = Metadata.new
  metadata.load_table(o[:metadata]) unless o[:metadata].nil?
  metadata.set_unique! o[:unique] unless o[:unique].nil?


  $stderr.puts "Loading jplace file." unless o[:q]
  ifh = File.open(o[:in], 'r')
  jplace = JSON.load(ifh)
  ifh.close


  $stderr.puts "Parsing tree." unless o[:q]
  tree = JPlace::Tree.from_nwk(jplace["tree"])


  $stderr.puts "Parsing placements." unless o[:q]
  JPlace::Placement.fields = jplace["fields"]
  placements_n = 0
  jplace["placements"].each do |placement|
    JPlace::Node.link_placement(JPlace::Placement.new(placement))
    placements_n += 1
  end
  $stderr.puts " #{placements_n} placements." unless o[:q]
  tree.pre_order do |n|
    n.placements.each do |p|
      p.nm.each do |r|
        m = (o[:unique].nil? ? (/#{o[:regex]}/.match(r[:n]) or
          abort "Cannot parse read name: #{r[:n]}, placed at edge #{n.index}") :
          {:dataset=>o[:unique]})
        metadata[ m[:dataset] ].add_count(r[:m])
      end
    end
  end


  unless o[:collapse].nil?
    $stderr.puts "Collapsing nodes." unless o[:q]
    collapse = File.readlines(o[:collapse]).map do |ln|
      l = ln.chomp.split(/\t/)
      l[1] = l[0] if l[1].nil?
      l
    end.inject({}) do |hash,ar|
      hash[ar[0]] = ar[1]
      hash
    end
    f = File.open(o[:out] + ".collapse", "w")
    coll_n = 0
    tree.pre_order do |n|
      if collapse.keys.include? n.cannonical_name
        n.collapse!
        n.name = collapse[n.cannonical_name]
        f.puts n.name
        coll_n += 1
      end
    end
    f.close
    $stderr.puts " #{coll_n} nodes collapsed (#{collapse.length} requested)." unless o[:q]
  end
   

  $stderr.puts "Estimating normalizing factors by #{o[:norm].to_s}." unless o[:q] or o[:norm]==:none
  case o[:norm]
  when :none
    metadata.datasets.values.each{ |d| d.add_datum :norm, 1.0 }
  when :counts
    metadata.datasets.values.each{ |d| d.add_datum :norm, d.count.to_f }
  when :size
    abort "Column 'size' required in metadata." if metadata.datasets.values[0].size.nil?
    metadata.datasets.values.each{ |d| d.add_datum :norm, d.size.to_f }
  when :norm
    abort "Column 'norm' required in metadata." if metadata.datasets.values[0].norm.nil?
  end
  max_norm = metadata.datasets.values.map{ |d| d.norm }.max


  $stderr.puts "Generating iToL dataset." unless o[:q]
  f = File.open(o[:out] + ".itol.txt", "w")
  if o[:olditol]
    f.puts "LABELS\t" + metadata.names.join("\t")
    f.puts "COLORS\t" + metadata.colors.join("\t")
  else
    f.puts "DATASET_PIECHART"
    f.puts "SEPARATOR TAB"
    f.puts "DATASET_LABEL\tReadPlacement"
    f.puts "COLOR\t#1f2122"
    f.puts "FIELD_LABELS\t" + metadata.names.join("\t")
    f.puts "FIELD_COLORS\t" + metadata.colors.join("\t")
    f.puts "DATA"
  end
  max_norm_sum,min_norm_sum,max_norm_n,min_norm_n = 0.0,Float::INFINITY,"",""
  tree.pre_order do |n|
    ds_counts = Hash.new(0.0)
    n.placements.each do |p|
      p.nm.each do |r|
        m = (o[:unique].nil? ? (/#{o[:regex]}/.match(r[:n]) or
          abort "Cannot parse read name: #{r[:n]}, placed at edge #{n.index}") :
          {:dataset=>o[:unique]})
        ds_counts[ m[:dataset] ] += r[:m] / metadata[ m[:dataset] ].norm
      end
    end
    counts_sum = ds_counts.values.reduce(:+)
    unless counts_sum.nil?
      # In the area option, the radius is "twice" to make the smallest > 1 (since counts_sum is >= 1)
      radius = (o[:area] ? 2*Math.sqrt(counts_sum/Math::PI) : counts_sum)*max_norm
      f.puts n.cannonical_name +
        "#{"\t0.5" unless o[:olditol]}\t#{"R" if o[:olditol]}" +
        radius.to_i.to_s + "\t" +
        metadata.names.map{ |n| ds_counts[n] }.join("\t")
      if counts_sum > max_norm_sum
        max_norm_n = n.cannonical_name
        max_norm_sum = counts_sum
      end
      if counts_sum < min_norm_sum
        min_norm_n = n.cannonical_name
        min_norm_sum = counts_sum
      end
    end
  end
  f.close
  units = {none: "", counts: " per million placements",
    size: " per million reads", norm: " per normalizing unit"}
  $stderr.puts " The pie #{o[:area] ? "areas" : "radii"} are proportional to the placements#{units[o[:norm]]}." unless o[:q]
  $stderr.puts " The minimum radius (#{min_norm_n}) represents #{min_norm_sum*(([:none, :norm].include? o[:norm]) ? 1 : 1e6)} placements#{units[o[:norm]]}." unless o[:q]
  $stderr.puts " The maximum radius (#{max_norm_n}) represents #{max_norm_sum*(([:none, :norm].include? o[:norm]) ? 1 : 1e6)} placements#{units[o[:norm]]}." unless o[:q]


  $stderr.puts "Re-formatting tree for iToL." unless o[:q]
  f = File.open(o[:out] + ".nwk", "w")
  f.puts tree.to_s + ";"
  f.close

rescue => err
  $stderr.puts "Exception: #{err}\n\n"
  err.backtrace.each { |l| $stderr.puts l + "\n" }
  err
end

