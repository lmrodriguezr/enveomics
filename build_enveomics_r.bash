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

