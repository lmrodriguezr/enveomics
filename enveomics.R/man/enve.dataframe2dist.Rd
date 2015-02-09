\name{enve.dataframe2dist}
\alias{enve.dataframe2dist}
\title{enve dataframe2dist}
\description{Transform a dataframe (or coercible object, like a table) into a `dist` object.}
\usage{enve.dataframe2dist(x, obj1.index = 1, obj2.index = 2, dist.index = 3)}
\arguments{
  \item{x}{A dataframe (or coercible object) with at least three columns: (1) ID of the object 1,
(2) ID of the object 2, and (3) distance between the two objects.}
  \item{obj1.index}{Index of the column containing the ID of the object 1.}
  \item{obj2.index}{Index of the column containing the ID of the object 2.}
  \item{dist.index}{Index of the column containing the distance.}
}

\value{Returns a `dist` object.}

\author{Luis M. Rodriguez-R <lmrodriguezr@gmail.com> [aut, cre]}





