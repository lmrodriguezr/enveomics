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
opt <- suppressWarnings(enve.cliopts(enve.tribs,
   file.path(enveomics_R, "man", "enve.tribs.Rd"),
   positional_arguments=c(0,2),
   usage="usage: %prog [options] [output.Rdata [bins=50]]",
   mandatory=c("dist", "selection"),
   defaults=c(dimensions=0, selection=NULL),
   ignore=c("metaMDS.opts","points","pre.tribs","subsamples"),
   o_desc=list(dist="A tab-delimited matrix of distances.",
      selection="A list of names with the selection to evaluate."),
   p_desc=paste("",
      "Estimates the empirical difference between all the distances",
      "in a set of objects and a subset, together with its statistical",
      "significance.",sep="\n\t")))

#= Run it!
opt$options[['dist']] <- as.dist(read.table(opt$options[['dist']],
   header=TRUE, sep="\t", row.names=1))
opt$options[['selection']] <- read.table(opt$options[['selection']],
   header=FALSE, sep="\t", as.is=TRUE)[,1]
if(opt$options[['dimensions']]==0) opt$options[['dimensions']] <- NULL
if(length(opt$args)>1) opt$options[['bins']] <- as.numeric(opt$args[2])
t <- do.call("enve.tribs.test", opt$options)
summary(t)
if(length(opt$args)>0) save(t, file=opt$args[1])
