\name{enve.df2dist.group}
\alias{enve.df2dist.group}
\title{enve df2dist group}
\description{Transform a dataframe (or coercible object, like a table) into a `dist` object, where
there are 1 or more distances between each pair of objects.}
\usage{enve.df2dist.group(x, obj1.index = 1, obj2.index = 2, dist.index = 3, 
    summary = median, empty.rm = TRUE)}
\arguments{
  \item{x}{A dataframe (or coercible object) with at least three columns: (1) ID of the object 1,
(2) ID of the object 2, and (3) distance between the two objects.}
  \item{obj1.index}{Index of the column containing the ID of the object 1.}
  \item{obj2.index}{Index of the column containing the ID of the object 2.}
  \item{dist.index}{Index of the column containing the distance.}
  \item{summary}{Function summarizing the different distances between the two objects.}
  \item{empty.rm}{Remove rows with empty or NA groups}
}

\value{Returns a `dist` object.}

\author{Luis M. Rodriguez-R [aut, cre]}





