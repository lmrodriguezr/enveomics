\name{enve.recplot2.seqdepth}
\alias{enve.recplot2.seqdepth}
\title{enve recplot2 seqdepth}
\description{Calculate the sequencing depth of the given window(s)}
\usage{enve.recplot2.seqdepth(x, sel, low.identity = FALSE)}
\arguments{
  \item{x}{`enve.RecPlot2` object.}
  \item{sel}{Window(s) for which the sequencing depth is to be calculated. If not
passed, it returns the sequencing depth of all windows}
  \item{low.identity}{A logical indicating if the sequencing depth is to be estimated only
with low-identity matches. By default, only high-identity matches are
used.}
}

\value{Returns a numeric vector of sequencing depths (in bp/bp). }

\author{Luis M. Rodriguez-R [aut, cre]}





