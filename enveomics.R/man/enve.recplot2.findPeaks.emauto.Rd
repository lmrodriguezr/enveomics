\name{enve.recplot2.findPeaks.emauto}
\alias{enve.recplot2.findPeaks.emauto}
\title{enve recplot2 findPeaks emauto}
\description{Identifies peaks in the population histogram using a Gaussian Mixture Model
Expectation Maximization (GMM-EM) method with number of components automatically
detected.}
\usage{enve.recplot2.findPeaks.emauto(x, components = seq(1, 10), criterion = "aic", 
    merge.tol = 2L, verbose = FALSE, ...)}
\arguments{
  \item{x}{An `enve.RecPlot2` object.}
  \item{components}{A vector of number of components to evaluate.}
  \item{criterion}{Criterion to use for components selection. Must be one of:
'aic' (Akaike Information Criterion),
'bic' or 'sbc' (Bayesian Information Criterion or Schwarz Criterion).}
  \item{merge.tol}{When attempting to merge peaks with very similar sequencing depth, use
this number of significant digits (in log-scale).}
  \item{verbose}{Display (mostly debugging) information.}
  \item{\dots}{Any additional parameters supported by `enve.recplot2.findPeaks.em`.}
}

\value{Returns a list of `enve.RecPlot2.Peak` objects.}

\author{Luis M. Rodriguez-R [aut, cre]}





