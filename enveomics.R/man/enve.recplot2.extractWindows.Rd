\name{enve.recplot2.extractWindows}
\alias{enve.recplot2.extractWindows}
\title{enve recplot2 extractWindows}
\description{Extract windows significantly below (or above) the peak in sequencing
depth.}
\usage{enve.recplot2.extractWindows(rp, peak, lower.tail = TRUE, significance = 0.05, 
    seq.names = FALSE)}
\arguments{
  \item{rp}{Recruitment plot, a `enve.RecPlot2` object.}
  \item{peak}{Peak, an `enve.RecPlot2.Peak` object. If list, it is assumed to be a
list of `enve.RecPlot2.Peak` objects, in which case the core peak is
used (see `enve.recplot2.corePeak`).}
  \item{lower.tail}{If FALSE, it returns windows significantly above the peak in
sequencing depth.}
  \item{significance}{Significance threshold (alpha) to select windows.}
  \item{seq.names}{Returns subject sequence names instead of a vector of Booleans. If
the recruitment plot was generated with pos.breaks=0 it returns a
vector of characters (the sequence identifiers), otherwise it returns
a data.frame with a name column and two columns of coordinates.}
}

\value{Returns a vector of logicals if `seq.names=FALSE`. If `seq.names=TRUE`,
it returns a vector of characters if the object was built with
`pos.breaks=0` or a data.frame with four columns otherwise: name.from,
name.to, pos.from, and pos.to (see `enve.recplot2.coordinates`).}

\author{Luis M. Rodriguez-R [aut, cre]}





