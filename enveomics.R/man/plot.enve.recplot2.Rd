\name{plot.enve.recplot2}
\alias{plot.enve.recplot2}
\title{plot enve recplot2}
\description{Plots an `enve.recplot2` object.}
\usage{\method{plot}{enve.recplot2}(x, layout = matrix(c(5, 5, 2, 1, 4, 3), nrow = 2), 
    widths = c(1, 7, 2), heights = c(1, 2), palette = grey((0:100)/100), 
    underlay.group = FALSE, peaks.col = NA, id.lim = range(attr(x, 
        "id.breaks")), pos.lim = range(attr(x, "pos.breaks")), 
    pos.units = c("Mbp", "Kbp", "bp"), mar = list(`1` = c(5, 
        4, 1, 1) + 0.1, `2` = c(1, 4, 4, 1) + 0.1, `3` = c(5, 
        1, 1, 2) + 0.1, `4` = c(1, 1, 4, 2) + 0.1, `5` = c(5, 
        3, 4, 1) + 0.1, `6` = c(5, 4, 4, 2) + 0.1), pos.splines = 0, 
    id.splines = 0, in.lwd = ifelse(pos.splines > 0, 1/2, 2), 
    in.col = "black", out.lwd = ifelse(pos.splines > 0, 1/2, 
        2), out.col = grey(2/3), id.lwd = ifelse(id.splines > 
        0, 1/2, 2), id.col = "black", peaks.opts = list())}
\arguments{
  \item{x}{`enve.recplot2` object to plot.}
  \item{layout}{Matrix indicating the position of the different panels in the layout, where:
0: Empty space, 1: Counts matrix, 2: position histogram (sequencing depth),
3: identity histogram, 4: Populations histogram (histogram of sequencing depths),
5: Color scale for the counts matrix (vertical), 6: Color scale of the counts
matrix (horizontal). Only panels indicated here will be plotted. To plot only
one panel simply set this to the number of the panel you want to plot.}
  \item{widths}{Relative widths of the columns of `layout`.}
  \item{heights}{Relative heights of the rows of `layout`.}
  \item{palette}{Colors to be used to represent the counts matrix, sorted from no hits to the
maximum sequencing depth.}
  \item{underlay.group}{If TRUE, it indicates the in-group and out-group areas couloured based on
`in.col` and `out.col`. Requires support for semi-transparency.}
  \item{peaks.col}{If not NA, it attempts to represent peaks in the population histogram in the
specified color.}
  \item{id.lim}{Limits of identities to represent.}
  \item{pos.lim}{Limits of positions to represent (in bp, regardless of `pos.units`).}
  \item{pos.units}{Units in which the positions should be represented (powers of 1,000 base pairs).}
  \item{mar}{
}
  \item{pos.splines}{
}
  \item{id.splines}{
}
  \item{in.lwd}{
}
  \item{in.col}{
}
  \item{out.lwd}{
}
  \item{out.col}{
}
  \item{id.lwd}{
}
  \item{id.col}{
}
  \item{peaks.opts}{Options passed to `enve.recplot2.findPeaks`, if `peaks.col` is not NA.}
}



\author{Luis M. Rodriguez-R <lmrodriguezr@gmail.com> [aut, cre]}





