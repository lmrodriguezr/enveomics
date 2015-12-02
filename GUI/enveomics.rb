#!/usr/bin/env jruby -J-XstartOnFirstThread
#
# @package enve-omics
# @author  Luis M. Rodriguez-R <lmrodriguezr at gmail dot com>
# @license artistic license 2.0
# @update  Dec-02-2015
#

$:.push File.expand_path("lib", File.dirname(__FILE__))
$IS_CLI = !(ARGV[0] == "-cli")
require "enve-gui"

### MAIN
begin
   $stderr.puts "Wearing shoes."
   EnveGUI.init
rescue => err
   $stderr.puts "Exception: #{err}\n\n"
   err.backtrace.each { |l| $stderr.puts l + "\n" }
   err
end
