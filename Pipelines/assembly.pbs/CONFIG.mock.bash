#!/bin/bash

##################### VARIABLES
# Queue: Preferred queue.  Delete (or comment) this line to allow
# automatic detection:
#QUEUE="biocluster-6"
# If you set the QUEUE variable, you MUST set the WTIME variable
# as well, containing the walltime to be asked for.  The WTIME
# variable is ignored otherwise.
WTIME="120:00:00"

# Scratch:  This is where the output will be created.
SCRATCH="$HOME/scratch/pipelines/assembly"

# Data folder:  This is the folder that cointains the input files.
DATA="$HOME/data/trim"

# Location of Newbler's binaries
BIN454="$HOME/454/bin"

# Name(s) of the library(ies) to use, separated by spaces:
# This is determined by the name of your input files.  For example,
# if your input files are: LLSEP.CoupledReads.fa and LWP.CoupledReads.fa,
# use:
# LIBRARIES="LLSEP LWP"
# It's strongly encouraged to use only one per CONFIG file.
LIBRARIES="A";

# Use .CoupledReads.fa and/or .SingleReads.fa (yes or no):
USECOUPLED=yes
USESINGLE=no

# Insert length (in bp):  This is the average length of the entire insert,
# not just the gap length.
INSLEN=300

# Number of CPUs to use (for SOAP and Newbler):
PPN=16

# RAM multiplier: Multiply the estimated required RAM by this number:
RAMMULT=1

# Maximum number of simultaneous jobs: Uncomment and increase these values if
# you have increased resources (e.g., a dedicated queue); uncomment and decrease
# if the resources are scarce (e.g., a very busy queue or other simultaneous jobs).
#VELVETSIM=22
#SOAPSIM=8

# Extra parameters for Velvet: Any additional parameters to be passed to
# velvetg or velveth.  If you have MP data, consider adding the option
# -shortMatePaired yes to VELVETG_EXTRA.  If you have Nextera, consider
# adding the option above, plus the option -ins_length_sd <integer>, to
# indicate the standard deviation of the insert size.  By default, the
# SD is assumed to be 10% of the average, but Nextera produces much
# wider distribution of sizes (i.e., larger SD).  Typically you shouldn't
# need to add anything in VELVETH_EXTRA.
VELVETH_EXTRA=""
VELVETG_EXTRA=""

# Clean non-essential files (yes or no):
CLEANUP=yes

# Best k-mers:  Space-delimited list of kmers selected from Velvet and SOAP.
# This is to be modified at the begining of step 4, and it's ignored in all
# the other steps.
K_VELVET="21 23 35"
K_SOAP="21 23 35"


