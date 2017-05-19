
##### CLASSES:
# Gene.new(genome, id): Initializes a new Gene.
# genome: A string uniquely identifying the parent genome.
# id: A string uniquely identifying the gene within the genome. It can be
#   non-unique across genomes.
class Gene
  attr_reader :genome_id, :id
  @@genomes = []
  def self.genomes
    @@genomes
  end
  def initialize(genome, id)
    if genome.is_a? Integer
      abort "Internal error: Genome #{genome} does not exist yet." if
        @@genomes[genome].nil?
      @genome_id = genome
    else
      @@genomes << genome unless @@genomes.include? genome
      @genome_id = @@genomes.index(genome)
    end
    @id = id
  end
  # Compare if two Gene objects refer to the same gene.
  def ==(b)
    self.genome_id==b.genome_id and self.id==b.id
  end
  # Get all genomes in the run as an array of strings.
  def genome
    @@genomes[self.genome_id]
  end
  def to_s
    "#{self.genome}:#{self.id}"
  end
end

# OG.new(): Initializes an empty OG.
# OG.new(genomes, genes): Initializes a pre-computed OG.
# genomes: List of genomes as an array of strings (as in Gene.genomes).
# genes: List of genes as an array of strings, with '-' indicating no genes and
#   multiple genes separated by ','.
class OG
  attr_reader :genes, :notes
  def initialize(genomes=nil, genes=nil)
    @genes = []
    @notes = []
    unless genomes.nil? or genes.nil?
      (0 .. genes.length-1).each do |genome_i|
        next if genes[genome_i]=="-"
        genes[genome_i].split(/,/).each do |gene_id|
          self << Gene.new(genomes[genome_i], gene_id)
        end
      end
    end
  end
  # Add genes or combine another OG into the loaded OG (self).
  def <<(obj)
    if obj.is_a? Gene
      @genes[obj.genome_id] = [] if @genes[obj.genome_id].nil?
      @genes[obj.genome_id] << obj.id unless self.include? obj
    elsif obj.is_a? OG
      obj.genes_obj.each{ |gene| self << gene }
    else
      abort "Unsupported class for #{obj}"
    end
  end
  # Get the list of genes as objects (internally saved as strings to save RAM).
  def genes_obj
    o = []
    (0 .. Gene.genomes.length-1).map do |genome_id|
      o += self.genes[genome_id].map{ |gene_id|
        Gene.new(Gene.genomes[genome_id], gene_id) } unless
          self.genes[genome_id].nil?
    end
    return o
  end
  # Evaluates if the OG contains the passed gene.
  def include?(gene)
    return false if self.genes[gene.genome_id].nil?
    self.genes[gene.genome_id].include? gene.id
  end
  # Get the list of genomes containing genes in this OG.
  def genomes
    (0 .. Gene.genomes.length-1).select do |gno|
      not(self.genes[gno].nil? or self.genes[gno].empty?)
    end
  end
  # Adds a note that will be printed after the last column
  def add_note note, note_idx=nil
    if note_idx.nil?
      @notes << note
    else
      @notes[note_idx] = (@notes[note_idx].nil? ? '' :
        (@notes[note_idx]+' || ')) + note
    end
  end
  def to_s
    (0 .. Gene.genomes.length-1).map do |genome_id|
      self.genes[genome_id].nil? ? "-" : self.genes[genome_id].join(",")
    end.join("\t") + ((self.notes.size==0) ? '' :
      ("\t#\t"+self.notes.join("\t")))
  end
  def to_bool_a
    (0 .. Gene.genomes.length-1).map { |genome_id| not genes[genome_id].nil? }
  end
end

# OGCollection.new(): Initializes an empty collection of OGs.
class OGCollection
  attr_reader :ogs, :note_srcs
  def initialize
    @ogs = []
    @note_srcs = []
  end
  # Add an OG to the collection
  def <<(og)
    @ogs << og
  end
  # Compare OGs all-vs-all to identify groups that should be merged.
  def consolidate!
    old_ogs = self.ogs
    @ogs = []
    old_ogs.each do |og|
      is_new = true
      og.genes_obj.each do |gene|
        o = self.get_og gene
        unless o.nil?
          o << og
          is_new = false
          break
        end
      end
      self << og if is_new
    end
  end
  # Removes OGs present in less than 'fraction' of the genomes
  def filter_core!(fraction=1.0)
    min_genomes = (fraction * Gene.genomes.size).ceil
    @ogs.select! { |og| og.genomes.size >= min_genomes }
  end
  # Removes OGs present more than 'dups' number of times in any genome
  def remove_inparalogs!(dups=1)
    @ogs.select! do |og|
      og.genes.map{ |pergenome| pergenome.size }.max <= dups
    end
  end
  # Add a pair of RBM genes into the corresponding OG, or create a new OG.
  def add_rbm(a, b)
    og = self.get_og(a)
    og = self.get_og(b) if og.nil?
    if og.nil?
      og = OG.new
      @ogs << og
    end
    og << a
    og << b
  end
  # Get the OG containing the gene (returns the first, if multiple).
  def get_og(gene)
    idx = self.ogs.index { |og| og.include? gene }
    idx.nil? ? nil : self.ogs[idx]
  end
  # Get the genes from a given genome (returns an array of arrays)
  def get_genome_genes(genome)
    genome_id = Gene.genomes.index(genome)
    self.ogs.map do |og|
      g = og.genes[genome_id]
      g.nil? ? [] : g
    end
  end
  # Add annotation sources
  def add_note_src src
    @note_srcs << src
  end
  def to_s
    Gene.genomes.join("\t") + ((self.note_srcs.length>0) ?
        ("\t#\t"+self.note_srcs.join("\t")) : '') +
      "\n" + self.ogs.map{ |og| og.to_s }.join("\n")
  end
  def to_bool_a ; ogs.map{ |og| og.to_bool_a } ; end
end

