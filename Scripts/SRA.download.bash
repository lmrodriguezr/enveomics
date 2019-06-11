#!/bin/bash

#
# @author  Luis M. Rodriguez-R
# @license artistic license 2.0
#

DATA_LINK="https://www.ebi.ac.uk/ena/data/warehouse/filereport"
DATA_OPS="result=read_run&fields=run_accession,fastq_ftp,fastq_md5"
SRX=$1
DIR=${2:-$SRX}

if [[ "$SRX" == "" ]] ; then
echo "
Downloads the set of runs from a project, sample, or experiment in SRA.

Usage:
$0 <SRA-ID>[ <dir>]

<SRA-ID>	ID of the SRA Project, Sample, or Experiment.
<dir>		Directory where the files are to be downladed. By default,
		same as <SRA-ID>.
" >&2
exit
fi

[[ -d "$DIR" ]] || mkdir "$DIR"

function md5value {
  local file=$1
  o=$(md5 "$file" | perl -pe 's/.* //')
  [[ -n $o ]] || o=$(md5sum-lite "$file" | awk '{print $1}')
  [[ -n $o ]] || o=$(md5sum "$file" | awk '{print $1}')
  echo "$o"
}

curl -s "$DATA_LINK?$DATA_OPS&accession=$SRX" -o "$DIR/srr_list.txt"
tail -n +2 "$DIR/srr_list.txt" | while read ln ; do
  srr=$(echo "$ln"|cut -f 1)
  ftp=$(echo "$ln"|cut -f 2)
  md5=$(echo "$ln"|cut -f 3)
  dir="$DIR/$srr"
  [[ -d "$dir" ]] || mkdir "$dir"
  echo "o $srr" >&2
  for uri in $(echo "$ftp" | tr ";" " ") ; do
    file="$dir/$(basename $uri)"
    curl "$uri" -o "$file"
    md5obs=$(md5value "$file" 2> /dev/null)
    if [[ "$md5" == "$md5obs"* ]] ; then
      md5=$(echo "$md5" | perl -pe 's/^[^;]+;//')
    else
      echo "Corrupt file: $file" >&2
      echo "  MD5 mismatch: $md5obs not in $md5" >&2
      exit 1;
    fi
  done
done
