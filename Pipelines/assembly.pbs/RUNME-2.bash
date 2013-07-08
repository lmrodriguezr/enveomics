#!/bin/bash

##################### HELP
HELP="
Usage:
   $0 name[ prog[ k-mers]]
   
   name		The name of the run.  CONFIG.name.bash must exist.
   prog		Program to execute.  One of 'soap' or 'velvet'.  By
   		default, it executes both.
   k-mers	Comma-separated list of k-mers to run.  By default,
   		it executes all the odd numbers between 21 and 63
		(inclusive).
   
   See $PDIR/README.txt for more information.
"
##################### RUN
# Find the directory of the pipeline
PDIR=$(dirname $(readlink -f $0));
# Load variables
source "$PDIR/RUNME.bash"
if [[ "$SCRATCH" == "" ]] ; then
   echo "$0: Error loading $PDIR/RUNME.bash, variable SCRATCH undefined" >&2
   exit 1
fi

# Check request
RUNVELVET=yes
RUNSOAP=yes
if [[ "$2" == "velvet" ]] ; then
   RUNSOAP=no
elif [[ "$2" == "soap" ]] ; then
   RUNVELVET=no
fi
if [[ "$3" == "" ]] ; then
   KMERARRAY="21";
   for i in $(seq 11 31); do
      let k=$i*2+1
      KMERARRAY="$KMERARRAY,$k"
   done
else
   KMERARRAY=$3
fi

# Run it
RAMMULT=${RAMMULT:-1}
echo "Jobs being launched in $SCRATCH"
for LIB in $LIBRARIES; do
   # Prepare info
   echo "Running $LIB";
   if [[ "$USECOUPLED" == "yes" ]] ; then
      INPUT="$DATA/$LIB.CoupledReads.fa"
   elif [[ "$USESINGLE" == "yes" ]] ; then
      INPUT="$DATA/$LIB.SingleReads.fa"
   else
      echo "$0: Error: No task selected, neither USECOUPLED nor USESINGLE set to yes." >&2
      exit 1;
   fi
   VARS="LIB=$LIB,PDIR=$PDIR,DATA=$DATA,INSLEN=$INSLEN,USECOUPLED=$USECOUPLED,USESINGLE=$USESINGLE,VELVETG_EXTRA=$VELVETG_EXTRA,VELVETH_EXTRA=$VELVETH_EXTRA,CLEANUP=$CLEANUP"
   let SIZE=$(ls -lH "$INPUT" | awk '{print $5}')/1024/1024/1024;
   let RAMS=40+$SIZE*10*$RAMMULT;
   let RAMV=50+$SIZE*15*$RAMMULT;
   # Launch Velvet
   if [[ "$RUNVELVET" == "yes" ]] ; then
      NAME="velvet_${LIB}"
      if [[ "$QUEUE" -ne "" ]]; then
	 qsub "$PDIR/velvet.pbs" -v "$VARS" -d "$SCRATCH" -N "$NAME" -l mem=${RAMS}gb -l "walltime=$WTIME" -q "$QUEUE" -t $KMERARRAY
      elif [[ $RAMV -gt 150 ]]; then
	 qsub "$PDIR/velvet.pbs" -v "$VARS" -d "$SCRATCH" -N "$NAME" -l mem=${RAMS}gb -l walltime=360:00:00 -q biohimem-6 -t $KMERARRAY
      elif [[ $SIZE -lt 6 ]]; then
	 qsub "$PDIR/velvet.pbs" -v "$VARS" -d "$SCRATCH" -N "$NAME" -l mem=${RAMS}gb -l walltime=12:00:00 -q iw-shared-6 -t $KMERARRAY
      elif [[ $SIZE -lt 20 ]]; then
	 qsub "$PDIR/velvet.pbs" -v "$VARS" -d "$SCRATCH" -N "$NAME" -l mem=${RAMS}gb -l walltime=120:00:00 -q bioforce-6 -t $KMERARRAY
      else
	 qsub "$PDIR/velvet.pbs" -v "$VARS" -d "$SCRATCH" -N "$NAME" -l mem=${RAMS}gb -l walltime=360:00:00 -q biocluster-6 -t $KMERARRAY
      fi
   fi
   # Launch SOAP
   if [[ "$RUNSOAP" == "yes" ]] ; then
      NAME="soap_${LIB}"
      if [[ "$QUEUE" -ne "" ]]; then
	 qsub "$PDIR/soap.pbs" -v "$VARS" -d "$SCRATCH" -N "$NAME" -l mem=${RAMV}gb -l walltime=$WTIME -q $QUEUE -l nodes=1:ppn=$PPN -t $KMERARRAY
      elif [[ $RAMS -gt 150 ]]; then
	 qsub "$PDIR/soap.pbs" -v "$VARS" -d "$SCRATCH" -N "$NAME" -l mem=${RAMV}gb -l walltime=48:00:00 -q biohimem-6 -l nodes=1:ppn=$PPN -t $KMERARRAY
      else
	 qsub "$PDIR/soap.pbs" -v "$VARS" -d "$SCRATCH" -N "$NAME" -l mem=${RAMV}gb -l walltime=12:00:00 -q iw-shared-6 -l nodes=1:ppn=$PPN -t $KMERARRAY
      fi
   fi
done

