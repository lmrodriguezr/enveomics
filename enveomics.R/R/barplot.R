#' Enveomics: Barplot
#' 
#' Creates nice barplots from tab-delimited tables.
#'
#' @param x Can be either the input data or the path to the file containing 
#' the table. 
#' \itemize{
#'    \item{If it contains the data, it must be a data frame or an
#'    object coercible to a data frame.} 
#'    \item{If it is a path, it must point to a
#'    tab-delimited file containing a header (first row) and row names 
#'    (first column).}
#'    }
#' @param sizes  A numeric vector containing the real size of the samples
#' (columns) in the same order of the input table. If set, the values are
#' assumed to be 100\%. Otherwise, the sum of the columns is used.
#' @param top Maximum number of categories to display. Any additional
#' categories will be listed as "Others".
#' @param colors.per.group Number of categories in the first two saturation 
#' groups of colors. The third group contains the remaining categories if 
#' needed.
#' @param bars.width Width of the barplot with respect to the legend.
#' @param legend.ncol Number of columns in the legend.
#' @param other.col Color of the "Others" category.
#' @param add.trend Controls if semi-transparent areas are to be plotted
#' between the bars to connect the regions (trend regions).
#' @param organic.trend Controls if the trend regions are to be smoothed 
#' (curves). By default, trend regions have straight edges. If \code{TRUE}, 
#' forces \code{add.trend=TRUE}.
#' @param sort.by Any function that takes a numeric vector and returns a
#' numeric scalar. This function is applied to each row, and the resulting
#' values are used to sort the rows (decreasingly). Good options include: 
#' \code{sd, min, max, mean, median}.
#' @param min.report Minimum percentage to report the value in the plot.
#' Any value above 100 indicates that no values are to be reported.
#' @param order Controls how the rows should be ordered. 
#' \itemize{
#'   \item{
#'     If \code{NULL} (default), \code{sort.by} is applied per row and the
#'     results are sorted decreasingly.
#'   }
#'   \item{
#'     If \code{NA}, no sorting is performed, i.e., the original order is
#'     respected.
#'   }
#'   \item{
#'     If a vector is provided, it is assumed to be the custom order to be used
#'     (either by numeric index or by row names).
#'   }
#' }
#' @param col Colors to use. If provided, overrides the variables \code{top}
#' and \code{colors.per.group}, but \code{other.col} is still used if the 
#' vector is insufficient for all the rows. An additional palette is available
#' with \code{col='coto'} (contributed by Luis (Coto) Orellana).
#' @param ... Any additional parameters to be passed to barplot.
#' 
#' @return No return value
#' 
#' @author Luis M. Rodriguez-R [aut, cre]
#' 
#' @examples
#' # Load data
#' data("phyla.counts", package = "enveomics.R", envir = environment())
#' # Create a barplot sorted by variance with organic trends
#' enve.barplot(
#'   phyla.counts, # Counts of phyla in four sites
#'   sizes = c(250,100,75,200), # Total sizes of the datasets of each site
#'   bars.width = 2, # Decrease from default, so the names are fully displayed
#'   organic.trend = TRUE, # Nice curvy background
#'   sort.by = var # Sort by variance across sites
#' )
#' 
#' @export

enve.barplot <- function(
  x,
  sizes,
  top = 25,
  colors.per.group = 9,
  bars.width = 4,
  legend.ncol = 1,
  other.col = "#000000",
  add.trend = FALSE,
  organic.trend = FALSE,
  sort.by = median,
  min.report = 101,
  order = NULL,
  col,
  ...
){
  # Read input
  if (is.character(x)) {
    c <- read.table(x, sep = "\t", header = TRUE, row.names = 1, quote = "",
                    comment.char = "")
  } else {
    c <- as.data.frame(x)
  }
  if (missing(sizes)) sizes <- colSums(c)
  p <- c
  for (i in 1:ncol(c)) p[, i] <- c[, i] * 100 / sizes[i]
  if(top > nrow(p)) top <- nrow(p)

  # Sort
  if (is.null(order[1])) {
    p <- p[order(apply(p, 1, sort.by)), ]
  } else if (is.na(order[1])) {
    
  } else {
    p <- p[order, ]
  }
  if(organic.trend) add.trend <- TRUE

  # Colors
  if (is.null(top)) top <- nrow(p)
  if (missing(col)) {
    color.col <- rainbow(min(colors.per.group, top), s = 1, v = 4/5)
    if(top > colors.per.group)
      color.col <- c(color.col,
                     rainbow(min(colors.per.group * 2, top) - colors.per.group,
                             s = 3/4, v = 3/5))
    if(top > colors.per.group * 2)
      color.col <- c(color.col,
                     rainbow(top-colors.per.group * 2, s = 1, v = 1.25 / 4))
  } else if (length(col) == 1 & col[1] == "coto") {
    color.col <- c("#5BC0EB", "#FDE74C", "#9BC53D", "#E55934", "#FA7921",
                   "#EF476F", "#FFD166", "#06D6A0", "#118AB2", "#073B4C",
                   "#264653", "#2A9D8F", "#E9C46A", "#F4A261", "#E76F51")
    color.col <- head(color.col, n = nrow(p))
    top <- length(color.col)
  } else {
    color.col <- col
    color.col <- tail(color.col, n = nrow(p))
    top <- length(color.col)
  }
  
  # Plot
  layout(matrix(1:2, nrow = 1), widths = c(bars.width, 1))
  mar <- par(mar = c(5, 4, 4, 0) + 0.1) 
  on.exit(par(mar)) 
  mp <- barplot(
    as.matrix(p),
    col = rev(c(color.col, rep(other.col, nrow(p) - length(color.col)))),
    space = ifelse(add.trend,ifelse(organic.trend, 0.75, 0.5), 0.2),
    border = NA, ...
  )
  if (add.trend || min.report < max(p)) {
    color.alpha <- enve.col.alpha(c(color.col, other.col), 1/4)
    if (top < nrow(p)) {
      cf <- colSums(p[1:(nrow(p)-top), ])
    } else {
      cf <- rep(0, ncol(p))
    }
    for (i in (nrow(p) - top + 1):nrow(p)) {
      f <- as.numeric(p[i, ])
      cf <- as.numeric(cf + f)
      if (nrow(p) - i < top){
        if (organic.trend) {
          spc <- 0.5
          x <- c(mp[1] - spc)
          y1 <- c(cf[1] - f[1])
          y2 <- c(cf[1])
          for (j in 2:ncol(p)) {
            x <- c(x, seq(mp[j - 1] + spc, mp[j] - spc, length.out = 22))
            y1 <- c(
              y1, cf[j - 1] - f[j - 1],
              (tanh(seq(-2.5, 2.5, length.out = 20)) / 2 + 0.5) *
                ((cf[j] - f[j]) - (cf[j - 1] - f[j - 1])) +
                (cf[j - 1] - f[j - 1]),
              cf[j] - f[j]
            )
            y2 <- c(
              y2, cf[j-1],
              (tanh(seq(-2.5, 2.5, length.out = 20)) / 2 + 0.5) *
                (cf[j] - cf[j - 1]) + (cf[j - 1]), cf[j]
            )
          }
          x <- c(x, mp[length(mp)] + spc)
          y1 <- c(y1, cf[length(cf)] - f[length(f)])
          y2 <- c(y2, cf[length(cf)])
          polygon(c(x, rev(x)), c(y1, rev(y2)),
                  col = color.alpha[nrow(p) - i + 1], border = NA)
        } else if (add.trend) {
          x <- rep(mp, each = 2) + c(-0.5, 0.5)
          if(add.trend)
            polygon(c(x, rev(x)),
                    c(rep(cf - f, each = 2), rev(rep(cf, each = 2))),
                    col = color.alpha[nrow(p) - i + 1], border = NA)
        }
        text(mp, cf - f / 2, ifelse(f > min.report, signif(f, 3), ""),
             col = "white")
      }
    }
  }

  # Legend
  par(mar = rep(0, 4) + 0.1) # par(mar) already being watched by on.exit
  plot(1, t = "n", bty = "n", xlab = "", ylab = "", xaxt = "n", yaxt = "n")
  nam <- rownames(p[nrow(p):(nrow(p) - top + 1), ])
  if(top < nrow(p))
    nam <- c(nam, paste("Other (", nrow(p) - length(color.col), ")", sep = ""))
  legend("center", col = c(color.col, other.col), legend = nam, pch = 15,
         bty = "n", pt.cex = 2, ncol = legend.ncol)
}
