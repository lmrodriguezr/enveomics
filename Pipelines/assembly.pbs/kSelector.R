
# @author: Luis M. Rodriguez-R
# @update: Nov-29-2012

kSelector <- function(file, lib){
   red <- rgb(0.6, 0, 0);
   d <- read.table(file, sep=" ", h=T, fill=T);
   d <- d[!is.na(d$N50) & !is.na(d$used), ];
   d$reads <- max(d$reads, na.rm=T)
   d <- d[order(d$K), ];
   rownames(d) <- 1:nrow(d);
   par(mar=c(5,4,4,5)+.1, cex=0.8);
   barplot(d$reads/1e6, names=d$K, col='white', ylab='Number of reads (in millions)', xlab='K',
      main=paste('Reads used and N50 by K-mers in the assembly of', lib));
   barplot(d$used/1e6, col='grey', add=T);
   par(new=T);
   plot(1:length(d$K)-0.5, d$N50, col=red, t='b', lty=2, pch=20, cex=1, lwd=1.5,
      xlim=c(0, length(d$K)), xaxt='n', yaxt='n', xlab='', ylab='');
   axis(4, col.axis=red);
   mtext('N50 (bp)', side=4, line=3, col=red);
   # Suggest best k-mers
   if(nrow(d) >= 3){
      x = data.frame(K=d$K, l=(d$N50 - mean(d$N50))/sd(d$N50), u=(d$used - mean(d$used))/sd(d$used));
      rownames(x) <- rownames(d)
      d <- cbind(d, sel=FALSE);
      k_s = c();
      for(l_star in c(2, 1/2, 1)){
         k_s_i = x$K[which.max(l_star*x$l + x$u)];
	 k_s <- c(k_s, k_s_i);
	 x <- x[x$K!=k_s_i, ];
	 d$sel[d$K==k_s_i] <- TRUE;
      }
      abline(v=as.numeric(rownames(d)[d$sel])-0.5, col='darkgreen', lty=6);
   }
   return(d);
}

