\name{enve.recplot2.compareIdentities}
\alias{enve.recplot2.compareIdentities}
\title{enve recplot2 compareIdentities}
\description{Compare the distribution of identities between two enve.RecPlot2 objects.}
\usage{enve.recplot2.compareIdentities(x, y, method = "hellinger", pseudocounts = 0, 
    max.deviation = 0.75)}
\arguments{
  \item{x}{First enve.RecPlot2 object.}
  \item{y}{Second enve.RecPlot2 object.}
  \item{method}{Distance method to use. This should be (an unambiguous abbreviation of)
one of:
"hellinger" (Hellinger, 1090, doi:10.1515/crll.1909.136.210),
"bhattacharyya" (Bhattacharyya, 1943, Bull. Calcutta Math. Soc. 35),
"kl" or "kullback–leibler" (Kullback & Leibler, 1951,
doi:10.1214/aoms/1177729694), or "euclidean".}
  \item{pseudocounts}{Smoothing parameter for Laplace smoothing. Use 0 for no smoothing, or
1 for add-one smoothing.}
  \item{max.deviation}{Maximum mean deviation between identity breaks tolerated (as percent
identity). Difference in number of id.breaks is never tolerated.}
}



\author{Luis M. Rodriguez-R [aut, cre]}





