\name{enve.recplot2.coordinates}
\alias{enve.recplot2.coordinates}
\title{enve recplot2 coordinates}
\description{Returns the sequence name and coordinates of the requested position bins.}
\usage{enve.recplot2.coordinates(x, bins)}
\arguments{
  \item{x}{`enve.RecPlot2` object.}
  \item{bins}{Vector of selected bins to return. It can be a vector of logical values
with the same length as `x$pos.breaks`-1 or a vector of integers. If
missing, returns the coordinates of all windows.}
}

\value{Returns a data.frame with four columns: name.from (character), pos.from
(numeric) name.to (character), and pos.to (numeric). The first two
correspond to sequence and position of the start point of the bin, the
last two correspond to the sequence and position of the end point of the
bin.}

\author{Luis M. Rodriguez-R [aut, cre]}





