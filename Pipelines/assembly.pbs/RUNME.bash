#!/bin/bash

##################### RUN
# Check if it was sourced from RUNME-*.bash
if [[ "$PDIR" == "" ]] ; then
   echo "$0: Error: This file is not stand-alone.  Execute one of RUNME-*.bash as described in the README.txt file" >&2
   exit 1
fi

# Find the directory of the pipeline
CWD=$(pwd)
PDIR=$(dirname $(readlink -f $0));

# Run it
# Actually, this script doesn't run anything.  It's meant to keep the
# variables centralized.

# Load config
NAMES=$(ls $PDIR/CONFIG.*.bash | sed -e 's/.*CONFIG\./    * /' | sed -e 's/\.bash//');
if [[ "$1" == "" ]] ; then
   if [[ "$HELP" == "" ]] ; then
      echo "
Usage:
   $0 name
   
   name		The name of the run.  CONFIG.name.bash must exist.
   
   See $PDIR/README.txt for more information.
   
   Available names are:
$NAMES
" >&2
   else
      echo "$HELP   
   Available names are:
$NAMES
" >&2
   fi
   exit 1
fi
if [[ ! -e "$PDIR/CONFIG.$1.bash" ]] ; then
   echo "$0: Error: Impossible to find $PDIR/CONFIG.$1.bash, available names are:
$NAMES" >&2
   exit 1
fi
source "$PDIR/CONFIG.$1.bash"

# Create the scratch directory
if [[ ! -d $SCRATCH ]] ; then mkdir -p $SCRATCH ; fi;

