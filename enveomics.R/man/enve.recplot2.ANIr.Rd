\name{enve.recplot2.ANIr}
\alias{enve.recplot2.ANIr}
\title{enve recplot2 ANIr}
\description{Estimate the Average Nucleotide Identity from reads (ANIr) from a
recruitment plot}
\usage{enve.recplot2.ANIr(x, range = c(0, Inf))}
\arguments{
  \item{x}{`enve.RecPlot2` object.}
  \item{range}{Range of identities to be considered. By default, the full range
is used (note that the upper boundary is `Inf` and not 100 because
recruitment plots can also be built with bit-scores). To use only
intra-population matches (with identities), use c(95,100). To use only
inter-population values, use c(0,95).}
}



\author{Luis M. Rodriguez-R [aut, cre]}





