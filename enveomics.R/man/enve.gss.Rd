\name{enve.gss}
\alias{enve.gss}
\title{enve gss}
\description{Subsample any objects in "distance space" to reduce the effect of sample-clustering.
This function was originally designed to subsample genomes in "phylogenetic distance
space", a clear case of strong clustering bias in sampling, by Luis M. Rodriguez-R
and Michael R Weigand.}
\usage{enve.gss(dist, selection = labels(dist), replicates = 1000, summary.fx = median, 
    dist.method = "euclidean", subsamples = seq(0, 1, by = 0.01), 
    dimensions = floor(length(selection) * 0.05), metaMDS.opts = list(), 
    threads = 2, verbosity = 1, points, pre.gss)}
\arguments{
  \item{dist}{Distances as a `dist` object.}
  \item{selection}{Objects to include in the subsample. By default, all objects are selected.}
  \item{replicates}{Number of replications per point}
  \item{summary.fx}{Function to summarize the distance distributions in a given replicate. By
default, the median distance is estimated.}
  \item{dist.method}{Distance method between random points and samples. See `dist`.}
  \item{subsamples}{Subsampling fractions}
  \item{dimensions}{Dimensions to use in the NMDS. By default, 5\% of the selection length.}
  \item{metaMDS.opts}{Any additional options to pass to metaMDS, as `list`.}
  \item{threads}{Number of threads to use.}
  \item{verbosity}{Verbosity. Use 0 to run quietly, increase for additional information.}
  \item{points}{Optional. If passed, the MDS step is skipped and this object is used instead.
It can be the `$points` slot of class `metaMDS` (from `vegan`). It must be a
matrix or matrix-coercible object, with samples as rows and dimensions as
columns.}
  \item{pre.gss}{Optional. If passed, the points are recovered from this object (except if
`points` is also passed. This should be an `enve.GSS` object estimated on the
same objects (the selection is unimportant).}
}

\value{Returns an `enve.GSS` object.}

\author{Luis M. Rodriguez-R <lmrodriguezr@gmail.com> [aut, cre]}





