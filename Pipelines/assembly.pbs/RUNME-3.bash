#!/bin/bash

##################### RUN
# Find the directory of the pipeline
PDIR=$(dirname $(readlink -f $0));
# Load variables
source "$PDIR/RUNME.bash"
if [[ "$SCRATCH" == "" ]] ; then
   echo "$0: Error loading $PDIR/RUNME.bash, variable SCRATCH undefined" >&2
   exit 1
fi

# Run it
echo "Jobs being launched in $SCRATCH"
for LIB in $LIBRARIES; do
   # Prepare info
   echo "Running $LIB";
   VARS="LIB=$LIB,PDIR=$PDIR"
   # Launch Stats
   NAME="N50_${LIB}"
   qsub "$PDIR/stats.pbs" -v "$VARS" -d "$SCRATCH" -N "$NAME"
done

