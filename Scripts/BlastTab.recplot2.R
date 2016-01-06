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
opt <- enve.cliopts(enve.recplot2,
   file.path(enveomics_R, "man", "enve.recplot2.Rd"),
   positional_arguments=c(1,4),
   usage="usage: %prog [options] output.Rdata [output.pdf [width height]]",
   mandatory=c("prefix"),
   o_desc=list(pos.breaks="Breaks in the positions histogram.",
     id.breaks="Breaks in the identity histogram.",
     id.summary="Function summarizing the identity bins. By default: sum."),
   p_desc=paste("","Produce recruitment plot objects provided that",
     "BlastTab.catsbj.pl has been previously executed.", sep="\n\t"),
   ignore=c("plot"),

   defaults=c(id.metric="identity"))

#= Run it!
if(length(opt$args)>1){
   args = as.list(opt$args[-1])
   for(i in 2:3) if(length(args)>=i) args[[i]] <- as.numeric(args[[i]])
   do.call("pdf", args)
}else{
   opt$options[["plot"]] <- FALSE
}
rp <- do.call("enve.recplot2", opt$options)
save(rp, file=opt$args[1])
if(length(opt$args)>1) dev.off()
