#!/usr/bin/env ruby

#
# @author: Luis M. Rodriguez-R
# @update: Jul-19-2015
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

o = {win:1000, step:200, id:70, len:700, correct:true, hits:50, q:false, bin:"", program:"blast+", thr:1, dec:2, auto:false}
ARGV << '-h' if ARGV.size==0
OptionParser.new do |opts|
   opts.banner = "
Calculates the Average Nucleotide Identity between two genomes.

Usage: #{$0} [options]"
   opts.separator ""
   opts.separator "Mandatory"
   opts.on("-1", "--seq1 FILE", "Path to the FastA file containing the genome 1."){ |v| o[:seq1] = v }
   opts.on("-2", "--seq2 FILE", "Path to the FastA file containing the genome 2."){ |v| o[:seq2] = v }
   if has_rest_client
      opts.separator "    Alternatively, you can supply a GI with the format gi:12345 instead of files."
   else
      opts.separator "    Install rest-client to enable gi support."
   end
   opts.separator ""
   opts.separator "Search Options"
   opts.on("-w", "--win INT", "Window size in the ANI calculation (in bp).  By default: #{o[:win].to_s}."){ |v| o[:win] = v.to_i }
   opts.on("-s", "--step INT", "Step size in the ANI calculation (in bp).  By default: #{o[:step].to_s}."){ |v| o[:step] = v.to_i }
   opts.on("-l", "--len INT", "Minimum alignment length (in bp).  By default: #{o[:len].to_s}."){ |v| o[:len] = v.to_i }
   opts.on("-i", "--id NUM", "Minimum alignment identity (in %).  By default: #{o[:id].to_s}."){ |v| o[:id] = v.to_f }
   opts.on("-n", "--hits INT", "Minimum number of hits.  By default: #{o[:hits].to_s}."){ |v| o[:hits] = v.to_i }
   opts.on("-N", "--nocorrection", "Report values without post-hoc correction."){ |v| o[:correct] = false }
   opts.separator ""
   opts.separator "Software Options"
   opts.on("-b", "--bin DIR", "Path to the directory containing the binaries of the search program."){ |v| o[:bin] = v }
   opts.on("-p", "--program STR", "Search program to be used.  One of: blast+ (default), blast, blat."){ |v| o[:program] = v }
   opts.on("-t", "--threads INT", "Number of parallel threads to be used.  By default: #{o[:thr]}."){ |v| o[:thr] = v.to_i }
   opts.separator ""
   opts.separator "Other Options"
   opts.on("-S", "--sqlite3 FILE", "Path to the SQLite3 database to create (or update) with the results."){ |v| o[:sqlite3] = v }
   opts.separator "    Install sqlite3 gem to enable database support." unless has_sqlite3
   opts.on(      "--name1 STR", "Name of --seq1 to use in --sqlite3. By default it's determined by the filename."){ |v| o[:seq1name] = v }
   opts.on(      "--name2 STR", "Name of --seq2 to use in --sqlite3. By default it's determined by the filename."){ |v| o[:seq2name] = v }
   opts.on("-d", "--dec INT", "Decimal positions to report. By default: #{o[:dec]}"){ |v| o[:dec] = v.to_i }
   opts.on("-o", "--out FILE", "Saves a file describing the alignments used for two-way ANI."){ |v| o[:out] = v }
   opts.on("-r", "--res FILE", "Saves a file with the final results."){ |v| o[:res] = v }
   opts.on("-T", "--tab FILE", "Saves a file with the final two-way results in a tab-delimited form.",
      "The columns are (in that order): ANI, standard deviation, fragments used, fragments in the smallest genome."){ |v| o[:tab]=v }
   opts.on("-a", "--auto", "ONLY outputs the ANI value in STDOUT (or nothing, if calculation fails)."){ o[:auto] = true }
   opts.on("-q", "--quiet", "Run quietly (no STDERR output)"){ o[:q] = true }
   opts.on("-h", "--help", "Display this screen") do
      puts opts
      exit
   end
   opts.separator ""
end.parse!
abort "-1 is mandatory" if o[:seq1].nil?
abort "-2 is mandatory" if o[:seq2].nil?
abort "SQLite3 requested (-S) but sqlite3 not supported.  First install gem sqlite3." unless o[:sqlite3].nil? or has_sqlite3
abort "Step size must be smaller than window size." if o[:step] > o[:win]
o[:bin] = o[:bin]+"/" if o[:bin].size > 0

Dir.mktmpdir do |dir|
   $stderr.puts "Temporal directory: #{dir}." unless o[:q]

   # Create databases.
   $stderr.puts "Creating databases." unless o[:q]
   minfrg = nil
   seq_names = []
   [:seq1, :seq2].each do |seq|
      gi = /^gi:(\d+)/.match(o[seq])
      if not gi.nil?
	 abort "GI requested but rest-client not supported.  First install gem rest-client." unless has_rest_client
	 response = RestClient.get 'http://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi', {:params=>{:db=>'nuccore', :rettype=>'fasta', :id=>gi[1]}}
	 abort "Unable to reach NCBI EUtils, error code #{response.code}." unless response.code == 200
	 o[seq] = "#{dir}/gi-#{seq.to_s}.fa"
	 fo = File.open(o[seq], "w")
	 fo.puts response.to_str
	 fo.close
	 seq_names << "gi:#{gi[1]}"
      else
         if o[ "#{seq}name".to_sym ].nil?
	    seq_names << File.basename(o[seq], ".fna")
	 else
	    seq_names << o[ "#{seq}name".to_sym ]
	 end
      end
      $stderr.puts "  Reading FastA file: #{o[seq]}" unless o[:q]
      buffer = ""
      frgs = 0
      seqs = 0
      disc = 0
      fi = File.open(o[seq], "r")
      fo = File.open("#{dir}/#{seq.to_s}.fa", "w")
      fi.each_line do |ln|
	 if /^>(\S+)/.match(ln).nil?
	    ln.gsub!(/[^A-Za-z]/, '')
	    buffer = buffer + ln
	    while buffer.size > o[:win]
	       seq_i = buffer[0, o[:win]]
	       if seq_i =~ /^N+$/
	          disc += seq_i.size
	       else
		  frgs += 1
		  fo.puts ">#{frgs}"
		  fo.puts seq_i
	       end
	       buffer = buffer[o[:step] .. -1]
	    end
	 else
	    seqs += 1
	    disc += buffer.size
	    buffer = ""
	 end
      end
      fi.close
      fo.close
      $stderr.puts "    Created #{frgs} fragments from #{seqs} sequences, discarded #{disc} bp." unless o[:q]
      minfrg ||= frgs
      minfrg = frgs if minfrg > frgs
      case o[:program].downcase
      when "blast"
         `"#{o[:bin]}formatdb" -i "#{dir}/#{seq.to_s}.fa" -p F`
      when "blast+"
         `"#{o[:bin]}makeblastdb" -in "#{dir}/#{seq.to_s}.fa" -dbtype nucl`
      when "blat"
	 # Nothing to do
      else
         abort "Unsupported program: #{o[:program]}."
      end
   end

   # Create SQLite3 file
   unless o[:sqlite3].nil?
      sqlite_db = SQLite3::Database.new o[:sqlite3]
      sqlite_db.execute "create table if not exists rbm( seq1 varchar(256), seq2 varchar(256), id1 varchar(256), id2 varchar(256), id float, evalue float, bitscore float )"
      sqlite_db.execute "create table if not exists ani( seq1 varchar(256), seq2 varchar(256), ani float, sd float, n int, omega int )"
      sqlite_db.execute "delete from rbm where seq1=? and seq2=?", seq_names
      sqlite_db.execute "delete from ani where seq1=? and seq2=?", seq_names
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
   [1,2].each do |i|
      qry_seen = []
      q = "#{dir}/seq#{i}.fa"
      s = "#{dir}/seq#{i==1?2:1}.fa"
      case o[:program].downcase
      when "blast"
	 `"#{o[:bin]}blastall" -p blastn -d "#{s}" -i "#{q}" \
	 -F F -v 1 -b 1 -a #{o[:thr]} -m 8 -o "#{dir}/#{i}.tab"`
	 #-F F -e 0.001 -v 1 -b 1 -X 150 -a #{o[:thr]} -m 8 -o "#{dir}/#{i}.tab"`
      when "blast+"
	 `"#{o[:bin]}blastn" -db "#{s}" -query "#{q}" \
	 -dust no -max_target_seqs 1 \
	 -num_threads #{o[:thr]} -outfmt 6 -out "#{dir}/#{i}.tab"`
	 #-dust no -max_target_seqs 1 -xdrop_ungap 150 -xdrop_gap 150 \
      when "blat"
	 `#{o[:bin]}blat "#{s}" "#{q}" -out=blast8 "#{dir}/#{i}.tab"`
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
	 if qry_seen[ row[0].to_i ].nil? and row[3].to_i >= o[:len] and row[2].to_f >= o[:id]
	    qry_seen[ row[0].to_i ] = 1
	    identity_corr = 100 - (100 - row[2].to_f)/(o[:correct] ? 0.8621: 1.0)
	    id += identity_corr
	    sq += identity_corr ** 2
	    n  += 1
	    if i==1
	       rbh[ row[0].to_i ] = row[1].to_i
	    else
	       if !rbh[ row[1].to_i ].nil? and rbh[ row[1].to_i ]==row[0].to_i
	          id2 += identity_corr
		  sq2 += identity_corr ** 2
		  n2  += 1
		  fo.puts [identity_corr,row[3..5],row[10..11]].join("\t") unless o[:out].nil?
		  sqlite_db.execute("insert into rbm values(?,?,?,?,?,?,?)", seq_names + [row[1], row[0], row[2], row[10], row[11]] ) unless o[:sqlite3].nil?
	       end
	    end
	 end
      end
      fh.close
      if n < o[:hits]
	 puts "Insuffient hits to estimate one-way ANI: #{n}." unless o[:auto]
	 res.puts "Insufficient hits to estimate one-way ANI: #{n}" unless o[:res].nil?
      else
	 printf "! One-way ANI %d: %.#{o[:dec]}f%% (SD: %.#{o[:dec]}f%%), from %i fragments.\n", i, id/n, (sq/n - (id/n)**2)**0.5, n unless o[:auto]
	 res.puts sprintf "<b>One-way ANI %d:</b> %.#{o[:dec]}f%% (SD: %.#{o[:dec]}f%%), from %i fragments.<br/>", i, id/n, (sq/n - (id/n)**2)**0.5, n unless o[:res].nil?
      end
   end
   if n2 < o[:hits]
      puts "Insufficient hits to estimate two-way ANI: #{n2}" unless o[:auto]
      res.puts "Insufficient hits to estimate two-way ANI: #{n2}" unless o[:res].nil?
   else
      printf "! Two-way ANI  : %.#{o[:dec]}f%% (SD: %.#{o[:dec]}f%%), from %i fragments.\n", id2/n2, (sq2/n2 - (id2/n2)**2)**0.5, n2 unless o[:auto]
      res.puts sprintf "<b>Two-way ANI:</b> %.#{o[:dec]}f%% (SD: %.#{o[:dec]}f%%), from %i fragments.<br/>", id2/n2, (sq2/n2 - (id2/n2)**2)**0.5, n2 unless o[:res].nil?
      unless o[:tab].nil?
         tab = File.open(o[:tab], 'w')
	 tab.printf "%.#{o[:dec]}f\t%.#{o[:dec]}f\t%i\t%i\n", id2/n2, (sq2/n2 - (id2/n2)**2)**0.5, n2, minfrg
	 tab.close
      end
      sqlite_db.execute("insert into ani values(?,?,?,?,?,?)", seq_names + [id2/n2, (sq2/n2 - (id2/n2)**2)**0.5, n2, minfrg]) unless o[:sqlite3].nil?
      puts id2/n2 if o[:auto]
   end
   res.close unless o[:res].nil?
   fo.close unless o[:out].nil?
end



