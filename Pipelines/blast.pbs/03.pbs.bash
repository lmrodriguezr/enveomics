# blast.pbs pipeline
# Step 03 : Finalize

# Read configuration
cd $SCRATCH ;
TASK="dry" ;
source "$PDIR/RUNME.bash" ;
PREFIX="$SCRATCH/results/$PROJ" ;
OUT="$SCRATCH/$PROJ.blast" ;
echo "$PBS_JOBID" > "$SCRATCH/success/02.00" ;

# 01. END
if [[ ! -e "$SCRATCH/success/03.01" ]] ; then
   REGISTER_JOB "03" "01" "Custom END function" \
      && END "$PREFIX" "$OUT" \
      || exit 1 ;
   touch "$SCRATCH/success/03.01" ;
fi ;

JOB_DONE "03" ;

