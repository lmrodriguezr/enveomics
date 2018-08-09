\name{enve.truncate}
\alias{enve.truncate}
\title{enve truncate}
\description{Removes the `n` highest and lowest values from a vector, and applies a
summary function. The value of `n` is determined such that the central
range is used, corresponding to the `f` fraction of values.}
\usage{enve.truncate(x, f = 0.95, FUN = mean)}
\arguments{
  \item{x}{A vector of numbers.}
  \item{f}{The fraction of values to retain.}
  \item{FUN}{Summary function to apply to the vectors. To obtain the truncated
vector itself, use `c`.}
}

\value{Returns the summary (`FUN`) of the truncated vector.}

\author{Luis M. Rodriguez-R [aut, cre]}





