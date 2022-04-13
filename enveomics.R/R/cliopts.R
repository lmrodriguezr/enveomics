#' Enveomics: Cliopts
#' 
#' Generates nicely formatted command-line interfaces for functions 
#' (\strong{closures} only).
#'
#' @param fx Function for which the interface should be generated.
#' @param rd_file (Optional) .Rd file with the standard documentation of 
#' the function.
#' @param positional_arguments (Optional) Number of \strong{positional} 
#' arguments passed to \code{\link[optparse]{parse_args}} 
#' (package: \pkg{optparse}).
#' @param usage (Optional) Usage passed to \code{\link[optparse]{OptionParser}} 
#' (package: \pkg{optparse}).
#' @param mandatory Mandatory arguments.
#' @param vectorize Arguments of the function to vectorize (comma-delimited).
#' If numeric, use also \code{number}.
#' @param ignore Arguments of the function to ignore.
#' @param number Force these arguments as numerics. Useful for numeric
#' vectors (see \code{vectorize}) or arguments with no defaults.
#' @param defaults Defaults to use instead of the ones provided by the 
#' formals.
#' @param o_desc Descriptions of the options. Help from \code{rd} is ignored
#' for arguments present in this list.
#' @param p_desc Description Description of the function. Help from \code{rd} 
#' is ignored for the function description unless this value is an empty string.
#' 
#' @return Returns a list with keys: 
#' \itemize{
#'    \item{\code{options}, a named list with the values for the function's 
#'    arguments} 
#'    \item{\code{args}, a vector with zero or more strings containing the
#'    positional arguments}}
#'
#' @author Luis M. Rodriguez-R [aut, cre]
#'
#' @export

enve.cliopts <- function(
  fx,
  rd_file,
  positional_arguments,
  usage,
  mandatory = c(),
  vectorize = c(),
  ignore    = c(),
  number    = c(),
  defaults  = list(),
  o_desc    = list(),
  p_desc    = ""
){
  # Load stuff
  if (!suppressPackageStartupMessages(
        requireNamespace("optparse", quietly = TRUE)))
    stop("Package 'optparse' is required.")
  requireNamespace("tools", quietly = TRUE)
  if (missing(positional_arguments)) positional_arguments <- FALSE
  if (missing(usage)) usage <- "usage: %prog [options]"

  # Get help (if any)
  if (!missing(rd_file)) {
    rd <- tools::parse_Rd(rd_file)
    for (i in 1:length(rd)) {
      tag <- attr(rd[[i]], "Rd_tag")
      if (tag == "\\description" && p_desc == "") {
        p_desc <- paste("\n\t", as.character(rd[[i]]), sep = "")
      } else if (tag == "\\arguments") {
        for (j in 1:length(rd[[i]])) {
          if (length(rd[[i]][[j]]) == 2) {
            name <- as.character(rd[[i]][[j]][[1]])
            if (length(o_desc[[name]]) == 1) next
            desc <- as.character(rd[[i]][[j]][[2]])
            o_desc[[name]] <- paste(gsub("\n", "\n\t\t", desc), collapse = "")
          }
        }
      }
    }
  }

  # Set options
  o_i <- 0
  opts <- list()
  f <- formals(fx)
  if (length(defaults) > 0) {
    for (i in 1:length(defaults)) f[[names(defaults)[i]]] <- defaults[[i]]
  }
  for (i in names(f)) {
    if (i == "..." || i %in% ignore) next
    o_i <- o_i + 1
    flag <- gsub("\\.", "-", i)

    optopt <- list(help = "")
    if (length(o_desc[[i]]) == 1) optopt$help <- o_desc[[i]]
    if (!is.null(f[[i]]) && !suppressWarnings(is.na(f[[i]])) &&
        is.logical(f[[i]])){
      optopt$opt_str <- paste(ifelse(f[[i]], "--no-", "--"), flag, sep = "")
      optopt$action  <- ifelse(f[[i]], "store_false", "store_true")
    } else {
      optopt$opt_str <- paste("--", flag, sep = "")
      optopt$action  <- "store"
      optopt$help <- paste(
        optopt$help, "\n\t\t[",
        ifelse(i %in% mandatory, "** MANDATORY", "default %default"),
        ifelse(i %in% vectorize, ", separate values by commas", ""),
        "].",
        sep = ""
      )
    }
    if (!is.name(f[[i]])) {
      optopt$default <- f[[i]]
      optopt$metavar <- class(f[[i]])
    }
    if (i %in% number) optopt$metavar <- "NUMERIC"
    optopt$dest <- i

    opts[[o_i]] <- do.call(optparse::make_option, optopt)
  }
  opt <- optparse::parse_args(
    optparse::OptionParser(
      option_list = opts, description = p_desc, usage = usage
    ),
    positional_arguments = positional_arguments
  )
  
  # Post-hoc checks
  if (length(opt[["options"]]) == 0) opt <- list(options = opt, args = c())
  for (i in mandatory) {
    if(length(opt$options[[i]]) == 0) stop("Missing mandatory argument: ", i)
  }
  for (i in vectorize) {
    if (length(opt$options[[i]]) == 1)
      opt$options[[i]] <- strsplit(opt$options[[i]], ",")[[1]]
  }
  for (i in number) {
    if (length(opt$options[[i]]) > 0)
      opt$options[[i]] <- as.numeric(opt$options[[i]])
  }
  opt$options$help <- NULL

  return(opt)
}

