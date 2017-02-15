\name{enve.RecPlot2-class}
\Rdversion{1.1}
\docType{class}
\alias{enve.RecPlot2-class}
\alias{enve.RecPlot2}
%% \alias{$}

\title{enve.RecPlot2 S4 class}
\description{Enve-omics representation of Recruitment plots. This object can
be produced by `enve.recplot2` and supports S4 method plot.}
\section{Objects from the Class}{Objects can be created by calls of the form \code{new(enve.RecPlot2 ...)}}
\section{Slots}{
  \describe{
    \item{\code{counts}:}{(\code{matrix}) Counts as a two-dimensional histogram.}
    \item{\code{pos.counts.in}:}{(\code{numeric}) Counts of in-group hits per position bin.}
    \item{\code{pos.counts.out}:}{(\code{numeric}) Counts of out-group hits per position bin.}
    \item{\code{id.counts}:}{(\code{numeric}) Counts per ID bin.}
    \item{\code{id.breaks}:}{(\code{numeric}) Breaks of identity bins.}
    \item{\code{pos.breaks}:}{(\code{numeric}) Breaks of position bins.}
    \item{\code{seq.breaks}:}{Object of class \code{"numeric"}}
    \item{\code{peaks}:}{(\code{list}) Peaks identified in the recplot.
Limits of the subject sequences after concatenation.}
    \item{\code{seq.names}:}{(\code{character}) Names of the subject sequences.}
    \item{\code{id.metric}:}{(\code{character}) Metric used as 'identity'.}
    \item{\code{id.ingroup}:}{(\code{logical}) Identity bins considered in-group.}
    \item{\code{call}:}{(\code{call}) Call producing this object.}
  }
}
\section{Methods}{
  \describe{
    \item{$}{\code{signature(x = "enve.RecPlot2")}: ... }
	 }
}

\author{Luis M. Rodriguez-R [aut, cre]}





