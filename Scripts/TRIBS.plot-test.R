#!/usr/bin/env Rscript
#
# @author  Luis M. Rodriguez-R
# @update  Jan-05-2016
# @license artistic license 2.0
#

#= Load stuff
suppressPackageStartupMessages(library(enveomics.R))
args <- commandArgs(trailingOnly = F)  
enveomics_R <- file.path(dirname(
   sub("^--file=", "", args[grep("^--file=", args)])),
   "lib", "enveomics.R")

#= Generate interface
opt <- enve.cliopts(plot.enve.TRIBStest,
   file.path(enveomics_R, "man", "plot.enve.TRIBStest.Rd"),
   positional_arguments=c(1,3),
   usage="usage: %prog [options] output.pdf [width height]",
   mandatory=c("x"),
   vectorize=c("xlim","ylim"),
   number=c("xlim","ylim"),
   defaults=c(type="overlap", xlim=NA, ylim=NA))

#= Run it!
a <- new.env()
load(opt$options[['x']], a)
opt$options[['x']] <- get(ls(envir=a),envir=a)
summary(opt$options[['x']])
if(is.na(opt$options[['xlim']][1])) opt$options[['xlim']] <- NULL
if(is.na(opt$options[['ylim']][1])) opt$options[['ylim']] <- NULL
args = as.list(opt$args)
for(i in 2:3) if(length(args)>=i) args[[i]] <- as.numeric(args[[i]])
do.call("pdf", args)
do.call("plot.enve.TRIBStest", opt$options)
dev.off()
