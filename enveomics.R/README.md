## enveomics.R

Execute `R CMD INSTALL ./` to install enveomics.R. If you're using a
non-standard R location, open your own R in this location and execute:
```R
    install.packages('./', repos=NULL);
```

To load enveomics.R, simply execute:
```R
    library(enveomics.R);
```

And open help messages using any of the following commands:
```R
    ?enveomics.R
    ?enve.barplot
    ?enve.recplot2
    ?enve.recplot2.findPeaks
    ?enve.recplot2.corePeak
    ?enve.prune.dist
    ?enve.tribs
    ?enve.tribs.test
```

You can run some examples using these libraries in the
[enveomics-GUI](https://github.com/lmrodriguezr/enveomics-gui).


## Changelog

* 1.0.1: enve.recplot2 now supports pos.breaks=0 to define a
  bin per subject sequence.

