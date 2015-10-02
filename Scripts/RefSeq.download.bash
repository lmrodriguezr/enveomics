#!/bin/bash

#
# @author  Luis M. Rodriguez-R
# @update  Oct-02-2015
# @license artistic license 2.0
#

FTP="ftp://ftp.ncbi.nlm.nih.gov/genomes/refseq/bacteria"
ORG=$1
EXT=${2:-.*.gz}
STT=${3:-Any}

if [[ "$ORG" == "" ]] ; then
echo "
Downloads a collection of sequences and/or annotations from NCBI's RefSeq.

Usage:
$0 <organism> [<extension>[ <level>]]

<organism>	The organism to download (e.g., Streptococcus_pneumoniae).
<extension>	Extension to download.  Common extensions include '.fna.gz'
		(genomic sequences), '.faa.gz' (protein sequences), and
		'.gff.gz' (annotations).  By default: '.*.gz' (all data).
<level>		Use only genomes with this assembly level. Common levels are
		'Complete Genome' and 'Contig'.  By default, any assembly
		level is allowed ('Any').
" >&2
exit
fi

[[ -d "$ORG" ]] || mkdir "$ORG"

curl "$FTP/$ORG/assembly_summary.txt" -o "$ORG/assembly_summary.txt"
for path in $(cat "$ORG/assembly_summary.txt" \
      | awk -F"\t" "\$12==\"$STT\" || \"$STT\"==\"Any\" {print \$20}" ) ; do
   dir="$ORG/$(basename "$path")"
   [[ -d "$dir" ]] || mkdir "$dir"
   for file in $(curl -s "$path/" | awk '{print $9}') ; do
      if [[ "$file" == $EXT ]] ; then
	 curl "$path/$file" -o "$dir/$file"
      fi
   done
done

