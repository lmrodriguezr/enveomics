# blast.pbs pipeline
# Step 01 : Initialize input files

# 00. Read configuration
cd $SCRATCH ;
TASK="dry" ;
source "$PDIR/RUNME.bash" ;

if [[ ! -e "$SCRATCH/success/01.01" ]] ; then
   # 01. BEGIN
   REGISTER_JOB "01" "01" "Custom BEGIN function" \
      && BEGIN \
      || exit 1 ;
   touch "$SCRATCH/success/01.01" ;
fi

if [[ ! -e "$SCRATCH/success/01.02" ]] ; then
   # 02. Split
   [[ -d "$SCRATCH/tmp/split" ]] && rm -R "$SCRATCH/tmp/split" ;
   REGISTER_JOB "01" "02" "Splitting query files" \
      && mkdir "$SCRATCH/tmp/split" \
      && "$PDIR/FastA.split.pl" "$INPUT" "$SCRATCH/tmp/split/$PROJ" "$MAX_JOBS" \
      || exit 1 ;
   touch "$SCRATCH/success/01.02" ;
fi ;

if [[ ! -e "$SCRATCH/success/01.03" ]] ; then
   # 03. Finalize
   REGISTER_JOB "01" "03" "Finalizing input preparation" && \
      mv "$SCRATCH/tmp/split" "$SCRATCH/tmp/in" \
      || exit 1 ;
   echo "msub -q '$QUEUE' -l 'walltime=$MAX_H:00:00,mem=$RAM,nodes=1:ppn=$PPN' \\
      -v '$MINVARS' -N '$PROJ-02' -t '$PROJ-02[1-$MAX_JOBS]' '$PDIR/02.pbs.bash'|tr -d '\\n'" \
      > "$SCRATCH/etc/02.bash" \
      || exit 1 ;
   touch "$SCRATCH/success/01.03" ;
fi ;

"$PDIR/RUNME.bash" "$PROJ" run || exit 1 ;

