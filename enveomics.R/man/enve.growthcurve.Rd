\name{enve.growthcurve}
\alias{enve.growthcurve}
\title{enve growthcurve}
\description{Calculates growth curves using the logistic growth function.}
\usage{enve.growthcurve(x, times = 1:nrow(x), triplicates = FALSE, design, 
    new.times = seq(min(times), max(times), length.out = length(times) * 
        10), level = 0.95, interval = c("confidence", "prediction"), 
    plot = TRUE, FUN = function(t, K, r, P0) K * P0 * exp(r * 
        t)/(K + P0 * (exp(r * t) - 1)), nls.opt = list(), ...)}
\arguments{
  \item{x}{Data frame (or coercible) containing the observed growth data (e.g.,
O.D. values). Each column is an independent growth curve and each
row is a time point. NA's are allowed.}
  \item{times}{Vector with the times at which each row was taken. By default, all
rows are assumed to be part of constantly periodic measurements.}
  \item{triplicates}{If TRUE, the columns are assumed to be sorted by sample with three
replicates by sample. It requires a number of columns multiple of 3.}
  \item{design}{Experimental design of the data. An `array` of mode list with sample
names as index and the list of column names in each sample as the
values. By default, each column is assumed to be an independent sample
if `triplicates` is FALSE, or every three columns are assumed to be a
sample if `triplicates` is TRUE. In the latter case, samples are
simply numbered.}
  \item{new.times}{Values of time for the fitted curve.}
  \item{level}{Confidence (or prediction) interval in the fitted curve.}
  \item{interval}{Type of interval to be calculated for the fitted curve.}
  \item{plot}{Should the growth curve be plotted?}
  \item{FUN}{Function to fit. By default: logistic growth with paramenters `K`:
carrying capacity, `r`: intrinsic growth rate, and `P0`: Initial
population.}
  \item{nls.opt}{Any additional options passed to `nls`.}
  \item{\dots}{Any additional parameters to be passed to `plot.enve.GrowthCurve`.}
}

\value{Returns an `enve.GrowthCurve` object.}

\author{Luis M. Rodriguez-R [aut, cre]}




\examples{
# Load data
data("growth.curves", package="enveomics.R", envir=environment())
# Generate growth curves with different colors
g <- enve.growthcurve(growth.curves[,-1], growth.curves[,1], triplicates=TRUE)
# Generate black-and-white growth curves with different symbols
plot(g, pch=15:17, col="black", band.density=45, band.angle=c(-45,45,0))
}
