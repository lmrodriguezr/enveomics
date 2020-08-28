
require 'enveomics_rb/errors'
require 'zlib'

def use(gems, mandatory = true)
  gems = [gems] unless gems.is_a? Array
  begin
    require 'rubygems'
    while !gems.empty?
      require gems.shift
    end
    return true
  rescue LoadError
    abort "\nUnmet requirements, please install required gems:" +
      gems.map{ |gem| "\n   gem install #{gem}" }.join + "\n\n" if mandatory
    return false
  end
end

def say(*msg)
  return if $QUIET ||= false

  o = '[%s] %s' % [Time.now, msg.join('')]
  $stderr.puts(o)
end

##
# Returns an open reading file handler for the file,
# supporting .gz and '-' for STDIN
def reader(file)
  file == '-' ? $stdin :
    file =~ /\.gz$/ ? Zlib::GzipReader.open(file) :
    File.open(file, 'r')
end

##
# Returns an open writing file handler for the file,
# supporting .gz and '-' for STDOUT
def writer(file)
  file == '-' ? $stdout :
    file =~ /\.gz$/ ? Zlib::GzipWriter.open(file) :
    File.open(file, 'w')
end

##
# Run a command +cmd+ that can be a ready-to-go string or an Array to escape
# 
# Supported symbol key options in Hash +opts+:
# - wait: Boolean, should I wait for the command to complete? Default: true
# - stdout: Path to redirect the standard output
# - stderr: Path to redirect the standard error
# - mergeout: Send stderr to stdout
#
# Return the process ID. If wait is true (default), check for the exit
# status and throw an Enveomics::CommandError if non-zero
def run_cmd(cmd, opts = {})
  opts[:wait] = true if opts[:wait].nil?
  cmd = cmd.shelljoin if cmd.is_a? Array
  cmd += "  > #{opts[:stdout].shellescape}" if opts[:stdout]
  cmd += " 2> #{opts[:stderr].shellescape}" if opts[:stderr]
  cmd += ' 2>&1' if opts[:mergeout]
  pid = spawn(cmd)
  return pid unless opts[:wait]

  Process.wait(pid)
  unless $?.success?
    raise Enveomics::CommandError.new(
      "Command failed with status #{$?.exitstatus}:\n#{cmd}"
    )
  end
  pid
end

