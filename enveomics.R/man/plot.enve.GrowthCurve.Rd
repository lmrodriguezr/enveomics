\name{plot.enve.GrowthCurve}
\alias{plot.enve.GrowthCurve}
\title{plot enve GrowthCurve}
\description{Plots an `enve.GrowthCurve` object.}
\usage{\method{plot}{enve.GrowthCurve}(x, col, pt.alpha = 0.9, ln.alpha = 1, ln.lwd = 1, 
    ln.lty = 1, band.alpha = 0.4, band.density = NULL, band.angle = 45, 
    xp.alpha = 0.5, xp.lwd = 1, xp.lty = 1, pch = 19, new = TRUE, 
    legend = new, add.params = FALSE, ...)}
\arguments{
  \item{x}{`enve.GrowthCurve` object to plot.}
  \item{col}{Base colors to use for the different samples. Can be recycled. By
default, grey for one sample or rainbow colors for more than one.}
  \item{pt.alpha}{Color alpha for the observed data points, using `col` as a base.}
  \item{ln.alpha}{Color alpha for the fitted growth curve, using `col` as a base.}
  \item{ln.lwd}{Line width for the fitted curve.}
  \item{ln.lty}{Line type for the fitted curve.}
  \item{band.alpha}{Color alpha for the confidence interval band of the fitted growth curve,
using `col` as a base.}
  \item{band.density}{Density of the filling pattern in the interval band. If NULL, a solid
color is used.}
  \item{band.angle}{Angle of the density filling pattern in the interval band. Ignored if
`band.density` is NULL.}
  \item{xp.alpha}{Color alpha for the line connecting individual experiments, using `col`
as a base.}
  \item{xp.lwd}{Width of line for the experiments.}
  \item{xp.lty}{Type of line for the experiments.}
  \item{pch}{Point character for observed data points.}
  \item{new}{Should a new plot be generated? If FALSE, the existing canvas is used.}
  \item{legend}{Should the plot include a legend? If FALSE, no legend is added. If TRUE,
a legend is added in the bottom-right corner. Otherwise, a legend is
added in the position specified as `xy.coords`. }
  \item{add.params}{Should the legend include the parameters of the fitted model?}
  \item{\dots}{Any other graphic parameters.}
}



\author{Luis M. Rodriguez-R [aut, cre]}





