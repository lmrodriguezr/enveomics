#!/bin/bash

if [[ "$1" == "" ]] ; then
   echo "
   Usage: ./RUNME.bash folder [max_jobs]

   folder	Path to the folder containing the raw reads. The raw reads must be in FastQ format,
   		and filenames must follow the format: <name>.<sis>.fastq, where <name> is the name
		of the sample, and <sis> is 1 or 2 indicating which sister read the file contains.
		Use only '1' as <sis> if you have single reads.
   max_jobs	(optional) Maximum number of jobs to run in parallel. This number can be increased,
   		but bear in mind that this process is highly I/O-intensive, and likely to crash or
		significantly slow down the hard drive if many jobs are running simultaneously. By
		default: 5.
   " >&2 ;
   exit 1 ;
fi ;
if [[ "$2" == "" ]] ; then
   MAX=5 ;
else
   let MAX=$2+0 ;
fi ;

dir=$(readlink -f $1) ;
pac=$(dirname $(readlink -f $0)) ;
cwd=$(pwd) ;

cd $dir ;
mkdir 01.raw_reads 02.trimmed_reads 03.read_quality 04.trimmed_fasta 05.assembly ;

k=0 ;
for i in $dir/*.1.fastq ; do
   EXTRA="" ;
   if [[ $k -ge $MAX ]] ; then
      let prek=$k-$MAX ;
      EXTRA="-l depend=afterany:${jids[$prek]}" ;
   fi ;
   b=$(basename $i .1.fastq) ;
   mv $b.[12].fastq 01.raw_reads/ ;
   jids[$k]=$(msub -v "SAMPLE=$b,FOLDER=$dir" $pac/run.pbs $EXTRA | grep .) ;
   echo "$b: ${jids[$k]}" ;
   let k=$k+1 ;
done ;


