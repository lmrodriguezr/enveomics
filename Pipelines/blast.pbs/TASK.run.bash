#!/bin/bash

##################### RUN
# Check if it was sourced from RUNME.bash
if [[ "$PDIR" == "" ]] ; then
   echo "$0: Error: This file is not stand-alone.  Execute RUNME.bash as described in the README.txt file" >&2
   exit 1
fi

if [[ ! -e "$SCRATCH/etc/01.bash" ]] ; then
   # 00. Initialize the project
   mkdir -p "$SCRATCH/tmp" "$SCRATCH/etc" "$SCRATCH/results" "$SCRATCH/success" ;
   mkdir -p "$SCRATCH/log/status" "$SCRATCH/log/active" "$SCRATCH/log/done" ;
   mkdir -p "$SCRATCH/log/err" "$SCRATCH/log/out" ;
   echo "Preparing structure." >> "$SCRATCH/log/status/00" ;
   echo "msub -q '$QUEUE' -l 'walltime=$MAX_H:00:00,MEM=$RAM' -v '$MINVARS' -N '$PROJ-01' '$PDIR/01.pbs.bash' | tr -d '\\n'" > "$SCRATCH/etc/01.bash"
   touch "$SCRATCH/success/00" ;
fi ;

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

