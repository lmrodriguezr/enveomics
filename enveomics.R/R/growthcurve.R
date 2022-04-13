#==============> S4 classes

#' Enveomics: Growth Curve S4 Class
#' 
#' Enve-omics representation of fitted growth curves.
#'
#' @slot design \code{(array)} Experimental design of the experiment.
#' @slot models \code{(list)} Fitted growth curve models.
#' @slot predict \code{(list)} Fitted growth curve values.
#' @slot call \code{(call)} Call producing this object.
#' 
#' @author Luis M. Rodriguez-R [aut, cre]
#' 
#' @exportClass

enve.GrowthCurve <- setClass(
  "enve.GrowthCurve",
  representation(
    design  = "array",
    models  = "list",
    predict = "list",
    call    = "call"
  ), package = "enveomics.R"
)

#' Attribute accessor
#' 
#' @param x Object
#' @param name Attribute name
setMethod("$", "enve.GrowthCurve", function(x, name) attr(x, name))

#==============> S4 methods

#' Enveomics: Plot of Growth Curve
#' 
#' Plots an \code{\link{enve.GrowthCurve}} object.
#' 
#' @param x An \code{\link{enve.GrowthCurve}} object to plot.
#' @param col Base colors to use for the different samples. Can be recycled.
#' By default, grey for one sample or rainbow colors for more than one.
#' @param pt.alpha Color alpha for the observed data points, using \code{col}
#' as a base.
#' @param ln.alpha Color alpha for the fitted growth curve, using \code{col}
#' as a base.
#' @param ln.lwd Line width for the fitted curve.
#' @param ln.lty Line type for the fitted curve.
#' @param band.alpha Color alpha for the confidence interval band of the 
#' fitted growth curve, using \code{col} as a base.
#' @param band.density Density of the filling pattern in the interval band.
#' If \code{NULL}, a solid color is used.
#' @param band.angle Angle of the density filling pattern in the interval 
#' band. Ignored if \code{band.density} is \code{NULL}.
#' @param xp.alpha Color alpha for the line connecting individual experiments,
#' using \code{col} as a base.
#' @param xp.lwd Width of line for the experiments.
#' @param xp.lty Type of line for the experiments.
#' @param pch Point character for observed data points.
#' @param new Should a new plot be generated? If \code{FALSE}, the existing
#' canvas is used.
#' @param legend Should the plot include a legend? If \code{FALSE}, no legend
#' is added. If \code{TRUE}, a legend is added in the bottom-right corner.
#' Otherwise, a legend is added in the position specified as \code{xy.coords}.
#' @param add.params Should the legend include the parameters of the fitted 
#' model?
#' @param ... Any other graphic parameters.
#' 
#' @return No return value.
#' 
#' @author Luis M. Rodriguez-R [aut, cre]
#' 
#' @method plot enve.GrowthCurve
#' @export
plot.enve.GrowthCurve <- function(
  x,
  col,
  pt.alpha     = 0.9,
  ln.alpha     = 1.0,
  ln.lwd       = 1,
  ln.lty       = 1,
  band.alpha   = 0.4,
  band.density = NULL,
  band.angle   = 45,
  xp.alpha     = 0.5,
  xp.lwd       = 1,
  xp.lty       = 1,
  pch          = 19,
  new          = TRUE,
  legend       = new,
  add.params   = FALSE,
  ...
) {
  # Arguments
  if (missing(col)) {
    col <-
      if (length(x$design) == 0) grey(0.2)
      else rainbow(length(x$design), v = 3/5, s = 3/5)
  }

  if (new) {
    # Initiate canvas
    od.fit.max <- max(sapply(x$predict, function(x) max(x[, "upr"])))
    od.obs.max <- max(sapply(x$models, function(x) max(x$data[, "od"])))
    opts <- list(...)
    plot.defaults <- list(
      xlab = "Time", ylab = "Density", xlim = range(x$predict[[1]][, "t"]),
      ylim = c(0, max(od.fit.max, od.obs.max))
    )
    for (i in names(plot.defaults)) {
      if(is.null(opts[[i]])) opts[[i]] <- plot.defaults[[i]]
    }
    opts[["x"]] <- 1
    opts[["type"]] <- "n"
    do.call(plot, opts)
  }

  # Graphic default
  pch <- rep(pch, length.out = length(x$design))
  col <- rep(col, length.out = length(x$design))
  pt.col     <- enve.col2alpha(col, pt.alpha)
  ln.col     <- enve.col2alpha(col, ln.alpha)
  band.col   <- enve.col2alpha(col, band.alpha)
  xp.col     <- enve.col2alpha(col, xp.alpha)
  band.angle <- rep(band.angle, length.out = length(x$design))
  if (!all(is.null(band.density))) {
    band.density <- rep(band.density, length.out = length(x$design))
  }
  
  for (i in 1:length(x$design)) {
    # Observed data
    d <- x$models[[i]]$data
    points(d[, "t"], d[, "od"], pch = pch[i], col = pt.col[i])
    for (j in unique(d[, "replicate"])) {
      sel <- d[, "replicate"] == j
      lines(d[sel, "t"], d[sel, "od"],
            col = xp.col[i], lwd = xp.lwd, lty = xp.lty)
    }

    # Fitted growth curves
    if (x$models[[i]]$convInfo$isConv) {
      d <- x$predict[[i]]
      lines(d[, "t"], d[, "fit"], col = ln.col[i], lwd = ln.lwd, lty = ln.lty)
      polygon(c(d[, "t"], rev(d[, "t"])), c(d[, "lwr"], rev(d[, "upr"])),
              border = NA, col = band.col[i], density = band.density[i],
              angle = band.angle[i])
    }
  }

  if (!all(is.logical(legend)) || legend) {
    if (all(is.logical(legend))) legend <- "bottomright"
    legend.txt <- names(x$design)
    if (add.params) {
      for (p in names(coef(x$models[[1]]))) {
        legend.txt <- paste(
          legend.txt, ", ", p, "=",
          sapply(x$models, function(x) signif(coef(x)[p], 2)) , sep = ""
        )
      }
    }
    legend(legend, legend = legend.txt, pch = pch, col = ln.col)
  }
}

#' Enveomics: Summary of Growth Curve
#' 
#' Summary of an \code{\link{enve.GrowthCurve}} object.
#' 
#' @param object An \code{\link{enve.GrowthCurve}} object.
#' @param ... No additional parameters are currently supported.
#' 
#' @return No return value.
#' 
#' @author Luis M. Rodriguez-R [aut, cre]
#'
#' @method summary enve.GrowthCurve
#' @export

summary.enve.GrowthCurve <- function(object, ...) {
  x <- object
  cat("===[ enve.GrowthCurves ]------------------\n")
  for (i in names(x$design)) {
    cat(i, ":\n", sep = "")
    if (x$models[[i]]$convInfo$isConv) {
      for (j in names(coef(x$models[[i]]))) {
        cat("  - ", j, " = ", coef(x$models[[i]])[j], "\n", sep = "")
      }
    } else {
      cat("  Model didn't converge:\n    ",
          x$models[[i]]$convInfo$stopMessage, "\n", sep = "")
    }
    cat(
      "  ", nrow(x$models[[i]]$data), " observations, ",
      length(unique(x$models[[i]]$data[, "replicate"])), " replicates.\n",
      sep = ""
    )
  }
  cat("------------------------------------------\n")
  cat("call:", as.character(attr(x, "call")), "\n")
  cat("------------------------------------------\n")
}

#==============> Core functions

#' Enveomics: Growth Curve
#' 
#' Calculates growth curves using the logistic growth function.
#' 
#' @param x Data frame (or coercible) containing the observed growth data
#' (e.g., O.D. values). Each column is an independent growth curve and each
#' row is a time point. \code{NA}'s are allowed.
#' @param times Vector with the times at which each row was taken. By default,
#' all rows are assumed to be part of constantly periodic measurements.
#' @param triplicates If \code{TRUE}, the columns are assumed to be sorted by
#' sample with three replicates by sample. It requires a number of columns 
#' multiple of 3.
#' @param design Experimental design of the data. An \strong{array} of mode list
#' with sample names as index and the list of column names in each sample as 
#' the values. By default, each column is assumed to be an independent sample
#' if \code{triplicates} is \code{FALSE}, or every three columns are assumed 
#' to be a sample if \code{triplicates} is \code{TRUE}. In the latter case, 
#' samples are simply numbered.
#' @param new.times Values of time for the fitted curve.
#' @param level Confidence (or prediction) interval in the fitted curve.
#' @param interval Type of interval to be calculated for the fitted curve.
#' @param plot Should the growth curve be plotted?
#' @param FUN Function to fit. By default: logistic growth with paramenters
#' \code{K}: carrying capacity, 
#' \code{r}: intrinsic growth rate, and
#' \code{P0}: Initial population.
#' @param nls.opt Any additional options passed to \code{nls}.
#' @param ... Any additional parameters to be passed to 
#' \code{plot.enve.GrowthCurve}.
#' 
#' @return Returns an \code{\link{enve.GrowthCurve}} object.
#'
#' @author Luis M. Rodriguez-R [aut, cre]
#' 
#' @examples 
#' # Load data
#' data("growth.curves", package = "enveomics.R", envir = environment())
#' 
#' # Generate growth curves with different colors
#' g <- enve.growthcurve(growth.curves[, -1], growth.curves[, 1],
#'                       triplicates = TRUE)
#' 
#' # Generate black-and-white growth curves with different symbols
#' plot(g, pch=15:17, col="black", band.density=45, band.angle=c(-45,45,0))
#'
#' @export
enve.growthcurve <- function(
  x,
  times       = 1:nrow(x),
  triplicates = FALSE,
  design,
  new.times   = seq(min(times), max(times), length.out = length(times) * 10),
  level       = 0.95,
  interval    = c("confidence", "prediction"),
  plot        = TRUE,
  FUN = function(t, K, r, P0) K * P0 * exp(r * t) / (K + P0 * (exp(r * t) - 1)),
  nls.opt     = list(),
  ...
) {
  # Arguments
  if (missing(design)) {
    design <-
      if(triplicates)
        tapply(
          colnames(x),
          colnames(x)[rep(1:(ncol(x) / 3) * 3 - 2, each = 3)],
          c, simplify = FALSE
        )
      else tapply(colnames(x), colnames(x), c, simplify = FALSE)
  }
  mod <- list()
  fit <- list()
  interval <- match.arg(interval)
  enve._growth.fx <- NULL
  enve._growth.fx <<- FUN

  for (sample in names(design)) {
    od <- c()
    for (col in design[[sample]]) {
      od <- c(od, x[, col])
    }
    data <- data.frame(
      t = rep(times, length(design[[sample]])), od = od,
      replicate = rep(1:length(design[[sample]]), each = length(times))
    )
    data <- data[!is.na(data$od), ]
    opts <- nls.opt
    opts[["data"]] <- data
    opt.defaults <- list(
      formula = od ~ enve._growth.fx(t, K, r, P0),
      algorithm = "port", lower = list(P0 = 1e-16),
      control = nls.control(warnOnly = TRUE),
      start = list(
        K  = 2 * max(data$od),
        r  = length(times) / max(data$t),
        P0 = min(data$od[data$od > 0])
      )
    )
    for (i in names(opt.defaults)) {
      if (is.null(opts[[i]])) {
        opts[[i]] <- opt.defaults[[i]]
      }
    }
    mod[[sample]] <- do.call(nls, opts)
    fit[[sample]] <- cbind(
      t = new.times,
      predFit(
        mod[[sample]], level = level, interval = interval,
        newdata = data.frame(t = new.times)
      )
    )
  }
  enve._growth.fx <<- NULL
  gc <- new(
    "enve.GrowthCurve",
    design = design, models = mod, predict = fit, call = match.call()
  )
  if (plot) plot(gc, ...)
  return(gc)
}

#' Enveomics: Color to Alpha (deprecated)
#' 
#' Takes a vector of colors and sets the alpha.
#'
#' DEPRECATED: Use instead \code{\link{enve.col.alpha}}.
#' 
#' @param x A vector of any value base colors.
#' @param alpha Alpha level to set, in the [0, 1] range.
#' 
#' @return A vector of colors with alpha set.
#' 
#' @author Luis M. Rodriguez-R [aut, cre]
#' 
#' @export
enve.col2alpha <- function(x, alpha) {
  out <- c()
  for(i in x){
    opt <- as.list(col2rgb(i)[, 1])
    opt[["alpha"]] <- alpha * 255
    opt[["maxColorValue"]] <- 255
    out <- c(out, do.call(rgb, opt))
  }
  names(out) <- names(x)
  return(out)
}

