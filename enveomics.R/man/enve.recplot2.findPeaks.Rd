\name{enve.recplot2.findPeaks}
\alias{enve.recplot2.findPeaks}
\title{enve recplot2 findPeaks}
\description{Identifies peaks in the population histogram potentially indicating
sub-population mixtures}
\usage{enve.recplot2.findPeaks(x, method = "emauto", ...)}
\arguments{
  \item{x}{An `enve.RecPlot2` object.}
  \item{method}{Peak-finder method. This should be one of:
"emauto" (Expectation-Maximization with auto-selection of components),
"em" (Expectation-Maximization),
"mower" (Custom distribution-mowing method).}
  \item{\dots}{Any additional parameters supported by `enve.recplot2.findPeaks.<method>`.}
}

\value{Returns a list of `enve.RecPlot2.Peak` objects.}

\author{Luis M. Rodriguez-R [aut, cre]}





