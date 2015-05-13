#!/usr/bin/env awk -f
#
# @author: Luis M. Rodriguez-R
# @update: May-10-2015
# @license: artistic license 2.0
#

NR%4 == 1, NR%4 == 2 {
   if(NR%4 == 1){ gsub(/^@/,">") }
   print $0
}

