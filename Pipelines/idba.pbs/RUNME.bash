#!/bin/bash

if [[ "$1" == "" || "$1" == "-h" || "$2" == "" ]] ; then
   echo "
   Usage: ./RUNME.bash folder data_type [max_jobs]

   folder	Path to the folder containing the 04.trimmed_fasta folder. The
		trimmed reads must be in interposed FastA format, and filenames
		must follow the format: <name>.CoupledReads.fa, where <name> is
		the name of the sample. If non-paired, the filenames must follow
		the format: <name>.SingleReads.fa. If both suffixes are found
		for the same <name> prefix, they are both used.
   data_type	Type of datasets in the project. One of: mg (for metagenomes),
		scg (for single-cell genomes), g (for traditional genomes), or t
		(for transcriptomes).
   max_jobs	(optional) Maximum number of jobs to run in parallel. This
		number can be increased, but bear in mind that this process is
		highly I/O-intensive, and likely to crash or significantly slow
		down the hard drive if many jobs are running simultaneously. By
		default: 5.
   " >&2
   exit 1
fi
TYPE=$2
if [[ "$TYPE" != "g" && "$TYPE" != "mg" && "$TYPE" != "scg" \
		     && "$TYPE" != "t" ]] ; then
   echo "Unsupported data type: $TYPE." >&2
   exit 1
fi
if [[ "$3" == "" ]] ; then
   MAX=5
else
   let MAX=$3+0
fi

dir=$(readlink -f $1)
pac=$(dirname $(readlink -f $0))
cwd=$(pwd)

cd $dir
if [[ ! -e 04.trimmed_fasta ]] ; then
   echo "Cannot locate the 04.trimmed_fasta directory, aborting..." >&2
   exit 1
fi
for i in 05.assembly ; do
   [[ -d $i ]] || mkdir $i
done

k=0
for i in $dir/04.trimmed_fasta/*.SingleReads.fa ; do
   b=$(basename $i .SingleReads.fa)
   touch $dir/04.trimmed_fasta/$b.CoupledReads.fa
done

for i in $dir/04.trimmed_fasta/*.CoupledReads.fa ; do
   b=$(basename $i .CoupledReads.fa)
   [[ -d $dir/05.assembly/$b ]] && continue
   EXTRA=""
   EXTRA_MSG=""
   if [[ $k -ge $MAX ]] ; then
      let prek=$k-$MAX
      EXTRA="-W depend=afterany:${jids[$prek]}"
      EXTRA_MSG=" (waiting for ${jids[$prek]})"
   fi
   
   # Predict time (in hours)
   SIZE_M=$(($(ls -pl 04.trimmed_fasta/$b.CoupledReads.fa \
	       | awk '{print $5}')/1000000))
   let TIME_H=6+$SIZE_M*2/1000
   let RAM_G=20+$SIZE_M*20/1000
   
   # Find the right queue
   if [[ $TIME_H -lt 12 ]] ; then
      QUEUE="-q iw-shared-6 -l walltime=12:00:00"
   elif [[ $TIME_H -lt 120 ]] ; then
      QUEUE="-q microcluster -l walltime=120:00:00"
   else
      QUEUE="-q microcluster -l walltime=2000:00:00"
   fi
   
   # Launch job
   mkdir $dir/05.assembly/$b
   OPTS="SAMPLE=$b,FOLDER=$dir,TYPE=$TYPE"
   if [[ -s $dir/04.trimmed_fasta/$b.SingleReads.fa ]] ; then
      OPTS="$OPTS,FA=$dir/04.trimmed_fasta/$b.SingleReads.fa"
      [[ -s $dir/04.trimmed_fasta/$b.CoupledReads.fa ]] \
	 && OPTS="$OPTS,FA_RL2=$dir/04.trimmed_fasta/$b.CoupledReads.fa"
   else
      OPTS="$OPTS,FA=$dir/04.trimmed_fasta/$b.CoupledReads.fa"
   fi
   jids[$k]=$(qsub -v "$OPTS" -N "IDBA-$b" -l "mem=${RAM_G}g" \
	       $QUEUE $EXTRA $pac/run.pbs | grep .)
   echo "$b: ${jids[$k]}$EXTRA_MSG"
   let k=$k+1
done
