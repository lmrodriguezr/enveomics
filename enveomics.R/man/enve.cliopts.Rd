\name{enve.cliopts}
\alias{enve.cliopts}
\title{enve cliopts}
\description{Generates nicely formatted command-line interfaces for
functions (_closures_ only).}
\usage{enve.cliopts(fx, rd_file, positional_arguments, usage, mandatory = c(), 
    vectorize = c(), ignore = c(), number = c(), defaults = list(), 
    o_desc = list(), p_desc = "")}
\arguments{
  \item{fx}{Function for which the interface should be generated.}
  \item{rd_file}{(Optional) .Rd file with the standard documentation of the function.}
  \item{positional_arguments}{(Optional) Number of _positional_ arguments passed to parse_args
(package:optparse).}
  \item{usage}{(Optional) Usage passed to OptionParser (package:optparse).}
  \item{mandatory}{Mandatory arguments.}
  \item{vectorize}{Arguments of the function to vectorize (comma-delimited). If numeric,
use also `number`.}
  \item{ignore}{Arguments of the function to ignore.}
  \item{number}{Force these arguments as numerics. Useful for numeric
vectors (see `vectorize`) or arguments with no defaults.}
  \item{defaults}{Defaults to use instead of the ones provided by the formals.}
  \item{o_desc}{Descriptions of the options. Help from `rd` is ignored for arguments
present in this list.}
  \item{p_desc}{Description of the function. Help from `rd` is ignored for the
function description unless this value is an empty string.}
}

\value{Returns a `list` with keys: `options`, a named list with the values for
the function's arguments; and `args`, a vector with zero or more strings
containing the positional arguments.}

\author{Luis M. Rodriguez-R <lmrodriguezr@gmail.com> [aut, cre]}





