#!/bin/bash

##################### RUN
# Check if it was sourced from RUNME.bash
if [[ "$PDIR" == "" ]] ; then
   echo "$0: Error: This file is not stand-alone." >&2
   echo "  Execute RUNME.bash as described in the README.txt file" >&2
   exit 1
fi

# Check if the project exists
if [[ ! -d "$SCRATCH" ]] ; then
   echo "The project $PROJ doesn't exist at $SCRATCH_DIR." >&2
   echo "  Execute '$PDIR/RUNME.bash $PROJ run' first." >&2
   exit 1
fi

# Get log:
echo "==[ Running tasks ]=="
for i in $(ls $SCRATCH/log/status/* 2>/dev/null) ; do
   echo "  $(basename $i): $(tail -n 1 $i)"
done
echo ""

# Get active jobs:
echo "==[ Active jobs ]=="
job_r=0
job_i=0
job_c=0
for i in $(ls $SCRATCH/log/active/* 2>/dev/null) ; do
   jid=$(basename $i)
   stat=$(qstat -f1 $jid 2>&1)
   state=$(echo "$stat" | grep '^ *job_state = ' | sed -e 's/.*job_state = //')
   case $state in
   C)
      code=$(echo "$stat" | grep '^ *exit_status = ' | sed -e 's/.*exit_status = //')
      if [[ "$code" == "0" ]] ; then
         mv "$i" "$SCRATCH/log/done/"
	 let job_c=$job_c+1
      else
	 echo "Warning: Job $jid ($(cat $i|tr -d '\n')) failed with code $code." >&2
	 echo "  see errors at: $(echo "$stat" | grep '^ *Error_Path = ' | sed -e 's/.*Error_Path = //')"
         mv "$i" "$SCRATCH/log/failed/"
      fi ;;
   R)
      echo "  Running: $jid: $(cat "$i")"
      let job_r=$job_r+1 ;;
   [HQW])
      echo "  Idle: $jid: $(cat "$i")"
      let job_i=$job_i+1 ;;
   E)
      echo "  Canceling: $jid: $(cat "$i")" ;;
   *)
      tmp_err=$(echo "$stat" | grep ERROR)
      if [[ "$tmp_err" == "" ]] ; then
	 echo "Warning: Unrecognized state: $jid: $state." >&2
	 echo "  Please report this problem." >&2
      else
	 echo "  Error: $jid: $tmp_err"
      fi ;;
   esac
   #subjobs=$(echo "$stat" | grep 'Sub-jobs:' | sed -e 's/.*: *//')
   #if [[ "$subjobs" -gt 0 ]] ; then
   #   echo "$stat" | grep '^ *\(Sub-jobs\|Active\|Eligible\|Blocked\|Completed\):' | sed -e 's/^ *//' | sed -e 's/  *//' | tr '\n' ' ' | sed -e 's/^/    /'
   #   echo
   #fi
done
if [[ $job_c -gt 0 ]] ; then
   echo ""
   echo "  Completed since last check: $job_c."
fi
if [[ $job_r -gt 0 || $job_i -gt 0 ]] ; then
   echo ""
   echo "  Running jobs: $job_r."
   echo "  Idle jobs: $job_i."
fi
echo ""

# Auto-trials
echo "==[ Auto-trials ]=="
if [[ -e "$SCRATCH/etc/trials" ]] ; then
   trials=$(cat "$SCRATCH/etc/trials" | wc -l | sed -e 's/ //g')
   if [[ $trials -gt 1 ]] ; then
      echo "  $trials trials attempted:"
   else
      echo "  No recent failures in the current step, job launched:"
   fi
   cat "$SCRATCH/etc/trials" | sed -e 's/^/  o /' | sed -e 's/# $/No active trials\n/g'
fi
echo ""

# Step-specific checks:
echo "==[ Step summary ]=="
todo=1
if [[ -e "$SCRATCH/success/00" ]] ; then
   echo "  Successful project initialization."
   if [[ -e "$SCRATCH/success/01" ]] ; then
      echo "  Successful input preparation."
      if [[ -e "$SCRATCH/success/02" ]] ; then
	 echo "  Successful BLAST execution."
	 if [[ -e "$SCRATCH/success/02" ]] ; then
	    echo "  Successful concatenation."
	    echo "  Project finished successfully!"
	    todo=0
	 else
	    echo "  Concatenating results."
	 fi
      else
	 echo "  Running BLAST."
      fi
   else
      echo "  Preparing input."
   fi
else
   echo "  Initializing project."
fi

if [[ "$todo" -eq 1 && $job_r -eq 0 && $job_i -eq 0 ]] ; then
   echo "  Job currently paused. To resume, execute:"
   echo "  $PDIR/RUNME.bash $PROJ run"
fi
echo

# Entire log
echo "==[ Complete log ]=="
for i in $(ls $SCRATCH/log/status/* 2>/dev/null) ; do
   cat "$i" | sed -e "s/^/  $(basename $i): /"
done
