
module Enveomics
  class Error < RuntimeError
  end

  class CommandError < Error
  end

  class OptionError < Error
  end

  class UnimplementedError < Error
  end

  class ParseError < Error
  end
end
