#!/usr/bin/env Rscript

# @author  Luis M. Rodriguez-R
# @license Artistic-2.0

#= Load stuff
suppressPackageStartupMessages(library(enveomics.R))
args <- commandArgs(trailingOnly = FALSE)
enveomics_R <- file.path(
  dirname(sub("^--file=", "", args[grep("^--file=", args)])),
  "..", "enveomics.R"
)

#= Generate interface
opt <- enve.cliopts(enve.recplot2,
  file.path(enveomics_R, "man", "enve.recplot2.Rd"),
  positional_arguments=c(1,4),
  usage="usage: %prog [options] output.Rdata [output.pdf [width height]]",
  mandatory=c("prefix"),
  o_desc=list(pos.breaks="Breaks in the positions histogram.",
    pos.breaks.tsv="File with (absolute) coordinates of breaks in the position histogram",
    id.breaks="Breaks in the identity histogram.",
    id.summary="Function summarizing the identity bins. By default: sum.",
    peaks.col="Color of peaks, mandatory for peak-finding (e.g., darkred).",
    peaks.method="Method to detect peaks; one of emauto, em, or mower."),
  p_desc=paste("","Produce recruitment plot objects provided that",
    "BlastTab.catsbj.pl has been previously executed.", sep="\n\t"),
  ignore=c("plot"),
  defaults=c(pos.breaks.tsv=NA, id.metric="identity", peaks.col=NA,
    peaks.method="emauto"))

#= Run it!
if(length(opt$args)>1){
  args = as.list(opt$args[-1])
  for(i in 2:3) if(length(args)>=i) args[[i]] <- as.numeric(args[[i]])
  do.call("pdf", args)
}else{
  opt$options[["plot"]] <- FALSE
}
pc <- opt$options[["peaks.col"]]
if(!is.na(pc) && pc=="NA") opt$options[["peaks.col"]] <- NA
if(!is.null(opt$options[["peaks.method"]])){
  opt$options[["peaks.opts"]] <- list(method=opt$options[["peaks.method"]])
  opt$options[["peaks.method"]] <- NULL
}
rp <- do.call("enve.recplot2", opt$options)
save(rp, file=opt$args[1])
if(length(opt$args)>1) dev.off()

