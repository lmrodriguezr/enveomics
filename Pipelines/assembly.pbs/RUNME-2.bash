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
  KMERARRAY="21,23,25,27,29,31,33,35,37,39,41,43,45,47,49,51,53,55,57,59,61,63"
else
  KMERARRAY=$3
fi
if [[ "$VELVETSIM" == "" ]] ; then
  VELVETSIM=22
fi
if [[ "$SOAPSIM" == "" ]] ; then
  let SOAPSIM=130/$PPN
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
  VARS="LIB=$LIB,PDIR=$PDIR,DATA=$DATA,USECOUPLED=$USECOUPLED,USESINGLE=$USESINGLE"
  [[ -n $INSLEN ]] && VARS="$VARS,INSLEN=$INSLEN"
  [[ -n $VELVETG_EXTRA ]] && VARS="$VARS,VELVETG_EXTRA=$VELVETG_EXTRA"
  [[ -n $VELVETH_EXTRA ]] && VARS="$VARS,VELVETH_EXTRA=$VELVETH_EXTRA"
  [[ -n $CLEANUP ]] && VARS="$VARS,CLEANUP=$CLEANUP"
  let SIZE=$(ls -lH "$INPUT" | awk '{print $5}')/1024/1024/1024;
  let RAMS=40+$SIZE*10*$RAMMULT;
  let RAMV=50+$SIZE*15*$RAMMULT;
  # Launch Velvet
  if [[ "$RUNVELVET" == "yes" ]] ; then
    NAME="velvet_${LIB}"
    if [[ "$QUEUE" != "" ]]; then
      qsub "$PDIR/velvet.pbs" -v "$VARS" -d "$SCRATCH" -N "$NAME" \
          -l mem=${RAMV}gb -l "walltime=$WTIME" -q "$QUEUE" \
          -t "$KMERARRAY%$VELVETSIM"
    elif [[ $RAMV -gt 150 ]]; then
      qsub "$PDIR/velvet.pbs" -v "$VARS" -d "$SCRATCH" -N "$NAME" \
          -l mem=${RAMV}gb -l walltime=360:00:00 -q biohimem-6 \
          -t "$KMERARRAY%$VELVETSIM"
    elif [[ $SIZE -lt 6 ]]; then
      qsub "$PDIR/velvet.pbs" -v "$VARS" -d "$SCRATCH" -N "$NAME" \
          -l mem=${RAMV}gb -l walltime=12:00:00 -q iw-shared-6 \
          -t "$KMERARRAY%$VELVETSIM"
    elif [[ $SIZE -lt 20 ]]; then
      qsub "$PDIR/velvet.pbs" -v "$VARS" -d "$SCRATCH" -N "$NAME" \
          -l mem=${RAMV}gb -l walltime=120:00:00 -q bioforce-6 \
          -t "$KMERARRAY%$VELVETSIM"
    else
      qsub "$PDIR/velvet.pbs" -v "$VARS" -d "$SCRATCH" -N "$NAME" \
          -l mem=${RAMV}gb -l walltime=360:00:00 -q biocluster-6 \
          -t "$KMERARRAY%$VELVETSIM"
    fi
  fi
  # Launch SOAP
  if [[ "$RUNSOAP" == "yes" ]] ; then
    NAME="soap_${LIB}"
    if [[ "$QUEUE" != "" ]]; then
      qsub "$PDIR/soap.pbs" -v "$VARS" -d "$SCRATCH" -N "$NAME" \
          -l mem=${RAMS}gb -l walltime=$WTIME -q $QUEUE -l nodes=1:ppn=$PPN \
          -t "$KMERARRAY%$SOAPSIM"
    elif [[ $RAMS -gt 150 ]]; then
      qsub "$PDIR/soap.pbs" -v "$VARS" -d "$SCRATCH" -N "$NAME" \
          -l mem=${RAMS}gb -l walltime=48:00:00 -q biohimem-6 \
          -l nodes=1:ppn=$PPN -t "$KMERARRAY%$SOAPSIM"
    else
      qsub "$PDIR/soap.pbs" -v "$VARS" -d "$SCRATCH" -N "$NAME" \
          -l mem=${RAMS}gb -l walltime=12:00:00 -q iw-shared-6 \
          -l nodes=1:ppn=$PPN -t "$KMERARRAY%$SOAPSIM"
    fi
  fi
done

