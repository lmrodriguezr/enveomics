# Recruitment plots

**Working document: Technical details**

## To do

- [x] Document structure
- [x] Package: `enveomics.R`
- [x] Recruitment plots: `enve.recplot2`
- [x] Peak-finder: `enve.recplot2.findPeaks`
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

---

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

---

## Recruitment plots: `enve.recplot2`

The first step in this analysis is the mapping of reads to the genome, processed with
[BlastTab.catsbj.pl](http://enve-omics.ce.gatech.edu/enveomics/docs?t=BlastTab.catsbj.pl).
We'll assume the mapping is saved in the file `my-mapping.tab` and this is also the
prefix of the processed files.

Once you have these input files (`.rec` and `.lim`), you can build the recruitment plot.
For this, you'll have two options.

### Option 1: Using the `BlastTab.recplot2.R` stand-alone script

The stand-alone script
[BlastTab.recplot2.R](http://enve-omics.ce.gatech.edu/enveomics/docs?t=BlastTab.recplot2.R)
is the easiest option to run, and should be the preferred method if you're automating
this analysis to process several mappings, but it doesn't offer access to advanced options.

You can run it like this using two CPUs:
```bash
BlastTab.recplot2.R --prefix my-mapping.tab --threads 2 my-recplot.rdata my-recplot.pdf
```

> **NOTE 1**: It's NOT recommended to map reads against genes, the recommended strategy is to
> map against contigs. However, if you did map reads against genes, you may want to use the
> `--pos-breaks 0` option to use each gene as a recruitment window.
> 
> **NOTE 2**: If you want to plot the population peaks at this step, simply pass the
> `--peaks-col darkred` option.

Now you should have two output files: `my-recplot.rdata`, containing your `enve.RecPlot2` R
object, and `my-recplot.pdf` with the graphical output of the recruitment plot.

### Option 2: Using the `enve.recplot2` R function

If you require access to advanced options, or for some other reason prefer to calculate the
recruitment plot interactively, you can directly use the `enve.recplot2` R function. This is
and example session in R:
```R
# Load the package
library(enveomics.R)
# Open the PDF
pdf('my-recplot.pdf')
# Build and plot the object using two threads
rp <- enve.recplot2('my-mapping.tab', threads=2)
# Close the PDF
dev.off()
# Save the object
save(rp, file='my-recplot.rdata')
```

> **IMPORTANT**: Remember to save the `enve.RecPlot2` R object (that's the last line above).

Naturally, you may want to see what other (advanced) options you have. You can access the
documentation of the function in R using `?enve.recplot2`.

---

## Peak-finder: `enve.recplot2.findPeaks`

In this step we will try to identify one or multiple population peaks corresponding to different
sub-populations and/or composites of sub-populations.

> **NOTE** This step can be performed together with the step above, but we separate here it for
> two reasons: **1** This step is much more unstable but less computationally demanding than the
> step before, so it makes sense to re-run only this part with different parameters and/or
> package updates; and **2** We want to save the R objects independently, so the following steps
> are more clear.



