require 'enveomics_rb/bm_set'

module Enveomics
  class RBM
    attr :seq1, :seq2, :bms1, :bms2

    ##
    # Initialize RBM object with sequence paths +seq1+ and +seq2+, and
    # Enveomics::BMset options Hash +bm_opts+
    def initialize(seq1, seq2, bm_opts = {})
      @seq1 = seq1
      @seq2 = seq2
      @bms1 = Enveomics::BMset.new(seq1, seq2, bm_opts)
      @bms2 = Enveomics::BMset.new(seq2, seq1, bm_opts)
      @set = nil
    end

    ##
    # Array of Reciprocal Best Enveomics::Match objects
    def set
      @set ||= reciprocate!
    end

    ##
    # Number of reciprocal best matches found
    def count
      set.count
    end

    ##
    # Find reciprocal best matches and return the subset of +bms1+ that
    # is reciprocal with +bms2+
    def reciprocate!
      bms1.each.select do |bm|
        bms2[bm.sbj] && bm.qry == bms2[bm.sbj].sbj
      end
    end

    ##
    # Enumerate RBMs and yield +blk+
    def each(&blk)
      if block_given?
        set.each { |bm| blk.call(bm) }
      else
        to_enum(:each)
      end
    end
  end
end
