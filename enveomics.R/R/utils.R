

enve.col.alpha <- function
  ### Modify alpha in a color (or vector of colors).
    (col,
    ### Color or vector of colors. It can be any value supported by `col2rgb`, 
    ### such as 'darkred' or '#009988'.
    alpha=1/2
    ### Alpha value to add to the color, from 0 to 1.
    ){
  return(
    apply(col2rgb(col), 2,
      function(x) do.call(rgb, as.list(c(x[1:3]/256, alpha))) ) )
  ### Returns a color or a vector of colors in hex notation including alpha.
}

enve.truncate <- function
  ### Removes the `n` highest and lowest values from a vector, and applies a
  ### summary function. The value of `n` is determined such that the central
  ### range is used, corresponding to the `f` fraction of values.
    (x,
    ### A vector of numbers.
    f=0.95,
    ### The fraction of values to retain.
    FUN=mean
    ### Summary function to apply to the vectors. To obtain the truncated
    ### vector itself, use `c`.
    ){
  n <- round(length(x)*(1-f)/2)
  y <- sort(x)[ -c(seq(1, n), seq(length(x)+1-n, length(x))) ]
  return(FUN(y))
  ### Returns the summary (`FUN`) of the truncated vector.
}

