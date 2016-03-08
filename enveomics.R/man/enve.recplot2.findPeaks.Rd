\name{enve.recplot2.findPeaks}
\alias{enve.recplot2.findPeaks}
\title{enve recplot2 findPeaks}
\description{Identifies peaks in the population histogram potentially indicating
sub-population mixtures.}
\usage{enve.recplot2.findPeaks(x, min.points = 10, quant.est = c(0.002, 
    0.998), mlv.opts = list(method = "parzen"), fitdist.opts.sn = list(distr = "sn", 
    method = "qme", probs = c(0.1, 0.5, 0.8), start = list(omega = 1, 
        alpha = -1), lower = c(1e-06, -Inf, 0), upper = c(Inf, 
        0, Inf)), fitdist.opts.norm = list(distr = "norm", method = "qme", 
    probs = c(0.4, 0.6), start = list(sd = 1), lower = c(1e-08, 
        0)), rm.top = 0.05, with.skewness = TRUE, optim.rounds = 200, 
    optim.epsilon = 1e-08, merge.logdist = log(1.75), verbose = FALSE)}
\arguments{
  \item{x}{An `enve.RecPlot2` object.}
  \item{min.points}{Minimum number of points in the quantile-estimation-range
(`quant.est`) to estimate a peak.}
  \item{quant.est}{Range of quantiles to be used in the estimation of a peak's
parameters.}
  \item{mlv.opts}{Options passed to `mlv` to estimate the mode.}
  \item{fitdist.opts.sn}{
}
  \item{fitdist.opts.norm}{
}
  \item{rm.top}{Top-values to remove before finding peaks, as a quantile probability.
This step is useful to remove highly conserved regions, but can be
turned off by setting rm.top=0. The quantile is determined *after*
removing zero-coverage windows.}
  \item{with.skewness}{Allow skewness correction of the peaks. Typically, the
sequencing-depth distribution for a single peak is left-skewed, due
partly (but not exclusively) to fragmentation and mapping sensitivity.
See Lindner et al 2013, Bioinformatics 29(10):1260-7 for an
alternative solution for the first problem (fragmentation) called
"tail distribution".}
  \item{optim.rounds}{Maximum rounds of peak optimization.}
  \item{optim.epsilon}{Trace change at which optimization stops (unless `optim.rounds` is
reached first). The trace change is estimated as the sum of square
differences between parameters in one round and those from two rounds
earlier (to avoid infinite loops from approximation).}
  \item{merge.logdist}{Maximum value of |log-ratio| between centrality parameters in peaks to
attempt merging. The default of ~0.22 corresponds to a maximum
difference of 25\%.}
  \item{verbose}{Display (mostly debugging) information.}
}

\value{Returns a list of `enve.RecPlot2.Peak` objects.}

\author{Luis M. Rodriguez-R [aut, cre]}





