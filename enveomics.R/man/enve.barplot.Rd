\name{enve.barplot}
\alias{enve.barplot}
\title{enve barplot}
\description{Creates nice barplots from tab-delimited tables}
\usage{enve.barplot(x, sizes, top = 25, colors.per.group = 9, bars.width = 4, 
    legend.ncol = 1, other.col = "#000000", add.trend = FALSE, 
    organic.trend = FALSE, sort.by = median, min.report = 101, 
    order = NULL)}
\arguments{
  \item{x}{Can be either the input data or the path to the file containing the table. If it
contains the data, it must be a data frame or an object coercible to data frame.
If it is a path, it must point to a tab-delimited file containing header (first
row) and row names (first column).}
  \item{sizes}{A numeric vector containing the real size of the samples (columns) in the same
order of the input table. If set, the values are assumed to be 100\%, otherwise
the sum of the columns is used.}
  \item{top}{Maximum number of categories to display. Any additional categories will be listed
as "Others".}
  \item{colors.per.group}{Number of categories in the first two saturation groups of colors. The third group
contains the remaining categories if needed.}
  \item{bars.width}{Width of the barplot with respect to the legend.}
  \item{legend.ncol}{Number of columns in the legend.}
  \item{other.col}{Color of the "Others" category.}
  \item{add.trend}{Controls if semi-transparent areas are to be plotted between the bars to connect
the regions (trend regions).}
  \item{organic.trend}{Controls if the trend regions are to be smoothed (curves). By default, trend
regions have straight edges. If TRUE, forces add.trend=TRUE.}
  \item{sort.by}{Any function that takes a numeric vector and returns a numeric scalar. This
function is applied to each row, and the resulting values are used to sort the
rows (decreasingly). Good options include: sd, min, max, mean, median.}
  \item{min.report}{Minimum percentage to report the value in the plot. Any value above 100 indicates
that no values are to be reported.}
  \item{order}{Controls how the rows should be ordered. If NULL (default), sort.by is applied per
row and the results are sorted decreasingly. If NA, no sorting is performed, i.e.,
the original order is respected. If a vector is provided, it is assumed to be the
custom order to be used (either by numeric index or by row names).}
}



\author{Luis M. Rodriguez-R <lmrodriguezr@gmail.com> [aut, cre]}




\examples{
# Create a barplot sorted by standard deviation displaying the abundance of categories with >2\%
enve.barplot('taxo-counts.txt', sort.by=sd, min.report=2);
}
