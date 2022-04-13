#==============> Define S4 classes

#' Enveomics: Recruitment Plot (2) - S4 Class
#'
#' Enve-omics representation of Recruitment plots. This object can
#' be produced by \code{\link{enve.recplot2}} and supports S4 method plot.
#'
#' @slot counts \code{(matrix)} Counts as a two-dimensional histogram.
#' @slot pos.counts.in
#' \code{(numeric)} Counts of in-group hits per position bin.
#' @slot pos.counts.out
#' \code{(numeric)} Counts of out-group hits per position bin.
#' @slot id.counts \code{(numeric)} Counts per ID bin.
#' @slot id.breaks \code{(numeric)} Breaks of identity bins.
#' @slot pos.breaks \code{(numeric)} Breaks of position bins.
#' @slot pos.names \code{(character)} Names of the position bins.
#' @slot seq.breaks \code{(numeric)} Breaks of input sequences.
#' @slot peaks \code{(list)} Peaks identified in the recplot.
#' Limits of the subject sequences after concatenation.
#' @slot seq.names \code{(character}) Names of the subject sequences.
#' @slot id.metric \code{(character}) Metric used as 'identity'.
#' @slot id.ingroup \code{(logical}) Identity bins considered in-group.
#' @slot call \code{(call)} Call producing this object.
#'
#' @author Luis M. Rodriguez-R [aut, cre]
#'
#' @exportClass

enve.RecPlot2 <- setClass("enve.RecPlot2",
                          representation(
                            # slots = list(
                            counts='matrix',
                            pos.counts.in='numeric',
                            pos.counts.out='numeric',
                            id.counts='numeric',
                            id.breaks='numeric',
                            pos.breaks='numeric',
                            pos.names='character',
                            seq.breaks='numeric',
                            peaks='list',
                            seq.names='character',
                            id.metric='character',
                            id.ingroup='logical',
                            call='call')
                          ,package='enveomics.R'
);

#' Enveomics: Recruitment Plot (2) Peak - S4 Class
#'
#' Enve-omics representation of a peak in the sequencing depth histogram
#' of a Recruitment plot (see \code{\link{enve.recplot2.findPeaks}}).
#'
#' @slot dist \code{(character)}
#' Distribution of the peak. Currently supported: \code{norm} (normal) and \code{sn}
#' (skew-normal).
#' @slot values \code{(numeric)}
#' Sequencing depth values predicted to conform the peak.
#' @slot values.res \code{(numeric)}
#' Sequencing depth values not explained by this or previously identified
#' peaks.
#' @slot mode \code{(numeric)}
#' Seed-value of mode anchoring the peak.
#' @slot param.hat \code{(list)}
#' Parameters of the distribution. A list of two values if dist=\code{norm} (sd
#' and mean), or three values if dist=\code{sn}(omega=scale, alpha=shape, and
#' xi=location). Note that the "dispersion" parameter is always first and
#' the "location" parameter is always last.
#' @slot n.hat \code{(numeric)}
#' Number of bins estimated to be explained by this peak. This should
#' ideally be equal to the length of  \code{values}, but it's not an integer.
#' @slot n.total \code{(numeric)}
#' Total number of bins from which the peak was extracted. I.e., total
#' number of position bins with non-zero sequencing depth in the recruitment
#' plot (regardless of peak count).
#' @slot err.res \code{(numeric)}
#' Error left after adding the peak (mower) or log-likelihood (em or emauto).
#' @slot merge.logdist \code{(numeric)}
#' Attempted \code{merge.logdist} parameter.
#' @slot seq.depth \code{(numeric)}
#' Best estimate available for the sequencing depth of the peak (centrality).
#' @slot log \code{(logical)}
#' Indicates if the estimation was performed in natural logarithm space.
#'
#' @author Luis M. Rodriguez-R [aut, cre]
#'
#' @exportClass

enve.RecPlot2.Peak <- setClass("enve.RecPlot2.Peak",
                               representation(
                                 # slots = list(
                                 dist='character',
                                 values='numeric',
                                 values.res='numeric',
                                 mode='numeric',
                                 param.hat='list',
                                 n.hat='numeric',
                                 n.total='numeric',
                                 err.res='numeric',
                                 merge.logdist='numeric',
                                 seq.depth='numeric',
                                 log='logical'
                               ));

#' Attribute accessor
#'
#'
#' @param x Object
#' @param name Attribute name
setMethod("$", "enve.RecPlot2", function(x, name) attr(x, name))

#' Attribute accessor
#'
#'
#' @param x Object
#' @param name Attribute name
setMethod("$", "enve.RecPlot2.Peak", function(x, name) attr(x, name))

#==============> Define S4 methods

#' Enveomics: Recruitment Plot (2)
#'
#' Plots an \code{\link{enve.RecPlot2}} object.
#'
#' @param x
#' \code{\link{enve.RecPlot2}} object to plot.
#' @param layout
#' Matrix indicating the position of the different panels in the layout,
#' where:
#' \itemize{
#'   \item 0: Empty space
#'   \item 1: Counts matrix
#'   \item 2: position histogram (sequencing depth)
#'   \item 3: identity histogram
#'   \item 4: Populations histogram (histogram of sequencing depths)
#'   \item 5: Color scale for the counts matrix (vertical)
#'   \item 6: Color scale of the counts matrix (horizontal)
#' }
#' Only panels indicated here will be plotted. To plot only one panel
#' simply set this to the number of the panel you want to plot.
#' @param panel.fun
#' List of functions to be executed after drawing each panel. Use the
#' indices in \code{layout} (as characters) as keys. Functions for indices
#' missing in \code{layout} are ignored. For example, to add a vertical line
#' at the 3Mbp mark in both the position histogram and the counts matrix:
#' \code{list('1'=function() abline(v=3), '2'=function() abline(v=3))}.
#' Note that the X-axis in both panels is in Mbp by default. To change
#' this behavior, set \code{pos.units} accordingly.
#' @param widths
#' Relative widths of the columns of \code{layout}.
#' @param heights
#' Relative heights of the rows of \code{layout}.
#' @param palette
#' Colors to be used to represent the counts matrix, sorted from no hits
#' to the maximum sequencing depth.
#' @param underlay.group
#' If TRUE, it indicates the in-group and out-group areas couloured based
#' on \code{in.col} and \code{out.col}. Requires support for semi-transparency.
#' @param peaks.col
#' If not \code{NA}, it attempts to represent peaks in the population histogram
#' in the specified color. Set to \code{NA} to avoid peak-finding.
#' @param use.peaks
#' A list of \code{\link{enve.RecPlot2.Peak}} objects, as returned by
#' \code{\link{enve.recplot2.findPeaks}}. If passed, \code{peaks.opts} is ignored.
#' @param id.lim
#' Limits of identities to represent.
#' @param pos.lim
#' Limits of positions to represent (in bp, regardless of \code{pos.units}).
#' @param pos.units
#' Units in which the positions should be represented (powers of 1,000
#' base pairs).
#' @param mar
#' Margins of the panels as a list, with the character representation of
#' the number of the panel as index (see \code{layout}).
#' @param pos.splines
#' Smoothing parameter for the splines in the position histogram. Zero
#' (0) for no splines. Use \code{NULL} to automatically detect by leave-one-out
#' cross-validation.
#' @param id.splines
#' Smoothing parameter for the splines in the identity histogram. Zero
#' (0) for no splines. Use \code{NULL} to automatically detect by leave-one-out
#' cross-validation.
#' @param in.lwd
#' Line width for the sequencing depth of in-group matches.
#' @param out.lwd
#' Line width for the sequencing depth of out-group matches.
#' @param id.lwd
#' Line width for the identity histogram.
#' @param in.col
#' Color associated to in-group matches.
#' @param out.col
#' Color associated to out-group matches.
#' @param id.col
#' Color for the identity histogram.
#' @param breaks.col
#' Color of the vertical lines indicating sequence breaks.
#' @param peaks.opts
#' Options passed to \code{\link{enve.recplot2.findPeaks}},
#' if \code{peaks.col} is not \code{NA}.
#' @param ...
#' Any other graphic parameters (currently ignored).
#'
#' @return
#' Returns a list of \code{\link{enve.RecPlot2.Peak}} objects (see
#' \code{\link{enve.recplot2.findPeaks}}). If \code{peaks.col=NA} or
#' \code{layout} doesn't include 4, returns \code{NA}.
#'
#' @author Luis M. Rodriguez-R [aut, cre]
#'
#' @method plot enve.RecPlot2
#' @export

plot.enve.RecPlot2 <- function
(
  x,
  layout     = matrix(c(5, 5, 2, 1, 4, 3), nrow = 2),
  panel.fun  = list(),
  widths     = c(1, 7, 2),
  heights    = c(1, 2),
  palette    = grey((100:0) / 100),
  underlay.group = TRUE,
  peaks.col  = "darkred",
  use.peaks,
  id.lim     = range(x$id.breaks),
  pos.lim    = range(x$pos.breaks),
  pos.units  = c("Mbp", "Kbp", "bp"),
  mar = list(
    "1" = c(5, 4, 1, 1) + 0.1,
    "2" = c(ifelse(any(layout == 1), 1, 5), 4, 4, 1) + 0.1,
    "3" = c(5, ifelse(any(layout == 1), 1, 4), 1, 2) + 0.1,
    "4" = c(ifelse(any(layout == 1), 1, 5),
            ifelse(any(layout == 2), 1, 4), 4, 2) + 0.1,
    "5" = c(5, 3, 4, 1) + 0.1,
    "6" = c(5, 4, 4, 2) + 0.1
  ),
  pos.splines = 0,
  id.splines = 1/2,
  in.lwd     = ifelse(is.null(pos.splines) || pos.splines > 0, 1/2, 2),
  out.lwd    = ifelse(is.null(pos.splines) || pos.splines > 0, 1/2, 2),
  id.lwd     = ifelse(is.null(id.splines) || id.splines > 0, 1/2, 2),
  in.col     = "darkblue",
  out.col    = "lightblue",
  id.col     = "black",
  breaks.col = "#AAAAAA40",
  peaks.opts = list(),
  ...
) {
  pos.units	<- match.arg(pos.units)
  pos.factor	<- ifelse(pos.units == "bp", 1,
                          ifelse(pos.units == "Kbp", 1e3, 1e6))
  pos.lim	<- pos.lim / pos.factor
  lmat <- layout
  for (i in 1:6) if (!any(layout == i)) lmat[layout > i] <- lmat[layout > i] - 1

  layout(lmat, widths = widths, heights = heights)
  ori.mar <- par("mar")
  on.exit(par(ori.mar))

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

  # [1] Counts matrix
  if (any(layout==1)) {
    par(mar = mar[["1"]]) # par(mar) already being watched by on.exit
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
    if(exists("1", panel.fun)) panel.fun[["1"]]()
  }

  # [2] Position histogram
  if (any(layout == 2)) {
    par(mar = mar[["2"]]) # par(mar) already being watched by on.exit
    if (any(layout == 1)) {
      xlab <- ""
      xaxt <- "n"
    } else {
      xlab <- paste("Position in genome (", pos.units, ")", sep = "")
      xaxt <- "s"
    }
    plot(1,t='n', bty='l', log='y',
         xlim=pos.lim, xlab=xlab, xaxt=xaxt, xaxs='i',
         ylim=seqdepth.lim, yaxs='i', ylab='Sequencing depth (X)');
    abline(v=x$seq.breaks/pos.factor, col=breaks.col)
    pos.x <- rep(pos.breaks,each=2)[-c(1,2*length(pos.breaks))]
    pos.f <- rep(seqdepth.in,each=2)
    lines(pos.x, rep(seqdepth.out,each=2), lwd=out.lwd, col=out.col);
    lines(pos.x, pos.f, lwd=in.lwd, col=in.col);
    if (is.null(pos.splines) || pos.splines > 0) {
      pos.spline <- smooth.spline(pos.x[pos.f>0], log(pos.f[pos.f>0]),
                                  spar=pos.splines)
      lines(pos.spline$x, exp(pos.spline$y), lwd=2, col=in.col)
    }
    if (any(pos.counts.out==0))
      rect(pos.breaks[c(pos.counts.out==0,FALSE)],
           seqdepth.lim[1], pos.breaks[c(FALSE,pos.counts.out==0)],
           seqdepth.lim[1]*3/2, col=out.col, border=NA);
    if (any(pos.counts.in==0))
      rect(pos.breaks[c(pos.counts.in==0,FALSE)],
           seqdepth.lim[1], pos.breaks[c(FALSE,pos.counts.in==0)],
           seqdepth.lim[1]*3/2, col=in.col,  border=NA);
    if (exists("2", panel.fun)) panel.fun[["2"]]()
  }

  # [3] Identity histogram
  if (any(layout == 3)) {
    par(mar = mar[["3"]]) # par(mar) already being watched by on.exit
    if (any(layout == 1)) {
      ylab <- ""
      yaxt <- "n"
    } else {
      ylab <- x$id.metric
      yaxt <- "s"
    }
    if (sum(id.counts > 0) >= 4) {
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
      if(is.null(id.splines) || id.splines > 0){
        id.spline <- smooth.spline(id.x[id.f>0], log(id.f[id.f>0]),
                                   spar=id.splines)
        lines(exp(id.spline$y), id.spline$x, lwd=2, col=id.col)
      }
    } else {
      plot(1,t='n',bty='l',xlab='', xaxt='n', ylab='', yaxt='n')
      text(1,1,labels='Insufficient data', srt=90)
    }
    if (exists("3", panel.fun)) panel.fun[["3"]]()
  }

  # [4] Populations histogram
  peaks <- NA;
  if (any(layout == 4)) {
    par(mar = mar[["4"]]) # par(mar) already being watched by on.exit
    if (any(layout == 2)) {
      ylab <- ""
      yaxt <- "n"
    } else {
      ylab <- "Sequencing depth (X)"
      yaxt <- "s"
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
      o <- peaks.opts; o$x = x;
      if(missing(use.peaks)){
        peaks <- do.call(enve.recplot2.findPeaks, o)
      }else{
        peaks <- use.peaks
      }
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
                 function(x) ifelse(length(x$values)==0, x$n.hat,
                                    length(x$values))/x$n.total)), 2)
        if (peaks[[1]]$err.res < 0) {
          err <- paste(", LL:", signif(peaks[[1]]$err.res, 3))
        } else {
          err <- paste(
            ", err:",
            signif(as.numeric(lapply(peaks, function(x) x$err.res)), 2)
          )
        }
        legend('topright', bty='n', cex=1/2,
               legend=paste(letters[1:length(peaks)],'. ',
                            dpt,'X (', frx, '%', err, ')', sep=''))
      }
    }
    if (exists("4", panel.fun)) panel.fun[["4"]]()
  }

  # [5] Color scale of the counts matrix (vertical)
  count.bins <- 10^seq(
    log10(min(counts[counts>0])), log10(max(counts)),
    length.out = 1 + length(palette)
  )
  if (any(layout == 5)) {
    par(mar = mar[["5"]]) # par(mar) already being watched by on.exit
    plot(1,t='n',log='y',xlim=0:1,xaxt='n',xlab='',xaxs='i',
         ylim=range(count.bins), yaxs='i', ylab='')
    rect(0,count.bins[-length(count.bins)],1,count.bins[-1],col=palette,
         border=NA)
    if (exists("5", panel.fun)) panel.fun[["5"]]()
  }

  # [6] Color scale of the coutnts matrix (horizontal)
  if (any(layout == 6)) {
    par(mar = mar[["6"]]) # par(mar) already being watched by on.exit
    plot(1,t='n',log='x',ylim=0:1,yaxt='n',ylab='',yaxs='i',
         xlim=range(count.bins), xaxs='i',xlab='');
    rect(count.bins[-length(count.bins)],0,count.bins[-1],1,col=palette,
         border=NA);
    if (exists("6", panel.fun)) panel.fun[["6"]]()
  }

  return(peaks)
}

#==============> Define core functions

#' Enveomics: Recruitment Plot (2)
#'
#' Produces recruitment plots provided that \code{BlastTab.catsbj.pl} has
#' been previously executed.
#'
#' @param prefix
#' Path to the prefix of the \code{BlastTab.catsbj.pl} output files. At
#' least the files .rec and .lim must exist with this prefix.
#' @param plot
#' Should the object be plotted?
#' @param pos.breaks
#' Breaks in the positions histogram. It can also be a vector of break
#' points, and values outside the range are ignored. If zero (0), it
#' uses the sequence breaks as defined in the .lim file, which means
#' one bin per contig (or gene, if the mapping is agains genes). Ignored
#' if `pos.breaks.tsv` is passed.
#' @param pos.breaks.tsv
#' Path to a list of (absolute) coordinates to use as position breaks.
#' This tab-delimited file can be produced by \code{GFF.catsbj.pl}, and it
#' must contain at least one column: coordinates of the break positions of
#' each position bin. If it has a second column, this is used as the name
#' of the position bin that ends at the given coordinate (the first row is
#' ignored). Any additional columns are currently ignored. If \code{NA},
#' position bins are determined by \code{pos.breaks}.
#' @param id.breaks
#' Breaks in the identity histogram. It can also be a vector of break
#' points, and values outside the range are ignored.
#' @param id.free.range
#' Indicates that the range should be freely set from the observed
#' values. Otherwise, 70-100\% is included in the identity histogram
#' (default).
#' @param id.metric
#' Metric of identity to be used (Y-axis). Corrected identity is only
#' supported if the original BLAST file included sequence lengths.
#' @param id.summary
#' Function summarizing the identity bins. Other recommended options
#' include: \code{median} to estimate the median instead of total bins, and
#' \code{function(x) mlv(x,method='parzen')$M} to estimate the mode.
#' @param id.cutoff
#' Cutoff of identity metric above which the hits are considered
#' \code{in-group}. The 95\% identity corresponds to the expectation of
#' ANI<95\% within species.
#' @param threads
#' Number of threads to use.
#' @param verbose
#' Indicates if the function should report the advance.
#' @param ...
#' Any additional parameters supported by \code{\link{plot.enve.RecPlot2}}.
#'
#' @return Returns an object of class \code{\link{enve.RecPlot2}}.
#'
#' @author Luis M. Rodriguez-R [aut, cre]
#' @author Kenji Gerhardt [aut]
#'
#' @export

enve.recplot2 <- function(
  prefix,
  plot = TRUE,
  pos.breaks = 1e3,
  pos.breaks.tsv = NA,
  id.breaks = 60,
  id.free.range = FALSE,
  id.metric = c('identity', 'corrected identity', 'bit score'),
  id.summary = sum,
  id.cutoff = 95,
  threads = 2,
  verbose = TRUE,
  ...
){
  # Settings
  id.metric <- match.arg(id.metric);

  #Read files
  if (verbose) cat("Reading files.\n")
  rec <- read.table(paste(prefix, ".rec", sep = ""),
    sep = "\t", comment.char = "", quote = "");
  lim <- read.table(paste(prefix, ".lim", sep = ""),
    sep = "\t", comment.char = "", quote = "", as.is = TRUE);

  # Build matrix
  if (verbose) cat("Building counts matrix.\n")
  if (id.metric == "corrected identity" & ncol(rec) < 6) {
    stop("Requesting corr. identity, but .rec file doesn't have 6th column")
  }
  rec.idcol <- ifelse(id.metric == "identity", 3,
                      ifelse(id.metric == "corrected identity", 6, 4))
  pos.names <- as.character(NULL)
  if (!is.na(pos.breaks.tsv)){
    tmp <- read.table(pos.breaks.tsv, sep = "\t", header = FALSE, as.is = TRUE)
    pos.breaks <- as.numeric(tmp[, 1])
    if (ncol(tmp) > 1) pos.names <- as.character(tmp[-1, 2])
  } else if (length(pos.breaks) == 1) {
    if (pos.breaks > 0){
      pos.breaks <- seq(min(lim[, 2]), max(lim[, 3]), length.out = pos.breaks + 1)
    } else {
      pos.breaks <- c(lim[1, 2], lim[, 3])
      pos.names  <- lim[, 1]
    }
  }
  if (length(id.breaks) == 1) {
    id.range.v <- rec[, rec.idcol]
    if (!id.free.range) id.range.v <- c(id.range.v, 70, 100)
    id.range.v <- range(id.range.v)
    id.breaks <- seq(id.range.v[1], id.range.v[2], length.out = id.breaks + 1)
  }

  # Run in parallel
  # If they already set threads to 1 manually, there's no point in launching
  # clusters, it's just slower. Ditto for small files.
  if (nrow(rec) < 75000 | threads == 1) {
    # Coerces rec into a form that __counts is happy about
    rec.l <- list()
    rec.l[[1]] <- list(rec = rec, verbose = FALSE)

    # No need to make a temporary variable, there's only one return for sure
    # and it's not a list because it isn't coming back from an apply
    counts <- enve.recplot2.__counts(
      rec.l[[1]], pos.breaks = pos.breaks, id.breaks = id.breaks,
      rec.idcol = rec.idcol)
  } else {
    cl <- makeCluster(threads)
    rec.l <- list()
    thl <- ceiling(nrow(rec)/threads)
    for (i in 0:(threads - 1)) {
      rec.l[[i + 1]] <- list(
        rec = rec[(i * thl + 1):min(((i + 1) * thl), nrow(rec)), ],
        verbose = ifelse(i == 0, verbose, FALSE))
    }
    counts.l <- clusterApply(
      cl, rec.l, enve.recplot2.__counts, pos.breaks = pos.breaks,
      id.breaks = id.breaks, rec.idcol = rec.idcol)
    stopCluster(cl) # No spooky ghost clusters

    counts <- counts.l[[1]]
    for (i in 2:threads) counts <- counts + counts.l[[i]]
  }

  # Estimate 1D histograms
  if (verbose) cat("Building histograms.\n")
  id.mids	<- (id.breaks[-length(id.breaks)] + id.breaks[-1])/2;
  id.ingroup	<- (id.mids > id.cutoff);
  id.counts	<- apply(counts, 2, id.summary);
  pos.counts.in   <- apply(counts[, id.ingroup], 1, sum);
  pos.counts.out  <- apply(counts[, !id.ingroup], 1, sum);

  # Plot and return
  recplot <- new('enve.RecPlot2',
                 counts = counts, id.counts = id.counts,
                 pos.counts.in = pos.counts.in, pos.counts.out = pos.counts.out,
                 id.breaks = id.breaks, pos.breaks = pos.breaks,
                 pos.names = pos.names, seq.breaks = c(lim[1, 2], lim[, 3]),
                 seq.names = lim[, 1], id.ingroup = id.ingroup,
                 id.metric = id.metric, call = match.call());
  if (plot) {
    if (verbose) cat("Plotting.\n")
    peaks <- plot(recplot, ...);
    attr(recplot, "peaks") <- peaks
  }
  return(recplot);
}

#' Enveomics: Recruitment Plot (2) Peak Finder
#'
#' Identifies peaks in the population histogram potentially indicating
#' sub-population mixtures.
#'
#' @param x
#' An \code{\link{enve.RecPlot2}} object.
#' @param method
#' Peak-finder method. This should be one of:
#' \itemize{
#'    \item \strong{emauto}
#'    (Expectation-Maximization with auto-selection of components)
#'    \item \strong{em}
#'    (Expectation-Maximization)
#'    \item \strong{mower}
#'    (Custom distribution-mowing method)
#' }
#' @param ...
#' Any additional parameters supported by
#' \code{\link{enve.recplot2.findPeaks}}.
#'
#' @return Returns a list of \code{\link{enve.RecPlot2.Peak}} objects.
#'
#' @author Luis M. Rodriguez-R [aut, cre]
#'
#' @export

enve.recplot2.findPeaks <- function(
  x,
  method="emauto",
  ...
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
}

#' Enveomics: Recruitment Plot (2) Emauto Peak Finder
#'
#' Identifies peaks in the population histogram using a Gaussian Mixture
#' Model Expectation Maximization (GMM-EM) method with number of components
#' automatically detected.
#'
#' @param x
#' An \code{\link{enve.RecPlot2}} object.
#' @param components
#' A vector of number of components to evaluate.
#' @param criterion
#' Criterion to use for components selection. Must be one of:
#' \code{aic} (Akaike Information Criterion), \code{bic} or \code{sbc}
#' (Bayesian Information Criterion or Schwarz Criterion).
#' @param merge.tol
#' When attempting to merge peaks with very similar sequencing depth, use
#' this number of significant digits (in log-scale).
#' @param verbose
#' Display (mostly debugging) information.
#' @param ...
#' Any additional parameters supported by
#' \code{\link{enve.recplot2.findPeaks.em}}.
#'
#' @return Returns a list of \code{\link{enve.RecPlot2.Peak}} objects.
#'
#' @author Luis M. Rodriguez-R [aut, cre]
#'
#' @export

enve.recplot2.findPeaks.emauto <- function(
  x,
  components = seq(1, 5),
  criterion = 'aic',
  merge.tol = 2L,
  verbose = FALSE,
  ...
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
    if(verbose) cat('Testing:',comp,'\n')
    best <- enve.recplot2.findPeaks.__emauto_one(x, comp, do_crit, best,
                                                 verbose, ...)
  }
  if(length(best[['peaks']])==0) return(list())

  seqdepths.r <- signif(log(sapply(best[['peaks']],
                                   function(x) x$seq.depth)), merge.tol)
  distinct <- length(unique(seqdepths.r))
  if(distinct < length(best[['peaks']])){
    if(verbose) cat('Attempting merge to', distinct, 'components\n')
    init <- apply(sapply(best[['peaks']],
                         function(x) c(x$param.hat, alpha=x$n.hat/x$n.total)), 1, as.numeric)
    init <- init[!duplicated(seqdepths.r),]
    init <- list(mu=init[,'mean'], sd=init[,'sd'],
                 alpha=init[,'alpha']/sum(init[,'alpha']))
    best <- enve.recplot2.findPeaks.__emauto_one(x, distinct, do_crit, best,
                                                 verbose, ...)
  }
  return(best[['peaks']])
}

#' Enveomics: Recruitment Plot (2) Em Peak Finder
#'
#' Identifies peaks in the population histogram using a Gaussian Mixture
#' Model Expectation Maximization (GMM-EM) method.
#'
#' @param x
#' An \code{\link{enve.RecPlot2}} object.
#' @param max.iter
#' Maximum number of EM iterations.
#' @param ll.diff.res
#' Maximum Log-Likelihood difference to be considered as convergent.
#' @param components
#' Number of distributions assumed in the mixture.
#' @param rm.top
#' Top-values to remove before finding peaks, as a quantile probability.
#' This step is useful to remove highly conserved regions, but can be
#' turned off by setting \code{rm.top=0}. The quantile is determined
#' \strong{after} removing zero-coverage windows.
#' @param verbose
#' Display (mostly debugging) information.
#' @param init
#' Initialization parameters. By default, these are derived from k-means
#' clustering. A named list with vectors for \code{mu}, \code{sd}, and
#' \code{alpha}, each of length \code{components}.
#' @param log
#' Logical value indicating if the estimations should be performed in
#' natural logarithm units. Do not change unless you know what you're
#' doing.
#'
#' @return Returns a list of \code{\link{enve.RecPlot2.Peak}} objects.
#'
#' @author Luis M. Rodriguez-R [aut, cre]
#'
#' @export

enve.recplot2.findPeaks.em <- function(
  x,
  max.iter = 1000,
  ll.diff.res = 1e-8,
  components = 2,
  rm.top = 0.05,
  verbose = FALSE,
  init,
  log = TRUE
){

  # Essential vars
  pos.binsize  <- x$pos.breaks[-1] - x$pos.breaks[-length(x$pos.breaks)]
  lsd1  <- (x$pos.counts.in/pos.binsize)[ x$pos.counts.in > 0 ]
  lsd1 <- lsd1[ lsd1 < quantile(lsd1, 1-rm.top, names = FALSE) ]
  if(log) lsd1 <- log(lsd1)

  # 1. Initialize
  if(missing(init)){
    km.clust <- kmeans(lsd1, components)$cluster
    init <- list(
      mu = tapply(lsd1, km.clust, mean),
      sd = tapply(lsd1, km.clust, sd),
      alpha = table(km.clust) / length(km.clust)
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
    if(is.na(ll.diff) || ll.diff == Inf) break
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
}

#' Enveomics: Recruitment Plot (2) Mowing Peak Finder
#'
#' Identifies peaks in the population histogram potentially indicating
#' sub-population mixtures, using a custom distribution-mowing method.
#'
#' @param x
#' An \code{\link{enve.RecPlot2}} object.
#' @param min.points
#' Minimum number of points in the quantile-estimation-range
#' \code{(quant.est)} to estimate a peak.
#' @param quant.est
#' Range of quantiles to be used in the estimation of a peak's
#' parameters.
#' @param mlv.opts
#' Ignored. For backwards compatibility.
#' @param fitdist.opts.sn
#' Options passed to \code{fitdist} to estimate the standard deviation if
#' \code{with.skewness=TRUE}. Note that the \code{start} parameter will be
#' ammended with \code{xi=estimated} mode for each peak.
#' @param fitdist.opts.norm
#' Options passed to \code{fitdist} to estimate the standard deviation if
#' \code{with.skewness=FALSE}. Note that the \code{start} parameter will be
#' ammended with \code{mean=estimated} mode for each peak.
#' @param rm.top
#' Top-values to remove before finding peaks, as a quantile probability.
#' This step is useful to remove highly conserved regions, but can be
#' turned off by setting \code{rm.top=0}. The quantile is determined
#' \strong{after} removing zero-coverage windows.
#' @param with.skewness
#' Allow skewness correction of the peaks. Typically, the
#' sequencing-depth distribution for a single peak is left-skewed, due
#' partly (but not exclusively) to fragmentation and mapping sensitivity.
#' See \emph{Lindner et al 2013, Bioinformatics 29(10):1260-7} for an
#' alternative solution for the first problem (fragmentation) called
#' "tail distribution".
#' @param optim.rounds
#' Maximum rounds of peak optimization.
#' @param optim.epsilon
#' Trace change at which optimization stops (unless \code{optim.rounds} is
#' reached first). The trace change is estimated as the sum of square
#' differences between parameters in one round and those from two rounds
#' earlier (to avoid infinite loops from approximation).
#' @param merge.logdist
#' Maximum value of \code{|log-ratio|} between centrality parameters in peaks
#' to attempt merging. The default of ~0.22 corresponds to a maximum
#' difference of 25\%.
#' @param verbose
#' Display (mostly debugging) information.
#' @param log
#' Logical value indicating if the estimations should be performed in
#' natural logarithm units. Do not change unless you know what you're
#' doing.
#'
#' @return Returns a list of \code{\link{enve.RecPlot2.Peak}} objects.
#'
#' @author Luis M. Rodriguez-R [aut, cre]
#'
#' @export

enve.recplot2.findPeaks.mower <- function(
  x,
  min.points=10,
  quant.est=c(0.002, 0.998),
  mlv.opts=list(method='parzen'),
  fitdist.opts.sn=list(distr='sn', method='qme', probs=c(0.1,0.5,0.8),
                       start=list(omega=1, alpha=-1), lower=c(0, -Inf, -Inf)),
  fitdist.opts.norm=list(distr='norm', method='qme', probs=c(0.4,0.6),
                         start=list(sd=1), lower=c(0, -Inf)),
  rm.top=0.05,
  with.skewness=TRUE,
  optim.rounds=200,
  optim.epsilon=1e-4,
  merge.logdist=log(1.75),
  verbose=FALSE,
  log=TRUE
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
}

#==============> Define utils

#' Enveomics: Recruitment Plot (2) Core Peak Finder
#'
#' Finds the peak in a list of peaks that is most likely to represent the
#' "core genome" of a population.
#'
#' @param x \code{list} of \code{\link{enve.RecPlot2.Peak}} objects.
#' 
#' @return A \code{\link{enve.RecPlot2.Peak}} object.
#'
#' @author Luis M. Rodriguez-R [aut, cre]
#'
#' @export

enve.recplot2.corePeak <- function(x) {
  # Find the peak with maximum depth (centrality)
  maxPeak <- x[[
    which.max(
      as.numeric(
        lapply(x, function(y) y$param.hat[[length(y$param.hat)]])
      )
    )
  ]]
  # If a "larger" peak (a peak explaining more bins of the genome) is within
  # the default "merge.logdist" distance, take that one instead.
  corePeak <- maxPeak
  for (p in x) {
    p.len <- ifelse(length(p$values) == 0, p$n.hat, length(p$values))
    corePeak.len <- ifelse(
      length(corePeak$values) == 0,
      corePeak$n.hat,
      length(corePeak$values)
    )
    sz.d <- log(p.len / corePeak.len)
    if (is.nan(sz.d) || sz.d < 0) next
    sq.d.a <- as.numeric(tail(p$param.hat, n = 1))
    sq.d.b <- as.numeric(tail(maxPeak$param.hat, n = 1))
    if (p$log) sq.d.a <- exp(sq.d.a)
    if (corePeak$log) sq.d.b <- exp(sq.d.b)
    if (abs(log(sq.d.a / sq.d.b)) < log(1.75) + sz.d / 5) corePeak <- p
  }
  return(corePeak)
}

#' Enveomics: Recruitment Plot (2) Change Cutoff
#'
#' Change the intra-species cutoff of an existing recruitment plot.
#'
#' @param rp
#' \code{\link{enve.RecPlot2}} object.
#' @param new.cutoff
#' New cutoff to use.
#' 
#' @return The modified \code{\link{enve.RecPlot2}} object.
#'
#' @author Luis M. Rodriguez-R [aut, cre]
#'
#' @export

enve.recplot2.changeCutoff <- function(rp, new.cutoff = 98) {
  # Re-calculate vectors
  id.mids	 <- (rp$id.breaks[-length(rp$id.breaks)] + rp$id.breaks[-1]) / 2
  id.ingroup	 <- (id.mids > new.cutoff)
  pos.counts.in  <- apply(rp$counts[, id.ingroup], 1, sum)
  pos.counts.out <- apply(rp$counts[, !id.ingroup], 1, sum)

  # Update object
  attr(rp, "id.ingroup")     <- id.ingroup
  attr(rp, "pos.counts.in")  <- pos.counts.in
  attr(rp, "pos.counts.out") <- pos.counts.out
  attr(rp, "call")           <- match.call()
  return(rp)
}

#' Enveomics: Recruitment Plot (2) Window Depth Threshold
#'
#' Identifies the threshold below which windows should be identified as
#' variable or absent.
#'
#' @param rp
#' Recruitment plot, an \code{\link{enve.RecPlot2}} object.
#' @param peak
#' Peak, an \code{\link{enve.RecPlot2.Peak}} object. If list, it is assumed to
#' be a list of \code{\link{enve.RecPlot2.Peak}} objects, in which case the core
#' peak is used (see \code{\link{enve.recplot2.corePeak}}).
#' @param lower.tail
#' If \code{FALSE}, it returns windows significantly above the peak in
#' sequencing depth.
#' @param significance
#' Significance threshold (alpha) to select windows.
#'
#' @return
#' Returns a float. The units are depth if the peaks were estimated in
#' linear scale, or log-depth otherwise (\code{peak$log}).
#'
#' @author Luis M. Rodriguez-R [aut, cre]
#'
#' @export

enve.recplot2.windowDepthThreshold <- function(
  rp,
  peak,
  lower.tail   = TRUE,
  significance = 0.05
) {
  if (is.list(peak)) peak <- enve.recplot2.corePeak(peak)
  par <- peak$param.hat
  par[["p"]] <- ifelse(lower.tail, significance, 1 - significance)
  thr <- do.call(ifelse(length(par) == 4, qsn, qnorm), par)
  if(peak$log) thr <- exp(thr)

  return(thr)
}

#' Enveomics: Recruitment Plot (2) Extract Windows
#'
#' Extract windows significantly below (or above) the peak in sequencing
#' depth.
#'
#' @param rp
#' Recruitment plot, a \code{\link{enve.RecPlot2}} object.
#' @param peak
#' Peak, an \code{\link{enve.RecPlot2.Peak}} object. If list, it is assumed to
#' be a list of \code{\link{enve.RecPlot2.Peak}} objects, in which case the core
#' peak is used (see \code{\link{enve.recplot2.corePeak}}).
#' @param lower.tail
#' If \code{FALSE}, it returns windows significantly above the peak in
#' sequencing depth.
#' @param significance
#' Significance threshold (alpha) to select windows.
#' @param seq.names
#' Returns subject sequence names instead of a vector of Booleans. If
#' the recruitment plot was generated with named position bins (e.g, using
#' \code{pos.breaks=0} or a two-column \code{pos.breaks.tsv}), it returns a
#' vector of characters (the sequence identifiers), otherwise it returns a
#' data.frame with a name column and two columns of coordinates.
#'
#' @return
#' Returns a vector of logicals if \code{seq.names = FALSE}.
#' If \code{seq.names = TRUE}, it returns a data.frame with five columns:
#' \code{name.from}, \code{name.to}, \code{pos.from}, \code{pos.to}, and
#' \code{seq.name} (see \code{\link{enve.recplot2.coordinates}}).
#'
#' @author Luis M. Rodriguez-R [aut, cre]
#'
#' @export

enve.recplot2.extractWindows <- function(
  rp,
  peak,
  lower.tail   = TRUE,
  significance = 0.05,
  seq.names    = FALSE
) {
  # Determine the threshold
  thr <- enve.recplot2.windowDepthThreshold(rp, peak, lower.tail, significance)

  # Select windows past the threshold
  seqdepth.in <- enve.recplot2.seqdepth(rp)
  if (lower.tail) {
    sel <- seqdepth.in < thr
  } else {
    sel <- seqdepth.in > thr
  }

  # seq.names = FALSE
  if(!seq.names) return(sel)
  # seq.names = TRUE
  return(enve.recplot2.coordinates(rp, sel))
}

#' Enveomics: Recruitment Plot (2) Compare Identities
#'
#' Compare the distribution of identities between two
#' \code{\link{enve.RecPlot2}} objects.
#' 
#' @param x
#' First \code{\link{enve.RecPlot2}} object.
#' @param y
#' Second \code{\link{enve.RecPlot2}} object.
#' @param method
#' Distance method to use. This should be (an unambiguous abbreviation of)
#' one of:
#' \itemize{
#'    \item{"hellinger"
#'          (\emph{Hellinger, 1090, doi:10.1515/crll.1909.136.210}),}
#'    \item{"bhattacharyya"
#'          (\emph{Bhattacharyya, 1943, Bull. Calcutta Math. Soc. 35}),}
#'    \item{"kl" or "kullback-leibler"
#'          (\emph{Kullback & Leibler, 1951, doi:10.1214/aoms/1177729694}), or}
#'    \item{"euclidean"}
#' }
#' @param smooth.par
#' Smoothing parameter for cubic spline smoothing. Use 0 for no smoothing.
#' Use \code{NULL} to automatically determine this value using leave-one-out
#' cross-validation (see \code{smooth.spline} parameter \code{spar}).
#' @param pseudocounts
#' Smoothing parameter for Laplace smoothing. Use 0 for no smoothing, or
#' 1 for add-one smoothing.
#' @param max.deviation
#' Maximum mean deviation between identity breaks tolerated (as percent
#' identity). Difference in number of \code{id.breaks} is never tolerated.
#' 
#' @return A \strong{numeric} indicating the distance between the objects.
#' 
#' @author Luis M. Rodriguez-R [aut, cre]
#'
#' @export

enve.recplot2.compareIdentities <- function
(
  x,
  y,
  method        = "hellinger",
  smooth.par    = NULL,
  pseudocounts  = 0,
  max.deviation = 0.75
) {
  # Sanity checks
  METHODS <- c(
    "hellinger", "bhattacharyya", "kullback-leibler", "kl", "euclidean"
  )
  i.meth <- pmatch(method, METHODS)
  if (is.na(i.meth)) stop("Invalid distance ", method)
  if (!inherits(x, "enve.RecPlot2"))
    stop("'x' must inherit from class `enve.RecPlot2`")
  if (!inherits(y, "enve.RecPlot2"))
    stop("'y' must inherit from class `enve.RecPlot2`")
  if (length(x$id.breaks) != length(y$id.breaks))
    stop("'x' and 'y' must have the same number of `id.breaks`")
  dev <- mean(abs(x$id.breaks - y$id.breaks))
  if (dev > max.deviation)
    stop("'x' and 'y' must have similar `id.breaks`; exceeding max.deviation: ",
         dev)

  # Initialize
  x.cnt <- x$id.counts
  y.cnt <- y$id.counts
  if (is.null(smooth.par) || smooth.par > 0){
    x.mids <- (x$id.breaks[-1] + x$id.breaks[-length(x$id.breaks)]) / 2
    y.mids <- (y$id.breaks[-1] + y$id.breaks[-length(y$id.breaks)]) / 2
    p.spline <- smooth.spline(x.mids, x.cnt, spar = smooth.par)
    q.spline <- smooth.spline(y.mids, y.cnt, spar = smooth.par)
    x.cnt <- pmax(p.spline$y, 0)
    y.cnt <- pmax(q.spline$y, 0)
  }

  a <- as.numeric(pseudocounts)
  p <- (x.cnt + a) / sum(x.cnt + a)
  q <- (y.cnt + a) / sum(y.cnt + a)
  d <- NA

  if (i.meth %in% c(1L, 2L)) {
    d <- sqrt(sum((sqrt(p) - sqrt(q))**2)) / sqrt(2)
    if(i.meth == 2L) d <- 1 - d**2
  } else if (i.meth %in% c(3L, 4L)) {
    sel <- p > 0
    if (any(q[sel] == 0))
      stop("Undefined distance without absolute continuity, use pseudocounts")
    d <- -sum(p[sel] * log(q[sel] / p[sel]))
  } else if (i.meth == 5L) {
    d <- sqrt(sum((q - p)**2))
  }
  return(d)
}

#' Enveomics: Recruitment Plot (2) Coordinates
#'
#' Returns the sequence name and coordinates of the requested position bins.
#'
#' @param x
#' \code{\link{enve.RecPlot2}} object.
#' @param bins
#' Vector of selected bins to return. It can be a vector of logical values
#' with the same length as \code{x$pos.breaks-1} or a vector of integers. If
#' missing, returns the coordinates of all windows.
#'
#' @return
#' Returns a data.frame with five columns: \code{name.from} (character),
#' \code{pos.from} (numeric), \code{name.to} (character), \code{pos.to}
#' (numeric), and \code{seq.name} (character).
#' The first two correspond to sequence and position of the start point of the
#' bin. The next two correspond to the sequence and position of the end point of
#' the bin. The last one indicates the name of the sequence (if defined).
#'
#' @author Luis M. Rodriguez-R [aut, cre]
#'
#' @export

enve.recplot2.coordinates <- function(x, bins) {
  if (!inherits(x, "enve.RecPlot2"))
    stop("'x' must inherit from class `enve.RecPlot2`")
  if (missing(bins)) bins <- rep(TRUE, length(x$pos.breaks)-1)
  if (!is.vector(bins)) stop("'bins' must be a vector")
  if (inherits(bins, "logical")) bins <- which(bins)

  y <- data.frame(stringsAsFactors = FALSE, row.names = bins)

  for (i in 1:length(bins)) {
    j <- bins[i]
    # Concatenated coordinates
    cc <- x$pos.breaks[c(j, j+1)]
    # Find the corresponding `seq.breaks`
    sb.from <- which(
      cc[1] >= x$seq.breaks[-length(x$seq.breaks)] &
        cc[1] <  x$seq.breaks[-1])
    sb.to   <- which(
      cc[2] >  x$seq.breaks[-length(x$seq.breaks)] &
        cc[2] <= x$seq.breaks[-1])
    # Translate coordinates
    if (length(sb.from) == 1 & length(sb.to) == 1) {
      y[i, 'name.from'] <- x$seq.names[sb.from]
      y[i, 'pos.from']  <- floor(x$seq.breaks[sb.from] + cc[1] - 1)
      y[i, 'name.to']   <- x$seq.names[sb.to]
      y[i, 'pos.to']    <- ceiling(x$seq.breaks[sb.to] + cc[2] - 1)
      y[i, 'seq.name']  <- x$pos.names[i]
    }
  }

  return(y)
}

#' Enveomics: Recruitment Plot (2) Sequencing Depth
#'
#' Calculate the sequencing depth of the given window(s).
#'
#' @param x
#' \code{\link{enve.RecPlot2}} object.
#' @param sel
#' Window(s) for which the sequencing depth is to be calculated. If not
#' passed, it returns the sequencing depth of all windows.
#' @param low.identity
#' A logical indicating if the sequencing depth is to be estimated only
#' with low-identity matches. By default, only high-identity matches are
#' used.
#'
#' @return
#' Returns a numeric vector of sequencing depths (in bp/bp).
#'
#' @author Luis M. Rodriguez-R [aut, cre]
#'
#' @export

enve.recplot2.seqdepth <- function(x, sel, low.identity = FALSE) {
  if (!inherits(x, "enve.RecPlot2"))
    stop("'x' must inherit from class `enve.RecPlot2`")
  if (low.identity) {
    pos.cnts.in <- x$pos.counts.out
  } else {
    pos.cnts.in <- x$pos.counts.in
  }
  pos.breaks  <- x$pos.breaks
  pos.binsize <- (pos.breaks[-1] - pos.breaks[-length(pos.breaks)])
  seqdepth.in <- pos.cnts.in/pos.binsize
  if (missing(sel)) return(seqdepth.in)
  return(seqdepth.in[sel])
}

#' Enveomics: Recruitment Plot (2) ANI Estimate
#'
#' Estimate the Average Nucleotide Identity from reads (ANIr) from a
#' recruitment plot.
#'
#' @param x
#' \code{\link{enve.RecPlot2}} object.
#' @param range
#' Range of identities to be considered. By default, the full range
#' is used (note that the upper boundary is \code{Inf} and not 100 because
#' recruitment plots can also be built with bit-scores). To use only
#' intra-population matches (with identities), use \code{c(95, 100)}. To use
#' only inter-population values, use \code{c(0, 95)}.
#' 
#' @return A numeric value indicating the ANIr (as percentage).
#'
#' @author Luis M. Rodriguez-R [aut, cre]
#'
#' @export

enve.recplot2.ANIr <- function
(x,
 range=c(0,Inf)
){
  if(!inherits(x, "enve.RecPlot2"))
    stop("'x' must inherit from class `enve.RecPlot2`")
  id.b <- x$id.breaks
  id <- (id.b[-1]+id.b[-length(id.b)])/2
  cnt <- x$id.counts
  cnt[id < range[1]] <- 0
  cnt[id > range[2]] <- 0
  return(sum(id*cnt/sum(cnt)))
}

#==============> Define internal functions

#' Enveomics: Recruitment Plot (2) Internal Ancillary Function
#'
#' Internal ancillary function (see \code{\link{enve.recplot2}}).
#'
#' @param x \code{\link{enve.RecPlot2}} object
#' @param pos.breaks Position breaks
#' @param id.breaks Identity breaks
#' @param rec.idcol Identity column to use
#' 
#' @return 2-dimensional matrix of counts per identity and position bins.
#'
#' @author Luis M. Rodriguez-R [aut, cre]
#' @author Kenji Gerhardt [aut]
#'
#' @export

enve.recplot2.__counts <- function(x, pos.breaks, id.breaks, rec.idcol) {
  rec2 <- x$rec
  verbose <- x$verbose

  # get counts of how many occurrences of each genome pos.bin there are per read
  x.bins <- mapply(
    function(start, end) {
      list(rle(findInterval(start:end, pos.breaks, left.open = TRUE)))
    },
    rec2[, 1], rec2[, 2]
  )

  # find the single y bin for each row, replicates it at the correct places to
  # the number of distinct bins found in its row
  y.bins <- rep(findInterval(rec2[, rec.idcol], id.breaks, left.open = TRUE),
                times = unlist(lapply(x.bins, function(a) length(a$lengths))))

  # x.bins_counts is the number of occurrences of each bin a row contains,
  # per row, then unlisted
  x.bins_counts <- unlist(lapply(x.bins, function(a) a$lengths))

  # these are the pos. in. genome bins that each count in x.bins_counts falls
  # into
  x.bins <- unlist(lapply(x.bins, function(a) a$values))

  # much more efficient counts implementation in R using lists instead of a
  # matrix:
  counts <- lapply(
    1:(length(pos.breaks) - 1),
    function(col_len) rep(0, length(id.breaks) - 1)
  )

  # accesses the correct list in counts by x.bin, then
  # accesses the position in that row by y.bins and adds the new count
  for (i in 1:length(x.bins)) {
    counts[[x.bins[i]]][y.bins[i]] <- counts[[x.bins[i]]][y.bins[i]] + x.bins_counts[i]
  }

  counts <- do.call(rbind, counts)
  return(counts)
}

#' Enveomics: Recruitment Plot (2) EMauto Peak Finder - Internal Ancillary Function
#'
#' Internal ancillary function (see
#' \code{\link{enve.recplot2.findPeaks.emauto}}).
#'
#' @param x \code{\link{enve.RecPlot2}} object.
#' @param comp Components.
#' @param do_crit Function estimating the criterion.
#' @param best Best solution thus far.
#' @param verbose If verbose.
#' @param ...
#' Additional parameters for \code{\link{enve.recplot2.findPeaks.em}}.
#'
#' @return Updated solution with the same structure as \code{best}.
#'
#' @author Luis M. Rodriguez-R [aut, cre]
#'
#' @export

enve.recplot2.findPeaks.__emauto_one <- function(
  x, comp, do_crit, best, verbose, ...
) {
  peaks <- enve.recplot2.findPeaks.em(x = x, components = comp, ...)
  if (length(peaks) == 0) return(best)
  k <- comp * 3 - 1 # mean & sd for each component, and n-1 free alpha params
  crit <- do_crit(peaks[[1]]$err.res, k, peaks[[1]]$n.total)
  if(verbose)
    cat(comp, "\t| LL =", peaks[[1]]$err.res, "\t| Estimate =", crit,
        ifelse(crit > best[["crit"]], "*", ""), "\n")
  if(crit > best[["crit"]]){
    best[["crit"]]  <- crit
    best[["peaks"]] <- peaks
  }
  best[["pstore"]][[comp]] <- peaks
  return(best)
}

#' Enveomics: Recruitment Plot (2) EM Peak Finder - Internal Ancillary Function Expectation
#'
#' Internal ancillary function (see \code{\link{enve.recplot2.findPeaks.em}}).
#'
#' @param x Vector of log-transformed sequencing depths
#' @param theta Parameters list
#' 
#' @return A list with components \code{ll} (numeric) the log-likelihood, and
#' \code{posterior} (numeric) the posterior probability.
#'
#' @author Luis M. Rodriguez-R [aut, cre]
#'
#' @export

enve.recplot2.findPeaks.__em_e <- function(x, theta) {
  components <- length(theta[['mu']])
  product <- do.call(cbind,
                     lapply(1:components,
                            function(i) dnorm(x, theta[['mu']][i],
                                              theta[['sd']][i])*theta[['alpha']][i]))
  sum.of.components <- rowSums(product)
  posterior <- product / sum.of.components
  for(i in which(sum.of.components == Inf)) {
    cat(i,'/',nrow(product), ':', product[i,], '\n')
  }

  return(list(ll = sum(log(sum.of.components)), posterior = posterior))
}

#' Enveomics: Recruitment Plot (2) Em Peak Finder - Internal Ancillary Function Maximization
#'
#' Internal ancillary function (see \code{\link{enve.recplot2.findPeaks.em}}).
#'
#' @param x Vector of log-transformed sequencing depths
#' @param posterior Posterior probability
#' 
#' @return A list with components \code{mu} (numeric) the estimated mean,
#' \code{sd} (numeric) the estimated standard deviation, and \code{alpha}
#' (numeric) the estimated alpha parameter.
#'
#' @author Luis M. Rodriguez-R [aut, cre]
#'
#' @export

enve.recplot2.findPeaks.__em_m <- function(x, posterior) {
  components <- ncol(posterior)
  n <- colSums(posterior)
  mu <- colSums(posterior * x) / n
  sd <- sqrt( colSums(
    posterior * (matrix(rep(x,components), ncol=components) - mu)^2) / n )
  alpha <- n/length(x)
  return(list(mu = mu, sd = sd, alpha = alpha))
}

#' Enveomics: Recruitment Plot (2) Peak S4 Class - Internal Ancillary Function
#'
#' Internal ancillary function (see \code{\link{enve.RecPlot2.Peak}}).
#'
#' @param x \code{\link{enve.RecPlot2.Peak}} object
#' @param mids Midpoints
#' @param counts Counts
#' 
#' @return A numeric vector of counts (histogram)
#'
#' @author Luis M. Rodriguez-R [aut, cre]
#'
#' @export

enve.recplot2.__peakHist <- function(x, mids, counts = TRUE){
  d.o <- x$param.hat
  if (length(x$log) == 0) x$log <- FALSE
  if (x$log) {
    d.o$x <- log(mids)
  } else {
    d.o$x <- mids
  }
  prob  <- do.call(paste('d', x$dist, sep = ""), d.o)
  if(!counts) return(prob)
  if(length(x$values)>0) return(prob*length(x$values)/sum(prob))
  return(prob * x$n.hat / sum(prob))
}

#' Enveomics: Recruitment Plot (2) Mowing Peak Finder - Internal Ancillary Function 1
#'
#' Internal ancillary function (see
#' \code{\link{enve.recplot2.findPeaks.mower}}).
#'
#' @param lsd1 Vector of log-transformed sequencing depths
#' @param min.points Minimum number of points
#' @param quant.est Quantile estimate
#' @param mlv.opts List of options for \code{mlv}
#' @param fitdist.opts List of options for \code{fitdist}
#' @param with.skewness If skewed-normal should be used
#' @param optim.rounds Maximum number of optimization rounds
#' @param optim.epsilon Minimum difference considered negligible
#' @param n.total Global number of windows
#' @param merge.logdist Attempted \code{merge.logdist} parameter
#' @param verbose If verbose
#' @param log If log-transformed depths
#' 
#' @return Return an \code{enve.RecPlot2.Peak} object.
#'
#' @author Luis M. Rodriguez-R [aut, cre]
#'
#' @export

enve.recplot2.findPeaks.__mow_one <- function(
  lsd1, min.points, quant.est, mlv.opts, fitdist.opts, with.skewness,
  optim.rounds, optim.epsilon, n.total, merge.logdist, verbose, log
) {
  dist	<- ifelse(with.skewness, "sn", "norm")

  # Find peak
  o <- mlv.opts
  o$x <- lsd1
  mode1 <- median(lsd1) # mode1 <- do.call(mlv, o)$M;
  if (verbose) cat("Anchoring at mode =", mode1, "\n")
  param.hat <- fitdist.opts$start
  last.hat <- param.hat
  lim <- NA
  if (with.skewness) { param.hat$xi <- mode1 } else { param.hat$mean <- mode1 }

  # Refine peak parameters
  for (round in 1:optim.rounds) {
    param.hat[[ 1 ]] <- param.hat[[1]] / diff(quant.est) # <- expand dispersion
    lim.o <- param.hat
    lim.o$p <- quant.est
    lim <- do.call(paste("q", dist, sep = ""), lim.o)
    lsd1.pop <- lsd1[(lsd1 > lim[1]) & (lsd1 < lim[2])]
    if (verbose)
      cat(" Round", round, "with n =", length(lsd1.pop),
          "and params =", as.numeric(param.hat), " \r")
    if (length(lsd1.pop) < min.points) break
    o <- fitdist.opts
    o$data <- lsd1.pop
    o$start <- param.hat
    last.last.hat <- last.hat
    last.hat <- param.hat
    param.hat <- as.list(do.call(fitdist, o)$estimate)
    if (any(is.na(param.hat))) {
      if (round > 1) param.hat <- last.hat
      break
    }
    if (round > 1) {
      epsilon1 <- sum((as.numeric(last.hat) - as.numeric(param.hat))^2)
      if (epsilon1 < optim.epsilon) break
      if (round > 2) {
        epsilon2 <- sum((as.numeric(last.last.hat) - as.numeric(param.hat))^2)
        if (epsilon2 < optim.epsilon) break
      }
    }
  }
  if (verbose) cat("\n")
  if (is.na(param.hat[1]) | is.na(lim[1])) return(NULL)

  # Mow distribution
  lsd2 <- c()
  lsd.pop <- c()
  n.hat <- length(lsd1.pop) / diff(quant.est)
  peak <- new(
    "enve.RecPlot2.Peak", dist = dist, values = as.numeric(), mode = mode1,
    param.hat = param.hat, n.hat = n.hat, n.total = n.total,
    merge.logdist = merge.logdist, log = log
  )
  peak.breaks <- seq(min(lsd1), max(lsd1), length = 20)
  peak.cnt <- enve.recplot2.__peakHist(
    peak, (peak.breaks[-length(peak.breaks)] + peak.breaks[-1]) / 2
  )
  for (i in 2:length(peak.breaks)) {
    values <- lsd1[(lsd1 >= peak.breaks[i-1]) & (lsd1 < peak.breaks[i])]
    n.exp <- peak.cnt[i - 1]
    if (is.na(n.exp) | n.exp == 0) n.exp <- 0.1
    if (length(values) == 0) next
    in.peak <- runif(length(values)) <= n.exp / length(values)
    lsd2 <- c(lsd2, values[!in.peak])
    lsd.pop <- c(lsd.pop, values[in.peak])
  }
  if (length(lsd.pop) < min.points) return(NULL)

  # Return peak
  attr(peak, "values") <- lsd.pop
  attr(peak, "values.res") <- lsd2
  attr(peak, "err.res") <- 1 - 0.5 * (
    cor(
      hist(lsd.pop, breaks = peak.breaks, plot = FALSE)$counts,
      hist(lsd1, breaks = peak.breaks, plot = FALSE)$counts
    ) + 1
  )
  mu <- tail(param.hat, n = 1)
  attr(peak, "seq.depth") <- ifelse(log, exp(mu), mu)
  if(verbose)
    cat(" Extracted peak with n =", length(lsd.pop),
        "with expected n =", n.hat, "\n")
  return(peak)
}

#' Enveomics: Recruitment Plot (2) Mowing Peak Finder - Internal Ancillary Function 2
#'
#' Internal ancillary function (see \code{\link{enve.recplot2.findPeaks.mower}}).
#'
#' @param peaks.opts List of options for \code{\link{enve.recplot2.findPeaks.__mow_one}}
#'
#' @return A list of \code{enve.RecPlot2.Peak} objects.
#'
#' @author Luis M. Rodriguez-R [aut, cre]
#'
#' @export

enve.recplot2.findPeaks.__mower <- function(peaks.opts) {
  peaks <- list()
  while (length(peaks.opts$lsd1) > peaks.opts$min.points) {
    peak <- do.call(enve.recplot2.findPeaks.__mow_one, peaks.opts)
    if (is.null(peak)) break
    peaks[[length(peaks) + 1]] <- peak
    peaks.opts$lsd1 <- peak$values.res
  }
  return(peaks)
}

#' Enveomics: Recruitment Plot (2) Peak Finder - Internal Ancillary Function
#'
#' Internal ancillary function (see \code{\link{enve.recplot2.findPeaks}}).
#'
#' @param peak Query \code{\link{enve.RecPlot2.Peak}} object
#' @param peaks list of \code{\link{enve.RecPlot2.Peak}} objects
#'
#' @return A numeric index out of \code{peaks}.
#'
#' @author Luis M. Rodriguez-R [aut, cre]
#'
#' @export

enve.recplot2.__whichClosestPeak <- function(peak, peaks){
  dist <- as.numeric(
    lapply(
      peaks,
      function(x)
        abs(log(x$param.hat[[length(x$param.hat)]] /
          peak$param.hat[[length(peak$param.hat)]]))
    )
  )
  dist[dist == 0] <- Inf
  return(which.min(dist))
}
