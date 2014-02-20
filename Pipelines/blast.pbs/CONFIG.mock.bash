#!/bin/bash

##################### VARIABLES
# Queue and resources.
QUEUE="biocluster-6" # queue
RUNNING_TIME_D=365 # Estimated TOTAL number of days that the job would take in one node
PPN=2 # Number of CPUs per node
RAM="9gb" # Maximum RAM to use

# Paths
SCRATCH="$HOME/scratch/pipelines/assembly" # Where the outputs and temporals will be created
INPUT="$HOME/data/my-large-file.fasta" # Input query file

##################### FUNCTIONS
# Function to execute BEFORE running the BLAST.
function BEFORE_BLAST {
   IN=$1
   OUT=$2
}

# Function that executes BLAST
function RUN_BLAST {
   IN=$1
   OUT=$2
   DB="$HOME/data/db/nr" # Input database
   module load ncbi_blast/2.2.25
   blastp -query $IN -db $DB -out $OUT -num_threads $PPN \
   	-outfmt "6 qseqid sseqid pident length mismatch gapopen qstart qend sstart send evalue bitscore qlen slen"
}

# Function to execute AFTER running the BLAST
function AFTER_BLAST {
   IN=$1
   OUT=$2
   ### Filter by Bit-score 60:
   # awk '$12>=60' $OUT > $OUT.bs60
   ### Filter by corrected identity 95 (only if it has the additional 13th column):
   # awk '$3*$4/$13 >= 95' $OUT > $OUT.ci95
}

# Function to execute ONLY ONCE to concatenate the results
function END {
   PREFIX=$1
   SUFFIX=$2
   OUT=$3
   ### Simply concatenate files:
   # cat $PREFIX.*.$SUFFIX > $OUT
   ### Concatenate only the filtered files (if filtering in AFTER_BLAST):
   # cat $PREFIX.*.$SUFFIX > $OUT
   ### Sort the BLAST by query (might require considerable RAM):
   # sort -k 1 $PREFIX.*.$SUFFIX > $OUT
   ### Don't do anyhthing:
   # 
}

