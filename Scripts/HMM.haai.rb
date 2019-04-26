#!/usr/bin/env ruby

# @author Luis M. Rodriguez-R <lmrodriguezr at gmail dot com>
# @license Artistic-2.0

require 'optparse'

o = {q: false}
ARGV << '-h' if ARGV.size==0

OptionParser.new do |opt|
  opt.banner = "
Estimates Average Amino Acid Identity (AAI) from the essential genes extracted
and aligned by HMM.essential.rb (see --alignments).

Usage: #{$0} [options]"
  opt.separator ''
  opt.separator 'Mandatory'
  opt.on('-1 PATH', 'Input alignments file for genome 1.'){ |v| o[:a] = v }
  opt.on('-2 PATH', 'Input alignments file for genome 2.'){ |v| o[:b] = v }
  opt.separator ''
  opt.separator 'Options'
  opt.on('-a', '--aln-out FILE',
    'Output file containing the aligned proteins'){ |v| o[:alnout] = v }
  opt.on('-q', '--quiet', 'Run quietly (no STDERR output).'){ o[:q] = true }
  opt.on('-h', '--help', 'Display this screen.') do
    puts opt
    exit
  end
  opt.separator ''
end.parse!
abort '-1 is mandatory.' if o[:a].nil?
abort '-2 is mandatory.' if o[:b].nil?

class HList
  attr_accessor :list
  def initialize(file)
    @list = {}
    r = File.readlines(file)
    while not r.empty?
      e = HElement.new(*r.shift(3))
      @list[ e.model_id ] = e
    end
  end

  def [](model_id)
    list[model_id]
  end

  ##
  # Returns an array of HAln objects.
  def align(other)
    list.keys.map do |model_id|
      self[model_id].align(other[model_id]) unless other[model_id].nil?
    end.compact
  end

  def models
    list.keys
  end
end

class HElement
  attr_accessor :defline, :model_id, :protein_id, :protein_coords
  attr_accessor :model_aln, :protein_aln
  def initialize(defline, model_aln, protein_aln)
    @defline = defline.chomp
    @model_aln = model_aln.chomp
    @protein_aln = protein_aln.chomp
    if defline =~ /^# (.+) : (.+) : (.+)/
      @model_id = $1
      @protein_id = $2
      @protein_coords = $3
    end
  end

  def dup
    HElement.new(defline, model_aln, protein_aln)
  end

  ##
  # Returns an HAln object
  def align(other)
    HAln.new(self, other)
  end

  def mask
    @mask ||= model_aln.chars.
      each_with_index.map{ |v, k| v == '.' ? k : nil }.
      compact.reverse
  end

  def mask!(template)
    (template - mask).each do |d|
      @model_aln[d]   = '-' + @model_aln[d]
      @protein_aln[d] = '-' + @protein_aln[d]
    end
  end
end

class HAln
  attr :protein_1, :protein_2, :model_id, :protein_1_id, :protein_2_id
  def initialize(a, b)
    a_masked = a.dup
    a_masked.mask! b.mask.reverse
    b_masked = b.dup
    b_masked.mask! b_masked.mask
    @protein_1 = a_masked.protein_aln
    @protein_2 = b_masked.protein_aln
    @model_id = a.model_id
    @protein_1_id = a.protein_id + '/' + a.protein_coords
    @protein_2_id = b.protein_id + '/' + b.protein_coords
  end

  def stats
    @stats = { len: 0, gaps: 0, matches: 0 }
    return @stats unless @stats[:id].nil?
    protein_1.chars.each_with_index do |v, k|
      next if v == '-' and protein_2[k] == '-'
      @stats[:len] += 1
      if v == protein_2[k]
        @stats[:matches] += 1
      elsif v == '-' or protein_2[k] == '-'
        @stats[:gaps] += 1
      end
    end
    @stats.tap { |i| i[:id] = 100.0 * @stats[:matches] / @stats[:len] }
  end

  def stats_to_s
    stats.map{ |k,v| "#{k}:#{v}" }.join " "
  end

  def to_s
    "# #{model_id} | #{protein_1_id} | #{protein_2_id} | #{stats_to_s}\n" +
      protein_1 + "\n" + protein_2 + "\n"
  end
end

hlist1 = HList.new(o[:a])
hlist2 = HList.new(o[:b])
haln_arr = hlist1.align(hlist2)

avg_identity  = haln_arr.map{ |i| i.stats[:id] }.inject(:+) / haln_arr.size
avg2_identity = haln_arr.map{ |i| i.stats[:id] ** 2 }.inject(:+) / haln_arr.size
sd_identity   = Math.sqrt( avg2_identity - avg_identity ** 2 )
puts "Common models: #{haln_arr.size}"
puts "All models: #{(hlist1.models | hlist1.models).size}"
puts "Average identity: #{avg_identity.round(2)}%"
puts "SD identity: #{sd_identity.round(2)}"

if o[:alnout]
  File.open(o[:alnout], 'w') do |fh|
    haln_arr.each do |i|
      fh.puts i
    end
  end
end

