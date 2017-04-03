# @author  Luis M. Rodriguez-R
# @license Artistic-2.0

##
# Enveomics representation of a Variant Call Format (VCF) file.
class VCF
  
  ##
  # File-handler, a File object.
  attr_reader :fh
  def initialize(file)
    @fh = (file.is_a?(String) ? File.open(file, "r") : file )
  end
  
  ##
  # Iterate through each variant (i.e., each non-comment line), passing a
  # VCF::Variant object to +blk+.
  def each_variant(&blk)
    fh.rewind
    fh.each_line do |ln|
      next if ln =~ /^#/
      blk.call VCF::Variant.new(ln)
    end
  end

  ##
  # Iterate through each header (i.e., each comment line), passing a String to
  # +blk+.
  def each_header(&blk)
    fh.rewind
    fh.each_line do |ln|
      next unless ln =~ /^#/
      blk.call ln
    end
  end
end

class VCF::Variant
  
  ##
  # Column definitions in VCF.
  @@COLUMNS = [:chrom,:pos,:id,:ref,:alt,:qual,:filter,:info,:format,:bam]
  
  ##
  # An Array of String, containing each of the VCF entrie's columns.
  attr_reader :data

  ##
  # Initialize VCF::Variant from String +line+, a non-comment line in the VCF.
  def initialize(line)
    @data = line.chomp.split("\t")
    # Qual as float
    @data[5] = data[5].to_f
    # Split info
    info = data[7].split(";").map{ |i| i=~/=/ ? i.split("=", 2) : [i, true] }
    @data[7] = Hash[*info.map{ |i| [i[0].to_sym, i[1]] }.flatten]
    # Read formatted data
    unless data[9].nil? or data[9].empty?
      f = format.split(":")
      b = bam.split(":")
      f.each_index{ |i| @data[7][f[i].to_sym] = b[i] }
    end
    @data[7][:INDEL] = true if ref.size != alt.split(",").first.size
  end

  ##
  # Named functions for each column.
  @@COLUMNS.each_index do |i|
    define_method(@@COLUMNS[i]) { @@COLUMNS[i]==:pos ? data[i].to_i : data[i] }
  end

  ##
  # Sequencing depth.
  def dp
    return nil if info[:DP].nil?
    info[:DP].to_i
  end

  ##
  # Sequencing depth of FWD-REF, REV-REF, FWD-ALT, and REV-ALT.
  def dp4
    return nil if info[:DP4].nil?
    @dp4 ||= info[:DP4].split(",").map{ |i| i.to_i }
    @dp4
  end

  ##
  ## Sequencing depth of REF and ALT.
  def ad
    return nil if info[:AD].nil?
    @ad ||= info[:AD].split(",").map{ |i| i.to_i }
    @ad
  end
  
  ##
  # Sequencing depth of the REF allele.
  def ref_dp
    return dp4[0] + dp4[1] unless dp4.nil?
    return ad[0] unless ad.nil?
    nil
  end

  ##
  # Sequencing depth of the ALT allele.
  def alt_dp
    return dp4[2] + dp4[3] unless dp4.nil?
    return ad[1] unless ad.nil?
    nil
  end

  ##
  # Information content of the variant in bits (from 0 to 1).
  def shannon
    return @shannon unless @shannon.nil?
    a = ref_dp
    b = alt_dp
    ap = a.to_f/(a+b)
    bp = b.to_f/(a+b)
    @shannon = -(ap*Math.log(ap,2) + bp*Math.log(bp,2))
    @shannon
  end

  ##
  # Is it an indel?
  def indel? ; !info[:INDEL].nil? and info[:INDEL] ; end

  ##
  # Return as String.
  def to_s ; (data[0..6] + [info_to_s] + data[8..-1].to_a).join("\t") + "\n" ; end

  ##
  # Returns the INFO entry as String.
  def info_to_s ; data[7].to_a.map{ |i| i.join("=") }.join(";") ; end
  
end
