#!/bin/bash

cd $(dirname -- $0)/enveomics.R
rm man/*
echo '
\name{phyla.counts}
\docType{data}
\alias{phyla.counts}
\title{Counts of microbial phyla in four sites}
\description{
  This data set gives the counts of phyla in three different
  sites.
}
\usage{phyla.counts}
\format{A data frame with 9 rows (phyla) and 4 rows (sites).}
\keyword{datasets}
' > man/phyla.counts.Rd
echo '
\name{growth.curves}
\docType{data}
\alias{growth.curves}
\title{Bacterial growth curves for three Escherichia coli mutants}
\description{
  This data set provides time (first column) and three triplicated growth
  curves as optical density at 600nm (OD_600nm) for different mutants of E.
  coli.
}
\usage{growth.curves}
\format{A data frame with 16 rows (times) and 10 rows (times and OD_600nm).}
\keyword{datasets}
' > man/growth.curves.Rd
echo "
library(inlinedocs)
package.skeleton.dx('./');
" | R --vanilla
cat man/enveomics.R-package.Rd | tr -d '\r' \
   | grep -v '^}$' | grep -v '^\\author{' \
   | grep -v '^Maintainer' \
   | perl -pe 's/^\\keyword/}\n\\author{Luis M. Rodriguez-R <lmrodriguezr\@gmail.com> [aut, cre]}\n\n\\keyword/' \
   | perl -lwe '$/=\0; $_=<>; s/^\\details{\n+([^}].*\n+)*}\n+//mg; print' \
   > o && mv o man/enveomics.R-package.Rd
#[[ ! -d inst/doc ]] && mkdir -p inst/doc
#pandoc -o inst/doc/enveomics.R.pdf -f markdown_github README.md

