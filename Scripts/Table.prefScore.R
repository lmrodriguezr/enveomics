#!/usr/bin/env Rscript

#= Load stuff
args <- commandArgs(trailingOnly = FALSE)  
enveomics_R <- file.path(
  dirname(sub('^--file=', '', args[grep('^--file=', args)])),
  'lib',
  'enveomics.R'
)
for(file in c('cliopts.R','utils.R','prefscore.R'))
  source(file.path(enveomics_R, 'R', file))

#= Generate interface
opt <- enve.cliopts(
  enve.prefscore,
  file.path(enveomics_R, 'man', 'enve.prefscore.Rd'),
  positional_arguments = c(1, 4),
  usage = 'usage: %prog [options] output.tsv [output.pdf [width height]]',
  mandatory = c('x', 'set'),
  number = c('signif.thr'),
  ignore = c('plot'),
  o_desc = list(
    x = 'A tab-delimited table of presence/absence (1/0) with species as rows and samples as columns.',
    set = 'A list of sample names that constitute the test set, one per line',
    ignore = 'A list of species to exclude from the analysis, one per line'
  )
)

#= Set output files
opt$options[['x']] <- read.table(
  opt$options[['x']],
  header = TRUE,
  row.names = 1,
  sep = '\t'
)
opt$options[['set']] <- read.table(
  opt$options[['set']],
  header = FALSE,
  sep = '\t',
  as.is = TRUE
)[,1]
if(!is.null(opt$options[['ignore']]))
  opt$options[['ignore']] <- read.table(
    opt$options[['ignore']],
    header = FALSE,
    sep = '\t',
    as.is = TRUE
  )[,1]
if(length(opt$args) > 1) {
  args <- as.list(opt$args[-1])
  for(i in 2:3) if(length(args) >= i) args[[i]] <- as.numeric(args[[i]])
  do.call('pdf', args)
} else {
  opt$options[['plot']] <- FALSE
}

#= Run it!
y <- do.call('enve.prefscore', opt$options)
write.table(y, opt$args[1], quote = FALSE, sep = '\t', col.names = FALSE)
if(length(opt$args)>1) ttt <- dev.off()
