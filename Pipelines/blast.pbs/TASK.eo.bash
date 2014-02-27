#!/bin/bash

##################### RUN
# Check if it was sourced from RUNME.bash
if [[ "$PDIR" == "" ]] ; then
   echo "$0: Error: This file is not stand-alone." >&2
   echo "  Execute RUNME.bash as described in the README.txt file" >&2 ;
   exit 1 ;
fi ;

# Check if the project exists
if [[ ! -d "$SCRATCH" ]] ; then
   echo "The project $PROJ doesn't exist at $SCRATCH_DIR." >&2 ;
   echo "  Execute '$PDIR/RUNME.bash $PROJ run' first." >&2 ;
   exit 1 ;
fi ;

# Review errors
(echo -e "==[ Last 10 lines of all e files ]==\nPress q to exit\n" ; tail -n 10 $SCRATCH/log/eo/*.e* ) | less
# Review output
(echo -e "==[ Last 100 lines of all o files ]==\nPress q to exit\n" ; tail -n 100 $SCRATCH/log/eo/*.o* ) | less

