#!/usr/bin/env Rscript
#
# @author  Luis M. Rodriguez-R
# @update  Jan-07-2016
# @license artistic license 2.0
#

#= Load stuff
args <- commandArgs(trailingOnly = F)  
enveomics_R <- file.path(dirname(
   sub("^--file=", "", args[grep("^--file=", args)])),
   "lib", "enveomics.R")
source(file.path(enveomics_R, "R", "cliopts.R"))
source(file.path(enveomics_R, "R", "autoprune.R"))

#= Generate interface
opt <- enve.cliopts(enve.prune.dist,
   file.path(enveomics_R, "man", "enve.prune.dist.Rd"),
   positional_arguments=1,
   usage="usage: %prog [options] output.nwk",
   mandatory=c("t"),
   number=c("min_dist","order"),
   o_desc=list(t="A tree to prune in Newick format."))

#= Run it!
pt <- do.call("enve.prune.dist", opt$options)
ape::write.tree(pt, opt$args[1])
