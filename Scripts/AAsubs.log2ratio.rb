#!/usr/bin/env ruby
#
# @author  Luis M. Rodriguez-R
# @update  Dec-21-2015
# @license artistic license 2.0
#

$:.push File.expand_path(File.dirname(__FILE__) + "/lib")
require "enveomics_rb/enveomics"

o = {permutations: 1000, bootstraps: 1000, overwrite: false}
OptionParser.new do |opt|
   opt.banner = "
   Estimates the log2-ratio of different amino acids in homologous sites using
   an AAsubs file (see BlastPairwise.AAsubs.pl). It provides the point
   estimation (.obs file), the bootstrap of the estimation (.boot file) and the
   null model based on label-permutation (.null file).

   Usage: #{$0} [options]".gsub(/^ +/,"")
   opt.separator ""
   opt.separator "Mandatory"
   opt.on("-i", "--input FILE",
      "Input file in AAsubs format (see BlastPairwise.AAsubs.pl)."
      ){ |v| o[:file] = v}
   opt.separator ""
   opt.separator "Output files"
   opt.on("-O", "--obs-file FILE",
      "Output file with the log2-ratios per amino acid.",
      "By default, '--input value'.obs."
      ){ |v| o[:obs] = v }
   opt.on("-B", "--bootstrap-file FILE",
      "Output file with the bootstrap results of log2-ratios per amino acid.",
      "By default, '--input value'.boot."
      ){ |v| o[:boot] = v }
   opt.on("-N", "--null-file FILE",
      "Output file with the permutation results of log2-ratios per amino acid.",
      "By default, '--input value'.null."
      ){ |v| o[:null] = v }
   opt.on("--overwrite",
      "Overwrite existing files. By default, skip steps if the files already" +
      " exist."){ |v| o[:overwrite] = v }
   opt.separator ""
   opt.separator "Parameters"
   opt.on("-b", "--bootstraps INT",
      "Number of bootstraps to run. By default: #{o[:bootstraps]}."
      ){ |v| o[:bootstraps] = v.to_i }
   opt.on("-p", "--permutations INT",
      "Number of permutations to run. By default: #{o[:permutations]}."
      ){ |v| o[:permutations] = v.to_i }
   opt.on("-q", "--quiet", "Run quietly (no STDERR output)."){ o[:q] = TRUE }
   opt.on("-h", "--help", "Display this screen.") do
      puts opt
      exit
   end
   opt.separator ""
end.parse!

# Initialize
abort "--input is mandatory" if o[:file].nil?
ALPHABET = %w(A C D E F G H I K L M N P Q R S T V W Y X)
o[:obs] ||= "#{o[:file]}.obs"
o[:boot] ||= "#{o[:file]}.boot"
o[:null] ||= "#{o[:file]}.null"

# Functions
def dist_summary(a,b)
   ALPHABET.map do |i|
      Math.log(a[i].reduce(0,:+).to_f/b[i].reduce(0,:+), 10)
   end
end
def empty_sample
   Hash[ALPHABET.map{|k| [k, []]}]
end

# Initialize
$stderr.puts "Initializing." unless o[:q]
sample_A = empty_sample
sample_B = empty_sample
last_label = nil
prot_index = -1

# Read file
$stderr.puts "Reading input file." unless o[:q]
ifh = File.open(o[:file], "r")
ifh.each do |l|
   r = l.chomp.split /\t/
   if r.first != last_label
      prot_index +=1
      last_label = r.first
      ALPHABET.each do |a|
         sample_A[a][prot_index] = 0
         sample_B[a][prot_index] = 0
      end
   end
   [1,2].each do |ds|
      unless %w(- *).include? r[ds]
	 abort "Unknown amino acid in line #{$.}: '#{r[ds]}'." unless
	    ALPHABET.include? r[ds]
	 sample_A[ r[ds] ][ prot_index ] += 1 if ds==1
	 sample_B[ r[ds] ][ prot_index ] += 1 if ds==2
      end
   end
end
ifh.close
$stderr.puts "  > Found #{prot_index+1} proteins." unless o[:q]
$stderr.puts "  > Saving #{o[:obs]}" unless o[:q]
sum = dist_summary(sample_A, sample_B)
File.open(o[:obs], "w") do |fh|
   fh.puts ["AA", "log10_AB"].join("\t")
   ALPHABET.each do |i|
      fh.puts [i, sum.shift].join("\t")
   end
end

# Permutations
if File.size? o[:null] and not o[:overwrite]
   $stderr.puts "Skipping permutations." unless o[:q]
else
   $stderr.puts "Permutating." unless o[:q]
   permut_sum = []
   o[:permutations].times do |i|
      permut_A = empty_sample
      permut_B = empty_sample
      (0 .. prot_index).each do |j|
	 # Copy counts of the protein
	 ALPHABET.each do |k|
	    permut_A[k][j] = sample_A[k][j]
	    permut_B[k][j] = sample_B[k][j]
	 end
	 # Swap labels at random
	 permut_A,permut_B = permut_B,permut_A if rand(2)==1
      end
      permut_sum << dist_summary(permut_A, permut_B)
   end
   $stderr.puts "  > Performed #{o[:permutations]} permutations." unless o[:q]
   $stderr.puts "  > Saving #{o[:null]}" unless o[:q]
   File.open(o[:null], "w") do |fh|
      fh.puts ALPHABET.join("\t")
      permut_sum.each{ |s| fh.puts s.join("\t") }
   end
end

# Bootstraps
if File.size? o[:boot] and not o[:overwrite]
   $stderr.puts "Skipping bootstraps." unless o[:q]
else
   $stderr.puts "Bootstrapping." unless o[:q]
   boot_sum = []
   o[:bootstraps].times do |i|
      boot_A = empty_sample
      boot_B = empty_sample
      (0 .. prot_index).each do |j|
	 # Sample randomly with replacement
	 jr = rand(prot_index+1)
	 # Copy counts of the protein
	 ALPHABET.each do |k|
	    boot_A[k][j] = sample_A[k][jr]
	    boot_B[k][j] = sample_B[k][jr]
	 end
      end
      boot_sum << dist_summary(boot_A, boot_B)
   end
   $stderr.puts "  > Performed #{o[:bootstraps]} bootstraps." unless o[:q]
   $stderr.puts "  > Saving #{o[:boot]}" unless o[:q]
   File.open(o[:boot], "w") do |fh|
      fh.puts ALPHABET.join("\t")
      boot_sum.each{ |s| fh.puts s.join("\t") }
   end
end

$stderr.puts "Done. Yayyy!" unless o[:q]
