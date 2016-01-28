# blast.pbs pipeline
# Step 02 : Run BLAST

# Read configuration
cd $SCRATCH ;
TASK="dry" ;
source "$PDIR/RUNME.bash" ;

# 00. Initial vars
ID_N=$PBS_ARRAYID
[[ "$ID_N" == "" ]] && exit 1 ;
[[ -e "$SCRATCH/success/02.$ID_N" ]] && exit 0 ;
IN="$SCRATCH/tmp/in/$PROJ.$ID_N.fa" ;
OUT="$SCRATCH/tmp/out/$PROJ.blast.$ID_N" ;
FINAL_OUT="$SCRATCH/results/$PROJ.$ID_N.blast" ;
if [[ -e "$SCRATCH/success/02.$ID_N.00" ]] ; then
   pre_job=$(cat "$SCRATCH/success/02.$ID_N.00") ;
   state=$(qstat -f "$pre_job" 2>/dev/null | grep job_state | sed -e 's/.*= //')
   if [[ "$state" == "R" ]] ; then
      echo "Warning: This task is already being executed by $pre_job. Aborting." >&2 ;
      exit 0 ;
   elif [[ "$state" == "" ]] ; then
      echo "Warning: This task was initialized by $pre_job, but it's currently not running. Superseding." >&2 ;
   fi ;
fi
echo "$PBS_JOBID" > "$SCRATCH/success/02.$ID_N.00" ;

# 01. Before BLAST
if [[ ! -e "$SCRATCH/success/02.$ID_N.01" ]] ; then
   BEFORE_BLAST "$IN" "$OUT" || exit 1 ;
   touch "$SCRATCH/success/02.$ID_N.01" ;
fi ;

# 02. Run BLAST
if [[ ! -e "$SCRATCH/success/02.$ID_N.02" ]] ; then
   # Recover previous runs, if any
   if [[ -s "$OUT" ]] ; then
      perl "$PDIR/BlastTab.recover_job.pl" "$IN" "$OUT" \
	 || exit 1 ;
   fi ;
   # Run BLAST
   RUN_BLAST "$IN" "$OUT" \
      && mv "$OUT" "$OUT-z" \
      || exit 1 ;
   touch "$SCRATCH/success/02.$ID_N.02" ;
fi ;

# 03. Collect BLAST parts
if [[ ! -e "$SCRATCH/success/02.$ID_N.03" ]] ; then
   if [[ -e "$OUT" ]] ; then
      echo "Warning: The file $OUT pre-exists, but the BLAST collection was incomplete." >&2 ;
      echo "  I'm assuming that it corresponds to the first part of the result, but you should check manually." >&2 ;
      echo "  The last lines are:" >&2 ;
      tail -n 3 "$OUT" >&2 ;
   else
      touch "$OUT" || exit 1 ;
   fi ;
   for i in $(ls $OUT-*) ; do
      cat "$i" >> "$OUT" ;
      rm "$i" || exit 1 ;
   done ;
   mv "$OUT" "$FINAL_OUT"
   touch "$SCRATCH/success/02.$ID_N.03" ;
fi ;

# 04. After BLAST
if [[ ! -e "$SCRATCH/success/02.$ID_N.04" ]] ; then
   AFTER_BLAST "$IN" "$FINAL_OUT" || exit 1 ;
   touch "$SCRATCH/success/02.$ID_N.04" ;
fi ;

touch "$SCRATCH/success/02.$ID_N" ;

