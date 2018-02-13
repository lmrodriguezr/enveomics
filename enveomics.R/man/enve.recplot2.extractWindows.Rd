\name{enve.recplot2.extractWindows}
\alias{enve.recplot2.extractWindows}
\title{enve recplot2 extractWindows}
\description{Extract windows significantly below (or above) the peak in sequencing
depth.}
\usage{enve.recplot2.extractWindows(rp, peak, lower.tail = TRUE, significance = 0.05, 
    seq.names = FALSE)}
\arguments{
  \item{rp}{Recruitment plot, a enve.RecPlot2 object.}
  \item{peak}{Peak, a enve.RecPlot2.Peak object. If list, it is assumed to be a list
of enve.RecPlot2.Peak objects, in which case the core peak is used
(see enve.recplot2.corePeak).}
  \item{lower.tail}{If FALSE, it returns windows significantly above the peak in
sequencing depth.}
  \item{significance}{Significance threshold (alpha) to select windows.}
  \item{seq.names}{Returns subject sequence names instead of a vector of Booleans. It
assumes that the recruitment plot was generated with pos.breaks=0.}
}



\author{Luis M. Rodriguez-R [aut, cre]}





