
module Enveomics
  ##
  # A simple object representing a sequence match from a search engine
  # supporting tabular BLAST output
  class Match
    attr :row

    ##
    # Initialize Enveomics::Match object from a tabular blast line String +ln+
    def initialize(ln)
      @row = ln.chomp.split("\t")
    end

    def qry
      row[0]
    end

    def sbj
      row[1]
    end

    def id
      @id ||= row[2].to_f
    end

    def len
      @len ||= row[3].to_i
    end

    def evalue
      @evalue ||= row[9].to_f
    end

    def score
      @score ||= row[10].to_f
    end

    def qry_len
      @qry_len ||= row[12].to_i
    end

    def sbj_len
      @sbj_len ||= row[13].to_i
    end

    def qry_fract
      return 0.0 unless qry_len.zero?
      @fract ||= len.to_f / qry_len
    end

    alias fract qry_fract

    def sbj_fract
      return 0.0 unless sbj_len.zero?
      @fract ||= len.to_f / sbj_len
    end

    def to_s
      row.join("\t")
    end
  end
end
