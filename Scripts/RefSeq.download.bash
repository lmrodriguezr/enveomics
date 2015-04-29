#!/bin/bash

#
# @author: Luis M. Rodriguez-R
# @update: Apr-29-2015
# @license: artistic license 2.0
#

FTP="ftp://ftp.ncbi.nlm.nih.gov/genomes/refseq/bacteria"
ORG=$1
EXT=${2:-.*.gz}

if [[ "$ORG" == "" ]] ; then
   echo "
Downloads a collection of assemblies (or annotations) from NCBI's RefSeq.

Usage:
$0 <organism> [<extension>]

<organism>	The organism to download (e.g., Streptococcus_pneumoniae).
<extension>	Extension to download. By default: '.*.gz'.
" >&2
else
   wget -m "$FTP/$ORG/assembly_summary.txt"
   for i in $(curl -s "$FTP/$ORG/latest_assembly_versions/" | awk '{print $9}') ; do
      wget -m "$FTP/$ORG/latest_assembly_versions/$i/*$EXT"
   done
fi



