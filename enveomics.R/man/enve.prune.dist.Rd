\name{enve.prune.dist}
\alias{enve.prune.dist}
\title{enve prune dist}
\description{Automatically prunes a tree, to keep representatives of each clade.}
\usage{enve.prune.dist(t, dist.quantile = 0.25, min_dist, quiet = FALSE, 
    max_iters = 100)}
\arguments{
  \item{t}{A `phylo` object}
  \item{dist.quantile}{The quantile of pairwise distances.}
  \item{min_dist}{The minimum distance to allow between two tips. If not set, dist.quantile is
used instead to calculate it.}
  \item{quiet}{Boolean indicating if the function must run without output.}
  \item{max_iters}{
}
}

\value{Returns a pruned phylo object.}

\author{Luis M. Rodriguez-R <lmrodriguezr@gmail.com> [aut, cre]}





