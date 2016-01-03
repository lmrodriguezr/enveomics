#!/usr/bin/env Rscript
#
# @author  Luis M. Rodriguez-R
# @update  Dec-29-2015
# @license artistic license 2.0
#

#= Load stuff
args <- commandArgs(trailingOnly = F)  
enveomics_R <- file.path(dirname(
   sub("^--file=", "", args[grep("^--file=", args)])),
   "lib", "enveomics.R")
source(file.path(enveomics_R, "R", "cliopts.R"))
source(file.path(enveomics_R, "R", "barplot.R"))

#= Generate interface
opt <- enve.cliopts(enve.barplot,
   file.path(enveomics_R, "man", "enve.barplot.Rd"),
   positional_arguments=c(1,3),
   usage="usage: %prog [options] output.pdf [width height]",
   mandatory=c("x"), vectorize=c("sizes","order","col"),
   number=c("sizes","order"),
   o_desc=list(x="A tab-delimited file containing header (first row) and row names (first column)."))

#= Run it!
args = as.list(opt$args)
for(i in 2:3) if(length(args)>=i) args[[i]] <- as.numeric(args[[i]])
do.call("pdf", args)
do.call("enve.barplot", opt$options)
dev.off()
