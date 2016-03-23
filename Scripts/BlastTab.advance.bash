#!/bin/bash

#
# @author  Luis M. Rodriguez-R
# @update  Mar-23-2016
# @license artistic license 2.0
#

if [[ ! $2 ]] ; then
   echo "
.DESCRIPTION
   Calculates the percentage of a partial BLAST result. The
   value produced slightly subestimates the actual advance,
   due to un-flushed output and trailing queries that could
   be processed but generate no results.

.USAGE
   $0 blast.txt qry.fasta

   blast.txt	Incomplete Tabular BLAST output.
   qry.fasta	FastA file with query sequences.
";
   exit 1;
fi

if [[ ! -r $1 ]]; then
   echo "Cannot open file: $1";
   exit 1;
fi

if [[ ! -r $2 ]]; then
   echo "Cannot open file: $2";
   exit 1;
fi

LAST_Q=`tail -n 2 $1 | head -n 1 | awk '{print $1}'`
LAST_Q_NO=`grep -n "^>$LAST_Q\\( \\|$\\)" $2 | sed -e 's/:.*//'`
if [[ ! $LAST_Q_NO ]]; then
   echo "Cannot find sequence: $LAST_Q";
   echo "Make sure you are providing the right query file.";
   exit 1;
fi
TOTAL_Q_NO=`cat $2 | wc -l | sed -e 's/ *//'`
let PERC=100*$LAST_Q_NO/$TOTAL_Q_NO

echo "$PERC%: $LAST_Q_NO / $TOTAL_Q_NO"
exit 0;

