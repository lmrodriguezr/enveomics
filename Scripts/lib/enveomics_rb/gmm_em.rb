
require 'enveomics_rb/stats/sample'

module Enveomics
  # Calculate Gaussian Mixture Models by Expectation Maximization
  class GmmEm
    attr :sample
    attr :components
    attr :opts

    # Initialize Enve::GmmEm object from numeric array +x+, +components+
    # gaussian components (an Integer), and options hash +opts+ with supported
    # Symbol keys:
    # - ll_delta_converge: Maximum change in LL to consider convergence
    #   (by default: 1e-15)
    # - max_iter: Maximum number of EM iterations (by default: 1_000)
    # - init_mu: Initial components means as numeric array
    # - init_sigma: Initial components standard deviation as numeric array
    # - init_alpha: Initial components fractions as numeric array adding up to 1
    def initialize(x, components = 2, opts = {})
      @sample = Enve::Stats::Sample.new(x)
      @opts = opts
      @opts[:ll_delta_convergence] ||= 1e-15
      @opts[:max_iter] ||= 1_000
    end

    
  end
end

