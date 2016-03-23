#!/bin/bash

#
# @author  Luis M. Rodriguez-R
# @update  Mar-23-2016
# @license artistic license 2.0
#

set -e # <- So it stops if there is an error
function exists { [[ -e "$1" ]] ; } # <- To test *any* of many files

ORG=$1 # <- Organism (see help)
THR=2 # <- Number or threads

# This is just the help message
if [[ "$ORG" == "" ]] ; then
echo "
Use case: Essential genes phylogeny of a species. The essential genes are a
collection of genes typically found in single copy in archaeal and bacterial
genomes

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
for i in 01.proteome 02.essential 03.aln 04.cat 05.raxml 06.autoprune ; do
   mkdir $ORG/$i
done

# 01. Download proteomes
echo "[01/06] Downloading and guzipping data"
RefSeq.download.bash $ORG .faa.gz "Complete Genome" $ORG/01.proteome
rm $ORG/01.proteome/assembly_summary.txt
for i in $ORG/01.proteome/* ; do
   b=$(basename $i | perl -pe 's/[^A-Za-z0-9]/_/g' | perl -pe 's/_+$//')
   if exists $i/*.faa.gz ; then
      for j in $i/*.faa.gz ; do gunzip $j ; done
      cat $i/*.faa > $ORG/01.proteome/$b.faa
   fi
   rm -R $i
done

# 02. Essential genes
echo "[02/06] Idenfifying essential genes"
N=0
for i in $ORG/01.proteome/*.faa ; do # <- This loop could be parallelized
   genomeA=$(basename $i .faa)
   dir=$ORG/02.essential/$genomeA
   mkdir $dir
   HMM.essential.rb -i $i -m $dir/ -R $dir/log.txt -r $genomeA -t $THR
   let N=$N+1
done

# 03. Find core and align groups
echo "[03/06] Identifying core essentials and aligning groups"
CORE_ESS=$(basename -s .faa $ORG/02.essential/*/*.faa | sort | uniq -c \
   | awk '$1=='$N'{print $2}') 
for b in $CORE_ESS ; do # <- This loop could be parallelized
   cat $ORG/02.essential/*/$b.faa > $ORG/03.aln/$b.faa
   clustalo -i $ORG/03.aln/$b.faa -o $ORG/03.aln/$b.aln #--threads=$THR
done

# 04. Concatenate alignment
echo "[04/06] Concatenating alignments and removing invariable sites"
Aln.cat.rb -I -c $ORG/04.cat/essential.raxcoords -i '|' $ORG/03.aln/*.aln \
   > $ORG/04.cat/essential.aln 2> $ORG/04.cat/essential.log

# 05. Run RAxML
echo "[05/06] Inferring phylogeny"
# You REALLY should consider running the following with more threads (-T) and,
# if possible, multi-nodes using MPI
cd $ORG/05.raxml
raxmlHPC-PTHREADS -T $THR -p 1234 \
   -s ../04.cat/essential.aln -q ../04.cat/essential.raxcoords \
   -m PROTCATGTR -n UNUS #  IMPORTANT:	Please read the documentation of RAxML
   			 # 		before running this line, so you know
			 #  that you're running what you really want. Check
			 #  options for bootstrapping and the different
			 #  algorithms (-f). Note that -m is required, but the
			 #  file unus.raxcoords specifies "AUTO", so RAxML will
			 #  attempt to find the model resulting in the highest
			 #  likelihood.
cd ../..

# 06. Autoprune
echo "[06/06] Auto-pruning the tree"
Newick.autoprune.R --t $ORG/05.raxml/RAxML_bestTree.UNUS --min_dist 0.001 \
   $ORG/06.autoprune/essential-pruned.nwk

