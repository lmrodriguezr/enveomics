
require 'enveomics_rb/enveomics'
require 'enveomics_rb/match'
use 'tmpdir'
use 'shellwords'

module Enveomics
  class BMset
    attr :qry, :sbj, :set, :opt

    ##
    # Initialize Enveomics::BMset object with sequence paths +qry+ and +sbj+,
    # and options Hash +opts+ (see #opt for supported options) with Symbol keys
    def initialize(qry, sbj, opts = {})
      @qry = qry
      @sbj = sbj
      @set = nil
      @opt = opts
    end

    ##
    # Returns option with key +k+ as defined by #initialize or by default
    # Supported options include [defaults in brackets]:
    # - len   [0]:   Minimum alignment length in residues
    # - id    [0.0]: Minimum alignment identity in percent
    # - fract [0.0]: Minimum alignment length as fraction of the query
    # - score [0.0]: Minimum alignment score in bits
    # - nucl  [false]: The sequences are in nucleotides
    # - thr   [1]:   Number of threads to use
    # - bin   ['']:  Path to the directory containing binaries
    # - program [:blast+]: Search engine to use
    def opt(k)
      @defaults ||= {
        len: 0, id: 0.0, fract: 0.0, score: 0.0,
        nucl: false, thr: 1, bin: '', program: :'blast+'
      }
      k = k.to_sym
      @opt[k] = @defaults[k] if @opt[k].nil?
      @opt[k]
    end

    ##
    # Array of Enveomics::Match objects
    def set
      match_and_filter! if @set.nil?
      @set
    end

    ##
    # Returns the best match of query +qry+ as Enveomics::Match or nil if
    # no qualifying match was found
    def [](qry)
      set[qry]
    end

    ##
    # Number of matches found
    def count
      set.count
    end

    ##
    # Execute search and filter matches 
    def match_and_filter!
      @set = {}
      match!.each do |match|
        # Already a better match?
        next if self[match.qry] && self[match.qry].score >= match.score

        # Is this a good enough match?
        next unless %i[len id score fract].all? do |metric|
          match.send(metric) >= opt(metric)
        end

        # Save match
        @set[match.qry] = match
      end
    end

    ##
    # Find all matches and return as an array of Enveomics::Match objects
    def match!
      y = []
      Dir.mktmpdir do |dir|
        # Determine commands
        say('Temporal directory: ', dir)
        db_path = File.join(dir, 'sbj.db')
        out_path = File.join(dir, 'out.tsv')
        cmds = []
        case opt(:program)
        when :blast
          cmds << [
            'formatdb', '-i', sbj, '-n', db_path, '-l', File.join(dir, 'log'),
            '-p', opt(:nucl) ? 'F' : 'T'
          ]
          cmd << [
            'blastall', '-p', opt(:nucl) ? 'blastn' : 'blastp', '-d', db_path,
            '-i', qry, '-v', '1', '-b', '1', '-a', opt(:thr).to_s, '-m', '8',
            '-o', out_path
          ]
        when :'blast+'
          cmds << [
            'makeblastdb', '-in', sbj, '-out', db_path,
            '-dbtype', opt(:nucl) ? 'nucl' : 'prot'
          ]
          cmds << [
            opt(:nucl) ? 'blastn' : 'blastp', '-db', db_path, '-query', qry,
            '-num_threads', opt(:thr).to_s, '-out', out_path, '-outfmt',
            '6 qseqid sseqid pident length mismatch gapopen qstart qend ' \
              'sstart send evalue bitscore qlen slen'
          ]
        when :diamond
          raise Enveomics::OptionError.new(
            'Unsupported search engine diamond for nucleotides'
          ) if opt(:nucl)
          cmds << [
            'diamond', 'makedb', '--in', sbj, '--db', db_path,
            '--threads', opt(:thr).to_s
          ]
          cmds << [
            'diamond', 'blastp', '--threads', opt(:thr).to_s,
            '--db', db_path, '--query', qry, '--daa', "#{out_path}.daa",
            '--quiet', '--sensitive'
          ]
          cmds << [
            'diamond', 'view', '--daa', "#{out_path}.daa", '--out', out_path,
            '--quiet', '--outfmt'
          ] + %w[6 qseqid sseqid pident length mismatch gapopen qstart] +
              %w[qend sstart send evalue bitscore qlen slen]
        when :blat
          cmds << ['blat', sbj, qry, '-out=blast8', out_path]
          cmds[0] << '-prot' unless opt(:nucl)
        else
          raise Enveomics::OptionError.new(
            "Unsupported search engine: #{opt(:program)}"
          )
        end

        # Run commands
        say('Running comparison')
        say('Query: ', qry)
        say('Subject: ', sbj)
        cmd_err = File.join(dir, 'err')
        begin
          cmds.each do |cmd|
            cmd[0] = File.join(opt(:bin), cmd[0]) unless opt(:bin) == ''
            run_cmd(cmd, stderr: cmd_err)
          end
        rescue Enveomics::CommandError => e
          $stderr.puts e
          $stderr.puts ''
          $stderr.puts '[ Error log ]'
          $stderr.puts File.read(cmd_err)
          exit
        end

        # Parse output
        File.open(out_path, 'r') do |fh|
          fh.each { |ln| y << Enveomics::Match.new(ln) }
        end
      end
      y
    end

    ##
    # Enumerate RBMs and yield +blk+
    def each(&blk)
      if block_given?
        set.each { |_, bm| blk.call(bm) }
      else
        to_enum(:each)
      end
    end
  end
end
