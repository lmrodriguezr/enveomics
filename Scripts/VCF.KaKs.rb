#!/usr/bin/env ruby

# @author  Luis M. Rodriguez-R
# @license Artistic-2.0

$:.push File.expand_path("../lib", __FILE__)
require "enveomics_rb/enveomics"
require "enveomics_rb/vcf"

o = {}
OptionParser.new do |opt|
  opt.banner = "
  Estimates the Ka/Ks ratio from the SNPs in a VCF file. Ka and Ks are corrected
  using pseudo-counts, but no corrections for multiple substitutions are
  applied.
  
  Usage: #{$0} [options]".gsub(/^ +/,"")
  opt.separator ""
  opt.separator "Mandatory"
  opt.on("-i", "--input FILE",
    "Input file in Variant Call Format (VCF)."){ |v| o[:file] = v}
  opt.on("-s", "--seqs FILE",
    "Input gene sequences (nucleotides) in FastA format."){ |v| o[:seqs] = v}
  opt.separator ""
  opt.separator "Parameters"
  opt.on("-f", "--syn-frx FLOAT",
    "Fraction of synonymous substitutions. If passed, the number of sites are",
    "estimated (not counted per gene), speeding up the computation ~10X."
    ){ |v| o[:syn_frx] = v.to_f }
  opt.on("-b", "--syn-bacterial-code",
    "Sets --syn-frx to 0.760417, approximately the proportion of synonymous",
    "substitutions in the bacterial code."){ o[:syn_frx] = 0.760417 }
  opt.separator ""
  opt.separator "Miscellaneous"
  opt.on("-c", "--codon-file FILE",
    "Output file including the codons of substitution variants."
    ){ |v| o[:codon_file] = v }
  opt.on("-h", "--help", "Display this screen.") do
    puts opt
    exit
  end
  opt.separator ""
end.parse!

abort "--input is mandatory" if o[:file].nil?
abort "--seqs is mandatory"  if o[:seqs].nil?

# Codon table (11. The Bacterial, Archaeal and Plant Plastid Code)
# https://www.ncbi.nlm.nih.gov/Taxonomy/Utils/wprintgc.cgi#SG11
t = {
    AAs: "FFLLSSSSYY**CC*WLLLLPPPPHHQQRRRRIIIMTTTTNNKKSSRRVVVVAAAADDEEGGGG",
 Starts: "---M------**--*----M------------MMMM---------------M------------",
  Base1: "TTTTTTTTTTTTTTTTCCCCCCCCCCCCCCCCAAAAAAAAAAAAAAAAGGGGGGGGGGGGGGGG",
  Base2: "TTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGG",
  Base3: "TCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAG"
}
$codon_aa = {}
$codon_st = {}
(0 .. (t[:Base1].size-1)).each do |i|
  cod = [:Base1, :Base2, :Base3].map{ |k| t[k][i] }.join
  $codon_aa[cod] = t[:AAs][i]
  $codon_st[cod] = t[:Starts][i]
end

##
# Is the change +cod+ to +cod_alt+ synonymous? +start_codon+ indicates if the
# codon the first in the gene.
def syn?(cod, cod_alt, start_codon=false)
  start_codon ?
    ( $codon_st[cod] == $codon_st[cod_alt] ) :
    ( $codon_aa[cod] == $codon_aa[cod_alt] )
end

##
# Estimates the fraction of times that the substitutions in the sequence +seq+
# result in synonymous mutations from those in position +pos+ by any of the
# nucleotides in +alts+.
def syn_fraction(seq, pos, alts)
  cod_let = (pos-1)%3
  cod_pos = (pos-1) - cod_let
  cod = seq[cod_pos .. (cod_pos+2)]
  syn = 0
  cod_alts = alts.map do |alt|
    cod_alt = "#{cod}"
    cod_alt[cod_let] = alt
    cod_alt
  end
  syn = cod_alts.map{ |i| syn?(cod, i, pos<=3) ? 1 : 0 }.inject(0,:+)
  $codon_fh.puts [syn, cod, cod_alts.join(",")].join("\t") unless $codon_fh.nil?
  syn.to_f/alts.size
end

# Read sequences
seqs = {}
File.open(o[:seqs], "r") do |fh|
  id = ""
  fh.each_line do |ln|
    if ln =~ /^>(\S+)/
      id = $1
      seqs[id] = ""
    else
      seqs[id] += ln.chomp.gsub(/[^A-Za-z]/, "")
    end
  end
end

# Process variants
$codon_fh = nil
unless o[:codon_file].nil?
  $codon_fh = File.open(o[:codon_file], "w")
  $codon_fh.puts "#" + %w[Syn Ref Alt].join("\t")
end
vcf = VCF.new(o[:file])
gen = {}
vcf.each_variant do |v|
  next if v.indel?
  raise "REF doesn't match VCF:\n#{v}" unless seqs[v.chrom][v.pos-1] == v.ref
  gen[v.chrom] ||= [0.0, 0.0]
  alts = v.alt.split(",")
  syn = syn_fraction(seqs[v.chrom], v.pos, alts)
  gen[v.chrom][0] += 1.0-syn
  gen[v.chrom][1] += syn
end
$codon_fh.close unless $codon_fh.nil?
$codon_fh = nil

# Ka/Ks
puts "#" +
  "SeqID KaKs Ka Ks NonSynSubs SynSubs NonSynSites SynSites".tr(" ","\t")
gen.each do |k,v|
  if o[:syn_frx].nil?
    v[2,3] = [0.0,0.0]
    (1 .. seqs[k].size).each do |pos|
      alts = %w(A C T G) - [seqs[k][pos-1]]
      syn = syn_fraction(seqs[k], pos, alts)
      v[2] += 1.0-syn
      v[3] += syn
    end
  else
    v[2] = seqs[k].size.to_f*o[:syn_frx]
    v[3] = seqs[k].size.to_f*(1.0-o[:syn_frx])
  end
  ka = (v[0] + 1) / (v[2] + 2)
  ks = (v[1] + 1) / (v[3] + 2)
  puts ([k, ka/ks, ka, ks] + v).join("\t")
end

