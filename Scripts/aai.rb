#!/usr/bin/env ruby

#
# @author: Luis M. Rodriguez-R
# @update: Jul-13-2015
# @license: artistic license 2.0
#

require 'optparse'
require 'tmpdir'
has_rest_client = true
has_sqlite3 = true
begin
   require 'rubygems'
   require 'restclient'
rescue LoadError
   has_rest_client = false
end
begin
   require 'sqlite3'
rescue LoadError
   has_sqlite3 = false
end

o = {:len=>0, :id=>20, :bits=>0, :hits=>50, :q=>FALSE, :bin=>'', :program=>'blast+', :thr=>1, :dec=>2, :auto=>false}
ARGV << '-h' if ARGV.size==0
OptionParser.new do |opts|
   opts.banner = "
Calculates the Average Amino acid Identity between two genomes.

Usage: #{$0} [options]"
   opts.separator ""
   opts.separator "Mandatory"
   opts.on("-1", "--seq1 FILE", "Path to the FastA file containing the genome 1 (proteins)."){ |v| o[:seq1] = v }
   opts.on("-2", "--seq2 FILE", "Path to the FastA file containing the genome 2 (proteins)."){ |v| o[:seq2] = v }
   if has_rest_client
      opts.separator "    Alternatively, you can supply the GI of a genome (nucleotides) with the format gi:12345 instead of files."
   else
      opts.separator "    Install rest-client to enable gi support."
   end
   opts.separator ""
   opts.separator "Search Options"
   opts.on("-l", "--len INT", "Minimum alignment length (in aa).  By default: #{o[:len].to_s}."){ |v| o[:len] = v.to_i }
   opts.on("-i", "--id NUM", "Minimum alignment identity (in %).  By default: #{o[:id].to_s}."){ |v| o[:id] = v.to_f }
   opts.on("-s", "--bitscore NUM", "Minimum bit score (in bits).  By default: #{o[:bits].to_s}."){ |v| o[:bits] = v.to_f }
   opts.on("-n", "--hits INT", "Minimum number of hits.  By default: #{o[:hits].to_s}."){ |v| o[:hits] = v.to_i }
   opts.separator ""
   opts.separator "Software Options"
   opts.on("-b", "--bin DIR", "Path to the directory containing the binaries of the search program."){ |v| o[:bin] = v }
   opts.on("-p", "--program STR", "Search program to be used.  One of: blast+ (default), blast, blat."){ |v| o[:program] = v }
   opts.on("-t", "--threads INT", "Number of parallel threads to be used.  By default: #{o[:thr]}."){ |v| o[:thr] = v.to_i }
   opts.separator ""
   opts.separator "Other Options"
   opts.on("-S", "--sqlite3 STR", "Path to the sqlite3 database to create (or update) with the results."){ |v| o[:sqlite3] = v }
   unless has_sqlite3
      opts.separator "    Install sqlite3 gem to enable database support."
   end
   opts.on("-d", "--dec INT", "Decimal positions to report. By default: #{o[:dec]}"){ |v| o[:dec] = v.to_i }
   opts.on("-R", "--rbm FILE", "Saves a file with the reciprocal best matches."){ |v| o[:rbm] = v }
   opts.on("-o", "--out FILE", "Saves a file describing the alignments used for two-way AAI."){ |v| o[:out] = v }
   opts.on("-r", "--res FILE", "Saves a file with the final results."){ |v| o[:res] = v }
   opts.on("-T", "--tab FILE", "Saves a file with the final two-way results in a tab-delimited form.",
      "The columns are (in that order): AAI, standard deviation, proteins used, proteins in the smallest genome."){ |v| o[:tab]=v }
   opts.on("-q", "--quiet", "Run quietly (no STDERR output)"){ o[:q] = true }
   opts.on("-a", "--auto", "ONLY outputs the AAI value in STDOUT (or nothing, if calculation fails)."){ o[:auto] = true }
   opts.on("-h", "--help", "Display this screen") do
      puts opts
      exit
   end
   opts.separator ""
end.parse!
abort "-1 is mandatory" if o[:seq1].nil?
abort "-2 is mandatory" if o[:seq2].nil?
abort "SQLite3 requested (-S) but sqlite3 not supported.  First install gem sqlite3." unless o[:sqlite3].nil? or has_sqlite3
o[:bin] = o[:bin]+"/" if o[:bin].size > 0

Dir.mktmpdir do |dir|
   $stderr.puts "Temporal directory: #{dir}." unless o[:q]

   # Create databases.
   $stderr.puts "Creating databases." unless o[:q]
   minfrg = nil
   ori_ids = {}
   [:seq1, :seq2].each do |seq|
      gi = /^gi:(\d+)/.match(o[seq])
      if not gi.nil?
	 abort "GI requested but rest-client not supported.  First install gem rest-client." unless has_rest_client
	 $stderr.puts "  Downloading dataset from GI:#{gi[1]}." unless o[:q]
	 responseLink = RestClient.get 'http://eutils.ncbi.nlm.nih.gov/entrez/eutils/elink.fcgi', {:params=>{:db=>'protein',:dbfrom=>'nuccore', :id=>gi[1]}}
	 abort "Unable to reach NCBI EUtils, error code #{responseLink.code}." unless responseLink.code == 200
	 fromId = TRUE
	 protIds = []
	 o[seq] = "#{dir}/gi-#{seq.to_s}.fa"
	 fo = File.open(o[seq], "w")
	 responseLink.to_str.each_line.grep(/<Id>/) do |ln|
	    idMatch = /<Id>(\d+)<\/Id>/.match(ln);
	    unless idMatch.nil?
	       protIds.push(idMatch[1]) unless fromId
	       fromId = FALSE
	    end
	 end
	 response = RestClient.post 'http://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi', :db=>'nuccore', :rettype=>'fasta', :id=>protIds.join(',')
	 abort "Unable to reach NCBI EUtils, error code #{response.code}." unless response.code == 200
	 fo.puts response.to_str
	 fo.close
      end
      $stderr.puts "  Reading FastA file: #{o[seq]}" unless o[:q]
      ori_ids[seq] = [nil]
      seqs = 0
      fi = File.open(o[seq], "r")
      fo = File.open("#{dir}/#{seq.to_s}.fa", "w")
      fi.each_line do |ln|
	 if ln =~ /^>(\S+)/
	    ori_ids[seq] << $1 unless o[:rbm].nil?
	    seqs += 1
	    fo.puts ">#{seqs}"
	 else
	    fo.puts ln
	 end
      end
      fi.close
      fo.close
      $stderr.puts "    File contains #{seqs} sequences." unless o[:q]
      minfrg ||= seqs
      minfrg = seqs if minfrg > seqs
      case o[:program].downcase
      when "blast"
         `"#{o[:bin]}formatdb" -i "#{dir}/#{seq.to_s}.fa" -p T`
      when "blast+"
         `"#{o[:bin]}makeblastdb" -in "#{dir}/#{seq.to_s}.fa" -dbtype prot`
      when "blat"
      	 # Nothing to do
      else
         abort "Unsupported program: #{o[:program]}."
      end
   end

   # Create SQLite3 file
   seq_names = [File.basename(o[:seq1], ".faa"), File.basename(o[:seq2], ".faa")]
   unless o[:sqlite3].nil?
      sqlite_db = SQLite3::Database.new o[:sqlite3]
      sqlite_db.execute "create table if not exists rbm( seq1 varchar(256), seq2 varchar(256), id1 varchar(256), id2 varchar(256), id float, evalue float, bitscore float )"
      sqlite_db.execute "create table if not exists aai( seq1 varchar(256), seq2 varchar(256), aai float, sd float, n int, omega int )"
      sqlite_db.execute "delete from rbm where seq1=? and seq2=?", seq_names
      sqlite_db.execute "delete from aai where seq1=? and seq2=?", seq_names
   end
   
   # Best-hits.
   $stderr.puts "Running one-way comparisons." unless o[:q]
   rbh = []
   id2 = 0
   sq2 = 0
   n2  = 0
   unless o[:out].nil?
      fo = File.open(o[:out], "w")
      fo.puts %w(identity aln.len mismatch gap.open evalue bitscore).join("\t")
   end
   res = File.open(o[:res], "w") unless o[:res].nil?
   rbm = File.open(o[:rbm], "w") unless o[:rbm].nil?
   [1,2].each do |i|
      qry_seen = []
      q = "#{dir}/seq#{i}.fa"
      s = "#{dir}/seq#{i==1?2:1}.fa"
      case o[:program].downcase
      when "blast"
	 `"#{o[:bin]}blastall" -p blastp -d "#{s}" -i "#{q}" \
	 -v 1 -b 1 -a #{o[:thr]} -m 8 -o "#{dir}/#{i}.tab"`
	 #-F F -e 0.001 -v 1 -b 1 -X 150 -a #{o[:thr]} -m 8 -o "#{dir}/#{i}.tab"`
      when "blast+"
	 `"#{o[:bin]}blastp" -db "#{s}" -query "#{q}" \
	 -max_target_seqs 1 \
	 -num_threads #{o[:thr]} -outfmt 6 -out "#{dir}/#{i}.tab"`
	 #-dust no -max_target_seqs 1 -xdrop_ungap 150 -xdrop_gap 150 \
      when "blat"
	 `#{o[:bin]}blat "#{s}" "#{q}" -prot -out=blast8 "#{dir}/#{i}.tab.unsorted"`
	 `sort -k 1 "#{dir}/#{i}.tab.unsorted" > "#{dir}/#{i}.tab"`
      else
	 abort "Unsupported program: #{o[:program]}."
      end
      fh = File.open("#{dir}/#{i}.tab", "r")
      id = 0
      sq = 0
      n  = 0
      fh.each_line do |ln|
	 ln.chomp!
	 row = ln.split(/\t/)
	 if qry_seen[ row[0].to_i ].nil? and row[3].to_i >= o[:len] and row[2].to_f >= o[:id] and row[11].to_f >= o[:bits]
	    qry_seen[ row[0].to_i ] = 1
	    id += row[2].to_f
	    sq += row[2].to_f ** 2
	    n  += 1
	    if i==1
	       rbh[ row[0].to_i ] = row[1].to_i
	    else
	       if !rbh[ row[1].to_i ].nil? and rbh[ row[1].to_i ]==row[0].to_i
		  id2 += row[2].to_f
		  sq2 += row[2].to_f**2
		  n2  += 1
		  fo.puts [row[2..5],row[10..11]].join("\t") unless o[:out].nil?
		  rbm.puts [ori_ids[:seq1][row[1].to_i], ori_ids[:seq2][row[0].to_i], row[2..5], row[8..9], row[6..7], row[10..11]].join("\t") unless o[:rbm].nil?
		  sqlite_db.execute("insert into rbm values(?,?,?,?,?,?,?)", seq_names + [ori_ids[:seq1][row[1].to_i], ori_ids[:seq2][row[0].to_i], row[2], row[10], row[11]] ) unless o[:sqlite3].nil?
	       end
	    end
	 end
      end
      fh.close
      if n < o[:hits]
	 puts "Insuffient hits to estimate one-way AAI: #{n}." unless o[:auto]
	 res.puts "Insufficient hits to estimate one-way AAI: #{n}" unless o[:res].nil?
      else
	 printf "! One-way AAI %d: %.#{o[:dec]}f%% (SD: %.#{o[:dec]}f%%), from %i proteins.\n", i, id/n, (sq/n - (id/n)**2)**0.5, n unless o[:auto]
	 res.puts sprintf "<b>One-way AAI %d:</b> %.#{o[:dec]}f%% (SD: %.#{o[:dec]}f%%), from %i proteins.<br/>", i, id/n, (sq/n - (id/n)**2)**0.5, n unless o[:res].nil?
      end
   end
   rbm.close unless o[:rbm].nil?
   if n2 < o[:hits]
      puts "Insufficient hits to estimate two-way AAI: #{n2}" unless o[:auto]
      res.puts "Insufficient hits to estimate two-way AAI: #{n2}" unless o[:res].nil?
   else
      printf "! Two-way AAI  : %.#{o[:dec]}f%% (SD: %.#{o[:dec]}f%%), from %i proteins.\n", id2/n2, (sq2/n2 - (id2/n2)**2)**0.5, n2 unless o[:auto]
      res.puts sprintf "<b>Two-way AAI:</b> %.#{o[:dec]}f%% (SD: %.#{o[:dec]}f%%), from %i proteins.<br/>", id2/n2, (sq2/n2 - (id2/n2)**2)**0.5, n2 unless o[:res].nil?
      unless o[:tab].nil?
         tab = File.open(o[:tab], 'w')
	 tab.printf "%.#{o[:dec]}f\t%.#{o[:dec]}f\t%i\t%i\n", id2/n2, (sq2/n2 - (id2/n2)**2)**0.5, n2, minfrg
	 tab.close
      end
      sqlite_db.execute("insert into aai values(?,?,?,?,?,?)", seq_names + [id2/n2, (sq2/n2 - (id2/n2)**2)**0.5, n2, minfrg]) unless o[:sqlite3].nil?
      puts id2/n2 if o[:auto]
   end
   res.close unless o[:res].nil?
   fo.close unless o[:out].nil?
end



