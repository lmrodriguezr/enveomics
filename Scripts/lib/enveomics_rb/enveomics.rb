
require 'enveomics_rb/utils'
use 'optparse'
ARGV << '-h' if ARGV.empty?

module Enveomics
  class << self
    def opt_banner(opt, banner, usage = nil)
      opt.version ||= $VERSION
      usage ||= "#{opt.program_name}.rb [options]"
      opt.banner = <<~BANNER

        [Enveomics Collection: #{opt.program_name} #{opt.version}]

        #{banner}

        Usage
          #{usage}

      BANNER
    end
  end
end

