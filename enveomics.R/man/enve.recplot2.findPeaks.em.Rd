\name{enve.recplot2.findPeaks.em}
\alias{enve.recplot2.findPeaks.em}
\title{enve recplot2 findPeaks em}
\description{Identifies peaks in the population histogram using a Gaussian Mixture
Model Expectation Maximization (GMM-EM) method.}
\usage{enve.recplot2.findPeaks.em(x, max.iter = 1000, ll.diff.res = 1e-08, 
    components = 2, rm.top = 0.05, verbose = FALSE, init, log = TRUE)}
\arguments{
  \item{x}{An `enve.RecPlot2` object.}
  \item{max.iter}{Maximum number of EM iterations.}
  \item{ll.diff.res}{Maximum Log-Likelihood difference to be considered as convergent.}
  \item{components}{Number of distributions assumed in the mixture.}
  \item{rm.top}{Top-values to remove before finding peaks, as a quantile probability.
This step is useful to remove highly conserved regions, but can be
turned off by setting rm.top=0. The quantile is determined *after*
removing zero-coverage windows.}
  \item{verbose}{Display (mostly debugging) information.}
  \item{init}{Initialization parameters. By default, these are derived from k-means
clustering. A named list with vectors for 'mu', 'sd', and 'alpha', each
of length `components`.}
  \item{log}{Logical value indicating if the estimations should be performed in
natural logarithm units. Do not change unless you know what you're
doing.}
}

\value{Returns a list of `enve.RecPlot2.Peak` objects.}

\author{Luis M. Rodriguez-R [aut, cre]}





