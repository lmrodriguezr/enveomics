#' Enveomics: Pref Score
#'
#' Estimate preference score of species based on occupancy in biased sample sets
#'
#' @param x
#' Occupancy matrix (logical or numeric binary) with species as rows and samples
#' as columns
#' @param set
#' Vector indicating samples in the test set. It can be any selection vector:
#' boolean (same length as the number of columns in \code{x}), or numeric or
#' character vector with indexes of the \code{x} columns.
#' @param ignore
#' Vector indicating species to ignore. It can be any selection vector with
#' respect to the rows in \code{x} (see \code{set}).
#' @param signif.thr Absolute value of the significance threshold
#' @param plot Indicates if a plot should be generated
#' @param col.above Color for points significantly above zero
#' @param col.equal Color for points not significantly different from zero
#' @param col.below Color for points significantly below zero
#' @param ... Any additional parameters supported by \code{plot}
#'
#' @return Returns a named vector of preference scores.
#'
#' @author Luis M. Rodriguez-R [aut, cre]
#'
#' @export

enve.prefscore <- function
(
  x,
  set,
  ignore = NULL,
  signif.thr,
  plot = TRUE,
  col.above = rgb(148, 17, 0, maxColorValue = 255),
  col.equal = rgb(189, 189, 189, maxColorValue = 255),
  col.below = rgb(47, 84, 150, maxColorValue = 255),
  ...
) {
  # Normalize classes and filter universe
  x <- !!as.matrix(x)
  if(is.null(colnames(x))) colnames(x) <- 1:ncol(x)
  if(is.null(rownames(x))) rownames(x) <- 1:nrow(x)
  set <- enve.selvector(set, colnames(x))
  universe <- !enve.selvector(ignore, rownames(x))
  x.u <- x[universe, ]
  if(missing(signif.thr)) signif.thr <- 1 + 100 / length(universe)

  # Base (null) probabilities
  p_a <- (rowSums(x.u) + 1) / (ncol(x.u) + 2)
  p_b <- (colSums(x.u) + 1) / (nrow(x.u) + 2)
  p_p <- p_a %*% t(p_b)

  # Set preference score
  expected <- (rowSums(p_p[, set]) - rowSums(p_p[, !set])) / sum(p_p)
  observed <- (rowSums(x.u[, set]) - rowSums(x.u[, !set])) / sum(x.u)
  y <- observed / abs(expected)
  names(y) <- rownames(x)[universe]
  y.code <- cut(y, c(-Inf, -signif.thr, signif.thr, Inf), 1:3)

  # Plot
  if(plot) {
    idx <- (1:nrow(x))[universe]
    opts.def <- list(x = idx, y = y, ylim = c(-1, 1) * max(abs(y)),
      xlab = 'Species', ylab = 'Preference score', xlim = c(0, nrow(x)+1),
      col = c(col.above, col.equal, col.below)[y.code],
      las = 1, xaxs = 'i', pch = 15)
    opts <- list(...)
    for(i in names(opts.def)) if(is.null(opts[[i]])) opts[[i]] <- opts.def[[i]]
    do.call('plot', opts)
    abline(h = 0, lty = 1, col = rgb(0, 0, 0, 1/4))
    abline(h = c(-1, 1) * signif.thr, lty = 2, col = rgb(0, 0, 0, 1/4))
  }

  # Print and return
  print(table(c(c('<', '=', '>')[y.code], rep('Tot', length(y.code)))))
  cat('---------\n')
  return(y)
}
