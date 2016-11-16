
module Enve
  class Stat
    # Generates a random number from the +dist+ distribution with +params+
    # parameters. This is simply a wrapper to the r_* functions below.
    def self.rand(dist=:unif, *params)
      send("r_#{dist}", *params)
    end

    # Generates a random number from the uniform distribution between +min+ and
    # +max+. By default generates random numbers between 0.0 and 1.0.
    def self.r_unif(min=0.0, max=1.0)
      min + (max-min)*Random::rand
    end
    
    # Generates a random number from the geometric distribution with support
    # {0, 1, 2, ...} and probability of success +p+.
    def self.r_geom(p)
      (Math::log(1.0 - rand)/Math::log(1.0-p) - 1.0).ceil
    end

    # Generates a random number from the shifted geometric distribution with
    # support {1, 2, 3, ...} and probability of success +p+.
    def self.r_sgeom(p)
      (Math::log(1.0 - rand)/Math::log(1.0-p)).ceil
    end
    
  end
end

