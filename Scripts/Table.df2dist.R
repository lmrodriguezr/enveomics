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
source(file.path(enveomics_R, "R", "cliopts.R"))
source(file.path(enveomics_R, "R", "df2dist.R"))

#= Generate interface
opt <- enve.cliopts(enve.df2dist,
   file.path(enveomics_R, "man", "enve.df2dist.Rd"),
   positional_arguments=1,
   usage="usage: %prog [options] output.mat",
   mandatory=c("x"),
   number=c("default.d", "max.sim"),
   o_desc=list(x="A tab-delimited table with the distances."),
   p_desc="Transform a tab-delimited list of distances into a squared matrix.")

#= Run it!
opt$options[['x']] <- read.table(opt$options[['x']],
   header=TRUE, sep="\t", as.is=TRUE)
dist <- do.call("enve.df2dist", opt$options)
write.table(as.matrix(dist), opt$args[1], quote=FALSE, sep="\t", col.names=NA)
