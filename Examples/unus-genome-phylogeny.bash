#!/bin/bash

#
# @author  Luis M. Rodriguez-R
# @update  Oct-20-2015
# @license artistic license 2.0
#

ORG=$1 # <- Organism (see help)
THR=2 # <- Number or threads

# This is just the help message
if [[ "$ORG" == "" ]] ; then
echo "
Use case: Unus genome phylogeny of a species. The unus genome is the collection
of orthologous groups in a set of genomes that has exactly one gene per genome,
i.e., the core genome minus in-paralogs.

IMPORTANT
This script is functional, but it's mainly intended for illustrative purposes.
Please take a look at the code first.

Usage:
$0 <organism>

<organism>	The organism to use (e.g., Streptococcus_pneumoniae).

" >&2
exit
fi

# 00. Create environment
export PATH=$(dirname $0)/../Scripts:$PATH
if [[ -e $ORG ]] ; then
   echo "Cowardly refusing to overwrite $ORG, please remove archive first." >&2
   exit 1
fi
mkdir $ORG
for i in 01.proteome 02.rbm 03.ogs 04.aln 05.cat 06.raxml ; do
   mkdir $ORG/$i
done

# 01. Download proteomes
echo "[01/06] Downloading and guzipping data"
RefSeq.download.bash $ORG .faa.gz "Complete Genome" $ORG/01.proteome
rm $ORG/01.proteome/assembly_summary.txt
for i in $ORG/01.proteome/* ; do
   b=$(basename $i | perl -pe 's/[^A-Za-z0-9]/_/g' | perl -pe 's/_+$//')
   for j in $i/*.faa.gz ; do gunzip $j ; done
   cat $i/*.faa > $ORG/01.proteome/$b.faa.tmp
   FastA.tag.rb -i $ORG/01.proteome/$b.faa.tmp -o $ORG/01.proteome/$b.faa.tmp -d
   rm -R $i $ORG/01.proteome/$b.faa.tmp
done

# 02. Reciprocal Best Matches
echo "[02/06] Idenfifying Reciprocal Best Matches"
for i in $ORG/01.proteome/*.faa ; do # <- This nested loop could be parallelized
   genomeA=$(basename $i .faa)
   for j in $ORG/01.proteome/*.faa ; do
      genomeB=$(basename $j .faa)
      rbm.rb -1 $i -2 $j -t $THR > $ORG/02.rbm/$genomeA-$genomeB.rbm
      [[ "$i" == "$j" ]] && continue # <- Ignore if it simplifies distribution
   done
done

# 03. Orthologous Groups
echo "[03/06] Compiling Orthologous Groups"
ogs.mcl.rb -d $ORG/02.rbm -o $ORG/03.ogs/pangenome.ogs -t $THR

# 04. Extract unus genome and align groups
echo "[04/06] Extracting unus genome and aligning OGs"
ogs.extract.rb -i $ORG/03.ogs/pangenome.ogs -s $ORG/01.proteome/%s.faa \
   -o $ORG/04.aln/ -c 1 -d 1 -p
for i in $ORG/04.aln/*.fa ; do # <- This loop could be parallelized
   b=$(basename $i .fa)
   clustalo -i $i -o $ORG/04.aln/$b.aln --threads=$THR
done

# 05. Concatenate alignment
echo "[05/06] Concatenating alignments and removing invariable sites"
Aln.cat.rb -I -c $ORG/05.cat/unus.raxcoords -i - $ORG/04.aln/*.aln \
   > $ORG/05.cat/unus.aln 2> $ORG/05.cat/unus.log

# 06. Run RAxML
echo "[06/06] Inferring phylogeny"
# You REALLY should consider running the following with more threads (-T) and,
# if possible, multi-nodes using MPI
cd $ORG/06.raxml
raxmlHPC-PTHREADS -T $THR -p 1234 \
   -s ../05.cat/unus.aln -q ../05.cat/unus.raxcoords \
   -m PROTCATGTR -n UNUS #  IMPORTANT:	Please read the documentation of RAxML
   			 # 		before running this line, so you know
			 # 		that you're running what you really
			 #		want. Check options for bootstrapping
			 #		and the different algorithms (-f). Note
			 #		that -m is required, but the file
			 #		unus.raxcoords specifies "AUTO", so
			 #		RAxML will attempt to find the model
			 #		resulting in the highest likelihood.

