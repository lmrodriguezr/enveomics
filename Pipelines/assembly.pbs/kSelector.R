
# @author: Luis M. Rodriguez-R
# @update: Nov-29-2012

kSelector <- function(file, lib){
   red <- rgb(0.6, 0, 0);
   d <- read.table(file, sep=" ", h=T, fill=T);
   d <- d[!is.na(d$N50) & !is.na(d$used), ];
   d$reads <- max(d$reads, na.rm=T)
   d <- d[order(d$K), ];
   par(mar=c(5,4,4,5)+.1, cex=0.8);
   barplot(d$reads/1e6, names=d$K, col='white', ylab='Number of reads (in millions)', xlab='K',
      main=paste('Reads used and N50 by K-mers in the assembly of', lib));
   barplot(d$used/1e6, col='grey', add=T);
   par(new=T);
   plot(1:length(d$K)-0.5, d$N50, col=red, t='b', lty=2, pch=20, cex=1, lwd=1.5,
      xlim=c(0, length(d$K)), xaxt='n', yaxt='n', xlab='', ylab='');
   axis(4, col.axis=red);
   mtext('N50 (bp)', side=4, line=3, col=red);
   return(d);
}

