# blast.pbs pipeline
# Sentinel script

echo "Sentinel script after $AFTERJOB" ;

# Step-specific checks
if [[ "$STEP" == "02" ]] ; then
   # Read configuration
   cd $SCRATCH ;
   TASK="dry" ;
   source "$PDIR/RUNME.bash" ;
   
   # Check tasks
   INCOMPLETE=0;
   for i in $(seq 1 $MAX_JOBS) ; do
      if [[ ! -e "$SCRATCH/success/02.$i" ]] ; then
	 let INCOMPLETE=$INCOMPLETE+1 ;
      fi ;
   done
   if [[ $INCOMPLETE -eq 0 ]] ; then
      JOB_DONE "02" ;
   else
      echo "$INCOMPLETE incomplete jobs, re-launching step 02." ;
   fi ;
fi

# Continue the workflow
"$PDIR/RUNME.bash" "$PROJ" run || exit 1 ;

