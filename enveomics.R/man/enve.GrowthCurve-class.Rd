\name{enve.GrowthCurve-class}
\Rdversion{1.1}
\docType{class}
\alias{enve.GrowthCurve-class}
\alias{enve.GrowthCurve}
%% \alias{$}

\title{enve.GrowthCurve S4 class}
\description{Enve-omics representation of fitted growth curves.}
\section{Objects from the Class}{Objects can be created by calls of the form \code{new(enve.GrowthCurve ...)}}
\section{Slots}{
  \describe{
    \item{\code{design}:}{(\code{array}) Experimental design of the experiment.}
    \item{\code{models}:}{(\code{list}) Fitted growth curve models.}
    \item{\code{predict}:}{(\code{list}) Fitted growth curve values.}
    \item{\code{call}:}{(\code{call}) Call producing this object.}
  }
}
\section{Methods}{
  \describe{
    \item{$}{\code{signature(x = "enve.GrowthCurve")}: ... }
	 }
}

\author{Luis M. Rodriguez-R [aut, cre]}





