\name{enve.TRIBS-class}
\Rdversion{1.1}
\docType{class}
\alias{enve.TRIBS-class}
\alias{enve.TRIBS}

\title{enve.TRIBS S4 class}
\description{Enve-omics representation of "Transformed-space Resampling In Biased Sets
(TRIBS)".  This object represents sets of distances between objects,
sampled nearly-uniformly at random in "distance space".  Subsampling
without selection is trivial, since both the distances space and the
selection occur in the same transformed space. However, it's useful to
compare randomly subsampled sets against a selected set of objects. This
is intended to identify overdispersion or overclustering (see
`enve.TRIBStest`) of a subset against the entire collection of objects
with minimum impact of sampling biases. This object can be produced by
`enve.tribs` and supports S4 methods `plot` and `summary`.}
\section{Objects from the Class}{Objects can be created by calls of the form \code{new(enve.TRIBS ...)}}
\section{Slots}{
  \describe{
    \item{\code{distance}:}{(\code{numeric}) Centrality measurement of the distances between the
<< selected objects (without subsampling).}
    \item{\code{points}:}{(\code{matrix}) Position of the different objects in distance
<< space.}
    \item{\code{distances}:}{(\code{matrix}) Subsampled distances, where the rows are replicates
<< and the columns are subsampling levels.}
    \item{\code{spaceSize}:}{(\code{numeric}) Number of objects.}
    \item{\code{selSize}:}{(\code{numeric}) Number of selected objects.}
    \item{\code{dimensions}:}{(\code{numeric}) Number of dimensions in the distance space.}
    \item{\code{subsamples}:}{(\code{numeric}) Subsampling levels (as fractions, from 0 to 1).}
    \item{\code{call}:}{(\code{call}) Call producing this object.}
  }
}
\section{Methods}{
No methods defined with class "enve.TRIBS" in the signature.
}

\author{Luis M. Rodriguez-R [aut, cre]}





