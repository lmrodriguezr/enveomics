# Recruitment plots

## Aims

This document aims to cover the technical aspects of the recruitment plot functions in the
`enveomics.R` package, focusing on the peak finder and gene-content diversity analyses.

## Caveats

This is a __*working document*__, describing  unstable and/or experimental code. The material
here is susceptible of changes without warning, pay attention to the modification date and (if
in doubt) the commit history. The definitions and default parameters of the functions described
here may change in the near future as result of further experimentation or more stable
implementations.

The current document was generated and tested with the `enveomics.R` package version 1.3. To
check your current version in R, use `packageVersion('enveomics.R')`.

> **IMPORTANT**: Some of the functions described here may return unexpected results with your data.
> Carefully evaluate all your results.

---

## Package: `enveomics.R`

The functionalities described here are provided by the `enveomics.R` package. Some features
described here are updated more frequently than the official
[CRAN releases](https://CRAN.R-project.org/package=enveomics.R). In order to have the latest
updates (package HEAD), download (or update), and install this git repository.

### Quick installation guide

:globe_with_meridians: To install the latest stable version available in CRAN, use in R:

```R
install.packages(c('enveomics.R','optparse'))
```

:octocat: To install the latest HEAD version (potentially unstable) available in GitHub, use in R:

```R
install.packages('devtools')
library('devtools')
install_github('lmrodriguezr/enveomics', subdir='enveomics.R')
```

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
# Build and plot the object using two threads and no peak detection
# (to turn on peak detection, simply remove `peaks.col=NA`)
rp <- enve.recplot2('my-mapping.tab', threads=2, peaks.col=NA)
# Close the PDF
dev.off()
# Save the object
save(rp, file='my-recplot.rdata')
```

> **IMPORTANT**: Remember to save the `enve.RecPlot2` R object (that's the last line above)
> before closing the R session.

Naturally, you may want to see what other (advanced) options you have. You can access the
documentation of the function in R using `?enve.recplot2`.

---

## Summary statistics

Here we explore some frequently used summary statistics from recruitment plots. First, load the
package and the `enve.RecPlot2` object you saved previously, in R:

```R
library(enveomics.R)
load('my-recplot.rdata')
```

### Average and median sequencing depth

```R
mean(enve.recplot2.seqdepth(rp)) # <- Average
median(enve.recplot2.seqdepth(rp)) # <- Median
```

The functions above only use hits with identity above the identity cutoff for "in-group" (by default: 95% identity).
In order to estimate the sequencing depth with a different identity cutoff, modify the cutoff first:

```R
rp98 <- enve.recplot2.changeCutoff(rp, 98) # <- Change to ≥98%
mean(enve.recplot2.seqdepth(rp98)) # <- Average (for the new object)
median(enve.recplot2.seqdepth(rp98)) # <- Median (for the new object)
```

### Average and median sequencing depth excluding zero-coverage windows

```R
seqdepth <- enve.recplot2.seqdepth(rp)
mean(seqdepth[seqdepth>0]) # <- Average
median(seqdepth[seqdepth>0]) # <- Median
```

### Average Nucleotide Identity from reads (ANIr)

```R
enve.recplot2.ANIr(rp) # <- Complete recruitment plot
enve.recplot2.ANIr(rp, c(90,100)) # <- All reads above 90% (recommended for intra-population)
enve.recplot2.ANIr(rp, c(95,100)) # <- Reads above 95%
enve.recplot2.ANIr(rp, c( 0, 90)) # <- Between populations (other species)
```

### Coordinates of each sequence window with their respective sequencing depth

```R
d <- enve.recplot2.coordinates(rp)
d$seqdepth <- enve.recplot2.seqdepth(rp)
d
```

### Sequencing breadth (upper boundary)

This estimate depends on the window size. The smaller the window size, the better the
estimate. When the window size is 1bp, the estimate is exact, otherwise it's consistently
biased (overestimate).

```R
mean(enve.recplot2.seqdepth(rp) > 0)
```

---

## Peak-finder: `enve.recplot2.findPeaks`

In this step we will try to identify one or multiple population peaks corresponding to different
sub-populations and/or composites of sub-populations.

> **NOTE** This step can be performed together with the step above, but we separate it here for
> two reasons: **(1)** This step is much more unstable but less computationally demanding than the
> step before, so it makes sense to re-run only this part with different parameters and/or
> package updates; and **(2)** We want to save the R objects independently, so the following steps
> are more clear.

In R:

```R
# Load the package
library(enveomics.R)
# Load the `enve.RecPlot2` object you saved previously
load('my-recplot.rdata')
# Find the peaks
peaks <- enve.recplot2.findPeaks(rp)
# Save the peaks R object (optional)
save(peaks, file='my-recplot-peaks.rdata')
# Plot the peaks in a PDF (optional)
pdf('my-recplot-peaks.pdf')
p <- plot(rp, use.peaks=peaks, layout=4) # <- Remove `layout=4` for the full plot
dev.off()
```

The key function here is `enve.recplo2.findPeaks`. This function has several parameters, depending on
the method used. To see all supported methods, use `?enve.recplot2.findPeaks`. To see all the options
of the default method (`'emauto'`) use `?enve.recplot2.findPeaks.emauto`.

---

## Gene-content diversity: `enve.recplot2.extractWindows`

In R:

```R
# Load the package and the objects (unless you're still in the same session from the last step)
library(enveomics.R)
load('my-recplot.rdata')
load('my-recplot-peaks.rdata')
# Find the peak representing the core genome
cp <- enve.recplot2.corePeak(peaks)
#-----
# The following functions illustrate how to obtain different results. Please explore the resulting
# objects and the associated documentation
#-----
# Find the coordinates of windows significantly below the average sequencing depth
div <- enve.recplot2.extractWindows(rp, cp, seq.names=TRUE)
# Add sequencing depth
div$seqdepth <- enve.recplot2.seqdepth(rp, as.numeric(rownames(div)))
# Save the coordinates as a tab-delimited table
write.table(div, 'my-low-seqdepth.tsv', quote=FALSE, sep='\t', row.names=FALSE)
# Find all the windows with sequencing depth zero
zero <- enve.recplot2.coordinates(rp, enve.recplot2.seqdepth(rp)==0)
```

---

## To do

- [x] Document structure
- [x] Package: `enveomics.R`
- [x] Recruitment plots: `enve.recplot2`
- [x] Summary statistics
- [x] Peak-finder: `enve.recplot2.findPeaks`
- [x] Gene-content diversity: `enve.recplot2.extractWindows`
- [ ] Compare identity profiles: `enve.recplot2.compareIdentities`
