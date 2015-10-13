\name{enve.tribs.test}
\alias{enve.tribs.test}
\title{enve tribs test}
\description{Estimates the empirical difference between all the distances in a set of
objects and a subset, together with its statistical significance.}
\usage{enve.tribs.test(dist, selection, bins = 50, ...)}
\arguments{
  \item{dist}{Distances as `dist` object.}
  \item{selection}{Selection defining the subset.}
  \item{bins}{Number of bins to evaluate in the range of distances.}
  \item{\dots}{Any other parameters supported by `enve.tribs`, except `subsamples`.}
}

\value{Returns an `enve.TRIBStest` object.}

\author{Luis M. Rodriguez-R <lmrodriguezr@gmail.com> [aut, cre]}





