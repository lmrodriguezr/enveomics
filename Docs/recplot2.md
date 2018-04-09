# Recruitment plots

**Working document: Technical details**

## To do

- [x] Document structure
- [x] Package: `enveomics.R`
- [ ] Recruitment plots: `enve.recplot2`
- [ ] Peak-finder: `enve.recplot2.findPeaks`
- [ ] Core-genome peak: `enve.recplot2.corePeak`
- [ ] Gene-content diversity: `enve.recplot2.extractWindows`
- [ ] Compare identity profiles: `enve.recplot2.compareIdentities`

## Aims

This document aims to cover the technical aspects of the recruitment plot functions in the
`enveomics.R` package, focusing on the peak finder and gene-content diversity analyses.

## Caveats

This is a __*working document*__, describing  unstable and/or experimental code. The material
here is susceptible of changes without warning, pay attention to the modification date and (if
in doubt) the commit history. The definitions and default parameters of the functions described
here may change in the near future as result of further experimentation or more stable
implementations.

Some of the functions described here may return unexpected results with your data. Carefully
evaluate all of your results.

## Package: `enveomics.R`

The functionalities described here are provided by the `enveomics.R` package. Some features
described here are updated more frequently than the official
[CRAN releases](https://CRAN.R-project.org/package=enveomics.R). In order to have the latest
updates (package HEAD), download (or update), and install this git repository.

### Quick installation guide

- [ ] Install the latest release in R
- **R>** `install.packages(c('enveomics.R','optparse'))`
- [ ] Get the HEAD code :octocat:
- **$>** `git clone https://github.com/lmrodriguezr/enveomics.git`
- [ ] Install the HEAD code
- **$>** `R CMD INSTALL ./enveomics/enveomics.R`
- [ ] Load the library in R
- **R>** `library(enveomics.R)`


