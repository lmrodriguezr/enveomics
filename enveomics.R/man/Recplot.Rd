\name{Recplot}
\alias{Recplot}
\title{Recplot}
\description{Produces recruitment plots provided that BlastTab.catsbj.pl has
been previously executed.}
\usage{Recplot(prefix, id.min = NULL, id.max = NULL, id.binsize = NULL, 
    id.splines = 0, id.metric = "id", pos.min = 1, pos.max = NULL, 
    pos.binsize = 1000, pos.splines = 0, rec.col1 = "white", 
    rec.col2 = "black", main = NULL, id.mean = TRUE, id.median = TRUE, 
    id.mode = TRUE, seqdepth.top = TRUE, seqdepth.notop = TRUE, 
    seqdepth.all = TRUE, ret.recplot = FALSE, ret.idhist = FALSE, 
    ret.poshist = FALSE, id.cutoff = NULL, verbose = TRUE, ...)}
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
  \item{id.mean}{Indicates if the mean identity is to be computed.}
  \item{id.median}{Indicates if the median identity is to be computed.}
  \item{id.mode}{Indicates if the mode of the identity is to be computed. It requires the modeest
package.}
  \item{seqdepth.top}{Indicates if the mean sequencing depth of the "top" alignments (above id.cutoff) is
to be computed.}
  \item{seqdepth.notop}{Indicates if the mean sequencing depth of the "bad" alignments (below id.cutoff) is
to be computed.}
  \item{seqdepth.all}{Indicates if the total mean sequencing depth is to be computed (regardless of the
alignment identity).}
  \item{ret.recplot}{Indicates if the matrix of the recruitment plot is to be returned.}
  \item{ret.idhist}{Indicates if the vector of the identity histogram is to be returned.}
  \item{ret.poshist}{Indicates if the vector of the position histogram is to be returned.}
  \item{id.cutoff}{Minimum identity to consider an alignment as "top". By default, it is 0.95 for the
identity metrics and 95\% of the best scoring alignment for bit score.}
  \item{verbose}{Indicates if the function should report the advance.}
  \item{\dots}{Any additional graphic parameters to be passed to plot for all panels except the
recruitment plot (lower-left).}
}



\author{Luis M. Rodriguez-R <lmrodriguezr@gmail.com> [aut, cre]}





