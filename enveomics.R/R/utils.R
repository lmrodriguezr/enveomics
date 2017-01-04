

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

