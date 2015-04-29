\name{enve.recplot2.peak-class}
\Rdversion{1.1}
\docType{class}
\alias{enve.recplot2.peak-class}
\alias{enve.recplot2.peak}
%% \alias{$}

\title{enve.recplot2.peak S4 class}
\description{Enve-omics representation of a peak in the sequencing depth histogram
of a Recruitment plot (see `enve.recplot2`).}
\section{Objects from the Class}{Objects can be created by calls of the form \code{new(enve.recplot2.peak ...)}}
\section{Slots}{
  \describe{
    \item{\code{dist}:}{(\code{character}) Distribution of the peak. Currently supported: 'norm' (normal) and 'sn' (skew-normal).}
    \item{\code{values}:}{(\code{numeric}) Sequencing depth values predicted to conform the peak.}
    \item{\code{mode}:}{(\code{numeric}) Seed-value of mode anchoring the peak.}
    \item{\code{param.hat}:}{(\code{list}) Parameters of the distribution. A list of two values if dist='norm' (mean and sd),
or three values if dist='sn' (xi=location, omega=scale, and alpha=shape).}
    \item{\code{n.hat}:}{(\code{numeric}) Number of bins estimated to be explained by this peak. This should ideally be equal to
the length of `values`, but it's not and integer.}
    \item{\code{n.total}:}{(\code{numeric}) Total number of bins from which the peak was extracted.}
  }
}
\section{Methods}{
  \describe{
    \item{$}{\code{signature(x = "enve.recplot2.peak")}: ... }
	 }
}

\author{Luis M. Rodriguez-R <lmrodriguezr@gmail.com> [aut, cre]}





