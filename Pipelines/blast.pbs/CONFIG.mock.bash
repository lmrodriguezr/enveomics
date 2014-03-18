#!/bin/bash

##################### VARIABLES
# Queue and resources.
QUEUE="iw-shared-6" ;
MAX_JOBS=500 ; # Maximum number of concurrent jobs. Never exceed 1990.
PPN=2 ;
RAM="9gb" ;

# Paths
SCRATCH_DIR="$HOME/scratch/pipelines/blast" ; # Where the outputs and temporals will be created
INPUT="$HOME/data/my-large-file.fasta" ; # Input query file
DB="$HOME/data/db/nr" ; # Input database
PROGRAM="blastp" ;

# Pipeline
MAX_TRIALS=5 ; # Maximum number of automated attempts to re-start a job

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
   # module load ncbi_blast/2.2.25 || exit 1 ;
   # makeblastdb -in $HOME/data/some-database.faa -title $DB -dbtype prot || exit 1 ;
   # module unload ncbi_blast/2.2.25 || exit 1 ;
   ### Don't do anything:
   true ;
}

# Function to execute BEFORE running the BLAST, for each sub-task.
function BEFORE_BLAST {
   local IN=$1 # Query file
   local OUT=$2 # Blast file (to be created)
   ### Don't do anything:
   true ;
}

# Function that executes BLAST, for each sub-task
function RUN_BLAST {
   local IN=$1 # Query file
   local OUT=$2 # Blast file (to be created)
   ### Run BLAST+ with 13th and 14th columns (query length and subject length):
   module load ncbi_blast/2.2.28_binary || exit 1 ;
   $PROGRAM -query $IN -db $DB -out $OUT -num_threads $PPN \
   	-outfmt "6 qseqid sseqid pident length mismatch gapopen qstart qend sstart send evalue bitscore qlen slen" \
	|| exit 1 ;
   module unload ncbi_blast/2.2.28_binary || exit 1 ;
   ### Run BLAT (nucleotides)
   # module load blat/rhel6 || exit 1 ;
   # blat $DB $IN -out=blast8 $OUT || exit 1 ;
   # module unload blat/rhel6 || exit 1 ;
   ### Run BLAT (proteins)
   # module load blat/rhel6 || exit 1 ;
   # blat $DB $IN -out=blast8 -prot $OUT || exit 1 ;
   # module unload blat/rhel6 || exit 1 ;
}

# Function to execute AFTER running the BLAST, for each sub-task
function AFTER_BLAST {
   local IN=$1 # Query files
   local OUT=$2 # Blast files
   ### Filter by best-match:
   # sort $OUT | perl $PDIR/../../Scripts/BlastTab.best_hit_sorted.pl > $OUT.bm
   ### Filter by Bit-score 60:
   # awk '$12>=60' $OUT > $OUT.bs60
   ### Filter by corrected identity 95 (only if it has the additional 13th column):
   # awk '$3*$4/$13 >= 95' $OUT > $OUT.ci95
   ### Don't do anything:
   true ;
}

# Function to execute ONLY ONCE at the end, to concatenate the results
function END {
   local PREFIX=$1 # Prefix of all Blast files
   local OUT=$2 # Single Blast output (to be created).
   ### Simply concatenate files:
   # cat $PREFIX.*.blast > $OUT
   ### Concatenate only the filtered files (if filtering in AFTER_BLAST):
   # cat $PREFIX.*.blast.bs60 > $OUT
   ### Sort the BLAST by query (might require considerable RAM):
   # sort -k 1 $PREFIX.*.blast > $OUT
   ### Don't do anyhthing:
   true ;
}

