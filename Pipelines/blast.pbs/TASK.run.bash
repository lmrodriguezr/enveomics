#!/bin/bash

##################### RUN
# Check if it was sourced from RUNME.bash
if [[ "$PDIR" == "" ]] ; then
   echo "$0: Error: This file is not stand-alone.  Execute RUNME.bash as described in the README.txt file" >&2
   exit 1
fi

# Check if too many auto-trials were attempted
trials=0 ;
if [[ -e "$SCRATCH/etc/trials" ]] ; then
   trials=$(cat "$SCRATCH/etc/trials" | wc -l | sed -e 's/ //g');
   if [[ $trials -ge $MAX_TRIALS ]] ; then
      echo "The maximum number of trials was already attempted, halting." >&2 ;
      exit 1 ;
   fi ;
fi ;

# Create the scratch directory
if [[ ! -d "$SCRATCH" ]] ; then mkdir -p "$SCRATCH" || exit 1 ; fi;

if [[ ! -e "$SCRATCH/success/00" ]] ; then
   # 00. Initialize the project
   echo "00. Initializing project." >&2 ;
   mkdir -p "$SCRATCH/tmp" "$SCRATCH/etc" "$SCRATCH/results" "$SCRATCH/success" || exit 1 ;
   mkdir -p "$SCRATCH/log/active" "$SCRATCH/log/done" "$SCRATCH/log/failed" || exit 1 ;
   mkdir -p "$SCRATCH/log/status" "$SCRATCH/log/eo" || exit 1 ;
   echo "Preparing structure." >> "$SCRATCH/log/status/00" ;
   # Build 01.bash
   echo "NEW_JOBID=\$(qsub -q '$QUEUE' -l 'walltime=$MAX_H:00:00,mem=$RAM' -v '$MINVARS' -N '$PROJ-01' \\
      '$PDIR/01.pbs.bash'|tr -d '\\n')" \
      > "$SCRATCH/etc/01.bash" || exit 1 ;
   echo "SENTINEL_JOBID=\$(qsub -q '$QUEUE' -l 'walltime=2:00:00' -W \"depend=afterany:\$NEW_JOBID\" \\
      -v \"$MINVARS,STEP=01,AFTERJOB=\$NEW_JOBID\" -N '$PROJ-01-sentinel' '$PDIR/sentinel.pbs.bash'|tr -d '\\n')" \
      >> "$SCRATCH/etc/01.bash" || exit 1 ;
   # Build 02.bash
   echo "NEW_JOBID=\$(qsub -q '$QUEUE' -l 'walltime=$MAX_H:00:00,mem=$RAM,nodes=1:ppn=$PPN' \\
      -v '$MINVARS' -N '$PROJ-02' -t '1-$MAX_JOBS' '$PDIR/02.pbs.bash'|tr -d '\\n')" \
      > "$SCRATCH/etc/02.bash" \
      || exit 1 ;
   echo "SENTINEL_JOBID=\$(qsub -q '$QUEUE' -l 'walltime=2:00:00' -W \"depend=afteranyarray:\$NEW_JOBID\" \\
      -v \"$MINVARS,STEP=02,AFTERJOB=\$NEW_JOBID\" -N '$PROJ-02-sentinel' '$PDIR/sentinel.pbs.bash'|tr -d '\\n')" \
      >> "$SCRATCH/etc/02.bash" \
      || exit 1 ;
   # Build 03.bash
   echo "NEW_JOBID=\$(qsub -q '$QUEUE' -l 'walltime=$MAX_H:00:00,mem=$RAM' -v '$MINVARS' -N '$PROJ-03' \\
      '$PDIR/03.pbs.bash'|tr -d '\\n')" \
      > "$SCRATCH/etc/03.bash" || exit 1 ;
   echo "SENTINEL_JOBID=\$(qsub -q '$QUEUE' -l 'walltime=2:00:00' -W \"depend=afterany:\$NEW_JOBID\" \\
      -v \"$MINVARS,STEP=03,AFTERJOB=\$NEW_JOBID\" -N '$PROJ-03-sentinel' '$PDIR/sentinel.pbs.bash'|tr -d '\\n')" \
      >> "$SCRATCH/etc/03.bash" || exit 1 ;
   
   JOB_DONE "00" ;
fi ;

if [[ ! -e "$SCRATCH/success/01" ]] ; then
   # 01. Preparing input
   echo "01. Preparing input." >&2 ;
   JOB01=$(LAUNCH_JOB "01" "00" "Preparing input files" "$SCRATCH/etc/01.bash") ;
   echo "  New job: $JOB01." >&2 ;
else
   if [[ ! -e "$SCRATCH/success/02" ]] ; then
      # 02. Launching BLAST
      echo "02. Launching BLAST." >&2 ;
      JOB02=$(LAUNCH_JOB "02" "00" "Running BLAST" "$SCRATCH/etc/02.bash") ;
      echo "  New job: $JOB02." >&2 ;
      # Clean on resubmission
      cleaned=0
      echo -n "  Cleaning completed sub-jobs on $JOB02: " >&2 ;
      for jobi in $(seq 1 $MAX_JOBS) ; do
	 if [[ -e "$SCRATCH/success/02.$jobi" ]] ; then
	    qdel "$JOB02""[$jobi]" &> /dev/null ;
	    let cleaned=$cleaned+1 ;
	 fi ;
      done ;
      echo "$cleaned sub-jobs completed." >&2 ;
   else
      if [[ ! -e "$SCRATCH/success/03" ]] ; then
	 # 03. Finalize
	 echo "03. Finalizing." >&2 ;
	 JOB03=$(LAUNCH_JOB "03" "00" "Concatenating results" "$SCRATCH/etc/03.bash") ;
	 echo "  New job: $JOB03." >&2 ;
      else
         echo "Project complete, nothing to run." ;
      fi ;
   fi ;
fi ;

