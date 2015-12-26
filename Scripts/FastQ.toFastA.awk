#!/usr/bin/env awk -f
#
# @author  Luis M. Rodriguez-R
# @update  Dec-26-2015
# @license artistic license 2.0
#

BEGIN {
  for (i = 0; i < ARGC; i++) {
     if(ARGV[i] == "--help"){
       print "Description:\n"
       print "  Translates FastQ files into FastA.\n"
       print "Usage:\n"
       print "  FastQ.toFastA.awk < in.fq > out.fa\n"
       exit
     }
  }
}

NR%4 == 1, NR%4 == 2 {
   if(NR%4 == 1){ gsub(/^@/,">") }
   print $0
}

