#!/bin/bash

# @author  Luis M. Rodriguez-R
# @license Artistic-2.0

set -e # <- So it stops if there is an error
function exists { [[ -e "$1" ]] ; } # <- To test *any* of many files

OUT=$1		# <- Output file
[[ -n "$1" ]] && shift
SEQS=("$@")	# <- list of all genomes
THR=2		# <- Number or threads
DEF_DIST=0.9	# <- Default distance when AAI cannot be reliably estimated

# This is just the help message
if [[ $# -lt 2 ]] ; then
echo "
Use case: Building AAI matrices from a collection of genomes.

IMPORTANT
This script is functional, but it's mainly intended for illustrative purposes.
Please take a look at the code first.

Usage:
$0 <output.txt> <genomes...>

<output.txt>	The output AAI list, in tab-delimited form containing the
		following columns: (1) Sequence A, (2) Sequence B, (3)
		AAI, (4) AAI-SD, (5) Proteins used, (6) Number of proteins in
		the smallest genome, (7) Percentage of the genome shared.
<genomes...>	The list of files containing the genomes (at least 2).

" >&2
exit
fi

# 00. Create environment
export PATH=$(dirname "$0")/../Scripts:$PATH

# 01. Calculate AAI
echo "[01/03] Calculating AAI"
for i in "${SEQS[@]}" ; do
  for j in "${SEQS[@]}" ; do
    echo -n " o $i vs $j: "
    AAI=$(aai.rb -1 "$i" -2 "$j" -S "$OUT.db" -t "$THR" \
      --no-save-rbm --auto --quiet)
    echo ${AAI:-Below detection}
    [[ "$i" == "$j" ]] && break
  done
done

# 02. Extract matrix
echo "[02/03] Extracting list"
echo -e "SeqA\tSeqB\tAAI\tSD\tN\tOmega\tFrx" > "$OUT"
echo "select seq1, seq2, aai, sd, n, omega, (100.0*n/omega) from aai;" \
  | sqlite3 "$OUT.db" | tr '|' '\t' >> "$OUT"

# 03. Make it a distance matrix.
echo "[03/03] Generating distance matrix"
echo "
source('$(dirname $0)/../enveomics.R/R/df2dist.R');
a <- read.table('$OUT', sep='\\t', h=TRUE, as.is=T);
aai.d <- enve.df2dist(a, default.d=$DEF_DIST, max.sim=100);
write.table(as.matrix(aai.d), '$OUT.dist',
  quote=FALSE, col.names=NA, row.names=TRUE, sep='\\t')
" | R --vanilla >/dev/null
