#!/usr/bin/env Rscript
#
# @author  Luis M. Rodriguez-R
# @update  Jan-04-2016
# @license artistic license 2.0
#

#= Load stuff
args <- commandArgs(trailingOnly = F)  
enveomics_R <- file.path(dirname(
   sub("^--file=", "", args[grep("^--file=", args)])),
   "lib", "enveomics.R")
library(methods)
source(file.path(enveomics_R, "R", "cliopts.R"))
source(file.path(enveomics_R, "R", "recplot2.R"))

#= Generate interface
opt <- enve.cliopts(enve.recplot2.compareIdentities,
   file.path(enveomics_R, "man", "enve.recplot2.compareIdentities.Rd"),
   positional_arguments=2,
   usage="usage: %prog [options] recplot-A.Rdata recplot-B.Rdata",
   number=c("pseudocounts", "max.deviation"), ignore=c("x", "y"),
   p_desc="Calculates the difference between identity distributions of two recruitment plots.")

#= Run it!
load(opt$args[1])
opt$options[['x']] <- rp
load(opt$args[2])
opt$options[['y']] <- rp
dist <- do.call("enve.recplot2.compareIdentities", opt$options)
cat(dist, '\n')

