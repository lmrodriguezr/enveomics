#!/usr/bin/env ruby

# @author  Luis M. Rodriguez-R
# @license Artistic-2.0

$:.push File.expand_path(File.dirname(__FILE__) + "/lib")
require "enveomics_rb/enveomics"
require "enveomics_rb/vcf"

o = {min_dp:4, max_dp:Float::INFINITY, min_ref_dp:2, min_alt_dp:2, min_qual:0.0,
  indels:false, min_ic:0.0}
OptionParser.new do |opt|
  opt.banner = "
  Counts the number of Single-Nucleotide Polymorphisms (SNPs) in a VCF file.
  
  Usage: #{$0} [options]".gsub(/^ +/,"")
  opt.separator ""
  opt.separator "Mandatory"
  opt.on("-i", "--input FILE",
    "Input file in Variant Call Format (VCF)."){ |v| o[:file] = v}
  opt.separator ""
  opt.separator "Parameters"
  opt.on("-o", "--out FILE",
    "Output (filtered) file in Variant Call Format (VCF)."){ |v| o[:out] = v}
  opt.on("-m", "--min-dp INT",
    "Minimum number of reads covering the position. By default: #{o[:min_dp]}."
    ){ |v| o[:min_dp] = v.to_i }
  opt.on("-M", "--max-dp INT",
    "Maximum number of reads covering the position. By default: #{o[:max_dp]}."
    ){ |v| o[:max_dp] = (v=="Infinity" ? Float::INFINITY : v.to_i) }
  opt.on("-r", "--min-ref-dp INT",
    "Minimum number of reads supporting allele REF. " +
    "By default: #{o[:min_ref_dp]}."
    ){ |v| o[:min_ref_dp] = v.to_i }
  opt.on("-a", "--min-alt-dp INT",
    "Minimum number of reads supporting allele ALT. " +
    "By default: #{o[:min_alt_dp]}."
    ){ |v| o[:min_alt_dp] = v.to_i }
  opt.on("-q", "--min-quality FLOAT",
    "Minimum quality of the position mapping. By default: #{o[:min_qual]}."
    ){ |v| o[:max_dp] = v.to_f }
  opt.on("-s", "--min-shannon FLOAT",
    "Minimum information content (in bits, from 0 to 1). " +
    "By default: #{o[:min_ic]}"){ |v| o[:min_ic] = v.to_f }
  opt.on("--[no-]indels",
    "Process (or ignore) indels. By default: ignore."
    ){ |v| o[:indels] = v }
  opt.on("-h", "--help", "Display this screen.") do
    puts opt
    exit
  end
  opt.separator ""
end.parse!

abort "--input is mandatory" if o[:file].nil?

vcf = VCF.new(o[:file])
c = 0
dp = 0
ref_dp = 0
alt_dp = 0
h = 0
unless o[:out].nil?
  ofh = File.open(o[:out], "w")
  vcf.each_header{ |h| ofh.print h }
end
vcf.each_variant do |v|
  next if v.indel? and not o[:indels]
  next if v.dp < o[:min_dp]
  next if v.dp > o[:max_dp]
  next if v.ref_dp < o[:min_ref_dp]
  next if v.alt_dp < o[:min_alt_dp]
  next if v.qual < o[:min_qual]
  next if v.shannon < o[:min_ic]
  c += 1
  dp += v.dp
  ref_dp += v.ref_dp
  alt_dp += v.alt_dp
  h += v.shannon
  ofh.print v.to_s unless o[:out].nil?
end
ofh.close unless o[:out].nil?

puts "SNPs: #{c}", "Information content: #{h}",
  "Average SNP depth: #{dp.to_f/c}",
  "Average REF allele depth: #{ref_dp.to_f/c}",
  "Average ALT allele depth: #{alt_dp.to_f/c}"

