#!/bin/bash

##################### RUN
# Check if it was sourced from RUNME.bash
if [[ "$PDIR" == "" ]] ; then
   echo "$0: Error: This file is not stand-alone.  Execute RUNME.bash as described in the README.txt file" >&2
   exit 1
fi

if [[ ! -e "$SCRATCH/etc/01.bash" ]] ; then
   # 00. Initialize the project
   mkdir -p "$SCRATCH/tmp" "$SCRATCH/etc" "$SCRATCH/results" ;
   mkdir -p "$SCRATCH/log/status" "$SCRATCH/log/active" "$SCRATCH/log/done" ;
   echo "Preparing structure." >> "$SCRATCH/log/status/00" ;
   echo "msub -v '$MINVARS' '$PDIR/01.pbs.bash' | tr -d '\\n'" > "$SCRATCH/etc/01.bash"
fi

if [[ ! -e "$SCRATCH/etc/02.bash" ]] ; then
   # 01. Preparing input
   JOB01=$(bash "$SCRATCH/etc/01.bash") ;
   REGISTER_JOB "01" "00" "Preparing input files" "$JOB01" ;
else
   if [[ ! -e "$SCRATCH/etc/03.bash" ]] ; then
      # 02. Launching BLAST
      JOB02=$(bash "$SCRATCH/etc/02.bash") ;
      REGISTER_JOB "02" "00" "Launching BLAST runs" "$JOB02" ;
   else
      # 03. Finalize
      JOB03=$(bash "$SCRATCH/etc/03.bash")
      REGISTER_JOB "03" "00" "Concatenating results" "$JOB03"
   fi ;
fi ;


