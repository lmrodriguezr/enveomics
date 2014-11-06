#!/usr/bin/ruby -w

#
# @author Luis M. Rodriguez-R <lmrodriguezr at gmail dot com>
# @author Luis (Coto) Orellana
# @license artistic license 2.0
# @update Oct-28-2014
#

require 'optparse'
require 'tmpdir'
has_build_gems = TRUE
warn <<WARN

┌──[ IMPORTANT ]──────────────────────────────────────────────┐
│ ROCker is in alpha version: undertested, and very unstable. │
│ Please don't use in production.                             │
└─────────────────────────────────────────────────────────────┘

WARN

#================================[ Options parsing ]
$o = {
   :q=>false, :r=>'R',
   :positive=>[], :negative=>[], :sbj=>[],:color=>false,
   :win=>20, :gformat=>'pdf', :width=>9, :height=>9, :minscore=>0,
   :grinder=>'grinder', :muscle=>'muscle', :blastbins=>'', :seqdepth=>3, :minovl=>0.75,
   :grindercmd=>'%1$s -reference_file "%2$s" -cf "%3$f" -base_name "%4$s"',
   :musclecmd=>'%1$s -in "%2$s" -out "%3$s" -quiet',
   :blastcmd=>'%1$sblastx -query "%2$s" -db "%3$s" -out "%4$s" -outfmt 6 -max_target_seqs 1',
   :makedbcmd=>'%1$smakeblastdb -in "%2$s" -out "%3$s" -dbtype prot'
}
$t = {
   'build'   => 'Creates in silico metagenomes and training sets from reference genomes.',
   'compile' => 'Identifies the most discriminant bit-score per sequence position in a set of sequence.',
   'filter'  => 'Uses a pre-compiled set of bit-score thresholds to filter a BLAST result.',
   'plot'    => 'Generates a graphical representation of the alignment, the thresholds, and the hits.',
}
task = (ARGV.size > 0 ? ARGV.shift : '').downcase
ARGV << '-h' if ARGV.size==0
if task == 'build'
   begin
      require 'rubygems'
      require 'restclient'
      require 'nokogiri'
   rescue LoadError
      has_build_gems = FALSE
   end
end
$eutils = 'http://eutils.ncbi.nlm.nih.gov/entrez/eutils'
opts = OptionParser.new do |opt|
   if $t.keys.include? task
      opt.banner = "Usage: ROCker.rb #{task} [options]"
      opt.separator ""
      opt.separator $t[task]
      opt.separator ""
   end
   case task
   when 'build'
      unless has_build_gems
	 opt.separator "UNSATISFIED REQUIREMENTS"
	 opt.separator "    The building task requires uninstalled gems, please install them executing:"
	 opt.separator "       gem install rest_client"
	 opt.separator "       gem install nokogiri"
	 opt.separator ""
      end
      opt.separator "BUILDING ARGUMENTS"
      opt.on("-p", "--positive GI1,GI2,GI3", Array, "Comma-separated list of NCBI GIs corresponding to the 'positive' training set. Required."){ |v| $o[:positive]=v }
      opt.on("-n", "--negative GI1,GI2,GI3", Array, "Comma-separated list of NCBI GIs corresponding to the 'negative' training set."){ |v| $o[:negative]=v }
      opt.on("-P", "--positive-file PATH", "File containing the positive set (see -p), one GI per line."){ |v| $o[:posfile]=v }
      opt.on("-N", "--negative-file PATH", "File containing the negative set (see -n), one GI per line."){ |v| $o[:negfile]=v }
      opt.on("-o", "--baseout PATH", "Prefix for the output files to be generated. Required."){ |v| $o[:baseout]=v }
      opt.on("-s", "--seqdepth NUMBER", "Sequencing depth to be used in building the in silico metagenome. By default: '#{$o[:seqdepth]}'."){ |v| $o[:seqdepth]=v.to_f }
      opt.on("-v", "--overlap NUMBER", "Minimum overlap with reference gene to tag a read as positive. By default: '#{$o[:minovl]}'."){ |v| $o[:minovl]=v.to_f }
      opt.on("-G", "--grinder PATH", "Path to the grinder executable. By default: '#{$o[:grinder]}' (in the $PATH)."){ |v| $o[:grinder]=v }
      opt.on("-M", "--muscle PATH", "Path to the muscle executable. By default: '#{$o[:muscle]}' (in the $PATH)."){ |v| $o[:muscle]=v }
      opt.on("-B", "--blastbins PATH", "Path to the Blast+ executables. By default: '#{$o[:blastbins]}' (in the $PATH)."){ |v| $o[:blastbins]=v }
      opt.on(      "--nometagenome", "Do not create metagenome. Implies --no-blast. By default, metagenome is created."){ |v| $o[:nomg]=v }
      opt.on(      "--noblast", "Do not execute BLAST. By default, BLAST is executed."){ |v| $o[:noblast]=v }
      opt.on(      "--noalignment", "Do not align reference set. By default, references are aligned."){ |v| $o[:noaln]=v }
      opt.on(      "--nocleanup", "Keep all intermediate files. By default, intermediate files are removed."){ |v| $o[:noclean]=v }
      opt.on(      "--reuse-files", "Re-use existing result files. By default, existing files are ignored."){ |v| $o[:reuse]=true }
      opt.on(      "--grinder-cmd STR", "Command calling grinder, where %1$s: grinder bin, %2$s: input, %3$s: seq. depth, %4$s: output.",
	 "By default: '#{$o[:grindercmd]}'."){ |v| $o[:grindercmd]=v }
      opt.on("--muscle-cmd STR", "Command calling muscle, where %1$s: muscle bin, %2$s: input, %3$s: output.",
	 "By default: '#{$o[:musclecmd]}'."){ |v| $o[:musclecmd]=v }
      opt.on("--blast-cmd STR", "Command calling BLAST search, where %1$s: blast bins, %2$s: input, %3$s: database, %4$s: output.",
	 "By default: '#{$o[:blastcmd]}'."){ |v| $o[:blastcmd]=v }
      opt.on("--makedb-cmd STR", "Command calling BLAST format, where %1$s: blast bins, %2$s: input, %3$s: database.",
	 "By default: '#{$o[:makedbcmd]}'."){ |v| $o[:makedbcmd]=v }
   when 'compile'
      opt.separator "COMPILATION ARGUMENTS"
      opt.on("-a", "--alignment FILE", "Protein alignment of the reference sequences. Required."){ |v| $o[:aln]=v }
      opt.on("-b", "--ref-blast FILE",
      		"Tabular BLAST (blastx) of the test reads vs. the reference dataset. Required unless -t exists."){ |v| $o[:blast]=v }
      opt.on("-t", "--table FILE", "Formated tabular file to be created (or reused). Required unless -b is provided."){ |v| $o[:table]=v }
      opt.on("-k", "--rocker FILE", "ROCker file to be created. Required."){ |v| $o[:rocker]=v }
      opt.on(      "--min-score NUMBER", "Minimum Bit-Score to consider a hit. By default: #{$o[:minscore]}"){ |v| $o[:minscore]=v.to_f }
      opt.on("-w", "--window INT", "Size of alignment windows (in number of AA columns). By default: #{$o[:win]}."){ |v| $o[:win]=v.to_i }
      opt.separator ""
      opt.separator "INPUT/OUTPUT"
      opt.separator "   o The input alignment (-a) MUST be in FastA format, and the IDs must"
      opt.separator "     coincide with those from the BLAST (-b)."
      opt.separator "   o The input BLAST (-b) MUST be in tabular format. True positives must"
      opt.separator "     contain the string '@%' somewhere in the query ID."
      opt.separator "   o The table file (-t) should be tab-delimited and contain six columns:"
      opt.separator "      1. Subject ID."
      opt.separator "      2. Start of alignment in subject (translated to alignment column)."
      opt.separator "      3. End of alignment in subject (translated to alignment column)."
      opt.separator "      4. Bit score."
      opt.separator "      5. A number indicating if it was a true (1) or a false (0) positive."
      opt.separator "      6. Mid-point of the alignment in the reference sequence."
      opt.separator "   o The ROCker file (-k) is a tab-delimited file containing five columns:"
      opt.separator "      1. First column of the window in the alignment."
      opt.separator "      2. Last column of the window in the alignment."
      opt.separator "      3. Number of positives in the window (hits)."
      opt.separator "      4. Number of true positives in the window."
      opt.separator "      5. Bit score threshold set for the window."
      opt.separator "     The file also contains the alignment (commented with #:)."
      opt.separator ""
   when 'filter'
      opt.separator "FILTERING ARGUMENTS"
      opt.on("-k", "--rocker FILE", "ROCker file generated by the compile task (-k). Required."){ |v| $o[:rocker]=v }
      opt.on("-x", "--query-blast FILE", "Tabular BLAST (blastx) of the query reads vs. the reference dataset. Required."){ |v| $o[:qblast]=v }
      opt.on("-o", "--out-blast FILE", "Filtered tabular BLAST to be created. Required."){ |v| $o[:oblast]=v }
   when 'plot'
      opt.separator "PLOTTING ARGUMENTS"
      opt.on("-k", "--rocker FILE", "ROCker file generated by the compile task (-k). Required."){ |v| $o[:rocker]=v }
      opt.on("-b", "--ref-blast FILE",
      		"Tabular BLAST (blastx) of the test reads vs. the reference dataset. Required unless -t exists."){ |v| $o[:blast]=v }
      opt.on("-t", "--table FILE", "Formated tabular file to be created (or reused). Required unless -b is provided."){ |v| $o[:table]=v }
      opt.on("-o", "--plot-file FILE", "File to be created with the plot. By default: value of -k + '.' + value of -f."){ |v| $o[:gout]=v }
      opt.on(      "--color", "Color alignment by amino acid."){ $o[:color]=true }
      opt.on(      "--min-score NUMBER", "Minimum Bit-Score to consider a hit. By default: #{$o[:minscore]}"){ |v| $o[:minscore]=v.to_f }
      opt.on("-s", "--subject SBJ1,SBJ2,...", Array,
      	"Plot only information regarding this(ese) subject(s). If multiple, separate by comma. By default, all hits are plotted."){ |v| $o[:sbj]=v }
      opt.on("-f", "--plot-format STRING",
      	"Format of the plot file. Supported values: pdf (default), png, jpeg, and tiff."){ |v| $o[:gformat]=v }
      opt.on("-W", "--width NUMBER", "Width of the plot in inches. By default: #{$o[:width]}."){ |v| $o[:width]=v.to_f }
      opt.on("-H", "--height NUMBER", "Height of the plot in inches. By defaule: #{$o[:height]}."){ |v| $o[:width]=v.to_f }
   else
      opt.banner = "Usage: ROCker.rb [task] [options]"
      opt.separator ""
      opt.separator "Please specify one of the following tasks:"
      $t.keys.each{ |t| opt.separator "     #{t}:\t#{$t[t]}" }
   end
   opt.separator ""
   opt.separator "GENERAL ARGUMENTS"
   opt.on("-R", "--path-to-r EXE", "Path to the R executable to be used. By default: '#{$o[:r]}'."){ |v| $o[:r]=v }
   opt.on("-q", "--quiet", "Run quietly."){ |v| $o[:q]=true }
   opt.on("-h", "--help","Display this screen") do
      puts opt
      exit
   end
   opt.separator ""
   unless $t.include? task
      puts opt
      exit
   end
end
opts.parse!

#================================[ Classes ]
class Sequence
   attr_reader :id, :seq, :aln
   def initialize(id, aln)
      @id = id
      @aln = aln.gsub(/[-\.]/,'-').gsub(/[^A-Za-z-]/, '').upcase
      @seq = aln.gsub(/[^A-Za-z]/, '').upcase
   end
   def pos2col(pos)
      col = 0
      self.aln.split(//).each do |c|
	 col+=1
	 pos-=1 unless c=='-'
	 return col if pos==0
      end
      col
   end
   def col2pos(col)
      pos = 1
      self.aln.split(//).each do |c|
         col-=1
	 pos+=1 unless c=='-'
	 return pos if col==0
      end
      pos
   end
   def cols
      self.aln.length
   end
   def length
      self.seq.length
   end
   def to_s
      "#:>#{self.id}\n#:#{self.aln}\n"
   end
end

class Alignment
   attr_reader :seqs, :cols
   def initialize
      @seqs = {}
   end
   def read_fasta(file)
      self.read_file(file, false)
   end
   def read_rocker(file)
      self.read_file(file, true)
   end
   def read_file(file, is_rocker)
      f = File.open(file, 'r')
      id = nil
      sq = ""
      while ln = f.gets
	 if is_rocker
	    next if /^#:(.*)/.match(ln).nil?
	    ln = $1
	 end
	 m = /^>(\S+)/.match(ln)
	 if m.nil?
	    sq += ln
	 else
	    self << Sequence.new(id, sq) unless id.nil?
	    id = m[1]
	    sq = ""
	 end
      end
      self << Sequence.new(id, sq) unless id.nil?
   end
   def <<(seq)
      @seqs[seq.id] = seq
      @cols = seq.cols if self.cols.nil?
      raise "Aligned sequence #{seq.id} has a different length (#{seq.cols} vs #{self.cols})" unless seq.cols == self.cols
   end
   def seq(id)
      @seqs[id]
   end
   def size
      self.seqs.size
   end
   def to_s
      self.seqs.values.map{|s| s.to_s}.join + "\n"
   end
end

class BlastHit
   attr_reader :sbj, :sfrom, :sto, :bits, :istrue, :midpoint
   # Initialize from BLAST using new(ln,aln), initialize from TABLE using new(ln)
   def initialize(ln, aln=nil)
      l = ln.chomp.split(/\t/)
      if aln.nil?
	 @sbj	= l[0]
	 @sfrom	= l[1].to_i
	 @sto	= l[2].to_i
	 @bits	= l[3].to_f
	 @istrue = l[4]=='1'
	 @midpoint = l[5].to_i
      else
	 s = aln.seq(l[1])
	 return nil if s.nil?
	 @sbj	= s.id
	 a	= s.pos2col(l[8].to_i)
	 b 	= s.pos2col(l[9].to_i)
	 @sfrom	= [a,b].min
	 @sto	= [a,b].max
	 @bits	= l[11].to_f
	 @istrue = ! /@%/.match(l[0]).nil?
	 @midpoint = s.pos2col(((l[8].to_f+l[9].to_f)/2).ceil)
      end
   end
   def to_s
      self.sbj.nil? ? "" : [self.sbj, self.sfrom.to_s, self.sto.to_s, self.bits.to_s, self.istrue ? '1' : '0', self.midpoint].join("\t") + "\n"
   end
end

class ROCWindow
   attr_reader :data, :from, :to, :hits, :tps, :thr
   def initialize(data, from=nil, to=nil)
      @data = data
      if from.is_a? String
	 r = from.split(/\t/)
	 @from	= r[0].to_i
	 @to	= r[1].to_i
	 @hits	= r[2].to_i
	 @tps	= r[3].to_i
	 @thr	= r[4].to_f
      else
	 a = from.nil? ? 1 : [from,1].max
	 b = to.nil? ? data.aln.cols : [to,data.aln.cols].min
	 @from = [a,b].min
	 @to = [a,b].max
	 @thr = nil
	 self.compute!
      end
   end
   def compute!
      self.load_hits
      @hits = self.rrun "nrow(y);", :int
      @tps = self.rrun "sum(y$V5);", :int
      unless self.almost_empty
	 self.rrun "rocobj <- roc(y$V5, y$V4);"
	 thr = self.rrun 'coords(rocobj, "best", ret="threshold", best.method="youden", best.weights=c(0.5, sum(y$V5)/nrow(y)))[1];', :float
	 @thr = thr.to_f
	 @thr = nil if @thr==0.0 or @thr.infinite?
      end
   end
   def load_hits
      self.rrun "y <- x[x$V6>=#{self.from} & x$V6<=#{self.to},];"
   end
   def previous
      return nil if self.from == 1
      self.data.win_at_col(self.from - 1)
   end
   def next
      return nil if self.to == self.data.aln.cols
      self.data.win_at_col(self.to + 1)
   end
   def around_thr
      a = self.previous
      b = self.next
      while not a.nil? and a.thr.nil?
	 a = a.previous
      end
      while not b.nil? and b.thr.nil?
	 b = b.next
      end
      return nil if a.nil? and b.nil?
      return a.thr if b.nil?
      return b.thr if a.nil?
      return (b.thr*(self.from-a.from) - a.thr*(self.from-b.from))/(b.from-a.from)
   end
   def thr_notnil
      (@thr.nil? or @thr.infinite?) ? self.around_thr : @thr
   end
   def fps
      self.hits - self.tps
   end
   def almost_empty
      self.fps < 3 or self.tps < 3
   end
   def length
      self.to - self.from + 1
   end
   def rrun(cmd, type=nil)
      self.data.rrun cmd, type
   end
   def to_s
      [self.from, self.to, self.hits, self.tps, self.thr_notnil].join("\t") + "\n"
   end
end

class ROCData
   attr_reader :aln, :windows, :r
   # Use ROCData.new(table,aln,window) to re-compute from table, use ROCData.new(data) to load
   def initialize(val, aln=nil, window=nil)
      @r = RInterface.new
      if not aln.nil?
	 @aln = aln
	 self.rrun "library('pROC');"
	 self.rrun "x <- read.table('#{val}', sep='\\t', h=F);"
	 self.init_windows! window
      else
	 f = File.open(val, "r")
	 @windows = []
	 while ln = f.gets
	    break unless /^#:/.match(ln).nil?
	    @windows << ROCWindow.new(self, ln)
	 end
	 f.close
	 @aln = Alignment.new
	 @aln.read_rocker(val)
      end
   end
   def win_at_col(col)
      self.windows.select{|w| (w.from<=col) and (w.to>=col)}.first
   end
   def refine! table
      while true
	 return false unless self.load_table! table
	 break if self._refine_iter(table)==0
      end
      return true
   end
   def _refine_iter table
      to_refine = []
      self.windows.each do |w|
	 next if w.almost_empty or w.length <= 5
	 self.rrun "acc <- w$accuracy[w$V1==#{w.from}];"
	 to_refine << w if self.rrun("ifelse(is.na(acc), 100, acc)", :float) < 95.0
      end
      n = to_refine.size
      return 0 unless n > 0
      to_refine.each do |w|
	 w1 = ROCWindow.new(self, w.from, (w.from+w.to)/2)
	 w2 = ROCWindow.new(self, (w.from+w.to)/2, w.to)
	 if w1.almost_empty or w2.almost_empty
	    n -= 1
	 else
	    @windows << w1
	    @windows << w2
	    @windows.delete w
	 end
      end
      @windows.sort!{ |x,y| x.from <=> y.from }
      n
   end
   def load_table! table, sbj=[], min_score=0
      self.rrun "x <- read.table('#{table}', sep='\\t', h=F);"
      self.rrun "x <- x[x$V1 %in% c('#{sbj.join("','")}'),];" if sbj.size > 0
      self.rrun "x <- x[x$V4 >= #{minscore.to_s},];" if min_score > 0
      Dir.mktmpdir do |dir|
         self.save(dir + "/rocker")
	 self.rrun "w <- read.table('#{dir}/rocker', sep='\\t', h=F);"
      end
      self.rrun "w <- w[!is.na(w$V5),];"
      if self.rrun("nrow(w)", :int)==0
         warn "\nWARNING: Insufficient windows with estimated thresholds.\n\n"
         return false
      end
      self.rrun <<-EOC
	 w$tp<-0; w$fp<-0; w$tn<-0; w$fn<-0;
	 for(i in 1:nrow(x)){
	    m <- x$V6[i];
	    win <- which( (m>=w$V1) & (m<=w$V2))[1];
	    if(!is.na(win)){
	       if(x$V4[i] >= w$V5[win]){
		  if(x$V5[i]==1){ w$tp[win] <- w$tp[win]+1 }else{ w$fp[win] <- w$fp[win]+1 };
	       }else{
		  if(x$V5[i]==1){ w$fn[win] <- w$fn[win]+1 }else{ w$tn[win] <- w$tn[win]+1 };
	       }
	    }
	 }
      EOC
      r.run <<-EOC
	 w$p <- w$tp + w$fp;
	 w$n <- w$tn + w$fn;
	 w$sensitivity <- 100*w$tp/(w$tp+w$fn);
	 w$specificity <- 100*w$tn/(w$fp+w$tn);
	 w$accuracy <- 100*(w$tp+w$tn)/(w$p+w$n);
	 w$precision <- 100*w$tp/(w$tp+w$fp);
      EOC
      
      return true
   end
   def init_windows!(size)
      @windows = []
      1.step(self.aln.cols,size).each { |a| @windows << ROCWindow.new(self, a, a+size-1) }
   end
   def rrun(cmd, type=nil)
      self.r.run cmd, type
   end
   def save(file)
      f = File.open(file, "w")
      f.print self.to_s
      f.close
   end
   def to_s
      o = ''
      self.windows.each{|w| o += w.to_s}
      o += self.aln.to_s
      return o
   end
end

class RInterface
   attr_reader :handler
   def initialize
      @handler = IO.popen("#{$o[:r]} --slave 2>&1", "w+")
   end
   def run(cmd, type=nil)
      @handler.puts cmd
      @handler.puts "cat('---FIN---\n')"
      o = ""
      while true
         l = @handler.gets
	 raise "R failed on command:\n#{cmd}\n\nError:\n#{o}" if l.nil?
	 break unless /^---FIN---/.match(l).nil?
	 o += l
      end
      o.chomp!
      case type
      when :float
	 /^\s*\[1\]\s+([0-9\.Ee+-]+|Inf).*/.match(o).nil? and raise "R error: expecting float, got #{o}"
	 return Float::INFINITY if $1=='Inf'
	 return $1.to_f
      when :int
	 /^\s*\[1\]\s+([0-9\.Ee+-]+).*/.match(o).nil? and raise "R error: expecting integer, got #{o}"
	 return $1.to_i
      else
	 return o
      end
   end
end

#================================[ Extensions ]
class Numeric
   def ordinalize
      n= self.to_s
      s= n[-2]=='1' ? 'th' :
	 n[-1]=='1' ? 'st' :
	 n[-1]=='2' ? 'nd' :
	 n[-1]=='3' ? 'rd' : 'th'
      n + s
   end
end
#================================[ Functions ]
def blast2table(blast_f, table_f, aln, minscore)
   ifh = File.open(blast_f, "r")
   ofh = File.open(table_f, "w")
   while ln = ifh.gets
      bh = BlastHit.new(ln, aln)
      ofh.print bh.to_s if bh.bits >= minscore
   end
   ifh.close
   ofh.close
end
def eutils(script, params={}, outfile=nil)
   response = RestClient.get "#{$eutils}/#{script}", {:params=>params}
   raise "Unable to reach NCBI EUtils, error code #{response.code}." unless response.code == 200
   unless outfile.nil?
      ohf = File.open(outfile, 'w')
      ohf.print response.to_s
      ohf.close
   end
   response.to_s
end
def efetch(*etc)
   eutils 'efetch.fcgi', *etc
end
def elink(*etc)
   eutils 'elink.fcgi', *etc
end
def bash(cmd, err_msg=nil)
   o = `#{cmd} 2>&1 && echo '{'`
   raise (err_msg.nil? ? "Error executing: #{cmd}\n\n#{o}" : err_msg) unless o[-2]=='{'
   true
end
#================================[ Main ]
begin
   bash "echo '' | #{$o[:r]} --vanilla", "-r/--path-to-r must be executable. Is R installed?" unless task=='build'
   case task
   when 'build'
      # Check requirements
      puts "Testing environment." unless $o[:q]
      $o[:noblast]=true if $o[:nomg]
      raise "Unsatisfied requirements." unless has_build_gems
      $o[:positive] += File.readlines($o[:posfile]).map{ |l| l.chomp } unless $o[:posfile].nil?
      $o[:negative] += File.readlines($o[:negfile]).map{ |l| l.chomp } unless $o[:negfile].nil?
      raise "-p or -P are mandatory." if $o[:positive].size==0
      raise "-o/--baseout is mandatory." if $o[:baseout].nil?
      if $o[:positive].size == 1 and not $o[:noaln]
	 warn "\nWARNING: Positive set contains only one protein, turning off alignment.\n\n"
	 $o[:noaln] = true
      end
      bash "#{$o[:grinder]} --version", "-G/--grinder must be executable. Is Grinder installed?" unless $o[:nomg]
      bash "#{$o[:muscle]} -version", "-M/--muscle must be executable. Is Muscle installed?" unless $o[:noaln]
      bash "#{$o[:blastbins]}makeblastdb -version", "-B/--blastbins must contain executables. Is BLAST+ installed?" unless $o[:noblast]
      # Download genes and genomes
      puts "Downloading data." unless $o[:q]
      puts "  * downloading #{$o[:positive].size} sequence(s) in positive set." unless $o[:q]
      efetch({:db=>'protein', :id=>$o[:positive].join(','), :rettype=>'fasta', :retmode=>'text'}, $o[:baseout] + '.ref.fasta')
      genome_gis = {:positive=>[], :negative=>[]}
      [:positive, :negative].each do |set|
         unless $o[set].size==0
	    puts "  * gathering genomes from #{$o[set].size} #{set.to_s} protein(s)." unless $o[:q]
	    doc = Nokogiri::XML( elink({:dbfrom=>'protein', :db=>'nuccore', :id=>$o[set]}) )
	    genome_gis[set] = doc.xpath('/eLinkResult/LinkSet/LinkSetDb/Link/Id').map{ |id| id.content }.uniq
	 end
      end
      all_gis = genome_gis.values.reduce(:+).uniq
      genomes_file = $o[:baseout] + '.src.fasta'
      if $o[:reuse] and File.exists? genomes_file
	 puts "  * reusing existing file: #{genomes_file}." unless $o[:q]
      else
	 puts "  * downloading #{all_gis.size} genome(s) in FastA." unless $o[:q]
	 efetch({:db=>'nuccore', :id=>all_gis.join(','), :rettype=>'fasta', :retmode=>'text'}, genomes_file)
      end
      # Locate proteins
      puts "Locating proteins in genomes." unless $o[:q]
      puts "  * downloading and parsing #{genome_gis[:positive].size} XML file(s)." unless $o[:q]
      positive_coords = {}
      i = 0
      genome_gis[:positive].each do |gi|
	 print "  * scanning #{(i+=1).ordinalize} genome out of #{genome_gis[:positive].size}. \r" unless $o[:q]
	 genome_file = $o[:baseout] + '.src.' + i.to_s + '.xml'
	 if $o[:reuse] and File.exists? genome_file
	    puts "  * reusing existing file: #{genome_file}." unless $o[:q]
	    ifh = File.open(genome_file, 'r')
	    doc = Nokogiri::XML( ifh )
	    ifh.close
	 else
	    genome_file=nil unless $o[:noclean]
	    res = efetch({:db=>'nuccore', :id=>gi, :rettype=>'xml', :retmode=>'text'}, genome_file)
	    doc = Nokogiri::XML( res )
	 end
	 doc.xpath('/Bioseq-set/Bioseq-set_seq-set/Seq-entry').each do |genome|
	    genome_gi = genome.at_xpath('./Seq-entry_set/Bioseq-set/Bioseq-set_seq-set/Seq-entry/Seq-entry_seq/Bioseq/Bioseq_id/Seq-id/Seq-id_gi').content
	    warn "\nWARNING: GI mismatch, expecting '#{gi}', got '#{genome_gi}'.\n\n" unless gi==genome_gi
	    positive_coords[genome_gi] ||= []
	    genome.xpath('./Seq-entry_set/Bioseq-set/Bioseq-set_annot/Seq-annot/Seq-annot_data/Seq-annot_data_ftable/Seq-feat').each do |pr|
	       pr_gi = pr.at_xpath('./Seq-feat_product/Seq-loc/Seq-loc_whole/Seq-id/Seq-id_gi')
	       next if pr_gi.nil?
	       if $o[:positive].include? pr_gi.content
		  pr_loc = pr.at_xpath('./Seq-feat_location/Seq-loc/Seq-loc_int/Seq-interval')
		  positive_coords[genome_gi] << {
		     :gi     => pr_gi.content,
		     :from   => pr_loc.at_xpath('./Seq-interval_from').content.to_i,
		     :to     => pr_loc.at_xpath('./Seq-interval_to').content.to_i
		     #, :strand => pr_loc.at_xpath('./Seq-interval_strand/Na-strand/@value').content
		  }
	       end
	    end
	 end
	 doc = nil
      end
      print "\n" unless $o[:q]
      missing = $o[:positive] - positive_coords.values.map{ |a| a.map{ |b| b[:gi] } }.reduce(:+)
      warn "\nWARNING: Cannot find genomic location of protein(s) #{missing.join(',')}.\n\n" unless missing.size==0
      # Generate metagenome
      unless $o[:nomg]
	 puts "Generating in silico metagenome" unless $o[:q]
	 if $o[:reuse] and File.exists? $o[:baseout] + ".mg.fasta"
	    puts "  * reusing existing file: #{$o[:baseout]}.mg.fasta." unless $o[:q]
	 else
	    puts "  * running grinder." unless $o[:q]
	    bash sprintf($o[:grindercmd], $o[:grinder], "#{$o[:baseout]}.src.fasta", $o[:seqdepth], "#{$o[:baseout]}.mg.tmp")
	    # Tag positives
	    puts "  * tagging positive reads." unless $o[:q]
	    ifh = File.open($o[:baseout] + ".mg.tmp-reads.fa", 'r')
	    ofh = File.open($o[:baseout] + ".mg.fasta", 'w')
	    while ln=ifh.gets
	       rd = /^>(?<id>\d+) reference=gi\|(?<gi>\d+)\|.* position=(?<comp>complement\()?(?<from>\d+)\.\.(?<to>\d+)\)? /.match(ln)
	       unless rd.nil?
		  positive = false
		  positive_coords[rd[:gi]] ||= []
		  positive_coords[rd[:gi]].each do |gn|
		     left  = rd[:to].to_i - gn[:from]
		     right = gn[:to] - rd[:from].to_i
		     if (left*right >= 0) and ([left, right].min/(rd[:to].to_i-rd[:from].to_i) >= $o[:minovl])
			positive = true
			break
		     end
		  end
		  ln = ">#{rd[:id]}#{positive ? "@%" : ""} ref=#{rd[:gi]}:#{rd[:from]}..#{rd[:to]}#{(rd[:comp]=='complement(')?'-':'+'}\n"
	       end
	       ofh.print ln
	    end
	    ofh.close
	    ifh.close
         end
      end # unless $o[:nomg]
      # Align references
      unless $o[:noaln]
	 puts "Aligning reference set." unless $o[:q]
	 if $o[:reuse] and File.exists? "#{$o[:baseout]}.ref.aln"
	    puts "  * reusing existing file: #{$o[:baseout]}.ref.aln." unless $o[:q]
	 else
	    bash sprintf($o[:musclecmd], $o[:muscle], "#{$o[:baseout]}.ref.fasta", "#{$o[:baseout]}.ref.aln")
	    puts "  +--\n  | IMPORTANT NOTE: Manually checking the alignment before\n  | the 'compile' step is *strongly* encouraged.\n  +--\n" unless $o[:q]
	 end
      end
      # Run BLAST 
      unless $o[:noblast]
	 puts "Running homology search." unless $o[:q]
	 if $o[:reuse] and File.exists? "#{$o[:baseout]}.ref.blast"
	    puts "  * reusing existing file: #{$o[:baseout]}.ref.blast." unless $o[:q]
	 else
	    puts "  * preparing database." unless $o[:q]
	    bash sprintf($o[:makedbcmd], $o[:blastbins], "#{$o[:baseout]}.ref.fasta", "#{$o[:baseout]}.ref")
	    puts "  * running BLAST." unless $o[:q]
	    bash sprintf($o[:blastcmd], $o[:blastbins], "#{$o[:baseout]}.mg.fasta", "#{$o[:baseout]}.ref", "#{$o[:baseout]}.ref.blast")
	 end
      end
      # Clean
      unless $o[:noclean]
	 puts "Cleaning." unless $o[:q]
	 sff  = %w{.src.xml .src.fasta}
	 sff += %w{.mg.tmp-reads.fa .mg.tmp-ranks.txt} unless $o[:nomg]
	 sff += %w{.ref.phr .ref.pin .ref.psq} unless $o[:noblast]
	 sff.each { |sf| File.unlink $o[:baseout] + sf if File.exists? $o[:baseout] + sf }
      end
   when 'compile'
      raise "-a/--alignment is mandatory." if $o[:aln].nil?
      raise "-a/--alignment must exist." unless File.exists? $o[:aln]
      if $o[:table].nil?
	 raise "-t/--table is mandatory unless -b is provided." if $o[:blast].nil?
	 $o[:table] = "#{$o[:blast]}.table"
      end
      raise "-b/--blast is mandatory unless -t exists." if $o[:blast].nil? and not File.exists? $o[:table]
      raise "-k/--rocker is mandatory." if $o[:rocker].nil?
      bash "echo \"library('pROC')\" | #{$o[:r]} --vanilla", "Please install the 'pROC' library for R first."

      puts "Reading files." unless $o[:q]
      puts "  * loading alignment: #{$o[:aln]}." unless $o[:q]
      aln = Alignment.new
      aln.read_fasta $o[:aln]
      
      if File.exists? $o[:table]
	 puts "  * reusing existing file: #{$o[:table]}." unless $o[:q]
      else
	 puts "  * generating table: #{$o[:table]}." unless $o[:q]
	 blast2table($o[:blast], $o[:table], aln, $o[:minscore])
      end

      puts "Analyzing data." unless $o[:q]
      puts "  * computing windows." unless $o[:q]
      data = ROCData.new($o[:table], aln, $o[:win])
      puts "  * refining windows." unless $o[:q]
      warn "Insufficient hits to refine results." unless data.refine! $o[:table]
      puts "  * saving ROCker file: #{$o[:rocker]}." unless $o[:q]
      data.save $o[:rocker]
   when 'filter'
      raise "-k/--rocker is mandatory." if $o[:rocker].nil?
      raise "-x/--query-blast is mandatory." if $o[:qblast].nil?
      raise "-o/--out-blast is mandatory." if $o[:oblast].nil?
      
      puts "Reading ROCker file." unless $o[:q]
      data = ROCData.new $o[:rocker]

      puts "Filtering BLAST." unless $o[:q]
      ih = File.open($o[:qblast], 'r')
      oh = File.open($o[:oblast], 'w')
      while ln = ih.gets
	 bh = BlastHit.new(ln, data.aln)
	 oh.print ln if not(bh.sfrom.nil?) and bh.bits >= data.win_at_col(bh.midpoint).thr
      end
      ih.close
      oh.close
   when 'plot'
      raise "-k/--rocker is mandatory." if $o[:rocker].nil?
      if $o[:table].nil?
	 raise "-t/--table is mandatory unless -b is provided." if $o[:blast].nil?
	 $o[:table] = "#{$o[:blast]}.table"
      end
      raise "-b/--blast is mandatory unless -t exists." if $o[:blast].nil? and not File.exists? $o[:table]

      puts "Reading files." unless $o[:q]
      puts "  * loding ROCker file: #{$o[:rocker]}." unless $o[:q]
      data = ROCData.new $o[:rocker]
      if File.exists? $o[:table]
	 puts "  * reusing existing file: #{$o[:table]}." unless $o[:q]
      else
	 puts "  * generating table: #{$o[:table]}." unless $o[:q]
	 blast2table($o[:blast], $o[:table], data.aln, $o[:minscore])
      end

      puts "Plotting hits." unless $o[:q]
      extra = $o[:gformat]=='pdf' ? "" : ", units='in', res=300"
      $o[:gout] ||= "#{$o[:rocker]}.#{$o[:gformat]}"
      # Open file
      data.rrun "#{$o[:gformat]}('#{$o[:gout]}', #{$o[:width]}, #{$o[:height]}#{extra});"
      data.rrun "layout(c(2,1,3), heights=c(2-1/#{data.aln.size},3,1));"
      # Read table
      some_thr = data.load_table! $o[:table], $o[:sbj], $o[:minscore]
      # Plot
      data.rrun "par(mar=c(0,4,0,0.5)+.1);"
      data.rrun "plot(1, t='n', xlim=c(0.5,#{data.aln.cols}+0.5), ylim=range(x$V4)+c(-0.04,0.04)*diff(range(x$V4)), xlab='', ylab='Bit score', xaxs='i', xaxt='n');"
      data.rrun "noise <- runif(ncol(x),-.2,.2)"
      data.rrun "arrows(x0=x$V2, x1=x$V3, y0=x$V4+noise, col=ifelse(x$V5==1, rgb(0,0,.5,.2), rgb(.5,0,0,.2)), length=0);"
      data.rrun "points(x$V6, x$V4+noise, col=ifelse(x$V5==1, rgb(0,0,.5,.5), rgb(.5,0,0,.5)), pch=19, cex=1/4);"

      puts "Plotting windows." unless $o[:q]
      if some_thr
	 data.rrun "arrows(x0=w$V1, x1=w$V2, y0=w$V5, lwd=2, length=0)"
	 data.rrun "arrows(x0=w$V2[-nrow(w)], x1=w$V1[-1], y0=w$V5[-nrow(w)], y1=w$V5[-1], lwd=2, length=0)"
      end
      data.rrun "legend('bottomright',legend=c('Hit span','Hit mid-point','Reference','Non-reference')," +
	 "lwd=c(1,NA,1,1),pch=c(NA,19,19,19),col=c('black','black','darkblue','darkred'),ncol=4,bty='n')"

      puts "Plotting alignment." unless $o[:q]
      data.rrun "par(mar=c(0,4,0.5,0.5)+0.1);"
      data.rrun "plot(1, t='n', xlim=c(0,#{data.aln.cols}),ylim=c(1,#{data.aln.seqs.size}),xlab='',ylab='Alignment',xaxs='i',xaxt='n',yaxs='i',yaxt='n',bty='n');"
      i = 0
      data.rrun "clr <- rainbow(26, v=1/2, s=3/4);" if $o[:color]
      data.aln.seqs.values.each do |s|
         color = s.aln.split(//).map{|c| c=="-" ? "'grey80'" : ($o[:sbj].include?(s.id) ? "'red'" : ($o[:color] ? "clr[#{c.ord-64}]" : "'black'"))}.join(',')
	 data.rrun "rect((1:#{data.aln.cols-1})-0.5, rep(#{i}, #{data.aln.cols-1}), (1:#{data.aln.cols-1})+0.5, rep(#{i+1}, #{data.aln.cols-1}), col=c(#{color}), border=NA);"
	 i += 1
      end

      puts "Plotting statistics." unless $o[:q]
      data.rrun "par(mar=c(5,4,0,0.5)+.1);"
      unless $o[:q] or not some_thr
	 puts "  * sensitivity: #{data.rrun "100*sum(w$tp)/(sum(w$tp)+sum(w$fn))", :float}%"
	 puts "  * specificity: #{data.rrun "100*sum(w$tn)/(sum(w$fp)+sum(w$tn))", :float}%"
	 puts "  * accuracy: #{data.rrun "100*(sum(w$tp)+sum(w$tn))/(sum(w$p)+sum(w$n))", :float}%"
      end
      data.rrun "plot(1, t='n', xlim=c(0,#{data.aln.cols}),ylim=c(50,100),xlab='Alignment position (amino acids)',ylab='Precision',xaxs='i');"
      if some_thr
	 data.rrun "pos <- (w$V1+w$V2)/2"
	 data.rrun "lines(pos[!is.na(w$specificity)], w$specificity[!is.na(w$specificity)], col='darkred', lwd=2, t='o', cex=1/3, pch=19);"
	 data.rrun "lines(pos[!is.na(w$sensitivity)], w$sensitivity[!is.na(w$sensitivity)], col='darkgreen', lwd=2, t='o', cex=1/3, pch=19);"
	 data.rrun "lines(pos[!is.na(w$accuracy)], w$accuracy[!is.na(w$accuracy)], col='darkblue', lwd=2, t='o', cex=1/3, pch=19);"
	 #data.rrun "lines(pos[!is.na(w$precision)], w$precision[!is.na(w$precision)], col='purple', lwd=2, t='o', cex=1/3, pch=19);"
      end
      data.rrun "legend('bottomright',legend=c('Specificity','Sensitivity','Accuracy'),lwd=2,col=c('darkred','darkgreen','darkblue'),ncol=3,bty='n')"
      data.rrun "dev.off();"
   end
rescue => err
   $stderr.puts "Exception: #{err}\n\n"
   err.backtrace.each { |l| $stderr.puts l + "\n" }
   err
end

