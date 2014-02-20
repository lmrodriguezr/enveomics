#!/bin/bash

##################### VARIABLES
# Queue and resources.
QUEUE="biocluster-6"
RUNNING_TIME_D=365 # <-- Estimated TOTAL number of days that the job would take in one node
PPN=2
RAM="9gb"

# Paths
SCRATCH="$HOME/scratch/pipelines/assembly" # Where the outputs and temporals will be created
INPUT="$HOME/data/my-large-file.fasta" # Input query file
DB="$HOME/data/db/nr" # Input database
PROGRAM="blastp"

##################### FUNCTIONS
## All the functions below can be edited to suit your particular job.
## No function can be empty, but you can use a "dummy" function (like true).
## All functions have access to any of the variables defined above.
## 
## The functions are executed in the following order (from left to right):
##
##           / -----> BEFORE_BLAST --> RUN_BLAST --> AFTER_BLAST ---\
##          /              ···            ···            ···         \
## BEGIN --#--------> BEFORE_BLAST --> RUN_BLAST --> AFTER_BLAST -----#---> END
##          \              ···            ···            ···         /
##           \ -----> BEFORE_BLAST --> RUN_BLAST --> AFTER_BLAST ---/
##

# Function to execute ONLY ONCE at the begining
function BEGIN {
   ### Format the database (assuming proteins, check commands):
   # module load ncbi_blast/2.2.25
   # makeblastdb -in $HOME/data/some-database.faa -title $DB -dbtype prot
   # module unload ncbi_blast/2.2.25
   ### Don't do anything:
   true ;
}

# Function to execute BEFORE running the BLAST, for each sub-task.
function BEFORE_BLAST {
   IN=$1
   OUT=$2
   ### Don't do anything:
   true ;
}

# Function that executes BLAST, for each sub-task
function RUN_BLAST {
   IN=$1
   OUT=$2
   ### Run blastp (from BLAST+) with 13th and 14th columns (query length and subject length):
   module load ncbi_blast/2.2.25
   $PROGRAM -query $IN -db $DB -out $OUT -num_threads $PPN \
   	-outfmt "6 qseqid sseqid pident length mismatch gapopen qstart qend sstart send evalue bitscore qlen slen"
   module unload ncbi_blast/2.2.25
}

# Function to execute AFTER running the BLAST, for each sub-task
function AFTER_BLAST {
   IN=$1
   OUT=$2
   ### Filter by Bit-score 60:
   # awk '$12>=60' $OUT > $OUT.bs60
   ### Filter by corrected identity 95 (only if it has the additional 13th column):
   # awk '$3*$4/$13 >= 95' $OUT > $OUT.ci95
}

# Function to execute ONLY ONCE at the end, to concatenate the results
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
   true ;
}

