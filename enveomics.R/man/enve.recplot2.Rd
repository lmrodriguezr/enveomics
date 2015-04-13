\name{enve.recplot2}
\alias{enve.recplot2}
\title{enve recplot2}
\description{Produces recruitment plots provided that BlastTab.catsbj.pl has
been previously executed.}
\usage{enve.recplot2(prefix, plot = TRUE, pos.breaks = 1000, id.breaks = 400, 
    id.metric = c("identity", "corrected identity", "bit score"), 
    id.summary = sum, id.cutoff = 95, threads = 2, verbose = TRUE, 
    ...)}
\arguments{
  \item{prefix}{Path to the prefix of the BlastTab.catsbj.pl output files. At
least the files .rec and .lim must exist with this prefix.}
  \item{plot}{Should the object be plotted?}
  \item{pos.breaks}{Breaks in the positions histogram. It can also be a vector of break
points, and values outside the range are ignored.}
  \item{id.breaks}{Breaks in the identity histogram. It can also be a vector of break
points, and values outside the range are ignored.}
  \item{id.metric}{Metric of identity to be used (Y-axis). Corrected identity is only
supported if the original BLAST file included sequence lengths.}
  \item{id.summary}{Function summarizing the identity bins. Other recommended options
include: `median` to estimate the median instead of the sum, and
`function(x) mlv(x,method='parzen')$M` to estimate the mode.}
  \item{id.cutoff}{Cutoff of identity metric above which the hits are considered
'in-group'. The 95\% identity corresponds to the expectation of
ANI<95\% within species.}
  \item{threads}{Number of threads to use.}
  \item{verbose}{Indicates if the function should report the advance.}
  \item{\dots}{Any additional parameters supported by `plot.enve.recplot2`.}
}



\author{Luis M. Rodriguez-R <lmrodriguezr@gmail.com> [aut, cre]}





