
#
# @author Luis M. Rodriguez-R <lmrodriguezr at gmail dot com>
# @license artistic license 2.0
#
library(gplots);
library(modeest);
require(splines);

Recplot <- function(prefix,
		# Id. hist.
		id.min=NULL, id.max=NULL, id.binsize=NULL, id.splines=0,
		id.metric='id',
		# Pos. hist.
		pos.min=1, pos.max=NULL, pos.binsize=1e3, pos.splines=0,
		# Rec. plot
		rec.col1='white', rec.col2='black', main=NULL,
		# Stats
		id.mean=TRUE, id.median=TRUE, id.mode=TRUE,
		seqdepth.top=TRUE, seqdepth.notop=TRUE, seqdepth.all=TRUE,
		# Return
		ret.recplot=FALSE, ret.idhist=FALSE, ret.poshist=FALSE,
		# General
		id.cutoff=NULL, verbose=TRUE, ...){
   if(is.null(prefix)) stop('Parameter prefix is mandatory.');
   
   # Read files
   if(verbose) cat("Reading files.\n")
   rec <- read.table(paste(prefix, '.rec', sep=''), sep="\t", comment.char='', quote='');
   lim <- read.table(paste(prefix, '.lim', sep=''), sep="\t", comment.char='', quote='');
   id.metric <- tolower(id.metric)
   if(id.metric=='id' || id.metric=='identity'){
      id.reccol <- 3
      id.shortname <- 'Id.'
      id.fullname  <- 'Identity'
      id.units     <- '%'
      id.hallmarks <- seq(0, 100, by=5)
      if(is.null(id.max)) id.max <- 100
      if(is.null(id.cutoff)) id.cutoff <- 95
      if(is.null(id.binsize)) id.binsize <- 0.1
   }else if(id.metric=='cid' || id.metric=='nid' || id.metric=='corrected identity'){
      if(ncol(rec)<6) stop("Requesting corrected identity, but .rec file doesn't have 6th column")
      id.reccol <- 6
      id.shortname <- 'cId.'
      id.fullname  <- 'Corrected identity'
      id.units     <- '%'
      id.hallmarks <- seq(0, 100, by=5)
      if(is.null(id.max)) id.max <- 100
      if(is.null(id.cutoff)) id.cutoff <- 95
      if(is.null(id.binsize)) id.binsize <- 0.1
   }else if(id.metric=='bs' || id.metric=='bits' || id.metric=='bit score'){
      id.reccol <- 4
      id.shortname <- 'BSc.'
      id.fullname  <- 'Bit score'
      id.units     <- 'bits'
      max.bs <- max(rec[, id.reccol])
      id.hallmarks <- seq(0, max.bs*1.2, by=50)
      if(is.null(id.max)) id.max <- max.bs
      if(is.null(id.cutoff)) id.cutoff <- 0.95 * max.bs
      if(is.null(id.binsize)) id.binsize <- 5
   }else{
      stop("Unsupported id.metric value: ", id.metric)
   }
   if(is.null(id.min)) id.min <- min(rec[, id.reccol]);
   if(is.null(pos.max)) pos.max <- max(lim[, 3]);
   id.lim <- c(id.min, id.max);
   pos.lim <- c(pos.min, pos.max)/1e6;
   id.breaks <- round((id.max-id.min)/id.binsize);
   pos.breaks <- round((pos.max-pos.min)/pos.binsize);
   if(is.null(main)) main <- paste('Recruitment plot of ', prefix, sep='');
   pos.marks=seq(pos.min, pos.max, length.out=pos.breaks+1)/1e6;
   id.marks=seq(id.min, id.max, length.out=id.breaks+1);
   id.topclasses <- 0;
   for(i in length(id.marks):1) if(id.marks[i]>id.cutoff) id.topclasses <- id.topclasses + 1;
   
   # Set-up image
   layout(matrix(c(3,4,1,2), nrow=2, byrow=TRUE), widths=c(2,1), heights=c(1,2));
   out <- list();

   # Recruitment plot
   if(verbose) cat("Rec. plot.\n")
   par(mar=c(5,4,0,0)+0.1);
   rec.hist <- matrix(0, nrow=pos.breaks, ncol=id.breaks);
   for(i in 1:nrow(rec)){
      id.class <- ceiling((id.breaks)*((rec[i, id.reccol]-id.min)/(id.max-id.min)));
      if(id.class<=id.breaks & id.class>0){
	 for(pos in rec[i, 1]:rec[i, 2]){
	    pos.class <- ceiling((pos.breaks)*((pos-pos.min)/(pos.max-pos.min)));
	    if(pos.class<=pos.breaks & pos.class>0) rec.hist[pos.class, id.class] <- rec.hist[pos.class, id.class]+1;
	 }
      }
   }
   id.top <- c((1-id.topclasses):0) + id.breaks;
   rec.col=colorpanel(256, rec.col1, rec.col2);
   image(x=pos.marks, y=id.marks, z=log10(rec.hist),
   		breaks=seq(0, log10(max(rec.hist)), length.out=1+length(rec.col)), col=rec.col,
		xlim=pos.lim, ylim=id.lim, xlab='Position in genome (Mbp)',
		ylab=paste(id.fullname, ' (',id.units,')', sep=''), xaxs='i', yaxs='r');
   abline(v=c(lim$V2, lim$V3)/1e6, lty=1, col=grey(0.85));
   abline(h=id.hallmarks, lty=2, col=grey(0.7));
   abline(h=id.marks[id.top[1]], lty=3, col=grey(0.5))
   legend('bottomleft', 'Rec. plot', bg=rgb(1,1,1,2/3));
   out <- c(out, list(pos.marks=pos.marks, id.marks=id.marks));
   if(ret.recplot) out <- c(out, list(recplot=rec.hist));

   # Identity histogram
   if(verbose) cat(id.shortname, " hist.\n", sep='')
   par(mar=c(5,0,0,2)+0.1);
   id.hist <- colSums(rec.hist);
   plot(1, t='n', xlim=c(1, max(id.hist)), ylim=id.lim, ylab='', yaxt='n', xlab='Sequences (bp)', log='x', ...);
   id.x <- rep(id.marks, each=2)[2:(id.breaks*2+1)]
   id.f <- rep(id.hist, each=2)[1:(id.breaks*2)]
   if(sum(id.f)>0){
      lines(id.f, id.x, lwd=ifelse(id.splines>0, 1/2, 2), type='o', pch='.');
      if(id.splines>0){
	 id.spline <- smooth.spline(id.x[id.f>0], log(id.f[id.f>0]), spar=id.splines)
	 lines(exp(id.spline$y), id.spline$x, lwd=2)
      }
   }
   
   abline(h=id.hallmarks, lty=2, col=grey(0.7));
   abline(h=id.marks[id.top[1]], lty=3, col=grey(0.5))
   legend('bottomright', paste(id.shortname, 'histogram'), bg=rgb(1,1,1,2/3));
   if(id.mean)   out <- c(out, list(id.mean=mean(rec[, id.reccol])));
   if(id.median) out <- c(out, list(id.median=median(rec[, id.reccol])));
   if(id.mode)   out <- c(out, list(id.mode=mlv(rec[, id.reccol], method='mfv')$M));
   if(ret.idhist)  out <- c(out, list(id.hist=id.hist));

   # Position histogram
   if(verbose) cat("Pos. hist.\n")
   par(mar=c(0,4,4,0)+0.1);
   h1<-rep(0,nrow(rec.hist)) ;
   h2<-rep(0,nrow(rec.hist)) ;
   pos.winsize <- (pos.max-pos.min+1)/pos.breaks;
   if(sum(rec.hist[, id.top])>0) h1 <- rowSums(matrix(rec.hist[, id.top], nrow=nrow(rec.hist)))/pos.winsize;
   if(sum(rec.hist[,-id.top])>0) h2 <- rowSums(matrix(rec.hist[,-id.top], nrow=nrow(rec.hist)))/pos.winsize;
   
   ymin <- min(1, h1[h1>0], h2[h2>0]);
   ymax <- max(10, h1, h2);
   if(is.na(ymin) || ymin<=0) ymin <- 1e-10;
   if(is.na(ymax) || ymax<=0) ymax <- 1;
   plot(1, t='n', xlab='', xaxt='n', ylab='Sequencing depth (X)', log='y', xlim=pos.lim,
   	ylim=c(ymin, ymax), xaxs='i', main=main, ...);
   abline(v=c(lim[,2], lim[,3])/1e6, lty=1, col=grey(0.85));
   abline(h=10^c(0:5), lty=2, col=grey(0.7));
   if(sum(h2)>0){
      h2.x <- rep(pos.marks, each=2)[2:(pos.breaks*2+1)]
      h2.y <- rep(h2, each=2)[1:(pos.breaks*2)]
      lines(h2.x, h2.y, lwd=ifelse(pos.splines>0, 1/2, 2), col=grey(0.5));
      if(pos.splines>0){
         h2.spline <- smooth.spline(h2.x[h2.y>0], log(h2.y[h2.y>0]), spar=pos.splines)
	 lines(h2.spline$x, exp(h2.spline$y), lwd=2, col=grey(0.5))
      }
      if(ret.poshist) out <- c(out, list(pos.hist.low=h2.y));
   }
   if(sum(h1)>0){
      h1.x <- rep(pos.marks, each=2)[2:(pos.breaks*2+1)]
      h1.y <- rep(h1, each=2)[1:(pos.breaks*2)]
      lines(h1.x, h1.y, lwd=ifelse(pos.splines>0, 1/2, 2), col=grey(0));
      if(pos.splines>0){
         h1.spline <- smooth.spline(h1.x[h1.y>0], log(h1.y[h1.y>0]), spar=pos.splines)
	 lines(h1.spline$x, exp(h1.spline$y), lwd=2, col=grey(0))
      }
      if(ret.poshist) out <- c(out, list(pos.hist.top=h1.y));
   }
   legend('topleft', 'Pos. histogram', bg=rgb(1,1,1,2/3));
   out <- c(out, list(id.max=id.max, id.cutoff=id.marks[id.top[1]]));
   if(seqdepth.top)   out <- c(out, list(seqdepth.mean.top=mean(h1)));
   if(seqdepth.notop) out <- c(out, list(seqdepth.mean.low=mean(h2)));
   if(seqdepth.all)   out <- c(out, list(seqdepth.mean=mean(h1+h2)));
   out <- c(out, list(id.metric=id.fullname))
   
   # Legend
   par(mar=c(0,0,4,2)+0.1);
   plot(1, t='n', xlab='', xaxt='n', ylab='', yaxt='n', xlim=c(0,1), ylim=c(0,1), xaxs='r', yaxs='i', ...);
   text(1/2, 5/6, labels=paste('Reads per ', signif((pos.max-pos.min)/pos.breaks, 2), ' bp (rec. plot)', sep=''), pos=3);
   leg.col <- colorpanel(100, rec.col1, rec.col2);
   leg.lab <- signif(10^seq(0, log10(max(rec.hist)), length.out=10), 2);
   for(i in 1:10){
      for(j in 1:10){
         k <- (i-1)*10 + j;
	 polygon(c(k-1, k, k, k-1)/100, c(2/3, 2/3, 5/6, 5/6), border=leg.col[k], col=leg.col[k]);
      }
      text((i-0.5)/10, 2/3, labels=paste(leg.lab[i], ''), srt=90, pos=2, offset=0, cex=3/4);
   }
   legend('bottom',
   	legend=c('Contig boundary', 'Hallmark', paste(id.fullname, 'cutoff'),
		paste('Pos. hist.: ',id.shortname,' > ',signif(id.marks[id.top[1]],2),id.units,sep=''),
		paste('Pos. hist.: ',id.shortname,' < ',signif(id.marks[id.top[1]],2),id.units,sep='')), ncol=2,
   	col=grey(c(0.85, 0.7, 0.5, 0, 0.5)), lty=c(1,2,3,1,1), lwd=c(1,1,1,2,2), bty='n', inset=0.05, cex=5/6);
   return(out);
}

