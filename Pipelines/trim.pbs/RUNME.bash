#!/bin/bash

if [[ "$1" == "" || "$1" == "-h" ]] ; then
   echo "
   Usage: ./RUNME.bash folder [clipper [max_jobs]]

   folder	Path to the folder containing the raw reads. The raw reads must be in FastQ format,
   		and filenames must follow the format: <name>.<sis>.fastq, where <name> is the name
		of the sample, and <sis> is 1 or 2 indicating which sister read the file contains.
		Use only '1' as <sis> if you have single reads.
   clipper	(optional) One of: trimmomatic, scythe, or none. By default: scythe.
   max_jobs	(optional) Maximum number of jobs to run in parallel. This number can be increased,
   		but bear in mind that this process is highly I/O-intensive, and likely to crash or
		significantly slow down the hard drive if many jobs are running simultaneously. By
		default: 5.
   " >&2 ;
   exit 1 ;
fi ;
CLIPPER=$2
if [[ "$CLIPPER" == "" ]] ; then
   CLIPPER="scythe"
fi ;
if [[ "$3" == "" ]] ; then
   MAX=5 ;
else
   let MAX=$3+0 ;
fi ;

dir=$(readlink -f $1) ;
pac=$(dirname $(readlink -f $0)) ;
cwd=$(pwd) ;

cd $dir ;
for i in 01.raw_reads 02.trimmed_reads 03.read_quality 04.trimmed_fasta zz.info ; do
   if [[ ! -d $i ]] ; then mkdir $i ; fi ;
done ;

k=0 ;
for i in $dir/*.1.fastq ; do
   EXTRA="" ;
   EXTRA_MSG="" ;
   if [[ $k -ge $MAX ]] ; then
      let prek=$k-$MAX ;
      EXTRA="-W depend=afterany:${jids[$prek]}" ;
      EXTRA_MSG=" (waiting for ${jids[$prek]})"
   fi ;
   b=$(basename $i .1.fastq) ;
   mv $b.[12].fastq 01.raw_reads/ ;
   # Predict time (in hours)
   SIZE_M=$(($(ls -pl 01.raw_reads/$b.1.fastq | awk '{print $5}')/1000000)) ;
   let TIME_H=$SIZE_M*5/1000 ;
   [[ -e 01.raw_reads/$b.2.fastq ]] || let TIME_H=$TIME_H/2 ;
   let RAM_G=$SIZE_M*8/1000 ;
   [[ $RAM_G -lt 10 ]] && RAM_G=10 ;
   
   # Find the right queue
   if [[ $TIME_H -lt 12 ]] ; then
      QUEUE="-q iw-shared-6 -l walltime=12:00:00" ;
   elif [[ $TIME_H -lt 120 ]] ; then
      QUEUE="-q microcluster -l walltime=120:00:00" ;
   else
      QUEUE="-q microcluster -l walltime=2000:00:00" ;
   fi ;
   # Launch job
   jids[$k]=$(qsub -v "SAMPLE=$b,FOLDER=$dir,CLIPPER=$CLIPPER" -N "Trim-$b" -l "mem=${RAM_G}g" $QUEUE $EXTRA $pac/run.pbs | grep .) ;
   echo "$b: ${jids[$k]}$EXTRA_MSG" ;
   let k=$k+1 ;
done ;


