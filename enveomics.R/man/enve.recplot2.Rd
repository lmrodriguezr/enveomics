\name{enve.recplot2}
\alias{enve.recplot2}
\title{enve recplot2}
\description{Produces recruitment plots provided that BlastTab.catsbj.pl has
been previously executed.}
\usage{enve.recplot2(prefix, plot = TRUE, pos.breaks = 1000, id.breaks = 300, 
    id.metric = c("identity", "corrected identity", "bit score"), 
    id.summary = sum, id.cutoff = 95, threads = 2, verbose = TRUE, 
    ...)}
\arguments{
  \item{prefix}{Path to the prefix of the BlastTab.catsbj.pl output files. At
least the files .rec and .lim must exist with this prefix.}
  \item{plot}{Should the object be plotted?}
  \item{pos.breaks}{Breaks in the positions histogram. It can also be a vector of break
points, and values outside the range are ignored. If zero (0), it
uses the sequence breaks as defined in the .lim file, which means
one bin per contig (or gene, if the mapping is agains genes).}
  \item{id.breaks}{Breaks in the identity histogram. It can also be a vector of break
points, and values outside the range are ignored.}
  \item{id.metric}{Metric of identity to be used (Y-axis). Corrected identity is only
supported if the original BLAST file included sequence lengths.}
  \item{id.summary}{Function summarizing the identity bins. Other recommended options
include: `median` to estimate the median instead of total bins, and
`function(x) mlv(x,method='parzen')$M` to estimate the mode.}
  \item{id.cutoff}{Cutoff of identity metric above which the hits are considered
'in-group'. The 95\% identity corresponds to the expectation of
ANI<95\% within species.}
  \item{threads}{Number of threads to use.}
  \item{verbose}{Indicates if the function should report the advance.}
  \item{\dots}{Any additional parameters supported by `plot.enve.RecPlot2`.}
}

\value{Returns an object of class `enve.RecPlot2`.}

\author{Luis M. Rodriguez-R [aut, cre]}





