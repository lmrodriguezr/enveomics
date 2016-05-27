#!/bin/bash

##################### VARIABLES
# Find the directory of the pipeline
if [[ "$PDIR" == "" ]] ; then PDIR=$(dirname $(readlink -f $0)); fi ;
CWD=$(pwd)

# Load config
if [[ "$PROJ" == "" ]] ; then PROJ="$1" ; fi
if [[ "$TASK" == "" ]] ; then TASK="$2" ; fi
if [[ "$TASK" == "" ]] ; then TASK="check" ; fi
NAMES=$(ls $PDIR/CONFIG.*.bash | sed -e 's/.*CONFIG\./    o /' | sed -e 's/\.bash//');
if [[ "$PROJ" == "" ]] ; then
   if [[ "$HELP" == "" ]] ; then
      echo "
Usage:
   $0 name task
   
   name	The name of the run.  CONFIG.name.bash must exist.
   task	The action to perform.  One of:
	o run: Executes the BLAST.
	o check: Indicates the progress of the task (default).
	o pause: Cancels running jobs (resume using run).
	o dry: Checks that the parameters are correct, but doesn't run.
	o eo: Review all eo files produced in the project.

   See $PDIR/README.md for more information.
   
   Available names are:
$NAMES
" >&2
   else
      echo "$HELP   
   Available names are:
$NAMES
" >&2
   fi
   exit 1
fi
if [[ ! -e "$PDIR/CONFIG.$PROJ.bash" ]] ; then
   echo "$0: Error: Impossible to find $PDIR/CONFIG.$PROJ.bash, available names are:
$NAMES" >&2
   exit 1
fi
source "$PDIR/CONFIG.$PROJ.bash" ;
SCRATCH="$SCRATCH_DIR/$PROJ" ;
MINVARS="PDIR=$PDIR,SCRATCH=$SCRATCH,PROJ=$PROJ" ;
case $QUEUE in
bioforce-6)
   MAX_H=120 ;;
iw-shared-6)
   MAX_H=12 ;;
micro-largedata)
   MAX_H=120 ;;
biocluster-6 | biohimem-6 | microcluster)
   MAX_H=240 ;;
*)
   echo "Unrecognized queue: $QUEUE." >&2 ;
   exit 1 ;;
esac ;

##################### FUNCTIONS
function REGISTER_JOB {
   local STEP=$1
   local SUBSTEP=$2
   local MESSAGE=$3
   local JOBID=$4

   if [[ "$JOBID" != "" ]] ; then
      MESSAGE="$MESSAGE [$JOBID]" ;
      echo "$STEP: $SUBSTEP: $(date)" >> "$SCRATCH/log/active/$JOBID" ;
   fi
   echo "$MESSAGE." >> "$SCRATCH/log/status/$STEP" ;
}

function LAUNCH_JOB {
   local STEP=$1
   local SUBSTEP=$2
   local MESSAGE=$3
   local BASHFILE=$4
   
   cd "$SCRATCH/log/eo" ;
   date >> "$SCRATCH/etc/trials" ;
   source "$BASHFILE" || exit 1 ;
   cd $CWD ;
   if [[ "$SENTINEL_JOBID" != "" ]] ; then
      REGISTER_JOB "$STEP" "$SUBSTEP" "Guarding job $NEW_JOBID" "$SENTINEL_JOBID" ;
   fi ;
   REGISTER_JOB "$STEP" "$SUBSTEP" "$MESSAGE" "$NEW_JOBID" ;
   echo $NEW_JOBID ;
}

function JOB_DONE {
   STEP=$1

   echo "Done." >> "$SCRATCH/log/status/$STEP" ;
   touch "$SCRATCH/success/$STEP" ;
   echo -n '# ' > "$SCRATCH/etc/trials" ;
}

##################### RUN
# Execute task
if [[ ! -e "$PDIR/TASK.$TASK.bash" ]] ; then
   echo "Unrecognized task: $TASK." >&2 ;
   exit 1 ;
else
   source "$PDIR/TASK.$TASK.bash"
fi

