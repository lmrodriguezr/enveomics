\name{enve.recplot}
\alias{enve.recplot}
\title{enve recplot}
\description{Produces recruitment plots provided that BlastTab.catsbj.pl has
been previously executed.}
\usage{enve.recplot(prefix, id.min = NULL, id.max = NULL, id.binsize = NULL, 
    id.splines = 0, id.metric = "id", pos.min = 1, pos.max = NULL, 
    pos.binsize = 1000, pos.splines = 0, rec.col1 = "white", 
    rec.col2 = "black", main = NULL, ret.recplot = FALSE, ret.hist = FALSE, 
    ret.mode = FALSE, id.cutoff = NULL, verbose = TRUE, ...)}
\arguments{
  \item{prefix}{Path to the prefix of the BlastTab.catsbj.pl output files. At
least the files .rec and .lim must exist with this prefix.}
  \item{id.min}{Minimum identity to be considered. By default, the minimum detected
identity. This value is a percentage.}
  \item{id.max}{Maximum identity to be considered. By default, 100.}
  \item{id.binsize}{Size of the identity bins (vertical histograms). By default, 0.1 for
identity metrics and 5 for bit score.}
  \item{id.splines}{Spar factor of the splines in the identity histogram. Zero (0) for no
splines. A generally good value is 1/2. If non-zero, requires the package
splines.}
  \item{id.metric}{Metric of identity to be used (Y-axis). It can be any unambiguous prefix
of "identity", "corrected identity", or "bit score".}
  \item{pos.min}{Minimum (leftmost) position in the reference (concatenated) genome (in bp).}
  \item{pos.max}{Maximum (rightmost) position in the reference (concatenated) genome (in bp).
By default: Length of the genome.}
  \item{pos.binsize}{Size of the position bins (horizontal histograms) in bp.}
  \item{pos.splines}{Spar factor of the splines in the position histogram. Zero (0) for no splines.
If non-zero, requires the package splines.}
  \item{rec.col1}{Lightest color in the recruitment plot.}
  \item{rec.col2}{Darkest color in the recruitment plot.}
  \item{main}{Title of the plot.}
  \item{ret.recplot}{Indicates if the matrix of the recruitment plot is to be returned.}
  \item{ret.hist}{Indicates if the vectors of the identity and position histograms are to be returned.}
  \item{ret.mode}{Indicates if the mode of the identity is to be computed. It requires the modeest
package.}
  \item{id.cutoff}{Minimum identity to consider an alignment as "top". By default, it is 0.95 for the
identity metrics and 95\% of the best scoring alignment for bit score.}
  \item{verbose}{Indicates if the function should report the advance.}
  \item{\dots}{Any additional graphic parameters to be passed to plot for all panels except the
recruitment plot (lower-left).}
}

\value{A list with the following elements:

pos.marks: Midpoints of the position histogram.

id.matrix: Midpoints of the identity histogram.

recplot (if ret.recplot=TRUE): Matrix containing the recruitment plot values.

id.mean: Mean identity.

id.median: Median identity.

id.mode (if ret.mode=TRUE): Mode of the identity.

id.hist (if ret.hist=TRUE): Values of the identity histogram.

pos.hist.low (if ret.hist=TRUE): Values of the position histogram (depth) with "low"
identity (i.e., below id.cutoff).

pos.hist.top (if ret.hist=TRUE): Values of the position histogram (depth) with "top"
identity (i.e., above id.cutoff).

id.max: Value of id.max. This is returned because id.max=NULL may vary.

id.cutoff: Value of id.cutoff. This is returned because id.cutoff=NULL may vary.

seqdepth.mean.top: Average sequencing depth with identity above id.cutoff.

seqdepth.mean.low: Average sequencing depth with identity below id.cutoff.

seqdepth.mean.all: Average sequencing depth without identity filtering.

id.metric: Full name of the used identity metric.}

\author{Luis M. Rodriguez-R <lmrodriguezr@gmail.com> [aut, cre]}





