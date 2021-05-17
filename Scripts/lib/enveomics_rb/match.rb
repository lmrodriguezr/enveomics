
module Enveomics
  ##
  # A simple object representing a sequence match from a search engine
  # supporting tabular BLAST output
  class Match
    class << self
      def column_types
        {
          qseqid: String,    sseqid: String,    pident: Float,
          length: Integer,   mismatch: Integer, gapopen: Integer,
          q_start: Integer,  q_end: Integer,    s_start: Integer,
          s_end: Integer,    evalue: Float,     bitscore: Float,
          # Non-standard (but frequently used in Enveomics Collection):
          qry_len: Integer,  sbj_len: Integer
        }
      end

      def column_type(sym)
        column_types[colname(sym)]
      end

      def to_column_type(sym, value)
        case column_type(sym).to_s
        when 'String' ; value.to_s
        when 'Float'  ; value.to_f
        when 'Integer'; value.to_i
        end
      end

      def columns
        column_types.keys
      end

      def column(sym)
        columns.index(colname(sym))
      end

      def colsynonyms
        {
          qry: :qseqid, sbj: :sseqid,
          id: :pident, len: :length, score: :bitscore
        }
      end

      def colnames
        columns + colsynonyms.keys
      end

      def colname(sym)
        s = sym.to_sym
        column_types[s] ? s : colsynonyms[s]
      end
    end

    ####--- Instance Level ---###

    attr :row

    ##
    # Initialize Enveomics::Match object from a tabular blast line String +ln+
    def initialize(ln)
      @row = ln.chomp.split("\t")
    end

    colnames.each do |sym|
      define_method sym do
        self.class.to_column_type(sym, row[self.class.column(sym)])
      end
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
