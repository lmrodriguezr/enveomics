\name{enve.recplot2.windowDepthThreshold}
\alias{enve.recplot2.windowDepthThreshold}
\title{enve recplot2 windowDepthThreshold}
\description{Identifies the threshold below which windows should be identified as
variable or absent.}
\usage{enve.recplot2.windowDepthThreshold(rp, peak, lower.tail = TRUE, 
    significance = 0.05)}
\arguments{
  \item{rp}{Recruitment plot, an `enve.RecPlot2` object.}
  \item{peak}{Peak, an `enve.RecPlot2.Peak` object. If list, it is assumed to be a
list of `enve.RecPlot2.Peak` objects, in which case the core peak is
used (see `enve.recplot2.corePeak`).}
  \item{lower.tail}{If FALSE, it returns windows significantly above the peak in
sequencing depth.}
  \item{significance}{Significance threshold (alpha) to select windows.}
}

\value{Returns a float. The units are depth if the peaks were estimated in
linear scale, or log-depth otherwise (`peak$log`).}

\author{Luis M. Rodriguez-R [aut, cre]}





