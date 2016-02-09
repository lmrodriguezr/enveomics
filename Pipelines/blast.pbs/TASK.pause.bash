#!/bin/bash

##################### RUN
# Check if it was sourced from RUNME.bash
if [[ "$PDIR" == "" ]] ; then
   echo "$0: Error: This file is not stand-alone." >&2
   echo "  Execute RUNME.bash as described in the README.txt file" >&2 ;
   exit 1 ;
fi ;

# Get active jobs:
echo "======[ check ]======"
job_r=0;
job_i=0;
job_c=0;

echo "======[ pause ]======"
for i in $(ls $SCRATCH/log/active/* 2>/dev/null) ; do
   echo "  Pausing $jid." ;
   jid=$(basename $i) ;
   qdel $jid ;
done ;

# Restart auto-trials
echo -n > "$SCRATCH/etc/trials" ;

