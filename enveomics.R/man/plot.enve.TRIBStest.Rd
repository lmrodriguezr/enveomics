\name{plot.enve.TRIBStest}
\alias{plot.enve.TRIBStest}
\title{plot enve TRIBStest}
\description{Plots an `enve.TRIBStest` object.}
\usage{\method{plot}{enve.TRIBStest}(x, type = c("overlap", "difference"), col = "#00000044", 
    col1 = col, col2 = "#44001144", ylab = "Probability", xlim = range(attr(x, 
        "dist.mids")), ylim = c(0, max(c(attr(x, "all.dist"), 
        attr(x, "sel.dist")))), ...)}
\arguments{
  \item{x}{`enve.TRIBStest` object to plot.}
  \item{type}{What to plot. 'overlap' generates a plot of the two contrasting empirical
PDFs (to compare against each other), 'difference' produces a plot of the
differences between the empirical PDFs (to compare against zero).}
  \item{col}{Main color of the plot if type='difference'.}
  \item{col1}{First color of the plot if type='overlap'.}
  \item{col2}{Second color of the plot if type='overlap'.}
  \item{ylab}{Y-axis label.}
  \item{xlim}{X-axis limits.}
  \item{ylim}{Y-axis limits.}
  \item{\dots}{Any other graphical arguments.}
}



\author{Luis M. Rodriguez-R [aut, cre]}





