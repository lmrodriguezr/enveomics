\name{enve.TRIBStest-class}
\Rdversion{1.1}
\docType{class}
\alias{enve.TRIBStest-class}
\alias{enve.TRIBStest}

\title{enve.TRIBStest S4 class}
\description{Test of significance of overclustering or overdispersion in a selected
set of objects with respect to the entire set (see `enve.TRIBS`). This
object can be produced by `enve.tribs.test` and supports S4 methods
`plot` and `summary`.}
\section{Objects from the Class}{Objects can be created by calls of the form \code{new(enve.TRIBStest ...)}}
\section{Slots}{
  \describe{
    \item{\code{pval.gt}:}{(\code{numeric}) P-value for the overdispersion test.}
    \item{\code{pval.lt}:}{(\code{numeric}) P-value for the overclustering test.}
    \item{\code{all.dist}:}{(\code{numeric}) Empiric PDF of distances for the entire dataset (subsampled at selection
size).}
    \item{\code{sel.dist}:}{(\code{numeric}) Empiric PDF of distances for the selected objects (without subsampling).}
    \item{\code{diff.dist}:}{(\code{numeric}) Empiric PDF of the difference between `all.dist` and `sel.dist`. The
p-values are estimating by comparing areas in this PDF greater than and
lesser than zero.}
    \item{\code{dist.mids}:}{(\code{numeric}) Midpoints of the empiric PDFs of distances.}
    \item{\code{diff.mids}:}{(\code{numeric}) Midpoints of the empiric PDF of difference of distances.}
    \item{\code{call}:}{(\code{call}) Call producing this object.}
  }
}
\section{Methods}{
No methods defined with class "enve.TRIBStest" in the signature.
}

\author{Luis M. Rodriguez-R <lmrodriguezr@gmail.com> [aut, cre]}





