#' Enveomics: Color Alpha
#' 
#' Modify alpha in a color (or vector of colors).
#'
#' @param col Color or vector of colors. It can be any value supported by 
#' \code{\link[grDevices]{col2rgb}}, such as \code{darkred} or \code{#009988}.
#' @param alpha Alpha value to add to the color, from 0 to 1.
#'
#' @return Returns a color or a vector of colors in \emph{hex} notation, 
#' including \code{alpha}.
#'
#' @author Luis M. Rodriguez-R [aut, cre]
#'
#' @export

enve.col.alpha <- function
    (col,
    alpha=1/2
    ){
  return(
    apply(col2rgb(col), 2,
      function(x) do.call(rgb, as.list(c(x[1:3]/256, alpha))) ) )
}

#' Enveomics: Truncate
#' 
#' Removes the \code{n} highest and lowest values from a vector, and applies
#' summary function. The value of \code{n} is determined such that the central
#' range is used, corresponding to the \code{f} fraction of values.
#'
#' @param x A vector of numbers.
#' @param f The fraction of values to retain.
#' @param FUN Summary function to apply to the vectors. To obtain the 
#' truncated vector itself, use \code{c}.
#' 
#' @return Returns the summary \code{(FUN)} of the truncated vector.
#' 
#' @author Luis M. Rodriguez-R [aut, cre]
#'
#' @export

enve.truncate <- function
    (x,
    f=0.95,
    FUN=mean
    ){
  n <- round(length(x)*(1-f)/2)
  y <- sort(x)[ -c(seq(1, n), seq(length(x)+1-n, length(x))) ]
  return(FUN(y))
}

#' Enveomics: Selection vector
#' 
#' Normalizes a selection vector \code{sel} to a logical vector with indexes
#' from \code{dim.names}.
#'
#' @param sel A vector of numbers, characters, or booleans.
#' @param dim.names A vector of names from which to select.
#' 
#' @return Returns a logical vector with the same length as \code{dim.name}.
#' 
#' @author Luis M. Rodriguez-R [aut, cre]
#'
#' @export

enve.selvector <- function(sel, dim.names) {
  if(is.logical(sel)) {
    if(length(sel) != length(dim.names))
      stop('sel is logical but differs in length from dim.names')
    sel
  } else if(is.numeric(sel)) {
    if(max(sel) > length(dim.names))
      stop('sel includes numeric index beyond the length of dim.names')
    1:length(dim.names) %in% sel
  } else {
    if(any(!sel %in% dim.names))
      stop('sel includes character index missing from dim.names')
    dim.names %in% sel
  }
}
