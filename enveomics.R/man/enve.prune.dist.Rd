\name{enve.prune.dist}
\alias{enve.prune.dist}
\title{enve prune dist}
\description{Automatically prunes a tree, to keep representatives of each clade.}
\usage{enve.prune.dist(t, dist.quantile = 0.25, min_dist, quiet = FALSE, 
    max_iters = 100, min_nodes_random = 40000, random_nodes_frx = 1)}
\arguments{
  \item{t}{A `phylo` object or a path to the Newick file.}
  \item{dist.quantile}{The quantile of edge lengths.}
  \item{min_dist}{The minimum distance to allow between two tips. If not set, dist.quantile is
used instead to calculate it.}
  \item{quiet}{Boolean indicating if the function must run without output.}
  \item{max_iters}{Maximum number of iterations.}
  \item{min_nodes_random}{Minimum number of nodes to trigger "tip-pairs" nodes sampling. This sampling
is less reproducible and more computationally expensive, but it's the only
solution if the cophenetic matrix exceeds 2^31-1 entries; above that, it
cannot be represented in R.}
  \item{random_nodes_frx}{Fraction of the nodes to be sampled if more than `min_nodes_random`.}
}

\value{Returns a pruned phylo object.}

\author{Luis M. Rodriguez-R [aut, cre]}





