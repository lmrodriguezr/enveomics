
module Enveomics
  module Stats
    # Descriptive statistics for a given sample
    class Sample
      attr :x
      attr :opts

      # Initialize Enveomics::Stats::Sample with numeric vector +x+ and options
      # Hash +opts+ supporting the keys:
      # - +effective_range+: Range where values fall (by default: range of +x+)
      # - +histo_bin_size+: Width of histogram widths
      #   (by default: 1/50th of +effective_range+)
      def initialize(x, opts = {})
        raise 'Cannot initialize an empty sample' if x.empty?
        @x = x.map(&:to_f)
        @opts = opts
      end

      # Size of the sample
      def n
        x.size
      end

      # Estimates the sample mean
      def mean
        @mean ||= x.inject(:+) / n
      end

      # Estimates the mean of the square of the sample
      def square_mean
        @square_mean ||= x.map { |i| i**2 }.inject(:+) / n
      end

      # Estimates the unbiased sample variance
      def var
        @var ||= (square_mean - mean ** 2) * n / (n - 1)
      end

      # Estimates the unbiased sample standard deviation
      def sd
        @sd ||= var ** 0.5
      end

      # --- Higher moments ---

      # Estimate sample skewness
      def skewness
        return 0.0 if n == 1
        cubed_dev = x.inject(0.0) { |sum, i| sum + (i - mean) ** 3 }
        cubed_dev / ((n - 1) * (sd ** 3))
      end

      # Estimate sample excess kurtosis
      def kurtosis
        return 0.0 if n == 1
        quart_dev = x.inject(0.0) { |sum, i| sum + (i - mean)**4 }
        quart_dev / ((n - 1) * (sd**4))
      end

      # --- Ranges ---

      # Range effectively considered
      def effective_range
        @opts[:effective_range] ||= [nil, nil]
        @opts[:effective_range][0] ||= x.min
        @opts[:effective_range][1] ||= x.max
        @opts[:effective_range]
      end

      # Size of the effective range
      def effective_range_size
        effective_range[1] - effective_range[0]
      end

      # --- Histograms ---

      # Size of each histogram bin
      def histo_bin_size
        @opts[:histo_bin_size] ||= effective_range_size / 50.0
      end

      # Calculate histogram ranges without checking for cached value
      #
      # Use #histo_ranges instead
      def calculate_histo_ranges
        rng = [[effective_range[1], effective_range[1] - histo_bin_size]]
        while rng[rng.size - 1][1] > effective_range[0]
          rng << [rng[rng.size - 1][1], rng[rng.size - 1][1] - histo_bin_size]
        end
        rng
      end

      # Histogram ranges as an array of two-entry arrays where the fist entry
      # is the closed-ended maximum value (inclusive) of the range and the
      # second entry is the open-ended minimum value (non-inclusive) of the
      # range. The array is sorted from maximum to minimum
      #
      # Something like: +[[100.0, 99.0], [99.0, 98.0], ...]+, representing the
      # ranges: {[100, 99), [99, 98), ...}
      #
      # The bin width is determined by #hist_bin_size
      def histo_ranges
        @histo_ranges ||= calculate_histo_ranges
      end

      # Mid-points of the histogram ranges from #histo_ranges, returns
      # and array of Float
      def histo_mids
        @histo_mids ||= histo_ranges.map { |x| (x[0] + x[1]) / 2 }
      end

      # Calculate the histogram counts withouth checking cached value
      #
      # Use #histo_count instead
      def calculate_histo_counts
        counts = []
        xx = x.dup
        histo_ranges.each do |i|
          counts << xx.size - xx.delete_if { |j| j > i[1] }.size
        end
        counts
      end

      # Histogram counts in the ranges determined by #histo_ranges
      def histo_counts
        @histo_counts ||= calculate_histo_counts
      end

      # --- Bimodality coefficients ---

      # Sarle's sample bimodality coefficient b
      def sarle_bimodality
        (skewness**2 + 1) /
          (kurtosis + (3 * ((n - 1)**2)) / ((n - 2) * (n - 3)))
      end

      # de Michele & Accantino (2014) B index
      # DOI: 10.1371%2Fjournal.pone.0091195
      def dma_bimodality
        (mean - dma_mu_M).abs
      end

      # µ_M index proposed by Michele & Accantino (2014)
      # DOI: 10.1371%2Fjournal.pone.0091195
      def dma_mu_M
        histo_counts.each_with_index.map { |m, k| m * histo_mids[k] }.inject(:+) / n
      end
    end
  end
end

