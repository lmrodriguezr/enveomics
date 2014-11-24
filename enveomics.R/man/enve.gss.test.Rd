\name{enve.gss.test}
\alias{enve.gss.test}
\title{enve gss test}
\description{Estimates the empirical difference between distances in a datasets and a subset, and its
statistical significance.}
\usage{enve.gss.test(dist, selection, bins = 50, ...)}
\arguments{
  \item{dist}{Distances as `dist` object.}
  \item{selection}{Selection defining the subset.}
  \item{bins}{Number of bins to evaluate in the range of distances.}
  \item{\dots}{Any other parameters supported by `enve.gss`, except `subsamples`.}
}

\value{Returns an `enve.GSStest` object.}

\author{Luis M. Rodriguez-R <lmrodriguezr@gmail.com> [aut, cre]}





