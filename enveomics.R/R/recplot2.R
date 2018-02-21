#==============> Define S4 classes
setClass("enve.RecPlot2",
   ### Enve-omics representation of Recruitment plots. This object can
   ### be produced by `enve.recplot2` and supports S4 method plot.
   representation(
   counts='matrix',		##<< Counts as a two-dimensional histogram.
   pos.counts.in='numeric',	##<< Counts of in-group hits per position bin.
   pos.counts.out='numeric',	##<< Counts of out-group hits per position bin.
   id.counts='numeric',		##<< Counts per ID bin.
   id.breaks='numeric',		##<< Breaks of identity bins.
   pos.breaks='numeric',	##<< Breaks of position bins.
   seq.breaks='numeric',
   peaks='list',                ##<< Peaks identified in the recplot.
   ### Limits of the subject sequences after concatenation.
   seq.names='character',	##<< Names of the subject sequences.
   id.metric='character',	##<< Metric used as 'identity'.
   id.ingroup='logical',	##<< Identity bins considered in-group.
   call='call')			##<< Call producing this object.
   ,package='enveomics.R'
   );
setClass("enve.RecPlot2.Peak",
### Enve-omics representation of a peak in the sequencing depth histogram
### of a Recruitment plot (see `enve.recplot2.findPeaks`).
   representation(
   dist='character',
   ### Distribution of the peak. Currently supported: 'norm' (normal) and 'sn'
   ### (skew-normal).
   values='numeric',
   ### Sequencing depth values predicted to conform the peak.
   values.res='numeric',
   ### Sequencing depth values not explained by this or previously identified
   ### peaks.
   mode='numeric',
   ### Seed-value of mode anchoring the peak.
   param.hat='list',
   ### Parameters of the distribution. A list of two values if dist='norm' (sd
   ### and mean), or three values if dist='sn' (omega=scale, alpha=shape, and
   ### xi=location). Note that the "dispersion" parameter is always first and
   ### the "location" parameter is always last.
   n.hat='numeric',
   ### Number of bins estimated to be explained by this peak. This should
   ### ideally be equal to the length of `values`, but it's not and integer.
   n.total='numeric',
   ### Total number of bins from which the peak was extracted. I.e., total
   ### number of position bins with non-zero sequencing depth in the recruitment
   ### plot (regardless of peak count).
   err.res='numeric',
   ### Error left after adding the peak (mower) or log-likelihood (em or emauto).
   merge.logdist='numeric',
   ### Attempted `merge.logdist` parameter.
   seq.depth='numeric',
   ### Best estimate available for the sequencing depth of the peak (centrality).
   log='logical'
   ### Indicates if the estimation was performed in natural logarithm space
   ));
setMethod("$", "enve.RecPlot2", function(x, name) attr(x, name))
setMethod("$", "enve.RecPlot2.Peak", function(x, name) attr(x, name))

#==============> Define S4 methods
plot.enve.RecPlot2 <- function
   ### Plots an `enve.RecPlot2` object.
      (x,
      ### `enve.RecPlot2` object to plot.
      layout=matrix(c(5,5,2,1,4,3), nrow=2),
      ### Matrix indicating the position of the different panels in the layout,
      ### where:
      ###   0: Empty space,
      ###   1: Counts matrix,
      ###   2: position histogram (sequencing depth),
      ###   3: identity histogram,
      ###   4: Populations histogram (histogram of sequencing depths),
      ###   5: Color scale for the counts matrix (vertical),
      ###   6: Color scale of the counts
      ### matrix (horizontal). Only panels indicated here will be plotted. To
      ### plot only one panel simply set this to the number of the panel you
      ### want to plot.
      widths=c(1,7,2),
      ### Relative widths of the columns of `layout`.
      heights=c(1,2),
      ### Relative heights of the rows of `layout`.
      palette=grey((100:0)/100),
      ### Colors to be used to represent the counts matrix, sorted from no hits
      ### to the maximum sequencing depth.
      underlay.group=TRUE,
      ### If TRUE, it indicates the in-group and out-group areas couloured based
      ### on `in.col` and `out.col`. Requires support for semi-transparency.
      peaks.col='darkred',
      ### If not NA, it attempts to represent peaks in the population histogram
      ### in the specified color. Set to NA to avoid peak-finding.
      id.lim=range(x$id.breaks),
      ### Limits of identities to represent.
      pos.lim=range(x$pos.breaks),
      ### Limits of positions to represent (in bp, regardless of `pos.units`).
      pos.units=c('Mbp','Kbp','bp'),
      ### Units in which the positions should be represented (powers of 1,000
      ### base pairs).
      mar=list('1'=c(5,4,1,1)+.1, '2'=c(ifelse(any(layout==1),1,5),4,4,1)+.1,
	 '3'=c(5,ifelse(any(layout==1),1,4),1,2)+0.1,
	 '4'=c(ifelse(any(layout==1),1,5),ifelse(any(layout==2),1,4),4,2)+0.1,
	 '5'=c(5,3,4,1)+0.1, '6'=c(5,4,4,2)+0.1),
      ### Margins of the panels as a list, with the character representation of
      ### the number of the panel as index (see `layout`).
      pos.splines=0,
      ### Smoothing parameter for the splines in the position histogram. Zero
      ### (0) for no splines. If non-zero, requires the stats package.
      id.splines=1/2,
      ### Smoothing parameter for the splines in the identity histogram. Zero
      ### (0) for no splines. If non-zero, requires the stats package.
      in.lwd=ifelse(pos.splines>0, 1/2, 2),
      ### Line width for the sequencing depth of in-group matches.
      out.lwd=ifelse(pos.splines>0, 1/2, 2),
      ### Line width for the sequencing depth of out-group matches.
      id.lwd=ifelse(id.splines>0, 1/2, 2),
      ### Line width for the identity histogram.
      in.col='darkblue',
      ### Color associated to in-group matches.
      out.col='lightblue',
      ### Color associated to out-group matches.
      id.col='black',
      ### Color for the identity histogram.
      breaks.col='#AAAAAA40',
      ### Color of the vertical lines indicating sequence breaks.
      peaks.opts=list(),
      ### Options passed to `enve.recplot2.findPeaks`, if `peaks.col` is not NA.
      ...
      ### Any other graphic parameters (currently ignored).
   ){
   pos.units	<- match.arg(pos.units);
   pos.factor	<- ifelse(pos.units=='bp',1,ifelse(pos.units=='Kbp',1e3,1e6));
   pos.lim	<- pos.lim/pos.factor;
   lmat <- layout;
   for(i in 1:6) if(!any(layout==i)) lmat[layout>i] <- lmat[layout>i]-1;

   layout(lmat, widths=widths, heights=heights);
   ori.mar <- par('mar');

   # Essential vars
   counts	<- x$counts

   id.ingroup	<- x$id.ingroup
   id.counts	<- x$id.counts
   id.breaks	<- x$id.breaks
   id.mids	<- (id.breaks[-length(id.breaks)]+id.breaks[-1])/2
   id.binsize	<- id.breaks[-1] - id.breaks[-length(id.breaks)]

   pos.counts.in  <- x$pos.counts.in
   pos.counts.out <- x$pos.counts.out
   pos.breaks   <- x$pos.breaks/pos.factor
   pos.mids     <- (pos.breaks[-length(pos.breaks)]+pos.breaks[-1])/2
   pos.binsize  <- (pos.breaks[-1] - pos.breaks[-length(pos.breaks)])*pos.factor

   seqdepth.in  <- pos.counts.in/pos.binsize
   seqdepth.out <- pos.counts.out/pos.binsize
   seqdepth.lim <- range(c(seqdepth.in[seqdepth.in>0],
		     seqdepth.out[seqdepth.out>0]))*c(1/2,2)

   if(underlay.group){
      in.bg  <- do.call(rgb, c(as.list(col2rgb(in.col)),
		  list(maxColorValue=256, alpha=62)));
      out.bg <- do.call(rgb, c(as.list(col2rgb(out.col)[,1]),
		  list(maxColorValue=256, alpha=52)));
   }

   # Counts matrix
   if(any(layout==1)){
      par(mar=mar[['1']]);
      plot(1, t='n', bty='l',
	 xlim=pos.lim, xlab=paste('Position in genome (',pos.units,')',sep=''),
	    xaxs='i', ylim=id.lim,  ylab=x$id.metric, yaxs='i');
      if(underlay.group){
	 rect(pos.lim[1], id.lim[1], pos.lim[2],
	    min(id.breaks[c(id.ingroup,TRUE)]), col=out.bg, border=NA);
	 rect(pos.lim[1], min(id.breaks[c(id.ingroup,TRUE)]), pos.lim[2],
	    id.lim[2], col=in.bg,  border=NA);
      }
      abline(v=x$seq.breaks/pos.factor, col=breaks.col);
      image(x=pos.breaks, y=id.breaks, z=log10(counts),col=palette,
	 bg=grey(1,0), breaks=seq(-.1,log10(max(counts)),
	 length.out=1+length(palette)), add=TRUE);
   }

   # Position histogram
   if(any(layout==2)){
      par(mar=mar[['2']]);
      if(any(layout==1)){
	 xlab=''
	 xaxt='n'
      }else{
	 xlab=paste('Position in genome (',pos.units,')',sep='')
	 xaxt='s'
      }
      plot(1,t='n', bty='l', log='y',
	 xlim=pos.lim, xlab=xlab, xaxt=xaxt, xaxs='i',
	 ylim=seqdepth.lim, yaxs='i', ylab='Sequencing depth (X)');
      abline(v=x$seq.breaks/pos.factor, col=breaks.col)
      pos.x <- rep(pos.breaks,each=2)[-c(1,2*length(pos.breaks))]
      pos.f <- rep(seqdepth.in,each=2)
      lines(pos.x, rep(seqdepth.out,each=2), lwd=out.lwd, col=out.col);
      lines(pos.x, pos.f, lwd=in.lwd, col=in.col);
      if(pos.splines > 0){
	 pos.spline <- smooth.spline(pos.x[pos.f>0], log(pos.f[pos.f>0]),
	    spar=pos.splines)
	 lines(pos.spline$x, exp(pos.spline$y), lwd=2, col=in.col)
      }
      if(any(pos.counts.out==0)) rect(pos.breaks[c(pos.counts.out==0,FALSE)],
	       seqdepth.lim[1], pos.breaks[c(FALSE,pos.counts.out==0)],
	       seqdepth.lim[1]*3/2, col=out.col, border=NA);
      if(any(pos.counts.in==0))  rect(pos.breaks[c(pos.counts.in==0,FALSE)],
	       seqdepth.lim[1], pos.breaks[c(FALSE,pos.counts.in==0)],
	       seqdepth.lim[1]*3/2, col=in.col,  border=NA);
   }

   # Identity histogram
   if(any(layout==3)){
      par(mar=mar[['3']]);
      if(any(layout==1)){
	 ylab=''
	 yaxt='n'
      }else{
	 ylab=x$id.metric
	 yaxt='s'
      }
      if(sum(id.counts>0) >= 4){
	 id.counts.range <- range(id.counts[id.counts>0])*c(1/2,2);
	 plot(1,t='n', bty='l', log='x',
	       xlim=id.counts.range, xlab='bps per bin', xaxs='i',
	       ylim=id.lim, yaxs='i', ylab=ylab, yaxt=yaxt);
	 if(underlay.group){
	    rect(id.counts.range[1], id.lim[1], id.counts.range[2],
	       min(id.breaks[c(id.ingroup,TRUE)]), col=out.bg, border=NA);
	    rect(id.counts.range[1], min(id.breaks[c(id.ingroup,TRUE)]),
	       id.counts.range[2], id.lim[2], col=in.bg,  border=NA);
	 }
	 id.f <- rep(id.counts,each=2)
	 id.x <- rep(id.breaks,each=2)[-c(1,2*length(id.breaks))]
	 lines(id.f, id.x, lwd=id.lwd, col=id.col);
	 if(id.splines > 0){
	    id.spline <- smooth.spline(id.x[id.f>0], log(id.f[id.f>0]),
	       spar=id.splines)
	    lines(exp(id.spline$y), id.spline$x, lwd=2, col=id.col)
	 }
      }else{
	 plot(1,t='n',bty='l',xlab='', xaxt='n', ylab='', yaxt='n')
	 text(1,1,labels='Insufficient data', srt=90)
      }
   }

   # Populations histogram
   peaks <- NA;
   if(any(layout==4)){
      par(mar=mar[['4']]);
      if(any(layout==2)){
	 ylab=''
	 yaxt='n'
      }else{
	 ylab='Sequencing depth (X)'
	 yaxt='s'
      }
      h.breaks <- seq(log10(seqdepth.lim[1]*2), log10(seqdepth.lim[2]/2),
	 length.out=200);
      h.in <- hist(log10(seqdepth.in), breaks=h.breaks, plot=FALSE);
      h.out <- hist(log10(seqdepth.out), breaks=h.breaks, plot=FALSE);
      plot(1, t='n', log='y',
	 xlim=range(c(h.in$counts,h.out$counts,sum(pos.counts.in==0))),
	 xaxs='r', xlab='', xaxt='n', ylim=seqdepth.lim, yaxs='i', ylab=ylab,
	 yaxt=yaxt)
      y.tmp.in <- c(rep(10^h.in$breaks,each=2),seqdepth.lim[1]*c(1,1,3/2,3/2))
      y.tmp.out <- c(rep(10^h.out$breaks,each=2),seqdepth.lim[1]*c(1,1,3/2,3/2))
      lines(c(0,rep(h.out$counts,each=2),0,0,rep(sum(pos.counts.out==0),2),0),
	 y.tmp.out, col=out.col)
      polygon(c(0,rep(h.in$counts,each=2),0,0,rep(sum(pos.counts.in==0),2),0),
	 y.tmp.in, border=NA, col=in.col)
      if(!is.na(peaks.col)){
	 o	<- peaks.opts; o$x = x;
	 peaks	<- do.call(enve.recplot2.findPeaks, o);
	 h.mids <- (10^h.breaks[-1] + 10^h.breaks[-length(h.breaks)])/2
	 if(!is.null(peaks) & length(peaks)>0){
	    pf <- h.mids*0;
	    for(i in 1:length(peaks)){
	       cnt <- enve.recplot2.__peakHist(peaks[[i]], h.mids)
	       lines(cnt, h.mids, col='red');
	       pf <- pf+cnt;
	       axis(4, at=peaks[[i]]$seq.depth, letters[i], las=1, hadj=1/2)
	    }
	    lines(pf, h.mids, col='red',lwd=1.5);
            dpt <- signif(as.numeric(lapply(peaks, function(x) x$seq.depth)),2)
            frx <- signif(100*as.numeric(
                  lapply(peaks,
                    function(x) ifelse(length(x$values)==0, x$n.hat, length(x$values))/x$n.total)), 2)
            if(peaks[[1]]$err.res < 0){
              err <- paste(', LL:', signif(peaks[[1]]$err.res, 3))
            }else{
              err <- paste(', err:', signif(as.numeric(lapply(peaks, function(x) x$err.res)), 2))
            }
	    legend('topright', bty='n', cex=1/2,
                  legend=paste(letters[1:length(peaks)],'. ', dpt,'X (', frx, '%', err, ')', sep=''))
	 }
      }
   }

   # Color scale
   count.bins <- 10^seq(log10(min(counts[counts>0])), log10(max(counts)),
      length.out=1+length(palette))
   if(any(layout==5)){
      par(mar=mar[['5']]);
      plot(1,t='n',log='y',xlim=0:1,xaxt='n',xlab='',xaxs='i',
	 ylim=range(count.bins), yaxs='i', ylab='')
      rect(0,count.bins[-length(count.bins)],1,count.bins[-1],col=palette,
	 border=NA)
   }
   if(any(layout==6)){
      par(mar=mar[['6']]);
      plot(1,t='n',log='x',ylim=0:1,yaxt='n',ylab='',yaxs='i',
	 xlim=range(count.bins), xaxs='i',xlab='');
      rect(count.bins[-length(count.bins)],0,count.bins[-1],1,col=palette,
	 border=NA);
   }
   
   par(mar=ori.mar);
   return(peaks);
   ### Returns a list of `enve.RecPlot2.Peak` objects (see
   ### `enve.recplot2.findPeaks`). If `peaks.col`=NA or `layout` doesn't include
   ### 4, returns NA.
}

#==============> Define core functions
enve.recplot2 <- function(
   ### Produces recruitment plots provided that BlastTab.catsbj.pl has
   ### been previously executed.
      prefix,
      ### Path to the prefix of the BlastTab.catsbj.pl output files. At
      ### least the files .rec and .lim must exist with this prefix.
      plot=TRUE,
      ### Should the object be plotted?
      pos.breaks=1e3,
      ### Breaks in the positions histogram. It can also be a vector of break
      ### points, and values outside the range are ignored. If zero (0), it
      ### uses the sequence breaks as defined in the .lim file, which means
      ### one bin per contig (or gene, if the mapping is agains genes).
      id.breaks=300,
      ### Breaks in the identity histogram. It can also be a vector of break
      ### points, and values outside the range are ignored.
      id.free.range=FALSE,
      ### Indicates that the range should be freely set from the observed
      ### values. Otherwise, 70-100% is included in the identity histogram
      ### (default).
      id.metric=c('identity', 'corrected identity', 'bit score'),
      ### Metric of identity to be used (Y-axis). Corrected identity is only
      ### supported if the original BLAST file included sequence lengths.
      id.summary=sum,
      ### Function summarizing the identity bins. Other recommended options
      ### include: `median` to estimate the median instead of total bins, and
      ### `function(x) mlv(x,method='parzen')$M` to estimate the mode.
      id.cutoff=95,
      ### Cutoff of identity metric above which the hits are considered
      ### 'in-group'. The 95% identity corresponds to the expectation of
      ### ANI<95% within species.
      threads=2,
      ### Number of threads to use.
      verbose=TRUE,
      ### Indicates if the function should report the advance.
      ...
      ### Any additional parameters supported by `plot.enve.RecPlot2`.
   ){
   # Settings
   id.metric <- match.arg(id.metric);
   
   #Read files
   if(verbose) cat("Reading files.\n")
   rec <- read.table(paste(prefix, ".rec", sep=""), sep="\t", comment.char="",
      quote="");
   lim <- read.table(paste(prefix, ".lim", sep=""), sep="\t", comment.char="",
      quote="", as.is=TRUE);
   
   # Build matrix
   if(verbose) cat("Building counts matrix.\n")
   if(id.metric=="corrected identity" & ncol(rec)<6){
      stop("Requesting corr. identity, but .rec file doesn't have 6th column")
   }
   rec.idcol <- ifelse(id.metric=="identity", 3,
      ifelse(id.metric=="corrected identity", 6, 4));
   if(length(pos.breaks)==1){
      if(pos.breaks>0){
         pos.breaks <- seq(min(lim[,2]), max(lim[,3]), length.out=pos.breaks+1);
      }else{
         pos.breaks <- c(lim[,2], tail(lim[,3], n=1))
      }
   }
   if(length(id.breaks)==1){
      id.range.v <- rec[,rec.idcol]
      if(!id.free.range) id.range.v <- c(id.range.v,70,100)
      id.range.v <- range(id.range.v)
      id.breaks <- seq(id.range.v[1], id.range.v[2], length.out=id.breaks+1);
   }
   
   # Run in parallel
   if(nrow(rec) < 200) threads <- 1 # It doesn't worth the overhead
   cl		<- makeCluster(threads)
   rec.l	<- list()
   thl		<- ceiling(nrow(rec)/threads)
   for(i in 0:(threads-1)){
      rec.l[[i+1]] <- list(rec=rec[ (i*thl+1):min(((i+1)*thl),nrow(rec)), ],
			verbose=ifelse(i==0, verbose, FALSE))
   }
   counts.l	<- clusterApply(cl, rec.l, enve.recplot2.__counts,
			pos.breaks=pos.breaks, id.breaks=id.breaks,
			rec.idcol=rec.idcol)
   counts	<- counts.l[[1]]
   if(threads>1) for(i in 2:threads) counts <- counts + counts.l[[i]]
   stopCluster(cl)
   
   # Estimate 1D histograms
   if(verbose) cat("Building histograms.\n")
   id.mids	<- (id.breaks[-length(id.breaks)]+id.breaks[-1])/2;
   id.ingroup	<- (id.mids > id.cutoff);
   id.counts	<- apply(counts, 2, id.summary);
   pos.counts.in   <- apply(counts[,id.ingroup], 1, sum);
   pos.counts.out  <- apply(counts[,!id.ingroup], 1, sum);

   # Plot and return
   recplot <- new('enve.RecPlot2',
      counts=counts, id.counts=id.counts, pos.counts.in=pos.counts.in,
      pos.counts.out=pos.counts.out,
      id.breaks=id.breaks, pos.breaks=pos.breaks,
      seq.breaks=c(lim[1,2], lim[,3]), seq.names=lim[,1],
      id.ingroup=id.ingroup,id.metric=id.metric,
      call=match.call());
   if(plot){
      if(verbose) cat("Plotting.\n")
      peaks <- plot(recplot, ...);
      attr(recplot, "peaks") <- peaks
   }
   return(recplot);
   ### Returns an object of class `enve.RecPlot2`.
}

enve.recplot2.findPeaks <- function(
  ### Identifies peaks in the population histogram potentially indicating
  ### sub-population mixtures
    x,
    ### An `enve.RecPlot2` object.
    method="emauto",
    ### Peak-finder method. This should be one of:
    ### "emauto" (Expectation-Maximization with auto-selection of components),
    ### "em" (Expectation-Maximization),
    ### "mower" (Custom distribution-mowing method).
    ...
    ### Any additional parameters supported by `enve.recplot2.findPeaks.<method>`.
    ){
  if(method == "emauto"){
    peaks <- enve.recplot2.findPeaks.emauto(x, ...)
  }else if(method == "em"){
    peaks <- enve.recplot2.findPeaks.em(x, ...)
  }else if(method == "mower"){
    peaks <- enve.recplot2.findPeaks.mower(x, ...)
  }else{
    stop("Invalid peak-finder method ", method)
  }
  return(peaks)
  ### Returns a list of `enve.RecPlot2.Peak` objects.
}

enve.recplot2.findPeaks.emauto <- function(
  ### Identifies peaks in the population histogram using a Gaussian Mixture Model
  ### Expectation Maximization (GMM-EM) method with number of components automatically
  ### detected.
    x,
    ### An `enve.RecPlot2` object.
    components=seq(1,10),
    ### A vector of number of components to evaluate.
    criterion='aic',
    ### Criterion to use for components selection. Must be one of:
    ### 'aic' (Akaike Information Criterion),
    ### 'bic' or 'sbc' (Bayesian Information Criterion or Schwarz Criterion).
    merge.tol=2L,
    ### When attempting to merge peaks with very similar sequencing depth, use
    ### this number of significant digits (in log-scale).
    verbose=FALSE,
    ### Display (mostly debugging) information.
    ...
    ### Any additional parameters supported by `enve.recplot2.findPeaks.em`.
    ){
  best <- list(crit=0, pstore=list())
  if(criterion == 'aic'){
    do_crit <- function(ll, k, n) 2*k - 2*ll
  }else if(criterion %in% c('bic', 'sbc')){
    do_crit <- function(ll, k, n) log(n)*k - 2*ll
  }else{
    stop('Invalid criterion ', criterion)
  }
  for(comp in components){
    best <- enve.recplot2.findPeaks.__emauto_one(x, comp, do_crit, best, verbose, ...)
  }

  seqdepths.r <- signif(log(sapply(best[['peaks']], function(x) x$seq.depth)), merge.tol)
  distinct <- length(unique(seqdepths.r))
  if(distinct < length(best[['peaks']])){
    if(verbose) cat('Attempting merge to', distinct, 'components\n')
    init <- apply(sapply(best[['peaks']],
          function(x) c(x$param.hat, alpha=x$n.hat/x$n.total)), 1, as.numeric)
    init <- init[!duplicated(seqdepths.r),]
    init <- list(mu=init[,'mean'], sd=init[,'sd'], alpha=init[,'alpha']/sum(init[,'alpha']))
    best <- enve.recplot2.findPeaks.__emauto_one(x, distinct, do_crit, best, verbose, ...)
  }
  return(best[['peaks']])
  ### Returns a list of `enve.RecPlot2.Peak` objects.
}

enve.recplot2.findPeaks.em <- function(
  ### Identifies peaks in the population histogram using a Gaussian Mixture Model
  ### Expectation Maximization (GMM-EM) method.
    x,
    ### An `enve.RecPlot2` object.
    max.iter=1000,
    ### Maximum number of EM iterations.
    ll.diff.res=1e-8,
    ### Maximum Log-Likelihood difference to be considered as convergent.
    components=2,
    ### Number of distributions assumed in the mixture.
    rm.top=0.05,
    ### Top-values to remove before finding peaks, as a quantile probability.
    ### This step is useful to remove highly conserved regions, but can be
    ### turned off by setting rm.top=0. The quantile is determined *after*
    ### removing zero-coverage windows.
    verbose=FALSE,
    ### Display (mostly debugging) information.
    init,
    ### Initialization parameters. By default, these are derived from k-means clustering.
    ### A named list with vectors for 'mu', 'sd', and 'alpha', each of length `components`.
    log=TRUE
    ### Logical value indicating if the estimations should be performed in natural
    ### logarithm units. Do not change unless you know what you're doing.
  ){
  
  # Essential vars
  pos.binsize  <- x$pos.breaks[-1] - x$pos.breaks[-length(x$pos.breaks)]
  lsd1  <- (x$pos.counts.in/pos.binsize)[ x$pos.counts.in > 0 ]
  lsd1 <- lsd1[ lsd1 < quantile(lsd1, 1-rm.top, names=FALSE) ]
  if(log) lsd1 <- log(lsd1)

  # 1. Initialize
  if(missing(init)){
    km.clust <- kmeans(lsd1, components)$cluster
    init <- list(
      mu = tapply(lsd1, km.clust, mean),
      sd = tapply(lsd1, km.clust, sd),
      alpha = table(km.clust)/length(km.clust)
    )
  }
  m.step <- init
  ll <- c()
  cur.ll <- -Inf
  
  for(i in 1:max.iter){
    # 2/3. EM
    e.step <- enve.recplot2.findPeaks.__em_e(lsd1, m.step)
    m.step <- enve.recplot2.findPeaks.__em_m(lsd1, e.step[['posterior']])
    # 4. Convergence
    ll <- c(ll, e.step[["ll"]])
    ll.diff <- abs(cur.ll - e.step[["ll"]])
    cur.ll <- e.step[["ll"]]
    if(verbose) cat(i, '\t| LL =', cur.ll, '\t| LL.diff =', ll.diff, '\n')
    if(ll.diff <= ll.diff.res) break
  }

  # Return
  peaks <- list()
  for(i in 1:components){
    n.hat <- m.step[['alpha']][i]*length(lsd1)
    peaks[[i]] <- new('enve.RecPlot2.Peak', dist='norm', values=as.numeric(),
      values.res=0, mode=m.step[['mu']][i],
      param.hat=list(sd=m.step[['sd']][i], mean=m.step[['mu']][i]),
      n.hat=n.hat, n.total=length(lsd1), err.res=cur.ll,
      merge.logdist=as.numeric(), log=log,
      seq.depth=ifelse(log, exp(m.step[['mu']][i]), m.step[['mu']][i]))
  }
  return(peaks)
  ### Returns a list of `enve.RecPlot2.Peak` objects.
}

enve.recplot2.findPeaks.mower <- function(
   ### Identifies peaks in the population histogram potentially indicating
   ### sub-population mixtures, using a custom distribution-mowing method.
      x,
      ### An `enve.RecPlot2` object.
      min.points=10,
      ### Minimum number of points in the quantile-estimation-range
      ### (`quant.est`) to estimate a peak.
      quant.est=c(0.002, 0.998),
      ### Range of quantiles to be used in the estimation of a peak's
      ### parameters.
      mlv.opts=list(method='parzen'),
      ### Options passed to `mlv` to estimate the mode.
      fitdist.opts.sn=list(distr='sn', method='qme', probs=c(0.1,0.5,0.8),
	 start=list(omega=1, alpha=-1), lower=c(0, -Inf, -Inf)),
      ### Options passed to `fitdist` to estimate the standard deviation if
      ### with.skewness=TRUE. Note that the `start` parameter will be ammended
      ### with xi=estimated mode for each peak.
      fitdist.opts.norm=list(distr='norm', method='qme', probs=c(0.4,0.6),
	 start=list(sd=1), lower=c(0, -Inf)),
      ### Options passed to `fitdist` to estimate the standard deviation if
      ### with.skewness=FALSE. Note that the `start` parameter will be ammended
      ### with mean=estimated mode for each peak.
      rm.top=0.05,
      ### Top-values to remove before finding peaks, as a quantile probability.
      ### This step is useful to remove highly conserved regions, but can be
      ### turned off by setting rm.top=0. The quantile is determined *after*
      ### removing zero-coverage windows.
      with.skewness=TRUE,
      ### Allow skewness correction of the peaks. Typically, the
      ### sequencing-depth distribution for a single peak is left-skewed, due
      ### partly (but not exclusively) to fragmentation and mapping sensitivity.
      ### See Lindner et al 2013, Bioinformatics 29(10):1260-7 for an
      ### alternative solution for the first problem (fragmentation) called
      ### "tail distribution".
      optim.rounds=200,
      ### Maximum rounds of peak optimization.
      optim.epsilon=1e-4,
      ### Trace change at which optimization stops (unless `optim.rounds` is
      ### reached first). The trace change is estimated as the sum of square
      ### differences between parameters in one round and those from two rounds
      ### earlier (to avoid infinite loops from approximation).
      merge.logdist=log(1.75),
      ### Maximum value of |log-ratio| between centrality parameters in peaks to
      ### attempt merging. The default of ~0.22 corresponds to a maximum
      ### difference of 25%.
      verbose=FALSE,
      ### Display (mostly debugging) information.
      log=TRUE
      ### Logical value indicating if the estimations should be performed in natural
      ### logarithm units. Do not change unless you know what you're doing.
   ){
   
   # Essential vars
   pos.binsize	<- x$pos.breaks[-1] - x$pos.breaks[-length(x$pos.breaks)];
   seqdepth.in	<- x$pos.counts.in/pos.binsize;
   lsd1 <- seqdepth.in[seqdepth.in>0];
   lsd1 <- lsd1[ lsd1 < quantile(lsd1, 1-rm.top, names=FALSE) ]
   if(log) lsd1 <- log(lsd1)
   if(with.skewness){
      fitdist.opts <- fitdist.opts.sn
   }else{
      fitdist.opts <- fitdist.opts.norm
   }
   peaks.opts <- list(lsd1=lsd1, min.points=min.points, quant.est=quant.est,
      mlv.opts=mlv.opts, fitdist.opts=fitdist.opts, with.skewness=with.skewness,
      optim.rounds=optim.rounds, optim.epsilon=optim.epsilon, verbose=verbose,
      n.total=length(lsd1), merge.logdist=merge.logdist, log=log)
   
   # Find seed peaks
   if(verbose) cat('Mowing peaks for n =',length(lsd1),'\n')
   peaks <- enve.recplot2.findPeaks.__mower(peaks.opts);

   # Merge overlapping peaks
   if(verbose) cat('Trying to merge',length(peaks),'peaks\n')
   merged <- (length(peaks)>1)
   while(merged){
      merged <- FALSE
      ignore <- c()
      peaks2 <- list();
      for(i in 1:length(peaks)){
	 if(i %in% ignore) next
	 p <- peaks[[ i ]]
	 j <- enve.recplot2.__whichClosestPeak(p, peaks)
	 p2 <- peaks[[ j ]]
	 dst.a <- p$param.hat[[ length(p$param.hat) ]]
	 dst.b <- p2$param.hat[[ length(p2$param.hat) ]]
	 if( abs(log(dst.a/dst.b)) < merge.logdist ){
	    if(verbose) cat('==> Attempting a merge at',
		  p$param.hat[[ length(p$param.hat) ]],'&',
		  p2$param.hat[[ length(p2$param.hat) ]],'X\n');
	    peaks.opts$lsd1 <- c(p$values, p2$values)
	    p.new <- enve.recplot2.findPeaks.__mower(peaks.opts)
	    if(length(p.new)==1){
	       peaks2[[ length(peaks2)+1 ]] <- p.new[[ 1 ]]
	       ignore <- c(ignore, j)
	       merged <- TRUE
	    }
	 }
	 if(!merged) peaks2[[ length(peaks2)+1 ]] <- p
      }
      peaks <- peaks2
      if(length(peaks)==1) break
   }
   
   if(verbose) cat('Found',length(peaks),'peak(s)\n')
   return(peaks);
   ### Returns a list of `enve.RecPlot2.Peak` objects.
}

#==============> Define utils
enve.recplot2.corePeak <- function
   ### Finds the peak in a list of peaks that is most likely to represent the
   ### "core genome" of a population.
      (x
      ### `list` of `enve.RecPlot2.Peak` objects.
   ){
   # Find the peak with maximum depth (centrality)
   maxPeak <- x[[
	 which.max(as.numeric(lapply(x,
	    function(y) y$param.hat[[ length(y$param.hat) ]])))
      ]]
   # If a "larger" peak (a peak explaining more bins of the genome) is within
   # the "merge.logdist" distance, take that one instead.
   corePeak <- maxPeak
   for(p in x){
      sz.d = log(length(p$values)/length(corePeak$values))
      if(sz.d < 0)
	 next;
      sq.d.a <- p$param.hat[[ length(p$param.hat) ]]
      sq.d.b <- maxPeak$param.hat[[ length(maxPeak$param.hat) ]]
      if(abs(log(sq.d.a/sq.d.b )) < maxPeak$merge.logdist+sz.d/5)
         corePeak <- p
   }
   return(corePeak)
}

enve.recplot2.changeCutoff <- function
   ### Change the intra-species cutoff of an existing recruitment plot.
      (rp,
      ### enve.RecPlot2 object.
      new.cutoff=98
      ### New cutoff to use.
      ){
   # Re-calculate vectors
   id.mids	<- (rp$id.breaks[-length(rp$id.breaks)]+rp$id.breaks[-1])/2
   id.ingroup	<- (id.mids > new.cutoff)
   pos.counts.in  <- apply(rp$counts[,id.ingroup], 1, sum)
   pos.counts.out <- apply(rp$counts[,!id.ingroup], 1, sum)
   # Update object
   attr(rp, "id.ingroup")     <- id.ingroup
   attr(rp, "pos.counts.in")  <- pos.counts.in
   attr(rp, "pos.counts.out") <- pos.counts.out
   attr(rp, "call")           <- match.call()
   return(rp)
}

enve.recplot2.extractWindows <- function
   ### Extract windows significantly below (or above) the peak in sequencing
   ### depth.
      (rp,
      ### Recruitment plot, a enve.RecPlot2 object.
      peak,
      ### Peak, a enve.RecPlot2.Peak object. If list, it is assumed to be a list
      ### of enve.RecPlot2.Peak objects, in which case the core peak is used
      ### (see enve.recplot2.corePeak).
      lower.tail=TRUE,
      ### If FALSE, it returns windows significantly above the peak in
      ### sequencing depth.
      significance=0.05,
      ### Significance threshold (alpha) to select windows.
      seq.names=FALSE
      ### Returns subject sequence names instead of a vector of Booleans. It
      ### assumes that the recruitment plot was generated with pos.breaks=0.
      ){
   # Determine the threshold
   if(is.list(peak)) peak <- enve.recplot2.corePeak(peak)
   par <- peak$param.hat
   par[["p"]] <- ifelse(lower.tail, significance, 1-significance)
   thr <- do.call(ifelse(length(par)==4, qsn, qnorm), par)
   
   # Estimate sequencing depths per window
   pos.cnts.in <- rp$pos.counts.in
   pos.breaks  <- rp$pos.breaks
   pos.binsize <- (pos.breaks[-1] - pos.breaks[-length(pos.breaks)])
   seqdepth.in <- pos.cnts.in/pos.binsize

   # Select windows past the threshold
   if(lower.tail){
      sel <- seqdepth.in < thr
   }else{
      sel <- seqdepth.in > thr
   }
   if(!seq.names) return(sel)
   if(length(seqdepth.in) != length(rp$seq.names))
      stop(paste("Requesting subject sequence names, but the recruitment plot",
         "was not generated with pos.breaks=0."))
   return(rp$seq.names[sel])
}

enve.recplot2.compareIdentities <- function
  ### Compare the distribution of identities between two enve.RecPlot2 objects.
    (x,
    ### First enve.RecPlot2 object.
    y,
    ### Second enve.RecPlot2 object.
    method="hellinger",
    ### Distance method to use. This should be (an unambiguous abbreviation of)
    ### one of:
    ### "hellinger" (Hellinger, 1090, doi:10.1515/crll.1909.136.210),
    ### "bhattacharyya" (Bhattacharyya, 1943, Bull. Calcutta Math. Soc. 35),
    ### "kl" or "kullback-leibler" (Kullback & Leibler, 1951,
    ### doi:10.1214/aoms/1177729694), or "euclidean".
    pseudocounts=0,
    ### Smoothing parameter for Laplace smoothing. Use 0 for no smoothing, or
    ### 1 for add-one smoothing.
    max.deviation=0.75
    ### Maximum mean deviation between identity breaks tolerated (as percent
    ### identity). Difference in number of id.breaks is never tolerated.
    ){
  METHODS <- c("hellinger","bhattacharyya","kullback-leibler","kl","euclidean")
  i.meth <- pmatch(method, METHODS)
  if (is.na(i.meth)) stop("Invalid distance ", method)
  if(!inherits(x, "enve.RecPlot2"))
    stop("'x' must inherit from class `enve.RecPlot2`")
  if(!inherits(y, "enve.RecPlot2"))
    stop("'y' must inherit from class `enve.RecPlot2`")
  if(length(x$id.breaks) != length(y$id.breaks))
    stop("'x' and 'y' must have the same number of `id.breaks`")
  dev <- mean(abs(x$id.breaks - y$id.breaks))
  if(dev > max.deviation)
    stop("'x' and 'y' must have similar `id.breaks`; exceeding max.deviation: ",
          dev)
  a <- as.numeric(pseudocounts)
  p <- (x$id.counts + a) / sum(x$id.counts + a)
  q <- (y$id.counts + a) / sum(y$id.counts + a)
  d <- NA
  if(i.meth %in% c(1L, 2L)){
    d <- sqrt(sum((sqrt(p) - sqrt(q))**2))/sqrt(2)
    if(i.meth==2L) d <- 1 - d**2
  }else if(i.meth %in% c(3L, 4L)){
    sel <- p>0
    if(any(q[sel]==0))
      stop("Undefined distance without absolute continuity, use pseudocounts")
    d <- -sum(p[sel]*log(q[sel]/p[sel]))
  }else if(i.meth == 5L){
    d <- sqrt(sum((q-p)**2))
  }
  return(d)
}

#==============> Define internal functions
enve.recplot2.__counts <- function
   ### Internal ancilliary function (see `enve.recplot2`).
      (x, pos.breaks, id.breaks, rec.idcol){
   rec <- x$rec
   verbose <- x$verbose
   counts <- matrix(0, nrow=length(pos.breaks)-1, ncol=length(id.breaks)-1);
   for(i in 1:nrow(rec)){
      if(verbose & i%%100==0) cat("   [",signif(i*100/nrow(rec),3),"% ]   \r");
      y.bin <- which(
	 rec[i,rec.idcol]>=id.breaks[-length(id.breaks)] &
	 rec[i,rec.idcol]<=id.breaks[-1])[1] ;
      for(pos in rec[i,1]:rec[i,2]){
	 x.bin <- which(
	    pos>=pos.breaks[-length(pos.breaks)] & pos<=pos.breaks[-1])[1] ;
	 counts[x.bin, y.bin] <- counts[x.bin, y.bin]+1 ;
      }
   }
   return(counts);
}

enve.recplot2.findPeaks.__emauto_one <- function
  ### Internal ancilliary function (see `enve.recplot2.findPeaks.emauto).
    (x, comp, do_crit, best, verbose, ...){
  peaks <- enve.recplot2.findPeaks.em(x=x, components=comp, ...)
  k <- comp*3 - 1 # mean & sd for each component, and n-1 free alpha parameters
  crit <- do_crit(peaks[[1]]$err.res, k, peaks[[1]]$n.total)
  if(verbose) cat(comp,'\t| LL =', peaks[[1]]$err.res, '\t| Estimate =', crit,
        ifelse(crit > best[['crit']], '*', ''), '\n')
  if(crit > best[['crit']]){
    best[['crit']] <- crit
    best[['peaks']] <- peaks
  }
  best[['pstore']][[comp]] <- peaks
  return(best)
}
enve.recplot2.findPeaks.__em_e <- function
  ### Internal ancilliary function (see `enve.recplot2.findPeaks.em`).
    (x, theta){
  components <- length(theta[['mu']])
  product <- do.call(cbind,
        lapply(1:components,
          function(i) dnorm(x, theta[['mu']][i], theta[['sd']][i])*theta[['alpha']][i]))
  sum.of.components <- rowSums(product)
  posterior <- product / sum.of.components
  
  return(list(ll=sum(log(sum.of.components)), posterior=posterior))
}

enve.recplot2.findPeaks.__em_m <- function
  ### Internal ancilliary function (see `enve.recplot2.findPeaks.em`
    (x, posterior){
  components <- ncol(posterior)
  n <- colSums(posterior)
  mu <- colSums(posterior * x) / n
  sd <- sqrt( colSums(posterior * (matrix(rep(x,components), ncol=components) - mu)^2) / n )
  alpha <- n/length(x)
  return(list(mu=mu, sd=sd, alpha=alpha))
}

enve.recplot2.__peakHist <- function
   ### Internal ancilliary function (see `enve.RecPlot2.Peak`).
      (x, mids, counts=TRUE){
   d.o <- x$param.hat
   if(length(x$log)==0) x$log <- FALSE
   if(x$log){
     d.o$x <- log(mids)
   }else{
     d.o$x <- mids
   }
   prob  <- do.call(paste('d', x$dist, sep=''), d.o)
   if(!counts) return(prob)
   if(length(x$values)>0) return(prob*length(x$values)/sum(prob))
   return(prob*x$n.hat/sum(prob))
}

enve.recplot2.findPeaks.__mow_one <- function
   ### Internall ancilliary function (see `enve.recplot2.findPeaks.mower`).
      (lsd1, min.points, quant.est, mlv.opts, fitdist.opts, with.skewness,
      optim.rounds, optim.epsilon, n.total, merge.logdist, verbose, log
   ){
   dist	<- ifelse(with.skewness, 'sn', 'norm');
   
   # Find peak
   o <- mlv.opts; o$x = lsd1;
   mode1 <- do.call(mlv, o)$M;
   if(verbose) cat('Anchoring at mode =',mode1,'\n')
   param.hat <- fitdist.opts$start; last.hat <- param.hat;
   lim <- NA;
   if(with.skewness){ param.hat$xi <- mode1 }else{ param.hat$mean <- mode1 }
   
   # Refine peak parameters
   for(round in 1:optim.rounds){
      param.hat[[ 1 ]] <- param.hat[[ 1 ]]/diff(quant.est)# <- expand dispersion
      lim.o <- param.hat
      lim.o$p <- quant.est; lim <- do.call(paste('q',dist,sep=''), lim.o)
      lsd1.pop <- lsd1[(lsd1>lim[1]) & (lsd1<lim[2])];
      if(verbose) cat(' Round', round, 'with n =',length(lsd1.pop),
	    'and params =',as.numeric(param.hat),' \r')
      if(length(lsd1.pop) < min.points) break;
      o <- fitdist.opts; o$data = lsd1.pop; o$start = param.hat;
      last.last.hat <- last.hat
      last.hat <- param.hat
      param.hat <- as.list(do.call(fitdist, o)$estimate);
      if(any(is.na(param.hat))){
	 if(round>1) param.hat <- last.hat;
	 break;
      }
      if(round > 1){
        epsilon1 <- sum((as.numeric(last.hat)-as.numeric(param.hat))^2)
        if(epsilon1 < optim.epsilon) break;
        if(round > 2){
          epsilon2 <- sum((as.numeric(last.last.hat)-as.numeric(param.hat))^2)
          if(epsilon2 < optim.epsilon) break;
        }
      }
   }
   if(verbose) cat('\n')
   if(is.na(param.hat[1]) | is.na(lim[1])) return(NULL);

   # Mow distribution
   lsd2 <- c();
   lsd.pop <- c();
   n.hat <- length(lsd1.pop)/diff(quant.est)
   peak <- new('enve.RecPlot2.Peak', dist=dist, values=as.numeric(), mode=mode1,
      param.hat=param.hat, n.hat=n.hat, n.total=n.total,
      merge.logdist=merge.logdist, log=log)
   peak.breaks <- seq(min(lsd1), max(lsd1), length=20)
   peak.cnt <- enve.recplot2.__peakHist(peak,
      (peak.breaks[-length(peak.breaks)]+peak.breaks[-1])/2)
   for(i in 2:length(peak.breaks)){
      values <- lsd1[ (lsd1 >= peak.breaks[i-1]) & (lsd1 < peak.breaks[i]) ]
      n.exp <- peak.cnt[i-1]
      if(is.na(n.exp) | n.exp==0) n.exp <- 0.1
      if(length(values)==0) next
      in.peak <- runif(length(values)) <= n.exp/length(values)
      lsd2 <- c(lsd2, values[!in.peak])
      lsd.pop <- c(lsd.pop, values[in.peak])
   }
   if(length(lsd.pop) < min.points) return(NULL)

   # Return peak
   attr(peak, 'values') <- lsd.pop
   attr(peak, 'values.res') <- lsd2
   attr(peak, 'err.res') <- 1-(cor(hist(lsd.pop, breaks=peak.breaks,
      plot=FALSE)$counts, hist(lsd1, breaks=peak.breaks,
      plot=FALSE)$counts)+1)/2
   mu <- tail(param.hat, n=1)
   attr(peak, 'seq.depth') <- ifelse(log, exp(mu), mu)
   if(verbose) cat(' Extracted peak with n =',length(lsd.pop),
	 'with expected n =',n.hat,'\n')
   return(peak)
}

enve.recplot2.findPeaks.__mower <- function
   ### Internal ancilliary function (see `enve.recplot2.findPeaks.mower`).
      (peaks.opts){
   peaks <- list()
   while(length(peaks.opts$lsd1) > peaks.opts$min.points){
      peak <- do.call(enve.recplot2.findPeaks.__mow_one, peaks.opts)
      if(is.null(peak)) break
      peaks[[ length(peaks)+1 ]] <- peak
      peaks.opts$lsd1 <- peak$values.res
   }
   return(peaks)
}


enve.recplot2.__whichClosestPeak <- function
   ### Internal ancilliary function (see `enve.recplot2.findPeaks`).
      (peak, peaks){
   dist <- as.numeric(lapply(peaks, function(x) abs(log(x$param.hat[[ length(x$param.hat) ]]/peak$param.hat[[ length(peak$param.hat) ]] ))))
   dist[ dist==0 ] <- Inf
   return(which.min(dist))
}

