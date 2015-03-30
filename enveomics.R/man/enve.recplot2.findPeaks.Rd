\name{enve.recplot2.findPeaks}
\alias{enve.recplot2.findPeaks}
\title{enve recplot2 findPeaks}
\description{Identifies peaks in the population histogram potentially indicating
sub-population mixtures.}
\usage{enve.recplot2.findPeaks(x, min.points = 50, mlv.opts = list(method = "parzen"), 
    fitdist.opts = list(distr = "norm", method = "qme", probs = c(0.2), 
        start = list(sd = 0.1)), optim.rounds = 5)}
\arguments{
  \item{x}{An `enve.recplot2` object.}
  \item{min.points}{Minimum number of points to estimate a peak.}
  \item{mlv.opts}{Options passed to `mlv` to estimate the mode.}
  \item{fitdist.opts}{
}
  \item{optim.rounds}{Rounds of peak optimization}
}



\author{Luis M. Rodriguez-R <lmrodriguezr@gmail.com> [aut, cre]}





