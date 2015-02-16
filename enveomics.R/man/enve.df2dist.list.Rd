\name{enve.df2dist.list}
\alias{enve.df2dist.list}
\title{enve df2dist list}
\description{Transform a dataframe (or coercible object, like a table) into a `dist` object.}
\usage{enve.df2dist.list(x, groups, obj1.index = 1, obj2.index = 2, 
    dist.index = 3, empty.rm = TRUE, ...)}
\arguments{
  \item{x}{A dataframe (or coercible object) with at least three columns: (1) ID of the object 1,
(2) ID of the object 2, and (3) distance between the two objects.}
  \item{groups}{Named array where the IDs correspond to the object IDs, and the values correspond to
the group.}
  \item{obj1.index}{Index of the column containing the ID of the object 1.}
  \item{obj2.index}{Index of the column containing the ID of the object 2.}
  \item{dist.index}{Index of the column containing the distance.}
  \item{empty.rm}{Remove incomplete matrices}
  \item{\dots}{Any other parameters supported by `enve.df2dist.group`.}
}

\value{Returns a `list` of `dist` object.}

\author{Luis M. Rodriguez-R <lmrodriguezr@gmail.com> [aut, cre]}





