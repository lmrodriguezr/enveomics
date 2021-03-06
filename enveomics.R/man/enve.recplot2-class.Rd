% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/recplot2.R
\docType{class}
\name{enve.RecPlot2-class}
\alias{enve.RecPlot2-class}
\alias{enve.RecPlot2}
\title{Enveomics: Recruitment Plot (2) - S4 Class}
\description{
Enve-omics representation of Recruitment plots. This object can
be produced by \code{\link{enve.recplot2}} and supports S4 method plot.
}
\section{Slots}{

\describe{
\item{\code{counts}}{\code{(matrix)} Counts as a two-dimensional histogram.}

\item{\code{pos.counts.in}}{\code{(numeric)} Counts of in-group hits per position bin.}

\item{\code{pos.counts.out}}{\code{(numeric)} Counts of out-group hits per position bin.}

\item{\code{id.counts}}{\code{(numeric)} Counts per ID bin.}

\item{\code{id.breaks}}{\code{(numeric)} Breaks of identity bins.}

\item{\code{pos.breaks}}{\code{(numeric)} Breaks of position bins.}

\item{\code{pos.names}}{\code{(character)} Names of the position bins.}

\item{\code{seq.breaks}}{\code{(numeric)} Breaks of input sequences.}

\item{\code{peaks}}{\code{(list)} Peaks identified in the recplot.
Limits of the subject sequences after concatenation.}

\item{\code{seq.names}}{\code{(character}) Names of the subject sequences.}

\item{\code{id.metric}}{\code{(character}) Metric used as 'identity'.}

\item{\code{id.ingroup}}{\code{(logical}) Identity bins considered in-group.}

\item{\code{call}}{\code{(call)} Call producing this object.}
}}

\author{
Luis M. Rodriguez-R [aut, cre]
}
